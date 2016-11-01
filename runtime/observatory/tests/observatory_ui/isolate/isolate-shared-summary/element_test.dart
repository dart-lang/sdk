// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/isolate/counter_chart.dart';
import 'package:observatory/src/elements/isolate/shared_summary.dart';
import '../../mocks.dart';

main() {
  IsolateSharedSummaryElement.tag.ensureRegistration();

  final cTag = IsolateCounterChartElement.tag.name;

  const isolate = const IsolateMock();
  final events = new EventRepositoryMock();
  test('instantiation', () {
    final e = new IsolateSharedSummaryElement(isolate, events);
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created', () async {
    final e = new IsolateSharedSummaryElement(isolate, events);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(cTag).length, equals(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
