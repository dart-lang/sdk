// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.dart_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../context/abstract_context.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(BuildClassConstructorsTaskTest);
  runReflectiveTests(BuildCompilationUnitElementTaskTest);
  runReflectiveTests(BuildDirectiveElementsTaskTest);
  runReflectiveTests(BuildEnumMemberElementsTaskTest);
  runReflectiveTests(BuildSourceClosuresTaskTest);
  runReflectiveTests(BuildExportNamespaceTaskTest);
  runReflectiveTests(BuildFunctionTypeAliasesTaskTest);
  runReflectiveTests(BuildLibraryConstructorsTaskTest);
  runReflectiveTests(BuildLibraryElementTaskTest);
  runReflectiveTests(BuildPublicNamespaceTaskTest);
  runReflectiveTests(BuildTypeProviderTaskTest);
  runReflectiveTests(GatherUsedImportedElementsTaskTest);
  runReflectiveTests(GatherUsedLocalElementsTaskTest);
  runReflectiveTests(GenerateHintsTaskTest);
  runReflectiveTests(ParseDartTaskTest);
  runReflectiveTests(ResolveUnitTypeNamesTaskTest);
  runReflectiveTests(ResolveLibraryTypeNamesTaskTest);
  runReflectiveTests(ResolveReferencesTaskTest);
  runReflectiveTests(ResolveVariableReferencesTaskTest);
  runReflectiveTests(ScanDartTaskTest);
  runReflectiveTests(VerifyUnitTaskTest);
}

