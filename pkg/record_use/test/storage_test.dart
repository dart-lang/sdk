// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

import 'test_data.dart';

void main() {
  group('object 1', () {
    final json = jsonDecode(recordedUsesJson) as Map<String, Object?>;
    test('JSON', () => expect(recordedUses.toJson(), json));

    test('Object', () => expect(Recordings.fromJson(json), recordedUses));

    test('Json->Object->Json', () {
      expect(Recordings.fromJson(json).toJson(), json);
    });

    test('Object->Json->Object', () {
      expect(Recordings.fromJson(recordedUses.toJson()), recordedUses);
    });
  });

  group('object 2', () {
    final json2 = jsonDecode(recordedUsesJson2) as Map<String, Object?>;
    test('JSON', () => expect(recordedUses2.toJson(), json2));

    test('Object', () => expect(Recordings.fromJson(json2), recordedUses2));

    test('Json->Object->Json', () {
      expect(Recordings.fromJson(json2).toJson(), json2);
    });

    test('Object->Json->Object', () {
      expect(Recordings.fromJson(recordedUses2.toJson()), recordedUses2);
    });
  });
}
