// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class S<T extends S<T>> {
  m() => 123;
  get S_T => T;
}

class C<T extends C<T>> extends S<C> {
  m() => 456;
  get C_T => T;
}

class D extends C<D> {}

main() {
  Expect.equals(new C<D>().m(), 456);
  // TODO(jmesserly): this should be dart1 vs dart2, not DDC vs VM.
  var isVM = const bool.fromEnvironment('dart.isVM');
  Expect.equals(new C<D>().S_T.toString(), isVM ? 'C' : 'C<C>');
  Expect.equals(new C<D>().C_T.toString(), isVM ? 'dynamic' : 'D');
}
