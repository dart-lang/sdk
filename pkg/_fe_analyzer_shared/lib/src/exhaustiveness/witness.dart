// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_template_buffer.dart';
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

  /// The static type of the context. [valueType] is a subtype of this type.
  final StaticType staticType;

  /// The type this predicate tests.
  // TODO(johnniwinther): In order to model exhaustiveness on enum types,
  // bool values, and maybe integers at some point, we may later want a separate
  // kind of predicate that means "this value was equal to this constant".
  final StaticType valueType;

  Predicate(this.path, this.staticType, this.valueType);

  @override
  String toString() => 'Predicate(path=$path,type=$valueType)';
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
  late final PropertyWitness _witness = _buildWitness();

  Witness(this._predicates);

  PropertyWitness _buildWitness() {
    PropertyWitness witness = new PropertyWitness();

    for (Predicate predicate in _predicates) {
      PropertyWitness here = witness;
      for (Key field in predicate.path.toList()) {
        here = here.properties.putIfAbsent(field, () => new PropertyWitness());
      }
      here.staticType = predicate.staticType;
      here.valueType = predicate.valueType;
    }
    return witness;
  }

  String get asWitness => _witness.asWitness;

  String get asCorrection => _witness.asCorrection;

  /// Writes a representation of this witness to the given [buffer].
  void toDart(DartTemplateBuffer buffer, {required bool forCorrection}) {
    _witness.witnessToDart(buffer, forCorrection: forCorrection);
  }

  @override
  String toString() => _witness.toString();
}

/// Helper class used to turn a list of [Predicates] into a string.
class PropertyWitness {
  StaticType staticType = StaticType.nullableObject;
  StaticType valueType = StaticType.nullableObject;
  final Map<Key, PropertyWitness> properties = {};

  void witnessToDart(DartTemplateBuffer buffer, {required bool forCorrection}) {
    if (properties.isNotEmpty) {
      Map<StaticType, Map<Key, PropertyWitness>> witnessFieldsByType = {};
      for (MapEntry<Key, PropertyWitness> entry in properties.entries) {
        Key key = entry.key;
        PropertyWitness witness = entry.value;
        if (forCorrection && witness.isTrivial) {
          continue;
        }
        if (key is ExtensionKey) {
          (witnessFieldsByType[key.receiverType] ??= {})[key] = witness;
        } else {
          (witnessFieldsByType[valueType] ??= {})[key] = witness;
        }
      }
      if (witnessFieldsByType.isNotEmpty) {
        String and = '';
        for (MapEntry<StaticType, Map<Key, PropertyWitness>> entry
            in witnessFieldsByType.entries) {
          StaticType type = entry.key;
          Map<Key, PropertyWitness> witnessFields = entry.value;
          buffer.write(and);
          and = ' && ';
          type.witnessToDart(buffer, this, witnessFields,
              forCorrection: forCorrection);
        }
      } else {
        valueType.witnessToDart(buffer, this, const {},
            forCorrection: forCorrection);
      }
    } else {
      valueType.witnessToDart(buffer, this, const {},
          forCorrection: forCorrection);
    }
  }

  bool get isTrivial {
    if (!staticType.isSubtypeOf(valueType)) return false;
    for (PropertyWitness property in properties.values) {
      if (!property.isTrivial) {
        return false;
      }
    }
    return true;
  }

  /// Returns the witness as pattern syntax including all subproperties.
  String get asWitness {
    DartTemplateBuffer buffer = new SimpleDartBuffer();
    witnessToDart(buffer, forCorrection: false);
    return buffer.toString();
  }

  /// Return the witness as pattern syntax without subproperties that fully
  /// match the static type.
  String get asCorrection {
    DartTemplateBuffer buffer = new SimpleDartBuffer();
    witnessToDart(buffer, forCorrection: true);
    return buffer.toString();
  }

  @override
  String toString() => asWitness;
}
