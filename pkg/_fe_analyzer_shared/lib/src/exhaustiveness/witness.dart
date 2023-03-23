// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'key.dart';
import 'path.dart';
import 'static_type.dart';

/// Describes a pattern that matches the value or a field accessed from it.
///
/// Used only to generate the witness description.
class Predicate {
  /// The path of getters that led from the original matched value to the value
  /// tested by this predicate.
  final Path path;

  /// The type this predicate tests.
  // TODO(johnniwinther): In order to model exhaustiveness on enum types,
  // bool values, and maybe integers at some point, we may later want a separate
  // kind of predicate that means "this value was equal to this constant".
  final StaticType type;

  Predicate(this.path, this.type);

  @override
  String toString() => 'Predicate(path=$path,type=$type)';
}

/// Witness that show an unmatched case.
///
/// This is used to builds a human-friendly pattern-like string for the witness
/// matched by [_predicates].
///
/// For example, given:
///
///     [] is U
///     ['w'] is T
///     ['w', 'x'] is B
///     ['w', 'y'] is B
///     ['z'] is T
///     ['z', 'x'] is C
///     ['z', 'y'] is B
///
/// the [toString] produces:
///
///     'U(w: T(x: B, y: B), z: T(x: C, y: B))'
class Witness {
  final List<Predicate> _predicates;
  late final FieldWitness _witness = _buildWitness();

  Witness(this._predicates);

  FieldWitness _buildWitness() {
    FieldWitness witness = new FieldWitness();

    for (Predicate predicate in _predicates) {
      FieldWitness here = witness;
      for (Key field in predicate.path.toList()) {
        here = here.fields.putIfAbsent(field, () => new FieldWitness());
      }
      here.type = predicate.type;
    }
    return witness;
  }

  @override
  String toString() => _witness.toString();
}

/// Helper class used to turn a list of [Predicates] into a string.
class FieldWitness {
  StaticType type = StaticType.nullableObject;
  final Map<Key, FieldWitness> fields = {};

  void witnessToText(StringBuffer buffer) {
    type.witnessToText(buffer, this, fields);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    witnessToText(sb);
    return sb.toString();
  }
}
