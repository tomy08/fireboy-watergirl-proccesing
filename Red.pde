// =====================================================================
// 13. JUEGO EN RED (LAN)
// =====================================================================
// Dos ordenadores en la misma red (WiFi o cable) ejecutan este mismo
// programa:
//   - El ANFITRIÓN pulsa "Crear partida". Juega con Fuego y es quien
//     calcula de verdad el juego (física, gemas, puertas, muertes...).
//   - El otro pulsa "Unirse", escribe la IP del anfitrión y juega con Agua.
//     Solo envía sus teclas y dibuja lo que le cuenta el anfitrión.
//
// Se usa la biblioteca processing.net, que viene incluida con Processing.
// Los mensajes son líneas de texto terminadas en '\n':
//   Anfitrión -> invitado:  "S|..."  estado del juego (60 veces por segundo)
//                           "M"      el anfitrión está en los menús
//                           "E|..."  evento: sonido o explosión de partículas
//   Invitado -> anfitrión:  "K|izq|der|salto"  teclas de Agua (1 o 0)
//                           "C|orden"          pausa, reiniciar o siguiente

final int PUERTO = 5204;

// Modos de juego
final int LOCAL = 0;        // los dos jugadores en el mismo teclado
final int ANFITRION = 1;    // este ordenador ha creado la partida (Fuego)
final int INVITADO = 2;     // este ordenador se ha unido (Agua)
int modoRed = LOCAL;

Server servidor;            // solo lo usa el anfitrión
Client companero;           // en el anfitrión: el invitado conectado
Client conexion;            // en el invitado: la conexión con el anfitrión

String ipEscrita = "192.168.";     // IP que escribe el invitado
String misIPs = "";                // IPs de este ordenador (para enseñarlas)
String mensajeRed = "";            // avisos y errores
boolean conectando = false;        // el invitado está intentando conectar
boolean companeroSeFue = false;    // lo marca disconnectEvent()

// Teclas de Agua que llegan por la red (las usa el anfitrión)
boolean remotoIzq, remotoDer, remotoSalto;

// Cada vez que el anfitrión carga un nivel suma 1. Si el invitado ve un
// número distinto, carga también el nivel.
int idCarga = 0;
int idCargaInvitado = -1;

// Para que el invitado reconstruya el mensaje de muerte
char causaMuerte = ' ';
boolean muertoEsFuego = true;

boolean esEstadoDeJuego(int e) {
  return e == JUGANDO || e == PAUSA || e == VICTORIA || e == VICTORIA_FINAL;
}

// Al salir de una partida se vuelve a la sala de red (si estamos online)
void irAlMenu() {
  if (modoRed == LOCAL) estado = MENU;
  else if (modoRed == ANFITRION) estado = RED;
  else estado = ESPERA;
}


// ---------------------------------------------------------------------
// Crear, unirse y desconectar
// ---------------------------------------------------------------------
void crearPartida() {
  servidor = new Server(this, PUERTO);
  if (!servidor.active()) {
    mensajeRed = "No se pudo crear la partida (¿el puerto " + PUERTO + " está ocupado?)";
    servidor = null;
    return;
  }
  modoRed = ANFITRION;
  companero = null;
  misIPs = obtenerIPs();
  mensajeRed = "";
  estado = RED;
}

void unirsePartida() {
  if (conectando) return;
  conectando = true;
  mensajeRed = "Conectando con " + ipEscrita + "...";
  thread("conectarEnSegundoPlano");   // así la ventana no se congela mientras conecta
}

// Se ejecuta en otro hilo: conectar puede tardar unos segundos
void conectarEnSegundoPlano() {
  Client intento = new Client(this, trim(ipEscrita), PUERTO);
  if (intento.active()) {
    conexion = intento;
    companeroSeFue = false;
    modoRed = INVITADO;
    idCargaInvitado = -1;
    mensajeRed = "";
    estado = ESPERA;
  } else {
    mensajeRed = "No se pudo conectar con " + ipEscrita + ". Revisa la IP y que la partida esté creada.";
  }
  conectando = false;
}

