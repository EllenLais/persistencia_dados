import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'tarefa.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    
    final path = join(await getDatabasesPath(), 'tarefas.db');
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tarefas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        dataCriacao INTEGER NOT NULL,
        concluida INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertTarefa(Tarefa tarefa) async {
    final db = await database;
    return await db.insert('tarefas', tarefa.toMap());
  }

  Future<List<Tarefa>> getTarefas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tarefas',
      orderBy: 'dataCriacao DESC',
    );
    return List.generate(maps.length, (i) {
      return Tarefa.fromMap(maps[i]);
    });
  }

  Future<Tarefa?> getTarefa(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Tarefa.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTarefa(Tarefa tarefa) async {
    final db = await database;
    return await db.update(
      'tarefas',
      tarefa.toMap(),
      where: 'id = ?',
      whereArgs: [tarefa.id],
    );
  }

  Future<int> deleteTarefa(int id) async {
    final db = await database;
    return await db.delete(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTarefas() async {
    final db = await database;
    return await db.delete('tarefas');
  }
}