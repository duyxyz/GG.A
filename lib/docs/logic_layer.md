# Lớp Logic (Logic Layer)

Lớp này quản lý trạng thái của ứng dụng và điều phối hoạt động giữa Giao diện và Dữ liệu thông qua các ViewModel.

## ViewModels (`logic/viewmodels/`)
- **app_config_view_model.dart**: 
    - **Công dụng**: Quản lý cài đặt ứng dụng (Theme, màu sắc, haptics).
    - **Nguyên lý**: Sử dụng `ChangeNotifier` để báo hiệu khi cài đổi và lưu trữ bền vững vào `SharedPreferences`.
- **home_view_model.dart**: 
    - **Công dụng**: Viewmodel quan trọng nhất, quản lý danh sách ảnh chính.
    - **Nguyên lý**: 
        - Tải dữ liệu từ cache trước, sau đó mới tải từ mạng để tối ưu tốc độ.
        - Lắng nghe sự kiện Realtime từ `ImageRepository`. Khi có thay đổi trên database, nó sẽ tự động làm mới danh sách ảnh.
        - Quản lý trạng thái `isLoading` và `error` cho toàn bộ trang chủ.
- **update_view_model.dart**: Quản lý trạng thái kiểm tra và cài đặt phiên bản mới của ứng dụng.
