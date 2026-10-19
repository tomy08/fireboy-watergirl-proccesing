import javax.sound.sampled.*;   // sonido de Java (ya incluido, no hay que instalarlo)
import processing.net.*;        // red local (biblioteca incluida con Processing)


// =====================================================================
// 1. VARIABLES GLOBALES
// =====================================================================

// --- Tamaño del mapa ---
final int TAM = 32;            // tamaño de una casilla en píxeles
final int COLUMNAS = 30;       // 30 casillas x 32 px = 960 px de ancho
final int FILAS = 20;          // 20 casillas x 32 px = 640 px de alto
final int TOTAL_NIVELES = 10;

// --- Pantallas (estados) del juego ---
final int MENU = 0;
final int SELECCION = 1;
final int AYUDA = 2;
final int JUGANDO = 3;
final int PAUSA = 4;
final int VICTORIA = 5;
final int VICTORIA_FINAL = 6;
final int RED = 7;              // sala para crear o unirse a una partida en red
final int ESPERA = 8;           // el invitado espera a que el anfitrión elija nivel
int estado = MENU;

// --- Datos del nivel que se está jugando ---
int nivelActual = 0;                             // 0 = nivel 1 ... 9 = nivel 10
char[][] mapa = new char[FILAS][COLUMNAS];       // casillas del nivel
Personaje fuego, agua;
ArrayList<Gema> gemas = new ArrayList<Gema>();
ArrayList<Interruptor> interruptores = new ArrayList<Interruptor>();
ArrayList<PlataformaMovil> plataformas = new ArrayList<PlataformaMovil>();
ArrayList<Particula> particulas = new ArrayList<Particula>();
int salidaFuegoCol, salidaFuegoFila;             // casilla de la puerta de Fuego
int salidaAguaCol, salidaAguaFila;               // casilla de la puerta de Agua
float aperturaSalidaFuego = 0, aperturaSalidaAgua = 0;  // animación de las puertas de salida

boolean[] puertaAbierta = new boolean[2];        // [0] = puertas X (moradas), [1] = puertas Y (amarillas)
float[] aperturaPuerta = new float[2];           // 0 = cerrada ... 1 = abierta (animación)

int gemasRojas, gemasAzules;                     // gemas recogidas en este intento
int totalRojas, totalAzules;                     // gemas que tiene el nivel
int tiempoMuerte = 0;                            // cuenta atrás después de morir
String mensajeMuerte = "";
int tiempoSalida = 0;                            // frames que llevan los dos en su puerta
int framesNivel = 0;                             // cronómetro del nivel (en frames)
int framesVictoria = 0;                          // para animar las pantallas de victoria

// --- Teclado (true mientras la tecla está pulsada) ---
boolean teclaA, teclaD, teclaW;                  // Fuego
boolean teclaIzq, teclaDer, teclaArriba;         // Agua

// --- Progreso guardado ---
int nivelDesbloqueado = 0;                       // último nivel desbloqueado (0 a 9)
boolean[] nivelCompletado = new boolean[TOTAL_NIVELES];
boolean sonidoActivado = true;                   // efectos de sonido
boolean musicaActivada = true;                   // música de fondo

// --- Gráficos ---
PGraphics capaFondo;                             // fondo + bloques del nivel (se dibuja una vez)
PFont fuente;


// =====================================================================
// 2. CONFIGURACIÓN INICIAL
// =====================================================================
void setup() {
  size(960, 640);
  frameRate(60);
  fuente = createFont("SansSerif", 32, true);
  textFont(fuente);

  cargarProgreso();      // lee progreso.txt si existe (pestaña Guardado)
  crearBotones();        // botones de todas las pantallas (pestaña Menu)
  crearBotonesRed();     // botones de la sala de red (pestaña Red)
  iniciarMenu();         // estrellas y chispas decorativas (pestaña Menu)
  iniciarSonidos();      // crea los efectos y la música (pestaña Sonido)
  actualizarMusica();
}


