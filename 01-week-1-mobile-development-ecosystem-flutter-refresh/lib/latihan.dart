import 'package:flutter/material.dart';

String nama = 'Muhammad anka reza';
int semester = 5;
final bool aktif = true;

double panjang = 10.0;
double lebar = 5.0;

String sapa(String nama, int semester) =>
    'Halo $nama, semester $semester';

double hitungLuasPersegiPanjang(double panjang, double lebar) =>
    panjang * lebar;

class Profil {
  Profil({this.nama, this.nim, this.email});

  final String? nama;
  final String? nim;
  final String? email;
}

class Mahasiswa {
  Mahasiswa({
    required this.nama,
    required this.aktif,
  });
  

  final String nama;
  final bool aktif;

  String status() =>
      aktif ? '$nama aktif' : '$nama tidak aktif';
}




class LatihanApp extends StatelessWidget {
  const LatihanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mahasiswa = Mahasiswa(
      nama: nama,
      aktif: aktif,
    );

    final luas = hitungLuasPersegiPanjang(
      panjang,
      lebar,
    );

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(sapa(nama, semester)),
              Text(mahasiswa.status()),
              Text('Luas Persegi Panjang: $luas'),
            ],
          ),
        ),
      ),
    );
  }
}