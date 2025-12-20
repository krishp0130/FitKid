# How to Configure Google OAuth in Supabase

## Problem
You're getting "Your session is not authorized" error because Google OAuth provider is not configured in Supabase.

## Solution: Enable Google OAuth in Supabase

### Step 1: Go to Supabase Dashboard
1. Visit: https://app.supabase.com/
2. Select your project: `cgvzyhxdhbtorgpqeuel`

### Step 2: Navigate to Authentication Settings
1. Click **Authentication** in the left sidebar
2. Click **Providers** tab
3. Find **Google** in the list

### Step 3: Enable Google Provider
1. Click on **Google** provider
2. Toggle **Enable Google provider** to ON
3. You'll need to configure OAuth credentials:

### Step 4: Configure Google OAuth Credentials

**You'll need from Google Cloud Console:**
- **Client ID**: `816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel`
- **Client Secret**: (Get this from Google Cloud Console)

**To get your Client Secret:**
1. Go to: https://console.cloud.google.com/
2. Select your project
3. Go to **APIs & Services** > **Credentials**
4. Find your OAuth 2.0 Client ID
5. Click on it to see the **Client secret**
6. Copy the Client secret

### Step 5: Add Credentials to Supabase
1. In Supabase > Authentication > Providers > Google:
   - Paste your **Client ID**: `816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel`
   - Paste your **Client Secret** (from Google Cloud Console)
   
2. **Authorized Client IDs**: Add your iOS client ID:
   - `816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel.apps.googleusercontent.com`

3. **Authorized Redirect URLs**: Supabase will provide you with a redirect URL like:
   - `https://cgvzyhxdhbtorgpqeuel.supabase.co/auth/v1/callback`
   
   **IMPORTANT**: Add this redirect URL to Google Cloud Console:
   - Go to Google Cloud Console > APIs & Services > Credentials
   - Click on your OAuth 2.0 Client ID
   - Under **Authorized redirect URIs**, add:
     - `https://cgvzyhxdhbtorgpqeuel.supabase.co/auth/v1/callback`

### Step 6: Save and Test
1. Click **Save** in Supabase
2. Try signing in again from your iOS app

## Summary Checklist

- [ ] Google provider enabled in Supabase
- [ ] Client ID added: `816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel`
- [ ] Client Secret added (from Google Cloud Console)
- [ ] Authorized Client IDs configured
- [ ] Redirect URL added to Google Cloud Console: `https://cgvzyhxdhbtorgpqeuel.supabase.co/auth/v1/callback`
- [ ] Saved changes in Supabase

## After Configuration

Once configured, the authentication flow will be:
1. iOS app → Google Sign-In → Gets ID token ✅
2. iOS app → Backend → Exchanges token with Supabase ✅
3. Supabase validates Google token → Creates session ✅
4. Backend returns session to iOS app ✅
5. User is authenticated ✅

## Troubleshooting

**Still getting errors?**
- Check backend logs (terminal where `npm run dev` is running) for actual error messages
- Verify Client Secret is correct (no extra spaces)
- Make sure redirect URL matches exactly in both Supabase and Google Cloud Console
- Wait a few minutes after saving for changes to propagate


