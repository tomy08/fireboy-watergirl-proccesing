import javax.sound.sampled.*;   // sonido de Java (ya incluido, no hay que instalarlo)
import processing.net.*;        // red local (biblioteca incluida con Processing)


// =====================================================================
// 1. VARIABLES GLOBALES
// =====================================================================
final int TAM = 32;            // tamaño de una casilla en píxeles
final int COLUMNAS = 30;       // 30 casillas x 32 px = 960 px de ancho
final int FILAS = 20;          // 20 casillas x 32 px = 640 px de alto
final int TOTAL_NIVELES = 10;

// Pantallas (estados) del juego
final int MENU = 0, SELECCION = 1, AYUDA = 2, JUGANDO = 3, PAUSA = 4;
final int VICTORIA = 5, RED = 6, ESPERA = 7;
int estado = MENU;

// Datos del nivel que se está jugando
int nivelActual = 0;                             // 0 = nivel 1 ... 9 = nivel 10
char[][] mapa = new char[FILAS][COLUMNAS];       // casillas del nivel
Personaje fuego, agua;
ArrayList<Gema> gemas = new ArrayList<Gema>();
ArrayList<Interruptor> interruptores = new ArrayList<Interruptor>();
ArrayList<PlataformaMovil> plataformas = new ArrayList<PlataformaMovil>();
int salidaFuegoCol, salidaFuegoFila;             // casilla de la puerta de Fuego
int salidaAguaCol, salidaAguaFila;               // casilla de la puerta de Agua
boolean[] puertaAbierta = new boolean[2];        // [0] = puertas X (moradas), [1] = puertas Y (amarillas)
int gemasRojas, gemasAzules;                     // gemas recogidas
int totalRojas, totalAzules;                     // gemas que tiene el nivel
int tiempoMuerte = 0;                            // cuenta atrás después de morir
String mensajeMuerte = "";
int tiempoSalida = 0;                            // frames que llevan los dos en su puerta
int framesNivel = 0;                             // cronómetro del nivel (60 frames = 1 segundo)

// Teclado (true mientras la tecla está pulsada)
boolean teclaA, teclaD, teclaW;                  // Fuego
boolean teclaIzq, teclaDer, teclaArriba;         // Agua

// Progreso guardado
int nivelDesbloqueado = 0;                       // último nivel desbloqueado (0 a 9)
boolean[] nivelCompletado = new boolean[TOTAL_NIVELES];
boolean sonidoActivado = true;
boolean musicaActivada = true;


// =====================================================================
// 2. CONFIGURACIÓN INICIAL
// =====================================================================
void setup() {
  size(960, 640);
  frameRate(60);
  cargarProgreso();      // pestaña Guardado
  crearBotones();        // pestaña Menu
  iniciarSonidos();      // pestaña Sonido
  actualizarMusica();
}


// =====================================================================
// 3. BUCLE PRINCIPAL
// =====================================================================
void draw() {
  actualizarRed();       // recibe los mensajes de la red (pestaña Red)

  if (estado == MENU) dibujarMenu();
  else if (estado == SELECCION) dibujarSeleccion();
  else if (estado == AYUDA) dibujarAyuda();
  else if (estado == RED) dibujarRed();
  else if (estado == ESPERA) dibujarEspera();
  else if (estado == JUGANDO) {
    if (modoRed != INVITADO) actualizarJuego();   // el invitado no calcula, solo dibuja
    dibujarJuego();
  } else if (estado == PAUSA) {
    dibujarJuego();
    dibujarPausa();
  } else if (estado == VICTORIA) {
    dibujarJuego();
    dibujarVictoria();
  }

  enviarRed();           // envía el estado (anfitrión) o las teclas (invitado)
}

