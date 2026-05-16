const fs = require('fs');
const path = require('path');

// 1x1 像素透明 PNG (base64)
const iconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
const iconBuffer = Buffer.from(iconBase64, 'base64');

const files = [
  'AppScope/resources/base/media/app_icon.png',
  'entry/src/main/resources/base/media/icon.png'
];

files.forEach(relativePath => {
  const fullPath = path.join(__dirname, relativePath);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(fullPath, iconBuffer);
  console.log('✓ Created: ' + relativePath);
});

console.log('\n所有图标已生成！回到 DevEco Studio 重新 Build 即可。');
