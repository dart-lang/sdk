// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventTaskZoneTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:async';
import 'dart:html';

// Tests event-subscription specifications.

main() {
  useHtmlConfiguration();

  var defaultTarget = new Element.div();
  var defaultOnData = (x) => null;

  EventSubscriptionSpecification createSpec({useCapture, isOneShot}) {
    return new EventSubscriptionSpecification(
        name: "name",
        target: defaultTarget,
        useCapture: useCapture,
        isOneShot: isOneShot,
        onData: defaultOnData,
        eventType: "eventType");
  }

  for (var useCapture in [true, false]) {
    for (var isOneShot in [true, false]) {
      var spec = createSpec(useCapture: useCapture, isOneShot: isOneShot);

      test(
          "EventSubscriptionSpecification - constructor "
          "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replaced = spec.replace(eventType: 'replace-eventType');
        expect(replaced.name, "name");
        expect(replaced.target, defaultTarget);
        expect(replaced.useCapture, useCapture);
        expect(replaced.isOneShot, isOneShot);
        expect(replaced.onData, equals(defaultOnData));
        expect(replaced.eventType, "replace-eventType");
      });

      test(
          "replace name "
          "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replaced = spec.replace(name: 'replace-name');
        expect(replaced.name, "replace-name");
        expect(replaced.target, defaultTarget);
        expect(replaced.useCapture, useCapture);
        expect(replaced.isOneShot, isOneShot);
        expect(replaced.onData, equals(defaultOnData));
        expect(replaced.eventType, "eventType");
      });

      test(
          "replace target "
          "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replacementTarget = new Element.a();
        var replaced = spec.replace(target: replacementTarget);
        expect(replaced.name, "name");
        expect(replaced.target, replacementTarget);
        expect(replaced.useCapture, useCapture);
        expect(replaced.isOneShot, isOneShot);
        expect(replaced.onData, equals(defaultOnData));
        expect(replaced.eventType, "eventType");
      });

      test(
          "replace useCapture "
              "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replaced = spec.replace(useCapture: !useCapture);
        expect(replaced.name, "name");
        expect(replaced.target, defaultTarget);
        expect(replaced.useCapture, !useCapture);
        expect(replaced.isOneShot, isOneShot);
        expect(replaced.onData, equals(defaultOnData));
        expect(replaced.eventType, "eventType");
      });

      test(
          "replace isOneShot "
              "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replaced = spec.replace(isOneShot: !isOneShot);
        expect(replaced.name, "name");
        expect(replaced.target, defaultTarget);
        expect(replaced.useCapture, useCapture);
        expect(replaced.isOneShot, !isOneShot);
        expect(replaced.onData, equals(defaultOnData));
        expect(replaced.eventType, "eventType");
      });

      test(
          "replace onData "
              "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replacementOnData = (x) {};
        var replaced = spec.replace(onData: replacementOnData);
        expect(replaced.name, "name");
        expect(replaced.target, defaultTarget);
        expect(replaced.useCapture, useCapture);
        expect(replaced.isOneShot, isOneShot);
        expect(replaced.onData, equals(replacementOnData));
        expect(replaced.eventType, "eventType");
      });

      test(
          "replace eventType "
          "useCapture: $useCapture isOneShot: $isOneShot", () {
        var replaced = spec.replace(eventType: 'replace-eventType');
        expect(replaced.name, "name");
        expect(replaced.target, defaultTarget);
        expect(replaced.useCapture, useCapture);
        expect(replaced.isOneShot, isOneShot);
        expect(replaced.onData, equals(defaultOnData));
        expect(replaced.eventType, "replace-eventType");
      });
    }
  }
}
