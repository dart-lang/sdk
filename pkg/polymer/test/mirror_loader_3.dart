library mirror_loader_test3;

import 'dart:html';

import 'package:polymer/polymer.dart';

@CustomTag('x-b')
class XB<T> extends PolymerElement {
  final String x = "a";
  XB.created() : super.created();
}
