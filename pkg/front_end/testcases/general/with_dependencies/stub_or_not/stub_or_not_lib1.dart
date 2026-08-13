// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'stub_or_not_lib2.dart';

abstract class Qux implements EventFileA {
  void handleEvent(covariant EvenFileB entry) {}
}

class EvenFileBPrime extends EvenFileB {}

abstract class Baz extends Qux {
  void handleEvent(EvenFileBPrime entry) {}
}

abstract class Foo extends Baz implements Qux {}
