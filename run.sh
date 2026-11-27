#!/usr/bin/env bash
# Menjalankan aplikasi di Chrome sebagai user saat ini.
# Jika masih ada file milik user lain (sisa setup sebelumnya), skrip ini
# mengambil alih kepemilikan folder proyek sekali saja lewat sudo.
set -euo pipefail

cd "$(dirname "$0")"

if find . -maxdepth 2 ! -user "$(id -un)" -print -quit | grep -q .; then
  echo "Ada file milik user lain. Memperbaiki kepemilikan folder proyek (sudo sekali)..."
  sudo chown -R "$(id -u):$(id -g)" .
fi

flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json
