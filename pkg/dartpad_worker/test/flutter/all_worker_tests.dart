// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'worker/compile.dart' as flutter_compile;
import 'worker/hot_reload_compiler.dart' as flutter_hotreloadcompiler;
import 'worker/language_server.dart' as flutter_languageserver;
import 'worker/pub.dart' as flutter_pub;

/// Compiling these workers tests is slow, so we've combined them all into
/// one test suite.
final testFiles = [
  ('flutter/worker/compile.dart', flutter_compile.main),
  ('flutter/worker/hot_reload_compiler.dart', flutter_hotreloadcompiler.main),
  ('flutter/worker/language_server.dart', flutter_languageserver.main),
  ('flutter/worker/pub.dart', flutter_pub.main),
];
