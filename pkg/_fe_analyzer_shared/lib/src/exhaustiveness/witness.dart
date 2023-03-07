// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'exhaustive.dart';
import 'profile.dart' as profile;
import 'static_type.dart';

/// Returns `true` if [caseSpaces] exhaustively covers all possible values of
/// [valueSpace].
bool isExhaustive(Space valueSpace, List<Space> caseSpaces) {
  return checkExhaustiveness(valueSpace, caseSpaces) == null;
}

/// Checks the [cases] representing a series of switch cases to see if they
/// exhaustively cover all possible values of the matched [valueType]. Also
/// checks to see if any case can't be matched because it's covered by previous
/// cases.
///
/// Returns a list of any unreachable case or non-exhaustive match errors.
/// Returns an empty list if all cases are reachable and the cases are
/// exhaustive.
List<ExhaustivenessError> reportErrors(
    StaticType valueType, List<Space> cases) {
  List<ExhaustivenessError> errors = <ExhaustivenessError>[];

  Space valuePattern = new Space(const Path.root(), valueType);
  List<List<Space>> caseRows = cases.map((space) => [space]).toList();

  for (int i = 1; i < caseRows.length; i++) {
    // See if this case is covered by previous ones.
    if (_unmatched(caseRows.sublist(0, i), caseRows[i]) == null) {
      errors.add(new UnreachableCaseError(valueType, cases, i));
    }
  }

  Witness? witness = _unmatched(caseRows, [valuePattern]);
  if (witness != null) {
    errors.add(new NonExhaustiveError(valueType, cases, witness));
  }

  return errors;
}

/// Determines if [cases] is exhaustive over all values contained by
/// [valueSpace]. If so, returns `null`. Otherwise, returns a string describing
/// an example of one value that isn't matched by anything in [cases].
Witness? checkExhaustiveness(Space valueSpace, List<Space> cases) {
  // TODO(johnniwinther): Perform reachability checking.
  List<List<Space>> caseRows = cases.map((space) => [space]).toList();

  Witness? witness = _unmatched(caseRows, [valueSpace]);

  // Uncomment this to have it print out the witness for non-exhaustive matches.
  // if (witness != null) print(witness);

  return witness;
}

/// Tries to find a pattern containing at least one value matched by
/// [valuePatterns] that is not matched by any of the patterns in [caseRows].
///
/// If found, returns it. This is a witness example showing that [caseRows] is
/// not exhaustive over all values in [valuePatterns]. If it returns `null`,
/// then [caseRows] exhaustively covers [valuePatterns].
Witness? _unmatched(List<List<Space>> caseRows, List<Space> valuePatterns,
    [List<Predicate> witnessPredicates = const []]) {
  assert(caseRows.every((element) => element.length == valuePatterns.length),
      "Value patterns: $valuePatterns, case rows: $caseRows.");
  profile.count('_unmatched');
  // If there are no more columns, then we've tested all the predicates we have
  // to test.
  if (valuePatterns.isEmpty) {
    // If there are still any rows left, then it means every remaining value
    // will go to one of those rows' bodies, so we have successfully matched.
    if (caseRows.isNotEmpty) return null;

    // If we ran out of rows too, then it means [witnessPredicates] is now a
    // complete description of at least one value that slipped past all the
    // rows.
    return new Witness(witnessPredicates);
  }

  // Look down the first column of tests.
  Space firstValuePatterns = valuePatterns[0];

  for (SingleSpace firstValuePattern in firstValuePatterns.singleSpaces) {
    // TODO(johnniwinther): Right now, this brute force expands all subtypes of
    // sealed types and considers them individually. It would be faster to look
    // at the types of the patterns in the first column of each row and only
    // expand subtypes that are actually tested.
    // Split the type into its sealed subtypes and consider each one separately.
    // This enables it to filter rows more effectively.
    List<StaticType> subtypes = expandSealedSubtypes(firstValuePattern.type);
    for (StaticType subtype in subtypes) {
      Witness? result = _filterByType(subtype, caseRows, firstValuePattern,
          valuePatterns, witnessPredicates, firstValuePatterns.path);

      // If we found a witness for a subtype that no rows match, then we can
      // stop. There may be others but we don't need to find more.
      if (result != null) return result;
    }
  }

  // If we get here, no subtype yielded a witness, so we must have matched
  // everything.
  return null;
}

