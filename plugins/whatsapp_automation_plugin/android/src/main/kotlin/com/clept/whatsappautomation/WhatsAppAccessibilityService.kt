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
            val maxAttempts = 30 // Até 15 segundos (~30x 500ms)
            var pickerSearchDone = false

            val checkRunnable = object : Runnable {
                override fun run() {
                    val root = rootInActiveWindow
                    if (root != null && WhatsAppAutomationPlugin.automationState > 0) {
                        Log.d(TAG, "Current UI State: ${WhatsAppAutomationPlugin.automationState}")
                        when (WhatsAppAutomationPlugin.automationState) {
                            5 -> {
                                // Aguarda o chat da wa.me abrir (campo de entrada visível)
                                val entryBox = findNodeById(root, "com.whatsapp:id/entry")
                                            ?: findNodeById(root, "com.whatsapp.w4b:id/entry")
                                if (entryBox != null) {
                                    Log.d(TAG, "Pre-Warm: chat open! Injecting ACTION_SEND with warm JID.")
                                    WhatsAppAutomationPlugin.automationState = 4
                                    attempts = 0

                                    val sendIntent = android.content.Intent(android.content.Intent.ACTION_SEND)
                                    sendIntent.type = WhatsAppAutomationPlugin.pendingMimeType
                                    sendIntent.putExtra(android.content.Intent.EXTRA_STREAM, WhatsAppAutomationPlugin.pendingUri)
                                    sendIntent.putExtra("jid", "${WhatsAppAutomationPlugin.pendingPhone}@s.whatsapp.net")
                                    if (!WhatsAppAutomationPlugin.pendingMessage.isNullOrEmpty()) {
                                        sendIntent.putExtra(android.content.Intent.EXTRA_TEXT, WhatsAppAutomationPlugin.pendingMessage)
                                    }
                                    sendIntent.addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    sendIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                                    sendIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                    val pkg = WhatsAppAutomationPlugin.pendingPackage
                                    if (pkg != null) sendIntent.setPackage(pkg)
                                    try {
                                        startActivity(sendIntent)
                                        Log.d(TAG, "Pre-Warm: ACTION_SEND injected for pkg=$pkg")
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Pre-Warm: Error injecting ACTION_SEND", e)
                                    }
                                }
                            }
                            4 -> {
                                // Tela final de envio (Media Preview)
                                if (findAndClickSendButton(root)) {
                                    WhatsAppAutomationPlugin.automationState = 0
                                    WhatsAppAutomationPlugin.isPendingSendClick = false
                                    Log.d(TAG, "Clicked Final Send Button in Preview")
                                } else {
                                    val btnSendDialog = findNodesByText(root, listOf("Send", "Enviar", "SEND", "ENVIAR", "Sim", "Yes"))
                                    var clickedDialog = false
                                    for (btn in btnSendDialog) {
                                        if (btn.className?.contains("Button") == true) {
                                            btn.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                                            WhatsAppAutomationPlugin.automationState = 0
                                            WhatsAppAutomationPlugin.isPendingSendClick = false
                                            Log.d(TAG, "Clicked Send in Alert Dialog")
                                            clickedDialog = true
                                            break
                                        }
                                    }
                                    // Se depois de 5 tentativas ainda não achou o botão enviar,
                                    // provavelmente estamos no Contact Picker → vai para State 6
                                    if (!clickedDialog && attempts >= 5 && !pickerSearchDone) {
                                        Log.d(TAG, "State 4: No Send button found after $attempts attempts. Switching to Contact Picker automation (State 6)")
                                        WhatsAppAutomationPlugin.automationState = 6
                                        attempts = 0
                                    }
                                }
                            }
                            6 -> {
                                // Automatiza o Contact Picker do WhatsApp
                                // Fase 1: Digitar o número no campo de busca
                                if (!pickerSearchDone) {
                                    val phone = WhatsAppAutomationPlugin.pendingPhone ?: ""
                                    // Procura campo de busca (EditText editável que não seja o campo de mensagem)
                                    val allEditTexts = mutableListOf<AccessibilityNodeInfo>()
                                    collectNodes(root, allEditTexts) { it.className?.contains("EditText") == true && it.isEditable }
                                    val searchField = allEditTexts.firstOrNull()
                                    if (searchField != null) {
                                        searchField.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                                        val args = Bundle()
                                        args.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, phone)
                                        searchField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
                                        pickerSearchDone = true
                                        Log.d(TAG, "State 6: Typed phone '$phone' in Contact Picker search field")
                                    } else {
                                        Log.d(TAG, "State 6: Search field not found yet (attempt $attempts)")
                                    }
                                } else {
                                    // Fase 2: Aguarda resultados e clica no primeiro contato encontrado
                                    val clickableRows = mutableListOf<AccessibilityNodeInfo>()
                                    collectNodes(root, clickableRows) {
                                        it.isClickable && 
                                        (it.className?.contains("RelativeLayout") == true || 
                                         it.className?.contains("LinearLayout") == true ||
                                         it.className?.contains("ConstraintLayout") == true ||
                                         it.className?.contains("FrameLayout") == true) &&
                                        it.childCount > 0
                                    }
                                    // Filtra para evitar clickar na barra de topo ou em botões de navegação
                                    val contactRow = clickableRows.firstOrNull { node ->
                                        val bounds = android.graphics.Rect()
                                        node.getBoundsInScreen(bounds)
                                        bounds.top > 200 && bounds.height() in 60..300
                                    }
                                    if (contactRow != null) {
                                        contactRow.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                                        Log.d(TAG, "State 6: Clicked contact row in picker. Switching back to State 4.")
                                        WhatsAppAutomationPlugin.automationState = 4
                                        pickerSearchDone = false
                                        attempts = 0
                                    } else {
                                        Log.d(TAG, "State 6: Waiting for contact list results (attempt $attempts)...")
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
            "com.whatsapp:id/fab",
            "com.whatsapp:id/media_send",
            "com.whatsapp.w4b:id/send",
            "com.whatsapp.w4b:id/send_container",
            "com.whatsapp.w4b:id/fab",
            "com.whatsapp.w4b:id/media_send"
        )
        for (id in ids) {
            val list = rootNode.findAccessibilityNodeInfosByViewId(id)
            if (list != null) {
                for (node in list) {
                    // Impede o falso positivo se o robô encostar na tela Home antes da Preview Screen
                    val desc = node.contentDescription?.toString()?.lowercase() ?: ""
                    if (id.endsWith("fab") && (desc.contains("nova") || desc.contains("new") || desc.contains("nuevo"))) {
                        continue
                    }
                    nodesToClick.add(node)
                }
            }
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

    private fun collectNodes(
        node: AccessibilityNodeInfo,
        out: MutableList<AccessibilityNodeInfo>,
        predicate: (AccessibilityNodeInfo) -> Boolean
    ) {
        if (predicate(node)) out.add(node)
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            collectNodes(child, out, predicate)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service Interrupted")
    }
}