@reflectiveTest
class BuildClassConstructorsTaskTest extends _AbstractDartTaskTest {
  test_perform_ClassDeclaration_errors_mixinHasNoConstructors() {
    Source source = newSource('/test.dart', '''
class B {
  B({x});
}
class M {}
class C extends B with M {}
''');
    LibraryElement libraryElement;
    {
      _computeResult(source, LIBRARY_ELEMENT5);
      libraryElement = outputs[LIBRARY_ELEMENT5];
    }
    // prepare C
    ClassElement c = libraryElement.getType('C');
    expect(c, isNotNull);
    // build constructors
    _computeResult(c, CONSTRUCTORS);
    expect(task, new isInstanceOf<BuildClassConstructorsTask>());
    _fillErrorListener(CONSTRUCTORS_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
  }

  test_perform_ClassDeclaration_explicitConstructors() {
    Source source = newSource('/test.dart', '''
class B {
  B(p);
}
class C extends B {
  C(int a, String b) {}
}
''');
    LibraryElement libraryElement;
    {
      _computeResult(source, LIBRARY_ELEMENT5);
      libraryElement = outputs[LIBRARY_ELEMENT5];
    }
    // prepare C
    ClassElement c = libraryElement.getType('C');
    expect(c, isNotNull);
    // build constructors
    _computeResult(c, CONSTRUCTORS);
    expect(task, new isInstanceOf<BuildClassConstructorsTask>());
    // no errors
    expect(outputs[CONSTRUCTORS_ERRORS], isEmpty);
    // explicit constructor
    List<ConstructorElement> constructors = outputs[CONSTRUCTORS];
    expect(constructors, hasLength(1));
    expect(constructors[0].parameters, hasLength(2));
  }

  test_perform_ClassTypeAlias() {
    Source source = newSource('/test.dart', '''
class B {
  B(int i);
}
class M1 {}
class M2 {}

class C2 = C1 with M2;
class C1 = B with M1;
''');
    LibraryElement libraryElement;
    {
      _computeResult(source, LIBRARY_ELEMENT5);
      libraryElement = outputs[LIBRARY_ELEMENT5];
    }
    // prepare C2
    ClassElement class2 = libraryElement.getType('C2');
    expect(class2, isNotNull);
    // build constructors
    _computeResult(class2, CONSTRUCTORS);
    expect(task, new isInstanceOf<BuildClassConstructorsTask>());
    List<ConstructorElement> constructors = outputs[CONSTRUCTORS];
    expect(constructors, hasLength(1));
    expect(constructors[0].parameters, hasLength(1));
  }

  test_perform_ClassTypeAlias_errors_mixinHasNoConstructors() {
    Source source = newSource('/test.dart', '''
class B {
  B({x});
}
class M {}
class C = B with M;
''');
    LibraryElement libraryElement;
    {
      _computeResult(source, LIBRARY_ELEMENT5);
      libraryElement = outputs[LIBRARY_ELEMENT5];
    }
    // prepare C
    ClassElement c = libraryElement.getType('C');
    expect(c, isNotNull);
    // build constructors
    _computeResult(c, CONSTRUCTORS);
    expect(task, new isInstanceOf<BuildClassConstructorsTask>());
    _fillErrorListener(CONSTRUCTORS_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
  }
}

@reflectiveTest
class BuildCompilationUnitElementTaskTest extends _AbstractDartTaskTest {
  test_buildInputs() {
    LibrarySpecificUnit target =
        new LibrarySpecificUnit(emptySource, emptySource);
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
class A {}
class B = Object with A;
''');
    expect(outputs, hasLength(3));
    expect(outputs[CLASS_ELEMENTS], hasLength(2));
    expect(outputs[COMPILATION_UNIT_ELEMENT], isNotNull);
    expect(outputs[RESOLVED_UNIT1], isNotNull);
  }

  void _performBuildTask(String content) {
    Source source = newSource('/test.dart', content);
    AnalysisTarget target = new LibrarySpecificUnit(source, source);
    _computeResult(target, RESOLVED_UNIT1);
    expect(task, new isInstanceOf<BuildCompilationUnitElementTask>());
  }
}

@reflectiveTest
class BuildDirectiveElementsTaskTest extends _AbstractDartTaskTest {
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
    _computeResult(sourceA, LIBRARY_ELEMENT2);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
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
    _computeResult(sourceA, LIBRARY_ELEMENT2);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
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
    _computeResult(sourceA, LIBRARY_ELEMENT2);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
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
    _computeResult(sourceA, LIBRARY_ELEMENT2);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // validate errors
    _assertErrorsWithCodes([CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
  }

  test_perform_hasExtUri() {
    List<Source> sources = newSources({
      '/lib.dart': '''
import 'dart-ext:doesNotExist.dart';
'''
    });
    Source source = sources[0];
    // perform task
    _computeResult(source, LIBRARY_ELEMENT2);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
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
    _computeResult(sourceA, LIBRARY_ELEMENT2);
    expect(task, new isInstanceOf<BuildDirectiveElementsTask>());
    // prepare outputs
    CompilationUnit libraryUnitA = context
        .getCacheEntry(new LibrarySpecificUnit(sourceA, sourceA))
        .getValue(RESOLVED_UNIT1);
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
    Source source = newSource('/test.dart', '''
enum MyEnum {
  A, B
}
''');
    _computeResult(new LibrarySpecificUnit(source, source), RESOLVED_UNIT2);
    expect(task, new isInstanceOf<BuildEnumMemberElementsTask>());
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
    Source sourceA = newSource('/a.dart', '''
library lib_a;
export 'b.dart';
''');
    Source sourceB = newSource('/b.dart', '''
library lib_b;
main() {}
''');
    _computeResult(sourceA, LIBRARY_ELEMENT4);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      LibraryElement library = outputs[LIBRARY_ELEMENT4];
      FunctionElement entryPoint = library.entryPoint;
      expect(entryPoint, isNotNull);
      expect(entryPoint.source, sourceB);
    }
  }

  test_perform_hideCombinator() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
export 'b.dart' hide B1;
class A1 {}
class A2 {}
class _A3 {}
''');
    newSource('/b.dart', '''
library lib_b;
class B1 {}
class B2 {}
class B3 {}
class _B4 {}
''');
    newSource('/c.dart', '''
library lib_c;
class C1 {}
class C2 {}
class C3 {}
''');
    _computeResult(sourceA, LIBRARY_ELEMENT4);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      LibraryElement library = outputs[LIBRARY_ELEMENT4];
      Namespace namespace = library.exportNamespace;
      Iterable<String> definedKeys = namespace.definedNames.keys;
      expect(definedKeys, unorderedEquals(['A1', 'A2', 'B2', 'B3']));
    }
  }

