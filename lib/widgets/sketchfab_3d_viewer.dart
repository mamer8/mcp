import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/sketchfab_model.dart';

class Sketchfab3DViewer extends StatefulWidget {
  final SketchfabModel model;

  const Sketchfab3DViewer({super.key, required this.model});

  @override
  State<Sketchfab3DViewer> createState() => _Sketchfab3DViewerState();
}

class _Sketchfab3DViewerState extends State<Sketchfab3DViewer> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE7EDF0))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              setState(() => _hasError = true);
            }
          },
        ),
      );
    _loadModel();
  }

  @override
  void didUpdateWidget(covariant Sketchfab3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.uid != widget.model.uid) _loadModel();
  }

  void _loadModel() {
    setState(() {
      _progress = 0;
      _hasError = false;
    });
    final uri = Uri.parse(widget.model.embedUrl).replace(
      queryParameters: const {
        'autostart': '1',
        'ui_controls': '1',
        'ui_infos': '0',
        'ui_watermark': '1',
      },
    );
    _controller.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'تعذر تحميل النموذج ثلاثي الأبعاد. تحقق من الاتصال وحاول مرة أخرى.',
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          key: const Key('product_3d_viewer'),
          controller: _controller,
        ),
        if (_progress < 100)
          IgnorePointer(
            child: ColoredBox(
              color: const Color(0xFFE7EDF0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text('تحميل نموذج ${_progress.clamp(0, 100)}٪'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
