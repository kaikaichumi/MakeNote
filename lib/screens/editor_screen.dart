import 'package:flutter/material.dart';
import 'package:note/models/note.dart';
import 'package:note/models/category.dart';
import 'package:note/models/tag.dart';
import 'package:note/services/storage_service.dart';
import 'package:note/widgets/markdown_editor.dart';
import 'package:note/widgets/markdown_preview.dart';
import 'dart:async';

class EditorScreen extends StatefulWidget {
  final Note? note;

  const EditorScreen({Key? key, this.note}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late Note _currentNote;
  late TextEditingController _titleController;
  late String _markdownContent;
  bool _isEditing = true;
  bool _isModified = false;
  bool _isSplitView = false;
  bool _isSaving = false;
  final StorageService _storageService = StorageService();
  
  // 自動儲存相關
  Timer? _autoSaveTimer;
  final Duration _autoSaveDuration = const Duration(seconds: 5);
  
  // 類別和標籤相關
  List<Category> _allCategories = [];
  List<Tag> _allTags = [];
  Category? _selectedCategory;
  List<Tag> _selectedTags = [];
  bool _isLoadingMetadata = true;

  @override
  void initState() {
    super.initState();
    _initializeNote();
    _loadCategoriesAndTags();
    _startAutoSaveTimer();
  }

  // 啟動自動儲存計時器
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveDuration, (timer) {
      if (_isModified && !_isSaving) {
        _autoSave();
      }
    });
  }

  // 自動儲存功能
  Future<void> _autoSave() async {
    if (!_isModified || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedNote = _currentNote.copyWith(
        title: _titleController.text,
        content: _markdownContent,
        categoryId: _selectedCategory?.id,
        tagIds: _selectedTags.map((tag) => tag.id).toList(),
      );

      if (widget.note == null) {
        await _storageService.saveNote(updatedNote);
      } else {
        await _storageService.updateNote(updatedNote);
      }

      setState(() {
        _currentNote = updatedNote;
        _isModified = false;
        _isSaving = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已自動儲存'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('自動儲存失敗: $e')),
        );
      }
    }
  }

  // 載入類別和標籤
  Future<void> _loadCategoriesAndTags() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      final categories = await _storageService.getAllCategories();
      final tags = await _storageService.getAllTags();
      
      setState(() {
        _allCategories = categories;
        _allTags = tags;
        
        if (_currentNote.categoryId != null) {
          _selectedCategory = _allCategories
              .where((category) => category.id == _currentNote.categoryId)
              .firstOrNull;
        }
        
        _selectedTags = _allTags.where(
          (tag) => _currentNote.tagIds.contains(tag.id)
        ).toList();
        
        _isLoadingMetadata = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetadata = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入類別和標籤時出錯: $e')),
        );
      }
    }
  }

  // 初始化筆記
  void _initializeNote() {
    if (widget.note != null) {
      _currentNote = widget.note!;
    } else {
      _currentNote = Note(
        title: '未命名筆記',
        content: '',
      );
    }

    _titleController = TextEditingController(text: _currentNote.title);
    _markdownContent = _currentNote.content;

    // 監聽標題變化
    _titleController.addListener(() {
      setState(() {
        _isModified = true;
      });
    });
  }

  // 手動保存筆記
  Future<void> _saveNote() async {
    if (!_isModified) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedNote = _currentNote.copyWith(
        title: _titleController.text,
        content: _markdownContent,
        categoryId: _selectedCategory?.id,
        tagIds: _selectedTags.map((tag) => tag.id).toList(),
      );

      if (widget.note == null) {
        await _storageService.saveNote(updatedNote);
      } else {
        await _storageService.updateNote(updatedNote);
      }

      setState(() {
        _currentNote = updatedNote;
        _isModified = false;
        _isSaving = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('筆記已儲存')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存筆記時出錯: $e')),
        );
      }
    }
  }

  // 切換編輯/預覽模式
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _isSplitView = false; // 切換時關閉雙欄模式
    });
  }

  // 切換雙欄模式
  void _toggleSplitView() {
    setState(() {
      _isSplitView = !_isSplitView;
      if (_isSplitView) {
        _isEditing = true; // 啟用雙欄模式時，編輯模式必須啟用
      }
    });
  }

  // 處理筆記內容變化
  void _handleContentChanged(String newContent) {
    setState(() {
      _markdownContent = newContent;
      _isModified = true;
    });
  }

  // 顯示選擇類別對話框
  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇類別'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 添加一個「無類別」選項
              ListTile(
                title: const Text('無類別'),
                leading: const Icon(Icons.clear),
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _isModified = true;
                  });
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              ..._allCategories.map((category) => ListTile(
                title: Text(category.name),
                leading: CircleAvatar(backgroundColor: category.color),
                selected: _selectedCategory?.id == category.id,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _isModified = true;
                  });
                  Navigator.of(context).pop();
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  // 顯示選擇標籤對話框
  void _showTagDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('選擇標籤'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _allTags.map((tag) => CheckboxListTile(
                title: Text(tag.name),
                secondary: Icon(Icons.label, color: tag.color),
                value: _selectedTags.any((t) => t.id == tag.id),
                onChanged: (selected) {
                  setState(() {
                    if (selected!) {
                      if (!_selectedTags.any((t) => t.id == tag.id)) {
                        _selectedTags.add(tag);
                      }
                    } else {
                      _selectedTags.removeWhere((t) => t.id == tag.id);
                    }
                  });
                  
                  // 更新父 widget 的狀態
                  this.setState(() {
                    _isModified = true;
                  });
                },
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );
  }

  // 顯示保存確認對話框
  Future<bool> _showSaveConfirmDialog() async {
    if (!_isModified) return true;

    // 自動儲存最新內容
    await _autoSave();
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showSaveConfirmDialog,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: '輸入筆記標題',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // 顯示儲存狀態
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            // 類別按鈕
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: _showCategoryDialog,
              tooltip: '選擇類別',
            ),
            // 標籤按鈕
            IconButton(
              icon: const Icon(Icons.label),
              onPressed: _showTagDialog,
              tooltip: '選擇標籤',
            ),
            // 雙欄模式切換按鈕
            IconButton(
              icon: Icon(_isSplitView ? Icons.view_agenda : Icons.view_column),
              onPressed: _toggleSplitView,
              tooltip: _isSplitView ? '單欄模式' : '雙欄模式',
            ),
            // 預覽/編輯切換按鈕 (僅在非雙欄模式下顯示)
            if (!_isSplitView)
              IconButton(
                icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                onPressed: _toggleEditMode,
                tooltip: _isEditing ? '預覽' : '編輯',
              ),
            // 手動儲存按鈕
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: '手動儲存',
            ),
          ],
        ),
        body: Column(
          children: [
            // 類別和標籤顯示區域
            if (_selectedCategory != null || _selectedTags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: Row(
                  children: [
                    if (_selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundColor: _selectedCategory!.color,
                            radius: 8,
                          ),
                          label: Text(_selectedCategory!.name),
                          deleteIcon: const Icon(Icons.clear, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                              _isModified = true;
                            });
                          },
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _selectedTags.map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              avatar: Icon(Icons.label, color: tag.color, size: 18),
                              label: Text(tag.name),
                              deleteIcon: const Icon(Icons.clear, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedTags.remove(tag);
                                  _isModified = true;
                                });
                              },
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 內容區域
            Expanded(
              child: _buildContentArea(),
            ),
          ],
        ),
      ),
    );
  }

  // 構建內容區域
  Widget _buildContentArea() {
    if (_isSplitView) {
      // 雙欄模式：左邊編輯器，右邊預覽
      return Row(
        children: [
          Expanded(
            child: MarkdownEditor(
              initialValue: _markdownContent,
              onChanged: _handleContentChanged,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: MarkdownPreview(
              markdownText: _markdownContent,
            ),
          ),
        ],
      );
    } else {
      // 單欄模式：根據當前模式顯示編輯器或預覽
      return _isEditing
          ? MarkdownEditor(
              initialValue: _markdownContent,
              onChanged: _handleContentChanged,
            )
          : MarkdownPreview(
              markdownText: _markdownContent,
            );
    }
  }
}

// Dart 2.12 後的 firstOrNull 擴展方法
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}