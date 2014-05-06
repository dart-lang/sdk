// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--package-root=sdk/lib/_internal/

// Test that cursor positions are correctly updated after adding new content.

library trydart.cursor_position_test;

import 'dart:html';
import 'dart:async';

import '../../site/try/src/interaction_manager.dart' show
    InteractionManager;

import '../../site/try/src/ui.dart' show
    hackDiv,
    mainEditorPane,
    observer;

import '../../site/try/src/user_option.dart' show
    UserOption;

import '../../pkg/expect/lib/expect.dart';

import '../../pkg/async_helper/lib/async_helper.dart';

void main() {
  InteractionManager interaction = mockTryDartInteraction();

  List<TestCase> tests = <TestCase>[

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

  ];

  runTests(tests.iterator, completerForAsyncTest());
}

void simulateEnterKeyDown(Interaction interaction) {
  interaction.onKeyUp(
      new MockKeyboardEvent('keydown', keyCode: KeyCode.ENTER));
}

void clearEditorPaneWithoutNotifications() {
  mainEditorPane.nodes.clear();
  observer.takeRecords();
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

runTests(Iterator<TestCase> iterator, Completer completer) {
  if (iterator.moveNext()) {
    TestCase test = iterator.current;
    new Future(() {
      print('${test.description}\nSetup.');
      test.setup();
      new Future(() {
        test.validate();
        print('${test.description}\nDone.');
        runTests(iterator, completer);
      });
    });
  } else {
    completer.complete(null);
  }
}

Completer completerForAsyncTest() {
  Completer completer = new Completer();
  asyncTest(() => completer.future.then((_) {
    // Clear the DOM to work around a bug in test.dart.
    document.body.nodes.clear();
  }));
  return completer;
}

InteractionManager mockTryDartInteraction() {
  UserOption.storage = {};

  InteractionManager interaction = new InteractionManager();

  hackDiv = new DivElement();
  mainEditorPane = new DivElement()
      ..style.whiteSpace = 'pre'
      ..contentEditable = 'true';

  observer = new MutationObserver(interaction.onMutation);
  observer.observe(
      mainEditorPane, childList: true, characterData: true, subtree: true);

  document.body.nodes.addAll([mainEditorPane, hackDiv]);

  return interaction;
}

class MockKeyboardEvent extends KeyEvent {
  final int keyCode;

  MockKeyboardEvent(String type, {int keyCode})
      : this.keyCode = keyCode,
        super.wrap(new KeyEvent(type, keyCode: keyCode));

  bool getModifierState(String keyArgument) => false;
}

typedef void VoidFunction();

class TestCase {
  final String description;
  final VoidFunction setup;
  final VoidFunction validate;

  TestCase(this.description, this.setup, this.validate);
}
