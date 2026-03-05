<div align="right">

![Visitors](https://visitor-badge.laobi.icu/badge?page_id=Ryan-infitech.Refinance)

</div>

# Refinance#

<p align="center">
  <img src="assets/images/refinance.png" alt="Reinventory Logo" width="200" onerror="this.style.display='none'"/>
</p>

Aplikasi pencatatan keuangan berbasis Flutter yang berfungsi secara **offline** dengan fitur registrasi, login, dan manajemen transaksi pemasukan & pengeluaran..

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Fitur Utama

- 🔐 **Autentikasi**: Register dan Login dengan penyimpanan offline
- 💰 **Pencatatan Transaksi**: Catat income dan expense dengan mudah
- 📸 **Upload Foto**: Ambil foto dari kamera atau galeri sebagai bukti transaksi
- 📊 **Dashboard**: Lihat ringkasan saldo, pemasukan, dan pengeluaran
- 📈 **Laporan Keuangan**: Recap bulanan atau custom date range dengan breakdown per kategori
- 📝 **Riwayat**: Lihat daftar transaksi dengan filter
- 🗑️ **Hapus Transaksi**: Kelola transaksi dengan mudah
- 📱 **Offline**: Semua data tersimpan lokal tanpa koneksi internet

## 🎯 Fitur Terbaru

### 📊 Laporan Keuangan (Report)
- Pilih periode bulanan atau custom date range
- Summary total income, expense, dan balance
- Breakdown per kategori dengan persentase dan progress bar
- Detail transaksi per periode
- Visual yang informatif dan mudah dipahami

### 🎨 Rebranding
- Nama aplikasi: **Refinance#**
- Splash screen dengan logo
- Consistent branding di semua screen

## 🚀 Quick Start

```bash
# Clone repository (jika dari git)
git clone <repository-url>

# Masuk ke folder project
cd aplikasi_pencatatan_keuangan

# Install dependencies
flutter pub get

# (Optional) Generate app icon jika logo sudah ada
flutter pub run flutter_launcher_icons

# Run aplikasi
flutter run

# Build APK untuk Android
flutter build apk --release
```

## 📱 Screenshot & Flow

### Flow Aplikasi:
```
Splash Screen → Login/Register → Dashboard → Add Transaction/View Report/Transaction List
```

### Fitur per Screen:
1. **Login**: Email & Password
2. **Register**: Username, Email, Password
3. **Dashboard**: Summary keuangan + quick actions
4. **Add Transaction**: Form dengan foto optional
5. **Transaction List**: Filter & detail transaksi
6. **Report**: Laporan periode dengan breakdown

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
│   ├── transaction_list_screen.dart   # Daftar transaksi
│   └── report_screen.dart        # Laporan keuangan (NEW!)
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

dev_dependencies:
  flutter_launcher_icons: ^0.13.1  # Generate app icon
```

## 🎨 Setup Logo & App Icon

### 1. Tambahkan Logo
Letakkan file `refinance.png` (1024x1024 px) di folder:
```
assets/images/refinance.png
```

### 2. Generate App Icon
```bash
flutter pub run flutter_launcher_icons
```

Logo akan digunakan di:
- Splash Screen (200x200)
- Login Screen (120x120)
- Register Screen (100x100)
- App Icon Android & iOS

**Note**: Jika logo tidak ada, aplikasi akan menggunakan icon wallet default.

## 📱 Cara Penggunaan

### 1. First Time Setup
1. **Register**: Buat akun baru dengan username, email, dan password
2. **Login**: Masuk menggunakan email dan password

### 2. Dashboard
- Lihat saldo, total income, dan total expense
- Quick action: Tambah Income atau Expense
- Lihat 5 transaksi terakhir
- Akses Laporan melalui icon 📊

### 3. Tambah Transaksi
1. Klik tombol "Pemasukan" atau "Pengeluaran"
2. Isi form:
   - Jumlah (Rp)
   - Kategori (dropdown)
   - Tanggal (date picker)
   - Deskripsi (text)
   - Foto optional (camera/gallery)
3. Klik "Simpan"

### 4. Lihat Laporan (NEW!)
1. Dari Dashboard, tap icon 📊 Laporan
2. Default: Laporan bulan berjalan
3. **Pilih Bulan**: Tap icon 📅 (calendar)
4. **Custom Range**: Tap icon 📆 (date range)
5. Lihat:
   - Summary Income, Expense, Balance
   - Breakdown per kategori dengan %
   - Detail semua transaksi periode

### 5. Riwayat Transaksi
1. Dari Dashboard, tap "Lihat Semua"
2. Filter: Semua / Pemasukan / Pengeluaran
3. Tap transaksi untuk lihat detail
4. Hapus transaksi jika diperlukan

## 🔒 Keamanan

- ✅ Password di-hash menggunakan **SHA256**
- ✅ Data disimpan secara lokal di device
- ✅ Session management dengan SharedPreferences
- ✅ Tidak memerlukan koneksi internet
- ✅ Privacy terjaga (no cloud sync)

## 🎨 Kategori Default

### Pemasukan:
- Gaji, Bonus, Investasi, Hadiah, Penjualan, Lainnya

### Pengeluaran:
- Makanan, Transport, Belanja, Hiburan, Tagihan, Kesehatan, Pendidikan, Lainnya

## 📊 Report Features

### Date Selection:
- **Monthly Report**: Pilih bulan & tahun
- **Custom Range**: Pilih start & end date

### Summary Cards:
- 💚 Total Pemasukan
- ❤️ Total Pengeluaran  
- 💙 Saldo Periode

### Category Breakdown:
- Progress bar per kategori
- Persentase kontribusi
- Visual color-coded (hijau/merah)

### Transaction Details:
- List lengkap transaksi
- Icon & badge untuk foto
- Tap untuk detail lengkap

## 🛠️ Pengembangan

### Tech Stack:
- **Framework**: Flutter 3.x
- **Language**: Dart
- **Database**: SQLite (sqflite)
- **State Management**: StatefulWidget
- **Local Storage**: SharedPreferences
- **Image Handling**: image_picker

### Architecture:
```
Models ← Services ← Screens
   ↓        ↓         ↓
Database Helper  Auth/Trans/Image Services
```

## 📝 Catatan Penting

1. ✅ Aplikasi **100% offline** - tidak perlu internet
2. ✅ Foto disimpan di app document directory
3. ✅ Data tidak hilang selama app tidak di-uninstall
4. ⚠️ Backup manual dengan export (fitur bisa ditambahkan)
5. ⚠️ Logo `refinance.png` perlu ditambahkan manual

## 🔮 Roadmap & Future Features

Fitur yang bisa ditambahkan:
- [ ] Export report ke PDF/Excel
- [ ] Grafik pie chart & line chart
- [ ] Budget planning & alerts
- [ ] Reminder untuk tagihan rutin
- [ ] Multi-currency support
- [ ] Backup & restore ke cloud
- [ ] Dark mode
- [ ] Biometric login (fingerprint/face)
- [ ] Widget untuk quick add
- [ ] Recurring transactions

## 🐛 Troubleshooting

### Error: Logo tidak muncul
- Pastikan file `refinance.png` ada di `assets/images/`
- Run `flutter clean` kemudian `flutter pub get`
- Restart aplikasi

### Error: Database tidak terbaca
- Uninstall dan install ulang aplikasi
- Data akan hilang (expected behavior untuk reset)

### Error: Permission camera/gallery
- Enable permission di Settings → Apps → Refinance# → Permissions

## 📄 License

MIT License - Bebas digunakan untuk pembelajaran dan pengembangan.

## 👨‍💻 Developer

Dikembangkan dengan ❤️ menggunakan Flutter

---

## 📚 Dokumentasi Lengkap

- [DOKUMENTASI.md](DOKUMENTASI.md) - Dokumentasi detail aplikasi
- [RANCANGAN_VISUAL.md](RANCANGAN_VISUAL.md) - Flow & wireframe
- [UPDATE_FITUR.md](UPDATE_FITUR.md) - Changelog & fitur baru

---

**Refinance#** - Kelola Keuangan Lebih Mudah 💰
