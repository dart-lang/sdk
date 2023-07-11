// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that top-level external members need an @JS annotation even if the
// library has one when using dart:js_interop.

@JS()
library top_level_member_annotation_static_test;

import 'dart:js_interop';

external int field;
//           ^
// [web] Only JS interop members may be 'external'.

external int finalField;
//           ^
// [web] Only JS interop members may be 'external'.

external int get getter;
//               ^
// [web] Only JS interop members may be 'external'.

external set setter(_);
//           ^
// [web] Only JS interop members may be 'external'.

external int method();
//           ^
// [web] Only JS interop members may be 'external'.

@JS()
external int annotatedField;

@JS()
external int annotatedFinalField;

@JS()
external int get annotatedGetter;

@JS()
external set annotatedSetter(_);

@JS()
external int annotatedMethod();
