# Authentication Fixes Summary

## 🚨 Current Issues

### 1. Google Sign-In: "App can only be used by people within its organization"
**Root Cause**: OAuth consent screen is set to "Internal" mode  
**Location**: Google Cloud Console  
**Fix Time**: 5-10 minutes + wait for propagation

### 2. Apple Sign-In: Error 1000 (AuthorizationError)
**Root Cause**: Sign in with Apple capability not enabled in Xcode  
**Location**: Xcode project settings  
**Fix Time**: 2-3 minutes

---

## ✅ Quick Fix Steps

### Google Sign-In (Do This First)

1. **Open Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select project with Client ID: `816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel`

2. **Change OAuth Consent Screen**
   - Navigate: **APIs & Services** > **OAuth consent screen**
   - Find **User Type** section (usually at the top)
   - Change from **Internal** → **Testing** (for development)

3. **Add Test Users** (if Testing mode)
   - Click **+ ADD USERS** button
   - Add your Google account email(s)
   - Click **SAVE**

4. **Wait and Test**
   - Wait 5-10 minutes for changes to propagate
   - Try signing in again

**For Production Later:**
- Change to **External** mode
- Complete OAuth consent screen verification process
- Google may require app verification for external apps

---

### Apple Sign-In (Do This Second)

1. **Open Xcode Project**
   - Open `frontend/KidzoneApp.xcodeproj`

2. **Add Sign in with Apple Capability**
   - Select **KidzoneApp** target (left sidebar)
   - Click **Signing & Capabilities** tab (top)
   - Click **+ Capability** button (top left)
   - Search: "Sign in with Apple"
   - Double-click to add it
   - Xcode will automatically create entitlements file

3. **Verify Bundle ID**
   - Check Bundle Identifier is: `com.kidzone.KidzoneApp`
   - This should match your Apple Developer account

4. **Sign Into Simulator** (for testing)
   - In iOS Simulator: **Settings** > **Sign in to your iPhone**
   - Use a test Apple ID if needed
   - This is required for Sign in with Apple to work

5. **Clean Build**
   - In Xcode: **Product** > **Clean Build Folder** (Shift+Cmd+K)
   - Then: **Product** > **Build** (Cmd+B)
   - Run app: **Product** > **Run** (Cmd+R)

---

## 🧪 Testing Checklist

After making both fixes:

- [ ] Google Sign-In prompts for account selection
- [ ] Google Sign-In allows selecting your test account
- [ ] Apple Sign-In shows the Sign in with Apple dialog
- [ ] Apple Sign-In completes successfully
- [ ] Both redirect back to app after authentication
- [ ] App proceeds to role selection screen

---

## 📝 Notes

### Google OAuth
- **Testing mode**: Only added test users can sign in (good for development)
- **External mode**: Anyone can sign in (requires app verification for production)
- Changes can take up to 10 minutes to propagate

### Apple Sign-In
- Requires Xcode capability to be enabled
- Works on simulators (need to be signed into iCloud)
- Bundle ID must match Apple Developer account configuration
- Error 1000 = capability not enabled or bundle ID mismatch

---

## 🆘 If Still Not Working

### Google:
- Double-check you're using the test user email you added
- Wait longer (up to 30 minutes in some cases)
- Check Google Cloud Console for any error messages
- Verify Client ID matches: `816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel`

### Apple:
- Verify capability shows in Signing & Capabilities tab
- Check entitlements file exists (should be auto-created)
- Ensure simulator is signed into iCloud
- Try on a real device if simulator doesn't work
- Check Apple Developer account has Sign in with Apple enabled for this Bundle ID


