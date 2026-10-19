// =====================================================================
// 10. SONIDOS
// =====================================================================
// Los sonidos no se cargan de archivos: se FABRICAN al arrancar sumando
// ondas (senos y ondas cuadradas), como en las consolas antiguas.
//
// Se usa javax.sound.sampled, que viene con Java, en lugar de la
// biblioteca processing.sound. Así el juego funciona sin instalar nada.
// Si el ordenador no tiene salida de audio, se captura el error y el
// juego sigue funcionando en modo silencioso.

final float FREC_MUESTREO = 22050;    // muestras por segundo

Clip sonidoSalto, sonidoGema, sonidoInterruptor, sonidoMuerte;
Clip sonidoPuerta, sonidoVictoria, sonidoClick;
Clip musicaFondo;
boolean audioDisponible = true;

// Formas de onda
final int SENO = 0;       // suave
final int CUADRADA = 1;   // sonido "retro"
final int RUIDO = 2;      // explosiones

void iniciarSonidos() {
  try {
    sonidoSalto = crearClip(barrido(300, 650, 0.13, 0.22, CUADRADA));
    sonidoGema = crearClip(unir(barrido(1046, 1046, 0.07, 0.3, SENO), barrido(1568, 1568, 0.14, 0.3, SENO)));
    sonidoInterruptor = crearClip(unir(barrido(220, 140, 0.05, 0.3, CUADRADA), barrido(520, 520, 0.06, 0.2, CUADRADA)));
    sonidoMuerte = crearClip(mezclar(barrido(520, 70, 0.5, 0.25, CUADRADA), barrido(0, 0, 0.3, 0.15, RUIDO)));
    sonidoPuerta = crearClip(barrido(90, 170, 0.35, 0.3, CUADRADA));
    sonidoVictoria = crearClip(unir(unir(barrido(523, 523, 0.11, 0.3, CUADRADA), barrido(659, 659, 0.11, 0.3, CUADRADA)),
      unir(barrido(784, 784, 0.11, 0.3, CUADRADA), barrido(1046, 1046, 0.4, 0.3, CUADRADA))));
    sonidoClick = crearClip(barrido(900, 700, 0.04, 0.2, SENO));
    musicaFondo = crearClip(crearMusica());
  }
  catch (Exception e) {
    audioDisponible = false;
    println("No hay audio disponible, el juego seguirá en silencio: " + e);
  }
}

// Reproduce un efecto desde el principio (si el sonido está activado)
void reproducir(Clip efecto) {
  if (!sonidoActivado || efecto == null) return;
  efecto.stop();
  efecto.setFramePosition(0);
  efecto.start();
}

// Enciende o apaga la música según la opción elegida
void actualizarMusica() {
  if (musicaFondo == null) return;
  if (musicaActivada) {
    if (!musicaFondo.isRunning()) {
      musicaFondo.setFramePosition(0);
      musicaFondo.loop(Clip.LOOP_CONTINUOUSLY);
    }
  } else {
    musicaFondo.stop();
  }
}

void detenerMusica() {
  if (musicaFondo != null) musicaFondo.stop();
}

void alternarSonido() {
  sonidoActivado = !sonidoActivado;
  reproducir(sonidoClick);
  guardarProgreso();
}

void alternarMusica() {
  musicaActivada = !musicaActivada;
  reproducir(sonidoClick);
  actualizarMusica();
  guardarProgreso();
}

// Crea un tono que va de frecInicio a frecFin durante 'segundos'
float[] barrido(float frecInicio, float frecFin, float segundos, float volumen, int forma) {
  int n = (int) (segundos * FREC_MUESTREO);
  float[] datos = new float[n];
  float fase = 0;
  for (int i = 0; i < n; i++) {
    float t = i / (float) n;                         // 0 al empezar, 1 al terminar
    float frec = lerp(frecInicio, frecFin, t);
    fase += TWO_PI * frec / FREC_MUESTREO;
    if (fase > TWO_PI) fase -= TWO_PI;
    float onda;
    if (forma == SENO) onda = sin(fase);
    else if (forma == CUADRADA) onda = sin(fase) > 0 ? 0.6 : -0.6;
    else onda = random(-1, 1);
    float envolvente = min(1, i / 150.0) * (1 - t);   // empieza suave y se apaga
    datos[i] = onda * volumen * envolvente;
  }
  return datos;
}

