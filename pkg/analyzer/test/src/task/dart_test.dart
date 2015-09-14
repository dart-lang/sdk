// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.dart_test;

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptionsImpl, CacheState;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(BuildCompilationUnitElementTaskTest);
  runReflectiveTests(BuildDirectiveElementsTaskTest);
  runReflectiveTests(BuildEnumMemberElementsTaskTest);
  runReflectiveTests(BuildExportNamespaceTaskTest);
  runReflectiveTests(BuildLibraryElementTaskTest);
  runReflectiveTests(BuildPublicNamespaceTaskTest);
  runReflectiveTests(BuildSourceExportClosureTaskTest);
  runReflectiveTests(BuildSourceImportExportClosureTaskTest);
  runReflectiveTests(BuildTypeProviderTaskTest);
  runReflectiveTests(ComputeConstantDependenciesTaskTest);
  runReflectiveTests(ComputeConstantValueTaskTest);
  runReflectiveTests(ComputeInferableStaticVariableDependenciesTaskTest);
  runReflectiveTests(ContainingLibrariesTaskTest);
  runReflectiveTests(DartErrorsTaskTest);
  runReflectiveTests(EvaluateUnitConstantsTaskTest);
  runReflectiveTests(GatherUsedImportedElementsTaskTest);
  runReflectiveTests(GatherUsedLocalElementsTaskTest);
  runReflectiveTests(GenerateHintsTaskTest);
  runReflectiveTests(InferInstanceMembersInUnitTaskTest);
  runReflectiveTests(InferStaticVariableTypesInUnitTaskTest);
  runReflectiveTests(InferStaticVariableTypeTaskTest);
  runReflectiveTests(LibraryErrorsReadyTaskTest);
  runReflectiveTests(LibraryUnitErrorsTaskTest);
  runReflectiveTests(ParseDartTaskTest);
  runReflectiveTests(PartiallyResolveUnitReferencesTaskTest);
  runReflectiveTests(ResolveFunctionBodiesInUnitTaskTest);
  runReflectiveTests(ResolveLibraryTypeNamesTaskTest);
//  runReflectiveTests(ResolveUnitReferencesTaskTest);
  runReflectiveTests(ResolveUnitTypeNamesTaskTest);
  runReflectiveTests(ResolveVariableReferencesTaskTest);
  runReflectiveTests(ScanDartTaskTest);
  runReflectiveTests(VerifyUnitTaskTest);
}

isInstanceOf isBuildCompilationUnitElementTask =
    new isInstanceOf<BuildCompilationUnitElementTask>();
isInstanceOf isBuildDirectiveElementsTask =
    new isInstanceOf<BuildDirectiveElementsTask>();
isInstanceOf isBuildEnumMemberElementsTask =
    new isInstanceOf<BuildEnumMemberElementsTask>();
isInstanceOf isBuildExportNamespaceTask =
    new isInstanceOf<BuildExportNamespaceTask>();
isInstanceOf isBuildLibraryElementTask =
    new isInstanceOf<BuildLibraryElementTask>();
isInstanceOf isBuildPublicNamespaceTask =
    new isInstanceOf<BuildPublicNamespaceTask>();
isInstanceOf isBuildSourceExportClosureTask =
    new isInstanceOf<BuildSourceExportClosureTask>();
isInstanceOf isBuildSourceImportExportClosureTask =
    new isInstanceOf<BuildSourceImportExportClosureTask>();
isInstanceOf isBuildTypeProviderTask =
    new isInstanceOf<BuildTypeProviderTask>();
isInstanceOf isComputeConstantDependenciesTask =
    new isInstanceOf<ComputeConstantDependenciesTask>();
isInstanceOf isComputeConstantValueTask =
    new isInstanceOf<ComputeConstantValueTask>();
isInstanceOf isComputeInferableStaticVariableDependenciesTask =
    new isInstanceOf<ComputeInferableStaticVariableDependenciesTask>();
isInstanceOf isContainingLibrariesTask =
    new isInstanceOf<ContainingLibrariesTask>();
isInstanceOf isDartErrorsTask = new isInstanceOf<DartErrorsTask>();
isInstanceOf isEvaluateUnitConstantsTask =
    new isInstanceOf<EvaluateUnitConstantsTask>();
isInstanceOf isGatherUsedImportedElementsTask =
    new isInstanceOf<GatherUsedImportedElementsTask>();
isInstanceOf isGatherUsedLocalElementsTask =
    new isInstanceOf<GatherUsedLocalElementsTask>();
isInstanceOf isGenerateHintsTask = new isInstanceOf<GenerateHintsTask>();
isInstanceOf isInferInstanceMembersInUnitTask =
    new isInstanceOf<InferInstanceMembersInUnitTask>();
isInstanceOf isInferStaticVariableTypesInUnitTask =
    new isInstanceOf<InferStaticVariableTypesInUnitTask>();
isInstanceOf isInferStaticVariableTypeTask =
    new isInstanceOf<InferStaticVariableTypeTask>();
isInstanceOf isLibraryErrorsReadyTask =
    new isInstanceOf<LibraryErrorsReadyTask>();
isInstanceOf isLibraryUnitErrorsTask =
    new isInstanceOf<LibraryUnitErrorsTask>();
isInstanceOf isParseDartTask = new isInstanceOf<ParseDartTask>();
isInstanceOf isPartiallyResolveUnitReferencesTask =
    new isInstanceOf<PartiallyResolveUnitReferencesTask>();
isInstanceOf isResolveFunctionBodiesInUnitTask =
    new isInstanceOf<ResolveFunctionBodiesInUnitTask>();
isInstanceOf isResolveLibraryTypeNamesTask =
    new isInstanceOf<ResolveLibraryTypeNamesTask>();
isInstanceOf isResolveUnitTypeNamesTask =
    new isInstanceOf<ResolveUnitTypeNamesTask>();
isInstanceOf isResolveVariableReferencesTask =
    new isInstanceOf<ResolveVariableReferencesTask>();
isInstanceOf isScanDartTask = new isInstanceOf<ScanDartTask>();
isInstanceOf isVerifyUnitTask = new isInstanceOf<VerifyUnitTask>();

@reflectiveTest
class BuildCompilationUnitElementTaskTest extends _AbstractDartTaskTest {
  Source source;
  LibrarySpecificUnit target;

  test_perform_find_constants() {
    _performBuildTask('''
const x = 1;
class C {
  static const y = 1;
  const C([p = 1]);
}
@x
f() {
  const z = 1;
}
''');
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    CompilationUnitElement unitElement = outputs[COMPILATION_UNIT_ELEMENT];
    Annotation annotation = unit.declarations
        .firstWhere((m) => m is FunctionDeclaration)
        .metadata[0];
    List<ConstantEvaluationTarget> expectedConstants = [
      unitElement.accessors.firstWhere((e) => e.isGetter).variable,
      unitElement.types[0].fields[0],
      unitElement.functions[0].localVariables[0],
      unitElement.types[0].constructors[0],
      new ConstantEvaluationTarget_Annotation(
          context, source, source, annotation),
      unitElement.types[0].constructors[0].parameters[0]
    ];
    expect(
        outputs[COMPILATION_UNIT_CONSTANTS].toSet(), expectedConstants.toSet());
  }

