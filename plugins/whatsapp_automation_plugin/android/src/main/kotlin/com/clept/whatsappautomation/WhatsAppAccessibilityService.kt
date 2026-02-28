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
            val clicked = findAndClickSendButton(rootNode)
            if (clicked) {
                WhatsAppAutomationPlugin.isPendingSendClick = false
            }
        }
    }

    private fun findAndClickSendButton(rootNode: AccessibilityNodeInfo): Boolean {
        val nodesToClick = ArrayList<AccessibilityNodeInfo>()

        // 1. By ID
        val ids = listOf("com.whatsapp:id/send", "com.whatsapp:id/send_container", "com.whatsapp:id/fab")
        for (id in ids) {
            val list = rootNode.findAccessibilityNodeInfosByViewId(id)
            if (list != null) nodesToClick.addAll(list)
        }

        // 2. By Text
        nodesToClick.addAll(rootNode.findAccessibilityNodeInfosByText("Enviar"))
        nodesToClick.addAll(rootNode.findAccessibilityNodeInfosByText("Send"))

        // 3. By Content Description (Critical for Icon Buttons)
        findNodesByContentDescription(rootNode, listOf("Enviar", "Send"), nodesToClick)

        for (node in nodesToClick) {
            if (node.isClickable && node.isEnabled) {
                Log.d(TAG, "Clicking Node: $node")
                val clicked = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                if (clicked) return true // Click successful
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
