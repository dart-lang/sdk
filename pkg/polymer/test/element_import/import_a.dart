library polymer.test.element_import.import_a;

import 'package:polymer/polymer.dart';

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  final bool isCustom = true;

  XFoo.created() : super.created();
}
