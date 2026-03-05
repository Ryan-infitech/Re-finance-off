# Aplikasi Pencatatan Keuangan

Aplikasi pencatatan keuangan berbasis Flutter yang berfungsi secara **offline** dengan fitur registrasi, login, dan manajemen transaksi pemasukan & pengeluaran.

## ✨ Fitur Utama

- 🔐 **Autentikasi**: Register dan Login dengan penyimpanan offline
- 💰 **Pencatatan Transaksi**: Catat income dan expense dengan mudah
- 📸 **Upload Foto**: Ambil foto dari kamera atau galeri sebagai bukti transaksi
- 📊 **Dashboard**: Lihat ringkasan saldo, pemasukan, dan pengeluaran
- 📝 **Riwayat**: Lihat daftar transaksi dengan filter
- 🗑️ **Hapus Transaksi**: Kelola transaksi dengan mudah
- 📱 **Offline**: Semua data tersimpan lokal tanpa koneksi internet

## 🏗️ Struktur Aplikasi

```
lib/
├── models/
│   ├── user_model.dart           # Model untuk data user
│   └── transaction_model.dart    # Model untuk data transaksi
├── services/
│   ├── database_helper.dart      # Helper untuk SQLite
│   ├── auth_service.dart         # Service autentikasi
│   ├── transaction_service.dart  # Service transaksi
│   └── image_service.dart        # Service untuk foto
├── screens/
│   ├── login_screen.dart         # Halaman login
│   ├── register_screen.dart      # Halaman register
│   ├── home_screen.dart          # Dashboard utama
│   ├── add_transaction_screen.dart    # Tambah transaksi
│   └── transaction_list_screen.dart   # Daftar transaksi
└── main.dart                     # Entry point aplikasi
```

## 🗄️ Database Schema

### Tabel `users`
| Kolom       | Tipe    | Deskripsi                 |
|-------------|---------|---------------------------|
| id          | INTEGER | Primary key, auto increment|
| username    | TEXT    | Nama pengguna             |
| email       | TEXT    | Email (unique)            |
| password    | TEXT    | Password (hashed SHA256)  |
| created_at  | TEXT    | Timestamp pembuatan       |

### Tabel `transactions`
| Kolom       | Tipe    | Deskripsi                 |
|-------------|---------|---------------------------|
| id          | INTEGER | Primary key, auto increment|
| user_id     | INTEGER | Foreign key ke users      |
| type        | TEXT    | 'income' atau 'expense'   |
| amount      | REAL    | Jumlah uang               |
| category    | TEXT    | Kategori transaksi        |
| description | TEXT    | Deskripsi transaksi       |
| image_path  | TEXT    | Path foto (nullable)      |
| date        | TEXT    | Tanggal transaksi         |
| created_at  | TEXT    | Timestamp pembuatan       |

## 📦 Dependencies

```yaml
dependencies:
  sqflite: ^2.3.0              # Database SQLite
  path_provider: ^2.1.1        # Akses direktori lokal
  shared_preferences: ^2.2.2   # Penyimpanan session
  image_picker: ^1.0.5         # Ambil foto dari kamera/galeri
  crypto: ^3.0.3               # Hashing password
  intl: ^0.19.0                # Format tanggal dan mata uang
```

## 🚀 Cara Menjalankan

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

## 📱 Cara Penggunaan

1. **Register**: Buat akun baru dengan username, email, dan password
2. **Login**: Masuk menggunakan email dan password
3. **Dashboard**: Lihat ringkasan keuangan Anda
4. **Tambah Transaksi**: 
   - Klik tombol "Pemasukan" atau "Pengeluaran"
   - Isi jumlah, kategori, tanggal, dan deskripsi
   - (Opsional) Tambahkan foto dari kamera atau galeri
   - Klik "Simpan"
5. **Lihat Riwayat**: Klik "Lihat Semua" untuk melihat semua transaksi
6. **Detail Transaksi**: Tap pada transaksi untuk melihat detail dan menghapus
7. **Filter**: Gunakan chip filter untuk melihat semua/pemasukan/pengeluaran saja

## 🔒 Keamanan

- Password di-hash menggunakan **SHA256** sebelum disimpan
- Data disimpan secara lokal di device pengguna
- Session management menggunakan SharedPreferences

## 🎨 Kategori Default

**Pemasukan:**
- Gaji
- Bonus
- Investasi
- Hadiah
- Penjualan
- Lainnya

**Pengeluaran:**
- Makanan
- Transport
- Belanja
- Hiburan
- Tagihan
- Kesehatan
- Pendidikan
- Lainnya

## 📝 Catatan

- Aplikasi ini sepenuhnya **offline**, tidak memerlukan koneksi internet
- Foto disimpan di direktori aplikasi lokal
- Data tidak akan hilang selama aplikasi tidak di-uninstall
- Pastikan memberikan permission untuk kamera dan galeri saat diminta

## 🛠️ Pengembangan Selanjutnya

Beberapa fitur yang bisa ditambahkan:
- [ ] Export data ke PDF/Excel
- [ ] Grafik statistik keuangan
- [ ] Budget planning
- [ ] Reminder untuk tagihan rutin
- [ ] Multi-currency support
- [ ] Backup & restore data
- [ ] Dark mode
- [ ] Fingerprint/Face ID login

## 📄 License

MIT License - bebas digunakan untuk pembelajaran dan pengembangan pribadi.
