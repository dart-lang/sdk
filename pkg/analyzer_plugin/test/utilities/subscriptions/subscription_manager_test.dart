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
    manager.setSubscriptions({
      AnalysisService.HIGHLIGHTS: [
        '/project/lib/foo.dart',
        '/project/lib/bar.dart'
      ],
      AnalysisService.NAVIGATION: ['/project/lib/foo.dart']
    });
    expect(manager.servicesForFile('/project/lib/test.dart'), hasLength(0));
    expect(manager.servicesForFile('/project/lib/bar.dart'),
        unorderedEquals([AnalysisService.HIGHLIGHTS]));
    expect(
        manager.servicesForFile('/project/lib/foo.dart'),
        unorderedEquals(
            [AnalysisService.HIGHLIGHTS, AnalysisService.NAVIGATION]));
  }
}
