import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:todo_app/model/todo_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      home: LockScreen(),
    );
  }
}

class LockScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.grey[200],
            ),
            Image.asset(
              'images/wp-mobile.jpg',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Container(
                    child: Text(
                      'To Do App',
                      style: TextStyle(
                        fontSize: 60.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return HomeScreen();
                        }),
                      );
                    },
                    child: Text('Continue >>>'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Future<Database> database;
  List<ToDo> todos = [];

  @override
  void initState() {
    super.initState();
    initDB();
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _dateController.dispose();
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    DateTime init = DateTime.now();
    if (index != null) {
      init = todos[index].deadline;
    }
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2015, 1),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
        _dateController.text = dateToString(_selectedDate);
      });
  }

  Future initDB() async {
    WidgetsFlutterBinding.ensureInitialized();
    database = openDatabase(
      join(await getDatabasesPath(), 'todo.db'),
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE IF NOT EXISTS todo(id INTEGER PRIMARY KEY, name TEXT, deadline TEXT, isDone INTEGER)");
      },
      version: 1,
    );

    await getToDo();
  }

  Future getToDo() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todo');

    setState(() {
      todos = List.generate(maps.length, (i) {
        return ToDo(
          id: maps[i]['id'],
          name: maps[i]['name'],
          deadline: DateTime.parse(maps[i]['deadline']),
          isDone: maps[i]['isDone'] == 1 ? true : false,
        );
      });
    });

    todos.sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Future createToDo(String name, DateTime deadline) async {
    final Database db = await database;
    final int count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT max(id) FROM todo'));

    await db.insert(
      'todo',
      ToDo(
        id: count == null ? 0 : count + 1,
        name: name,
        deadline: deadline,
        isDone: false,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await getToDo();
  }

  Future updateToDo(int id, ToDo todo) async {
    final Database db = await database;

    await db.update(
      'todo',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await getToDo();
  }

  Future deleteToDo(int id) async {
    final db = await database;

    await db.delete(
      'todo',
      where: "id = ?",
      whereArgs: [id],
    );

    await getToDo();
  }

  Future clear() async {
    final db = await database;

    await db.rawDelete('DELETE FROM todo');
    await getToDo();
  }

  void resetController() {
    // final DateTime date = DateTime.now();
    _nameController.text = '';
    _dateController.text = dateToString(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        leading: ElevatedButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
              EdgeInsets.zero,
            ),
          ),
          child: Text(
            'Back',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (builder, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: todos[index].isDone == true
                    ? Colors.green[400]
                    : Colors.red,
              ),
              padding: const EdgeInsets.all(6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width - 140,
                        child: Text(
                          '${todos[index].name}',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${dateToString(todos[index].deadline)}',
                        textAlign: TextAlign.left,
                      )
                    ],
                  ),
                  if (todos[index].isDone == true)
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.close),
                            color: Colors.red,
                            onPressed: () {
                              updateToDo(
                                todos[index].id,
                                ToDo(
                                  id: todos[index].id,
                                  name: todos[index].name,
                                  deadline: todos[index].deadline,
                                  isDone: false,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 4.0),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              deleteToDo(todos[index].id);
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.edit),
                            color: Colors.green[800],
                            onPressed: () {
                              _showDialog(context, todos[index].id, 1,
                                  index: index);
                            },
                          ),
                        ),
                        SizedBox(width: 4.0),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(Icons.check),
                            color: Colors.green[800],
                            onPressed: () {
                              updateToDo(
                                todos[index].id,
                                ToDo(
                                  id: todos[index].id,
                                  name: todos[index].name,
                                  deadline: todos[index].deadline,
                                  isDone: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await _showDialog(context, todos.length + 1, 0);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistic',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                int finished =
                    todos.where((element) => element.isDone == true).length;
                return StatScreen(finished, todos.length - finished);
              }),
            );
          }
        },
      ),
    );
  }

  _showDialog(BuildContext context, int id, int method, {int index}) async {
    resetController();
    if (method == 1) {
      _nameController.text = todos[index].name;
      _dateController.text = dateToString(todos[index].deadline);
    }
    showDialog(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: AlertDialog(
            content: Column(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Task name: ',
                  ),
                ),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date: ',
                  ),
                  onTap: () => _selectDate(context, index),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  if (method == 0) {
                    await createToDo(_nameController.text, _selectedDate);
                  } else {
                    await updateToDo(
                      id,
                      ToDo(
                        id: id,
                        name: _nameController.text,
                        deadline: _selectedDate,
                        isDone: false,
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatScreen extends StatelessWidget {
  final int _finished;
  final int _unfinished;

  StatScreen(this._finished, this._unfinished);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistic page'),
        leading: ElevatedButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
              EdgeInsets.zero,
            ),
          ),
          child: Text(
            'Back',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6.0),
                padding: const EdgeInsets.all(15.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.green[400],
                ),
                child: Column(
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Finished',
                          style: TextStyle(
                            fontSize: 30.0,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 5,
                      child: Center(
                        child: Text(
                          '$_finished',
                          style: TextStyle(
                            fontSize: 150.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6.0),
                padding: const EdgeInsets.all(15.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.red,
                ),
                child: Column(
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Unfinished',
                          style: TextStyle(
                            fontSize: 30.0,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 5,
                      child: Center(
                        child: Text(
                          '$_unfinished',
                          style: TextStyle(
                            fontSize: 150.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistic',
          ),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
