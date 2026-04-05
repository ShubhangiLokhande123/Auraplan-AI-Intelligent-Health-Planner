package com.auraplan.auraplan_ai

import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.ktx.Firebase

/**
 * Centralised Firebase Analytics helper.
 *
 * Covers the four background metrics requested:
 *   WHO       — setUserId()         : persists the Firebase UID as a User Property
 *   WHERE     — enabled by default  : geography is derived from IP; collection is
 *               explicitly confirmed on (see AuraPlanApplication)
 *   HOW MANY  — logSuccessfulLogin(): fires the standard LOGIN event
 *   HOW LONG  — logSessionEnd()     : called by SessionLifecycleObserver
 */
object AnalyticsHelper {

    private val analytics: FirebaseAnalytics by lazy { Firebase.analytics }

    // ── WHO ──────────────────────────────────────────────────────────────────
    /**
     * Records the authenticated user's Firebase UID so every subsequent event
     * is attributed to that user in the Analytics dashboard.
     */
    fun setUserId(uid: String) {
        analytics.setUserId(uid)
        // Also store as a User Property for audience segmentation
        analytics.setUserProperty("firebase_uid", uid)
    }

    // ── HOW MANY ─────────────────────────────────────────────────────────────
    /**
     * Logs a standard LOGIN event with the sign-in method as a parameter.
     * This increments the 'successful_login' count in Analytics.
     *
     * @param method Human-readable sign-in method label (default: "google_one_tap").
     */
    fun logSuccessfulLogin(method: String = "google_one_tap") {
        val params = Bundle().apply {
            putString(FirebaseAnalytics.Param.METHOD, method)
        }
        analytics.logEvent(FirebaseAnalytics.Event.LOGIN, params)
        // Also fire a named event so it appears as 'successful_login' in reports
        analytics.logEvent("successful_login", params)
    }

    // ── HOW LONG ─────────────────────────────────────────────────────────────
    /**
     * Logs a 'session_end' event with the foreground session length.
     * Called automatically by [SessionLifecycleObserver.onStop].
     *
     * @param durationSeconds Seconds the app was in the foreground.
     */
    fun logSessionEnd(durationSeconds: Long) {
        analytics.logEvent("session_end", Bundle().apply {
            putLong("duration_seconds", durationSeconds)
        })
    }
}
