// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--no-deprecated-js-interop
// ddcOptions=--no-deprecated-js-interop

/// Tests that with `--no-deprecated-js-interop`, `dart.library.*` conditions
/// for the deprecated JS interop libraries are `false`, while conditions for
/// other web libraries are unaffected.
///
/// The deprecated branch of the conditional imports below imports every
/// deprecated JS interop library itself. Since that branch is never selected,
/// it must not cause an error.

import 'package:expect/expect.dart';

import 'conditional_import_default.dart'
    if (dart.library.html) 'conditional_import_deprecated.dart'
    as html_condition;
import 'conditional_import_default.dart'
    if (dart.library.html_common) 'conditional_import_deprecated.dart'
    as html_common_condition;
import 'conditional_import_default.dart'
    if (dart.library.indexed_db) 'conditional_import_deprecated.dart'
    as indexed_db_condition;
import 'conditional_import_default.dart'
    if (dart.library.js) 'conditional_import_deprecated.dart'
    as js_condition;
import 'conditional_import_default.dart'
    if (dart.library.js_util) 'conditional_import_deprecated.dart'
    as js_util_condition;
import 'conditional_import_default.dart'
    if (dart.library.svg) 'conditional_import_deprecated.dart'
    as svg_condition;
import 'conditional_import_default.dart'
    if (dart.library.web_audio) 'conditional_import_deprecated.dart'
    as web_audio_condition;
import 'conditional_import_default.dart'
    if (dart.library.web_gl) 'conditional_import_deprecated.dart'
    as web_gl_condition;
import 'conditional_import_default.dart'
    if (dart.library.js_interop) 'conditional_import_js_interop.dart'
    as js_interop_condition;

void main() {
  Expect.equals('default', html_condition.selectedLibrary);
  Expect.equals('default', html_common_condition.selectedLibrary);
  Expect.equals('default', indexed_db_condition.selectedLibrary);
  Expect.equals('default', js_condition.selectedLibrary);
  Expect.equals('default', js_util_condition.selectedLibrary);
  Expect.equals('default', svg_condition.selectedLibrary);
  Expect.equals('default', web_audio_condition.selectedLibrary);
  Expect.equals('default', web_gl_condition.selectedLibrary);
  Expect.equals('js_interop', js_interop_condition.selectedLibrary);

  Expect.isFalse(const bool.fromEnvironment('dart.library.html'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.html_common'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.indexed_db'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.js'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.js_util'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.svg'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.web_audio'));
  Expect.isFalse(const bool.fromEnvironment('dart.library.web_gl'));

  Expect.isTrue(const bool.fromEnvironment('dart.library.js_interop'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.js_interop_unsafe'));
}