Witness? _filterByType(
    StaticType type,
    List<List<Space>> caseRows,
    SingleSpace firstSingleSpaceValue,
    List<Space> valueSpaces,
    List<Predicate> witnessPredicates,
    Path path) {
  profile.count('_filterByType');
  // Extend the witness with the type we're matching.
  List<Predicate> extendedWitness = [
    ...witnessPredicates,
    new Predicate(path, type)
  ];

  // 1) Discard any rows that might not match because the column's type isn't a
  // subtype of the value's type.  We only keep rows that *must* match because a
  // row that could potentially fail to match will not help us prove
  // exhaustiveness.
  //
  // 2) Expand any unions in the first column. This can (deliberately) produce
  // duplicate rows in remainingRows.
  List<SingleSpace> remainingRowFirstSingleSpaces = [];
  List<List<Space>> remainingRows = [];
  for (List<Space> row in caseRows) {
    Space firstSpace = row[0];

    for (SingleSpace firstSingleSpace in firstSpace.singleSpaces) {
      // If the row's type is a supertype of the value pattern's type then it
      // must match.
      if (type.isSubtypeOf(firstSingleSpace.type)) {
        remainingRowFirstSingleSpaces.add(firstSingleSpace);
        remainingRows.add(row);
      }
    }
  }

  // We have now filtered by the type test of the first column of patterns, but
  // some of those may also have field subpatterns. If so, lift those out so we
  // can recurse into them.
  Set<String> fieldNames = {
    ...firstSingleSpaceValue.fields.keys,
    for (SingleSpace firstPattern in remainingRowFirstSingleSpaces)
      ...firstPattern.fields.keys
  };

  // Sorting isn't necessary, but makes the behavior deterministic.
  List<String> sorted = fieldNames.toList()..sort();

  // Remove the first column from the value list and replace it with any
  // expanded fields.
  valueSpaces = [
    ..._expandFields(sorted, firstSingleSpaceValue, type, path),
    ...valueSpaces.skip(1)
  ];

  // Remove the first column from each row and replace it with any expanded
  // fields.
  for (int i = 0; i < remainingRows.length; i++) {
    remainingRows[i] = [
      ..._expandFields(sorted, remainingRowFirstSingleSpaces[i],
          remainingRowFirstSingleSpaces[i].type, path),
      ...remainingRows[i].skip(1)
    ];
  }

  // Proceed to the next column.
  return _unmatched(remainingRows, valueSpaces, extendedWitness);
}

/// Given a list of [fieldNames] and a [singleSpace], generates a list of
/// single spaces, one for each named field.
///
/// When [singleSpace] contains a field with that name, extracts it into the
/// resulting list. Otherwise, the [singleSpace] doesn't care about that field,
/// so inserts a default [Space] that matches all values for the field.
///
/// In other words, this unpacks a set of fields so that the main algorithm can
/// add them to the worklist.
List<Space> _expandFields(List<String> fieldNames, SingleSpace singleSpace,
    StaticType type, Path path) {
  profile.count('_expandFields');
  List<Space> result = <Space>[];
  for (String fieldName in fieldNames) {
    Space? field = singleSpace.fields[fieldName];
    if (field != null) {
      result.add(field);
    } else {
      // This pattern doesn't test this field, so add a pattern for the
      // field that matches all values. This way the columns stay aligned.
      result.add(new Space(path.add(fieldName),
          type.fields[fieldName] ?? StaticType.nullableObject));
    }
  }

  return result;
}

/// Recursively expands [type] with its subtypes if its sealed.
///
/// Otherwise, just returns [type].
List<StaticType> expandSealedSubtypes(StaticType type) {
  profile.count('expandSealedSubtypes');
  if (!type.isSealed) return [type];

  return {
    for (StaticType subtype in type.subtypes) ...expandSealedSubtypes(subtype)
  }.toList();
}

/// The main pattern for matching types and destructuring.
///
/// It has a type which determines the type of values it contains. The type may
/// be [StaticType.nullableObject] to indicate that it doesn't filter by type.
///
/// It may also contain zero or more named fields. The pattern then only matches
/// values where the field values are matched by the corresponding field
/// patterns.
class SingleSpace {
  static final SingleSpace empty = new SingleSpace(StaticType.neverType);

  /// The type of values the pattern matches.
  final StaticType type;

  /// Any field subpatterns the pattern matches.
  final Map<String, Space> fields;

  SingleSpace(this.type, {this.fields = const {}});

