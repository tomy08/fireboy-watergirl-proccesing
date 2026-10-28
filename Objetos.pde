// =====================================================================
// 9. GEMAS, PELIGROS, INTERRUPTORES Y PUERTAS
// =====================================================================

// ---------------------------------------------------------------------
// Gemas
// ---------------------------------------------------------------------
class Gema {
  int col, fila;
  boolean roja;          // true = roja (Fuego), false = azul (Agua)
  boolean recogida = false;

  Gema(int col, int fila, boolean roja) {
    this.col = col;
    this.fila = fila;
    this.roja = roja;
  }

  void dibujar() {
    if (recogida) return;
    float cx = col * TAM + TAM / 2;
    float cy = fila * TAM + TAM / 2;
    noStroke();
    if (roja) fill(255, 60, 70);
    else fill(50, 170, 255);
    quad(cx, cy - 11, cx + 9, cy, cx, cy + 11, cx - 9, cy);   // rombo
  }
}

void comprobarGemas() {
  for (Gema g : gemas) {
    if (g.recogida) continue;
    Personaje p = g.roja ? fuego : agua;   // cada personaje solo recoge las de su color
    if (p.tocaRect(g.col * TAM + 6, g.fila * TAM + 6, 20, 20)) {
      g.recogida = true;
      if (g.roja) gemasRojas++;
      else gemasAzules++;
      reproducir(sonidoGema);
    }
  }
}


// ---------------------------------------------------------------------
// Peligros: lava, agua, ácido y vacío
// ---------------------------------------------------------------------
void comprobarPeligros() {
  char causaFuego = fuego.tocaPeligro();
  char causaAgua = agua.tocaPeligro();
  if (causaFuego != ' ') matar(fuego, causaFuego);
  else if (causaAgua != ' ') matar(agua, causaAgua);
}

void matar(Personaje p, char causa) {
  p.vivo = false;
  tiempoMuerte = 75;               // algo más de un segundo antes de reiniciar
  reproducir(sonidoMuerte);
  causaMuerte = causa;             // se guardan para enviarlos por la red
  muertoEsFuego = p.esFuego;
  mensajeMuerte = textoMuerte(causa, p.esFuego);
}

String textoMuerte(char causa, boolean esFuego) {
  String nombre = esFuego ? "Fuego" : "Agua";
  if (causa == 'W') return "¡Fuego se ha apagado en el agua!";
  if (causa == 'L') return "¡Agua se ha evaporado en la lava!";
  if (causa == 'V') return "¡" + nombre + " ha tocado el ácido!";
  return "¡" + nombre + " ha caído al vacío!";
}


// ---------------------------------------------------------------------
// Interruptores (botones del suelo) y puertas X / Y
// ---------------------------------------------------------------------
class Interruptor {
  int col, fila, grupo;    // grupo 0 abre las puertas X, grupo 1 abre las Y
  boolean pulsado = false;

  Interruptor(int col, int fila, int grupo) {
    this.col = col;
    this.fila = fila;
    this.grupo = grupo;
  }

  // Está pulsado mientras uno de los dos personajes lo pisa
  void actualizar() {
    float bx = col * TAM + 4;
    float by = fila * TAM + TAM - 8;
    boolean antes = pulsado;
    pulsado = fuego.tocaRect(bx, by, TAM - 8, 8) || agua.tocaRect(bx, by, TAM - 8, 8);
    if (pulsado && !antes) reproducir(sonidoInterruptor);
  }

  void dibujar() {
    noStroke();
    fill(colorGrupo(grupo));
    float alto = pulsado ? 2 : 7;            // se hunde al pisarlo
    rect(col * TAM + 6, fila * TAM + TAM - alto, TAM - 12, alto);
  }
}

color colorGrupo(int grupo) {
  if (grupo == 0) return color(170, 80, 255);   // morado (X)
  return color(255, 195, 30);                   // amarillo (Y)
}

