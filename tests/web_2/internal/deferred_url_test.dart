// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.11
import 'dart:_js_helper';
import 'dart:_foreign_helper';
import 'dart:_js_embedded_names';

import 'package:expect/expect.dart';

main() {
  String currentScriptUrl = 'x/main.dart.js';
  String expectedPartUrl = 'x/part.js';
  // We make use of the multi-tests format to test multiple scenarios, that's
  // because internally dart:_js_helper computes what the current script
  // location is and caches the result in a final variable. As a result, we
  // can only set it once per test.
  currentScriptUrl = 'x/y/main.dart.js'; //# 01: ok
  expectedPartUrl = 'x/y/part.js'; //# 01: continued

  currentScriptUrl = 'main.dart.js'; //# 02: ok
  expectedPartUrl = 'part.js'; //# 02: continued

  currentScriptUrl = '/main.dart.js'; //# 03: ok
  expectedPartUrl = '/part.js'; //# 03: continued

  // Override the currentScript. This depends on the internal implementation
  // of [thisScript].
  JS('', '# = {"src": #}', JS_EMBEDDED_GLOBAL('', CURRENT_SCRIPT),
      currentScriptUrl);
  Object url = getBasedScriptUrlForTesting("part.js");
  Expect.equals(expectedPartUrl, JS('', '#.toString()', url));
}
