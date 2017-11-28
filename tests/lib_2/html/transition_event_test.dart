// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library transition_event_test;

import 'dart:html';
import 'dart:async';

import 'package:expect/minitest.dart';

Future testTransitionEnd() async {
  var element = new DivElement();
  document.body.append(element);

  element.style.opacity = '0';
  element.style.width = '100px';
  element.style.height = '100px';
  element.style.background = 'red';
  element.style.transition = 'opacity .1s';

  final done = new Completer();

  new Timer(const Duration(milliseconds: 100), () {
    element.onTransitionEnd.first.then((e) {
      expect(e is TransitionEvent, isTrue);
      expect(e.propertyName, 'opacity');
    }).then(done.complete, onError: done.completeError);

    element.style.opacity = '1';
  });

  await done.future;
}

main() async {
  expect(CssStyleDeclaration.supportsTransitions, isTrue);
  if (CssStyleDeclaration.supportsTransitions) {
    await testTransitionEnd();
  }
}
