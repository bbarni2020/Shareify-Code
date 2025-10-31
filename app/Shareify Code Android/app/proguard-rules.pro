-keep class com.shareify.code.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exception

-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
