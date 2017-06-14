// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.dart_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptionsImpl, CacheState;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/src/task/strong/ast_properties.dart' as strong_ast;
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:front_end/src/scanner/scanner.dart' as fe;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';
import '../../generated/test_support.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuildCompilationUnitElementTaskTest);
    defineReflectiveTests(BuildDirectiveElementsTaskTest);
    defineReflectiveTests(BuildEnumMemberElementsTaskTest);
    defineReflectiveTests(BuildExportNamespaceTaskTest);
    defineReflectiveTests(BuildLibraryElementTaskTest);
    defineReflectiveTests(BuildPublicNamespaceTaskTest);
    defineReflectiveTests(BuildSourceExportClosureTaskTest);
    defineReflectiveTests(BuildTypeProviderTaskTest);
    defineReflectiveTests(ComputeConstantDependenciesTaskTest);
    defineReflectiveTests(ComputeConstantValueTaskTest);
    defineReflectiveTests(ComputeInferableStaticVariableDependenciesTaskTest);
    defineReflectiveTests(ComputeLibraryCycleTaskTest);
    defineReflectiveTests(ContainingLibrariesTaskTest);
    defineReflectiveTests(DartErrorsTaskTest);
    defineReflectiveTests(EvaluateUnitConstantsTaskTest);
    defineReflectiveTests(GatherUsedImportedElementsTaskTest);
    defineReflectiveTests(GatherUsedLocalElementsTaskTest);
    defineReflectiveTests(GenerateHintsTaskTest);
    defineReflectiveTests(GenerateLintsTaskTest);
    defineReflectiveTests(InferInstanceMembersInUnitTaskTest);
    defineReflectiveTests(InferStaticVariableTypesInUnitTaskTest);
    defineReflectiveTests(InferStaticVariableTypeTaskTest);
    defineReflectiveTests(LibraryErrorsReadyTaskTest);
    defineReflectiveTests(LibraryUnitErrorsTaskTest);
    defineReflectiveTests(ParseDartTaskTest);
    defineReflectiveTests(PartiallyResolveUnitReferencesTaskTest);
    defineReflectiveTests(ResolveDirectiveElementsTaskTest);
    defineReflectiveTests(ResolveInstanceFieldsInUnitTaskTest);
    defineReflectiveTests(ResolveLibraryTaskTest);
    defineReflectiveTests(ResolveLibraryTypeNamesTaskTest);
    defineReflectiveTests(ResolveTopLevelUnitTypeBoundsTaskTest);
    defineReflectiveTests(ResolveUnitTaskTest);
    defineReflectiveTests(ResolveUnitTypeNamesTaskTest);
    defineReflectiveTests(ResolveVariableReferencesTaskTest);
    defineReflectiveTests(ScanDartTaskTest);
    defineReflectiveTests(StrongModeInferenceTest);
    defineReflectiveTests(StrongModeVerifyUnitTaskTest);
    defineReflectiveTests(VerifyUnitTaskTest);
  });
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
isInstanceOf isGenerateLintsTask = new isInstanceOf<GenerateLintsTask>();
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
isInstanceOf isResolveDirectiveElementsTask =
    new isInstanceOf<ResolveDirectiveElementsTask>();
isInstanceOf isResolveLibraryReferencesTask =
    new isInstanceOf<ResolveLibraryReferencesTask>();
isInstanceOf isResolveLibraryTask = new isInstanceOf<ResolveLibraryTask>();
isInstanceOf isResolveLibraryTypeNamesTask =
    new isInstanceOf<ResolveLibraryTypeNamesTask>();
isInstanceOf isResolveTopLevelUnitTypeBoundsTask =
    new isInstanceOf<ResolveTopLevelUnitTypeBoundsTask>();
isInstanceOf isResolveUnitTask = new isInstanceOf<ResolveUnitTask>();
isInstanceOf isResolveUnitTypeNamesTask =
    new isInstanceOf<ResolveUnitTypeNamesTask>();
isInstanceOf isResolveVariableReferencesTask =
    new isInstanceOf<ResolveVariableReferencesTask>();
isInstanceOf isScanDartTask = new isInstanceOf<ScanDartTask>();
isInstanceOf isStrongModeVerifyUnitTask =
    new isInstanceOf<StrongModeVerifyUnitTask>();
isInstanceOf isVerifyUnitTask = new isInstanceOf<VerifyUnitTask>();

final LintCode _testLintCode = new LintCode('test lint', 'test lint code');

