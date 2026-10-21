// =====================================================================
// 11. INTERFAZ, PAUSA Y PANTALLAS DE VICTORIA
// =====================================================================

// ---------------------------------------------------------------------
// Marcador superior (HUD)
// ---------------------------------------------------------------------
void dibujarHUD() {
  noStroke();
  fill(0, 150);
  rect(0, 0, width, 34);

  fill(255);
  textAlign(LEFT, CENTER);
  textSize(17);
  text("Nivel " + (nivelActual + 1) + ": " + NOMBRES_NIVELES[nivelActual], 12, 16);

  dibujarIconoGema(390, 17, true, 0.7);
  fill(255);
  text(gemasRojas + "/" + totalRojas, 404, 16);
  dibujarIconoGema(470, 17, false, 0.7);
  fill(255);
  text(gemasAzules + "/" + totalAzules, 484, 16);

  text(formatoTiempo(framesNivel), 560, 16);

  textSize(13);
  fill(255, 170);
  text("ESC: pausa    R: reiniciar", 680, 16);

  // botón de pausa
  boolean sobre = encimaBotonPausa();
  fill(sobre ? color(255, 200, 80) : color(255, 230));
  ellipse(935, 17, 26, 26);
  fill(40);
  rect(929, 10, 4, 14);
  rect(937, 10, 4, 14);
}

boolean encimaBotonPausa() {
  return dist(mouseX, mouseY, 935, 17) < 14;
}

String formatoTiempo(int frames) {
  int segundos = frames / 60;
  return nf(segundos / 60, 2) + ":" + nf(segundos % 60, 2);
}

void dibujarMensajeMuerte() {
  fill(0, 150);
  noStroke();
  rect(0, height / 2 - 40, width, 80);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(30);
  text(mensajeMuerte, width / 2, height / 2 - 8);
  textSize(15);
  fill(255, 190);
  text("Reiniciando el nivel...", width / 2, height / 2 + 24);
}


// ---------------------------------------------------------------------
// Pausa
// ---------------------------------------------------------------------
void pausar() {
  estado = PAUSA;
  soltarTeclas();
}

void dibujarPausa() {
  actualizarTextosBotones();
  fill(0, 160);
  noStroke();
  rect(0, 0, width, height);
  panel(320, 120, 320, 330);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("PAUSA", width / 2, 165);
  btnReanudar.dibujar();
  btnReiniciarNivel.dibujar();
  btnPausaSonido.dibujar();
  btnPausaMusica.dibujar();
  btnPausaMenu.dibujar();
}

void clickPausa() {
  if (modoRed == INVITADO) {               // el invitado pide las acciones al anfitrión
    if (btnReanudar.encima()) enviarOrden("pausa");
    else if (btnReiniciarNivel.encima()) enviarOrden("reiniciar");
    else if (btnPausaSonido.encima()) alternarSonido();
    else if (btnPausaMusica.encima()) alternarMusica();
    else if (btnPausaMenu.encima()) desconectar();
    return;
  }
  if (btnReanudar.encima()) {
    reproducir(sonidoClick);
    estado = JUGANDO;
  } else if (btnReiniciarNivel.encima()) {
    reproducir(sonidoClick);
    reiniciarNivel();
  } else if (btnPausaSonido.encima()) {
    alternarSonido();
  } else if (btnPausaMusica.encima()) {
    alternarMusica();
  } else if (btnPausaMenu.encima()) {
    reproducir(sonidoClick);
    irAlMenu();
  }
}


// ---------------------------------------------------------------------
// Fin de nivel
// ---------------------------------------------------------------------
void completarNivel() {
  nivelCompletado[nivelActual] = true;
  if (nivelActual + 1 < TOTAL_NIVELES && nivelDesbloqueado < nivelActual + 1) {
    nivelDesbloqueado = nivelActual + 1;      // desbloquea el siguiente nivel
  }
  guardarProgreso();
  reproducir(sonidoVictoria);
  soltarTeclas();
  framesVictoria = 0;
  particulas.clear();
  if (nivelActual == TOTAL_NIVELES - 1) estado = VICTORIA_FINAL;
  else estado = VICTORIA;
}

void siguienteNivel() {
  if (nivelActual + 1 < TOTAL_NIVELES) cargarNivel(nivelActual + 1);
}