  test_perform_library() {
    _performBuildTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
final x = '';
class A {
  static final y = 0;
}
class B = Object with A;
''');
    expect(outputs, hasLength(3));
    expect(outputs[COMPILATION_UNIT_CONSTANTS], isNotNull);
    expect(outputs[COMPILATION_UNIT_ELEMENT], isNotNull);
    expect(outputs[RESOLVED_UNIT1], isNotNull);
  }

  test_perform_reuseElement() {
    _performBuildTask(r'''
library lib;
class A {}
class B = Object with A;
''');
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    CompilationUnitElement unitElement = outputs[COMPILATION_UNIT_ELEMENT];
    expect(unit, isNotNull);
    expect(unitElement, isNotNull);
    // invalidate RESOLVED_UNIT1
    CacheEntry cacheEntry = analysisCache.get(target);
    cacheEntry.setState(RESOLVED_UNIT1, CacheState.INVALID);
    // compute again
    computeResult(target, RESOLVED_UNIT1,
        matcher: isBuildCompilationUnitElementTask);
    expect(outputs[COMPILATION_UNIT_ELEMENT], same(unitElement));
    expect(outputs[RESOLVED_UNIT1], isNot(same(unit)));
  }

  void _performBuildTask(String content) {
    source = newSource('/test.dart', content);
    target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT1,
        matcher: isBuildCompilationUnitElementTask);
  }
}

@reflectiveTest
class BuildDirectiveElementsTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    List<Source> sources = newSources({
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
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    LibraryElement libraryElementA = outputs[LIBRARY_ELEMENT2];
    LibraryElement libraryElementB = _getImportLibraryInput(sourceB);
    LibraryElement libraryElementC = _getExportLibraryInput(sourceC);
    // no errors
    _assertErrorsWithCodes([]);
    // validate directives
    CompilationUnit libraryUnitA = context
        .getCacheEntry(new LibrarySpecificUnit(sourceA, sourceA))
        .getValue(RESOLVED_UNIT1);
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
      expect(imports[1].isSynthetic, isTrue);
    }
  }

  test_perform_combinators() {
    List<Source> sources = newSources({
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
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    CompilationUnit libraryUnitA = context
        .getCacheEntry(new LibrarySpecificUnit(sourceA, sourceA))
        .getValue(RESOLVED_UNIT1);
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

  test_perform_dartCoreContext() {
    List<Source> sources = newSources({'/libA.dart': ''});
    Source source = sources[0];
    // perform task
    computeResult(source, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    LibraryElement libraryElement = outputs[LIBRARY_ELEMENT2];
    // verify that dart:core has SDK context
    {
      LibraryElement coreLibrary = libraryElement.importedLibraries[0];
      DartSdk dartSdk = context.sourceFactory.dartSdk;
      expect(coreLibrary.context, same(dartSdk.context));
    }
  }

  test_perform_error_exportOfNonLibrary() {
    List<Source> sources = newSources({
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
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // validate errors
    _assertErrorsWithCodes([CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
  }

  test_perform_error_importOfNonLibrary() {
    List<Source> sources = newSources({
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
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // validate errors
    _assertErrorsWithCodes([CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
  }

  test_perform_explicitDartCoreImport() {
    List<Source> sources = newSources({
      '/lib.dart': '''
library lib;
import 'dart:core' show List;
'''
    });
    Source source = sources[0];
    // perform task
    computeResult(source, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    LibraryElement libraryElement = outputs[LIBRARY_ELEMENT2];
    // has an explicit "dart:core" import
    {
      List<ImportElement> imports = libraryElement.imports;
      expect(imports, hasLength(1));
      expect(imports[0].importedLibrary.isDartCore, isTrue);
      expect(imports[0].isSynthetic, isFalse);
    }
  }

  test_perform_hasExtUri() {
    List<Source> sources = newSources({
      '/lib.dart': '''
import 'dart-ext:doesNotExist.dart';
'''
    });
    Source source = sources[0];
    // perform task
    computeResult(source, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    LibraryElement libraryElement = outputs[LIBRARY_ELEMENT2];
    expect(libraryElement.hasExtUri, isTrue);
  }

  test_perform_importPrefix() {
    List<Source> sources = newSources({
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
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    CompilationUnit libraryUnitA = context
        .getCacheEntry(new LibrarySpecificUnit(sourceA, sourceA))
        .getValue(RESOLVED_UNIT1);
    // validate directives
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

  void _assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    _fillErrorListener(BUILD_DIRECTIVES_ERRORS);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  _getExportLibraryInput(Source source) {
    var key = BuildDirectiveElementsTask.EXPORTS_LIBRARY_ELEMENT_INPUT_NAME;
    return task.inputs[key][source];
  }

  _getImportLibraryInput(Source source) {
    var key = BuildDirectiveElementsTask.IMPORTS_LIBRARY_ELEMENT_INPUT_NAME;
    return task.inputs[key][source];
  }
}

@reflectiveTest
class BuildEnumMemberElementsTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource(
        '/test.dart',
        '''
enum MyEnum {
  A, B
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT2,
        matcher: isBuildEnumMemberElementsTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT2];
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
  test_perform_entryPoint() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
export 'b.dart';
''');
    Source sourceB = newSource(
        '/b.dart',
        '''
library lib_b;
main() {}
''');
    computeResult(sourceA, LIBRARY_ELEMENT4,
        matcher: isBuildExportNamespaceTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT4];
    FunctionElement entryPoint = library.entryPoint;
    expect(entryPoint, isNotNull);
    expect(entryPoint.source, sourceB);
  }

  test_perform_hideCombinator() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
export 'b.dart' hide B1;
class A1 {}
class A2 {}
class _A3 {}
''');
    newSource(
        '/b.dart',
        '''
library lib_b;
class B1 {}
class B2 {}
class B3 {}
class _B4 {}
''');
    newSource(
        '/c.dart',
        '''
library lib_c;
class C1 {}
class C2 {}
class C3 {}
''');
    computeResult(sourceA, LIBRARY_ELEMENT4,
        matcher: isBuildExportNamespaceTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT4];
    Namespace namespace = library.exportNamespace;
    Iterable<String> definedKeys = namespace.definedNames.keys;
    expect(definedKeys, unorderedEquals(['A1', 'A2', 'B2', 'B3']));
  }

  test_perform_showCombinator() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
export 'b.dart' show B1;
class A1 {}
class A2 {}
class _A3 {}
''');
    newSource(
        '/b.dart',
        '''
library lib_b;
class B1 {}
class B2 {}
class _B3 {}
''');
    computeResult(sourceA, LIBRARY_ELEMENT4,
        matcher: isBuildExportNamespaceTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT4];
    Namespace namespace = library.exportNamespace;
    Iterable<String> definedKeys = namespace.definedNames.keys;
    expect(definedKeys, unorderedEquals(['A1', 'A2', 'B1']));
  }

  test_perform_showCombinator_setter() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
export 'b.dart' show topLevelB;
class A {}
''');
    newSource(
        '/b.dart',
        '''
library lib_b;
int topLevelB;
''');
    computeResult(sourceA, LIBRARY_ELEMENT4,
        matcher: isBuildExportNamespaceTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT4];
    Namespace namespace = library.exportNamespace;
    Iterable<String> definedKeys = namespace.definedNames.keys;
    expect(definedKeys, unorderedEquals(['A', 'topLevelB', 'topLevelB=']));
  }
}

@reflectiveTest
class BuildLibraryElementTaskTest extends _AbstractDartTaskTest {
  Source librarySource;
  CompilationUnit libraryUnit;
  CompilationUnitElement libraryUnitElement;
  List<CompilationUnit> partUnits;

  LibraryElement libraryElement;

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
    expect(outputs, hasLength(3));
    // simple outputs
    expect(outputs[BUILD_LIBRARY_ERRORS], isEmpty);
    expect(outputs[IS_LAUNCHABLE], isFalse);
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

  test_perform_error_partDoesNotExist() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part.dart';
'''
    });
    // we already report URI_DOES_NOT_EXIST, no need to report other errors
    _assertErrorsWithCodes([]);
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

  test_perform_invalidUri_part() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part '//////////';
'''
    });
    expect(libraryElement.parts, isEmpty);
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

  test_perform_noSuchFilePart() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'no-such-file.dart';