@reflectiveTest
class BuildCompilationUnitElementTaskTest extends _AbstractDartTaskTest {
  Source source;
  LibrarySpecificUnit target;

  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT1);
    expect(outputs[RESOLVED_UNIT1], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT1], isTrue);
  }

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
    List<ConstantEvaluationTarget> expectedConstants =
        <ConstantEvaluationTarget>[
      unitElement.accessors.firstWhere((e) => e.isGetter).variable,
      unitElement.types[0].fields[0],
      unitElement.functions[0].localVariables[0],
      unitElement.types[0].constructors[0],
      resolutionMap.elementAnnotationForAnnotation(annotation),
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
    expect(outputs, hasLength(4));
    expect(outputs[COMPILATION_UNIT_CONSTANTS], isNotNull);
    expect(outputs[COMPILATION_UNIT_ELEMENT], isNotNull);
    expect(outputs[RESOLVED_UNIT1], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT1], isTrue);
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
  /**
   * Verify that the given [element] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved and points back to [element].
   *
   * The compilation unit stored in the [ElementAnnotationImpl] should be
   * [compilationUnit].
   */
  void checkMetadata(Element element, CompilationUnitElement compilationUnit) {
    expect(element.metadata, hasLength(1));
    expect(element.metadata[0], new isInstanceOf<ElementAnnotationImpl>());
    ElementAnnotationImpl elementAnnotation = element.metadata[0];
    expect(elementAnnotation.element, isNull); // Not yet resolved
    expect(elementAnnotation.compilationUnit, isNotNull);
    expect(elementAnnotation.compilationUnit, compilationUnit);
  }

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

  test_perform_configurations_export() {
    context.declaredVariables.define('dart.library.io', 'true');
    context.declaredVariables.define('dart.library.html', 'true');
    newSource('/foo.dart', '');
    var foo_io = newSource('/foo_io.dart', '');
    newSource('/foo_html.dart', '');
    var testSource = newSource(
        '/test.dart',
        r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    // Perform the task.
    computeResult(testSource, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    LibraryElement testLibrary = outputs[LIBRARY_ELEMENT2];
    // Validate the export element.
    ExportElement export = testLibrary.exports[0];
    expect(export.exportedLibrary.source, foo_io);
    expect(export.uri, 'foo_io.dart');
  }

  test_perform_configurations_import() {
    context.declaredVariables.define('dart.library.io', 'true');
    context.declaredVariables.define('dart.library.html', 'true');
    newSource('/foo.dart', '');
    var foo_io = newSource('/foo_io.dart', '');
    newSource('/foo_html.dart', '');
    var testSource = newSource(
        '/test.dart',
        r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    // Perform the task.
    computeResult(testSource, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    LibraryElement testLibrary = outputs[LIBRARY_ELEMENT2];
    // Validate the import element.
    ImportElement import = testLibrary.imports[0];
    expect(import.importedLibrary.source, foo_io);
    expect(import.uri, 'foo_io.dart');
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

  test_perform_metadata() {
    List<Source> sources = newSources({
      '/libA.dart': '''
@a library libA;
@b import 'libB.dart';
@c export 'libC.dart';
@d part 'part.dart';''',
      '/libB.dart': 'library libB;',
      '/libC.dart': 'library libC;',
      '/part.dart': 'part of libA;'
    });
    Source sourceA = sources[0];
    // perform task
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // Get outputs
    LibraryElement libraryA =
        context.getCacheEntry(sourceA).getValue(LIBRARY_ELEMENT2);
    // Validate metadata
    checkMetadata(libraryA, libraryA.definingCompilationUnit);
    checkMetadata(libraryA.imports[0], libraryA.definingCompilationUnit);
    checkMetadata(libraryA.exports[0], libraryA.definingCompilationUnit);
    checkMetadata(libraryA.parts[0], libraryA.definingCompilationUnit);
  }

  test_perform_metadata_partOf() {
    // We don't record annotations on `part of` directives because the element
    // associated with a `part of` directive is the library, and the convention
    // is to annotate the library at the site of the `library` declaration.
    List<Source> sources = newSources({
      '/libA.dart': '''
library libA;
part 'part.dart';''',
      '/part.dart': '@a part of libA;'
    });
    Source sourceA = sources[0];
    Source sourcePart = sources[1];
    // perform task
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // Get outputs
    LibraryElement libraryA =
        context.getCacheEntry(sourceA).getValue(LIBRARY_ELEMENT2);
    CompilationUnit part = context
        .getCacheEntry(new LibrarySpecificUnit(sourceA, sourcePart))
        .getValue(RESOLVED_UNIT1);
    // Validate metadata
    expect(part.directives[0], new isInstanceOf<PartOfDirective>());
    expect(part.directives[0].element, same(libraryA));
    expect(
        resolutionMap.elementDeclaredByDirective(part.directives[0]).metadata,
        isEmpty);
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
  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT3);
    expect(outputs[RESOLVED_UNIT3], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT3], isTrue);
  }

  test_perform() {
    Source source = newSource(
        '/test.dart',
        '''
enum MyEnum {
  A, B
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT3,
        matcher: isBuildEnumMemberElementsTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT3];
    // validate Element
    ClassElement enumElement =
        resolutionMap.elementDeclaredByCompilationUnit(unit).getEnum('MyEnum');
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
    enableUriInPartOf();
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
part of 'lib.dart';
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
    if (resolutionMap.elementDeclaredByCompilationUnit(partUnits[0]).uri ==
        'part1.dart') {
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

  test_perform_error_missingLibraryDirectiveWithPart() {
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
    if (context.analysisOptions.enableUriInPartOf) {
      // TODO(28522)
      // Should report that names are wrong.
    } else {
      _assertErrorsWithCodes(
          [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
    }
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
    if (context.analysisOptions.enableUriInPartOf) {
      // TODO(28522)
      // Should report that names are wrong.
    } else {
      _assertErrorsWithCodes(
          [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
    }
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
    String invalidUri = resourceProvider.pathContext.separator == '/'
        ? '//////////'
        : '\\\\\\\\\\\\';
    _performBuildTask({
      '/lib.dart': '''
library lib;
part '$invalidUri';
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
    CompilationUnitElement unitElement1 = partUnits
        .singleWhere((u) => resolutionMap
            .elementDeclaredByCompilationUnit(u)
            .name
            .endsWith('part1.dart'))
        .element;
    CompilationUnitElement unitElement2 = partUnits
        .singleWhere((u) => resolutionMap
            .elementDeclaredByCompilationUnit(u)
            .name
            .endsWith('part2.dart'))
        .element;
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
    partUnits = task.inputs[BuildLibraryElementTask.PARTS_UNIT_INPUT]
        as List<CompilationUnit>;
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
  List<Source> getExportSourceClosure(Map<ResultDescriptor, dynamic> outputs) {
    return outputs[EXPORT_SOURCE_CLOSURE] as List<Source>;
  }

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
      List<Source> closure = getExportSourceClosure(outputs);
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // c.dart
    {
      computeResult(sourceC, EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceExportClosureTask);
      List<Source> closure = getExportSourceClosure(outputs);
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // d.dart
    {
      computeResult(sourceD, EXPORT_SOURCE_CLOSURE,
          matcher: isBuildSourceExportClosureTask);
      List<Source> closure = getExportSourceClosure(outputs);
      expect(closure, unorderedEquals([sourceD]));
    }
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
    CompilationUnitElement compilationUnitElement =
        resolutionMap.elementDeclaredByCompilationUnit(unit);
    List<PropertyAccessorElement> accessors = compilationUnitElement.accessors;
    Element x = accessors
        .firstWhere((PropertyAccessorElement accessor) =>
            accessor.isGetter && accessor.name == 'x')
        .variable;
    List<ClassElement> types = compilationUnitElement.types;
    Element constructorForD =
        types.firstWhere((ClassElement cls) => cls.name == 'D').constructors[0];
    Annotation annotation = findClassAnnotation(unit, 'C');
    // Now compute the dependencies for the annotation, and check that it is
    // the set [x, constructorForD].
    // TODO(paulberry): test librarySource != source
    computeResult(resolutionMap.elementAnnotationForAnnotation(annotation),
        CONSTANT_DEPENDENCIES,
        matcher: isComputeConstantDependenciesTask);
    expect(
        outputs[CONSTANT_DEPENDENCIES].toSet(), [x, constructorForD].toSet());
  }

  test_annotation_with_nonConstArg() {
    Source source = newSource(
        '/test.dart',
        '''
class A {
  const A(x);
}
class C {
  @A(const [(_) => null])
  String s;
}
''');
    // First compute the resolved unit for the source.
    LibrarySpecificUnit librarySpecificUnit =
        new LibrarySpecificUnit(source, source);
    computeResult(librarySpecificUnit, RESOLVED_UNIT1);
    CompilationUnit unit = outputs[RESOLVED_UNIT1];
    // Find the annotation on the field.
    ClassDeclaration classC = unit.declarations[1];
    Annotation annotation = classC.members[0].metadata[0];
    // Now compute the dependencies for the annotation, and check that it is
    // the right size.
    computeResult(resolutionMap.elementAnnotationForAnnotation(annotation),
        CONSTANT_DEPENDENCIES,
        matcher: isComputeConstantDependenciesTask);
    expect(outputs[CONSTANT_DEPENDENCIES], hasLength(1));
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
    List<PropertyAccessorElement> accessors =
        resolutionMap.elementDeclaredByCompilationUnit(unit).accessors;
    Element x = accessors
        .firstWhere((PropertyAccessorElement accessor) =>
            accessor.isGetter && accessor.name == 'x')
        .variable;
    Annotation annotation = findClassAnnotation(unit, 'C');
    // Now compute the dependencies for the annotation, and check that it is
    // the list [x].
    computeResult(resolutionMap.elementAnnotationForAnnotation(annotation),
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
    computeResult(librarySpecificUnit, RESOLVED_UNIT3);
    CompilationUnit unit = outputs[RESOLVED_UNIT3];
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
    List<PropertyAccessorElement> accessors =
        resolutionMap.elementDeclaredByCompilationUnit(unit).accessors;
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
        ElementAnnotationImpl target = annotation.elementAnnotation;
        computeResult(target, CONSTANT_VALUE,
            matcher: isComputeConstantValueTask);
        expect(outputs[CONSTANT_VALUE], same(target));
        EvaluationResultImpl evaluationResult =
            (annotation.elementAnnotation as ElementAnnotationImpl)
                .evaluationResult;
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
    expect(evaluationResult.value.fields['value'].toIntValue(), 1);
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
    expect(evaluationResult.value.toIntValue(), 1);
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
    expect(evaluationResult.value.toIntValue(), 2);
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
    expect(evaluationResult.value.toIntValue(), 1);
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
          AstFinder.getTopLevelVariableElement(unit, otherVariableName);
      _expectCircularityError(
          (otherVariableElement as TopLevelVariableElementImpl)
              .evaluationResult);
    }
  }

  EvaluationResultImpl _computeTopLevelVariableConstValue(
      String variableName, String content) {
    return _evaluateConstant(_resolveUnit(content), variableName);
  }

  EvaluationResultImpl _evaluateConstant(
      CompilationUnit unit, String variableName) {
    // Find the element for the given constant.
    PropertyInducingElement variableElement =
        AstFinder.getTopLevelVariableElement(unit, variableName);
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
  @override
  void setUp() {
    super.setUp();
    // Variable dependencies are only available in strong mode.
    enableStrongMode();
  }

  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT7);
    expect(outputs[RESOLVED_UNIT7], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT7], isTrue);
  }

  test_perform() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
const a = b;
const b = 0;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    TopLevelVariableElement elementA = resolutionMap
        .elementDeclaredByCompilationUnit(unit)
        .topLevelVariables[0];
    TopLevelVariableElement elementB = resolutionMap
        .elementDeclaredByCompilationUnit(unit)
        .topLevelVariables[1];

    computeResult(elementA, INFERABLE_STATIC_VARIABLE_DEPENDENCIES,
        matcher: isComputeInferableStaticVariableDependenciesTask);
    expect(outputs, hasLength(1));
    List<VariableElement> dependencies =
        outputs[INFERABLE_STATIC_VARIABLE_DEPENDENCIES]
            as List<VariableElement>;
    expect(dependencies, unorderedEquals([elementB]));
  }
}

@reflectiveTest
class ComputeLibraryCycleTaskTest extends _AbstractDartTaskTest {
  List<LibraryElement> getLibraryCycle(Map<ResultDescriptor, dynamic> outputs) {
    return outputs[LIBRARY_CYCLE] as List<LibraryElement>;
  }

  List<LibrarySpecificUnit> getLibraryCycleDependencies(
      Map<ResultDescriptor, dynamic> outputs) {
    return outputs[LIBRARY_CYCLE_DEPENDENCIES] as List<LibrarySpecificUnit>;
  }

  List<LibrarySpecificUnit> getLibraryCycleUnits(
      Map<ResultDescriptor, dynamic> outputs) {
    return outputs[LIBRARY_CYCLE_UNITS] as List<LibrarySpecificUnit>;
  }

  @override
  void setUp() {
    super.setUp();
    enableStrongMode();
  }

  void test_library_cycle_incremental() {
    enableStrongMode();
    Source a = newSource(
        '/a.dart',
        '''
library a;
''');
    Source b = newSource(
        '/b.dart',
        '''
library b;
import 'a.dart';
''');
    Source c = newSource(
        '/c.dart',
        '''
library c;
import 'b.dart';
''');

    _assertLibraryCycle(a, [a]);
    _assertLibraryCycle(b, [b]);
    _assertLibraryCycle(c, [c]);

    // Create a cycle.
    context.setContents(
        a,
        '''
library a;
import 'c.dart';
''');
    _expectInvalid(a);
    _expectInvalid(b);
    _expectInvalid(c);

    _assertLibraryCycle(a, [a, b, c]);
    _assertLibraryCycle(b, [a, b, c]);
    _assertLibraryCycle(c, [a, b, c]);

    // Break the cycle again.
    context.setContents(
        a,
        '''
library a;
''');
    _expectInvalid(a);
    _expectInvalid(b);
    _expectInvalid(c);

    _assertLibraryCycle(a, [a]);
    _assertLibraryCycle(b, [b]);
    _assertLibraryCycle(c, [c]);
  }

  void test_library_cycle_incremental_partial() {
    enableStrongMode();
    Source a = newSource(
        '/a.dart',
        r'''
library a;
''');
    Source b = newSource(
        '/b.dart',
        r'''
library b;
import 'a.dart';
''');
    Source c = newSource(
        '/c.dart',
        r'''
library c;
import 'b.dart';
''');

    _assertLibraryCycle(a, [a]);
    _assertLibraryCycle(b, [b]);
    // 'c' is not reachable, so we have not yet computed its library cycles.

    // Complete the cycle, via 'c'.
    context.setContents(
        a,
        r'''
library a;
import 'c.dart';
''');
    _expectInvalid(a);
    _expectInvalid(b);
    _expectInvalid(c);

    // Ensure that everything reachable through 'c' was invalidated,
    // and recomputed to include all three sources.
    _assertLibraryCycle(a, [a, b, c]);
    _assertLibraryCycle(b, [a, b, c]);
    _assertLibraryCycle(c, [a, b, c]);
  }

  void test_library_cycle_incremental_partial2() {
    enableStrongMode();
    Source a = newSource(
        '/a.dart',
        r'''
library a;
import 'b.dart';
''');
    Source b = newSource(
        '/b.dart',
        r'''
library b;
import 'a.dart';
''');
    Source c = newSource(
        '/c.dart',
        r'''
library c;
import 'b.dart';
''');

    _assertLibraryCycle(a, [a, b]);
    _assertLibraryCycle(b, [a, b]);
    _assertLibraryCycle(c, [c]);

    // Include 'c' into the cycle.
    context.setContents(
        a,
        r'''
library a;
import 'b.dart';
import 'c.dart';
''');
    _expectInvalid(a);
    _expectInvalid(b);
    _expectInvalid(c);

    // Start processing with 'b', so that when we resolve 'b' directives,
    // and invalidate library cycles, the 'a' directives are not resolved yet,
    // so we don't know that the cycle must include 'c'.
    _assertLibraryCycle(b, [a, b, c]);
    _assertLibraryCycle(a, [a, b, c]);
    _assertLibraryCycle(c, [a, b, c]);
  }

  void test_library_cycle_linear() {
    List<Source> sources = newSources({
      '/a.dart': '''
''',
      '/b.dart': '''
import 'a.dart';
  '''
    });
    List<Map<ResultDescriptor, dynamic>> results =
        computeLibraryResultsMap(sources, LIBRARY_CYCLE);
    List<LibraryElement> component0 = getLibraryCycle(results[0]);
    List<LibraryElement> component1 = getLibraryCycle(results[1]);
    expect(component0, hasLength(1));
    expect(component1, hasLength(1));

    List<LibrarySpecificUnit> units0 = getLibraryCycleUnits(results[0]);
    List<LibrarySpecificUnit> units1 = getLibraryCycleUnits(results[1]);
    expect(units0, hasLength(1));
    expect(units1, hasLength(1));

    List<LibrarySpecificUnit> dep0 = getLibraryCycleDependencies(results[0]);
    List<LibrarySpecificUnit> dep1 = getLibraryCycleDependencies(results[1]);
    expect(dep0, hasLength(1)); // dart:core
    expect(dep1, hasLength(2)); // dart:core, a.dart
  }

  void test_library_cycle_loop() {
    List<Source> sources = newSources({
      '/a.dart': '''
  import 'c.dart';
''',
      '/b.dart': '''
  import 'a.dart';
  ''',
      '/c.dart': '''
  import 'b.dart';
  '''
    });
    List<Map<ResultDescriptor, dynamic>> results =
        computeLibraryResultsMap(sources, LIBRARY_CYCLE).toList();
    List<LibraryElement> component0 = getLibraryCycle(results[0]);
    List<LibraryElement> component1 = getLibraryCycle(results[1]);
    List<LibraryElement> component2 = getLibraryCycle(results[2]);

    expect(component0, hasLength(3));
    expect(component1, hasLength(3));
    expect(component2, hasLength(3));

    List<LibrarySpecificUnit> units0 = getLibraryCycleUnits(results[0]);
    List<LibrarySpecificUnit> units1 = getLibraryCycleUnits(results[1]);
    List<LibrarySpecificUnit> units2 = getLibraryCycleUnits(results[2]);
    expect(units0, hasLength(3));
    expect(units1, hasLength(3));
    expect(units2, hasLength(3));

    List<LibrarySpecificUnit> dep0 = getLibraryCycleDependencies(results[0]);
    List<LibrarySpecificUnit> dep1 = getLibraryCycleDependencies(results[1]);
    List<LibrarySpecificUnit> dep2 = getLibraryCycleDependencies(results[2]);
    expect(dep0, hasLength(1)); // dart:core
    expect(dep1, hasLength(1)); // dart:core
    expect(dep2, hasLength(1)); // dart:core
  }

  void test_library_cycle_override_inference_incremental() {
    enableStrongMode();
    Source lib1Source = newSource(
        '/my_lib1.dart',
        '''
library my_lib1;
import 'my_lib3.dart';
''');
    Source lib2Source = newSource(
        '/my_lib2.dart',
        '''
library my_lib2;
import 'my_lib1.dart';
''');
    Source lib3Source = newSource(
        '/my_lib3.dart',
        '''
library my_lib3;
import 'my_lib2.dart';

class A {
  int foo(int x) => null;
}
class B extends A {
  foo(x) => null;
}
''');
    AnalysisTarget lib1Target = new LibrarySpecificUnit(lib1Source, lib1Source);
    AnalysisTarget lib2Target = new LibrarySpecificUnit(lib2Source, lib2Source);
    AnalysisTarget lib3Target = new LibrarySpecificUnit(lib3Source, lib3Source);

    computeResult(lib1Target, RESOLVED_UNIT);
    computeResult(lib2Target, RESOLVED_UNIT);
    computeResult(lib3Target, RESOLVED_UNIT);
    CompilationUnit unit = outputs[RESOLVED_UNIT];
    ClassElement b = unit.declarations[1].element;
    expect(b.getMethod('foo').returnType.toString(), 'int');

    // add a dummy edit.
    context.setContents(
        lib1Source,
        '''
library my_lib1;
import 'my_lib3.dart';
var foo = 123;
''');
    _expectInvalid(lib1Source);
    _expectInvalid(lib2Source);
    _expectInvalid(lib3Source);

    computeResult(lib1Target, RESOLVED_UNIT);
    computeResult(lib2Target, RESOLVED_UNIT);
    computeResult(lib3Target, RESOLVED_UNIT);
    unit = outputs[RESOLVED_UNIT];
    b = unit.declarations[1].element;
    expect(b.getMethod('foo').returnType.toString(), 'int',
        reason: 'edit should not affect member inference');
  }

  void test_library_cycle_self_loop() {
    List<Source> sources = newSources({
      '/a.dart': '''
  import 'a.dart';
'''
    });
    List<Map<ResultDescriptor, dynamic>> results =
        computeLibraryResultsMap(sources, LIBRARY_CYCLE).toList();
    List<LibraryElement> component0 = getLibraryCycle(results[0]);
    expect(component0, hasLength(1));

    List<LibrarySpecificUnit> units0 = getLibraryCycleUnits(results[0]);
    expect(units0, hasLength(1));

    List<LibrarySpecificUnit> dep0 = getLibraryCycleDependencies(results[0]);
    expect(dep0, hasLength(1)); // dart:core
  }

  void test_library_cycle_singleton() {
    Source source = newSource(
        '/test.dart',
        '''
import 'dart:core';
''');
    computeResult(source, LIBRARY_CYCLE);
    List<LibraryElement> component = getLibraryCycle(outputs);
    List<LibrarySpecificUnit> units = getLibraryCycleUnits(outputs);
    List<LibrarySpecificUnit> deps = getLibraryCycleDependencies(outputs);
    expect(component, hasLength(1));
    expect(units, hasLength(1));
    expect(deps, hasLength(1));
  }

  void test_library_cycle_tree() {
    List<Source> sources = newSources({
      '/a.dart': '''
''',
      '/b.dart': '''
  ''',
      '/c.dart': '''
  import 'a.dart';
  import 'b.dart';
  '''
    });
    List<Map<ResultDescriptor, dynamic>> results =
        computeLibraryResultsMap(sources, LIBRARY_CYCLE);
    List<LibraryElement> component0 = getLibraryCycle(results[0]);
    List<LibraryElement> component1 = getLibraryCycle(results[1]);
    List<LibraryElement> component2 = getLibraryCycle(results[2]);
    expect(component0, hasLength(1));
    expect(component1, hasLength(1));
    expect(component2, hasLength(1));

    List<LibrarySpecificUnit> units0 = getLibraryCycleUnits(results[0]);
    List<LibrarySpecificUnit> units1 = getLibraryCycleUnits(results[1]);
    List<LibrarySpecificUnit> units2 = getLibraryCycleUnits(results[2]);
    expect(units0, hasLength(1));
    expect(units1, hasLength(1));
    expect(units2, hasLength(1));

    List<LibrarySpecificUnit> dep0 = getLibraryCycleDependencies(results[0]);
    List<LibrarySpecificUnit> dep1 = getLibraryCycleDependencies(results[1]);
    List<LibrarySpecificUnit> dep2 = getLibraryCycleDependencies(results[2]);
    expect(dep0, hasLength(1)); // dart:core
    expect(dep1, hasLength(1)); // dart:core,
    expect(dep2, hasLength(3)); // dart:core, a.dart, b.dart
  }

  void test_library_double_loop() {
    List<Source> sources = newSources({
      '/a.dart': '''
  import 'b.dart';
''',
      '/b.dart': '''
  import 'a.dart';
  ''',
      '/c.dart': '''
  import 'd.dart' as foo;
  import 'a.dart' as bar;
  export 'b.dart';
  ''',
      '/d.dart': '''
  import 'c.dart' as foo;
  import 'b.dart' as bar;
  export 'a.dart';
  '''
    });
    List<Map<ResultDescriptor, dynamic>> results =
        computeLibraryResultsMap(sources, LIBRARY_CYCLE).toList();
    List<LibraryElement> component0 = getLibraryCycle(results[0]);
    List<LibraryElement> component1 = getLibraryCycle(results[1]);
    List<LibraryElement> component2 = getLibraryCycle(results[2]);
    List<LibraryElement> component3 = getLibraryCycle(results[3]);

    expect(component0, hasLength(2));
    expect(component1, hasLength(2));
    expect(component2, hasLength(2));
    expect(component3, hasLength(2));

    List<LibrarySpecificUnit> units0 = getLibraryCycleUnits(results[0]);
    List<LibrarySpecificUnit> units1 = getLibraryCycleUnits(results[1]);
    List<LibrarySpecificUnit> units2 = getLibraryCycleUnits(results[2]);
    List<LibrarySpecificUnit> units3 = getLibraryCycleUnits(results[3]);
    expect(units0, hasLength(2));
    expect(units1, hasLength(2));
    expect(units2, hasLength(2));
    expect(units3, hasLength(2));

    List<LibrarySpecificUnit> dep0 = getLibraryCycleDependencies(results[0]);
    List<LibrarySpecificUnit> dep1 = getLibraryCycleDependencies(results[1]);
    List<LibrarySpecificUnit> dep2 = getLibraryCycleDependencies(results[2]);
    List<LibrarySpecificUnit> dep3 = getLibraryCycleDependencies(results[3]);
    expect(dep0, hasLength(1)); // dart:core
    expect(dep1, hasLength(1)); // dart:core
    expect(dep2, hasLength(3)); // dart:core, a.dart, b.dart
    expect(dep3, hasLength(3)); // dart:core, a.dart, b.dart
  }

  void test_library_double_loop_parts() {
    List<Source> sources = newSources({
      '/a.dart': '''
  import 'b.dart';
  part 'aa.dart';
  part 'ab.dart';
''',
      '/b.dart': '''
  import 'a.dart';
''',
      '/aa.dart': '''
''',
      '/ab.dart': '''
''',
      '/c.dart': '''
  import 'd.dart' as foo;
  import 'a.dart' as bar;
  export 'b.dart';
''',
      '/d.dart': '''
  import 'c.dart' as foo;
  import 'b.dart' as bar;
  export 'a.dart';
  part 'da.dart';
  part 'db.dart';
''',
      '/da.dart': '''
''',
      '/db.dart': '''
'''
    });
    computeResult(sources[0], LIBRARY_CYCLE);
    Map<ResultDescriptor, dynamic> results0 = outputs;
    computeResult(sources[1], LIBRARY_CYCLE);
    Map<ResultDescriptor, dynamic> results1 = outputs;
    computeResult(sources[4], LIBRARY_CYCLE);
    Map<ResultDescriptor, dynamic> results4 = outputs;
    computeResult(sources[5], LIBRARY_CYCLE);
    Map<ResultDescriptor, dynamic> results5 = outputs;

    List<LibraryElement> component0 = getLibraryCycle(results0);
    List<LibraryElement> component1 = getLibraryCycle(results1);
    List<LibraryElement> component4 = getLibraryCycle(results4);
    List<LibraryElement> component5 = getLibraryCycle(results5);

    expect(component0, hasLength(2));
    expect(component1, hasLength(2));
    expect(component4, hasLength(2));
    expect(component5, hasLength(2));

    List<LibrarySpecificUnit> units0 = getLibraryCycleUnits(results0);
    List<LibrarySpecificUnit> units1 = getLibraryCycleUnits(results1);
    List<LibrarySpecificUnit> units4 = getLibraryCycleUnits(results4);
    List<LibrarySpecificUnit> units5 = getLibraryCycleUnits(results5);
    expect(units0, hasLength(4));
    expect(units1, hasLength(4));
    expect(units4, hasLength(4));
    expect(units5, hasLength(4));

    List<LibrarySpecificUnit> dep0 = getLibraryCycleDependencies(results0);
    List<LibrarySpecificUnit> dep1 = getLibraryCycleDependencies(results1);
    List<LibrarySpecificUnit> dep4 = getLibraryCycleDependencies(results4);
    List<LibrarySpecificUnit> dep5 = getLibraryCycleDependencies(results5);
    expect(dep0, hasLength(1)); // dart:core
    expect(dep1, hasLength(1)); // dart:core
    expect(dep4, hasLength(5)); // dart:core, a.dart, aa.dart, ab.dart, b.dart
    expect(dep5, hasLength(5)); // dart:core, a.dart, aa.dart, ab.dart, b.dart
  }

  void _assertLibraryCycle(Source source, List<Source> expected) {
    computeResult(source, LIBRARY_CYCLE);
    List<LibraryElement> cycle = outputs[LIBRARY_CYCLE] as List<LibraryElement>;
    expect(cycle.map((e) => e.source), unorderedEquals(expected));
  }

  void _expectInvalid(Source librarySource) {
    CacheEntry entry = context.getCacheEntry(librarySource);
    expect(entry.getState(LIBRARY_CYCLE), CacheState.INVALID);
  }
}

@reflectiveTest
class ContainingLibrariesTaskTest extends _AbstractDartTaskTest {
  List<Source> getContainingLibraries(Map<ResultDescriptor, dynamic> outputs) {
    return outputs[CONTAINING_LIBRARIES] as List<Source>;
  }

  test_perform_definingCompilationUnit() {
    AnalysisTarget library = newSource('/test.dart', 'library test;');
    computeResult(library, INCLUDED_PARTS);
    computeResult(library, CONTAINING_LIBRARIES,
        matcher: isContainingLibrariesTask);
    expect(outputs, hasLength(1));
    List<Source> containingLibraries = getContainingLibraries(outputs);
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
    List<Source> containingLibraries = getContainingLibraries(outputs);
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
    List<Source> containingLibraries = getContainingLibraries(outputs);
    expect(containingLibraries, unorderedEquals([library]));
  }
}

@reflectiveTest
class DartErrorsTaskTest extends _AbstractDartTaskTest {
  List<AnalysisError> getDartErrors(Map<ResultDescriptor, dynamic> outputs) {
    return outputs[DART_ERRORS] as List<AnalysisError>;
  }

  test_perform_definingCompilationUnit() {
    AnalysisTarget library =
        newSource('/test.dart', 'library test; import "dart:math";');
    computeResult(library, INCLUDED_PARTS);
    computeResult(library, DART_ERRORS, matcher: isDartErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = getDartErrors(outputs);
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
    List<AnalysisError> errors = getDartErrors(outputs);
    // This should contain only the errors in the part file, not the ones in the
    // library.
    expect(errors, hasLength(1));
  }
}

@reflectiveTest
class EvaluateUnitConstantsTaskTest extends _AbstractDartTaskTest {
  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT12);
    expect(outputs[RESOLVED_UNIT12], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT12], isTrue);
  }

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
    computeResult(target, RESOLVED_UNIT12,
        matcher: isEvaluateUnitConstantsTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT12];
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

  test_perform_inBody() {
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

  test_perform_inComment_exportDirective() {
    Source source = newSource(
        '/test.dart',
        r'''
import 'dart:async';
/// Use [Future].
export 'dart:math';
''');
    _computeUsedElements(source);
    expect(usedElementNames, unorderedEquals(['Future']));
  }

  test_perform_inComment_importDirective() {
    Source source = newSource(
        '/test.dart',
        r'''
import 'dart:async';
/// Use [Future].
import 'dart:math';
''');
    _computeUsedElements(source);
    expect(usedElementNames, unorderedEquals(['Future']));
  }

  test_perform_inComment_libraryDirective() {
    Source source = newSource(
        '/test.dart',
        r'''
/// Use [Future].
library test;
import 'dart:async';
''');
    _computeUsedElements(source);
    expect(usedElementNames, unorderedEquals(['Future']));
  }

  test_perform_inComment_topLevelFunction() {
    Source source = newSource(
        '/test.dart',
        r'''
import 'dart:async';
/// Use [Future].
main() {}
''');
    _computeUsedElements(source);
    expect(usedElementNames, unorderedEquals(['Future']));
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

  test_perform_forPart_afterLibraryUpdate() {
    Source libSource = newSource(
        '/my_lib.dart',
        '''
library my_lib;
part 'my_part.dart';
foo() => null;
class _LocalClass {}
''');
    Source partSource = newSource(
        '/my_part.dart',
        '''
part of my_lib;
bar() {
  print(_LocalClass);
}
''');
    AnalysisTarget libTarget = new LibrarySpecificUnit(libSource, libSource);
    AnalysisTarget partTarget = new LibrarySpecificUnit(libSource, partSource);
    computeResult(libTarget, USED_LOCAL_ELEMENTS);
    computeResult(partTarget, USED_LOCAL_ELEMENTS);
    // _LocalClass is used in my_part.dart
    {
      UsedLocalElements usedElements =
          analysisCache.getValue(partTarget, USED_LOCAL_ELEMENTS);
      expect(usedElements.elements, contains(predicate((Element e) {
        return e.displayName == '_LocalClass';
      })));
    }
    // change my_lib.dart and recompute
    context.setContents(
        libSource,
        '''
library my_lib;
part 'my_part.dart';
String foo() => null;
class _LocalClass {}
''');
    computeResult(libTarget, USED_LOCAL_ELEMENTS);
    computeResult(partTarget, USED_LOCAL_ELEMENTS);
    // _LocalClass should still be used in my_part.dart
    {
      UsedLocalElements usedElements =
          analysisCache.getValue(partTarget, USED_LOCAL_ELEMENTS);
      expect(usedElements.elements, contains(predicate((Element e) {
        return e.displayName == '_LocalClass';
      })));
    }
  }

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
class GenerateLintsTaskTest extends _AbstractDartTaskTest {
  void enableLints() {
    AnalysisOptionsImpl options = context.analysisOptions;
    options.lint = true;
    context.analysisOptions = options;
  }

  @override
  void setUp() {
    super.setUp();
    enableLints();
    setLints(context, [new GenerateLintsTaskTest_TestLinter()]);
  }

  @override
  void tearDown() {
    setLints(context, []);
    super.tearDown();
  }

  test_camel_case_types() {
    Source source = newSource(
        '/test.dart',
        '''
class a { }
''');

    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, LINTS, matcher: isGenerateLintsTask);
    // validate
    _fillErrorListener(LINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[_testLintCode]);
  }
}

class GenerateLintsTaskTest_AstVisitor extends SimpleAstVisitor {
  Linter linter;
  GenerateLintsTaskTest_AstVisitor(this.linter);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (!new RegExp(r'^([_]*)([A-Z]+[a-z0-9]*)+$')
        .hasMatch(node.name.toString())) {
      linter.reporter.reportErrorForNode(_testLintCode, node, []);
    }
  }
}

