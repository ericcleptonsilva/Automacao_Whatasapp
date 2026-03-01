package com.clept.whatsappautomation

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Bundle
import android.util.Log

class WhatsAppAccessibilityService : AccessibilityService() {

    private val TAG = "WhatsAppAccessibility"

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Check if event is from WhatsApp
        if (event.packageName?.toString()?.contains("com.whatsapp") == true) {
            // Check if automation is globally enabled
            if (!WhatsAppAutomationPlugin.isAutomationEnabled) {
                return
            }
            
            // SECURITY LOCK: Only click if the App explicitly requested an automated type action
            if (!WhatsAppAutomationPlugin.isPendingSendClick) {
                return
            }

            val rootNode = rootInActiveWindow ?: return
            
            // Just find and click send button if needed (legacy fallback)
            val handler = android.os.Handler(android.os.Looper.getMainLooper())
            var attempts = 0
            val maxAttempts = 20 // Retenta até 10 segundos (~20x 500ms)

            val checkRunnable = object : Runnable {
                override fun run() {
                    val root = rootInActiveWindow
                    if (root != null && WhatsAppAutomationPlugin.automationState > 0) {
                        Log.d(TAG, "Current UI State: ${WhatsAppAutomationPlugin.automationState}")
                        when (WhatsAppAutomationPlugin.automationState) {
                            4 -> {
                                // Tela final de envio (Media Preview ou Dialogo de Confirmação de PDF)
                                if (findAndClickSendButton(root)) {
                                    WhatsAppAutomationPlugin.automationState = 0
                                    WhatsAppAutomationPlugin.isPendingSendClick = false
                                    Log.d(TAG, "Clicked Final Send Button in Preview")
                                } else {
                                    val btnSendDialog = findNodesByText(root, listOf("Send", "Enviar", "SEND", "ENVIAR", "Sim", "Yes"))
                                    for (btn in btnSendDialog) {
                                        if (btn.className?.contains("Button") == true) {
                                            btn.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                                            WhatsAppAutomationPlugin.automationState = 0
                                            WhatsAppAutomationPlugin.isPendingSendClick = false
                                            Log.d(TAG, "Clicked Send in Alert Dialog")
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    } else if (root != null && WhatsAppAutomationPlugin.isPendingSendClick) {
                        // Fallback Text Only handling
                        if (findAndClickSendButton(root)) {
                            WhatsAppAutomationPlugin.isPendingSendClick = false
                            Log.d(TAG, "Successfully clicked Send button after $attempts attempts.")
                            return
                        }
                    }
                    
                    if (attempts < maxAttempts && (WhatsAppAutomationPlugin.automationState > 0 || WhatsAppAutomationPlugin.isPendingSendClick)) {
                        attempts++
                        handler.postDelayed(this, 500) // retry every 500ms
                    } else if (attempts >= maxAttempts) {
                        Log.d(TAG, "Failed to complete Acessibility Automation after $maxAttempts attempts.")
                        WhatsAppAutomationPlugin.automationState = 0
                        WhatsAppAutomationPlugin.isPendingSendClick = false
                    }
                }
            }
            handler.post(checkRunnable)
            
        }
    }
    
    private fun findNodeById(root: AccessibilityNodeInfo, id: String): AccessibilityNodeInfo? {
        val list = root.findAccessibilityNodeInfosByViewId(id)
        return if (list.isNotEmpty()) list[0] else null
    }

    private fun findNodesByText(root: AccessibilityNodeInfo, texts: List<String>): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        for (text in texts) {
            results.addAll(root.findAccessibilityNodeInfosByText(text))
        }
        return results
    }

    private fun findAndClickSendButton(rootNode: AccessibilityNodeInfo): Boolean {
        val nodesToClick = ArrayList<AccessibilityNodeInfo>()


        // 1. By ID (Mais modernos)
        val ids = listOf(
            "com.whatsapp:id/send", 
            "com.whatsapp:id/send_container", 
            "com.whatsapp:id/media_send",
            "com.whatsapp.w4b:id/send",
            "com.whatsapp.w4b:id/send_container",
            "com.whatsapp.w4b:id/media_send"
        )
        for (id in ids) {
            val list = rootNode.findAccessibilityNodeInfosByViewId(id)
            if (list != null) nodesToClick.addAll(list)
        }

        // 2. By Text (Diversos idiomas)
        val texts = listOf("Enviar", "Send", "Envia", "Envoyer", "Inviare")
        for (t in texts) {
            nodesToClick.addAll(rootNode.findAccessibilityNodeInfosByText(t))
        }

        // 3. By Content Description (Critical for Icon Buttons)
        findNodesByContentDescription(rootNode, texts, nodesToClick)

        for (node in nodesToClick) {
            if (node.isClickable && node.isEnabled) {
                Log.d(TAG, "Clicking Node: $node")
                val clicked = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                if (clicked) return true // Click successful
            } else if (node.parent != null && node.parent.isClickable) {
                Log.d(TAG, "Clicking Parent Node: ${node.parent}")
                val clicked = node.parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                if (clicked) return true
            }
        }
        return false
    }

    private fun findNodesByContentDescription(
        node: AccessibilityNodeInfo, 
        descriptions: List<String>, 
        outList: MutableList<AccessibilityNodeInfo>
    ) {
        if (node.contentDescription != null) {
            for (desc in descriptions) {
                if (node.contentDescription.toString().equals(desc, ignoreCase = true)) {
                    outList.add(node)
                }
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                findNodesByContentDescription(child, descriptions, outList)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service Interrupted")
    }
}
