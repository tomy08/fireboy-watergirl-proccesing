// =====================================================================
// 6. LÓGICA DE LOS PERSONAJES
// =====================================================================

// Medidas y física (en píxeles y píxeles por frame)
final float ANCHO_PJ = 22;        // ancho de la "caja" de colisión
final float ALTO_PJ = 28;         // alto de la "caja" de colisión
final float VELOCIDAD = 3;        // velocidad al caminar
final float GRAVEDAD = 0.5;       // cuánto aumenta la velocidad de caída cada frame
final float FUERZA_SALTO = 10.2;  // velocidad inicial del salto
final float CAIDA_MAXIMA = 10;    // velocidad máxima de caída
final float MARGEN_PELIGRO = 6;   // píxeles de cada lado que pueden "sobrar" sobre un líquido sin morir

class Personaje {
  float x, y;              // esquina superior izquierda de la caja de colisión
  float vx = 0, vy = 0;    // velocidad
  boolean enSuelo = false;
  boolean esFuego;         // true = Fuego, false = Agua
  boolean vivo = true;
  boolean enSalida = false;

  Personaje(boolean esFuego, float x, float y) {
    this.esFuego = esFuego;
    this.x = x;
    this.y = y;
  }

  // Se llama una vez por frame con las teclas de este jugador
  void actualizar(boolean izquierda, boolean derecha, boolean saltar) {
    if (!vivo) return;

    vx = 0;
    if (izquierda) vx -= VELOCIDAD;
    if (derecha) vx += VELOCIDAD;

    // Solo se puede saltar si estamos apoyados en algo
    if (saltar && enSuelo) {
      vy = -FUERZA_SALTO;
      reproducir(sonidoSalto);
    }

    vy += GRAVEDAD;
    if (vy > CAIDA_MAXIMA) vy = CAIDA_MAXIMA;

    // Primero nos movemos en horizontal y luego en vertical.
    // Separarlo así hace que las colisiones sean muy sencillas.
    moverX(vx);
    enSuelo = false;
    moverY(vy);
  }

  // ¿Está tocando el rectángulo indicado?
  boolean tocaRect(float rx, float ry, float rw, float rh) {
    return vivo && x < rx + rw && x + ANCHO_PJ > rx && y < ry + rh && y + ALTO_PJ > ry;
  }

  // ¿Está delante de la puerta que está en esa casilla?
  boolean estaEnCasilla(int col, int fila) {
    float centroX = x + ANCHO_PJ / 2;
    return vivo && centroX >= col * TAM && centroX < col * TAM + TAM
      && y < fila * TAM + TAM && y + ALTO_PJ > fila * TAM;
  }

  // ¿Está de pie encima de la plataforma móvil p?
  boolean estaSobre(PlataformaMovil p) {
    return vivo && enSuelo && abs(y + ALTO_PJ - p.y) < 2
      && x + ANCHO_PJ > p.x && x < p.x + p.ancho;
  }

  // Devuelve qué lo ha matado: 'L' lava, 'W' agua, 'V' ácido, 'v' vacío, o ' ' si nada.
  // Se mira la fila de casillas que hay justo debajo de los pies.
  char tocaPeligro() {
    if (!vivo) return ' ';
    if (y > height + 50) return 'v';
    int fila = floor((y + ALTO_PJ) / TAM);
    int colIzq = floor((x + MARGEN_PELIGRO) / TAM);
    int colDer = floor((x + ANCHO_PJ - MARGEN_PELIGRO - 0.01) / TAM);
    for (int c = colIzq; c <= colDer; c++) {
      char t = casilla(c, fila);
      if (t == 'V') return 'V';
      if (t == 'W' && esFuego) return 'W';
      if (t == 'L' && !esFuego) return 'L';
    }
    return ' ';
  }

  void dibujar() {
    dibujarPersonaje(x, y, esFuego);
  }


  // ===================================================================
  // 7. FÍSICA Y COLISIONES
  // ===================================================================
  // El mapa es una cuadrícula. Para saber si chocamos solo hay que mirar
  // las casillas que ocupa la caja del personaje después de moverse.

