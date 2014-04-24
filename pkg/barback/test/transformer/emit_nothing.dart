// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.emit_nothing;

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that emits no assets.
class EmitNothingTransformer extends MockTransformer {
  final String extension;

  EmitNothingTransformer(this.extension);

  bool doIsPrimary(AssetId id) => id.extension == ".$extension";

  void doApply(Transform transform) {
    // Emit nothing.
  }

  String toString() => "$extension->nothing";
}
