class CampusLocalKnowledgeBase {
  static const Map<List<String>, String> _faqEntries = {
    ['krs', 'kartu rencana studi', 'jadwal', 'perkuliahan', 'semester']:
        'Alur pengisian KRS semester genap dilakukan secara mandiri melalui Portal Akademik setelah menyelesaikan her-registrasi. Batas akhir pengisian dan persetujuan DPA adalah 10 Februari pukul 23.59 WIB.',
    ['beasiswa', 'kip', 'djarum', 'bantuan biaya']:
        'Informasi beasiswa (KIP-Kuliah, Beasiswa Djarum Plus, Bank Indonesia) dikelola oleh Bagian Kemahasiswaan. Pendaftaran dan verifikasi berkas semester berjalan dibuka pada minggu ke-2 perkuliahan.',
    ['ukt', 'bayar', 'kuitansi', 'tagihan', 'dispensasi', 'biaya']:
        'Pembayaran UKT dilakukan via Virtual Account Bank mitra (Mandiri, BNI, BRI, BTN). Untuk pengajuan keringanan atau cicilan UKT, mahasiswa wajib mengajukan surat permohonan ke Bagian Keuangan sebelum batas her-registrasi.',
    ['perpustakaan', 'buku', 'pinjam']:
        'Perpustakaan Pusat Kampus buka hari Senin–Jumat pukul 07.30–16.00 WIB. Peminjaman buku maksimal 3 buku selama 7 hari menggunakan KTM aktif atau barcode digital.',
    ['surat', 'keterangan aktif', 'magang', 'legalisir']:
        'Surat Keterangan Mahasiswa Aktif dan surat pengantar magang dapat diajukan secara online melalui menu Layanan Mandiri di Portal SIAKAD dan diproses 1x24 jam kerja.',
  };

  /// Mencari jawaban dari basis pengetahuan lokal kampus berdasarkan kata kunci
  static String? search(String query) {
    final lower = query.toLowerCase();
    for (final entry in _faqEntries.entries) {
      if (entry.key.any((keyword) => lower.contains(keyword))) {
        return entry.value;
      }
    }
    return null;
  }

  /// Daftar topik FAQ offline yang tersedia
  static List<String> getAllTopics() {
    return [
      'Alur Pengisian KRS & Jadwal Kuliah',
      'Informasi Beasiswa (KIP, Djarum, BI)',
      'Pembayaran UKT & Dispensasi Keuangan',
      'Layanan Perpustakaan & Peminjaman Buku',
      'Surat Keterangan Mahasiswa Aktif & Magang',
    ];
  }
}

