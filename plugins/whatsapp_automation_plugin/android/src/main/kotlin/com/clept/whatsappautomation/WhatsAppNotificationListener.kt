package com.clept.whatsappautomation

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification
import android.util.Log
import android.content.Intent

class WhatsAppNotificationListener : NotificationListenerService() {

    private val TAG = "WhatsAppNotification"
    
    companion object {
        val replyActions = HashMap<String, Notification.Action>()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        
        if (sbn == null) return
        
        val packageName = sbn.packageName
        if (packageName == "com.whatsapp" || packageName == "com.whatsapp.w4b") {
            val extras = sbn.notification.extras
            val title = extras.getString(Notification.EXTRA_TITLE)
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            
            if (title != null && text != null) {
                val lowerText = text.lowercase()
                val isSummary = lowerText.contains("new messages") || 
                                lowerText.contains("novas mensagens") || 
                                lowerText.matches(Regex("^\\d+\\s+mensagens?\$")) ||
                                lowerText.matches(Regex("^\\d+\\s+messages?\$"))

                if (!isSummary) {
                    Log.d(TAG, "Notification received from: $title | Message: $text")
                    
                    val action = findReplyAction(sbn.notification)
                    if (action != null) {
                        replyActions[title] = action
                        
                        // Notify Plugin Directly (All engines)
                        val extraTag = sbn.tag ?: ""

                        val data = mapOf(
                            "title" to title,
                            "message" to text,
                            "package" to packageName,
                            "replyKey" to title,
                            "tag" to extraTag
                        )
                        WhatsAppAutomationPlugin.notifyNotification(data)
                    }
                }
            }
        }
    }

    private fun findReplyAction(notification: Notification): Notification.Action? {
        val actions = notification.actions ?: return null
        for (action in actions) {
            val remoteInputs = action.remoteInputs ?: continue
            for (remoteInput in remoteInputs) {
                if (remoteInput.resultKey.contains("text", true) || 
                    remoteInput.label.toString().contains("Reply", true) || 
                    remoteInput.label.toString().contains("Responder", true)) {
                    return action
                }
            }
        }
        return null
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
