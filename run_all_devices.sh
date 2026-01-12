#!/bin/bash

# Near - Run on All Devices
# Bu script 3 ayri terminal penceresinde uygulamayi calistirir

PROJECT_DIR="/Users/user/Desktop/near"

# macOS
osascript -e "tell application \"Terminal\" to do script \"cd $PROJECT_DIR && flutter run -d macos\""

# iPhone 15 Simulator
osascript -e "tell application \"Terminal\" to do script \"cd $PROJECT_DIR && flutter run -d A8DAFB08-4C0B-4EA7-A8C0-B4DF050726C9\""

# Android Fiziksel Cihaz
osascript -e "tell application \"Terminal\" to do script \"cd $PROJECT_DIR && flutter run -d 2502FRA65G\""

echo "✅ 3 terminal penceresi açıldı!"
echo "Her birinde uygulama build ediliyor..."
