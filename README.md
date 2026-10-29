# Quản Lý Sao Kê Chứng Khoán & Lãi Lỗ (Stock PnL Tracker)

Ứng dụng Flutter đa nền tảng (hỗ trợ **iOS** và **Web**) giúp quản lý sao kê các lệnh mua/bán cổ phiếu, tự động tính giá vốn bình quân gia quyền, theo dõi lãi lỗ tạm tính (Unrealized P&L), lãi lỗ đã chốt (Realized P&L) và import/export dữ liệu sao kê.

---

## 🚀 Hướng Dẫn Chạy & Test

### 1. Chạy trên Web (Dùng thử ngay trên trình duyệt Chrome/Edge)
Chạy lệnh sau tại thư mục dự án:
```bash
flutter run -d chrome
```
Hoặc test trên Microsoft Edge:
```bash
flutter run -d edge
```

Build gói Web tĩnh (Deploy lên GitHub Pages, Vercel hoặc Firebase Hosting):
```bash
flutter build web --release
```
Thư mục xuất kết quả: `build/web/`.

---

### 2. Cài đặt và Chạy trên iOS

#### Yêu cầu:
- Máy Mac cài đặt **macOS** và **Xcode** (hoặc dùng CI/CD như Codemagic, GitHub Actions nếu build từ Windows).
- CocoaPods (`sudo gem install cocoapods`).

#### Các bước cài đặt:
1. Mở Terminal trên Mac, di chuyển vào thư mục dự án:
   ```bash
   cd projectSaoKeCK/ios
   pod install
   cd ..
   ```
2. Chạy trên máy ảo iOS Simulator:
   ```bash
   flutter run -d "iPhone 16"
   ```
3. Cài trực tiếp lên iPhone thật:
   - Cắm cáp iPhone vào Mac.
   - Mở file `ios/Runner.xcworkspace` trong Xcode.
   - Chọn mục **Signing & Capabilities** -> Đăng nhập tài khoản Apple ID cá nhân (miễn phí) và chọn **Team**.
   - Chọn thiết bị iPhone của bạn ở thanh trên cùng và bấm nút **Run (Play)** để cài trực tiếp vào máy.
4. Xuất file `.ipa` / TestFlight:
   ```bash
   flutter build ipa
   ```

---

## 📈 Logic Nghiệp Vụ & Công Thức Tính Toán

1. **Giá vốn bình quân gia quyền (Weighted Average Cost):**
   - Khi Mua: $\text{Giá vốn mới} = \frac{(\text{Vốn cũ} \times \text{SL cũ}) + (\text{Giá mua} \times \text{SL mua}) + \text{Phí mua}}{\text{SL cũ} + \text{SL mua}}$
   - Nhận cổ tức cổ phiếu / CP thưởng: Tăng số lượng CP, tổng giá vốn không đổi $\rightarrow$ Giá vốn tự động pha loãng giảm xuống.
2. **Lãi / Lỗ đã chốt (Realized P&L khi Bán):**
   - $\text{Lãi ròng} = (\text{Giá bán} \times \text{SL}) - (\text{Giá vốn TB} \times \text{SL}) - \text{Phí bán} - \text{Thuế TNCN (0.1\%)}$
3. **Lãi / Lỗ tạm tính (Unrealized P&L hàng đang giữ):**
   - $\text{Lãi tạm tính} = (\text{Giá thị trường} - \text{Giá vốn TB}) \times \text{SL đang giữ}$

---

## 📂 Cấu Trúc Dự Án
```
lib/
├── models/
│   ├── transaction.dart          # Dữ liệu 1 giao dịch sao kê (Mua, Bán, Cổ tức...)
│   ├── holding_stock.dart        # Dữ liệu mã cổ phiếu đang nắm giữ
│   ├── closed_trade.dart         # Lịch sử các lệnh bán đã chốt lãi/lỗ
│   └── portfolio_summary.dart    # Thống kê tổng tài sản, tỷ lệ thắng
├── services/
│   ├── pnl_calculator.dart       # Engine tính toán lãi/lỗ tài chính
│   └── storage_service.dart      # Lưu trữ Local (SharedPreferences) & CSV Parser
├── providers/
│   └── portfolio_provider.dart   # Quản lý State bằng Riverpod
├── utils/
│   └── formatters.dart           # Format tiền VNĐ, %, ngày tháng & màu PnL
├── widgets/
│   ├── responsive_scaffold.dart  # Bố cục tự thích ứng Responsive cho iOS & Web
│   ├── transaction_dialog.dart   # Modal Thêm / Chỉnh sửa sao kê
│   └── update_price_dialog.dart  # Hộp thoại cập nhật giá thị trường nhanh
└── screens/
    ├── dashboard_screen.dart     # Tab 1: Tổng quan tài sản & biểu đồ tròn
    ├── holdings_screen.dart      # Tab 2: Danh mục cổ phiếu đang nắm giữ
    ├── transactions_screen.dart  # Tab 3: Lịch sử sao kê giao dịch & bộ lọc
    ├── closed_trades_screen.dart # Tab 4: Thống kê hiệu suất chốt lời / cắt lỗ
    └── settings_screen.dart      # Tab 5: Import/Export CSV, cài đặt dữ liệu
```
