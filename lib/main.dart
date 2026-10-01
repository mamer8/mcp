import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'app/store_app.dart';
import 'screens/store_main_screen.dart';

export 'app/store_app.dart' show StoreApp;
export 'screens/store_main_screen.dart' show StoreMainScreen;

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(const StoreApp(home: StoreMainScreen()));
}
