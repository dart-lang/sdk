// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.serialization.elements_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_handle.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart'
    show Namespace, TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthTest);
}

@reflectiveTest
class ResynthTest extends ResolverTestCase {
  Set<Source> otherLibrarySources = new Set<Source>();
  bool shouldCompareConstValues = false;

  /**
   * Determine the analysis options that should be used for this test.
   */
  AnalysisOptionsImpl get options =>
      new AnalysisOptionsImpl()..enableGenericMethods = true;

  void addLibrary(String uri) {
    otherLibrarySources.add(analysisContext2.sourceFactory.forUri(uri));
  }

  void addLibrarySource(String filePath, String contents) {
    otherLibrarySources.add(addNamedSource(filePath, contents));
  }

  void checkLibrary(String text, {bool allowErrors: false}) {
    Source source = addSource(text);
    LibraryElementImpl original = resolve2(source);
    LibraryElementImpl resynthesized = resynthesizeLibraryElement(
        encodeLibrary(original, allowErrors: allowErrors),
        source.uri.toString());
    checkLibraryElements(original, resynthesized);
  }

  void checkLibraryElements(
      LibraryElementImpl original, LibraryElementImpl resynthesized) {
    compareElements(resynthesized, original, '(library)');
    expect(resynthesized.displayName, original.displayName);
    expect(original.enclosingElement, isNull);
    expect(resynthesized.enclosingElement, isNull);
    expect(resynthesized.hasExtUri, original.hasExtUri);
    compareCompilationUnitElements(resynthesized.definingCompilationUnit,
        original.definingCompilationUnit);
    expect(resynthesized.parts.length, original.parts.length);
    for (int i = 0; i < resynthesized.parts.length; i++) {
      compareCompilationUnitElements(resynthesized.parts[i], original.parts[i]);
    }
    expect(resynthesized.imports.length, original.imports.length);
    for (int i = 0; i < resynthesized.imports.length; i++) {
      compareImportElements(resynthesized.imports[i], original.imports[i],
          'import ${original.imports[i].uri}');
    }
    expect(resynthesized.exports.length, original.exports.length);
    for (int i = 0; i < resynthesized.exports.length; i++) {
      compareExportElements(resynthesized.exports[i], original.exports[i],
          'export ${original.exports[i].uri}');
    }
    expect(resynthesized.nameLength, original.nameLength);
    compareNamespaces(resynthesized.publicNamespace, original.publicNamespace,
        '(public namespace)');
    compareNamespaces(resynthesized.exportNamespace, original.exportNamespace,
        '(export namespace)');
    if (original.entryPoint == null) {
      expect(resynthesized.entryPoint, isNull);
    } else {
      expect(resynthesized.entryPoint, isNotNull);
      compareFunctionElements(
          resynthesized.entryPoint, original.entryPoint, '(entry point)');
    }
    // The libraries `dart:core` and `dart:async` cannot create their
    // `loadLibrary` functions until after both are created.
    if (original.name != 'dart.core' && original.name != 'dart.async') {
      compareExecutableElements(
          resynthesized.loadLibraryFunction as ExecutableElementImpl,
          original.loadLibraryFunction as ExecutableElementImpl,
          '(loadLibraryFunction)');
    }
    // TODO(paulberry): test metadata.
  }

