// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Native implementation.

library lib2;
import 'native_library_same_name_used_lib1.dart';  // To get abstract class I.
import 'dart:_js_helper';

// Native impl has same name as abstract class.
@Native("I")
class Impl implements I {
  Impl read() native;
  write(Impl x) native;
}
