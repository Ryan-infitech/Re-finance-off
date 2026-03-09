import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'encryption_service.dart';

class ImageService {
  static final ImageService instance = ImageService._init();
  final ImagePicker _picker = ImagePicker();

  ImageService._init();

  // Pick image from gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Take photo with camera
  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return await _saveImage(photo);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save image encrypted to app directory
  Future<String> _saveImage(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.enc';
    final savedPath = '${appDir.path}/$fileName';

    final imageBytes = await File(image.path).readAsBytes();
    final base64Data = base64Encode(imageBytes);
    final encryptedData = EncryptionService.instance.encryptData(base64Data);
    await File(savedPath).writeAsString(encryptedData);

    return savedPath;
  }

  // Validate path is within app documents directory
  Future<bool> _isValidAppPath(String filePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final resolvedPath = path.canonicalize(filePath);
    final appDirPath = path.canonicalize(appDir.path);
    return resolvedPath.startsWith(appDirPath);
  }

  // Load and decrypt image file, returns decrypted bytes as temp file
  Future<File?> getDecryptedImage(String encryptedPath) async {
    try {
      // Validate path is within app directory
      if (!await _isValidAppPath(encryptedPath)) return null;

      final file = File(encryptedPath);
      if (!await file.exists()) return null;

      // Check if this is an encrypted file
      if (encryptedPath.endsWith('.enc')) {
        final encryptedData = await file.readAsString();
        final base64Data = EncryptionService.instance.decryptData(encryptedData);
        final imageBytes = base64Decode(base64Data);

        // Write to temp directory (not documents) for display
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/view_${path.basename(encryptedPath)}.jpg');
        await tempFile.writeAsBytes(imageBytes);
        return tempFile;
      }

      // Legacy: unencrypted file, return as-is
      return file;
    } catch (e) {
      return null;
    }
  }

  // Clean up decrypted temp files
  Future<void> cleanupTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      await for (final entity in dir.list()) {
        if (entity is File && path.basename(entity.path).startsWith('view_')) {
          await _secureDelete(entity);
        }
      }
    } catch (_) {}
  }

  // Securely delete a file by overwriting before deletion
  Future<void> _secureDelete(File file) async {
    try {
      if (!await file.exists()) return;
      final size = await file.length();
      final random = Random.secure();
      await file.writeAsBytes(List<int>.generate(size, (_) => random.nextInt(256)));
      await file.delete();
    } catch (_) {}
  }

  // Delete all encrypted images
  Future<void> deleteAllImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(appDir.path);
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.enc')) {
          await _secureDelete(entity);
        }
      }
      await cleanupTempImages();
    } catch (_) {}
  }

  // Delete image file
  Future<bool> deleteImage(String imagePath) async {
    try {
      if (!await _isValidAppPath(imagePath)) return false;
      final file = File(imagePath);
      if (await file.exists()) {
        await _secureDelete(file);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
