// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/src/elements/library_ref.dart';

main(){
  LibraryRefElement.tag.ensureRegistration();

  final IsolateRefMock isolate = new IsolateRefMock(id: 'i-id', name: 'i-name');
  final LibraryRefMock library = new LibraryRefMock(id: 'c-id', name: 'c-name');
  test('instantiation', () {
    final LibraryRefElement e = new LibraryRefElement(isolate, library);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.library, equals(library));
  });
  test('elements created after attachment', () async {
    final LibraryRefElement e = new LibraryRefElement(isolate, library);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
