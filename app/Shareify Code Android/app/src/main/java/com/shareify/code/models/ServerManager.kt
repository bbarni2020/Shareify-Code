package com.shareify.code.models

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.TimeUnit

class ServerManager private constructor(private val context: Context) {
    private var cryptoManager: CryptoManager? = null
    private var sessionEstablished = false
    private val prefs: SharedPreferences = context.getSharedPreferences("server_prefs", Context.MODE_PRIVATE)
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    init {
        val clientId = prefs.getString("client_id", null) ?: UUID.randomUUID().toString()
        prefs.edit().putString("client_id", clientId).apply()
        cryptoManager = CryptoManager(clientId)
    }

    suspend fun establishEncryptedSession(): Boolean = withContext(Dispatchers.IO) {
        val publicKeyPEM = cryptoManager?.getPublicKeyPEM() ?: return@withContext false
        val jwtToken = prefs.getString("jwt_token", null) ?: return@withContext false

        try {
            val clientId = prefs.getString("client_id", "") ?: ""
            val requestBody = JSONObject().apply {
                put("client_id", clientId)
                put("public_key", publicKeyPEM)
            }

            val request = Request.Builder()
                .url("https://bridge.bbarni.hackclub.app/cloud/establish_session")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .addHeader("Authorization", "Bearer $jwtToken")
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            if (response.isSuccessful && responseBody != null) {
                val json = JSONObject(responseBody)
                val encryptedKey = json.getString("encrypted_session_key")
                
                sessionEstablished = cryptoManager?.decryptSessionKey(encryptedKey) ?: false
                sessionEstablished
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    suspend fun executeServerCommand(
        command: String,
        method: String = "GET",
        body: Map<String, Any> = emptyMap(),
        waitTime: Int = 2,
        useEncryption: Boolean = true
    ): Result<Any> = withContext(Dispatchers.IO) {
        if (useEncryption && !sessionEstablished) {
            val established = establishEncryptedSession()
            if (!established) {
                return@withContext executeServerCommand(command, method, body, waitTime, false)
            }
        }

        val jwtToken = prefs.getString("jwt_token", null)
        if (jwtToken.isNullOrEmpty()) {
            return@withContext Result.failure(ServerError.NoJWTToken)
        }

        try {
            var requestBody = JSONObject().apply {
                put("command", command)
                put("method", method)
                put("wait_time", waitTime)
                if (body.isNotEmpty()) {
                    put("body", JSONObject(body))
                }
            }

            val clientId = prefs.getString("client_id", "") ?: ""
            
            if (useEncryption) {
                val encryptedPayload = cryptoManager?.encryptRequest(requestBody.toString())
                if (encryptedPayload != null) {
                    requestBody = JSONObject().apply {
                        put("encrypted", true)
                        put("client_id", clientId)
                        put("encrypted_payload", encryptedPayload)
                    }
                }
            }

            val requestBuilder = Request.Builder()
                .url("https://command.bbarni.hackclub.app/")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .addHeader("Authorization", "Bearer $jwtToken")

            val shareifyJWT = prefs.getString("shareify_jwt", null)
            if (!shareifyJWT.isNullOrEmpty()) {
                requestBuilder.addHeader("X-Shareify-JWT", shareifyJWT)
            }

            val response = client.newCall(requestBuilder.build()).execute()
            val responseBody = response.body?.string()

            if (response.code == 401) {
                return@withContext refreshJWTAndRetry(command, method, body, waitTime, useEncryption)
            }

            if (response.isSuccessful && responseBody != null) {
                try {
                    val json = JSONObject(responseBody)
                    
                    if (useEncryption && json.optBoolean("encrypted", false)) {
                        val encryptedResponse = json.getJSONObject("encrypted_response")
                        val decrypted = cryptoManager?.decryptResponse(encryptedResponse)
                        if (decrypted != null) {
                            return@withContext Result.success(decrypted)
                        }
                    }
                    
                    Result.success(json.toMap())
                } catch (e: Exception) {
                    try {
                        val jsonArray = JSONArray(responseBody)
                        Result.success(jsonArray.toList())
                    } catch (e2: Exception) {
                        Result.failure(ServerError.InvalidResponse)
                    }
                }
            } else {
                Result.failure(ServerError.ServerError(responseBody ?: "Unknown error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun refreshJWTAndRetry(
        command: String,
        method: String,
        body: Map<String, Any>,
        waitTime: Int,
        useEncryption: Boolean
    ): Result<Any> = withContext(Dispatchers.IO) {
        val email = prefs.getString("user_email", null)
        val password = prefs.getString("user_password", null)

        if (email.isNullOrEmpty() || password.isNullOrEmpty()) {
            return@withContext Result.failure(ServerError.NoCredentials)
        }

        try {
            val requestBody = JSONObject().apply {
                put("email", email)
                put("password", password)
            }

            val request = Request.Builder()
                .url("https://bridge.bbarni.hackclub.app/login")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            if (response.isSuccessful && responseBody != null) {
                val json = JSONObject(responseBody)
                val newJwtToken = json.getString("jwt_token")
                prefs.edit().putString("jwt_token", newJwtToken).apply()
                
                sessionEstablished = false
                
                executeServerCommand(command, method, body, waitTime, useEncryption)
            } else {
                Result.failure(ServerError.AuthFailed)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun loginToServer(username: String, password: String): Result<Map<String, Any>> = 
        withContext(Dispatchers.IO) {
            val jwtToken = prefs.getString("jwt_token", null)
            if (jwtToken.isNullOrEmpty()) {
                return@withContext Result.failure(ServerError.NoJWTToken)
            }

            try {
                val requestBody = JSONObject().apply {
                    put("command", "/user/login")
                    put("method", "POST")
                    put("wait_time", 5)
                    put("body", JSONObject().apply {
                        put("username", username)
                        put("password", password)
                    })
                }

                val request = Request.Builder()
                    .url("https://command.bbarni.hackclub.app/")
                    .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                    .addHeader("Authorization", "Bearer $jwtToken")
                    .build()

                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()

                if (response.isSuccessful && responseBody != null) {
                    val json = JSONObject(responseBody)
                    val token = json.optString("token")
                    if (token.isNotEmpty()) {
                        prefs.edit()
                            .putString("shareify_jwt", token)
                            .putString("server_username", username)
                            .putString("server_password", password)
                            .apply()
                    }
                    Result.success(json.toMap())
                } else {
                    Result.failure(ServerError.ServerError(responseBody ?: "Login failed"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    suspend fun bridgeLogin(email: String, password: String): Result<Map<String, Any>> = 
        withContext(Dispatchers.IO) {
            try {
                val requestBody = JSONObject().apply {
                    put("email", email)
                    put("password", password)
                }

                val request = Request.Builder()
                    .url("https://bridge.bbarni.hackclub.app/login")
                    .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()

                if (response.isSuccessful && responseBody != null) {
                    val json = JSONObject(responseBody)
                    val jwtToken = json.getString("jwt_token")
                    prefs.edit()
                        .putString("jwt_token", jwtToken)
                        .putString("user_email", email)
                        .putString("user_password", password)
                        .apply()
                    Result.success(json.toMap())
                } else {
                    Result.failure(ServerError.ServerError(responseBody ?: "Bridge login failed"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    fun isServerLoggedIn(): Boolean {
        return !prefs.getString("shareify_jwt", null).isNullOrEmpty()
    }

    suspend fun testServerConnection(): Boolean = withContext(Dispatchers.IO) {
        val jwtToken = prefs.getString("jwt_token", null)
        if (jwtToken.isNullOrEmpty()) return@withContext false

        try {
            val requestBody = JSONObject().apply {
                put("command", "/is_up")
                put("method", "GET")
                put("wait_time", 1)
            }

            val requestBuilder = Request.Builder()
                .url("https://command.bbarni.hackclub.app/")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .addHeader("Authorization", "Bearer $jwtToken")

            val shareifyJWT = prefs.getString("shareify_jwt", null)
            if (!shareifyJWT.isNullOrEmpty()) {
                requestBuilder.addHeader("X-Shareify-JWT", shareifyJWT)
            }

            val response = client.newCall(requestBuilder.build()).execute()
            response.isSuccessful || response.code == 404
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        @Volatile
        private var instance: ServerManager? = null

        fun getInstance(context: Context): ServerManager {
            return instance ?: synchronized(this) {
                instance ?: ServerManager(context.applicationContext).also { instance = it }
            }
        }
    }
}

sealed class ServerError : Exception() {
    object NoJWTToken : ServerError()
    object NoCredentials : ServerError()
    object InvalidResponse : ServerError()
    object AuthFailed : ServerError()
    data class ServerError(val message: String) : com.shareify.code.models.ServerError()
}

private fun JSONObject.toMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    keys().forEach { key ->
        map[key] = get(key)
    }
    return map
}

private fun JSONArray.toList(): List<Any> {
    val list = mutableListOf<Any>()
    for (i in 0 until length()) {
        list.add(get(i))
    }
    return list
}
