package com.reactnative.zeropermissionpicker

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.fragment.app.FragmentActivity
import android.util.Log
import com.facebook.react.bridge.ActivityEventListener
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableArray
import java.io.File
import kotlin.math.roundToInt

class RNZeroPermissionPickerModule(
    private val context: ReactApplicationContext
) : ReactContextBaseJavaModule(context), ActivityEventListener {

  companion object {
    private const val TAG = "ZeroPermissionPicker"
  }

  private val fileHelper = PickerFileHelper(context)
  private var pendingRequest: PendingRequest? = null

  init {
    context.addActivityEventListener(this)
  }

  override fun getName(): String = "RNZeroPermissionPicker"

  @ReactMethod
  fun pickMedia(options: ReadableMap, promise: Promise) {
    val activity = context.currentActivity ?: run {
      Log.w(TAG, "pickMedia called but currentActivity is null")
      promise.reject("NO_ACTIVITY", "No current activity.")
      return
    }

    if (pendingRequest != null) {
      promise.reject("PICKER_BUSY", "Another picker request is already in progress.")
      return
    }

    val pickerOptions =
        PickerOptions(
            multiple = options.getBooleanOrDefault("multiple", false),
            copyToCache = options.getBooleanOrDefault("copyToCache", true),
            stripExif = options.getBooleanOrDefault("stripEXIF", false),
            compress = options.getBooleanOrDefault("compress", false),
            quality = options.getDoubleOrDefault("quality", 0.9),
            maxLongEdge = options.getIntOrNull("maxLongEdge"),
            convertHeicToJpeg = options.getBooleanOrDefault("convertHeicToJpeg", true),
            allowDirectories = false
        )

    val mimeTypes = getMimeTypesForKind(options.getString("kind") ?: "mixed")
    val requestType =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          RequestType.MEDIA_PHOTO_PICKER
        } else {
          RequestType.MEDIA_SAF
        }
    pendingRequest = PendingRequest(requestType, pickerOptions, promise)

    try {
      Log.d(
          TAG,
          "Launching ${requestType.name} for media. multiple=${pickerOptions.multiple}, " +
              "copyToCache=${pickerOptions.copyToCache}, compress=${pickerOptions.compress}")
      if (requestType == RequestType.MEDIA_PHOTO_PICKER) {
        launchPhotoPicker(activity as FragmentActivity, mimeTypes, pickerOptions.multiple, requestType.requestCode)
      } else {
        launchSaf(activity, mimeTypes, pickerOptions.multiple, pickerOptions.allowDirectories, requestType.requestCode)
      }
    } catch (e: Exception) {
      pendingRequest = null
      Log.e(TAG, "Failed to launch picker", e)
      promise.reject("IO_ERROR", "Failed to launch picker: ${e.message}", e)
    }
  }

  @ReactMethod
  fun pickFiles(options: ReadableMap, promise: Promise) {
    val activity = context.currentActivity ?: run {
      Log.w(TAG, "pickFiles called but currentActivity is null")
      promise.reject("NO_ACTIVITY", "No current activity.")
      return
    }

    if (pendingRequest != null) {
      promise.reject("PICKER_BUSY", "Another picker request is already in progress.")
      return
    }

    val pickerOptions =
        PickerOptions(
            multiple = options.getBooleanOrDefault("multiple", false),
            copyToCache = options.getBooleanOrDefault("copyToCache", true),
            stripExif = false,
            compress = false,
            quality = 1.0,
            maxLongEdge = null,
            convertHeicToJpeg = false,
            allowDirectories = options.getBooleanOrDefault("allowDirectories", false)
        )

    val mimeTypes = getMimeTypesForFileKind(options.getString("kind") ?: "any")
    pendingRequest = PendingRequest(RequestType.FILES_SAF, pickerOptions, promise)

    try {
      Log.d(
          TAG,
          "Launching ${pendingRequest?.requestType?.name ?: RequestType.FILES_SAF.name} for files. " +
              "multiple=${pickerOptions.multiple}, allowDirectories=${pickerOptions.allowDirectories}")
      launchSaf(activity, mimeTypes, pickerOptions.multiple, pickerOptions.allowDirectories, RequestType.FILES_SAF.requestCode)
    } catch (e: Exception) {
      pendingRequest = null
      Log.e(TAG, "Failed to launch file picker", e)
      promise.reject("IO_ERROR", "Failed to launch picker: ${e.message}", e)
    }
  }

  @ReactMethod
  fun isSystemPhotoPickerAvailable(promise: Promise) {
    promise.resolve(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
  }

  @ReactMethod
  fun clearCachedFiles(promise: Promise) {
    try {
      fileHelper.clearCache()
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("IO_ERROR", "Failed to clear cache: ${e.message}", e)
    }
  }

  private fun launchPhotoPicker(
      activity: FragmentActivity,
      mimeTypes: List<String>,
      multiple: Boolean,
      requestCode: Int
  ) {
    val intent = Intent(MediaStore.ACTION_PICK_IMAGES).apply {
      if (multiple) {
        val maxLimit =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
              MediaStore.getPickImagesMaxLimit()
            } else {
              1
            }
        putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, maxLimit)
      }
      if (mimeTypes.isNotEmpty()) {
        type = if (mimeTypes.size == 1) mimeTypes[0] else "*/*"
        if (mimeTypes.size > 1) {
          putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
        }
      }
    }
    activity.startActivityForResult(intent, requestCode)
  }

  private fun launchSaf(
      activity: Activity,
      mimeTypes: List<String>,
      multiple: Boolean,
      allowDirectories: Boolean,
      requestCode: Int
  ) {
    val intent =
        if (allowDirectories) {
          Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        } else {
          Intent(Intent.ACTION_OPEN_DOCUMENT).apply { addCategory(Intent.CATEGORY_OPENABLE) }
        }.apply {
          addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
          addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)

          if (!allowDirectories) {
            if (mimeTypes.isNotEmpty()) {
              type = if (mimeTypes.size == 1) mimeTypes[0] else "*/*"
              if (mimeTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
              }
            } else {
              type = "*/*"
            }
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
          }
        }
    Log.d(TAG, "Starting SAF intent. allowDirectories=$allowDirectories, multiple=$multiple, requestCode=$requestCode")
    activity.startActivityForResult(intent, requestCode)
  }

  override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
    val request = pendingRequest
    if (request == null || request.requestType.requestCode != requestCode) {
      return
    }
    pendingRequest = null

    if (resultCode != Activity.RESULT_OK) {
      Log.d(TAG, "Picker canceled or failed. resultCode=$resultCode")
      request.promise.resolve(Arguments.createArray())
      return
    }

    val uris = extractUris(data, request)
    Log.d(TAG, "Received ${uris.size} URIs for request ${request.requestType}")
    if (uris.isEmpty()) {
      request.promise.resolve(Arguments.createArray())
      return
    }

    try {
      val result = processUris(uris, request)
      Log.d(TAG, "Processed ${result.size()} items successfully")
      request.promise.resolve(result)
    } catch (e: Exception) {
      Log.e(TAG, "Failed processing picked items", e)
      request.promise.reject("PROCESSING_ERROR", "Failed to process picked items: ${e.message}", e)
    }
  }

  override fun onNewIntent(intent: Intent) = Unit

  override fun onCatalystInstanceDestroy() {
    super.onCatalystInstanceDestroy()
    context.removeActivityEventListener(this)
  }

  private fun extractUris(intent: Intent?, request: PendingRequest): List<Uri> {
    val result = mutableListOf<Uri>()
    if (intent == null) {
      return result
    }

    if (request.requestType == RequestType.FILES_SAF && request.options.allowDirectories) {
      intent.data?.let { result.add(it) }
      return result
    }

    val clipData = intent.clipData
    if (clipData != null && clipData.itemCount > 0) {
      val limit = if (request.options.multiple) clipData.itemCount else 1
      for (i in 0 until limit.coerceAtMost(clipData.itemCount)) {
        clipData.getItemAt(i)?.uri?.let { result.add(it) }
      }
    } else {
      intent.data?.let { result.add(it) }
    }
    return result
  }

  private fun processUris(uris: List<Uri>, request: PendingRequest): WritableArray {
    val array = Arguments.createArray()
    val resolver = context.contentResolver

    uris.forEach { originalUri ->
      val originalMimeType = resolver.getType(originalUri)
      var workingUri = originalUri

      if (request.options.copyToCache) {
        fileHelper.copyToCache(workingUri)?.let { workingUri = it }
      }

      if (request.options.stripExif && isImage(originalMimeType)) {
        fileHelper.stripExifFromImage(workingUri)?.let { workingUri = it }
      }

      val shouldCompress =
          (request.options.compress && isImage(originalMimeType)) ||
              (request.options.convertHeicToJpeg && isHeic(originalMimeType))
      if (shouldCompress) {
        val quality = toQualityPercent(request.options.quality)
        fileHelper.compressImage(workingUri, quality, request.options.maxLongEdge)?.let { workingUri = it }
      }

      val displayName = resolveDisplayName(workingUri)
      val map = fileHelper.getPickedItemMap(workingUri, displayName, emptyMap())
      val loggedMime = map.getString("mimeType")
      Log.d(TAG, "Item processed uri=$workingUri displayName=$displayName mimeType=$loggedMime")
      if (!map.hasKey("mimeType") && originalMimeType != null) {
        map.putString("mimeType", originalMimeType)
      }
      array.pushMap(map)
    }

    return array
  }

  private fun resolveDisplayName(uri: Uri): String? {
    if ("file".equals(uri.scheme, ignoreCase = true)) {
      return uri.path?.let { path -> path.substringAfterLast(File.separator) }
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && DocumentsContract.isTreeUri(uri)) {
      return DocumentsContract.getTreeDocumentId(uri)?.substringAfterLast(':')
    }

    var cursor: Cursor? = null
    return try {
      cursor = context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
      if (cursor != null && cursor.moveToFirst()) {
        cursor.getString(0)
      } else {
        uri.lastPathSegment
      }
    } catch (_: Exception) {
      uri.lastPathSegment
    } finally {
      cursor?.close()
    }
  }

  private fun isImage(mimeType: String?): Boolean =
      mimeType?.startsWith("image/", ignoreCase = true) == true

  private fun isHeic(mimeType: String?): Boolean =
      mimeType.equals("image/heic", ignoreCase = true) ||
          mimeType.equals("image/heif", ignoreCase = true)

  private fun toQualityPercent(value: Double): Int =
      when {
        value.isNaN() -> 90
        value >= 1.0 -> value.roundToInt().coerceIn(0, 100)
        value <= 0.0 -> 100
        else -> (value * 100.0).roundToInt().coerceIn(0, 100)
      }

}

