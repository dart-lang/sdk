// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library operator_test;

import 'package:js/js.dart';

@JS()
class JSClass {
  // https://dart.dev/guides/language/language-tour#_operators for the list of
  // operators allowed by the language.
  external void operator <(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator <=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator -(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator +(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator /(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator ~/(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator *(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator %(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator |(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator ^(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator &(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator <<(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >>>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator [](_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator []=(_, __);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator ~();
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external bool operator ==(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
}

@JS()
@anonymous
class AnonymousClass {
  external void operator <(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator <=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >=(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator -(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator +(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator /(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator ~/(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator *(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator %(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator |(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator ^(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator &(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator <<(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator >>>(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator [](_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator []=(_, __);
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external void operator ~();
  //                     ^
  // [web] JS interop classes do not support operator methods.
  external bool operator ==(_);
  //                     ^
  // [web] JS interop classes do not support operator methods.
}

@JS()
class JSClassExtensions {}

extension _ on JSClassExtensions {
  // External operators in extensions are allowed for now, but don't work as
  // intended. Specific operators will need to be allowlisted in the future.
  // TODO(srujzs): Remove this test once we do that.
  external void operator <(_);
  external void operator >(_);
  external void operator <=(_);
  external void operator >=(_);
  external void operator -(_);
  external void operator +(_);
  external void operator /(_);
  external void operator ~/(_);
  external void operator *(_);
  external void operator %(_);
  external void operator |(_);
  external void operator ^(_);
  external void operator &(_);
  external void operator <<(_);
  external void operator >>(_);
  external void operator >>>(_);
  external void operator [](_);
  external void operator []=(_, __);
  external void operator ~();
  // No `==` as it's an `Object` method.
}

void main() {}
