// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resynthesize_common.dart';
import 'test_strategies.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeAst2Test);
  });
}

@reflectiveTest
class ResynthesizeAst2Test extends ResynthesizeTestStrategyTwoPhase
    with ResynthesizeTestCases {
  @override
  bool get isAstBasedSummary => true;

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors = false, bool dumpSummaries = false}) async {
    var dartCoreSource = sourceFactory.forUri('dart:core');
    var dartAsyncSource = sourceFactory.forUri('dart:async');
    var dartMathSource = sourceFactory.forUri('dart:math');

    var dartCoreCode = getFile(dartCoreSource.fullName).readAsStringSync();
    dartCoreCode = r'''
library dart.core;

abstract class Comparable<T> {
  int compareTo(T other);
}

class Iterable<T> {}

class Iterator<T> {}

class List<T> {}

class Map<K, V> {}

abstract class Null {}

class Object {
  const Object();
}

abstract class String {
  int get length;
  String operator +(String other);
}

class Set<T> {}

abstract class Symbol {}

abstract class Type {}

abstract class bool {}

abstract class double extends num {}

abstract class int extends num {
  bool get isEven => false;
  bool get isNegative;
  
  int operator &(int other);
  int operator -();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);
  int operator ^(int other);
  int operator |(int other);
  int operator ~();
}

abstract class num implements Comparable<num> {
  bool operator <(num other);
  bool operator <=(num other);
  bool operator ==(Object other);
  bool operator >(num other);
  bool operator >=(num other);
  
  double operator /(num other);
  double toDouble();
  
  int operator <<(int other);
  int operator >>(int other);
  int operator ^(int other);
  int operator |(int other);
  int operator ~();
  int operator ~/(num other);
  
  int round();
  int toInt();
  num abs();
  
  num operator %(num other);
  num operator *(num other);
  num operator +(num other);
  num operator -();
  num operator -(num other);
}
''';

    var dartAsyncCode = r'''
library dart.async;

class Future<T> {}

class FutureOr<T> {}

class Stream<T> {}
''';

    var dartMathCode = r'''
library dart.math;

const double E = 2.718281828459045;
const double PI = 3.1415926535897932;
const double LN10 =  2.302585092994046;

T min<T extends num>(T a, T b) => null;
T max<T extends num>(T a, T b) => null;
''';

    var dartCoreResult = _link({
      dartCoreSource: dartCoreCode,
      dartAsyncSource: dartAsyncCode,
      dartMathSource: dartMathCode,
    });

    var source = addTestSource(text);
    var unit = parseText(text, experimentStatus: experimentStatus);

    var libraryUnitMap = {
      source: _unitsOfLibrary(source, unit),
    };

    for (var otherLibrarySource in otherLibrarySources) {
      var text = getFile(otherLibrarySource.fullName).readAsStringSync();
      var unit = parseText(text, experimentStatus: experimentStatus);
      var unitMap = _unitsOfLibrary(otherLibrarySource, unit);
      libraryUnitMap[otherLibrarySource] = unitMap;
    }

    var linkResult = link(
      AnalysisOptionsImpl(),
      sourceFactory,
      [dartCoreResult.bundle],
      libraryUnitMap,
    );

    var analysisContext = _FakeAnalysisContext(sourceFactory);

    var rootReference = Reference.root();
    rootReference.getChild('dart:core').getChild('dynamic').element =
        DynamicElementImpl.instance;

    var elementFactory = LinkedElementFactory(
      analysisContext,
      null,
      rootReference,
    );
    elementFactory.addBundle(
      LinkedBundleContext(elementFactory, dartCoreResult.bundle),
    );
    elementFactory.addBundle(
      LinkedBundleContext(elementFactory, linkResult.bundle),
    );

    var dartCore = elementFactory.libraryOfUri('dart:core');
    var dartAsync = elementFactory.libraryOfUri('dart:async');
    var typeProvider = SummaryTypeProvider()
      ..initializeCore(dartCore)
      ..initializeAsync(dartAsync);
    analysisContext.typeProvider = typeProvider;
    analysisContext.typeSystem = Dart2TypeSystem(typeProvider);

    return elementFactory.libraryOfUri('${source.uri}');
  }

  @override
  @failingTest
  test_class_type_parameters_bound() async {
    await super.test_class_type_parameters_bound();
  }

  @override
  @failingTest
  test_const_constructor_inferred_args() async {
    await super.test_const_constructor_inferred_args();
  }

  @override
  @failingTest
  test_const_finalField_hasConstConstructor() async {
    // TODO(scheglov) Needs initializer, because of const constructor.
    await super.test_const_finalField_hasConstConstructor();
  }

  @override
  @failingTest
  test_const_reference_topLevelVariable_imported() async {
    await super.test_const_reference_topLevelVariable_imported();
  }

  @override
  @failingTest
  test_const_reference_topLevelVariable_imported_withPrefix() async {
    await super.test_const_reference_topLevelVariable_imported_withPrefix();
  }

  @override
  @failingTest
  test_const_topLevel_typedList_typedefArgument() async {
    await super.test_const_topLevel_typedList_typedefArgument();
  }

  @override
  @failingTest
  test_constExpr_pushReference_field_simpleIdentifier() async {
    await super.test_constExpr_pushReference_field_simpleIdentifier();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_generic() async {
    await super.test_constructor_redirected_factory_named_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_imported_generic() async {
    await super.test_constructor_redirected_factory_named_imported_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_prefixed_generic() async {
    await super.test_constructor_redirected_factory_named_prefixed_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_imported_generic() async {
    await super.test_constructor_redirected_factory_unnamed_imported_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed_generic();
  }

  @override
  @failingTest
  test_export_configurations_useFirst() async {
    await super.test_export_configurations_useFirst();
  }

  @override
  @failingTest
  test_export_configurations_useSecond() async {
    await super.test_export_configurations_useSecond();
  }

  @override
  @failingTest
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
  }

  @override
  @failingTest
  test_field_formal_param_inferred_type_implicit() async {
    await super.test_field_formal_param_inferred_type_implicit();
  }

  @override
  @failingTest
  test_field_inferred_type_nonStatic_implicit_uninitialized() async {
    await super.test_field_inferred_type_nonStatic_implicit_uninitialized();
  }

  @override
  @failingTest
  test_field_propagatedType_final_dep_inLib() async {
    await super.test_field_propagatedType_final_dep_inLib();
  }

  @override
  @failingTest
  test_field_propagatedType_final_dep_inPart() async {
    await super.test_field_propagatedType_final_dep_inPart();
  }

  @override
  @failingTest
  test_getter_inferred_type_nonStatic_implicit_return() async {
    await super.test_getter_inferred_type_nonStatic_implicit_return();
  }

  @override
  @failingTest
  test_implicitConstructor_named_const() async {
    await super.test_implicitConstructor_named_const();
  }

  @override
  @failingTest
  test_import_configurations_useFirst() async {
    await super.test_import_configurations_useFirst();
  }

  @override
  @failingTest
  test_import_invalidUri_metadata() async {
    await super.test_import_invalidUri_metadata();
  }

  @override
  @failingTest
  test_import_short_absolute() async {
    // TODO(scheglov) fails on Windows
    fail('test_import_short_absolute on Windows');
//    await super.test_import_short_absolute();
  }

  @override
  @failingTest
  test_infer_generic_typedef_complex() async {
    await super.test_infer_generic_typedef_complex();
  }

  @override
  @failingTest
  test_inference_issue_32394() async {
    await super.test_inference_issue_32394();
  }

  @override
  @failingTest
  test_inference_map() async {
    await super.test_inference_map();
  }

  @override
  @failingTest
  test_inferred_type_is_typedef() async {
    await super.test_inferred_type_is_typedef();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_bound_type_param() async {
    await super.test_inferred_type_refers_to_bound_type_param();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    await super
        .test_inferred_type_refers_to_function_typed_parameter_type_generic_class();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    await super
        .test_inferred_type_refers_to_function_typed_parameter_type_other_lib();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    await super
        .test_inferred_type_refers_to_method_function_typed_parameter_type();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    await super
        .test_inferred_type_refers_to_setter_function_typed_parameter_type();
  }

  @override
  @failingTest
  test_inferredType_definedInSdkLibraryPart() async {
    await super.test_inferredType_definedInSdkLibraryPart();
  }

  @override
  @failingTest
  test_inferredType_implicitCreation() async {
    await super.test_inferredType_implicitCreation();
  }

  @override
  @failingTest
  test_instantiateToBounds_functionTypeAlias_reexported() async {
    await super.test_instantiateToBounds_functionTypeAlias_reexported();
  }

  @override
  @failingTest
  test_invalidUri_part_emptyUri() async {
    await super.test_invalidUri_part_emptyUri();
  }

  @override
  @failingTest
  test_invalidUris() async {
    await super.test_invalidUris();
  }

  @override
  @failingTest
  test_method_inferred_type_nonStatic_implicit_param() async {
    await super.test_method_inferred_type_nonStatic_implicit_param();
  }

  @override
  @failingTest
  test_method_inferred_type_nonStatic_implicit_return() async {
    await super.test_method_inferred_type_nonStatic_implicit_return();
  }

  @override
  @failingTest
  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    // TODO(scheglov) unexpectedly passes on Windows
    fail('unexpectedly passes on Windows');
//    await super.test_nameConflict_importWithRelativeUri_exportWithAbsolute();
  }

  @override
  @failingTest
  test_parameter_covariant_inherited() async {
    await super.test_parameter_covariant_inherited();
  }

  @override
  @failingTest
  test_parts_invalidUri_nullStringValue() async {
    await super.test_parts_invalidUri_nullStringValue();
  }

  @override
  @failingTest
  test_setter_inferred_type_nonStatic_implicit_param() async {
    await super.test_setter_inferred_type_nonStatic_implicit_param();
  }

  @override
  @failingTest
  test_syntheticFunctionType_genericClosure() async {
    await super.test_syntheticFunctionType_genericClosure();
  }

  @override
  @failingTest
  test_type_inference_based_on_loadLibrary() async {
    await super.test_type_inference_based_on_loadLibrary();
  }

  @override
  @failingTest
  test_type_inference_depends_on_exported_variable() async {
    await super.test_type_inference_depends_on_exported_variable();
  }

  @override
  @failingTest
  test_typedef_type_parameters_bound() async {
    await super.test_typedef_type_parameters_bound();
  }

  @override
  @failingTest
  test_unresolved_annotation_instanceCreation_argument_super() async {
    await super.test_unresolved_annotation_instanceCreation_argument_super();
  }

  @override
  @failingTest
  test_unresolved_export() async {
    await super.test_unresolved_export();
  }

  @override
  @failingTest
  test_unresolved_import() async {
    await super.test_unresolved_import();
  }

  @override
  @failingTest
  test_variable_propagatedType_final_dep_inLib() async {
    await super.test_variable_propagatedType_final_dep_inLib();
  }

  @override
  @failingTest
  test_variable_propagatedType_final_dep_inPart() async {
    await super.test_variable_propagatedType_final_dep_inPart();
  }

  LinkResult _link(Map<Source, String> codeMap) {
    // TODO(scheglov) support for parts
    var libraryUnitMap = <Source, Map<Source, CompilationUnit>>{};
    for (var source in codeMap.keys) {
      var code = codeMap[source];
      var unit = parseText(code, experimentStatus: experimentStatus);
      libraryUnitMap[source] = {source: unit};
    }

    return link(
      AnalysisOptionsImpl(),
      sourceFactory,
      [],
      libraryUnitMap,
    );
  }

  Map<Source, CompilationUnit> _unitsOfLibrary(
      Source definingSource, CompilationUnit definingUnit) {
    var result = <Source, CompilationUnit>{
      definingSource: definingUnit,
    };
    for (var directive in definingUnit.directives) {
      if (directive is PartDirective) {
        var relativeUriStr = directive.uri.stringValue;

        var partSource = sourceFactory.resolveUri(
          definingSource,
          relativeUriStr,
        );

        String text;
        try {
          var partFile = resourceProvider.getFile(partSource.fullName);
          text = partFile.readAsStringSync();
        } catch (_) {
          text = '';
        }

        var partUnit = parseText(text, experimentStatus: experimentStatus);
        result[partSource] = partUnit;
      }
    }
    return result;
  }
}

class _FakeAnalysisContext implements AnalysisContext {
  final SourceFactory sourceFactory;
  TypeProvider typeProvider;
  Dart2TypeSystem typeSystem;

  _FakeAnalysisContext(this.sourceFactory);

  @override
  AnalysisOptions get analysisOptions {
    return AnalysisOptionsImpl();
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