// =====================================================================
// 3. BUCLE PRINCIPAL
// =====================================================================
void draw() {
  actualizarRed();           // recibe los mensajes de la red (si se juega online)

  if (estado == MENU) {
    dibujarMenu();
  } else if (estado == SELECCION) {
    dibujarSeleccion();
  } else if (estado == AYUDA) {
    dibujarAyuda();
  } else if (estado == RED) {
    dibujarRed();
  } else if (estado == ESPERA) {
    dibujarEspera();
  } else if (estado == JUGANDO) {
    if (modoRed == INVITADO) actualizarJuegoInvitado();   // el invitado solo dibuja
    else actualizarJuego();
    dibujarJuego();
  } else if (estado == PAUSA) {
    dibujarJuego();          // el nivel se ve quieto detrás del menú de pausa
    dibujarPausa();
  } else if (estado == VICTORIA) {
    actualizarParticulas();
    dibujarJuego();
    dibujarVictoria();
  } else if (estado == VICTORIA_FINAL) {
    dibujarVictoriaFinal();
  }

  enviarRed();               // envía el estado (anfitrión) o las teclas (invitado)
}

// Un paso de la partida: mueve todo y comprueba las reglas
void actualizarJuego() {
  framesNivel++;
  actualizarParticulas();

  // Si alguien ha muerto, esperamos un momento y reiniciamos el nivel
  if (tiempoMuerte > 0) {
    tiempoMuerte--;
    if (tiempoMuerte == 0) reiniciarNivel();
    return;
  }

  for (PlataformaMovil p : plataformas) p.actualizar();   // primero las plataformas (llevan a los personajes)
  if (modoRed == ANFITRION) {
    // En red, el anfitrión maneja a Fuego con W A D o con las flechas,
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
  crearChispasAmbiente();
}

// Dibuja el nivel completo
void dibujarJuego() {
  image(capaFondo, 0, 0);
  dibujarLiquidos();
  dibujarPuertas();
  dibujarSalidas();
  for (Interruptor i : interruptores) i.dibujar();
  for (PlataformaMovil p : plataformas) p.dibujar();
  for (Gema g : gemas) g.dibujar();
  if (fuego.vivo) fuego.dibujar();
  if (agua.vivo) agua.dibujar();
  dibujarParticulas();
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
    if (modoRed == INVITADO) {
      if (estado == JUGANDO || estado == PAUSA) enviarOrden("pausa");   // se lo pide al anfitrión
    } else if (estado == JUGANDO) pausar();
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

  // El invitado no controla la partida: pide las acciones al anfitrión
  if (modoRed == INVITADO) {
    if ((key == 'r' || key == 'R') && (estado == JUGANDO || estado == PAUSA)) enviarOrden("reiniciar");
    if ((key == 'p' || key == 'P') && (estado == JUGANDO || estado == PAUSA)) enviarOrden("pausa");
    if ((key == ENTER || key == RETURN) && estado == VICTORIA) enviarOrden("siguiente");
    return;
  }

  if (estado == JUGANDO && (key == 'r' || key == 'R')) reiniciarNivel();
  if (estado == JUGANDO && (key == 'p' || key == 'P')) pausar();
  else if (estado == PAUSA && (key == 'p' || key == 'P')) estado = JUGANDO;
  if (estado == VICTORIA && (key == ENTER || key == RETURN)) siguienteNivel();
}

void keyReleased() {
  cambiarTecla(false);
}

// Guarda en las variables qué teclas están pulsadas. Así cada jugador
// se mueve de forma continua y las teclas de uno no afectan al otro.
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
  else if (estado == AYUDA) clickAyuda();
  else if (estado == RED) clickRed();
  else if (estado == ESPERA) clickEspera();
  else if (estado == JUGANDO && encimaBotonPausa()) {
    if (modoRed == INVITADO) enviarOrden("pausa");
    else pausar();
  }
  else if (estado == PAUSA) clickPausa();
  else if (estado == VICTORIA) clickVictoria();
  else if (estado == VICTORIA_FINAL) clickVictoriaFinal();
}