class GenerateLintsTaskTest_TestLinter extends Linter {
  @override
  String get name => 'GenerateLintsTaskTest_TestLinter';

  @override
  AstVisitor getVisitor() => new GenerateLintsTaskTest_AstVisitor(this);
}

@reflectiveTest
class InferInstanceMembersInUnitTaskTest extends _AbstractDartTaskTest {
  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT10);
    expect(outputs[RESOLVED_UNIT10], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT10], isTrue);
  }

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
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT10,
        matcher: isInferInstanceMembersInUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT10];
    VariableDeclaration field = AstFinder.getFieldInClass(unit, 'B', 'f');
    MethodDeclaration method = AstFinder.getMethodInClass(unit, 'B', 'm');
    DartType typeX = resolutionMap
        .elementDeclaredByClassDeclaration(AstFinder.getClass(unit, 'X'))
        .type;
    DartType typeY = resolutionMap
        .elementDeclaredByClassDeclaration(AstFinder.getClass(unit, 'Y'))
        .type;
    DartType typeZ = resolutionMap
        .elementDeclaredByClassDeclaration(AstFinder.getClass(unit, 'Z'))
        .type;

    expect(
        resolutionMap.elementDeclaredByVariableDeclaration(field).type, typeX);
    expect(resolutionMap.elementDeclaredByMethodDeclaration(method).returnType,
        typeY);
    expect(
        resolutionMap
            .elementDeclaredByMethodDeclaration(method)
            .parameters[0]
            .type,
        typeZ);
  }

  void test_perform_cross_library_const() {
    enableStrongMode();
    AnalysisTarget firstSource = newSource(
        '/first.dart',
        '''
library first;

const a = 'hello';
''');
    AnalysisTarget secondSource = newSource(
        '/second.dart',
        '''
import 'first.dart';

const b = a;
class M {
   String c = a;
}
''');
    computeResult(
        new LibrarySpecificUnit(firstSource, firstSource), RESOLVED_UNIT10,
        matcher: isInferInstanceMembersInUnitTask);
    CompilationUnit firstUnit = outputs[RESOLVED_UNIT10];
    computeResult(
        new LibrarySpecificUnit(secondSource, secondSource), RESOLVED_UNIT10);
    CompilationUnit secondUnit = outputs[RESOLVED_UNIT10];

    VariableDeclaration variableA =
        AstFinder.getTopLevelVariable(firstUnit, 'a');
    VariableDeclaration variableB =
        AstFinder.getTopLevelVariable(secondUnit, 'b');
    VariableDeclaration variableC =
        AstFinder.getFieldInClass(secondUnit, 'M', 'c');
    InterfaceType stringType = context.typeProvider.stringType;

    expect(resolutionMap.elementDeclaredByVariableDeclaration(variableA).type,
        stringType);
    expect(resolutionMap.elementDeclaredByVariableDeclaration(variableB).type,
        stringType);
    expect(variableB.initializer.staticType, stringType);
    expect(resolutionMap.elementDeclaredByVariableDeclaration(variableC).type,
        stringType);
    expect(variableC.initializer.staticType, stringType);
  }

  void test_perform_reresolution() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
