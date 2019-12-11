// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test case for DDC bug where if a getter/setter is mixed in
// without a corresponding getter/setter, DDC fails to install a the
// corresponding getter/setter that calls super.

import "package:expect/expect.dart";

abstract class C<E> {
  E get first;
  set first(E value);
  E operator [](int index);
  operator []=(int index, E value);
}

abstract class CMixin<E> implements C<E> {
  E get first => this[0];
  set first(E x) {
    this[0] = x;
  }
}

abstract class CBase<E> extends Object with CMixin<E> {}

abstract class DMixin<E> implements C<E> {
  set first(E _) => throw new UnsupportedError('');
  operator []=(int index, E value) => throw new UnsupportedError('');
}

abstract class DBase<E> = CBase<E> with DMixin<E>;

class DView<E> extends DBase<E> {
  final Iterable<E> _source;
  DView(this._source);
  E operator [](int index) => _source.elementAt(index);
}

abstract class FMixin<E> implements C<E> {
  E get first => throw new UnsupportedError('');
  E operator [](int index) => throw new UnsupportedError('');
}

class FView<E> extends CBase<E> with FMixin<E> {
  List<E> _values;
  FView(this._values);
  operator []=(int index, E value) {
    _values[index] = value;
  }
}

void main() {
  var d = new DView([3]);
  Expect.equals(3, d.first);
  Expect.throws(() => d.first = 42, (e) => e is UnsupportedError);

  var list = [3];
  var f = new FView(list);
  f.first = 42;
  Expect.equals(42, list[0]);
  Expect.throws(() => f.first, (e) => e is UnsupportedError);
}
