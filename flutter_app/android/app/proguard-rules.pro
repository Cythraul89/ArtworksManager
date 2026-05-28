# WorkManager: keep Room database and initializer classes so R8 doesn't rename them
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepnames class androidx.work.impl.WorkDatabase
-keepnames class androidx.work.impl.WorkDatabase_Impl

# Keep startup initializers
-keep class androidx.startup.** { *; }
