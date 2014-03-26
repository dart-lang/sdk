// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--package-root=sdk/lib/_internal/

library trydart.paste_test;

import 'dart:html';
import 'dart:async';

import '../../site/try/src/interaction_manager.dart' show
    InteractionManager;

import '../../site/try/src/ui.dart' show
    inputPre,
    observer;

import '../../site/try/src/user_option.dart' show
    UserOption;

import '../../pkg/expect/lib/expect.dart';
import '../../pkg/async_helper/lib/async_helper.dart';

main() {
  UserOption.storage = {};

  var interaction = new InteractionManager();
  inputPre = new DivElement();
  document.body.append(inputPre);
  observer = new MutationObserver(interaction.onMutation)
      ..observe(inputPre, childList: true, characterData: true, subtree: true);

  inputPre.innerHtml = "<span><p>//...</p>}</span>";

  asyncTest(() => new Future(() {
    print('Welcome to the future');
    Expect.stringEquals('//...\n}\n', inputPre.text);
  }).then((_) {
    inputPre.innerHtml = 'someText';
    return new Future(() {
      Expect.stringEquals('someText\n', inputPre.text);

      // Clear the DOM to work around a bug in test.dart.
      document.body.nodes.clear();
    });
  }));
}
