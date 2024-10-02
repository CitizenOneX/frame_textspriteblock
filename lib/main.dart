import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:simple_frame_app/simple_frame_app.dart';
import 'package:simple_frame_app/tx/text_sprite.dart';


void main() => runApp(const MainApp());

final _log = Logger("MainApp");

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

/// SimpleFrameAppState mixin helps to manage the lifecycle of the Frame connection outside of this file
class MainAppState extends State<MainApp> with SimpleFrameAppState {

  // Display image
  final List<Image> _images = [];

  MainAppState() {
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: [${record.loggerName}] ${record.time}: ${record.message}');
    });
  }

  @override
  Future<void> run() async {
    _log.info('Starting run()');
    currentState = ApplicationState.running;
    if (mounted) setState(() {});

    try {
        // some sample text
        String inputString = 'Hello, friend!\nمرحبا يا صديق\nこんにちは、友人！\n朋友你好！\nПривет, друг!\nשלום, חבר\n안녕, 친구!';

        // TODO do I really want to specify displayRows? I just render and send all the lines - let the frame_app decide how many to render
        // TODO I still want to have phoneside pagination though, so maybe both need to be solved together (for PlainText as well as TextSprites)
        var tsb = TxTextSpriteBlock(msgCode: 0x20, width: 640, lineHeight: 32, displayRows: 3, fontFamily: null, text: inputString);
        await tsb.rasterize();

        // for preview only, make a full-sized image made up of all the lines composited
        // into one large image and add it to the _images widget list for display
        _images.clear();
        _images.add(Image.memory(await tsb.toPngBytes()));

        // TODO send (some of) the TxTextSpriteLines to Frame for display
        frame!.sendMessage(tsb.lines[6]);

        currentState = ApplicationState.ready;
        if (mounted) setState(() {});

    } catch (e) {
      _log.fine('Error executing application logic: $e');
      currentState = ApplicationState.ready;
      if (mounted) setState(() {});
    }
  }

  @override
  Future<void> cancel() async {
    // TODO any logic while canceling?

    currentState = ApplicationState.ready;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frame TextSpriteBlock',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Frame TextSpriteBlock'),
          actions: [getBatteryWidget()]
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(onPressed: run, child: const Text('Run')),
              ..._images,
            ],
          ),
        ),
        floatingActionButton: getFloatingActionButtonWidget(const Icon(Icons.file_open), const Icon(Icons.close)),
        persistentFooterButtons: getFooterButtonsWidget(),
      )
    );
  }
}
