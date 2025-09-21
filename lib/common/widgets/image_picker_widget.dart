import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File? file, XFile? webFile)? onImageSelected;
  final File? initialImage;
  final XFile? initialWebImage;
  final double? width;
  final double? height;
  final String? placeholder;
  final bool isCircular;

  const ImagePickerWidget({
    super.key,
    this.onImageSelected,
    this.initialImage,
    this.initialWebImage,
    this.width = 140,
    this.height = 140,
    this.placeholder = "Add image",
    this.isCircular = false,
  });

  @override
  State<ImagePickerWidget> createState() => ImagePickerWidgetState();
}

class ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _selectedImage;
  XFile? _selectedImageWeb;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
    _selectedImageWeb = widget.initialWebImage;
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        if (kIsWeb) {
                          _selectedImageWeb = pickedFile;
                          _selectedImage = null;
                        } else {
                          _selectedImage = File(pickedFile.path);
                          _selectedImageWeb = null;
                        }
                      });
                      widget.onImageSelected?.call(_selectedImage, _selectedImageWeb);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        if (kIsWeb) {
                          _selectedImageWeb = pickedFile;
                          _selectedImage = null;
                        } else {
                          _selectedImage = File(pickedFile.path);
                          _selectedImageWeb = null;
                        }
                      });
                      widget.onImageSelected?.call(_selectedImage, _selectedImageWeb);
                    }
                  },
                ),
                if (_selectedImage != null || _selectedImageWeb != null)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Remove Image'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _selectedImageWeb = null;
                      });
                      widget.onImageSelected?.call(null, null);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageDisplay() {
    final hasImage = _selectedImage != null || _selectedImageWeb != null;
    
    if (widget.isCircular) {
      return CircleAvatar(
        radius: (widget.width ?? 60) / 2,
        backgroundColor: Colors.white,
        backgroundImage: hasImage
            ? (kIsWeb && _selectedImageWeb != null
                ? null // Will be handled by FutureBuilder
                : _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : null)
            : null,
        child: hasImage
            ? (kIsWeb && _selectedImageWeb != null
                ? FutureBuilder<Uint8List>(
                    future: _selectedImageWeb!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ClipOval(
                          child: Image.memory(
                            snapshot.data!,
                            width: widget.width,
                            height: widget.height,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  )
                : null)
            : Text(
                widget.placeholder ?? "Add image",
                style: const TextStyle(color: Colors.teal, fontSize: 16),
                textAlign: TextAlign.center,
              ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: kIsWeb && _selectedImageWeb != null
                  ? FutureBuilder<Uint8List>(
                      future: _selectedImageWeb!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            width: widget.width! - 4,
                            height: widget.height! - 4,
                            fit: BoxFit.cover,
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: widget.width! - 4,
                          height: widget.height! - 4,
                          fit: BoxFit.cover,
                        )
                      : Container(),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo,
                    color: Colors.teal,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.placeholder ?? "Add image",
                    style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: _buildImageDisplay(),
        ),
        if (!widget.isCircular)
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 18,
                child: Icon(
                  (_selectedImage != null || _selectedImageWeb != null)
                      ? Icons.edit
                      : Icons.add_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Public method to clear image
  void clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageWeb = null;
    });
    widget.onImageSelected?.call(null, null);
  }

  // Public method to get current image
  Map<String, dynamic> getCurrentImage() {
    return {
      'file': _selectedImage,
      'webFile': _selectedImageWeb,
    };
  }
}