// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './bar_lib.dart';

export './bar_lib.dart';

abstract class Foo {
  const Foo();
  const factory Foo.bar() = Bar;
}
