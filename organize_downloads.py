import os
import shutil
import time
from pathlib import Path

# Definir las rutas de las carpetas
DOWNLOADS_DIR = Path.home() / "Downloads"
DOCUMENTS_DIR = Path.home() / "Documents"

# Crear carpetas para los tipos de archivos si no existen
DOCUMENT_TYPES = {
    "PDF": DOCUMENTS_DIR / "PDFs",
    "Word": DOCUMENTS_DIR / "Word",
    "PowerPoint": DOCUMENTS_DIR / "PowerPoint",
    "Text": DOCUMENTS_DIR / "Text",
}

for folder in DOCUMENT_TYPES.values():
    folder.mkdir(exist_ok=True)

# Función para eliminar archivos .deb y .exe antiguos
def delete_old_files(directory, extensions, days_old):
    now = time.time()
    for file in directory.glob("*"):
        if file.suffix.lower() in extensions and (now - file.stat().st_mtime) > (days_old * 86400):
            print(f"Eliminando {file.name}")
            file.unlink()

# Función para mover archivos a sus respectivas carpetas
def move_files_to_folders(directory, file_types):
    for file in directory.glob("*"):
        if file.suffix.lower() == ".pdf" and file.is_file():
            shutil.move(str(file), str(file_types["PDF"] / file.name))
        elif file.suffix.lower() in (".doc", ".docx") and file.is_file():
            shutil.move(str(file), str(file_types["Word"] / file.name))
        elif file.suffix.lower() in (".ppt", ".pptx") and file.is_file():
            shutil.move(str(file), str(file_types["PowerPoint"] / file.name))
        elif file.suffix.lower() == ".txt" and file.is_file():
            shutil.move(str(file), str(file_types["Text"] / file.name))

# Ejecutar las tareas
delete_old_files(DOWNLOADS_DIR, [".deb", ".exe"], 7)  # Eliminar archivos .deb y .exe de más de 7 días
move_files_to_folders(DOWNLOADS_DIR, DOCUMENT_TYPES)  # Mover archivos a sus carpetas correspondientes
