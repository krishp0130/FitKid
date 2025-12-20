# FitKid Setup Guide

Complete setup instructions for the FitKid financial education app.

## 📋 Prerequisites

- **macOS** with Xcode 15+
- **Node.js** 18+ and npm
- **Redis** (for caching)
- **Supabase** account
- **Google Cloud** account (for Google Sign-In)
- **Apple Developer** account (for Apple Sign-In)

## 🚀 Quick Start

### 1. Backend Setup

#### Install Dependencies
```bash
cd backend
npm install
```

#### Configure Environment Variables
```bash
# Copy the template
cp .env.template .env

# Edit .env with your credentials
nano .env
```

Required environment variables:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
PORT=3000
REDIS_URL=redis://localhost:6379  # Optional, defaults to localhost
```

#### Get Supabase Credentials
1. Go to https://app.supabase.com/
2. Select your project
3. Navigate to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY`

#### Install and Start Redis
```bash
# macOS (via Homebrew)
brew install redis
brew services start redis

# Verify Redis is running
redis-cli PING  # Should return PONG
```

#### Start Backend Server
```bash
npm run dev
```

You should see:
```
✅ Redis connected successfully
✅ Server listening at http://0.0.0.0:3000
```

### 2. Supabase Authentication Setup

#### Enable Google OAuth
1. Go to Supabase Dashboard → **Authentication** → **Providers**
2. Find **Google** and click to configure
3. Toggle **Enable Google provider** ON
4. Enter your Google OAuth credentials:
   - **Client ID**: Get from Google Cloud Console
   - **Client Secret**: Get from Google Cloud Console

**Get Google OAuth Credentials:**
1. Go to https://console.cloud.google.com/
2. Create a new project or select existing
3. Navigate to **APIs & Services** → **Credentials**
4. Create **OAuth 2.0 Client ID**
5. Set authorized redirect URIs:
   ```
   https://your-project.supabase.co/auth/v1/callback
   ```
6. Copy Client ID and Client Secret to Supabase

#### Enable Apple Sign-In
1. Go to Supabase Dashboard → **Authentication** → **Providers**
2. Find **Apple** and click to configure
3. Toggle **Enable Apple provider** ON
4. Configure with your Apple Developer credentials:
   - **Services ID**
   - **Team ID**
   - **Key ID**
   - **Private Key**

**Get Apple Credentials:**
1. Go to https://developer.apple.com/
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create a **Services ID** for Sign in with Apple
4. Configure redirect URL:
   ```
   https://your-project.supabase.co/auth/v1/callback
   ```
5. Create a **Key** for Sign in with Apple
6. Note your Team ID from Account settings

### 3. iOS Frontend Setup

#### Install Dependencies
Open the project in Xcode:
```bash
cd frontend
open KidzoneApp.xcodeproj
```

Dependencies (managed via Swift Package Manager):
- GoogleSignIn-iOS
- Supabase-swift

#### Configure Google Sign-In
1. Add `GoogleService-Info.plist` to the Xcode project
2. Get this file from Firebase Console:
   - Go to https://console.firebase.google.com/
   - Select your project → Project Settings
   - Download `GoogleService-Info.plist`
3. Drag the file into Xcode (ensure "Copy items if needed" is checked)

#### Configure Apple Sign-In Capability
1. In Xcode, select the project target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Sign in with Apple**
5. Ensure your Apple Developer account is configured

#### Update Backend URL
If your backend is not on `localhost:3000`, update the API base URL:

In `frontend/KidzoneApp/Services/Auth/AuthAPI.swift`:
```swift
private let authBaseURLString = "http://YOUR_BACKEND_URL:3000"
```

#### Build and Run
1. Select a simulator (iPhone 16 or later recommended)
2. Press **⌘R** to build and run

## 🗄️ Database Setup

The database schema is automatically applied through Supabase migrations.

Key tables:
- `users` - User accounts (parent/child)
- `families` - Family groups
- `chores` - Tasks assigned to children
- `ledger_accounts` - Account balances
- `transactions` - Financial transactions
- `postings` - Double-entry bookkeeping

## 🔐 Authentication Flow

1. **Sign In/Sign Up** - Google, Apple, or Email/Password
2. **Onboarding** - Select role (Parent or Child)
3. **Family Setup**:
   - Parents: Create family and get family code
   - Children: Enter family code to join
4. **Main App** - Access features based on role

## 📱 Features

### Parent Features
- Dashboard with family overview
- Create and assign chores to children
- Approve/reject completed chores
- View wallet balances and transactions
- Configure family settings

### Child Features
- Dashboard with tasks and progress
- View and complete assigned chores
- Track wallet balance
- Browse marketplace items
- View credit score (gamified)

## ⚡ Redis Cache Layer

The app uses Redis for instant data access:
- **Family members**: Cached for 30s
- **Chores list**: Cached for 30s
- **Wallet balance**: Cached for 30s

Cache automatically invalidates when data changes.

See `REDIS_CACHE_SETUP.md` for detailed cache documentation.

## 🧪 Testing

### Test with Multiple Simulators
```bash
# Launch parent simulator
xcrun simctl boot "iPhone 16"
open -a Simulator

# Launch child simulator (in separate terminal)
xcrun simctl boot "iPhone 17"
open -a Simulator
```

### Test Flow
1. **Parent**: Sign up → Create family → Copy family code
2. **Child**: Sign up → Enter family code → Join family
3. **Parent**: Assign chore to child
4. **Child**: Complete chore → Submit for approval
5. **Parent**: Approve chore
6. **Child**: See updated wallet balance

## 🐛 Troubleshooting

### Backend won't start
- Check `.env` file exists and has correct credentials
- Verify Supabase credentials are valid
- Ensure Redis is running: `redis-cli PING`
- Check port 3000 is not in use: `lsof -ti :3000`

### Redis connection error
```bash
# Start Redis
brew services start redis

# Check status
brew services list | grep redis

# Test connection
redis-cli PING
```

### Google Sign-In not working
- Verify `GoogleService-Info.plist` is in Xcode project
- Check Google OAuth is enabled in Supabase
- Verify redirect URI is configured in Google Cloud Console
- Check backend logs for error details

### Apple Sign-In not working
- Verify "Sign in with Apple" capability is added in Xcode
- Check Apple provider is enabled in Supabase
- Ensure your Apple Developer account is active
- Check backend logs for error details

### Build errors in Xcode
```bash
# Clean build folder
⌘⇧K (Cmd + Shift + K)

# Reset package caches
File → Packages → Reset Package Caches

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 📚 Documentation

- `README.md` - Project overview
- `REDIS_CACHE_SETUP.md` - Cache layer documentation
- `backend/README.md` - Backend API documentation

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend logs: `tail -f /tmp/backend.log`
3. Check Redis logs: `tail -f /opt/homebrew/var/log/redis.log`
4. Verify Supabase dashboard for auth issues

## 🔄 Development Workflow

1. **Make changes** to backend or frontend
2. **Test locally** with simulators
3. **Commit changes**: `git add -A && git commit -m "Description"`
4. **Push to main**: `git push origin main`

## 🎯 Next Steps

After setup is complete:
- [ ] Create a parent account
- [ ] Create a child account
- [ ] Assign and complete a test chore
- [ ] Verify wallet balance updates
- [ ] Test tab switching (should be instant with cache)
- [ ] Explore marketplace and credit features

