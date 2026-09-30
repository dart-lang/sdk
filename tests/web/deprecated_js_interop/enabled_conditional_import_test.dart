// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that by default (deprecated JS interop enabled), `dart.library.*`
/// conditions for the deprecated JS interop libraries are `true`.

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
  Expect.equals('deprecated', html_condition.selectedLibrary);
  Expect.equals('deprecated', html_common_condition.selectedLibrary);
  Expect.equals('deprecated', indexed_db_condition.selectedLibrary);
  Expect.equals('deprecated', js_condition.selectedLibrary);
  Expect.equals('deprecated', js_util_condition.selectedLibrary);
  Expect.equals('deprecated', svg_condition.selectedLibrary);
  Expect.equals('deprecated', web_audio_condition.selectedLibrary);
  Expect.equals('deprecated', web_gl_condition.selectedLibrary);
  Expect.equals('js_interop', js_interop_condition.selectedLibrary);

  Expect.isTrue(const bool.fromEnvironment('dart.library.html'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.html_common'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.indexed_db'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.js'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.js_util'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.svg'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.web_audio'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.web_gl'));

  Expect.isTrue(const bool.fromEnvironment('dart.library.js_interop'));
  Expect.isTrue(const bool.fromEnvironment('dart.library.js_interop_unsafe'));
}
