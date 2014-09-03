// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transformer that deletes everything that it sees, but only in release mode.
library code_transformers.src.delete_file;

import 'dart:async';
import 'package:barback/barback.dart';

// Deletes all files supplied in release mode.
class DeleteFile extends Transformer {
  BarbackSettings settings;

  DeleteFile.asPlugin(this.settings);

  /// Only apply to files in release mode.
  isPrimary(_) => settings.mode == BarbackMode.RELEASE;

  apply(Transform transform) {
    transform.consumePrimary();
  }
}
