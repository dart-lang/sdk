// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.catch_asset_not_found;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';

import 'mock.dart';

/// A transformer that tries to load a secondary input and catches an
/// [AssetNotFoundException] if the input doesn't exist.
class CatchAssetNotFoundTransformer extends MockTransformer {
  /// The extension of assets this applies to.
  final String extension;

  /// The id of the secondary input to load.
  final AssetId input;

  CatchAssetNotFoundTransformer(this.extension, String input)
      : input = new AssetId.parse(input);

  Future<bool> doIsPrimary(AssetId id) =>
      new Future.value(id.extension == extension);

  Future doApply(Transform transform) {
    return transform.getInput(input).then((_) {
      transform.addOutput(new Asset.fromString(
          transform.primaryInput.id, "success"));
    }).catchError((e) {
      if (e is! AssetNotFoundException) throw e;
      transform.addOutput(new Asset.fromString(
          transform.primaryInput.id, "failed to load $input"));
    });
  }
}
