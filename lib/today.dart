import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:woyao_app/today.dart';
import 'initDatabaseCalender.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_slidable/flutter_slidable.dart';

class Today extends StatefulWidget {
  @override
  _TodayState createState() => _TodayState();
}

class _TodayState extends State<Today> {
  List<WoItem> items = [];

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  /// init all items and display them
  Future<void> _initItems() async {
    final dbProvider = DBProvider.instance;
    final allItems = await dbProvider.queryAllWoItem();
    setState(() {
      items = allItems;
    });
  }

  /// init an new item
  Future<void> _addItem() async {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(158, 118, 248, 255),
          title: Text('Add Item'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: "Enter name"),
          ),
          actions: [
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final name = textController.text;
                if (name.isNotEmpty) {
                  final newItem = WoItem(name: name, duringTime: "0", startTime: DateTime.now().toString());
                  await DBProvider.instance.insertWoItem(newItem);
                  Navigator.of(context).pop();
                  _initItems();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(20, 0, 0, 0),
        title: Text("Today' s Item"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
        
      ),
    body: ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Slidable(
          key: ValueKey(item.id),
          startActionPane: ActionPane(
            motion: DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _editItemDuringTime(item),
                backgroundColor: const Color.fromARGB(120, 33, 149, 243),
                icon: Icons.edit,
                label: 'Edit',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _deleteItem(item),
                backgroundColor: const Color.fromARGB(120, 244, 67, 54),
                icon: Icons.delete,
                label: 'Delete',
              ),
              SlidableAction(
                onPressed: (context) => _pickAndSaveImage(item),
                backgroundColor: const Color.fromARGB(120, 76, 175, 79),
                icon: Icons.image,
                label: 'Image',
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              _editItemDuringTime(item);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0), 
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 6, 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                      crossAxisAlignment: CrossAxisAlignment.start, // 文本对齐开始处
                      children: <Widget>[
                        Text(
                          item.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${item.startTime} during: ${item.duringTime}",
                          style: TextStyle(color: Color.fromARGB(255, 17, 123, 119)), // 较淡的字体
                        ),
                      ],
                    ),
                  ),
                  // 图片或空白占位符
                  Expanded(
                    flex: 1, // 分配空间给图片或占位符
                    child: item.imagePath != null && item.imagePath!.isNotEmpty
                        ? Container(
                            width: 50,
                            height: 50,
                            child: Image.file(
                              File(item.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.transparent, // 可以设置为透明或任何背景色
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),

  );
}

  void navigateToTodayPage(BuildContext context, WoItem item) {
    // Navigator.of(context).push(MaterialPageRoute(builder: (context) => Today(item: item)));
  }
  Future<void> _pickAndSaveImage(WoItem item) async {
    final ImagePicker _picker = ImagePicker();
    // 让用户从图库中选择图片。
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // 获取应用文档目录用于保存图片。
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = path.join(appDir.path, path.basename(image.path));
      
      final File newImage = await File(image.path).copy(imagePath);
      
      item.imagePath = newImage.path;
      await DBProvider.instance.updateWoItem(item);

      setState(() {});
    }
  }

  Future<void> _editItemDuringTime(WoItem item) async {
    final TextEditingController textController = TextEditingController(text: item.duringTime);
    final FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(Duration(milliseconds: 100), () {
          focusNode.requestFocus();
          textController.selection = TextSelection(baseOffset: 0, extentOffset: textController.text.length);
        });

        return AlertDialog(
          backgroundColor: Color.fromARGB(158, 118, 248, 255),
          title: Text('Edit during time'),
          content: TextField(
            controller: textController,
            focusNode: focusNode,
            decoration: InputDecoration(hintText: "Edit during time"),
          ),
          actions: [
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final duringTime = textController.text;
                if (duringTime.isNotEmpty && duringTime != item.duringTime) { 
                  item.duringTime = duringTime; 
                  await DBProvider.instance.updateWoItem(item);
                  Navigator.of(context).pop();
                  _initItems();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(WoItem item) async {
    await DBProvider.instance.deleteWoItem(item.id!);
    _initItems();
  }
}
