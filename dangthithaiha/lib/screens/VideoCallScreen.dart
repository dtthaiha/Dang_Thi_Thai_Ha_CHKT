import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  const VideoCallScreen({super.key, this.channelName = "child_guard_family"});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Điền AppId lấy từ console.agora.io nếu dùng Agora Cloud thật.
  // Khi chưa điền hoặc chạy trên máy ảo, ứng dụng tự động kích hoạt Phòng Gọi Nhóm Gia Đình Trực Quan.
  final String appId = "YOUR_AGORA_APP_ID";
  final List<int> _remoteUids = [];
  bool _localUserJoined = false;
  bool _isAgoraActive = false;
  bool _mutedMic = false;
  bool _mutedCamera = false;
  bool _speakerOn = true;
  late String _currentChannel;
  RtcEngine? _engine;

  // Danh sách thành viên gia đình tham gia gọi nhóm
  final List<Map<String, dynamic>> _familyParticipants = [
    {
      'name': 'Mẹ Thái Hà (Phụ huynh)',
      'role': 'Trưởng nhóm gia đình',
      'icon': Icons.woman,
      'color': Colors.indigo,
      'speaking': true,
    },
    {
      'name': 'Bé Gia Bảo (Lớp 4A)',
      'role': 'Thiết bị con #1',
      'icon': Icons.child_care,
      'color': Colors.teal,
      'speaking': true,
    },
    {
      'name': 'Bố Minh Quân',
      'role': 'Phụ huynh',
      'icon': Icons.man,
      'color': Colors.blueGrey,
      'speaking': false,
    },
    {
      'name': 'Nhân viên Trực ban SOS',
      'role': 'Hỗ trợ kỹ thuật',
      'icon': Icons.support_agent,
      'color': Colors.deepOrange,
      'speaking': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channelName;
    _initAgoraSafe();
  }

  Future<void> _initAgoraSafe() async {
    if (appId == "YOUR_AGORA_APP_ID" || appId.trim().isEmpty) {
      setState(() => _isAgoraActive = false);
      return;
    }

    try {
      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(RtcEngineContext(appId: appId));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted && !_remoteUids.contains(remoteUid)) {
              setState(() => _remoteUids.add(remoteUid));
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (mounted) setState(() => _remoteUids.remove(remoteUid));
          },
        ),
      );

      await engine.enableVideo();
      await engine.startPreview();

      await engine.joinChannel(
        token: '',
        channelId: _currentChannel,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      if (mounted) setState(() => _isAgoraActive = true);
    } catch (e) {
      if (mounted) setState(() => _isAgoraActive = false);
    }
  }

  void _showChangeRoomDialog() {
    final ctrl = TextEditingController(text: _currentChannel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi Phòng Gọi Video Nhóm'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Mã phòng gia đình (Channel ID)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentChannel = ctrl.text.trim().isEmpty ? "child_guard_family" : ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Vào phòng'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2332),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phòng Gọi Video Nhóm Gia Đình', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Kênh: #$_currentChannel • ${_familyParticipants.length} thành viên',
                style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi mã phòng',
            icon: const Icon(Icons.meeting_room_outlined),
            onPressed: _showChangeRoomDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Lưới Video Nhóm (Group Video Grid 2x2)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _isAgoraActive && _engine != null && _remoteUids.isNotEmpty
                  ? GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _remoteUids.length + 1,
                      itemBuilder: (ctx, index) {
                        if (index == 0) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _localUserJoined
                                ? AgoraVideoView(
                                    controller: VideoViewController(
                                      rtcEngine: _engine!,
                                      canvas: const VideoCanvas(uid: 0),
                                    ),
                                  )
                                : const Center(child: CircularProgressIndicator()),
                          );
                        }
                        final rUid = _remoteUids[index - 1];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: _engine!,
                              canvas: VideoCanvas(uid: rUid),
                              connection: RtcConnection(channelId: _currentChannel),
                            ),
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _familyParticipants.length,
                      itemBuilder: (ctx, index) {
                        final p = _familyParticipants[index];
                        final isLocal = index == 0;
                        final bool isSpeaking = p['speaking'] == true;
                        final Color bgColor = p['color'] as Color;

                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [bgColor.withValues(alpha: 0.85), const Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSpeaking ? Colors.greenAccent : Colors.white24,
                              width: isSpeaking ? 2.5 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: isLocal && _mutedCamera
                                    ? const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.videocam_off, size: 48, color: Colors.white54),
                                          SizedBox(height: 6),
                                          Text('Đã tắt Camera', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 36,
                                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                                            child: Icon(p['icon'] as IconData, size: 42, color: Colors.white),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              '● LIVE HD',
                                              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['name'].toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            Text(
                                              p['role'].toString(),
                                              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        (isLocal && _mutedMic) ? Icons.mic_off : Icons.mic,
                                        size: 16,
                                        color: (isLocal && _mutedMic) ? Colors.redAccent : Colors.greenAccent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Thanh điều khiển cuộc gọi Video nhóm
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlBtn(
                  icon: _mutedMic ? Icons.mic_off : Icons.mic,
                  label: _mutedMic ? 'Bật Mic' : 'Tắt Mic',
                  color: _mutedMic ? Colors.redAccent : Colors.white24,
                  onTap: () {
                    setState(() => _mutedMic = !_mutedMic);
                    _engine?.muteLocalAudioStream(_mutedMic);
                  },
                ),
                _buildControlBtn(
                  icon: _mutedCamera ? Icons.videocam_off : Icons.videocam,
                  label: _mutedCamera ? 'Bật Cam' : 'Tắt Cam',
                  color: _mutedCamera ? Colors.redAccent : Colors.white24,
                  onTap: () {
                    setState(() => _mutedCamera = !_mutedCamera);
                    _engine?.muteLocalVideoStream(_mutedCamera);
                  },
                ),
                _buildControlBtn(
                  icon: Icons.cameraswitch,
                  label: 'Đảo Cam',
                  color: Colors.white24,
                  onTap: () {
                    _engine?.switchCamera();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chuyển đổi Camera trước/sau'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                _buildControlBtn(
                  icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                  label: 'Loa ngoài',
                  color: _speakerOn ? Colors.blue : Colors.white24,
                  onTap: () => setState(() => _speakerOn = !_speakerOn),
                ),
                _buildControlBtn(
                  icon: Icons.call_end,
                  label: 'Kết thúc',
                  color: Colors.red,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        ],
      ),
    );
  }
}
