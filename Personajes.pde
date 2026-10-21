// =====================================================================
// 6. LÓGICA DE LOS PERSONAJES
// =====================================================================

// Medidas y física (en píxeles y píxeles por frame)
final float ANCHO_PJ = 22;        // ancho de la "caja" de colisión
final float ALTO_PJ = 28;         // alto de la "caja" de colisión
final float VELOCIDAD = 3;        // velocidad al caminar
final float GRAVEDAD = 0.5;       // cuánto aumenta la velocidad de caída cada frame
final float FUERZA_SALTO = 10.2;    // velocidad inicial del salto (sube algo más de 3 casillas)
final float CAIDA_MAXIMA = 10;    // velocidad máxima de caída
final float MARGEN_PELIGRO = 6;   // píxeles de cada lado que pueden "sobrar" sobre un líquido sin morir

class Personaje {
  float x, y;              // esquina superior izquierda de la caja de colisión
  float vx = 0, vy = 0;    // velocidad
  boolean enSuelo = false;
  boolean esFuego;         // true = Fuego, false = Agua
  boolean vivo = true;
  boolean enSalida = false;
  int direccion = 1;       // 1 = mira a la derecha, -1 = a la izquierda
  float paso = 0;          // contador para animar las piernas

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
    if (vx > 0) direccion = 1;
    if (vx < 0) direccion = -1;

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

    if (vx != 0 && enSuelo) paso += 0.35;
    else paso = 0;
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

  // La plataforma móvil desplaza al personaje que lleva encima
  void arrastrar(float dx, float dy) {
    moverX(dx);
    moverY(dy);
  }

  // Devuelve qué lo ha matado: 'L' lava, 'W' agua, 'V' ácido, 'v' vacío, o ' ' si nada.
  // Se mira la fila de casillas que hay justo debajo de los pies.
  char tocaPeligro() {
    if (!vivo) return ' ';
    if (y > height + 50) return 'v';
    int fila = floor((y + ALTO_PJ) / TAM);
    int colIzq = floor((x + MARGEN_PELIGRO) / TAM);     // margen a cada lado: hay que pisar el líquido de verdad
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
    dibujarCuerpo(x, y, esFuego, direccion, paso, !enSuelo, 1.0);
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

// ¿Se puede atravesar la casilla? Los líquidos son suelo (se camina por encima).
boolean esSolido(int col, int fila) {
  char c = casilla(col, fila);
  if (c == '#' || c == 'L' || c == 'W' || c == 'V') return true;
  if (c == 'X') return !puertaAbierta[0];
  if (c == 'Y') return !puertaAbierta[1];
  return false;
}


// ---------------------------------------------------------------------
// Dibujo de los personajes (se usa en el juego, el menú y la victoria)
// x, y: esquina superior izquierda de la caja de colisión
// ---------------------------------------------------------------------
void dibujarCuerpo(float px, float py, boolean esFuego, int dir, float paso, boolean enAire, float escala) {
  color principal = esFuego ? color(240, 90, 30) : color(40, 140, 240);
  color oscuro = esFuego ? color(160, 40, 20) : color(20, 70, 170);
  color claro = esFuego ? color(255, 210, 70) : color(170, 225, 255);

  pushMatrix();
  translate(px + ANCHO_PJ / 2 * escala, py + ALTO_PJ * escala);   // origen: entre los pies
  scale(escala);
  if (enAire) scale(0.92, 1.08);                                  // se estira al saltar
  noStroke();

  // aura
  fill(principal, 45);
  ellipse(0, -16, 44, 44);

  // piernas (se balancean al caminar)
  float balanceo = sin(paso) * 3;
  fill(oscuro);
  rect(-8 + balanceo, -7, 6, 7, 2);
  rect(2 - balanceo, -7, 6, 7, 2);

  // cabeza: llama para Fuego, gota para Agua
  float t = frameCount * 0.25;
  if (esFuego) {
    fill(255, 120, 20);
    triangle(-11, -21, -2, -21, -8 + sin(t) * 2, -35 + sin(t * 1.3) * 3);
    triangle(-5, -22, 6, -22, 1 + sin(t + 1) * 2, -42 + sin(t * 1.7) * 3);
    triangle(2, -21, 11, -21, 8 + sin(t + 2) * 2, -34 + sin(t * 1.1) * 3);
    fill(claro);
    triangle(-5, -22, 5, -22, sin(t) * 1.5, -33 + sin(t * 2) * 2);
  } else {
    fill(principal);
    triangle(-10, -19, 10, -19, -dir * 3, -41);
    fill(claro, 200);
    ellipse(-4, -28, 4, 7);
  }

  // cuerpo
  fill(principal);
  rect(-11, -26, 22, 20, 8);
  fill(claro, 90);
  rect(-8, -24, 7, 5, 3);       // brillo

  // ojos (miran hacia donde camina)
  fill(255);
  ellipse(-4 + dir * 2, -17, 7, 8);
  ellipse(4 + dir * 2, -17, 7, 8);
  fill(30);
  ellipse(-4 + dir * 3, -16.5, 3.5, 4.5);
  ellipse(4 + dir * 3, -16.5, 3.5, 4.5);

  // boca sonriente
  noFill();
  stroke(oscuro);
  strokeWeight(1.5);
  arc(dir * 2, -12, 8, 5, 0, PI);
  noStroke();
  popMatrix();
}
