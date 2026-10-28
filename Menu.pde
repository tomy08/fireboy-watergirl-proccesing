// =====================================================================
// 4. MENÚ PRINCIPAL Y PANTALLA "CÓMO JUGAR"
// =====================================================================

// Botón rectangular que cambia de color al pasar el ratón
class BotonMenu {
  float x, y, w, h;
  String texto;

  BotonMenu(float x, float y, float w, float h, String texto) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.texto = texto;
  }

  boolean encima() {
    return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }

  void dibujar() {
    if (encima()) fill(255, 160, 60);
    else fill(200, 90, 40);
    stroke(255);
    strokeWeight(2);
    rect(x, y, w, h, 10);
    noStroke();
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(20);
    text(texto, x + w / 2, y + h / 2);
  }
}

// Botones de todas las pantallas
BotonMenu btnJugar, btnJugarRed, btnSeleccion, btnAyuda, btnSonido, btnMusica, btnVolver;
BotonMenu btnPausaHUD, btnReanudar, btnReiniciarNivel, btnPausaMenu;
BotonMenu btnSiguiente, btnRepetir, btnVictoriaMenu;
BotonMenu btnCrear, btnUnirse, btnRedJugar, btnRedElegir, btnDesconectar;
BotonMenu[] botonesNivel = new BotonMenu[TOTAL_NIVELES];

void crearBotones() {
  // Menú principal
  btnJugar     = new BotonMenu(330, 170, 300, 45, "Jugar");
  btnJugarRed  = new BotonMenu(330, 225, 300, 45, "Jugar en red");
  btnSeleccion = new BotonMenu(330, 280, 300, 45, "Seleccionar nivel");
  btnAyuda     = new BotonMenu(330, 335, 300, 45, "Cómo jugar");
  btnSonido    = new BotonMenu(330, 390, 145, 45, "");
  btnMusica    = new BotonMenu(485, 390, 145, 45, "");
  btnVolver    = new BotonMenu(380, 575, 200, 45, "Volver");

  // Selección de niveles: dos columnas de cinco
  for (int i = 0; i < TOTAL_NIVELES; i++) {
    botonesNivel[i] = new BotonMenu(90 + (i / 5) * 400, 120 + (i % 5) * 80, 380, 60, "");
  }

  // Partida, pausa y victoria
  btnPausaHUD       = new BotonMenu(880, 2, 75, 28, "Pausa");
  btnReanudar       = new BotonMenu(360, 230, 240, 50, "Reanudar");
  btnReiniciarNivel = new BotonMenu(360, 295, 240, 50, "Reiniciar nivel");
  btnPausaMenu      = new BotonMenu(360, 360, 240, 50, "");
  btnSiguiente      = new BotonMenu(360, 360, 240, 50, "Siguiente nivel");
  btnRepetir        = new BotonMenu(230, 425, 240, 50, "Repetir nivel");
  btnVictoriaMenu   = new BotonMenu(490, 425, 240, 50, "");

  // Juego en red (pestaña Red)
  btnCrear       = new BotonMenu(120, 300, 300, 50, "Crear partida");
  btnUnirse      = new BotonMenu(540, 360, 300, 50, "Unirse");
  btnRedJugar    = new BotonMenu(330, 300, 300, 50, "");
  btnRedElegir   = new BotonMenu(330, 365, 300, 50, "Elegir nivel");
  btnDesconectar = new BotonMenu(380, 575, 200, 45, "Desconectar");
}

