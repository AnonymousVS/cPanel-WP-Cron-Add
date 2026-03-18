#!/bin/bash
# =============================================================
# add-wp-cron.sh - สร้าง cron job สำหรับ wp-cron.php
# รองรับ cPanel multi-account environment
# Random เลข 2 หลักสำหรับ minute (ห่างกัน 30 นาที)
# =============================================================

# --- ตรวจสอบ argument ---
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 24noarbet.org"
    exit 1
fi

DOMAIN="$1"

# --- หา path จริงของ domain จาก cPanel ---
DOMAININFO=$(grep "^${DOMAIN}:" /etc/userdatadomains 2>/dev/null | head -1)

if [ -z "$DOMAININFO" ]; then
    echo "[ERROR] ไม่พบ domain: $DOMAIN ใน /etc/userdatadomains"
    exit 1
fi

# ดึง username และ document root
CPUSER=$(echo "$DOMAININFO" | awk -F'==' '{print $1}' | awk -F': ' '{print $2}')
DOCROOT=$(echo "$DOMAININFO" | awk -F'==' '{print $5}')

echo "[INFO] Domain   : $DOMAIN"
echo "[INFO] cPanel User : $CPUSER"
echo "[INFO] Document Root: $DOCROOT"

# --- ตรวจสอบว่ามี wp-cron.php อยู่จริง ---
if [ ! -f "${DOCROOT}/wp-cron.php" ]; then
    echo "[ERROR] ไม่พบ ${DOCROOT}/wp-cron.php"
    echo "        domain นี้อาจไม่ได้ติดตั้ง WordPress"
    exit 1
fi

# --- ตรวจสอบว่ามี wp-config.php อยู่จริง ---
if [ ! -f "${DOCROOT}/wp-config.php" ]; then
    echo "[ERROR] ไม่พบ ${DOCROOT}/wp-config.php"
    exit 1
fi

# --- Random เลข minute ตัวแรก (0-29) แล้วตัวที่ 2 บวก 30 ---
MIN1=$((RANDOM % 30))
MIN2=$((MIN1 + 30))

# Format ให้เป็น 2 หลัก (เช่น 04,34)
MIN1_FMT=$(printf "%d" $MIN1)
MIN2_FMT=$(printf "%d" $MIN2)

CRON_SCHEDULE="${MIN1_FMT},${MIN2_FMT} * * * *"
CRON_CMD="cd ${DOCROOT} && /usr/local/bin/php ${DOCROOT}/wp-cron.php"
CRON_LINE="${CRON_SCHEDULE} ${CRON_CMD}"

echo "[INFO] Cron Schedule: ${CRON_SCHEDULE} (ทุก 30 นาที)"

# --- เช็คว่ามี cron ของ domain นี้อยู่แล้วหรือไม่ ---
EXISTING=$(crontab -u "$CPUSER" -l 2>/dev/null | grep "$DOMAIN")
if [ -n "$EXISTING" ]; then
    echo "[WARN] มี cron job ของ $DOMAIN อยู่แล้ว:"
    echo "       $EXISTING"
    read -p "       ต้องการเพิ่มซ้ำไหม? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "[SKIP] ไม่ได้เพิ่ม cron job"
        exit 0
    fi
fi

# --- เพิ่ม DISABLE_WP_CRON ใน wp-config.php (ถ้ายังไม่มี) ---
if grep -q "DISABLE_WP_CRON" "${DOCROOT}/wp-config.php"; then
    echo "[INFO] wp-config.php มี DISABLE_WP_CRON อยู่แล้ว"
else
    # เพิ่มก่อนบรรทัด "That's all, stop editing"
    if grep -q "That's all" "${DOCROOT}/wp-config.php"; then
        sed -i "/That's all/i define('DISABLE_WP_CRON', true);" "${DOCROOT}/wp-config.php"
        echo "[OK] เพิ่ม DISABLE_WP_CRON ใน wp-config.php แล้ว"
    else
        # ถ้าไม่เจอ comment นั้น ให้เพิ่มต่อท้าย DB_COLLATE
        sed -i "/DB_COLLATE/a define('DISABLE_WP_CRON', true);" "${DOCROOT}/wp-config.php"
        echo "[OK] เพิ่ม DISABLE_WP_CRON ใน wp-config.php แล้ว (หลัง DB_COLLATE)"
    fi
fi

# --- เพิ่ม cron job ให้ user ---
(crontab -u "$CPUSER" -l 2>/dev/null; echo "$CRON_LINE") | crontab -u "$CPUSER" -
echo "[OK] เพิ่ม cron job สำเร็จ!"
echo ""
echo "=== สรุป ==="
echo "Domain    : $DOMAIN"
echo "User      : $CPUSER"
echo "Path      : $DOCROOT"
echo "Cron      : $CRON_LINE"
echo ""
echo "ตรวจสอบด้วย: crontab -u $CPUSER -l"
