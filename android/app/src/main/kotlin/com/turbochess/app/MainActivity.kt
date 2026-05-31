package com.turbochess.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun shouldHandleDeeplinking(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.turbochess.app/stockfish",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEngineInfo" -> result.success(getEngineInfo())
                "getDeviceProfile" -> result.success(getDeviceProfile())
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.turbochess.app/system_clock",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "elapsedRealtimeMillis" -> result.success(SystemClock.elapsedRealtime())
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }

    private fun getEngineInfo(): Map<String, Any?> {
        val nativeLibraryDir = applicationInfo.nativeLibraryDir.orEmpty()
        val stockfishFile = File(nativeLibraryDir, "libstockfish.so")
        return mapOf(
            "nativeLibraryDir" to nativeLibraryDir,
            "stockfishPath" to stockfishFile.absolutePath,
            "stockfishExists" to stockfishFile.exists(),
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
        )
    }

    private fun getDeviceProfile(): Map<String, Any?> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return mapOf(
            "lowRamDevice" to activityManager.isLowRamDevice,
            "memoryClassMb" to activityManager.memoryClass,
            "largeMemoryClassMb" to activityManager.largeMemoryClass,
            "totalMemoryMb" to (memoryInfo.totalMem / (1024L * 1024L)).toInt(),
            "availableMemoryMb" to (memoryInfo.availMem / (1024L * 1024L)).toInt(),
        )
    }
}