  void compareClassElements(
      ClassElementImpl resynthesized, ClassElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.fields.length, original.fields.length,
        reason: '$desc fields.length');
    for (int i = 0; i < resynthesized.fields.length; i++) {
      String name = original.fields[i].name;
      compareFieldElements(
          resynthesized.fields[i], original.fields[i], '$desc.field $name');
    }
    compareTypes(
        resynthesized.supertype, original.supertype, '$desc supertype');
    expect(resynthesized.interfaces.length, original.interfaces.length);
    for (int i = 0; i < resynthesized.interfaces.length; i++) {
      compareTypes(resynthesized.interfaces[i], original.interfaces[i],
          '$desc interface ${original.interfaces[i].name}');
    }
    expect(resynthesized.mixins.length, original.mixins.length);
    for (int i = 0; i < resynthesized.mixins.length; i++) {
      compareTypes(resynthesized.mixins[i], original.mixins[i],
          '$desc mixin ${original.mixins[i].name}');
    }
    expect(resynthesized.typeParameters.length, original.typeParameters.length);
    for (int i = 0; i < resynthesized.typeParameters.length; i++) {
      compareTypeParameterElements(
          resynthesized.typeParameters[i],
          original.typeParameters[i],
          '$desc type parameter ${original.typeParameters[i].name}');
    }
    expect(resynthesized.constructors.length, original.constructors.length,
        reason: '$desc constructors.length');
    for (int i = 0; i < resynthesized.constructors.length; i++) {
      compareConstructorElements(
          resynthesized.constructors[i],
          original.constructors[i],
          '$desc constructor ${original.constructors[i].name}');
    }
    expect(resynthesized.accessors.length, original.accessors.length);
    for (int i = 0; i < resynthesized.accessors.length; i++) {
      comparePropertyAccessorElements(
          resynthesized.accessors[i],
          original.accessors[i],
          '$desc accessor ${original.accessors[i].name}');
    }
    expect(resynthesized.methods.length, original.methods.length);
    for (int i = 0; i < resynthesized.methods.length; i++) {
      compareMethodElements(resynthesized.methods[i], original.methods[i],
          '$desc.${original.methods[i].name}');
    }
    compareTypes(resynthesized.type, original.type, desc);
  }

  void compareCompilationUnitElements(CompilationUnitElementImpl resynthesized,
      CompilationUnitElementImpl original) {
    String desc = 'Compilation unit ${original.source.uri}';
    compareUriReferencedElements(resynthesized, original, desc);
    expect(resynthesized.source, original.source);
    expect(resynthesized.librarySource, original.librarySource);
    expect(resynthesized.types.length, original.types.length);
    for (int i = 0; i < resynthesized.types.length; i++) {
      compareClassElements(
          resynthesized.types[i], original.types[i], original.types[i].name);
    }
    expect(resynthesized.topLevelVariables.length,
        original.topLevelVariables.length);
    for (int i = 0; i < resynthesized.topLevelVariables.length; i++) {
      compareTopLevelVariableElements(
          resynthesized.topLevelVariables[i],
          original.topLevelVariables[i],
          'variable ${original.topLevelVariables[i].name}');
    }
    expect(resynthesized.functions.length, original.functions.length);
    for (int i = 0; i < resynthesized.functions.length; i++) {
      compareFunctionElements(resynthesized.functions[i], original.functions[i],
          'function ${original.functions[i].name}');
    }
    expect(resynthesized.functionTypeAliases.length,
        original.functionTypeAliases.length);
    for (int i = 0; i < resynthesized.functionTypeAliases.length; i++) {
      compareFunctionTypeAliasElements(
          resynthesized.functionTypeAliases[i],
          original.functionTypeAliases[i],
          original.functionTypeAliases[i].name);
    }
    expect(resynthesized.enums.length, original.enums.length);
    for (int i = 0; i < resynthesized.enums.length; i++) {
      compareClassElements(
          resynthesized.enums[i], original.enums[i], original.enums[i].name);
    }
    expect(resynthesized.accessors.length, original.accessors.length);
    for (int i = 0; i < resynthesized.accessors.length; i++) {
      if (original.accessors[i].isGetter) {
        comparePropertyAccessorElements(resynthesized.accessors[i],
            original.accessors[i], 'getter ${original.accessors[i].name}');
      } else {
        comparePropertyAccessorElements(resynthesized.accessors[i],
            original.accessors[i], 'setter ${original.accessors[i].name}');
      }
    }
    // TODO(paulberry): test metadata and offsetToElementMap.
  }

  void compareConstantValues(
      DartObject resynthesized, DartObject original, String desc) {
    if (original == null) {
      expect(resynthesized, isNull, reason: desc);
    } else {
      expect(resynthesized, isNotNull, reason: desc);
      compareTypes(resynthesized.type, original.type, desc);
      expect(resynthesized.hasKnownValue, original.hasKnownValue, reason: desc);
      if (original.isNull) {
        expect(resynthesized.isNull, isTrue, reason: desc);
      } else if (original.toBoolValue() != null) {
        expect(resynthesized.toBoolValue(), original.toBoolValue(),
            reason: desc);
      } else if (original.toIntValue() != null) {
        expect(resynthesized.toIntValue(), original.toIntValue(), reason: desc);
      } else if (original.toDoubleValue() != null) {
        expect(resynthesized.toDoubleValue(), original.toDoubleValue(),
            reason: desc);
      } else if (original.toListValue() != null) {
        List<DartObject> resynthesizedList = resynthesized.toListValue();
        List<DartObject> originalList = original.toListValue();
        expect(resynthesizedList, hasLength(originalList.length));
        for (int i = 0; i < originalList.length; i++) {
          compareConstantValues(resynthesizedList[i], originalList[i], desc);
        }
      } else if (original.toMapValue() != null) {
        Map<DartObject, DartObject> resynthesizedMap =
            resynthesized.toMapValue();
        Map<DartObject, DartObject> originalMap = original.toMapValue();
        expect(resynthesizedMap, hasLength(originalMap.length));
        List<DartObject> resynthesizedKeys = resynthesizedMap.keys.toList();
        List<DartObject> originalKeys = originalMap.keys.toList();
        for (int i = 0; i < originalKeys.length; i++) {
          DartObject resynthesizedKey = resynthesizedKeys[i];
          DartObject originalKey = originalKeys[i];
          compareConstantValues(resynthesizedKey, originalKey, desc);
          DartObject resynthesizedValue = resynthesizedMap[resynthesizedKey];
          DartObject originalValue = originalMap[originalKey];
          compareConstantValues(resynthesizedValue, originalValue, desc);
        }
      } else if (original.toStringValue() != null) {
        expect(resynthesized.toStringValue(), original.toStringValue(),
            reason: desc);
      } else if (original.toSymbolValue() != null) {
        expect(resynthesized.toSymbolValue(), original.toSymbolValue(),
            reason: desc);
      } else if (original.toTypeValue() != null) {
        fail('Not implemented');
      }
      // TODO(scheglov) implement
    }
  }

  void compareConstructorElements(ConstructorElementImpl resynthesized,
      ConstructorElementImpl original, String desc) {
    compareExecutableElements(resynthesized, original, desc);
    // TODO(paulberry): test redirectedConstructor and constantInitializers
  }

  void compareElements(Element resynthesized, Element original, String desc) {
    expect(resynthesized, isNotNull);
    expect(resynthesized.kind, original.kind);
    expect(resynthesized.location, original.location, reason: desc);
    expect(resynthesized.name, original.name);
    expect(resynthesized.nameOffset, original.nameOffset, reason: desc);
    expect(resynthesized.documentationComment, original.documentationComment,
        reason: desc);
    expect(resynthesized.docRange, original.docRange, reason: desc);
    // Modifiers are a pain to test via handles.  So just test them via the
    // actual element.
    ElementImpl actualResynthesized = getActualElement(resynthesized, desc);
    ElementImpl actualOriginal = getActualElement(original, desc);
    for (Modifier modifier in Modifier.values) {
      bool got = actualResynthesized.hasModifier(modifier);
      bool want = actualOriginal.hasModifier(modifier);
      expect(got, want,
          reason: 'Mismatch in $desc.$modifier: got $got, want $want');
    }
  }

  void compareExecutableElements(ExecutableElement resynthesized,
      ExecutableElement original, String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.parameters.length, original.parameters.length);
    for (int i = 0; i < resynthesized.parameters.length; i++) {
      compareParameterElements(
          resynthesized.parameters[i],
          original.parameters[i],
          '$desc parameter ${original.parameters[i].name}');
    }
    compareTypes(
        resynthesized.returnType, original.returnType, '$desc return type');
    compareTypes(resynthesized.type, original.type, desc);
  }

  void compareExportElements(ExportElementImpl resynthesized,
      ExportElementImpl original, String desc) {
    compareUriReferencedElements(resynthesized, original, desc);
    expect(resynthesized.exportedLibrary.location,
        original.exportedLibrary.location);
    expect(resynthesized.combinators.length, original.combinators.length);
    for (int i = 0; i < resynthesized.combinators.length; i++) {
      compareNamespaceCombinators(
          resynthesized.combinators[i], original.combinators[i]);
    }
  }

  void compareFieldElements(
      FieldElementImpl resynthesized, FieldElementImpl original, String desc) {
    comparePropertyInducingElements(resynthesized, original, desc);
    // TODO(paulberry): test evaluationResult
  }

  void compareFunctionElements(
      FunctionElement resynthesized, FunctionElement original, String desc) {
    compareExecutableElements(resynthesized, original, desc);
  }

  void compareFunctionTypeAliasElements(
      FunctionTypeAliasElementImpl resynthesized,
      FunctionTypeAliasElementImpl original,
      String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.parameters.length, original.parameters.length);
    for (int i = 0; i < resynthesized.parameters.length; i++) {
      compareParameterElements(
          resynthesized.parameters[i],
          original.parameters[i],
          '$desc parameter ${original.parameters[i].name}');
    }
    compareTypes(
        resynthesized.returnType, original.returnType, '$desc return type');
    compareTypes(resynthesized.type, original.type, desc);
    expect(resynthesized.typeParameters.length, original.typeParameters.length);
    for (int i = 0; i < resynthesized.typeParameters.length; i++) {
      compareTypeParameterElements(
          resynthesized.typeParameters[i],
          original.typeParameters[i],
          '$desc type parameter ${original.typeParameters[i].name}');
    }
  }

  void compareImportElements(ImportElementImpl resynthesized,
      ImportElementImpl original, String desc) {
    compareUriReferencedElements(resynthesized, original, desc);
    expect(resynthesized.importedLibrary.location,
        original.importedLibrary.location);
    expect(resynthesized.prefixOffset, original.prefixOffset);
    if (original.prefix == null) {
      expect(resynthesized.prefix, isNull);
    } else {
      comparePrefixElements(
          resynthesized.prefix, original.prefix, original.prefix.name);
    }
    expect(resynthesized.combinators.length, original.combinators.length);
    for (int i = 0; i < resynthesized.combinators.length; i++) {
      compareNamespaceCombinators(
          resynthesized.combinators[i], original.combinators[i]);
    }
  }

  void compareMethodElements(MethodElementImpl resynthesized,
      MethodElementImpl original, String desc) {
    // TODO(paulberry): do we need to deal with
    // MultiplyInheritedMethodElementImpl?
    // TODO(paulberry): compare type parameters for generic methods.
    compareExecutableElements(resynthesized, original, desc);
  }

  void compareNamespaceCombinators(
      NamespaceCombinator resynthesized, NamespaceCombinator original) {
    if (original is ShowElementCombinatorImpl &&
        resynthesized is ShowElementCombinatorImpl) {
      expect(resynthesized.shownNames, original.shownNames);
    } else if (original is HideElementCombinatorImpl &&
        resynthesized is HideElementCombinatorImpl) {
      expect(resynthesized.hiddenNames, original.hiddenNames);
    } else if (resynthesized.runtimeType != original.runtimeType) {
      fail(
          'Type mismatch: expected ${original.runtimeType}, got ${resynthesized.runtimeType}');
    } else {
      fail('Unimplemented comparison for ${original.runtimeType}');
    }
  }

  void compareNamespaces(
      Namespace resynthesized, Namespace original, String desc) {
    Map<String, Element> resynthesizedMap = resynthesized.definedNames;
    Map<String, Element> originalMap = original.definedNames;
    expect(resynthesizedMap.keys.toSet(), originalMap.keys.toSet(),
        reason: desc);
    for (String key in originalMap.keys) {
      Element resynthesizedElement = resynthesizedMap[key];
      Element originalElement = originalMap[key];
      compareElements(resynthesizedElement, originalElement, key);
    }
  }

  void compareParameterElements(ParameterElementImpl resynthesized,
      ParameterElementImpl original, String desc) {
    compareVariableElements(resynthesized, original, desc);
    expect(resynthesized.parameters.length, original.parameters.length);
    for (int i = 0; i < resynthesized.parameters.length; i++) {
      compareParameterElements(
          resynthesized.parameters[i],
          original.parameters[i],
          '$desc parameter ${original.parameters[i].name}');
    }
    expect(resynthesized.parameterKind, original.parameterKind);
    expect(resynthesized.isInitializingFormal, original.isInitializingFormal,
        reason: desc);
    expect(resynthesized is FieldFormalParameterElementImpl,
        original is FieldFormalParameterElementImpl);
    if (resynthesized is FieldFormalParameterElementImpl &&
        original is FieldFormalParameterElementImpl) {
      if (original.field == null) {
        expect(resynthesized.field, isNull, reason: '$desc field');
      } else {
        expect(resynthesized.field, isNotNull, reason: '$desc field');
        compareFieldElements(
            resynthesized.field, original.field, '$desc field');
      }
    }
  }

  void comparePrefixElements(PrefixElementImpl resynthesized,
      PrefixElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    // TODO(paulberry): test _importedLibraries.
  }

  void comparePropertyAccessorElements(
      PropertyAccessorElementImpl resynthesized,
      PropertyAccessorElementImpl original,
      String desc) {
    // TODO(paulberry): do I need to worry about
    // MultiplyInheritedPropertyAccessorElementImpl?
    compareExecutableElements(resynthesized, original, desc);
    expect(resynthesized.variable, isNotNull);
    expect(resynthesized.variable.location, original.variable.location);
  }

  void comparePropertyInducingElements(
      PropertyInducingElementImpl resynthesized,
      PropertyInducingElementImpl original,
      String desc) {
    compareVariableElements(resynthesized, original, desc);
    compareTypes(resynthesized.propagatedType, original.propagatedType, desc);
    if (original.getter == null) {
      expect(resynthesized.getter, isNull);
    } else {
      expect(resynthesized.getter, isNotNull);
      expect(resynthesized.getter.location, original.getter.location);
    }
    if (original.setter == null) {
      expect(resynthesized.setter, isNull);
    } else {
      expect(resynthesized.setter, isNotNull);
      expect(resynthesized.setter.location, original.setter.location);
    }
  }

  void compareTopLevelVariableElements(
      TopLevelVariableElementImpl resynthesized,
      TopLevelVariableElementImpl original,
      String desc) {
    comparePropertyInducingElements(resynthesized, original, desc);
    // TODO(paulberry): test evaluationResult
  }

  void compareTypeImpls(
      TypeImpl resynthesized, TypeImpl original, String desc) {
    expect(resynthesized.element.location, original.element.location,
        reason: desc);
    expect(resynthesized.name, original.name, reason: desc);
  }

  void compareTypeParameterElements(TypeParameterElementImpl resynthesized,
      TypeParameterElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    compareTypes(resynthesized.type, original.type, desc);
    compareTypes(resynthesized.bound, original.bound, '$desc bound');
  }

  void compareTypes(DartType resynthesized, DartType original, String desc) {
    if (original == null) {
      expect(resynthesized, isNull, reason: desc);
    } else if (resynthesized is InterfaceTypeImpl &&
        original is InterfaceTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
      expect(resynthesized.typeArguments.length, original.typeArguments.length);
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc type argument ${original.typeArguments[i].name}');
      }
    } else if (resynthesized is TypeParameterTypeImpl &&
        original is TypeParameterTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
    } else if (resynthesized is DynamicTypeImpl &&
        original is DynamicTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is UndefinedTypeImpl &&
        original is UndefinedTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is FunctionTypeImpl &&
        original is FunctionTypeImpl) {
      compareTypeImpls(resynthesized, original, desc);
      expect(resynthesized.isInstantiated, original.isInstantiated,
          reason: desc);
      if (original.element.isSynthetic &&
          original.element is FunctionTypeAliasElementImpl &&
          resynthesized.element is FunctionTypeAliasElementImpl) {
        compareFunctionTypeAliasElements(
            resynthesized.element, original.element, desc);
      }
      expect(resynthesized.typeArguments.length, original.typeArguments.length,
          reason: desc);
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc type argument ${original.typeArguments[i].name}');
      }
      if (original.typeParameters == null) {
        expect(resynthesized.typeParameters, isNull, reason: desc);
      } else {
        expect(resynthesized.typeParameters, isNotNull, reason: desc);
        expect(
            resynthesized.typeParameters.length, original.typeParameters.length,
            reason: desc);
        for (int i = 0; i < resynthesized.typeParameters.length; i++) {
          compareTypeParameterElements(resynthesized.typeParameters[i],
              original.typeParameters[i], '$desc type parameter $i');
        }
      }
      expect(resynthesized.typeFormals.length, original.typeFormals.length,
          reason: desc);
      for (int i = 0; i < resynthesized.typeFormals.length; i++) {
        compareTypeParameterElements(resynthesized.typeFormals[i],
            original.typeFormals[i], '$desc bound type parameter $i');
      }
    } else if (resynthesized is VoidTypeImpl && original is VoidTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized.runtimeType != original.runtimeType) {
      fail(
          'Type mismatch: expected ${original.runtimeType}, got ${resynthesized.runtimeType}');
    } else {
      fail('Unimplemented comparison for ${original.runtimeType}');
    }
  }

  void compareUriReferencedElements(UriReferencedElementImpl resynthesized,
      UriReferencedElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.uri, original.uri);
    expect(resynthesized.uriOffset, original.uriOffset, reason: desc);
    expect(resynthesized.uriEnd, original.uriEnd, reason: desc);
  }

  void compareVariableElements(VariableElementImpl resynthesized,
      VariableElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    compareTypes(resynthesized.type, original.type, desc);
    if (shouldCompareConstValues) {
      compareConstantValues(
          resynthesized.constantValue, original.constantValue, desc);
    }
    // TODO(paulberry): test initializer
  }

  /**
   * Serialize the given [library] into a summary.  Then create a
   * [_TestSummaryResynthesizer] which can deserialize it, along with any
   * references it makes to `dart:core`.
   *
   * Errors will lead to a test failure unless [allowErrors] is `true`.
   */
  _TestSummaryResynthesizer encodeLibrary(LibraryElementImpl library,
      {bool allowErrors: false}) {
    if (!allowErrors) {
      assertNoErrors(library.source);
    }
    addLibrary('dart:core');
    return encodeLibraryElement(library);
  }

  /**
   * Convert the library element [library] into a summary, and then create a
   * [_TestSummaryResynthesizer] which can deserialize it.
   *
   * Caller is responsible for checking the library for errors, and adding any
   * dependent libraries using [addLibrary].
   */
  _TestSummaryResynthesizer encodeLibraryElement(LibraryElementImpl library) {
    Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
    LinkedLibrary getLinkedSummaryFor(LibraryElement lib) {
      LibrarySerializationResult serialized = serializeLibrary(
          lib, typeProvider, analysisContext.analysisOptions.strongMode);
      for (int i = 0; i < serialized.unlinkedUnits.length; i++) {
        unlinkedSummaries[serialized.unitUris[i]] =
            new UnlinkedUnit.fromBuffer(serialized.unlinkedUnits[i].toBuffer());
      }
      return new LinkedLibrary.fromBuffer(serialized.linked.toBuffer());
    }
    Map<String, LinkedLibrary> linkedSummaries = <String, LinkedLibrary>{
      library.source.uri.toString(): getLinkedSummaryFor(library)
    };
    for (Source source in otherLibrarySources) {
      LibraryElement original = resolve2(source);
      String uri = source.uri.toString();
      linkedSummaries[uri] = getLinkedSummaryFor(original);
    }
    return new _TestSummaryResynthesizer(
        null,
        analysisContext,
        analysisContext.typeProvider,
        analysisContext.sourceFactory,
        unlinkedSummaries,
        linkedSummaries,
        options.strongMode);
  }

  fail_library_hasExtUri() {
    checkLibrary('import "dart-ext:doesNotExist.dart";');
  }

  ElementImpl getActualElement(Element element, String desc) {
    if (element is ElementHandle) {
      return element.actualElement;
    } else if (element is ElementImpl) {
      return element;
    } else {
      fail('Unexpected type for resynthesized ($desc):'
          ' ${element.runtimeType}');
      return null;
    }
  }

  /**
   * Resynthesize the library element associated with [uri] using
   * [resynthesizer], and verify that it only had to consult one summary in
   * order to do so.
   */
  LibraryElementImpl resynthesizeLibraryElement(
      _TestSummaryResynthesizer resynthesizer, String uri) {
    LibraryElementImpl resynthesized = resynthesizer.getLibraryElement(uri);
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 1);
    return resynthesized;
  }

  @override
  void setUp() {
    super.setUp();
    resetWithOptions(options);
  }

  test_class_abstract() {
    checkLibrary('abstract class C {}');
  }

  test_class_alias() {
    checkLibrary('class C = D with E, F; class D {} class E {} class F {}');
  }

  test_class_alias_abstract() {
    checkLibrary('abstract class C = D with E; class D {} class E {}');
  }

  test_class_alias_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''');
  }

  test_class_alias_with_forwarding_constructors() {
    addLibrarySource(
        '/a.dart',
        '''