// Cierra la conexión y vuelve al modo de un solo ordenador
void desconectar() {
  if (servidor != null) servidor.stop();
  if (conexion != null) conexion.stop();
  servidor = null;
  companero = null;
  conexion = null;
  modoRed = LOCAL;
  companeroSeFue = false;
  remotoIzq = remotoDer = remotoSalto = false;
  particulas.clear();
  estado = RED;
}

// Processing llama a esta función cuando alguien se conecta a nuestro servidor
void serverEvent(Server s, Client nuevo) {
  if (companero != null && companero.active()) {
    s.disconnect(nuevo);        // solo se admite un compañero
  } else {
    companero = nuevo;
    companeroSeFue = false;
  }
}

// Processing llama a esta función cuando se cae una conexión
void disconnectEvent(Client c) {
  if (c == companero || c == conexion) companeroSeFue = true;
}

// Busca las IP de este ordenador en la red local (ej: 192.168.1.35)
String obtenerIPs() {
  String ips = "";
  try {
    java.util.Enumeration<java.net.NetworkInterface> interfaces = java.net.NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
      java.net.NetworkInterface tarjeta = interfaces.nextElement();
      if (!tarjeta.isUp() || tarjeta.isLoopback() || tarjeta.isVirtual()) continue;
      java.util.Enumeration<java.net.InetAddress> direcciones = tarjeta.getInetAddresses();
      while (direcciones.hasMoreElements()) {
        java.net.InetAddress d = direcciones.nextElement();
        if (d instanceof java.net.Inet4Address) ips += d.getHostAddress() + "    ";
      }
    }
  }
  catch (Exception e) {
  }
  if (ips.equals("")) ips = "no encontrada (¿estás conectado a una red?)";
  return trim(ips);
}


// ---------------------------------------------------------------------
// Recibir y enviar (se llama al principio y al final de draw)
// ---------------------------------------------------------------------
void actualizarRed() {
  if (modoRed == ANFITRION) {
    // ¿se ha ido el compañero?
    if (companero != null && (companeroSeFue || !companero.active())) {
      companero = null;
      remotoIzq = remotoDer = remotoSalto = false;
      if (esEstadoDeJuego(estado) || estado == SELECCION) {
        estado = RED;
        mensajeRed = "Tu compañero se ha desconectado.";
      }
    }
    companeroSeFue = false;
    if (companero == null) return;
    String linea = companero.readStringUntil('\n');
    while (linea != null) {
      procesarMensajeInvitado(trim(linea));
      linea = companero.readStringUntil('\n');
    }
  } else if (modoRed == INVITADO) {
    if (companeroSeFue || !conexion.active()) {
      desconectar();
      mensajeRed = "Se ha perdido la conexión con el anfitrión.";
      companeroSeFue = false;
      return;
    }
    String linea = conexion.readStringUntil('\n');
    while (linea != null) {
      procesarMensajeAnfitrion(trim(linea));
      linea = conexion.readStringUntil('\n');
    }
  }
}

void enviarRed() {
  if (modoRed == ANFITRION && companero != null) {
    if (esEstadoDeJuego(estado) && fuego != null) companero.write(crearMensajeEstado() + "\n");
    else companero.write("M\n");
  } else if (modoRed == INVITADO && conexion != null) {
    // el invitado puede usar las flechas o W A D, como prefiera
    boolean izq = teclaIzq || teclaA;
    boolean der = teclaDer || teclaD;
    boolean salto = teclaArriba || teclaW;
    conexion.write("K|" + (izq ? 1 : 0) + "|" + (der ? 1 : 0) + "|" + (salto ? 1 : 0) + "\n");
  }
}

// El invitado pide algo al anfitrión (pausar, reiniciar, siguiente nivel)
void enviarOrden(String orden) {
  if (modoRed == INVITADO && conexion != null) conexion.write("C|" + orden + "\n");
}

// Sonidos y explosiones que el anfitrión reenvía al invitado
void enviarEvento(String evento) {
  if (modoRed == ANFITRION && companero != null) companero.write("E|" + evento + "\n");
}


