import os

with open('theirs_main_utf8.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    start_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('@app.post("/cart")'):
            start_idx = i
            break
    if start_idx > 0:
        endpoints = ''.join(lines[start_idx:])
        with open('UniTrade/backend/main.py', 'a', encoding='utf-8') as f:
            f.write('\n' + endpoints)
        print("Appended endpoints successfully.")
    else:
        print("Could not find @app.post('/cart')")
