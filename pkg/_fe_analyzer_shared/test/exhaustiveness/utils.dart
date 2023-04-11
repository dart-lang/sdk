// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/key.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/path.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

/// Test that [spaces] is exhaustive over [value].
void expectExhaustive(
    ObjectPropertyLookup fieldLookup, Space value, List<Space> spaces) {
  _expectExhaustive(fieldLookup, value, spaces, true);
}

/// Test that [cases] are exhaustive over [type] if and only if all cases are
/// included and that all subsets of the cases are not exhaustive.
void expectExhaustiveOnlyAll(
    ObjectPropertyLookup fieldLookup, StaticType type, List<Object> cases) {
  _testCases(fieldLookup, type, cases, true);
}

/// Test that [cases] are not exhaustive over [type]. Also test that omitting
/// each case is still not exhaustive.
void expectNeverExhaustive(
    ObjectPropertyLookup fieldLookup, StaticType type, List<Object> cases) {
  _testCases(fieldLookup, type, cases, false);
}

/// Test that [spaces] is not exhaustive over [value].
void expectNotExhaustive(
    ObjectPropertyLookup fieldLookup, Space value, List<Space> spaces) {
  _expectExhaustive(fieldLookup, value, spaces, false);
}

Map<Key, Space> fieldsToSpace(Map<String, Object> fields, Path path,
        {required bool asRecordNames}) =>
    fields.map((String name, Object value) {
      Key key = asRecordNames ? new RecordNameKey(name) : new NameKey(name);
      return MapEntry(key, parseSpace(value, path.add(key)));
    });

Space parseSpace(Object object, [Path path = const Path.root()]) {
  if (object is Space) return object;
  if (object == '∅') return Space(path, StaticType.neverType);
  if (object is StaticType) return Space(path, object);
  if (object is List<Object>) {
    Space? spaces;
    for (Object element in object) {
      if (spaces == null) {
        spaces = parseSpace(element, path);
      } else {
        spaces = spaces.union(parseSpace(element, path));
      }
    }
    return spaces ?? new Space.empty(path);
  }
  throw ArgumentError('Invalid space $object');
}

/// Parse a list of spaces using [parseSpace].
List<Space> parseSpaces(List<Object> objects) =>
    objects.map(parseSpace).toList();

/// Make a [Space] with [type] and [fields].
Space ty(StaticType type, Map<String, Object> fields,
        [Path path = const Path.root()]) =>
    Space(path, type,
        properties: fieldsToSpace(fields, path, asRecordNames: type.isRecord));

void _checkExhaustive(ObjectPropertyLookup fieldLookup, Space value,
    List<Space> spaces, bool expectation) {
  var actual = isExhaustive(fieldLookup, value, spaces);
  if (expectation != actual) {
    if (expectation) {
      fail('Expected $spaces to cover $value but did not.');
    } else {
      fail('Expected $spaces to not cover $value but did.');
    }
  }
}

void _expectExhaustive(ObjectPropertyLookup fieldLookup, Space value,
    List<Space> spaces, bool expectation) {
  test(
      '$value - ${spaces.join(' - ')} ${expectation ? 'is' : 'is not'} '
      'exhaustive', () {
    _checkExhaustive(fieldLookup, value, spaces, expectation);
  });
}

/// Test that [cases] are not exhaustive over [type].
void _testCases(ObjectPropertyLookup fieldLookup, StaticType type,
    List<Object> cases, bool expectation) {
  var valueSpace = Space(const Path.root(), type);
  var spaces = parseSpaces(cases);

  test('$type with all cases', () {
    _checkExhaustive(fieldLookup, valueSpace, spaces, expectation);
  });

  // With any single case removed, should also not be exhaustive.
  for (var i = 0; i < spaces.length; i++) {
    var filtered = spaces.toList();
    filtered.removeAt(i);

    test('$type without case ${spaces[i]}', () {
      _checkExhaustive(fieldLookup, valueSpace, filtered, false);
    });
  }
}
