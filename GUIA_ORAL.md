# Fireboy & Watergirl (Processing)

| Pestaña                | Qué hace                                                                    |
| ---------------------- | --------------------------------------------------------------------------- |
| `FireboyWatergirl.pde` | Pestaña principal: variables globales, `setup()`, `draw()`, teclado y ratón |
| `Personajes.pde`       | Clase `Personaje`: movimiento, gravedad, salto, colisiones, dibujo          |
| `Objetos.pde`          | Gemas, peligros, interruptores, puertas, salidas, plataformas móviles       |
| `Niveles.pde`          | Los 10 mapas como texto, `cargarNivel()`, dibujo del mapa                   |
| `Menu.pde`             | Clase `BotonMenu`, menú principal, ayuda, selección de nivel                |
| `Pantallas.pde`        | HUD (marcador), pausa, victoria, completar nivel                            |
| `Sonido.pde`           | Sonidos fabricados con ondas (sin archivos de audio)                        |
| `Guardado.pde`         | Guarda/carga el progreso en `progreso.txt`                                  |
| `Red.pde`              | Juego en LAN: servidor, cliente, mensajes                                   |

---

## 1. Cómo funciona un programa de Processing

- `setup()` se ejecuta **una vez** al empezar.
- `draw()` se ejecuta **60 veces por segundo** (`frameRate(60)`). Cada ejecución es un _frame_ (fotograma).
- `keyPressed()`, `keyReleased()` y `mousePressed()` las llama Processing solo cuando pasa ese evento.

Todo el juego se basa en eso: en cada frame se **actualiza** (se mueve todo y se aplican reglas) y después se **dibuja**.

---

## 2. Pestaña principal (`FireboyWatergirl.pde`)

### Variables globales

- `TAM = 32`: cada casilla mide 32×32 px. `COLUMNAS = 30`, `FILAS = 20` → ventana de 960×640 (`size(960, 640)`).
- `final` = constante, no se puede cambiar.
- **Estados (pantallas)**: `MENU, SELECCION, AYUDA, JUGANDO, PAUSA, VICTORIA, RED, ESPERA` son números (0 a 7). La variable `estado` dice en qué pantalla estamos. Esto se llama **máquina de estados**.
- `char[][] mapa`: matriz de 20 filas × 30 columnas con una letra por casilla.
- `fuego`, `agua`: los dos objetos `Personaje`.
- `ArrayList` de gemas, interruptores y plataformas: listas que crecen según lo que tenga cada nivel.
- `puertaAbierta[0]` = puertas X (moradas), `[1]` = puertas Y (amarillas).
- `teclaA, teclaD, teclaW, teclaIzq...`: booleanos que valen `true` mientras la tecla está apretada.

### `setup()`

Pone el tamaño y los FPS, carga el progreso guardado, crea los botones, fabrica los sonidos y arranca la música en bucle (`Clip.LOOP_CONTINUOUSLY`).

### `draw()`

1. `actualizarRed()` → lee lo que llegó por la red.
2. Según `estado`, dibuja la pantalla que toca (if / else if).
   - En `JUGANDO`: si **no** soy invitado, llamo a `actualizarJuego()` (calcular). Siempre llamo a `dibujarJuego()`.
   - En `PAUSA` y `VICTORIA` se dibuja el juego de fondo y encima el panel.
3. `enviarRed()` → manda el estado o las teclas.

### `actualizarJuego()` — el corazón del juego

1. Suma 1 al cronómetro `framesNivel` (60 frames = 1 segundo).
2. Si alguien murió (`tiempoMuerte > 0`), descuenta; al llegar a 0 reinicia el nivel. `return` para no mover nada mientras tanto.
3. Mueve las plataformas **primero** (porque arrastran a los personajes).
4. Mueve a Fuego y Agua con sus teclas. En red, el anfitrión maneja a Fuego con cualquier tecla, y Agua usa `remotoIzq/Der/Salto` (lo que llegó del otro ordenador).
5. Comprueba gemas → puertas → peligros → salidas.

### `dibujarJuego()`