class Base {
  Base._priv();
  Base();
  Base.noArgs();
  Base.requiredArg(x);
  Base.positionalArg([x]);
  Base.namedArg({x});
  factory Base.fact() => null;
  factory Base.fact2() = Base.noArgs;
}
''');
    checkLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution() {
    checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp = Base with M;
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution_complex() {
    checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp<U> = Base<List<U>> with M;
''');
  }

  test_class_alias_with_mixin_members() {
    checkLibrary('''
class C = D with E;
class D {}
class E {
  int get a => null;
  void set b(int i) {}
  void f() {}
  int x;
}''');
  }

  test_class_constructor_const() {
    checkLibrary('class C { const C(); }');
  }

  test_class_constructor_const_external() {
    checkLibrary('class C { external const C(); }');
  }

  test_class_constructor_explicit_named() {
    checkLibrary('class C { C.foo(); }');
  }

  test_class_constructor_explicit_type_params() {
    checkLibrary('class C<T, U> { C(); }');
  }

  test_class_constructor_explicit_unnamed() {
    checkLibrary('class C { C(); }');
  }

  test_class_constructor_external() {
    checkLibrary('class C { external C(); }');
  }

  test_class_constructor_factory() {
    checkLibrary('class C { factory C() => null; }');
  }

  test_class_constructor_field_formal_dynamic_dynamic() {
    checkLibrary('class C { dynamic x; C(dynamic this.x); }');
  }

  test_class_constructor_field_formal_dynamic_typed() {
    checkLibrary('class C { dynamic x; C(int this.x); }');
  }

  test_class_constructor_field_formal_dynamic_untyped() {
    checkLibrary('class C { dynamic x; C(this.x); }');
  }

  test_class_constructor_field_formal_multiple_matching_fields() {
    // This is a compile-time error but it should still analyze consistently.
    checkLibrary('class C { C(this.x); int x; String x; }', allowErrors: true);
  }

  test_class_constructor_field_formal_no_matching_field() {
    // This is a compile-time error but it should still analyze consistently.
    checkLibrary('class C { C(this.x); }', allowErrors: true);
  }

  test_class_constructor_field_formal_typed_dynamic() {
    checkLibrary('class C { num x; C(dynamic this.x); }', allowErrors: true);
  }

  test_class_constructor_field_formal_typed_typed() {
    checkLibrary('class C { num x; C(int this.x); }');
  }

  test_class_constructor_field_formal_typed_untyped() {
    checkLibrary('class C { num x; C(this.x); }');
  }

  test_class_constructor_field_formal_untyped_dynamic() {
    checkLibrary('class C { var x; C(dynamic this.x); }');
  }

  test_class_constructor_field_formal_untyped_typed() {
    checkLibrary('class C { var x; C(int this.x); }');
  }

  test_class_constructor_field_formal_untyped_untyped() {
    checkLibrary('class C { var x; C(this.x); }');
  }

  test_class_constructor_implicit() {
    checkLibrary('class C {}');
  }

  test_class_constructor_implicit_type_params() {
    checkLibrary('class C<T, U> {}');
  }

  test_class_constructor_params() {
    checkLibrary('class C { C(x, y); }');
  }

  test_class_constructors() {
    checkLibrary('class C { C.foo(); C.bar(); }');
  }

  test_class_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''');
  }

  test_class_documented_with_references() {
    checkLibrary('''
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''');
  }

  test_class_documented_with_windows_line_endings() {
    checkLibrary('/**\r\n * Docs\r\n */\r\nclass C {}');
  }

  test_class_field_const() {
    checkLibrary('class C { static const int i = 0; }');
  }

  test_class_field_implicit_type() {
    checkLibrary('class C { var x; }');
  }

  test_class_field_static() {
    checkLibrary('class C { static int i; }');
  }

  test_class_fields() {
    checkLibrary('class C { int i; int j; }');
  }

  test_class_getter_abstract() {
    checkLibrary('abstract class C { int get x; }');
  }

  test_class_getter_external() {
    checkLibrary('class C { external int get x; }');
  }

  test_class_getter_implicit_return_type() {
    checkLibrary('class C { get x => null; }');
  }

  test_class_getter_static() {
    checkLibrary('class C { static int get x => null; }');
  }

  test_class_getters() {
    checkLibrary('class C { int get x => null; get y => null; }');
  }

  test_class_implicitField_getterFirst() {
    checkLibrary('class C { int get x => 0; void set x(int value) {} }');
  }

  test_class_implicitField_setterFirst() {
    checkLibrary('class C { void set x(int value) {} int get x => 0; }');
  }

  test_class_interfaces() {
    checkLibrary('class C implements D, E {} class D {} class E {}');
  }

  test_class_method_abstract() {
    checkLibrary('abstract class C { f(); }');
  }

  test_class_method_external() {
    checkLibrary('class C { external f(); }');
  }

  test_class_method_params() {
    checkLibrary('class C { f(x, y) {} }');
  }

  test_class_method_static() {
    checkLibrary('class C { static f() {} }');
  }

  test_class_methods() {
    checkLibrary('class C { f() {} g() {} }');
  }

  test_class_mixins() {
    checkLibrary('class C extends Object with D, E {} class D {} class E {}');
  }

  test_class_setter_abstract() {
    checkLibrary('abstract class C { void set x(int value); }');
  }

  test_class_setter_external() {
    checkLibrary('class C { external void set x(int value); }');
  }

  test_class_setter_implicit_param_type() {
    checkLibrary('class C { void set x(value) {} }');
  }

  test_class_setter_implicit_return_type() {
    checkLibrary('class C { set x(int value) {} }');
  }

  test_class_setter_static() {
    checkLibrary('class C { static void set x(int value) {} }');
  }

  test_class_setters() {
    checkLibrary('class C { void set x(int value) {} set y(value) {} }');
  }

  test_class_supertype() {
    checkLibrary('class C extends D {} class D {}');
  }

  test_class_type_parameters() {
    checkLibrary('class C<T, U> {}');
  }

  test_class_type_parameters_bound() {
    checkLibrary('class C<T extends Object, U extends D> {} class D {}');
  }

  test_class_type_parameters_f_bound_complex() {
    checkLibrary('class C<T extends List<U>, U> {}');
  }

  test_class_type_parameters_f_bound_simple() {
    checkLibrary('class C<T extends U, U> {}');
  }

  test_classes() {
    checkLibrary('class C {} class D {}');
  }

  test_const_topLevel_binary() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vEqual = 1 == 2;
const vAnd = true && false;
const vOr = false || true;
const vBitXor = 1 ^ 2;
const vBitAnd = 1 & 2;
const vBitOr = 1 | 2;
const vBitShiftLeft = 1 << 2;
const vBitShiftRight = 1 >> 2;
const vAdd = 1 + 2;
const vSubtract = 1 - 2;
const vMiltiply = 1 * 2;
const vDivide = 1 / 2;
const vFloorDivide = 1 ~/ 2;
const vModulo = 1 % 2;
const vGreater = 1 > 2;
const vGreaterEqual = 1 >= 2;
const vLess = 1 < 2;
const vLessEqual = 1 <= 2;
''');
  }

  test_const_topLevel_conditional() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
  }

  test_const_topLevel_identical() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
  }

  test_const_topLevel_literal() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vNull = null;
