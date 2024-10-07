package com.devoup.isthihaaru

import android.content.Context
import android.media.MediaScannerConnection
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaScannerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.devoup.isthihaaru/media_scanner")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanFile" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    MediaScannerConnection.scanFile(context, arrayOf(path), null) { _, _ ->
                        result.success(null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Path cannot be null", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}