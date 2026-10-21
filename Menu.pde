// =====================================================================
// 4. MENÚ PRINCIPAL  (y pantalla "Cómo jugar")
// =====================================================================

// Botón rectangular que reacciona al ratón
class BotonMenu {
  float x, y, w, h;
  String texto;
  color colorBase;

  BotonMenu(float x, float y, float w, float h, String texto, color colorBase) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.texto = texto;
    this.colorBase = colorBase;
  }

  boolean encima() {
    return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }

  void dibujar() {
    boolean sobre = encima();
    float escala = sobre ? 1.06 : 1.0;          // crece un poco al pasar el ratón
    pushMatrix();
    translate(x + w / 2, y + h / 2);
    scale(escala);
    noStroke();
    fill(0, 90);
    rect(-w / 2 + 4, -h / 2 + 6, w, h, 14);     // sombra
    color relleno = sobre ? lerpColor(colorBase, color(255), 0.25) : colorBase;
    fill(relleno);
    stroke(255, sobre ? 255 : 170);
    strokeWeight(3);
    rect(-w / 2, -h / 2, w, h, 14);
    noStroke();
    fill(255, 45);
    rect(-w / 2 + 6, -h / 2 + 4, w - 12, h / 2 - 4, 10);   // brillo superior
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(min(h * 0.42, 24));
    text(texto, 0, -2);
    popMatrix();
  }
}

// --- Botones de todas las pantallas ---
BotonMenu btnJugar, btnJugarRed, btnSeleccion, btnAyuda, btnSonido, btnMusica, btnBorrar, btnSalir;
BotonMenu btnVolver;
BotonMenu btnReanudar, btnReiniciarNivel, btnPausaSonido, btnPausaMusica, btnPausaMenu;
BotonMenu btnSiguiente, btnRepetir, btnVictoriaMenu;
BotonMenu btnFinalMenu, btnFinalSeleccion;

boolean confirmarBorrado = false;   // el progreso se borra solo si se pulsa dos veces
int tiempoConfirmar = 0;

void crearBotones() {
  color naranja = color(230, 95, 35);
  color azul = color(40, 120, 220);
  color morado = color(120, 70, 190);
  color verde = color(50, 160, 90);
  color gris = color(90, 90, 110);

  // Menú principal
  btnJugar     = new BotonMenu(330, 194, 300, 46, "Jugar", naranja);
  btnJugarRed  = new BotonMenu(330, 248, 300, 46, "Jugar en red", color(200, 70, 120));
  btnSeleccion = new BotonMenu(330, 302, 300, 46, "Seleccionar nivel", azul);
  btnAyuda     = new BotonMenu(330, 356, 300, 46, "Cómo jugar", morado);
  btnSonido    = new BotonMenu(330, 410, 145, 38, "", verde);
  btnMusica    = new BotonMenu(485, 410, 145, 38, "", verde);
  btnBorrar    = new BotonMenu(330, 456, 190, 34, "Borrar progreso", gris);
  btnSalir     = new BotonMenu(530, 456, 100, 34, "Salir", gris);

  btnVolver = new BotonMenu(380, 570, 200, 46, "Volver", gris);

  // Pausa
  btnReanudar       = new BotonMenu(360, 210, 240, 48, "Reanudar", verde);
  btnReiniciarNivel = new BotonMenu(360, 268, 240, 48, "Reiniciar nivel", naranja);
  btnPausaSonido    = new BotonMenu(360, 326, 115, 44, "", azul);
  btnPausaMusica    = new BotonMenu(485, 326, 115, 44, "", azul);
  btnPausaMenu      = new BotonMenu(360, 380, 240, 48, "Menú principal", gris);

  // Victoria de nivel
  btnSiguiente    = new BotonMenu(360, 380, 240, 50, "Siguiente nivel", verde);
  btnRepetir      = new BotonMenu(240, 442, 230, 44, "Repetir nivel", naranja);
  btnVictoriaMenu = new BotonMenu(490, 442, 230, 44, "Menú principal", gris);

  // Victoria final
  btnFinalMenu      = new BotonMenu(250, 560, 220, 50, "Menú principal", naranja);
  btnFinalSeleccion = new BotonMenu(490, 560, 220, 50, "Elegir nivel", azul);
}

