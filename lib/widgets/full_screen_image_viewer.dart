import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? imagePath;
  final String fileName;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    required this.fileName,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pinch-to-zoom interactive area spanning the full viewport
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: SizedBox.expand(
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: imagePath != null
                      ? Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade900,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.white38,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey.shade900,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.white38,
                          ),
                        ),
                ),
              ),
            ),
          ),
          
          // Semi-transparent premium header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (imagePath != null)
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () async {
                            try {
                              await Share.shareXFiles([XFile(imagePath!)]);
                            } catch (e) {
                              debugPrint("Error sharing image: $e");
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
