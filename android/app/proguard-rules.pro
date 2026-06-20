# Keep the flutter_local_notifications classes from being obfuscated or removed
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep attributes for generic type signatures needed by Gson
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses

# Gson rules for TypeToken generic preservation
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
