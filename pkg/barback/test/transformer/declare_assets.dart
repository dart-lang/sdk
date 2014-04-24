// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.declare_asset;

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that declares some outputs and emits others.
class DeclareAssetsTransformer extends MockTransformer
    implements DeclaringTransformer {
  /// The assets that the transformer declares that it will emit.
  final List<AssetId> declared;

  /// The assets that the transformer actually emits.
  ///
  /// These assets' contents will be identical to their ids.
  final List<AssetId> emitted;

  DeclareAssetsTransformer(Iterable<String> declared, [Iterable<String> emitted])
      : this.declared = declared.map((id) => new AssetId.parse(id)).toList(),
        this.emitted = (emitted == null ? declared : emitted)
            .map((id) => new AssetId.parse(id)).toList();

  bool doIsPrimary(AssetId id) => true;

  void doApply(Transform transform) {
    for (var id in emitted) {
      transform.addOutput(new Asset.fromString(id, id.toString()));
    }
  }

  void declareOutputs(DeclaringTransform transform) {
    declared.forEach(transform.declareOutput);
  }
}
