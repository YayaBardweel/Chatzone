// ============================================================================
// File: lib/core/data/services/storage_service.dart
// ============================================================================

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';

/// Firebase Storage service for file operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================================
  // FILE UPLOAD OPERATIONS
  // ============================================================================

  /// Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String path,
    Map<String, String>? metadata,
    void Function(double)? onProgress,
  }) async {
    try {
      print('🔥 StorageService: Uploading file to $path');

      final ref = _storage.ref().child(path);

      // Set metadata if provided
      SettableMetadata? settableMetadata;
      if (metadata != null) {
        settableMetadata = SettableMetadata(
          customMetadata: metadata,
        );
      }

      // Start upload
      final uploadTask = ref.putFile(file, settableMetadata);

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ StorageService: File uploaded successfully');
      return downloadUrl;
    } catch (e) {
      print('❌ StorageService: Upload file failed - $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload file from bytes
  Future<String> uploadFileFromBytes({
    required Uint8List bytes,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
    void Function(double)? onProgress,
  }) async {
    try {
      print('🔥 StorageService: Uploading bytes to $path');

      final ref = _storage.ref().child(path);

      // Set metadata
      SettableMetadata settableMetadata = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata,
      );

      // Start upload
      final uploadTask = ref.putData(bytes, settableMetadata);

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ StorageService: Bytes uploaded successfully');
      return downloadUrl;
    } catch (e) {
      print('❌ StorageService: Upload bytes failed - $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload image with compression
  Future<String> uploadImage({
    required File imageFile,
    required String path,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    void Function(double)? onProgress,
  }) async {
    try {
      print('🔥 StorageService: Uploading image to $path');

      // Set image metadata
      final metadata = {
        'type': 'image',
        'uploadedAt': DateTime.now().toIso8601String(),
        if (maxWidth != null) 'maxWidth': maxWidth.toString(),
        if (maxHeight != null) 'maxHeight': maxHeight.toString(),
        if (quality != null) 'quality': quality.toString(),
      };

      return await uploadFile(
        file: imageFile,
        path: path,
        metadata: metadata,
        onProgress: onProgress,
      );
    } catch (e) {
      print('❌ StorageService: Upload image failed - $e');
      rethrow;
    }
  }

  // ============================================================================
  // FILE DOWNLOAD OPERATIONS
  // ============================================================================

  /// Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ StorageService: Get download URL failed - $e');
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// Download file to local storage
  Future<File> downloadFile({
    required String path,
    required String localPath,
  }) async {
    try {
      print('🔥 StorageService: Downloading file from $path to $localPath');

      final ref = _storage.ref().child(path);
      final file = File(localPath);

      await ref.writeToFile(file);

      print('✅ StorageService: File downloaded successfully');
      return file;
    } catch (e) {
      print('❌ StorageService: Download file failed - $e');
      throw Exception('Failed to download file: $e');
    }
  }

  /// Download file as bytes
  Future<Uint8List?> downloadFileAsBytes(String path) async {
    try {
      print('🔥 StorageService: Downloading file as bytes from $path');

      final ref = _storage.ref().child(path);
      final bytes = await ref.getData();

      print('✅ StorageService: File downloaded as bytes successfully');
      return bytes;
    } catch (e) {
      print('❌ StorageService: Download file as bytes failed - $e');
      throw Exception('Failed to download file: $e');
    }
  }

  // ============================================================================
  // FILE MANAGEMENT OPERATIONS
  // ============================================================================

  /// Delete file from storage
  Future<void> deleteFile({required String path}) async {
    try {
      print('🔥 StorageService: Deleting file at $path');

      final ref = _storage.ref().child(path);
      await ref.delete();

      print('✅ StorageService: File deleted successfully');
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        print('⚠️ StorageService: File not found, already deleted - $path');
        return; // File doesn't exist, consider it successful
      }
      print('❌ StorageService: Delete file failed - $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        return false;
      }
      print('❌ StorageService: Check file exists failed - $e');
      rethrow;
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ StorageService: Get file metadata failed - $e');
      throw Exception('Failed to get file metadata: $e');
    }
  }

  /// Update file metadata
  Future<void> updateFileMetadata({
    required String path,
    required Map<String, String> metadata,
  }) async {
    try {
      print('🔥 StorageService: Updating metadata for $path');

      final ref = _storage.ref().child(path);
      final settableMetadata = SettableMetadata(customMetadata: metadata);

      await ref.updateMetadata(settableMetadata);

      print('✅ StorageService: Metadata updated successfully');
    } catch (e) {
      print('❌ StorageService: Update metadata failed - $e');
      throw Exception('Failed to update metadata: $e');
    }
  }

  // ============================================================================
  // FOLDER OPERATIONS
  // ============================================================================

  /// List all files in a folder
  Future<List<Reference>> listFiles({
    required String folderPath,
    int? maxResults,
  }) async {
    try {
      print('🔥 StorageService: Listing files in $folderPath');

      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();

      List<Reference> files = result.items;

      if (maxResults != null && files.length > maxResults) {
        files = files.take(maxResults).toList();
      }

      print('✅ StorageService: Found ${files.length} files');
      return files;
    } catch (e) {
      print('❌ StorageService: List files failed - $e');
      throw Exception('Failed to list files: $e');
    }
  }

  /// Delete all files in a folder
  Future<void> deleteFolder(String folderPath) async {
    try {
      print('🔥 StorageService: Deleting folder $folderPath');

      final files = await listFiles(folderPath: folderPath);

      for (final file in files) {
        await file.delete();
      }

      print('✅ StorageService: Folder deleted successfully');
    } catch (e) {
      print('❌ StorageService: Delete folder failed - $e');
      throw Exception('Failed to delete folder: $e');
    }
  }

  // ============================================================================
  // UPLOAD PROGRESS TRACKING
  // ============================================================================

  /// Upload file with detailed progress tracking
  Future<String> uploadFileWithProgress({
    required File file,
    required String path,
    required Function(UploadProgress) onProgress,
    Map<String, String>? metadata,
  }) async {
    try {
      print('🔥 StorageService: Uploading file with progress tracking to $path');

      final ref = _storage.ref().child(path);

      // Set metadata if provided
      SettableMetadata? settableMetadata;
      if (metadata != null) {
        settableMetadata = SettableMetadata(customMetadata: metadata);
      }

      // Start upload
      final uploadTask = ref.putFile(file, settableMetadata);

      // Listen to progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = UploadProgress(
          bytesTransferred: snapshot.bytesTransferred,
          totalBytes: snapshot.totalBytes,
          percentage: snapshot.bytesTransferred / snapshot.totalBytes,
          state: _mapTaskState(snapshot.state),
        );
        onProgress(progress);
      });

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ StorageService: File uploaded with progress tracking');
      return downloadUrl;
    } catch (e) {
      print('❌ StorageService: Upload with progress failed - $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Map Firebase task state to our enum
  UploadState _mapTaskState(TaskState state) {
    switch (state) {
      case TaskState.running:
        return UploadState.uploading;
      case TaskState.paused:
        return UploadState.paused;
      case TaskState.success:
        return UploadState.completed;
      case TaskState.canceled:
        return UploadState.canceled;
      case TaskState.error:
        return UploadState.error;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get file size
  Future<int> getFileSize(String path) async {
    try {
      final metadata = await getFileMetadata(path);
      return metadata.size ?? 0;
    } catch (e) {
      print('❌ StorageService: Get file size failed - $e');
      return 0;
    }
  }

  /// Validate file size
  bool isFileSizeValid(File file, int maxSizeInBytes) {
    final fileSizeInBytes = file.lengthSync();
    return fileSizeInBytes <= maxSizeInBytes;
  }

  /// Get file extension
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  /// Generate unique file name
  String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalName);
    final nameWithoutExtension = originalName.substring(0, originalName.lastIndexOf('.'));
    return '${nameWithoutExtension}_$timestamp.$extension';
  }
}

// ============================================================================
// UPLOAD PROGRESS CLASSES
// ============================================================================

class UploadProgress {
  final int bytesTransferred;
  final int totalBytes;
  final double percentage;
  final UploadState state;

  UploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.percentage,
    required this.state,
  });

  @override
  String toString() {
    return 'UploadProgress(transferred: $bytesTransferred, total: $totalBytes, percentage: ${(percentage * 100).toStringAsFixed(1)}%, state: $state)';
  }
}

enum UploadState {
  uploading,
  paused,
  completed,
  canceled,
  error,
}