
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native/canaux.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: PageCanaux(),
));

class PageCanaux extends StatefulWidget {
  const PageCanaux({super.key});

  @override
  State<PageCanaux> createState() => _PageCanauxState();
}

class _PageCanauxState extends State<PageCanaux> {

  String _infos = 'Appuyez sur le bouton';

  double? _lux;
  StreamSubscription<double>? _abonnementLumiere;

  double? _db;
  StreamSubscription<double>? _abonnementAudio;

  void _basculerLumiere() {
    if (_abonnementLumiere == null) {
      _abonnementLumiere = CanauxNatifs.lumiere().listen(
        (lux) => setState(() => _lux = lux),
        onError: (e) => _message(
          'Capteur : ${(e as PlatformException).message}',
        ),
      );
    } else {
      _abonnementLumiere!.cancel();
      _abonnementLumiere = null;
    }
    setState(() {});
  }

  Future<void> _basculerMicro() async {
    if (_abonnementAudio != null) {
      await _abonnementAudio!.cancel();
      setState(() => _abonnementAudio = null);
      return;
    }

    final accordee = await CanauxNatifs.demanderMicro();

    if (!accordee) {
      _message('Permission micro refusée');
      return;
    }

    setState(() {
      _abonnementAudio = CanauxNatifs.niveauSonore().listen(
        (db) => setState(() => _db = db),
        onError: (e) => _message(
          'Micro : ${(e as PlatformException).message}',
        ),
      );
    });
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  Future<void> _lireInfos() async {
    final i = await CanauxNatifs.lireInfos();

    setState(() {
      _infos =
          '${i['marque']} ${i['modele']}\n'
          'Android ${i['version']} (API ${i['sdk']})';
    });
  }

  Widget _carte(String titre, List<Widget> contenu) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...contenu,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TP 3 – Platform Channels'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // 1. Infos appareil
          _carte('1. Infos appareil (MethodChannel)', [
            Text(_infos),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _lireInfos,
              child: const Text('Lire'),
            ),
          ]),

          // 2. Vibration
          _carte('2. Vibration (MethodChannel)', [
            FilledButton(
              onPressed: () async {
                final ok = await CanauxNatifs.vibrer();

                if (ok) {
                  _message('Vibration envoyée !');
                } else {
                  _message('La vibration a échoué.');
                }
              },
              child: const Text('Vibrer'),
            ),
          ]),

          // 3. Capteur de lumière
          _carte('3. Capteur de lumière (EventChannel)', [
            Text(
              _lux == null ? '—' : '${_lux!.toStringAsFixed(0)} lux',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerLumiere,
              child: Text(
                _abonnementLumiere == null ? 'Démarrer' : 'Arrêter',
              ),
            ),
          ]),

          // 4. Niveau sonore
          _carte('4. Niveau sonore (permission + coroutine)', [
            Text(
              _db == null ? '—' : '${_db!.toStringAsFixed(1)} dBFS',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (((_db ?? -90) + 90) / 90).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerMicro,
              child: Text(
                _abonnementAudio == null ? 'Écouter' : 'Arrêter',
              ),
            ),
          ]),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _abonnementLumiere?.cancel();
    _abonnementAudio?.cancel();
    super.dispose();
  }
}