const topLevel = '';
class C {
  String field = topLevel;
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT10);
    CompilationUnit unit = outputs[RESOLVED_UNIT10];
    VariableDeclaration topLevelDecl =
        AstFinder.getTopLevelVariable(unit, 'topLevel');
    VariableDeclaration fieldDecl =
        AstFinder.getFieldInClass(unit, 'C', 'field');
    VariableElement topLevel = topLevelDecl.name.staticElement;
    VariableElement field = fieldDecl.name.staticElement;

    InterfaceType stringType = context.typeProvider.stringType;
    expect(topLevel.type, stringType);
    expect(field.type, stringType);
    expect(fieldDecl.initializer.staticType, stringType);
  }
}

@reflectiveTest
class InferStaticVariableTypesInUnitTaskTest extends _AbstractDartTaskTest {
  @override
  void setUp() {
    super.setUp();
    enableStrongMode();
  }

  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT8);
    expect(outputs[RESOLVED_UNIT8], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT8], isTrue);
  }

  void test_perform_const_field() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
class M {
  static const X = "";
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT8,
        matcher: isInferStaticVariableTypesInUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT8];
    VariableDeclaration declaration = AstFinder.getFieldInClass(unit, 'M', 'X');
    InterfaceType stringType = context.typeProvider.stringType;
    expect(resolutionMap.elementDeclaredByVariableDeclaration(declaration).type,
        stringType);
  }

  test_perform_hasParseError() {
    Source source = newSource(
        '/test.dart',
        r'''
@(i $=
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT8);
    expect(outputs[RESOLVED_UNIT8], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT8], isTrue);
  }

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
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT8,
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
        new LibrarySpecificUnit(firstSource, firstSource), RESOLVED_UNIT8,
        matcher: isInferStaticVariableTypesInUnitTask);
    CompilationUnit firstUnit = outputs[RESOLVED_UNIT8];
    computeResult(
        new LibrarySpecificUnit(secondSource, secondSource), RESOLVED_UNIT8);
    CompilationUnit secondUnit = outputs[RESOLVED_UNIT8];

    VariableDeclaration variableA =
        AstFinder.getTopLevelVariable(firstUnit, 'a');
    VariableDeclaration variableB =
        AstFinder.getTopLevelVariable(secondUnit, 'b');
    VariableDeclaration variableC =
        AstFinder.getTopLevelVariable(firstUnit, 'c');
    ClassDeclaration classM = AstFinder.getClass(secondUnit, 'M');
    DartType typeM =
        resolutionMap.elementDeclaredByClassDeclaration(classM).type;

    expect(resolutionMap.elementDeclaredByVariableDeclaration(variableA).type,
        typeM);
    expect(resolutionMap.elementDeclaredByVariableDeclaration(variableB).type,
        typeM);
    expect(variableB.initializer.staticType, typeM);
    expect(resolutionMap.elementDeclaredByVariableDeclaration(variableC).type,
        typeM);
    expect(variableC.initializer.staticType, typeM);
  }

  void test_perform_simple() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var X = 1;
var Y = () => 1 + X;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT8,
        matcher: isInferStaticVariableTypesInUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT8];
    TopLevelVariableDeclaration declaration = unit.declarations[1];
    FunctionExpression function =
        declaration.variables.variables[0].initializer;
    ExpressionFunctionBody body = function.body;
    Expression expression = body.expression;
    InterfaceType intType = context.typeProvider.intType;
    expect(expression.staticType, intType);
  }

  test_staticModeHints_forStaticVariableInference() {
    context.analysisOptions =
        new AnalysisOptionsImpl.from(context.analysisOptions)
          ..strongModeHints = true;
    Source source = newSource(
        '/test.dart',
        r'''
var V = [42];
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT8);
    expect(outputs[RESOLVED_UNIT8], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT8], isTrue);
    // An INFERRED_TYPE_LITERAL error should be generated.
    List<AnalysisError> errors =
        outputs[STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT]
            as List<AnalysisError>;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StrongModeCode.INFERRED_TYPE_LITERAL);
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
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableDeclaration declaration =
        AstFinder.getFieldInClass(unit, 'C', 'field');
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
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableDeclaration declaration =
        AstFinder.getTopLevelVariable(unit, 'topLevel');
    VariableElement variable = declaration.name.staticElement;
    InferStaticVariableTypeTask inferTask =
        new InferStaticVariableTypeTask(task.context, variable);
    expect(inferTask.getDeclaration(unit), declaration);
  }

  void test_perform() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test3.dart',
        '''
var topLevel3 = '';
class C {
  var field3 = topLevel3;
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableDeclaration topLevelDecl =
        AstFinder.getTopLevelVariable(unit, 'topLevel3');
    VariableDeclaration fieldDecl =
        AstFinder.getFieldInClass(unit, 'C', 'field3');
    VariableElement topLevel = topLevelDecl.name.staticElement;
    VariableElement field = fieldDecl.name.staticElement;

    computeResult(field, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    InterfaceType stringType = context.typeProvider.stringType;
    expect(topLevel.type, stringType);
    expect(field.type, stringType);
    expect(fieldDecl.initializer.staticType, stringType);
  }

  void test_perform_const() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
const topLevel = "hello";
class C {
  var field = topLevel;
}
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableElement topLevel =
        AstFinder.getTopLevelVariable(unit, 'topLevel').name.staticElement;
    VariableElement field =
        AstFinder.getFieldInClass(unit, 'C', 'field').name.staticElement;

    computeResult(field, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    InterfaceType stringType = context.typeProvider.stringType;
    expect(topLevel.type, stringType);
    expect(field.type, stringType);
  }

  void test_perform_cycle() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var piFirst = true;
var pi = piFirst ? 3.14 : tau / 2;
var tau = piFirst ? pi * 2 : 6.28;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableElement piFirst =
        AstFinder.getTopLevelVariable(unit, 'piFirst').name.staticElement;
    VariableElement pi =
        AstFinder.getTopLevelVariable(unit, 'pi').name.staticElement;
    VariableElement tau =
        AstFinder.getTopLevelVariable(unit, 'tau').name.staticElement;

    computeResult(piFirst, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    expect(piFirst.type, context.typeProvider.boolType);
    expect(pi.type.isDynamic, isTrue);
    expect(tau.type.isDynamic, isTrue);
  }

  void test_perform_error() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var a = '' / null;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableElement a =
        AstFinder.getTopLevelVariable(unit, 'a').name.staticElement;

    computeResult(a, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    expect(a.type.isDynamic, isTrue);
  }

  void test_perform_null() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var a = null;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT7);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    VariableElement a =
        AstFinder.getTopLevelVariable(unit, 'a').name.staticElement;

    computeResult(a, INFERRED_STATIC_VARIABLE,
        matcher: isInferStaticVariableTypeTask);
    expect(a.type.isDynamic, isTrue);
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
  List<AnalysisError> getLibraryUnitErrors(
      Map<ResultDescriptor, dynamic> outputs) {
    return outputs[LIBRARY_UNIT_ERRORS] as List<AnalysisError>;
  }

  test_perform_definingCompilationUnit() {
    AnalysisTarget library =
        newSource('/test.dart', 'library test; import "dart:math";');
    computeResult(
        new LibrarySpecificUnit(library, library), LIBRARY_UNIT_ERRORS,
        matcher: isLibraryUnitErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = getLibraryUnitErrors(outputs);
    expect(errors, hasLength(1));
  }

  test_perform_partInSingleLibrary() {
    AnalysisTarget library =
        newSource('/lib.dart', 'library test; part "part.dart";');
    AnalysisTarget part = newSource('/part.dart', 'part of test;');
    computeResult(new LibrarySpecificUnit(library, part), LIBRARY_UNIT_ERRORS,
        matcher: isLibraryUnitErrorsTask);
    expect(outputs, hasLength(1));
    List<AnalysisError> errors = getLibraryUnitErrors(outputs);
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
    expect(outputs, hasLength(10));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[LIBRARY_SPECIFIC_UNITS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[REFERENCED_SOURCES], hasLength(2));
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
    expect(outputs, hasLength(10));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[LIBRARY_SPECIFIC_UNITS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[REFERENCED_SOURCES], hasLength(2));
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
    expect(outputs[UNITS], hasLength(1));
  }

  test_perform_flushTokenStream() {
    _performParseTask(r'''
