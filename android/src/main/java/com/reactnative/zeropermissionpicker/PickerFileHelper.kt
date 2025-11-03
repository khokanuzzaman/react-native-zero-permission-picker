package com.reactnative.zeropermissionpicker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import java.io.File
import java.io.IOException
import java.util.Locale
import java.util.UUID

class PickerFileHelper(internal val context: Context) {
  private val cacheDir: File = File(context.cacheDir, "rn-zero-permission-picker")

  init {
    if (!cacheDir.exists()) {
      cacheDir.mkdirs()
    }
  }

  fun getPickedItemMap(
      uri: Uri,
      originalName: String?,
      includeFileSize: Boolean,
      includeDimensions: Boolean,
      includeDuration: Boolean
  ): WritableMap {
    val map = Arguments.createMap()

    map.putString("id", UUID.randomUUID().toString())
    map.putString("uri", uri.toString())
    map.putString("displayName", originalName ?: resolveDisplayName(uri) ?: "file")

    val mimeType = resolveMimeType(uri, originalName)
    mimeType?.let { map.putString("mimeType", it) }

    if (includeFileSize) {
      resolveSize(uri)?.let { size ->
        map.putDouble("size", size.toDouble())
      }
    }

    if (includeDimensions && mimeType?.startsWith("image/") == true) {
      decodeImageBounds(uri)?.let { (width, height) ->
        map.putInt("width", width)
        map.putInt("height", height)
      }
    }

    if (includeDuration && mimeType?.startsWith("video/") == true) {
      resolveVideoDuration(uri)?.let { duration ->
        map.putInt("durationMs", duration)
      }
    }

    return map
  }

  fun copyToCache(uri: Uri, displayName: String?, mimeType: String?): Uri? {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && DocumentsContract.isTreeUri(uri)) {
      // Directory selections cannot be copied to cache.
      return uri
    }
    return try {
      context.contentResolver.openInputStream(uri)?.use { input ->
        val cachedFile = File(cacheDir, buildCacheFileName(displayName, mimeType))
        cachedFile.outputStream().use { output -> input.copyTo(output) }
        Uri.fromFile(cachedFile)
      }
    } catch (e: IOException) {
      Log.w("ZeroPermissionPicker", "Failed to copy uri=$uri to cache", e)
      null
    }
  }

  fun transformImageIfNeeded(
      uri: Uri,
      mimeType: String?,
      stripExif: Boolean,
      quality: Int,
      maxLongEdge: Int?,
      convertHeicToJpeg: Boolean,
      shouldCompress: Boolean
  ): ImageTransformationResult? {
    val resizeRequested = maxLongEdge != null && maxLongEdge > 0
    val needsTransform =
        stripExif || shouldCompress || resizeRequested || (convertHeicToJpeg && isHeic(mimeType))
    if (!needsTransform) {
      return null
    }

    return try {
      context.contentResolver.openInputStream(uri)?.use { input ->
        val originalBitmap = BitmapFactory.decodeStream(input) ?: return null
        val processedBitmap =
            if (maxLongEdge != null && maxLongEdge > 0) {
              val longEdge = maxOf(originalBitmap.width, originalBitmap.height)
              if (longEdge > maxLongEdge) {
                val scale = maxLongEdge.toFloat() / longEdge
                val newWidth = (originalBitmap.width * scale).toInt()
                val newHeight = (originalBitmap.height * scale).toInt()
                Bitmap.createScaledBitmap(originalBitmap, newWidth, newHeight, true)
              } else {
                originalBitmap
              }
            } else {
              originalBitmap
            }
        if (processedBitmap !== originalBitmap) {
          originalBitmap.recycle()
        }
        val bitmap = processedBitmap

        val outFile =
            File(
                cacheDir,
                "processed_${System.currentTimeMillis()}_${UUID.randomUUID().toString().take(8)}.jpg")
        outFile.outputStream().use { output ->
          bitmap.compress(Bitmap.CompressFormat.JPEG, quality, output)
        }
        if (!bitmap.isRecycled) {
          bitmap.recycle()
        }

        ImageTransformationResult(
            uri = Uri.fromFile(outFile),
            mimeType = "image/jpeg",
            exifStripped = stripExif || convertHeicToJpeg)
      }
    } catch (e: IOException) {
      Log.w("ZeroPermissionPicker", "Failed to transform image $uri", e)
      null
    }
  }

  fun clearCache() {
    try {
      cacheDir.listFiles()?.forEach { file ->
        file.delete()
      }
    } catch (e: Exception) {
      // Ignore
    }
  }
}

data class ImageTransformationResult(
    val uri: Uri,
    val mimeType: String?,
    val exifStripped: Boolean
)

private fun PickerFileHelper.resolveDisplayName(uri: Uri): String? {
  if ("file".equals(uri.scheme, ignoreCase = true)) {
    return uri.path?.substringAfterLast(File.separator)
  }

  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && DocumentsContract.isDocumentUri(context, uri)) {
    context.contentResolver
        .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
        ?.use { cursor ->
          if (cursor.moveToFirst()) {
            return cursor.getString(0)
          }
        }
  }

  return uri.lastPathSegment
}

private fun PickerFileHelper.resolveMimeType(uri: Uri, originalName: String?): String? {
  val type = context.contentResolver.getType(uri)
  if (!type.isNullOrEmpty()) {
    return type
  }

  val extension = originalName?.substringAfterLast('.', "")
  if (!extension.isNullOrEmpty()) {
    return MimeTypeMap.getSingleton()
        .getMimeTypeFromExtension(extension.lowercase(Locale.US))
  }

  return null
}

private fun PickerFileHelper.resolveSize(uri: Uri): Long? {
  if ("file".equals(uri.scheme, ignoreCase = true)) {
    return uri.path?.let { File(it).takeIf(File::exists)?.length() }
  }

  return context.contentResolver
      .query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)
      ?.use { cursor -> if (cursor.moveToFirst()) cursor.getLong(0).takeIf { it >= 0 } else null }
}

private fun PickerFileHelper.decodeImageBounds(uri: Uri): Pair<Int, Int>? {
  return try {
    context.contentResolver.openInputStream(uri)?.use { input ->
      val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
      BitmapFactory.decodeStream(input, null, options)
      if (options.outWidth > 0 && options.outHeight > 0) {
        options.outWidth to options.outHeight
      } else {
        null
      }
    }
  } catch (_: Exception) {
    null
  }
}

private fun PickerFileHelper.resolveVideoDuration(uri: Uri): Int? {
  return try {
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(context, uri)
      retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toInt()
    } finally {
      retriever.release()
    }
  } catch (_: Exception) {
    null
  }
}

private fun PickerFileHelper.buildCacheFileName(
    displayName: String?,
    mimeType: String?
): String {
  val sanitizedName =
      displayName?.takeIf { it.isNotBlank() }?.let { sanitizeFileName(it) }?.takeIf { it.isNotEmpty() }
  if (!sanitizedName.isNullOrEmpty()) {
    return sanitizedName
  }

  val extension =
      mimeType?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
          ?.takeIf { it.isNotBlank() }

  val suffix = extension?.let { ".$it" } ?: ""
  return "cached_${System.currentTimeMillis()}_${UUID.randomUUID().toString().take(8)}$suffix"
}

private fun sanitizeFileName(name: String): String {
  return name.replace(Regex("[\\\\/:*?\"<>|]"), "_")
}

private fun isHeic(mimeType: String?): Boolean {
  return mimeType.equals("image/heic", ignoreCase = true) ||
      mimeType.equals("image/heif", ignoreCase = true)
}
