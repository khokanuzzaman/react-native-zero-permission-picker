package com.reactnative.zeropermissionpicker

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments
import java.io.File
import java.io.InputStream
import java.util.UUID
import android.graphics.Bitmap
import android.graphics.BitmapFactory

class PickerFileHelper(private val context: Context) {
  private val cacheDir: File = File(context.cacheDir, "rn-zero-permission-picker")

  init {
    if (!cacheDir.exists()) {
      cacheDir.mkdirs()
    }
  }

  fun getPickedItemMap(uri: Uri, originalName: String?, options: Map<String, Any>): WritableMap {
    val map = Arguments.createMap()
    
    map.putString("id", UUID.randomUUID().toString())
    map.putString("uri", uri.toString())
    map.putString("displayName", originalName ?: "file")
    
    // Get MIME type
    val mimeType = context.contentResolver.getType(uri)
    if (mimeType != null) {
      map.putString("mimeType", mimeType)
    }

    // Get file size
    try {
      val inputStream = context.contentResolver.openInputStream(uri)
      if (inputStream != null) {
        val size = inputStream.available()
        map.putInt("size", size)
        inputStream.close()
      }
    } catch (e: Exception) {
      // Ignore
    }

    // Get dimensions for images
    if (mimeType?.startsWith("image/") == true) {
      try {
        val inputStream = context.contentResolver.openInputStream(uri)
        if (inputStream != null) {
          val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
          BitmapFactory.decodeStream(inputStream, null, options)
          if (options.outWidth > 0 && options.outHeight > 0) {
            map.putInt("width", options.outWidth)
            map.putInt("height", options.outHeight)
          }
          inputStream.close()
        }
      } catch (e: Exception) {
        // Ignore
      }
    }

    // Get duration for videos
    if (mimeType?.startsWith("video/") == true) {
      try {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(context, uri)
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
        if (duration != null) {
          map.putInt("durationMs", duration.toInt())
        }
        retriever.release()
      } catch (e: Exception) {
        // Ignore
      }
    }

    return map
  }

  fun copyToCache(uri: Uri): Uri? {
    return try {
      val inputStream = context.contentResolver.openInputStream(uri) ?: return null
      val filename = "cached_${System.currentTimeMillis()}_${UUID.randomUUID().toString().substring(0, 8)}"
      val cachedFile = File(cacheDir, filename)
      
      inputStream.use { input ->
        cachedFile.outputStream().use { output ->
          input.copyTo(output)
        }
      }
      
      Uri.fromFile(cachedFile)
    } catch (e: Exception) {
      null
    }
  }

  fun stripExifFromImage(uri: Uri): Uri? {
    return try {
      val inputStream = context.contentResolver.openInputStream(uri) ?: return null
      val bitmap = BitmapFactory.decodeStream(inputStream)
      inputStream.close()
      
      if (bitmap != null) {
        val filename = "exif_stripped_${System.currentTimeMillis()}"
        val outFile = File(cacheDir, filename)
        val outputStream = outFile.outputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 95, outputStream)
        outputStream.close()
        
        Uri.fromFile(outFile)
      } else {
        null
      }
    } catch (e: Exception) {
      null
    }
  }

  fun compressImage(uri: Uri, quality: Int, maxLongEdge: Int?): Uri? {
    return try {
      val inputStream = context.contentResolver.openInputStream(uri) ?: return null
      var bitmap = BitmapFactory.decodeStream(inputStream)
      inputStream.close()
      
      if (bitmap != null) {
        // Resize if needed
        if (maxLongEdge != null && maxLongEdge > 0) {
          val longEdge = maxOf(bitmap.width, bitmap.height)
          if (longEdge > maxLongEdge) {
            val scale = maxLongEdge.toFloat() / longEdge
            val newWidth = (bitmap.width * scale).toInt()
            val newHeight = (bitmap.height * scale).toInt()
            bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
          }
        }
        
        val filename = "compressed_${System.currentTimeMillis()}"
        val outFile = File(cacheDir, filename)
        val outputStream = outFile.outputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
        outputStream.close()
        
        Uri.fromFile(outFile)
      } else {
        null
      }
    } catch (e: Exception) {
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