Dibuja en orden de "capas": fondo → mapa → salidas → botones → plataformas → gemas → personajes (si están vivos) → HUD → mensaje de muerte. Lo último que se dibuja queda encima.

### Teclado

- **ESC**: normalmente cierra Processing. Se hace `key = 0` para "anularla" y usarla como pausa.
- En la pantalla `RED` el teclado sirve para escribir la IP.
- `cambiarTecla(true/false)`: en `keyPressed` pone la tecla en `true` y en `keyReleased` en `false`. **¿Por qué así y no mover directamente en keyPressed?** Porque `keyPressed` solo avisa una vez (y repite lento); guardando booleanos el personaje se mueve fluido y **los dos jugadores pueden apretar teclas a la vez** sin pisarse.
- Flechas: `key == CODED` y se mira `keyCode` (LEFT, RIGHT, UP). Letras: `Character.toLowerCase(key)` para aceptar mayúscula y minúscula.
- `soltarTeclas()`: pone todo en false al cambiar de pantalla, para que nadie siga caminando solo.

### Ratón

`mousePressed()` mira el estado y llama a la función de click de esa pantalla.

---

## 3. Personajes y física (`Personajes.pde`)

### Constantes de física

| Constante             | Valor  | Significado                                                              |
| --------------------- | ------ | ------------------------------------------------------------------------ |
| `ANCHO_PJ`, `ALTO_PJ` | 22, 28 | La "caja de colisión" (rectángulo invisible)                             |
| `VELOCIDAD`           | 3      | píxeles por frame al caminar                                             |
| `GRAVEDAD`            | 0.5    | cuánto aumenta la velocidad de caída cada frame                          |
| `FUERZA_SALTO`        | 10.2   | velocidad inicial hacia arriba                                           |
| `CAIDA_MAXIMA`        | 10     | límite de velocidad cayendo                                              |
| `MARGEN_PELIGRO`      | 6      | px que pueden sobresalir sobre un líquido sin morir (para ser más justo) |

### Clase `Personaje`

Atributos: `x, y` (esquina superior izquierda), `vx, vy` (velocidad), `enSuelo`, `esFuego`, `vivo`, `enSalida`.
El **constructor** recibe si es Fuego y su posición inicial (`this.x = x` distingue el atributo del parámetro).

### `actualizar(izquierda, derecha, saltar)`

1. `vx = 0`, y suma o resta `VELOCIDAD` según las teclas.
2. Si salta **y** está en el suelo → `vy = -FUERZA_SALTO` (negativo = hacia arriba, porque en Processing la Y crece hacia abajo). Así no puede saltar en el aire.
3. Gravedad: `vy += GRAVEDAD` cada frame → la caída se acelera (parábola). Se limita con `CAIDA_MAXIMA`.
4. **Primero se mueve en X y después en Y** (`moverX`, `moverY`). Separarlo hace las colisiones sencillas: si choco en X sé que es una pared, si choco en Y es suelo o techo.

### Colisiones con el mapa (`moverX`, `moverY`)

El mapa es una cuadrícula, así que para saber en qué casilla está un punto se divide por 32: `floor(x / TAM)`.

- `moverX`: avanza, mira la columna del borde hacia donde va y todas las filas que ocupa. Si alguna es sólida, lo "pega" a la pared (`x = col * TAM - ANCHO_PJ`).
- `moverY`: si cae (`dy > 0`) mira la fila de los pies; si es sólida lo apoya, `vy = 0` y `enSuelo = true`. Si sube mira la fila de la cabeza (techo).
- El `- 0.01` evita que un borde justo en 32 cuente como la casilla siguiente.
- **Plataformas móviles** solo se pisan desde arriba: se compara `pieAnterior` (dónde estaban los pies antes de moverse) con la altura de la plataforma. Si antes estaba arriba y ahora la atravesó, se queda encima.

### Otros métodos

- `tocaRect(...)`: colisión entre dos rectángulos (técnica **AABB**). Se solapan si en X y en Y se superponen. Se usa para gemas e interruptores.
- `estaEnCasilla(col, fila)`: si el **centro** del personaje está en la casilla de su puerta.
- `estaSobre(p)`: si está parado sobre una plataforma (pies a menos de 2 px de ella).
- `tocaPeligro()`: devuelve una letra con la causa: `'v'` vacío (cayó debajo de la pantalla), `'V'` ácido, `'W'` agua (si es Fuego), `'L'` lava (si es Agua), `' '` nada. Mira las casillas justo debajo de los pies.

