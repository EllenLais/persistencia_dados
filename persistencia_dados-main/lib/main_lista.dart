import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://mzxoxghhbefuqnmlixgz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16eG94Z2hoYmVmdXFubWxpeGd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2Njk2NTEsImV4cCI6MjA3NTI0NTY1MX0.b6NG4-ov8bNMP6T_f3LvTQeO4d0xO4ZBcSFpKhZb2_U',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Produtos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ListaProdutosScreen(),
    );
  }
}

class Produto {
  final int id;
  final String produto;
  final String descricao;
  final double preco;
  final int estoque;
  final String? imagemUrl;
  final DateTime? createdAt;

  const Produto({
    required this.id,
    required this.produto,
    required this.descricao,
    required this.preco,
    required this.estoque,
    this.imagemUrl,
    this.createdAt,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] ?? 0,
      produto: json['produto'] ?? '',
      descricao: json['descricao'] ?? '',
      preco: (json['preco'] ?? 0.0).toDouble(),
      estoque: json['estoque'] ?? 0,
      imagemUrl: json['imagem_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

class ListaProdutosScreen extends StatefulWidget {
  const ListaProdutosScreen({Key? key}) : super(key: key);

  @override
  State<ListaProdutosScreen> createState() => ListaProdutosScreenState();
}

class ListaProdutosScreenState extends State<ListaProdutosScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Produto> _produtos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _supabase
          .from('Produtos') 
          .select()
          .order('produto');

      final produtos = (response as List)
          .map<Produto>((json) => Produto.fromJson(json))
          .toList();

      setState(() {
        _produtos = produtos;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar produtos: $e';
      });
      print('Erro detalhado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarProdutos(String query) async {
    try {
      final response = await _supabase
          .from('Produtos')  
          .select()
          .ilike('produto', '%$query%')
          .order('produto');

      final produtos = (response as List)
          .map<Produto>((json) => Produto.fromJson(json))
          .toList();

      setState(() {
        _produtos = produtos;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro na busca: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Produtos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarProdutos,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _carregarProdutos,
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando produtos...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregarProdutos,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_produtos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar produtos...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                _carregarProdutos();
              } else {
                _buscarProdutos(value);
              }
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregarProdutos,
            child: ListView.builder(
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final produto = _produtos[index];
                return _buildProdutoCard(produto);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProdutoCard(Produto produto) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: produto.imagemUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(produto.imagemUrl!),
                radius: 25,
              )
            : const CircleAvatar(
                child: Icon(Icons.shopping_bag),
                radius: 25,
              ),
        title: Text(
          produto.produto,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(produto.descricao),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'R\$${produto.preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Estoque: ${produto.estoque}',
                  style: TextStyle(
                    color: produto.estoque > 0 ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _mostrarDetalhesProduto(produto);
        },
      ),
    );
  }

  void _mostrarDetalhesProduto(Produto produto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(produto.produto),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (produto.imagemUrl != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(produto.imagemUrl!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              const SizedBox(height: 16),
              Text(produto.descricao),
              const SizedBox(height: 8),
              Text(
                'Preço: R\$${produto.preco.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estoque: ${produto.estoque} unidades',
                style: TextStyle(
                  color: produto.estoque > 0 ? Colors.blue : Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}