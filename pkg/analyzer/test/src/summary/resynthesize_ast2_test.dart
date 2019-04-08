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
  test_class_alias_notSimplyBounded_self() async {
    await super.test_class_alias_notSimplyBounded_self();
  }

  @override
  @failingTest
  test_class_constructor_field_formal_functionTyped_noReturnType() async {
    await super
        .test_class_constructor_field_formal_functionTyped_noReturnType();
  }

  @override
  @failingTest
  test_class_constructor_field_formal_functionTyped_withReturnType() async {
    await super
        .test_class_constructor_field_formal_functionTyped_withReturnType();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_circularity_via_typedef() async {
    await super.test_class_notSimplyBounded_circularity_via_typedef();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_complex_by_cycle() async {
    await super.test_class_notSimplyBounded_complex_by_cycle();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_complex_by_reference_to_cycle() async {
    await super.test_class_notSimplyBounded_complex_by_reference_to_cycle();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_complex_by_use_of_parameter() async {
    await super.test_class_notSimplyBounded_complex_by_use_of_parameter();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_dependency_with_type_params() async {
    await super.test_class_notSimplyBounded_dependency_with_type_params();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_function_typed_bound_complex_via_parameter_type() async {
    await super
        .test_class_notSimplyBounded_function_typed_bound_complex_via_parameter_type();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_function_typed_bound_complex_via_return_type() async {
    await super
        .test_class_notSimplyBounded_function_typed_bound_complex_via_return_type();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_refers_to_circular_typedef() async {
    await super.test_class_notSimplyBounded_refers_to_circular_typedef();
  }

  @override
  @failingTest
  test_class_notSimplyBounded_self() async {
    await super.test_class_notSimplyBounded_self();
  }

  @override
  @failingTest
  test_class_type_parameters_bound() async {
    await super.test_class_type_parameters_bound();
  }

  @override
  @failingTest
  test_class_type_parameters_f_bound_complex() async {
    await super.test_class_type_parameters_f_bound_complex();
  }

  @override
  @failingTest
  test_class_type_parameters_f_bound_simple() async {
    await super.test_class_type_parameters_f_bound_simple();
  }

  @override
  @failingTest
  test_closure_generic() async {
    await super.test_closure_generic();
  }

  @override
  @failingTest
  test_closure_in_variable_declaration_in_part() async {
    await super.test_closure_in_variable_declaration_in_part();
  }

  @override
  @failingTest
  test_codeRange_class() async {
    await super.test_codeRange_class();
  }

  @override
  @failingTest
  test_codeRange_class_namedMixin() async {
    await super.test_codeRange_class_namedMixin();
  }

  @override
  @failingTest
  test_codeRange_constructor() async {
    await super.test_codeRange_constructor();
  }

  @override
  @failingTest
  test_codeRange_constructor_factory() async {
    await super.test_codeRange_constructor_factory();
  }

  @override
  @failingTest
  test_codeRange_field() async {
    await super.test_codeRange_field();
  }

  @override
  @failingTest
  test_codeRange_field_annotations() async {
    await super.test_codeRange_field_annotations();
  }

  @override
  @failingTest
  test_codeRange_function() async {
    await super.test_codeRange_function();
  }

  @override
  @failingTest
  test_codeRange_method() async {
    await super.test_codeRange_method();
  }

  @override
  @failingTest
  test_codeRange_parameter() async {
    await super.test_codeRange_parameter();
  }

  @override
  @failingTest
  test_codeRange_parameter_annotations() async {
    await super.test_codeRange_parameter_annotations();
  }

  @override
  @failingTest
  test_codeRange_topLevelVariable() async {
    await super.test_codeRange_topLevelVariable();
  }

  @override
  @failingTest
  test_codeRange_topLevelVariable_annotations() async {
    await super.test_codeRange_topLevelVariable_annotations();
  }

  @override
  @failingTest
  test_codeRange_type_parameter() async {
    await super.test_codeRange_type_parameter();
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
  test_const_parameterDefaultValue_initializingFormal_functionTyped() async {
    await super
        .test_const_parameterDefaultValue_initializingFormal_functionTyped();
  }

  @override
  @failingTest
  test_const_reference_topLevelFunction_generic() async {
    await super.test_const_reference_topLevelFunction_generic();
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
  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    await super.test_constExpr_pushReference_staticMethod_simpleIdentifier();
  }

  @override
  @failingTest
  test_constructor_initializers_assertInvocation() async {
    await super.test_constructor_initializers_assertInvocation();
  }

  @override
  @failingTest
  test_constructor_initializers_assertInvocation_message() async {
    await super.test_constructor_initializers_assertInvocation_message();
  }

  @override
  @failingTest
  test_constructor_initializers_field() async {
    await super.test_constructor_initializers_field();
  }

  @override
  @failingTest
  test_constructor_initializers_field_notConst() async {
    await super.test_constructor_initializers_field_notConst();
  }

  @override
  @failingTest
  test_constructor_initializers_field_withParameter() async {
    await super.test_constructor_initializers_field_withParameter();
  }

  @override
  @failingTest
  test_constructor_initializers_superInvocation_named() async {
    await super.test_constructor_initializers_superInvocation_named();
  }

  @override
  @failingTest
  test_constructor_initializers_superInvocation_named_underscore() async {
    await super
        .test_constructor_initializers_superInvocation_named_underscore();
  }

  @override
  @failingTest
  test_constructor_initializers_superInvocation_namedExpression() async {
    await super.test_constructor_initializers_superInvocation_namedExpression();
  }

  @override
  @failingTest
  test_constructor_initializers_superInvocation_unnamed() async {
    await super.test_constructor_initializers_superInvocation_unnamed();
  }

  @override
  @failingTest
  test_constructor_initializers_thisInvocation_named() async {
    await super.test_constructor_initializers_thisInvocation_named();
  }

  @override
  @failingTest
  test_constructor_initializers_thisInvocation_namedExpression() async {
    await super.test_constructor_initializers_thisInvocation_namedExpression();
  }

  @override
  @failingTest
  test_constructor_initializers_thisInvocation_unnamed() async {
    await super.test_constructor_initializers_thisInvocation_unnamed();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named() async {
    await super.test_constructor_redirected_factory_named();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_generic() async {
    await super.test_constructor_redirected_factory_named_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_imported() async {
    await super.test_constructor_redirected_factory_named_imported();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_imported_generic() async {
    await super.test_constructor_redirected_factory_named_imported_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_prefixed() async {
    await super.test_constructor_redirected_factory_named_prefixed();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_named_prefixed_generic() async {
    await super.test_constructor_redirected_factory_named_prefixed_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed() async {
    await super.test_constructor_redirected_factory_unnamed();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_imported() async {
    await super.test_constructor_redirected_factory_unnamed_imported();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_imported_generic() async {
    await super.test_constructor_redirected_factory_unnamed_imported_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_prefixed() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed();
  }

  @override
  @failingTest
  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_thisInvocation_named() async {
    await super.test_constructor_redirected_thisInvocation_named();
  }

  @override
  @failingTest
  test_constructor_redirected_thisInvocation_named_generic() async {
    await super.test_constructor_redirected_thisInvocation_named_generic();
  }

  @override
  @failingTest
  test_constructor_redirected_thisInvocation_unnamed() async {
    await super.test_constructor_redirected_thisInvocation_unnamed();
  }

  @override
  @failingTest
  test_constructor_redirected_thisInvocation_unnamed_generic() async {
    await super.test_constructor_redirected_thisInvocation_unnamed_generic();
  }

  @override
  @failingTest
  test_constructor_withCycles_const() async {
    await super.test_constructor_withCycles_const();
  }

  @override
  @failingTest
  test_defaultValue_genericFunction() async {
    await super.test_defaultValue_genericFunction();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass() async {
    await super.test_defaultValue_refersToGenericClass();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass_constructor() async {
    await super.test_defaultValue_refersToGenericClass_constructor();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass_constructor2() async {
    await super.test_defaultValue_refersToGenericClass_constructor2();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass_functionG() async {
    await super.test_defaultValue_refersToGenericClass_functionG();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass_methodG() async {
    await super.test_defaultValue_refersToGenericClass_methodG();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass_methodG_classG() async {
    await super.test_defaultValue_refersToGenericClass_methodG_classG();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass_methodNG() async {
    await super.test_defaultValue_refersToGenericClass_methodNG();
  }

  @override
  @failingTest
  test_export_class_type_alias() async {
    await super.test_export_class_type_alias();
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
  test_export_hide() async {
    await super.test_export_hide();
  }

  @override
  @failingTest
  test_export_multiple_combinators() async {
    await super.test_export_multiple_combinators();
  }

  @override
  @failingTest
  test_export_show() async {
    await super.test_export_show();
  }

  @override
  @failingTest
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
  }

  @override
  @failingTest
  test_field_covariant() async {
    await super.test_field_covariant();
  }

  @override
  @failingTest
  test_field_documented() async {
    await super.test_field_documented();
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
  test_function_entry_point_in_part() async {
    await super.test_function_entry_point_in_part();
  }

  @override
  @failingTest
  test_function_parameter_parameters() async {
    await super.test_function_parameter_parameters();
  }

  @override
  @failingTest
  test_function_parameter_return_type() async {
    await super.test_function_parameter_return_type();
  }

  @override
  @failingTest
  test_function_parameter_return_type_void() async {
    await super.test_function_parameter_return_type_void();
  }

  @override
  @failingTest
  test_function_type_parameter() async {
    await super.test_function_type_parameter();
  }

  @override
  @failingTest
  test_function_type_parameter_with_function_typed_parameter() async {
    await super.test_function_type_parameter_with_function_typed_parameter();
  }

  @override
  @failingTest
  test_function_typed_parameter_implicit() async {
    await super.test_function_typed_parameter_implicit();
  }

  @override
  @failingTest
  test_futureOr_inferred() async {
    await super.test_futureOr_inferred();
  }

  @override
  @failingTest
  test_generic_gClass_gMethodStatic() async {
    await super.test_generic_gClass_gMethodStatic();
  }

  @override
  @failingTest
  test_genericFunction_asFunctionTypedParameterReturnType() async {
    await super.test_genericFunction_asFunctionTypedParameterReturnType();
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
  test_import_export() async {
    await super.test_import_export();
  }

  @override
  @failingTest
  test_import_hide() async {
    await super.test_import_hide();
  }

  @override
  @failingTest
  test_import_invalidUri_metadata() async {
    await super.test_import_invalidUri_metadata();
  }

  @override
  @failingTest
  test_import_multiple_combinators() async {
    await super.test_import_multiple_combinators();
  }

  @override
  @failingTest
  test_import_prefixed() async {
    await super.test_import_prefixed();
  }

  @override
  @failingTest
  test_import_self() async {
    await super.test_import_self();
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
  test_import_show() async {
    await super.test_import_show();
  }

  @override
  @failingTest
  test_infer_generic_typedef_complex() async {
    await super.test_infer_generic_typedef_complex();
  }

  @override
  @failingTest
  test_infer_generic_typedef_simple() async {
    await super.test_infer_generic_typedef_simple();
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
  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    await super.test_inferred_type_refers_to_function_typed_param_of_typedef();
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
  test_inferred_type_refers_to_nested_function_typed_param() async {
    await super.test_inferred_type_refers_to_nested_function_typed_param();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    await super
        .test_inferred_type_refers_to_nested_function_typed_param_named();
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
  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    await super
        .test_inferredType_usesSyntheticFunctionType_functionTypedParam();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure() async {
    await super.test_initializer_executable_with_return_type_from_closure();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_dynamic();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_future3_int() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_future3_int();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_future_int() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_future_int();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_future_noArg() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_future_noArg();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_field() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_field();
  }

  @override
  @failingTest
  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    await super.test_instantiateToBounds_boundRefersToEarlierTypeArgument();
  }

  @override
  @failingTest
  test_instantiateToBounds_boundRefersToItself() async {
    await super.test_instantiateToBounds_boundRefersToItself();
  }

  @override
  @failingTest
  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    await super.test_instantiateToBounds_boundRefersToLaterTypeArgument();
  }

  @override
  @failingTest
  test_instantiateToBounds_functionTypeAlias_reexported() async {
    await super.test_instantiateToBounds_functionTypeAlias_reexported();
  }

  @override
  @failingTest
  test_instantiateToBounds_functionTypeAlias_simple() async {
    await super.test_instantiateToBounds_functionTypeAlias_simple();
  }

  @override
  @failingTest
  test_instantiateToBounds_simple() async {
    await super.test_instantiateToBounds_simple();
  }

  @override
  @failingTest
  test_invalid_nameConflict_imported_exported() async {
    await super.test_invalid_nameConflict_imported_exported();
  }

  @override
  @failingTest
  test_invalid_nameConflict_local() async {
    await super.test_invalid_nameConflict_local();
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
  test_library_documented_lines() async {
    await super.test_library_documented_lines();
  }

  @override
  @failingTest
  test_library_documented_stars() async {
    await super.test_library_documented_stars();
  }

  @override
  @failingTest
  test_metadata_exportDirective() async {
    await super.test_metadata_exportDirective();
  }

  @override
  @failingTest
  test_metadata_fieldFormalParameter() async {
    await super.test_metadata_fieldFormalParameter();
  }

  @override
  @failingTest
  test_metadata_fieldFormalParameter_withDefault() async {
    await super.test_metadata_fieldFormalParameter_withDefault();
  }

  @override
  @failingTest
  test_metadata_functionTypedFormalParameter() async {
    await super.test_metadata_functionTypedFormalParameter();
  }

  @override
  @failingTest
  test_metadata_functionTypedFormalParameter_withDefault() async {
    await super.test_metadata_functionTypedFormalParameter_withDefault();
  }

  @override
  @failingTest
  test_metadata_importDirective() async {
    await super.test_metadata_importDirective();
  }

  @override
  @failingTest
  test_metadata_libraryDirective() async {
    await super.test_metadata_libraryDirective();
  }

  @override
  @failingTest
  test_metadata_partDirective() async {
    await super.test_metadata_partDirective();
  }

  @override
  @failingTest
  test_metadata_simpleFormalParameter() async {
    await super.test_metadata_simpleFormalParameter();
  }

  @override
  @failingTest
  test_metadata_simpleFormalParameter_method() async {
    await super.test_metadata_simpleFormalParameter_method();
  }

  @override
  @failingTest
  test_metadata_simpleFormalParameter_withDefault() async {
    await super.test_metadata_simpleFormalParameter_withDefault();
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
  test_method_type_parameter() async {
    await super.test_method_type_parameter();
  }

  @override
  @failingTest
  test_method_type_parameter_in_generic_class() async {
    await super.test_method_type_parameter_in_generic_class();
  }

  @override
  @failingTest
  test_method_type_parameter_with_function_typed_parameter() async {
    await super.test_method_type_parameter_with_function_typed_parameter();
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
  test_new_typedef_notSimplyBounded_self() async {
    await super.test_new_typedef_notSimplyBounded_self();
  }

  @override
  @failingTest
  test_old_typedef_notSimplyBounded_self() async {
    await super.test_old_typedef_notSimplyBounded_self();
  }

  @override
  @failingTest
  test_parameter() async {
    await super.test_parameter();
  }

  @override
  @failingTest
  test_parameter_covariant() async {
    await super.test_parameter_covariant();
  }

  @override
  @failingTest
  test_parameter_covariant_inherited() async {
    await super.test_parameter_covariant_inherited();
  }

  @override
  @failingTest
  test_parameter_parameters() async {
    await super.test_parameter_parameters();
  }

  @override
  @failingTest
  test_parameter_parameters_in_generic_class() async {
    await super.test_parameter_parameters_in_generic_class();
  }

  @override
  @failingTest
  test_parameter_return_type() async {
    await super.test_parameter_return_type();
  }

  @override
  @failingTest
  test_parameter_return_type_void() async {
    await super.test_parameter_return_type_void();
  }

  @override
  @failingTest
  test_parts() async {
    await super.test_parts();
  }

  @override
  @failingTest
  test_parts_invalidUri() async {
    await super.test_parts_invalidUri();
  }

  @override
  @failingTest
  test_parts_invalidUri_nullStringValue() async {
    await super.test_parts_invalidUri_nullStringValue();
  }

  @override
  @failingTest
  test_setter_covariant() async {
    await super.test_setter_covariant();
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
  test_syntheticFunctionType_inGenericClass() async {
    await super.test_syntheticFunctionType_inGenericClass();
  }

  @override
  @failingTest
  test_syntheticFunctionType_noArguments() async {
    await super.test_syntheticFunctionType_noArguments();
  }

  @override
  @failingTest
  test_syntheticFunctionType_withArguments() async {
    await super.test_syntheticFunctionType_withArguments();
  }

  @override
  @failingTest
  test_type_inference_based_on_loadLibrary() async {
    await super.test_type_inference_based_on_loadLibrary();
  }

  @override
  @failingTest
  test_type_inference_closure_with_function_typed_parameter() async {
    await super.test_type_inference_closure_with_function_typed_parameter();
  }

  @override
  @failingTest
  test_type_inference_closure_with_function_typed_parameter_new() async {
    await super.test_type_inference_closure_with_function_typed_parameter_new();
  }

  @override
  @failingTest
  test_type_inference_depends_on_exported_variable() async {
    await super.test_type_inference_depends_on_exported_variable();
  }

  @override
  @failingTest
  test_type_inference_nested_function() async {
    await super.test_type_inference_nested_function();
  }

  @override
  @failingTest
  test_type_inference_nested_function_with_parameter_types() async {
    await super.test_type_inference_nested_function_with_parameter_types();
  }

  @override
  @failingTest
  test_type_inference_of_closure_with_default_value() async {
    await super.test_type_inference_of_closure_with_default_value();
  }

  @override
  @failingTest
  test_type_invalid_typeParameter_asPrefix() async {
    await super.test_type_invalid_typeParameter_asPrefix();
  }

  @override
  @failingTest
  test_type_invalid_unresolvedPrefix() async {
    await super.test_type_invalid_unresolvedPrefix();
  }

  @override
  @failingTest
  test_type_reference_lib_to_part() async {
    await super.test_type_reference_lib_to_part();
  }

  @override
  @failingTest
  test_type_reference_part_to_lib() async {
    await super.test_type_reference_part_to_lib();
  }

  @override
  @failingTest
  test_type_reference_part_to_other_part() async {
    await super.test_type_reference_part_to_other_part();
  }

  @override
  @failingTest
  test_type_reference_part_to_part() async {
    await super.test_type_reference_part_to_part();
  }

  @override
  @failingTest
  test_type_reference_to_import_part2() async {
    await super.test_type_reference_to_import_part2();
  }

  @override
  @failingTest
  test_type_reference_to_typedef_with_type_arguments() async {
    await super.test_type_reference_to_typedef_with_type_arguments();
  }

  @override
  @failingTest
  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    await super.test_type_reference_to_typedef_with_type_arguments_implicit();
  }

  @override
  @failingTest
  test_type_unresolved_prefixed() async {
    await super.test_type_unresolved_prefixed();
  }

  @override
  @failingTest
  test_typedef_generic() async {
    await super.test_typedef_generic();
  }

  @override
  @failingTest
  test_typedef_generic_asFieldType() async {
    await super.test_typedef_generic_asFieldType();
  }

  @override
  @failingTest
  test_typedef_notSimplyBounded_dependency_via_param_type_new_style_name_included() async {
    await super
        .test_typedef_notSimplyBounded_dependency_via_param_type_new_style_name_included();
  }

  @override
  @failingTest
  test_typedef_notSimplyBounded_dependency_via_param_type_new_style_name_omitted() async {
    await super
        .test_typedef_notSimplyBounded_dependency_via_param_type_new_style_name_omitted();
  }

  @override
  @failingTest
  test_typedef_notSimplyBounded_dependency_via_param_type_old_style() async {
    await super
        .test_typedef_notSimplyBounded_dependency_via_param_type_old_style();
  }

  @override
  @failingTest
  test_typedef_notSimplyBounded_dependency_via_return_type_new_style() async {
    await super
        .test_typedef_notSimplyBounded_dependency_via_return_type_new_style();
  }

  @override
  @failingTest
  test_typedef_notSimplyBounded_dependency_via_return_type_old_style() async {
    await super
        .test_typedef_notSimplyBounded_dependency_via_return_type_old_style();
  }

  @override
  @failingTest
  test_typedef_parameter_parameters() async {
    await super.test_typedef_parameter_parameters();
  }

  @override
  @failingTest
  test_typedef_parameter_parameters_in_generic_class() async {
    await super.test_typedef_parameter_parameters_in_generic_class();
  }

  @override
  @failingTest
  test_typedef_parameter_return_type() async {
    await super.test_typedef_parameter_return_type();
  }

  @override
  @failingTest
  test_typedef_type_parameters_bound() async {
    await super.test_typedef_type_parameters_bound();
  }

  @override
  @failingTest
  test_typedef_type_parameters_bound_recursive() async {
    await super.test_typedef_type_parameters_bound_recursive();
  }

  @override
  @failingTest
  test_typedef_type_parameters_bound_recursive2() async {
    await super.test_typedef_type_parameters_bound_recursive2();
  }

  @override
  @failingTest
  test_typedef_type_parameters_f_bound_complex() async {
    await super.test_typedef_type_parameters_f_bound_complex();
  }

  @override
  @failingTest
  test_typedef_type_parameters_f_bound_simple() async {
    await super.test_typedef_type_parameters_f_bound_simple();
  }

  @override
  @failingTest
  test_typedef_type_parameters_f_bound_simple_new_syntax() async {
    await super.test_typedef_type_parameters_f_bound_simple_new_syntax();
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
  test_unresolved_part() async {
    await super.test_unresolved_part();
  }

  @override
  @failingTest
  test_unused_type_parameter() async {
    await super.test_unused_type_parameter();
  }

  @override
  @failingTest
  test_variable_documented() async {
    await super.test_variable_documented();
  }

  @override
  @failingTest
  test_variable_getterInLib_setterInPart() async {
    await super.test_variable_getterInLib_setterInPart();
  }

  @override
  @failingTest
  test_variable_getterInPart_setterInLib() async {
    await super.test_variable_getterInPart_setterInLib();
  }

  @override
  @failingTest
  test_variable_getterInPart_setterInPart() async {
    await super.test_variable_getterInPart_setterInPart();
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

  @override
  @failingTest
  test_variable_setterInPart_getterInPart() async {
    await super.test_variable_setterInPart_getterInPart();
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
