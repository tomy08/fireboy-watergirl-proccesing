// =====================================================================
// 10. SONIDOS
// =====================================================================
// Los sonidos no se cargan de archivos: se FABRICAN al arrancar con
// ondas, como en las consolas antiguas. Se usa javax.sound.sampled,
// que viene con Java, así que no hay que instalar nada. Si el ordenador
// no tiene audio, crearClip() devuelve null y el juego sigue en silencio.

final float FREC_MUESTREO = 22050;    // muestras por segundo

Clip sonidoSalto, sonidoGema, sonidoInterruptor, sonidoMuerte, sonidoPuerta, sonidoVictoria;
Clip musicaFondo;

void iniciarSonidos() {
  sonidoSalto = crearClip(tono(300, 650, 0.12));        // sube: salto
  sonidoGema = crearClip(tono(1000, 1600, 0.15));       // agudo: gema
  sonidoInterruptor = crearClip(tono(500, 300, 0.08));  // corto: botón
  sonidoMuerte = crearClip(tono(500, 70, 0.5));         // baja: muerte
  sonidoPuerta = crearClip(tono(90, 170, 0.35));        // grave: puerta
  sonidoVictoria = crearClip(tono(400, 1200, 0.6));     // sube largo: victoria
  musicaFondo = crearClip(crearMusica());
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
  if (musicaActivada) musicaFondo.loop(Clip.LOOP_CONTINUOUSLY);
  else musicaFondo.stop();
}

void detenerMusica() {
  if (musicaFondo != null) musicaFondo.stop();
}

void alternarSonido() {
  sonidoActivado = !sonidoActivado;
  guardarProgreso();
}

void alternarMusica() {
  musicaActivada = !musicaActivada;
  actualizarMusica();
  guardarProgreso();
}

// Crea un tono "retro" (onda cuadrada) que va de frecInicio a frecFin
// y se apaga poco a poco. Devuelve las muestras, entre -1 y 1.
float[] tono(float frecInicio, float frecFin, float segundos) {
  int n = (int) (segundos * FREC_MUESTREO);
  float[] muestras = new float[n];
  float fase = 0;
  for (int i = 0; i < n; i++) {
    float t = i / (float) n;                    // 0 al empezar, 1 al terminar
    fase += TWO_PI * lerp(frecInicio, frecFin, t) / FREC_MUESTREO;
    float onda = sin(fase) > 0 ? 1 : -1;        // onda cuadrada
    muestras[i] = onda * 0.15 * (1 - t);
  }
  return muestras;
}

// Música de fondo: 32 notas en bucle. Los números son semitonos
// respecto a la nota La (440 Hz).
float[] crearMusica() {
  int[] notas = {
    0, 3, 7, 12, 10, 7, 5, 7, 3, 5, 7, 10, 7, 5, 3, 0,
    -4, 0, 3, 8, 7, 3, 2, 3, 5, 7, 10, 7, 5, 2, -2, 2
  };
  int porNota = (int) (0.2 * FREC_MUESTREO);  // cada nota dura 0,2 segundos
  float[] muestras = new float[notas.length * porNota];
  for (int n = 0; n < notas.length; n++) {
    float frecuencia = 440 * pow(2, notas[n] / 12.0);
    for (int i = 0; i < porNota; i++) {
      float t = i / FREC_MUESTREO;
      muestras[n * porNota + i] = sin(TWO_PI * frecuencia * t) * 0.08 * (1 - i / (float) porNota);
    }
  }
  return muestras;
}

// Convierte las muestras en un Clip de Java listo para sonar.
// Si algo falla (por ejemplo, no hay tarjeta de sonido) devuelve null.
Clip crearClip(float[] muestras) {
  byte[] bytes = new byte[muestras.length * 2];   // 16 bits por muestra
  for (int i = 0; i < muestras.length; i++) {
    int valor = (int) (muestras[i] * 32000);
    bytes[2 * i] = (byte) (valor & 0xFF);         // primero el byte bajo
    bytes[2 * i + 1] = (byte) ((valor >> 8) & 0xFF);
  }
  try {
    AudioFormat formato = new AudioFormat(FREC_MUESTREO, 16, 1, true, false);
    Clip nuevoClip = AudioSystem.getClip();
    // Equivale a: nuevoClip.open(formato, bytes, 0, bytes.length);
    // Se escribe así porque Processing 4.5 da un error de sintaxis falso
    // con la palabra "open" (es una palabra reservada de Java).
    Clip.class.getMethod("open", AudioFormat.class, byte[].class, int.class, int.class)
      .invoke(nuevoClip, formato, bytes, 0, bytes.length);
    return nuevoClip;
  }
  catch (Exception e) {
    return null;
  }
}
