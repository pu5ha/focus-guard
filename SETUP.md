# FocusGuard Setup Instructions

## Phase 1 Complete! ✅

All Phase 1 code has been written. Now we need to create the Xcode project.

## Step 1: Create Xcode Project

1. Open Xcode
2. Click "Create New Project"
3. Choose **macOS** → **App**
4. Configure:
   - Product Name: **FocusGuard**
   - Team: Your team
   - Organization Identifier: `com.yourname` (or similar)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Check "Use Core Data"
   - Location: `/Users/jasonchaskin/Desktop/productivity/FocusGuard`

## Step 2: Add Source Files to Project

1. In Xcode, right-click on "FocusGuard" folder in the navigator
2. Choose "Add Files to FocusGuard..."
3. Navigate to `/Users/jasonchaskin/Desktop/productivity/FocusGuard/FocusGuard/`
4. Select these folders:
   - `Models` folder
   - `Views` folder
   - `Services` folder
5. Make sure "Copy items if needed" is **unchecked** (files are already in place)
6. Click "Add"

## Step 3: Replace Default Files

Xcode created some default files. Replace them:

1. **Delete** the default `FocusGuardApp.swift` file Xcode created
2. **Delete** the default `ContentView.swift` file
3. **Delete** the default Core Data model (`FocusGuard.xcdatamodeld`)
4. The files in the FocusGuard folder should now be linked

## Step 4: Add Files to Project

Add these specific files to the project:
1. Right-click FocusGuard → Add Files
2. Add: `FocusGuardApp.swift`
3. Add: `MenuBarController.swift`
4. Add all files from Models, Views, Services folders

## Step 5: Configure App Settings

1. Select the FocusGuard target
2. Go to "Signing & Capabilities"
3. Add capability: **App Sandbox**
4. Under App Sandbox, enable:
   - ✅ Outgoing Connections (Network Client)
5. Go to "Info" tab
6. Set "Application is agent (UIElement)": **YES**

## Step 6: Build and Run

1. Select "FocusGuard" scheme
2. Press **⌘ + B** to build
3. Press **⌘ + R** to run
4. You should see a shield icon in your menu bar!

## What You Can Do Now

Once running, you can:
- Click the menu bar icon to see the FocusGuard interface
- Enter "x.com" and click + to add a block
- Click "1 Hour" to block x.com for 1 hour
- Try visiting x.com in Brave - it should be blocked!
- Click the X next to a block to remove it

## Troubleshooting

### Build Errors

If you get build errors about missing files:
- Make sure all `.swift` files are added to the target
- Check that the Core Data model is properly linked

### "Cannot find type" errors

- Clean build folder: **Product → Clean Build Folder**
- Rebuild: **⌘ + B**

### Password Prompts

The first time you block a site, macOS will ask for your password to modify /etc/hosts. This is normal for Phase 1. Phase 4 will eliminate these prompts with the XPC helper.

## Next Steps

Once Phase 1 is working:
- Test blocking x.com
- Test the timer (blocks expire after duration)
- Provide feedback on the UI

Then we'll move to **Phase 2**: Chrome extension with pre-emptive intervention page!