  test_perform_showCombinator() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
export 'b.dart' show B1;
class A1 {}
class A2 {}
class _A3 {}
''');
    newSource('/b.dart', '''
library lib_b;
class B1 {}
class B2 {}
class _B3 {}
''');
    _computeResult(sourceA, LIBRARY_ELEMENT4);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      LibraryElement library = outputs[LIBRARY_ELEMENT4];
      Namespace namespace = library.exportNamespace;
      Iterable<String> definedKeys = namespace.definedNames.keys;
      expect(definedKeys, unorderedEquals(['A1', 'A2', 'B1']));
    }
  }

  test_perform_showCombinator_setter() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
export 'b.dart' show topLevelB;
class A {}
''');
    newSource('/b.dart', '''
library lib_b;
int topLevelB;
''');
    _computeResult(sourceA, LIBRARY_ELEMENT4);
    expect(task, new isInstanceOf<BuildExportNamespaceTask>());
    // validate
    {
      LibraryElement library = outputs[LIBRARY_ELEMENT4];
      Namespace namespace = library.exportNamespace;
      Iterable<String> definedKeys = namespace.definedNames.keys;
      expect(definedKeys, unorderedEquals(['A', 'topLevelB', 'topLevelB=']));
    }
  }
}

@reflectiveTest
class BuildFunctionTypeAliasesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource('/test.dart', '''
typedef int F(G g);
typedef String G(int p);
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, RESOLVED_UNIT3);
    expect(task, new isInstanceOf<BuildFunctionTypeAliasesTask>());
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

  test_perform_errors() {
    Source source = newSource('/test.dart', '''
typedef int F(NoSuchType p);
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, BUILD_FUNCTION_TYPE_ALIASES_ERRORS);
    expect(task, new isInstanceOf<BuildFunctionTypeAliasesTask>());
    // validate
    _fillErrorListener(BUILD_FUNCTION_TYPE_ALIASES_ERRORS);
    errorListener
        .assertErrorsWithCodes(<ErrorCode>[StaticWarningCode.UNDEFINED_CLASS]);
  }
}

@reflectiveTest
class BuildLibraryConstructorsTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource('/test.dart', '''
class B {
  B(int i);
}
class M1 {}
class M2 {}

class C2 = C1 with M2;
class C1 = B with M1;
class C3 = B with M2;
''');
    _computeResult(source, LIBRARY_ELEMENT);
    expect(task, new isInstanceOf<BuildLibraryConstructorsTask>());
    LibraryElement libraryElement = outputs[LIBRARY_ELEMENT];
    // C1
    {
      ClassElement classElement = libraryElement.getType('C2');
      List<ConstructorElement> constructors = classElement.constructors;
      expect(constructors, hasLength(1));
      expect(constructors[0].parameters, hasLength(1));
    }
    // C3
    {
      ClassElement classElement = libraryElement.getType('C3');
      List<ConstructorElement> constructors = classElement.constructors;
      expect(constructors, hasLength(1));
      expect(constructors[0].parameters, hasLength(1));
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
    expect(outputs, hasLength(4));
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

  test_perform_classElements() {
    _performBuildTask({
      '/lib.dart': '''
library lib;
part 'part1.dart';
part 'part2.dart';
class A {}
''',
      '/part1.dart': '''
part of lib;
class B {}
''',
      '/part2.dart': '''
part of lib;
class C {}
'''
    });
    List<ClassElement> classElements = outputs[CLASS_ELEMENTS];
    List<String> classNames = classElements.map((c) => c.displayName).toList();
    expect(classNames, unorderedEquals(['A', 'B', 'C']));
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
    List<Source> sources = newSources(sourceMap);
    Source libSource = sources.first;
    _computeResult(libSource, LIBRARY_ELEMENT1);
    expect(task, new isInstanceOf<BuildLibraryElementTask>());
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
  test_buildInputs() {
    Map<String, TaskInput> inputs =
        BuildPublicNamespaceTask.buildInputs(emptySource);
    expect(inputs, isNotNull);
    expect(
        inputs.keys, unorderedEquals([BuildPublicNamespaceTask.LIBRARY_INPUT]));
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
    _computeResult(sources.first, LIBRARY_ELEMENT3);
    expect(task, new isInstanceOf<BuildPublicNamespaceTask>());
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT3];
    Namespace namespace = library.publicNamespace;
    expect(namespace.definedNames.keys, unorderedEquals(['a', 'd']));
  }
}

