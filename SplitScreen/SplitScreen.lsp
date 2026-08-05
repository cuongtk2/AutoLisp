;;; ---------------------------------------------------------------------
;;; Chia doi man hinh chong bat lai (AutoCAD trai, Explorer phai)
;;; Dung PowerShell (co san tren Windows) -> khong can cai them gi
;;; Neu da co cua so Explorer -> dung luon, khong tao moi
;;; Chay an hoan toan, khong nhay cua so PowerShell/cmd
;;; ---------------------------------------------------------------------

(vl-load-com)

(defun bp:powershell-split-script-string ()
  (strcat
    "Add-Type @\"\n"
    "using System;\n"
    "using System.Text;\n"
    "using System.Runtime.InteropServices;\n"
    "using System.Collections.Generic;\n"
    "public class WinTool {\n"
    "    [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);\n"
    "    [DllImport(\"user32.dll\")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);\n"
    "    [DllImport(\"user32.dll\")] public static extern bool IsWindowVisible(IntPtr hWnd);\n"
    "    [DllImport(\"user32.dll\")] public static extern int GetWindowTextLength(IntPtr hWnd);\n"
    "    [DllImport(\"user32.dll\")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);\n"
    "    [DllImport(\"user32.dll\")] public static extern int GetSystemMetrics(int nIndex);\n"
    "    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);\n"
    "    [DllImport(\"user32.dll\")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);\n"
    "    [DllImport(\"user32.dll\")] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);\n"
    "\n"
    "    public static IntPtr FindByKeyword(string keyword) {\n"
    "        IntPtr result = IntPtr.Zero;\n"
    "        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {\n"
    "            if (IsWindowVisible(hWnd)) {\n"
    "                int len = GetWindowTextLength(hWnd);\n"
    "                if (len > 0) {\n"
    "                    StringBuilder sb = new StringBuilder(len + 1);\n"
    "                    GetWindowText(hWnd, sb, sb.Capacity);\n"
    "                    string title = sb.ToString().ToLower();\n"
    "                    if (title.Contains(keyword)) {\n"
    "                        result = hWnd;\n"
    "                        return false;\n"
    "                    }\n"
    "                }\n"
    "            }\n"
    "            return true;\n"
    "        }, IntPtr.Zero);\n"
    "        return result;\n"
    "    }\n"
    "\n"
    "    // Lay danh sach cua so Explorer THAT SU (class \"CabinetWClass\"), khong\n"
    "    // tinh nham cua so Desktop (\"Program Manager\") - cung thuoc process\n"
    "    // explorer.exe nhung khong phai cua so duyet file.\n"
    "    public static List<IntPtr> ListExplorerWindows() {\n"
    "        List<IntPtr> list = new List<IntPtr>();\n"
    "        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {\n"
    "            if (IsWindowVisible(hWnd) && GetWindowTextLength(hWnd) > 0) {\n"
    "                StringBuilder cls = new StringBuilder(256);\n"
    "                GetClassName(hWnd, cls, cls.Capacity);\n"
    "                if (cls.ToString() == \"CabinetWClass\") {\n"
    "                    list.Add(hWnd);\n"
    "                }\n"
    "            }\n"
    "            return true;\n"
    "        }, IntPtr.Zero);\n"
    "        return list;\n"
    "    }\n"
    "}\n"
    "\"@\n"
    "\n"
    "$SW_RESTORE     = 9\n"
    "$SWP_NOZORDER   = 0x0004\n"
    "$SWP_NOACTIVATE = 0x0010\n"
    "$flags          = $SWP_NOZORDER -bor $SWP_NOACTIVATE\n"
    "\n"
    "$screenW = [WinTool]::GetSystemMetrics(0)\n"
    "$screenH = [WinTool]::GetSystemMetrics(1)\n"
    "$halfW   = [int]($screenW / 2)\n"
    "\n"
    "# 1. AutoCAD sang trai\n"
    "$acadHwnd = [WinTool]::FindByKeyword('autocad')\n"
    "if ($acadHwnd -eq [IntPtr]::Zero) { $acadHwnd = [WinTool]::FindByKeyword('autodesk') }\n"
    "if ($acadHwnd -ne [IntPtr]::Zero) {\n"
    "    [WinTool]::ShowWindow($acadHwnd, $SW_RESTORE)\n"
    "    Start-Sleep -Milliseconds 100\n"
    "    [WinTool]::SetWindowPos($acadHwnd, [IntPtr]::Zero, 0, 0, $halfW, $screenH, $flags)\n"
    "}\n"
    "\n"
    "# 2. Kiem tra xem da co san cua so Explorer (that su, khong tinh Desktop) chua\n"
    "$existing = [WinTool]::ListExplorerWindows()\n"
    "\n"
    "if ($existing.Count -gt 0) {\n"
    "    # Da co san -> dung luon cua so dau tien tim thay, khong tao moi\n"
    "    $expHwnd = $existing[0]\n"
    "}\n"
    "else {\n"
    "    # Chua co cua so nao -> mo moi\n"
    "    Start-Process explorer.exe\n"
    "    Start-Sleep -Milliseconds 1000\n"
    "    $after = [WinTool]::ListExplorerWindows()\n"
    "    $expHwnd = if ($after.Count -gt 0) { $after[0] } else { $null }\n"
    "}\n"
    "\n"
    "# 3. Explorer sang phai\n"
    "if ($expHwnd) {\n"
    "    [WinTool]::ShowWindow($expHwnd, $SW_RESTORE)\n"
    "    Start-Sleep -Milliseconds 100\n"
    "    [WinTool]::SetWindowPos($expHwnd, [IntPtr]::Zero, $halfW, 0, $halfW, $screenH, $flags)\n"
    "}\n"
  )
)

(defun bp:write-split-temp-file ( / psfile f)
  (setq psfile (vl-filename-mktemp "splitscreen" nil ".ps1"))
  (setq f (open psfile "w"))
  (write-line (bp:powershell-split-script-string) f)
  (close f)
  psfile
)

(defun c:SPLITSCREEN ( / psFile shell cmd)
  (setq psFile (bp:write-split-temp-file))
  (if psFile
    (progn
      (setq cmd (strcat
        "powershell -NoProfile -NoLogo -WindowStyle Hidden -ExecutionPolicy Bypass -File \""
        psFile "\""
      ))
      ;; Dung WScript.Shell.Run voi window-style = 0 (an hoan toan, khong
      ;; nhay cua so du chi 1 khung hinh) thay vi startapp qua cmd.exe
      (setq shell (vlax-create-object "WScript.Shell"))
      (vlax-invoke-method shell 'Run cmd 0 :vlax-false)
      (vlax-release-object shell)
      (princ "\nDang phan chia man hinh...")
      (vl-cmdf "_.delay" 2500)
      (if (findfile psFile) (vl-file-delete psFile))
    )
    (princ "\nKhong the khoi tao tien trinh chia man hinh.")
  )
  (princ)
)

(princ "\nDa nap lenh SPLITSCREEN (dung PowerShell, tu dong nhan dien Explorer da mo).")
(princ)