class Test {}
''');
    expect(analysisCache.getState(source, TOKEN_STREAM), CacheState.FLUSHED);
  }

  test_perform_invalidDirectives() {
    _performParseTask(r'''
library lib;
import '/does/not/exist.dart';
import '://invaliduri.dart';
export '${a}lib3.dart';
part 'part.dart';
class A {}''');
    expect(outputs, hasLength(10));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[LIBRARY_SPECIFIC_UNITS], hasLength(2));
    expect(outputs[PARSE_ERRORS], hasLength(2));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[REFERENCED_SOURCES], hasLength(4));
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
    expect(outputs, hasLength(10));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(1));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(1));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[LIBRARY_SPECIFIC_UNITS], hasLength(2));
    if (fe.Scanner.useFasta) {
      // Missing closing brace error is reported by the Fasta scanner.
      expect(outputs[PARSE_ERRORS], hasLength(0));
    } else {
      expect(outputs[PARSE_ERRORS], hasLength(1));
    }
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[REFERENCED_SOURCES], hasLength(5));
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
    expect(outputs[UNITS], hasLength(2));
  }

  test_perform_library_configurations_bool1() {
    context.declaredVariables.define('dart.library.io', 'true');
    newSource('/foo.dart', '');
    newSource('/foo_io.dart', '');
    newSource('/foo_html.dart', '');
    newSource('/bar.dart', '');
    newSource('/bar_io.dart', '');
    newSource('/bar_html.dart', '');
    _performParseTask(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
export 'bar.dart'
  if (dart.library.io) 'bar_io.dart'
  if (dart.library.html) 'bar_html.dart';
''');
    var unit = outputs[PARSED_UNIT] as CompilationUnit;

    var imported = outputs[IMPORTED_LIBRARIES] as List<Source>;
    _assertContainsOnlyShortName(imported, 'foo_io.dart');

    var import = unit.directives[0] as ImportDirective;
    expect(import.uriSource.shortName, 'foo.dart');
    expect(import.selectedSource.shortName, 'foo_io.dart');
    expect(import.configurations[0].uriSource.shortName, 'foo_io.dart');
    expect(import.configurations[1].uriSource.shortName, 'foo_html.dart');

    var exported = outputs[EXPORTED_LIBRARIES] as List<Source>;
    _assertContainsOnlyShortName(exported, 'bar_io.dart');

    var export = unit.directives[1] as ExportDirective;
    expect(export.uriSource.shortName, 'bar.dart');
    expect(export.selectedSource.shortName, 'bar_io.dart');
    expect(export.configurations[0].uriSource.shortName, 'bar_io.dart');
    expect(export.configurations[1].uriSource.shortName, 'bar_html.dart');

    var refSources = outputs[REFERENCED_SOURCES] as List<Source>;
    var refNames = refSources.map((source) => source.shortName).toList();
    expect(refNames, contains('test.dart'));
    expect(refNames, contains('foo.dart'));
    expect(refNames, contains('foo_io.dart'));
    expect(refNames, contains('foo_html.dart'));
    expect(refNames, contains('bar.dart'));
    expect(refNames, contains('bar_io.dart'));
    expect(refNames, contains('bar_html.dart'));
  }

  test_perform_library_configurations_bool2() {
    context.declaredVariables.define('dart.library.html', 'true');
    newSource('/foo.dart', '');
    newSource('/foo_io.dart', '');
    newSource('/foo_html.dart', '');
    _performParseTask(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var imported = outputs[IMPORTED_LIBRARIES] as List<Source>;
    _assertContainsOnlyShortName(imported, 'foo_html.dart');
  }

  test_perform_library_configurations_default() {
    context.declaredVariables.define('dart.library.io', 'false');
    newSource('/foo.dart', '');
    newSource('/foo_io.dart', '');
    newSource('/foo_html.dart', '');
    _performParseTask(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var imported = outputs[IMPORTED_LIBRARIES] as List<Source>;
    _assertContainsOnlyShortName(imported, 'foo.dart');
  }

  test_perform_library_configurations_preferFirst() {
    context.declaredVariables.define('dart.library.io', 'true');
    context.declaredVariables.define('dart.library.html', 'true');
    newSource('/foo.dart', '');
    newSource('/foo_io.dart', '');
    newSource('/foo_html.dart', '');
    _performParseTask(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');

    var imported = outputs[IMPORTED_LIBRARIES] as List<Source>;
    _assertContainsOnlyShortName(imported, 'foo_io.dart');

    var unit = outputs[PARSED_UNIT] as CompilationUnit;
    var import = unit.directives[0] as ImportDirective;
    expect(import.uriSource.shortName, 'foo.dart');
    expect(import.selectedSource.shortName, 'foo_io.dart');
    expect(import.configurations[0].uriSource.shortName, 'foo_io.dart');
    expect(import.configurations[1].uriSource.shortName, 'foo_html.dart');
  }

  test_perform_library_configurations_value() {
    context.declaredVariables.define('dart.platform', 'Windows');
    newSource('/foo.dart', '');
    newSource('/foo_posix.dart', '');
    newSource('/foo_windows.dart', '');
    _performParseTask(r'''
import 'foo.dart'
  if (dart.platform == 'Posix') 'foo_posix.dart'
  if (dart.platform == 'Windows') 'foo_windows.dart';
''');
    var imported = outputs[IMPORTED_LIBRARIES] as List<Source>;
    _assertContainsOnlyShortName(imported, 'foo_windows.dart');
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
    expect(outputs, hasLength(10));
    expect(outputs[EXPLICITLY_IMPORTED_LIBRARIES], hasLength(0));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[LIBRARY_SPECIFIC_UNITS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[REFERENCED_SOURCES], hasLength(2));
    expect(outputs[SOURCE_KIND], SourceKind.PART);
    expect(outputs[UNITS], hasLength(1));
  }

  /**
   * Assert that [sources] contains either just a source with the given
   * [expectedShortName], or it and the `dart:core` source.
   */
  void _assertContainsOnlyShortName(
      List<Source> sources, String expectedShortName) {
    Iterable<String> shortNames = sources.map((s) => s.shortName);
    if (shortNames.length == 2) {
      expect(shortNames, unorderedEquals(['core.dart', expectedShortName]));
    } else {
      expect(shortNames, unorderedEquals([expectedShortName]));
    }
  }

  void _performParseTask(String content) {
    if (content == null) {
      source = resourceProvider
          .getFile(resourceProvider.convertPath('/test.dart'))
          .createSource();
    } else {
      source = newSource('/test.dart', content);
    }
    computeResult(source, PARSED_UNIT, matcher: isParseDartTask);
  }

  static void _assertHasCore(dynamic sourceList, int lenght) {
    List<Source> sources = sourceList as List<Source>;
    expect(sources, hasLength(lenght));
    expect(sources, contains(predicate((Source s) {
      return s.fullName.endsWith('core.dart');
    })));
  }
}

@reflectiveTest
class PartiallyResolveUnitReferencesTaskTest extends _AbstractDartTaskTest {
  test_perform_strong_importExport() {
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
    computeResult(new LibrarySpecificUnit(sourceC, sourceC), RESOLVED_UNIT7,
        matcher: isPartiallyResolveUnitReferencesTask);
    // validate
    expect(outputs[INFERABLE_STATIC_VARIABLES_IN_UNIT], hasLength(0));
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
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

  test_perform_strong_inferable() {
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
    computeResult(target, RESOLVED_UNIT7,
        matcher: isPartiallyResolveUnitReferencesTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    // INFERABLE_STATIC_VARIABLES_IN_UNIT
    {
      List<VariableElement> variables =
          outputs[INFERABLE_STATIC_VARIABLES_IN_UNIT] as List<VariableElement>;
      expect(variables, hasLength(4));
      expect(variables.map((v) => v.displayName),
          unorderedEquals(['a', 'b', 'd', 'f']));
    }
    // Test the state of the AST
    TopLevelVariableDeclaration a = unit.declarations[0];
    VariableDeclaration variableA = a.variables.variables[0];
    SimpleIdentifier initializer = variableA.initializer;
    expect(initializer.staticElement, isNotNull);
  }

  test_perform_strong_notResolved() {
    enableStrongMode();
    Source source = newSource(
        '/test.dart',
        '''
int A;
f1() {
  A;
}
var f2 = () {
  A;
  void f3() {
    A;
  }
}
class C {
  C() {
    A;
  }
  m() {
    A;
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT7,
        matcher: isPartiallyResolveUnitReferencesTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT7];
    NodeList<CompilationUnitMember> declarations = unit.declarations;

    void expectReference(BlockFunctionBody body, bool isResolved) {
      ExpressionStatement statement = body.block.statements[0];
      SimpleIdentifier reference = statement.expression;
      expect(reference.staticElement, isResolved ? isNotNull : isNull);
    }

    //
    // The reference to 'A' in 'f1' should not be resolved.
    //
    FunctionDeclaration f1 = declarations[1];
    expectReference(f1.functionExpression.body, false);
    //
    // The references to 'A' in 'f2' should be resolved.
    //
    TopLevelVariableDeclaration f2 = declarations[2];
    FunctionExpression expression2 = f2.variables.variables[0].initializer;
    BlockFunctionBody body2 = expression2.body;
    expectReference(body2, true);

    FunctionDeclarationStatement statement2 = body2.block.statements[1];
    BlockFunctionBody innerBody =
        statement2.functionDeclaration.functionExpression.body;
    expectReference(innerBody, true);
    //
    // The references to 'A' in 'C' should not be resolved.
    //
    ClassDeclaration c = declarations[3];
    NodeList<ClassMember> members = c.members;

    ConstructorDeclaration constructor = members[0];
    expectReference(constructor.body, false);

    MethodDeclaration method = members[1];
    expectReference(method.body, false);
  }
}

@reflectiveTest
class ResolveDirectiveElementsTaskTest extends _AbstractDartTaskTest {
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
    LibrarySpecificUnit targetA = new LibrarySpecificUnit(sourceA, sourceA);
    // build directive elements
    computeResult(sourceA, LIBRARY_ELEMENT2,
        matcher: isBuildDirectiveElementsTask);
    // prepare outputs
    LibraryElement libraryElementA = outputs[LIBRARY_ELEMENT2];
    LibraryElement libraryElementB = libraryElementA.imports[0].importedLibrary;
    LibraryElement libraryElementC = libraryElementA.exports[0].exportedLibrary;
    // clear elements in directive ASTs
    {
      CompilationUnit unitA = context.getResult(targetA, RESOLVED_UNIT1);
      unitA.directives[1].element = null;
      unitA.directives[2].element = null;
    }
    // resolve directive ASTs
    computeResult(targetA, RESOLVED_UNIT2,
        matcher: isResolveDirectiveElementsTask);
    // validate that directive ASTs have elements
    CompilationUnit unitA = context.getResult(targetA, RESOLVED_UNIT2);
    {
      ImportDirective importNode = unitA.directives[1];
      ImportElement importElement = importNode.element;
      expect(importElement, isNotNull);
      expect(importElement.importedLibrary, libraryElementB);
    }
    {
      ExportDirective exportNode = unitA.directives[2];
      ExportElement exportElement = exportNode.element;
      expect(exportElement, isNotNull);
      expect(exportElement.exportedLibrary, libraryElementC);
    }
  }
}

@reflectiveTest
class ResolveInstanceFieldsInUnitTaskTest extends _AbstractDartTaskTest {
  @override
  void setUp() {
    super.setUp();
    enableStrongMode();
  }

  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT9);
    expect(outputs[RESOLVED_UNIT9], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT9], isTrue);
  }

  /**
   * Test inference of instance fields across units
   */
  void test_perform_inference_cross_unit_instance() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
          class A {
            final a2 = new B().b2;
          }
      ''',
      '/b.dart': '''
          class B {
            final b2 = 1;
          }
      ''',
      '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            x = new A().a2;
          }
    '''
    });
    InterfaceType intType = context.typeProvider.intType;
    DartType dynamicType = context.typeProvider.dynamicType;

    computeResult(
        new LibrarySpecificUnit(sources[1], sources[1]), RESOLVED_UNIT9);
    CompilationUnit unit1 = outputs[RESOLVED_UNIT9];

    // B.b2 shoud be resolved on the rhs, but not yet inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), dynamicType, intType);

    computeResult(
        new LibrarySpecificUnit(sources[0], sources[0]), RESOLVED_UNIT9);
    CompilationUnit unit0 = outputs[RESOLVED_UNIT9];

    // B.b2 should now be fully resolved and inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), intType, intType);

    // A.a2 should now be resolved on the rhs, but not yet inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, intType);

    computeResult(
        new LibrarySpecificUnit(sources[2], sources[2]), RESOLVED_UNIT9);

    // A.a2 should now be fully resolved and inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), intType, intType);
  }

  /**
   * Test inference of instance fields across units
   */
  void test_perform_inference_cross_unit_instance_cyclic() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
          class A {
            final a2 = new B().b2;
          }
      ''',
      '/b.dart': '''
          import 'a.dart';
          class B {
            final b2 = 1;
          }
      ''',
      '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            x = new A().a2;
          }
    '''
    });
    DartType dynamicType = context.typeProvider.dynamicType;

    computeResult(
        new LibrarySpecificUnit(sources[0], sources[0]), RESOLVED_UNIT9);
    CompilationUnit unit0 = outputs[RESOLVED_UNIT9];

    // A.a2 should now be resolved on the rhs, but not yet inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, dynamicType);

    computeResult(
        new LibrarySpecificUnit(sources[2], sources[2]), RESOLVED_UNIT9);

    // A.a2 should now be fully resolved and inferred (but not re-resolved).
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, dynamicType);
  }

  /**
   * Test inference of instance fields across units with cycles
   */
  void test_perform_inference_cross_unit_static_instance() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
          class A {
            static final a1 = B.b1;
            final a2 = new B().b2;
          }
      ''',
      '/b.dart': '''
          class B {
            static final b1 = 1;
            final b2 = 1;
          }
      ''',
      '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            // inference in A now works.
            x = A.a1;
            x = new A().a2;
          }
    '''
    });
    InterfaceType intType = context.typeProvider.intType;
    DartType dynamicType = context.typeProvider.dynamicType;

    computeResult(
        new LibrarySpecificUnit(sources[1], sources[1]), RESOLVED_UNIT9);
    CompilationUnit unit1 = outputs[RESOLVED_UNIT9];

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), dynamicType, intType);

    computeResult(
        new LibrarySpecificUnit(sources[0], sources[0]), RESOLVED_UNIT9);
    CompilationUnit unit0 = outputs[RESOLVED_UNIT9];

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), intType, intType);

    computeResult(
        new LibrarySpecificUnit(sources[2], sources[2]), RESOLVED_UNIT9);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), intType, intType);
  }

  /**
   * Test inference between static and instance fields
   */
  void test_perform_inference_instance() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
          class A {
            final a2 = new B().b2;
          }

          class B {
            final b2 = 1;
          }
      ''',
      '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            x = new A().a2;
          }
    '''
    });
    InterfaceType intType = context.typeProvider.intType;
    DartType dynamicType = context.typeProvider.dynamicType;

    computeResult(
        new LibrarySpecificUnit(sources[0], sources[0]), RESOLVED_UNIT9);
    CompilationUnit unit0 = outputs[RESOLVED_UNIT9];

    // A.a2 should now be resolved on the rhs, but not yet inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, dynamicType);

    // B.b2 shoud be resolved on the rhs, but not yet inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "B", "b2"), dynamicType, intType);

    computeResult(
        new LibrarySpecificUnit(sources[1], sources[1]), RESOLVED_UNIT9);

    // A.a2 should now be fully resolved and inferred (but not re-resolved).
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, dynamicType);

    // B.b2 should now be fully resolved and inferred.
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "B", "b2"), intType, intType);
  }
}

@reflectiveTest
class ResolveLibraryTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source sourceLib = newSource(
        '/my_lib.dart',
        '''
library my_lib;
const a = new A();
class A {
  const A();
}
@a
class C {}
''');
    computeResult(sourceLib, LIBRARY_ELEMENT, matcher: isResolveLibraryTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT];
    ClassElement classC = library.getType('C');
    List<ElementAnnotation> metadata = classC.metadata;
    expect(metadata, hasLength(1));
    ElementAnnotation annotation = metadata[0];
    expect(annotation, isNotNull);
    expect((annotation as ElementAnnotationImpl).evaluationResult, isNotNull);
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
    computeResult(sourceLib, LIBRARY_ELEMENT6,
        matcher: isResolveLibraryTypeNamesTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT6];
    {
      ClassElement classB = library.getType('B');
      expect(classB.supertype.displayName, 'A');
    }
    {
      ClassElement classC = library.getType('C');
      expect(classC.supertype.displayName, 'A');
    }
    expect(library.loadLibraryFunction, isNotNull);
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
    computeResult(sourceA, LIBRARY_ELEMENT6,
        matcher: isResolveLibraryTypeNamesTask);
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT6];
    {
      ClassElement clazz = library.getType('A');
      expect(clazz.displayName, 'A');
      clazz = clazz.supertype.element;
      expect(clazz.displayName, 'B');
    }
  }
}

@reflectiveTest
class ResolveTopLevelUnitTypeBoundsTaskTest extends _AbstractDartTaskTest {
  test_perform_boundIsGenericType() {
    Source source = newSource(
        '/test.dart',
        '''
class C<T extends Map<String, List<int>>> {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveTopLevelUnitTypeBoundsTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    ClassDeclaration nodeC = unit.declarations[0];
    _assertTypeParameterBound(nodeC.typeParameters.typeParameters[0],
        'Map<String, List<int>>', 'Map');
  }

  test_perform_errors() {
    Source source = newSource(
        '/test.dart',
        '''
class C<T extends NoSuchClass> {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVE_TYPE_BOUNDS_ERRORS,
        matcher: isResolveTopLevelUnitTypeBoundsTask);
    // validate
    _fillErrorListener(RESOLVE_TYPE_BOUNDS_ERRORS);
    errorListener
        .assertErrorsWithCodes(<ErrorCode>[StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_perform_ignoreBoundsOfBounds() {
    Source source = newSource(
        '/test.dart',
        '''
class A<T1 extends num> {}
class B<T2 extends A> {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveTopLevelUnitTypeBoundsTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    ClassDeclaration nodeB = unit.declarations[1];
    _assertTypeParameterBound(
        nodeB.typeParameters.typeParameters[0], 'A<dynamic>', 'A');
  }

  test_perform_outputs() {
    Source source = newSource(
        '/test.dart',
        r'''
class C<T extends int> {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4);
    expect(outputs[RESOLVED_UNIT4], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT4], isTrue);
    expect(outputs[RESOLVE_TYPE_BOUNDS_ERRORS], isNotNull);
  }

  test_perform_unitMember_ClassDeclaration() {
    Source source = newSource(
        '/test.dart',
        '''
class C<T extends int> extends Object {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveTopLevelUnitTypeBoundsTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    ClassDeclaration nodeC = unit.declarations[0];
    // 'extends Object' is not resolved
    expect(nodeC.extendsClause.superclass.name.staticElement, isNull);
    // but 'T extends int' is resolved
    _assertTypeParameterBound(
        nodeC.typeParameters.typeParameters[0], 'int', 'int');
  }

  test_perform_unitMember_ClassTypeAlias() {
    Source source = newSource(
        '/test.dart',
        '''
class C<T extends double> = Object;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveTopLevelUnitTypeBoundsTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    ClassTypeAlias nodeC = unit.declarations[0];
    // '= Object' is not resolved
    expect(nodeC.superclass.name.staticElement, isNull);
    // but 'T extends int' is resolved
    _assertTypeParameterBound(
        nodeC.typeParameters.typeParameters[0], 'double', 'double');
  }

  test_perform_unitMember_FunctionTypeAlias() {
    Source source = newSource(
        '/test.dart',
        '''
typedef F<T extends String>();
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT4,
        matcher: isResolveTopLevelUnitTypeBoundsTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
    FunctionTypeAlias nodeF = unit.declarations[0];
    // but 'T extends String' is resolved
    _assertTypeParameterBound(
        nodeF.typeParameters.typeParameters[0], 'String', 'String');
  }

  void _assertTypeParameterBound(TypeParameter typeParameter,
      String expectedBoundTypeString, String expectedBoundElementName) {
    TypeAnnotation bound = typeParameter.bound;
    // TODO(brianwilkerson) Extend this to support function types as bounds.
    expect(bound, new isInstanceOf<TypeName>());
    TypeName boundNode = bound;
    Identifier boundName = boundNode.name;
    expect(boundNode.type.toString(), expectedBoundTypeString);
    expect(boundName.staticType.toString(), expectedBoundTypeString);
    expect(resolutionMap.staticElementForIdentifier(boundName).displayName,
        expectedBoundElementName);
  }
}

@reflectiveTest
class ResolveUnitTaskTest extends _AbstractDartTaskTest {
  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT11);
    expect(outputs[RESOLVED_UNIT11], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT11], isTrue);
  }

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
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11,
        matcher: isResolveUnitTask);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];

    FunctionDeclaration f = unit.declarations[0];
    _assertResolved(f.functionExpression.body);

    MethodDeclaration m = (unit.declarations[1] as ClassDeclaration).members[0];
    _assertResolved(m.body);

    expect(outputs[RESOLVE_UNIT_ERRORS], hasLength(0));
  }

  void _assertResolved(FunctionBody body) {
    ResolutionVerifier verifier = new ResolutionVerifier();
    body.accept(verifier);
    verifier.assertResolved();
  }
}

@reflectiveTest
class ResolveUnitTypeNamesTaskTest extends _AbstractDartTaskTest {
  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT5);
    expect(outputs[RESOLVED_UNIT5], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT5], isTrue);
  }

  test_perform() {
    Source source = newSource(
        '/test.dart',
        '''
class A {}
class B extends A {}
int f(String p) => p.length;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT5, matcher: isResolveUnitTypeNamesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    {
      ClassDeclaration nodeA = unit.declarations[0];
      ClassDeclaration nodeB = unit.declarations[1];
      DartType extendsType = nodeB.extendsClause.superclass.type;
      expect(extendsType,
          resolutionMap.elementDeclaredByClassDeclaration(nodeA).type);
    }
    {
      FunctionDeclaration functionNode = unit.declarations[2];
      DartType returnType = functionNode.returnType.type;
      List<FormalParameter> parameters =
          functionNode.functionExpression.parameters.parameters;
      expect(returnType.displayName, 'int');
      expect(
          resolutionMap
              .elementDeclaredByFormalParameter(parameters[0])
              .type
              .displayName,
          'String');
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
    computeResult(target, RESOLVED_UNIT5, matcher: isResolveUnitTypeNamesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    FunctionTypeAlias nodeF = unit.declarations[0];
    FunctionTypeAlias nodeG = unit.declarations[1];
    {
      FormalParameter parameter = nodeF.parameters.parameters[0];
      DartType parameterType =
          resolutionMap.elementDeclaredByFormalParameter(parameter).type;
      Element returnTypeElement =
          resolutionMap.typeForTypeName(nodeF.returnType).element;
      expect(returnTypeElement.displayName, 'int');
      expect(parameterType.element, nodeG.element);
    }
    {
      FormalParameter parameter = nodeG.parameters.parameters[0];
      DartType parameterType =
          resolutionMap.elementDeclaredByFormalParameter(parameter).type;
      expect(
          resolutionMap.typeForTypeName(nodeG.returnType).element.displayName,
          'String');
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
  void expectMutated(FunctionBody body, VariableElement variable,
      bool mutatedInClosure, bool mutatedInScope) {
    expect(body.isPotentiallyMutatedInClosure(variable), mutatedInClosure);
    expect(body.isPotentiallyMutatedInScope(variable), mutatedInScope);
  }

  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT6);
    expect(outputs[RESOLVED_UNIT6], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT6], isTrue);
  }

  test_perform_buildClosureLibraryElements() {
    Source source = newSource(
        '/test.dart',
        '''
main() {
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT6,
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
    computeResult(target, RESOLVED_UNIT6,
        matcher: isResolveVariableReferencesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT6];
    FunctionDeclaration mainDeclaration = unit.declarations[0];
    FunctionBody body = mainDeclaration.functionExpression.body;
    FunctionElement main = mainDeclaration.element;
    expectMutated(body, main.localVariables[0], false, false);
    expectMutated(body, main.localVariables[1], false, true);
    expectMutated(body, main.localVariables[2], true, true);
    expectMutated(body, main.localVariables[3], true, true);
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
    computeResult(target, RESOLVED_UNIT6,
        matcher: isResolveVariableReferencesTask);
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT6];
    FunctionDeclaration mainDeclaration = unit.declarations[0];
    FunctionBody body = mainDeclaration.functionExpression.body;
    FunctionElement main = mainDeclaration.element;
    expectMutated(body, main.parameters[0], false, false);
    expectMutated(body, main.parameters[1], false, true);
    expectMutated(body, main.parameters[2], true, true);
    expectMutated(body, main.parameters[3], true, true);
  }
}

