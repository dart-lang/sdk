// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'worker/compile.dart' as dart_compile;
import 'worker/filesystem.dart' as dart_filesystem;
import 'worker/hot_reload_compiler.dart' as dart_hotreloadcompiler;
import 'worker/language_server.dart' as dart_languageserver;
import 'worker/pub.dart' as dart_pub;
import 'worker/watch.dart' as dart_watch;

/// Compiling these workers tests is slow, so we've combined them all into
/// one test suite.
final testFiles = [
  ('dart/worker/compile.dart', dart_compile.main),
  ('dart/worker/filesystem.dart', dart_filesystem.main),
  ('dart/worker/hot_reload_compiler.dart', dart_hotreloadcompiler.main),
  ('dart/worker/language_server.dart', dart_languageserver.main),
  ('dart/worker/pub.dart', dart_pub.main),
  ('dart/worker/watch.dart', dart_watch.main),

  // TODO(jonasfj): Merge test_dart_worker.dart and test_flutter_worker.dart
  //                when pub no longer has global state. For now we need it
  //                Because once pub has detected SDK availablity it won't
  //                change in the same process.
];
