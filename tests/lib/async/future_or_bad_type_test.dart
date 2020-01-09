// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In non strong-mode, `FutureOr<T>` is dynamic, even if `T` doesn't exist.
// `FutureOr<T>` can not be used as superclass, mixin, nor can it be
// implemented (as interface).

import 'dart:async';
import 'package:expect/expect.dart';

class A
    extends FutureOr<String> /*@compile-error=unspecified*/
    extends Object with FutureOr<bool> /*@compile-error=unspecified*/
    implements FutureOr<int> /*@compile-error=unspecified*/
{}

main() {
}
