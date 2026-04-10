import SwiftUI
import SwiftData

struct TodoPanelView: View {
    @State private var todos: [Todo] = []
    @State private var newTodoTitle = ""
    @FocusState private var isInputFocused: Bool
    let store = DataStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with count
            HStack {
                Text("Todos")
                    .font(.system(size: 13, weight: .semibold))

                let pendingCount = todos.filter { !$0.isCompleted }.count
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue))
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 10)

            // Add new todo
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)

                TextField("Add a todo...", text: $newTodoTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isInputFocused)
                    .onSubmit {
                        addTodo()
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 10)

            // Todo list
            if todos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("All clear!")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(todos) { todo in
                            TodoRowView(todo: todo, onToggle: {
                                todo.toggleCompleted()
                                store.save()
                                refreshTodos()
                            }, onDelete: {
                                store.deleteTodo(todo)
                                refreshTodos()
                            })
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(width: 260, height: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
        .onAppear { refreshTodos() }
    }

    private func addTodo() {
        let title = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        _ = store.createTodo(title: title)
        newTodoTitle = ""
        refreshTodos()
    }

    private func refreshTodos() {
        todos = store.fetchTodos(includeCompleted: false)
    }
}

struct TodoRowView: View {
    @Bindable var todo: Todo
    var onToggle: () -> Void
    var onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.system(size: 12))
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? .tertiary : .primary)
                .lineLimit(2)

            Spacer()

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : .clear)
        )
        .onHover { isHovered = $0 }
    }
}
