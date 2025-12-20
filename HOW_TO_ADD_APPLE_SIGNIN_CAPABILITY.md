# How to Add Sign in with Apple Capability - Step by Step

## Step 1: Open the Xcode Project
1. Open Xcode
2. Go to **File** > **Open** (or press `Cmd+O`)
3. Navigate to: `frontend/KidzoneApp.xcodeproj`
4. Double-click to open it

## Step 2: Find the Target (Project Navigator)
1. Look at the **left sidebar** in Xcode (the Project Navigator)
2. At the **very top**, you'll see a blue icon with "KidzoneApp" (this is your project)
3. Click on it **once** to expand it (you should see folders like "KidzoneApp", etc.)
4. **Directly under the blue project icon**, you'll see a **yellow/gold icon** with "KidzoneApp" - this is your **target**
5. Click on this **target** (the yellow one)

**If you don't see it:**
- Make sure the left sidebar is visible (View > Navigators > Show Project Navigator, or press `Cmd+1`)
- The target is always right under the project (blue icon)

## Step 3: Select the "Signing & Capabilities" Tab
1. At the **top of the editor area** (where code usually shows), you'll see tabs:
   - General
   - **Signing & Capabilities** ← Click this one
   - Resource Tags
   - Info
   - Build Settings
   - Build Phases
   - Build Rules
2. Click on **"Signing & Capabilities"**

## Step 4: Add the Capability
1. In the "Signing & Capabilities" tab, you'll see sections like:
   - "Signing"
   - "App Sandbox" (or other capabilities if any)
2. Look for a **"+ Capability"** button at the **top left** of this tab area
3. Click the **"+ Capability"** button
4. A searchable list will appear
5. Type: **"Sign in with Apple"**
6. Double-click on **"Sign in with Apple"** (or click it once and press Enter)

## Step 5: Verify It Was Added
- You should now see a new section appear called "Sign in with Apple"
- If you see this, you're done!

## Step 6: Clean and Build
1. Go to **Product** > **Clean Build Folder** (or press `Shift+Cmd+K`)
2. Then **Product** > **Build** (or press `Cmd+B`)
3. Finally **Product** > **Run** (or press `Cmd+R`)

---

## Visual Guide (Where Everything Is)

```
Xcode Window Layout:

┌─────────────────────────────────────────────────────────┐
│ File Edit View ... (Menu Bar)                           │
├─────────┬───────────────────────────────────────────────┤
│         │ General | Signing & Capabilities | Info ...   │ ← Tabs (Step 3)
│         │                                                 │
│ PROJECT │ + Capability  ← Click here! (Step 4)          │
│ NAV     │                                                 │
│         │ Signing                                        │
│ (Side)  │   Team: ...                                    │
│         │   Bundle Identifier: ...                       │
│         │                                                 │
│ 🔵      │ Capabilities                                   │
│ KidzoneApp│                                                │
│   🟡    │   ✅ Sign in with Apple ← Should appear!      │
│ KidzoneApp│                                                │
│ (Target)│                                                 │
│         │                                                 │
│         │                                                 │
└─────────┴───────────────────────────────────────────────┘
```

---

## Troubleshooting

**Can't find the target?**
- The target is the **yellow/gold icon** right under the blue project icon in the left sidebar
- Make sure you clicked the **blue project icon first** to expand it
- Try clicking on different items in the left sidebar until you see tabs at the top

**Can't find "+ Capability" button?**
- Make sure you're in the **"Signing & Capabilities"** tab (not "General" or "Info")
- The button is at the **top left** of the editor area, near where the tabs are
- Try clicking around the top left area of the "Signing & Capabilities" section

**The capability isn't adding?**
- Make sure you selected the **target** (yellow icon), not the project (blue icon)
- Try closing and reopening Xcode
- Make sure your Bundle Identifier is set (should be `com.kidzone.KidzoneApp`)


