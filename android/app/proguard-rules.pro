# Flutter engine and plugins rely on reflection for their registrants.
-keep class io.flutter.** { *; }
-keep class com.lumashield.app.** { *; }
-dontwarn io.flutter.embedding.**
