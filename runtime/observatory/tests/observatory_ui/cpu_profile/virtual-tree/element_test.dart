// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/cpu_profile/virtual_tree.dart';
import '../../mocks.dart';

main() {
  CpuProfileVirtualTreeElement.tag.ensureRegistration();
  const isolate = const IsolateRefMock();
  group('instantiation', () {
    final profile = new SampleProfileMock();
    test('default', () {
      final e = new CpuProfileVirtualTreeElement(isolate, profile);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(isolate));
      expect(e.profile, equals(profile));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('mode', () {
      final e = new CpuProfileVirtualTreeElement(isolate, profile,
          mode: ProfileTreeMode.code);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(isolate));
      expect(e.profile, equals(profile));
      expect(e.mode, equals(ProfileTreeMode.code));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('direction', () {
      final e = new CpuProfileVirtualTreeElement(isolate, profile,
          direction: M.ProfileTreeDirection.inclusive);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(isolate));
      expect(e.profile, equals(profile));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.inclusive));
    });
  });
  test('elements created after attachment', () async {
    final profile = new SampleProfileMock();
    final e = new CpuProfileVirtualTreeElement(isolate, profile);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
