#!/data/data/com.termux/files/usr/bin/bash

clear
echo "=================================================="
echo "       LIVEGO TV FIX PREPARATION ENGINE"
echo "=================================================="
echo ""

echo "[1/7] Backup file inti TV..."
echo "--------------------------------------------------"

mkdir -p backup_tv_fix

cp lib/ui/tv/tv_player.dart backup_tv_fix/tv_player.dart.bak
cp lib/ui/tv/tv_home.dart backup_tv_fix/tv_home.dart.bak
cp lib/widgets/tv_button.dart backup_tv_fix/tv_button.dart.bak

echo "[OK] Backup selesai"

echo ""
echo "[2/7] Validasi FocusNode inline..."
echo "--------------------------------------------------"

grep -n "FocusNode()..requestFocus()" lib/ui/tv/tv_player.dart

echo ""
echo "[3/7] Validasi fetch dalam setState..."
echo "--------------------------------------------------"

grep -n "fetch(forceRefresh: true)" lib/ui/tv/tv_home.dart

echo ""
echo "[4/7] Hitung total setState berat..."
echo "--------------------------------------------------"

TOTAL=$(grep -R "setState(" lib/ui/tv/ | wc -l)

echo "Total setState ditemukan: $TOTAL"

if [ "$TOTAL" -gt 20 ]; then
  echo "[WARNING] Rebuild Android TV cukup berat"
fi

echo ""
echo "[5/7] Validasi TVButton engine..."
echo "--------------------------------------------------"

grep -n "class TVButton" lib/widgets/tv_button.dart

echo ""
echo "[6/7] Validasi KeyboardListener..."
echo "--------------------------------------------------"

grep -n "KeyboardListener" lib/ui/tv/tv_player.dart

echo ""
echo "[7/7] Ringkasan persiapan..."
echo "--------------------------------------------------"

echo "File backup tersimpan di:"
echo "~/livego_ready/backup_tv_fix"

echo ""
echo "TARGET FIX:"
echo "- Persistent FocusNode"
echo "- Stabilize TV Remote"
echo "- Reduce rebuild"
echo "- Lock drawer focus"
echo "- Optimize TV traversal"

echo ""
echo "=================================================="
echo "      SISTEM SIAP UNTUK PATCH ENGINE TV"
echo "=================================================="

