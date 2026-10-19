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
    float cy = fila * TAM + TAM / 2 + sin(frameCount * 0.08 + col) * 3;   // flota
    dibujarIconoGema(cx, cy, roja, 1.0);
    // destello de vez en cuando
    if ((frameCount + col * 13) % 90 < 12) {
      stroke(255, 230);
      strokeWeight(2);
      line(cx + 5, cy - 12, cx + 5, cy - 4);
      line(cx + 1, cy - 8, cx + 9, cy - 8);
      noStroke();
    }
  }
}

// Dibuja una gema (también se usa en el marcador y en la ayuda)
void dibujarIconoGema(float cx, float cy, boolean roja, float escala) {
  color c = roja ? color(255, 60, 70) : color(50, 170, 255);
  pushMatrix();
  translate(cx, cy);
  scale(escala);
  noStroke();
  fill(c, 70);
  float halo = 26 + sin(frameCount * 0.12) * 4;
  ellipse(0, 0, halo, halo);
  fill(c);
  quad(0, -11, 9, 0, 0, 11, -9, 0);
  fill(lerpColor(c, color(0), 0.3));
  triangle(0, 11, 9, 0, 0, 2);
  fill(255, 170);
  quad(0, -11, 4, -2, 0, 1, -4, -2);
  popMatrix();
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
      crearExplosion(g.col * TAM + TAM / 2, g.fila * TAM + TAM / 2,
        g.roja ? color(255, 90, 90) : color(90, 190, 255), 20);
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
  causaMuerte = causa;            // se guardan para enviarlos por la red
  muertoEsFuego = p.esFuego;
  mensajeMuerte = textoMuerte(causa, p.esFuego);
  color c = p.esFuego ? color(255, 130, 30) : color(70, 170, 255);
  crearExplosion(p.x + ANCHO_PJ / 2, min(p.y + ALTO_PJ / 2, height - 10), c, 40);
  crearExplosion(p.x + ANCHO_PJ / 2, min(p.y + ALTO_PJ / 2, height - 10), color(200), 15);   // humo
}

String textoMuerte(char causa, boolean esFuego) {
  String nombre = esFuego ? "Fuego" : "Agua";
  if (causa == 'W') return "¡Fuego se ha apagado en el agua!";
  if (causa == 'L') return "¡Agua se ha evaporado en la lava!";
  if (causa == 'V') return "¡" + nombre + " ha tocado el ácido!";
  return "¡" + nombre + " ha caído al vacío!";
}

// Chispas sobre la lava y burbujas en el agua y el ácido (solo decoración)
void crearChispasAmbiente() {
  for (int[] l : liquidos) {
    if (random(1) < 0.006) {
      char tipo = mapa[l[1]][l[0]];
      Particula p = new Particula(l[0] * TAM + random(TAM), l[1] * TAM + 6, random(-0.3, 0.3), random(-1.5, -0.6),
        lerpColor(colorLiquido(tipo), color(255), 0.4), random(3, 5), 40);
      p.gravedad = 0.01;
      particulas.add(p);
    }
  }
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
    float px = col * TAM;
    float py = fila * TAM;
    color c = colorGrupo(grupo);
    noStroke();
    fill(60);
    rect(px + 2, py + TAM - 5, TAM - 4, 5, 2);              // base
    fill(pulsado ? lerpColor(c, color(255), 0.4) : c);
    float alto = pulsado ? 2 : 7;
    rect(px + 6, py + TAM - 5 - alto, TAM - 12, alto, 2);   // botón (se hunde al pisarlo)
    if (pulsado) {
      fill(c, 80);
      ellipse(px + TAM / 2, py + TAM - 6, 40, 16);           // brillo
    }
  }
}

