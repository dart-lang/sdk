// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as driver;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/generator.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(NavigationGeneratorTest);
}

@reflectiveTest
class NavigationGeneratorTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();

  ResolveResult resolveResult = new driver.AnalysisResult(
      null, null, 'a.dart', null, true, '', null, '', null, null, null);

  test_none() {
    NavigationGenerator generator = new NavigationGenerator([]);
    NavigationRequest request =
        new DartNavigationRequestImpl(provider, 0, 100, resolveResult);
    GeneratorResult result = generator.generateNavigationNotification(request);
    expect(result.notifications, hasLength(1));
  }

  test_normal() {
    TestContributor contributor = new TestContributor();
    NavigationGenerator generator = new NavigationGenerator([contributor]);
    NavigationRequest request =
        new DartNavigationRequestImpl(provider, 0, 100, resolveResult);
    GeneratorResult result = generator.generateNavigationNotification(request);
    expect(result.notifications, hasLength(1));
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
        [contributor1, contributor2, contributor3, contributor4]);
    NavigationRequest request =
        new DartNavigationRequestImpl(provider, 0, 100, resolveResult);
    GeneratorResult result = generator.generateNavigationNotification(request);
    expect(result.notifications, hasLength(3));
    expect(
        result.notifications.where(
            (notification) => notification.event == 'analysis.navigation'),
        hasLength(1));
    expect(
        result.notifications
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
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector) {
    count++;
    if (throwException) {
      throw new Exception();
    }
  }
}
