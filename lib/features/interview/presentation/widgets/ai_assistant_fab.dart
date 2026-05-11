import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AiAssistantEmbed extends StatefulWidget {
  final double width;
  final double height;

  const AiAssistantEmbed({
    super.key,
    this.width = 350, // Increased width to fit the widget content
    this.height = 180, // Increased height
  });

  @override
  State<AiAssistantEmbed> createState() => _AiAssistantEmbedState();
}

class _AiAssistantEmbedState extends State<AiAssistantEmbed> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString('''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            margin: 0; 
            padding: 10px;
            display: flex; 
            justify-content: flex-end; 
            align-items: flex-end; 
            background-color: transparent; 
            height: 100vh;
            width: 100vw;
            overflow: hidden;
        }
    </style>
</head>
<body>
    <elevenlabs-convai agent-id="agent_1201kfnnxpq2eyrs4xha72jtvk8q"></elevenlabs-convai>
    <script src="https://unpkg.com/@elevenlabs/convai-widget-embed" async type="text/javascript"></script>
</body>
</html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: WebViewWidget(controller: controller),
    );
  }
}
