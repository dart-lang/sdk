library mirror_loader_test1;

import 'dart:html';
import 'package:polymer/polymer.dart';

@CustomTag('x-a')
class XA extends PolymerElement {
  final String x = "a";
  XA.created() : super.created();
}
