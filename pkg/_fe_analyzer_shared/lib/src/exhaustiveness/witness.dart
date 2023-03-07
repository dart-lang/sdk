// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'exhaustive.dart';
import 'profile.dart' as profile;
import 'space.dart';
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
    StaticType valueType, List<Space> caseSpaces) {
  List<ExhaustivenessError> errors = <ExhaustivenessError>[];

  Pattern valuePattern = new Pattern(valueType, {}, []);
  List<List<Patterns>> cases =
      caseSpaces.map((space) => [_spaceToPatterns(space)]).toList();

  for (int i = 1; i < cases.length; i++) {
    // See if this case is covered by previous ones.
    if (_unmatched(cases.sublist(0, i), cases[i]) == null) {
      errors.add(new UnreachableCaseError(valueType, caseSpaces, i));
    }
  }

  String? witness = _unmatched(cases, [
    new Patterns([valuePattern])
  ]);
  if (witness != null) {
    errors.add(new NonExhaustiveError(valueType, caseSpaces, witness));
  }

  return errors;
}

/// Determines if [caseSpaces] is exhaustive over all values contained by
/// [valueSpace]. If so, returns `null`. Otherwise, returns a string describing
/// an example of one value that isn't matched by anything in [caseSpaces].
String? checkExhaustiveness(Space valueSpace, List<Space> caseSpaces) {
  // TODO(johnniwinther): Perform reachability checking.
  Patterns value = _spaceToPatterns(valueSpace);
  List<List<Patterns>> cases =
      caseSpaces.map((space) => [_spaceToPatterns(space)]).toList();

  String? witness = _unmatched(cases, [value]);

  // Uncomment this to have it print out the witness for non-exhaustive matches.
  // if (witness != null) print(witness);

  return witness;
}

/// Convert the prototype's original [Space] representation to the [Patterns]
/// representation used here.
///
/// This is only a convenience to run the existing test code which creates
/// [Space]s using the new algorithm.
// TODO(johnniwinther): Encode Dart patterns directly into [Patterns].
Patterns _spaceToPatterns(Space space, [List<String> path = const []]) {
  if (space is UnionSpace) {
    return new Patterns(
        space.arms.map((arm) => _extractSpaceToPattern(arm, path)).toList());
  }
  return new Patterns([_extractSpaceToPattern(space as ExtractSpace, path)]);
}

/// Convert the prototype's original [ExtractSpace] representation into the
/// [Pattern] representation used here.
Pattern _extractSpaceToPattern(ExtractSpace space,
    [List<String> path = const []]) {
  Map<String, Patterns> fields = {
    for (String name in space.fields.keys)
      name: _spaceToPatterns(space.fields[name]!, [...path, name])
  };
  return new Pattern(space.type, fields, path);
}

/// Tries to find a pattern containing at least one value matched by
/// [valuePatterns] that is not matched by any of the patterns in [caseRows].
///
/// If found, returns it. This is a witness example showing that [caseRows] is
/// not exhaustive over all values in [valuePatterns]. If it returns `null`,
/// then [caseRows] exhaustively covers [valuePatterns].
String? _unmatched(List<List<Patterns>> caseRows, List<Patterns> valuePatterns,
    [List<Predicate> witnessPredicates = const []]) {
  assert(caseRows.every((element) => element.length == valuePatterns.length));
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
    return _witnessString(witnessPredicates);
  }

  // Look down the first column of tests.
  Patterns firstValuePatterns = valuePatterns[0];

  for (Pattern firstValuePattern in firstValuePatterns.patterns) {
    // TODO(johnniwinther): Right now, this brute force expands all subtypes of
    // sealed types and considers them individually. It would be faster to look
    // at the types of the patterns in the first column of each row and only
    // expand subtypes that are actually tested.
    // Split the type into its sealed subtypes and consider each one separately.
    // This enables it to filter rows more effectively.
    List<StaticType> subtypes = expandSealedSubtypes(firstValuePattern.type);
    for (StaticType subtype in subtypes) {
      String? result = _filterByType(subtype, caseRows, firstValuePattern,
          valuePatterns, witnessPredicates);

      // If we found a witness for a subtype that no rows match, then we can
      // stop. There may be others but we don't need to find more.
      if (result != null) return result;
    }
  }

  // If we get here, no subtype yielded a witness, so we must have matched
  // everything.
  return null;
}

