#!/data/data/com.termux/files/usr/bin/bash

clear
echo "=================================================="
echo "        LIVEGO DEEP TV DEBUG ENGINE"
echo "=================================================="
echo ""

echo "[1/10] Scan FocusNode berbahaya..."
echo "--------------------------------------------------"

grep -Rn "FocusNode()" lib/ui/tv/

echo ""
echo "[2/10] Scan requestFocus inline..."
echo "--------------------------------------------------"

grep -Rn "requestFocus" lib/ui/tv/

echo ""
echo "[3/10] Scan setState + fetch bersamaan..."
echo "--------------------------------------------------"

grep -Rn "fetch(forceRefresh" lib/ui/tv/

echo ""
echo "[4/10] Scan rebuild berat..."
echo "--------------------------------------------------"

grep -Rn "setState(()" lib/ui/tv/

echo ""
echo "[5/10] Scan TVButton usage..."
echo "--------------------------------------------------"

grep -Rc "TVButton(" lib/ui/tv/*

echo ""
echo "[6/10] Scan KeyboardListener..."
echo "--------------------------------------------------"

grep -Rn "KeyboardListener" lib/ui/tv/

echo ""
echo "[7/10] Scan FocusScope..."
echo "--------------------------------------------------"

grep -Rn "FocusScope" lib/ui/tv/

echo ""
echo "[8/10] Scan FocusTraversalGroup..."
echo "--------------------------------------------------"

grep -Rn "FocusTraversalGroup" lib/ui/tv/

echo ""
echo "[9/10] Scan potential async rebuild..."
echo "--------------------------------------------------"

grep -Rn "await ApiService.get" lib/ui/tv/

echo ""
echo "[10/10] Flutter analyze quick check..."
echo "--------------------------------------------------"

flutter analyze lib/ui/tv/ 2>/dev/null

echo ""
echo "=================================================="
echo "              DEBUG SELESAI"
echo "=================================================="