private fun getMimeTypesForKind(kind: String): List<String> =
    when (kind) {
      "image" -> listOf("image/*")
      "video" -> listOf("video/*")
      "mixed" -> listOf("image/*", "video/*")
      else -> listOf("image/*", "video/*")
    }

private fun getMimeTypesForFileKind(kind: String): List<String> =
    when (kind) {
      "image" -> listOf("image/*")
      "video" -> listOf("video/*")
      "pdf" -> listOf("application/pdf")
      "audio" -> listOf("audio/*")
      "text" -> listOf("text/*")
      "zip" -> listOf("application/zip", "application/x-zip-compressed")
      "custom" -> emptyList()
      else -> emptyList()
    }

private data class PickerOptions(
    val multiple: Boolean,
    val copyToCache: Boolean,
    val stripExif: Boolean,
    val compress: Boolean,
    val quality: Double,
    val maxLongEdge: Int?,
    val convertHeicToJpeg: Boolean,
    val allowDirectories: Boolean
)

private data class PendingRequest(
    val requestType: RequestType,
    val options: PickerOptions,
    val promise: Promise
)

private enum class RequestType(val requestCode: Int) {
  MEDIA_PHOTO_PICKER(1001),
  MEDIA_SAF(1002),
  FILES_SAF(1003)
}

private fun ReadableMap.getBooleanOrDefault(key: String, defaultValue: Boolean): Boolean =
    if (hasKey(key) && getType(key) != ReadableType.Null) getBoolean(key) else defaultValue

private fun ReadableMap.getDoubleOrDefault(key: String, defaultValue: Double): Double =
    if (hasKey(key) && getType(key) != ReadableType.Null) getDouble(key) else defaultValue

private fun ReadableMap.getIntOrNull(key: String): Int? =
    if (hasKey(key) && getType(key) != ReadableType.Null) getInt(key) else null
