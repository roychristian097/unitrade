import os
import glob

for file in glob.glob('lib/**/*.dart', recursive=True):
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    if '10.249.137.94' in content:
        content = content.replace('10.249.137.94', '127.0.0.1')
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
            print(f"Updated {file}")