const vBoolFalse = false;
const vBoolTrue = true;
const vInt = 1;
const vIntLong = 0x9876543210987654321;
const vDouble = 2.3;
const vString = 'abc';
const vStringConcat = 'aaa' 'bbb';
const vStringInterpolation = 'aaa ${true} ${42} bbb';
const vSymbol = #aaa.bbb.ccc;
''');
  }

  test_const_topLevel_typedList() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vNull = const <Null>[];
const vDynamic = const <dynamic>[1, 2, 3];
const vInterfaceNoTypeParameters = const <int>[1, 2, 3];
const vInterfaceNoTypeArguments = const <List>[];
const vInterfaceWithTypeArguments = const <List<String>>[];
const vInterfaceWithTypeArguments2 = const <Map<int, List<String>>>[];
''');
  }

  test_const_topLevel_typedList_imported() {
    shouldCompareConstValues = true;
    addNamedSource('/a.dart', 'class C {}');
    checkLibrary(r'''
import 'a.dart';
const v = const <C>[];
''');
  }

  test_const_topLevel_typedList_importedWithPrefix() {
    shouldCompareConstValues = true;
    addNamedSource('/a.dart', 'class C {}');
    checkLibrary(r'''
import 'a.dart' as p;
const v = const <p.C>[];
''');
  }

  test_const_topLevel_typedMap() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vDynamic1 = const <dynamic, int>{};