// Cambia el texto de los botones que dependen del estado actual
void actualizarTextosBotones() {
  if (nivelDesbloqueado == 0 && !nivelCompletado[0]) btnJugar.texto = "Jugar";
  else btnJugar.texto = "Continuar (nivel " + (nivelDesbloqueado + 1) + ")";
  btnSonido.texto = sonidoActivado ? "Sonido: SÍ" : "Sonido: NO";
  btnMusica.texto = musicaActivada ? "Música: SÍ" : "Música: NO";
  btnPausaSonido.texto = btnSonido.texto;
  btnPausaMusica.texto = btnMusica.texto;
  btnBorrar.texto = confirmarBorrado ? "¿Seguro? Pulsa otra vez" : "Borrar progreso";
  // en red, "Menú principal" significa volver a la sala o salir de la partida
  String textoSalir = "Menú principal";
  if (modoRed == ANFITRION) textoSalir = "Sala de red";
  if (modoRed == INVITADO) textoSalir = "Salir de la partida";
  btnPausaMenu.texto = textoSalir;
  btnVictoriaMenu.texto = textoSalir;
  btnFinalMenu.texto = textoSalir;
}

// --- Decoración animada del menú ---
float[] estrellaX = new float[60];
float[] estrellaY = new float[60];
float[] chispaX = new float[40];     // chispas de fuego (izquierda) y burbujas (derecha)
float[] chispaY = new float[40];
float[] chispaVel = new float[40];

void iniciarMenu() {
  for (int i = 0; i < estrellaX.length; i++) {
    estrellaX[i] = random(width);
    estrellaY[i] = random(height * 0.6);
  }
  for (int i = 0; i < chispaX.length; i++) {
    reiniciarChispa(i);
    chispaY[i] = random(height);
  }
}

void reiniciarChispa(int i) {
  if (i % 2 == 0) chispaX[i] = random(20, 420);    // fuego a la izquierda
  else chispaX[i] = random(540, 940);              // burbujas a la derecha
  chispaY[i] = height + random(40);
  chispaVel[i] = random(0.6, 1.8);
}

// Fondo con degradado (vertical) y dos resplandores, uno cálido y uno frío
void dibujarFondoMenu() {
  background(25, 15, 50);
  for (int yy = 0; yy < height; yy += 4) {
    stroke(lerpColor(color(25, 15, 50), color(60, 30, 70), yy / (float) height));
    strokeWeight(4);
    line(0, yy, width, yy);
  }
  noStroke();
  for (int r = 400; r > 0; r -= 40) {
    fill(255, 90, 20, 10);
    ellipse(120, height, r * 2, r * 2);
    fill(30, 140, 255, 10);
    ellipse(width - 120, height, r * 2, r * 2);
  }
  // estrellas que parpadean
  for (int i = 0; i < estrellaX.length; i++) {
    float brillo = 150 + 100 * sin(frameCount * 0.05 + i);
    fill(255, brillo);
    ellipse(estrellaX[i], estrellaY[i], 2.5, 2.5);
  }
  // chispas y burbujas subiendo
  for (int i = 0; i < chispaX.length; i++) {
    chispaY[i] -= chispaVel[i];
    float oscila = sin(frameCount * 0.04 + i) * 0.6;
    chispaX[i] += oscila;
    if (chispaY[i] < -10) reiniciarChispa(i);
    if (i % 2 == 0) {
      fill(255, 150 + (i * 7) % 100, 40, 200);
      ellipse(chispaX[i], chispaY[i], 5, 5);
    } else {
      noFill();
      stroke(170, 220, 255, 180);
      strokeWeight(1.5);
      ellipse(chispaX[i], chispaY[i], 8, 8);
      noStroke();
    }
  }
}

// Suelo decorativo con un lago de lava, un lago de agua y los personajes saltando
void dibujarEscenaMenu() {
  float suelo = 560;
  // lava (izquierda) y agua (derecha)
  dibujarOlas(0, 400, suelo + 12, color(255, 90, 20), color(255, 200, 60), 0);
  dibujarOlas(560, 960, suelo + 12, color(30, 120, 230), color(170, 225, 255), 2);
  // isla de piedra en el centro
  noStroke();
  fill(110, 90, 70);
  rect(400, suelo, 160, height - suelo);
  fill(90, 170, 70);
  rect(400, suelo, 160, 7);
  fill(0, 40);
  for (int i = 0; i < 4; i++) rect(400 + i * 40, suelo + 30, 38, 2);

  // personajes saltando por turnos
  float saltoFuego = abs(sin(frameCount * 0.05)) * 12;
  float saltoAgua = abs(sin(frameCount * 0.05 + HALF_PI)) * 12;
  dibujarCuerpo(430, suelo - ALTO_PJ * 1.6 - saltoFuego, true, 1, frameCount * 0.2, saltoFuego > 3, 1.6);
  dibujarCuerpo(505, suelo - ALTO_PJ * 1.6 - saltoAgua, false, -1, frameCount * 0.2, saltoAgua > 3, 1.6);
}

