// =====================================================================
// 13. JUEGO EN RED (LAN)
// =====================================================================
// Los dos ordenadores ejecutan este mismo programa:
//   - El ANFITRIÓN pulsa "Crear partida", juega con Fuego y es quien
//     calcula de verdad el juego (física, gemas, puertas, muertes...).
//   - El INVITADO pulsa "Unirse", escribe la IP del anfitrión y juega con
//     Agua. Solo envía sus teclas y dibuja lo que le cuenta el anfitrión.
//
// Los mensajes son líneas de texto terminadas en '\n':
//   Anfitrión -> invitado:  "S|..."  estado del juego (60 veces por segundo)
//                           "M"      el anfitrión está en los menús
//   Invitado -> anfitrión:  "K|izq|der|salto"  teclas de Agua (1 o 0)
// Solo el anfitrión pausa, reinicia o elige el nivel.

final int PUERTO = 5204;

final int LOCAL = 0;        // los dos jugadores en el mismo teclado
final int ANFITRION = 1;    // este ordenador ha creado la partida (Fuego)
final int INVITADO = 2;     // este ordenador se ha unido (Agua)
int modoRed = LOCAL;

Server servidor;            // solo lo usa el anfitrión
Client companero;           // en el anfitrión: el invitado conectado
Client conexion;            // en el invitado: la conexión con el anfitrión

String ipEscrita = "192.168.";     // IP que escribe el invitado
String misIPs = "";                // IPs de este ordenador (las ve el anfitrión)
String mensajeRed = "";            // avisos y errores
boolean conectando = false;        // el invitado está intentando conectar
boolean companeroSeFue = false;    // lo marca disconnectEvent()

boolean remotoIzq, remotoDer, remotoSalto;   // teclas de Agua que llegan por la red

// Cada vez que el anfitrión carga un nivel suma 1. Si el invitado ve un
// número distinto, carga también ese nivel.
int idCarga = 0;
int idCargaInvitado = -1;

// Para que el invitado pueda escribir el mensaje de muerte
char causaMuerte = ' ';
boolean muertoEsFuego = true;

// Al salir de una partida se vuelve a la sala de red (si estamos en red)
void irAlMenu() {
  if (modoRed == LOCAL) estado = MENU;
  else if (modoRed == ANFITRION) estado = RED;
  else estado = ESPERA;
}

boolean esEstadoDeJuego(int e) {
  return e == JUGANDO || e == PAUSA || e == VICTORIA;
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
}

void unirsePartida() {
  if (conectando) return;
  conectando = true;
  mensajeRed = "Conectando con " + ipEscrita + "...";
  thread("conectarEnSegundoPlano");   // así la ventana no se congela mientras conecta
}

// Se ejecuta en otro hilo, porque conectar puede tardar unos segundos
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
    mensajeRed = "No se pudo conectar con " + ipEscrita + ". Revisa la IP.";
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
    for (java.net.NetworkInterface tarjeta : java.util.Collections.list(java.net.NetworkInterface.getNetworkInterfaces())) {
      if (!tarjeta.isUp() || tarjeta.isLoopback() || tarjeta.isVirtual()) continue;
      for (java.net.InetAddress d : java.util.Collections.list(tarjeta.getInetAddresses())) {
        if (d instanceof java.net.Inet4Address) ips += d.getHostAddress() + "   ";
      }
    }
  }
  catch (Exception e) {
  }
  return ips;
}


// ---------------------------------------------------------------------
// Recibir y enviar (al principio y al final de draw)
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
  if (modoRed == ANFITRION && companero != null && companero.active()) {
    if (esEstadoDeJuego(estado)) companero.write(crearMensajeEstado() + "\n");
    else companero.write("M\n");
  } else if (modoRed == INVITADO && conexion != null && conexion.active()) {
    // el invitado puede usar las flechas o W A D, como prefiera
    boolean izq = teclaIzq || teclaA;
    boolean der = teclaDer || teclaD;
    boolean salto = teclaArriba || teclaW;
    conexion.write("K|" + (izq ? 1 : 0) + "|" + (der ? 1 : 0) + "|" + (salto ? 1 : 0) + "\n");
  }
}


// ---------------------------------------------------------------------
// El anfitrión recibe las teclas del invitado
// ---------------------------------------------------------------------
void procesarMensajeInvitado(String linea) {
  String[] p = split(linea, '|');
  if (p[0].equals("K") && p.length == 4) {
    remotoIzq = p[1].equals("1");
    remotoDer = p[2].equals("1");
    remotoSalto = p[3].equals("1");
  }
}

// Todo lo necesario para dibujar la partida, en una sola línea de texto:
// S|idCarga|nivel|estado|fuego|agua|gemas|rojas|azules|puertaX|puertaY|
//   tiempoMuerte|causa|muertoEsFuego|cronómetro|botones|plataformas
String crearMensajeEstado() {
  String textoGemas = "";
  for (Gema g : gemas) textoGemas += g.recogida ? "1" : "0";
  String textoBotones = "";
  for (Interruptor i : interruptores) textoBotones += i.pulsado ? "1" : "0";
  String textoPlataformas = "";
  for (PlataformaMovil pm : plataformas) textoPlataformas += pm.x + ";" + pm.y + ";";

  return "S|" + idCarga + "|" + nivelActual + "|" + estado
    + "|" + textoPersonaje(fuego) + "|" + textoPersonaje(agua)
    + "|" + textoGemas + "|" + gemasRojas + "|" + gemasAzules
    + "|" + (puertaAbierta[0] ? 1 : 0) + "|" + (puertaAbierta[1] ? 1 : 0)
    + "|" + tiempoMuerte + "|" + causaMuerte + "|" + (muertoEsFuego ? 1 : 0)
    + "|" + framesNivel + "|" + textoBotones + "|" + textoPlataformas;
}

