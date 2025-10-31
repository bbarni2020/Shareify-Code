package com.shareify.code.models

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

data class ChatMessage(
    val role: String,
    val content: String
)

data class AIModel(
    val id: String,
    val obj: String? = null,
    val created: Long? = null,
    val ownedBy: String? = null
)

class AIService private constructor() {
    private val baseURL = "https://ai.hackclub.com"
    private val client = OkHttpClient.Builder()
        .connectTimeout(60, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()
    
    private val systemPrompt = AISystemPrompt.PROMPT

    suspend fun fetchModels(): Result<List<AIModel>> = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("$baseURL/models")
                .get()
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            if (response.isSuccessful && responseBody != null) {
                val json = JSONObject(responseBody)
                val dataArray = json.getJSONArray("data")
                val models = mutableListOf<AIModel>()

                for (i in 0 until dataArray.length()) {
                    val modelJson = dataArray.getJSONObject(i)
                    models.add(
                        AIModel(
                            id = modelJson.getString("id"),
                            obj = modelJson.optString("object"),
                            created = modelJson.optLong("created"),
                            ownedBy = modelJson.optString("owned_by")
                        )
                    )
                }

                Result.success(models)
            } else {
                Result.failure(Exception("Failed to fetch models: ${response.code}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun sendMessage(
        messages: List<ChatMessage>,
        model: String = "meta-llama/llama-4-maverick",
        temperature: Double = 0.7,
        maxTokens: Int? = null
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val fullMessages = mutableListOf(ChatMessage("system", systemPrompt))
            fullMessages.addAll(messages)

            val messagesArray = JSONArray()
            fullMessages.forEach { message ->
                messagesArray.put(JSONObject().apply {
                    put("role", message.role)
                    put("content", message.content)
                })
            }

            val requestBody = JSONObject().apply {
                put("messages", messagesArray)
                put("model", model)
                put("temperature", temperature)
                if (maxTokens != null) {
                    put("max_tokens", maxTokens)
                }
            }

            val request = Request.Builder()
                .url("$baseURL/chat/completions")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            if (response.isSuccessful && responseBody != null) {
                val json = JSONObject(responseBody)
                val choices = json.getJSONArray("choices")
                
                if (choices.length() > 0) {
                    val firstChoice = choices.getJSONObject(0)
                    val message = firstChoice.getJSONObject("message")
                    val content = message.getString("content")
                    Result.success(content)
                } else {
                    Result.failure(Exception("No response from AI"))
                }
            } else {
                Result.failure(Exception("AI request failed: ${response.code} - $responseBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    companion object {
        @Volatile
        private var instance: AIService? = null

        fun getInstance(): AIService {
            return instance ?: synchronized(this) {
                instance ?: AIService().also { instance = it }
            }
        }
    }
}
