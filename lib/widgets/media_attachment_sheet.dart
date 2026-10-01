import 'package:flutter/material.dart';

enum AttachmentAction {
  camera,
  gallery,
  document,
  location,
}

class MediaAttachmentSheet extends StatelessWidget {
  final Function(AttachmentAction) onActionSelected;

  const MediaAttachmentSheet({super.key, required this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Wrap(
          spacing: 24,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildActionItem(
              context,
              icon: Icons.camera_alt,
              color: Colors.pink,
              label: 'Chụp ảnh',
              action: AttachmentAction.camera,
            ),
            _buildActionItem(
              context,
              icon: Icons.photo_library,
              color: Colors.purple,
              label: 'Thư viện',
              action: AttachmentAction.gallery,
            ),
            _buildActionItem(
              context,
              icon: Icons.insert_drive_file,
              color: Colors.indigo,
              label: 'Tài liệu',
              action: AttachmentAction.document,
            ),
            _buildActionItem(
              context,
              icon: Icons.location_on,
              color: Colors.green,
              label: 'Vị trí GPS',
              action: AttachmentAction.location,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required AttachmentAction action,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onActionSelected(action);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(40),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
