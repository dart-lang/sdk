// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_template_buffer.dart';
import 'key.dart';
import 'path.dart';
import 'space.dart';
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

  /// The supertypes of [valueType] that were tested for exhaustiveness before
  /// [valueType] was tested, ordered from the outermost to the immediate
  /// supertype.
  final List<StaticType>? superTypes;

  /// The type this predicate tests.
  // TODO(johnniwinther): In order to model exhaustiveness on enum types,
  // bool values, and maybe integers at some point, we may later want a separate
  // kind of predicate that means "this value was equal to this constant".
  final StaticType valueType;

  /// The original [valueType] for this predicate.
  ///
  /// This is used in [Witness.reduce] to track whether two predicates
  /// originally are aliases.
  ///
  /// For instance if we have the hierarchy
  ///
  ///     sealed class S {}
  ///     sealed class A extends S {}
  ///     sealed class SImpl implements S {}
  ///     class AImpl extends SImpl implements A {}
  ///
  /// then we can get a predicate for `AImpl` both through `A` and `SImpl`.
  /// Such predicates are aliases and a reduction for one whose [valueType] is
  /// a supertype of the other would exhaust both.
  final StaticType originalValueType;

  new({
    required this.path,
    required this.staticType,
    required this.superTypes,
    required this.valueType,
    StaticType? originalValueType,
  }) : originalValueType = originalValueType ?? valueType;

  /// Returns `true` if this predicate is an alias of [other] that is less
  /// specific than [other].
  ///
  /// A predicate, A, is an alias of another predicate, B, if they have the
  /// same [path] and [originalValueType]. Furthermore, A is less specific
  /// than B if the [valueType] of B is a subtype of the [valueType] of A.
  ///
  /// For instance consider this hierarchy:
  ///
  ///     sealed class S;
  ///     sealed class A extends S;
  ///     sealed class B extends S;
  ///     sealed class SImpl implements S;
  ///     class AImpl extends SImpl implements A;
  ///     class BImpl extends SImpl implements B;
  ///
  /// where the *Impl classes are inaccessible outside their package. If we
  /// have a non-exhaustive switch like
  ///
  ///     m(S s) => switch (s) {};
  ///
  /// we will compute four witnesses with the root predicates `AImpl` with
  /// supertype `A`, `AImpl` with supertype `SImpl`, `BImpl` with supertype `B`,
  /// and `BImpl` with supertype `SImpl`.
  ///
  /// If the switch occurs outside the package, these witnesses are not
  /// accessible and we will therefore compute reduced witnesses using
  /// [Witness.reduce] with these root predicates:
  ///
  ///     * For `AImpl` with supertype `A` we compute `A`.
  ///     * For `AImpl` with supertype `SImpl` we compute `S`.
  ///     * For `BImpl` with supertype `B` we compute `B`.
  ///     * For `BImpl` with supertype `SImpl` we compute `S`.
  ///
  /// Since the first two predicates have the same original value type, `AImpl`,
  /// they are aliases, and since `A` is a subtype of `S`, `S` is also
  /// less specific than `A`. Similarly for the last two predicates.
  bool isLessSpecificAliasThan(Predicate other) {
    return path == other.path &&
        originalValueType.isSubtypeOf(other.originalValueType) &&
        other.originalValueType.isSubtypeOf(originalValueType) &&
        other.valueType.isSubtypeOf(valueType);
  }

  /// Returns `true` if this predicate is more specific than [other].
  ///
  /// A predicate, A, is more specific than another predicate, B, if both
  /// predicates have the same path and the [valueType] of A is a subtype of the
  /// [valueType] of B.
  ///
  /// For instance if we have this hierarchy
  ///
  ///     sealed class S;
  ///     sealed class A extends S;
  ///     sealed class B extends S;
  ///     sealed class SImpl implements S;
  ///     class AImpl extends SImpl implements A;
  ///     class BImpl extends SImpl implements B;
  ///
  /// then the predicate `AImpl` is more specific than `A` and `BImpl` is
  /// more specific than `B`.
  bool isMoreSpecificThan(Predicate other) =>
      path == other.path && valueType.isSubtypeOf(other.valueType);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Predicate(path=$path,type=$valueType');
    if (valueType != originalValueType) {
      sb.write(',original=$originalValueType');
    }
    sb.write(')');
    return sb.toString();
  }
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

  /// If this witness was created through a reduction in [Witness.reduce]
  /// this holds the original witness.
  final Witness? _originalWitness;

  new(this._predicates, {Witness? originalWitness})
    : _originalWitness = originalWitness;

  /// Whether this witness was created through a reduction in [Witness.reduce].
  bool get isReduced => _originalWitness != null;

  /// Returns the original witness if this witness was reduced, or the witness
  /// itself otherwise.
  Witness get originalWitness => _originalWitness ?? this;

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

  /// Returns `true` if this witness is trivial.
  ///
  /// A witness is trivial if it fully covers the value space.
  ///
  /// For instance
  ///
  ///     method(String s) => switch (s) {
  ///       String(length: 0) => 0,
  ///       Object(:int hashCode) => 1,
  ///     };
  ///
  /// the pattern `Object(:int hashCode)` is trivial whereas `String(length: 0)`
  /// is not because it doesn't cover non-empty strings.
  bool get isTrivial => _witness.isTrivial;

  /// Returns `true` if this witness is more specific than [other].
  ///
  /// A witness, A, is more specific than another witness, B, if the pattern
  /// corresponding to A will be matched by all values that the pattern
  /// corresponding to B will match.
  ///
  /// For instance if we have this hierarchy
  ///
  ///     sealed class S;
  ///     sealed class A extends S;
  ///     sealed class B extends S;
  ///     sealed class SImpl implements S;
  ///     class AImpl extends SImpl implements A;
  ///     class BImpl extends SImpl implements B;
  ///
  /// then the witness `AImpl()` is more specific than `A()` and `BImpl()` is
  /// more specific than `B()`.
  bool isMoreSpecificThan(Witness other) {
    if (_predicates.length != other._predicates.length) {
      return false;
    }
    for (int index = 0; index < _predicates.length; index++) {
      Predicate thisPredicate = _predicates[index];
      Predicate otherPredicate = other._predicates[index];
      if (!thisPredicate.isMoreSpecificThan(otherPredicate)) {
        return false;
      }
    }
    return true;
  }

  /// Returns `true` if this witness is an alias of [other] that is less
  /// specific than [other].
  ///
  /// A witness, A, is an alias of another witness, B, if they have the same
  /// [originalWitness]. Furthermore, A is less specific than B if the pattern
  /// corresponding to B will be matched by all values that the pattern
  /// corresponding to A will match.
  ///
  /// For instance consider this hierarchy:
  ///
  ///     sealed class S;
  ///     sealed class A extends S;
  ///     sealed class B extends S;
  ///     sealed class SImpl implements S;
  ///     class AImpl extends SImpl implements A;
  ///     class BImpl extends SImpl implements B;
  ///
  /// where the *Impl classes are inaccessible outside their package. If we
  /// have a non-exhaustive switch like
  ///
  ///     m(S s) => switch (s) {};
  ///
  /// we will compute the four witnesses `AImpl()` through `A`, `AImpl()`
  /// through `SImpl`, `BImpl()` through `B`, and `BImpl()` through `SImpl`.
  ///
  /// If the switch occurs outside the package, these witnesses are not
  /// accessible and we will therefore compute these reduced witnesses using
  /// [reduce]:
  ///
  ///     * For `AImpl()` through `A` we compute `A()`.
  ///     * For `AImpl()` through `SImpl` we compute `S()`.
  ///     * For `BImpl()` through `B` we compute `B()`.
  ///     * For `BImpl()` through `SImpl` we compute `S()`.
  ///
  /// Since the first two witnesses have the same original witness, `AImpl()`,
  /// they are aliases, and since the pattern corresponding to `S()` will match
  /// all values that match the pattern corresponding to `A()`, `S()` is also
  /// less specific than `A()`. Similarly for the last two witnesses.
  bool isLessSpecificAliasThan(Witness other) {
    if (_predicates.length != other._predicates.length) {
      return false;
    }
    for (int index = 0; index < _predicates.length; index++) {
      Predicate thisPredicate = _predicates[index];
      Predicate otherPredicate = other._predicates[index];
      if (!thisPredicate.isLessSpecificAliasThan(otherPredicate)) {
        return false;
      }
    }
    return true;
  }

  /// Returns `true` if this witness is less specific than [space].
  ///
  /// A witness, A, is less specific than a space, B, if B will be matched by
  /// all values that the pattern corresponding to A will match.
  ///
  /// For instance consider this hierarchy
  ///
  ///     sealed class A;
  ///     sealed class B implements A;
  ///     abstract final class C implements B;
  ///     final class BImpl extends B;
  ///
  /// where only `A`, `B`, and `C` are accessible outside their package. If we
  /// have this non-exhaustive but partial switch
  ///
  ///     m(A a) => switch (a) {
  ///       C() => 0,
  ///     };
  ///
  /// we find the witness `BImpl()` through `B`.
  ///
  /// If the switch occurs outside the package, we will reduce `BImpl()` to
  /// `B()` using [reduce]. Since all values that match `C()` will be matched by
  /// `B()`, `B()` is less specific than the space `C`.
  bool isLessSpecificThanSpace(Space space) {
    if (_predicates.length == 1) {
      for (SingleSpace singleSpace in space.singleSpaces) {
        if (singleSpace.type.isSubtypeOf(_predicates.first.valueType)) {
          return true;
        }
      }
    }
    return false;
  }

  String get asWitness => _witness.asWitness;

  String get asCorrection => _witness.asCorrection;

  /// Writes a representation of this witness to the given [buffer].
  void toDart(DartTemplateBuffer buffer, {required bool forCorrection}) {
    _witness.witnessToDart(buffer, forCorrection: forCorrection);
  }

  /// Computes a sound approximation of this witness that is accessible as
  /// determined by [accessibility].
  ///
  /// If the witness is accessible, it itself is returned. Otherwise a reduced
  /// witness is created with an accessible value type.
  ///
  /// For instance if we have this hierarchy
  ///
  ///     sealed class A;
  ///     abstract class B;
  ///     sealed class _AImpl extends A;
  ///     class _BImpl extends _AImpl implements B;
  ///
  /// and the non-exhaustive switch expression
  ///
  ///     m(A a) => switch (a) {};
  ///
  /// outside the library, the witness `_BImpl()` that we find through `_AImpl`
  /// is not accessible, and we will reduce it to `A()` with an original value
  /// type of `_BImpl`.
  Future<Witness> reduce(DartAccessibility accessibility) async {
    bool changed = false;
    List<Predicate> newPredicates = [];
    for (Predicate predicate in _predicates) {
      if (!await predicate.valueType.isAccessible(accessibility)) {
        StaticType? superType;
        List<StaticType>? newSuperTypes;
        List<StaticType>? superTypes = predicate.superTypes;
        if (superTypes != null) {
          int index = superTypes.length;
          while (--index >= 0) {
            StaticType staticType = superTypes[index];
            if (await staticType.isAccessible(accessibility)) {
              superType = staticType;
              break;
            }
          }
          if (index > 0) {
            newSuperTypes = superTypes.sublist(0, index);
          }
        }
        Predicate newPredicate;
        if (superType != null) {
          newPredicate = new Predicate(
            path: predicate.path,
            staticType: predicate.staticType,
            superTypes: newSuperTypes,
            valueType: superType,
            originalValueType: predicate.originalValueType,
          );
        } else if (!await predicate.staticType.isAccessible(accessibility)) {
          newPredicate = new Predicate(
            path: predicate.path,
            staticType: predicate.staticType,
            superTypes: null,
            valueType: StaticType.nullableObject,
            originalValueType: predicate.originalValueType,
          );
        } else {
          newPredicate = new Predicate(
            path: predicate.path,
            staticType: predicate.staticType,
            superTypes: null,
            valueType: predicate.staticType,
            originalValueType: predicate.originalValueType,
          );
        }
        newPredicates.add(newPredicate);
        changed = true;
      } else {
        newPredicates.add(predicate);
      }
    }
    return changed ? new Witness(newPredicates, originalWitness: this) : this;
  }

  @override
  String toString() => _witness.toString();
}

