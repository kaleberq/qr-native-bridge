package com.example.qr_native_bridge

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import java.io.ByteArrayOutputStream

private const val CAMERA_REQUEST_CODE = 3981

/** QrNativeBridgePlugin */
class QrNativeBridgePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingScanResult: Result? = null
    private var scannerLauncher: androidx.activity.result.ActivityResultLauncher<Intent>? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "qr_native_bridge")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "generateQr" -> {
                val args = call.arguments as? Map<*, *>
                val data = args?.get("data") as? String
                if (data == null) {
                    result.error("INVALID_ARGS", "Missing data", null)
                    return
                }
                generateQrPng(data, result)
            }
            "scanQr" -> {
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity not available", null)
                    return
                }
                val act = activity!!
                when (ContextCompat.checkSelfPermission(act, android.Manifest.permission.CAMERA)) {
                    PackageManager.PERMISSION_DENIED -> {
                        ActivityCompat.requestPermissions(
                            act,
                            arrayOf(android.Manifest.permission.CAMERA),
                            CAMERA_REQUEST_CODE
                        )
                        pendingScanResult = result
                    }
                    PackageManager.PERMISSION_GRANTED -> {
                        launchScanner(result)
                    }
                    else -> {
                        result.error(
                            "PERMISSION_DENIED",
                            "Permissão de câmera negada",
                            null
                        )
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun launchScanner(result: Result) {
        val launcher = scannerLauncher
        if (launcher == null) {
            result.error("NO_ACTIVITY", "Scanner not ready", null)
            return
        }
        pendingScanResult = result
        val intent = Intent(activity, QrScannerActivity::class.java)
        launcher.launch(intent)
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode != CAMERA_REQUEST_CODE) return
        val pending = pendingScanResult ?: return
        pendingScanResult = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            launchScanner(pending)
        } else {
            pending.error("PERMISSION_DENIED", "Permissão de câmera negada", null)
        }
    }

    private fun generateQrPng(data: String, result: Result) {
        try {
            val hints = mapOf<EncodeHintType, Any>(
                EncodeHintType.CHARACTER_SET to "UTF-8",
                EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.Q
            )
            val writer = QRCodeWriter()
            val bitMatrix = writer.encode(data, BarcodeFormat.QR_CODE, 256, 256, hints)
            val width = bitMatrix.width
            val height = bitMatrix.height
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
            for (x in 0 until width) {
                for (y in 0 until height) {
                    bitmap.setPixel(x, y, if (bitMatrix[x, y]) 0xFF000000.toInt() else 0xFFFFFFFF.toInt())
                }
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            result.success(stream.toByteArray())
        } catch (e: Exception) {
            Log.e("QrNativeBridge", "QR generation failed", e)
            result.error("QR_FAILED", "Could not generate QR", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (activity is androidx.activity.ComponentActivity) {
            val componentActivity = activity as androidx.activity.ComponentActivity
            scannerLauncher = componentActivity.activityResultRegistry.register(
                "qr_scanner",
                componentActivity,
                androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult()
            ) { activityResult ->
                val pending = pendingScanResult ?: return@register
                pendingScanResult = null
                if (activityResult.resultCode == Activity.RESULT_OK) {
                    val value = activityResult.data?.getStringExtra(EXTRA_QR_RESULT)
                    if (value != null) {
                        pending.success(value)
                    } else {
                        pending.error("USER_CANCELLED", "Usuário cancelou o escaneamento", null)
                    }
                } else {
                    pending.error("USER_CANCELLED", "Usuário cancelou o escaneamento", null)
                }
            }
        }
        binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
            if (requestCode == CAMERA_REQUEST_CODE) {
                onRequestPermissionsResult(requestCode, permissions, grantResults)
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        scannerLauncher = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        scannerLauncher = null
        activity = null
    }
}
