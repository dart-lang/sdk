// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DRY_RUN: 0, dart:html
import 'dart:html';
// DRY_RUN: 0, dart:indexed_db
import 'dart:indexed_db';
// DRY_RUN: 0, dart:svg
import 'dart:svg';
// DRY_RUN: 0, dart:web_audio
import 'dart:web_audio';
// DRY_RUN: 0, dart:web_gl
import 'dart:web_gl';
import 'dart:js_interop';

@JS()
external Window get myWindow;

// Referencing unavailable `dart:html` symbols verifies both that CFE errors
// stay suppressed on stderr and that `InvalidType` triggers no cascading (2)
// JS interop findings.
void main() {
  Window? w;
  print(w);
  print(window);
  ((Window _) {}).toJS;
}
