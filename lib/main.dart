import 'package:flutter/material.dart';
import 'package:inputkeyboard/input_keyboard_field.dart';
import 'package:keyboard_utils/keyboard_listener.dart';
import 'package:keyboard_utils/keyboard_utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Input Keyboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Input Keyboard Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _controller = ScrollController();
  final KeyboardUtils _keyboardUtils = KeyboardUtils();
  final List<InputKeyboardField> inputKeyboardFields =
      List.generate(8, (index) => InputKeyboardField());

  ///记录上一次滚动偏移量
  double _lastOffset = 0;
  int _idKeyboardListener;
  double _keyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _initKeyboardListener();
    _initFocusNodeListener();
  }

  void _initFocusNodeListener() {
    inputKeyboardFields.forEach((field) {
      field.focusNode.addListener(() {
        if (field.focusNode.hasFocus) {
          _jumpTo(_keyboardHeight);
        }
      });
    });
  }

  void _initKeyboardListener() {
    _idKeyboardListener = _keyboardUtils.add(
        listener: KeyboardListener(willHideKeyboard: () {
      setState(() {
        _keyboardHeight = 0;
      });
      //滚动到上次偏移位置
      _controller.jumpTo(_lastOffset);
    }, willShowKeyboard: (double keyboardHeight) {
      setState(() {
        _keyboardHeight = keyboardHeight;
      });
      _jumpTo(keyboardHeight);
    }));
  }

  void _jumpTo(double keyboardHeight) {
    GlobalKey currentKey = inputKeyboardFields
        .where((field) => field.focusNode.hasFocus)
        .single
        .key;
    if (currentKey == null) return;
    var screenHeight = MediaQuery.of(context).size.height;
    RenderBox renderBox = currentKey.currentContext.findRenderObject();
    var offset = renderBox.localToGlobal(Offset(0.0, renderBox.size.height));
    var distance = offset.dy - (screenHeight - _keyboardHeight);
    _lastOffset = _controller.offset;
    if (distance > 0) {
      _controller.jumpTo(_controller.offset + distance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          controller: _controller,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
              maxHeight: MediaQuery.of(context).size.height + _keyboardHeight,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 40,
                  left: 40,
                  child: Text("键盘遮挡输入框解决方案演示", style: TextStyle(fontSize: 24),),
                ),
              ]..addAll(inputKeyboardFields
                  .asMap()
                  .map((index, field) {
                    return MapEntry(
                        index,
                        buildPositionedTextField(context, 120.0 + index * 70,
                            "labelText$index", field.focusNode, field.key));
                  })
                  .values
                  .toList()),
            ),
          ),
        ));
  }

  Positioned buildPositionedTextField(
    BuildContext context,
    double top,
    String labelText,
    FocusNode focusNode,
    GlobalKey key,
  ) {
    return Positioned(
      top: top,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: TextField(
          decoration: InputDecoration(
            labelText: labelText,
          ),
          focusNode: focusNode,
          key: key,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _disposeKeyboard();
    _disposeFocusNode();
  }

  void _disposeFocusNode() {
    inputKeyboardFields.forEach((field) {
      field.focusNode.dispose();
    });
  }

  void _disposeKeyboard() {
    _keyboardUtils.unsubscribeListener(subscribingId: _idKeyboardListener);
    if (_keyboardUtils.canCallDispose()) {
      _keyboardUtils.dispose();
    }
  }
}
