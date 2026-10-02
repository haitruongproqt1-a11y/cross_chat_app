import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'media_gallery_viewer.dart';

class ZaloMediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final String senderName;

  const ZaloMediaGrid({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
    this.senderName = 'Người dùng',
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    final count = mediaUrls.length;
    final gridWidth = (MediaQuery.of(context).size.width * 0.72).clamp(240.0, 320.0);

    // Xây dựng bố cục hàng chuẩn theo Zalo từ 1 đến 10 ảnh/video
    List<List<int>> rowIndices = [];

    if (count == 1) {
      rowIndices = [[0]];
    } else if (count == 2) {
      rowIndices = [[0, 1]];
    } else if (count == 3) {
      rowIndices = [[0, 1], [2]];
    } else if (count == 4) {
      rowIndices = [[0, 1], [2, 3]];
    } else if (count == 5) {
      rowIndices = [[0, 1], [2, 3, 4]];
    } else if (count == 6) {
      rowIndices = [[0, 1, 2], [3, 4, 5]];
    } else if (count == 7) {
      rowIndices = [[0, 1], [2, 3], [4, 5, 6]];
    } else if (count == 8) {
      rowIndices = [[0, 1], [2, 3, 4], [5, 6, 7]];
    } else if (count == 9) {
      rowIndices = [[0, 1, 2], [3, 4, 5], [6, 7, 8]];
    } else {
      // 10 ảnh / video: Đúng 100% hình ảnh thực tế Zalo (2 - 2 - 3 - 3)
      rowIndices = [
        [0, 1],
        [2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ];
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: gridWidth,
        color: Colors.black.withAlpha(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rowIndices.map((row) {
            final isLastRow = row == rowIndices.last;
            final rowHeight = count == 1
                ? 200.0
                : (row.length == 2 ? 115.0 : 88.0);

            return Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : 2.0),
              child: SizedBox(
                height: rowHeight,
                child: Row(
                  children: row.map((idx) {
                    final isLastInRow = idx == row.last;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLastInRow ? 0 : 2.0),
                        child: _buildMediaItem(context, idx),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, int index) {
    final url = mediaUrls[index];
    final isVideo = index < mediaTypes.length && mediaTypes[index] == 'video';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaGalleryViewer(
              mediaUrls: mediaUrls,
              mediaTypes: mediaTypes,
              initialIndex: index,
              title: '$senderName (${index + 1}/${mediaUrls.length})',
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh hoặc Thumbnail video
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFFE2E8F0),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF334155),
              child: Icon(
                isVideo ? Icons.videocam : Icons.broken_image,
                color: Colors.white70,
                size: 32,
              ),
            ),
          ),

          // Nhãn HD hoặc HD | Video ở góc trên bên trái chuẩn Zalo
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isVideo) ...[
                    const Text(
                      ' | 00:14',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Biểu tượng nút Play tròn ở chính giữa nếu là Video chuẩn Zalo
          if (isVideo)
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