/// Helper class used to turn a list of [Predicate]s into a string.
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
          type.witnessToDart(
            buffer,
            this,
            witnessFields,
            forCorrection: forCorrection,
          );
        }
      } else {
        valueType.witnessToDart(
          buffer,
          this,
          const {},
          forCorrection: forCorrection,
        );
      }
    } else {
      valueType.witnessToDart(
        buffer,
        this,
        const {},
        forCorrection: forCorrection,
      );
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

/// Helper class used for converting the witnesses found in a non-exhaustive
/// switch to concrete witnesses that are accessible at the call-site, and for
/// determining whether the call-site needs a default case due to inaccessible
/// witnesses.
class ReducedWitnesses {
  /// The potentially reduced witnesses that can be used to handle missing
  /// switch cases at the call-site.
  final List<Witness> nonTrivialWitnesses;

  /// `true` if a default case is needed at the call-site.
  final bool needsDefault;

  new({required this.nonTrivialWitnesses, required this.needsDefault});

  /// This computes the [ReducedWitnesses] for a non-exhaustive switch
  /// expression/statement with given [caseSpaces] and found [witnesses] using
  /// [accessibility] to determine which parts of the witnesses are accessible
  /// at the call site.
  ///
  /// For instance, consider this hierarchy
  ///
  ///     sealed class S;
  ///     sealed class A extends S;
  ///     sealed class B extends S;
  ///     sealed class SImpl implements S;
  ///     class AImpl extends SImpl implements A;
  ///     class BImpl extends SImpl implements B;
  ///
  /// where only `S`, `A`, and `B` are exported from the package.
  ///
  /// If we have an empty switch like
  ///
  ///     m(S s) => switch (s) {};
  ///
  /// it would result in the reporting that it is non-exhaustive with the
  /// witnesses `AImpl()` and `BImpl()`.
  ///
  /// Depending on whether `m` is located inside or outside the package we have
  /// two different ways to create a quick-fix that exhausts the switch
  /// expression.
  ///
  /// If `m` is located inside the package, we would like a quick-fix that adds
  /// cases for the *Impl classes:
  ///
  ///     m(S s) => switch (s) {
  ///       // TODO: Handle this case.
  ///       AImpl() => throw UnimplementedError(),
  ///       // TODO: Handle this case.
  ///       BImpl() => throw UnimplementedError(),
  ///     };
  ///
  /// If on the other hand `m` is located outside the package, then because
  /// the *Impl classes are not exported from the package, they should be seen
  /// as inaccessible and we should therefore instead generate a quick-fix that
  /// adds the exported classes:
  ///
  ///     m(S s) => switch (s) {
  ///       // TODO: Handle this case.
  ///       A() => throw UnimplementedError(),
  ///       // TODO: Handle this case.
  ///       B() => throw UnimplementedError(),
  ///     };
  ///
  /// Similarly if we have an enum like
  ///
  ///     enum E { a, b, _c }
  ///
  /// where some of the enum elements are not accessible outside the library,
  /// and a non-exhaustive switch expression like
  ///
  ///     m(E e) => switch (e) {
  ///       E.a => 0,
  ///     };
  ///
  /// then inside the library we would like to generate a quick-fix that
  /// adds all enum elements:
  ///
  ///     m(E e) => switch (e) {
  ///       E.a => 0,
  ///       // TODO: Handle this case.
  ///       E.b => throw UnimplementedError(),
  ///       // TODO: Handle this case.
  ///       E._c => throw UnimplementedError(),
  ///     };
  ///
  /// but outside the library we would like to generate a quick-fix that adds
  /// a wildcard case that handles the inaccessible values:
  ///
  ///     m(E e) => switch (e) {
  ///       E.a => 0,
  ///       // TODO: Handle this case.
  ///       E.b => throw UnimplementedError(),
  ///       // TODO: Handle this case.
  ///       _ => throw UnimplementedError(),
  ///     };
  ///
  static Future<ReducedWitnesses> computeReducedWitnesses(
    List<Space> caseSpaces,
    List<Witness> witnesses,
    DartAccessibility accessibility,
  ) async {
    List<Witness> accessibleWitnesses = await _computeAccessibleWitnesses(
      witnesses,
      accessibility,
    );
    List<Witness> neededWitnesses = _computeNeededWitnesses(
      accessibleWitnesses,
    );
    return _computeDefaultWitnesses(neededWitnesses, caseSpaces);
  }

  /// Processes [witnesses] using [accessibility] and returns the accessible
  /// witnesses corresponding to [witnesses].
  ///
  /// For instance if we have the enum
  ///
  ///     enum E { a, b, _c }
  ///
  /// with the non-exhaustive switch expression
  ///
  ///     m(E e) => switch (e) {};
  ///
  /// then the witnesses found by the exhaustiveness algorithm will be `E.a`,
  /// `E.b`, and `E._c`.
  ///
  /// If the switch expression occurs outside the library, such that `E._c` is
  /// not accessible, the corresponding accessible witnesses will be `E.a`,
  /// `E.b`, and `E()` reduced from `E._c`.
  static Future<List<Witness>> _computeAccessibleWitnesses(
    List<Witness> witnesses,
    DartAccessibility accessibility,
  ) async {
    List<Witness> result = [];
    nextWitness:
    for (Witness previousWitness in witnesses) {
      Witness reducedWitness = await previousWitness.reduce(accessibility);
      int index = 0;
      while (index < result.length) {
        Witness existingWitness = result[index];
        // If the [reducedWitness] is an alias of [existingWitness] but is
        // less specific, then we don't need [reducedWitness], and vice versa.
        //
        // For instance if we have this hierarchy:
        //
        //     sealed class S;
        //     sealed class A implements S;
        //     sealed class B implements S;
        //     sealed class SImpl extends S;
        //     class AImpl extends SImpl implements A;
        //     class BImpl extends SImpl implements B;
        //
        // where only `S`, `A`, and `B` are exported, then if we have this
        // non-exhaustive switch
        //
        //     m(S s) => switch (s) {};
        //
        // we find the four witnesses `AImpl` through `A`, `BImpl` through
        // `B`, `AImpl` through `SImpl`, and `BImpl` through `SImpl`.
        if (reducedWitness.isLessSpecificAliasThan(existingWitness)) {
          // When `A` is declared before `SImpl` we will reduce `AImpl` through
          // `A` to `A` before reducing `AImpl` through `SImpl` to `S`, and the
          // latter is therefore a less specific alias of the former so we
          // remove the latter.
          continue nextWitness;
        } else if (existingWitness.isLessSpecificAliasThan(reducedWitness)) {
          // When `SImpl` is declared before `A` we will reduce `AImpl`
          // through `SImpl` to `A` before reducing `AImpl` through `A` to `A`,
          // and the former is therefore a less specific alias of the latter so
          // we remove the former.
          result.removeAt(index);
        } else {
          index++;
        }
      }
      result.add(reducedWitness);
    }
    return result;
  }

  /// Filters [witnesses] to a list of witnesses that cover the same
  /// values but without redundancies caused by reductions performed
  /// in [_computeAccessibleWitnesses].
  ///
  /// For instance if we have the class hierarchy
  ///
  ///     sealed class A;
  ///     sealed class B extends A;
  ///     abstract final class C extends B;
  ///     class _CImpl extends B implements C;
  ///
  /// and the non-exhaustive switch expression
  ///
  ///     m(A a) => switch (a) {};
  ///
  /// in a library in which `_CImpl` is not accessible, then we would find the
  /// accessible witnesses to be `C()` and `B()` (reduced from `_CImpl()`) with
  /// the latter being redundant since `_CImpl` is a subtype of `C`.
  static List<Witness> _computeNeededWitnesses(List<Witness> witnesses) {
    List<Witness> result = [];
    nextWitness:
    for (Witness previousWitness in witnesses) {
      int index = 0;
      while (index < result.length) {
        Witness existingWitness = result[index];
        // If the [previousWitness] is a reduced witness whose original
        // witness is more specific than the original witness of
        // [existingWitness], then we don't need [previousWitness], and vice
        // versa.
        //
        // For instance if we have this hierarchy:
        //
        //     sealed class A;
        //     sealed class B implements A;
        //     abstract final class C implements B;
        //     final class CImpl extends B implements C;
        //
        // where only `A`, `B`, and `C` are exported, then if we have this
        // non-exhaustive switch
        //
        //     m(A a) => switch (a) {};
        //
        // we find the two witnesses `C` and `CImpl`, both through `B`.
        //
        // Note that we need to check the more-specific relation between the
        // original witnesses because we would otherwise risk losing coverage
        // in the missing switch cases generated by the quick fix.
        //
        // For instance if we have this hierarchy:
        //
        //     sealed class A;
        //     sealed class B implements A;
        //     final class _CImpl extends B implements C;
        //     final class _BImpl extends B;
        //     abstract final class C implements B;
        //
        // where only `A`, `B`, and `C` are exported, then if we have this
        // non-exhaustive switch
        //
        //     m(A a) => switch (a) {};
        //
        // we find the three witnesses `B` from `_CImpl`, `B` from `_BImpl`, and
        // `C`. Since the first two are reduced to `B` we would find that both
        // original witnesses, `_CImpl` and `_BImpl` are more specific than
        // their reduction, `B`. If we were to consider `B` from `_BImpl` to
        // _not_ be needed because `_BImpl` is more specific than `B` reduced
        // from `_CImpl` and therefore discard it, we would later discard `B`
        // from `_CImpl` in favor of `C` since it is more specific than `C`.
        // This would lead us to only generate a missing case for `C` and thus
        // create a non-exhaustive fix, missing a case for `_BImpl`.
        if (previousWitness.isReduced &&
            previousWitness.originalWitness.isMoreSpecificThan(
              existingWitness.originalWitness,
            )) {
          // When `C` is declared before `CImpl`, `C` will not be reduced and
          // we will reduce `CImpl` to `B` afterwards, and since `CImpl` is
          // more specific than `C` we remove it, instead of including the
          // otherwise unneeded witness `B`.
          continue nextWitness;
        } else if (existingWitness.isReduced &&
            existingWitness.originalWitness.isMoreSpecificThan(
              previousWitness.originalWitness,
            )) {
          // When `CImpl` is declared before `C`, we will reduce `CImpl` to `B`
          // first but will not reduce `C`, and since `CImpl` is more specific
          // than `C` we remove it, instead of including the otherwise unneeded
          // witness `B`.
          result.removeAt(index);
        } else {
          index++;
        }
      }
      result.add(previousWitness);
    }
    return result;
  }

  /// Computes which of the [witnesses] should be considered "trivial"
  /// given the other witnesses and the [caseSpaces] from the cases already
  /// present in the code.
  ///
  /// A witness is considered trivial if it is reduced to cover the whole
  /// exhaustive space. For instance if we have the enum
  ///
  ///     enum E { _a }
  ///
  /// and the non-exhaustive switch expression
  ///
  ///     m(E e) => switch (e) {};
  ///
  /// outside the library of `E`, then we would compute the needed witness to
  /// be `E()` reduced from `E._a`. Since this witness matches all values as a
  /// consequence of reduction, we consider it trivial.
  ///
  /// In quick fixes, trivial witnesses are matched using a default case to
  /// better signal that there were cases that could not be directly exhausted.
  static ReducedWitnesses _computeDefaultWitnesses(
    List<Witness> witnesses,
    List<Space> caseSpaces,
  ) {
    bool needsDefault = false;
    List<Witness> result = [];
    nextWitness:
    for (Witness previousWitness in witnesses) {
      // If [previousWitness] is reduced to be trivial, that is, it is less
      // specific than the root of the matched value space, then
      // [previousWitness] should be a default case.
      //
      // For instance if we have this enum
      //
      //     enum E { _a }
      //
      // and the non-exhaustive switch expression outside its library
      //
      //     m(E e) => switch (e) {};
      //
      // then we would compute the witness `E._a` and reduce it to `E()` because
      // `_a` is not accessible. Since `E()` matches all values of the switch
      // expression it is trivial and we use a default case for matching it to
      // signal that there are witnesses, `E._a` in this case, that are not
      // expressible at the call site.
      if (previousWitness.isReduced && previousWitness.isTrivial) {
        needsDefault = true;
        continue nextWitness;
      }

      int index = 0;
      while (index < result.length) {
        Witness existingWitness = result[index];
        // If the [previousWitness] is a reduced witness and [existingWitness]
        // is more specific than [previousWitness], then [previousWitness]
        // should be a default case, and vice versa.
        //
        // For instance if we have this hierarchy:
        //
        //     sealed class A;
        //     sealed class B implements A;
        //     abstract final class C implements B;
        //     final class BImpl extends B;
        //
        // where only `A`, `B`, and `C` are exported, then if we have this
        // non-exhaustive switch
        //
        //     m(A a) => switch (a) {};
        //
        // we find the two witnesses `C` and `BImpl`, both through `B`.
        if (previousWitness.isReduced &&
            existingWitness.isMoreSpecificThan(previousWitness)) {
          // When `C` is declared before `BImpl`, `C` will not be reduced and
          // we will reduce `BImpl` to `B` afterwards, and since `C` is
          // more specific than `B` we use a default case for matching it to
          // signal that there are witnesses, `BImpl` in this case, that are not
          // expressible at the call site.
          if (!previousWitness.isMoreSpecificThan(existingWitness)) {
            // Only need a default case if [existingWitness] is strictly more
            // specific than [previousWitness].
            needsDefault = true;
          }
          continue nextWitness;
        } else if (existingWitness.isReduced &&
            previousWitness.isMoreSpecificThan(existingWitness)) {
          // When `BImpl` is declared before `C`, we will reduce `BImpl` to `B`
          // first but will not reduce `C`, and since `C` is more specific
          // than `B` we use a default case for matching it to signal that there
          // are witnesses, `BImpl` in this case, that are not expressible at
          // the call site.
          result.removeAt(index);
          if (!existingWitness.isMoreSpecificThan(previousWitness)) {
            // Only need a default case if [previousWitness] is strictly more
            // specific than [existingWitness].
            needsDefault = true;
          }
        } else {
          index++;
        }
      }
      if (previousWitness.isReduced) {
        for (Space caseSpace in caseSpaces) {
          // If the [previousWitness] is a reduced witness that is less
          // specific than the space of an existing case, [caseSpace], then
          // [previousWitness] should be a default case.
          //
          // For instance if we have this hierarchy:
          //
          //     sealed class A;
          //     sealed class B implements A;
          //     abstract final class C implements B;
          //     final class BImpl extends B;
          //
          // where only `A`, `B`, and `C` are exported, then if we have this
          // non-exhaustive but partial switch
          //
          //     m(A a) => switch (a) {
          //       C() => 0,
          //     };
          //
          // we find the witness `BImpl` through `B`, which we reduce to `B`.
          // Since `B` is less specific than the space for `C()` we use a
          // default case for matching it to signal that there are witnesses,
          // `BImpl` in this case, that are not expressible at the call site.
          if (previousWitness.isLessSpecificThanSpace(caseSpace)) {
            needsDefault = true;
            continue nextWitness;
          }
        }
      }
      result.add(previousWitness);
    }
    return new ReducedWitnesses(
      nonTrivialWitnesses: result,
      needsDefault: needsDefault,
    );
  }
}
