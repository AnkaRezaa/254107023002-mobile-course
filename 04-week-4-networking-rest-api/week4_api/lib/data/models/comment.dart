// Model ini merepresentasikan satu komentar dari endpoint JSONPlaceholder.
class Comment {
  // Constructor menerima nilai yang sudah dinormalisasi oleh fromJson.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  // ID post yang memiliki komentar.
  final int postId;

  // ID unik komentar.
  final int id;

  // Nama penulis komentar.
  final String name;

  // Alamat email penulis komentar.
  final String email;

  // Isi komentar.
  final String body;

  // Factory ini membaca JSON dan memberi nilai default jika field hilang/null.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}
