// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Debug information representation and source map generation for Dart
/// compilers and tools.
library;

export 'src/bytes.dart' show BytesReader, BytesWriter;
export 'src/handle_stream.dart'
    show DebugInfoHandleReader, DebugInfoHandleWriter;
export 'src/handles.dart' show DebugInfo, Scope, Variable;
