// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.internal_error_test;

import 'dart:html';
import 'dart:async';

import 'package:try/src/interaction_manager.dart' show
    InteractionManager,
    TRY_DART_NEW_DEFECT;

import 'package:try/src/ui.dart' show
    mainEditorPane,
    observer,
    outputDiv;

import 'package:try/src/user_option.dart' show
    UserOption;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

main() {
  UserOption.storage = {};

  var interaction = new InteractionManager();
  mainEditorPane = new DivElement();
  outputDiv = new PreElement();
  document.body.append(mainEditorPane);
  observer = new MutationObserver((mutations, observer) {
    try {
      interaction.onMutation(mutations, observer);
    } catch (e) {
      // Ignored.
    }
  });
  observer.observe(
      mainEditorPane, childList: true, characterData: true, subtree: true);

  mainEditorPane.innerHtml = 'main() { print("hello"); }';

  interaction.currentCompilationUnit = null; // This will provoke a crash.

  asyncTest(() {
    return new Future(() {
      Expect.isTrue(outputDiv.text.contains(TRY_DART_NEW_DEFECT));
    });
  });
}
