// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_and_staticinterop_annotation_static_test;

import 'package:js/js.dart';

@staticInterop
class NoJSAnnotation {}
//    ^
// [web] `@staticInterop` classes should also have the `@JS` annotation.

@anonymous
@staticInterop
class AnonymousNoJSAnnotation {}
//    ^
// [web] `@staticInterop` classes should also have the `@JS` annotation.
