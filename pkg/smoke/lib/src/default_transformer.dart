// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformer that replaces the default mirror-based implementation of smoke,
/// so that during deploy smoke doesn't include any dependency on dart:mirrors.
library smoke.src.default_transformer;

import 'dart:async';
import 'package:barback/barback.dart';

/// Replaces the default mirror-based implementation of smoke in
/// `pacakge:smoke/implementation.dart`, so that during deploy smoke doesn't
/// include any dependency on dart:mirrors.
// TODO(sigmund): include tests that run this transformation automatically.
class DefaultTransformer extends Transformer {
  DefaultTransformer.asPlugin();

  /// Only apply to `lib/src/implementation.dart`.
  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(
        id.package == 'smoke' && id.path == 'lib/src/implementation.dart');
  }

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    return transform.primaryInput.readAsString().then((code) {
      // Note: this rewrite is highly-coupled with how implementation.dart is
      // written. Make sure both are updated in sync.
      transform.addOutput(new Asset.fromString(id, code
          .replaceAll(new RegExp('new Reflective[^;]*;'),
              'throwNotConfiguredError();')
          .replaceAll("import 'package:smoke/mirrors.dart';", '')));
    });
  }
}

/** Transformer phases which should be applied to the smoke package. */
List<List<Transformer>> get phasesForSmoke =>
    [[new DefaultTransformer.asPlugin()]];
