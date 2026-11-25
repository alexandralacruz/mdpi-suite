---
name: reviewer-mdpi-journal
description: Revisa un artículo científico con la rúbrica de evaluación de las revistas MDPI. Ejecuta primero el skill `reviewer` para el análisis técnico profundo (8 dimensiones), luego califica el manuscrito con una rúbrica ponderada (alcance/encaje con la revista, originalidad, significancia, solidez científica, presentación, interés para lectores, referencias e integridad ética) y emite un veredicto MDPI con plan de mejora, además de rellenar el formulario oficial MDPI (Report 1) con los datos del revisor. Use when se revisa un artículo para una revista MDPI, se simula una revisión antes de enviar, o se responde a revisores MDPI.
---

# Revisor de Artículos — Rúbrica de Revista MDPI

Revisa un artículo científico aplicando la **rúbrica de evaluación de las revistas MDPI**. Reutiliza el análisis profundo del skill `reviewer` (8 dimensiones) y lo convierte en una **calificación ponderada por criterio**, un **veredicto MDPI** y un **plan de mejora priorizado**, calibrado a los estándares editoriales de MDPI.

A diferencia de `reviewer-mdpi-perspective` (que replica el formulario oficial del revisor en inglés), este skill se centra en la **rúbrica de la revista**: puntúa cada criterio con bandas de desempeño y pesos, y entrega un diagnóstico de preparación para el envío. Al final, **rellena también el formulario oficial de revisión de MDPI (Report 1)** con las respuestas del revisor, listo para pegar en la interfaz de MDPI.

## Cuándo usarlo

- Revisar un artículo antes de enviarlo a una revista MDPI (dry-run de la rúbrica editorial)
- Actuar como revisor externo de un manuscrito para una revista MDPI
- Preparar una respuesta o revisión (rebuttal) para revisores MDPI
- Decidir si un manuscrito cumple el umbral de calidad de una revista MDPI concreta

## Cómo funciona este skill

Este skill hace **dos pasadas**:

1. **Análisis profundo** — invoca el skill `reviewer` (`/skill:reviewer`) y ejecuta su análisis de 8 dimensiones sobre el manuscrito: novedad y contribución, claridad y presentación, rigor metodológico, validez experimental, amenazas a la validez, reproducibilidad, referencias y estructura/encaje con el venue. Conserva fortalezas, debilidades, problemas críticos/mayores/menores, auditoría de figuras y preguntas esperadas de revisores.
2. **Rúbrica MDPI** — traduce esos hallazgos a la rúbrica ponderada de evaluación de la revista y emite el veredicto.

> Si aún no has ejecutado `reviewer`, hazlo primero (`/skill:reviewer`) con el mismo manuscrito. Si el skill `reviewer` no está disponible, realiza un análisis equivalente de 8 dimensiones antes de aplicar la rúbrica.

## Requisitos de entrada

1. **Manuscrito completo**: todas las secciones, figuras, tablas y referencias.
2. **Nombre de la revista MDPI y sección** (p. ej., *Sensors*, *Molecules*, *IJERPH*, *Applied Sciences*) para calibrar el alcance.
3. **Preocupaciones de los autores** (opcional) y **comentarios de revisores previos** (si es una re-envío).
4. **Rol del revisor**: dry-run del autor (simulación) o revisor real (informe final).

---

## La Rúbrica de Evaluación MDPI

La rúbrica evalúa el manuscrito con **8 criterios ponderados** y una **puerta ética** (si falla, el veredicto es Rechazo independientemente del puntaje). Puntúa cada criterio de 1 a 5 usando las bandas de desempeño indicadas.

### Criterios y pesos

