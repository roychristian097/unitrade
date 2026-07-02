import sqlite3
conn = sqlite3.connect('unitrade.db')
cursor = conn.cursor()
cursor.execute("UPDATE products SET approval_status = 'APPROVED'")
cursor.execute("UPDATE services SET approval_status = 'APPROVED'")
conn.commit()
conn.close()
