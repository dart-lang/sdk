// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/script_ref.dart';

main() {
  ScriptRefElement.tag.ensureRegistration();

  final M.IsolateRef isolate = const IsolateRefMock(id: 'isolate-id');
  final M.ScriptRef ref = const ScriptRefMock(id: 'script-id',
                                  uri: 'package/filename.dart');
  group('instantiation', () {
    test('no position', () {
      final ScriptRefElement e = new ScriptRefElement(isolate, ref);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(isolate));
      expect(e.script, equals(ref));
    });
  });
  test('elements created after attachment', () async {
    final ScriptRefElement e = new ScriptRefElement(isolate, ref);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.innerHtml.contains(isolate.id), isTrue,
      reason: 'no message in the component');
    expect(e.innerHtml.contains('filename.dart'), isTrue,
      reason: 'no message in the component');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero,
      reason: 'is empty');
  });
}
