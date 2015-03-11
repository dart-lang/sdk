// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.dart_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisTask, ParseDartTask, ScanDartTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(BuildCompilationUnitElementTaskTest);
  runReflectiveTests(BuildLibraryElementTaskTest);
  runReflectiveTests(BuildPublicNamespaceTaskTest);
  runReflectiveTests(ParseDartTaskTest);
  runReflectiveTests(ScanDartTaskTest);
}

@reflectiveTest
class BuildCompilationUnitElementTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs =
        BuildCompilationUnitElementTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals(
        [BuildCompilationUnitElementTask.PARSED_UNIT_INPUT_NAME]));
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    BuildCompilationUnitElementTask task =
        new BuildCompilationUnitElementTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    BuildCompilationUnitElementTask task =
        BuildCompilationUnitElementTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    BuildCompilationUnitElementTask task =
        new BuildCompilationUnitElementTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildCompilationUnitElementTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_library() {
    BuildCompilationUnitElementTask task = _performBuildTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(2));
    expect(outputs[COMPILATION_UNIT_ELEMENT], isNotNull);
    expect(outputs[BUILT_UNIT], isNotNull);
  }

  BuildCompilationUnitElementTask _performBuildTask(String content) {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();

    ScanDartTask scanTask = new ScanDartTask(context, target);
    scanTask.inputs = {ScanDartTask.CONTENT_INPUT_NAME: content};
    scanTask.perform();
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;

    ParseDartTask parseTask = new ParseDartTask(context, target);
    parseTask.inputs = {
      ParseDartTask.LINE_INFO_INPUT_NAME: scanOutputs[LINE_INFO],
      ParseDartTask.TOKEN_STREAM_INPUT_NAME: scanOutputs[TOKEN_STREAM]
    };
    parseTask.perform();
    Map<ResultDescriptor, dynamic> parseOutputs = parseTask.outputs;

    BuildCompilationUnitElementTask buildTask =
        new BuildCompilationUnitElementTask(context, target);
    buildTask.inputs = {
      BuildCompilationUnitElementTask.PARSED_UNIT_INPUT_NAME:
          parseOutputs[PARSED_UNIT]
    };
    buildTask.perform();

    return buildTask;
  }
}

@reflectiveTest
class BuildLibraryElementTaskTest extends _AbstractDartTaskTest {
  Source librarySource;
  CompilationUnit libraryUnit;
  CompilationUnitElement libraryUnitElement;
  List<CompilationUnit> partUnits;

  LibraryElement libraryElement;

  test_buildInputs() {
    ExtendedAnalysisContext context = new _MockContext();
    // prepare sources
    File libraryFile = resourceProvider.newFile('/lib.dart', '');
    File partFile1 = resourceProvider.newFile('/part1.dart', '');
    File partFile2 = resourceProvider.newFile('/part2.dart', '');
    Source librarySource = libraryFile.createSource();
    Source partSource1 = partFile1.createSource();
    Source partSource2 = partFile2.createSource();
    // set INCLUDED_PARTS
    context.getCacheEntry(librarySource).setValue(
        INCLUDED_PARTS, <Source>[partSource1, partSource2]);
    // set BUILT_UNIT
    CompilationUnit libraryUnit = AstFactory.compilationUnit();
    CompilationUnit partUnit1 = AstFactory.compilationUnit();
    CompilationUnit partUnit2 = AstFactory.compilationUnit();
    context.getCacheEntry(librarySource).setValue(BUILT_UNIT, libraryUnit);
    context.getCacheEntry(partSource1).setValue(BUILT_UNIT, partUnit1);
    context.getCacheEntry(partSource2).setValue(BUILT_UNIT, partUnit2);
    // request inputs
    WorkItem workItem = new WorkItem(
        context, librarySource, BuildLibraryElementTask.DESCRIPTOR);
    workItem.gatherInputs(null);
    Map<String, dynamic> inputs = workItem.inputs;
    expect(inputs, hasLength(2));
    expect(inputs[BuildLibraryElementTask.DEFINING_BUILT_UNIT_INPUT_NAME],
        libraryUnit);
    expect(inputs[BuildLibraryElementTask.PART_BUILT_UNITS_INPUT_NAME],
        unorderedEquals([partUnit1, partUnit2]));
  }

