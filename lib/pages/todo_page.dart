import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import 'add_todo_page.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

enum TodoSortOrder { createdAt, priority, dueDate }

class _TodoPageState extends State<TodoPage> {
  List<Todo> _todos = [];
  TodoSortOrder _currentSortOrder = TodoSortOrder.dueDate;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // --- データの保存・読み込み ---
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('todo_list');
    final int? sortIndex = prefs.getInt('sort_order');

    if (sortIndex != null) _currentSortOrder = TodoSortOrder.values[sortIndex];

    if (todosJson != null) {
      final List<dynamic> decoded = jsonDecode(todosJson);
      setState(() {
        _todos = decoded.map((item) => Todo.fromJson(item)).toList();
        _sortTodos();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
    await prefs.setString('todo_list', encoded);
    await prefs.setInt('sort_order', _currentSortOrder.index);
  }

  void _sortTodos() {
    setState(() {
      _todos.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        switch (_currentSortOrder) {
          case TodoSortOrder.createdAt: return b.createdAt.compareTo(a.createdAt);
          case TodoSortOrder.priority: return a.priority.index.compareTo(b.priority.index);
          case TodoSortOrder.dueDate: return a.dueDate.compareTo(b.dueDate);
        }
      });
    });
  }

  bool _isExpired(Todo todo) {
    if (todo.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return todo.dueDate.isBefore(today);
  }

  bool _isDueToday(Todo todo) {
    if (todo.isCompleted) return false; // 完了済みなら強調しない

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(todo.dueDate.year, todo.dueDate.month, todo.dueDate.day);

    return dueDate.isAtSameMomentAs(today);
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTodoPage()));
    if (result != null && result is Todo) {
      setState(() { _todos.add(result); _sortTodos(); });
      _saveTodos();
    }
  }

  void _navigateToEditPage(Todo todo, int indexInFullList) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddTodoPage(todo: todo)));
    if (result != null && result is Todo) {
      setState(() {
        // IDで探して差し替える
        final fullIndex = _todos.indexWhere((t) => t.id == todo.id);
        if (fullIndex != -1) _todos[fullIndex] = result;
        _sortTodos();
      });
      _saveTodos();
    }
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    final expiredTodos = _todos.where((t) => _isExpired(t)).toList();
    final ongoingTodos = _todos.where((t) => !_isExpired(t)).toList();

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TODOs'),
          actions: [
            PopupMenuButton<TodoSortOrder>(
              icon: const Icon(Icons.sort),
              onSelected: (order) { _currentSortOrder = order; _sortTodos(); _saveTodos(); },
              itemBuilder: (context) => [
                const PopupMenuItem(value: TodoSortOrder.dueDate, child: Text('期限順')),
                const PopupMenuItem(value: TodoSortOrder.priority, child: Text('優先度順')),
                const PopupMenuItem(value: TodoSortOrder.createdAt, child: Text('作成順')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.check_circle), text: '進行中'),
              Tab(icon: Icon(Icons.warning), text: '期限切れ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTodoList(ongoingTodos), // 進行中
            _buildTodoList(expiredTodos), // 期限切れ
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddPage,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> displayList) {
    if (displayList.isEmpty) return const Center(child: Text('タスクはありません'));
    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final todo = displayList[index];
        return _buildTodoItem(todo);
      },
    );
  }

  Widget _buildTodoItem(Todo todo) {
    // 色の決定ロジック
    Color textColor = Colors.black;
    FontWeight fontWeight = FontWeight.normal;

    if (_isExpired(todo)) {
      textColor = Colors.red;      // 期限切れは赤
      fontWeight = FontWeight.bold;
    } else if (_isDueToday(todo)) {
      textColor = Colors.orange;   // 今日が期限はオレンジ
      fontWeight = FontWeight.bold;
    } else if (todo.isCompleted) {
      textColor = Colors.grey;     // 完了済みはグレー
    }

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('削除確認'),
            content: Text('「${todo.title}」を削除しますか？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (dir) {
        setState(() {
          // 全リストの中から、この To.DoのIDと一致するものだけを取り除く
          _todos.removeWhere((t) => t.id == todo.id);
        });
        _saveTodos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${todo.title} を削除しました')),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          onTap: () => _navigateToEditPage(todo, _todos.indexOf(todo)),
          leading: CircleAvatar(
            backgroundColor: _getPriorityColor(todo.priority),
            radius: 8,
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: textColor == Colors.black ? Colors.grey : textColor
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '期限: ${todo.dueDate.year}/${todo.dueDate.month}/${todo.dueDate.day}',
                    style: TextStyle(color: textColor == Colors.black ? Colors.grey[600] : textColor),
                  ),
                ],
              ),
              if (todo.memo.isNotEmpty)
                Text(todo.memo, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: Checkbox(
            value: todo.isCompleted,
            onChanged: (val) {
              setState(() {
                todo.isCompleted = val!;
                _sortTodos(); // 並び替えを実行
              });
              _saveTodos(); // 保存
            },
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority p) {
    if (p == Priority.high) return Colors.red;
    if (p == Priority.medium) return Colors.orange;
    return Colors.blue;
  }
}