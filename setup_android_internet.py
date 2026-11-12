from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
if not p.exists():
    raise SystemExit('Run flutter create . first')
s = p.read_text()
permission = '<uses-permission android:name="android.permission.INTERNET" />'
if permission not in s:
    s = s.replace('<application', permission + '\n    <application', 1)
    p.write_text(s)
print('Android INTERNET permission ready')
