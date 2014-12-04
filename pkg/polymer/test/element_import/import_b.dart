library polymer.test.element_import.import_b;

import 'package:polymer/polymer.dart';

@CustomTag('x-bar')
class XBar extends PolymerElement {
  final bool isCustom = true;

  XBar.created() : super.created();
}
