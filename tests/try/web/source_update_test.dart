// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_try.dart';

InteractionContext interaction;

void main() {
  interaction = mockTryDartInteraction();

  runTests(<TestCase>[

    new TestCase('Test setting full source', () {
      clearEditorPaneWithoutNotifications();
      mainEditorPane.appendText('Foo\nBar');
    }, () {
      expectSource('Foo\nBar');
    }),

    new TestCase('Test modifying a single line', () {
      Element lastLine = mainEditorPane.lastChild;
      lastLine.appendText('Baz');
    }, () {
      expectSource('Foo\nBarBaz');
    }),

  ]);
}

void expectSource(String expected) {
  String actualSource = interaction.currentCompilationUnit.content;
  Expect.stringEquals(expected, actualSource);
}
