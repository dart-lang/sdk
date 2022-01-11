// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor_shared/serialization.dart';
import 'package:test/test.dart';

void main() {
  group('json serializer', () {
    test('can serialize and deserialize data', () {
      var serializer = JsonSerializer();
      serializer
        ..addNum(1)
        ..addNullableNum(null)
        ..addString('hello')
        ..addNullableString(null)
        ..startList()
        ..addBool(true)
        ..startList()
        ..addNull()
        ..endList()
        ..addNullableBool(null)
        ..endList()
        ..addNum(1.0)
        ..startList()
        ..endList();
      expect(
          serializer.result,
          equals([
            1,
            null,
            'hello',
            null,
            [
              true,
              [null],
              null
            ],
            1.0,
            [],
          ]));
      var deserializer = JsonDeserializer(serializer.result);
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNum(), 1);
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNullableNum(), null);
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectString(), 'hello');
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNullableString(), null);
      expect(deserializer.moveNext(), true);

      deserializer.expectList();
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectBool(), true);
      expect(deserializer.moveNext(), true);

      deserializer.expectList();
      expect(deserializer.moveNext(), true);
      expect(deserializer.checkNull(), true);
      expect(deserializer.moveNext(), false);

      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNullableBool(), null);
      expect(deserializer.moveNext(), false);

      // Have to move the parent again to advance it past the list entry.
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNum(), 1.0);
      expect(deserializer.moveNext(), true);

      deserializer.expectList();
      expect(deserializer.moveNext(), false);

      expect(deserializer.moveNext(), false);
    });
  });
}
