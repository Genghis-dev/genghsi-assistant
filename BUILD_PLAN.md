# Clicky Local — Build Plan

## Context

Building a local-first AI companion for macOS — a "personal Jarvis" that floats above all windows, powered by Gemma 4 running locally via Docker Model Runner. Zero cloud APIs, zero cost, fully private. Inspired by [farzaa/clicky](https://github.com/farzaa/clicky) but with additional tools (notes, todos, rewriter, clipboard) and no cloud dependencies.

## Tech Stack

| Layer | Tech |
|-------|------|
| App | Swift + SwiftUI (macOS 14.2+) |
| AI Brain | Docker Model Runner + Gemma 4 (E4B for speed, 26B MoE for quality) |
| STT | Apple Speech framework (`SFSpeechRecognizer`) — zero dependency |
| TTS | `AVSpeechSynthesizer` (built-in macOS) |
| Storage | SwiftData (SQLite under the hood) |
| Screenshots | ScreenCaptureKit |
| Hotkeys | `CGEvent` global tap |
| Overlay | `NSPanel` (always-on-top, non-activating) |

## Architecture

```
┌─────────────────────────────────────────────┐
│  MenuBar App (no dock icon)                 │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │ Overlay   │  │ Radial   │  │ Notes/    │ │
│  │ Panel     │  │ Menu     │  │ Todo Panel│ │
│  │ (NSPanel) │  │ (SwiftUI)│  │ (NSPanel) │ │
│  └────┬──────┘  └────┬─────┘  └─────┬─────┘ │
│       │              │              │        │
│  ┌────┴──────────────┴──────────────┴─────┐ │
│  │         CompanionManager               │ │
│  │    (central state machine / @Observable)│ │
│  └────┬──────────┬───────────┬────────────┘ │
│       │          │           │              │
│  ┌────┴───┐ ┌────┴────┐ ┌───┴──────┐       │
│  │ Gemma  │ │ Speech  │ │ SwiftData│       │
│  │ Client │ │ STT/TTS │ │ Store    │       │
│  └────┬───┘ └─────────┘ └──────────┘       │
│       │                                     │
└───────┼─────────────────────────────────────┘
        │ HTTP (localhost)
┌───────┴─────────────────┐
│  Docker Model Runner    │
│  Gemma 4 (E4B or 26B)   │
└─────────────────────────┘
```

## Data Model (SwiftData)

```swift
@Model class Note {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
}

@Model class Todo {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var source: TodoSource  // .manual, .extractedFromNote(noteId)
    var createdAt: Date
    var completedAt: Date?
}

@Model class ClipboardEntry {
    var id: UUID
    var content: String
    var appSource: String   // which app it was copied from
    var capturedAt: Date
}

@Model class WritingSample {
    var id: UUID
    var content: String
    var addedAt: Date
}
```

## Phased Build

### Phase 1 — Shell & Summon (Day 1 morning)

**Goal:** App launches in menubar, global hotkey summons/dismisses an overlay.

Files to create:
- `ClickyLocal/App/ClickyLocalApp.swift` — entry point, menubar-only app
- `ClickyLocal/App/AppDelegate.swift` — `NSApplicationDelegate`, setup
- `ClickyLocal/Core/CompanionManager.swift` — central `@Observable` state machine
- `ClickyLocal/Core/HotkeyManager.swift` — `CGEvent` global shortcut (Cmd+Shift+Space)
- `ClickyLocal/Windows/OverlayPanelController.swift` — `NSPanel` setup (always-on-top, transparent, non-activating)
- `ClickyLocal/Views/CompanionView.swift` — the Clicky avatar that appears at cursor

Reference: Clicky's `GlobalPushToTalkShortcutMonitor.swift`, `OverlayWindow.swift`, `MenuBarPanelManager.swift`

### Phase 2 — Radial Menu (Day 1 afternoon)

**Goal:** Hold Tab when Clicky is visible → pie menu fans out with tool slices.

Files:
- `ClickyLocal/Views/RadialMenuView.swift` — SwiftUI radial layout with spring animations
- `ClickyLocal/Models/Tool.swift` — enum of available tools
- Update `CompanionManager` with tool selection state

The radial menu: 6 slices arranged in a circle around the avatar. Each slice has an SF Symbol icon + label. Hover highlights, release activates. Use `withAnimation(.spring)` for the fan-out.

### Phase 3 — Notes & Todos (Day 1 evening)

**Goal:** Functional floating notes and todo panel.

Files:
- `ClickyLocal/Views/NotesPanel.swift` — floating, draggable sticky note (always-on-top `NSPanel`)
- `ClickyLocal/Views/TodoPanel.swift` — pending todo sidebar that slides in on summon
- `ClickyLocal/Store/DataStore.swift` — SwiftData container + CRUD helpers
- `ClickyLocal/Models/` — SwiftData models (Note, Todo, ClipboardEntry, WritingSample)

Notes panel: minimal, draggable, resizable, vibrancy material background. Dismiss with Esc.
Todo panel: slides in from right when Clicky summoned, shows uncompleted items, checkbox to complete.

### Phase 4 — Gemma 4 Integration (Day 2 morning)

**Goal:** Chat with Gemma 4 via Docker Model Runner. Wire up AI to the companion.

Files:
- `ClickyLocal/AI/GemmaClient.swift` — HTTP client hitting Docker Model Runner's local API (OpenAI-compatible at localhost)
- `ClickyLocal/AI/GemmaStreaming.swift` — SSE streaming response parser
- `ClickyLocal/AI/Prompts.swift` — system prompts for different tools (rewrite, todo extraction, digest, etc.)
- Update `CompanionManager` to route tool actions through Gemma

Docker Model Runner exposes an OpenAI-compatible API. Use `URLSession` with streaming for responses.

### Phase 5 — Smart Features (Day 2 afternoon)

**Goal:** AI-powered tools work end-to-end.

Features to wire up:
- **Todo extraction:** When a note is saved, send to Gemma → extract actionable items → create Todos
- **"Write Like Me" rewriter:** Read clipboard/selection + writing samples → Gemma rewrites in user's tone
- **Daily digest:** On first summon of the day, Gemma summarizes pending todos + recent notes
- **Screen context:** ScreenCaptureKit screenshot → send as image to Gemma 4 (multimodal) → "add to notes" or "make todo from this"

Files:
- `ClickyLocal/AI/TodoExtractor.swift`
- `ClickyLocal/AI/Rewriter.swift`
- `ClickyLocal/AI/DailyDigest.swift`
- `ClickyLocal/Screen/ScreenCaptureManager.swift`

### Phase 6 — Voice & Clipboard (Day 2 evening)

**Goal:** Push-to-talk voice input, TTS responses, clipboard history.

Files:
- `ClickyLocal/Voice/SpeechRecognizer.swift` — `SFSpeechRecognizer` for local STT
- `ClickyLocal/Voice/SpeechSynthesizer.swift` — `AVSpeechSynthesizer` for TTS
- `ClickyLocal/Clipboard/ClipboardMonitor.swift` — poll `NSPasteboard` every 1s, store last 50 entries
- `ClickyLocal/Views/ClipboardPanel.swift` — searchable clipboard history UI

### Phase 7 — Polish (Day 3)

**Goal:** Context zones, pin mode, animations, edge cases.

- `ClickyLocal/Core/ContextZoneDetector.swift` — `NSWorkspace` frontmost app detection, adapt available tools
- `ClickyLocal/Views/MiniModeView.swift` — persistent small widget (todo count + quick-note button)
- Design polish: vibrancy materials, spring animations, SF Symbols, smooth transitions
- `ClickyLocal/App/OnboardingView.swift` — first-launch: request permissions (accessibility, microphone, screen recording), check Docker is running

## Xcode Project Structure

```
ClickyLocal/
├── App/
│   ├── ClickyLocalApp.swift
│   ├── AppDelegate.swift
│   └── OnboardingView.swift
├── Core/
│   ├── CompanionManager.swift
│   ├── HotkeyManager.swift
│   └── ContextZoneDetector.swift
├── Windows/
│   └── OverlayPanelController.swift
├── Views/
│   ├── CompanionView.swift
│   ├── RadialMenuView.swift
│   ├── NotesPanel.swift
│   ├── TodoPanel.swift
│   ├── ClipboardPanel.swift
│   └── MiniModeView.swift
├── AI/
│   ├── GemmaClient.swift
│   ├── GemmaStreaming.swift
│   ├── Prompts.swift
│   ├── TodoExtractor.swift
│   ├── Rewriter.swift
│   └── DailyDigest.swift
├── Voice/
│   ├── SpeechRecognizer.swift
│   └── SpeechSynthesizer.swift
├── Screen/
│   └── ScreenCaptureManager.swift
├── Clipboard/
│   └── ClipboardMonitor.swift
├── Store/
│   └── DataStore.swift
├── Models/
│   ├── Tool.swift
│   ├── Note.swift
│   ├── Todo.swift
│   ├── ClipboardEntry.swift
│   └── WritingSample.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

## Permissions Required (Info.plist)

- `NSMicrophoneUsageDescription` — voice input
- `NSSpeechRecognitionUsageDescription` — STT
- `NSScreenCaptureUsageDescription` — screenshots
- Accessibility access — global hotkey via `CGEvent` (prompted at runtime)

## Prerequisites

1. macOS 14.2+ (for ScreenCaptureKit APIs)
2. Xcode 15+
3. Docker Desktop installed with Model Runner enabled
4. `docker model pull gemma4` (E4B recommended to start, ~5GB)

## Verification

1. **Phase 1:** App appears in menubar only (no dock icon). Cmd+Shift+Space shows/hides the avatar at cursor position.
2. **Phase 2:** Hold Tab with Clicky visible → radial menu animates out. Release on a slice → logs which tool was selected.
3. **Phase 3:** Select Notes from radial → floating note appears. Type text, dismiss, re-open → text persists. Todos panel shows on summon.
4. **Phase 4:** Select chat/voice → type a message → Gemma 4 responds via streaming text in the overlay.
5. **Phase 5:** Write "I need to fix the auth bug tomorrow" in notes → todo auto-created. Select text + Rewrite → returns rewritten text.
6. **Phase 6:** Hold voice key → speak → transcription appears. Gemma responds with TTS audio.
7. **Phase 7:** Switch to VS Code → Clicky shows code-relevant tools. Pin mode shows mini widget.