void dibujarMenu() {
  background(40, 30, 70);

  // decoración: lava, agua y los dos personajes
  noStroke();
  fill(255, 90, 20);
  rect(0, 590, 400, 50);
  fill(30, 120, 230);
  rect(560, 590, 400, 50);
  fill(120, 95, 70);
  rect(400, 590, 160, 50);
  dibujarPersonaje(440, 562, true);
  dibujarPersonaje(500, 562, false);

  fill(255, 150, 50);
  textAlign(CENTER, CENTER);
  textSize(56);
  text("Fireboy & Watergirl", width / 2, 75);
  fill(255);
  textSize(18);
  text("Niveles completados: " + contarCompletados() + " / " + TOTAL_NIVELES, width / 2, 130);

  // textos que dependen del progreso y de las opciones
  if (nivelDesbloqueado == 0) btnJugar.texto = "Jugar";
  else btnJugar.texto = "Continuar (nivel " + (nivelDesbloqueado + 1) + ")";
  btnSonido.texto = sonidoActivado ? "Sonido: SÍ" : "Sonido: NO";
  btnMusica.texto = musicaActivada ? "Música: SÍ" : "Música: NO";

  btnJugar.dibujar();
  btnJugarRed.dibujar();
  btnSeleccion.dibujar();
  btnAyuda.dibujar();
  btnSonido.dibujar();
  btnMusica.dibujar();
}

void clickMenu() {
  if (btnJugar.encima()) cargarNivel(nivelDesbloqueado);
  else if (btnJugarRed.encima()) {
    mensajeRed = "";
    estado = RED;
  }
  else if (btnSeleccion.encima()) estado = SELECCION;
  else if (btnAyuda.encima()) estado = AYUDA;
  else if (btnSonido.encima()) alternarSonido();
  else if (btnMusica.encima()) alternarMusica();
}

int contarCompletados() {
  int total = 0;
  for (int i = 0; i < TOTAL_NIVELES; i++) {
    if (nivelCompletado[i]) total++;
  }
  return total;
}

String[] TEXTO_AYUDA = {
  "CONTROLES",
  "Fuego: A y D para moverse, W para saltar.",
  "Agua: flechas izquierda y derecha para moverse, flecha arriba para saltar.",
  "ESC o P: pausa.     R: reiniciar el nivel.",
  "",
  "REGLAS",
  "Fuego puede pisar la lava, pero muere en el agua.",
  "Agua puede pisar el agua, pero muere en la lava.",
  "El ácido verde y caer al vacío matan a los dos.",
  "Fuego recoge las gemas rojas y Agua las azules.",
  "Un botón abre las puertas de su color mientras alguien lo pisa.",
  "Las plataformas grises se mueven y llevan a quien esté encima.",
  "Cada personaje debe llegar a su puerta. Si uno muere, el nivel se reinicia.",
  "",
  "EN RED: uno crea la partida (Fuego) y el otro se une con su IP (Agua)."
};

void dibujarAyuda() {
  background(40, 30, 70);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Cómo jugar", width / 2, 50);
  textSize(18);
  for (int i = 0; i < TEXTO_AYUDA.length; i++) {
    text(TEXTO_AYUDA[i], width / 2, 120 + i * 30);
  }
  btnVolver.dibujar();
}


// =====================================================================
// 5. SELECCIÓN DE NIVELES
// =====================================================================
void dibujarSeleccion() {
  background(40, 30, 70);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Selecciona un nivel", width / 2, 60);

  for (int i = 0; i < TOTAL_NIVELES; i++) {
    BotonMenu b = botonesNivel[i];
    if (i <= nivelDesbloqueado) {
      b.texto = (i + 1) + ". " + NOMBRES_NIVELES[i];
      if (nivelCompletado[i]) b.texto += "  (completado)";
      b.dibujar();
    } else {
      // nivel bloqueado: gris y sin efecto al pasar el ratón
      fill(90);
      stroke(150);
      rect(b.x, b.y, b.w, b.h, 10);
      noStroke();
      fill(170);
      textSize(20);
      text((i + 1) + ". Bloqueado", b.x + b.w / 2, b.y + b.h / 2);
    }
  }
  btnVolver.dibujar();
}

void clickSeleccion() {
  for (int i = 0; i <= nivelDesbloqueado; i++) {
    if (botonesNivel[i].encima()) {
      cargarNivel(i);
      return;
    }
  }
  if (btnVolver.encima()) irAlMenu();
}
