# Camera Plugin Compatibility Fix

## Error
```
Camera Plugin builtinultrawidecamera is only available in iOS 13 or newer
Camera Plugin builtindualwidecamera is only available in iOS 13 or newer
```

## Root Cause
The Flutter `camera` plugin (camera_avfoundation) uses AVFoundation camera device types that require iOS 13+:
- `AVCaptureDevice.DeviceType.builtInUltraWideCamera` (iOS 13+)
- `AVCaptureDevice.DeviceType.builtInDualWideCamera` (iOS 13+)

If your project's iOS deployment target is set to iOS 11 or iOS 12, you'll get this compilation error.

## Solution

### 1. Update Your Project's iOS Deployment Target

**Option A: Via Podfile (Recommended)**

Edit your app's `ios/Podfile`:

```ruby
# At the top of the file, set minimum iOS version
platform :ios, '13.0'  # ← Change this to 13.0

# ... rest of Podfile

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Add this to ensure all pods use iOS 13.0+
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

**Option B: Via Xcode**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** project in the navigator
3. Select the **Runner** target
4. Go to **Build Settings** tab
5. Search for "Deployment Target"
6. Set **iOS Deployment Target** to **iOS 13.0** or higher

### 2. Clean and Rebuild

```bash
# Clean Flutter build
flutter clean

# Remove iOS build artifacts
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

# Get dependencies
cd ..
flutter pub get

# Reinstall pods
cd ios
pod install --repo-update

# Go back and run
cd ..
flutter run
```

### 3. Verify Configuration

Check that all targets are set correctly:

```bash
cd ios
grep -r "IPHONEOS_DEPLOYMENT_TARGET" . --include="*.pbxproj"
```

Should show iOS 13.0 for all targets.

## Why iOS 13.0?

### cunning_document_scanner Requirements
- **VNDocumentCameraViewController**: Requires iOS 13.0+
- **VNRecognizeTextRequest**: Requires iOS 13.0+
- **Modern Vision Framework APIs**: Requires iOS 13.0+

### camera Plugin Requirements (if used in your project)
- **builtInUltraWideCamera**: Requires iOS 13.0+
- **builtInDualWideCamera**: Requires iOS 13.0+
- **Modern AVFoundation APIs**: Requires iOS 13.0+

## Additional Fixes

### If Using Multiple Camera-Related Plugins

Ensure all camera-related plugins support iOS 13.0+:

**Check your `pubspec.yaml`:**
```yaml
dependencies:
  camera: ^0.10.0  # Check latest version
  cunning_document_scanner: ^2.0.0
  image_picker: ^1.0.0  # If using
```

**Update all plugins:**
```bash
flutter pub upgrade
```

### If You Still Get Errors

1. **Check Runner project settings:**
   ```bash
   cd ios
   xcodebuild -showBuildSettings | grep IPHONEOS_DEPLOYMENT_TARGET
   ```

2. **Ensure Info.plist has minimum version:**
   Edit `ios/Runner/Info.plist` and add/verify:
   ```xml
   <key>MinimumOSVersion</key>
   <string>13.0</string>
   ```

3. **Force pod update:**
   ```bash
   cd ios
   pod deintegrate
   pod install --repo-update
   ```

## Device Compatibility

iOS 13.0+ is supported by:
- ✅ iPhone 6s and newer (released 2015+)
- ✅ iPad (5th generation) and newer
- ✅ iPad Pro (all models)
- ✅ iPad Air 2 and newer
- ✅ iPad mini 4 and newer
- ✅ iPod touch (7th generation)

**Coverage:** ~99% of active iOS devices as of 2025

## Testing

After fixing, test on:
1. **iOS 13.0** - Minimum supported version
2. **iOS 14.0** - Common deployment target
3. **iOS 15.0+** - Modern UI features
4. **iOS 16.0+** - Multi-language support

## Common Issues

### Issue 1: Pods still showing iOS 11/12
**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### Issue 2: Xcode still building for iOS 11/12
**Solution:**
```bash
# In Xcode
Product → Clean Build Folder (Cmd+Shift+K)
# Then rebuild
```

### Issue 3: Multiple deployment target warnings
**Solution:** Add to your Podfile:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Silence deployment target warnings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
    end
  end
end
```

## Need Help?

If you still encounter issues:

1. **Share your configuration:**
   ```bash
   cat ios/Podfile
   grep "IPHONEOS_DEPLOYMENT_TARGET" ios/*.xcodeproj/project.pbxproj
   ```

2. **Check Flutter doctor:**
   ```bash
   flutter doctor -v
   ```

3. **Verify plugin versions:**
   ```bash
   flutter pub deps
   ```

## Summary

✅ **Set iOS deployment target to 13.0 in:**
- `ios/Podfile` (line 2: `platform :ios, '13.0'`)
- Xcode project settings
- All pod targets (via post_install)

✅ **Clean and rebuild:**
```bash
flutter clean && cd ios && pod install && cd .. && flutter run
```

✅ **This fixes:**
- builtInUltraWideCamera error
- builtInDualWideCamera error
- All iOS 13+ API compatibility issues

---

**Plugin Version:** 2.0.0
**Minimum iOS:** 13.0
**Recommended iOS:** 15.0+