'''
    });
    expect(libraryElement.parts, hasLength(1));
    CompilationUnitElement part = libraryElement.parts[0];
    expect(part, isNotNull);
    expect(part.source, isNotNull);
    expect(part.library, same(libraryElement));
    expect(context.exists(part.source), isFalse);
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
    List<Source> sources = newSources(sourceMap);
    Source libSource = sources.first;
    computeResult(libSource, LIBRARY_ELEMENT1,
        matcher: isBuildLibraryElementTask);
    libraryUnit = context
        .getCacheEntry(new LibrarySpecificUnit(libSource, libSource))
        .getValue(RESOLVED_UNIT1);
    libraryUnitElement = libraryUnit.element;
    librarySource = libraryUnitElement.source;
    libraryElement = outputs[LIBRARY_ELEMENT1];
    partUnits = task.inputs[BuildLibraryElementTask.PARTS_UNIT_INPUT];
  }
}

@reflectiveTest
class BuildPublicNamespaceTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    List<Source> sources = newSources({
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
    computeResult(sources.first, LIBRARY_ELEMENT3,
        matcher: isBuildPublicNamespaceTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT3];
    Namespace namespace = library.publicNamespace;
    expect(namespace.definedNames.keys, unorderedEquals(['a', 'd']));
  }
}

@reflectiveTest
class BuildSourceExportClosureTaskTest extends _AbstractDartTaskTest {
  test_perform_exportClosure() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
export 'b.dart';
''');
    Source sourceB = newSource(
        '/b.dart',
        '''
library lib_b;
export 'c.dart';
''');
    Source sourceC = newSource(
        '/c.dart',
        '''
library lib_c;
export 'a.dart';
''');
    Source sourceD = newSource(
        '/d.dart',
        '''
library lib_d;
''');
    // a.dart
    {
      computeResult(sourceA, EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceExportClosureTask);
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // c.dart
    {
      computeResult(sourceC, EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceExportClosureTask);
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // d.dart
    {
      computeResult(sourceD, EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceExportClosureTask);
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceD]));
    }
  }
}

@reflectiveTest
class BuildSourceImportExportClosureTaskTest extends _AbstractDartTaskTest {
  test_perform_importExportClosure() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
''');
    Source sourceB = newSource(
        '/b.dart',
        '''
library lib_b;
export 'a.dart';
''');
    Source sourceC = newSource(
        '/c.dart',
        '''
library lib_c;
import 'b.dart';
''');
    Source coreSource = context.sourceFactory.resolveUri(null, 'dart:core');
    // c.dart
    {
      computeResult(sourceC, IMPORT_EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceImportExportClosureTask);
      List<Source> closure = outputs[IMPORT_EXPORT_SOURCE_CLOSURE];
      expect(closure, contains(sourceA));
      expect(closure, contains(sourceB));
      expect(closure, contains(sourceC));
      expect(closure, contains(coreSource));
    }
    // b.dart
    {
      computeResult(sourceB, IMPORT_EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceImportExportClosureTask);
      List<Source> closure = outputs[IMPORT_EXPORT_SOURCE_CLOSURE];
      expect(closure, contains(sourceA));
      expect(closure, contains(sourceB));
      expect(closure, contains(coreSource));
    }
  }

  test_perform_isClient_false() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
import 'b.dart';
''');
    newSource(
        '/b.dart',
        '''
library lib_b;
''');
    computeResult(sourceA, IS_CLIENT,
        matcher: isBuildSourceImportExportClosureTask);
    expect(outputs[IS_CLIENT], isFalse);
  }

  test_perform_isClient_true_export_indirect() {
    newSource(
        '/exports_html.dart',
        '''
library lib_exports_html;
export 'dart:html';
''');
    Source source = newSource(
        '/test.dart',
        '''
import 'exports_html.dart';
''');
    computeResult(source, IS_CLIENT,
        matcher: isBuildSourceImportExportClosureTask);
    expect(outputs[IS_CLIENT], isTrue);
  }

  test_perform_isClient_true_import_direct() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
import 'dart:html';
''');
    computeResult(sourceA, IS_CLIENT,
        matcher: isBuildSourceImportExportClosureTask);
    expect(outputs[IS_CLIENT], isTrue);
  }

  test_perform_isClient_true_import_indirect() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library lib_a;
import 'b.dart';
''');
    newSource(
        '/b.dart',
        '''
library lib_b;
import 'dart:html';
''');
    computeResult(sourceA, IS_CLIENT,
        matcher: isBuildSourceImportExportClosureTask);
    expect(outputs[IS_CLIENT], isTrue);
  }
}

@reflectiveTest
class BuildTypeProviderTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    computeResult(AnalysisContextTarget.request, TYPE_PROVIDER,
        matcher: isBuildTypeProviderTask);
    // validate
    TypeProvider typeProvider = outputs[TYPE_PROVIDER];
    expect(typeProvider, isNotNull);
    expect(typeProvider.boolType, isNotNull);
    expect(typeProvider.intType, isNotNull);
    expect(typeProvider.futureType, isNotNull);
  }
}

@reflectiveTest
class ComputeConstantDependenciesTaskTest extends _AbstractDartTaskTest {
  Annotation findClassAnnotation(CompilationUnit unit, String className) {
    for (CompilationUnitMember member in unit.declarations) {
      if (member is ClassDeclaration && member.name.name == className) {
        expect(member.metadata, hasLength(1));
        return member.metadata[0];
      }
    }
    fail('Annotation not found');
    return null;
  }

  test_annotation_with_args() {
    Source source = newSource(
        '/test.dart',
        '''
const x = 1;
@D(x) class C {}
class D { const D(value); }
''');
    // First compute the resolved unit for the source.
    LibrarySpecificUnit librarySpecificUnit =
        new LibrarySpecificUnit(source, source);
    computeResult(librarySpecificUnit, RESOLVED_UNIT1);
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    // Find the elements for x and D's constructor, and the annotation on C.
    List<PropertyAccessorElement> accessors = unit.element.accessors;
    Element x = accessors
        .firstWhere((PropertyAccessorElement accessor) =>
            accessor.isGetter && accessor.name == 'x')
        .variable;
    List<ClassElement> types = unit.element.types;
    Element constructorForD =
        types.firstWhere((ClassElement cls) => cls.name == 'D').constructors[0];
    Annotation annotation = findClassAnnotation(unit, 'C');
    // Now compute the dependencies for the annotation, and check that it is
    // the set [x, constructorForD].
    // TODO(paulberry): test librarySource != source
    computeResult(
        new ConstantEvaluationTarget_Annotation(
            context, source, source, annotation),
        CONSTANT_DEPENDENCIES,
        matcher: isComputeConstantDependenciesTask);
    expect(
        outputs[CONSTANT_DEPENDENCIES].toSet(), [x, constructorForD].toSet());
  }

  test_annotation_without_args() {
    Source source = newSource(
        '/test.dart',
        '''
const x = 1;
@x class C {}
''');
    // First compute the resolved unit for the source.
    LibrarySpecificUnit librarySpecificUnit =
        new LibrarySpecificUnit(source, source);
    computeResult(librarySpecificUnit, RESOLVED_UNIT1);
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    // Find the element for x and the annotation on C.
    List<PropertyAccessorElement> accessors = unit.element.accessors;
    Element x = accessors
        .firstWhere((PropertyAccessorElement accessor) =>
            accessor.isGetter && accessor.name == 'x')
        .variable;
    Annotation annotation = findClassAnnotation(unit, 'C');
    // Now compute the dependencies for the annotation, and check that it is
    // the list [x].
    computeResult(
        new ConstantEvaluationTarget_Annotation(
            context, source, source, annotation),
        CONSTANT_DEPENDENCIES,
        matcher: isComputeConstantDependenciesTask);
    expect(outputs[CONSTANT_DEPENDENCIES], [x]);
  }

  test_enumConstant() {
    Source source = newSource(
        '/test.dart',
        '''
enum E {A, B, C}
''');
    // First compute the resolved unit for the source.
    LibrarySpecificUnit librarySpecificUnit =
        new LibrarySpecificUnit(source, source);
    computeResult(librarySpecificUnit, RESOLVED_UNIT2);
    CompilationUnit unit = outputs[RESOLVED_UNIT2];
    // Find the element for 'A'
    EnumDeclaration enumDeclaration = unit.declarations[0];
    EnumConstantDeclaration constantDeclaration = enumDeclaration.constants[0];
    FieldElement constantElement = constantDeclaration.element;
    // Now compute the dependencies for the constant and check that there are
    // none.
    computeResult(constantElement, CONSTANT_DEPENDENCIES,
        matcher: isComputeConstantDependenciesTask);
    expect(outputs[CONSTANT_DEPENDENCIES], isEmpty);
  }

