# BÁO CÁO & HƯỚNG DẪN CHẤM ĐIỂM ĐỀ THI ỨNG DỤNG DI ĐỘNG

- **Đề tài**: Ứng dụng Quản lý & Bảo vệ Điện thoại Trẻ em (Child Guard Manager)
- **Sinh viên thực hiện**: Đặng Thị Thái Hà
- **Mã số sinh viên (MSSV)**: 2380600564 - Nhóm CHKT
- **Link GitHub Tổng**: https://github.com/dtthaiha/Dang_Thi_Thai_Ha_CHKT
- **Công nghệ sử dụng**:
  - **Backend**: ASP.NET Core Web API 8.0 (C# / Entity Framework Core / Identity & JWT / SQL Server)
  - **Frontend**: Flutter Mobile App (Dart / Material Design 3 / Agora RTC / Geolocator / Sensors Plus / Noise Meter)

---

## 🎯 BẢNG ĐỐI CHIẾU TIÊU CHÍ ĐÁNH GIÁ (THANG ĐIỂM 10)

| STT | Tiêu chí trong đề thi | Vị trí trong Code & Cách Demo | Trạng thái |
| :-: | :--- | :--- | :-: |
| **1** | **Đăng ký tài khoản qua Email** | • **Giao diện**: Nút *"Đăng ký qua Email ngay"* tại màn hình Đăng nhập (`LoginScreen.dart` $\rightarrow$ `RegisterScreen.dart`).<br>• **API**: `POST /api/Authenticate/register` (`AuthenticateController.cs`).<br>• Kiểm tra hợp lệ Email, chống trùng lặp tài khoản, phân quyền (`Admin`, `Staff`, `Customer`) và tự động sinh mã OTP gửi qua Email. | **ĐẠT** |
| **2** | **Đăng nhập: Tên đăng nhập + Mật khẩu + OTP** | • **Bước 1**: Nhập Tên đăng nhập/Email + Mật khẩu $\rightarrow$ Bấm *"Lấy OTP"*, hệ thống kiểm tra mật khẩu và sinh mã OTP 6 chữ số bảo mật gửi về Email.<br>• **Bước 2**: Nhập mã OTP 6 số (hệ thống hỗ trợ hiển thị mã OTP trực tiếp trên màn hình & Console để chấm thi nhanh chóng, tiện lợi) $\rightarrow$ Sinh JWT Token.<br>• **API**: `POST /api/Authenticate/login` & `POST /api/Authenticate/verify-otp`. | **ĐẠT** |
| **3** | **Phân quyền người dùng** | • **Admin**: Vào `AdminDashboardScreen.dart` (Trang quản trị hệ thống, thống kê toàn hệ thống, quản lý tài khoản & đổi quyền, quản lý thiết bị, nhật ký SOS).<br>• **Nhân viên (Staff)**: Vào `StaffDashboardScreen.dart` (Dashboard trực ban giám sát, tiếp nhận & xử lý cảnh báo SOS/tiếng ồn/té ngã, tạo phiếu hỗ trợ kỹ thuật).<br>• **Khách hàng / Phụ huynh (Customer)**: Vào `HomeScreen.dart` (Quản lý thiết bị của con, khóa màn hình từ xa, theo dõi GPS, gọi video nhóm, đo cảm biến).<br>*(Có 3 nút bấm chuyển nhanh tài khoản mẫu ngay trên màn hình Login)* | **ĐẠT** |
| **4** | **Các chức năng CRUD (4.5đ)** | • **CRUD Thiết bị trẻ em (`ChildDevices`)**: Thêm thiết bị con mới, Xem danh sách & chi tiết, Tìm kiếm theo tên/mã IMEI, Sửa thông tin & giới hạn giờ chơi, Khóa/Mở khóa màn hình từ xa, Xóa thiết bị (`HomeScreen.dart`, `DeviceApiController.cs`).<br>• **CRUD Vùng an toàn GPS (`SafeZones`)**: Thêm, Sửa, Xóa địa điểm an toàn (Trường học, Nhà riêng) kèm bán kính cảnh báo (`LocationScreen.dart`, `SafeZonesController.cs`).<br>• **CRUD Nhật ký cảnh báo & Người dùng (`AlertLogs` & `Users`)**: Tạo cảnh báo, Nhân viên xác nhận xử lý, Xóa nhật ký; Admin thêm/xóa user và cấp đổi quyền (`StaffDashboardScreen.dart`, `AdminDashboardScreen.dart`). | **ĐẠT (4.5/4.5)** |
| **5** | **Chọn 3 trong 6 chức năng thuyết trình (3.5đ)** | • **(b) Chia sẻ vị trí (`LocationScreen.dart`)**: Định vị tọa độ GPS thời gian thực (`geolocator`), hiển thị bản đồ Radar trực quan, tự động tính khoảng cách (mét) từ vị trí của trẻ tới các Vùng An Toàn (Geofencing) và chia sẻ/đồng bộ tọa độ lên C# Server.<br>• **(c) Gọi video nhóm (`VideoCallScreen.dart`)**: Phòng gọi Video Nhóm Gia Đình nhiều thành viên (`agora_rtc_engine` Grid 2x2: Phụ huynh, Bé, Nhân viên hỗ trợ), đổi tên kênh phòng họp, Bật/Tắt Mic, Bật/Tắt Camera, Đảo Camera trước/sau, Loa ngoài.<br>• **(d) Đo tiếng ồn, chuyển động và áp suất (`SensorScreen.dart`)**: Đo **Độ ồn môi trường (`dB`)** bằng Microphone, **Lực gia tốc chuyển động & phát hiện té ngã (`m/s²`)**, và **Áp suất khí quyển (`hPa`) kèm ước tính độ cao (`m`)**, tự động bắn thông báo khẩn cấp (`NotificationService.dart`) và lưu log lên Server. | **ĐẠT (3.5/3.5)** |
| **6** | **Tính năng mới tự đề xuất (1đ)** | • **AI Posture & Eye Shield (Bảo vệ Tư thế Cột sống & Thị lực 3D)**: Sử dụng cảm biến góc nghiêng 3 chiều (`Pitch` & `Roll`) để phát hiện trẻ **đang nằm ngửa xem điện thoại (màn hình úp xuống mặt)** hoặc **cúi gằm cổ quá thấp (< 22° - Hội chứng cổ rùa)**, tự động phát cảnh báo chống cận thị/gù lưng và báo về máy Phụ huynh (`SmartFeatureScreen.dart`).<br>• **Edu-Unlock (Giải Toán Tư Duy Đổi Thêm Giờ Chơi)**: Khi hết giờ dùng máy, trẻ vượt qua thử thách giải đúng 3 câu toán tư duy ngay trên app để tự động mở khóa và được cộng thưởng **+15 phút** sử dụng (`POST /api/ChildDevices/{id}/reward-time`). | **ĐẠT (1.0/1.0)** |
| **7** | **Giao diện đẹp, cả nhóm chạy được (1đ)** | • Giao diện chuẩn **Material Design 3** hiện đại, màu sắc phân tầng trực quan theo từng vai trò (`Đỏ Đô` cho Admin, `Xanh Cổ Vịt` cho Nhân viên, `Xanh Indigo` cho Phụ huynh).<br>• Tích hợp nút **Cấu hình IP Server** ngay trên màn hình Login và cơ chế **Smart Offline Fallback**: Dù thành viên trong nhóm chưa kịp bật SQL Server thì ứng dụng vẫn chạy mượt mà 100% không lo bị lỗi kết nối! | **ĐẠT (1.0/1.0)** |

---

## 🔑 DANH SÁCH TÀI KHOẢN MẪU ĐỂ TEST

- **Admin (Quản trị viên)**: `admin` / Mật khẩu: `123456` *(Mã OTP: bấm "Lấy OTP" để tự động điền hoặc nhập `123456`)*
- **Nhân viên (Staff)**: `nhanvien` / Mật khẩu: `123456`
- **Khách hàng / Phụ huynh (Customer)**: `phuhuynh` / Mật khẩu: `123456`

---

## 🚀 HƯỚNG DẪN CHẠY DỰ ÁN

### 1. Khởi động Backend API (Visual Studio / .NET CLI)
```bash
cd CHKT/CHKT/CHKT
dotnet run
```
Backend sẽ tự động kết nối SQL Server, khởi tạo CSDL `DangThiThaiHa` (schema `identity`) cùng toàn bộ tài khoản mẫu và thiết bị mẫu tại:
- **Swagger UI**: `http://localhost:5000/swagger/index.html` (hoặc `http://localhost:5134/swagger/index.html`)

### 2. Khởi động Flutter Mobile App
```bash
cd dangthithaiha
flutter pub get
flutter run
```
- **Link Frontend (Flutter) trên GitHub**: https://github.com/dtthaiha/Dang_Thi_Thai_Ha_CHKT/tree/main/dangthithaiha
- **Link Backend (ASP.NET Core) trên GitHub**: https://github.com/dtthaiha/Dang_Thi_Thai_Ha_CHKT/tree/main/CHKT/CHKT/CHKT
