import pandas as pd
import sys

file_path = r'c:\Users\gonza\OneDrive - Universidad Nacional de Chimborazo\CUARTO SEMESTRE\Base de Datos\Investigacion\Script\DATA\conjunto-de-datos_cuentas-nacionales-trimestrales-2024-iii.xlsx'

try:
    print("Leyendo el archivo Excel...")
    xl = pd.ExcelFile(file_path)
    print(f"Hojas encontradas: {xl.sheet_names}")
    
    for sheet in xl.sheet_names:
        print(f"\n--- Hoja: {sheet} ---")
        df = xl.parse(sheet, nrows=5)
        print("Dimensiones iniciales:", df.shape)
        print("Columnas:", df.columns.tolist()[:10], "..." if len(df.columns) > 10 else "")
        print(df.head())
        
except Exception as e:
    print(f"Error al leer el archivo: {e}")
