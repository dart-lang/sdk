// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.engine.task.dart;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/task/task_dart.dart';
import 'package:unittest/unittest.dart';

import '../generated/engine_test.dart';
import '../generated/resolver_test.dart';
import '../generated/test_support.dart';
import '../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(BuildUnitElementTaskTest);
}

class BuildUnitElementTaskTest extends EngineTestCase {
  void test_accept() {
    BuildUnitElementTask task = new BuildUnitElementTask(null, null, null, null);
    expect(task.accept(new BuildUnitElementTaskTV_accept()), isTrue);
  }

  void test_getException() {
    BuildUnitElementTask task = new BuildUnitElementTask(null, null, null, null);
    expect(task.exception, isNull);
  }

  void test_getLibrarySource() {
    Source source = new TestSource('/part.dart');
    Source library = new TestSource('/lib.dart');
    BuildUnitElementTask task =
        new BuildUnitElementTask(null, source, library, null);
    expect(task.library, equals(library));
  }

  void test_getUnitSource() {
    Source source = new TestSource('/part.dart');
    Source library = new TestSource('/lib.dart');
    BuildUnitElementTask task =
        new BuildUnitElementTask(null, source, library, null);
    expect(task.source, equals(source));
  }

  void test_perform_exception() {
    TestSource source = new TestSource();
    source.generateExceptionOnRead = true;
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    CompilationUnit unit = parseUnit(context, source, "");
    BuildUnitElementTask task =
        new BuildUnitElementTask(context, null, source, unit);
    task.perform(new BuildUnitElementTaskTV_perform_exception());
  }

  void test_perform_valid() {
    var content = EngineTestCase.createSource(["library lib;", "class A {}"]);
    Source source = new TestSource('/test.dart', content);
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    CompilationUnit unit = parseUnit(context, source, content);
    BuildUnitElementTask task =
        new BuildUnitElementTask(context, source, source, unit);
    task.perform(new BuildUnitElementTaskTV_perform_valid(source, unit));
  }

  CompilationUnit parseUnit(InternalAnalysisContext context, Source source, String content) {
    ScanDartTask scanTask = new ScanDartTask(
        context,
        source,
        content);
    scanTask.perform(new ScanDartTaskTestTV_accept());
    ParseDartTask parseTask = new ParseDartTask(
        context,
        source,
        scanTask.tokenStream,
        scanTask.lineInfo);
    parseTask.perform(new ParseDartTaskTestTV_accept());
    return parseTask.compilationUnit;
  }
}

class BuildUnitElementTaskTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitBuildUnitElementTask(BuildUnitElementTask task) => true;
}

class BuildUnitElementTaskTV_perform_exception extends TestTaskVisitor<bool> {
  @override
  bool visitBuildUnitElementTask(BuildUnitElementTask task) {
    expect(task.exception, isNotNull);
    return true;
  }
}

class BuildUnitElementTaskTV_perform_valid extends TestTaskVisitor<bool> {
  Source source;

  CompilationUnit unit;

  BuildUnitElementTaskTV_perform_valid(this.source, this.unit);

  @override
  bool visitBuildUnitElementTask(BuildUnitElementTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.source, equals(source));
    expect(task.library, equals(source));
    expect(task.unit, equals(unit));
    expect(task.unitElement, isNotNull);
    return true;
  }
}
