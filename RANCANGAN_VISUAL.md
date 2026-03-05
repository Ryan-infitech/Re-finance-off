# RANCANGAN APLIKASI PENCATATAN KEUANGAN

## 📱 FLOW APLIKASI

```
┌─────────────────┐
│  Splash Screen  │
│   (Check Auth)  │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Logged? │
    └─┬────┬──┘
      │    │
   NO │    │ YES
      │    │
  ┌───▼──┐ │
  │Login │ │
  └───┬──┘ │
      │    │
  ┌───▼──┐ │
  │Register│
  └───┬──┘ │
      │    │
      └────▼─────┐
      │  Home    │
      │Dashboard │
      └──┬───────┘
         │
    ┌────┴───────────┬──────────────┐
    │                │              │
┌───▼────┐    ┌─────▼──────┐  ┌───▼────┐
│  Add   │    │Transaction │  │Logout  │
│Income/ │    │   List     │  └────────┘
│Expense │    │  (Filter)  │
└────┬───┘    └─────┬──────┘
     │              │
     │         ┌────▼───────┐
     │         │Transaction │
     │         │   Detail   │
     │         └─────┬──────┘
     │               │
     └───────────────┴──► Delete/Back
```

## 🗂️ STRUKTUR DATA

### USER MODEL
```
User {
  - id: int
  - username: String
  - email: String
  - password: String (hashed)
  - created_at: DateTime
}
```

### TRANSACTION MODEL
```
Transaction {
  - id: int
  - user_id: int (FK)
  - type: String (income/expense)
  - amount: double
  - category: String
  - description: String
  - image_path: String? (optional)
  - date: DateTime
  - created_at: DateTime
}
```

## 🎨 TAMPILAN LAYAR

### 1. LOGIN SCREEN
```
┌─────────────────────────┐
│    [💰 Icon]            │
│                         │
│  Pencatatan Keuangan    │
│  Kelola keuangan...     │
│                         │
│  ┌───────────────────┐  │
│  │ Email             │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Password    [👁]  │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │      LOGIN        │  │
│  └───────────────────┘  │
│                         │
│  Belum punya akun?      │
│  [Daftar]               │
└─────────────────────────┘
```

### 2. REGISTER SCREEN
```
┌─────────────────────────┐
│  [←] Daftar             │
├─────────────────────────┤
│    [👤 Icon]            │
│  Buat Akun Baru         │
│                         │
│  ┌───────────────────┐  │
│  │ Nama Pengguna     │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Email             │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Password    [👁]  │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Konfirmasi  [👁]  │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │      DAFTAR       │  │
│  └───────────────────┘  │
│                         │
│  Sudah punya akun?      │
│  [Login]                │
└─────────────────────────┘
```

### 3. HOME/DASHBOARD SCREEN
```
┌─────────────────────────┐
│ Dashboard      [Logout] │
├─────────────────────────┤
│ Halo, Username!         │
│                         │
│ ┌─────────────────────┐ │
│ │ 💙 Saldo            │ │
│ │                     │ │
│ │ Rp 5.000.000        │ │
│ │                     │ │
│ │ ↓ Pemasukan         │ │
│ │   Rp 7.000.000      │ │
│ │                     │ │
│ │ ↑ Pengeluaran       │ │
│ │   Rp 2.000.000      │ │
│ └─────────────────────┘ │
│                         │
│ ┌──────────┬──────────┐ │
│ │ [+ Income]│[- Expense]│
│ └──────────┴──────────┘ │
│                         │
│ Transaksi Terakhir      │
│              [Lihat Semua]
│                         │
│ ┌─────────────────────┐ │
│ │ ↓ Gaji              │ │
│ │   Gaji bulan ini    │ │
│ │         Rp 5.000.000│ │
│ │         20 Nov 2025 │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │ ↑ Makanan           │ │
│ │   Makan siang       │ │
│ │           Rp 50.000 │ │
│ │         19 Nov 2025 │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

### 4. ADD TRANSACTION SCREEN
```
┌─────────────────────────┐
│ [←] Tambah Pemasukan    │
├─────────────────────────┤
│                         │
│  ┌───────────────────┐  │
│  │ Rp ___________    │  │
│  │ (Jumlah)          │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ [Gaji ▼]          │  │
│  │ (Kategori)        │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ 📅 03 Nov 2025    │  │
│  │ (Tanggal)         │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ _________________ │  │
│  │ _________________ │  │
│  │ (Deskripsi)       │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Foto (Opsional)   │  │
│  │                   │  │
│  │ [+ Tambah Foto]   │  │
│  │  atau             │  │
│  │ [📷 Preview]      │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │      SIMPAN       │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

