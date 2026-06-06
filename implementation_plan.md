# Plan Definitivo: Arquitectura Híbrida de Analítica Predictiva

Este documento establece la hoja de ruta final para el desarrollo del proyecto "Persistencia Híbrida y Analítica Predictiva", en estricto cumplimiento con los requerimientos del documento base de la asignatura.

## Goal Description
Construir una infraestructura de datos híbrida (**SQL Server + MongoDB**) y una aplicación interactiva (**Streamlit**) que implemente modelos de Machine Learning para predecir déficits de energía y analizar su impacto económico. El proyecto procesará más de 10,000 registros y al menos 15 variables.

## Datasets Seleccionados (Completitud)
1. **Energía y Demanda (ARCONEL)**: Archivos de facturación (demanda), energía producida y pérdidas de energía (2024).
2. **Clima e Hidrología (NASA POWER API)**: Temperaturas y precipitaciones diarias de la cuenca del Río Paute.
3. **Económico (BCE)**: Valor Agregado Bruto (VAB) sectorial para calcular las pérdidas financieras durante los apagones (Simulador de Crisis).

## User Review Required
> [!IMPORTANT]
> Se ha definido **SQL Server** como el motor relacional principal basándonos en el PDF de requerimientos. 
> Por favor confirma que tienes instalado **SQL Server** (y SQL Server Management Studio) y **MongoDB** (Compass o Atlas) en tu computadora para poder conectarnos desde Python en las siguientes fases.

## Proposed Changes

El flujo de trabajo se dividirá en los siguientes entregables y componentes técnicos:

### Fase 1: Base de Datos Relacional (SQL Server)
- **Normalización**: Diseño del modelo Entidad-Relación con tablas para `Dim_Tiempo`, `Dim_Geografia`, `Fact_Demanda`, `Fact_Clima`, `Fact_Economia`. 
- **Gobernanza**: Creación de triggers de auditoría (ej. `trg_UpdateDemanda`) y roles (`db_datareader`, `db_datawriter`).
- **DRP**: Script automatizado para backup y restore de la base de datos.
- *Entregable: Script `.sql` completo.*

### Fase 2: Puente de Datos y ETL (Jupyter Notebook)
- **Extracción**: Consumo de la API de NASA POWER y lectura de los CSVs de ARCONEL.
- **Transformación**: Imputación de nulos, eliminación de duplicados, escalamiento numérico (ej. `StandardScaler`) y codificación de variables categóricas.
- **Carga (pyodbc)**: Inserción de los más de 10,000 registros limpios hacia SQL Server.
- *Entregable: `1_ETL_Pipeline.ipynb`*

### Fase 3: Aprendizaje No Supervisado
- **Objetivo**: Encontrar patrones en el dominio eléctrico.
- **Modelo**: K-Means para agrupar provincias o subestaciones según eficiencia (% de pérdidas vs facturación).
- **Validación**: Gráficas del Método del Codo y Coeficiente de Silueta.
- *Entregable: Bloque en `2_Machine_Learning.ipynb`*

### Fase 4: Aprendizaje Supervisado
- **Objetivo**: Predecir el pico de demanda máxima o el déficit de generación.
- **Preparación**: `train_test_split` (80/20) con `random_state=42`.
- **Modelos**: Entrenamiento comparativo entre Regresión Lineal/Logística y Random Forest.
- *Entregable: Bloque en `2_Machine_Learning.ipynb`*

### Fase 5: Base de Datos NoSQL (MongoDB)
- **Persistencia**: Inyección automática de logs de los modelos entrenados.
- **Estructura JSON**: `{ "fecha_experimento", "tipo_aprendizaje", "algoritmo", "hiperparametros": {"n_clusters", "random_state"}, "metricas": {"inercia", "silueta"} }`.
- *Entregable: Integración en el notebook de ML.*

### Fase 6: Despliegue en Tiempo Real (Streamlit App)
- **Frontend**: Interfaz gráfica en Python (`app.py`).
- **Simulador de Crisis**: Formularios (`st.slider`, `st.selectbox`) para ingresar predicciones de lluvia y ver el impacto en tiempo real.
- **Conexión Directa**: Consultas en vivo a SQL Server para gráficos descriptivos y a MongoDB para mostrar el historial de entrenamientos.
- **Validación Cualitativa**: Integración de micro-videos testimoniales dentro de la app mostrando el impacto financiero en empresas reales.
- *Entregable: `app.py`*

## Verification Plan
1. Ejecución del script DDL en SQL Server Management Studio sin errores de FK.
2. Comprobación de que el `DataFrame` final en Pandas tenga shape > (10000, 15).
3. Verificación de la creación de documentos en MongoDB Compass tras entrenar el modelo.
4. Pruebas de usabilidad ejecutando `streamlit run app.py` localmente.