@reflectiveTest
class ScanDartTaskTest extends _AbstractDartTaskTest {
  test_ignore_info() {
    _performScanTask('''
//ignore: error_code
//ignore_for_file: error_code
var x = '';
foo(); // ignore:   error_code_2
bar(); //ignore: error_code, error_code_2
// ignore_for_file:  error_code_2, error_code_3
''');

    IgnoreInfo info = outputs[IGNORE_INFO];
    expect(info.ignores.keys, hasLength(3));
    expect(info.ignores[1].first, 'error_code');
    expect(info.ignores[4].first, 'error_code_2');
    expect(info.ignores[5], unorderedEquals(['error_code', 'error_code_2']));
    expect(info.ignoreForFiles,
        unorderedEquals(['error_code', 'error_code_2', 'error_code_3']));
  }

  test_perform_errors() {
    _performScanTask('import "');
    expect(outputs, hasLength(4));
    expect(outputs[LINE_INFO], isNotNull);
    expect(outputs[SCAN_ERRORS], hasLength(1));
    expect(outputs[TOKEN_STREAM], isNotNull);
    IgnoreInfo ignoreInfo = outputs[IGNORE_INFO];
    expect(ignoreInfo, isNotNull);
    expect(ignoreInfo.hasIgnores, isFalse);
  }