color colorGrupo(int grupo) {
  return grupo == 0 ? color(170, 80, 255) : color(255, 195, 30);
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

    // animación suave (la colisión cambia al instante)
    float objetivo = abrir ? 1 : 0;
    aperturaPuerta[g] += (objetivo - aperturaPuerta[g]) * 0.2;
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

// Las puertas X / Y son barrotes que se recogen hacia arriba
void dibujarPuertas() {
  for (int f = 0; f < FILAS; f++) {
    for (int c = 0; c < COLUMNAS; c++) {
      char t = mapa[f][c];
      if (t != 'X' && t != 'Y') continue;
      int g = t == 'X' ? 0 : 1;
      color col = colorGrupo(g);
      float px = c * TAM;
      float py = f * TAM;
      float alto = TAM * (1 - aperturaPuerta[g]);
      // marco
      noFill();
      stroke(col, 90);
      strokeWeight(1);
      rect(px + 2, py, TAM - 4, TAM);
      noStroke();
      if (alto > 1) {
        fill(lerpColor(col, color(0), 0.35));
        rect(px + 4, py, TAM - 8, alto);
        fill(col);
        for (int b = 0; b < 3; b++) rect(px + 7 + b * 7, py, 4, alto);   // barrotes
        fill(255, 80);
        rect(px + 4, py + alto - 3, TAM - 8, 3);
      }
    }
  }
}


// ---------------------------------------------------------------------
// Puertas de salida
// ---------------------------------------------------------------------
void comprobarSalidas() {
  fuego.enSalida = fuego.estaEnCasilla(salidaFuegoCol, salidaFuegoFila);
  agua.enSalida = agua.estaEnCasilla(salidaAguaCol, salidaAguaFila);
  aperturaSalidaFuego += ((fuego.enSalida ? 1 : 0) - aperturaSalidaFuego) * 0.15;
  aperturaSalidaAgua += ((agua.enSalida ? 1 : 0) - aperturaSalidaAgua) * 0.15;

  if (fuego.enSalida && agua.enSalida) {
    tiempoSalida++;
    if (tiempoSalida == 1) reproducir(sonidoPuerta);
    if (tiempoSalida > 40) completarNivel();       // pestaña Pantallas
  } else {
    tiempoSalida = 0;
  }
}

void dibujarSalidas() {
  dibujarSalida(salidaFuegoCol, salidaFuegoFila, true, aperturaSalidaFuego);
  dibujarSalida(salidaAguaCol, salidaAguaFila, false, aperturaSalidaAgua);
}

// La puerta ocupa su casilla y la de encima
void dibujarSalida(int col, int fila, boolean deFuego, float apertura) {
  float px = col * TAM - 4;
  float py = fila * TAM - TAM;
  float w = TAM + 8;
  float h = TAM * 2;
  color c = deFuego ? color(230, 70, 40) : color(40, 120, 230);

  noStroke();
  fill(c, 40 + 40 * sin(frameCount * 0.08));
  ellipse(px + w / 2, py + h / 2, w + 26, h + 20);      // resplandor
  fill(90, 75, 60);
  rect(px - 3, py - 3, w + 6, h + 3, 12, 12, 0, 0);    // marco de piedra
  fill(20, 15, 30);
  rect(px, py, w, h, 10, 10, 0, 0);                    // interior oscuro
  // la hoja de la puerta se desliza hacia un lado al abrirse
  fill(c);
  rect(px, py, w * (1 - apertura * 0.85), h, 10, 10, 0, 0);
  // símbolo
  float sx = px + w * (1 - apertura * 0.85) / 2;
  float sy = py + h / 2 - 4;
  fill(255, 220);
  if (apertura < 0.7) {
    if (deFuego) {
      triangle(sx - 7, sy + 8, sx + 7, sy + 8, sx, sy - 10);
      fill(c);
      triangle(sx - 3, sy + 8, sx + 3, sy + 8, sx, sy);
    } else {
      triangle(sx - 6, sy, sx + 6, sy, sx, sy - 12);
      ellipse(sx, sy + 2, 13, 13);
    }
  }
}


// ---------------------------------------------------------------------
// Plataformas móviles
// ---------------------------------------------------------------------
final float VELOCIDAD_PLATAFORMA = 1.5;   // píxeles por frame
final float ALTO_PLATAFORMA = 12;

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
      if (progreso >= 1) {
        progreso = 1;
        sentido = -1;
        espera = 45;
      } else if (progreso <= 0) {
        progreso = 0;
        sentido = 1;
        espera = 45;
      }
    }
    x = lerp(xInicio, xFin, progreso);
    y = lerp(yInicio, yFin, progreso);

    // los personajes que iban encima se mueven con ella
    if (llevaFuego) fuego.arrastrar(x - viejoX, y - viejoY);
    if (llevaAgua) agua.arrastrar(x - viejoX, y - viejoY);
  }

  void dibujar() {
    // raíl por donde se mueve
    stroke(255, 50);
    strokeWeight(2);
    line(xInicio + ancho / 2, yInicio + ALTO_PLATAFORMA / 2, xFin + ancho / 2, yFin + ALTO_PLATAFORMA / 2);
    noStroke();
    // plataforma metálica
    fill(0, 60);
    rect(x + 3, y + 4, ancho, ALTO_PLATAFORMA, 4);
    fill(150, 155, 170);
    rect(x, y, ancho, ALTO_PLATAFORMA, 4);
    fill(200, 205, 220);
    rect(x, y, ancho, 4, 4);
    fill(110, 115, 130);
    for (float rx = x + 8; rx < x + ancho - 4; rx += 16) ellipse(rx, y + 8, 4, 4);   // remaches
    fill(255, 200, 40);
    rect(x + ancho / 2 - 6, y + 5, 12, 3);    // luz central
  }
}


// ---------------------------------------------------------------------
// Partículas (gemas, muertes, chispas y fuegos artificiales)
// ---------------------------------------------------------------------
class Particula {
  float x, y, vx, vy;
  color c;
  float tam;
  int vida, vidaMax;
  float gravedad = 0.12;

  Particula(float x, float y, float vx, float vy, color c, float tam, int vida) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.c = c;
    this.tam = tam;
    this.vida = vida;
    this.vidaMax = vida;
  }

  void actualizar() {
    x += vx;
    y += vy;
    vy += gravedad;
    vida--;
  }

  void dibujar() {
    float t = vida / (float) vidaMax;
    noStroke();
    fill(c, 255 * t);
    ellipse(x, y, tam * (0.5 + t), tam * (0.5 + t));
  }
}

void crearExplosion(float x, float y, color c, int cantidad) {
  // en red, el invitado también tiene que ver las explosiones de la partida
  if (modoRed == ANFITRION && estado == JUGANDO) enviarEvento("exp|" + x + "|" + y + "|" + c + "|" + cantidad);
  for (int i = 0; i < cantidad; i++) {
    float angulo = random(TWO_PI);
    float rapidez = random(1, 4);
    particulas.add(new Particula(x, y, cos(angulo) * rapidez, sin(angulo) * rapidez - 1, c, random(4, 8), (int) random(25, 50)));
  }
}

void actualizarParticulas() {
  for (int i = particulas.size() - 1; i >= 0; i--) {
    Particula p = particulas.get(i);
    p.actualizar();
    if (p.vida <= 0) particulas.remove(i);
  }
}

void dibujarParticulas() {
  for (Particula p : particulas) p.dibujar();
}
