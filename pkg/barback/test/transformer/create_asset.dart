// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.create_asset;

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that outputs an asset with the given id.
class CreateAssetTransformer extends MockTransformer {
  final String output;

  CreateAssetTransformer(this.output);

  bool doIsPrimary(AssetId id) => true;

  void doApply(Transform transform) {
    transform.addOutput(
        new Asset.fromString(new AssetId.parse(output), output));
  }
}