// ---------------------------------------------------------------------
// Lo que hace el anfitrión con los mensajes del invitado
// ---------------------------------------------------------------------
void procesarMensajeInvitado(String linea) {
  String[] p = split(linea, '|');
  if (p[0].equals("K") && p.length == 4) {
    remotoIzq = p[1].equals("1");
    remotoDer = p[2].equals("1");
    remotoSalto = p[3].equals("1");
  } else if (p[0].equals("C") && p.length == 2) {
    String orden = p[1];
    if (orden.equals("pausa")) {
      if (estado == JUGANDO) pausar();
      else if (estado == PAUSA) estado = JUGANDO;
    } else if (orden.equals("reiniciar")) {
      if (estado == JUGANDO || estado == PAUSA || estado == VICTORIA) reiniciarNivel();
    } else if (orden.equals("siguiente")) {
      if (estado == VICTORIA) siguienteNivel();
    }
  }
}

// Todo lo necesario para dibujar la partida, en una sola línea de texto
String crearMensajeEstado() {
  String gemasTexto = "";
  for (Gema g : gemas) gemasTexto += g.recogida ? "1" : "0";
  String botonesTexto = "";
  for (Interruptor i : interruptores) botonesTexto += i.pulsado ? "1" : "0";
  String plataformasTexto = "";
  for (PlataformaMovil pm : plataformas) plataformasTexto += pm.x + ";" + pm.y + ";";

  return "S|" + idCarga + "|" + nivelActual + "|" + estado
    + "|" + textoPersonaje(fuego) + "|" + textoPersonaje(agua)
    + "|" + gemasTexto + "|" + gemasRojas + "|" + gemasAzules
    + "|" + (puertaAbierta[0] ? 1 : 0) + "|" + (puertaAbierta[1] ? 1 : 0)
    + "|" + aperturaPuerta[0] + "|" + aperturaPuerta[1]
    + "|" + aperturaSalidaFuego + "|" + aperturaSalidaAgua
    + "|" + tiempoMuerte + "|" + causaMuerte + "|" + (muertoEsFuego ? 1 : 0)
    + "|" + framesNivel + "|" + botonesTexto + "|" + plataformasTexto;
}

// x;y;enSuelo;direccion;paso;vivo;enSalida
String textoPersonaje(Personaje p) {
  return p.x + ";" + p.y + ";" + (p.enSuelo ? 1 : 0) + ";" + p.direccion + ";" + p.paso + ";"
    + (p.vivo ? 1 : 0) + ";" + (p.enSalida ? 1 : 0);
}


// ---------------------------------------------------------------------
// Lo que hace el invitado con los mensajes del anfitrión
// ---------------------------------------------------------------------
void procesarMensajeAnfitrion(String linea) {
  String[] p = split(linea, '|');
  if (p[0].equals("M")) {
    estado = ESPERA;
  } else if (p[0].equals("E")) {
    procesarEvento(p);
  } else if (p[0].equals("S") && p.length == 21) {
    aplicarEstado(p);
  }
}

void procesarEvento(String[] p) {
  if (p[1].equals("snd") && p.length == 3) {
    int numero = int(p[2]);
    if (numero >= 0 && numero < listaSonidos.length) reproducir(listaSonidos[numero]);
  } else if (p[1].equals("exp") && p.length == 6) {
    crearExplosion(float(p[2]), float(p[3]), int(p[4]), int(p[5]));
  }
}

