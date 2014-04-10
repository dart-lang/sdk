// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.create_asset;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';

import 'mock.dart';

/// A transformer that outputs an asset with the given id.
class CreateAssetTransformer extends MockTransformer {
  final String output;

  CreateAssetTransformer(this.output);

  Future<bool> doIsPrimary(_) => new Future.value(true);

  Future doApply(Transform transform) {
    return newFuture(() {
      transform.addOutput(
          new Asset.fromString(new AssetId.parse(output), output));
    });
  }
}
