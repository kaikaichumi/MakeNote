import 'package:flutter/material.dart';
import 'package:note/models/note.dart';
import 'package:note/screens/editor_screen.dart';
import 'package:note/screens/settings_screen.dart';
import 'package:note/services/storage_service.dart';
import 'package:note/widgets/note_list.dart';
import 'package:note/widgets/sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<Note> _notes = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // 載入所有筆記
  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _storageService.getAllNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入筆記時出錯: $e')),
        );
      }
    }
  }

  // 創建新筆記
  void _createNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditorScreen(),
      ),
    );
    
    // 返回時重新載入筆記
    _loadNotes();
  }

  // 打開筆記
  void _openNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(note: note),
      ),
    );
    
    // 返回時重新載入筆記
    _loadNotes();
  }

  // 刪除筆記
  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('您確定要刪除筆記 "${note.title}" 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.deleteNote(note.id);
        _loadNotes();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('筆記已刪除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除筆記時出錯: $e')),
          );
        }
      }
    }
  }

  // 添加收藏功能
  Future<void> _toggleFavorite(Note note, bool isFavorite) async {
    final updatedNote = note.copyWith(isFavorite: isFavorite);
    
    try {
      await _storageService.updateNote(updatedNote);
      _loadNotes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite ? '已加入收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新筆記時出錯: $e')),
        );
      }
    }
  }

  // 篩選筆記
  List<Note> _getFilteredNotes() {
    List<Note> filteredNotes = List.from(_notes);
    
    // 根據搜索查詢篩選
    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // 根據側邊欄選擇篩選
    switch (_selectedIndex) {
      case 0: // 所有筆記
        break;
      case 1: // 最近編輯
        filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 2: // 收藏
        filteredNotes = filteredNotes.where((note) => note.isFavorite).toList();
        break;
      case 3: // 已歸檔
        filteredNotes = filteredNotes.where((note) => note.isArchived).toList();
        break;
      default:
        if (_selectedIndex >= 100) {
          // 類別篩選，類別索引為100以上
          final categoryIndex = _selectedIndex - 100;
          // TODO: 實現按類別篩選
        }
        break;
    }
    
    return filteredNotes;
  }

  // 處理側邊欄選擇變化
  void _onSidebarItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 處理搜索查詢變化
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // 打開設定畫面
  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredNotes();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MakeNote'),
        actions: [
          // 搜索框
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: '搜索筆記...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                ),
              ),
            ),
          ),
          // 設定按鈕
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '設定',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // 側邊欄
                if (isDesktop)
                  Sidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onSidebarItemSelected,
                  ),
                // 筆記列表
                Expanded(
                  child: NoteList(
                    notes: filteredNotes,
                    onNoteTap: _openNote,
                    onNoteDelete: _deleteNote,
                    onNoteFavorite: _toggleFavorite,
                  ),
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  _onSidebarItemSelected(index);
                  Navigator.pop(context);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        tooltip: '新建筆記',
        child: const Icon(Icons.add),
      ),
    );
  }
}