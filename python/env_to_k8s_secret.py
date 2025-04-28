#!/usr/bin/env python3
import base64
import os

def main():
    # Pedir datos al usuario
    nombre_archivo = input("📄 Ingresa el nombre del archivo de variables (ej: variables.env): ").strip()
    nombre_secret = input("🔒 Ingresa el nombre del Secret que quieres crear: ").strip()
    namespace = input("🏷️ Ingresa el namespace donde se va a crear el Secret (por defecto 'default'): ").strip()

    if not namespace:
        namespace = "default"  # Usar default si no ponen nada

    # Verificar si el archivo existe en el directorio actual
    if not os.path.isfile(nombre_archivo):
        print(f"❌ Error: El archivo '{nombre_archivo}' no existe en la ruta actual.")
        return

    # Leer el archivo
    with open(nombre_archivo, "r") as f:
        lineas = f.readlines()

    # Procesar las variables
    variables_codificadas = {}
    for linea in lineas:
        linea = linea.strip()
        if not linea or "=" not in linea:
            continue

        nombre, valor = linea.split("=", 1)
        valor_base64 = base64.b64encode(valor.encode("utf-8")).decode("utf-8")
        variables_codificadas[nombre] = valor_base64

    if not variables_codificadas:
        print("⚠️ No se encontraron variables válidas en el archivo.")
        return

    # Crear el contenido del YAML
    yaml_output = [
        "apiVersion: v1",
        "kind: Secret",
        "metadata:",
        f"  name: {nombre_secret}",
        f"  namespace: {namespace}",
        "type: Opaque",
        "data:"
    ]

    for nombre, valor_base64 in variables_codificadas.items():
        yaml_output.append(f"  {nombre}: {valor_base64}")

    # Guardar en secrets.yaml
    nombre_salida = "secrets.yaml"
    with open(nombre_salida, "w") as f:
        f.write("\n".join(yaml_output))

    print(f"\n✅ Archivo '{nombre_salida}' generado exitosamente.")
    print(f"➡️ Nombre del Secret: {nombre_secret}")
    print(f"➡️ Namespace: {namespace}")

if __name__ == "__main__":
    main()

