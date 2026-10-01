import 'package:flutter/material.dart';
import '../../services/security_service.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _readReceipts = true;
  bool _lastSeen = true;
  final SecurityService _security = SecurityService();

  void _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bộ nhớ đệm (Cache)?'),
        content: const Text('Thao tác này sẽ xóa các tệp tin tạm, ảnh thumbnail và giải phóng bộ nhớ trên thiết bị này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _security.clearLocalCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã dọn dẹp bộ nhớ đệm thành công!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền Riêng Tư & Bảo Mật')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'MÃ HÓA & BẢO VỆ DỮ LIỆU',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline, color: Colors.green),
            title: Text('Mã Hóa Đầu Cuối (E2EE)'),
            subtitle: Text('Tin nhắn được mã hóa phía máy khách bằng AES-256 trước khi gửi đi.'),
            trailing: Icon(Icons.verified, color: Colors.green, size: 20),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'QUYỀN RIÊNG TƯ CÁ NHÂN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            value: _lastSeen,
            onChanged: (val) => setState(() => _lastSeen = val),
            title: const Text('Trạng Thái Hoạt Động (Last Seen)'),
            subtitle: const Text('Cho phép bạn bè thấy thời điểm bạn online gần nhất'),
          ),
          SwitchListTile(
            value: _readReceipts,
            onChanged: (val) => setState(() => _readReceipts = val),
            title: const Text('Thông Báo Đã Đọc (Đánh dấu tích xanh)'),
            subtitle: const Text('Hiện dấu tích xanh khi bạn đã đọc tin nhắn của người khác'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'KIỂM SOÁT DỮ LIỆU THIẾT BỊ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orangeAccent),
            title: const Text('Dọn Dẹp Bộ Nhớ Đệm'),
            subtitle: const Text('Giải phóng dung lượng ổ đĩa và xóa tệp tạm trên máy'),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }
}
