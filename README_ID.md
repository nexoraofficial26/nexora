# NEXORA V1 — Starter Flutter

Ini adalah **starter project** untuk membangun NEXORA, bukan APK yang sudah dikompilasi atau diuji pada perangkat.

## Fitur yang sudah disiapkan dalam source
- Registrasi email/password melalui Supabase Auth.
- Login dan logout.
- Profil otomatis dibuat oleh trigger database yang telah dipasang.
- Daftar pengguna.
- Membuat percakapan privat dan menambahkan kedua peserta.
- Mengirim pesan teks.
- Menerima pesan melalui Supabase Realtime.

Belum termasuk: unggah gambar, notifikasi push, voice/video call, pencarian kontak berdasarkan nomor telepon, dan pengujian keamanan multi-akun.

## Cara memasukkan ke GitHub dari Android
1. Buat repository GitHub bernama `nexora`.
2. Pilih **Add file → Upload files**.
3. Ekstrak ZIP ini di HP, lalu unggah isi folder `NEXORA` ke repository (termasuk folder `.github`).
4. Commit ke branch `main`.

## Tambahkan GitHub Actions Secrets
Repository → Settings → Secrets and variables → Actions → New repository secret.

Buat dua secret:
- `NEXORA_SUPABASE_URL` = `https://lpdjilckstwbsnitoidb.supabase.co`
- `NEXORA_SUPABASE_PUBLISHABLE_KEY` = publishable key project milikmu.

Publishable key boleh dipakai di aplikasi klien. Jangan pernah memasukkan secret key atau service_role key.

## Build APK
Buka tab **Actions**, pilih **Build NEXORA APK**, lalu tekan **Run workflow**.
Setelah proses hijau/berhasil:
1. Buka hasil workflow.
2. Cari bagian **Artifacts**.
3. Unduh `nexora-android-apk`.
4. Ekstrak ZIP artifact dan instal `app-release.apk`.

## Catatan database
Project ini mengasumsikan tabel `profiles`, `conversations`, `conversation_members`, `messages`, trigger `handle_new_user`, dan kebijakan RLS sudah dibuat seperti pada setup database percakapan.
Pastikan di Supabase → Authentication → Providers → Email, metode email/password aktif.
