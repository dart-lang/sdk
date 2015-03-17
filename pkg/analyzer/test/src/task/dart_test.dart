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
    hide AnalysisTask, GetContentTask, ParseDartTask, ScanDartTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../mock_sdk.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(BuildCompilationUnitElementTaskTest);
  runReflectiveTests(BuildDirectiveElementsTaskTest);
  runReflectiveTests(BuildEnumMemberElementsTaskTest);
  runReflectiveTests(BuildExportSourceClosureTaskTest);
  runReflectiveTests(BuildExportNamespaceTaskTest);
  runReflectiveTests(BuildLibraryElementTaskTest);
  runReflectiveTests(BuildPublicNamespaceTaskTest);
  runReflectiveTests(BuildTypeProviderTaskTest);
  runReflectiveTests(ParseDartTaskTest);
  runReflectiveTests(ScanDartTaskTest);
}

@reflectiveTest
class BuildCompilationUnitElementTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    LibraryUnitTarget target = new LibraryUnitTarget(emptySource, emptySource);
    Map<String, TaskInput> inputs =
        BuildCompilationUnitElementTask.buildInputs(target);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals(
        [BuildCompilationUnitElementTask.PARSED_UNIT_INPUT_NAME]));
  }

  test_constructor() {
    BuildCompilationUnitElementTask task =
        new BuildCompilationUnitElementTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_createTask() {
    BuildCompilationUnitElementTask task =
        BuildCompilationUnitElementTask.createTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_description() {
    BuildCompilationUnitElementTask task =
        new BuildCompilationUnitElementTask(null, emptySource);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildCompilationUnitElementTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_library() {
    _performBuildTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');
    expect(outputs, hasLength(2));
    expect(outputs[COMPILATION_UNIT_ELEMENT], isNotNull);
    expect(outputs[RESOLVED_UNIT1], isNotNull);
  }

  void _performBuildTask(String content) {
    Source source = _newSource('/test.dart', content);
    AnalysisTarget target = new LibraryUnitTarget(source, source);
    _computeResult(target, RESOLVED_UNIT1);
    expect(task, new isInstanceOf<BuildCompilationUnitElementTask>());
  }
}

@reflectiveTest
class BuildDirectiveElementsTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    ExtendedAnalysisContext context = new _MockContext();
    // prepare sources
    File fileA = resourceProvider.newFile('/libA.dart', '');
    File fileB = resourceProvider.newFile('/libB.dart', '');
    File fileC = resourceProvider.newFile('/libC.dart', '');
    Source sourceA = fileA.createSource();
    Source sourceB = fileB.createSource();
    Source sourceC = fileC.createSource();
    // configure "sourceA"
    CompilationUnit unitA = AstFactory.compilationUnit();
    context.getCacheEntry(sourceA).setValue(
        IMPORTED_LIBRARIES, <Source>[sourceB]);
    context.getCacheEntry(sourceA).setValue(
        EXPORTED_LIBRARIES, <Source>[sourceC]);
    context.getCacheEntry(sourceA).setValue(RESOLVED_UNIT2, unitA);
    // configure "sourceB"
    LibraryElement libraryElementB = ElementFactory.library(context, 'libB');
    context.getCacheEntry(sourceB).setValue(LIBRARY_ELEMENT1, libraryElementB);
    context.getCacheEntry(sourceB).setValue(SOURCE_KIND, SourceKind.LIBRARY);
    // configure "sourceC"
    LibraryElement libraryElementC = ElementFactory.library(context, 'libC');
    context.getCacheEntry(sourceC).setValue(LIBRARY_ELEMENT1, libraryElementC);
    context.getCacheEntry(sourceC).setValue(SOURCE_KIND, SourceKind.LIBRARY);
    // request inputs
    WorkItem workItem =
        new WorkItem(context, sourceA, BuildDirectiveElementsTask.DESCRIPTOR);
    workItem.gatherInputs(null);
    Map<String, dynamic> inputs = workItem.inputs;
    expect(inputs, hasLength(5));
    expect(inputs[BuildDirectiveElementsTask.RESOLVED_UNIT2_INPUT_NAME], unitA);
    expect(
        inputs[BuildDirectiveElementsTask.IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME],
        containsPair(sourceB, libraryElementB));
    expect(
        inputs[BuildDirectiveElementsTask.EXPORTS_LIBRARY_ELEMENT1_INPUT_NAME],
        containsPair(sourceC, libraryElementC));
    expect(inputs[BuildDirectiveElementsTask.IMPORTS_SOURCE_KIND_INPUT_NAME],
        containsPair(sourceB, SourceKind.LIBRARY));
    expect(inputs[BuildDirectiveElementsTask.EXPORTS_SOURCE_KIND_INPUT_NAME],
        containsPair(sourceC, SourceKind.LIBRARY));
  }

  test_constructor() {
    BuildDirectiveElementsTask task =
        new BuildDirectiveElementsTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_createTask() {
    BuildDirectiveElementsTask task =
        BuildDirectiveElementsTask.createTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_description() {
    BuildDirectiveElementsTask task =
        new BuildDirectiveElementsTask(null, emptySource);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildDirectiveElementsTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    List<Source> sources = _newSources({
      '/libA.dart': '''
library libA;
import 'libB.dart';
export 'libC.dart';
''',
      '/libB.dart': '''
library libB;
''',
      '/libC.dart': '''
library libC;
'''
    });
    Source sourceA = sources[0];
    Source sourceB = sources[1];
    Source sourceC = sources[2];
    // perform task
    _computeResult(sourceA, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // prepare outputs
    CompilationUnit libraryUnitA = outputs[RESOLVED_UNIT3];
    LibraryElement libraryElementA = libraryUnitA.element.library;
    LibraryElement libraryElementB = _getImportLibraryInput(sourceB);
    LibraryElement libraryElementC = _getExportLibraryInput(sourceC);
    // no errors
    _assertErrorsWithCodes([]);
    // validate directives
    {
      ImportDirective importNode = libraryUnitA.directives[1];
      ImportElement importElement = importNode.element;
      expect(importElement, isNotNull);
      expect(importElement.importedLibrary, libraryElementB);
      expect(importElement.prefix, isNull);
      expect(importElement.nameOffset, 14);
      expect(importElement.uriOffset, 21);
      expect(importElement.uriEnd, 32);
    }
    {
      ExportDirective exportNode = libraryUnitA.directives[2];
      ExportElement exportElement = exportNode.element;
      expect(exportElement, isNotNull);
      expect(exportElement.exportedLibrary, libraryElementC);
      expect(exportElement.nameOffset, 34);
      expect(exportElement.uriOffset, 41);
      expect(exportElement.uriEnd, 52);
    }
    // validate LibraryElement
    expect(libraryElementA.hasExtUri, isFalse);
    // has an artificial "dart:core" import
    {
      List<ImportElement> imports = libraryElementA.imports;
      expect(imports, hasLength(2));
      expect(imports[1].importedLibrary.isDartCore, isTrue);
    }
  }

  test_perform_combinators() {
    List<Source> sources = _newSources({
      '/libA.dart': '''
library libA;
import 'libB.dart' show A, B hide C, D;
''',
      '/libB.dart': '''
library libB;
'''
    });
    Source sourceA = sources[0];
    // perform task
    _computeResult(sourceA, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // prepare outputs
    CompilationUnit libraryUnitA = outputs[RESOLVED_UNIT3];
    // no errors
    _assertErrorsWithCodes([]);
    // validate directives
    ImportDirective importNode = libraryUnitA.directives[1];
    ImportElement importElement = importNode.element;
    List<NamespaceCombinator> combinators = importElement.combinators;
    expect(combinators, hasLength(2));
    {
      ShowElementCombinator combinator = combinators[0];
      expect(combinator.offset, 33);
      expect(combinator.end, 42);
      expect(combinator.shownNames, ['A', 'B']);
    }
    {
      HideElementCombinator combinator = combinators[1];
      expect(combinator.hiddenNames, ['C', 'D']);
    }
  }

  test_perform_error_exportOfNonLibrary() {
    List<Source> sources = _newSources({
      '/libA.dart': '''
library libA;
export 'part.dart';
''',
      '/part.dart': '''
part of notLib;
'''
    });
    Source sourceA = sources[0];
    // perform task
    _computeResult(sourceA, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // validate errors
    _assertErrorsWithCodes([CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
  }

  test_perform_error_importOfNonLibrary() {
    List<Source> sources = _newSources({
      '/libA.dart': '''
library libA;
import 'part.dart';
''',
      '/part.dart': '''
part of notLib;
'''
    });
    Source sourceA = sources[0];
    // perform task
    _computeResult(sourceA, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // validate errors
    _assertErrorsWithCodes([CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
  }

  test_perform_hasExtUri() {
    List<Source> sources = _newSources({
      '/lib.dart': '''
import 'dart-ext:doesNotExist.dart';
'''
    });
    Source source = sources[0];
    // perform task
    _computeResult(source, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // prepare outputs
    CompilationUnit libraryUnit = outputs[RESOLVED_UNIT3];
    LibraryElement libraryElement = libraryUnit.element.library;
    expect(libraryElement.hasExtUri, isTrue);
  }

  test_perform_importPrefix() {
    List<Source> sources = _newSources({
      '/libA.dart': '''
library libA;
import 'libB.dart' as pref;
import 'libC.dart' as pref;
''',
      '/libB.dart': '''
library libB;
''',
      '/libC.dart': '''
library libC;
'''
    });
    Source sourceA = sources[0];
    Source sourceB = sources[1];
    // perform task
    _computeResult(sourceA, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // prepare outputs
    CompilationUnit libraryUnitA = outputs[RESOLVED_UNIT3];
    // validate directives
    {
      ImportDirective importNodeB = libraryUnitA.directives[1];
      SimpleIdentifier prefixNodeB = importNodeB.prefix;
      ImportElement importElementB = importNodeB.element;
      PrefixElement prefixElement = importElementB.prefix;
      expect(importElementB, isNotNull);
      expect(importElementB.importedLibrary, _getImportLibraryInput(sourceB));
      expect(prefixElement, isNotNull);
      expect(importElementB.prefixOffset, prefixElement.nameOffset);
      expect(prefixNodeB.staticElement, prefixElement);
      // PrefixElement "pref" is shared
      ImportDirective importNodeC = libraryUnitA.directives[2];
      SimpleIdentifier prefixNodeC = importNodeC.prefix;
      ImportElement importElementC = importNodeC.element;
      expect(prefixNodeC.staticElement, prefixElement);
      expect(importElementC.prefix, prefixElement);
    }
  }

  void _assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    _fillErrorListener(BUILD_DIRECTIVES_ERRORS);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  _getExportLibraryInput(Source source) {
    var key = BuildDirectiveElementsTask.EXPORTS_LIBRARY_ELEMENT1_INPUT_NAME;
    return task.inputs[key][source];
  }

  _getImportLibraryInput(Source source) {
    var key = BuildDirectiveElementsTask.IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME;
    return task.inputs[key][source];
  }
}

@reflectiveTest
class BuildEnumMemberElementsTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = _newSource('/test.dart', '''
enum MyEnum {
  A, B
}
''');
    _computeResult(source, RESOLVED_UNIT4);
    expect(task, new isInstanceOf<BuildEnumMemberElementsTask>());
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    // validate Element
    ClassElement enumElement = unit.element.getEnum('MyEnum');
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(4));
    {
      FieldElementImpl index = fields[0];
      expect(index, isNotNull);
      expect(index.name, 'index');
      expect(index.isStatic, isFalse);
      expect(index.evaluationResult, isNull);
      _assertGetter(index);
    }
    {
      ConstFieldElementImpl values = fields[1];
      expect(values, isNotNull);
      expect(values.name, 'values');
      expect(values.isStatic, isTrue);
      expect(values.evaluationResult, isNotNull);
      _assertGetter(values);
    }
    {
      ConstFieldElementImpl constant = fields[2];
      expect(constant, isNotNull);
      expect(constant.name, 'A');
      expect(constant.isStatic, isTrue);
      expect(constant.evaluationResult, isNotNull);
      _assertGetter(constant);
    }
    {
      ConstFieldElementImpl constant = fields[3];
      expect(constant, isNotNull);
      expect(constant.name, 'B');
      expect(constant.isStatic, isTrue);
      expect(constant.evaluationResult, isNotNull);
      _assertGetter(constant);
    }
    // validate nodes
    EnumDeclaration enumNode = unit.declarations[0];
    expect(enumNode.name.staticElement, same(enumElement));
    expect(enumNode.constants[0].element, same(enumElement.getField('A')));
    expect(enumNode.constants[1].element, same(enumElement.getField('B')));
  }

  static void _assertGetter(FieldElement field) {
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.variable, same(field));
    expect(getter.type, isNotNull);
  }
}

@reflectiveTest
class BuildExportNamespaceTaskTest extends _AbstractDartTaskTest {
  test_perform_entyrPoint() {
    Source sourceA = _newSource('/a.dart', '''
library lib_a;
export 'b.dart';
''');
    Source sourceB = _newSource('/b.dart', '''
library lib_b;
main() {}
''');
    _computeResult(sourceA, LIBRARY_ELEMENT3);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      LibraryElement library = outputs[LIBRARY_ELEMENT3];
      FunctionElement entryPoint = library.entryPoint;
      expect(entryPoint, isNotNull);
      expect(entryPoint.source, sourceB);
    }
  }

  test_perform_hideCombinator() {
    Source sourceA = _newSource('/a.dart', '''
library lib_a;
export 'b.dart' hide B1;
class A1 {}
class A2 {}
class _A3 {}
''');
    _newSource('/b.dart', '''
library lib_b;
class B1 {}
class B2 {}
class B3 {}
class _B4 {}
''');
    _newSource('/c.dart', '''
library lib_c;
class C1 {}
class C2 {}
class C3 {}
''');
    _computeResult(sourceA, EXPORT_NAMESPACE);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      Namespace namespace = outputs[EXPORT_NAMESPACE];
      Iterable<String> definedKeys = namespace.definedNames.keys;
      expect(definedKeys, unorderedEquals(['A1', 'A2', 'B2', 'B3']));
    }
  }

  test_perform_showCombinator() {
    Source sourceA = _newSource('/a.dart', '''
library lib_a;
export 'b.dart' show B1;
class A1 {}
class A2 {}
class _A3 {}
''');
    _newSource('/b.dart', '''
library lib_b;
class B1 {}
class B2 {}
class _B3 {}
''');
    _computeResult(sourceA, EXPORT_NAMESPACE);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      Namespace namespace = outputs[EXPORT_NAMESPACE];
      Iterable<String> definedKeys = namespace.definedNames.keys;
      expect(definedKeys, unorderedEquals(['A1', 'A2', 'B1']));
    }
  }

  test_perform_showCombinator_setter() {
    Source sourceA = _newSource('/a.dart', '''
library lib_a;
export 'b.dart' show topLevelB;
class A {}
''');
    _newSource('/b.dart', '''
library lib_b;
int topLevelB;
''');
    _computeResult(sourceA, EXPORT_NAMESPACE);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      Namespace namespace = outputs[EXPORT_NAMESPACE];
      Iterable<String> definedKeys = namespace.definedNames.keys;
      expect(definedKeys, unorderedEquals(['A', 'topLevelB', 'topLevelB=']));
    }
  }
}

@reflectiveTest
class BuildExportSourceClosureTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source sourceA = _newSource('/a.dart', '''
library lib_a;
export 'b.dart';
''');
    Source sourceB = _newSource('/b.dart', '''
library lib_b;
export 'b.dart';
''');
    Source sourceC = _newSource('/c.dart', '''
library lib_c;
export 'a.dart';
''');
    Source sourceD = _newSource('/d.dart', '''
library lib_d;
''');
    // a.dart
    {
      _computeResult(sourceA, EXPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildExportSourceClosureTask>());
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceA, sourceB]));
    }
    // c.dart
    {
      _computeResult(sourceC, EXPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildExportSourceClosureTask>());
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // d.dart
    {
      _computeResult(sourceD, EXPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildExportSourceClosureTask>());
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceD]));
    }
  }
}

