// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that cursor positions are correctly updated after adding new content.

import 'test_try.dart';

void main() {
  InteractionManager interaction = mockTryDartInteraction();

  TestCase twoLines =
      new TestCase('Test adding two lines programmatically.', () {
        clearEditorPaneWithoutNotifications();
        mainEditorPane.appendText('\n\n');
        Text text = mainEditorPane.firstChild;
        window.getSelection().collapse(text, 1);
        checkSelectionIsCollapsed(text, 1);
      }, checkAtBeginningOfSecondLine);

  runTests(<TestCase>[
    twoLines,

    new TestCase('Test adding a new text node.', () {
      // This test relies on the previous test leaving two lines.
      Text text = new Text('fisk');
      window.getSelection().getRangeAt(0).insertNode(text);
      window.getSelection().collapse(text, text.length);
      checkSelectionIsCollapsed(text, text.length);
    }, checkAtEndOfSecondLineWithFisk),

    twoLines,

    new TestCase('Test adding a new wrapped text node.', () {
      // This test relies on the previous test leaving two lines.
      Text text = new Text('fisk');
      Node node = new SpanElement()..append(text);
      window.getSelection().getRangeAt(0).insertNode(node);
      window.getSelection().collapse(text, text.length);
      checkSelectionIsCollapsed(text, text.length);
    }, checkAtEndOfSecondLineWithFisk),

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

void checkAtEndOfSecondLineWithFisk() {
  checkLineCount(2);
  SpanElement secondLine = mainEditorPane.nodes[1];
  Text text = secondLine.firstChild.firstChild;
  Expect.stringEquals('fisk', text.text);
  Expect.equals(4, text.length);
  Text newline = secondLine.firstChild.nextNode;
  Expect.equals(newline, secondLine.lastChild);
  /// Chrome and Firefox cannot agree on where to put the cursor.  At the end
  /// of [text] or at the beginning of [newline].  It's the same position.
  if (window.getSelection().anchorOffset == 0) {
    // Firefox.
    checkSelectionIsCollapsed(newline, 0);
  } else {
    // Chrome.
    checkSelectionIsCollapsed(text, 4);
  }
}

class MockKeyboardEvent extends KeyEvent {
  final int keyCode;

  MockKeyboardEvent(String type, {int keyCode})
      : this.keyCode = keyCode,
        super.wrap(new KeyEvent(type, keyCode: keyCode));

  bool getModifierState(String keyArgument) => false;
}
