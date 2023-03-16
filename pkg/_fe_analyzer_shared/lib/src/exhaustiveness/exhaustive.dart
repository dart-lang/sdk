// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'static_type.dart';
import 'key.dart';
import 'path.dart';
import 'profile.dart' as profile;
import 'space.dart';
import 'witness.dart';

/// Indicates whether the "fallback" exhaustiveness algorithm (based on flow
/// analysis) should be used instead of full exhaustiveness.  This is a
/// temporary measure to allow for the possibility of turning on pattern support
/// before the full exhaustiveness algorithm is complete.
///
/// TODO(paulberry): remove this flag (and the implementation of the fallback
/// exhaustiveness algorithm) when it is no longer needed.
bool useFallbackExhaustivenessAlgorithm = true;

/// Returns `true` if [caseSpaces] exhaustively covers all possible values of
/// [valueSpace].
bool isExhaustive(
    ObjectFieldLookup fieldLookup, Space valueSpace, List<Space> caseSpaces) {
  return checkExhaustiveness(fieldLookup, valueSpace, caseSpaces) == null;
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
    ObjectFieldLookup fieldLookup, StaticType valueType, List<Space> cases) {
  _Checker checker = new _Checker(fieldLookup);

  List<ExhaustivenessError> errors = <ExhaustivenessError>[];

  Space valuePattern = new Space(const Path.root(), valueType);
  List<List<Space>> caseRows = cases.map((space) => [space]).toList();

  for (int i = 1; i < caseRows.length; i++) {
    // See if this case is covered by previous ones.
    if (checker._unmatched(caseRows.sublist(0, i), caseRows[i]) == null) {
      errors.add(new UnreachableCaseError(valueType, cases, i));
    }
  }

  Witness? witness = checker._unmatched(caseRows, [valuePattern]);
  if (witness != null) {
    errors.add(new NonExhaustiveError(valueType, cases, witness));
  }

  return errors;
}

/// Determines if [cases] is exhaustive over all values contained by
/// [valueSpace]. If so, returns `null`. Otherwise, returns a string describing
/// an example of one value that isn't matched by anything in [cases].
Witness? checkExhaustiveness(
    ObjectFieldLookup fieldLookup, Space valueSpace, List<Space> cases) {
  _Checker checker = new _Checker(fieldLookup);

  // TODO(johnniwinther): Perform reachability checking.
  List<List<Space>> caseRows = cases.map((space) => [space]).toList();

  Witness? witness = checker._unmatched(caseRows, [valueSpace]);

  // Uncomment this to have it print out the witness for non-exhaustive matches.
  // if (witness != null) print(witness);

  return witness;
}

class _Checker {
  final ObjectFieldLookup _fieldLookup;

  _Checker(this._fieldLookup);

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
    // If there are no more columns, then we've tested all the predicates we
    // have to test.
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

