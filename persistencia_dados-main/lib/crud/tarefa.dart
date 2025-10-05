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