  test_perform_library() {
    _performScanTask(r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''');
    expect(outputs, hasLength(4));
    expect(outputs[LINE_INFO], isNotNull);
    // Missing closing brace error is reported by the Fasta scanner.
    expect(outputs[SCAN_ERRORS], hasLength(fe.Scanner.useFasta ? 1 : 0));
    expect(outputs[TOKEN_STREAM], isNotNull);
    IgnoreInfo ignoreInfo = outputs[IGNORE_INFO];
    expect(ignoreInfo, isNotNull);
    expect(ignoreInfo.hasIgnores, isFalse);
  }

  test_perform_noErrors() {
    _performScanTask('class A {}');
    expect(outputs, hasLength(4));
    expect(outputs[LINE_INFO], isNotNull);
    expect(outputs[SCAN_ERRORS], hasLength(0));
    expect(outputs[TOKEN_STREAM], isNotNull);
    IgnoreInfo ignoreInfo = outputs[IGNORE_INFO];
    expect(ignoreInfo, isNotNull);
    expect(ignoreInfo.hasIgnores, isFalse);
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
    if (fe.Scanner.useFasta) {
      // Missing closing brace error is reported by Fasta scanner.
      expect(outputs[SCAN_ERRORS], hasLength(1));
    } else {
      expect(outputs[SCAN_ERRORS], isEmpty);
    }
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
class StrongModeInferenceTest extends _AbstractDartTaskTest {
  @override
  void setUp() {
    super.setUp();
    enableStrongMode();
  }

  // Check that even within a static variable cycle, inferred
  // types get propagated to the members of the cycle.
  void test_perform_cycle() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
var piFirst = true;
var pi = piFirst ? 3.14 : tau / 2;
var tau = piFirst ? pi * 2 : 6.28;
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];
    VariableElement piFirst =
        AstFinder.getTopLevelVariable(unit, 'piFirst').name.staticElement;
    VariableElement pi =
        AstFinder.getTopLevelVariable(unit, 'pi').name.staticElement;
    VariableElement tau =
        AstFinder.getTopLevelVariable(unit, 'tau').name.staticElement;
    Expression piFirstUse = (AstFinder
            .getTopLevelVariable(unit, 'tau')
            .initializer as ConditionalExpression)
        .condition;

    expect(piFirstUse.staticType, context.typeProvider.boolType);
    expect(piFirst.type, context.typeProvider.boolType);
    expect(pi.type.isDynamic, isTrue);
    expect(tau.type.isDynamic, isTrue);
  }

  void test_perform_inference_cross_unit_cyclic() {
    AnalysisTarget firstSource = newSource(
        '/a.dart',
        '''
          import 'test.dart';
          var x = 2;
          class A { static var x = 2; }
''');
    AnalysisTarget secondSource = newSource(
        '/test.dart',
        '''
          import 'a.dart';
          var y = x;
          class B { static var y = A.x; }

          test1() {
            int t = 3;
            t = x;
            t = y;
            t = A.x;
            t = B.y;
          }
''');
    computeResult(
        new LibrarySpecificUnit(firstSource, firstSource), RESOLVED_UNIT11);
    CompilationUnit unit1 = outputs[RESOLVED_UNIT11];
    computeResult(
        new LibrarySpecificUnit(secondSource, secondSource), RESOLVED_UNIT11);
    CompilationUnit unit2 = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;

    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit1, "x"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "A", "x"), intType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit2, "y"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit2, "B", "y"), intType, intType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit2, "test1");

    assertAssignmentStatementTypes(statements[1], intType, intType);
    assertAssignmentStatementTypes(statements[2], intType, intType);
    assertAssignmentStatementTypes(statements[3], intType, intType);
    assertAssignmentStatementTypes(statements[4], intType, intType);
  }

  // Test that local variables in method bodies are inferred appropriately
  void test_perform_inference_cross_unit_instance() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
          class A {
            final a2 = new B().b2;
          }
      ''',
      '/b.dart': '''
          class B {
            final b2 = 1;
          }
      ''',
      '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            x = new A().a2;
          }
    '''
    });
    List<dynamic> units =
        computeLibraryResults(sources, RESOLVED_UNIT11).toList();
    CompilationUnit unit0 = units[0];
    CompilationUnit unit1 = units[1];
    CompilationUnit unit2 = units[2];

    InterfaceType intType = context.typeProvider.intType;
    DartType dynamicType = context.typeProvider.dynamicType;

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), intType, intType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit2, "test1");

    assertAssignmentStatementTypes(statements[1], intType, dynamicType);
  }

  // Test inference interactions between local variables and fields
  void test_perform_inference_cross_unit_instance_member() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
            var bar = new B();
            void foo() {
              String x = bar.f.z;
            }
      ''',
      '/b.dart': '''
        class C {
          var z = 3;
        }

        class B {
          var f = new C();
        }
      ''',
      '/c.dart': '''
          import 'b.dart';
            var bar = new B();
            void foo() {
              String x = bar.f.z;
            }
    '''
    });
    List<dynamic> units =
        computeLibraryResults(sources, RESOLVED_UNIT11).toList();
    CompilationUnit unit0 = units[0];
    CompilationUnit unit2 = units[2];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;

    assertVariableDeclarationStatementTypes(
        AstFinder.getStatementsInTopLevelFunction(unit0, "foo")[0],
        stringType,
        intType);
    assertVariableDeclarationStatementTypes(
        AstFinder.getStatementsInTopLevelFunction(unit2, "foo")[0],
        stringType,
        intType);
  }

  // Test inference interactions between local variables and top level
  // variables
  void test_perform_inference_cross_unit_non_cyclic() {
    AnalysisTarget firstSource = newSource(
        '/a.dart',
        '''
          var x = 2;
          class A { static var x = 2; }
''');
    AnalysisTarget secondSource = newSource(
        '/test.dart',
        '''
          import 'a.dart';
          var y = x;
          class B { static var y = A.x; }

          test1() {
            x = /*severe:StaticTypeError*/"hi";
            y = /*severe:StaticTypeError*/"hi";
            A.x = /*severe:StaticTypeError*/"hi";
            B.y = /*severe:StaticTypeError*/"hi";
          }
''');
    computeResult(
        new LibrarySpecificUnit(firstSource, firstSource), RESOLVED_UNIT11);
    CompilationUnit unit1 = outputs[RESOLVED_UNIT11];
    computeResult(
        new LibrarySpecificUnit(secondSource, secondSource), RESOLVED_UNIT11);
    CompilationUnit unit2 = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;

    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit1, "x"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "A", "x"), intType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit2, "y"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit2, "B", "y"), intType, intType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit2, "test1");

    assertAssignmentStatementTypes(statements[0], intType, stringType);
    assertAssignmentStatementTypes(statements[1], intType, stringType);
  }

  // Test that inference does not propagate from null
  void test_perform_inference_cross_unit_static_instance() {
    List<Source> sources = newSources({
      '/a.dart': '''
          import 'b.dart';
          class A {
            static final a1 = B.b1;
            final a2 = new B().b2;
          }
      ''',
      '/b.dart': '''
          class B {
            static final b1 = 1;
            final b2 = 1;
          }
      ''',
      '/main.dart': '''
          import "a.dart";

          test1() {
            int x = 0;
            // inference in A now works.
            x = A.a1;
            x = new A().a2;
          }
    '''
    });
    List<dynamic> units =
        computeLibraryResults(sources, RESOLVED_UNIT11).toList();
    CompilationUnit unit0 = units[0];
    CompilationUnit unit1 = units[1];
    CompilationUnit unit2 = units[2];

    InterfaceType intType = context.typeProvider.intType;
    DartType dynamicType = context.typeProvider.dynamicType;

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit0, "A", "a2"), dynamicType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b1"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit1, "B", "b2"), intType, intType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit2, "test1");

    assertAssignmentStatementTypes(statements[1], intType, intType);
    assertAssignmentStatementTypes(statements[2], intType, dynamicType);
  }

  // Test inference across units (non-cyclic)
  void test_perform_inference_local_variables() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
      test() {
        int x = 3;
        x = "hi";
        var y = 3;
        y = "hi";
      }
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");

    assertVariableDeclarationStatementTypes(statements[0], intType, intType);
    assertAssignmentStatementTypes(statements[1], intType, stringType);
    assertVariableDeclarationStatementTypes(statements[2], intType, intType);
    assertAssignmentStatementTypes(statements[3], intType, stringType);
  }

  // Test inference across units (cyclic)
  void test_perform_inference_local_variables_fields() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
      class A {
        int x = 0;

        test1() {
          var a = x;
          a = "hi";
          a = 3;
          var b = y;
          b = "hi";
          b = 4;
          var c = z;
          c = "hi";
          c = 4;
        }

        int y; // field def after use
        final z = 42; // should infer `int`
      }
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;

    List<Statement> statements =
        AstFinder.getStatementsInMethod(unit, "A", "test1");

    assertVariableDeclarationStatementTypes(statements[0], intType, intType);
    assertAssignmentStatementTypes(statements[1], intType, stringType);
    assertAssignmentStatementTypes(statements[2], intType, intType);

    assertVariableDeclarationStatementTypes(statements[3], intType, intType);
    assertAssignmentStatementTypes(statements[4], intType, stringType);
    assertAssignmentStatementTypes(statements[5], intType, intType);

    assertVariableDeclarationStatementTypes(statements[6], intType, intType);
    assertAssignmentStatementTypes(statements[7], intType, stringType);
    assertAssignmentStatementTypes(statements[8], intType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit, "A", "x"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit, "A", "z"), intType, intType);
  }

  // Test inference of instance fields across units
  void test_perform_inference_local_variables_topLevel() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
      int x = 0;

      test1() {
        var a = x;
        a = /*severe:StaticTypeError*/"hi";
        a = 3;
        var b = y;
        b = /*severe:StaticTypeError*/"hi";
        b = 4;
        var c = z;
        c = /*severe:StaticTypeError*/"hi";
        c = 4;
      }

      int y = 0; // field def after use
      final z = 42; // should infer `int`
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test1");

    assertVariableDeclarationStatementTypes(statements[0], intType, intType);
    assertAssignmentStatementTypes(statements[1], intType, stringType);
    assertAssignmentStatementTypes(statements[2], intType, intType);

    assertVariableDeclarationStatementTypes(statements[3], intType, intType);
    assertAssignmentStatementTypes(statements[4], intType, stringType);
    assertAssignmentStatementTypes(statements[5], intType, intType);

    assertVariableDeclarationStatementTypes(statements[6], intType, intType);
    assertAssignmentStatementTypes(statements[7], intType, stringType);
    assertAssignmentStatementTypes(statements[8], intType, intType);

    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit, "x"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit, "y"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit, "z"), intType, intType);
  }

  // Test inference between static and instance fields
  void test_perform_inference_null() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
      var x = null;
      var y = 3;
      class A {
        static var x = null;
        static var y = 3;

        var x2 = null;
        var y2 = 3;
      }

      test() {
        x = "hi";
        y = /*severe:StaticTypeError*/"hi";
        A.x = "hi";
        A.y = /*severe:StaticTypeError*/"hi";
        new A().x2 = "hi";
        new A().y2 = /*severe:StaticTypeError*/"hi";
      }
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;
    DartType nullType = context.typeProvider.nullType;
    DartType dynamicType = context.typeProvider.dynamicType;

    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit, "x"), dynamicType, nullType);
    assertVariableDeclarationTypes(
        AstFinder.getTopLevelVariable(unit, "y"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit, "A", "x"), dynamicType, nullType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit, "A", "y"), intType, intType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit, "A", "x2"), dynamicType, nullType);
    assertVariableDeclarationTypes(
        AstFinder.getFieldInClass(unit, "A", "y2"), intType, intType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");

    assertAssignmentStatementTypes(statements[0], dynamicType, stringType);
    assertAssignmentStatementTypes(statements[1], intType, stringType);
    assertAssignmentStatementTypes(statements[2], dynamicType, stringType);
    assertAssignmentStatementTypes(statements[3], intType, stringType);
    assertAssignmentStatementTypes(statements[4], dynamicType, stringType);
    assertAssignmentStatementTypes(statements[5], intType, stringType);
  }

  // Test inference between fields and method bodies
  void test_perform_local_explicit_disabled() {
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
      test() {
        int x = 3;
        x = "hi";
      }
''');
    computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT11);
    CompilationUnit unit = outputs[RESOLVED_UNIT11];

    InterfaceType intType = context.typeProvider.intType;
    InterfaceType stringType = context.typeProvider.stringType;

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclaration decl =
        (statements[0] as VariableDeclarationStatement).variables.variables[0];
    expect(
        resolutionMap.elementDeclaredByVariableDeclaration(decl).type, intType);
    expect(decl.initializer.staticType, intType);

    ExpressionStatement statement = statements[1];
    AssignmentExpression assgn = statement.expression;
    expect(assgn.leftHandSide.staticType, intType);
    expect(assgn.rightHandSide.staticType, stringType);
  }
}

@reflectiveTest
class StrongModeVerifyUnitTaskTest extends _AbstractDartTaskTest {
  @override
  void setUp() {
    super.setUp();
    enableStrongMode();
  }

  test_created_resolved_unit() {
    Source source = newSource(
        '/test.dart',
        r'''
library lib;
class A {}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, RESOLVED_UNIT);
    expect(outputs[RESOLVED_UNIT], isNotNull);
    expect(outputs[CREATED_RESOLVED_UNIT], isTrue);
  }

  void test_perform_recordDynamicInvoke() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
