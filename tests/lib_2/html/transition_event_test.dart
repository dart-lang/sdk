// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

// @dart = 2.9

library transition_event_test;

import 'dart:html';
import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/minitest.dart';

Future testTransitionEnd() async {
  var element = new DivElement();
  document.body.append(element);

  element.style.opacity = '0';
  element.style.width = '100px';
  element.style.height = '100px';
  element.style.background = 'red';
  element.style.transition = 'opacity .1s';
  final eventFuture = element.onTransitionEnd.first;
  await Future.delayed(const Duration(milliseconds: 100));
  element.style.opacity = '1';
  final e = await eventFuture;
  expect(e is TransitionEvent, isTrue);
  expect(e.propertyName, 'opacity');
}

main() {
  asyncTest(() async {
    expect(CssStyleDeclaration.supportsTransitions, isTrue);
    if (CssStyleDeclaration.supportsTransitions) {
      await testTransitionEnd();
    }
  });
}
