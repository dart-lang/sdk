// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js/js.dart';

@JS()
@trustTypes
class Incorrect {}
//    ^
// [web] JS interop class 'Incorrect' has an `@trustTypes` annotation, but no `@staticInterop` annotation.
