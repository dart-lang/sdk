// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class OneArg<A> {
  OneArg<A> get foo => new OneArg<A>();
  OneArg<A> get bar {
    return new OneArg<A>();
  }
}

class TwoArgs<A, B> {
  TwoArgs<A, B> get foo => new TwoArgs<A, B>();
  TwoArgs<A, B> get bar {
    return new TwoArgs<A, B>();
  }
}

void main() {
  Expect.isTrue(new OneArg<String>().foo is OneArg);
  Expect.isTrue(new OneArg<String>().bar is OneArg);
  Expect.isTrue(new TwoArgs<String, int>().foo is TwoArgs);
  Expect.isTrue(new TwoArgs<String, int>().bar is TwoArgs);

  // TODO(karlklose): Please remove the return when dart2js can handle
  // the type tests after it.
  return;
  Expect.isTrue(new OneArg<String>().foo is OneArg<String>);
  Expect.isTrue(new OneArg<String>().bar is OneArg<String>);
  Expect.isTrue(new TwoArgs<String, int>().foo is TwoArgs<String, int>);
  Expect.isTrue(new TwoArgs<String, int>().bar is TwoArgs<String, int>);
}
