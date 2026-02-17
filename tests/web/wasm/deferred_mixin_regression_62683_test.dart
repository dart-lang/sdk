// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_mixin_regression_62683_helper.dart';

class Foo extends Object with FooMixin {}

void main() async {
  final foo = Foo();
  await foo.init();
  foo.access();
}