  test_perform() {
    Source source = newSource(
        '/test.dart',
        '''
const x = y;
const y = 1;
''');
    // First compute the resolved unit for the source.
    LibrarySpecificUnit librarySpecificUnit =
        new LibrarySpecificUnit(source, source);
    computeResult(librarySpecificUnit, RESOLVED_UNIT1);
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    // Find the elements for the constants x and y.
    List<PropertyAccessorElement> accessors = unit.element.accessors;
    Element x = accessors
        .firstWhere((PropertyAccessorElement accessor) =>
            accessor.isGetter && accessor.name == 'x')
        .variable;
    Element y = accessors
        .firstWhere((PropertyAccessorElement accessor) =>
            accessor.isGetter && accessor.name == 'y')
        .variable;
    // Now compute the dependencies for x, and check that it is the list [y].
    computeResult(x, CONSTANT_DEPENDENCIES,
        matcher: isComputeConstantDependenciesTask);
    expect(outputs[CONSTANT_DEPENDENCIES], [y]);
  }
}

@reflectiveTest
class ComputeConstantValueTaskTest extends _AbstractDartTaskTest {
  EvaluationResultImpl computeClassAnnotation(
      Source source, CompilationUnit unit, String className) {
    for (CompilationUnitMember member in unit.declarations) {
      if (member is ClassDeclaration && member.name.name == className) {
        expect(member.metadata, hasLength(1));
        Annotation annotation = member.metadata[0];
        ConstantEvaluationTarget_Annotation target =
            new ConstantEvaluationTarget_Annotation(
                context, source, source, annotation);
        computeResult(target, CONSTANT_VALUE,
            matcher: isComputeConstantValueTask);
        expect(outputs[CONSTANT_VALUE], same(target));
        EvaluationResultImpl evaluationResult = (annotation.elementAnnotation
            as ElementAnnotationImpl).evaluationResult;
        return evaluationResult;
      }
    }
    fail('Annotation not found');
    return null;
  }

  test_annotation_non_const_constructor() {
    // Calling a non-const constructor from an annotation that is illegal, but
    // shouldn't crash analysis.
    Source source = newSource(
        '/test.dart',
        '''
class A {
  final int i;
  A(this.i);
}

@A(5)
class C {}
''');
    // First compute the resolved unit for the source.
    CompilationUnit unit = _resolveSource(source);
    // Compute the constant value of the annotation on C.
    EvaluationResultImpl evaluationResult =
        computeClassAnnotation(source, unit, 'C');
    // And check that it has no value stored in it.
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNull);
  }

  test_annotation_with_args() {
    Source source = newSource(
        '/test.dart',
        '''
const x = 1;
@D(x) class C {}
class D {
  const D(this.value);
  final value;
}
''');
    // First compute the resolved unit for the source.
    CompilationUnit unit = _resolveSource(source);
    // Compute the constant value of the annotation on C.
    EvaluationResultImpl evaluationResult =
        computeClassAnnotation(source, unit, 'C');
    // And check that it has the expected value.
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNotNull);
    expect(evaluationResult.value.type, isNotNull);
    expect(evaluationResult.value.type.name, 'D');
    expect(evaluationResult.value.fields, contains('value'));
    expect(evaluationResult.value.fields['value'].intValue, 1);
  }

  test_annotation_without_args() {
    Source source = newSource(
        '/test.dart',
        '''
const x = 1;
@x class C {}
''');
    // First compute the resolved unit for the source.
    CompilationUnit unit = _resolveSource(source);
    // Compute the constant value of the annotation on C.
    EvaluationResultImpl evaluationResult =
        computeClassAnnotation(source, unit, 'C');
    // And check that it has the expected value.
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNotNull);
    expect(evaluationResult.value.intValue, 1);
  }

  test_circular_reference() {
    _checkCircularities(
        'x',
        ['y'],
        '''
const x = y + 1;
const y = x + 1;
''');
  }

  test_circular_reference_one_element() {
    // See dartbug.com/23490.
    _checkCircularities('x', [], 'const x = x;');
  }

  test_circular_reference_strongly_connected_component() {
    // When there is a circularity, all elements in the strongly connected
    // component should be marked as having an error.
    _checkCircularities(
        'a',
        ['b', 'c', 'd'],
        '''
const a = b;
const b = c + d;
const c = a;
const d = a;
''');
  }

  test_const_constructor_calls_implicit_super_constructor_implicitly() {
    // Note: the situation below is a compile-time error (since the synthetic
    // constructor for Base is non-const), but we need to handle it without
    // throwing an exception.
    EvaluationResultImpl evaluationResult = _computeTopLevelVariableConstValue(
        'x',
        '''
class Base {}
class Derived extends Base {
  const Derived();
}
const x = const Derived();
''');
    expect(evaluationResult, isNotNull);
  }

  test_dependency() {
    EvaluationResultImpl evaluationResult = _computeTopLevelVariableConstValue(
        'x',
        '''
const x = y + 1;
const y = 1;
''');
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNotNull);
    expect(evaluationResult.value.intValue, 2);
  }

  test_external_const_factory() {
    EvaluationResultImpl evaluationResult = _computeTopLevelVariableConstValue(
        'x',
        '''
const x = const C.foo();

class C extends B {
  external const factory C.foo();
}

class B {}
''');
    expect(evaluationResult, isNotNull);
  }

  test_simple_constant() {
    EvaluationResultImpl evaluationResult = _computeTopLevelVariableConstValue(
        'x',
        '''
const x = 1;
''');
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNotNull);
    expect(evaluationResult.value.intValue, 1);
  }

  void _checkCircularities(
      String variableName, List<String> otherVariables, String content) {
    // Evaluating the first constant should produce an error.
    CompilationUnit unit = _resolveUnit(content);
    _expectCircularityError(_evaluateConstant(unit, variableName));
    // And all the other constants involved in the strongly connected component
    // should be set to the same error state.
    for (String otherVariableName in otherVariables) {
      PropertyInducingElement otherVariableElement =
          _findVariable(unit, otherVariableName);
      _expectCircularityError((otherVariableElement
          as TopLevelVariableElementImpl).evaluationResult);
    }
  }

  EvaluationResultImpl _computeTopLevelVariableConstValue(
      String variableName, String content) {
    return _evaluateConstant(_resolveUnit(content), variableName);
  }

  EvaluationResultImpl _evaluateConstant(
      CompilationUnit unit, String variableName) {
    // Find the element for the given constant.
    PropertyInducingElement variableElement = _findVariable(unit, variableName);
    // Now compute the value of the constant.
    computeResult(variableElement, CONSTANT_VALUE,
        matcher: isComputeConstantValueTask);
    expect(outputs[CONSTANT_VALUE], same(variableElement));
    EvaluationResultImpl evaluationResult =
        (variableElement as TopLevelVariableElementImpl).evaluationResult;
    return evaluationResult;
  }

  void _expectCircularityError(EvaluationResultImpl evaluationResult) {
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNull);
    expect(evaluationResult.errors, hasLength(1));
    expect(evaluationResult.errors[0].errorCode,
        CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT);
  }

  PropertyInducingElement _findVariable(
      CompilationUnit unit, String variableName) {
    // Find the element for the given constant.
    return unit.element.topLevelVariables.firstWhere(
        (TopLevelVariableElement variable) => variable.name == variableName);
  }

  CompilationUnit _resolveSource(Source source) {
    LibrarySpecificUnit librarySpecificUnit =
        new LibrarySpecificUnit(source, source);
    computeResult(librarySpecificUnit, RESOLVED_UNIT1);
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    return unit;
  }

  CompilationUnit _resolveUnit(String content) =>
      _resolveSource(newSource('/test.dart', content));
}

@reflectiveTest
class ComputeInferableStaticVariableDependenciesTaskTest
    extends _AbstractDartTaskTest {
  test_perform() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
const a = b;
const b = 0;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    TopLevelVariableElement elementA = unit.element.topLevelVariables[0];
    TopLevelVariableElement elementB = unit.element.topLevelVariables[1];

    computeResult(elementA, INFERABLE_STATIC_VARIABLE_DEPENDENCIES,
        matcher: isComputeInferableStaticVariableDependenciesTask);
    expect(outputs, hasLength(1));
    List<VariableElement> dependencies =
        outputs[INFERABLE_STATIC_VARIABLE_DEPENDENCIES];
    expect(dependencies, unorderedEquals([elementB]));
  }
}

