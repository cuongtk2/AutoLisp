# SplitScreen — Lệnh AutoCAD chia đôi màn hình

Lệnh AutoLISP `SPLITSCREEN`: tự động đưa **AutoCAD sang nửa trái** màn hình và **File Explorer sang nửa phải**, chỉ bằng 1 lệnh gõ trong command line.

## Tính năng

- Chia đôi màn hình theo tỉ lệ 50/50, không cần kéo thả thủ công.
- Nếu đã có cửa sổ Explorer đang mở → **dùng luôn**, không mở thêm cửa sổ mới.
- Nếu chưa có cửa sổ Explorer nào → tự mở mới.
- Không dùng thư viện ngoài, không cần cài Python hay bất kỳ phần mềm nào — chỉ dùng PowerShell có sẵn trên Windows (7 SP1 trở lên).
- Chạy hoàn toàn ẩn, không có cửa sổ cmd/PowerShell nào nháy lên khi thực thi.
- Chỉ 1 file `.lsp` duy nhất, tự sinh và tự dọn file tạm.

## Cài đặt

1. Tải file [`SplitScreen.lsp`](./SplitScreen.lsp) về máy.
2. Trong AutoCAD, gõ lệnh `APPLOAD` (hoặc `NETLOAD` nếu cần), chọn file `SplitScreen.lsp` và load.
3. (Tuỳ chọn) Thêm file vào **Startup Suite** trong `APPLOAD` để tự động load mỗi khi mở AutoCAD.

## Sử dụng

Gõ lệnh trong command line của AutoCAD:

```
SPLITSCREEN
```

AutoCAD sẽ tự động dời sang nửa trái màn hình, File Explorer dời/mở sang nửa phải.

## Yêu cầu hệ thống

- Windows 7 SP1 trở lên (có PowerShell built-in).
- AutoCAD (bất kỳ phiên bản nào hỗ trợ AutoLISP).
- Không cần quyền Administrator, không cần cài thêm phần mềm nào khác.

## Cách hoạt động

Lệnh sinh ra một file PowerShell tạm (`.ps1`), trong đó nhúng một class C# nhỏ (biên dịch runtime qua `Add-Type`) để gọi các hàm Windows API (`user32.dll`):

- `EnumWindows` / `GetWindowText` — quét toàn bộ cửa sổ đang mở để tìm AutoCAD.
- `GetClassName` — xác định đúng cửa sổ File Explorer thật (`CabinetWClass`), tránh nhầm với cửa sổ Desktop ẩn (`Program Manager`) vốn cũng thuộc process `explorer.exe`.
- `ShowWindow` / `SetWindowPos` — khôi phục kích thước và di chuyển cửa sổ về đúng nửa màn hình mong muốn.

Script này được gọi qua đối tượng COM `WScript.Shell` với chế độ cửa sổ ẩn (`0`), nên không có bất kỳ cửa sổ console nào xuất hiện trong lúc chạy. File `.ps1` tạm được tự động xoá sau khi thực thi xong.

## Giới hạn đã biết

- Nhận diện cửa sổ AutoCAD dựa trên tiêu đề chứa từ khoá `autocad` hoặc `autodesk` (không phân biệt hoa/thường). Nếu tiêu đề cửa sổ AutoCAD của bạn không chứa các từ này (một số bản build/localize đặc biệt), lệnh có thể không nhận diện được.
- Chỉ hỗ trợ chia 2 cửa sổ theo chiều ngang (trái/phải), tỉ lệ cố định 50/50.
- Đã test trên các máy đơn màn hình; với hệ thống nhiều màn hình, kết quả có thể cần điều chỉnh thêm.

## Giấy phép

Tự do sử dụng, chỉnh sửa, và phân phối lại.