import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/auth_screen.dart';
import 'package:message_app/model/chat_model.dart';
import 'package:message_app/providers/room_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Hàm xử lý đăng xuất
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Xóa cờ trạng thái đăng nhập
    await prefs.setBool('userLoggedIn', false);
    // Bạn cũng có thể muốn xóa các dữ liệu người dùng khác đã lưu trữ
    // await prefs.remove('userToken'); // Ví dụ

    // Điều hướng trở lại màn hình AuthScreen và xóa tất cả các màn hình trước đó khỏi stack
    if (mounted) {
      // Kiểm tra xem widget còn trong cây widget không
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) =>
            false, // Điều kiện này xóa tất cả các route trước đó
      );
    }
  }

  // ...existing code...
  // Thêm RoomProvider
  final TextEditingController _roomNameController = TextEditingController();
  RoomType _selectedType = RoomType.public;
  // Để demo, tạo provider tại đây. Khi triển khai thực tế, dùng Provider package.
  final roomProvider = RoomProvider();

  String _userId = 'user_demo'; // Thay bằng userId thực tế

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng cộng đồng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(hintText: 'Tên phòng'),
                  ),
                ),
                DropdownButton<RoomType>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: RoomType.public,
                      child: Text('Public'),
                    ),
                    DropdownMenuItem(
                      value: RoomType.private,
                      child: Text('Private'),
                    ),
                  ],
                  onChanged: (type) {
                    if (type != null) setState(() => _selectedType = type);
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_roomNameController.text.trim().isNotEmpty) {
                      roomProvider.createRoom(
                        name: _roomNameController.text.trim(),
                        type: _selectedType,
                        members: _selectedType == RoomType.private
                            ? [_userId]
                            : [],
                      );
                      _roomNameController.clear();
                      setState(() {});
                    }
                  },
                  child: const Text('Tạo phòng'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: roomProvider.rooms.length,
              itemBuilder: (context, index) {
                final room = roomProvider.rooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(room.name[0].toUpperCase()),
                  ),
                  title: Text(room.name),
                  subtitle: Text(
                    room.type == RoomType.public ? 'Public' : 'Private',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final canJoin = roomProvider.joinRoom(room.id, _userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            canJoin
                                ? 'Tham gia phòng thành công!'
                                : 'Bạn không có quyền vào phòng này!',
                          ),
                        ),
                      );
                    },
                    child: const Text('Tham gia'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