  @override
  late final int hashCode = Object.hash(
      type,
      Object.hashAllUnordered(fields.keys),
      Object.hashAllUnordered(fields.values));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SingleSpace) return false;
    if (type != other.type) return false;
    if (fields.length != other.fields.length) return false;
    if (fields.isNotEmpty) {
      for (MapEntry<String, Space> entry in fields.entries) {
        if (entry.value != other.fields[entry.key]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String toString() {
    if (type == StaticType.nullableObject && fields.isEmpty) return '()';
    if (this == StaticType.neverType && fields.isEmpty) return '∅';

    if (type.isRecord) {
      StringBuffer buffer = new StringBuffer();
      buffer.write('(');
      bool first = true;
      type.fields.forEach((String name, StaticType staticType) {
        if (!first) buffer.write(', ');
        // TODO(johnniwinther): Ensure using Dart syntax for positional fields.
        buffer.write('$name: ${fields[name] ?? staticType}');
        first = false;
      });

      buffer.write(')');
      return buffer.toString();
    } else {
      // If there are no fields, just show the type.
      if (fields.isEmpty) return type.name;

      StringBuffer buffer = new StringBuffer();
      buffer.write(type.name);

      buffer.write('(');
      bool first = true;

      fields.forEach((String name, Space space) {
        if (!first) buffer.write(', ');
        buffer.write('$name: $space');
        first = false;
      });

      buffer.write(')');
      return buffer.toString();
    }
  }
}

/// A set of runtime values encoded as a union of [SingleSpace]s.
///
/// This is used to support logical-or patterns without having to eagerly
/// expand the subpatterns in the parent context.
class Space {
  /// The path of getters that led from the original matched value to value
  /// matched by this pattern. Used to generate a human-readable witness.
  final Path path;

  final List<SingleSpace> singleSpaces;

  /// Create an empty space.
  Space.empty(this.path) : singleSpaces = [SingleSpace.empty];

  Space(Path path, StaticType type, {Map<String, Space> fields = const {}})
      : this._(path, [new SingleSpace(type, fields: fields)]);

  Space._(this.path, this.singleSpaces);

  factory Space.fromSingleSpaces(Path path, List<SingleSpace> singleSpaces) {
    Set<SingleSpace> singleSpacesSet = {};

    for (SingleSpace singleSpace in singleSpaces) {
      // Discard empty space.
      if (singleSpace == SingleSpace.empty) {
        continue;
      }

      singleSpacesSet.add(singleSpace);
    }

    List<SingleSpace> singleSpacesList = singleSpacesSet.toList();
    if (singleSpacesSet.isEmpty) {
      singleSpacesList.add(SingleSpace.empty);
    } else if (singleSpacesList.length == 2) {
      if (singleSpacesList[0].type == StaticType.nullType &&
          singleSpacesList[0].fields.isEmpty &&
          singleSpacesList[1].fields.isEmpty) {
        singleSpacesList = [new SingleSpace(singleSpacesList[1].type.nullable)];
      } else if (singleSpacesList[1].type == StaticType.nullType &&
          singleSpacesList[1].fields.isEmpty &&
          singleSpacesList[0].fields.isEmpty) {
        singleSpacesList = [new SingleSpace(singleSpacesList[0].type.nullable)];
      }
    }
    return new Space._(path, singleSpacesList);
  }

  Space union(Space other) {
    return new Space.fromSingleSpaces(
        path, [...singleSpaces, ...other.singleSpaces]);
  }

  @override
  String toString() => singleSpaces.join('|');
}

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

/// A path that describes location of a [SingleSpace] from the root of
/// enclosing [Space].
abstract class Path {
  const Path();

  /// Create root path.
  const factory Path.root() = _Root;

  /// Returns a path that adds a step by the [name] to the current path.
  Path add(String name) => new _Step(this, name);

  void _toList(List<String> list);

  /// Returns a list of the names from the root to this path.
  List<String> toList();
}

/// The root path object.
class _Root extends Path {
  const _Root();

  @override
  void _toList(List<String> list) {}

  @override
  List<String> toList() => const [];

  @override
  int get hashCode => 1729;

  @override
  bool operator ==(Object other) {
    return other is _Root;
  }

  @override
  String toString() => '@';
}

/// A single step in a path that holds the [parent] pointer the [name] for the
/// step.
class _Step extends Path {
  final Path parent;
  final String name;

  _Step(this.parent, this.name);

  @override
  List<String> toList() {
    List<String> list = [];
    _toList(list);
    return list;
  }

  @override
  void _toList(List<String> list) {
    parent._toList(list);
    list.add(name);
  }

  @override
  late final int hashCode = Object.hash(parent, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Step && name == other.name && parent == other.parent;
  }

  @override
  String toString() {
    if (parent is _Root) {
      return name;
    } else {
      return '$parent.$name';
    }
  }
}