@reflectiveTest
class BuildLibraryElementTaskTest extends _AbstractDartTaskTest {
  Source librarySource;
  CompilationUnit libraryUnit;
  CompilationUnitElement libraryUnitElement;
  List<CompilationUnit> partUnits;

  LibraryElement libraryElement;

  test_constructor() {
    BuildLibraryElementTask task =
        new BuildLibraryElementTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_createTask() {
    BuildLibraryElementTask task =
        BuildLibraryElementTask.createTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_description() {
    BuildLibraryElementTask task =
        new BuildLibraryElementTask(null, emptySource);
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
    expect(outputs, hasLength(5));
    // simple outputs
    expect(outputs[BUILD_LIBRARY_ERRORS], isEmpty);
    expect(outputs[RESOLVED_UNIT2], same(libraryUnit));
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
    CompilationUnitElement firstPart;
    CompilationUnitElement secondPart;
    if (partUnits[0].element.uri == 'part1.dart') {
      firstPart = partUnits[0].element;
      secondPart = partUnits[1].element;
    } else {
      firstPart = partUnits[1].element;
      secondPart = partUnits[0].element;
    }
    expect(firstPart.uri, 'part1.dart');
    expect(firstPart.uriOffset, 18);
    expect(firstPart.uriEnd, 30);
    expect(
        (libraryUnit.directives[1] as PartDirective).element, same(firstPart));

    expect(secondPart.uri, 'part2.dart');
    expect(secondPart.uriOffset, 37);
    expect(secondPart.uriEnd, 49);
    expect(
        (libraryUnit.directives[2] as PartDirective).element, same(secondPart));
  }

  test_perform_error_missingLibraryDirectiveWithPart_hasCommon() {
    _performBuildTask({
      '/lib.dart': '''
part 'partA.dart';
part 'partB.dart';
''',
      '/partA.dart': '''
part of my_lib;
        ''',
      '/partB.dart': '''
part of my_lib;
'''
    });
    _assertErrorsWithCodes(
        [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
    AnalysisError error = errorListener.errors[0];
    expect(error.getProperty(ErrorProperty.PARTS_LIBRARY_NAME), 'my_lib');
  }

  test_perform_error_missingLibraryDirectiveWithPart_noCommon() {
    _performBuildTask({
      '/lib.dart': '''
part 'partA.dart';
part 'partB.dart';
''',
      '/partA.dart': '''
part of libA;
        ''',
      '/partB.dart': '''
part of libB;
'''
    });
    _assertErrorsWithCodes(
        [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
    AnalysisError error = errorListener.errors[0];
    expect(error.getProperty(ErrorProperty.PARTS_LIBRARY_NAME), isNull);
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
    _fillErrorListener(BUILD_LIBRARY_ERRORS);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  void _performBuildTask(Map<String, String> sourceMap) {
    List<Source> sources = _newSources(sourceMap);
    _computeResult(sources.first, RESOLVED_UNIT2);
    expect(task, new isInstanceOf<BuildLibraryElementTask>());
    libraryUnit = outputs[RESOLVED_UNIT2];
    libraryUnitElement = libraryUnit.element;
    librarySource = libraryUnitElement.source;
    libraryElement = outputs[LIBRARY_ELEMENT1];
    partUnits =
        task.inputs[BuildLibraryElementTask.PARTS_RESOLVED_UNIT1_INPUT_NAME];
  }
}

@reflectiveTest
class BuildPublicNamespaceTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    Map<String, TaskInput> inputs =
        BuildPublicNamespaceTask.buildInputs(emptySource);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals(
        [BuildPublicNamespaceTask.BUILT_LIBRARY_ELEMENT_INPUT_NAME]));
  }

  test_constructor() {
    BuildPublicNamespaceTask task =
        new BuildPublicNamespaceTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_createTask() {
    BuildPublicNamespaceTask task =
        BuildPublicNamespaceTask.createTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_description() {
    BuildPublicNamespaceTask task =
        new BuildPublicNamespaceTask(null, emptySource);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = BuildPublicNamespaceTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    List<Source> sources = _newSources({
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
    _computeResult(sources.first, PUBLIC_NAMESPACE);
    expect(task, new isInstanceOf<BuildPublicNamespaceTask>());
    // validate
    Namespace namespace = outputs[PUBLIC_NAMESPACE];
    expect(namespace.definedNames.keys, unorderedEquals(['a', 'd']));
  }
}

@reflectiveTest
class BuildTypeProviderTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    _computeResult(AnalysisContextTarget.request, TYPE_PROVIDER);
    expect(task, new isInstanceOf<BuildTypeProviderTask>());
    // validate
    TypeProvider typeProvider = outputs[TYPE_PROVIDER];
    expect(typeProvider, isNotNull);
    expect(typeProvider.boolType, isNotNull);
    expect(typeProvider.intType, isNotNull);
    expect(typeProvider.futureType, isNotNull);
  }
}

@reflectiveTest
class ParseDartTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    Map<String, TaskInput> inputs = ParseDartTask.buildInputs(emptySource);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals([
      ParseDartTask.LINE_INFO_INPUT_NAME,
      ParseDartTask.TOKEN_STREAM_INPUT_NAME
    ]));
  }

  test_constructor() {
    ParseDartTask task = new ParseDartTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_createTask() {
    ParseDartTask task = ParseDartTask.createTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_description() {
    ParseDartTask task = new ParseDartTask(null, emptySource);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ParseDartTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform() {
    _performParseTask(r'''
part of lib;
class B {}''');
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.PART);
  }

  test_perform_invalidDirectives() {
    _performParseTask(r'''
library lib;
import '/does/not/exist.dart';
import '://invaliduri.dart';
export '${a}lib3.dart';
part 'part.dart';
class A {}''');
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(2));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  test_perform_library() {
    _performParseTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');
    expect(outputs, hasLength(6));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(1));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(1));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  void _performParseTask(String content) {
    AnalysisTarget target = _newSource('/test.dart', content);
    _computeResult(target, PARSED_UNIT);
    expect(task, new isInstanceOf<ParseDartTask>());
  }

  static void _assertHasCore(List<Source> sources, int lenght) {
    expect(sources, hasLength(lenght));
    expect(sources, contains(predicate((Source s) {
      return s.fullName.endsWith('core.dart');
    })));
  }
}

@reflectiveTest
class ScanDartTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    Map<String, TaskInput> inputs = ScanDartTask.buildInputs(emptySource);
    expect(inputs, isNotNull);
    expect(inputs.keys, unorderedEquals([ScanDartTask.CONTENT_INPUT_NAME]));
  }

  test_constructor() {
    ScanDartTask task = new ScanDartTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_createTask() {
    ScanDartTask task = ScanDartTask.createTask(context, emptySource);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, emptySource);
  }

  test_description() {
    ScanDartTask task = new ScanDartTask(null, emptySource);
    expect(task.description, isNotNull);
  }

  test_descriptor() {
    TaskDescriptor descriptor = ScanDartTask.DESCRIPTOR;
    expect(descriptor, isNotNull);
  }

  test_perform_errors() {
    _performScanTask('import "');
    expect(outputs, hasLength(3));
    expect(outputs[LINE_INFO], isNotNull);
    expect(outputs[SCAN_ERRORS], hasLength(1));
    expect(outputs[TOKEN_STREAM], isNotNull);
  }

  test_perform_noErrors() {
    _performScanTask('class A {}');
    expect(outputs, hasLength(3));
    expect(outputs[LINE_INFO], isNotNull);
    expect(outputs[SCAN_ERRORS], hasLength(0));
    expect(outputs[TOKEN_STREAM], isNotNull);
  }

  void _performScanTask(String content) {
    AnalysisTarget target = _newSource('/test.dart', content);
    _computeResult(target, TOKEN_STREAM);
    expect(task, new isInstanceOf<ScanDartTask>());
  }
}

class _AbstractDartTaskTest extends EngineTestCase {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  Source emptySource;

  DartSdk sdk = new MockSdk();
  _MockContext context = new _MockContext();
  Map<AnalysisTarget, CacheEntry> entryMap = <AnalysisTarget, CacheEntry>{};

  TaskManager taskManager = new TaskManager();
  AnalysisDriver analysisDriver;

  AnalysisTask task;
  Map<ResultDescriptor<dynamic>, dynamic> outputs;
  GatheringErrorListener errorListener = new GatheringErrorListener();

  CacheEntry getCacheEntry(AnalysisTarget target) {
    return entryMap.putIfAbsent(target, () => new CacheEntry());
  }

  void setUp() {
    emptySource = _newSource('/test.dart');
    // prepare AnalysisContext
    context.sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new ResourceUriResolver(resourceProvider)
    ]);
    // prepare TaskManager
    taskManager.addTaskDescriptor(GetContentTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(ScanDartTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(ParseDartTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildCompilationUnitElementTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildLibraryElementTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildPublicNamespaceTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildDirectiveElementsTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildExportSourceClosureTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildExportNamespaceTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildTypeProviderTask.DESCRIPTOR);
    taskManager.addTaskDescriptor(BuildEnumMemberElementsTask.DESCRIPTOR);
    // prepare AnalysisDriver
    analysisDriver = new AnalysisDriver(taskManager, context);
  }

  void _computeResult(AnalysisTarget target, ResultDescriptor result) {
    task = analysisDriver.computeResult(target, result);
    expect(task.caughtException, isNull);
    outputs = task.outputs;
  }

  /**
   * Fill [errorListener] with [result] errors in the current [task].
   */
  void _fillErrorListener(ResultDescriptor<List<AnalysisError>> result) {
    List<AnalysisError> errors = task.outputs[result];
    expect(errors, isNotNull, reason: result.name);
    errorListener = new GatheringErrorListener();
    errorListener.addAll(errors);
  }

  Source _newSource(String path, [String content = '']) {
    File file = resourceProvider.newFile(path, content);
    return file.createSource();
  }

  List<Source> _newSources(Map<String, String> sourceMap) {
    List<Source> sources = <Source>[];
    sourceMap.forEach((String path, String content) {
      File file = resourceProvider.newFile(path, content);
      Source source = file.createSource();
      sources.add(source);
    });
    return sources;
  }
}

class _MockContext extends TypedMock implements ExtendedAnalysisContext {
  AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
  SourceFactory sourceFactory;
  TypeProvider typeProvider;

  Map<AnalysisTarget, CacheEntry> entryMap = <AnalysisTarget, CacheEntry>{};

  String get name => '_MockContext';

  bool exists(Source source) => source.exists();

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    return entryMap.putIfAbsent(target, () => new CacheEntry());
  }

  TimestampedData<String> getContents(Source source) => source.contents;

  noSuchMethod(Invocation invocation) {
    print('noSuchMethod: ${invocation.memberName}');
    return super.noSuchMethod(invocation);
  }
}
