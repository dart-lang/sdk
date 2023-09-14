// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library operator_test;

import 'dart:js_interop';

@JS()
@staticInterop
class StaticInterop {}

extension _ on StaticInterop {
  // https://dart.dev/guides/language/language-tour#_operators for the list of
  // operators allowed by the language.
  external void operator <(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator -(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator +(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator /(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ~/(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator *(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator %(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator |(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ^(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator &(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <<(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  @JS('rename')
  external void operator [](_);
  //                     ^
  // [web] JS interop operator methods cannot be renamed using the '@JS' annotation.
  @JS('rename')
  external void operator []=(_, __);
  //                     ^
  // [web] JS interop operator methods cannot be renamed using the '@JS' annotation.
  external void operator ~();
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.

  // No `==` as it's an `Object` method.
}

@JS()
extension type ExtensionType(JSObject _) {
  external void operator <(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator -(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator +(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator /(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ~/(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator *(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator %(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator |(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ^(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator &(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <<(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.
  @JS('rename')
  external void operator [](_);
  //                     ^
  // [web] JS interop operator methods cannot be renamed using the '@JS' annotation.
  @JS('rename')
  external void operator []=(_, __);
  //                     ^
  // [web] JS interop operator methods cannot be renamed using the '@JS' annotation.
  external void operator ~();
  //                     ^
  // [web] JS interop classes do not support operator methods, with the exception of '[]' and '[]=' using static interop.

  // No `==` as it's an `Object` method.
}
