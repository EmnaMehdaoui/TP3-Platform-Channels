
package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel

class CapteurLumiere(context: Context) :
    EventChannel.StreamHandler, SensorEventListener {

    private val sensorManager =
        context.getSystemService(SensorManager::class.java)

    private val capteur: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)

    private var sink: EventChannel.EventSink? = null

    // Flutter commence à écouter
    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink
    ) {
        if (capteur == null) {
            events.error(
                "PAS_DE_CAPTEUR",
                "Ce téléphone n'a pas de capteur de lumière",
                null
            )
            return
        }

        sink = events

        android.util.Log.d("TP3", "onListen")

        sensorManager.registerListener(
            this,
            capteur,
            SensorManager.SENSOR_DELAY_NORMAL
        )
    }

    // Flutter arrête d'écouter
    override fun onCancel(arguments: Any?) {
        android.util.Log.d("TP3", "onCancel")

        sensorManager.unregisterListener(this)
        sink = null
    }

    // Nouvelle mesure
    override fun onSensorChanged(event: SensorEvent) {
        sink?.success(event.values[0].toDouble())
    }

    override fun onAccuracyChanged(
        sensor: Sensor?,
        accuracy: Int
    ) {}
}
