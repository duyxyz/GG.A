# Tiện ích và Công cụ (Utilities)

## `utils/`
- **haptics.dart**: Quản lý phản hồi rung (haptic feedback) tập trung cho ứng dụng, đảm bảo tính nhất quán và tôn trọng cài đặt người dùng.
- **update_manager.dart**: Chứa logic tải về và cài đặt file APK trực tiếp trong ứng dụng.
- **migrate_to_supabase.dart**: Công cụ hỗ trợ chuyển đổi dữ liệu từ file JSON cũ (trên GitHub) sang cơ sở dữ liệu Supabase mới.
- **scroll_behavior.dart**: Tùy chỉnh hành vi cuộn (ví dụ: tắt hiệu ứng co giãn trên Android để giao diện mượt hơn).

## Tệp tin gốc (`main.dart`)
- Điểm khởi đầu của ứng dụng.
- Khởi tạo tất cả các Dependency (Services, Repositories, ViewModels) thông qua lớp `AppDependencies`.
- Cấu hình Theme (Light/Dark) dựa trên cài đặt của người dùng.
