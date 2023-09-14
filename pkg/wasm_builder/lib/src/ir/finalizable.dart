// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Some aspects of Wasm bytecode cannot be determined until after
/// finalizing the module graph, e.g. indices of certain objects. We could
/// rebuild any parts of the module graph that need indices when we finalize the
/// module. This would ensure indices are always final, but at the cost of
/// copying objects that otherwise wouldn't need to be copied. A lighter weight
/// approach might be to use interfaces to hide indices before finalization.
///
/// For the time being, we use [Finalizable] objects, which are part of the
/// module graph, but will throw if a user tries to access a non-final value.
class Finalizable<T> {
  T? _value;

  set value(T v) => finalize(v);

  T get value {
    final v = _value;
    if (v == null) {
      throw 'Value not yet finalized';
    }
    return v;
  }

  void finalize(T v) {
    if (_value != null) {
      throw 'Value already finalized';
    }
    _value = v;
  }

  bool get isFinal => _value == null;

  /// If we've been finalized, then print the finalized value, otherwise print a
  /// sentinel(NF - Not Final).
  @override
  String toString() => isFinal ? '$_value' : '<NF>';
}

typedef FinalizableIndex = Finalizable<int>;