// Pone un sonido detrás de otro
float[] unir(float[] a, float[] b) {
  float[] r = new float[a.length + b.length];
  for (int i = 0; i < a.length; i++) r[i] = a[i];
  for (int i = 0; i < b.length; i++) r[a.length + i] = b[i];
  return r;
}

// Suena a la vez (suma las dos ondas)
float[] mezclar(float[] a, float[] b) {
  float[] r = new float[max(a.length, b.length)];
  for (int i = 0; i < r.length; i++) {
    if (i < a.length) r[i] += a[i];
    if (i < b.length) r[i] += b[i];
  }
  return r;
}

// Música de fondo: melodía de 32 corcheas y un bajo, en bucle.
// Los números son semitonos respecto a la nota La (440 Hz).
float[] crearMusica() {
  int[] melodia = {
    0, 3, 7, 12, 10, 7, 5, 7,
    3, 5, 7, 10, 7, 5, 3, 0,
    -4, 0, 3, 8, 7, 3, 2, 3,
    5, 7, 10, 7, 5, 2, -2, 2
  };
  int[] bajo = {
    -24, -24, -17, -24,
    -24, -24, -17, -21,
    -28, -28, -21, -28,
    -26, -26, -19, -26
  };
  float duracion = 0.19;                              // segundos por corchea
  int porNota = (int) (duracion * FREC_MUESTREO);
  float[] datos = new float[melodia.length * porNota];

  for (int n = 0; n < melodia.length; n++) {
    float frecMelodia = 440 * pow(2, melodia[n] / 12.0);
    float frecBajo = 440 * pow(2, bajo[n / 2] / 12.0);
    for (int i = 0; i < porNota; i++) {
      float t = i / FREC_MUESTREO;
      float env = min(1, i / 150.0) * exp(-t * 5);
      float melodiaOnda = (sin(TWO_PI * frecMelodia * t) + 0.3 * sin(TWO_PI * 2 * frecMelodia * t)) * env * 0.06;
      int iBajo = (n % 2) * porNota + i;              // el bajo dura dos corcheas
      float tBajo = iBajo / FREC_MUESTREO;
      float envBajo = min(1, iBajo / 200.0) * exp(-tBajo * 2.5);
      float bajoOnda = sin(TWO_PI * frecBajo * tBajo) * envBajo * 0.11;
      datos[n * porNota + i] = melodiaOnda + bajoOnda;
    }
  }
  return datos;
}

// Convierte las muestras (-1 a 1) en un Clip de Java listo para sonar.
// Si algo falla (por ejemplo, no hay tarjeta de sonido) devuelve null.
Clip crearClip(float[] muestras) {
  byte[] bytes = new byte[muestras.length * 2];
  for (int i = 0; i < muestras.length; i++) {
    int valor = (int) (constrain(muestras[i], -1, 1) * 32000);
    bytes[2 * i] = (byte) (valor & 0xFF);              // 16 bits, primero el byte bajo
    bytes[2 * i + 1] = (byte) ((valor >> 8) & 0xFF);
  }
  try {
    AudioFormat formato = new AudioFormat(FREC_MUESTREO, 16, 1, true, false);
    Clip nuevoClip = AudioSystem.getClip();
    // Equivale a: nuevoClip.open(formato, bytes, 0, bytes.length);
    // Lo escribimos así porque el editor de Processing 4.5 da un error de
    // sintaxis falso con la palabra "open" (es una palabra reservada de Java).
    Clip.class.getMethod("open", AudioFormat.class, byte[].class, int.class, int.class)
      .invoke(nuevoClip, formato, bytes, 0, bytes.length);
    return nuevoClip;
  }
  catch (Exception e) {
    audioDisponible = false;
    return null;
  }
}
