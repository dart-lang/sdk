// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

import 'test_data.dart';

void main() {
  test(
    'JSON',
    () => expect(recordedUses.toJson(), recordedUsesJson),
  );

  test(
    'Object',
    () => expect(UsageRecord.fromJson(recordedUsesJson), recordedUses),
  );

  test('Json->Object->Json', () {
    expect(UsageRecord.fromJson(recordedUsesJson).toJson(), recordedUsesJson);
  });

  test('Object->Json->Object', () {
    expect(UsageRecord.fromJson(recordedUses.toJson()), recordedUses);
  });
}
