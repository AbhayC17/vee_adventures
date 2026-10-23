from pathlib import Path

root = Path(__file__).resolve().parents[1]

android = root / 'android/app/src/main/AndroidManifest.xml'
if android.exists():
    text = android.read_text(encoding='utf-8')
    permission = '    <uses-permission android:name="android.permission.CAMERA"/>\n'
    if 'android.permission.CAMERA' not in text:
        marker = '<manifest '
        start = text.find('>\n', text.find(marker))
        if start >= 0:
            text = text[:start+2] + permission + text[start+2:]
            android.write_text(text, encoding='utf-8')

plist = root / 'ios/Runner/Info.plist'
if plist.exists():
    text = plist.read_text(encoding='utf-8')
    additions = '''\t<key>NSCameraUsageDescription</key>\n\t<string>Vee uses the camera for Spot discoveries with a grown-up.</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Vee can use a photo for a Spot discovery with a grown-up.</string>\n'''
    if 'NSCameraUsageDescription' not in text:
        text = text.replace('</dict>', additions + '</dict>')
        plist.write_text(text, encoding='utf-8')