  void moverX(float dx) {
    x += dx;
    int filaArriba = floor(y / TAM);
    int filaAbajo = floor((y + ALTO_PJ - 0.01) / TAM);
    if (dx > 0) {
      int col = floor((x + ANCHO_PJ - 0.01) / TAM);      // columna del borde derecho
      for (int f = filaArriba; f <= filaAbajo; f++) {
        if (esSolido(col, f)) {
          x = col * TAM - ANCHO_PJ;                       // nos pegamos a la pared
          break;
        }
      }
    } else if (dx < 0) {
      int col = floor(x / TAM);                           // columna del borde izquierdo
      for (int f = filaArriba; f <= filaAbajo; f++) {
        if (esSolido(col, f)) {
          x = (col + 1) * TAM;
          break;
        }
      }
    }
  }

  void moverY(float dy) {
    float pieAnterior = y + ALTO_PJ;
    y += dy;
    int colIzq = floor(x / TAM);
    int colDer = floor((x + ANCHO_PJ - 0.01) / TAM);
    if (dy > 0) {
      // Cayendo: ¿hemos tocado el suelo?
      int fila = floor((y + ALTO_PJ - 0.01) / TAM);
      for (int c = colIzq; c <= colDer; c++) {
        if (esSolido(c, fila)) {
          y = fila * TAM - ALTO_PJ;
          vy = 0;
          enSuelo = true;
          break;
        }
      }
      // Las plataformas móviles solo se pisan desde arriba
      for (PlataformaMovil p : plataformas) {
        if (x + ANCHO_PJ > p.x && x < p.x + p.ancho && pieAnterior <= p.y + 0.01 && y + ALTO_PJ >= p.y) {
          y = p.y - ALTO_PJ;
          vy = 0;
          enSuelo = true;
        }
      }
    } else if (dy < 0) {
      // Subiendo: ¿nos damos con el techo?
      int fila = floor(y / TAM);
      for (int c = colIzq; c <= colDer; c++) {
        if (esSolido(c, fila)) {
          y = (fila + 1) * TAM;
          vy = 0;
          break;
        }
      }
    }
  }
}

// Devuelve el carácter de una casilla. Fuera del mapa: paredes a los
// lados y arriba, y vacío por debajo (para poder caer).
char casilla(int col, int fila) {
  if (col < 0 || col >= COLUMNAS || fila < 0) return '#';
  if (fila >= FILAS) return '.';
  return mapa[fila][col];
}

// ¿Es una casilla sólida? Los líquidos son suelo (se camina por encima).
boolean esSolido(int col, int fila) {
  char c = casilla(col, fila);
  if (c == '#' || c == 'L' || c == 'W' || c == 'V') return true;
  if (c == 'X') return !puertaAbierta[0];
  if (c == 'Y') return !puertaAbierta[1];
  return false;
}

// Dibuja a Fuego o a Agua: cuerpo, llama o gota, y ojos.
// (x, y) es la esquina superior izquierda de la caja de colisión.
void dibujarPersonaje(float x, float y, boolean esFuego) {
  noStroke();
  if (esFuego) fill(240, 90, 30);
  else fill(40, 140, 240);
  rect(x, y + 6, ANCHO_PJ, ALTO_PJ - 6, 6);                          // cuerpo
  triangle(x, y + 8, x + ANCHO_PJ, y + 8, x + ANCHO_PJ / 2, y - 10);  // llama o gota
  if (esFuego) {
    fill(255, 210, 60);
    triangle(x + 5, y + 8, x + 17, y + 8, x + 11, y - 2);             // centro amarillo de la llama
  }
  fill(255);
  ellipse(x + 7, y + 14, 7, 8);                                       // ojos
  ellipse(x + 15, y + 14, 7, 8);
  fill(0);
  ellipse(x + 7, y + 15, 3, 4);
  ellipse(x + 15, y + 15, 3, 4);
}
