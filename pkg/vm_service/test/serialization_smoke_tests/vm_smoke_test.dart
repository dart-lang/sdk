// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

// Regression test for failure to roll into Flutter found in
// https://github.com/flutter/flutter/pull/185274#discussion_r3116379311

void main() {
  test('VM.parse() never results in null lists', () {
    final vmService = VM.parse({})!;
    expect(vmService.systemIsolateGroups, allOf(isNotNull, isEmpty));
    expect(vmService.systemIsolates, allOf(isNotNull, isEmpty));
    expect(vmService.isolateGroups, allOf(isNotNull, isEmpty));
    expect(vmService.isolates, allOf(isNotNull, isEmpty));
  });
}
