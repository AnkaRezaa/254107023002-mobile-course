import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/validators/task_validator.dart';

void main() {
  group('isValidTaskTitle', () {
    test('menerima judul yang berisi teks', () {
      // Arrange
      const title = 'Belajar Flutter Testing';

      // Act
      final result = isValidTaskTitle(title);

      // Assert
      expect(result, isTrue);
    });

    test('menolak teks kosong atau hanya spasi', () {
      // Arrange & Act & Assert
      expect(isValidTaskTitle(''), isFalse);
      expect(isValidTaskTitle('   '), isFalse);
      expect(isValidTaskTitle('\t\n'), isFalse);
    });

    test('menerima judul dengan spasi di awal atau akhir', () {
      // Arrange
      const titleWithPadding = '   Tugas Mobile Week 12   ';

      // Act
      final result = isValidTaskTitle(titleWithPadding);

      // Assert
      expect(result, isTrue);
    });
  });

  group('TaskValidator.validateTaskTitle - Kasus Tepi dan Nilai Batas', () {
    test('mengembalikan error jika input null', () {
      // Arrange
      const String? nullInput = null;

      // Act
      final error = TaskValidator.validateTaskTitle(nullInput);

      // Assert
      expect(error, equals('Judul tugas tidak boleh kosong atau hanya spasi'));
    });

    test('mengembalikan error jika input kosong atau hanya spasi', () {
      expect(
        TaskValidator.validateTaskTitle(''),
        equals('Judul tugas tidak boleh kosong atau hanya spasi'),
      );
      expect(
        TaskValidator.validateTaskTitle('     '),
        equals('Judul tugas tidak boleh kosong atau hanya spasi'),
      );
    });

    test('menolak masukan di bawah batas minimum (< 3 karakter)', () {
      // Arrange
      const shortTitle = 'AB';

      // Act
      final error = TaskValidator.validateTaskTitle(shortTitle);

      // Assert
      expect(error, equals('Judul tugas minimal harus terdiri dari 3 karakter'));
    });

    test('menolak masukan di atas batas maksimum (> 100 karakter)', () {
      // Arrange
      final longTitle = 'A' * 101;

      // Act
      final error = TaskValidator.validateTaskTitle(longTitle);

      // Assert
      expect(error, equals('Judul tugas maksimal 100 karakter'));
    });

    test('menerima masukan tepat pada batas minimum dan maksimum', () {
      // Tepat 3 karakter
      expect(TaskValidator.validateTaskTitle('ABC'), isNull);

      // Tepat 100 karakter
      expect(TaskValidator.validateTaskTitle('A' * 100), isNull);
    });
  });

  group('TaskValidator.isValidTaskDescription', () {
    test('menerima deskripsi normal dan kosong', () {
      expect(TaskValidator.isValidTaskDescription(''), isTrue);
      expect(
        TaskValidator.isValidTaskDescription('Deskripsi pengerjaan praktikum'),
        isTrue,
      );
    });

    test('menolak deskripsi yang melebihi batas 500 karakter', () {
      final oversizedDescription = 'D' * 501;
      expect(
        TaskValidator.isValidTaskDescription(oversizedDescription),
        isFalse,
      );
    });
  });
}

