
import 'package:flutter/services.dart';

/// Point d'accès unique au code natif Kotlin.
class CanauxNatifs {

  // 1. Informations de l'appareil
  static const _infos = MethodChannel('appareil/infos');

  static Future<Map<String, dynamic>> lireInfos() async {
    final infos = await _infos.invokeMapMethod<String, dynamic>('lire');
    return infos ?? {};
  }

  // 2. Vibration
  static const _vibrer = MethodChannel('appareil/vibrer');

  static Future<bool> vibrer() async {
    final resultat = await _vibrer.invokeMethod<bool>('vibrer');
    return resultat ?? false;
  }

  // 3. Capteur de lumière
  static const _lumiere = EventChannel('capteur/lumiere');

  static Stream<double> lumiere() =>
    _lumiere.receiveBroadcastStream().map((v) => (v as num).toDouble());

static const _permission = MethodChannel('audio/permission');
static const _audio = EventChannel('audio/niveau');

static Future<bool> demanderMicro() async =>
    await _permission.invokeMethod<bool>('demander') ?? false;

static Stream<double> niveauSonore() =>
    _audio.receiveBroadcastStream().map(
      (v) => (v as num).toDouble(),
    );

}
