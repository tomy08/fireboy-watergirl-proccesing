// =====================================================================
// 8. DISEÑO Y CARGA DE NIVELES
// =====================================================================
// Cada nivel es una lista de 20 textos de 30 letras. Cada letra es una
// casilla de 32 x 32 píxeles. Para modificar un nivel basta con cambiar
// las letras (¡cada fila debe seguir teniendo 30 caracteres!).
//
//   #  bloque de piedra (suelo, pared o techo)
//   .  aire
//   L  lava   (Fuego la pisa sin problema, Agua muere)
//   W  agua   (Agua la pisa sin problema, Fuego muere)
//   V  ácido verde (mueren los dos)
//   f  posición inicial de Fuego      a  posición inicial de Agua
//   F  puerta de salida de Fuego      A  puerta de salida de Agua
//   r  gema roja (para Fuego)         b  gema azul (para Agua)
//   x  botón morado   -> abre las puertas X mientras alguien lo pisa
//   y  botón amarillo -> abre las puertas Y mientras alguien lo pisa
//   X  puerta morada  Y  puerta amarilla
//   Un hueco en la fila de abajo (fila 19) es un pozo sin fondo.
//
// Las letras f, a, F, A, x, y deben ir justo encima de una casilla sólida.
//
// Plataformas móviles: cada nivel tiene una lista MOVILES_n con filas
//   {columna, fila, anchoEnCasillas, columnaFinal, filaFinal}
// La plataforma va y vuelve entre (columna, fila) y (columnaFinal, filaFinal).
//
// Reglas para que un nivel sea superable con esta física:
//   - un salto sube como máximo 3 casillas (mejor 2),
//   - un salto en horizontal cruza como máximo 3 casillas de hueco,
//   - un charco de 4 o más casillas no se puede saltar.

// ---------- NIVEL 1: El comienzo ----------
String[] NIVEL_1 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#............................#",   // 2
  "#............................#",   // 3
  "#............................#",   // 4
  "#............................#",   // 5
  "#............................#",   // 6
  "#............................#",   // 7
  "#........................F.A.#",   // 8
  "#........................#####",   // 9
  "#....................rb......#",   // 10
  "#...................####.....#",   // 11
  "#...............rb...........#",   // 12
  "#..............####..........#",   // 13
  "#..........rb................#",   // 14
  "#.........####...............#",   // 15
  "#.....rb.....................#",   // 16
  "#....####....................#",   // 17
  "#.fa.....r..b................#",   // 18
  "##############################"   // 19
};
int[][] MOVILES_1 = { };

// ---------- NIVEL 2: Primeros peligros ----------
String[] NIVEL_2 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#............................#",   // 2
  "#............................#",   // 3
  "#............................#",   // 4
  "#............................#",   // 5
  "#............................#",   // 6
  "#............................#",   // 7
  "#............................#",   // 8
  "#............................#",   // 9
  "#..........b.....r...........#",   // 10
  "#............................#",   // 11
  "#....F.A.....................#",   // 12
  "#...######LLL###WWW####......#",   // 13
  "#..........................b.#",   // 14
  "#........................#####",   // 15
  "#....................r.......#",   // 16
  "#...................####.....#",   // 17
  "#.fa....r......b.............#",   // 18
  "#######LLL####WWW#############"   // 19
};
int[][] MOVILES_2 = { };

// ---------- NIVEL 3: Saltos y alturas ----------
String[] NIVEL_3 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#............................#",   // 2
  "#............................#",   // 3
  "#............................#",   // 4
  "#............................#",   // 5
  "#..F..A......................#",   // 6
  "##########...................#",   // 7
  "#............................#",   // 8
  "#...........rb...............#",   // 9
  "#..........####..............#",   // 10
  "#................b...........#",   // 11
  "#................#...........#",   // 12
  "#............................#",   // 13
  "#..................#.........#",   // 14
  "#....................r.......#",   // 15
  "#......r......b.....###......#",   // 16
  "#......................#.....#",   // 17
  "#.fa.....................r.b.#",   // 18
  "######...##W#...#L##.#########"   // 19
};
int[][] MOVILES_3 = { };

