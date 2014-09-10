// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformer that removes any sourcemap comments from javascript files.
library code_transformers.src.remove_sourcemap_comment;

import 'dart:async';
import 'package:barback/barback.dart';

/// Transformer that removes any sourcemap comments from javascript files.
/// Comments should be on their own line in the form: //# sourceMappingURL=*.map
class RemoveSourcemapComment extends Transformer {
  BarbackSettings settings;

  RemoveSourcemapComment.asPlugin(this.settings);

  /// Only apply to files in release mode.
  isPrimary(_) => settings.mode == BarbackMode.RELEASE;

  apply(Transform transform) {
    var id = transform.primaryInput.id;
    return transform.readInputAsString(id).then((file) {
      if (file.contains(_SOURCE_MAP_COMMENT)) {
        transform.addOutput(new Asset.fromString(
            id, file.replaceAll(_SOURCE_MAP_COMMENT, '')));
      }
    });
  }
}

final RegExp _SOURCE_MAP_COMMENT = new RegExp(r'\n\s*\/\/# sourceMappingURL.*');
