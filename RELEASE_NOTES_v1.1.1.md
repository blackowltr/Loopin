## Loopin v1.1.1 — Güvenlik & İzin Mekanizması Düzeltmesi (Patch)

> macOS Erişilebilirlik izni kilitlenmesi ve TCC kimlik eşleşmesi düzeltmesi.  
> *Critical Patch: Fixed TCC accessibility permission refresh loop, added persistent designated requirement, and introduced one-click restart/bypass controls.*

---

### 🇹🇷 Yapılan Düzeltmeler (Bug Fixes & Optimization)

1. **Sabit Kod İmzası Tanımlayıcısı (Designated Requirement):**
   - Önceden ad-hoc imza rastgele `cdhash` ürettiği için macOS TCC her yeni derlemede izni sıfırlıyordu.
   - Artık kod imzası kalıcı olarak `identifier "com.blackowl.Loopin"` gereksinimiyle imzalanmaktadır. Bu sayede Sistem Ayarlarında verilen izinler tüm sürümler boyunca kalıcı olur.
2. **Kilitlenmeyi Önleyen Alternatif Butonlar:**
   - **"İzni Verdim, Giriş Yap" Butonu:** macOS arka planda izni onaylamakta gecikse bile kullanıcının sihirbaza hapsolmasını engeller ve doğrudan uygulamaya geçiş sağlar.
   - **"Uygulamayı Yeniden Başlat" Butonu:** macOS'in çalışan uygulamalarda TCC yetkisini hemen tanıması için uygulamayı tek tıkla kapatıp anında yeniden başlatır.
   - **"Şimdilik Atla":** Dileyen kullanıcının kurulum ekranını geçebilmesini sağlar.
3. **Akıllı Erişim Denetimi:**
   - İzin API'si henüz senkronize olmasa bile kullanıcının onayladığı durumlarda tıklama eylemlerinin çalışmasına izin verilir.

---

### 📦 İndirme & Kurulum

#### SHA-256 Doğrulama (Checksums)
```text
c8fda7ffbce6dea0511c477ee64c4dd6c357a20d00d538c6db90c15ac5c30ee1  Loopin-v1.1.1-macOS-arm64.dmg
df466648c542f352842ed1c587992dac13af86bae3a4ce3c0208e765ddc27c6c  Loopin-v1.1.1-macOS-arm64.zip
```
