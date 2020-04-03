// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../plugin/mocks.dart';

void main() {
  defineReflectiveTests(NavigationGeneratorTest);
}

@reflectiveTest
class NavigationGeneratorTest with ResourceProviderMixin {
  ResolvedUnitResult resolvedUnit = MockResolvedUnitResult(path: 'a.dart');

  void test_none() {
    var generator = NavigationGenerator([]);
    NavigationRequest request =
        DartNavigationRequestImpl(resourceProvider, 0, 100, resolvedUnit);
    var result = generator.generateNavigationNotification(request);
    expect(result.notifications, hasLength(1));
  }

  void test_normal() {
    var contributor = TestContributor();
    var generator = NavigationGenerator([contributor]);
    NavigationRequest request =
        DartNavigationRequestImpl(resourceProvider, 0, 100, resolvedUnit);
    var result = generator.generateNavigationNotification(request);
    expect(result.notifications, hasLength(1));
    expect(contributor.count, 1);
  }

  /// This tests that we get an error notification for each contributor that
  /// throws an error and that an error in one contributor doesn't prevent other
  /// contributors from being called.
  void test_withException() {
    var contributor1 = TestContributor();
    var contributor2 = TestContributor(throwException: true);
    var contributor3 = TestContributor();
    var contributor4 = TestContributor(throwException: true);
    var generator = NavigationGenerator(
        [contributor1, contributor2, contributor3, contributor4]);
    NavigationRequest request =
        DartNavigationRequestImpl(resourceProvider, 0, 100, resolvedUnit);
    var result = generator.generateNavigationNotification(request);
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
  /// A flag indicating whether the contributor should throw an exception when
  /// [computeNavigation] is invoked.
  bool throwException;

  /// The number of times that [computeNavigation] was invoked.
  int count = 0;

  TestContributor({this.throwException = false});

  @override
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector) {
    count++;
    if (throwException) {
      throw Exception();
    }
  }
}
