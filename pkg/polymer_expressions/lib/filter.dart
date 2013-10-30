// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.filter;

typedef Object Filter(Object value);

abstract class Transformer<T, V> {

  T forward(V v);
  V reverse(T t);
  Transformer<V, T> get inverse => new _InverseTransformer/*<V, T>*/(this);
}

// TODO(jmesserly): restore types when Issue 14094 is fixed.
class _InverseTransformer/*<V, T>*/ implements Transformer/*<V, T>*/ {
  final Transformer/*<T, V>*/ _t;
  _InverseTransformer(this._t);

  /*V*/ forward(/*T*/ v) => _t.reverse(v);
  /*T*/ reverse(/*V*/ t) => _t.forward(t);
  Transformer/*<T, V>*/ get inverse => _t;
}
