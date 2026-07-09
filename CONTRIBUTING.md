# Guía de Contribución para WJPr

Gracias por tu interés en contribuir a WJPr. Esta guía establece las reglas y convenciones para agregar nuevas funciones al paquete.

## Tabla de Contenidos

1. [Estructura del Proyecto](#estructura-del-proyecto)
2. [Convenciones de Nomenclatura](#convenciones-de-nomenclatura)
3. [Anatomía de una Función de Gráfico](#anatomía-de-una-función-de-gráfico)
4. [Documentación Roxygen2](#documentación-roxygen2)
5. [Patrones de Diseño Obligatorios](#patrones-de-diseño-obligatorios)
6. [Checklist de Contribución](#checklist-de-contribución)
7. [Proceso de Pull Request](#proceso-de-pull-request)

---

## Estructura del Proyecto

```
WJPr/
├── R/                          # Funciones del paquete
│   ├── barsChart.R             # Una función por archivo
│   ├── dotsChart.R
│   ├── imports.R               # Imports centralizados
│   ├── utils.R                 # Funciones auxiliares (fonts, theme)
│   ├── check_data.R            # Validación de datos
│   ├── check_deps.R            # Verificación de dependencias
│   └── data.R                  # Documentación de datasets
├── data/                       # Datasets (.rda)
├── data-raw/                   # Scripts para generar datos y ejemplos
├── man/                        # Documentación generada (NO editar)
│   └── figures/                # Imágenes de ejemplo
├── vignettes/                  # Tutoriales y guías
├── tests/                      # Tests unitarios
├── renv/                       # Configuración de renv
├── renv.lock                   # Versiones exactas de dependencias
├── DESCRIPTION                 # Metadatos del paquete
├── NAMESPACE                   # Exportaciones (generado por roxygen2)
└── CLAUDE.md                   # Guía para asistentes IA
```

---

## Configuración del Entorno de Desarrollo

Usamos **renv** para garantizar un entorno de desarrollo reproducible.

### Primera vez (clonar repositorio)

```r
# 1. Clonar el repositorio
# git clone https://github.com/worldjusticeproject-org/WJPr.git

# 2. Abrir el proyecto en RStudio o R

# 3. renv se activa automáticamente. Instalar dependencias:
renv::restore()

# 4. Verificar que todo está instalado:
library(WJPr)
wjp_check_deps()
```

### Agregar nuevas dependencias

```r
# 1. Instalar el paquete
renv::install("nuevo_paquete")

# 2. Actualizar el lockfile
renv::snapshot()

# 3. Commit de renv.lock
```

### Actualizar dependencias existentes

```r
# Actualizar todos los paquetes
renv::update()

# Guardar cambios
renv::snapshot()
```

---

## Convenciones de Nomenclatura

### Archivos

| Tipo | Convención | Ejemplo |
|------|------------|---------|
| Función de gráfico | `{tipo}Chart.R` | `barsChart.R`, `radarChart.R` |
| Utilidades | `{nombre}.R` | `utils.R`, `check_data.R` |
| Datos | `data.R` (documentación) | - |

### Funciones

| Tipo | Prefijo | Ejemplo |
|------|---------|---------|
| Gráficos | `wjp_` | `wjp_bars()`, `wjp_radar()` |
| Utilidades | `wjp_` | `wjp_fonts()`, `wjp_check_data()` |
| Tema | `WJP_` | `WJP_theme()` |

### Parámetros Estándar

Todas las funciones de gráfico DEBEN usar estos nombres de parámetros cuando aplique:

| Parámetro | Descripción | Tipo |
|-----------|-------------|------|
| `data` | Data frame con los datos | data.frame |
| `target` | Variable con valores numéricos a graficar | string |
| `grouping` | Variable de agrupación (eje X o Y) | string |
| `colors` | Variable para colores | string |
| `cvec` | Vector nombrado de colores hex | named vector |
| `labels` | Variable con etiquetas | string |
| `ptheme` | Tema ggplot2 | ggplot theme |

---

## Anatomía de una Función de Gráfico

Toda función de gráfico debe seguir esta estructura:

```r
#' Título corto descriptivo
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Descripción detallada de qué hace la función.
#'
#' @param data Data frame con los datos.
#' @param target String. Variable con valores numéricos.
#' @param ... otros parámetros
#'
#' @return Un objeto ggplot.
#' @export
#'
#' @examples
#' # Ejemplo reproducible completo
#'
wjp_nuevafuncion <- function(
    data,
    target,
    grouping,
    colors     = NULL,
    cvec       = NULL,
    labels     = NULL,
    ptheme     = WJP_theme()
) {


  # =========================================================================
  # 1. RENOMBRAR VARIABLES

# =========================================================================
  # Usar all_of() para renombrar columnas de forma segura
  data <- data %>%
    rename(
      target_var   = all_of(target),
      grouping_var = all_of(grouping)
    )

  # Manejar parámetros opcionales con NULL checks
  if (is.null(colors)) {
    data <- data %>%
      mutate(colors_var = grouping_var)
  } else {
    data <- data %>%
      rename(colors_var = all_of(colors))
  }

  # =========================================================================
  # 2. TRANSFORMAR DATOS (si es necesario)
  # =========================================================================
  # Cálculos, ordenamiento, etc.

  # =========================================================================
  # 3. CREAR GRÁFICO BASE
  # =========================================================================
  plt <- ggplot(data, aes(x = grouping_var, y = target_var)) +
    geom_*(...) +
    # ... otras capas

  # =========================================================================
  # 4. APLICAR COLORES (si cvec no es NULL)
  # =========================================================================
  if (!is.null(cvec)) {
    plt <- plt +
      scale_fill_manual(values = cvec)
      # o scale_color_manual(values = cvec)
  }

  # =========================================================================
  # 5. APLICAR TEMA Y AJUSTES FINALES
  # =========================================================================
  plt <- plt +
    ptheme +
    theme(
      # Ajustes específicos del gráfico
    )

  return(plt)
}
```

---

## Documentación Roxygen2

### Tags Obligatorios

Toda función exportada DEBE incluir:

```r
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Descripción de la función.

#' @param nombre Tipo. Descripción del parámetro.

#' @return Descripción de lo que retorna.

#' @export

#' @examples
#' # Ejemplo completo y reproducible
```

### Ejemplo Completo de Documentación

```r
#' Plot a Bar Chart following WJP style guidelines
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `wjp_bars()` takes a data frame with a specific data structure
#' (usually long shaped) and returns a ggplot object with a bar chart
#' following WJP style guidelines.
#'
#' @param data Data frame containing the data to plot.
#' @param target String. Column name of the variable with values to plot.
#' @param grouping String. Column name of the grouping variable.
#' @param colors String. Column name for color grouping. Default is NULL.
#' @param cvec Named vector with hex colors. Default is NULL.
#' @param ptheme ggplot theme. Default is WJP_theme().
#'
#' @return A ggplot object representing the bar chart.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#'
#' # Load WJP fonts (optional)
#' wjp_fonts()
#'
#' # Prepare data
#' data4bars <- data.frame(
#'   country = c("A", "B", "C"),
#'   value = c(45, 67, 23)
#' )
#'
#' # Create chart
#' wjp_bars(
#'   data4bars,
#'   target   = "value",
#'   grouping = "country"
#' )
```

---

## Patrones de Diseño Obligatorios

### 1. Formato de Datos: Long/Tidy

Todas las funciones esperan datos en formato largo (tidy):

```r
# CORRECTO - Formato largo
country    variable    value
"México"   "Police"    45
"México"   "Courts"    52
"Chile"    "Police"    67
"Chile"    "Courts"    71

# INCORRECTO - Formato ancho
country    Police    Courts
"México"   45        52
"Chile"    67        71
```

### 2. Vector de Colores (cvec)

El parámetro `cvec` SIEMPRE debe ser un vector nombrado:

```r
cvec <- c(
  "Category A" = "#482d8b",
  "Category B" = "#2894aa",
  "Category C" = "#f26b21"
)
```

Los nombres deben coincidir con los valores de la variable `colors`.

### 3. Manejo de Parámetros NULL

Siempre proporcionar valores por defecto sensatos:

```r
# Si colors es NULL, usar grouping como color
if (is.null(colors)) {
  data <- data %>%
    mutate(colors_var = grouping_var)
}

# Si cvec es NULL, no aplicar scale_*_manual
if (!is.null(cvec)) {
  plt <- plt + scale_fill_manual(values = cvec)
}
```

### 4. Tipografías

Usar SOLO las fuentes del paquete:

- `"Lato Full"` - Texto general
- `"Fraunces"` - Títulos (opcional)
- `"IBM Plex Sans"` - Alternativa

```r
geom_text(
  family   = "Lato Full",
  fontface = "bold"
)
```

### 5. Colores Institucionales

Colores WJP estándar para referencia:

```r
# Primarios
"#482d8b"  # Violeta WJP
"#2894aa"  # Teal-blue WJP
"#f26b21"  # Naranja WJP

# Grises
"#555659"  # Texto y elementos de apoyo
"#D0D1D3"  # Líneas de grilla

# Texto en fondos oscuros
"#ffffff"  # Blanco
```

### 6. Evitar Duplicados en Rename

Cuando múltiples parámetros pueden tener el mismo valor:

```r
# Si grouping == colors, no hacer doble rename
if (grouping == colors) {
  data <- data %>%
    mutate(colors_var = grouping_var)
} else {
  data <- data %>%
    rename(colors_var = all_of(colors))
}
```

---

## Checklist de Contribución

Antes de enviar un PR, verifica:

### Código

- [ ] Función sigue la estructura estándar
- [ ] Parámetros usan nombres estándar (`target`, `grouping`, `colors`, etc.)
- [ ] Manejo correcto de parámetros NULL
- [ ] No hay duplicados en rename cuando parámetros coinciden
- [ ] Usa `all_of()` para selección de columnas
- [ ] Colores aplicados solo si `cvec` no es NULL
- [ ] Tema aplicado con `ptheme` parameter
- [ ] Retorna objeto ggplot

### Documentación

- [ ] Roxygen2 completo con todos los tags obligatorios
- [ ] `@export` tag presente
- [ ] `lifecycle::badge()` en descripción
- [ ] Ejemplo reproducible y funcional
- [ ] Parámetros documentados con tipo y descripción

### Testing

- [ ] Ejemplo en documentación ejecuta sin errores
- [ ] `devtools::check()` pasa sin errores
- [ ] `devtools::document()` actualiza NAMESPACE

### Archivos

- [ ] Archivo nombrado como `{tipo}Chart.R`
- [ ] Agregada imagen de ejemplo en `man/figures/`
- [ ] Actualizado `data-raw/generate-examples.R`
- [ ] Actualizado `CLAUDE.md` con nueva función

---

## Proceso de Pull Request

### 1. Preparar el Entorno

```r
# Instalar dependencias de desarrollo
install.packages(c("devtools", "roxygen2", "testthat"))

# Clonar repositorio
# git clone https://github.com/worldjusticeproject-org/WJPr.git
```

### 2. Crear Rama

```bash
git checkout -b feature/nueva-funcion
```

### 3. Desarrollar

1. Crear archivo `R/nuevafuncionChart.R`
2. Escribir función siguiendo estructura estándar
3. Documentar con Roxygen2
4. Agregar ejemplo a `data-raw/generate-examples.R`

### 4. Verificar

```r
# Regenerar documentación
devtools::document()

# Verificar paquete
devtools::check()

# Probar localmente
devtools::load_all()
# Ejecutar ejemplo de la función
```

### 5. Generar Imagen de Ejemplo

```r
source("data-raw/generate-examples.R")
```

### 6. Commit y Push

```bash
git add .
git commit -m "Add wjp_nuevafuncion() chart type"
git push origin feature/nueva-funcion
```

### 7. Crear Pull Request

- Título descriptivo
- Descripción de cambios
- Screenshot del gráfico generado
- Checklist completado

---

## Preguntas Frecuentes

### ¿Cómo manejo datos haven_labelled?

Convierte a tipos nativos de R antes de procesar:

```r
data <- data %>%
  mutate(across(where(haven::is.labelled), ~ as.numeric(.x)))
```

### ¿Puedo agregar nuevas dependencias?

Consulta primero. Preferimos minimizar dependencias. Si es necesario:

1. Agregar a `Imports` en DESCRIPTION
2. Usar `paquete::funcion()` en el código
3. Documentar por qué es necesaria

### ¿Cómo pruebo sin instalar el paquete?

```r
devtools::load_all()  # Carga funciones sin instalar
```

---

## Contacto

- **Issues**: [GitHub Issues](https://github.com/worldjusticeproject-org/WJPr/issues)
- **Maintainer**: Carlos Toruño

¡Gracias por contribuir a WJPr!
