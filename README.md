<div align="center">

# 📊 Queueease

**A comprehensive Queue Management System built with Flutter**

[![GitHub stars](https://img.shields.io/github/stars/Abhiii8/Queueease?style=for-the-badge&color=ffd700)](https://github.com/Abhiii8/Queueease/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Abhiii8/Queueease?style=for-the-badge&color=blue)](https://github.com/Abhiii8/Queueease/network)
[![GitHub issues](https://img.shields.io/github/issues/Abhiii8/Queueease?style=for-the-badge&color=red)](https://github.com/Abhiii8/Queueease/issues)
[![License](https://img.shields.io/github/license/Abhiii8/Queueease?style=for-the-badge)](https://github.com/Abhiii8/Queueease/blob/main/LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)

</div>

<br/>

<div align="center">
  <img src="https://github-readme-stats.vercel.app/api/pin/?username=Abhiii8&repo=Queueease&theme=radical" alt="Queueease Repo Card" />
</div>

<br/>

Queueease streamlines the queueing experience for both businesses and customers, providing live tracking, QR code check-ins, and robust analytics in one modern, elegant platform.

---

## ✨ Features

- **Queue Booking & Live Tracking:** Users can book their spot in line and monitor their status in real-time, reducing physical wait times.
- **Organization Management:** Admins can create and manage multiple businesses or branches seamlessly.
- **Role-Based Dashboards:** Dedicated screens for Queue Admins, Counter Agents, and End Users.
- **QR Code Integration:** Quick check-in and verification using integrated QR code scanning (`mobile_scanner` & `qr_flutter`).
- **Analytics & Insights:** Visual dashboards for organizations to track queue metrics and performance (`fl_chart`).
- **Audio Notifications:** Alerts for queue updates and counter calls (`audioplayers`).
- **State Management & Routing:** Built with robust architecture using Riverpod (`flutter_riverpod`) for state management and GoRouter (`go_router`) for navigation.

## 📈 Project Statistics

<div align="center">
  <img src="https://github-readme-stats.vercel.app/api?username=Abhiii8&repo=Queueease&show_icons=true&theme=radical" alt="GitHub stats" />
  <img src="https://github-readme-stats.vercel.app/api/top-langs/?username=Abhiii8&layout=compact&theme=radical&repo=Queueease" alt="Top Languages" />
</div>

## 🚀 Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version >=3.10.7)
- Dart SDK
- Android Studio / Xcode for emulators

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Abhiii8/Queueease.git
   cd Queueease
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🛠 Built With

- [Flutter](https://flutter.dev/) - The UI toolkit used
- [Riverpod](https://riverpod.dev/) - Reactive caching and data-binding framework
- [GoRouter](https://pub.dev/packages/go_router) - Declarative routing package
- [FlChart](https://pub.dev/packages/fl_chart) - Highly customizable Flutter chart library

## 📁 Project Structure

The project follows a feature-first architecture to maintain clean separation of concerns:
```text
lib/
├── core/           # Core configurations (Network, Theme, Constants)
├── features/       # Feature modules
│   ├── analytics/      # Analytics and charts
│   ├── auth/           # Authentication and authorization
│   ├── main/           # Main layout and navigation shell
│   ├── organization/   # Organization and admin dashboards
│   ├── profile/        # User profile settings
│   └── queue/          # Booking and live queue tracking
└── main.dart       # Application entry point
```

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📬 Contact

Project Link: [https://github.com/Abhiii8/Queueease](https://github.com/Abhiii8/Queueease)