@reflectiveTest
class ContainingLibrariesTaskTest extends _AbstractDartTaskTest {
  test_perform_definingCompilationUnit() {
    AnalysisTarget library = newSource('/test.dart', 'library test;');
    computeResult(library, INCLUDED_PARTS);
    computeResult(library, CONTAINING_LIBRARIES,
        matcher: isContainingLibrariesTask);
    expect(outputs, hasLength(1));
    List<Source> containingLibraries = outputs[CONTAINING_LIBRARIES];
    expect(containingLibraries, unorderedEquals([library]));
  }

  test_perform_partInMultipleLibraries() {
    AnalysisTarget library1 =
        newSource('/lib1.dart', 'library test; part "part.dart";');
    AnalysisTarget library2 =
        newSource('/lib2.dart', 'library test; part "part.dart";');
    AnalysisTarget part = newSource('/part.dart', 'part of test;');
    computeResult(library1, INCLUDED_PARTS);
    computeResult(library2, INCLUDED_PARTS);
    computeResult(part, SOURCE_KIND);
    computeResult(part, CONTAINING_LIBRARIES,
        matcher: isContainingLibrariesTask);
    expect(outputs, hasLength(1));
    List<Source> containingLibraries = outputs[CONTAINING_LIBRARIES];
    expect(containingLibraries, unorderedEquals([library1, library2]));
  }

  test_perform_partInSingleLibrary() {
    AnalysisTarget library =
        newSource('/lib.dart', 'library test; part "part.dart";');
    AnalysisTarget part = newSource('/part.dart', 'part of test;');
    computeResult(library, INCLUDED_PARTS);
    computeResult(part, SOURCE_KIND);
    computeResult(part, CONTAINING_LIBRARIES,
        matcher: isContainingLibrariesTask);
    expect(outputs, hasLength(1));
    List<Source> containingLibraries = outputs[CONTAINING_LIBRARIES];
    expect(containingLibraries, unorderedEquals([library]));
  }
}

@reflectiveTest
class DartErrorsTaskTest extends _AbstractDartTaskTest {
  test_perform_definingCompilationUnit() {
    AnalysisTarget library =
        newSource('/test.dart', 'library test; import "dart:math";');
    computeResult(library, INCLUDED_PARTS);
    computeResult(library, DART_ERRORS, matcher: isDartErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = outputs[DART_ERRORS];
    expect(errors, hasLength(1));
  }

  test_perform_partInSingleLibrary() {
    AnalysisTarget library = newSource(
        '/lib.dart', 'library test; import "dart:math"; part "part.dart";');
    AnalysisTarget part =
        newSource('/part.dart', 'part of test; class A extends A {}');
    computeResult(library, INCLUDED_PARTS);
    computeResult(library, DART_ERRORS);
    computeResult(part, DART_ERRORS, matcher: isDartErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = outputs[DART_ERRORS];
    // This should contain only the errors in the part file, not the ones in the
    // library.
    expect(errors, hasLength(1));
  }
}

@reflectiveTest
class EvaluateUnitConstantsTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource(
        '/test.dart',
        '''
class C {
  const C();
}

@x
f() {}

const x = const C();
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT, matcher: isEvaluateUnitConstantsTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT];
    CompilationUnitElement unitElement = unit.element;
    expect(
        (unitElement.types[0].constructors[0] as ConstructorElementImpl)
            .isCycleFree,
        isTrue);
    expect(
        (unitElement.functions[0].metadata[0] as ElementAnnotationImpl)
            .evaluationResult,
        isNotNull);
    expect(
        (unitElement.topLevelVariables[0] as TopLevelVariableElementImpl)
            .evaluationResult,
        isNotNull);
  }
}

@reflectiveTest
class GatherUsedImportedElementsTaskTest extends _AbstractDartTaskTest {
  UsedImportedElements usedElements;
  Set<String> usedElementNames;

  test_perform() {
    newSource(
        '/a.dart',
        r'''
library lib_a;
class A {}
''');
    newSource(
        '/b.dart',
        r'''
library lib_b;
class B {}
''');
    Source source = newSource(
        '/test.dart',
        r'''
import 'a.dart';
import 'b.dart';
main() {
  new A();
}''');
    _computeUsedElements(source);
    // validate
    expect(usedElementNames, unorderedEquals(['A']));
  }

  void _computeUsedElements(Source source) {
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, USED_IMPORTED_ELEMENTS,
        matcher: isGatherUsedImportedElementsTask);
    usedElements = outputs[USED_IMPORTED_ELEMENTS];
    usedElementNames = usedElements.elements.map((e) => e.name).toSet();
  }
}

@reflectiveTest
class GatherUsedLocalElementsTaskTest extends _AbstractDartTaskTest {
  UsedLocalElements usedElements;
  Set<String> usedElementNames;

  test_perform_localVariable() {
    Source source = newSource(
        '/test.dart',
        r'''
main() {
  var v1 = 1;
  var v2 = 2;
  print(v2);
}''');
    _computeUsedElements(source);
    // validate
    expect(usedElementNames, unorderedEquals(['v2']));
  }

  test_perform_method() {
    Source source = newSource(
        '/test.dart',
        r'''
class A {
  _m1() {}
  _m2() {}
}

main(A a, p) {
  a._m2();
  p._m3();
}
''');
    _computeUsedElements(source);
    // validate
    expect(usedElementNames, unorderedEquals(['A', 'a', 'p', '_m2']));
    expect(usedElements.members, unorderedEquals(['_m2', '_m3']));
  }

  void _computeUsedElements(Source source) {
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, USED_LOCAL_ELEMENTS,
        matcher: isGatherUsedLocalElementsTask);
    usedElements = outputs[USED_LOCAL_ELEMENTS];
    usedElementNames = usedElements.elements.map((e) => e.name).toSet();
  }
}

@reflectiveTest
class GenerateHintsTaskTest extends _AbstractDartTaskTest {
  test_perform_bestPractices_missingReturn() {
    Source source = newSource(
        '/test.dart',
        '''
int main() {
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.MISSING_RETURN]);
  }

  test_perform_dart2js() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    prepareAnalysisContext(options);
    Source source = newSource(
        '/test.dart',
        '''
main(p) {
  if (p is double) {
    print('double');
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.IS_DOUBLE]);
  }

  test_perform_deadCode() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
  if (false) {
    print('how?');
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.DEAD_CODE]);
  }

  test_perform_disabled() {
    context.analysisOptions =
        new AnalysisOptionsImpl.from(context.analysisOptions)..hint = false;
    Source source = newSource(
        '/test.dart',
        '''
int main() {
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertNoErrors();
  }

  test_perform_imports_duplicateImport() {
    newSource(
        '/a.dart',
        r'''
library lib_a;
class A {}
''');
    Source source = newSource(
        '/test.dart',
        r'''
import 'a.dart';
import 'a.dart';
main() {
  new A();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.DUPLICATE_IMPORT]);
  }

  test_perform_imports_unusedImport_one() {
    newSource(
        '/a.dart',
        r'''
library lib_a;
class A {}
''');
    newSource(
        '/b.dart',
        r'''
library lib_b;
class B {}
''');
    Source source = newSource(
        '/test.dart',
        r'''
import 'a.dart';
import 'b.dart';
main() {
  new A();
}''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.UNUSED_IMPORT]);
  }

  test_perform_imports_unusedImport_zero() {
    newSource(
        '/a.dart',
        r'''
library lib_a;
class A {}
''');
    Source source = newSource(
        '/test.dart',
        r'''
import 'a.dart';
main() {
  new A();
}''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertNoErrors();
  }

  test_perform_overrideVerifier() {
    Source source = newSource(
        '/test.dart',
        '''
class A {}
class B {
  @override
  m() {}
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD]);
  }

