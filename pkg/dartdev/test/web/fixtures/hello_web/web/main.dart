import 'dart:js_interop';

import 'package:hello_web/greeting.dart';

@JS('document.title')
external set title(String value);

void main() {
  title = greeting;
}
