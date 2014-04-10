library mirror_loader_test1;

import 'package:polymer/polymer.dart';

@CustomTag('x-a')
class XA extends PolymerElement {
  final String x = "a";
  XA.created() : super.created();
}
