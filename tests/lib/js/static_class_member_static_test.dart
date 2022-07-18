// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js/js.dart';

@JS('a.Foo')
class Foo {
  @JS('c.d.plus')
  external static plus1(arg);
//                ^
// [web] JS interop static class members cannot have '.' in their JS name.
}

main() {}
