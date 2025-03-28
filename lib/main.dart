import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:note/screens/home_screen.dart';
import 'package:note/services/theme_service.dart';
import 'package:note/services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 針對不同平台導入不同的窗口工具
import 'window_utils.dart';

void main() async {
  // 確保Flutter綁定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化存儲服務
  await StorageService().initialize();
  
  // 桌面特定設定，僅在非 Web 平台進行
  if (!kIsWeb) {
    initializeWindowSettings();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        // 其他Provider可以在這裡添加
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      title: 'MakeNote',
      debugShowCheckedModeBanner: false,
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.themeMode,
      home: const HomeScreen(),
    );
  }
}