  test_constructor() {
    AnalysisTarget target = new TestSource();
    BuildLibraryElementTask task = new BuildLibraryElementTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisTarget target = new TestSource();
    BuildLibraryElementTask task =
        BuildLibraryElementTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    BuildLibraryElementTask task = new BuildLibraryElementTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildLibraryElementTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part1.dart';
part 'part2.dart';
''',
      '/part1.dart': '''
part of lib;
''',
      '/part2.dart': '''
part of lib;
'''
    });
    expect(task.caughtException, isNull);
    expect(outputs, hasLength(4));
    // simple outputs
    expect(outputs[BUILD_LIBRARY_ERRORS], isEmpty);
    expect(outputs[IS_LAUNCHABLE], isFalse);
    expect(outputs[HAS_HTML_IMPORT], isFalse);
    // LibraryElement output
    expect(libraryElement, isNotNull);
    expect(libraryElement.entryPoint, isNull);
    expect(libraryElement.source, same(librarySource));
    expect(libraryElement.definingCompilationUnit, libraryUnitElement);
    expect(libraryElement.parts,
        unorderedEquals([partUnits[0].element, partUnits[1].element]));
    // LibraryElement references
    expect((libraryUnit.directives[0] as LibraryDirective).element,
        same(libraryElement));
    expect((partUnits[0].directives[0] as PartOfDirective).element,
        same(libraryElement));
    expect((partUnits[1].directives[0] as PartOfDirective).element,
        same(libraryElement));
    // CompilationUnitElement(s)
    {
      CompilationUnitElement unitElement = partUnits[0].element;
      expect(unitElement.uri, 'part1.dart');
      expect(unitElement.uriOffset, 18);
      expect(unitElement.uriEnd, 30);
      expect((libraryUnit.directives[1] as PartDirective).element,
          same(unitElement));
    }
    {
      CompilationUnitElement unitElement = partUnits[1].element;
      expect(unitElement.uri, 'part2.dart');
      expect(unitElement.uriOffset, 37);
      expect(unitElement.uriEnd, 49);
      expect((libraryUnit.directives[2] as PartDirective).element,
          same(unitElement));
    }
  }

  test_perform_error_missingLibraryDirectiveWithPart() {
    _performBuildTask({
      '/lib.dart': '''
part 'part.dart';
''',
      '/part.dart': '''
part of lib;
'''
    });
    expect(task.caughtException, isNull);
    _assertErrorsWithCodes(
        [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
  }

  test_perform_error_partOfDifferentLibrary() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part.dart';
''',
      '/part.dart': '''
part of someOtherLib;
'''
    });
    expect(task.caughtException, isNull);
    _assertErrorsWithCodes([StaticWarningCode.PART_OF_DIFFERENT_LIBRARY]);
  }

  test_perform_error_partOfNonPart() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part.dart';
''',
      '/part.dart': '''
// no part of
'''
    });
    expect(task.caughtException, isNull);
    _assertErrorsWithCodes([CompileTimeErrorCode.PART_OF_NON_PART]);
  }

  test_perform_hasHtmlImport() {
    _performBuildTask({
      '/lib.dart': '''
import 'dart:html';
'''
    });
    expect(outputs[HAS_HTML_IMPORT], isTrue);
  }

  test_perform_isLaunchable_inDefiningUnit() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
main() {
}
'''
    });
    expect(outputs[IS_LAUNCHABLE], isTrue);
    expect(libraryElement.entryPoint, isNotNull);
  }

  test_perform_isLaunchable_inPartUnit() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part.dart';
''',
      '/part.dart': '''
part of lib;
main() {
}
'''
    });
    expect(outputs[IS_LAUNCHABLE], isTrue);
    expect(libraryElement.entryPoint, isNotNull);
  }

  test_perform_patchTopLevelAccessors() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part1.dart';
part 'part2.dart';
''',
      '/part1.dart': '''
part of lib;
int get test => 0;
''',
      '/part2.dart': '''
part of lib;
void set test(_) {}
'''
    });
    CompilationUnitElement unitElement1 = partUnits[0].element;
    CompilationUnitElement unitElement2 = partUnits[1].element;
    PropertyAccessorElement getter = unitElement1.accessors[0];
    PropertyAccessorElement setter = unitElement2.accessors[0];
    PropertyInducingElement variable = getter.variable;
    expect(getter.isGetter, isTrue);
    expect(setter.isSetter, isTrue);
    expect(variable, isNotNull);
    expect(setter.variable, same(variable));
    expect(unitElement1.topLevelVariables, [variable]);
    expect(unitElement2.topLevelVariables, [variable]);
  }

  void _assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    List<AnalysisError> errors = outputs[BUILD_LIBRARY_ERRORS];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll(errors);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  void _performBuildTask(Map<String, String> sourceMap) {
    _BuildLibraryElementTaskResult result = _buildLibraryElement(sourceMap);
    Map<String, CompilationUnit> unitMap = <String, CompilationUnit>{};
    sourceMap.forEach((String path, String content) {
      CompilationUnit unit = _buildCompilationUnit(path, content);
      unitMap[path] = unit;
    });

    libraryUnit = result.libraryUnit;
    libraryUnitElement = result.libraryUnitElement;
    librarySource = result.librarySource;
    partUnits = result.partUnits;

    task = result.task;
    outputs = result.outputs;
    libraryElement = result.libraryElement;
  }
}