@reflectiveTest
class BuildSourceClosuresTaskTest extends _AbstractDartTaskTest {
  test_perform_exportClosure() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
export 'b.dart';
''');
    Source sourceB = newSource('/b.dart', '''
library lib_b;
export 'c.dart';
''');
    Source sourceC = newSource('/c.dart', '''
library lib_c;
export 'a.dart';
''');
    Source sourceD = newSource('/d.dart', '''
library lib_d;
''');
    // a.dart
    {
      _computeResult(sourceA, EXPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildSourceClosuresTask>());
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // c.dart
    {
      _computeResult(sourceC, EXPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildSourceClosuresTask>());
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceA, sourceB, sourceC]));
    }
    // d.dart
    {
      _computeResult(sourceD, EXPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildSourceClosuresTask>());
      List<Source> closure = outputs[EXPORT_SOURCE_CLOSURE];
      expect(closure, unorderedEquals([sourceD]));
    }
  }

  test_perform_importClosure() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
import 'b.dart';
''');
    Source sourceB = newSource('/b.dart', '''
library lib_b;
import 'c.dart';
''');
    Source sourceC = newSource('/c.dart', '''
library lib_c;
import 'a.dart';
''');
    Source sourceD = newSource('/d.dart', '''
library lib_d;
''');
    Source coreSource = context.sourceFactory.resolveUri(null, 'dart:core');
    // a.dart
    {
      _computeResult(sourceA, IMPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildSourceClosuresTask>());
      List<Source> closure = outputs[IMPORT_SOURCE_CLOSURE];
      expect(closure, contains(sourceA));
      expect(closure, contains(sourceB));
      expect(closure, contains(sourceC));
      expect(closure, contains(coreSource));
    }
    // c.dart
    {
      _computeResult(sourceC, IMPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildSourceClosuresTask>());
      List<Source> closure = outputs[IMPORT_SOURCE_CLOSURE];
      expect(closure, contains(sourceA));
      expect(closure, contains(sourceB));
      expect(closure, contains(sourceC));
      expect(closure, contains(coreSource));
    }
    // d.dart
    {
      _computeResult(sourceD, IMPORT_SOURCE_CLOSURE);
      expect(task, new isInstanceOf<BuildSourceClosuresTask>());
      List<Source> closure = outputs[IMPORT_SOURCE_CLOSURE];
      expect(closure, contains(sourceD));
      expect(closure, contains(coreSource));
    }
  }

  test_perform_isClient_false() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
import 'b.dart';
''');
    newSource('/b.dart', '''
library lib_b;
''');
    _computeResult(sourceA, IS_CLIENT);
    expect(task, new isInstanceOf<BuildSourceClosuresTask>());
    expect(outputs[IS_CLIENT], isFalse);
  }

  test_perform_isClient_true_export_indirect() {
    newSource('/exports_html.dart', '''
library lib_exports_html;
export 'dart:html';
''');
    Source source = newSource('/test.dart', '''