// Superficie de líquido con olas (sirve para el menú)
void dibujarOlas(float x1, float x2, float alturaY, color base, color claro, float desfase) {
  noStroke();
  fill(base);
  beginShape();
  vertex(x1, height);
  for (float xx = x1; xx <= x2; xx += 10) {
    vertex(xx, alturaY + sin(frameCount * 0.06 + xx * 0.03 + desfase) * 5);
  }
  vertex(x2, height);
  endShape(CLOSE);
  stroke(claro);
  strokeWeight(3);
  noFill();
  beginShape();
  for (float xx = x1; xx <= x2; xx += 10) {
    vertex(xx, alturaY + sin(frameCount * 0.06 + xx * 0.03 + desfase) * 5);
  }
  endShape();
  noStroke();
}

// Título con letras de colores que se mueven
void dibujarTitulo(String titulo, float centroY, float tam) {
  textSize(tam);
  textAlign(LEFT, CENTER);
  float anchoTotal = textWidth(titulo);
  float xLetra = width / 2 - anchoTotal / 2;
  for (int i = 0; i < titulo.length(); i++) {
    String letra = titulo.substring(i, i + 1);
    float t = i / (float) (titulo.length() - 1);
    color c = lerpColor(color(255, 120, 30), color(60, 160, 255), t);   // de fuego a agua
    float sube = sin(frameCount * 0.07 + i * 0.6) * 5;
    fill(0, 120);
    text(letra, xLetra + 4, centroY + sube + 5);   // sombra
    fill(c);
    text(letra, xLetra, centroY + sube);
    xLetra += textWidth(letra);
  }
}

void dibujarMenu() {
  actualizarTextosBotones();
  if (confirmarBorrado && millis() > tiempoConfirmar) confirmarBorrado = false;

  dibujarFondoMenu();
  dibujarEscenaMenu();

  dibujarTitulo("Fireboy & Watergirl", 85, 78);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(30);
  text("La Aventura", width / 2, 150);

  btnJugar.dibujar();
  btnJugarRed.dibujar();
  btnSeleccion.dibujar();
  btnAyuda.dibujar();
  btnSonido.dibujar();
  btnMusica.dibujar();
  btnBorrar.dibujar();
  btnSalir.dibujar();

  fill(255, 170);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("Niveles completados: " + contarCompletados() + " / " + TOTAL_NIVELES, width / 2, 178);
  if (!audioDisponible) text("(No se encontró dispositivo de audio: modo silencioso)", width / 2, 500);
}

void clickMenu() {
  if (btnJugar.encima()) {
    reproducir(sonidoClick);
    cargarNivel(nivelDesbloqueado);
  } else if (btnJugarRed.encima()) {
    reproducir(sonidoClick);
    mensajeRed = "";
    estado = RED;
  } else if (btnSeleccion.encima()) {
    reproducir(sonidoClick);
    estado = SELECCION;
  } else if (btnAyuda.encima()) {
    reproducir(sonidoClick);
    estado = AYUDA;
  } else if (btnSonido.encima()) {
    alternarSonido();
  } else if (btnMusica.encima()) {
    alternarMusica();
  } else if (btnBorrar.encima()) {
    reproducir(sonidoClick);
    if (confirmarBorrado) {
      borrarProgreso();
      confirmarBorrado = false;
    } else {
      confirmarBorrado = true;
      tiempoConfirmar = millis() + 3000;   // 3 segundos para confirmar
    }
  } else if (btnSalir.encima()) {
    detenerMusica();
    exit();
  }
}

int contarCompletados() {
  int total = 0;
  for (int i = 0; i < TOTAL_NIVELES; i++) if (nivelCompletado[i]) total++;
  return total;
}

