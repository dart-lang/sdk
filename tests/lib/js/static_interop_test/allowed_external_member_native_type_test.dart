// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Like allowed_external_member_type_test, but tests `@Native` types. The only
// valid ones are those that <: `JavaScriptObject` and users can reference,
// which end up only being the types in the SDK web libraries.

@JS()
library allowed_external_member_native_type_test;

import 'dart:html';
import 'dart:js_interop';
import 'dart:svg';
import 'dart:typed_data';

@JS()
external void documentTest(Document _);

@JS()
external void elementTypeParamTest<T extends Element>(T _);

@JS()
external GeometryElement geometryElementTest();

// Not an `@Native` type.
@JS()
external void platformTest(Platform _);
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*Platform*)'.

// While the factory returns an `@Native` type that implements
// `JavaScriptObject`, the public interface is not such a type.
@JS()
external void uint8ListTest(Uint8List _);
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*Uint8List*)'.

void main() {}
