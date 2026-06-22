# MoveAttToOutPoly

Lệnh AutoLISP di chuyển attribute của block mốc góc ranh ra ngoài polyline ranh giới.  
AutoLISP command to move attributes of boundary corner marker blocks outside a boundary polyline.

## Mô tả / Description

Với mỗi block mốc góc ranh có insert point nằm trên vertex của polyline, lệnh tính toán hướng ra ngoài tại đỉnh đó và di chuyển attribute ra ngoài polyline một khoảng bằng 2 lần chiều cao text.

For each boundary corner block whose insert point lies on a polyline vertex, the command computes the outward direction at that vertex and moves the attribute outside the polyline by a distance of 2× the text height.

## Yêu cầu / Requirements

- AutoCAD hoặc Civil 3D
- Polyline phải là LWPOLYLINE khép kín / Polyline must be a closed LWPOLYLINE
- Insert point của block phải nằm đúng trên vertex của polyline / Block insert point must lie exactly on a polyline vertex

## Cách dùng / Usage

1. Load file: `APPLOAD` → chọn / select `MoveAttToOutPoly.lsp`
2. Gõ lệnh / Run command: `MoveAttToOutPoly`
3. Chọn LWPOLYLINE ranh khép kín / Select a closed boundary LWPOLYLINE
4. Chọn các block mốc góc ranh / Select the boundary corner blocks