void aplicarEstado(String[] p) {
  int id = int(p[1]);
  int nivel = int(p[2]);
  int nuevoEstado = int(p[3]);

  // ¿El anfitrión ha cargado (o reiniciado) un nivel? Lo cargamos también
  if (id != idCargaInvitado) {
    cargarNivel(nivel);
    idCargaInvitado = id;
  }
  // Al llegar a una pantalla de victoria se reinicia su animación
  if (nuevoEstado != estado && (nuevoEstado == VICTORIA || nuevoEstado == VICTORIA_FINAL)) {
    framesVictoria = 0;
    particulas.clear();
  }
  estado = nuevoEstado;

  leerPersonaje(fuego, p[4]);
  leerPersonaje(agua, p[5]);
  for (int i = 0; i < gemas.size() && i < p[6].length(); i++) gemas.get(i).recogida = p[6].charAt(i) == '1';
  gemasRojas = int(p[7]);
  gemasAzules = int(p[8]);
  puertaAbierta[0] = p[9].equals("1");
  puertaAbierta[1] = p[10].equals("1");
  aperturaPuerta[0] = float(p[11]);
  aperturaPuerta[1] = float(p[12]);
  aperturaSalidaFuego = float(p[13]);
  aperturaSalidaAgua = float(p[14]);
  tiempoMuerte = int(p[15]);
  causaMuerte = p[16].length() > 0 ? p[16].charAt(0) : ' ';
  muertoEsFuego = p[17].equals("1");
  if (tiempoMuerte > 0) mensajeMuerte = textoMuerte(causaMuerte, muertoEsFuego);
  framesNivel = int(p[18]);
  for (int i = 0; i < interruptores.size() && i < p[19].length(); i++) interruptores.get(i).pulsado = p[19].charAt(i) == '1';
  String[] pos = split(p[20], ';');
  for (int i = 0; i < plataformas.size() && i * 2 + 1 < pos.length; i++) {
    plataformas.get(i).x = float(pos[i * 2]);
    plataformas.get(i).y = float(pos[i * 2 + 1]);
  }
}

void leerPersonaje(Personaje pj, String texto) {
  String[] d = split(texto, ';');
  if (d.length != 7) return;
  pj.x = float(d[0]);
  pj.y = float(d[1]);
  pj.enSuelo = d[2].equals("1");
  pj.direccion = int(d[3]);
  pj.paso = float(d[4]);
  pj.vivo = d[5].equals("1");
  pj.enSalida = d[6].equals("1");
}

// El invitado no calcula el juego: solo anima lo decorativo
void actualizarJuegoInvitado() {
  actualizarParticulas();
  crearChispasAmbiente();
}


// ---------------------------------------------------------------------
// Pantallas: sala de red y espera del invitado
// ---------------------------------------------------------------------
BotonMenu btnCrear, btnUnirse, btnRedVolver;
BotonMenu btnRedContinuar, btnRedElegir, btnRedDesconectar;

void crearBotonesRed() {
  btnCrear = new BotonMenu(120, 300, 300, 56, "Crear partida", color(230, 95, 35));
  btnUnirse = new BotonMenu(540, 360, 300, 56, "Unirse", color(40, 120, 220));
  btnRedVolver = new BotonMenu(380, 570, 200, 46, "Volver", color(90, 90, 110));
  btnRedContinuar = new BotonMenu(330, 330, 300, 52, "", color(50, 160, 90));
  btnRedElegir = new BotonMenu(330, 392, 300, 52, "Elegir nivel", color(40, 120, 220));
  btnRedDesconectar = new BotonMenu(380, 570, 200, 46, "Desconectar", color(90, 90, 110));
}