// ---------- NIVEL 4: Las gemas ----------
String[] NIVEL_4 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#............................#",   // 2
  "#............................#",   // 3
  "#............................#",   // 4
  "#........b..........r........#",   // 5
  "#............................#",   // 6
  "#.......F............A.......#",   // 7
  "#......#####......#####......#",   // 8
  "#...........b....r...........#",   // 9
  "#............................#",   // 10
  "#............####............#",   // 11
  "#.........b........r.........#",   // 12
  "#............................#",   // 13
  "#........###......###........#",   // 14
  "#b..........................r#",   // 15
  "###..b....b...fa...r....r..###",   // 16
  "#............####............#",   // 17
  "#............####............#",   // 18
  "####LLL##LLL######WWW##WWW####"   // 19
};
int[][] MOVILES_4 = { };

// ---------- NIVEL 5: Los interruptores ----------
String[] NIVEL_5 = {
  "##############################",   // 0
  "#........#...................#",   // 1
  "#........#...................#",   // 2
  "#........#...................#",   // 3
  "#........#...................#",   // 4
  "#........#...................#",   // 5
  "#........#...................#",   // 6
  "#........#...................#",   // 7
  "#........#...................#",   // 8
  "#........#...................#",   // 9
  "#........#...................#",   // 10
  "#........Y.............b.....#",   // 11
  "#...r.b..Y..b....r...........#",   // 12
  "#.y..F.A.Y....y..............#",   // 13
  "######################..r....#",   // 14
  "#..............X.......##....#",   // 15
  "#.....r........X.............#",   // 16
  "#..............X....b.....####",   // 17
  "#.fa.......x...X..x.......####",   // 18
  "#####WW#############VV########"   // 19
};
int[][] MOVILES_5 = { };

// ---------- NIVEL 6: Caminos separados ----------
String[] NIVEL_6 = {
  "##############################",   // 0
  "#.............##.............#",   // 1
  "#......r......##......b......#",   // 2
  "#..F..........##..........A..#",   // 3
  "#######V####..##..####V#######",   // 4
  "#.............##.............#",   // 5
  "#...........######...........#",   // 6
  "#...r......########......b...#",   // 7
  "#........y.########..........#",   // 8
  "#..###W################L###..#",   // 9
  "#.....X.......##.......Y.....#",   // 10
  "###...X.r.....##.....b.Y...###",   // 11
  "####..X.......##.......Y..####",   // 12
  "####..X.......##.......Y..####",   // 13
  "########WW##..##..##LL########",   // 14
  "#.............##.............#",   // 15
  "#....r......######......b....#",   // 16
  "#.........########...........#",   // 17
  "#.f........########..x.....a.#",   // 18
  "####VVV##W##########L##VVV####"   // 19
};
int[][] MOVILES_6 = { };

// ---------- NIVEL 7: Plataformas móviles ----------
String[] NIVEL_7 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#............................#",   // 2
  "#............................#",   // 3
  "#............................#",   // 4
  "#.......r.....rb......b......#",   // 5
  "#..F..A......................#",   // 6
  "########LL##......###WW###...#",   // 7
  "#............................#",   // 8
  "#............................#",   // 9
  "#............................#",   // 10
  "#..........................b.#",   // 11
  "#............................#",   // 12
  "#............................#",   // 13
  "#...........r...b............#",   // 14
  "#.f.a...................r....#",   // 15
  "#######...............####...#",   // 16
  "#######...............####...#",   // 17
  "#######...............####...#",   // 18
  "#######VVVVVVVVVVVVVVV########"   // 19
};
int[][] MOVILES_7 = { {7, 16, 3, 19, 16}, {26, 16, 3, 26, 7}, {12, 7, 2, 16, 7} };

