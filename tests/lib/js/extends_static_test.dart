// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library extends_static_test;

import 'package:js/js.dart';

@JS()
class JSClass {}

@JS()
@anonymous
class AnonymousClass {}

class DartClass {}

class DartExtendJSClass extends JSClass {}
//    ^
// [web] Dart class 'DartExtendJSClass' cannot extend JS interop class 'JSClass'.

class DartExtendAnonymousClass extends AnonymousClass {}
//    ^
// [web] Dart class 'DartExtendAnonymousClass' cannot extend JS interop class 'AnonymousClass'.

@JS()
class JSExtendDartClass extends DartClass {}
//    ^
// [web] JS interop class 'JSExtendDartClass' cannot extend Dart class 'DartClass'.

@JS()
@anonymous
class AnonymousExtendDartClass extends DartClass {}
//    ^
// [web] JS interop class 'AnonymousExtendDartClass' cannot extend Dart class 'DartClass'.

void main() {}
