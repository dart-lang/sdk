// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformer that removes uses of mirrors from the polymer runtime, so that
/// deployed applications are thin and small.
library polymer.src.build.mirrors_remover;

import 'dart:async';
import 'package:barback/barback.dart';

/// Removes the code-initialization logic based on mirrors.
class MirrorsRemover extends Transformer {
  MirrorsRemover.asPlugin();

  /// Only apply to `lib/polymer.dart`.
  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(
        id.package == 'polymer' && id.path == 'lib/polymer.dart');
  }

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    return transform.primaryInput.readAsString().then((code) {
      // Note: this rewrite is highly-coupled with how polymer.dart is
      // written. Make sure both are updated in sync.
      var start = code.indexOf('@MirrorsUsed(');
      if (start == -1) _error();
      var end = code.indexOf('show MirrorsUsed;', start);
      if (end == -1) _error();
      end = code.indexOf('\n', end);
      var loaderImport = code.indexOf(
          "import 'src/mirror_loader.dart' as loader;", end);
      if (loaderImport == -1) _error();
      var sb = new StringBuffer()
          ..write(code.substring(0, start))
          ..write(code.substring(end)
              .replaceAll('src/mirror_loader.dart', 'src/static_loader.dart'));

      transform.addOutput(new Asset.fromString(id, sb.toString()));
    });
  }
}

/** Transformer phases which should be applied to the smoke package. */
List<List<Transformer>> get phasesForSmoke =>
    [[new MirrorsRemover.asPlugin()]];

_error() => throw new StateError("Couldn't remove imports to mirrors, maybe "
    "polymer.dart was modified, but mirrors_remover.dart wasn't.");