// ---------- NIVEL 8: El laberinto ----------
String[] NIVEL_8 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#........r..........b........#",   // 2
  "#....A..................F....#",   // 3
  "#..###########V############..#",   // 4
  "#..........#......#..........#",   // 5
  "###........#......#........###",   // 6
  "####..........rb..........####",   // 7
  "####......................####",   // 8
  "#####LLLL#####..#####WWWW#####",   // 9
  "#...#....................#...#",   // 10
  "#...#.........##.........#...#",   // 11
  "#rb....#..b..####..r..#....rb#",   // 12
  "#......#.....####.....#......#",   // 13
  "#..######LL########WW######..#",   // 14
  "#...........#....#...........#",   // 15
  "###.........#....#.........###",   // 16
  "####..b................r..####",   // 17
  "####..........fa..........####",   // 18
  "####WWWW##V########V##LLLL####"   // 19
};
int[][] MOVILES_8 = { };

// ---------- NIVEL 9: La gran prueba ----------
String[] NIVEL_9 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#............................#",   // 2
  "#........b...r...............#",   // 3
  "#.....x..........F.A.........#",   // 4
  "#....###LL###WW######........#",   // 5
  "#.........#..................#",   // 6
  "#.........#..................#",   // 7
  "#.rb......X..................#",   // 8
  "#.........X..................#",   // 9
  "#.........X..b...............#",   // 10
  "#.........X.....x........r...#",   // 11
  "#....################........#",   // 12
  "#............................#",   // 13
  "#.....................#####..#",   // 14
  "#............................#",   // 15
  "#......r........b............#",   // 16
  "#....................b...r..##",   // 17
  "#.f.a.......................##",   // 18
  "######...##VV##...###LL#WW####"   // 19
};
int[][] MOVILES_9 = { {1, 12, 4, 1, 5} };

// ---------- NIVEL 10: El templo final ----------
String[] NIVEL_10 = {
  "##############################",   // 0
  "#............................#",   // 1
  "#...............rb...........#",   // 2
  "#....A..F....................#",   // 3
  "#############V#############..#",   // 4
  "#............................#",   // 5
  "#............................#",   // 6
  "#...........r.....b....r.....#",   // 7
  "#............................#",   // 8
  "#..######......##LL###WW###rb#",   // 9
  "#........VVVVVV.......b......#",   // 10
  "###.......X..........r.......#",   // 11
  "####....b.X........##WW##....#",   // 12
  "####..x...X...x..............#",   // 13
  "####################LLLL###..#",   // 14
  "#............................#",   // 15
  "#..........r.b.............###",   // 16
  "#.f.a..................r..####",   // 17
  "#######..........####.....####",   // 18
  "#######VVVVVVVVVV######WW#####"   // 19
};
int[][] MOVILES_10 = { {7, 18, 2, 15, 18}, {9, 9, 2, 13, 9}, {27, 9, 2, 27, 4} };

String[][] MAPAS = {
  NIVEL_1, NIVEL_2, NIVEL_3, NIVEL_4, NIVEL_5,
  NIVEL_6, NIVEL_7, NIVEL_8, NIVEL_9, NIVEL_10
};

int[][][] MOVILES = {
  MOVILES_1, MOVILES_2, MOVILES_3, MOVILES_4, MOVILES_5,
  MOVILES_6, MOVILES_7, MOVILES_8, MOVILES_9, MOVILES_10
};

String[] NOMBRES_NIVELES = {
  "El comienzo", "Primeros peligros", "Saltos y alturas", "Las gemas", "Los interruptores",
  "Caminos separados", "Plataformas móviles", "El laberinto", "La gran prueba", "El templo final"
};