// Un personaje como texto: x;y;vivo;enSalida
String textoPersonaje(Personaje p) {
  return p.x + ";" + p.y + ";" + (p.vivo ? 1 : 0) + ";" + (p.enSalida ? 1 : 0);
}


// ---------------------------------------------------------------------
// El invitado aplica lo que le manda el anfitrión
// ---------------------------------------------------------------------
void procesarMensajeAnfitrion(String linea) {
  String[] p = split(linea, '|');
  if (p[0].equals("M")) {
    estado = ESPERA;
  } else if (p[0].equals("S") && p.length == 17) {
    aplicarEstado(p);
  }
}

void aplicarEstado(String[] p) {
  // ¿El anfitrión ha cargado (o reiniciado) un nivel? Lo cargamos también
  int id = int(p[1]);
  if (id != idCargaInvitado) {
    cargarNivel(int(p[2]));
    idCargaInvitado = id;
  }
  estado = int(p[3]);
  leerPersonaje(fuego, p[4]);
  leerPersonaje(agua, p[5]);
  for (int i = 0; i < gemas.size(); i++) gemas.get(i).recogida = p[6].charAt(i) == '1';
  gemasRojas = int(p[7]);
  gemasAzules = int(p[8]);
  puertaAbierta[0] = p[9].equals("1");
  puertaAbierta[1] = p[10].equals("1");
  tiempoMuerte = int(p[11]);
  if (tiempoMuerte > 0) mensajeMuerte = textoMuerte(p[12].charAt(0), p[13].equals("1"));
  framesNivel = int(p[14]);
  for (int i = 0; i < interruptores.size(); i++) interruptores.get(i).pulsado = p[15].charAt(i) == '1';
  String[] pos = split(p[16], ';');
  for (int i = 0; i < plataformas.size(); i++) {
    plataformas.get(i).x = float(pos[i * 2]);
    plataformas.get(i).y = float(pos[i * 2 + 1]);
  }
}

void leerPersonaje(Personaje pj, String texto) {
  String[] d = split(texto, ';');
  pj.x = float(d[0]);
  pj.y = float(d[1]);
  pj.vivo = d[2].equals("1");
  pj.enSalida = d[3].equals("1");
}


// ---------------------------------------------------------------------
// Pantallas: sala de red y espera del invitado
// ---------------------------------------------------------------------
void dibujarRed() {
  background(40, 30, 70);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("Jugar en red", width / 2, 50);
  textSize(18);
  text("Los dos ordenadores deben estar en la misma red (WiFi o cable).", width / 2, 100);

  if (modoRed == LOCAL) {
    text("Tú juegas con Fuego", 270, 260);
    btnCrear.dibujar();
    text("Escribe la IP del anfitrión (juegas con Agua):", 690, 260);
    fill(20, 15, 40);
    stroke(255);
    rect(560, 290, 260, 50, 8);
    noStroke();
    fill(255);
    textSize(24);
    text(ipEscrita, 690, 315);
    btnUnirse.dibujar();
    btnVolver.dibujar();
  } else if (companero == null) {
    textSize(26);
    text("Esperando a tu compañero...", width / 2, 200);
    textSize(18);
    text("Dile que pulse \"Unirse\" y escriba esta IP:", width / 2, 260);
    fill(255, 220, 80);
    textSize(30);
    text(misIPs, width / 2, 310);
    fill(255);
    textSize(16);
    text("Si Windows pregunta por el firewall, pulsa \"Permitir\".", width / 2, 360);
    btnDesconectar.dibujar();
  } else {
    textSize(26);
    text("¡Tu compañero (Agua) se ha unido!", width / 2, 200);
    btnRedJugar.texto = "Jugar (nivel " + (nivelDesbloqueado + 1) + ")";
    btnRedJugar.dibujar();
    btnRedElegir.dibujar();
    btnDesconectar.dibujar();
  }

  fill(255, 200, 120);
  textAlign(CENTER, CENTER);
  textSize(16);
  text(mensajeRed, width / 2, 540);
}

void clickRed() {
  if (modoRed == LOCAL) {
    if (btnCrear.encima()) crearPartida();
    else if (btnUnirse.encima()) unirsePartida();
    else if (btnVolver.encima()) estado = MENU;
  } else {
    if (companero != null && btnRedJugar.encima()) cargarNivel(nivelDesbloqueado);
    else if (companero != null && btnRedElegir.encima()) estado = SELECCION;
    else if (btnDesconectar.encima()) desconectar();
  }
}

// Escribir la IP con el teclado (números y puntos)
void escribirIP() {
  if (key == BACKSPACE && ipEscrita.length() > 0) ipEscrita = ipEscrita.substring(0, ipEscrita.length() - 1);
  else if (key == ENTER || key == RETURN) unirsePartida();
  else if ((key >= '0' && key <= '9') || key == '.') ipEscrita += key;
}

// Pantalla del invitado mientras el anfitrión está en los menús
void dibujarEspera() {
  background(40, 30, 70);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(28);
  text("Conectado como Agua", width / 2, 200);
  textSize(18);
  text("Esperando a que el anfitrión elija un nivel...", width / 2, 260);
  text("Puedes moverte con las flechas o con W A D.", width / 2, 310);
  btnDesconectar.dibujar();
}
