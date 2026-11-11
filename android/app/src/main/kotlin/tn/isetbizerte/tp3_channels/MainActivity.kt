
package tn.isetbizerte.tp3_channels

import android.os.Build
import android.content.Context
import android.os.Vibrator
import android.os.VibratorManager
import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel

class MainActivity : FlutterActivity() {

    private val scope = MainScope()
    private var resultatPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messager = flutterEngine.dartExecutor.binaryMessenger

        // 1. Informations de l'appareil
        MethodChannel(messager, "appareil/infos")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lire" -> result.success(
                        mapOf(
                            "marque" to Build.MANUFACTURER,
                            "modele" to Build.MODEL,
                            "version" to Build.VERSION.RELEASE,
                            "sdk" to Build.VERSION.SDK_INT
                        )
                    )
                    else -> result.notImplemented()
                }
            }

        // 2. Vibration
        MethodChannel(messager, "appareil/vibrer")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrer" -> {
                        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
                            val manager = getSystemService(
                                Context.VIBRATOR_MANAGER_SERVICE
                            ) as VibratorManager
                            manager.defaultVibrator
                        } else {
                            @Suppress("DEPRECATION")
                            getSystemService(
                                Context.VIBRATOR_SERVICE
                            ) as Vibrator
                        }

                        vibrator.vibrate(300)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 3. Capteur de lumière
        EventChannel(messager, "capteur/lumiere")
            .setStreamHandler(CapteurLumiere(this))

        // 4. Permission du microphone
        MethodChannel(messager, "audio/permission")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "demander" -> {
                        if (checkSelfPermission(
                                Manifest.permission.RECORD_AUDIO
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(true)
                        } else {
                            resultatPermission = result
                            requestPermissions(
                                arrayOf(Manifest.permission.RECORD_AUDIO),
                                REQ_MICRO
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 5. Niveau sonore
        EventChannel(messager, "audio/niveau")
            .setStreamHandler(NiveauSonore(scope))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        if (requestCode == REQ_MICRO) {
            resultatPermission?.success(
                grantResults.firstOrNull() ==
                        PackageManager.PERMISSION_GRANTED
            )
            resultatPermission = null
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val REQ_MICRO = 42
    }
}
