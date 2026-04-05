package com.auraplan.auraplan_ai

import android.app.Activity
import android.content.Intent
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase

class GoogleSignInHelper(private val activity: Activity) {

    companion object {
        const val RC_SIGN_IN = 9001
        // Web client ID (type 3) from google-services.json
        private const val WEB_CLIENT_ID =
            "383700501573-dpqoc3mkgh9qipm3dmm08dbbnltaodlv.apps.googleusercontent.com"
    }

    private val auth: FirebaseAuth = Firebase.auth

    private val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        .requestIdToken(WEB_CLIENT_ID)
        .requestEmail()
        .requestProfile()
        .build()

    private val googleSignInClient: GoogleSignInClient =
        GoogleSignIn.getClient(activity, gso)

    var onSuccess: ((uid: String, displayName: String, email: String, photoUrl: String) -> Unit)? = null
    var onError: ((code: String, message: String) -> Unit)? = null

    fun startSignIn() {
        // Sign out first to always show the account picker
        googleSignInClient.signOut().addOnCompleteListener {
            val signInIntent = googleSignInClient.signInIntent
            activity.startActivityForResult(signInIntent, RC_SIGN_IN)
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != RC_SIGN_IN) return
        val task = GoogleSignIn.getSignedInAccountFromIntent(data)
        try {
            val account: GoogleSignInAccount = task.getResult(ApiException::class.java)
            firebaseAuthWithGoogle(account)
        } catch (e: ApiException) {
            onError?.invoke("SIGN_IN_CANCELLED", e.statusCode.toString() + ": " + e.message)
        }
    }

    private fun firebaseAuthWithGoogle(account: GoogleSignInAccount) {
        val credential = GoogleAuthProvider.getCredential(account.idToken, null)
        auth.signInWithCredential(credential)
            .addOnSuccessListener { result ->
                val user = result.user ?: run {
                    onError?.invoke("NO_USER", "Firebase returned no user")
                    return@addOnSuccessListener
                }
                AnalyticsHelper.setUserId(user.uid)
                AnalyticsHelper.logSuccessfulLogin()
                onSuccess?.invoke(
                    user.uid,
                    user.displayName ?: "",
                    user.email ?: "",
                    user.photoUrl?.toString() ?: ""
                )
            }
            .addOnFailureListener { e ->
                onError?.invoke("FIREBASE_AUTH_FAILED", e.message ?: "Unknown error")
            }
    }

    fun signOut(onComplete: () -> Unit) {
        auth.signOut()
        googleSignInClient.signOut().addOnCompleteListener { onComplete() }
    }
}
