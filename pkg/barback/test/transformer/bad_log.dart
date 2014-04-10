// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.bad_log;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';

import 'mock.dart';

/// A transformer that logs an error when run, Before generating the given
/// outputs.
class BadLogTransformer extends MockTransformer {
  /// The list of asset names that it should output.
  final List<String> outputs;

  BadLogTransformer(this.outputs);

  Future<bool> doIsPrimary(AssetId id) => new Future.value(true);

  Future doApply(Transform transform) {
    return newFuture(() {
      transform.logger.error("first error");
      transform.logger.error("second error");

      for (var output in outputs) {
        var id = new AssetId.parse(output);
        transform.addOutput(new Asset.fromString(id, output));
      }
    });
  }
}
