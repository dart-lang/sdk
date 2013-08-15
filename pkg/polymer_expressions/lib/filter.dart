// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.filter;

typedef Object Filter(Object value);

abstract class Transformer<T, V> {

  T forward(V v);
  V reverse(T t);
  Transformer<V, T> get inverse => new _InverseTransformer(this);
}

class _InverseTransformer<T, V> implements Transformer<T, V> {
  final Transformer<V, T> _t;
  _InverseTransformer(this._t);

  T forward(V v) => _t.reverse(v);
  V reverse(T t) => _t.forward(t);
  Transformer<V, T> get inverse => _t;
}
