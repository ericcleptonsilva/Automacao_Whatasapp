package com.clept.whatsappautomation

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.graphics.drawable.GradientDrawable
import android.graphics.Color
import android.util.Log

class FloatingButtonService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: FrameLayout? = null
    private var params: WindowManager.LayoutParams? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        // Create the view
        floatingView = FrameLayout(this)
        val button = ImageView(this)
        
        // Setup Button appearance
        updateButtonStyle(button, WhatsAppAutomationPlugin.isAutomationEnabled)
        
        val layoutParams = FrameLayout.LayoutParams(60.toPx(), 60.toPx())
        button.layoutParams = layoutParams
        button.elevation = 8f.toPx()
        
        floatingView?.addView(button)

        // Window Manager Params
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        params?.gravity = Gravity.TOP or Gravity.START
        params?.x = 100
        params?.y = 300

        windowManager?.addView(floatingView, params)

        // Dragging & Clicking Logic
        button.setOnTouchListener(object : View.OnTouchListener {
            private var lastX: Int = 0
            private var lastY: Int = 0
            private var initialX: Int = 0
            private var initialY: Int = 0
            private var startTime: Long = 0

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params!!.x
                        initialY = params!!.y
                        lastX = event.rawX.toInt()
                        lastY = event.rawY.toInt()
                        startTime = System.currentTimeMillis()
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX.toInt() - lastX
                        val dy = event.rawY.toInt() - lastY
                        params!!.x = initialX + dx
                        params!!.y = initialY + dy
                        windowManager?.updateViewLayout(floatingView, params)
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        val duration = System.currentTimeMillis() - startTime
                        val dx = Math.abs(event.rawX.toInt() - lastX)
                        val dy = Math.abs(event.rawY.toInt() - lastY)
                        
                        // Permite clique se duração for curta e não tiver arrastado muito (50 px)
                        if (duration < 250 && dx < 50 && dy < 50) {
                            WhatsAppAutomationPlugin.isAutomationEnabled = !WhatsAppAutomationPlugin.isAutomationEnabled
                            updateButtonStyle(button, WhatsAppAutomationPlugin.isAutomationEnabled)
                            Log.d("FloatingButton", "Automation Toggled: ${WhatsAppAutomationPlugin.isAutomationEnabled}")
                            v.performClick()
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun updateButtonStyle(view: ImageView, enabled: Boolean) {
        val shape = GradientDrawable()
        shape.shape = GradientDrawable.OVAL
        shape.setColor(if (enabled) Color.parseColor("#4CAF50") else Color.parseColor("#F44336")) // Green / Red
        shape.setStroke(2.toPx().toInt(), Color.WHITE)
        view.background = shape
        
        // We could add an icon here if we had one in resources, but let's use a simple colored circle for now
        // or a simple drawable if available.
        // For now, the color change is the primary indicator.
    }

    override fun onDestroy() {
        super.onDestroy()
        if (floatingView != null) windowManager?.removeView(floatingView)
    }

    // Helper functions
    private fun Int.toPx(): Int = (this * resources.displayMetrics.density).toInt()
    private fun Float.toPx(): Float = (this * resources.displayMetrics.density)
}
