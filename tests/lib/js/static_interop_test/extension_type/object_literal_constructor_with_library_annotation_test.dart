// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate that the library adding an annotation doesn't change the backend's
// lowerings.

@JS()
library object_literal_constructor_with_library_annotation_test;

import 'dart:js_interop';

import 'object_literal_constructor_test.dart' show testProperties;

extension type Literal._(JSObject _) implements JSObject {
  external Literal({double? a});
  external factory Literal.fact({double? a});
}

void main() {
  testProperties(Literal());
  testProperties(Literal.fact(a: 0.0), a: 0.0);
}