const vDynamic2 = const <int, dynamic>{};
const vInterface = const <int, String>{};
const vInterfaceWithTypeArguments = const <int, List<String>>{};
''');
  }

  test_const_topLevel_unary() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const vNotEqual = 1 != 2;
const vNot = !true;
const vNegate = -1;
const vComplement = ~1;
''');
  }

  test_const_topLevel_untypedList() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const v = const [1, 2, 3];
''');
  }

  test_const_topLevel_untypedMap() {
    shouldCompareConstValues = true;
    checkLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
  }

  test_constructor_documented() {
    checkLibrary('''
class C {
  /**
   * Docs
   */
  C();
}''');
  }

  test_core() {
    String uri = 'dart:core';
    LibraryElementImpl original =
        resolve2(analysisContext2.sourceFactory.forUri(uri));
    LibraryElementImpl resynthesized =
        resynthesizeLibraryElement(encodeLibraryElement(original), uri);
    checkLibraryElements(original, resynthesized);
  }

  test_enum_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''');
  }

  test_enum_value_documented() {
    checkLibrary('''
enum E {
  /**
   * Docs
   */
  v
}''');
  }

  test_enum_values() {
    checkLibrary('enum E { v1, v2 }');
  }

  test_enums() {
    checkLibrary('enum E1 { v1 } enum E2 { v2 }');
  }

  test_export_class() {
    addLibrarySource('/a.dart', 'class C {}');
    checkLibrary('export "a.dart";');
  }

  test_export_class_type_alias() {
    addLibrarySource(
        '/a.dart', 'class C {} exends _D with _E; class _D {} class _E {}');
    checkLibrary('export "a.dart";');
  }

  test_export_function() {
    addLibrarySource('/a.dart', 'f() {}');
    checkLibrary('export "a.dart";');
  }

  test_export_getter() {
    addLibrarySource('/a.dart', 'get f() => null;');
    checkLibrary('export "a.dart";');
  }

  test_export_hide() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" hide Stream, Future;');
  }

  test_export_multiple_combinators() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" hide Stream show Future;');
  }

  test_export_setter() {
    addLibrarySource('/a.dart', 'void set f(value) {}');
    checkLibrary('export "a.dart";');
  }

  test_export_show() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" show Future, Stream;');
  }

  test_export_typedef() {
    addLibrarySource('/a.dart', 'typedef F();');
    checkLibrary('export "a.dart";');
  }

  test_export_variable() {
    addLibrarySource('/a.dart', 'var x;');
    checkLibrary('export "a.dart";');
  }

  test_export_variable_const() {
    addLibrarySource('/a.dart', 'const x = 0;');
    checkLibrary('export "a.dart";');
  }

  test_export_variable_final() {
    addLibrarySource('/a.dart', 'final x = 0;');
    checkLibrary('export "a.dart";');
  }

  test_exports() {
    addLibrarySource('/a.dart', 'library a;');
    addLibrarySource('/b.dart', 'library b;');
    checkLibrary('export "a.dart"; export "b.dart";');
  }

  test_field_documented() {
    checkLibrary('''
class C {
  /**
   * Docs
   */
  var x;
}''');
  }

  test_field_formal_param_inferred_type_implicit() {
    checkLibrary('class C extends D { var v; C(this.v); }'
        ' abstract class D { int get v; }');
  }

  test_field_inferred_type_nonstatic_explicit_initialized() {
    checkLibrary('class C { num v = 0; }');
  }

  test_field_inferred_type_nonstatic_implicit_initialized() {
    checkLibrary('class C { var v = 0; }');
  }

  test_field_inferred_type_nonstatic_implicit_uninitialized() {
    checkLibrary(
        'class C extends D { var v; } abstract class D { int get v; }');
  }

  test_field_inferred_type_static_implicit_initialized() {
    checkLibrary('class C { static var v = 0; }');
  }

  test_field_propagatedType_const_noDep() {
    checkLibrary('''
class C {
  static const x = 0;
}''');
  }

  test_field_propagatedType_final_dep_inLib() {
    addNamedSource('/a.dart', 'final a = 1;');
    checkLibrary('''
import "a.dart";
class C {
  final b = a / 2;
}''');
  }

  test_field_propagatedType_final_dep_inPart() {
    addNamedSource('/a.dart', 'part of lib; final a = 1;');
    checkLibrary('''
library lib;
part "a.dart";
class C {
  final b = a / 2;
}''');
  }

  test_field_propagatedType_final_noDep_instance() {
    checkLibrary('''
class C {
  final x = 0;
}''');
  }

  test_field_propagatedType_final_noDep_static() {
    checkLibrary('''
class C {
  static final x = 0;
}''');
  }

  test_function_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''');
  }

  test_function_entry_point() {
    checkLibrary('main() {}');
  }

  test_function_entry_point_in_export() {
    addLibrarySource('/a.dart', 'library a; main() {}');
    checkLibrary('export "a.dart";');
  }

  test_function_entry_point_in_export_hidden() {
    addLibrarySource('/a.dart', 'library a; main() {}');
    checkLibrary('export "a.dart" hide main;');
  }

  test_function_entry_point_in_part() {
    addNamedSource('/a.dart', 'part of my.lib; main() {}');
    checkLibrary('library my.lib; part "a.dart";');
  }

  test_function_external() {
    checkLibrary('external f();');
  }

  test_function_parameter_kind_named() {
    // TODO(paulberry): also test default value.
    checkLibrary('f({x}) {}');
  }

  test_function_parameter_kind_positional() {
    // TODO(paulberry): also test default value.
    checkLibrary('f([x]) {}');
  }

  test_function_parameter_kind_required() {
    checkLibrary('f(x) {}');
  }

  test_function_parameter_parameters() {
    checkLibrary('f(g(x, y)) {}');
  }

  test_function_parameter_return_type() {
    checkLibrary('f(int g()) {}');
  }

  test_function_parameter_return_type_void() {
    checkLibrary('f(void g()) {}');
  }

  test_function_parameter_type() {
    checkLibrary('f(int i) {}');
  }

  test_function_parameters() {
    checkLibrary('f(x, y) {}');
  }

  test_function_return_type() {
    checkLibrary('int f() => null;');
  }

  test_function_return_type_implicit() {
    checkLibrary('f() => null;');
  }

  test_function_return_type_void() {
    checkLibrary('void f() {}');
  }

  test_function_type_parameter() {
    resetWithOptions(new AnalysisOptionsImpl()..enableGenericMethods = true);
    checkLibrary('T f<T, U>(U u) => null;');
  }

  test_function_type_parameter_with_function_typed_parameter() {
    resetWithOptions(new AnalysisOptionsImpl()..enableGenericMethods = true);
    checkLibrary('void f<T, U>(T x(U u)) {}');
  }

  test_functions() {
    checkLibrary('f() {} g() {}');
  }

  test_getElement_constructor_named() {
    ConstructorElement original = resolve2(addSource('class C { C.named(); }'))
        .getType('C')
        .getNamedConstructor('named');
    expect(original, isNotNull);
    ConstructorElement resynthesized = validateGetElement(original);
    compareConstructorElements(resynthesized, original, 'C.constructor named');
  }

  test_getElement_constructor_unnamed() {
    ConstructorElement original =
        resolve2(addSource('class C { C(); }')).getType('C').unnamedConstructor;
    expect(original, isNotNull);
    ConstructorElement resynthesized = validateGetElement(original);
    compareConstructorElements(resynthesized, original, 'C.constructor');
  }

  test_getElement_field() {
    FieldElement original =
        resolve2(addSource('class C { var f; }')).getType('C').getField('f');
    expect(original, isNotNull);
    FieldElement resynthesized = validateGetElement(original);
    compareFieldElements(resynthesized, original, 'C.field f');
  }

  test_getElement_getter() {
    PropertyAccessorElement original =
        resolve2(addSource('class C { get f => null; }'))
            .getType('C')
            .getGetter('f');
    expect(original, isNotNull);
    PropertyAccessorElement resynthesized = validateGetElement(original);
    comparePropertyAccessorElements(resynthesized, original, 'C.getter f');
  }

  test_getElement_method() {
    MethodElement original =
        resolve2(addSource('class C { f() {} }')).getType('C').getMethod('f');
    expect(original, isNotNull);
    MethodElement resynthesized = validateGetElement(original);
    compareMethodElements(resynthesized, original, 'C.method f');
  }

  test_getElement_operator() {
    MethodElement original =
        resolve2(addSource('class C { operator+(x) => null; }'))
            .getType('C')
            .getMethod('+');
    expect(original, isNotNull);
    MethodElement resynthesized = validateGetElement(original);
    compareMethodElements(resynthesized, original, 'C.operator+');
  }

  test_getElement_setter() {
    PropertyAccessorElement original =
        resolve2(addSource('class C { void set f(value) {} }'))
            .getType('C')
            .getSetter('f');
    expect(original, isNotNull);
    PropertyAccessorElement resynthesized = validateGetElement(original);
    comparePropertyAccessorElements(resynthesized, original, 'C.setter f');
  }

  test_getter_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get x => null;''');
  }

  test_getter_external() {
    checkLibrary('external int get x;');
  }

  test_getter_inferred_type_nonstatic_implicit_return() {
    checkLibrary(
        'class C extends D { get f => null; } abstract class D { int get f; }');
  }

  test_getters() {
    checkLibrary('int get x => null; get y => null;');
  }

  test_implicitTopLevelVariable_getterFirst() {
    checkLibrary('int get x => 0; void set x(int value) {}');
  }

  test_implicitTopLevelVariable_setterFirst() {
    checkLibrary('void set x(int value) {} int get x => 0;');
  }

  test_import_deferred() {
    addLibrarySource('/a.dart', 'f() {}');
    checkLibrary('import "a.dart" deferred as p; main() { p.f(); }');
  }

  test_import_hide() {
    addLibrary('dart:async');
    checkLibrary('import "dart:async" hide Stream, Completer; Future f;');
  }

  test_import_multiple_combinators() {
    addLibrary('dart:async');
    checkLibrary('import "dart:async" hide Stream show Future; Future f;');
  }

  test_import_prefixed() {
    addLibrarySource('/a.dart', 'library a; class C {}');
    checkLibrary('import "a.dart" as a; a.C c;');
  }

  test_import_show() {
    addLibrary('dart:async');
    checkLibrary('import "dart:async" show Future, Stream; Future f;');
  }

  test_imports() {
    addLibrarySource('/a.dart', 'library a; class C {}');
    addLibrarySource('/b.dart', 'library b; class D {}');
    checkLibrary('import "a.dart"; import "b.dart"; C c; D d;');
  }

  test_inferred_type_is_typedef() {
    checkLibrary('typedef int F(String s);'
        ' class C extends D { var v; }'
        ' abstract class D { F get v; }');
  }

  test_inferred_type_refers_to_bound_type_param() {
    checkLibrary('class C<T> extends D<int, T> { var v; }'
        ' abstract class D<U, V> { Map<V, U> get v; }');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() {
    checkLibrary('class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() {
    checkLibrary('class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }');
  }

  test_library() {
    checkLibrary('');
  }

  test_library_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
library foo;''');
  }

  test_library_name_with_spaces() {
    checkLibrary('library foo . bar ;');
  }

  test_library_named() {
    checkLibrary('library foo.bar;');
  }

  test_main_class() {
    checkLibrary('class main {}');
  }

  test_main_class_alias() {
    checkLibrary('class main = C with D; class C {} class D {}');
  }

  test_main_class_alias_via_export() {
    addLibrarySource('/a.dart', 'class main = C with D; class C {} class D {}');
    checkLibrary('export "a.dart";');
  }

  test_main_class_via_export() {
    addLibrarySource('/a.dart', 'class main {}');
    checkLibrary('export "a.dart";');
  }

  test_main_getter() {
    checkLibrary('get main => null;');
  }

  test_main_getter_via_export() {
    addLibrarySource('/a.dart', 'get main => null;');
    checkLibrary('export "a.dart";');
  }

  test_main_typedef() {
    checkLibrary('typedef main();');
  }

  test_main_typedef_via_export() {
    addLibrarySource('/a.dart', 'typedef main();');
    checkLibrary('export "a.dart";');
  }

  test_main_variable() {
    checkLibrary('var main;');
  }

  test_main_variable_via_export() {
    addLibrarySource('/a.dart', 'var main;');
    checkLibrary('export "a.dart";');
  }

  test_method_documented() {
    checkLibrary('''
class C {
  /**
   * Docs
   */
  f() {}
}''');
  }

  test_method_inferred_type_nonstatic_implicit_param() {
    checkLibrary('class C extends D { void f(value) {} }'
        ' abstract class D { void f(int value); }');
  }

  test_method_inferred_type_nonstatic_implicit_return() {
    checkLibrary(
        'class C extends D { f() => null; } abstract class D { int f(); }');
  }

  test_method_parameter_parameters() {
    checkLibrary('class C { f(g(x, y)) {} }');
  }

  test_method_parameter_parameters_in_generic_class() {
    checkLibrary('class C<A, B> { f(A g(B x)) {} }');
  }

  test_method_parameter_return_type() {
    checkLibrary('class C { f(int g()) {} }');
  }

  test_method_parameter_return_type_void() {
    checkLibrary('class C { f(void g()) {} }');
  }

  test_method_type_parameter() {
    resetWithOptions(new AnalysisOptionsImpl()..enableGenericMethods = true);
    checkLibrary('class C { T f<T, U>(U u) => null; }');
  }

  test_method_type_parameter_in_generic_class() {
    resetWithOptions(new AnalysisOptionsImpl()..enableGenericMethods = true);
    checkLibrary('class C<T, U> { V f<V, W>(T t, U u, W w) => null; }');
  }

  test_method_type_parameter_with_function_typed_parameter() {
    resetWithOptions(new AnalysisOptionsImpl()..enableGenericMethods = true);
    checkLibrary('class C { void f<T, U>(T x(U u)) {} }');
  }

  test_operator() {
    checkLibrary('class C { C operator+(C other) => null; }');
  }

  test_operator_equal() {
    checkLibrary('class C { bool operator==(Object other) => false; }');
  }

  test_operator_external() {
    checkLibrary('class C { external C operator+(C other); }');
  }

  test_operator_greater_equal() {
    checkLibrary('class C { bool operator>=(C other) => false; }');
  }

  test_operator_index() {
    checkLibrary('class C { bool operator[](int i) => null; }');
  }

  test_operator_index_set() {
    checkLibrary('class C { void operator[]=(int i, bool v) {} }');
  }

  test_operator_less_equal() {
    checkLibrary('class C { bool operator<=(C other) => false; }');
  }

  test_parts() {
    addNamedSource('/a.dart', 'part of my.lib;');
    addNamedSource('/b.dart', 'part of my.lib;');
    checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
  }

  test_setter_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set x(value) {}''');
  }

  test_setter_external() {
    checkLibrary('external void set x(int value);');
  }

  test_setter_inferred_type_nonstatic_implicit_param() {
    checkLibrary('class C extends D { void set f(value) {} }'
        ' abstract class D { void set f(int value); }');
  }

  test_setter_inferred_type_static_implicit_return() {
    checkLibrary('class C { static set f(int value) {} }');
  }

  test_setter_inferred_type_top_level_implicit_return() {
    checkLibrary('set f(int value) {}');
  }

  test_setters() {
    checkLibrary('void set x(int value) {} set y(value) {}');
  }

  test_type_arguments_explicit_dynamic_dynamic() {
    checkLibrary('Map<dynamic, dynamic> m;');
  }

  test_type_arguments_explicit_dynamic_int() {
    checkLibrary('Map<dynamic, int> m;');
  }

  test_type_arguments_explicit_String_dynamic() {
    checkLibrary('Map<String, dynamic> m;');
  }

  test_type_arguments_explicit_String_int() {
    checkLibrary('Map<String, int> m;');
  }

  test_type_arguments_implicit() {
    checkLibrary('Map m;');
  }

  test_type_dynamic() {
    checkLibrary('dynamic d;');
  }

  test_type_reference_lib_to_lib() {
    checkLibrary('class C {} enum E { v } typedef F(); C c; E e; F f;');
  }

  test_type_reference_lib_to_part() {
    addNamedSource(
        '/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    checkLibrary('library l; part "a.dart"; C c; E e; F f;');
  }

  test_type_reference_part_to_lib() {
    addNamedSource('/a.dart', 'part of l; C c; E e; F f;');
    checkLibrary(
        'library l; part "a.dart"; class C {} enum E { v } typedef F();');
  }

  test_type_reference_part_to_other_part() {
    addNamedSource(
        '/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    addNamedSource('/b.dart', 'part of l; C c; E e; F f;');
    checkLibrary('library l; part "a.dart"; part "b.dart";');
  }

  test_type_reference_part_to_part() {
    addNamedSource('/a.dart',
        'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;');
    checkLibrary('library l; part "a.dart";');
  }

  test_type_reference_to_class() {
    checkLibrary('class C {} C c;');
  }

  test_type_reference_to_class_with_type_arguments() {
    checkLibrary('class C<T, U> {} C<int, String> c;');
  }

  test_type_reference_to_class_with_type_arguments_implicit() {
    checkLibrary('class C<T, U> {} C c;');
  }

  test_type_reference_to_enum() {
    checkLibrary('enum E { v } E e;');
  }

  test_type_reference_to_import() {
    addLibrarySource('/a.dart', 'class C {} enum E { v }; typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export() {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export_export() {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'export "c.dart";');
    addLibrarySource('/c.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export_export_in_subdirs() {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'export "../c/c.dart";');
    addLibrarySource('/a/c/c.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a/a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_export_in_subdirs() {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a/a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_part() {
    addLibrarySource('/a.dart', 'library l; part "b.dart";');
    addNamedSource(
        '/b.dart', 'part of l; class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_part2() {
    addLibrarySource('/a.dart', 'library l; part "p1.dart"; part "p2.dart";');
    addNamedSource('/p1.dart', 'part of l; class C1 {}');
    addNamedSource('/p2.dart', 'part of l; class C2 {}');
    checkLibrary('import "a.dart"; C1 c1; C2 c2;');
  }

  test_type_reference_to_import_part_in_subdir() {
    addLibrarySource('/a/b.dart', 'library l; part "c.dart";');
    addNamedSource(
        '/a/c.dart', 'part of l; class C {} enum E { v } typedef F();');
    checkLibrary('import "a/b.dart"; C c; E e; F f;');
  }

  test_type_reference_to_import_relative() {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    checkLibrary('import "a.dart"; C c; E e; F f;');
  }

  test_type_reference_to_typedef() {
    checkLibrary('typedef F(); F f;');
  }

  test_type_reference_to_typedef_with_type_arguments() {
    checkLibrary('typedef U F<T, U>(T t); F<int, String> f;');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() {
    checkLibrary('typedef U F<T, U>(T t); F f;');
  }

  test_type_unresolved() {
    checkLibrary('C c;', allowErrors: true);
  }

  test_type_unresolved_prefixed() {
    checkLibrary('import "dart:core" as core; core.C c;', allowErrors: true);
  }

  test_typedef_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''');
  }

  test_typedef_parameter_parameters() {
    checkLibrary('typedef F(g(x, y));');
  }

  test_typedef_parameter_parameters_in_generic_class() {
    checkLibrary('typedef F<A, B>(A g(B x));');
  }

  test_typedef_parameter_return_type() {
    checkLibrary('typedef F(int g());');
  }

  test_typedef_parameter_type() {
    checkLibrary('typedef F(int i);');
  }

  test_typedef_parameter_type_generic() {
    checkLibrary('typedef F<T>(T t);');
  }

  test_typedef_parameters() {
    checkLibrary('typedef F(x, y);');
  }

  test_typedef_return_type() {
    checkLibrary('typedef int F();');
  }

  test_typedef_return_type_generic() {
    checkLibrary('typedef T F<T>();');
  }

  test_typedef_return_type_implicit() {
    checkLibrary('typedef F();');
  }

  test_typedef_return_type_void() {
    checkLibrary('typedef void F();');
  }

  test_typedef_type_parameters() {
    checkLibrary('typedef U F<T, U>(T t);');
  }

  test_typedef_type_parameters_bound() {
    checkLibrary('typedef U F<T extends Object, U extends D>(T t); class D {}');
  }

  test_typedef_type_parameters_f_bound_complex() {
    checkLibrary('typedef U F<T extends List<U>, U>(T t);');
  }

  test_typedef_type_parameters_f_bound_simple() {
    checkLibrary('typedef U F<T extends U, U>(T t);');
  }

  test_typedefs() {
    checkLibrary('f() {} g() {}');
  }

  test_variable_const() {
    checkLibrary('const int i = 0;');
  }

  test_variable_documented() {
    checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var x;''');
  }

  test_variable_final() {
    checkLibrary('final int x = 0;');
  }

  test_variable_getterInLib_setterInPart() {
    addNamedSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    checkLibrary('library my.lib; part "a.dart"; int get x => 42;');
  }

  test_variable_getterInPart_setterInLib() {
    addNamedSource('/a.dart', 'part of my.lib; int get x => 42;');
    checkLibrary('library my.lib; part "a.dart"; void set x(int _) {}');
  }

  test_variable_getterInPart_setterInPart() {
    addNamedSource('/a.dart', 'part of my.lib; int get x => 42;');
    addNamedSource('/b.dart', 'part of my.lib; void set x(int _) {}');
    checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
  }

  test_variable_implicit_type() {
    checkLibrary('var x;');
  }

  test_variable_inferred_type_implicit_initialized() {
    checkLibrary('var v = 0;');
  }

  test_variable_propagatedType_const_noDep() {
    checkLibrary('const i = 0;');
  }

  test_variable_propagatedType_final_dep_inLib() {
    addNamedSource('/a.dart', 'final a = 1;');
    checkLibrary('import "a.dart"; final b = a / 2;');
  }

  test_variable_propagatedType_final_dep_inPart() {
    addNamedSource('/a.dart', 'part of lib; final a = 1;');
    checkLibrary('library lib; part "a.dart"; final b = a / 2;');
  }

  test_variable_propagatedType_final_noDep() {
    checkLibrary('final i = 0;');
  }

  test_variable_propagatedType_implicit_dep() {
    // The propagated type is defined in a library that is not imported.
    addNamedSource('/a.dart', 'class C {}');
    addNamedSource('/b.dart', 'import "a.dart"; C f() => null;');
    checkLibrary('import "b.dart"; final x = f();');
  }

  test_variable_setterInPart_getterInPart() {
    addNamedSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    addNamedSource('/b.dart', 'part of my.lib; int get x => 42;');
    checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
  }

  test_variables() {
    checkLibrary('int i; int j;');
  }

  /**
   * Encode the library containing [original] into a summary and then use
   * [_TestSummaryResynthesizer.getElement] to retrieve just the original
   * element from the resynthesized summary.
   */
  Element validateGetElement(Element original) {
    _TestSummaryResynthesizer resynthesizer = encodeLibrary(original.library);
    ElementLocationImpl location = original.location;
    Element result = resynthesizer.getElement(location);
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 1);
    expect(result.location, location);
    return result;
  }
}

class _TestSummaryResynthesizer extends SummaryResynthesizer {
  final Map<String, UnlinkedUnit> unlinkedSummaries;
  final Map<String, LinkedLibrary> linkedSummaries;

  _TestSummaryResynthesizer(
      SummaryResynthesizer parent,
      AnalysisContext context,
      TypeProvider typeProvider,
      SourceFactory sourceFactory,
      this.unlinkedSummaries,
      this.linkedSummaries,
      bool strongMode)
      : super(parent, context, typeProvider, sourceFactory, strongMode);

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    LinkedLibrary serializedLibrary = linkedSummaries[uri];
    if (serializedLibrary == null) {
      fail('Unexpectedly tried to get linked summary for $uri');
    }
    return serializedLibrary;
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    UnlinkedUnit serializedUnit = unlinkedSummaries[uri];
    if (serializedUnit == null) {
      fail('Unexpectedly tried to get unlinked summary for $uri');
    }
    return serializedUnit;
  }

  @override
  bool hasLibrarySummary(String uri) {
    return true;
  }
}
