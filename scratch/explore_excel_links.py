import pandas as pd
import sys

file_path = r'c:\Users\gonza\OneDrive - Universidad Nacional de Chimborazo\CUARTO SEMESTRE\Base de Datos\Investigacion\Script\DATA\conjunto-de-datos_cuentas-nacionales-trimestrales-2024-iii.xlsx'

try:
    xl = pd.ExcelFile(file_path)
    df = xl.parse('CNT 2024 III')
    for index, row in df.iterrows():
        print(f"[{index}] Contenido: {row['CONTENIDO']}")
        print(f"    Enlace: {row['ENLACE ']}\n")
except Exception as e:
    print(f"Error: {e}")
