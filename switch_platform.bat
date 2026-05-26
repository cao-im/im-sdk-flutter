@echo off
echo ============================================
echo   CAO IM SDK - Web Development Switcher
echo ============================================
echo.

REM 检查参数
if "%1"=="web" (
    echo [INFO] 切换到 Web 开发模式...
    echo [INFO] 移除 sqlite3_flutter_libs (Web 不支持 FFI)
    
    REM 备份原文件
    if exist pubspec.yaml.backup (
        del pubspec.yaml.backup
    )
    rename pubspec.yaml pubspec.yaml.backup
    copy pubspec.web.yaml pubspec.yaml
    
    echo.
    echo ✓ 已切换到 Web 模式
    echo   - 使用内存数据库（数据不持久化）
    echo   - 刷新页面后数据会丢失
    echo.
    echo 现在执行: flutter run -d chrome
    goto :end
)

if "%1"=="native" (
    echo [INFO] 切换到原生平台模式...
    echo [INFO] 启用 sqlite3_flutter_libs (完整 SQLite 支持)
    
    REM 恢复原文件
    if exist pubspec.yaml.backup (
        rename pubspec.yaml pubspec.web.yaml
        rename pubspec.yaml.backup pubspec.yaml
        echo.
        echo ✓ 已切换到原生模式
        echo   - iOS/Android/Windows/macOS/Linux
        echo   - 完整 SQLite 功能 + 数据持久化
        echo.
        echo 现在执行: flutter run -d windows (或其他设备)
    ) else (
        echo ✗ 未找到备份文件，可能已经在原生模式
    )
    goto :end
)

echo 用法:
echo   switch_platform web      - 切换到 Web 开发模式
echo   switch_platform native   - 切换回原生平台模式
echo.
echo 示例:
echo   switch_platform web && flutter run -d chrome
echo   switch_platform native && flutter run -d windows

:end
echo.
pause
