// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  late final _Witness _witness = _buildWitness();

  Witness(this._predicates);

  _Witness _buildWitness() {
    _Witness witness = new _Witness();

    for (Predicate predicate in _predicates) {
      _Witness here = witness;
      for (String field in predicate.path.toList()) {
        here = here.fields.putIfAbsent(field, () => new _Witness());
      }
      here.type = predicate.type;
    }
    return witness;
  }

  @override
  String toString() => _witness.toString();
}

/// Helper class used to turn a list of [Predicates] into a string.
class _Witness {
  StaticType type = StaticType.nullableObject;
  final Map<String, _Witness> fields = {};

  void _buildString(StringBuffer buffer) {
    if (!type.isRecord) {
      buffer.write(type);
    }

    if (fields.isNotEmpty) {
      buffer.write('(');
      bool first = true;
      fields.forEach((name, field) {
        if (!first) buffer.write(', ');
        first = false;

        buffer.write(name);
        buffer.write(': ');
        field._buildString(buffer);
      });
      buffer.write(')');
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    _buildString(sb);
    return sb.toString();
  }
}