// Un paso de la partida: mueve todo y comprueba las reglas
void actualizarJuego() {
  framesNivel++;

  // Si alguien ha muerto, esperamos un momento y reiniciamos el nivel
  if (tiempoMuerte > 0) {
    tiempoMuerte--;
    if (tiempoMuerte == 0) reiniciarNivel();
    return;
  }

  for (PlataformaMovil p : plataformas) p.actualizar();   // primero las plataformas (llevan a los personajes)
  if (modoRed == ANFITRION) {
    // En red, el anfitrión maneja a Fuego con cualquiera de las teclas
    // y Agua se mueve con las teclas que llegan del otro ordenador
    fuego.actualizar(teclaA || teclaIzq, teclaD || teclaDer, teclaW || teclaArriba);
    agua.actualizar(remotoIzq, remotoDer, remotoSalto);
  } else {
    fuego.actualizar(teclaA, teclaD, teclaW);
    agua.actualizar(teclaIzq, teclaDer, teclaArriba);
  }

  comprobarGemas();
  actualizarPuertas();
  comprobarPeligros();
  comprobarSalidas();
}

// Dibuja el nivel completo
void dibujarJuego() {
  background(60, 90, 130);
  dibujarMapa();
  dibujarSalidas();
  for (Interruptor i : interruptores) i.dibujar();
  for (PlataformaMovil p : plataformas) p.dibujar();
  for (Gema g : gemas) g.dibujar();
  if (fuego.vivo) fuego.dibujar();
  if (agua.vivo) agua.dibujar();
  dibujarHUD();
  if (tiempoMuerte > 0) dibujarMensajeMuerte();
}


// ---------------------------------------------------------------------
// Teclado y ratón
// ---------------------------------------------------------------------
void keyPressed() {
  // ESC normalmente cierra Processing: lo "anulamos" con key = 0
  if (key == ESC) {
    key = 0;
    if (modoRed == INVITADO) return;   // en red, solo el anfitrión pausa la partida
    if (estado == JUGANDO) pausar();
    else if (estado == PAUSA) estado = JUGANDO;
    else if (estado == SELECCION) irAlMenu();
    else if (estado == AYUDA || (estado == RED && modoRed == LOCAL)) estado = MENU;
    return;
  }

  // En la sala de red el teclado sirve para escribir la IP
  if (estado == RED && modoRed == LOCAL) {
    escribirIP();
    return;
  }

  cambiarTecla(true);
  if (modoRed == INVITADO) return;   // el invitado solo mueve a Agua: el anfitrión controla la partida

  if (estado == JUGANDO && (key == 'r' || key == 'R')) reiniciarNivel();
  if (estado == JUGANDO && (key == 'p' || key == 'P')) pausar();
  else if (estado == PAUSA && (key == 'p' || key == 'P')) estado = JUGANDO;
  if (estado == VICTORIA && (key == ENTER || key == RETURN)) siguienteNivel();
}

void keyReleased() {
  cambiarTecla(false);
}

// Guarda qué teclas están pulsadas. Así cada jugador se mueve de forma
// continua y las teclas de uno no afectan al otro.
void cambiarTecla(boolean pulsada) {
  if (key == CODED) {
    if (keyCode == LEFT)  teclaIzq = pulsada;
    if (keyCode == RIGHT) teclaDer = pulsada;
    if (keyCode == UP)    teclaArriba = pulsada;
  } else {
    char k = Character.toLowerCase(key);
    if (k == 'a') teclaA = pulsada;
    if (k == 'd') teclaD = pulsada;
    if (k == 'w') teclaW = pulsada;
  }
}

// Suelta todas las teclas (al cambiar de pantalla, para que nadie se mueva solo)
void soltarTeclas() {
  teclaA = teclaD = teclaW = false;
  teclaIzq = teclaDer = teclaArriba = false;
}

void mousePressed() {
  if (estado == MENU) clickMenu();
  else if (estado == SELECCION) clickSeleccion();
  else if (estado == AYUDA && btnVolver.encima()) estado = MENU;
  else if (estado == RED) clickRed();
  else if (estado == ESPERA && btnDesconectar.encima()) desconectar();
  else if (estado == JUGANDO && btnPausaHUD.encima() && modoRed != INVITADO) pausar();
  else if (estado == PAUSA) clickPausa();
  else if (estado == VICTORIA) clickVictoria();
}
