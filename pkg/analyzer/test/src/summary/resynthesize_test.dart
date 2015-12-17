// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.serialization.elements_test;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/builder.dart';
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

  void addLibrary(String uri) {
    otherLibrarySources.add(analysisContext2.sourceFactory.forUri(uri));
  }

  void addLibrarySource(String filePath, String contents) {
    otherLibrarySources.add(addNamedSource(filePath, contents));
  }

  void checkLibrary(String text, {bool allowErrors: false}) {
    Source source = addSource(text);
    LibraryElementImpl original = resolve2(source);
    LibraryElementImpl resynthesized =
        resynthesizeLibrary(source, original, allowErrors);
    checkLibraryElements(original, resynthesized);
  }

  void checkLibraryElements(
      LibraryElementImpl original, LibraryElementImpl resynthesized) {
    compareElements(resynthesized, original, '(library)');
    expect(resynthesized.displayName, original.displayName);
    expect(original.enclosingElement, isNull);
    expect(resynthesized.enclosingElement, isNull);
    compareCompilationUnitElements(resynthesized.definingCompilationUnit,
        original.definingCompilationUnit);
    expect(resynthesized.parts.length, original.parts.length);
    for (int i = 0; i < resynthesized.parts.length; i++) {
      compareCompilationUnitElements(resynthesized.parts[i], original.parts[i]);
    }
    expect(resynthesized.imports.length, original.imports.length);
    for (int i = 0; i < resynthesized.imports.length; i++) {
      compareImportElements(resynthesized.imports[i], original.imports[i],
          'import ${original.imports[i].name}');
    }
    expect(resynthesized.exports.length, original.exports.length);
    for (int i = 0; i < resynthesized.exports.length; i++) {
      compareExportElements(resynthesized.exports[i], original.exports[i],
          'export ${original.exports[i].name}');
    }
    // TODO(paulberry): test entryPoint, exportNamespace, publicNamespace,
    // and metadata.
  }

  void compareClassElements(
      ClassElementImpl resynthesized, ClassElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    expect(resynthesized.fields.length, original.fields.length,
        reason: '$desc fields.length');
    for (int i = 0; i < resynthesized.fields.length; i++) {
      String name = original.fields[i].name;
      compareFieldElements(resynthesized.getField(name), original.fields[i],
          '$desc.field $name');
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
      String name = original.accessors[i].name;
      if (name.endsWith('=')) {
        comparePropertyAccessorElements(resynthesized.getSetter(name),
            original.accessors[i], '$desc.${original.accessors[i].name}=');
      } else {
        comparePropertyAccessorElements(resynthesized.getGetter(name),
            original.accessors[i], '$desc.${original.accessors[i].name}');
      }
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
    compareUriReferencedElements(resynthesized, original, '(compilation unit)');
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
      compareTopLevelVariableElements(resynthesized.topLevelVariables[i],
          original.topLevelVariables[i], original.topLevelVariables[i].name);
    }
    expect(resynthesized.functions.length, original.functions.length);
    for (int i = 0; i < resynthesized.functions.length; i++) {
      compareFunctionElements(resynthesized.functions[i], original.functions[i],
          original.functions[i].name);
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
      comparePropertyAccessorElements(resynthesized.accessors[i],
          original.accessors[i], original.accessors[i].name);
    }
    // TODO(paulberry): test metadata and offsetToElementMap.
  }

  void compareConstructorElements(ConstructorElementImpl resynthesized,
      ConstructorElementImpl original, String desc) {
    compareExecutableElements(resynthesized, original, desc);
    // TODO(paulberry): test redirectedConstructor and constantInitializers
  }

  void compareElements(
      ElementImpl resynthesized, ElementImpl original, String desc) {
    expect(resynthesized, isNotNull);
    expect(resynthesized.kind, original.kind);
    expect(resynthesized.location, original.location, reason: desc);
    expect(resynthesized.name, original.name);
    for (Modifier modifier in Modifier.values) {
      if (modifier == Modifier.MIXIN) {
        // Skipping for now.  TODO(paulberry): fix.
        continue;
      }
      bool got = resynthesized.hasModifier(modifier);
      bool want = original.hasModifier(modifier);
      expect(got, want,
          reason: 'Mismatch in $desc.$modifier: got $got, want $want');
    }
  }

  void compareExecutableElements(ExecutableElementImpl resynthesized,
      ExecutableElementImpl original, String desc) {
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

  void compareFunctionElements(FunctionElementImpl resynthesized,
      FunctionElementImpl original, String desc) {
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

  void compareTypeImpls(TypeImpl resynthesized, TypeImpl original) {
    expect(resynthesized.element.location, original.element.location);
    expect(resynthesized.name, original.name);
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
      compareTypeImpls(resynthesized, original);
      expect(resynthesized.typeArguments.length, original.typeArguments.length);
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc type argument ${original.typeArguments[i].name}');
      }
    } else if (resynthesized is TypeParameterTypeImpl &&
        original is TypeParameterTypeImpl) {
      compareTypeImpls(resynthesized, original);
    } else if (resynthesized is DynamicTypeImpl &&
        original is DynamicTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is UndefinedTypeImpl &&
        original is UndefinedTypeImpl) {
      expect(resynthesized, same(original));
    } else if (resynthesized is FunctionTypeImpl &&
        original is FunctionTypeImpl) {
      compareTypeImpls(resynthesized, original);
      if (original.element.isSynthetic &&
          original.element is FunctionTypeAliasElementImpl &&
          resynthesized.element is FunctionTypeAliasElementImpl) {
        compareFunctionTypeAliasElements(
            resynthesized.element, original.element, desc);
      }
      for (int i = 0; i < resynthesized.typeArguments.length; i++) {
        compareTypes(resynthesized.typeArguments[i], original.typeArguments[i],
            '$desc type argument ${original.typeArguments[i].name}');
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
  }

  void compareVariableElements(VariableElementImpl resynthesized,
      VariableElementImpl original, String desc) {
    compareElements(resynthesized, original, desc);
    compareTypes(resynthesized.type, original.type, desc);
    // TODO(paulberry): test initializer
  }

  LibraryElementImpl resynthesizeLibrary(
      Source source, LibraryElementImpl original, bool allowErrors) {
    if (!allowErrors) {
      assertNoErrors(source);
    }
    String uri = source.uri.toString();
    addLibrary('dart:core');
    return resynthesizeLibraryElement(uri, original);
  }

  LibraryElementImpl resynthesizeLibraryElement(
      String uri, LibraryElementImpl original) {
    Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
    PrelinkedLibrary getPrelinkedSummaryFor(LibraryElement lib) {
      BuilderContext ctx = new BuilderContext();
      LibrarySerializationResult serialized =
          serializeLibrary(ctx, lib, typeProvider);
      for (int i = 0; i < serialized.unlinkedUnits.length; i++) {
        unlinkedSummaries[serialized.unitUris[i]] =
            new UnlinkedUnit.fromBuffer(serialized.unlinkedUnits[i].toBuffer());
      }
      return new PrelinkedLibrary.fromBuffer(serialized.prelinked.toBuffer());
    }
    Map<String, PrelinkedLibrary> prelinkedSummaries =
        <String, PrelinkedLibrary>{uri: getPrelinkedSummaryFor(original)};
    for (Source source in otherLibrarySources) {
      LibraryElement original = resolve2(source);
      String uri = source.uri.toString();
      prelinkedSummaries[uri] = getPrelinkedSummaryFor(original);
    }
    PrelinkedLibrary getPrelinkedSummary(String uri) {
      PrelinkedLibrary serializedLibrary = prelinkedSummaries[uri];
      if (serializedLibrary == null) {
        fail('Unexpectedly tried to get prelinked summary for $uri');
      }
      return serializedLibrary;
    }
    UnlinkedUnit getUnlinkedSummary(String uri) {
      UnlinkedUnit serializedUnit = unlinkedSummaries[uri];
      if (serializedUnit == null) {
        fail('Unexpectedly tried to get unlinked summary for $uri');
      }
      return serializedUnit;
    }
    SummaryResynthesizer resynthesizer = new SummaryResynthesizer(
        analysisContext,
        getPrelinkedSummary,
        getUnlinkedSummary,
        analysisContext.sourceFactory);
    LibraryElementImpl resynthesized = resynthesizer.getLibraryElement(uri);
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 1);
    return resynthesized;
  }

  test_class_alias() {
    checkLibrary('class C = D with E, F; class D {} class E {} class F {}');
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

  test_class_field_const() {
    checkLibrary('class C { static const int i = 0; }');
  }

  test_class_field_static() {
    checkLibrary('class C { static int i; }');
  }

  test_class_fields() {
    checkLibrary('class C { int i; int j; }');
  }

  test_class_getter_external() {
    checkLibrary('class C { external int get x; }');
  }

  test_class_getter_static() {
    checkLibrary('class C { static int get x => null; }');
  }

  test_class_getters() {
    checkLibrary('class C { int get x => null; get y => null; }');
  }

  test_class_interfaces() {
    checkLibrary('class C implements D, E {} class D {} class E {}');
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

  test_class_setter_external() {
    checkLibrary('class C { external void set x(int value); }');
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

  test_core() {
    String uri = 'dart:core';
    LibraryElementImpl original =
        resolve2(analysisContext2.sourceFactory.forUri(uri));
    LibraryElementImpl resynthesized =
        resynthesizeLibraryElement(uri, original);
    checkLibraryElements(original, resynthesized);
  }

  test_enum_values() {
    checkLibrary('enum E { v1, v2 }');
  }

  test_enums() {
    checkLibrary('enum E1 { v1 } enum E2 { v2 }');
  }

  test_export_hide() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" hide Stream, Future;');
  }

  test_export_multiple_combinators() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" hide Stream show Future;');
  }

  test_export_show() {
    addLibrary('dart:async');
    checkLibrary('export "dart:async" show Future, Stream;');
  }

  test_exports() {
    addLibrarySource('/a.dart', 'library a;');
    addLibrarySource('/b.dart', 'library b;');
    checkLibrary('export "a.dart"; export "b.dart";');
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

  test_functions() {
    checkLibrary('f() {} g() {}');
  }

  test_getter_external() {
    checkLibrary('external int get x;');
  }

  test_getters() {
    checkLibrary('int get x => null; get y => null;');
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

  test_library() {
    checkLibrary('');
  }

  test_library_named() {
    checkLibrary('library foo.bar;');
  }

  test_method_parameter_parameters() {
    checkLibrary('class C { f(g(x, y)) {} }');
  }

  test_method_parameter_return_type() {
    checkLibrary('class C { f(int g()) {} }');
  }

  test_method_parameter_return_type_void() {
    checkLibrary('class C { f(void g()) {} }');
  }

  test_operator() {
    checkLibrary('class C { C operator+(C other) => null; }');
  }

  test_operator_equal() {
    checkLibrary('class C { bool operator==(C other) => false; }');
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

  test_setter_external() {
    checkLibrary('external void set x(int value);');
  }

  test_setters() {
    checkLibrary('void set x(int value) {} set y(value) {}');
  }

  test_type_arguments_explicit() {
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

  test_typedef_parameter_parameters() {
    checkLibrary('typedef F(g(x, y));');
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

  test_variables() {
    checkLibrary('int i; int j;');
  }
}
