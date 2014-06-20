// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.paste_test;

import 'dart:html';
import 'dart:async';

import 'package:try/src/interaction_manager.dart' show
    InteractionManager;

import 'package:try/src/ui.dart' show
    mainEditorPane,
    observer;

import 'package:try/src/user_option.dart' show
    UserOption;

import '../../pkg/expect/lib/expect.dart';
import '../../pkg/async_helper/lib/async_helper.dart';

const Map<String, String> tests = const <String, String> {
  '<span><p>//...</p>}</span>': '//...\n}',
  'someText': 'someText',
  '"\$"': '"<DIAGNOSTIC>\$</DIAGNOSTIC>"',
  '"\$\$"': '"<DIAGNOSTIC>\$</DIAGNOSTIC><DIAGNOSTIC>\$</DIAGNOSTIC>"',
  '"\$\$4"': '"<DIAGNOSTIC>\$</DIAGNOSTIC><DIAGNOSTIC>\$</DIAGNOSTIC>4"',
  '"\$\$4 "': '"<DIAGNOSTIC>\$</DIAGNOSTIC><DIAGNOSTIC>\$</DIAGNOSTIC>4 "',
  '1e': '<DIAGNOSTIC>1e</DIAGNOSTIC>',
  'r"""\n\n\'"""': 'r"""\n\n\'"""',
  '"': '<DIAGNOSTIC>"</DIAGNOSTIC>',
  '/**\n*/': '/**\n*/',
};

List<Node> queryDiagnosticNodes() {
  return mainEditorPane.querySelectorAll('a.diagnostic>span');
}

Future runTests() {
  Iterator<String> keys = tests.keys.iterator;
  keys.moveNext();
  mainEditorPane.innerHtml = keys.current;

  Future makeFuture() => new Future(() {
    String key = keys.current;
    print('Checking $key');
    queryDiagnosticNodes().forEach((Node node) {
      node.parent.insertBefore(
          new Text('<DIAGNOSTIC>'), node.parent.firstChild);
      node.replaceWith(new Text('</DIAGNOSTIC>'));
      observer.takeRecords(); // Discard mutations.
    });
    Expect.stringEquals(tests[key], mainEditorPane.text);
    if (keys.moveNext()) {
      key = keys.current;
      print('Setting $key');
      mainEditorPane.innerHtml = key;
      return makeFuture();
    } else {
      // Clear the DOM to work around a bug in test.dart.
      document.body.nodes.clear();
      return null;
    }
  });

  return makeFuture();
}

void main() {
  UserOption.storage = {};

  var interaction = new InteractionManager();
  mainEditorPane = new DivElement();
  document.body.append(mainEditorPane);
  observer = new MutationObserver(interaction.onMutation)
      ..observe(
          mainEditorPane, childList: true, characterData: true, subtree: true);

  asyncTest(runTests);
}