@reflectiveTest
class BuildPublicNamespaceTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs =
        BuildPublicNamespaceTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals(
        [BuildPublicNamespaceTask.BUILT_LIBRARY_ELEMENT_INPUT_NAME]));
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    BuildPublicNamespaceTask task =
        new BuildPublicNamespaceTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    BuildPublicNamespaceTask task =
        BuildPublicNamespaceTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    BuildPublicNamespaceTask task = new BuildPublicNamespaceTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildPublicNamespaceTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    var buildLibraryElementResult = _buildLibraryElement({
      '/lib.dart': '''
library lib;
part 'part.dart';
a() {}
_b() {}
''',
      '/part.dart': '''
part of lib;
_c() {}
d() {}
'''
    });
    Source librarySource = buildLibraryElementResult.librarySource;
    LibraryElement libraryElement = buildLibraryElementResult.libraryElement;
    // perform task
    BuildPublicNamespaceTask task =
        new BuildPublicNamespaceTask(context, librarySource);
    task.inputs = {
      BuildPublicNamespaceTask.BUILT_LIBRARY_ELEMENT_INPUT_NAME: libraryElement
    };
    Map<ResultDescriptor, dynamic> outputs = _performTask(task);
    // validate
    Namespace namespace = outputs[PUBLIC_NAMESPACE];
    expect(namespace.definedNames.keys, unorderedEquals(['a', 'd']));
  }
}

@reflectiveTest
class ParseDartTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs = ParseDartTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals([
      ParseDartTask.LINE_INFO_INPUT_NAME,
      ParseDartTask.TOKEN_STREAM_INPUT_NAME
    ]));
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ParseDartTask task = new ParseDartTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ParseDartTask task = ParseDartTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    ParseDartTask task = new ParseDartTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ParseDartTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    ParseDartTask task = _performParseTask(r'''
part of lib;
class B {}''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    expect(outputs[IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.PART);
  }

  test_perform_invalidDirectives() {
    ParseDartTask task = _performParseTask(r'''
library lib;
import '/does/not/exist.dart';
import '://invaliduri.dart';
export '${a}lib3.dart';
part 'part.dart';
class A {}''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    expect(outputs[IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(2));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  test_perform_library() {
    ParseDartTask task = _performParseTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');

    expect(task.caughtException, isNull);
    Map<ResultDescriptor<dynamic>, dynamic> outputs = task.outputs;
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(1));
    expect(outputs[IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(1));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  ParseDartTask _performParseTask(String content) {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();

    ScanDartTask scanTask = new ScanDartTask(context, target);
    scanTask.inputs = {ScanDartTask.CONTENT_INPUT_NAME: content};
    scanTask.perform();
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;

    ParseDartTask parseTask = new ParseDartTask(context, target);
    parseTask.inputs = {
      ParseDartTask.LINE_INFO_INPUT_NAME: scanOutputs[LINE_INFO],
      ParseDartTask.TOKEN_STREAM_INPUT_NAME: scanOutputs[TOKEN_STREAM]
    };
    parseTask.perform();
    return parseTask;
  }
}

@reflectiveTest
class ScanDartTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs = ScanDartTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals([ScanDartTask.CONTENT_INPUT_NAME]));
  }

  test_constructor() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ScanDartTask task = new ScanDartTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();
    ScanDartTask task = ScanDartTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_description() {
    AnalysisTarget target = new TestSource();
    ScanDartTask task = new ScanDartTask(null, target);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ScanDartTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_errors() {
    ScanDartTask scanTask = _performScanTask('import "');

    expect(scanTask.caughtException, isNull);
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;
    expect(scanOutputs, hasLength(3));
    expect(scanOutputs[LINE_INFO], isNotNull);
    expect(scanOutputs[SCAN_ERRORS], hasLength(1));
    expect(scanOutputs[TOKEN_STREAM], isNotNull);
  }

  test_perform_noErrors() {
    ScanDartTask scanTask = _performScanTask('class A {}');

    expect(scanTask.caughtException, isNull);
    Map<ResultDescriptor, dynamic> scanOutputs = scanTask.outputs;
    expect(scanOutputs, hasLength(3));
    expect(scanOutputs[LINE_INFO], isNotNull);
    expect(scanOutputs[SCAN_ERRORS], hasLength(0));
    expect(scanOutputs[TOKEN_STREAM], isNotNull);
  }

  ScanDartTask _performScanTask(String content) {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    AnalysisTarget target = new TestSource();

    ScanDartTask scanTask = new ScanDartTask(context, target);
    scanTask.inputs = {ScanDartTask.CONTENT_INPUT_NAME: content};
    scanTask.perform();
    return scanTask;
  }
}

