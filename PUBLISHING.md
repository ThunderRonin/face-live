# Face Live Plugin - Publishing Guide

This document outlines the complete process for publishing the `face_live` Flutter plugin to pub.dev.

## 📋 Pre-Publishing Checklist

### 1. Documentation Requirements
- [ ] **README.md** - Complete with installation, usage examples, and troubleshooting
- [ ] **CHANGELOG.md** - Updated with new version entry following [Keep a Changelog](https://keepachangelog.com/) format
- [ ] **LICENSE** - Valid open-source license included
- [ ] **API Documentation** - All public classes and methods have dartdoc comments

### 2. Code Quality & Testing
- [ ] Run `dart format` on all Dart files
- [ ] Run `dart analyze` with no errors
- [ ] All unit tests pass: `flutter test`
- [ ] Example app builds and runs on both platforms
- [ ] Integration tests pass
- [ ] Manual testing completed on real devices

### 3. Platform-Specific Requirements

#### Android
- [ ] Minimum SDK version: API 21+
- [ ] Required permissions in AndroidManifest.xml
- [ ] Firebase BOM and ML Kit dependencies properly configured
- [ ] ProGuard rules if needed

#### iOS  
- [ ] iOS deployment target: 15.5+
- [ ] Camera usage permissions in Info.plist
- [ ] ML Kit CocoaPods dependencies
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) included

### 4. Version Management
- [ ] Version number updated in `pubspec.yaml`
- [ ] Version follows semantic versioning (MAJOR.MINOR.PATCH)
- [ ] Breaking changes properly documented
- [ ] CHANGELOG.md entry added for new version

## 🚀 Publishing Process

### Step 1: Update Package Information

1. **Update pubspec.yaml metadata:**
   ```yaml
   name: face_live
   description: "A Flutter plugin for real-time face liveness detection using native camera and ML Kit."
   version: x.y.z  # Update version number
   homepage: https://github.com/your-org/face_live
   repository: https://github.com/your-org/face_live
   issue_tracker: https://github.com/your-org/face_live/issues
   ```

2. **Verify Dart SDK constraints:**
   ```yaml
   environment:
     sdk: '>=3.8.1 <4.0.0'
     flutter: '>=3.32.0'
   ```

### Step 2: Final Quality Checks

```bash
# Format all Dart code
dart format .

# Analyze code for issues
dart analyze

# Run all tests
flutter test

# Test example app
cd example
flutter build apk --debug
flutter build ios --debug --no-codesign
```

### Step 3: Validate Package

```bash
# Dry run to check for publishing issues
dart pub publish --dry-run
```

Fix any issues reported by the dry run before proceeding.

### Step 4: Publish to Pub.dev

```bash
# Publish the package
dart pub publish
```

**Note:** You'll need to:
- Have a Google account
- Be verified as a publisher on pub.dev
- Follow the prompts to authorize publishing

## 📝 Version Numbering Strategy

### Semantic Versioning Rules
- **MAJOR (x.0.0)**: Breaking changes, API modifications
- **MINOR (0.x.0)**: New features, backward-compatible additions
- **PATCH (0.0.x)**: Bug fixes, performance improvements

### Examples
- `0.2.0` → `0.2.1`: Bug fix (iOS recording issue)
- `0.2.1` → `0.3.0`: New feature (e.g., eye blink detection)  
- `0.3.0` → `1.0.0`: Stable API, breaking changes

### Pre-release Versions
For beta testing: `0.3.0-beta.1`, `0.3.0-beta.2`, etc.

## 📄 CHANGELOG Format

Follow this structure for each release:

```markdown
## x.y.z

### 🎉 New Features
* Feature description with implementation details

### 🔧 Improvements
* Improvement description with impact

### 🐛 Bug Fixes
* Bug fix description with root cause

### ⚠️ Breaking Changes
* Breaking change with migration instructions

### 📱 Platform Support
* Platform-specific updates
```

## 🔍 Post-Publishing Steps

### 1. Verify Publication
- [ ] Check package appears on [pub.dev/packages/face_live](https://pub.dev/packages/face_live)
- [ ] Verify documentation renders correctly
- [ ] Test installation in a fresh project

### 2. Update Repository
- [ ] Create git tag for the version: `git tag v0.2.1`
- [ ] Push tags: `git push origin --tags`
- [ ] Create GitHub release with release notes

### 3. Communication
- [ ] Update README badges if needed
- [ ] Notify users of significant changes
- [ ] Update example apps and documentation

## 🛠 Troubleshooting Common Issues

### Publishing Errors

**"Package validation failed"**
- Run `dart pub publish --dry-run` to identify issues
- Ensure all required files are present
- Check pubspec.yaml formatting

**"Version already exists"**
- Version numbers cannot be reused
- Increment version in pubspec.yaml
- Update CHANGELOG.md

**"Documentation issues"**
- Add missing dartdoc comments
- Fix broken links in README.md
- Ensure all public APIs are documented

### Platform-Specific Issues

**Android build failures:**
- Check Gradle versions compatibility
- Verify ProGuard rules
- Ensure all permissions are declared

**iOS build failures:**
- Check CocoaPods dependencies
- Verify deployment target
- Ensure privacy permissions are set

## 📋 Release Checklist Template

```markdown
## Release x.y.z Checklist

### Pre-Release
- [ ] Code formatted and analyzed
- [ ] All tests passing  
- [ ] Example app tested on devices
- [ ] CHANGELOG.md updated
- [ ] Version bumped in pubspec.yaml
- [ ] Documentation updated

### Publishing
- [ ] Dry run successful
- [ ] Published to pub.dev
- [ ] Package visible on pub.dev

### Post-Release  
- [ ] Git tag created and pushed
- [ ] GitHub release created
- [ ] Documentation verified
- [ ] Community notified if needed
```

## 🎯 Best Practices

1. **Test Thoroughly**: Always test on real devices before publishing
2. **Document Everything**: Clear documentation reduces support burden
3. **Follow Conventions**: Stick to Flutter/Dart conventions and pub.dev guidelines
4. **Version Carefully**: Use semantic versioning consistently
5. **Communicate Changes**: Keep users informed of breaking changes
6. **Monitor Issues**: Respond to GitHub issues and pub.dev feedback

## 📚 Resources

- [Pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Flutter Plugin Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

---

**Current Status**: Package at version 0.2.0, ready for next release cycle.