void dibujarRed() {
  dibujarFondoMenu();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Jugar en red", width / 2, 50);
  textSize(15);
  fill(255, 190);
  text("Los dos ordenadores deben estar conectados a la misma red (WiFi o cable).", width / 2, 92);

  if (modoRed == LOCAL) {
    // Crear partida (izquierda)
    panel(80, 130, 380, 320);
    dibujarCuerpo(255, 175, true, 1, 0, false, 1.6);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(20);
    text("Crear partida", 270, 250);
    textSize(14);
    fill(255, 200);
    text("Tú juegas con Fuego.", 270, 380);
    text("Tu compañero se une con tu IP.", 270, 402);
    btnCrear.dibujar();

    // Unirse (derecha)
    panel(500, 130, 380, 320);
    dibujarCuerpo(675, 175, false, -1, 0, false, 1.6);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(20);
    text("Unirse a una partida", 690, 250);
    textSize(14);
    fill(255, 200);
    text("Escribe la IP del anfitrión:", 690, 280);
    // casilla de texto
    stroke(255);
    strokeWeight(2);
    fill(20, 15, 40);
    rect(560, 298, 260, 44, 8);
    noStroke();
    fill(255);
    textSize(22);
    String cursor = (frameCount / 30) % 2 == 0 ? "|" : "";
    text(ipEscrita + cursor, 690, 318);
    btnUnirse.dibujar();
    fill(255, 200);
    textSize(14);
    text("Tú juegas con Agua.", 690, 432);

    btnRedVolver.dibujar();
  } else if (modoRed == ANFITRION) {
    panel(180, 130, 600, 400);
    fill(255);
    textAlign(CENTER, CENTER);
    if (companero == null) {
      textSize(26);
      text("Esperando a tu compañero" + puntosEspera(), width / 2, 180);
      textSize(17);
      text("Dile que pulse \"Unirse\" y escriba esta IP:", width / 2, 240);
      fill(255, 220, 80);
      textSize(30);
      text(misIPs, width / 2, 290);
      fill(255, 190);
      textSize(15);
      text("Puerto " + PUERTO + ". Si Windows pregunta por el firewall, pulsa \"Permitir\".", width / 2, 340);
      dibujarCuerpo(400, 400, true, 1, frameCount * 0.2, false, 1.5);
      dibujarCuerpo(525, 400 - abs(sin(frameCount * 0.08)) * 15, false, -1, 0, true, 1.5);
    } else {
      textSize(28);
      fill(120, 255, 140);
      text("¡Tu compañero se ha unido!", width / 2, 185);
      fill(255);
      textSize(17);
      text("Tú eres Fuego y tu compañero es Agua.", width / 2, 230);
      text("Elige el nivel en este ordenador.", width / 2, 260);
      btnRedContinuar.texto = "Jugar (nivel " + (nivelDesbloqueado + 1) + ")";
      btnRedContinuar.dibujar();
      btnRedElegir.dibujar();
    }
    btnRedDesconectar.dibujar();
  }

  if (!mensajeRed.equals("")) {
    fill(255, 200, 120);
    textAlign(CENTER, CENTER);
    textSize(16);
    text(mensajeRed, width / 2, 545);
  }
}

String puntosEspera() {
  int n = (frameCount / 20) % 4;
  String puntos = "";
  for (int i = 0; i < n; i++) puntos += ".";
  return puntos;
}

void clickRed() {
  if (modoRed == LOCAL) {
    if (btnCrear.encima()) {
      reproducir(sonidoClick);
      crearPartida();
    } else if (btnUnirse.encima()) {
      reproducir(sonidoClick);
      unirsePartida();
    } else if (btnRedVolver.encima()) {
      reproducir(sonidoClick);
      mensajeRed = "";
      estado = MENU;
    }
  } else if (modoRed == ANFITRION) {
    if (companero != null && btnRedContinuar.encima()) {
      reproducir(sonidoClick);
      mensajeRed = "";
      cargarNivel(nivelDesbloqueado);
    } else if (companero != null && btnRedElegir.encima()) {
      reproducir(sonidoClick);
      mensajeRed = "";
      estado = SELECCION;
    } else if (btnRedDesconectar.encima()) {
      reproducir(sonidoClick);
      desconectar();
      mensajeRed = "";
    }
  }
}

// Escribir la IP con el teclado (números y puntos)
void escribirIP() {
  if (key == BACKSPACE) {
    if (ipEscrita.length() > 0) ipEscrita = ipEscrita.substring(0, ipEscrita.length() - 1);
  } else if (key == ENTER || key == RETURN) {
    unirsePartida();
  } else if ((key >= '0' && key <= '9') || key == '.') {
    if (ipEscrita.length() < 15) ipEscrita += key;
  }
}

// Pantalla del invitado mientras el anfitrión está en los menús
void dibujarEspera() {
  dibujarFondoMenu();
  dibujarEscenaMenu();
  panel(200, 150, 560, 260);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(28);
  text("Conectado como Agua", width / 2, 200);
  textSize(18);
  text("Esperando a que el anfitrión elija un nivel" + puntosEspera(), width / 2, 260);
  textSize(15);
  fill(255, 190);
  text("Puedes moverte con las flechas o con W A D.", width / 2, 310);
  text("ESC pide una pausa y R reinicia el nivel.", width / 2, 335);
  btnRedDesconectar.dibujar();
}

void clickEspera() {
  if (btnRedDesconectar.encima()) {
    reproducir(sonidoClick);
    desconectar();
    mensajeRed = "";
  }
}
