#!/data/data/com.termux/files/usr/bin/bash

clear
echo "========================================"
echo "   LIVEGO TV ENGINE ANALYZER V2"
echo "========================================"
echo ""

ERROR_FOUND=0

echo "[1/8] Cek struktur file TV..."
echo "----------------------------------------"

FILES=(
"lib/ui/tv/tv_home.dart"
"lib/ui/tv/tv_player.dart"
"lib/widgets/tv_button.dart"
)

for file in "${FILES[@]}"
do
  if [ -f "$file" ]; then
    echo "[OK] $file"
  else
    echo "[ERROR] File hilang -> $file"
    ERROR_FOUND=1
  fi
done

echo ""
echo "[2/8] Analisis FocusNode rebuild..."
echo "----------------------------------------"

grep -R "FocusNode()..requestFocus()" lib/ui/tv/ >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[WARNING] FocusNode dibuat langsung di widget tree"
  echo "          Ini penyebab remote Android TV tidak stabil"
  ERROR_FOUND=1
else
  echo "[OK] Tidak ada FocusNode inline berbahaya"
fi

echo ""
echo "[3/8] Analisis KeyboardListener..."
echo "----------------------------------------"

grep -R "KeyboardListener" lib/ui/tv/ >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[OK] KeyboardListener ditemukan"
else
  echo "[ERROR] KeyboardListener tidak ditemukan"
  ERROR_FOUND=1
fi

echo ""
echo "[4/8] Analisis TVButton engine..."
echo "----------------------------------------"

grep -R "TVButton(" lib/ui/tv/ >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[OK] TVButton digunakan"
else
  echo "[ERROR] TVButton tidak dipakai"
  ERROR_FOUND=1
fi

if [ -f "lib/widgets/tv_button.dart" ]; then

  grep "Focus(" lib/widgets/tv_button.dart >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "[OK] Focus engine ditemukan di TVButton"
  else
    echo "[WARNING] TVButton belum memiliki Focus widget"
    ERROR_FOUND=1
  fi

else
  echo "[ERROR] tv_button.dart tidak ada"
  ERROR_FOUND=1
fi

echo ""
echo "[5/8] Analisis drawer episode..."
echo "----------------------------------------"

grep "_showEpisodeSidebar" lib/ui/tv/tv_player.dart >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[OK] Episode sidebar terdeteksi"
else
  echo "[ERROR] Sidebar episode tidak ditemukan"
  ERROR_FOUND=1
fi

echo ""
echo "[6/8] Analisis FocusScope..."
echo "----------------------------------------"

grep "FocusScope" lib/ui/tv/tv_player.dart >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[OK] FocusScope ditemukan"
else
  echo "[WARNING] FocusScope tidak ditemukan"
  ERROR_FOUND=1
fi

echo ""
echo "[7/8] Analisis potensi rebuild berat..."
echo "----------------------------------------"

grep "setState(() { selS = p; fetch(forceRefresh: true); });" lib/ui/tv/tv_home.dart >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[WARNING] fetch() dipanggil di dalam setState"
  echo "          Bisa memicu rebuild focus Android TV"
  ERROR_FOUND=1
else
  echo "[OK] Tidak ditemukan fetch berat dalam setState"
fi

echo ""
echo "[8/8] Ringkasan hasil..."
echo "----------------------------------------"

if [ $ERROR_FOUND -eq 0 ]; then
  echo "[SUCCESS] Tidak ditemukan masalah besar"
else
  echo "[ATTENTION] Ditemukan potensi error engine TV"
fi

echo ""
echo "========================================"
echo " ANALISIS SELESAI"
echo "========================================"