// Colores de cada nivel: {cielo arriba, cielo abajo, piedra, musgo}
int[][] COLORES_NIVEL = {
  {#5FB3E8, #CDEBFF, #8C6E4F, #5DBB45},
  {#3E2A5E, #D9785A, #7A5C46, #6BAF3E},
  {#2C6E9E, #A6E1F2, #6E6A63, #79C251},
  {#2D1E4F, #7C4FA8, #6B5A7D, #C07CE8},
  {#1F3B3A, #5E9C84, #5D6B5E, #A3D468},
  {#4A1C1C, #1C2E5A, #6A5650, #D98E4A},
  {#16384D, #4F8DA8, #59656E, #8FD3E8},
  {#2B2B2B, #5A5040, #6B5D45, #9AA33E},
  {#3A1030, #A8344E, #5C4250, #F2A541},
  {#120E24, #3D2A5C, #7D6A3F, #E8C547}
};

ArrayList<int[]> liquidos = new ArrayList<int[]>();   // casillas de lava/agua/ácido {col, fila}

// Prepara todo para jugar el nivel indicado (0 a 9)
void cargarNivel(int numero) {
  nivelActual = numero;
  idCarga++;            // avisa al invitado de que hay un nivel nuevo (pestaña Red)
  String[] filas = MAPAS[numero];
  gemas.clear();
  interruptores.clear();
  plataformas.clear();
  particulas.clear();
  liquidos.clear();
  totalRojas = 0;
  totalAzules = 0;

  for (int f = 0; f < FILAS; f++) {
    for (int c = 0; c < COLUMNAS; c++) {
      char letra = '.';
      if (f < filas.length && c < filas[f].length()) letra = filas[f].charAt(c);
      mapa[f][c] = '.';    // casi todos los objetos dejan aire en su casilla

      if (letra == 'f') {
        fuego = new Personaje(true, c * TAM + 5, f * TAM + 4);
      } else if (letra == 'a') {
        agua = new Personaje(false, c * TAM + 5, f * TAM + 4);
      } else if (letra == 'F') {
        salidaFuegoCol = c;
        salidaFuegoFila = f;
      } else if (letra == 'A') {
        salidaAguaCol = c;
        salidaAguaFila = f;
      } else if (letra == 'r' || letra == 'b') {
        gemas.add(new Gema(c, f, letra == 'r'));
        if (letra == 'r') totalRojas++;
        else totalAzules++;
      } else if (letra == 'x' || letra == 'y') {
        interruptores.add(new Interruptor(c, f, letra == 'x' ? 0 : 1));
      } else {
        mapa[f][c] = letra;    // bloques, líquidos, puertas o aire
        if (letra == 'L' || letra == 'W' || letra == 'V') liquidos.add(new int[] {c, f});
      }
    }
  }

  for (int[] d : MOVILES[numero]) {
    plataformas.add(new PlataformaMovil(d[0], d[1], d[2], d[3], d[4]));
  }

  // Valores iniciales de la partida
  puertaAbierta[0] = puertaAbierta[1] = false;
  aperturaPuerta[0] = aperturaPuerta[1] = 0;
  aperturaSalidaFuego = aperturaSalidaAgua = 0;
  gemasRojas = 0;
  gemasAzules = 0;
  tiempoMuerte = 0;
  tiempoSalida = 0;
  framesNivel = 0;

  crearFondoNivel();
  soltarTeclas();
  estado = JUGANDO;
}

void reiniciarNivel() {
  cargarNivel(nivelActual);
}

// Dibuja una sola vez el fondo y los bloques en una imagen (capaFondo).
// Así en cada frame solo hay que pegar esa imagen, que es muy rápido.
void crearFondoNivel() {
  if (capaFondo == null) capaFondo = createGraphics(width, height);
  int[] colores = COLORES_NIVEL[nivelActual];
  capaFondo.beginDraw();

  // degradado del cielo
  for (int yy = 0; yy < height; yy++) {
    capaFondo.stroke(lerpColor(colores[0], colores[1], yy / (float) height));
    capaFondo.line(0, yy, width, yy);
  }
  // ladrillos del templo al fondo (muy suaves)
  capaFondo.stroke(255, 22);
  capaFondo.strokeWeight(1);
  for (int yy = 0; yy < height; yy += 24) {
    capaFondo.line(0, yy, width, yy);
    int desplazamiento = (yy / 24) % 2 == 0 ? 0 : 24;
    for (int xx = desplazamiento; xx < width; xx += 48) capaFondo.line(xx, yy, xx, yy + 24);
  }

  // bloques y fondos de los charcos
  for (int f = 0; f < FILAS; f++) {
    for (int c = 0; c < COLUMNAS; c++) {
      char t = mapa[f][c];
      if (t == '#' || t == 'L' || t == 'W' || t == 'V') {
        dibujarBloque(capaFondo, c, f, colores[2], colores[3], t == '#');
      }
    }
  }
  capaFondo.endDraw();
}

boolean esBloqueOLiquido(char t) {
  return t == '#' || t == 'L' || t == 'W' || t == 'V';
}

void dibujarBloque(PGraphics pg, int c, int f, color piedra, color musgo, boolean conMusgo) {
  float px = c * TAM;
  float py = f * TAM;
  pg.noStroke();
  pg.fill(piedra);
  pg.rect(px, py, TAM, TAM);
  pg.fill(255, 30);
  pg.rect(px, py, TAM, 4);                 // luz arriba
  pg.fill(0, 45);
  pg.rect(px, py + TAM - 4, TAM, 4);       // sombra abajo
  pg.rect(px + TAM - 3, py, 3, TAM);
  pg.fill(0, 25);                           // pequeñas grietas para que no sea plano
  pg.rect(px + (c * 7 + f * 3) % 20 + 4, py + 10 + (c + f) % 3 * 5, 6, 2);
  pg.noFill();
  pg.stroke(0, 60);
  pg.rect(px + 0.5, py + 0.5, TAM - 1, TAM - 1);
  // musgo encima de los bloques que tienen aire arriba
  if (conMusgo && !esBloqueOLiquido(casilla(c, f - 1)) && f > 0) {
    pg.noStroke();
    pg.fill(musgo);
    pg.rect(px, py, TAM, 5);
    pg.rect(px + (c * 11) % 22 + 2, py + 5, 4, 3);
    pg.rect(px + (c * 5 + 13) % 22 + 2, py + 5, 3, 2);
  }
}

color colorLiquido(char tipo) {
  if (tipo == 'L') return color(255, 95, 20);
  if (tipo == 'W') return color(30, 130, 240);
  return color(90, 220, 60);   // ácido
}

// Dibuja la superficie de cada charco con olas animadas
void dibujarLiquidos() {
  noStroke();
  for (int[] l : liquidos) {
    int c = l[0];
    int f = l[1];
    char tipo = mapa[f][c];
    float px = c * TAM;
    float py = f * TAM;
    color base = colorLiquido(tipo);
    color claro = lerpColor(base, color(255), 0.55);

    fill(base);
    beginShape();
    vertex(px, py + 20);
    for (int i = 0; i <= 4; i++) {
      float ola = sin(frameCount * 0.08 + (c * 4 + i) * 0.9) * 2.5;
      vertex(px + i * TAM / 4.0, py + 4 + ola);
    }
    vertex(px + TAM, py + 20);
    endShape(CLOSE);

    // brillo de la superficie
    fill(claro, 170);
    float brillo = sin(frameCount * 0.05 + c) * 6;
    rect(px + 8 + brillo, py + 8, 10, 2, 1);
    if (tipo == 'L') {
      fill(255, 220, 80, 150 + 100 * sin(frameCount * 0.1 + c));
      ellipse(px + 22 - brillo, py + 13, 4, 4);   // burbujita de lava
    }
  }
}
