// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library operator_test;

import 'package:js/js.dart';

@JS()
class JSClass {
  // https://dart.dev/guides/language/language-tour#_operators for the list of
  // operators allowed by the language.
  @JS('rename')
  external void operator <(_);
  //                     ^
  // [web] JS interop operator methods cannot be renamed using the '@JS' annotation.
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <=(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >=(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator -(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator +(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator /(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ~/(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator *(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator %(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator |(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ^(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator &(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <<(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>>(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator [](_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator []=(_, __);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ~();
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external bool operator ==(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
}

@JS()
@anonymous
class AnonymousClass {
  @JS('rename')
  external void operator <(_);
  //                     ^
  // [web] JS interop operator methods cannot be renamed using the '@JS' annotation.
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <=(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >=(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator -(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator +(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator /(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ~/(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator *(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator %(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator |(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ^(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator &(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator <<(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator >>>(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator [](_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator []=(_, __);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external void operator ~();
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
  external bool operator ==(_);
  //                     ^
  // [web] JS interop types do not support overloading external operator methods, with the exception of '[]' and '[]=' using static interop.
}

void main() {}