// --- Pantalla "Cómo jugar" ---
void dibujarAyuda() {
  dibujarFondoMenu();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Cómo jugar", width / 2, 45);

  // Recuadro de controles (izquierda)
  panel(40, 90, 420, 460);
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(22);
  text("Controles", 60, 115);

  dibujarCuerpo(70, 150, true, 1, 0, false, 1.0);
  fill(255);
  textSize(18);
  text("Fuego", 105, 168);
  dibujarTecla(100, 215, "W");
  dibujarTecla(62, 255, "A");
  dibujarTecla(138, 255, "D");
  textSize(15);
  text("A / D: moverse", 175, 245);
  text("W: saltar", 175, 265);

  dibujarCuerpo(70, 300, false, 1, 0, false, 1.0);
  fill(255);
  textSize(18);
  text("Agua", 105, 318);
  dibujarTecla(100, 365, "arriba");
  dibujarTecla(62, 405, "izquierda");
  dibujarTecla(138, 405, "derecha");
  textSize(15);
  text("Flechas: moverse", 175, 395);
  text("Flecha arriba: saltar", 175, 415);

  dibujarTecla(62, 470, "ESC");
  textSize(15);
  text("Pausar / reanudar (también P)", 100, 470);
  dibujarTecla(62, 515, "R");
  textSize(15);
  text("Reiniciar el nivel", 100, 515);

  // Recuadro de reglas (derecha)
  panel(490, 90, 430, 460);
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(22);
  text("Reglas", 510, 115);
  textSize(14);
  float yy = 160;
  iconoLiquido(515, yy, 'L');
  text("Lava: Fuego puede pisarla, Agua muere.", 560, yy);
  yy += 45;
  iconoLiquido(515, yy, 'W');
  text("Agua: Agua puede pisarla, Fuego muere.", 560, yy);
  yy += 45;
  iconoLiquido(515, yy, 'V');
  text("Ácido verde: los dos mueren.", 560, yy);
  yy += 40;
  text("Caer al vacío también es mortal.", 560, yy);
  yy += 45;
  dibujarIconoGema(530, yy, true, 1);
  dibujarIconoGema(545, yy, false, 1);
  fill(255);
  text("Gemas: Fuego recoge las rojas y Agua las azules.", 560, yy);
  yy += 45;
  fill(180, 90, 255);
  rect(517, yy - 2, 26, 6, 2);
  fill(255);
  text("Botones: mientras alguien los pisa, se", 560, yy - 8);
  text("abren las puertas de su mismo color.", 560, yy + 10);
  yy += 45;
  fill(160);
  rect(510, yy - 3, 40, 8, 3);
  fill(255);
  text("Plataformas móviles: súbete y te llevan.", 560, yy);
  yy += 45;
  text("Cada personaje debe llegar a SU puerta.", 520, yy);
  text("Si uno muere, el nivel vuelve a empezar.", 520, yy + 20);
  text("¡Colaborad para superar los 10 niveles!", 520, yy + 40);

  btnVolver.dibujar();
}

void clickAyuda() {
  if (btnVolver.encima()) {
    reproducir(sonidoClick);
    estado = MENU;
  }
}

// Recuadro semitransparente para agrupar información
void panel(float x, float y, float w, float h) {
  noStroke();
  fill(0, 120);
  rect(x + 5, y + 6, w, h, 16);
  fill(30, 25, 60, 220);
  stroke(255, 120);
  strokeWeight(2);
  rect(x, y, w, h, 16);
  noStroke();
}

// Dibuja una tecla. Las flechas se dibujan con triángulos.
void dibujarTecla(float cx, float cy, String nombre) {
  stroke(40);
  strokeWeight(2);
  fill(235);
  rect(cx - 17, cy - 17, 34, 34, 6);
  fill(200);
  noStroke();
  rect(cx - 13, cy + 9, 26, 5, 2);
  fill(40);
  textAlign(CENTER, CENTER);
  if (nombre.equals("arriba")) {
    triangle(cx, cy - 9, cx - 8, cy + 5, cx + 8, cy + 5);
  } else if (nombre.equals("izquierda")) {
    triangle(cx - 9, cy - 2, cx + 6, cy - 10, cx + 6, cy + 6);
  } else if (nombre.equals("derecha")) {
    triangle(cx + 9, cy - 2, cx - 6, cy - 10, cx - 6, cy + 6);
  } else {
    textSize(nombre.length() > 1 ? 11 : 17);
    text(nombre, cx, cy - 3);
  }
  textAlign(LEFT, CENTER);
  fill(255);
}

