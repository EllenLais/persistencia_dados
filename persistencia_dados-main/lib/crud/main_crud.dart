import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class Tarefa {
  int? id;
  String titulo;
  String descricao;
  DateTime dataCriacao;
  bool concluida;

  Tarefa({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.dataCriacao,
    this.concluida = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'concluida': concluida ? 1 : 0,
    };
  }

  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['id'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']),
      concluida: map['concluida'] == 1,
    );
  }
}

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
    
    final dbPath = path.join(await getDatabasesPath(), 'tarefas.db');
    return await databaseFactory.openDatabase(
      dbPath,
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
    return List.generate(maps.length, (i) => Tarefa.fromMap(maps[i]));
  }

  Future<Tarefa?> getTarefa(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Tarefa.fromMap(maps.first);
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
    return await db.delete('tarefas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllTarefas() async {
    final db = await database;
    return await db.delete('tarefas');
  }
}

class ListaTarefasScreen extends StatefulWidget {
  const ListaTarefasScreen({super.key});

  @override
  State<ListaTarefasScreen> createState() => _ListaTarefasScreenState();
}

class _ListaTarefasScreenState extends State<ListaTarefasScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Tarefa> _tarefas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    setState(() => _carregando = true);
    final tarefas = await _databaseHelper.getTarefas();
    setState(() {
      _tarefas = tarefas;
      _carregando = false;
    });
  }

  void _adicionarTarefa() {
    _navegarParaTela(EditarTarefaScreen(onTarefaSalva: _carregarTarefas));
  }

  void _editarTarefa(Tarefa tarefa) {
    _navegarParaTela(EditarTarefaScreen(
      tarefa: tarefa,
      onTarefaSalva: _carregarTarefas,
    ));
  }

  void _navegarParaTela(Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => tela),
    );
  }

  Future<void> _deletarTarefa(int id) async {
    await _databaseHelper.deleteTarefa(id);
    _carregarTarefas();
    _mostrarSnackBar('Tarefa deletada com sucesso!');
  }

  Future<void> _alternarConclusao(Tarefa tarefa) async {
    tarefa.concluida = !tarefa.concluida;
    await _databaseHelper.updateTarefa(tarefa);
    _carregarTarefas();
  }

  Future<void> _deletarTodasTarefas() async {
    final deveDeletar = await _mostrarDialogoConfirmacao();
    if (deveDeletar) {
      await _databaseHelper.deleteAllTarefas();
      _carregarTarefas();
      _mostrarSnackBar('Todas as tarefas foram deletadas!');
    }
  }

  Future<bool> _mostrarDialogoConfirmacao() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Tem certeza que deseja deletar todas as tarefas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD de Tarefas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_tarefas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _deletarTodasTarefas,
              tooltip: 'Deletar todas as tarefas',
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _tarefas.isEmpty
              ? _buildTelaVazia()
              : _buildListaTarefas(),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarTarefa,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTelaVazia() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma tarefa encontrada',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'Clique no + para adicionar uma tarefa',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildListaTarefas() {
    return ListView.builder(
      itemCount: _tarefas.length,
      itemBuilder: (ctx, index) {
        final tarefa = _tarefas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: tarefa.concluida,
              onChanged: (_) => _alternarConclusao(tarefa),
            ),
            title: Text(
              tarefa.titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: tarefa.concluida
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: tarefa.concluida ? Colors.grey : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarefa.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: tarefa.concluida
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: tarefa.concluida ? Colors.grey : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Criada em: ${_formatarData(tarefa.dataCriacao)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarTarefa(tarefa),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletarTarefa(tarefa.id!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day}/${data.month}/${data.year} ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }
}

class EditarTarefaScreen extends StatefulWidget {
  final Tarefa? tarefa;
  final VoidCallback onTarefaSalva;

  const EditarTarefaScreen({
    super.key,
    this.tarefa,
    required this.onTarefaSalva,
  });

  @override
  State<EditarTarefaScreen> createState() => _EditarTarefaScreenState();
}

class _EditarTarefaScreenState extends State<EditarTarefaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.tarefa != null) {
      _tituloController.text = widget.tarefa!.titulo;
      _descricaoController.text = widget.tarefa!.descricao;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarTarefa() async {
    if (_formKey.currentState!.validate()) {
      final tarefa = Tarefa(
        id: widget.tarefa?.id,
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        dataCriacao: widget.tarefa?.dataCriacao ?? DateTime.now(),
        concluida: widget.tarefa?.concluida ?? false,
      );

      if (widget.tarefa == null) {
        await _databaseHelper.insertTarefa(tarefa);
      } else {
        await _databaseHelper.updateTarefa(tarefa);
      }

      widget.onTarefaSalva();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditando = widget.tarefa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Tarefa' : 'Nova Tarefa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                  hintText: 'Digite o título da tarefa',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  hintText: 'Digite a descrição da tarefa',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _salvarTarefa,
                  icon: const Icon(Icons.save),
                  label: Text(isEditando ? 'Atualizar' : 'Salvar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (isEditando) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD de Tarefas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ListaTarefasScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}