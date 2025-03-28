import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note/utils/markdown_formatter.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final FocusNode? focusNode;

  const MarkdownEditor({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    
    // 監聽文本變化
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // 插入標題
  void _insertHeading(int level) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = selection.baseOffset;
    
    if (cursorPos < 0) return;
    
    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);
    
    // 確定光標是否在行首
    final lastNewLine = beforeCursor.lastIndexOf('\n');
    final isStartOfLine = lastNewLine == beforeCursor.length - 1 || beforeCursor.isEmpty;
    
    // 定位到行首
    final lineStart = isStartOfLine ? cursorPos : lastNewLine + 1;
    final prefix = '#' * level + ' ';
    
    // 生成新文本
    String newText;
    if (isStartOfLine) {
      newText = beforeCursor + prefix + afterCursor;
    } else {
      final beforeLine = text.substring(0, lineStart);
      final currentLine = text.substring(lineStart, cursorPos);
      newText = beforeLine + prefix + currentLine + afterCursor;
    }
    
    // 更新文本
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (isStartOfLine ? cursorPos : lineStart) + prefix.length,
      ),
    );
  }

  // 插入粗體
  void _insertBold() {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.baseOffset == selection.extentOffset) {
      // 無選擇文本，插入佔位符
      final newText = text.replaceRange(selection.baseOffset, selection.baseOffset, '**粗體文字**');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset + 4),
      );
    } else {
      // 選擇了文本，將其加粗
      final selectedText = text.substring(selection.baseOffset, selection.extentOffset);
      final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, '**$selectedText**');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.extentOffset + 4),
      );
    }
  }

  // 插入斜體
  void _insertItalic() {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.baseOffset == selection.extentOffset) {
      // 無選擇文本，插入佔位符
      final newText = text.replaceRange(selection.baseOffset, selection.baseOffset, '*斜體文字*');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
      );
    } else {
      // 選擇了文本，將其變為斜體
      final selectedText = text.substring(selection.baseOffset, selection.extentOffset);
      final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, '*$selectedText*');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.extentOffset + 2),
      );
    }
  }

  // 插入代碼塊
  void _insertCodeBlock() {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.baseOffset == selection.extentOffset) {
      // 無選擇文本，插入空代碼塊
      const codeBlock = '```\n在此輸入代碼\n```';
      final newText = text.replaceRange(selection.baseOffset, selection.baseOffset, codeBlock);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset + 4),
      );
    } else {
      // 將選擇的文本包裹在代碼塊中
      final selectedText = text.substring(selection.baseOffset, selection.extentOffset);
      final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, '```\n$selectedText\n```');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.extentOffset + 6),
      );
    }
  }

  // 插入列表
  void _insertList(bool ordered) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = selection.baseOffset;
    
    if (cursorPos < 0) return;
    
    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);
    
    // 確定光標是否在行首
    final lastNewLine = beforeCursor.lastIndexOf('\n');
    final isStartOfLine = lastNewLine == beforeCursor.length - 1 || beforeCursor.isEmpty;
    
    // 根據列表類型定義前綴
    final prefix = ordered ? '1. ' : '- ';
    
    // 生成新文本
    String newText;
    if (isStartOfLine) {
      newText = beforeCursor + prefix + afterCursor;
    } else {
      newText = beforeCursor + '\n' + prefix + afterCursor;
    }
    
    // 更新文本
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (isStartOfLine ? cursorPos : beforeCursor.length + 1) + prefix.length,
      ),
    );
  }

  // 插入鏈接
  void _insertLink() {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.baseOffset == selection.extentOffset) {
      // 無選擇文本，插入示例鏈接
      final newText = text.replaceRange(selection.baseOffset, selection.baseOffset, '[鏈接文字](https://example.com)');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset + 5),
      );
    } else {
      // 將選擇的文本設置為鏈接文字
      final selectedText = text.substring(selection.baseOffset, selection.extentOffset);
      final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, '[$selectedText](https://example.com)');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.extentOffset + 19),
      );
    }
  }

  // 插入圖片
  void _insertImage() {
    final text = _controller.text;
    final selection = _controller.selection;
    const imageMarkdown = '![圖片說明](https://example.com/image.jpg)';
    
    final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, imageMarkdown);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.baseOffset + 6),
    );
  }

  // 插入表格
  void _insertTable() {
    final text = _controller.text;
    final selection = _controller.selection;
    const tableMarkdown = '| 標題1 | 標題2 | 標題3 |\n| --- | --- | --- |\n| 單元格1 | 單元格2 | 單元格3 |\n| 單元格4 | 單元格5 | 單元格6 |';
    
    final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, tableMarkdown);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.baseOffset + tableMarkdown.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具欄
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  icon: const Text('H1', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _insertHeading(1),
                  tooltip: '標題1',
                ),
                IconButton(
                  icon: const Text('H2', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _insertHeading(2),
                  tooltip: '標題2',
                ),
                IconButton(
                  icon: const Text('H3', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _insertHeading(3),
                  tooltip: '標題3',
                ),
                const VerticalDivider(),
                IconButton(
                  icon: const Icon(Icons.format_bold),
                  onPressed: _insertBold,
                  tooltip: '粗體',
                ),
                IconButton(
                  icon: const Icon(Icons.format_italic),
                  onPressed: _insertItalic,
                  tooltip: '斜體',
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: _insertCodeBlock,
                  tooltip: '代碼塊',
                ),
                const VerticalDivider(),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  onPressed: () => _insertList(false),
                  tooltip: '無序列表',
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_numbered),
                  onPressed: () => _insertList(true),
                  tooltip: '有序列表',
                ),
                const VerticalDivider(),
                IconButton(
                  icon: const Icon(Icons.link),
                  onPressed: _insertLink,
                  tooltip: '鏈接',
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _insertImage,
                  tooltip: '圖片',
                ),
                IconButton(
                  icon: const Icon(Icons.table_chart),
                  onPressed: _insertTable,
                  tooltip: '表格',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 編輯器
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: '使用 Markdown 語法輸入筆記內容...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16.0),
            ),
            style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 16.0),
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ],
    );
  }
}