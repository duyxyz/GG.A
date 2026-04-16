# Lớp Giao diện (UI Layer)

Chứa các màn hình, tab và các widget tùy chỉnh.

## Màn hình chính (`screens/`)
- **main_screen.dart**: Khung sườn của ứng dụng với Thanh điều hướng (Bottom Navigation) và TabBar. Sử dụng `NestedScrollView` để tạo hiệu ứng Header linh hoạt.
- **image_detail_screen.dart**: Màn hình xem ảnh đơn giản với hiệu ứng chuyển cảnh Hero.

## Các Tab (`tabs/`)
- **home_tab.dart**: Hiển thị lưới ảnh chính sử dụng `SliverMasonryGrid` để tạo bố cục ảnh so le đẹp mắt.
- **favorites_tab.dart**: Lọc và hiển thị các ảnh được người dùng yêu thích.
- **add_tab.dart**: Giao diện chọn ảnh từ điện thoại, nén sang WebP và tải lên hệ thống.
- **settings_tab.dart**: Trang cài đặt cá nhân hóa.

## Widgets tùy chỉnh (`widgets/`)
- **image_grid_item.dart**: Từng ô ảnh trong lưới. Hỗ trợ hiển thị mờ (`Skeleton`) khi đang tải và hiệu ứng Hero khi nhấn vào.
- **full_screen_viewer.dart**: Trình xem ảnh toàn màn hình nâng cao, hỗ trợ phóng to (`Zoom`), vuốt để đóng, tải ảnh về máy và thả tim.
- **expressive_loading_indicator.dart**: Vòng xoay tải dữ liệu đặc trưng của ứng dụng, sử dụng ảnh PNG xoay liên tục.
- **error_view.dart**: Hiển thị khi có lỗi kết nối hoặc dữ liệu.
