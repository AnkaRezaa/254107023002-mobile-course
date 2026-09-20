# 04-week-4-networking-rest-api

pada pertemuan kali ini saya mempelajari konsep dari HTTP, REST API DAN JSON,memetakan JSON ke model dart (serealization) dengan aman null, menerapkan repository pattern dasar sehingga UI tidak memanggil API secara langsung,mengonfigurasi Dio (base URL, timeout, interceptor) dan menangani error jaringan,menampilkan state loading, error, empty, dan success pada UI dengan AsyncValue + Riverpod,menerapkan pagination dasar (infinite scroll).

# KONSEP HTTP, REST dan JSON


# Praktikum 1 & 2 : Dio, model data & Provider, error handling

1. menjalankan aplikasi secara normal
prak2 1
![Praktikum 2.1 - Aplikasi berjalan normal](screenshots/prak2_1.jpg)


Gambar pertama menunjukkan aplikasi berhasil mengambil data dari API.

2. Mematikan internet (mode pesawat) dan ketika dinyalakan kembali
prak 2 2
prak 2 3 
![Praktikum 2.2 - Koneksi internet dimatikan](screenshots/prak2_2.jpg)

Gambar kedua menunjukkan kondisi ketika internet dimatikan.


![Praktikum 2.3 - Koneksi internet dinyalakan kembali](screenshots/prak2_3kembali.jpg)

Gambar ketiga menunjukkan aplikasi kembali berjalan setelah internet dinyalakan.

3. ubah BaseUrl menjadi URL salah 

prak ubahkode
prak 2 3 status
![Praktikum 2 - Base URL diubah menjadi URL salah](screenshots/prak2_ubahkode.jpg)
Gambar keempat menunjukkan perubahan BaseUrl menjadi URL yang salah.

![Praktikum 2.3 - Status error setelah Base URL salah](screenshots/prak2_3status.jpg)
Gambar kelima menunjukkan pesan error karena server tidak dapat ditemukan.