| # | Criterio | Peso | Qué evalúa |
|---|----------|:----:|------------|
| 1 | Alcance y encaje con la revista (Scope & Journal Fit) | 10% | Pertinencia temática con el alcance y sección de la revista |
| 2 | Originalidad / Novedad (Originality/Novelty) | 20% | Qué aporta de nuevo frente a la literatura existente |
| 3 | Significancia del contenido (Significance of Content) | 15% | Relevancia e impacto potencial del problema y los hallazgos |
| 4 | Solidez científica y rigor metodológico (Scientific Soundness) | 25% | Validez del diseño, métodos, análisis y conclusiones |
| 5 | Calidad de la presentación (Quality of Presentation) | 10% | Claridad, organización, figuras/tablas y redacción |
| 6 | Interés para los lectores (Interest to Readers) | 5% | Atractivo y utilidad para la audiencia de la revista |
| 7 | Referencias (References) | 10% | Cobertura, actualidad, precisión y equilibrio de citas |
| 8 | Integridad ética (Ethics) — puerta | 5% | Plagio, autocitación inapropiada, ética en datos/sujetos |

### Bandas de desempeño (escala 1–5)

| Puntaje | Nivel | Significado |
|:-------:|-------|-------------|
| **5** | Excelente | Cumple sobradamente el criterio; sin objeciones |
| **4** | Bueno | Cumple el criterio con debilidades menores |
| **3** | Aceptable | Cumple lo esencial; requiere mejoras claras |
| **2** | Débil | Deficiencias importantes que comprometen el criterio |
| **1** | Crítico | No cumple el criterio; falla grave |

### Puerta ética (gate)

Si se detecta **plagio**, **fabricación de datos**, **manipulación de imágenes**, **autocitación abusiva** o **incumplimiento ético grave**, el veredicto es **Rechazo** independientemente del puntaje ponderado, y el hallazgo se detalla en los comentarios confidenciales.

---

## Traducción de las dimensiones de `reviewer` a la rúbrica

| Criterio de la rúbrica | Dimensión(es) de `reviewer` | Regla de puntuación |
|------------------------|------------------------------|---------------------|
| Alcance y encaje | Estructura y encaje con el venue | **5** = encaje total con el alcance; **3** = tangencial pero defendible; **1** = fuera de alcance |
| Originalidad / Novedad | Novedad y contribución | **5** = avance significativo; **3** = mejora incremental sólida; **1** = marginal o redundante |
| Significancia | Novedad (significancia del problema) + impacto | **5** = problema de alto impacto; **3** = relevante; **1** = trivial |
| Solidez científica | Rigor metodológico + Validez experimental + Amenazas a la validez | **5** = riguroso y válido; **3** = sólido con debilidades; **1** = métodos/validez defectuosos |
| Calidad de presentación | Claridad y presentación (+ auditoría de figuras) | **5** = claro y bien organizado; **3** = aceptable; **1** = mal redactado/organizado |
| Interés para lectores | Novedad (atractivo/amplitud) + significancia | **5** = interés amplio; **3** = nicho pero valioso; **1** = estrecho/desactualizado |
| Referencias | Referencias (cobertura, actualidad, autocitación) | **5** = cobertura completa y equilibrada; **3** = omisiones menores; **1** = omisiones graves o abuso |
| Integridad ética | Análisis ético + verificación de plagio/citas | **5** = sin problemas; **1** = hallazgo ético grave (gate) |

> La rúbrica es una guía; usa el juicio profesional. Cada puntuación debe respaldarse con evidencia (sección, figura, tabla o línea).

---

## Reglas de decisión para el veredicto

Convierte el **puntaje ponderado total** (y la gravedad de los hallazgos) al veredicto MDPI:

| Puntaje ponderado | Veredicto MDPI |
|:-----------------:|----------------|
| 4.5 – 5.0 | **Accept in present form** (Aceptar en su forma actual) |
| 3.5 – 4.4 | **Accept after minor revision** (Aceptar tras revisión menor) |
| 2.5 – 3.4 | **Reconsider after major revision** (Reconsiderar tras revisión mayor) |
| 1.0 – 2.4 | **Reject** (Rechazar) |

**Reglas de consistencia**:
- Si la puerta ética falla → **Reject** (sin excepción).
- Si algún criterio de peso alto (Solidez científica u Originalidad) puntúa 1–2, un "Accept in present form" no está justificado; indica la tensión en lugar de ocultarla.
- El veredicto debe ser coherente con las puntuaciones, los problemas críticos y el plan de mejora. Si hay inconsistencia, señálala explícitamente.

---