import 'exports_html.dart';
''');
    _computeResult(source, IS_CLIENT);
    expect(task, new isInstanceOf<BuildSourceClosuresTask>());
    expect(outputs[IS_CLIENT], isTrue);
  }

  test_perform_isClient_true_import_direct() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
import 'dart:html';
''');
    _computeResult(sourceA, IS_CLIENT);
    expect(task, new isInstanceOf<BuildSourceClosuresTask>());
    expect(outputs[IS_CLIENT], isTrue);
  }

  test_perform_isClient_true_import_indirect() {
    Source sourceA = newSource('/a.dart', '''
library lib_a;
import 'b.dart';
''');
    newSource('/b.dart', '''
library lib_b;
import 'dart:html';
''');
    _computeResult(sourceA, IS_CLIENT);
    expect(task, new isInstanceOf<BuildSourceClosuresTask>());
    expect(outputs[IS_CLIENT], isTrue);
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
class GatherUsedImportedElementsTaskTest extends _AbstractDartTaskTest {
  UsedImportedElements usedElements;
  Set<String> usedElementNames;

  test_perform() {
    newSource('/a.dart', r'''
library lib_a;
class A {}
''');
    newSource('/b.dart', r'''
library lib_b;
class B {}
''');
    Source source = newSource('/test.dart', r'''
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
    _computeResult(target, USED_IMPORTED_ELEMENTS);
    expect(task, new isInstanceOf<GatherUsedImportedElementsTask>());
    usedElements = outputs[USED_IMPORTED_ELEMENTS];
    usedElementNames = usedElements.elements.map((e) => e.name).toSet();
  }
}

@reflectiveTest
class GatherUsedLocalElementsTaskTest extends _AbstractDartTaskTest {
  UsedLocalElements usedElements;
  Set<String> usedElementNames;

  test_perform_localVariable() {
    Source source = newSource('/test.dart', r'''
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
    Source source = newSource('/test.dart', r'''
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
    _computeResult(target, USED_LOCAL_ELEMENTS);
    expect(task, new isInstanceOf<GatherUsedLocalElementsTask>());
    usedElements = outputs[USED_LOCAL_ELEMENTS];
    usedElementNames = usedElements.elements.map((e) => e.name).toSet();
  }
}

@reflectiveTest
class GenerateHintsTaskTest extends _AbstractDartTaskTest {
  test_perform_bestPractices_missingReturn() {
    Source source = newSource('/test.dart', '''
int main() {
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.MISSING_RETURN]);
  }

  test_perform_dart2js() {
    Source source = newSource('/test.dart', '''
main(p) {
  if (p is double) {
    print('double');
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.IS_DOUBLE]);
  }

  test_perform_deadCode() {
    Source source = newSource('/test.dart', '''
main() {
  if (false) {
    print('how?');
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.DEAD_CODE]);
  }

  test_perform_imports_duplicateImport() {
    newSource('/a.dart', r'''
library lib_a;
class A {}
''');
    Source source = newSource('/test.dart', r'''
import 'a.dart';
import 'a.dart';
main() {
  new A();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.DUPLICATE_IMPORT]);
  }

  test_perform_imports_unusedImport_one() {
    newSource('/a.dart', r'''
library lib_a;
class A {}
''');
    newSource('/b.dart', r'''
library lib_b;
class B {}
''');
    Source source = newSource('/test.dart', r'''
import 'a.dart';
import 'b.dart';
main() {
  new A();
}''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.UNUSED_IMPORT]);
  }

  test_perform_imports_unusedImport_zero() {
    newSource('/a.dart', r'''
library lib_a;
class A {}
''');
    Source source = newSource('/test.dart', r'''
import 'a.dart';
main() {
  new A();
}''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertNoErrors();
  }

  test_perform_overrideVerifier() {
    Source source = newSource('/test.dart', '''
class A {}
class B {
  @override
  m() {}
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD]);
  }

  test_perform_todo() {
    Source source = newSource('/test.dart', '''
main() {
  // TODO(developer) foo bar
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[TodoCode.TODO]);
  }

  test_perform_unusedLocalElements_class() {
    Source source = newSource('/test.dart', '''
class _A {}
class _B {}
main() {
  new _A();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(<ErrorCode>[HintCode.UNUSED_ELEMENT]);
  }

  test_perform_unusedLocalElements_localVariable() {
    Source source = newSource('/test.dart', '''
main() {
  var v = 42;
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener
        .assertErrorsWithCodes(<ErrorCode>[HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_perform_unusedLocalElements_method() {
    Source source = newSource('/my_lib.dart', '''
library my_lib;
part 'my_part.dart';
class A {
  _ma() {}
  _mb() {}
  _mc() {}
}
''');
    newSource('/my_part.dart', '''
part of my_lib;

f(A a) {
  a._mb();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, HINTS);
    expect(task, new isInstanceOf<GenerateHintsTask>());
    // validate
    _fillErrorListener(HINTS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[HintCode.UNUSED_ELEMENT, HintCode.UNUSED_ELEMENT]);
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
    expect(outputs, hasLength(7));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(0));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 1);
    expect(outputs[INCLUDED_PARTS], hasLength(0));
    expect(outputs[PARSE_ERRORS], hasLength(0));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.PART);
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
    expect(outputs, hasLength(7));
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
    expect(outputs, hasLength(7));
    expect(outputs[EXPORTED_LIBRARIES], hasLength(1));
    _assertHasCore(outputs[IMPORTED_LIBRARIES], 2);
    expect(outputs[INCLUDED_PARTS], hasLength(1));
    expect(outputs[PARSE_ERRORS], hasLength(1));
    expect(outputs[PARSED_UNIT], isNotNull);
    expect(outputs[SOURCE_KIND], SourceKind.LIBRARY);
    expect(outputs[UNITS], hasLength(2));
  }

  void _performParseTask(String content) {
    AnalysisTarget target = newSource('/test.dart', content);
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
class ResolveLibraryTypeNamesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source sourceLib = newSource('/my_lib.dart', '''
library my_lib;
part 'my_part.dart';
class A {}
class B extends A {}
''');
    newSource('/my_part.dart', '''
part of my_lib;
class C extends A {}
''');
    _computeResult(sourceLib, LIBRARY_ELEMENT5);
    expect(task, new isInstanceOf<ResolveLibraryTypeNamesTask>());
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

  test_perform_deep() {
    Source sourceA = newSource('/a.dart', '''
library a;
import 'b.dart';
class A extends B {}
''');
    newSource('/b.dart', '''
library b;
import 'c.dart';
part 'b2.dart';
class B extends B2 {}
''');
    newSource('/b2.dart', '''
part of b;
class B2 extends C {}
''');
    newSource('/c.dart', '''
library c;
class C {}
''');
    _computeResult(sourceA, LIBRARY_ELEMENT5);
    expect(task, new isInstanceOf<ResolveLibraryTypeNamesTask>());
    // validate
    LibraryElement library = outputs[LIBRARY_ELEMENT5];
    {
      ClassElement clazz = library.getType('A');
      expect(clazz.displayName, 'A');
      clazz = clazz.supertype.element;
      expect(clazz.displayName, 'B');
      clazz = clazz.supertype.element;
      expect(clazz.displayName, 'B2');
      clazz = clazz.supertype.element;
      expect(clazz.displayName, 'C');
      clazz = clazz.supertype.element;
      expect(clazz.displayName, 'Object');
      expect(clazz.supertype, isNull);
    }
  }
}

@reflectiveTest
class ResolveReferencesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource('/test.dart', '''
class A {
  m() {}
}
main(A a) {
  a.m();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    // prepare unit and "a.m()" invocation
    CompilationUnit unit;
    MethodInvocation invocation;
    {
      _computeResult(target, RESOLVED_UNIT1);
      unit = outputs[RESOLVED_UNIT1];
      // walk the AST
      FunctionDeclaration function = unit.declarations[1];
      BlockFunctionBody body = function.functionExpression.body;
      ExpressionStatement statement = body.block.statements[0];
      invocation = statement.expression;
      // not resolved yet
      expect(invocation.methodName.staticElement, isNull);
    }
    // fully resolve
    {
      _computeResult(target, RESOLVED_UNIT);
      expect(task, new isInstanceOf<ResolveReferencesTask>());
      expect(outputs[RESOLVED_UNIT], same(outputs[RESOLVED_UNIT]));
      // a.m() is resolved now
      expect(invocation.methodName.staticElement, isNotNull);
    }
  }

  test_perform_errors() {
    Source source = newSource('/test.dart', '''
class A {
}
main(A a) {
  a.unknownMethod();
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, RESOLVED_UNIT);
    expect(task, new isInstanceOf<ResolveReferencesTask>());
    // validate
    _fillErrorListener(RESOLVE_REFERENCES_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[StaticTypeWarningCode.UNDEFINED_METHOD]);
  }
}

@reflectiveTest
class ResolveUnitTypeNamesTaskTest extends _AbstractDartTaskTest {
  test_perform() {
    Source source = newSource('/test.dart', '''
class A {}
class B extends A {}
int f(String p) => p.length;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, RESOLVED_UNIT4);
    expect(task, new isInstanceOf<ResolveUnitTypeNamesTask>());
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT4];
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
    Source source = newSource('/test.dart', '''
NoSuchClass f() => null;
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, RESOLVE_TYPE_NAMES_ERRORS);
    expect(task, new isInstanceOf<ResolveUnitTypeNamesTask>());
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

  test_perform_local() {
    Source source = newSource('/test.dart', '''
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
    _computeResult(target, RESOLVED_UNIT5);
    expect(task, new isInstanceOf<ResolveVariableReferencesTask>());
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    FunctionElement main = unit.element.functions[0];
    expectMutated(main.localVariables[0], isFalse, isFalse);
    expectMutated(main.localVariables[1], isFalse, isTrue);
    expectMutated(main.localVariables[2], isTrue, isTrue);
    expectMutated(main.localVariables[3], isTrue, isTrue);
  }

  test_perform_parameter() {
    Source source = newSource('/test.dart', '''
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
    _computeResult(target, RESOLVED_UNIT5);
    expect(task, new isInstanceOf<ResolveVariableReferencesTask>());
    // validate
    CompilationUnit unit = outputs[RESOLVED_UNIT5];
    FunctionElement main = unit.element.functions[0];
    expectMutated(main.parameters[0], isFalse, isFalse);
    expectMutated(main.parameters[1], isFalse, isTrue);
    expectMutated(main.parameters[2], isTrue, isTrue);
    expectMutated(main.parameters[3], isTrue, isTrue);
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
    AnalysisTarget target = newSource('/test.dart', content);
    _computeResult(target, TOKEN_STREAM);
    expect(task, new isInstanceOf<ScanDartTask>());
  }
}

@reflectiveTest
class VerifyUnitTaskTest extends _AbstractDartTaskTest {
  test_perform_verifyError() {
    Source source = newSource('/test.dart', '''
main() {
  if (42) {
    print('Not bool!');
  }
}
''');
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    _computeResult(target, VERIFY_ERRORS);
    expect(task, new isInstanceOf<VerifyUnitTask>());
    // validate
    _fillErrorListener(VERIFY_ERRORS);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }
}

class _AbstractDartTaskTest extends AbstractContextTest {
  Source emptySource;

  AnalysisTask task;
  Map<ResultDescriptor<dynamic>, dynamic> outputs;
  GatheringErrorListener errorListener = new GatheringErrorListener();

  void setUp() {
    super.setUp();
    emptySource = newSource('/test.dart');
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
}