void main() {
  dynamic a = [];
  a[0];
}
''');
    computeResult(new LibrarySpecificUnit(source, source), STRONG_MODE_ERRORS);
    CompilationUnit unit = outputs[RESOLVED_UNIT];

    // validate
    _fillErrorListener(STRONG_MODE_ERRORS);
    expect(errorListener.errors, isEmpty);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    ExpressionStatement statement = statements[1];
    IndexExpression idx = statement.expression;
    expect(strong_ast.isDynamicInvoke(idx.target), isTrue);
  }

  void test_perform_verifyError() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
class A {}
class B extends A {}
B b = new A();
''');
    computeResult(new LibrarySpecificUnit(source, source), STRONG_MODE_ERRORS);
    // validate
    _fillErrorListener(STRONG_MODE_ERRORS);

    var errors = errorListener.errors;
    expect(errors.length, 1);
    expect(errors[0].errorCode.name, "STRONG_MODE_INVALID_CAST_NEW_EXPR");
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

  test_perform_ConstantValidator_declaredIdentifier() {
    Source source = newSource(
        '/test.dart',
        '''
void main() {
  for (const foo in []) {
    print(foo);
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertNoErrors();
  }

  test_perform_ConstantValidator_dependencyCycle() {
    Source source = newSource(
        '/test.dart',
        '''
const int a = b;
const int b = c;
const int c = a;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT
    ]);
  }

  test_perform_ConstantValidator_duplicateFields() {
    Source source = newSource(
        '/test.dart',
        '''
class Test {
  final int x = 1;
  final int x = 2;
  const Test();
}

main() {
  const Test();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_perform_ConstantValidator_noInitializer() {
    Source source = newSource(
        '/test.dart',
        '''
const x;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
  }

  test_perform_ConstantValidator_unknownValue() {
    Source source = newSource(
        '/test.dart',
        '''
import 'no-such-file.dart' as p;

const int x = p.y;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
  }

  test_perform_directiveError_generated() {
    Source source = newSource(
        '/test.dart',
        '''
import 'generated-file.g.dart';
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    computeResult(target, VERIFY_ERRORS, matcher: isVerifyUnitTask);
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED]);
  }

  test_perform_directiveError_nonGenerated() {
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

  void test_perform_reresolution() {
    enableStrongMode();
    AnalysisTarget source = newSource(
        '/test.dart',
        '''
const topLevel = 3;
class C {
  String field = topLevel;
}
''');
    computeResult(new LibrarySpecificUnit(source, source), VERIFY_ERRORS);
    // validate
    _fillErrorListener(VERIFY_ERRORS);

    var errors = errorListener.errors;
    expect(errors.length, 1);
    expect(errors[0].errorCode, StaticTypeWarningCode.INVALID_ASSIGNMENT);
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

  void assertAssignmentStatementTypes(
      Statement stmt, DartType leftType, DartType rightType) {
    AssignmentExpression assgn = (stmt as ExpressionStatement).expression;
    expect(assgn.leftHandSide.staticType, leftType);
    expect(assgn.rightHandSide.staticType, rightType);
  }

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

  void assertVariableDeclarationStatementTypes(
      Statement stmt, DartType varType, DartType initializerType) {
    VariableDeclaration decl =
        (stmt as VariableDeclarationStatement).variables.variables[0];
    assertVariableDeclarationTypes(decl, varType, initializerType);
  }

  void assertVariableDeclarationTypes(
      VariableDeclaration decl, DartType varType, DartType initializerType) {
    expect(
        resolutionMap.elementDeclaredByVariableDeclaration(decl).type, varType);
    expect(decl.initializer.staticType, initializerType);
  }

  List<dynamic> computeLibraryResults(
      List<Source> sources, ResultDescriptor result,
      {isInstanceOf matcher: null}) {
    dynamic compute(Source source) {
      computeResult(new LibrarySpecificUnit(source, source), result,
          matcher: matcher);
      return outputs[result];
    }

    return sources.map(compute).toList();
  }

  List<Map<ResultDescriptor, dynamic>> computeLibraryResultsMap(
      List<Source> sources, ResultDescriptor result,
      {isInstanceOf matcher: null}) {
    Map<ResultDescriptor, dynamic> compute(Source source) {
      computeResult(source, result, matcher: matcher);
      return outputs;
    }

    return sources.map(compute).toList();
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
   * Enable the use of URIs in part-of directives in the current analysis
   * context.
   */
  void enableUriInPartOf() {
    AnalysisOptionsImpl options = context.analysisOptions;
    options.enableUriInPartOf = true;
    context.analysisOptions = options;
  }

  void setUp() {
    super.setUp();
    emptySource = newSource('/test.dart');
  }

  /**
   * Fill [errorListener] with [result] errors in the current [task].
   */
  void _fillErrorListener(ResultDescriptor<List<AnalysisError>> result) {
    List<AnalysisError> errors = task.outputs[result] as List<AnalysisError>;
    expect(errors, isNotNull, reason: result.name);
    errorListener = new GatheringErrorListener();
    errorListener.addAll(errors);
  }
}
