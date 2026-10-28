// =====================================================================
// 11. INTERFAZ, PAUSA Y PANTALLAS DE VICTORIA
// =====================================================================

// Marcador de arriba: nivel, gemas, tiempo y botón de pausa
void dibujarHUD() {
  noStroke();
  fill(0, 150);
  rect(0, 0, width, 32);
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(16);
  text("Nivel " + (nivelActual + 1) + ": " + NOMBRES_NIVELES[nivelActual], 10, 15);
  text("Gemas rojas: " + gemasRojas + "/" + totalRojas + "    Azules: " + gemasAzules + "/" + totalAzules, 330, 15);
  text("Tiempo: " + framesNivel / 60 + " s", 700, 15);
  btnPausaHUD.dibujar();
}

void dibujarMensajeMuerte() {
  fill(0, 150);
  rect(0, height / 2 - 40, width, 80);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(30);
  text(mensajeMuerte, width / 2, height / 2);
}

// Oscurece el juego y escribe un título (para la pausa y la victoria)
void dibujarPanel(String titulo) {
  fill(0, 170);
  noStroke();
  rect(0, 0, width, height);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text(titulo, width / 2, 160);
}

// En red, "Menú principal" lleva a la sala de red o sale de la partida
String textoBotonSalir() {
  if (modoRed == ANFITRION) return "Sala de red";
  if (modoRed == INVITADO) return "Salir de la partida";
  return "Menú principal";
}


// ---------------------------------------------------------------------
// Pausa
// ---------------------------------------------------------------------
void pausar() {
  estado = PAUSA;
  soltarTeclas();
}

void dibujarPausa() {
  dibujarPanel("PAUSA");
  btnPausaMenu.texto = textoBotonSalir();
  btnPausaMenu.dibujar();
  if (modoRed == INVITADO) {
    text("El anfitrión ha pausado la partida", width / 2, 260);   // el invitado solo puede salir
  } else {
    btnReanudar.dibujar();
    btnReiniciarNivel.dibujar();
  }
}

void clickPausa() {
  if (btnPausaMenu.encima()) {
    if (modoRed == INVITADO) desconectar();
    else irAlMenu();
  } else if (modoRed != INVITADO && btnReanudar.encima()) estado = JUGANDO;
  else if (modoRed != INVITADO && btnReiniciarNivel.encima()) reiniciarNivel();
}


// ---------------------------------------------------------------------
// Fin de nivel (y fin del juego al superar el nivel 10)
// ---------------------------------------------------------------------
void completarNivel() {
  nivelCompletado[nivelActual] = true;
  if (nivelActual + 1 < TOTAL_NIVELES && nivelDesbloqueado < nivelActual + 1) {
    nivelDesbloqueado = nivelActual + 1;      // desbloquea el siguiente nivel
  }
  guardarProgreso();
  reproducir(sonidoVictoria);
  soltarTeclas();
  estado = VICTORIA;
}

boolean esUltimoNivel() {
  return nivelActual == TOTAL_NIVELES - 1;
}

void siguienteNivel() {
  if (!esUltimoNivel()) cargarNivel(nivelActual + 1);
}

void dibujarVictoria() {
  if (esUltimoNivel()) {
    // victoria final: se han superado los 10 niveles
    dibujarPanel("¡VICTORIA!");
    textSize(26);
    text("Fuego y Agua han conquistado el Templo de la 35", width / 2, 220);
    textSize(18);
    text("Has completado los 10 niveles de Fireboy & Watergirl: La 35° Aventura", width / 2, 260);
  } else {
    dibujarPanel("¡Nivel " + (nivelActual + 1) + " superado!");
    textSize(22);
    text("Pulsa ENTER para continuar", width / 2, 260);
  }
  text("Gemas rojas: " + gemasRojas + "/" + totalRojas + "    Gemas azules: " + gemasAzules + "/" + totalAzules
    + "    Tiempo: " + framesNivel / 60 + " s", width / 2, 310);

  btnVictoriaMenu.texto = textoBotonSalir();
  btnVictoriaMenu.dibujar();
  if (modoRed == INVITADO) {
    text("El anfitrión elige cómo seguir", width / 2, 380);
  } else {
    if (!esUltimoNivel()) btnSiguiente.dibujar();
    btnRepetir.dibujar();
  }
}

void clickVictoria() {
  if (btnVictoriaMenu.encima()) {
    if (modoRed == INVITADO) desconectar();
    else irAlMenu();
  } else if (modoRed != INVITADO && btnSiguiente.encima()) siguienteNivel();
  else if (modoRed != INVITADO && btnRepetir.encima()) reiniciarNivel();
}
