import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListScreen(),
    );
  }
}

// Classe que representa a Estrutura dos Dados (Requisito 9)
class Task {
  String title;
  bool isCompleted;

  Task({required this.title, this.isCompleted = false});

  // Converte a Tarefa para Map (para poder salvar no formato JSON em texto plano)
  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
      };

  // Cria a Tarefa a partir do JSON recuperado do SharedPreferences
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _taskController = TextEditingController();
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Recupera os dados assim que o app abrir
  }

  // REQUISITO 8: Recuperação dos dados
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tarefas_salvas');
    
    if (tasksString != null) {
      final List<dynamic> decodedTasks = jsonDecode(tasksString);
      setState(() {
        _tasks = decodedTasks.map((item) => Task.fromJson(item)).toList();
      });
    }
  }

  // REQUISITO 7: Persistência (salvar a lista inteira)
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedTasks = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tarefas_salvas', encodedTasks);
  }

  // REQUISITO 4: Cadastro de tarefas
  void _addTask() {
    if (_taskController.text.trim().isEmpty) return; // Não cadastra tarefa sem título
    
    setState(() {
      _tasks.add(Task(title: _taskController.text.trim()));
      _taskController.clear();
    });
    _saveTasks();
  }

  // REQUISITO 5: Conclusão de tarefas
  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    _saveTasks();
  }

  // REQUISITO 6: Exclusão de tarefas
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    // DESAFIO ADICIONAL: Quantidade de tarefas pendentes
    int pendingCount = _tasks.where((t) => !t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas Persistente'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  // REQUISITO 10: TextField para entrada
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma nova tarefa...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.blueAccent, size: 48),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tarefas pendentes: $pendingCount',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            // REQUISITO 10: ListView para apresentar as tarefas
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleTask(index),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough // Risca a tarefa concluída
                          : TextDecoration.none,
                      color: task.isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteTask(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}