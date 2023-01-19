// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'null_value.dart' show NullValue;

/// [ValueKind] is used in [StackListener.checkState] to document and check the
/// expected values of the stack.
///
/// Add new value kinds as needed for documenting and checking the various stack
/// listener implementations.
abstract class ValueKind {
  const ValueKind();

  /// Checks the [value] an returns `true` if the value is of the expected kind.
  bool check(Object? value);
}

/// A [ValueKind] for a particular type [T], optionally with a recognized
/// [NullValue].
class SingleValueKind<T> implements ValueKind {
  // TODO(johnniwinther): Type this as `NullValue<T>?`.
  final NullValue<Object>? nullValue;

  const SingleValueKind([this.nullValue]);

  @override
  bool check(Object? value) {
    if (nullValue != null && value == nullValue) {
      return true;
    }
    return value is T;
  }

  @override
  String toString() {
    if (nullValue != null) {
      return '$T or $nullValue';
    }
    return '$T';
  }
}

/// A [ValueKind] for the union of a list of [ValueKind]s.
class UnionValueKind implements ValueKind {
  final List<ValueKind> kinds;

  const UnionValueKind(this.kinds);

  @override
  bool check(Object? value) {
    for (ValueKind kind in kinds) {
      if (kind.check(value)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    String or = '';
    for (ValueKind kind in kinds) {
      sb.write(or);
      sb.write(kind);
      or = ' or ';
    }
    return sb.toString();
  }
}

/// Helper method for creating a list of [ValueKind]s of the given length
/// [count].
List<ValueKind> repeatedKind(ValueKind kind, int count) {
  return new List.generate(count, (_) => kind);
}

/// Helper method for creating a list of [count] repetitions of a sequence of
/// [ValueKind]s.
List<ValueKind> repeatedKinds(List<ValueKind> kinds, int count) {
  List<ValueKind> list = [];
  for (int i = 0; i < count; i++) {
    list.addAll(kinds);
  }
  return list;
}

/// Helper method for creating a union of a list of [ValueKind]s.
ValueKind unionOfKinds(List<ValueKind> kinds) {
  return new UnionValueKind(kinds);
}
