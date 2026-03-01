<p align="center">
  <img src="close/Assets.xcassets/AppIcon.appiconset/ChatGPT Image Oct 13, 2025, 07_27_40 PM.png" alt="Close App Icon" width="120" height="120">
</p>

<h1 align="center">Close</h1>

<p align="center">A beautiful iOS app designed to help you maintain meaningful relationships by tracking when you last contacted your friends and family, and reminding you when it's time to reach out again.</p>

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-green.svg)

## 📱 Screenshots

<div align="center">
  <img src="screenshots/home dark.png" alt="Home - Dark Mode" width="300"/>
  <img src="screenshots/contact dark.png" alt="Contact View - Dark Mode" width="300"/>
</div>

## ✨ Features

### 🎯 Smart Contact Tracking

- **Automatic Reminders**: Never lose touch with important people in your life
- **Flexible Scheduling**: Set custom contact frequencies (daily, weekly, monthly, or custom intervals)
- **Visual Status Indicators**: Color-coded system shows when contacts are overdue, due soon, or on track
- **Smart Notifications**: Get notified when it's time to reach out, with quick action buttons

### 📞 Seamless Communication

- **Quick Actions**: Call or message contacts directly from the app
- **Notification Actions**: Respond to reminders without opening the app
- **Contact Integration**: Import contacts from your iPhone's address book
- **Profile Photos**: Automatic contact photos from your device

### 🎨 Beautiful Design

- **Modern UI**: Clean, intuitive interface built with SwiftUI
- **Dark Mode Support**: Seamlessly adapts to your system preference with beautiful light and dark themes
- **Smooth Animations**: Delightful interactions throughout the app
- **Accessibility**: Full VoiceOver support and accessibility features

### 🔧 Smart Features

- **Search**: Quickly find contacts by name
- **Swipe Actions**: Mark contacts as contacted with a simple swipe
- **Onboarding**: Guided setup for first-time users
- **Settings**: Customize your experience
- **Data Persistence**: Your contacts and settings are safely stored locally

## 🚀 Getting Started

### Requirements

- iOS 17.0 or later
- Xcode 15.0 or later (for development)
- Swift 5.9 or later

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/matjic/Close.git
   cd Close
   ```

2. **Open in Xcode**

   ```bash
   open close.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### First Launch

1. Grant contacts permission when prompted
2. Follow the onboarding flow
3. Add contacts from your address book
4. Set contact frequencies for each person
5. Start staying connected! 📱

## 🏗️ Architecture

### Core Components

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence and management
- **UserNotifications**: Smart reminder system
- **Contacts Framework**: Integration with iOS contacts

### Key Classes

- `Contact`: Core data model for contact information and scheduling
- `ContactScheduler`: Manages notification scheduling and contact timing
- `ContactsManager`: Handles iOS contacts integration and permissions
- `NotificationManager`: Manages local notifications and user interactions

### Data Flow

1. **Contact Import**: Users import contacts from their address book
2. **Scheduling**: App calculates next contact dates based on frequency settings
3. **Notifications**: System schedules local notifications for upcoming contacts
4. **User Actions**: Quick actions allow calling/messaging directly from notifications
5. **Updates**: Contact status updates trigger rescheduling

## 🎨 Design Philosophy

Close is built with the belief that technology should enhance human relationships, not replace them. The app uses:

- **Minimal Design**: Clean interface that doesn't distract from the core purpose
- **Intuitive Interactions**: Familiar iOS patterns and gestures
- **Emotional Design**: Color coding and visual cues that feel natural
- **Privacy First**: All data stays on your device

## 🔒 Privacy

- **Local Storage**: All contact data is stored locally on your device
- **No Cloud Sync**: Your personal information never leaves your iPhone
- **Minimal Permissions**: Only requests access to contacts when needed
- **Transparent**: Open source code means you can verify our privacy practices

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**

   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes**
4. **Test thoroughly**
5. **Submit a pull request**

### Development Guidelines

- Follow Swift style guidelines
- Write comprehensive tests
- Update documentation for new features
- Ensure accessibility compliance

## 📄 License

This project is licensed under the Apache License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI and SwiftData
- Inspired by the need to maintain meaningful relationships in our digital age
- Thanks to the iOS development community for inspiration and support

## 📞 Support

Having issues? Here's how to get help:

- **GitHub Issues**: Report bugs or request features
- **Documentation**: Check this README and code comments
- **Community**: Join discussions in GitHub Discussions

---

**Made with ❤️ for staying close to the people who matter most.**