void dibujarVictoria() {
  framesVictoria++;
  // confeti durante los primeros segundos
  if (framesVictoria < 120 && framesVictoria % 3 == 0) {
    color c = random(1) < 0.5 ? color(255, 120, 40) : color(60, 170, 255);
    particulas.add(new Particula(random(width), -10, random(-1, 1), random(1, 3), c, random(5, 9), 160));
  }

  fill(0, 140);
  noStroke();
  rect(0, 0, width, height);
  panel(220, 130, 520, 380);

  fill(255, 220, 80);
  textAlign(CENTER, CENTER);
  textSize(38);
  text("¡Nivel " + (nivelActual + 1) + " superado!", width / 2, 180);
  fill(255);
  textSize(20);
  text(NOMBRES_NIVELES[nivelActual], width / 2, 220);

  dibujarCuerpo(330, 250 - abs(sin(framesVictoria * 0.1)) * 20, true, 1, 0, false, 1.5);
  dibujarCuerpo(595, 250 - abs(sin(framesVictoria * 0.1 + 1)) * 20, false, -1, 0, false, 1.5);

  dibujarIconoGema(420, 280, true, 1);
  dibujarIconoGema(500, 280, false, 1);
  fill(255);
  textSize(18);
  textAlign(LEFT, CENTER);
  text(gemasRojas + "/" + totalRojas, 436, 280);
  text(gemasAzules + "/" + totalAzules, 516, 280);
  textAlign(CENTER, CENTER);
  text("Tiempo: " + formatoTiempo(framesNivel), width / 2, 320);
  if (gemasRojas == totalRojas && gemasAzules == totalAzules) {
    fill(120, 255, 140);
    text("¡Todas las gemas recogidas!", width / 2, 350);
  }

  btnSiguiente.dibujar();
  btnRepetir.dibujar();
  btnVictoriaMenu.dibujar();
  fill(255, 150);
  textSize(13);
  textAlign(CENTER, CENTER);
  text("Pulsa ENTER para continuar", width / 2, 498);
}

void clickVictoria() {
  if (modoRed == INVITADO) {
    if (btnSiguiente.encima()) enviarOrden("siguiente");
    else if (btnRepetir.encima()) enviarOrden("reiniciar");
    else if (btnVictoriaMenu.encima()) desconectar();
    return;
  }
  if (btnSiguiente.encima()) {
    reproducir(sonidoClick);
    siguienteNivel();
  } else if (btnRepetir.encima()) {
    reproducir(sonidoClick);
    reiniciarNivel();
  } else if (btnVictoriaMenu.encima()) {
    reproducir(sonidoClick);
    irAlMenu();
  }
}


// ---------------------------------------------------------------------
// Victoria final (después del nivel 10)
// ---------------------------------------------------------------------
void dibujarVictoriaFinal() {
  framesVictoria++;

  // cielo nocturno
  background(10, 5, 35);
  for (int yy = 0; yy < height; yy += 4) {
    stroke(lerpColor(color(10, 5, 35), color(70, 30, 90), yy / (float) height));
    strokeWeight(4);
    line(0, yy, width, yy);
  }
  noStroke();
  for (int i = 0; i < estrellaX.length; i++) {
    fill(255, 150 + 100 * sin(frameCount * 0.05 + i));
    ellipse(estrellaX[i], estrellaY[i], 2.5, 2.5);
  }

  // fuegos artificiales
  if (framesVictoria % 25 == 0) {
    color c = color(random(150, 255), random(80, 255), random(80, 255));
    crearExplosion(random(100, width - 100), random(60, 260), c, 45);
  }
  actualizarParticulas();
  dibujarParticulas();

  // templo
  fill(120, 95, 60);
  rect(280, 380, 400, 140);
  triangle(260, 380, 700, 380, 480, 300);
  fill(90, 70, 45);
  for (int i = 0; i < 5; i++) rect(305 + i * 80, 400, 30, 120);
  fill(232, 197, 71);
  ellipse(480, 350, 30, 30);
  fill(60, 45, 30);
  rect(0, 520, width, 120);
  fill(232, 197, 71);
  rect(0, 520, width, 6);

  // los dos héroes saltando de alegría
  float saltoF = abs(sin(framesVictoria * 0.09)) * 50;
  float saltoA = abs(sin(framesVictoria * 0.09 + 1.2)) * 50;
  dibujarCuerpo(380, 520 - ALTO_PJ * 2 - saltoF, true, 1, 0, saltoF > 3, 2);
  dibujarCuerpo(540, 520 - ALTO_PJ * 2 - saltoA, false, -1, 0, saltoA > 3, 2);

  dibujarTitulo("¡VICTORIA!", 80, 70);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(26);
  text("Fuego y Agua han conquistado el Templo de la 35", width / 2, 150);
  textSize(17);
  fill(255, 210);
  text("Has completado los 10 niveles de Fireboy & Watergirl: La 35° Aventura", width / 2, 185);
  text("Niveles completados: " + contarCompletados() + " / " + TOTAL_NIVELES, width / 2, 210);

  actualizarTextosBotones();
  btnFinalMenu.dibujar();
  if (modoRed == INVITADO) {
    fill(255, 200);
    textSize(16);
    textAlign(CENTER, CENTER);
    text("El anfitrión elegirá cómo seguir.", 600, 585);
  } else {
    btnFinalSeleccion.dibujar();
  }
}

void clickVictoriaFinal() {
  if (modoRed == INVITADO) {
    if (btnFinalMenu.encima()) desconectar();
    return;
  }
  if (btnFinalMenu.encima()) {
    reproducir(sonidoClick);
    particulas.clear();
    irAlMenu();
  } else if (btnFinalSeleccion.encima()) {
    reproducir(sonidoClick);
    particulas.clear();
    estado = SELECCION;
  }
}
