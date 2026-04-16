# Lớp Dữ liệu (Data Layer)

Lớp này chịu trách nhiệm giao tiếp với các nguồn dữ liệu bên ngoài (GitHub, Supabase) và định nghĩa các mô hình dữ liệu.

## Models (`data/models/`)
- **app_release.dart**: Định nghĩa thông tin một bản cập nhật ứng dụng từ GitHub (version, link download).
- **gallery_image.dart**: Mô hình dữ liệu cho một bức ảnh (tên, SHA, kích thước, tỷ lệ khung hình, URL). Chứa logic phân tách số thứ tự (`index`) từ tên file.

## Services (`data/services/`)
- **github_api_service.dart**:
    - **Công dụng**: Giao tiếp với GitHub API.
    - **Nguyên lý**: Sử dụng `http` để thực hiện các lệnh: `PUT` (tải ảnh lên), `DELETE` (xóa ảnh), `GET` (lấy danh sách file và phiên bản mới nhất).
- **supabase_api_service.dart**:
    - **Công dụng**: Giao tiếp với Supabase.
    - **Nguyên lý**: Sử dụng `supabase_flutter` để truy vấn metadata, thực hiện RPC `reserve_next_image_index` và lắng nghe stream dữ liệu thời gian thực.

## Repositories (`data/repositories/`)
- **image_repository.dart**: 
    - **Công dụng**: Cầu nối giữa giao diện và các dịch vụ ảnh.
    - **Nguyên lý**: Kết hợp dữ liệu từ Supabase (metadata) và GitHub (file ảnh). Quản lý bộ nhớ đệm (cache) bằng SharedPreferences để ứng dụng hiện ảnh nhanh khi vừa mở.
- **update_repository.dart**: Quản lý việc kiểm tra và tải về các bản cập nhật ứng dụng.
