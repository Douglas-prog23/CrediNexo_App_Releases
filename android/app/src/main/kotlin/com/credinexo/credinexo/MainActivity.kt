package com.credinexo.credinexo

import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "credinexo/share"
    private val whatsappBusinessPackage = "com.whatsapp.w4b"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "sharePdfToWhatsAppBusiness" -> {
                    val path = call.argument<String>("path")
                    val message = call.argument<String>("message") ?: ""
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_FILE", "No se recibio el archivo del comprobante.", null)
                        return@setMethodCallHandler
                    }
                    sharePdfToWhatsAppBusiness(path, message, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sharePdfToWhatsAppBusiness(path: String, message: String, result: MethodChannel.Result) {
        if (!isPackageInstalled(whatsappBusinessPackage)) {
            result.error(
                "WHATSAPP_BUSINESS_NOT_INSTALLED",
                "WhatsApp Business no esta instalado en este dispositivo.",
                null
            )
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "No se encontro el comprobante para compartir.", null)
            return
        }

        val uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            setPackage(whatsappBusinessPackage)
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, message)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val activities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        if (activities.isEmpty()) {
            result.error(
                "WHATSAPP_BUSINESS_NOT_INSTALLED",
                "WhatsApp Business no esta instalado en este dispositivo.",
                null
            )
            return
        }

        startActivity(intent)
        result.success(null)
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}
