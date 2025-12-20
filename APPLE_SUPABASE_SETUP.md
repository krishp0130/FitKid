# How to Configure Apple Sign-In in Supabase

## Current Status

The backend is configured to handle Apple Sign-In, but **Supabase needs to have Apple provider enabled**.

## Error You're Likely Seeing

When you try Apple Sign-In, the backend logs will show:
```
error: Apple token exchange failed
error: { message: "provider not enabled" or similar }
```

## Solution: Enable Apple Provider in Supabase

### Step 1: Go to Supabase Dashboard
1. Visit: https://app.supabase.com/
2. Select your project: `cgvzyhxdhbtorgpqeuel`

### Step 2: Navigate to Authentication
1. Click **Authentication** in the left sidebar
2. Click **Providers** tab
3. Find **Apple** in the list

### Step 3: Enable Apple Provider
1. Click on **Apple** provider
2. Toggle **"Enable Apple provider"** to ON

### Step 4: Configure Apple OAuth (if needed)

For development/testing, Supabase may require:

1. **Services ID**: Your Apple Services ID
   - Get from: https://developer.apple.com/account/resources/identifiers/list/serviceId
   - Should match your Bundle ID: `com.kidzone.KidzoneApp`

2. **Key ID and Private Key** (if required):
   - Get from: https://developer.apple.com/account/resources/authkeys/list
   - Download the private key file

3. **Team ID**: Your Apple Developer Team ID

### Step 5: Save and Test
1. Click **Save** in Supabase
2. Try Apple Sign-In again from your iOS app

## What the Backend Logs Show

Check the terminal where `npm run dev` is running. You should see:

**Before configuring Supabase:**
```
[timestamp] POST /api/auth/apple
[timestamp] error: Apple token exchange failed
  error: { message: "provider not enabled", ... }
```

**After configuring Supabase (if successful):**
```
[timestamp] POST /api/auth/apple
[timestamp] info: Request completed
```

## Note

For testing in simulator, you may still need:
- Sign in with Apple capability enabled in Xcode (✅ already done)
- iCloud signed in on simulator (you've done this via Xcode)
- Apple provider configured in Supabase (⚠️ needs to be done)