String? _filterByType(
    StaticType type,
    List<List<Patterns>> caseRows,
    Pattern firstValuePattern,
    List<Patterns> valuePatterns,
    List<Predicate> witnessPredicates) {
  profile.count('_filterByType');
  // Extend the witness with the type we're matching.
  List<Predicate> extendedWitness = [
    ...witnessPredicates,
    new Predicate(firstValuePattern.path, type)
  ];

  // 1) Discard any rows that might not match because the column's type isn't a
  // subtype of the value's type.  We only keep rows that *must* match because a
  // row that could potentially fail to match will not help us prove
  // exhaustiveness.
  //
  // 2) Expand any unions in the first column. This can (deliberately) produce
  // duplicate rows in remainingRows.
  List<Pattern> remainingRowFirstPatterns = [];
  List<List<Patterns>> remainingRows = [];
  for (List<Patterns> row in caseRows) {
    Patterns firstPatterns = row[0];

    for (Pattern firstPattern in firstPatterns.patterns) {
      // If the row's type is a supertype of the value pattern's type then it
      // must match.
      if (type.isSubtypeOf(firstPattern.type)) {
        remainingRowFirstPatterns.add(firstPattern);
        remainingRows.add(row);
      }
    }
  }

  // We have now filtered by the type test of the first column of patterns, but
  // some of those may also have field subpatterns. If so, lift those out so we
  // can recurse into them.
  Set<String> fieldNames = {
    ...firstValuePattern.fields.keys,
    for (Pattern firstPattern in remainingRowFirstPatterns)
      ...firstPattern.fields.keys
  };

  // Sorting isn't necessary, but makes the behavior deterministic.
  List<String> sorted = fieldNames.toList()..sort();

  // Remove the first column from the value list and replace it with any
  // expanded fields.
  valuePatterns = [
    ..._expandFields(sorted, firstValuePattern, type),
    ...valuePatterns.skip(1)
  ];

  // Remove the first column from each row and replace it with any expanded
  // fields.
  for (int i = 0; i < remainingRows.length; i++) {
    remainingRows[i] = [
      ..._expandFields(sorted, remainingRowFirstPatterns[i],
          remainingRowFirstPatterns[i].type),
      ...remainingRows[i].skip(1)
    ];
  }

  // Proceed to the next column.
  return _unmatched(remainingRows, valuePatterns, extendedWitness);
}

/// Given a list of [fieldNames] and a [pattern], generates a list of patterns,
/// one for each named field.
///
/// When pattern contains a field with that name, extracts it into the
/// resulting list. Otherwise, the pattern doesn't care
/// about that field, so inserts a default pattern that matches all values for
/// the field.
///
/// In other words, this unpacks a set of fields so that the main algorithm can
/// add them to the worklist.
List<Patterns> _expandFields(
    List<String> fieldNames, Pattern pattern, StaticType type) {
  profile.count('_expandFields');
  List<Patterns> result = <Patterns>[];
  for (String fieldName in fieldNames) {
    Patterns? field = pattern.fields[fieldName];
    if (field != null) {
      result.add(field);
    } else {
      // This pattern doesn't test this field, so add a pattern for the
      // field that matches all values. This way the columns stay aligned.
      result.add(
        new Patterns([
          new Pattern(
            type.fields[fieldName] ?? StaticType.nullableObject,
            {},
            [...pattern.path, fieldName],
          )
        ]),
      );
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
/// be [StaticType.top] to indicate that it doesn't filter by type.
///
/// It may also contain zero or more named fields. The pattern then only matches
/// values where the field values are matched by the corresponding field
/// patterns.
// TODO(johnniwinther): Rename this to avoid name clash with Pattern from
//  dart:core.
class Pattern {
  /// The type of values the pattern matches.
  final StaticType type;

  /// Any field subpatterns the pattern matches.
  final Map<String, Patterns> fields;

  /// The path of getters that led from the original matched value to value
  /// matched by this pattern. Used to generate a human-readable witness.
  final List<String> path;

  Pattern(this.type, this.fields, this.path);

  @override
  String toString() {
    return 'Pattern(type=$type,fields=$fields,path=$path)';
  }
}

/// A union of [Pattern]s.
///
/// This is used to support logical-or patterns without having to eagerly
/// expand the subpatterns in the parent context.
class Patterns {
  final List<Pattern> patterns;

  Patterns(this.patterns);

  @override
  String toString() => 'Patterns($patterns)';
}

/// Describes a pattern that matches the value or a field accessed from it.
///
/// Used only to generate the witness description.
class Predicate {
  /// The path of getters that led from the original matched value to the value
  /// tested by this predicate.
  final List<String> path;

  /// The type this predicate tests.
  // TODO(johnniwinther): In order to model exhaustiveness on enum types,
  // bool values, and maybe integers at some point, we may later want a separate
  // kind of predicate that means "this value was equal to this constant".
  final StaticType type;

  Predicate(this.path, this.type);

  @override
  String toString() => 'Predicate(path=$path,type=$type)';
}

/// Builds a human-friendly pattern-like string for the witness matched by
/// [predicates].
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
/// Produces:
///
///     'U(w: T(x: B, y: B), z: T(x: C, y: B))'
String _witnessString(List<Predicate> predicates) {
  Witness witness = new Witness();

  for (Predicate predicate in predicates) {
    Witness here = witness;
    for (String field in predicate.path) {
      here = here.fields.putIfAbsent(field, () => new Witness());
    }
    here.type = predicate.type;
  }

  StringBuffer buffer = new StringBuffer();
  witness.buildString(buffer);
  return buffer.toString();
}

/// Helper class used to turn a list of [Predicates] into a string.
class Witness {
  StaticType type = StaticType.nullableObject;
  final Map<String, Witness> fields = {};

  void buildString(StringBuffer buffer) {
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
        field.buildString(buffer);
      });
      buffer.write(')');
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    buildString(sb);
    return sb.toString();
  }
}
