import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});

  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) {
    return Todo(
      title ?? this.title,
      done: done ?? this.done,
    );
  }
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) {
    state = [...state, Todo(title)];
  }

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(
      done: !todos[index].done,
    );
    state = todos;
  }

  void remove(int index) {
    final todos = [...state]..removeAt(index);
    state = todos;
  }

  void toggleTodo(Todo todo) {
    toggle(state.indexOf(todo));
  }

  void removeTodo(Todo todo) {
    remove(state.indexOf(todo));
  }
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

final unfinishedTodoProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);

  return todos
      .where((todo) => !todo.done)
      .toList(growable: false);
});