import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoItem {
  String title;
  String description;
  String category;
  DateTime? dueDate;
  String priority;
  bool isDone;
  TodoItem({
    required this.title,
    required this.description,
    required this.category,
    this.dueDate,
    required this.priority,
    this.isDone = false,
  });
}

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> {
  final List<TodoItem> _todos = [];
  final List<String> _categories = ['Personal', 'Work', 'Other'];
  List<String> _priorities = ['High', 'Medium', 'Low'];

  void _addTodo(TodoItem item) {
    setState(() {
      _todos.add(item);
    });
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  Future<void> _showAddTodoDialog() async {
    String title = '';
    String description = '';
    String category = _categories.first;
    String priority = _priorities.last;
    DateTime? dueDate;
    bool isLoading = false;
    final titleController = TextEditingController();
    final descController = TextEditingController();

    Future<void> _addPriorityDialog() async {
      String newPriority = '';
      final controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Priority'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Priority name',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => newPriority = v,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPriority.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (newPriority.trim().isNotEmpty &&
          !_priorities.contains(newPriority.trim())) {
        setState(() {
          _priorities.insert(0, newPriority.trim());
          priority = newPriority.trim();
        });
      }
    }

    Future<void> _addCategoryDialog() async {
      String newCategory = '';
      final controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category name',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => newCategory = v,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newCategory.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (newCategory.trim().isNotEmpty &&
          !_categories.contains(newCategory.trim())) {
        setState(() {
          _categories.insert(0, newCategory.trim());
          category = newCategory.trim();
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add TO-DO'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width < 400
                    ? MediaQuery.of(context).size.width * 0.95
                    : 400,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (value) => description = value,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: [
                        ..._categories.map(
                              (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ),
                        ),
                        const DropdownMenuItem<String>(
                          value: '__add_category__',
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 6),
                              Text('Add Category'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        if (val == '__add_category__') {
                          await _addCategoryDialog();
                          setState(() {}); // refresh after adding
                        } else if (val != null) {
                          setState(() => category = val);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: priority,
                      items: [
                        ..._priorities.map(
                              (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          ),
                        ),
                        const DropdownMenuItem<String>(
                          value: '__add_priority__',
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 6),
                              Text('Add Priority'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        if (val == '__add_priority__') {
                          await _addPriorityDialog();
                          setState(() {}); // refresh after adding
                        } else if (val != null) {
                          setState(() => priority = val);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                        );
                        if (picked != null) setState(() => dueDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                dueDate != null
                                    ? DateFormat('yyyy-MM-dd').format(dueDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  color: dueDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xff0045F3)),
                ),
              ),
              isLoading
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                  ),
                ),
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () async {
                  if (title.trim().isEmpty) return;
                  setState(() => isLoading = true);
                  await Future.delayed(
                    const Duration(milliseconds: 400),
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _addTodo(
                      TodoItem(
                        title: title.trim(),
                        description: description.trim(),
                        category: category,
                        dueDate: dueDate,
                        priority: priority,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Color(0xff0045F3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double cardPadding = width < 400 ? 8 : 16;
    final double cardMargin = width < 400 ? 4 : 8;
    return Scaffold(
      backgroundColor: Colors.white, // Set the entire background to white
      appBar: AppBar(
        title: const Text('TO-DO List'),
        backgroundColor: Colors.white, // Optional: Set AppBar to white for consistency
        elevation: 0, // Optional: Remove shadow for a flat look
      ),
      body: _todos.isEmpty
          ? Center(
        child: Text(
          'No TO-DOs yet!',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.all(cardPadding),
        itemCount: _todos.length,
        separatorBuilder: (_, __) => SizedBox(height: cardMargin),
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return Dismissible(
            key: ValueKey(
              todo.title +
                  todo.description +
                  todo.category +
                  (todo.dueDate?.toIso8601String() ?? '') +
                  todo.priority,
            ),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteTodo(index),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: width < 400 ? 8 : 12,
                  horizontal: width < 400 ? 8 : 16,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: todo.isDone,
                    onChanged: (_) => _toggleTodo(index),
                    activeColor: const Color(0xff0045F3),
                  ),
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: width < 400 ? 16 : 18,
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: todo.isDone ? Colors.grey : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (todo.description.isNotEmpty)
                        Text(
                          todo.description,
                          style: TextStyle(
                            fontSize: width < 400 ? 12 : 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              todo.category,
                              style: TextStyle(
                                fontSize: width < 400 ? 11 : 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              todo.dueDate != null
                                  ? DateFormat('yyyy-MM-dd')
                                  .format(todo.dueDate!)
                                  : 'No due date',
                              style: TextStyle(
                                fontSize: width < 400 ? 11 : 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.flag,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              todo.priority,
                              style: TextStyle(
                                fontSize: width < 400 ? 11 : 13,
                                color: todo.priority == 'High'
                                    ? Colors.red
                                    : todo.priority == 'Medium'
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: const Color(0xff0045F3),
        tooltip: 'Add TO-DO',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}