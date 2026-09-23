// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Types shared across `package:dartpad_worker`, plus a re-export of the types
/// it shares with `package:dartpad`.
library;

export 'package:dartpad/src/dartpad_config.dart';
export 'package:dartpad/src/shared.dart';

/// A single DDC library bundle.
///
/// The `moduleName` must be the name the bundle passes to
/// `dartDevEmbedder.debugger.setSourceMap`, because that is how a stack frame
/// in this bundle finds its source map. `libraries` are the import URIs of the
/// Dart libraries defined in `code`.
typedef CompiledModule = ({
  String moduleName,
  String code,
  List<String> libraries,
});

// TODO(jonasfj): Consider a final class wouldn't be a more future proof API?
typedef CompileResult = ({
  List<CompiledModule> modules,
  String entrypointLibraryUri,
  String log,
});
