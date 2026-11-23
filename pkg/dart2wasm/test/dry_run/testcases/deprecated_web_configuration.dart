// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DRY_RUN: 18, 'dart:html' is deprecated
import 'dart:async' if (dart.library.html) 'dart:html' as i1;
// DRY_RUN: 18, 'dart:indexed_db' is deprecated
import 'dart:async' if (dart.library.indexed_db) 'dart:indexed_db' as i2;
// DRY_RUN: 18, 'dart:js' is deprecated
import 'dart:async' if (dart.library.js) 'dart:js' as i3;
// DRY_RUN: 18, 'dart:js_util' is deprecated
export 'dart:async' if (dart.library.js_util) 'dart:js_util';
// DRY_RUN: 18, 'dart:svg' is deprecated
import 'dart:async' if (dart.library.svg) 'dart:svg' as i4;
// DRY_RUN: 18, 'dart:web_audio' is deprecated
import 'dart:async' if (dart.library.web_audio) 'dart:web_audio' as i5;
// DRY_RUN: 18, 'dart:web_gl' is deprecated
import 'dart:async' if (dart.library.web_gl) 'dart:web_gl' as i6;

// Multi-branch configuration with a deprecated web branch.
import 'dart:async'
    if (dart.library.io) 'dart:io'
    // DRY_RUN: 18, 'dart:html' is deprecated
    if (dart.library.html) 'dart:html'
    as i7;

// Users are allowed to ignore warnings still.
// ignore: deprecated_web_configuration
import 'dart:collection' if (dart.library.js) 'dart:js';

// Non-deprecated web configuration should not be reported.
import 'dart:convert' if (dart.library.js_interop) 'dart:js_interop';

void main() {}