### 5. TRANSACTION LIST SCREEN
```
┌─────────────────────────┐
│ [←] Riwayat Transaksi   │
├─────────────────────────┤
│                         │
│ [Semua][Pemasukan][Pengeluaran]
│                         │
│ ┌─────────────────────┐ │
│ │ ↓ Gaji              │ │
│ │   Gaji bulan ini    │ │
│ │   20 Nov 2025       │ │
│ │         Rp 5.000.000│ │
│ │                  📷 │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │ ↑ Makanan           │ │
│ │   Makan siang       │ │
│ │   19 Nov 2025       │ │
│ │           Rp 50.000 │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │ ↓ Bonus             │ │
│ │   Bonus kinerja     │ │
│ │   18 Nov 2025       │ │
│ │         Rp 1.000.000│ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

### 6. TRANSACTION DETAIL (Modal)
```
┌─────────────────────────┐
│ Detail Transaksi    [X] │
├─────────────────────────┤
│                         │
│ ↓ Pemasukan             │
│                         │
│ Jumlah                  │
│ Rp 5.000.000            │
│                         │
│ Kategori                │
│ Gaji                    │
│                         │
│ Tanggal                 │
│ Senin, 20 November 2025 │
│                         │
│ Deskripsi               │
│ Gaji bulan November     │
│                         │
│ Foto                    │
│ ┌─────────────────────┐ │
│ │                     │ │
│ │   [Image Preview]   │ │
│ │                     │ │
│ └─────────────────────┘ │
│                         │
│ ┌───────────────────┐   │
│ │ 🗑️ Hapus Transaksi │   │
│ └───────────────────┘   │
└─────────────────────────┘
```

## 🔄 ALUR KERJA

### A. REGISTER & LOGIN
1. User membuka app → Splash Screen
2. Cek session di SharedPreferences
3. Jika belum login → Login Screen
4. User bisa pilih Daftar
5. Input data (username, email, password)
6. Password di-hash dengan SHA256
7. Simpan ke SQLite database
8. Session disimpan di SharedPreferences
9. Navigate ke Home Screen

### B. TAMBAH TRANSAKSI
1. User klik tombol Pemasukan/Pengeluaran
2. Form input terbuka
3. User isi:
   - Jumlah
   - Kategori (dropdown)
   - Tanggal (date picker)
   - Deskripsi (text area)
   - Foto (optional - camera/gallery)
4. Foto disimpan di app directory
5. Data transaksi disimpan ke SQLite
6. Kembali ke Home dengan refresh data

### C. LIHAT & HAPUS TRANSAKSI
1. User klik "Lihat Semua" atau item transaksi
2. Tampil list transaksi dengan filter
3. User tap transaksi → Detail modal
4. User bisa klik hapus
5. Konfirmasi hapus
6. Delete dari database + hapus foto
7. Refresh list

## 🔐 KEAMANAN

- Password: SHA256 hashing
- Session: SharedPreferences
- Data: SQLite (local device)
- Foto: App document directory
- No internet required (full offline)

## 📊 STATISTIK DASHBOARD

```
Saldo = Total Income - Total Expense

Query untuk mendapatkan:
- Total Income: SUM(amount) WHERE type='income'
- Total Expense: SUM(amount) WHERE type='expense'
- Balance: income - expense
- Recent Transactions: Latest 5 with ORDER BY date DESC
```

## 🎯 KATEGORI TRANSAKSI

### Income Categories:
- Gaji
- Bonus
- Investasi
- Hadiah
- Penjualan
- Lainnya

### Expense Categories:
- Makanan
- Transport
- Belanja
- Hiburan
- Tagihan
- Kesehatan
- Pendidikan
- Lainnya

## ✅ CHECKLIST IMPLEMENTASI

- [x] Setup project structure
- [x] Install dependencies
- [x] Create models (User, Transaction)
- [x] Setup SQLite database
- [x] Implement authentication service
- [x] Implement transaction service
- [x] Implement image service
- [x] Create Login screen
- [x] Create Register screen
- [x] Create Home/Dashboard screen
- [x] Create Add Transaction screen
- [x] Create Transaction List screen
- [x] Create Transaction Detail modal
- [x] Implement session management
- [x] Implement password hashing
- [x] Implement photo picker
- [x] Setup splash screen with auth check

## 🚀 CARA MENJALANKAN

```bash
# Install dependencies
flutter pub get

# Run aplikasi
flutter run

# Build APK (Android)
flutter build apk --release

# Build untuk iOS
flutter build ios --release
```

## 📱 TESTING FLOW

1. **First Time User**:
   - Open app → Login screen
   - Click Daftar → Register
   - Fill form → Submit
   - Auto login → Home screen

2. **Add Income**:
   - Click [+ Pemasukan]
   - Fill amount, category, date, description
   - Optional: Add photo
   - Save → See in dashboard

3. **Add Expense**:
   - Click [- Pengeluaran]
   - Fill form
   - Save → Balance updated

4. **View History**:
   - Click "Lihat Semua"
   - Use filters (All/Income/Expense)
   - Tap transaction for details
   - Delete if needed

5. **Logout**:
   - Click logout icon
   - Confirm → Back to login
