// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/utilities/navigation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(NavigationGeneratorTest);
}

@reflectiveTest
class NavigationGeneratorTest {
  test_none() {
    NavigationGenerator generator = new NavigationGenerator(null, []);
    List<Notification> notifications =
        generator.generateNavigationNotification('a.dart');
    expect(notifications, hasLength(1));
  }

  test_normal() {
    TestContributor contributor = new TestContributor();
    NavigationGenerator generator =
        new NavigationGenerator(null, [contributor]);
    List<Notification> notifications =
        generator.generateNavigationNotification('a.dart');
    expect(notifications, hasLength(1));
    expect(contributor.count, 1);
  }

  /**
   * This tests that we get an error notification for each contributor that
   * throws an error and that an error in one contributor doesn't prevent other
   * contributors from being called.
   */
  test_withException() {
    TestContributor contributor1 = new TestContributor();
    TestContributor contributor2 = new TestContributor(throwException: true);
    TestContributor contributor3 = new TestContributor();
    TestContributor contributor4 = new TestContributor(throwException: true);
    NavigationGenerator generator = new NavigationGenerator(
        null, [contributor1, contributor2, contributor3, contributor4]);
    List<Notification> notifications =
        generator.generateNavigationNotification('a.dart');
    expect(notifications, hasLength(3));
    expect(
        notifications.where(
            (notification) => notification.event == 'analysis.navigation'),
        hasLength(1));
    expect(
        notifications
            .where((notification) => notification.event == 'plugin.error'),
        hasLength(2));
    expect(contributor1.count, 1);
    expect(contributor2.count, 1);
    expect(contributor3.count, 1);
    expect(contributor4.count, 1);
  }
}

class TestContributor implements NavigationContributor {
  /**
   * A flag indicating whether the contributor should throw an exception when
   * [computeNavigation] is invoked.
   */
  bool throwException;

  /**
   * The number of times that [computeNavigation] was invoked.
   */
  int count = 0;

  TestContributor({this.throwException: false});

  @override
  void computeNavigation(NavigationCollector collector,
      AnalysisDriverGeneric driver, String filePath, int offset, int length) {
    count++;
    if (throwException) {
      throw new Exception();
    }
  }
}
