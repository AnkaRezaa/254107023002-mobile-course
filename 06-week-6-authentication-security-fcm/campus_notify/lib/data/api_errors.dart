import 'package:dio/dio.dart';


String mapDioExceptionToMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Koneksi ke server batas waktu (timeout). Silakan periksa jaringan Anda.';
      
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Sesi login Anda telah berakhir (401). Silakan masuk kembali.';
      } else if (statusCode == 403) {
        return 'Akses ditolak (403). Anda tidak memiliki izin untuk tindakan ini.';
      } else if (statusCode == 404) {
        return 'Layanan atau data tidak ditemukan (404).';
      } else if (statusCode != null && statusCode >= 500) {
        return 'Terjadi gangguan pada server kampus ($statusCode). Silakan coba lagi nanti.';
      }
      return 'Terjadi kesalahan respon dari server (${error.response?.statusCode}).';
      
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.';
      
    case DioExceptionType.cancel:
      return 'Permintaan ke server dibatalkan.';
      
    case DioExceptionType.badCertificate:
      return 'Sertifikat keamanan server tidak valid.';
      
    case DioExceptionType.unknown:
    default:
      return 'Terjadi kesalahan yang tidak terduga. Silakan coba beberapa saat lagi.';
  }
}