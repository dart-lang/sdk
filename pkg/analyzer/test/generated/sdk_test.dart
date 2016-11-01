// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.sdk_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/context/mock_sdk.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartSdkManagerTest);
    defineReflectiveTests(SdkDescriptionTest);
  });
}

@reflectiveTest
class DartSdkManagerTest extends EngineTestCase {
  void test_anySdk() {
    DartSdkManager manager = new DartSdkManager('/a/b/c', false);
    expect(manager.anySdk, isNull);

    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription description = new SdkDescription(<String>['/c/d'], options);
    DartSdk sdk = new MockSdk();
    manager.getSdk(description, () => sdk);
    expect(manager.anySdk, same(sdk));
  }

  void test_getSdk_differentDescriptors() {
    DartSdkManager manager = new DartSdkManager('/a/b/c', false);
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription description1 = new SdkDescription(<String>['/c/d'], options);
    DartSdk sdk1 = new MockSdk();
    DartSdk result1 = manager.getSdk(description1, () => sdk1);
    expect(result1, same(sdk1));
    SdkDescription description2 = new SdkDescription(<String>['/e/f'], options);
    DartSdk sdk2 = new MockSdk();
    DartSdk result2 = manager.getSdk(description2, () => sdk2);
    expect(result2, same(sdk2));

    manager.getSdk(description1, _failIfAbsent);
    manager.getSdk(description2, _failIfAbsent);
  }

  void test_getSdk_sameDescriptor() {
    DartSdkManager manager = new DartSdkManager('/a/b/c', false);
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription description = new SdkDescription(<String>['/c/d'], options);
    DartSdk sdk = new MockSdk();
    DartSdk result = manager.getSdk(description, () => sdk);
    expect(result, same(sdk));
    manager.getSdk(description, _failIfAbsent);
  }

  DartSdk _failIfAbsent() {
    fail('Use of ifAbsent function');
    return null;
  }
}

@reflectiveTest
class SdkDescriptionTest extends EngineTestCase {
  void test_equals_differentPaths_nested() {
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription left = new SdkDescription(<String>['/a/b/c'], options);
    SdkDescription right = new SdkDescription(<String>['/a/b'], options);
    expect(left == right, isFalse);
  }

  void test_equals_differentPaths_unrelated() {
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription left = new SdkDescription(<String>['/a/b/c'], options);
    SdkDescription right = new SdkDescription(<String>['/d/e'], options);
    expect(left == right, isFalse);
  }

  void test_equals_noPaths() {
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription left = new SdkDescription(<String>[], options);
    SdkDescription right = new SdkDescription(<String>[], options);
    expect(left == right, isTrue);
  }

  void test_equals_samePaths_differentOptions() {
    String path = '/a/b/c';
    AnalysisOptionsImpl leftOptions = new AnalysisOptionsImpl();
    AnalysisOptionsImpl rightOptions = new AnalysisOptionsImpl();
    rightOptions.strongMode = !leftOptions.strongMode;
    SdkDescription left = new SdkDescription(<String>[path], leftOptions);
    SdkDescription right = new SdkDescription(<String>[path], rightOptions);
    expect(left == right, isFalse);
  }

  void test_equals_samePaths_sameOptions_multiple() {
    String leftPath = '/a/b/c';
    String rightPath = '/d/e';
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription left =
        new SdkDescription(<String>[leftPath, rightPath], options);
    SdkDescription right =
        new SdkDescription(<String>[leftPath, rightPath], options);
    expect(left == right, isTrue);
  }

  void test_equals_samePaths_sameOptions_single() {
    String path = '/a/b/c';
    AnalysisOptions options = new AnalysisOptionsImpl();
    SdkDescription left = new SdkDescription(<String>[path], options);
    SdkDescription right = new SdkDescription(<String>[path], options);
    expect(left == right, isTrue);
  }
}
