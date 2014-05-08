// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--package-root=sdk/lib/_internal/

// Test that cursor positions are correctly updated after adding new content.

import 'test_try.dart';

void main() {
  InteractionManager interaction = mockTryDartInteraction();

  runTests(<TestCase>[

    new TestCase('Test adding two lines programmatically.', () {
      clearEditorPaneWithoutNotifications();
      mainEditorPane.appendText('\n\n');
      Text text = mainEditorPane.firstChild;
      window.getSelection().collapse(text, 1);
      checkSelectionIsCollapsed(text, 1);
    }, checkAtBeginningOfSecondLine),

    new TestCase('Test adding a new line with mock key event.', () {
      clearEditorPaneWithoutNotifications();
      checkSelectionIsCollapsed(mainEditorPane, 0);
      simulateEnterKeyDown(interaction);
    }, checkAtBeginningOfSecondLine),

  ]);
}

void simulateEnterKeyDown(InteractionManager interaction) {
  interaction.onKeyUp(
      new MockKeyboardEvent('keydown', keyCode: KeyCode.ENTER));
}

void checkSelectionIsCollapsed(Node node, int offset) {
  var selection = window.getSelection();
  Expect.isTrue(selection.isCollapsed, 'selection.isCollapsed');
  Expect.equals(node, selection.anchorNode, 'selection.anchorNode');
  Expect.equals(offset, selection.anchorOffset, 'selection.anchorOffset');
}

void checkLineCount(int expectedLineCount) {
  Expect.equals(
      expectedLineCount, mainEditorPane.nodes.length,
      'mainEditorPane.nodes.length');
}

void checkAtBeginningOfSecondLine() {
  checkLineCount(2);
  checkSelectionIsCollapsed(mainEditorPane.nodes[1].firstChild, 0);
}

class MockKeyboardEvent extends KeyEvent {
  final int keyCode;

  MockKeyboardEvent(String type, {int keyCode})
      : this.keyCode = keyCode,
        super.wrap(new KeyEvent(type, keyCode: keyCode));

  bool getModifierState(String keyArgument) => false;
}
