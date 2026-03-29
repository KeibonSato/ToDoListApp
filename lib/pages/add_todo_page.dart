import 'package:flutter/material.dart';
import '../models/todo.dart';

class AddTodoPage extends StatefulWidget {
  final Todo? todo; // 編集対象のTo.Doを受け取れるようにする
  const AddTodoPage({super.key, this.todo});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  late Priority _selectedPriority;

  @override
  void initState() {
    super.initState();
    // 渡されたTo.Doがあればその値で初期化、なければ新規用
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _memoController = TextEditingController(text: widget.todo?.memo ?? '');
    _selectedDate = widget.todo?.dueDate ?? DateTime.now();
    _selectedPriority = widget.todo?.priority ?? Priority.medium;
  }

  // カレンダーを表示して日付を選択
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('タスクを追加')),
      body: SingleChildScrollView( // キーボード表示時の画面被り防止
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル入力
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 優先度選択（Dropdown）
            const Text('優先度', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<Priority>(
              value: _selectedPriority,
              isExpanded: true,
              items: Priority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p == Priority.high ? '高 (至急)' : p == Priority.medium ? '中' : '低'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPriority = val!),
            ),
            const SizedBox(height: 20),

            // 期限日選択
            const Text('期限日', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text('${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 20),

            // メモ入力（200文字制限）
            TextField(
              controller: _memoController,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'メモ (200文字以内)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty) return;

                  final resultTodo = Todo(
                    // ★ 編集なら元のIDを維持、新規なら新しく発行
                    id: widget.todo?.id ?? DateTime.now().toString(),
                    title: _titleController.text,
                    dueDate: _selectedDate,
                    priority: _selectedPriority,
                    memo: _memoController.text,
                    isCompleted: widget.todo?.isCompleted ?? false, // 完了状態も引き継ぐ
                  );
                  Navigator.pop(context, resultTodo);
                },
                child: const Text('保存する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}