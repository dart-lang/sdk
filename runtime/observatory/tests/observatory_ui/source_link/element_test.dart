// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/source_link.dart';
import '../mocks.dart';

main() {
  SourceLinkElement.tag.ensureRegistration();

  const isolate = const IsolateRefMock(id: 'isolate-id');
  const file = 'filename.dart';
  final script = new ScriptMock(id: 'script-id', uri: 'package/$file',
      tokenToLine: (int token) => 1, tokenToCol: (int token) => 2);
  final location = new SourceLocationMock(script: script, tokenPos: 0,
      endTokenPos: 1);
  M.ScriptRepository repository;
  setUp(() {
    repository = new ScriptRepositoryMock({ 'script-id': script });
  });
  test('instantiation', () {
    final e = new SourceLinkElement(isolate, location, repository);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.location, equals(location));
  });
  test('elements created after attachment', () async {
    final e = new SourceLinkElement(isolate, location, repository);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.innerHtml.contains(isolate.id), isTrue,
      reason: 'no message in the component');
    expect(e.innerHtml.contains(file), isTrue,
      reason: 'no message in the component');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero,
      reason: 'is empty');
  });
}