  test_perform_todo() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
  // TODO(developer) foo bar
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[TodoCode.TODO]);
  }

  test_perform_unusedLocalElements_class() {
    Source source = newSource(
        '/test.dart',
        '''
class _A {}
class _B {}
main() {
  new _A();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.UNUSED_ELEMENT]);
  }

  test_perform_unusedLocalElements_localVariable() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
  var v = 42;
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener
        .assertErrorsWithCodes(<ErrorCode>[HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_perform_unusedLocalElements_method() {
    Source source = newSource(
        '/my_lib.dart',
        '''
library my_lib;
part 'my_part.dart';
class A {
  _ma() {}
  _mb() {}
  _mc() {}
}
''');
    newSource(
        '/my_part.dart',
        '''
part of my_lib;

f(A a) {
  a._mb();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, HINTS, matcher: isGenerateHintsTask);
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[HintCode.UNUSED_ELEMENT, HintCode.UNUSED_ELEMENT]);
  }
}

@reflectiveTest
class InferInstanceMembersInUnitTaskTest extends _AbstractDartTaskTest {
  void test_perform() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
class A {
  X f;
  Y m(Z x) {}
}
class B extends A {
  var f;
  m(x) {}
}
class X {}
class Y {}
class Z {}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7,
        matcher: isInferInstanceMembersInUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableDeclaration field = getFieldInClass(unit, 'B', 'f');
    MethodDeclaration method = getMethodInClass(unit, 'B', 'm');
    DartType typeX = getClass(unit, 'X').element.type;
    DartType typeY = getClass(unit, 'Y').element.type;
    DartType typeZ = getClass(unit, 'Z').element.type;

    expect(field.element.type, typeX);
    expect(method.element.returnType, typeY);
    expect(method.element.parameters[0].type, typeZ);
  }
}

@reflectiveTest
class InferStaticVariableTypesInUnitTaskTest extends _AbstractDartTaskTest {
  void test_perform_nestedDeclarations() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var f = (int x) {
  int squared(int value) => value * value;
  var xSquared = squared(x);
  return xSquared;
};
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT6,
        matcher: isInferStaticVariableTypesInUnitTask);
  }

  void test_perform_recursive() {
    enableStrongMode();
    AnalysisTarget firstSource = newSource(
        '/first.dart',
        '''
import 'second.dart';

var a = new M();
var c = b;
''');
    AnalysisTarget secondSource = newSource(
        '/second.dart',
        '''
import 'first.dart';

var b = a;
class M {}
''');
    computeResult(
        new LibrarySpecificUnit(firstSource, firstSource), RESOLVED_UNIT6,
        matcher: isInferStaticVariableTypesInUnitTask);
    CompilationUnit firstUnit = outputs[RESOLVED_UNIT6];
    computeResult(
        new LibrarySpecificUnit(secondSource, secondSource), RESOLVED_UNIT6);
    CompilationUnit secondUnit = outputs[RESOLVED_UNIT6];

    VariableDeclaration variableA = getTopLevelVariable(firstUnit, 'a');
    VariableDeclaration variableB = getTopLevelVariable(secondUnit, 'b');
    VariableDeclaration variableC = getTopLevelVariable(firstUnit, 'c');
    ClassDeclaration classM = getClass(secondUnit, 'M');
    DartType typeM = classM.element.type;

    expect(variableA.element.type, typeM);
    expect(variableB.element.type, typeM);
    expect(variableB.initializer.staticType, typeM);
    expect(variableC.element.type, typeM);
    expect(variableC.initializer.staticType, typeM);
  }

  void test_perform_simple() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var X = 1;

var Y = () {
  return 1 + X;
};
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT6,
        matcher: isInferStaticVariableTypesInUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT6];
    TopLevelVariableDeclaration declaration = unit.declarations[1];
    FunctionExpression function =
        declaration.variables.variables[0].initializer;
    BlockFunctionBody body = function.body;
    ReturnStatement statement = body.block.statements[0];
    Expression expression = statement.expression;
    InterfaceType intType = context.typeProvider.intType;
    expect(expression.staticType, intType);
  }
}

@reflectiveTest
class InferStaticVariableTypeTaskTest extends _AbstractDartTaskTest {
  void test_getDeclaration_staticField() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
class C {
  var field = '';
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    VariableDeclaration declaration = getFieldInClass(unit, 'C', 'field');
    VariableElement variable = declaration.name.staticElement;
    InferStaticVariableTypeTask inferTask =
        new InferStaticVariableTypeTask(task.context, variable);
    expect(inferTask.getDeclaration(unit), declaration);
  }

  void test_getDeclaration_topLevel() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var topLevel = '';
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    VariableDeclaration declaration = getTopLevelVariable(unit, 'topLevel');
    VariableElement variable = declaration.name.staticElement;
    InferStaticVariableTypeTask inferTask =
        new InferStaticVariableTypeTask(task.context, variable);
    expect(inferTask.getDeclaration(unit), declaration);
  }

  void test_perform() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var topLevel = '';
class C {
  var field = topLevel;
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    VariableElement topLevel =
        getTopLevelVariable(unit, 'topLevel').name.staticElement;
    VariableElement field =
        getFieldInClass(unit, 'C', 'field').name.staticElement;

    computeResult(field, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    InterfaceType stringType = context.typeProvider.stringType;
    expect(topLevel.type, stringType);
    expect(field.type, stringType);
    expect(outputs[INFER_STATIC_VARIABLE_ERRORS], hasLength(0));
  }

  void test_perform_cycle() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var piFirst = true;
var pi = piFirst ? 3.14 : tau / 2;
var tau = piFirst ? pi * 2 : 6.28;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    VariableElement piFirst =
        getTopLevelVariable(unit, 'piFirst').name.staticElement;
    VariableElement pi = getTopLevelVariable(unit, 'pi').name.staticElement;
    VariableElement tau = getTopLevelVariable(unit, 'tau').name.staticElement;

    computeResult(piFirst, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    expect(piFirst.type, context.typeProvider.boolType);
    expect(pi.type.isDynamic, isTrue);
    expect(tau.type.isDynamic, isTrue);
    expect(outputs[INFER_STATIC_VARIABLE_ERRORS], hasLength(0));
  }

  void test_perform_error() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var a = '' / null;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    VariableElement a = getTopLevelVariable(unit, 'a').name.staticElement;

    computeResult(a, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    expect(a.type.isDynamic, isTrue);
    expect(outputs[INFER_STATIC_VARIABLE_ERRORS], hasLength(1));
  }

  void test_perform_null() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var a = null;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT5);
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    VariableElement a = getTopLevelVariable(unit, 'a').name.staticElement;

    computeResult(a, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    expect(a.type.isDynamic, isTrue);
    expect(outputs[INFER_STATIC_VARIABLE_ERRORS], hasLength(0));
  }
}

@reflectiveTest
class LibraryErrorsReadyTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source library = newSource(
        '/lib.dart',
        r'''
library lib;
part 'part1.dart';
part 'part2.dart';
X v1;
''');
    Source part1 = newSource(
        '/part1.dart',
        r'''
part of lib;
X v2;
''');
    Source part2 = newSource(
        '/part2.dart',
        r'''
part of lib;
X v3;
''');
    computeResult(library, LIBRARY_ERRORS_READY,
        matcher: isLibraryErrorsReadyTask);
    expect(outputs, hasLength(1));
    bool ready = outputs[LIBRARY_ERRORS_READY];
    expect(ready, isTrue);
    expect(context.getErrors(library).errors, hasLength(1));
    expect(context.getErrors(part1).errors, hasLength(1));
    expect(context.getErrors(part2).errors, hasLength(1));
  }
}

