// =====================================================================
// 12. GUARDADO DEL PROGRESO
// =====================================================================
// El progreso se guarda en el archivo "progreso.txt", dentro de la
// carpeta del sketch. Es un archivo de texto normal, por ejemplo:
//
//   desbloqueado=3
//   completados=1110000000
//   sonido=1
//   musica=1
//
// Si el archivo no existe (primera partida) se empieza desde cero.

final String ARCHIVO_PROGRESO = "progreso.txt";

void guardarProgreso() {
  String completados = "";
  for (int i = 0; i < TOTAL_NIVELES; i++) {
    completados += nivelCompletado[i] ? "1" : "0";
  }
  String[] lineas = {
    "desbloqueado=" + nivelDesbloqueado,
    "completados=" + completados,
    "sonido=" + (sonidoActivado ? 1 : 0),
    "musica=" + (musicaActivada ? 1 : 0)
  };
  try {
    saveStrings(sketchPath(ARCHIVO_PROGRESO), lineas);
  }
  catch (Exception e) {
    println("No se pudo guardar el progreso: " + e);
  }
}

void cargarProgreso() {
  File archivo = new File(sketchPath(ARCHIVO_PROGRESO));
  if (!archivo.exists()) return;
  String[] lineas = loadStrings(archivo.getAbsolutePath());
  if (lineas == null) return;

  for (String linea : lineas) {
    String[] partes = split(trim(linea), '=');
    if (partes.length != 2) continue;
    String nombre = partes[0];
    String valor = partes[1];
    if (nombre.equals("desbloqueado")) {
      nivelDesbloqueado = constrain(int(valor), 0, TOTAL_NIVELES - 1);
    } else if (nombre.equals("completados")) {
      for (int i = 0; i < TOTAL_NIVELES && i < valor.length(); i++) {
        nivelCompletado[i] = valor.charAt(i) == '1';
      }
    } else if (nombre.equals("sonido")) {
      sonidoActivado = valor.equals("1");
    } else if (nombre.equals("musica")) {
      musicaActivada = valor.equals("1");
    }
  }
}

// Vuelve a dejar el juego como nuevo (mantiene las opciones de sonido)
void borrarProgreso() {
  nivelDesbloqueado = 0;
  for (int i = 0; i < TOTAL_NIVELES; i++) nivelCompletado[i] = false;
  guardarProgreso();
}
