// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/cpu_profile.dart';
import 'package:observatory/src/elements/cpu_profile/virtual_tree.dart';
import 'package:observatory/src/elements/stack_trace_tree_config.dart';
import 'package:observatory/src/elements/sample_buffer_control.dart';
import '../mocks.dart';

main() {
  CpuProfileElement.tag.ensureRegistration();

  final sTag = SampleBufferControlElement.tag.name;
  final cTag = StackTraceTreeConfigElement.tag.name;
  final tTag = CpuProfileVirtualTreeElement.tag.name;

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifs = new NotificationRepositoryMock();
  test('instantiation', () {
    final profiles = new IsolateSampleProfileRepositoryMock();
    final e = new CpuProfileElement(vm, isolate, events, notifs, profiles);
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created', () async {
    final controller
        = new StreamController<M.SampleProfileLoadingProgressEvent>.broadcast();
    final profiles = new IsolateSampleProfileRepositoryMock(
      getter: (M.IsolateRef i, M.SampleProfileTag t, bool clear,
          bool forceFetch) {
        expect(i, equals(isolate));
        expect(t, isNotNull);
        expect(clear, isFalse);
        expect(forceFetch, isFalse);
        return controller.stream;
      }
    );
    final e = new CpuProfileElement(vm, isolate, events, notifs, profiles);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(sTag).length, isZero);
    expect(e.querySelectorAll(cTag).length, isZero);
    expect(e.querySelectorAll(tTag).length, isZero);
    controller.add(new SampleProfileLoadingProgressEventMock(
      progress: new SampleProfileLoadingProgressMock(
        status: M.SampleProfileLoadingStatus.fetching
      )
    ));
    await e.onRendered.first;
    expect(e.querySelectorAll(sTag).length, equals(1));
    expect(e.querySelectorAll(cTag).length, isZero);
    expect(e.querySelectorAll(tTag).length, isZero);
    controller.add(new SampleProfileLoadingProgressEventMock(
      progress: new SampleProfileLoadingProgressMock(
        status: M.SampleProfileLoadingStatus.loading
      )
    ));
    controller.add(new SampleProfileLoadingProgressEventMock(
      progress: new SampleProfileLoadingProgressMock(
        status: M.SampleProfileLoadingStatus.loaded,
        profile: new SampleProfileMock()
      )
    ));
    controller.close();
    await e.onRendered.first;
    expect(e.querySelectorAll(sTag).length, equals(1));
    expect(e.querySelectorAll(cTag).length, equals(1));
    expect(e.querySelectorAll(tTag).length, equals(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
