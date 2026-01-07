// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtType<T>(T value) {}

abstract interface class MySink<T extends ExtType> {
  void add(T value);

  factory MySink() = _MySink<T>;
}

class _MySink<T extends ExtType> implements MySink<T> {
  @override
  void add(T value) {}
}

extension MySinkExt<T extends ExtType> on MySink<T> {
  MySink<T> spying({required void Function(T value) onAdd}) {
    return _Spying(this, onAdd);
  }
}

class _Spying<T extends ExtType> implements MySink<T> {
  final MySink<T> _delegate;
  final void Function(T value) _onAdd;

  _Spying(this._delegate, this._onAdd);

  @override
  void add(T value) {
    _delegate.add(value);
    _onAdd(value);
  }
}

void main() {}
