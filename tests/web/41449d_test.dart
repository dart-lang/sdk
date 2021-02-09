// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  Bar get bar => const Bar();
}

class Bar {
  const Bar();

  int call<S>(void Function(S) f) => 42;
}

class NoticeMe {}

void main() {
  Expect.equals(42, Foo().bar<NoticeMe>((_) {}));
}