## Proceso de evaluación

1. **Ejecutar `reviewer`** (`/skill:reviewer`) sobre el manuscrito y conservar sus hallazgos.
2. **Verificar el alcance** contra la revista MDPI indicada (¿encaja el tema con la sección?).
3. **Puntuar cada criterio** (1–5) con evidencia concreta y calcular el ponderado.
4. **Aplicar la puerta ética** y las reglas de decisión.
5. **Redactar el informe** con la rúbrica, el veredicto, los problemas priorizados y el plan de mejora; **rellenar el formulario oficial MDPI (Report 1)** con las respuestas del revisor; y **guardar todo en un archivo** `[nombre_del_articulo]_review.md`.
6. **Verificar consistencia** entre puntuaciones, problemas y veredicto.

---

## Formato de salida

Emite el informe en este formato para que pueda transcribirse/pegarse y quede trazable. Además de mostrarlo en pantalla, **escribe el contenido completo en un archivo Markdown** llamado `[nombre_del_articulo]_review.md` (p. ej., `deep-learning-sensors_review.md`), reemplazando `[nombre_del_articulo]` por el nombre real del artículo.

```markdown
# Revisión con Rúbrica MDPI — [Título del artículo]
*Manuscrito: [Título]*
*Revista/Sección: [p. ej., Sensors — Sección "Intelligent Sensors"]*
*Fecha: [fecha]*
*Preparado por: reviewer-mdpi-journal (Academic Research Suite)*

---

## Veredicto

**Puntaje ponderado: [X.XX] / 5** — *[Nivel global]*
**Recomendación MDPI:** Accept in present form / Accept after minor revision / Reconsider after major revision / Reject

## Resumen de la rúbrica

| # | Criterio | Peso | Puntaje (1–5) | Ponderado | Justificación breve |
|---|----------|:----:|:-------------:|:---------:|---------------------|
| 1 | Alcance y encaje | 10% | [X] | [X.XX] | [Evidencia] |
| 2 | Originalidad / Novedad | 20% | [X] | [X.XX] | [Evidencia] |
| 3 | Significancia | 15% | [X] | [X.XX] | [Evidencia] |
| 4 | Solidez científica | 25% | [X] | [X.XX] | [Evidencia] |
| 5 | Calidad de presentación | 10% | [X] | [X.XX] | [Evidencia] |
| 6 | Interés para lectores | 5% | [X] | [X.XX] | [Evidencia] |
| 7 | Referencias | 10% | [X] | [X.XX] | [Evidencia] |
| 8 | Integridad ética | 5% | [X] | [X.XX] | [Evidencia] |
| **Total** | — | 100% | — | **[X.XX]** | |

*Puerta ética: [Superada / FALLIDA — hallazgo grave]*

---

## Detalle por criterio

### 1. Alcance y encaje con la revista [Puntaje: X/5]
**Fortalezas**: [Pertinencia con el alcance/sección de la revista]
**Debilidades**: [Desajuste temático o de sección]
**Recomendación**: [Revista/sección alternativa si el encaje es débil]

### 2. Originalidad / Novedad [Puntaje: X/5]
**Fortalezas**: [Qué es genuinamente nuevo]
**Debilidades**: [Solapamiento con trabajos previos, sobreafirmación]
**Recomendación**: [Cómo reforzar la percepción de novedad]

### 3. Significancia del contenido [Puntaje: X/5]
**Fortalezas**: [Relevancia del problema y de los hallazgos]
**Debilidades**: [Impacto limitado o poco articulado]
**Recomendación**: [Cómo enfatizar la significancia]

### 4. Solidez científica y rigor metodológico [Puntaje: X/5]
**Fortalezas**: [Diseño y análisis sólidos]
**Debilidades**: [Defectos de diseño, validez o conclusiones]
**Recomendación**: [Experimentos/análisis adicionales necesarios]

### 5. Calidad de la presentación [Puntaje: X/5]
**Fortalezas**: [Claridad y organización]
**Debilidades**: [Pasajes confusos, figuras/tablas deficientes, redacción]
**Recomendación**: [Reescrituras y mejoras de figuras]

### 6. Interés para los lectores [Puntaje: X/5]
**Fortalezas**: [Atractivo para la audiencia]
**Debilidades**: [Interés estrecho o desactualizado]
**Recomendación**: [Cómo ampliar el atractivo]

### 7. Referencias [Puntaje: X/5]
**Fortalezas**: [Cobertura adecuada]
**Debilidades**: [Omisiones, citas irrelevantes, autocitación, desactualización]
**Recomendación**: [Citas concretas a añadir o reconsiderar]

### 8. Integridad ética [Puntaje: X/5]
**Hallazgos**: [Ninguno / hallazgo concreto con evidencia]
*(Si hay hallazgos graves, detállalos solo en los comentarios confidenciales.)*

---

## Problemas críticos (bloquean la aceptación)

| # | Problema | Severidad | Criterio afectado | Sección | Cómo corregirlo |
|---|----------|-----------|-------------------|---------|-----------------|
| 1 | [Problema] | 🔴 Crítico | [Criterio] | [Sección] | [Acción] |

## Problemas mayores (deben corregirse)

| # | Problema | Severidad | Criterio afectado | Sección | Cómo corregirlo |
|---|----------|-----------|-------------------|---------|-----------------|
| 1 | [Problema] | 🟠 Mayor | [Criterio] | [Sección] | [Acción] |

## Problemas menores (conviene corregir)

| # | Problema | Severidad | Criterio afectado | Sección | Cómo corregirlo |
|---|----------|-----------|-------------------|---------|-----------------|
| 1 | [Problema] | 🟡 Menor | [Criterio] | [Sección] | [Acción] |

---

## Plan de mejora priorizado

| Prioridad | Acción | Esfuerzo | Impacto en el puntaje |
|-----------|--------|:--------:|:---------------------:|
| 1 | [Mayor impacto / menor esfuerzo] | Bajo/Medio/Alto | Alto/Medio |
| 2 | ... | ... | ... |

---

## Comentarios para los autores

[Resumen del trabajo → puntos mayores → puntos menores → ediciones por sección. Constructivo y accionable; sin hallazgos éticos confidenciales.]

## Comentarios confidenciales (no mostrados a los autores)

[Solo hallazgos éticos, sospechas de mala conducta y preocupaciones confidenciales. "Ninguno" si no aplica.]

---

## Formulario oficial MDPI — Report 1

*Información del revisor (rellena con los datos reales):*

| Campo | Valor |
|-------|-------|
| Name | Dr. Alexandra La Cruz |
| Email | alexandra.lacruz@unibague.edu.co |

### Recommendations for Authors *(se mostrará a los autores)*

*Las respuestas a las siguientes preguntas no reemplazan los comentarios específicos para los autores. Da más detalle en el recuadro "Comments and Suggestions for Authors".*

| Pregunta | Respuesta |
|----------|-----------|
| Does the introduction provide sufficient background and include all relevant references? | Yes / Can be improved / Must be improved / Not applicable |
| Is the research design appropriate? | Yes / Can be improved / Must be improved / Not applicable |
| Are the methods adequately described? | Yes / Can be improved / Must be improved / Not applicable |
| Are the results clearly presented? | Yes / Can be improved / Must be improved / Not applicable |
| Are the conclusions supported by the results? | Yes / Can be improved / Must be improved / Not applicable |
| Are all figures and tables clear and well-presented? | Yes / Can be improved / Must be improved / Not applicable |

### Quality of English Language

- [ ] The English could be improved to more clearly express the research.
- [ ] The English is fine and does not require any improvement.

### Recommendations for Editors *(no se mostrará a los autores)*

*Si respondiste "Yes" a alguna de las siguientes preguntas, da detalles en el recuadro "Comments for Editors".*

| Pregunta | Respuesta |
|----------|-----------|
| Do you have any potential conflicts of interest with regard to this paper? | Yes / No |
| Did you detect plagiarism? | Yes / No |
| Did you detect inappropriate self-citations by authors? | Yes / No |
| Do you have any other ethical concerns about this study? | Yes / No |

### Ratings

| Criterio | Rating |
|----------|--------|
| Originality/Novelty | High / Average / Low / No Answer |
| Significance of Content | High / Average / Low / No Answer |
| Quality of Presentation | High / Average / Low / No Answer |
| Scientific Soundness | High / Average / Low / No Answer |
| Interest to Readers | High / Average / Low / No Answer |
| Overall Merit | High / Average / Low / No Answer |

### References

**Are the references cited in this manuscript appropriate and relevant to this research?** Yes / No

### Comments

**Comments and Suggestions for Authors** *(se mostrará a los autores)*

[Transcribe aquí los "## Comentarios para los autores" redactados arriba.]

**Comments for Editors** *(no se mostrará a los autores)*

[Transcribe aquí los "## Comentarios confidenciales" redactados arriba; "None" si no aplica.]

### Overall Recommendation

- [ ] Accept in present form
- [ ] Accept after minor revision (corrections to minor methodological errors and text editing)
- [ ] Reconsider after major revision (substantial revisions to text or experimental methods needed)
- [ ] Reject (article has serious flaws, additional experiments needed, research not conducted correctly)

### Cómo rellenar el Report 1 desde la rúbrica

| Campo del Report 1 | Se alimenta de |
|--------------------|----------------|
| Recommendations for Authors (6 preguntas) | Dimensiones de `reviewer` (claridad, rigor, validez, reproducibilidad, figuras) |
| Originality/Novelty | Criterio 2 (Originalidad): High = 5/4, Average = 3, Low = 2/1 |
| Significance of Content | Criterio 3 (Significancia) |
| Quality of Presentation | Criterio 5 (Presentación) |
| Scientific Soundness | Criterio 4 (Solidez científica) |
| Interest to Readers | Criterio 6 (Interés) |
| Overall Merit | Puntaje ponderado total |
| References | Criterio 7 (Referencias) |
| Recommendations for Editors | Puerta ética / Criterio 8 (Integridad ética) |
| Overall Recommendation | Veredicto (reglas de decisión) |

---

## Justificación interna (NO forma parte del informe — no enviar)

| Criterio | Puntaje | Evidencia / dimensión de `reviewer` |
|----------|:-------:|-------------------------------------|
| 1. Alcance y encaje | [X] | [Evidencia] |
| 2. Originalidad | [X] | [Evidencia] |
| ... | ... | ... |
| Veredicto | [X] | [Regla de decisión aplicada] |

**Verificación de consistencia:** [Confirma que puntuaciones, problemas y veredicto cuentan la misma historia; señala cualquier tensión.]
```

