# 🔄 React Native Directory Version Sync

## 📊 Current Status

### Directory vs npm:
- **Directory Shows**: v0.1.4 (old version, ~1.18MB)
- **npm Has**: v0.1.5 (new version, 86.7 kB)
- **Status**: ⏳ **Pending Sync** - Directory needs to rebuild

---

## 🔍 How Directory Sync Works

### Automatic Sync Process:
1. **Directory Scripts** pull data from npm registry
2. **Package Data** is fetched via `fetch-npm-registry-data.ts`
3. **Build Process** runs `build-and-score-data.ts`
4. **Website Rebuilds** with updated data
5. **API Updates** to reflect new version

### What Gets Synced:
- ✅ npm package version (`latestRelease`)
- ✅ Package size (`size`)
- ✅ Release date (`latestReleaseDate`)
- ✅ Download statistics
- ✅ GitHub repository data

---

## ⏰ Timeline

### Typical Sync Schedule:
- **Automatic Rebuilds**: Usually daily or on schedule
- **Manual Triggers**: Can be triggered by repository maintainers
- **Update Time**: Usually within **24-48 hours** after npm publish

### Current Situation:
- **v0.1.5 Published**: November 4, 2025 (today)
- **Directory Last Updated**: Still showing v0.1.4 data
- **Expected Sync**: Within 24-48 hours

---

## 📋 What Will Update

### When Directory Syncs:
- **Version**: Will show `0.1.5` instead of `0.1.4`
- **Package Size**: Will show `86.7 kB` instead of `~1.18MB`
- **Release Date**: Will show November 4, 2025
- **Download Stats**: Will track v0.1.5 downloads

### Data Changes:
```json
{
  "npm": {
    "latestRelease": "0.1.5",  // ← Will update from 0.1.4
    "size": 86691,              // ← Will update from 1181672
    "latestReleaseDate": "2025-11-04T09:53:21.240Z"
  }
}
```

---

## ✅ Verification

### Check When It Updates:

#### Method 1: API Check
```bash
curl "https://reactnative.directory/api/libraries?search=react-native-files-picker" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); \
  lib = data.get('libraries', [{}])[0]; \
  print(lib.get('npm', {}).get('latestRelease', 'N/A'))"
```

#### Method 2: Website Check
Visit: https://reactnative.directory/?search=react-native-files-picker
- Check the version displayed on the package page
- Check the package size shown

#### Method 3: Compare Sizes
- **Old (v0.1.4)**: ~1.18MB
- **New (v0.1.5)**: 86.7 kB
- When you see 86.7 kB, it's synced!

---

## 🎯 What You Can Do

### Option 1: Wait (Recommended)
- ✅ Directory syncs automatically
- ✅ No action needed
- ✅ Usually updates within 24-48 hours

### Option 2: Check Periodically
- Visit the directory page daily
- Check the API endpoint
- Monitor when version updates

### Option 3: Contact Maintainers (If Needed)
- If it doesn't update after 48 hours
- Check directory repository for build issues
- Contact React Native Directory maintainers

---

## 📊 Current Comparison

### Directory Data (v0.1.4):
```
Latest version: 0.1.4
Package size: ~1.18MB (1181672 bytes)
Release date: 2025-11-03
```

### npm Registry (v0.1.5):
```
Latest version: 0.1.5
Package size: 86.7 kB (86691 bytes)
Release date: 2025-11-04
```

### After Sync (Expected):
```
Latest version: 0.1.5 ✅
Package size: 86.7 kB ✅
Release date: 2025-11-04 ✅
```

---

## ✅ Summary

### Current Status:
- ✅ **v0.1.5 Published**: Yes (on npm)
- ⏳ **Directory Sync**: Pending (will update automatically)
- 📊 **Expected Timeline**: 24-48 hours
- ✅ **No Action Needed**: Directory auto-syncs

### What to Expect:
- Directory will automatically fetch v0.1.5 from npm
- Package size will update to 86.7 kB
- Version will show 0.1.5
- Download stats will track the new version

---

## 🔗 Links

- **npm Package**: https://www.npmjs.com/package/react-native-files-picker
- **Directory Page**: https://reactnative.directory/?search=react-native-files-picker
- **Directory API**: https://reactnative.directory/api/libraries?search=react-native-files-picker

---

**The directory will automatically sync v0.1.5 within 24-48 hours!** ⏳

Check back tomorrow to see the updated version and package size. 🚀