@reflectiveTest
class LibraryUnitErrorsTaskTest extends _AbstractDartTaskTest {
  test_perform_definingCompilationUnit() {
    AnalysisTarget library =
        newSource('/test.dart', 'library test; import "dart:math";');
    computeResult(
        new LibrarySpecificUnit(library, library), LIBRARY_UNIT_ERRORS,
        matcher: isLibraryUnitErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = outputs[LIBRARY_UNIT_ERRORS];
    expect(errors, hasLength(1));
  }

  test_perform_partInSingleLibrary() {
    AnalysisTarget library =
        newSource('/lib.dart', 'library test; part "part.dart";');
    AnalysisTarget part = newSource('/part.dart', 'part of test;');
    computeResult(new LibrarySpecificUnit(library, part), LIBRARY_UNIT_ERRORS,
        matcher: isLibraryUnitErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = outputs[LIBRARY_UNIT_ERRORS];
    expect(errors, hasLength(0));
  }
}

@reflectiveTest
class ParseDartTaskTest extends _AbstractDartTaskTest {
  Source source;

  test_perform() {
    _performParseTask(r'''
part of lib;
class B {}''');
    expect(outputs, hasLength(8));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.PART);
    expect(outputs[UNITS], hasLength(1));
  }

  test_perform_computeSourceKind_noDirectives_hasContainingLibrary() {
    // Parse "lib.dart" to let the context know that "test.dart" is included.
    computeResult(
        newSource(
            '/lib.dart',
            r'''
library lib;
part 'test.dart';
'''),
        PARSED_UNIT);
    // If there are no the "part of" directive, then it is not a part.
    _performParseTask('');
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  test_perform_computeSourceKind_noDirectives_noContainingLibrary() {
    _performParseTask('');
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
  }

  test_perform_doesNotExist() {
    _performParseTask(null);
    expect(outputs, hasLength(8));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.UNKNOWN);
    expect(outputs[UNITS], hasLength(1));
  }

  test_perform_invalidDirectives() {
    _performParseTask(r'''
library lib;
import '/does/not/exist.dart';
import '://invaliduri.dart';
export '${a}lib3.dart';
part 'part.dart';
class A {}''');
    expect(outputs, hasLength(8));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(2));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
    expect(outputs[UNITS], hasLength(2));
  }

  test_perform_library() {
    _performParseTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');
    expect(outputs, hasLength(8));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(1));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(1));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
    expect(outputs[UNITS], hasLength(2));
  }

  test_perform_library_selfReferenceAsPart() {
    _performParseTask(r'''
library lib;
part 'test.dart';
''');
    expect(outputs[INCLUDED_PARTS], unorderedEquals(<Source>[source]));
  }

  test_perform_part() {
    _performParseTask(r'''
part of lib;
class B {}''');
    expect(outputs, hasLength(8));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.PART);
    expect(outputs[UNITS], hasLength(1));
  }

  void _performParseTask(String content) {
    source = newSource('/test.dart', content);
    computeResult(source, PARSED_UNIT, matcher: isParseDartTask);
  }

  static void _assertHasCore(List<Source> sources, int lenght) {
    expect(sources, hasLength(lenght));
    expect(sources, contains(predicate((Source s) {
      return s.fullName.endsWith('core.dart');
    })));
  }
}

