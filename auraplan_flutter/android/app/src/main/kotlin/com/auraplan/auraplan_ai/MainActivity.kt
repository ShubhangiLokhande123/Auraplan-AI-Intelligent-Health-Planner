package com.auraplan.auraplan_ai

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var signInHelper: GoogleSignInHelper
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        signInHelper = GoogleSignInHelper(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.auraplan/auth")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "GoogleSignIn" -> {
                        pendingResult = result
                        signInHelper.onSuccess = { uid, displayName, email, photoUrl ->
                            pendingResult?.success(mapOf(
                                "uid" to uid,
                                "displayName" to displayName,
                                "email" to email,
                                "photoUrl" to photoUrl
                            ))
                            pendingResult = null
                        }
                        signInHelper.onError = { code, message ->
                            pendingResult?.error(code, message, null)
                            pendingResult = null
                        }
                        signInHelper.startSignIn()
                    }
                    "SignOut" -> {
                        signInHelper.signOut { result.success(null) }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::signInHelper.isInitialized) {
            signInHelper.handleActivityResult(requestCode, resultCode, data)
        }
    }
}
