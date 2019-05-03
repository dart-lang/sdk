// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsImplTest);
    defineReflectiveTests(SourcesChangedEventTest);
  });
}

@reflectiveTest
class AnalysisOptionsImplTest {
  test_resetToDefaults() {
    // Note that this only tests options visible from the interface.
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    AnalysisOptionsImpl modifiedOptions = new AnalysisOptionsImpl();
    modifiedOptions.dart2jsHint = true;
    modifiedOptions.disableCacheFlushing = true;
    modifiedOptions.enabledPluginNames = ['somePackage'];
    modifiedOptions.enableLazyAssignmentOperators = true;
    modifiedOptions.enableTiming = true;
    modifiedOptions.errorProcessors = [null];
    modifiedOptions.excludePatterns = ['a'];
    modifiedOptions.generateImplicitErrors = false;
    modifiedOptions.generateSdkErrors = true;
    modifiedOptions.hint = false;
    modifiedOptions.lint = true;
    modifiedOptions.lintRules = [null];
    modifiedOptions.patchPaths = {
      'dart:core': ['/dart_core.patch.dart']
    };
    modifiedOptions.preserveComments = false;
    modifiedOptions.trackCacheDependencies = false;

    modifiedOptions.resetToDefaults();

    expect(modifiedOptions.dart2jsHint, defaultOptions.dart2jsHint);
    expect(modifiedOptions.disableCacheFlushing,
        defaultOptions.disableCacheFlushing);
    expect(modifiedOptions.enabledPluginNames, isEmpty);
    expect(modifiedOptions.enableLazyAssignmentOperators,
        defaultOptions.enableLazyAssignmentOperators);
    expect(modifiedOptions.enableTiming, defaultOptions.enableTiming);
    expect(modifiedOptions.errorProcessors, defaultOptions.errorProcessors);
    expect(modifiedOptions.excludePatterns, defaultOptions.excludePatterns);
    expect(modifiedOptions.generateImplicitErrors,
        defaultOptions.generateImplicitErrors);
    expect(modifiedOptions.generateSdkErrors, defaultOptions.generateSdkErrors);
    expect(modifiedOptions.hint, defaultOptions.hint);
    expect(modifiedOptions.lint, defaultOptions.lint);
    expect(modifiedOptions.lintRules, defaultOptions.lintRules);
    expect(modifiedOptions.patchPaths, defaultOptions.patchPaths);
    expect(modifiedOptions.preserveComments, defaultOptions.preserveComments);
    expect(modifiedOptions.trackCacheDependencies,
        defaultOptions.trackCacheDependencies);
  }
}

@reflectiveTest
class SourcesChangedEventTest {
  void test_added() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.addedSource(source);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, wereSourcesAdded: true);
  }

  void test_changedContent() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.changedContent(source, 'library A;');
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, changedSources: [source]);
  }

  void test_changedContent2() {
    var source = new StringSource('', '/test.dart');
    var event = new SourcesChangedEvent.changedContent(source, 'library A;');
    assertEvent(event, changedSources: [source]);
  }

  void test_changedRange() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.changedRange(source, 'library A;', 0, 0, 13);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, changedSources: [source]);
  }

  void test_changedRange2() {
    var source = new StringSource('', '/test.dart');
    var event =
        new SourcesChangedEvent.changedRange(source, 'library A;', 0, 0, 13);
    assertEvent(event, changedSources: [source]);
  }

  void test_changedSources() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.changedSource(source);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, changedSources: [source]);
  }

  void test_empty() {
    var changeSet = new ChangeSet();
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event);
  }

  void test_removed() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.removedSource(source);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, wereSourcesRemoved: true);
  }

  static void assertEvent(SourcesChangedEvent event,
      {bool wereSourcesAdded: false,
      List<Source> changedSources: const <Source>[],
      bool wereSourcesRemoved: false}) {
    expect(event.wereSourcesAdded, wereSourcesAdded);
    expect(event.changedSources, changedSources);
    expect(event.wereSourcesRemoved, wereSourcesRemoved);
  }
}
