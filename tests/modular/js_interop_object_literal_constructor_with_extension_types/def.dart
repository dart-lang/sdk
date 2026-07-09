// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

extension type ObjectLiteral._(JSObject _) implements JSObject {
  external factory ObjectLiteral({int foo});
}
