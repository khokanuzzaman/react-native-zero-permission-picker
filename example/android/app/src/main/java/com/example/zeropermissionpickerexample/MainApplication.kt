package com.example.zeropermissionpickerexample

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost

class MainApplication : Application(), ReactApplication {

  override val reactHost: ReactHost by lazy {
    getDefaultReactHost(
        context = applicationContext,
        packageList =
            PackageList(this).packages.apply {
              // Add manually linked packages here if needed
            },
    )
  }

  override fun onCreate() {
    super.onCreate()
    loadReactNative(this)
  }
}
