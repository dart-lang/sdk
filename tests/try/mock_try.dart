// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' show
    DivElement,
    MutationObserver,
    document;

import 'package:try/src/interaction_manager.dart' show
    InteractionManager;

import 'package:try/src/ui.dart' show
    hackDiv,
    mainEditorPane,
    observer;

import 'package:try/src/user_option.dart' show
    UserOption;

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

void clearEditorPaneWithoutNotifications() {
  mainEditorPane.nodes.clear();
  observer.takeRecords();
}
