import urllib.request

url = "https://contenido.bce.fin.ec/documentos/informacioneconomica/cuentasnacionales/trimestrales/vab_129_202403.xlsx"
output_path = r"c:\Users\gonza\OneDrive - Universidad Nacional de Chimborazo\CUARTO SEMESTRE\Base de Datos\Investigacion\Script\DATA\VAB_Industrias_Ecuador.xlsx"

print(f"Descargando datos reales del BCE desde: {url}")
try:
    urllib.request.urlretrieve(url, output_path)
    print(f"¡Descarga exitosa! Archivo guardado en: {output_path}")
except Exception as e:
    print(f"Error descargando el archivo: {e}")