// Pequeño cuadrado de líquido para la ayuda
void iconoLiquido(float x, float y, char tipo) {
  noStroke();
  fill(110, 90, 70);
  rect(x, y - 10, 30, 20, 3);
  fill(colorLiquido(tipo));
  rect(x, y - 10, 30, 11, 3);
  fill(255);
}


// =====================================================================
// 5. SELECCIÓN DE NIVELES
// =====================================================================
final float TARJETA_ANCHO = 150;
final float TARJETA_ALTO = 140;

float tarjetaX(int i) {
  return 53 + (i % 5) * (TARJETA_ANCHO + 26);
}

float tarjetaY(int i) {
  return 140 + (i / 5) * (TARJETA_ALTO + 40);
}

boolean encimaTarjeta(int i) {
  return mouseX > tarjetaX(i) && mouseX < tarjetaX(i) + TARJETA_ANCHO
    && mouseY > tarjetaY(i) && mouseY < tarjetaY(i) + TARJETA_ALTO;
}

void dibujarSeleccion() {
  dibujarFondoMenu();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Selecciona un nivel", width / 2, 60);
  textSize(15);
  fill(255, 180);
  text("Completa un nivel para desbloquear el siguiente", width / 2, 100);

  for (int i = 0; i < TOTAL_NIVELES; i++) {
    boolean desbloqueado = i <= nivelDesbloqueado;
    boolean sobre = desbloqueado && encimaTarjeta(i);
    float x = tarjetaX(i);
    float y = tarjetaY(i) - (sobre ? 5 : 0);

    noStroke();
    fill(0, 100);
    rect(x + 5, y + 7, TARJETA_ANCHO, TARJETA_ALTO, 16);   // sombra

    if (desbloqueado) {
      // del naranja (nivel 1) al azul (nivel 10)
      color c = lerpColor(color(230, 100, 40), color(50, 110, 220), i / 9.0);
      if (sobre) c = lerpColor(c, color(255), 0.2);
      fill(c);
      stroke(255, sobre ? 255 : 150);
    } else {
      fill(70, 70, 85);
      stroke(120);
    }
    strokeWeight(3);
    rect(x, y, TARJETA_ANCHO, TARJETA_ALTO, 16);
    noStroke();

    textAlign(CENTER, CENTER);
    if (desbloqueado) {
      fill(255);
      textSize(46);
      text(i + 1, x + TARJETA_ANCHO / 2, y + 52);
      textSize(13);
      text(NOMBRES_NIVELES[i], x + TARJETA_ANCHO / 2, y + 108);
      if (nivelCompletado[i]) dibujarInsigniaCompletado(x + TARJETA_ANCHO - 18, y + 18);
    } else {
      dibujarCandado(x + TARJETA_ANCHO / 2, y + 60);
      fill(170);
      textSize(13);
      text("Bloqueado", x + TARJETA_ANCHO / 2, y + 112);
    }
  }
  btnVolver.dibujar();
}

void clickSeleccion() {
  for (int i = 0; i < TOTAL_NIVELES; i++) {
    if (i <= nivelDesbloqueado && encimaTarjeta(i)) {
      reproducir(sonidoClick);
      cargarNivel(i);
      return;
    }
  }
  if (btnVolver.encima()) {
    reproducir(sonidoClick);
    irAlMenu();
  }
}

void dibujarCandado(float cx, float cy) {
  noFill();
  stroke(190);
  strokeWeight(6);
  arc(cx, cy - 8, 30, 34, PI, TWO_PI);
  noStroke();
  fill(190);
  rect(cx - 21, cy - 8, 42, 32, 6);
  fill(70, 70, 85);
  ellipse(cx, cy + 4, 8, 8);
  rect(cx - 2, cy + 4, 4, 10);
}

void dibujarInsigniaCompletado(float cx, float cy) {
  fill(60, 190, 90);
  stroke(255);
  strokeWeight(2);
  ellipse(cx, cy, 26, 26);
  stroke(255);
  strokeWeight(3);
  line(cx - 6, cy, cx - 1, cy + 5);
  line(cx - 1, cy + 5, cx + 7, cy - 5);
  noStroke();
}
