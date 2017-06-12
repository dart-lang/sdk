// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/subscriptions/subscription_manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(SubscriptionManagerTest);
}

@reflectiveTest
class SubscriptionManagerTest {
  SubscriptionManager manager = new SubscriptionManager();

  test_servicesForFile() {
    expect(manager.servicesForFile('/project/lib/test.dart'), hasLength(0));
  }

  test_setSubscriptions() {
    String fooPath = '/project/lib/foo.dart';
    String barPath = '/project/lib/bar.dart';
    String bazPath = '/project/lib/baz.dart';
    //
    // Set the initial set of subscriptions.
    //
    Map<String, List<AnalysisService>> newSubscriptions =
        manager.setSubscriptions({
      AnalysisService.HIGHLIGHTS: [fooPath, barPath],
      AnalysisService.NAVIGATION: [fooPath]
    });

    expect(
        manager.servicesForFile(fooPath),
        unorderedEquals(
            [AnalysisService.HIGHLIGHTS, AnalysisService.NAVIGATION]));
    expect(manager.servicesForFile(barPath),
        unorderedEquals([AnalysisService.HIGHLIGHTS]));
    expect(manager.servicesForFile(bazPath), hasLength(0));

    expect(
        newSubscriptions[fooPath],
        unorderedEquals(
            [AnalysisService.HIGHLIGHTS, AnalysisService.NAVIGATION]));
    expect(newSubscriptions[barPath],
        unorderedEquals([AnalysisService.HIGHLIGHTS]));
    //
    // Update the subscriptions.
    //
    newSubscriptions = manager.setSubscriptions({
      AnalysisService.HIGHLIGHTS: [bazPath, barPath],
      AnalysisService.NAVIGATION: [barPath]
    });

    expect(manager.servicesForFile(fooPath), hasLength(0));
    expect(
        manager.servicesForFile(barPath),
        unorderedEquals(
            [AnalysisService.HIGHLIGHTS, AnalysisService.NAVIGATION]));
    expect(manager.servicesForFile(bazPath),
        unorderedEquals([AnalysisService.HIGHLIGHTS]));

    expect(newSubscriptions[barPath],
        unorderedEquals([AnalysisService.NAVIGATION]));
    expect(newSubscriptions[bazPath],
        unorderedEquals([AnalysisService.HIGHLIGHTS]));
  }
}
