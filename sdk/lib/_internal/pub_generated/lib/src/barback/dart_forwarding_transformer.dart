// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.dart_forwarding_transformer;

import 'dart:async';

import 'package:barback/barback.dart';

import '../utils.dart';

/// A single transformer that just forwards any ".dart" file as an output when
/// not in release mode.
///
/// Since the [Dart2JSTransformer] consumes its inputs, this is used in
/// parallel to make sure the original Dart file is still available for use by
/// Dartium.
class DartForwardingTransformer extends Transformer {
  /// The mode that the transformer is running in.
  final BarbackMode _mode;

  DartForwardingTransformer(this._mode);

  String get allowedExtensions => ".dart";

  Future apply(Transform transform) {
    return newFuture(() {
      transform.addOutput(transform.primaryInput);
    });
  }
}
