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

# The game is designed for landscape. Lock both platforms to it so a child
# turning the device never sees a squashed layout.
import re

if android.exists():
    text = android.read_text(encoding='utf-8')
    if 'android:screenOrientation' not in text:
        text = re.sub(
            r'(android:name="\.MainActivity")',
            r'\1\n            android:screenOrientation="sensorLandscape"',
            text,
            count=1,
        )
        android.write_text(text, encoding='utf-8')

if plist.exists():
    text = plist.read_text(encoding='utf-8')
    landscape = (
        '<array>\n\t\t<string>UIInterfaceOrientationLandscapeLeft</string>\n'
        '\t\t<string>UIInterfaceOrientationLandscapeRight</string>\n\t</array>'
    )
    text = re.sub(
        r'(<key>UISupportedInterfaceOrientations(?:~ipad)?</key>\s*)<array>.*?</array>',
        lambda m: m.group(1) + landscape,
        text,
        flags=re.S,
    )
    plist.write_text(text, encoding='utf-8')

# Friendly app name on the home screen / in the stores.
if android.exists():
    text = android.read_text(encoding='utf-8')
    text = re.sub(r'android:label="[^"]*"', 'android:label="Movement Missions"', text, count=1)
    android.write_text(text, encoding='utf-8')

if plist.exists():
    text = plist.read_text(encoding='utf-8')
    for key in ('CFBundleDisplayName', 'CFBundleName'):
        text = re.sub(
            r'(<key>' + key + r'</key>\s*<string>)[^<]*(</string>)',
            r'\1Movement Missions\2',
            text,
        )
    plist.write_text(text, encoding='utf-8')
