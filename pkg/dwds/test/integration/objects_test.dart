// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/utilities/objects.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

void main() {
  group('Property', () {
    final exampleMap = {'objectId': '1234', 'value': 'abcd'};

    test('from a map', () {
      // Verify that we behave the same whether created from a Map
      // or from a RemoteObject.
      final property = Property({'name': 'prop', 'value': exampleMap});
      expect(property.rawValue, exampleMap);
      final value = property.value!;
      expect(value.objectId, '1234');
      expect(value.value, 'abcd');
      expect(property.name, 'prop');
    });
    test('from a RemoteObject', () {
      final remoteObject = RemoteObject({'objectId': '1234', 'value': 'abcd'});
      final property = Property({'name': 'prop', 'value': remoteObject});
      expect(property.rawValue, remoteObject);
      final value = property.value!;
      expect(value.objectId, '1234');
      expect(value.value, 'abcd');
      expect(property.name, 'prop');
    });

    test('stripping the "Symbol(" from a private field', () {
      final property = Property({
        'name': 'Symbol(_privateThing)',
        'value': exampleMap,
      });
      expect(property.name, '_privateThing');
    });
  });
}
