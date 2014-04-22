// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.declaring_bad;

import 'package:barback/barback.dart';

import 'bad.dart';
import 'mock.dart';

/// A transformer that throws an exception when run, after generating the
/// given outputs.
class DeclaringBadTransformer extends MockTransformer
    implements DeclaringTransformer {
  /// Whether this should throw an error in [declareOutputs].
  final bool declareError;

  /// Whether this should throw an error in [apply].
  final bool applyError;

  /// The id of the output asset to emit.
  final AssetId output;

  DeclaringBadTransformer(String output, {bool declareError: true,
          bool applyError: false})
      : this.output = new AssetId.parse(output),
        this.declareError = declareError,
        this.applyError = applyError;

  bool doIsPrimary(AssetId id) => true;

  void doApply(Transform transform) {
    transform.addOutput(new Asset.fromString(output, "bad out"));
    if (applyError) throw BadTransformer.ERROR;
  }

  void declareOutputs(DeclaringTransform transform) {
    if (consumePrimary) transform.consumePrimary();
    transform.declareOutput(output);
    if (declareError) throw BadTransformer.ERROR;
  }
}
