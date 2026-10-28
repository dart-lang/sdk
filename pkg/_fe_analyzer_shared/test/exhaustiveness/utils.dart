// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/key.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/path.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/shape.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:test/test.dart';

/// Test that [spaces] is exhaustive over [value].
void expectExhaustive(
  ObjectPropertyLookup propertyLookup,
  Space value,
  List<Space> spaces,
) {
  _expectExhaustive(propertyLookup, value, spaces, true);
}

/// Test that [cases] are exhaustive over [shape] if and only if all cases are
/// included and that all subsets of the cases are not exhaustive.
void expectExhaustiveOnlyAll(
  ObjectPropertyLookup propertyLookup,
  Shape shape,
  List<Object> cases,
) {
  _testCases(propertyLookup, shape, cases, true);
}

/// Test that [cases] are not exhaustive over [shape]. Also test that omitting
/// each case is still not exhaustive.
void expectNeverExhaustive(
  ObjectPropertyLookup propertyLookup,
  Shape shape,
  List<Object> cases,
) {
  _testCases(propertyLookup, shape, cases, false);
}

/// Test that [spaces] is not exhaustive over [value].
void expectNotExhaustive(
  ObjectPropertyLookup propertyLookup,
  Space value,
  List<Space> spaces,
) {
  _expectExhaustive(propertyLookup, value, spaces, false);
}

Map<Key, Space> propertiesToSpace(
  Map<String, Object> properties,
  Path path, {
  required bool asRecordNames,
}) => properties.map((String name, Object value) {
  Key key = asRecordNames ? new RecordNameKey(name) : new NameKey(name);
  return MapEntry(key, parseSpace(value, path.add(key)));
});

Space parseSpace(Object object, [Path path = const Path.root()]) {
  if (object is Space) return object;
  if (object == '∅') return Space(path, Shape.neverShape);
  if (object is Shape) return Space(path, object);
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

/// Make a [Space] with [shape] and [properties].
Space ty(
  Shape shape,
  Map<String, Object> properties, [
  Path path = const Path.root(),
]) => Space(
  path,
  shape,
  properties: propertiesToSpace(
    properties,
    path,
    asRecordNames: shape.isRecord,
  ),
);

void _checkExhaustive(
  ObjectPropertyLookup propertyLookup,
  Space value,
  List<Space> spaces,
  bool expectation,
) {
  var actual = isExhaustive(propertyLookup, value, spaces);
  if (expectation != actual) {
    if (expectation) {
      fail('Expected $spaces to cover $value but did not.');
    } else {
      fail('Expected $spaces to not cover $value but did.');
    }
  }
}

void _expectExhaustive(
  ObjectPropertyLookup propertyLookup,
  Space value,
  List<Space> spaces,
  bool expectation,
) {
  test('$value - ${spaces.join(' - ')} ${expectation ? 'is' : 'is not'} '
      'exhaustive', () {
    _checkExhaustive(propertyLookup, value, spaces, expectation);
  });
}

/// Test that [cases] are not exhaustive over [shape].
void _testCases(
  ObjectPropertyLookup propertyLookup,
  Shape shape,
  List<Object> cases,
  bool expectation,
) {
  var valueSpace = Space(const Path.root(), shape);
  var spaces = parseSpaces(cases);

  test('$shape with all cases', () {
    _checkExhaustive(propertyLookup, valueSpace, spaces, expectation);
  });

  // With any single case removed, should also not be exhaustive.
  for (var i = 0; i < spaces.length; i++) {
    var filtered = spaces.toList();
    filtered.removeAt(i);

    test('$shape without case ${spaces[i]}', () {
      _checkExhaustive(propertyLookup, valueSpace, filtered, false);
    });
  }
}
