// Copyright 2015 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class Key {
  const factory Key(String value) = ValueKey<String>;

  const Key._();
}

abstract class LocalKey extends Key {
  const LocalKey() : super._();
}

class UniqueKey extends LocalKey {
  UniqueKey();
}

class ValueKey<T> extends LocalKey {
  final T value;

  const ValueKey(this.value);
}
