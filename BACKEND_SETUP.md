# Backend Setup Instructions

## ✅ What I've Done
1. Installed backend dependencies (`npm install`)
2. Created `.env.template` file
3. Attempted to start backend server

## 🔧 What You Need to Do

### Step 1: Create .env File with Supabase Credentials

The backend needs your Supabase credentials to work. 

**Get your Supabase credentials:**
1. Go to: https://app.supabase.com/
2. Select your project
3. Go to **Settings** > **API**
4. Copy:
   - **Project URL** (this is your `SUPABASE_URL`)
   - **service_role** key (this is your `SUPABASE_SERVICE_ROLE_KEY`)

**Create the .env file:**
```bash
cd backend
cp .env.template .env
```

**Edit `.env` file and add your credentials:**
```env
SUPABASE_URL=https://your-actual-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_actual_service_role_key_here
PORT=3000
```

⚠️ **IMPORTANT**: The `service_role` key is very powerful - it bypasses Row Level Security. Never commit it to git!

### Step 2: Start the Backend Server

Once you've created the `.env` file with your credentials:

```bash
cd backend
npm run dev
```

The server will start on: **http://localhost:3000**

### Step 3: Verify It's Working

In another terminal, test the health endpoint:
```bash
curl http://localhost:3000/health
```

You should see: `{"status":"ok"}`

## 🧪 Testing Authentication

Once the backend is running:

1. **Run your iOS app** (in Xcode or simulator)
2. **Try Google Sign-In** - it should now:
   - Show Google sign-in prompt ✅
   - Exchange token with backend ✅
   - Return user session ✅
   - Proceed to role selection ✅

## 📝 Backend Endpoints

- `GET /health` - Health check
- `POST /api/auth/google` - Exchange Google ID token for session
- `POST /api/auth/apple` - Exchange Apple ID token for session

## 🔍 Troubleshooting

**Server won't start:**
- Check that `.env` file exists in `backend/` directory
- Verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are set
- Check for typos in the `.env` file

**Authentication fails:**
- Make sure backend is running (`curl http://localhost:3000/health`)
- Check backend logs for errors
- Verify Supabase credentials are correct
- Make sure Google OAuth is configured in Supabase dashboard

**iOS app can't connect:**
- Simulator uses `localhost:3000` (should work automatically)
- For physical device, you'll need your Mac's IP address:
  - In `AuthAPI.swift`, change: `http://localhost:3000` to `http://YOUR_MAC_IP:3000`
  - Get your Mac IP: System Settings > Network > Wi-Fi > Details > TCP/IP > IPv4 Address