class _AbstractDartTaskTest extends EngineTestCase {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
  Map<AnalysisTarget, CacheEntry> entryMap = <AnalysisTarget, CacheEntry>{};

  AnalysisTask task;
  Map<ResultDescriptor<dynamic>, dynamic> outputs;

  CacheEntry getCacheEntry(AnalysisTarget target) {
    return entryMap.putIfAbsent(target, () => new CacheEntry());
  }

  void setUp() {
    DartSdk sdk = context.sourceFactory.dartSdk;
    context.sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ]);
  }

  CompilationUnit _buildCompilationUnit(String path, String content) {
    File file = resourceProvider.newFile(path, content);
    Source source = file.createSource();
    // scan
    ScanDartTask scanTask = new ScanDartTask(context, source);
    scanTask.inputs = {ScanDartTask.CONTENT_INPUT_NAME: content};
    var scanOutputs = _performTask(scanTask);
    // parse
    ParseDartTask parseTask = new ParseDartTask(context, source);
    parseTask.inputs = {
      ParseDartTask.LINE_INFO_INPUT_NAME: scanOutputs[LINE_INFO],
      ParseDartTask.TOKEN_STREAM_INPUT_NAME: scanOutputs[TOKEN_STREAM]
    };
    var parseOutputs = _performTask(parseTask);
    // build CompilationUnit
    BuildCompilationUnitElementTask buildTask =
        new BuildCompilationUnitElementTask(context, source);
    buildTask.inputs = {
      BuildCompilationUnitElementTask.PARSED_UNIT_INPUT_NAME:
          parseOutputs[PARSED_UNIT]
    };
    var buildUnitOutputs = _performTask(buildTask);
    // done
    return buildUnitOutputs[BUILT_UNIT];
  }

  _BuildLibraryElementTaskResult _buildLibraryElement(
      Map<String, String> sourceMap) {
    Map<String, CompilationUnit> unitMap = <String, CompilationUnit>{};
    sourceMap.forEach((String path, String content) {
      CompilationUnit unit = _buildCompilationUnit(path, content);
      unitMap[path] = unit;
    });

    CompilationUnit libraryUnit = unitMap.values.first;
    CompilationUnitElement libraryUnitElement = libraryUnit.element;
    Source librarySource = libraryUnitElement.source;
    List<CompilationUnit> partUnits = unitMap.values.skip(1).toList();

    BuildLibraryElementTask task =
        new BuildLibraryElementTask(context, librarySource);
    task.inputs = {
      BuildLibraryElementTask.DEFINING_BUILT_UNIT_INPUT_NAME: libraryUnit,
      BuildLibraryElementTask.PART_BUILT_UNITS_INPUT_NAME: partUnits
    };
    Map<ResultDescriptor, dynamic> outputs = _performTask(task);

    LibraryElement libraryElement = outputs[BUILT_LIBRARY_ELEMENT];
    return new _BuildLibraryElementTaskResult(librarySource, libraryUnit,
        libraryUnitElement, partUnits, task, outputs, libraryElement);
  }

  /**
   * Perform the given [task], record and return its outputs.
   */
  Map<ResultDescriptor, dynamic> _performTask(AnalysisTask task) {
    AnalysisTarget target = task.target;
    // perform the task
    task.perform();
    Map<ResultDescriptor, dynamic> outputs = task.outputs;
    // file the cache entry
    CacheEntry cacheEntry = getCacheEntry(target);
    outputs.forEach((result, value) {
      cacheEntry.setValue(result, value);
    });
    return outputs;
  }
}

class _BuildLibraryElementTaskResult {
  final Source librarySource;
  final CompilationUnit libraryUnit;
  final CompilationUnitElement libraryUnitElement;
  final List<CompilationUnit> partUnits;
  final BuildLibraryElementTask task;
  final Map<ResultDescriptor, dynamic> outputs;
  final LibraryElement libraryElement;
  _BuildLibraryElementTaskResult(this.librarySource, this.libraryUnit,
      this.libraryUnitElement, this.partUnits, this.task, this.outputs,
      this.libraryElement);
}

class _MockContext extends TypedMock implements ExtendedAnalysisContext {
  Map<AnalysisTarget, CacheEntry> entryMap = <AnalysisTarget, CacheEntry>{};

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    return entryMap.putIfAbsent(target, () => new CacheEntry());
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
