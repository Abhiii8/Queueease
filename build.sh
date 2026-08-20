#!/bin/bash
# Clone the Flutter stable branch
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to the PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build the web application
flutter build web --release
