# cpanel-wp-cron-add

Bash script สำหรับเปลี่ยน WordPress virtual cron (wp-cron.php) เป็น system cron job จริงบนเซิร์ฟเวอร์ cPanel/WHM

หา document root อัตโนมัติ, สุ่มเวลา cron, ปิด wp-cron ใน wp-config.php และสร้าง cron job ใน cPanel ให้ทั้งหมด
## ติดตั้ง

```bash
bash <(curl -sL https://raw.githubusercontent.com/AnonymousVS/cpanel-wp-cron-add/main/add-wp-cron.sh) domain.com
```

## ปัญหา

WordPress รัน `wp-cron.php` ทุกครั้งที่มีคนเข้าเว็บ ทำให้:
- เซิร์ฟเวอร์ load สูง โดยเฉพาะเว็บที่มี traffic เยอะ
- เป็นช่องทางโจมตี DDoS ผ่าน `wp-cron.php`
- เว็บ traffic ต่ำอาจพลาด scheduled task เพราะไม่มีคนเข้า

## วิธีแก้

Script นี้ปิด virtual wp-cron แล้วสร้าง system cron job จริงแทน รันทุก 30 นาที ด้วยเวลาที่สุ่มไม่ซ้ำกัน

## คุณสมบัติ

- หา cPanel user และ document root จากชื่อ domain อัตโนมัติ
- รองรับทุกรูปแบบ path:
  - `/home/user/public_html/domain.com/`
  - `/home/user/domain.com/`
  - `/homeN/user/public_html/domain.com/`
- สุ่มเลขนาที (เช่น `7,37` หรือ `22,52`) กระจาย load ไม่ให้รันพร้อมกัน
- เพิ่ม `DISABLE_WP_CRON` ใน `wp-config.php` ให้อัตโนมัติ
- ข้าม domain ที่มี cron job อยู่แล้ว
- ตรวจสอบว่ามี WordPress ติดตั้งจริงก่อนทำ
- รองรับทำหลายเว็บพร้อมกันผ่านไฟล์ domain list

## ความต้องการ

- เซิร์ฟเวอร์ cPanel/WHM พร้อม root access
- เว็บไซต์ WordPress ที่จัดการผ่าน cPanel


## วิธีใช้

### ทำทีละเว็บ

```bash
bash add-wp-cron.sh domain.com
```

ตัวอย่างผลลัพธ์:

```
[INFO] Domain      : domain.com
[INFO] cPanel User : cpaneluser
[INFO] Document Root: /home/cpaneluser/public_html/domain.com
[INFO] Cron Schedule: 7,37 * * * * (ทุก 30 นาที)
[OK] เพิ่ม DISABLE_WP_CRON ใน wp-config.php แล้ว
[OK] เพิ่ม cron job สำเร็จ!
```

### ทำหลายเว็บพร้อมกัน

สร้างไฟล์ใส่ domain ทีละบรรทัด:

```bash
nano domains.txt
```

```
site1.com
site2.org
site3.net
```

รัน:

```bash
bash bulk-add-wp-cron.sh domains.txt
```

### ตรวจสอบผลลัพธ์

```bash
# ดู cron jobs ของ user
crontab -u cpaneluser -l

# เช็ค wp-config.php
grep DISABLE_WP_CRON /home/cpaneluser/public_html/domain.com/wp-config.php
```

## Script ทำอะไรบ้าง

1. **หา path** — อ่าน `/etc/userdatadomains` เพื่อหา cPanel user และ document root ของ domain
2. **ตรวจสอบ WordPress** — เช็คว่ามี `wp-cron.php` และ `wp-config.php` อยู่จริง
3. **สุ่มเวลา** — สุ่มเลขนาที (เช่น `14,44`) ห่างกัน 30 นาที
4. **ปิด virtual cron** — เพิ่ม `define('DISABLE_WP_CRON', true);` ใน `wp-config.php`
5. **สร้าง system cron** — เพิ่ม cron job ใน crontab ของ cPanel user

## รูปแบบ cron job ที่สร้าง

```
14,44 * * * * cd /home/user/public_html/domain.com && /usr/local/bin/php /home/user/public_html/domain.com/wp-cron.php
```

รัน wp-cron.php 2 ครั้งต่อชั่วโมง (ทุก 30 นาที) ผ่าน system cron แทน WordPress virtual cron

## สภาพแวดล้อมที่ทดสอบ

- AlmaLinux 9 / cPanel & WHM
- LiteSpeed Enterprise
- ทดสอบกับเว็บ WordPress แบบ single-page landing page 4,000+ เว็บ

## License

MIT

## ผู้พัฒนา

[AnonymousVS](https://github.com/AnonymousVS)