### Funciones sueltas

- `casilla(col, fila)`: devuelve la letra. Fuera del mapa: a los lados y arriba devuelve pared `'#'`, abajo devuelve aire `'.'` → por eso se puede caer al vacío.
- `esSolido`: bloques y **líquidos** son sólidos (se camina encima del líquido, lo que mata es pisarlo). Las puertas X/Y son sólidas solo si están cerradas.
- `dibujarPersonaje`: con primitivas: `rect` (cuerpo), `triangle` (llama/gota), `ellipse` (ojos). Es una función aparte para reutilizarla en el menú.

---

## 4. Objetos (`Objetos.pde`)

### Gemas

- Clase `Gema` con `col`, `fila`, `roja`, `recogida`. Se dibuja como rombo con `quad`.
- `comprobarGemas()`: `Personaje p = g.roja ? fuego : agua;` (operador ternario) → cada uno solo recoge las de su color. Si la toca: `recogida = true`, suma al contador, suena.

### Peligros

- `comprobarPeligros()`: pregunta a cada uno `tocaPeligro()` y si hay causa llama a `matar`.
- `matar()`: `vivo = false`, `tiempoMuerte = 75` (≈1,25 s), sonido, guarda la causa y arma el mensaje con `textoMuerte()`.

### Interruptores y puertas

- Clase `Interruptor` con `grupo` (0 = X morado, 1 = Y amarillo).
- `actualizar()`: está pulsado **mientras** Fuego o Agua lo pisan. Guarda `antes` para que el sonido suene solo al empezar a pisarlo.
- `actualizarPuertas()`: para cada grupo, la puerta se abre si **algún** interruptor de ese grupo está pulsado. Detalle importante: **nunca cierra una puerta si hay un personaje adentro** (`personajeEnPuerta`), así no queda atrapado.

### Salidas

- `comprobarSalidas()`: si los dos están en su puerta, suma `tiempoSalida`; al pasar 40 frames → `completarNivel()`. Si alguno sale, vuelve a 0.
- La puerta se ve oscura (abierta) cuando su personaje está delante.

### Plataformas móviles

- Guardan inicio y fin, y un `progreso` de 0 a 1. La posición se calcula con `lerp(inicio, fin, progreso)` (**interpolación lineal**: lerp(a, b, 0.5) = punto medio).
- Avanza `VELOCIDAD_PLATAFORMA / distancia` por frame, así va a la misma velocidad sin importar lo larga que sea. `max(1, ...)` evita dividir por 0.
- Al llegar a un extremo invierte `sentido` y espera 45 frames.
- **Arrastre**: antes de moverse mira quién está encima; después mueve a esos personajes lo mismo que se movió ella (`x - viejoX`), usando `moverX/moverY` para que respeten las paredes.

---

## 5. Niveles (`Niveles.pde`)

- Cada nivel es un `String[]` de 20 textos de 30 letras. **Cada letra es una casilla**. Es fácil de diseñar y modificar: es "dibujar con letras".
- Leyenda: `#` piedra, `.` aire, `L` lava, `W` agua, `V` ácido, `f`/`a` inicio de Fuego/Agua, `F`/`A` puertas de salida, `r`/`b` gemas, `x`/`y` botones, `X`/`Y` puertas.
- `MOVILES_n`: cada plataforma es `{columna, fila, ancho, columnaFinal, filaFinal}`.
- `MAPAS` (arreglo de arreglos) y `MOVILES` (arreglo 3D) juntan los 10 niveles para elegirlos por número.

### `cargarNivel(numero)`

1. Limpia las listas y contadores. `idCarga++` (para la red).
2. Recorre las 20×30 casillas con dos `for` y `charAt(c)`:
   - Las letras de objetos (`f, a, F, A, r, b, x, y`) **crean el objeto** y en el mapa dejan aire `'.'`.
   - Las demás (bloques, líquidos, puertas) se copian al `mapa`.
   - La posición en píxeles es `columna * TAM` (+5, +4 para centrarlo).
