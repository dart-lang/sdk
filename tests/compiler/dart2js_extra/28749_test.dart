// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/28749.
//
// This would crash at compile time because inner typedefs remain after calling
// [type.unalias].  Expanding the typedef causes the inputs to be used multiple
// types, breaking the invariant of HTypeInfoExpression that the type variable
// occurrences correspond to inputs.

import 'package:expect/expect.dart';

typedef void F<T>(T value);
typedef F<U> Converter<U>(F<U> function);
typedef Converter<V> ConvertFactory<V>(int input);

class B<W> {
  final field = new Wrap<ConvertFactory<W>>();
  @NoInline()
  B();
}

class Wrap<X> {
  @NoInline()
  Wrap();
}

foo<Y>(int x) {
  if (x == 0)
    return new Wrap<ConvertFactory<Y>>().runtimeType;
  else
    return new B<Y>().field.runtimeType;
}

void main() {
  var name = '${Wrap}';
  if (name.length < 4) return; // minified.

  Expect.equals(
    'Wrap<(int) => ((int) => void) => (int) => void>',
    '${new B<int>().field.runtimeType}',
  );
  Expect.equals(
    'Wrap<(int) => ((bool) => void) => (bool) => void>',
    '${new B<bool>().field.runtimeType}',
  );

  Expect.equals(
    'Wrap<(int) => ((dynamic) => void) => (dynamic) => void>',
    '${foo<int>(0)}',
  );
  Expect.equals(
    'Wrap<(int) => ((dynamic) => void) => (dynamic) => void>',
    '${foo<String>(1)}',
  );
}
