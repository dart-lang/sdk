// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--no-deprecated-js-interop
// ddcOptions=--no-deprecated-js-interop

/// Tests that with `--no-deprecated-js-interop`, importing any of the
/// deprecated JS interop libraries is a compile-time error.

import 'dart:html';
//     ^
// [web] Import of deprecated JS interop library 'dart:html' is not allowed.
import 'dart:html_common';
//     ^
// [web] Import of deprecated JS interop library 'dart:html_common' is not allowed.
import 'dart:indexed_db';
//     ^
// [web] Import of deprecated JS interop library 'dart:indexed_db' is not allowed.
import 'dart:js';
//     ^
// [web] Import of deprecated JS interop library 'dart:js' is not allowed.
import 'dart:js_util';
//     ^
// [web] Import of deprecated JS interop library 'dart:js_util' is not allowed.
import 'dart:svg';
//     ^
// [web] Import of deprecated JS interop library 'dart:svg' is not allowed.
import 'dart:web_audio';
//     ^
// [web] Import of deprecated JS interop library 'dart:web_audio' is not allowed.
import 'dart:web_gl';
//     ^
// [web] Import of deprecated JS interop library 'dart:web_gl' is not allowed.

// Libraries that are not part of deprecated JS interop are still available.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void main() {}
