/// Validator fungsi logika bisnis untuk modul tugas dan pengumuman kampus.
/// Memastikan aturan masukan divalidasi secara murni tanpa ketergantungan UI.
class TaskValidator {
  /// Memeriksa apakah judul tugas berisi teks yang valid setelah spasi diabaikan.
  static bool isValidTaskTitle(String value) {
    return value.trim().isNotEmpty;
  }

  /// Validator untuk FormField Flutter yang mengembalikan pesan error atau null jika valid.
  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul tugas tidak boleh kosong atau hanya spasi';
    }
    if (value.trim().length < 3) {
      return 'Judul tugas minimal harus terdiri dari 3 karakter';
    }
    if (value.trim().length > 100) {
      return 'Judul tugas maksimal 100 karakter';
    }
    return null;
  }

  /// Memeriksa apakah deskripsi tugas berada dalam batas panjang yang diizinkan (default max 500 karakter).
  static bool isValidTaskDescription(String value, {int maxLength = 500}) {
    return value.trim().length <= maxLength;
  }
}

/// Fungsi helper tingkat atas sesuai contoh resmi codelab Week 12.
bool isValidTaskTitle(String value) => TaskValidator.isValidTaskTitle(value);
