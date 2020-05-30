// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartSdkManagerTest);
    defineReflectiveTests(SdkDescriptionTest);
  });
}

@reflectiveTest
class DartSdkManagerTest with ResourceProviderMixin {
  void test_anySdk() {
    DartSdkManager manager = DartSdkManager('/a/b/c');
    expect(manager.anySdk, isNull);

    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription description = SdkDescription(<String>['/c/d'], options);
    DartSdk sdk = MockSdk(resourceProvider: resourceProvider);
    manager.getSdk(description, () => sdk);
    expect(manager.anySdk, same(sdk));
  }

  void test_getSdk_differentDescriptors() {
    DartSdkManager manager = DartSdkManager('/a/b/c');
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription description1 = SdkDescription(<String>['/c/d'], options);
    DartSdk sdk1 = MockSdk(resourceProvider: resourceProvider);
    DartSdk result1 = manager.getSdk(description1, () => sdk1);
    expect(result1, same(sdk1));
    SdkDescription description2 = SdkDescription(<String>['/e/f'], options);
    DartSdk sdk2 = MockSdk(resourceProvider: resourceProvider);
    DartSdk result2 = manager.getSdk(description2, () => sdk2);
    expect(result2, same(sdk2));

    manager.getSdk(description1, _failIfAbsent);
    manager.getSdk(description2, _failIfAbsent);
  }

  void test_getSdk_sameDescriptor() {
    DartSdkManager manager = DartSdkManager('/a/b/c');
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription description = SdkDescription(<String>['/c/d'], options);
    DartSdk sdk = MockSdk(resourceProvider: resourceProvider);
    DartSdk result = manager.getSdk(description, () => sdk);
    expect(result, same(sdk));
    manager.getSdk(description, _failIfAbsent);
  }

  DartSdk _failIfAbsent() {
    fail('Use of ifAbsent function');
  }
}

@reflectiveTest
class SdkDescriptionTest {
  void test_equals_differentPaths_nested() {
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription left = SdkDescription(<String>['/a/b/c'], options);
    SdkDescription right = SdkDescription(<String>['/a/b'], options);
    expect(left == right, isFalse);
  }

  void test_equals_differentPaths_unrelated() {
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription left = SdkDescription(<String>['/a/b/c'], options);
    SdkDescription right = SdkDescription(<String>['/d/e'], options);
    expect(left == right, isFalse);
  }

  void test_equals_noPaths() {
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription left = SdkDescription(<String>[], options);
    SdkDescription right = SdkDescription(<String>[], options);
    expect(left == right, isTrue);
  }

  void test_equals_samePaths_differentOptions() {
    String path = '/a/b/c';
    AnalysisOptionsImpl leftOptions = AnalysisOptionsImpl()
      ..useFastaParser = false;
    AnalysisOptionsImpl rightOptions = AnalysisOptionsImpl()
      ..useFastaParser = true;
    SdkDescription left = SdkDescription(<String>[path], leftOptions);
    SdkDescription right = SdkDescription(<String>[path], rightOptions);
    expect(left == right, isFalse);
  }

  void test_equals_samePaths_sameOptions_multiple() {
    String leftPath = '/a/b/c';
    String rightPath = '/d/e';
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription left =
        SdkDescription(<String>[leftPath, rightPath], options);
    SdkDescription right =
        SdkDescription(<String>[leftPath, rightPath], options);
    expect(left == right, isTrue);
  }

  void test_equals_samePaths_sameOptions_single() {
    String path = '/a/b/c';
    AnalysisOptions options = AnalysisOptionsImpl();
    SdkDescription left = SdkDescription(<String>[path], options);
    SdkDescription right = SdkDescription(<String>[path], options);
    expect(left == right, isTrue);
  }
}
