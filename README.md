# Kidzone Financial Platform - iOS App 🚀

A kid-friendly financial education app built with SwiftUI for ages 7-13. Learn about money, credit, and responsibility while earning screen time!

## 🎨 Design Philosophy

The app is designed with **ages 7-13 in mind**, featuring:
- **Bright, energetic colors** - Blues, purples, pinks, yellows
- **Playful animations** - Bounce effects, smooth transitions
- **Gamification** - Badges, achievements, progress tracking
- **Clear visual hierarchy** - Large fonts, simple layouts
- **Positive reinforcement** - Encouraging messages and rewards

## 📁 Project Structure

```
frontend/                      # iOS app
└── KidzoneApp/
    ├── KidzoneApp.swift       # App entry point
    ├── Models/                # User, AppState, domain models
    ├── Services/              # Auth/API clients
    ├── ViewModels/            # State management
    ├── Views/                 # Auth, Child, Parent, Root views
    ├── Components/            # Shared UI components
    └── Theme/                 # Colors, gradients, typography

backend/                       # Backend/BFF (placeholder)
```

## 🚀 Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 15.0+ deployment target
- Swift 5.7+

### Running the App

1. Open `frontend/KidzoneApp.xcodeproj` in Xcode
2. Select a simulator (iPhone 14 or later)
3. Press **⌘ + R** to build and run

## 🎯 Key Features

### For Children (Ages 7-13)
- **Dashboard** - Credit score, wallet balance, quick actions
- **Chores** - Complete tasks to earn rewards
- **Credit Cards** - Apply for and manage credit cards
- **Marketplace** - Shop for rewards (device hours, physical items)
- **Profile** - View stats, achievements, and progress

### For Parents
- **Dashboard** - Monitor family financial progress
- **Chores** - Create and assign chores
- **Approvals** - Approve/reject completed chores and purchases
- **Settings** - Configure rules, tax rates, and limits

## 🔐 Authentication Flow

1. Welcome screen with animated logo
2. OAuth sign-in (Google, Microsoft, Facebook) - *currently mocked*
3. Role selection (Parent/Child)
4. Parent code entry (for children)
5. Welcome animation (for children)
6. Main app interface

## 🎨 Theme System

The app uses a kid-friendly color palette defined in `AppTheme.swift`:
- **Primary**: `kidzoneBlue`, `kidzonePurple`, `kidzonePink`
- **Accents**: `kidzoneGreen`, `kidzoneOrange`, `kidzoneYellow`
- **Status**: `kidzoneSuccess`, `kidzoneWarning`, `kidzoneDanger`

## 🔌 Backend Integration Ready

The app structure is designed for easy backend integration:
- `APIService.swift` - Ready for HTTP requests
- `AuthenticationManager` - Token storage ready
- `ViewModels` - Centralized state management
- All models are `Codable` for JSON parsing

## 📝 Current Status

### ✅ Completed
- Full UI implementation for child and parent views
- Authentication flow (mocked OAuth)
- Role-based navigation
- Kid-friendly design system
- All core features implemented

### 🚧 In Progress / TODO
- [ ] Integrate real OAuth providers (Google, Microsoft, Facebook)
- [ ] Connect to backend API
- [ ] Implement Paper Trading feature
- [ ] Add device time controls
- [ ] Push notifications
- [ ] Onboarding tutorial

## 🛠️ Development

### Building
```bash
xcodebuild -project frontend/KidzoneApp.xcodeproj -scheme KidzoneApp -sdk iphonesimulator build
```

### Code Style
- SwiftUI views organized by feature
- Models use `Codable` for API compatibility
- Services handle network and authentication
- ViewModels manage state
- Shared components in `Components/` folder

## 📄 License

ISC

## 🤝 Contributing

This is a private project. For questions or contributions, please contact the development team.
