// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS('library1')
library js_default_with_namespaces;

import 'dart:js_interop';

@JS()
@staticInterop
class SimpleObject {
  external factory SimpleObject();
  external factory SimpleObject.oneOptional(JSNumber n1, [JSNumber n2]);

  external static JSNumber oneOptionalStatic(JSNumber n1, [JSNumber n2]);
}

extension SimpleObjectExtension on SimpleObject {
  external JSNumber get initialArguments;
  external JSNumber oneOptional(JSNumber n1, [JSNumber n2]);
}

@JS('SimpleObject')
extension type SimpleObject2._(JSObject _) implements JSObject {
  external factory SimpleObject2();
  external factory SimpleObject2.oneOptional(JSNumber n1, [JSNumber n2]);

  external static JSNumber oneOptionalStatic(JSNumber n1, [JSNumber n2]);

  external JSNumber get initialArguments;
  external JSNumber oneOptional(JSNumber n1, [JSNumber n2]);
}

@JS()
external JSNumber oneOptional(JSNumber n1, [JSNumber n2]);