3. Crea las plataformas móviles.
4. Reinicia puertas, gemas, tiempos, teclas y pone `estado = JUGANDO`.

`reiniciarNivel()` simplemente vuelve a cargar el mismo nivel.

`dibujarMapa()`: recorre la matriz; los bloques son `rect` marrón, los líquidos son el mismo bloque con una franja de color arriba; las puertas X/Y se dibujan solo si están cerradas.

---

## 6. Menús (`Menu.pde`)

- Clase `BotonMenu` (x, y, ancho, alto, texto):
  - `encima()`: compara `mouseX`/`mouseY` con el rectángulo.
  - `dibujar()`: cambia de color si el ratón está encima (efecto _hover_).
- `crearBotones()`: crea todos los botones una vez. Los de selección de nivel se ubican en 2 columnas de 5 con `i / 5` (división entera → columna) e `i % 5` (resto → fila).
- Menú principal: el botón Jugar dice "Continuar (nivel N)" si ya avanzaste.
- Selección: los niveles mayores a `nivelDesbloqueado` se dibujan grises como "Bloqueado" y no se pueden clickear (el `for` del click solo llega hasta `nivelDesbloqueado`).
- `contarCompletados()`: cuenta los `true` del arreglo.

---

## 7. Pantallas (`Pantallas.pde`)

- `dibujarHUD()`: barra negra semitransparente (`fill(0, 150)`: el segundo número es la transparencia) con nivel, gemas, tiempo (`framesNivel / 60`) y botón de pausa.
- `dibujarPanel()`: oscurece toda la pantalla y escribe un título; lo usan pausa y victoria.
- `textoBotonSalir()`: el mismo botón dice "Menú principal", "Sala de red" o "Salir de la partida" según el modo.
- `completarNivel()`: marca el nivel como completado, desbloquea el siguiente (si existe y no estaba ya desbloqueado), **guarda en el archivo**, suena y pasa a `VICTORIA`.
- En el último nivel (`esUltimoNivel()`) se muestra un mensaje de victoria final y no aparece "Siguiente nivel".
- El invitado no ve los botones de reanudar/siguiente: solo el anfitrión controla.

---

## 8. Sonido (`Sonido.pde`)

**No hay archivos de audio: los sonidos se calculan con matemática al arrancar.**

- Un sonido digital es una lista de **muestras** (números entre -1 y 1). `FREC_MUESTREO = 22050` muestras por segundo.
- `tono(frecInicio, frecFin, segundos)`: genera una **onda cuadrada** (`sin(fase) > 0 ? 1 : -1`, sonido "retro" de consola). La frecuencia va de inicio a fin con `lerp` → salto sube, muerte baja. El volumen `(1 - t)` se apaga poco a poco.
- `crearMusica()`: 32 notas. Cada número es semitonos respecto a La (440 Hz). Fórmula musical: `frecuencia = 440 * 2^(semitonos/12)` (subir 12 semitonos = una octava = el doble de frecuencia). Usa onda seno (más suave).
- `crearClip()`: convierte las muestras a bytes de **16 bits** (2 bytes por muestra, primero el bajo: _little endian_, por eso el `false` en `AudioFormat`), y crea un `Clip` de Java. El `open` se llama por **reflexión** (`getMethod("open"...).invoke`) porque Processing 4.5 daba un error falso con la palabra `open`. Si no hay tarjeta de sonido, el `try/catch` devuelve `null` y el juego sigue en silencio.
- `reproducir()`: detiene, rebobina a 0 y vuelve a sonar. Si es `null` no hace nada.

---

## 9. Guardado (`Guardado.pde`)

- Archivo de texto `progreso.txt` con formato `nombre=valor`:
  ```
  desbloqueado=3
  completados=1110000000
  ```
  `completados` es una cadena de 10 caracteres: `1` = completado.