---

## Principios de revisión

1. **Ser decisivo**: cada criterio recibe un puntaje único y el veredicto es una sola opción — sin ambigüedades.
2. **Evidencia, no impresión**: cada puntaje, problema y recomendación debe citar sección, figura, tabla o línea. No inventar evidencia.
3. **Separar lo confidencial**: los hallazgos éticos van solo en los comentarios confidenciales, nunca en los comentarios para autores.
4. **Constructivo con los autores**: incluso un "Reject" va acompañado de retroalimentación respetuosa y accionable.
5. **Calibrar por revista**: el encaje (criterio 1) y los pesos pueden ajustarse si la revista define su propio alcance/prioridades.
6. **Mantener consistencia**: puntuaciones, problemas críticos y veredicto deben narrar la misma historia; si no, señalarlo.
7. **Puerta ética siempre**: un hallazgo ético grave anula el puntaje y fuerza "Reject".

## Integración

- **Entrada de**: `reviewer` (análisis profundo de 8 dimensiones) — ejecútalo siempre primero.
- **Complementa**: `reference-checker` (criterio de referencias), `plagiarism-checker` (puerta ética), `journal-selector` (confirmar encaje MDPI).
- **Salida a**: `research-manager` (planificación de la revisión tras la simulación) o directamente al autor/investigador como informe listo para MDPI.
- **Iteración**: revisar → corregir → volver a ejecutar `reviewer-mdpi-journal` hasta alcanzar el umbral deseado.
- **Complemento de forma**: `reviewer-mdpi-perspective` para rellenar el formulario oficial del revisor una vez superada la rúbrica.
