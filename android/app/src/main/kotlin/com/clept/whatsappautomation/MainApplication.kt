package com.clept.whatsappautomation

import android.app.Application
import android.util.Log

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d("MainApplication", "Application onCreate")
    }
}