- `guardarProgreso()`: arma las líneas y las escribe con `saveStrings(sketchPath(...))` (`sketchPath` = carpeta del sketch).
- `cargarProgreso()`: si el archivo no existe, se empieza de cero. Si existe, separa cada línea por `=` con `split`. `constrain()` asegura que el número quede entre 0 y 9 aunque alguien edite mal el archivo.
- Se usa `try/catch` para que un error de disco no cierre el juego.

---

## 10. Red (`Red.pde`)

### Idea general

- Los dos ordenadores ejecutan **el mismo programa**.
- **Anfitrión** (pulsa "Crear partida"): crea un `Server` en el **puerto 5204**, juega con Fuego y **calcula todo** (física, gemas, muertes).
- **Invitado** (pulsa "Unirse" y escribe la IP): crea un `Client`, juega con Agua, **solo manda sus teclas y dibuja** lo que le dice el anfitrión.
- Esto se llama **cliente-servidor con servidor autoritativo**: como solo uno calcula, nunca pueden ver cosas distintas.
- Protocolo **TCP** (con `processing.net`): garantiza que los mensajes llegan completos y en orden.

`modoRed` puede ser `LOCAL` (0, mismo teclado), `ANFITRION` (1) o `INVITADO` (2).

### Mensajes (texto, terminan en `\n`, campos separados por `|`)

| Mensaje              | Sentido              | Contenido                                            |
| -------------------- | -------------------- | ---------------------------------------------------- |
| `K\|izq\|der\|salto` | invitado → anfitrión | teclas de Agua con 1/0. Ej: `K\|0\|1\|1`             |
| `S\|...`             | anfitrión → invitado | estado completo del juego (17 campos)                |
| `M`                  | anfitrión → invitado | "estoy en los menús" → el invitado muestra la espera |

Se usa texto porque es fácil de leer al depurar y de partir con `split()`.

### Campos del mensaje `S` (`crearMensajeEstado`)

`S | idCarga | nivel | estado | fuego | agua | gemas | rojas | azules | puertaX | puertaY | tiempoMuerte | causa | muertoEsFuego | cronómetro | botones | plataformas`

- Personaje: `x;y;vivo;enSalida`.
- Gemas y botones: cadena de bits, ej `0110` (una letra por gema).
- Plataformas: `x;y;x;y;...`.

### `idCarga`

Cada vez que el anfitrión carga o reinicia un nivel suma 1. Si al invitado le llega un número distinto al que tiene, **carga ese nivel** (para tener el mapa, las gemas, etc.) y después aplica los datos. Así no hace falta mandar el mapa entero.

### Recibir y enviar

- `actualizarRed()` (al **principio** de `draw`): lee todas las líneas completas con `readStringUntil('\n')` en un `while`. Si no llegó una línea entera devuelve `null` y espera al próximo frame → **nunca bloquea** el juego.
- `enviarRed()` (al **final** de `draw`): el anfitrión manda `S` (si está jugando) o `M`; el invitado manda `K`. Una vez por frame = 60 por segundo.
- `aplicarEstado()`: el invitado convierte el texto a números con `int()` / `float()` y lo copia a sus variables. El mensaje de muerte se reconstruye con `textoMuerte()` en vez de mandar el texto (con tildes) por la red.

### Hilos

- `unirsePartida()` usa `thread("conectarEnSegundoPlano")`: conectar a una IP que no responde puede tardar segundos; en otro hilo, la ventana no se congela. La variable `conectando` evita conectar dos veces.
- `serverEvent()`: Processing la llama cuando alguien se conecta. Si ya hay compañero, **rechaza** al tercero.
- `disconnectEvent()`: se llama cuando se cae una conexión. Solo pone `companeroSeFue = true`; el hilo principal lo revisa en el siguiente frame y vuelve a la sala con un aviso. (Los hilos de red no tocan el juego directamente → no hay problemas de concurrencia.)

### Otras

- `obtenerIPs()`: recorre las tarjetas de red de Java (`NetworkInterface`), saltea las apagadas, _loopback_ (127.0.0.1) y virtuales, y muestra las IPv4 para que el invitado sepa qué escribir.
- `escribirIP()`: acepta solo números y puntos, Backspace borra, Enter conecta.
- `desconectar()`: cierra servidor/cliente, pone todo en `null` y vuelve a modo `LOCAL`.
