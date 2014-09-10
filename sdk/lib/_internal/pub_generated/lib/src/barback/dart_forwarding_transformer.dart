library pub.dart_forwarding_transformer;
import 'dart:async';
import 'package:barback/barback.dart';
import '../utils.dart';
class DartForwardingTransformer extends Transformer {
  final BarbackMode _mode;
  DartForwardingTransformer(this._mode);
  String get allowedExtensions => ".dart";
  Future apply(Transform transform) {
    return newFuture(() {
      transform.addOutput(transform.primaryInput);
    });
  }
}