void actualizarPuertas() {
  for (Interruptor i : interruptores) i.actualizar();

  for (int g = 0; g < 2; g++) {
    boolean abrir = false;
    for (Interruptor i : interruptores) {
      if (i.grupo == g && i.pulsado) abrir = true;
    }
    // Nunca cerramos una puerta encima de un personaje
    if (!abrir && puertaAbierta[g] && personajeEnPuerta(g)) abrir = true;

    if (abrir && !puertaAbierta[g]) reproducir(sonidoPuerta);
    puertaAbierta[g] = abrir;
  }
}

boolean personajeEnPuerta(int grupo) {
  char letra = grupo == 0 ? 'X' : 'Y';
  for (int f = 0; f < FILAS; f++) {
    for (int c = 0; c < COLUMNAS; c++) {
      if (mapa[f][c] == letra) {
        if (fuego.tocaRect(c * TAM, f * TAM, TAM, TAM) || agua.tocaRect(c * TAM, f * TAM, TAM, TAM)) return true;
      }
    }
  }
  return false;
}


// ---------------------------------------------------------------------
// Puertas de salida
// ---------------------------------------------------------------------
void comprobarSalidas() {
  fuego.enSalida = fuego.estaEnCasilla(salidaFuegoCol, salidaFuegoFila);
  agua.enSalida = agua.estaEnCasilla(salidaAguaCol, salidaAguaFila);

  if (fuego.enSalida && agua.enSalida) {
    tiempoSalida++;
    if (tiempoSalida == 1) reproducir(sonidoPuerta);
    if (tiempoSalida > 40) completarNivel();       // pestaña Pantallas
  } else {
    tiempoSalida = 0;
  }
}

void dibujarSalidas() {
  dibujarSalida(salidaFuegoCol, salidaFuegoFila, true, fuego.enSalida);
  dibujarSalida(salidaAguaCol, salidaAguaFila, false, agua.enSalida);
}

// La puerta ocupa su casilla y la de encima. Se ve oscura (abierta)
// cuando su personaje está delante.
void dibujarSalida(int col, int fila, boolean deFuego, boolean abierta) {
  stroke(255);
  strokeWeight(2);
  if (abierta) fill(30);
  else if (deFuego) fill(230, 70, 40);
  else fill(40, 120, 230);
  rect(col * TAM, fila * TAM - TAM, TAM, TAM * 2, 8, 8, 0, 0);
  noStroke();
}


// ---------------------------------------------------------------------
// Plataformas móviles
// ---------------------------------------------------------------------
final float VELOCIDAD_PLATAFORMA = 1.5;   // píxeles por frame

class PlataformaMovil {
  float x, y, ancho;
  float xInicio, yInicio, xFin, yFin;
  float progreso = 0;    // 0 = en el inicio, 1 = en el final
  float sentido = 1;
  float distancia;
  int espera = 0;        // pausa en cada extremo para subir con calma

  PlataformaMovil(int col, int fila, int anchoCasillas, int colFin, int filaFin) {
    xInicio = col * TAM;
    yInicio = fila * TAM;
    xFin = colFin * TAM;
    yFin = filaFin * TAM;
    ancho = anchoCasillas * TAM;
    x = xInicio;
    y = yInicio;
    distancia = max(1, dist(xInicio, yInicio, xFin, yFin));
  }

  void actualizar() {
    // ¿quién está encima ANTES de moverse?
    boolean llevaFuego = fuego.estaSobre(this);
    boolean llevaAgua = agua.estaSobre(this);
    float viejoX = x;
    float viejoY = y;

    if (espera > 0) {
      espera--;
    } else {
      progreso += sentido * VELOCIDAD_PLATAFORMA / distancia;
      if (progreso >= 1 || progreso <= 0) {
        progreso = constrain(progreso, 0, 1);
        sentido = -sentido;      // da la vuelta
        espera = 45;
      }
    }
    x = lerp(xInicio, xFin, progreso);
    y = lerp(yInicio, yFin, progreso);

    // los personajes que iban encima se mueven con ella
    if (llevaFuego) {
      fuego.moverX(x - viejoX);
      fuego.moverY(y - viejoY);
    }
    if (llevaAgua) {
      agua.moverX(x - viejoX);
      agua.moverY(y - viejoY);
    }
  }

  void dibujar() {
    noStroke();
    fill(170);
    rect(x, y, ancho, 12, 4);
  }
}
