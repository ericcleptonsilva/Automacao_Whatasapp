package com.clept.whatsappautomation

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class WhatsAppAutomationPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    companion object {
        private val activeChannels = mutableListOf<MethodChannel>()
        
        // Shared state (mostly for toggle)
        var isAutomationEnabled: Boolean = true
        var isPendingSendClick: Boolean = false

        @JvmStatic
        fun notifyNotification(data: Map<String, Any?>) {
            val count = activeChannels.size
            Log.d("WhatsAppPlugin", "Broadcasting notification to $count channels")
            activeChannels.forEach { channel ->
                try {
                    channel.invokeMethod("onNotification", data)
                } catch (e: Exception) {
                    Log.e("WhatsAppPlugin", "Error invoking onNotification", e)
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.clept.whatsappautomation/channel")
        channel?.setMethodCallHandler(this)
        
        channel?.let { activeChannels.add(it) }
        Log.d("WhatsAppPlugin", "onAttachedToEngine: ${flutterPluginBinding.binaryMessenger}. Total channels: ${activeChannels.size}")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.let { activeChannels.remove(it) }
        channel?.setMethodCallHandler(null)
        context = null
        channel = null
        Log.d("WhatsAppPlugin", "onDetachedFromEngine. Remaining channels: ${activeChannels.size}")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val appContext = context ?: return result.error("NO_CONTEXT", "Context is null", null)
        
        when (call.method) {
            "isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled(appContext))
            "isNotificationListenerEnabled" -> result.success(isNotificationServiceEnabled(appContext))
            "openAccessibilitySettings" -> {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                appContext.startActivity(intent)
                result.success(true)
            }
            "openNotificationListenerSettings" -> {
                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                appContext.startActivity(intent)
                result.success(true)
            }
            "openAppSettings" -> {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = android.net.Uri.parse("package:${appContext.packageName}")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                appContext.startActivity(intent)
                result.success(true)
            }
            "isIgnoringBatteryOptimizations" -> {
                val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                result.success(powerManager.isIgnoringBatteryOptimizations(appContext.packageName))
            }
            "requestIgnoreBatteryOptimizations" -> {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = android.net.Uri.parse("package:${appContext.packageName}")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                appContext.startActivity(intent)
                result.success(true)
            }
            "sendFile" -> {
                val phone = call.argument<String>("phone")
                val filePath = call.argument<String>("filePath")
                val message = call.argument<String>("message")
                val isImage = call.argument<Boolean>("isImage") ?: true
                
                if (phone != null && filePath != null) {
                    val sanitizedPhone = phone.replace(Regex("[^0-9]"), "")
                    isPendingSendClick = true // Activate accessibility trigger
                    sendFileToWhatsApp(appContext, sanitizedPhone, filePath, message, isImage)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Phone or FilePath missing", null)
                }
            }
            "sendText" -> {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                
                if (phone != null && message != null) {
                    val sanitizedPhone = phone.replace(Regex("[^0-9]"), "")
                    isPendingSendClick = true // Activate accessibility trigger
                    sendTextToWhatsApp(appContext, sanitizedPhone, message)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Phone or Message missing", null)
                }
            }
            "replyToNotification" -> {
                val title = call.argument<String>("title")
                val message = call.argument<String>("message")
                val replyKey = call.argument<String>("replyKey") ?: title
                
                if (title != null && message != null) {
                    val success = replyToNotification(appContext, replyKey ?: title, message)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGS", "Title or Message missing", null)
                }
            }
            "toggleAutomation" -> {
                val enabled = call.argument<Boolean>("enabled") ?: !isAutomationEnabled
                isAutomationEnabled = enabled
                result.success(isAutomationEnabled)
            }
            "isAutomationEnabled" -> {
                result.success(isAutomationEnabled)
            }
            "showFloatingButton" -> {
                val intent = Intent(appContext, FloatingButtonService::class.java)
                appContext.startService(intent)
                result.success(true)
            }
            "hideFloatingButton" -> {
                val intent = Intent(appContext, FloatingButtonService::class.java)
                appContext.stopService(intent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun replyToNotification(context: Context, title: String, message: String): Boolean {
        Log.d("WhatsAppPlugin", "Attempting to reply to: $title")
        try {
            val action = WhatsAppNotificationListener.replyActions[title]
            if (action == null) {
                Log.e("WhatsAppPlugin", "Action NOT found for: $title. Available keys: ${WhatsAppNotificationListener.replyActions.keys}")
                return false
            }

            val remoteInputs = action.remoteInputs ?: run {
                Log.e("WhatsAppPlugin", "No remote inputs for action")
                return false
            }
            
            val intent = Intent()
            val bundle = Bundle()
            for (remoteInput in remoteInputs) {
                bundle.putCharSequence(remoteInput.resultKey, message)
            }
            
            android.app.RemoteInput.addResultsToIntent(remoteInputs, intent, bundle)
            action.actionIntent.send(context, 0, intent)
            Log.d("WhatsAppPlugin", "Reply intent sent successfully to $title")
            return true
        } catch (e: Exception) {
            Log.e("WhatsAppPlugin", "Error sending reply", e)
            return false
        }
    }

    private fun sendFileToWhatsApp(context: Context, phone: String, filePath: String, message: String?, isImage: Boolean) {
        try {
            val file = java.io.File(filePath)
            if (!file.exists()) {
                Log.e("WhatsAppPlugin", "File does not exist: $filePath")
                return
            }

            val uri = androidx.core.content.FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_SEND)
            val extension = android.webkit.MimeTypeMap.getFileExtensionFromUrl(filePath)
            val mimeType = if (extension != null) {
                android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
            } else {
                if (isImage) "image/*" else "*/*"
            } ?: (if (isImage) "image/*" else "*/*")

            intent.type = mimeType
            intent.putExtra(Intent.EXTRA_STREAM, uri)
            if (!message.isNullOrEmpty()) intent.putExtra(Intent.EXTRA_TEXT, message)
            
            // Try WhatsApp first, then Business if standard not found
            val packages = listOf("com.whatsapp", "com.whatsapp.w4b")
            var activityStarted = false
            
            for (pkg in packages) {
                try {
                    val specificIntent = Intent(intent)
                    specificIntent.setPackage(pkg)
                    specificIntent.putExtra("jid", "$phone@s.whatsapp.net")
                    specificIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    specificIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(specificIntent)
                    activityStarted = true
                    Log.d("WhatsAppPlugin", "Started activity for package: $pkg")
                    break
                } catch (e: Exception) {
                    Log.d("WhatsAppPlugin", "Could not start package $pkg: ${e.message}")
                }
            }

            if (!activityStarted) {
                // Final fallback: Let Android choose (Chooser)
                val chooser = Intent.createChooser(intent, "Enviar via...")
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(chooser)
            }
        } catch (e: Exception) {
            Log.e("WhatsAppPlugin", "Global error in sendFileToWhatsApp", e)
            e.printStackTrace()
        }
    }

    private fun sendTextToWhatsApp(context: Context, phone: String, message: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW)
            val url = "https://wa.me/$phone?text=${java.net.URLEncoder.encode(message, "UTF-8")}"
            intent.data = android.net.Uri.parse(url)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

            // Try to force package to ensure accessibility catches it
            val packages = listOf("com.whatsapp", "com.whatsapp.w4b")
            var activityStarted = false
            
            for (pkg in packages) {
                try {
                    val specificIntent = Intent(intent)
                    specificIntent.setPackage(pkg)
                    context.startActivity(specificIntent)
                    activityStarted = true
                    Log.d("WhatsAppPlugin", "Started text activity for package: $pkg")
                    break
                } catch (e: Exception) {
                    Log.d("WhatsAppPlugin", "Could not start text for package $pkg: ${e.message}")
                }
            }

            if (!activityStarted) {
                context.startActivity(intent)
            }
        } catch (e: Exception) {
            Log.e("WhatsAppPlugin", "Error in sendTextToWhatsApp", e)
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val prefString = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        return prefString?.contains(context.packageName + "/" + WhatsAppAccessibilityService::class.java.canonicalName) == true
    }

    private fun isNotificationServiceEnabled(context: Context): Boolean {
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val componentName = android.content.ComponentName.unflattenFromString(name)
                if (componentName != null && TextUtils.equals(context.packageName, componentName.packageName)) {
                    return true
                }
            }
        }
        return false
    }
}
