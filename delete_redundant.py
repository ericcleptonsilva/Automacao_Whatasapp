import os
import shutil

base_path = r"C:\Users\clept\Documents\APPS\Automacao_Whatasapp\android\app\src\main\kotlin\com\clept\whatsappautomation"

files_to_delete = [
    "WhatsAppAccessibilityService.kt",
    "WhatsAppAutomationPlugin.kt",
    "WhatsAppNotificationListener.kt"
]

for filename in files_to_delete:
    file_path = os.path.join(base_path, filename)
    if os.path.exists(file_path):
        print(f"Deleting file: {file_path}")
        os.remove(file_path)

dir_to_delete = os.path.join(base_path, "whatsapp_auto")
if os.path.exists(dir_to_delete):
    print(f"Deleting directory: {dir_to_delete}")
    shutil.rmtree(dir_to_delete)

print("Cleanup complete.")
