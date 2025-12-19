# Quick Start Guide

## 🚀 Running the App

1. Open Xcode
2. Open the `frontend/KidzoneApp.xcodeproj`
3. Select a simulator or device
4. Press `Cmd + R` to run

## 🎯 Testing the Flow

### Child Flow:
1. Tap "Get Started" on welcome screen
2. Choose an OAuth provider (currently mocked)
3. Select "I'm a Kid"
4. Enter parent code: `ABC123` (or any 6-8 character code)
5. See welcome animation
6. Explore the child dashboard

### Parent Flow:
1. Tap "Get Started" on welcome screen
2. Choose an OAuth provider
3. Select "I'm a Parent"
4. See parent dashboard

## 📱 Key Features

### Child Views:
- **Dashboard** - Credit score, wallet, quick actions
- **Chores** - View and complete chores
- **Cards** - Credit cards with swipeable carousel
- **Shop** - Marketplace with purchase flow
- **Profile** - Stats, achievements, settings

### Parent Views:
- **Dashboard** - Family overview, pending approvals
- **Chores** - Create and manage chores
- **Approvals** - Approve/reject completed chores
- **Settings** - Configure rules and limits

## 🎨 Design Highlights

- **Kid-Friendly Colors**: Bright blues, pinks, purples
- **Smooth Animations**: Bounce effects, transitions
- **Large Touch Targets**: Easy for small hands
- **Clear Visual Hierarchy**: Important info stands out
- **Positive Feedback**: Encouraging messages throughout

## 🔧 Customization

### Change Colors:
Edit `frontend/KidzoneApp/Theme/AppTheme.swift`

### Modify Mock Data:
Edit `frontend/KidzoneApp/Models/AppState.swift` (mock property)

### Add New Views:
Follow the structure in `frontend/KidzoneApp/Views/`

## 📝 Next Steps

1. **Integrate Real OAuth**:
   - Add Google Sign-In SDK
   - Add Microsoft Authentication Library
   - Add Facebook Login SDK
   - Update `AuthenticationManager.swift`

2. **Connect Backend**:
   - Replace mock data in `AppStateViewModel`
   - Implement API calls in `APIService`
   - Add token storage (Keychain)

3. **Add Features**:
   - Paper Trading screen
   - Device time controls
   - Push notifications
   - Onboarding tutorial

## 🐛 Known Limitations

- OAuth providers are currently mocked
- All data is local/mock data
- No backend connection yet
- Device time controls not implemented

## 💡 Tips

- Use the Tab Bar to navigate between main sections
- Swipe cards in the Credit Cards view
- Tap chore cards for details and completion
- Use the shop to purchase rewards
