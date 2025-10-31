package com.shareify.code.models

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

fun JSONObject.toMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    keys().forEach { key ->
        map[key] = get(key)
    }
    return map
}

fun org.json.JSONArray.toList(): List<Any> {
    val list = mutableListOf<Any>()
    for (i in 0 until length()) {
        list.add(get(i))
    }
    return list
}

class CryptoManager(private val clientId: String) {
    private var privateKey: PrivateKey? = null
    private var publicKey: PublicKey? = null
    private var sessionKey: SecretKey? = null
    
    init {
        loadOrGenerateRSAKeyPair()
    }
    
    private fun loadOrGenerateRSAKeyPair() {
        try {
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)
            
            val alias = "shareify_rsa_$clientId"
            
            if (keyStore.containsAlias(alias)) {
                val entry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
                if (entry != null) {
                    privateKey = entry.privateKey
                    publicKey = entry.certificate.publicKey
                    return
                }
            }
            
            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_RSA,
                "AndroidKeyStore"
            )
            
            val spec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_DECRYPT
            )
                .setKeySize(4096)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
                .setDigests(KeyProperties.DIGEST_SHA256)
                .build()
            
            keyPairGenerator.initialize(spec)
            val keyPair = keyPairGenerator.generateKeyPair()
            
            privateKey = keyPair.private
            publicKey = keyPair.public
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    fun getPublicKeyPEM(): String? {
        val publicKey = publicKey ?: return null
        
        return try {
            val encoded = publicKey.encoded
            val base64 = Base64.encodeToString(encoded, Base64.NO_WRAP)
            val chunks = base64.chunked(64)
            
            buildString {
                appendLine("-----BEGIN PUBLIC KEY-----")
                chunks.forEach { appendLine(it) }
                append("-----END PUBLIC KEY-----")
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    fun decryptSessionKey(encryptedKeyBase64: String): Boolean {
        val privateKey = privateKey ?: return false
        
        return try {
            val encryptedData = Base64.decode(encryptedKeyBase64, Base64.DEFAULT)
            
            val cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")
            cipher.init(Cipher.DECRYPT_MODE, privateKey)
            val decryptedData = cipher.doFinal(encryptedData)
            
            sessionKey = SecretKeySpec(decryptedData, "AES")
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    fun encryptData(data: ByteArray): Map<String, String>? {
        val sessionKey = sessionKey ?: return null
        
        return try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, sessionKey)
            
            val ciphertext = cipher.doFinal(data)
            val iv = cipher.iv
            
            mapOf(
                "nonce" to Base64.encodeToString(iv, Base64.NO_WRAP),
                "ciphertext" to Base64.encodeToString(ciphertext, Base64.NO_WRAP)
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    fun decryptData(encryptedPackage: Map<String, String>): ByteArray? {
        val sessionKey = sessionKey ?: return null
        
        return try {
            val nonce = Base64.decode(encryptedPackage["nonce"], Base64.DEFAULT)
            val ciphertext = Base64.decode(encryptedPackage["ciphertext"], Base64.DEFAULT)
            
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, nonce)
            cipher.init(Cipher.DECRYPT_MODE, sessionKey, spec)
            
            cipher.doFinal(ciphertext)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    fun encryptRequest(requestJson: String): Map<String, String>? {
        return encryptData(requestJson.toByteArray())
    }
    
    fun decryptResponse(encryptedPackage: JSONObject): Any? {
        val packageMap = mapOf(
            "nonce" to encryptedPackage.optString("nonce", ""),
            "ciphertext" to encryptedPackage.optString("ciphertext", "")
        )
        
        val decryptedData = decryptData(packageMap) ?: return null
        val jsonString = String(decryptedData)
        
        return try {
            JSONObject(jsonString).toMap()
        } catch (e: Exception) {
            try {
                org.json.JSONArray(jsonString).toList()
            } catch (e2: Exception) {
                null
            }
        }
    }
    
    fun hasSessionKey(): Boolean = sessionKey != null
    
    fun clearSession() {
        sessionKey = null
    }
}