@reflectiveTest
class PartiallyResolveUnitReferencesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    enableStrongMode();
    Source source = newSource(
        '/test.dart',
        '''
int a = b;
int b = c;
var d = 0;
class A {}
class C {
  static final f = '';
  var g = 0;
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT5,
        matcher: isPartiallyResolveUnitReferencesTask);
    // Test the outputs
    expect(outputs[INFERABLE_STATIC_VARIABLES_IN_UNIT], hasLength(4));
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    expect(unit, same(outputs[RESOLVED_UNIT5]));
    // Test the state of the AST
    TopLevelVariableDeclaration a = unit.declarations[0];
    VariableDeclaration variableA = a.variables.variables[0];
    SimpleIdentifier initializer = variableA.initializer;
    expect(initializer.staticElement, isNotNull);
    // Test the error generation
    _fillErrorListener(PARTIALLY_RESOLVE_REFERENCES_ERRORS);
    errorListener.assertNoErrors();
  }

  test_perform_importExport() {
    newSource(
        '/a.dart',
        '''
library a;
class A<T> {
  T m() {}
}
''');
    newSource(
        '/b.dart',
        '''
library b;
export 'a.dart';
''');
    Source sourceC = newSource(
        '/c.dart',
        '''
library c;
import 'b.dart';
main() {
  new A<int>().m();
}
''');
    computeResult(new LibrarySpecificUnit(sourceC, sourceC), RESOLVED_UNIT5,
        matcher: isPartiallyResolveUnitReferencesTask);
    // validate
    expect(outputs[INFERABLE_STATIC_VARIABLES_IN_UNIT], hasLength(0));
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    expect(unit, isNotNull);

    FunctionDeclaration mainFunction = unit.declarations[0];
    expect(mainFunction.element, isNotNull);
    BlockFunctionBody body = mainFunction.functionExpression.body;
    List<Statement> statements = body.block.statements;
    ExpressionStatement statement = statements[0];
    MethodInvocation invocation = statement.expression;
    MethodElement methodElement = invocation.methodName.staticElement;
    expect(methodElement, isNull);
  }
}

@reflectiveTest
class ResolveFunctionBodiesInUnitTaskTest extends _AbstractDartTaskTest {
  void test_perform() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
void f() {
  var c = new C();
  c.m();
}
class C {
  void m() {
    f();
  }
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT8,
        matcher: isResolveFunctionBodiesInUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT8];

    FunctionDeclaration f = unit.declarations[0];
    _assertResolved(f.functionExpression.body);

    MethodDeclaration m = (unit.declarations[1] as ClassDeclaration).members[0];
    _assertResolved(m.body);

    expect(outputs[RESOLVE_FUNCTION_BODIES_ERRORS], hasLength(0));
  }

  void _assertResolved(FunctionBody body) {
    ResolutionVerifier verifier = new ResolutionVerifier();
    body.accept(verifier);
    verifier.assertResolved();
  }
}

@reflectiveTest
class ResolveLibraryTypeNamesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source sourceLib = newSource(
        '/my_lib.dart',
        '''
library my_lib;
part 'my_part.dart';
class A {}
class B extends A {}
''');
    newSource(
        '/my_part.dart',
        '''
part of my_lib;
class C extends A {}
''');
    computeResult(sourceLib, LIBRARY_ELEMENT5,
        matcher: isResolveLibraryTypeNamesTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT5];
    {
      ClassElement classB = library.getType('B');
      expect(classB.supertype.displayName, 'A');
    }
    {
      ClassElement classC = library.getType('C');
      expect(classC.supertype.displayName, 'A');
    }
  }

  test_perform_external() {
    Source sourceA = newSource(
        '/a.dart',
        '''
library a;
import 'b.dart';
class A extends B {}
''');
    newSource(
        '/b.dart',
        '''
library b;
class B {}
''');
    // The reference A to B should be resolved, but there's no requirement that
    // the full class hierarchy be resolved.
    computeResult(sourceA, LIBRARY_ELEMENT5,
        matcher: isResolveLibraryTypeNamesTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT5];
    {
      ClassElement clazz = library.getType('A');
      expect(clazz.displayName, 'A');
      clazz = clazz.supertype.element;
      expect(clazz.displayName, 'B');
    }
  }
}

@reflectiveTest
class ResolveUnitTypeNamesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource(
        '/test.dart',
        '''
class A {}
class B extends A {}
int f(String p) => p.length;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT3, matcher: isResolveUnitTypeNamesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT3];
    {
      ClassDeclaration nodeA = unit.declarations[0];
      ClassDeclaration nodeB = unit.declarations[1];
      DartType extendsType = nodeB.extendsClause.superclass.type;
      expect(extendsType, nodeA.element.type);
    }
    {
      FunctionDeclaration functionNode = unit.declarations[2];
      DartType returnType = functionNode.returnType.type;
      List<FormalParameter> parameters =
          functionNode.functionExpression.parameters.parameters;
      expect(returnType.displayName, 'int');
      expect(parameters[0].element.type.displayName, 'String');
    }
  }

  test_perform_errors() {
    Source source = newSource(
        '/test.dart',
        '''
NoSuchClass f() => null;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVE_TYPE_NAMES_ERRORS,
        matcher: isResolveUnitTypeNamesTask);
    // validate
    _fillErrorListener(RESOLVE_TYPE_NAMES_ERRORS);
    errorListener
        .assertErrorsWithCodes(<ErrorCode>[StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_perform_typedef() {
    Source source = newSource(
        '/test.dart',
        '''
typedef int F(G g);
typedef String G(int p);
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT3, matcher: isResolveUnitTypeNamesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT3];
    FunctionTypeAlias nodeF = unit.declarations[0];
    FunctionTypeAlias nodeG = unit.declarations[1];
    {
      FormalParameter parameter = nodeF.parameters.parameters[0];
      DartType parameterType = parameter.element.type;
      Element returnTypeElement = nodeF.returnType.type.element;
      expect(returnTypeElement.displayName, 'int');
      expect(parameterType.element, nodeG.element);
    }
    {
      FormalParameter parameter = nodeG.parameters.parameters[0];
      DartType parameterType = parameter.element.type;
      expect(nodeG.returnType.type.element.displayName, 'String');
      expect(parameterType.element.displayName, 'int');
    }
  }

  test_perform_typedef_errors() {
    Source source = newSource(
        '/test.dart',
        '''
typedef int F(NoSuchType p);
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVE_TYPE_NAMES_ERRORS,
        matcher: isResolveUnitTypeNamesTask);
    // validate
    _fillErrorListener(RESOLVE_TYPE_NAMES_ERRORS);
    errorListener
        .assertErrorsWithCodes(<ErrorCode>[StaticWarningCode.UNDEFINED_CLASS]);
  }
}

@reflectiveTest
class ResolveVariableReferencesTaskTest extends _AbstractDartTaskTest {
  /**
   * Verify that the mutated states of the given [variable] correspond to the
   * [mutatedInClosure] and [mutatedInScope] matchers.
   */
  void expectMutated(VariableElement variable, Matcher mutatedInClosure,
      Matcher mutatedInScope) {
    expect(variable.isPotentiallyMutatedInClosure, mutatedInClosure);
    expect(variable.isPotentiallyMutatedInScope, mutatedInScope);
  }

  test_perform_buildClosureLibraryElements() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveVariableReferencesTask);
  }

  test_perform_local() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
  var v1 = 1;
  var v2 = 1;
  var v3 = 1;
  var v4 = 1;
  v2 = 2;
  v4 = 2;
  localFunction() {
    v3 = 3;
    v4 = 3;
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveVariableReferencesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    FunctionElement main = unit.element.functions[0];
    expectMutated(main.localVariables[0], isFalse, isFalse);
    expectMutated(main.localVariables[1], isFalse, isTrue);
    expectMutated(main.localVariables[2], isTrue, isTrue);
    expectMutated(main.localVariables[3], isTrue, isTrue);
  }

  test_perform_parameter() {
    Source source = newSource(
        '/test.dart',
        '''
main(p1, p2, p3, p4) {
  p2 = 2;
  p4 = 2;
  localFunction() {
    p3 = 3;
    p4 = 3;
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveVariableReferencesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    FunctionElement main = unit.element.functions[0];
    expectMutated(main.parameters[0], isFalse, isFalse);
    expectMutated(main.parameters[1], isFalse, isTrue);
    expectMutated(main.parameters[2], isTrue, isTrue);
    expectMutated(main.parameters[3], isTrue, isTrue);
  }
}

@reflectiveTest
class ScanDartTaskTest extends _AbstractDartTaskTest {
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

  test_perform_script() {
    String scriptContent = '''
      void buttonPressed() {
    ''';
    String htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
    <script type='application/dart'>$scriptContent</script>
  </head>
  <body>Test</body>
</html>
''';
    Source source = newSource('/test.html', htmlContent);
    DartScript script =
        new DartScript(source, [new ScriptFragment(97, 5, 36, scriptContent)]);

    computeResult(script, TOKEN_STREAM, matcher: isScanDartTask);
    expect(outputs[LINE_INFO], isNotNull);
    expect(outputs[SCAN_ERRORS], isEmpty);
    Token tokenStream = outputs[TOKEN_STREAM];
    expect(tokenStream, isNotNull);
    expect(tokenStream.lexeme, 'void');
  }

  void _performScanTask(String content) {
    AnalysisTarget target = newSource('/test.dart', content);
    computeResult(target, TOKEN_STREAM, matcher: isScanDartTask);
  }
}

@reflectiveTest
class VerifyUnitTaskTest extends _AbstractDartTaskTest {
  test_perform_constantError() {
    Source source = newSource(
        '/test.dart',
        '''
main(int p) {
  const v = p;
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  test_perform_directiveError() {
    Source source = newSource(
        '/test.dart',
        '''
import 'no-such-file.dart';
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_perform_verifyError() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
  if (42) {
    print('Not bool!');
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }
}

class _AbstractDartTaskTest extends AbstractContextTest {
  Source emptySource;

  GatheringErrorListener errorListener = new GatheringErrorListener();

  void assertIsInvalid(AnalysisTarget target, ResultDescriptor descriptor) {
    CacheEntry entry = context.getCacheEntry(target);
    expect(entry.isInvalid(descriptor), isTrue);
  }

  void assertIsValid(AnalysisTarget target, ResultDescriptor descriptor) {
    CacheEntry entry = context.getCacheEntry(target);
    expect(entry.isValid(descriptor), isTrue);
  }

  void assertSameResults(List<ResultDescriptor> descriptors) {
    descriptors.forEach((descriptor) {
      var oldResult = oldOutputs[descriptor];
      var newResult = outputs[descriptor];
      expect(newResult, same(oldResult), reason: descriptor.name);
    });
  }

  /**
   * Create a script object with a single fragment containing the given
   * [scriptContent].
   */
  DartScript createScript(String scriptContent) {
    String htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <title>test page</title>
    <script type='application/dart'>$scriptContent</script>
  </head>
  <body>Test</body>
</html>
''';
    Source source = newSource('/test.html', htmlContent);
    return new DartScript(
        source, [new ScriptFragment(97, 5, 36, scriptContent)]);
  }

  /**
   * Enable strong mode in the current analysis context.
   */
  void enableStrongMode() {
    AnalysisOptionsImpl options = context.analysisOptions;
    options.strongMode = true;
    context.analysisOptions = options;
  }

  /**
   * Return the declaration of the class with the given [className] in the given
   * compilation [unit].
   */
  ClassDeclaration getClass(CompilationUnit unit, String className) {
    NodeList<CompilationUnitMember> unitMembers = unit.declarations;
    for (CompilationUnitMember unitMember in unitMembers) {
      if (unitMember is ClassDeclaration && unitMember.name.name == className) {
        return unitMember;
      }
    }
    fail('No class named $className in ${unit.element.source}');
    return null;
  }

  /**
   * Return the declaration of the field with the given [fieldName] in the class
   * with the given [className] in the given compilation [unit].
   */
  VariableDeclaration getFieldInClass(
      CompilationUnit unit, String className, String fieldName) {
    ClassDeclaration unitMember = getClass(unit, className);
    NodeList<ClassMember> classMembers = unitMember.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is FieldDeclaration) {
        NodeList<VariableDeclaration> fields = classMember.fields.variables;
        for (VariableDeclaration field in fields) {
          if (field.name.name == fieldName) {
            return field;
          }
        }
      }
    }
    fail('No field named $fieldName in $className');
    return null;
  }

  /**
   * Return the declaration of the method with the given [methodName] in the
   * class with the given [className] in the given compilation [unit].
   */
  MethodDeclaration getMethodInClass(
      CompilationUnit unit, String className, String methodName) {
    ClassDeclaration unitMember = getClass(unit, className);
    NodeList<ClassMember> classMembers = unitMember.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is MethodDeclaration) {
        if (classMember.name.name == methodName) {
          return classMember;
        }
      }
    }
    fail('No method named $methodName in $className');
    return null;
  }

  /**
   * Return the declaration of the top-level variable with the given
   * [variableName] in the given compilation [unit].
   */
  VariableDeclaration getTopLevelVariable(
      CompilationUnit unit, String variableName) {
    NodeList<CompilationUnitMember> unitMembers = unit.declarations;
    for (CompilationUnitMember unitMember in unitMembers) {
      if (unitMember is TopLevelVariableDeclaration) {
        NodeList<VariableDeclaration> variables =
            unitMember.variables.variables;
        for (VariableDeclaration variable in variables) {
          if (variable.name.name == variableName) {
            return variable;
          }
        }
      }
    }
    return null;
  }

  void setUp() {
    super.setUp();
    emptySource = newSource('/test.dart');
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
}
