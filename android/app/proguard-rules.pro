# Giữ nguyên lớp plugin Flutter được gọi qua JNI/Pigeon (R8 từng làm hỏng
# shared_preferences_android: NoSuchMethodError SharedPreferencesApiRegistrar.getAll
# -> app treo ở native splash trên bản release).
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-keep class com.dexterous.** { *; }
-keep class org.maplibre.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class kotlin.** { *; }
