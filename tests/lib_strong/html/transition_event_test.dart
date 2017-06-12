// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library transition_event_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:async';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(CssStyleDeclaration.supportsTransitions, true);
    });
  });

  group('functional', () {
    test('transitionEnd', () {
      if (CssStyleDeclaration.supportsTransitions) {
        var element = new DivElement();
        document.body.append(element);

        element.style.opacity = '0';
        element.style.width = '100px';
        element.style.height = '100px';
        element.style.background = 'red';
        element.style.transition = 'opacity .1s';

        new Timer(const Duration(milliseconds: 100), expectAsync(() {
          element.onTransitionEnd.first.then(expectAsync((e) {
            expect(e is TransitionEvent, isTrue);
            expect(e.propertyName, 'opacity');
          }));

          element.style.opacity = '1';
        }));
      }
    });
  });
}
