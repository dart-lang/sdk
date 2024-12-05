// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // Non-efficient length iterables.
  var i1 = [for (var i = 0; i < 16; i++) i].where((_) => true);
  var i2 = [for (var i = 0; i < 15; i++) "$i"].where((_) => true);

  // !! Removing this line avoids the error.
  if (0 != zip2((i1, i2)).length) throw "Bad";

  // !! Moving this declaration above the line above, or below the line below,
  // avoids the error?
  var i3 = [for (var i = 0; i < 17; i++) i.isEven].where((_) => true);

  print("Gets here");

  // !! Fails in this call to `length`.
  if (0 != zip2((i1, <bool>[])).length) throw "Bad";

  print("Does not get here");

  // !! Removing this line avoids the error.
  // !! Changing it to `zip2` avoids the error.
  if (0 != zip3((i1, i2, i3)).length) throw "Bad";
}

// !! If I change parameters to `Iterable<T1> it1, Iterable<T2> it2` and
// create `(it1, it2)` in this function, it avoids the error.
Iterable<(T1, T2)> zip2<T1, T2>((Iterable<T1>, Iterable<T2>) its) =>
    _ComputedIterable<(Iterable<T1>, Iterable<T2>),
        (Iterator<T1>, Iterator<T2>)>(_IterationStrategy2<T1, T2>(), its);

Iterable<(T1, T2, T3)> zip3<T1, T2, T3>(
        (Iterable<T1>, Iterable<T2>, Iterable<T3>) its) =>
    _ComputedIterable(_IterationStrategy3<T1, T2, T3>(), its);

class _IterationStrategy2<T1, T2>
    implements
        _IterationStrategy<(Iterable<T1>, Iterable<T2>),
            (Iterator<T1>, Iterator<T2>)> {
  (Iterator<T1>, Iterator<T2>) iterator(
          (Iterable<T1>, Iterable<T2>) iterables) =>
      (iterables.$1.iterator, iterables.$2.iterator);
}

class _IterationStrategy3<T1, T2, T3>
    implements
        _IterationStrategy<(Iterable<T1>, Iterable<T2>, Iterable<T3>),
            (Iterator<T1>, Iterator<T2>, Iterator<T3>)> {
  (Iterator<T1>, Iterator<T2>, Iterator<T3>) iterator(
          (Iterable<T1>, Iterable<T2>, Iterable<T3>) iterables) =>
      (iterables.$1.iterator, iterables.$2.iterator, iterables.$3.iterator);
}

class _ComputedIterable<S, I extends Object> extends Iterable<Never> {
  // !! Changing this to only storing the `I Function(S)` function
  // avoids the error.
  final _IterationStrategy<S, I> _strategy;
  final S _iterableState;

  _ComputedIterable(this._strategy, this._iterableState);

  int get length {
    // !! Fails here.
    _strategy.iterator(_iterableState);
    return 0;
  }

  Iterator<Never> get iterator => throw UnimplementedError("Not used");
  bool get isEmpty => throw UnimplementedError("Not used");
  bool get isNotEmpty => throw UnimplementedError("Not used");
  Never get first => throw UnimplementedError("Not used");
  Never get single => throw UnimplementedError("Not used");
  Never elementAt(int index) => throw UnimplementedError("Not used");
}

abstract interface class _IterationStrategy<S, I extends Object> {
  I iterator(S iterable);
}
