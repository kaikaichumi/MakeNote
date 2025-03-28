import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:note/services/theme_service.dart';
import 'package:note/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autosaveEnabled = true;
  int _autosaveInterval = 5;
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // 外觀設定
          const ListTile(
            title: Text('外觀'),
            subtitle: Text('更改應用程式的視覺風格'),
            leading: Icon(Icons.color_lens),
          ),
          const Divider(),
          // 主題切換
          ListTile(
            title: const Text('主題'),
            subtitle: Text(
              themeService.themeMode == ThemeMode.light
                  ? '亮色主題'
                  : themeService.themeMode == ThemeMode.dark
                      ? '深色主題'
                      : '系統預設',
            ),
            leading: const SizedBox(width: 10),
            onTap: () {
              _showThemeSelectionDialog(themeService);
            },
          ),
          // 黑色背景模式
          SwitchListTile(
            title: const Text('黑色背景'),
            subtitle: const Text('使用純黑色背景（在 OLED 螢幕上節省電力）'),
            value: themeService.useBlackTheme,
            onChanged: (value) {
              themeService.setUseBlackBackground(value);
            },
          ),
          const Divider(),
          // 編輯器設定
          const ListTile(
            title: Text('編輯器'),
            subtitle: Text('調整編輯器的行為和外觀'),
            leading: Icon(Icons.edit),
          ),
          const Divider(),
          // 自動儲存
          SwitchListTile(
            title: const Text('自動儲存'),
            subtitle: const Text('自動儲存編輯內容'),
            value: _autosaveEnabled,
            onChanged: (value) {
              setState(() {
                _autosaveEnabled = value;
              });
              // TODO: 將此值保存到共享偏好設定
            },
          ),
          // 自動儲存間隔
          ListTile(
            title: const Text('自動儲存間隔'),
            subtitle: Text('$_autosaveInterval 秒'),
            enabled: _autosaveEnabled,
            leading: const SizedBox(width: 10),
            onTap: _autosaveEnabled ? _showAutosaveIntervalDialog : null,
          ),
          const Divider(),
          // 資料設定
          const ListTile(
            title: Text('資料'),
            subtitle: Text('管理您的資料'),
            leading: Icon(Icons.storage),
          ),
          const Divider(),
          // 導出備份
          ListTile(
            title: const Text('導出備份'),
            subtitle: const Text('將所有筆記導出為備份文件'),
            leading: const SizedBox(width: 10),
            onTap: () {
              // TODO: 實現導出備份功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('此功能尚未實現')),
              );
            },
          ),
          // 導入備份
          ListTile(
            title: const Text('導入備份'),
            subtitle: const Text('從備份文件還原筆記'),
            leading: const SizedBox(width: 10),
            onTap: () {
              // TODO: 實現導入備份功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('此功能尚未實現')),
              );
            },
          ),
          const Divider(),
          // 關於
          ListTile(
            title: const Text('關於'),
            subtitle: Text('MarkNote ${AppConstants.appVersion}'),
            leading: const Icon(Icons.info),
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  // 顯示主題選擇對話框
  void _showThemeSelectionDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇主題'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('亮色主題'),
              leading: const Icon(Icons.wb_sunny),
              selected: themeService.themeMode == ThemeMode.light,
              onTap: () {
                themeService.setLightMode();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('深色主題'),
              leading: const Icon(Icons.nightlight_round),
              selected: themeService.themeMode == ThemeMode.dark,
              onTap: () {
                themeService.setDarkMode();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('系統預設'),
              leading: const Icon(Icons.settings_system_daydream),
              selected: themeService.themeMode == ThemeMode.system,
              onTap: () {
                themeService.setSystemMode();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 顯示自動儲存間隔對話框
  void _showAutosaveIntervalDialog() {
    final controller = TextEditingController(text: _autosaveInterval.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自動儲存間隔'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '間隔（秒）',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final interval = int.tryParse(controller.text);
              if (interval != null && interval > 0) {
                setState(() {
                  _autosaveInterval = interval;
                });
                // TODO: 保存此值到共享偏好設定
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入有效的數字')),
                );
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // 顯示關於對話框
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'MarkNote',
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const FlutterLogo(size: 64),
      children: [
        const Text('一個簡單而功能豐富的 Markdown 筆記應用程式。'),
        const SizedBox(height: 16),
        const Text('特色：'),
        const SizedBox(height: 8),
        const Text('• Markdown 編輯與預覽'),
        const Text('• 類別和標籤組織'),
        const Text('• 自動儲存功能'),
        const Text('• 黑色主題'),
        const Text('• 本地單機版本'),
      ],
    );
  }
}