// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_bad;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';

import 'mock.dart';

/// A lazy transformer that throws an exception after [declareOutputs].
class LazyBadTransformer extends MockTransformer implements LazyTransformer {
  /// The error [this] throws.
  static const ERROR = "I am a bad transformer!";

  /// The asset name that [this] should output.
  final String output;

  LazyBadTransformer(this.output);

  Future<bool> doIsPrimary(_) => new Future.value(true);

  Future doApply(Transform transform) {
    return newFuture(() {
      var id = new AssetId.parse(output);
      transform.addOutput(new Asset.fromString(id, output));
    });
  }

  Future declareOutputs(DeclaringTransform transform) {
    return newFuture(() {
      var id = new AssetId.parse(output);
      transform.declareOutput(id);
      throw ERROR;
    });
  }
}
