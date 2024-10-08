// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

import 'test_data.dart';

void main() {
  final json = jsonDecode(recordedUsesJson) as Map<String, dynamic>;
  test(
    'JSON',
    () => expect(recordedUses.toJson(), json),
  );

  test(
    'Object',
    () => expect(UsageRecord.fromJson(json), recordedUses),
  );

  test('Json->Object->Json', () {
    expect(UsageRecord.fromJson(json).toJson(), json);
  });

  test('Object->Json->Object', () {
    expect(UsageRecord.fromJson(recordedUses.toJson()), recordedUses);
  });
}