    Set<Key> keysOfInterest = {};
    for (List<Space> caseRow in caseRows) {
      for (SingleSpace singleSpace in caseRow.first.singleSpaces) {
        keysOfInterest.addAll(singleSpace.additionalFields.keys);
      }
    }
    for (SingleSpace firstValuePattern in firstValuePatterns.singleSpaces) {
      // TODO(johnniwinther): Right now, this brute force expands all subtypes
      // of sealed types and considers them individually. It would be faster to
      // look at the types of the patterns in the first column of each row and
      // only expand subtypes that are actually tested.
      // Split the type into its sealed subtypes and consider each one
      // separately. This enables it to filter rows more effectively.
      List<StaticType> subtypes =
          expandSealedSubtypes(firstValuePattern.type, keysOfInterest);
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

    // 1) Discard any rows that might not match because the column's type isn't
    // a subtype of the value's type.  We only keep rows that *must* match
    // because a row that could potentially fail to match will not help us prove
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

    // We have now filtered by the type test of the first column of patterns,
    // but some of those may also have field subpatterns. If so, lift those out
    // so we can recurse into them.
    Set<String> fieldNames = {
      ...firstSingleSpaceValue.fields.keys,
      for (SingleSpace firstPattern in remainingRowFirstSingleSpaces)
        ...firstPattern.fields.keys
    };

    Set<Key> additionalFieldKeys = {
      ...firstSingleSpaceValue.additionalFields.keys,
      for (SingleSpace firstPattern in remainingRowFirstSingleSpaces)
        ...firstPattern.additionalFields.keys
    };

    // Sorting isn't necessary, but makes the behavior deterministic.
    List<String> sortedFieldNames = fieldNames.toList()..sort();
    List<Key> sortedAdditionalFieldKeys = additionalFieldKeys.toList()..sort();

    // Remove the first column from the value list and replace it with any
    // expanded fields.
    valueSpaces = [
      ..._expandFields(sortedFieldNames, sortedAdditionalFieldKeys,
          firstSingleSpaceValue, type, path),
      ...valueSpaces.skip(1)
    ];

    // Remove the first column from each row and replace it with any expanded
    // fields.
    for (int i = 0; i < remainingRows.length; i++) {
      remainingRows[i] = [
        ..._expandFields(
            sortedFieldNames,
            sortedAdditionalFieldKeys,
            remainingRowFirstSingleSpaces[i],
            remainingRowFirstSingleSpaces[i].type,
            path),
        ...remainingRows[i].skip(1)
      ];
    }

    // Proceed to the next column.
    return _unmatched(remainingRows, valueSpaces, extendedWitness);
  }

  /// Given a list of [fieldNames] and [additionalFieldKeys], and a
  /// [singleSpace], generates a list of single spaces, one for each named field
  /// and additional field key.
  ///
  /// When [singleSpace] contains a field with that name or an additional field
  /// with the key, extracts it into the resulting list. Otherwise, the
  /// [singleSpace] doesn't care about that field, so inserts a default [Space]
  /// that matches all values for the field.
  ///
  /// In other words, this unpacks a set of fields so that the main algorithm
  /// can add them to the worklist.
  List<Space> _expandFields(
      List<String> fieldNames,
      List<Key> additionalFieldKeys,
      SingleSpace singleSpace,
      StaticType type,
      Path path) {
    profile.count('_expandFields');
    List<Space> result = <Space>[];
    for (String fieldName in fieldNames) {
      Space? field = singleSpace.fields[fieldName];
      if (field != null) {
        result.add(field);
      } else {
        // This pattern doesn't test this field, so add a pattern for the
        // field that matches all values. This way the columns stay aligned.
        result.add(new Space(
            path.add(fieldName),
            type.getField(_fieldLookup, fieldName) ??
                StaticType.nullableObject));
      }
    }
    for (Key key in additionalFieldKeys) {
      Space? field = singleSpace.additionalFields[key];
      if (field != null) {
        result.add(field);
      } else {
        // This pattern doesn't test this field, so add a pattern for the
        // field that matches all values. This way the columns stay aligned.
        result.add(new Space(path.add(key.name),
            type.getAdditionalField(key) ?? StaticType.nullableObject));
      }
    }
    return result;
  }
}

/// Recursively expands [type] with its subtypes if its sealed.
///
/// Otherwise, just returns [type].
List<StaticType> expandSealedSubtypes(
    StaticType type, Set<Key> keysOfInterest) {
  profile.count('expandSealedSubtypes');
  if (!type.isSealed) {
    return [type];
  } else {
    return {
      for (StaticType subtype in type.getSubtypes(keysOfInterest))
        ...expandSealedSubtypes(subtype, keysOfInterest)
    }.toList();
  }
}

class ExhaustivenessError {}

class NonExhaustiveError implements ExhaustivenessError {
  final StaticType valueType;

  final List<Space> cases;

  final Witness witness;

  NonExhaustiveError(this.valueType, this.cases, this.witness);

  @override
  String toString() =>
      '$valueType is not exhaustively matched by ${cases.join('|')}.';
}

class UnreachableCaseError implements ExhaustivenessError {
  final StaticType valueType;
  final List<Space> cases;
  final int index;

  UnreachableCaseError(this.valueType, this.cases, this.index);

  @override
  String toString() => 'Case #${index + 1} ${cases[index]} is unreachable.';
}
