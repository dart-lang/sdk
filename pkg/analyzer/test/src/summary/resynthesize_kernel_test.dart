// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_kernel_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart' as kernel;
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context/mock_sdk.dart';
import 'resynthesize_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeKernelStrongTest);
  });
}

@reflectiveTest
class ResynthesizeKernelStrongTest extends ResynthesizeTest {
  final resourceProvider = new MemoryResourceProvider(context: pathos.posix);

  @override
  bool get isSharedFrontEnd => true;

  @override
  bool get isStrongMode => true;

  @override
  Source addLibrarySource(String path, String content) {
    path = resourceProvider.convertPath(path);
    File file = resourceProvider.newFile(path, content);
    return file.createSource();
  }

  @override
  Source addSource(String path, String content) {
    path = resourceProvider.convertPath(path);
    File file = resourceProvider.newFile(path, content);
    return file.createSource();
  }

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) async {
    new MockSdk(resourceProvider: resourceProvider);

    File testFile = resourceProvider.newFile('/test.dart', text);
    Uri testUri = testFile.toUri();
    String testUriStr = testUri.toString();

    Map<String, Uri> dartLibraries = {};
    MockSdk.FULL_URI_MAP.forEach((dartUri, path) {
      dartLibraries[Uri.parse(dartUri).path] = Uri.parse('file://$path');
    });

    var uriTranslator =
        new UriTranslatorImpl(dartLibraries, {}, Packages.noPackages);
    var driver = new KernelDriver(
        new PerformanceLog(null),
        new _FileSystemAdaptor(resourceProvider),
        new MemoryByteStore(),
        uriTranslator,
        new NoneTarget(new TargetFlags(strongMode: isStrongMode)));

    KernelResult kernelResult = await driver.getKernel(testUri);

    var libraryMap = <String, kernel.Library>{};
    for (var cycleResult in kernelResult.results) {
      for (var library in cycleResult.kernelLibraries) {
        String uriStr = library.importUri.toString();
        libraryMap[uriStr] = library;
      }
    }

    var resynthesizer =
        new _KernelResynthesizer(context, kernelResult.types, libraryMap);
    return resynthesizer.getLibrary(testUriStr);
  }

  @override
  SummaryResynthesizer encodeDecodeLibrarySource(Source librarySource) {
    // TODO(scheglov): implement encodeDecodeLibrarySource
    throw new UnimplementedError();
  }

  @failingTest
  test_class_alias_documented() async {
    await super.test_class_alias_documented();
  }

  @failingTest
  test_class_alias_with_forwarding_constructors_type_substitution() async {
    await super
        .test_class_alias_with_forwarding_constructors_type_substitution();
  }

  @failingTest
  test_class_alias_with_forwarding_constructors_type_substitution_complex() async {
    await super
        .test_class_alias_with_forwarding_constructors_type_substitution_complex();
  }

  @failingTest
  test_class_constructor_field_formal_multiple_matching_fields() async {
    // Fasta does not generate the class.
    // main() with a fatal error is generated instead.
    await super.test_class_constructor_field_formal_multiple_matching_fields();
  }

  @failingTest
  test_class_documented_tripleSlash() async {
    await super.test_class_documented_tripleSlash();
  }

  @failingTest
  test_class_documented_withLeadingNotDocumentation() async {
    await super.test_class_documented_withLeadingNotDocumentation();
  }

  @failingTest
  test_class_interfaces_unresolved() async {
    await super.test_class_interfaces_unresolved();
  }

  @failingTest
  test_class_mixins_unresolved() async {
    await super.test_class_mixins_unresolved();
  }

  @failingTest
  test_class_supertype_unresolved() async {
    await super.test_class_supertype_unresolved();
  }

  @failingTest
  test_class_type_parameters_bound() async {
    await super.test_class_type_parameters_bound();
  }

  @failingTest
  test_class_type_parameters_f_bound_complex() async {
    await super.test_class_type_parameters_f_bound_complex();
  }

  @failingTest
  test_closure_generic() async {
    await super.test_closure_generic();
  }

  @failingTest
  test_closure_in_variable_declaration_in_part() async {
    await super.test_closure_in_variable_declaration_in_part();
  }

  @failingTest
  test_const_invalid_field_const() async {
    await super.test_const_invalid_field_const();
  }

  @failingTest
  test_const_invalid_field_final() async {
    await super.test_const_invalid_field_final();
  }

  @failingTest
  test_const_invalid_intLiteral() async {
    await super.test_const_invalid_intLiteral();
  }

  @failingTest
  test_const_invalid_topLevel() async {
    await super.test_const_invalid_topLevel();
  }

  @failingTest
  test_const_invokeConstructor_generic_named_imported_withPrefix() async {
    await super
        .test_const_invokeConstructor_generic_named_imported_withPrefix();
  }

  @failingTest
  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() async {
    await super
        .test_const_invokeConstructor_generic_unnamed_imported_withPrefix();
  }

  @failingTest
  test_const_invokeConstructor_named_imported_withPrefix() async {
    await super.test_const_invokeConstructor_named_imported_withPrefix();
  }

  @failingTest
  test_const_invokeConstructor_named_unresolved() async {
    await super.test_const_invokeConstructor_named_unresolved();
  }

  @failingTest
  test_const_invokeConstructor_named_unresolved2() async {
    await super.test_const_invokeConstructor_named_unresolved2();
  }

  @failingTest
  test_const_invokeConstructor_named_unresolved3() async {
    await super.test_const_invokeConstructor_named_unresolved3();
  }

  @failingTest
  test_const_invokeConstructor_named_unresolved4() async {
    await super.test_const_invokeConstructor_named_unresolved4();
  }

  @failingTest
  test_const_invokeConstructor_named_unresolved5() async {
    await super.test_const_invokeConstructor_named_unresolved5();
  }

  @failingTest
  test_const_invokeConstructor_named_unresolved6() async {
    await super.test_const_invokeConstructor_named_unresolved6();
  }

  @failingTest
  test_const_invokeConstructor_unnamed_imported_withPrefix() async {
    await super.test_const_invokeConstructor_unnamed_imported_withPrefix();
  }

  @failingTest
  test_const_invokeConstructor_unnamed_unresolved() async {
    await super.test_const_invokeConstructor_unnamed_unresolved();
  }

  @failingTest
  test_const_invokeConstructor_unnamed_unresolved2() async {
    await super.test_const_invokeConstructor_unnamed_unresolved2();
  }

  @failingTest
  test_const_invokeConstructor_unnamed_unresolved3() async {
    await super.test_const_invokeConstructor_unnamed_unresolved3();
  }

  @failingTest
  test_const_length_ofClassConstField_imported_withPrefix() async {
    await super.test_const_length_ofClassConstField_imported_withPrefix();
  }

  @failingTest
  test_const_length_ofTopLevelVariable_imported() async {
    await super.test_const_length_ofTopLevelVariable_imported();
  }

  @failingTest
  test_const_length_ofTopLevelVariable_imported_withPrefix() async {
    await super.test_const_length_ofTopLevelVariable_imported_withPrefix();
  }

  @failingTest
  test_const_length_staticMethod() async {
    await super.test_const_length_staticMethod();
  }

  @failingTest
  test_const_reference_staticField_imported_withPrefix() async {
    await super.test_const_reference_staticField_imported_withPrefix();
  }

  @failingTest
  test_const_reference_staticMethod() async {
    await super.test_const_reference_staticMethod();
  }

  @failingTest
  test_const_reference_staticMethod_imported() async {
    await super.test_const_reference_staticMethod_imported();
  }

  @failingTest
  test_const_reference_staticMethod_imported_withPrefix() async {
    await super.test_const_reference_staticMethod_imported_withPrefix();
  }

  @failingTest
  test_const_reference_topLevelFunction() async {
    await super.test_const_reference_topLevelFunction();
  }

  @failingTest
  test_const_reference_topLevelFunction_imported() async {
    await super.test_const_reference_topLevelFunction_imported();
  }

  @failingTest
  test_const_reference_topLevelFunction_imported_withPrefix() async {
    await super.test_const_reference_topLevelFunction_imported_withPrefix();
  }

  @failingTest
  test_const_reference_topLevelVariable_imported_withPrefix() async {
    await super.test_const_reference_topLevelVariable_imported_withPrefix();
  }

  @failingTest
  test_const_reference_type() async {
    await super.test_const_reference_type();
  }

  @failingTest
  test_const_reference_type_functionType() async {
    await super.test_const_reference_type_functionType();
  }

  @failingTest
  test_const_reference_type_imported() async {
    await super.test_const_reference_type_imported();
  }

  @failingTest
  test_const_reference_type_imported_withPrefix() async {
    await super.test_const_reference_type_imported_withPrefix();
  }

  @failingTest
  test_const_reference_type_typeParameter() async {
    await super.test_const_reference_type_typeParameter();
  }

  @failingTest
  test_const_reference_unresolved_prefix0() async {
    await super.test_const_reference_unresolved_prefix0();
  }

  @failingTest
  test_const_reference_unresolved_prefix1() async {
    await super.test_const_reference_unresolved_prefix1();
  }

  @failingTest
  test_const_reference_unresolved_prefix2() async {
    await super.test_const_reference_unresolved_prefix2();
  }

  @failingTest
  test_const_topLevel_ifNull() async {
    await super.test_const_topLevel_ifNull();
  }

  @failingTest
  test_const_topLevel_super() async {
    await super.test_const_topLevel_super();
  }

  @failingTest
  test_const_topLevel_this() async {
    await super.test_const_topLevel_this();
  }

  @failingTest
  test_const_topLevel_typedList_importedWithPrefix() async {
    await super.test_const_topLevel_typedList_importedWithPrefix();
  }

  @failingTest
  test_constExpr_pushReference_enum_field() async {
    await super.test_constExpr_pushReference_enum_field();
  }

  @failingTest
  test_constExpr_pushReference_enum_method() async {
    await super.test_constExpr_pushReference_enum_method();
  }

  @failingTest
  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    await super.test_constExpr_pushReference_staticMethod_simpleIdentifier();
  }

  @failingTest
  test_constructor_documented() async {
    await super.test_constructor_documented();
  }

  @failingTest
  test_constructor_initializers_assertInvocation() async {
    await super.test_constructor_initializers_assertInvocation();
  }

  @failingTest
  test_constructor_initializers_assertInvocation_message() async {
    await super.test_constructor_initializers_assertInvocation_message();
  }

  @failingTest
  test_constructor_initializers_field() async {
    await super.test_constructor_initializers_field();
  }

  @failingTest
  test_constructor_initializers_field_notConst() async {
    await super.test_constructor_initializers_field_notConst();
  }

  @failingTest
  test_constructor_initializers_field_withParameter() async {
    await super.test_constructor_initializers_field_withParameter();
  }

  @failingTest
  test_constructor_initializers_superInvocation_named() async {
    await super.test_constructor_initializers_superInvocation_named();
  }

  @failingTest
  test_constructor_initializers_superInvocation_namedExpression() async {
    await super.test_constructor_initializers_superInvocation_namedExpression();
  }

  @failingTest
  test_constructor_initializers_superInvocation_unnamed() async {
    await super.test_constructor_initializers_superInvocation_unnamed();
  }

  @failingTest
  test_constructor_initializers_thisInvocation_named() async {
    await super.test_constructor_initializers_thisInvocation_named();
  }

  @failingTest
  test_constructor_initializers_thisInvocation_namedExpression() async {
    await super.test_constructor_initializers_thisInvocation_namedExpression();
  }

  @failingTest
  test_constructor_initializers_thisInvocation_unnamed() async {
    await super.test_constructor_initializers_thisInvocation_unnamed();
  }

  @failingTest
  test_constructor_redirected_factory_named() async {
    await super.test_constructor_redirected_factory_named();
  }

  @failingTest
  test_constructor_redirected_factory_named_generic() async {
    await super.test_constructor_redirected_factory_named_generic();
  }

  @failingTest
  test_constructor_redirected_factory_named_imported() async {
    await super.test_constructor_redirected_factory_named_imported();
  }

  @failingTest
  test_constructor_redirected_factory_named_imported_generic() async {
    await super.test_constructor_redirected_factory_named_imported_generic();
  }

  @failingTest
  test_constructor_redirected_factory_named_prefixed() async {
    await super.test_constructor_redirected_factory_named_prefixed();
  }

  @failingTest
  test_constructor_redirected_factory_named_prefixed_generic() async {
    await super.test_constructor_redirected_factory_named_prefixed_generic();
  }

  @failingTest
  test_constructor_redirected_factory_named_unresolved_class() async {
    await super.test_constructor_redirected_factory_named_unresolved_class();
  }

  @failingTest
  test_constructor_redirected_factory_named_unresolved_constructor() async {
    await super
        .test_constructor_redirected_factory_named_unresolved_constructor();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed() async {
    await super.test_constructor_redirected_factory_unnamed();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_generic();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed_imported() async {
    await super.test_constructor_redirected_factory_unnamed_imported();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed_imported_generic() async {
    await super.test_constructor_redirected_factory_unnamed_imported_generic();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed_prefixed() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed_generic();
  }

  @failingTest
  test_constructor_redirected_factory_unnamed_unresolved() async {
    await super.test_constructor_redirected_factory_unnamed_unresolved();
  }

  @failingTest
  test_constructor_redirected_thisInvocation_named() async {
    await super.test_constructor_redirected_thisInvocation_named();
  }

  @failingTest
  test_constructor_redirected_thisInvocation_named_generic() async {
    await super.test_constructor_redirected_thisInvocation_named_generic();
  }

  @failingTest
  test_constructor_redirected_thisInvocation_unnamed() async {
    await super.test_constructor_redirected_thisInvocation_unnamed();
  }

  @failingTest
  test_constructor_redirected_thisInvocation_unnamed_generic() async {
    await super.test_constructor_redirected_thisInvocation_unnamed_generic();
  }

  @failingTest
  test_constructor_withCycles_const() async {
    await super.test_constructor_withCycles_const();
  }

  @failingTest
  test_defaultValue_refersToGenericClass_constructor() async {
    await super.test_defaultValue_refersToGenericClass_constructor();
  }

  @failingTest
  test_defaultValue_refersToGenericClass_constructor2() async {
    await super.test_defaultValue_refersToGenericClass_constructor2();
  }

  @failingTest
  test_defaultValue_refersToGenericClass_functionG() async {
    await super.test_defaultValue_refersToGenericClass_functionG();
  }

  @failingTest
  test_defaultValue_refersToGenericClass_methodG() async {
    await super.test_defaultValue_refersToGenericClass_methodG();
  }

  @failingTest
  test_defaultValue_refersToGenericClass_methodG_classG() async {
    await super.test_defaultValue_refersToGenericClass_methodG_classG();
  }

  @failingTest
  test_defaultValue_refersToGenericClass_methodNG() async {
    await super.test_defaultValue_refersToGenericClass_methodNG();
  }

  @failingTest
  test_enum_documented() async {
    await super.test_enum_documented();
  }

  @failingTest
  test_enum_value_documented() async {
    await super.test_enum_value_documented();
  }

  @failingTest
  test_enum_values() async {
    await super.test_enum_values();
  }

  @failingTest
  test_enums() async {
    await super.test_enums();
  }

  @failingTest
  test_error_extendsEnum() async {
    await super.test_error_extendsEnum();
  }

  @failingTest
  test_executable_parameter_type_typedef() async {
    await super.test_executable_parameter_type_typedef();
  }

  @failingTest
  test_export_class() async {
    await super.test_export_class();
  }

  @failingTest
  test_export_class_type_alias() async {
    await super.test_export_class_type_alias();
  }

  @failingTest
  test_export_configurations_useDefault() async {
    await super.test_export_configurations_useDefault();
  }

  @failingTest
  test_export_configurations_useFirst() async {
    await super.test_export_configurations_useFirst();
  }

  @failingTest
  test_export_configurations_useSecond() async {
    await super.test_export_configurations_useSecond();
  }

  @failingTest
  test_export_function() async {
    await super.test_export_function();
  }

  @failingTest
  test_export_getter() async {
    await super.test_export_getter();
  }

  @failingTest
  test_export_hide() async {
    await super.test_export_hide();
  }

  @failingTest
  test_export_multiple_combinators() async {
    await super.test_export_multiple_combinators();
  }

  @failingTest
  test_export_setter() async {
    await super.test_export_setter();
  }

  @failingTest
  test_export_show() async {
    await super.test_export_show();
  }

  @failingTest
  test_export_typedef() async {
    await super.test_export_typedef();
  }

  @failingTest
  test_export_variable() async {
    await super.test_export_variable();
  }

  @failingTest
  test_export_variable_const() async {
    await super.test_export_variable_const();
  }

  @failingTest
  test_export_variable_final() async {
    await super.test_export_variable_final();
  }

  @failingTest
  test_exportImport_configurations_useDefault() async {
    await super.test_exportImport_configurations_useDefault();
  }

  @failingTest
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
  }

  @failingTest
  test_exports() async {
    await super.test_exports();
  }

  @failingTest
  test_expr_invalid_typeParameter_asPrefix() async {
    await super.test_expr_invalid_typeParameter_asPrefix();
  }

  @failingTest
  test_field_covariant() async {
    await super.test_field_covariant();
  }

  @failingTest
  test_field_documented() async {
    await super.test_field_documented();
  }

  @failingTest
  test_field_propagatedType_final_dep_inLib() async {
    await super.test_field_propagatedType_final_dep_inLib();
  }

  @failingTest
  test_field_propagatedType_final_dep_inPart() async {
    await super.test_field_propagatedType_final_dep_inPart();
  }

  @failingTest
  test_field_propagatedType_final_noDep_instance() async {
    await super.test_field_propagatedType_final_noDep_instance();
  }

  @failingTest
  test_function_documented() async {
    await super.test_function_documented();
  }

  @failingTest
  test_function_entry_point_in_export() async {
    await super.test_function_entry_point_in_export();
  }

  @failingTest
  test_function_entry_point_in_export_hidden() async {
    await super.test_function_entry_point_in_export_hidden();
  }

  @failingTest
  test_function_entry_point_in_part() async {
    await super.test_function_entry_point_in_part();
  }

  @failingTest
  test_function_parameter_parameters() async {
    await super.test_function_parameter_parameters();
  }

  @failingTest
  test_function_parameter_return_type() async {
    await super.test_function_parameter_return_type();
  }

  @failingTest
  test_function_parameter_return_type_void() async {
    await super.test_function_parameter_return_type_void();
  }

  @failingTest
  test_function_type_parameter() async {
    await super.test_function_type_parameter();
  }

  @failingTest
  test_function_type_parameter_with_function_typed_parameter() async {
    await super.test_function_type_parameter_with_function_typed_parameter();
  }

  @failingTest
  test_futureOr() async {
    await super.test_futureOr();
  }

  @failingTest
  test_futureOr_const() async {
    await super.test_futureOr_const();
  }

  @failingTest
  test_futureOr_inferred() async {
    await super.test_futureOr_inferred();
  }

  @failingTest
  test_generic_gClass_gMethodStatic() async {
    await super.test_generic_gClass_gMethodStatic();
  }

  @failingTest
  test_genericFunction_asFunctionReturnType() async {
    await super.test_genericFunction_asFunctionReturnType();
  }

  @failingTest
  test_genericFunction_asFunctionTypedParameterReturnType() async {
    await super.test_genericFunction_asFunctionTypedParameterReturnType();
  }

  @failingTest
  test_genericFunction_asGenericFunctionReturnType() async {
    await super.test_genericFunction_asGenericFunctionReturnType();
  }

  @failingTest
  test_genericFunction_asMethodReturnType() async {
    await super.test_genericFunction_asMethodReturnType();
  }

  @failingTest
  test_genericFunction_asParameterType() async {
    await super.test_genericFunction_asParameterType();
  }

  @failingTest
  test_genericFunction_asTopLevelVariableType() async {
    await super.test_genericFunction_asTopLevelVariableType();
  }

  @failingTest
  test_getElement_constructor_named() async {
    await super.test_getElement_constructor_named();
  }

  @failingTest
  test_getElement_constructor_unnamed() async {
    await super.test_getElement_constructor_unnamed();
  }

  @failingTest
  test_getElement_field() async {
    await super.test_getElement_field();
  }

  @failingTest
  test_getElement_getter() async {
    await super.test_getElement_getter();
  }

  @failingTest
  test_getElement_method() async {
    await super.test_getElement_method();
  }

  @failingTest
  test_getElement_operator() async {
    await super.test_getElement_operator();
  }

  @failingTest
  test_getElement_setter() async {
    await super.test_getElement_setter();
  }

  @failingTest
  test_getElement_unit() async {
    await super.test_getElement_unit();
  }

  @failingTest
  test_getter_documented() async {
    await super.test_getter_documented();
  }

  @failingTest
  test_getter_external() async {
    await super.test_getter_external();
  }

  @failingTest
  test_getters() async {
    await super.test_getters();
  }

  @failingTest
  test_implicitTopLevelVariable_getterFirst() async {
    await super.test_implicitTopLevelVariable_getterFirst();
  }

  @failingTest
  test_implicitTopLevelVariable_setterFirst() async {
    await super.test_implicitTopLevelVariable_setterFirst();
  }

  @failingTest
  test_import_configurations_useDefault() async {
    await super.test_import_configurations_useDefault();
  }

  @failingTest
  test_import_configurations_useFirst() async {
    await super.test_import_configurations_useFirst();
  }

  @failingTest
  test_import_deferred() async {
    await super.test_import_deferred();
  }

  @failingTest
  test_import_hide() async {
    await super.test_import_hide();
  }

  @failingTest
  test_import_invalidUri_metadata() async {
    await super.test_import_invalidUri_metadata();
  }

  @failingTest
  test_import_multiple_combinators() async {
    await super.test_import_multiple_combinators();
  }

  @failingTest
  test_import_prefixed() async {
    await super.test_import_prefixed();
  }

  @failingTest
  test_import_self() async {
    await super.test_import_self();
  }

  @failingTest
  test_import_show() async {
    await super.test_import_show();
  }

  @failingTest
  test_inferred_function_type_for_variable_in_generic_function() async {
    await super.test_inferred_function_type_for_variable_in_generic_function();
  }

  @failingTest
  test_inferred_function_type_in_generic_class_in_generic_method() async {
    await super
        .test_inferred_function_type_in_generic_class_in_generic_method();
  }

  @failingTest
  test_inferred_type_is_typedef() async {
    await super.test_inferred_type_is_typedef();
  }

  @failingTest
  test_inferred_type_refers_to_bound_type_param() async {
    await super.test_inferred_type_refers_to_bound_type_param();
  }

  @failingTest
  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    await super.test_inferred_type_refers_to_function_typed_param_of_typedef();
  }

  @failingTest
  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    await super
        .test_inferred_type_refers_to_function_typed_parameter_type_generic_class();
  }

  @failingTest
  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    await super
        .test_inferred_type_refers_to_function_typed_parameter_type_other_lib();
  }

  @failingTest
  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    await super
        .test_inferred_type_refers_to_method_function_typed_parameter_type();
  }

  @failingTest
  test_inferred_type_refers_to_nested_function_typed_param() async {
    await super.test_inferred_type_refers_to_nested_function_typed_param();
  }

  @failingTest
  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    await super
        .test_inferred_type_refers_to_nested_function_typed_param_named();
  }

  @failingTest
  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    await super
        .test_inferred_type_refers_to_setter_function_typed_parameter_type();
  }

  @failingTest
  test_inferredType_definedInSdkLibraryPart() async {
    await super.test_inferredType_definedInSdkLibraryPart();
  }

  @failingTest
  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    await super
        .test_inferredType_usesSyntheticFunctionType_functionTypedParam();
  }

  @failingTest
  test_initializer_executable_with_return_type_from_closure() async {
    await super.test_initializer_executable_with_return_type_from_closure();
  }

  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_dynamic();
  }

  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_future3_int() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_future3_int();
  }

  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_future_int() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_future_int();
  }

  @failingTest
  test_initializer_executable_with_return_type_from_closure_await_future_noArg() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_await_future_noArg();
  }

  @failingTest
  test_initializer_executable_with_return_type_from_closure_field() async {
    await super
        .test_initializer_executable_with_return_type_from_closure_field();
  }

  @failingTest
  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    await super.test_instantiateToBounds_boundRefersToEarlierTypeArgument();
  }

  @failingTest
  test_instantiateToBounds_boundRefersToItself() async {
    await super.test_instantiateToBounds_boundRefersToItself();
  }

  @failingTest
  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    await super.test_instantiateToBounds_boundRefersToLaterTypeArgument();
  }

  @failingTest
  test_instantiateToBounds_functionTypeAlias_simple() async {
    await super.test_instantiateToBounds_functionTypeAlias_simple();
  }

  @failingTest
  test_instantiateToBounds_simple() async {
    await super.test_instantiateToBounds_simple();
  }

  @failingTest
  test_invalid_annotation_prefixed_constructor() async {
    await super.test_invalid_annotation_prefixed_constructor();
  }

  @failingTest
  test_invalid_annotation_unprefixed_constructor() async {
    await super.test_invalid_annotation_unprefixed_constructor();
  }

  @failingTest
  test_invalid_importPrefix_asTypeArgument() async {
    await super.test_invalid_importPrefix_asTypeArgument();
  }

  @failingTest
  test_invalid_nameConflict_imported() async {
    await super.test_invalid_nameConflict_imported();
  }

  @failingTest
  test_invalid_nameConflict_imported_exported() async {
    await super.test_invalid_nameConflict_imported_exported();
  }

  @failingTest
  test_invalid_nameConflict_local() async {
    await super.test_invalid_nameConflict_local();
  }

  @failingTest
  test_invalid_setterParameter_fieldFormalParameter() async {
    await super.test_invalid_setterParameter_fieldFormalParameter();
  }

  @failingTest
  test_invalid_setterParameter_fieldFormalParameter_self() async {
    await super.test_invalid_setterParameter_fieldFormalParameter_self();
  }

  @failingTest
  test_invalidUri_part_emptyUri() async {
    await super.test_invalidUri_part_emptyUri();
  }

  @failingTest
  test_invalidUris() async {
    await super.test_invalidUris();
  }

  @failingTest
  test_library_documented_lines() async {
    await super.test_library_documented_lines();
  }

  @failingTest
  test_library_documented_stars() async {
    await super.test_library_documented_stars();
  }

  @failingTest
  test_localFunctions_inTopLevelGetter() async {
    await super.test_localFunctions_inTopLevelGetter();
  }

  @failingTest
  test_main_class_alias_via_export() async {
    await super.test_main_class_alias_via_export();
  }

  @failingTest
  test_main_class_via_export() async {
    await super.test_main_class_via_export();
  }

  @failingTest
  test_main_getter() async {
    await super.test_main_getter();
  }

  @failingTest
  test_main_getter_via_export() async {
    await super.test_main_getter_via_export();
  }

  @failingTest
  test_main_typedef() async {
    await super.test_main_typedef();
  }

  @failingTest
  test_main_typedef_via_export() async {
    await super.test_main_typedef_via_export();
  }

  @failingTest
  test_main_variable_via_export() async {
    await super.test_main_variable_via_export();
  }

  @failingTest
  test_metadata_classDeclaration() async {
    await super.test_metadata_classDeclaration();
  }

  @failingTest
  test_metadata_classTypeAlias() async {
    await super.test_metadata_classTypeAlias();
  }

  @failingTest
  test_metadata_constructor_call_named() async {
    await super.test_metadata_constructor_call_named();
  }

  @failingTest
  test_metadata_constructor_call_named_prefixed() async {
    await super.test_metadata_constructor_call_named_prefixed();
  }

  @failingTest
  test_metadata_constructor_call_unnamed() async {
    await super.test_metadata_constructor_call_unnamed();
  }

  @failingTest
  test_metadata_constructor_call_unnamed_prefixed() async {
    await super.test_metadata_constructor_call_unnamed_prefixed();
  }

  @failingTest
  test_metadata_constructor_call_with_args() async {
    await super.test_metadata_constructor_call_with_args();
  }

  @failingTest
  test_metadata_constructorDeclaration_named() async {
    await super.test_metadata_constructorDeclaration_named();
  }

  @failingTest
  test_metadata_constructorDeclaration_unnamed() async {
    await super.test_metadata_constructorDeclaration_unnamed();
  }

  @failingTest
  test_metadata_enumDeclaration() async {
    await super.test_metadata_enumDeclaration();
  }

  @failingTest
  test_metadata_exportDirective() async {
    await super.test_metadata_exportDirective();
  }

  @failingTest
  test_metadata_fieldDeclaration() async {
    await super.test_metadata_fieldDeclaration();
  }

  @failingTest
  test_metadata_fieldFormalParameter() async {
    await super.test_metadata_fieldFormalParameter();
  }

  @failingTest
  test_metadata_fieldFormalParameter_withDefault() async {
    await super.test_metadata_fieldFormalParameter_withDefault();
  }

  @failingTest
  test_metadata_functionDeclaration_function() async {
    await super.test_metadata_functionDeclaration_function();
  }

  @failingTest
  test_metadata_functionDeclaration_getter() async {
    await super.test_metadata_functionDeclaration_getter();
  }

  @failingTest
  test_metadata_functionDeclaration_setter() async {
    await super.test_metadata_functionDeclaration_setter();
  }

  @failingTest
  test_metadata_functionTypeAlias() async {
    await super.test_metadata_functionTypeAlias();
  }

  @failingTest
  test_metadata_functionTypedFormalParameter() async {
    await super.test_metadata_functionTypedFormalParameter();
  }

  @failingTest
  test_metadata_functionTypedFormalParameter_withDefault() async {
    await super.test_metadata_functionTypedFormalParameter_withDefault();
  }

  @failingTest
  test_metadata_importDirective() async {
    await super.test_metadata_importDirective();
  }

  @failingTest
  test_metadata_invalid_classDeclaration() async {
    await super.test_metadata_invalid_classDeclaration();
  }

  @failingTest
  test_metadata_libraryDirective() async {
    await super.test_metadata_libraryDirective();
  }

  @failingTest
  test_metadata_methodDeclaration_getter() async {
    await super.test_metadata_methodDeclaration_getter();
  }

  @failingTest
  test_metadata_methodDeclaration_method() async {
    await super.test_metadata_methodDeclaration_method();
  }

  @failingTest
  test_metadata_methodDeclaration_setter() async {
    await super.test_metadata_methodDeclaration_setter();
  }

  @failingTest
  test_metadata_partDirective() async {
    await super.test_metadata_partDirective();
  }

  @failingTest
  test_metadata_prefixed_variable() async {
    await super.test_metadata_prefixed_variable();
  }

  @failingTest
  test_metadata_simpleFormalParameter() async {
    await super.test_metadata_simpleFormalParameter();
  }

  @failingTest
  test_metadata_simpleFormalParameter_withDefault() async {
    await super.test_metadata_simpleFormalParameter_withDefault();
  }

  @failingTest
  test_metadata_topLevelVariableDeclaration() async {
    await super.test_metadata_topLevelVariableDeclaration();
  }

  @failingTest
  test_metadata_typeParameter_ofFunction() async {
    await super.test_metadata_typeParameter_ofFunction();
  }

  @failingTest
  test_metadata_typeParameter_ofTypedef() async {
    await super.test_metadata_typeParameter_ofTypedef();
  }

  @failingTest
  test_method_documented() async {
    await super.test_method_documented();
  }

  @failingTest
  test_method_type_parameter() async {
    await super.test_method_type_parameter();
  }

  @failingTest
  test_method_type_parameter_in_generic_class() async {
    await super.test_method_type_parameter_in_generic_class();
  }

  @failingTest
  test_method_type_parameter_with_function_typed_parameter() async {
    await super.test_method_type_parameter_with_function_typed_parameter();
  }

  @failingTest
  test_nested_generic_functions_in_generic_class_with_function_typed_params() async {
    await super
        .test_nested_generic_functions_in_generic_class_with_function_typed_params();
  }

  @failingTest
  test_nested_generic_functions_in_generic_class_with_local_variables() async {
    await super
        .test_nested_generic_functions_in_generic_class_with_local_variables();
  }

  @failingTest
  test_nested_generic_functions_with_function_typed_param() async {
    await super.test_nested_generic_functions_with_function_typed_param();
  }

  @failingTest
  test_nested_generic_functions_with_local_variables() async {
    await super.test_nested_generic_functions_with_local_variables();
  }

  @failingTest
  test_parameter_checked() async {
    await super.test_parameter_checked();
  }

  @failingTest
  test_parameter_checked_inherited() async {
    await super.test_parameter_checked_inherited();
  }

  @failingTest
  test_parameter_covariant() async {
    await super.test_parameter_covariant();
  }

  @failingTest
  test_parameter_covariant_inherited() async {
    await super.test_parameter_covariant_inherited();
  }

  @failingTest
  test_parameter_parameters() async {
    await super.test_parameter_parameters();
  }

  @failingTest
  test_parameter_parameters_in_generic_class() async {
    await super.test_parameter_parameters_in_generic_class();
  }

  @failingTest
  test_parameter_return_type() async {
    await super.test_parameter_return_type();
  }

  @failingTest
  test_parameter_return_type_void() async {
    await super.test_parameter_return_type_void();
  }

  @failingTest
  test_parts() async {
    await super.test_parts();
  }

  @failingTest
  test_parts_invalidUri() async {
    await super.test_parts_invalidUri();
  }

  @failingTest
  test_parts_invalidUri_nullStringValue() async {
    await super.test_parts_invalidUri_nullStringValue();
  }

  @failingTest
  test_setter_covariant() async {
    await super.test_setter_covariant();
  }

  @failingTest
  test_setter_documented() async {
    await super.test_setter_documented();
  }

  @failingTest
  test_setter_external() async {
    await super.test_setter_external();
  }

  @failingTest
  test_setter_inferred_type_top_level_implicit_return() async {
    await super.test_setter_inferred_type_top_level_implicit_return();
  }

  @failingTest
  test_setters() async {
    await super.test_setters();
  }

  @failingTest
  test_syntheticFunctionType_inGenericClass() async {
    await super.test_syntheticFunctionType_inGenericClass();
  }

  @failingTest
  test_syntheticFunctionType_inGenericFunction() async {
    await super.test_syntheticFunctionType_inGenericFunction();
  }

  @failingTest
  test_syntheticFunctionType_noArguments() async {
    await super.test_syntheticFunctionType_noArguments();
  }

  @failingTest
  test_syntheticFunctionType_withArguments() async {
    await super.test_syntheticFunctionType_withArguments();
  }

  @failingTest
  test_type_invalid_topLevelVariableElement_asType() async {
    await super.test_type_invalid_topLevelVariableElement_asType();
  }

  @failingTest
  test_type_invalid_topLevelVariableElement_asTypeArgument() async {
    await super.test_type_invalid_topLevelVariableElement_asTypeArgument();
  }

  @failingTest
  test_type_invalid_typeParameter_asPrefix() async {
    await super.test_type_invalid_typeParameter_asPrefix();
  }

  @failingTest
  test_type_reference_lib_to_lib() async {
    await super.test_type_reference_lib_to_lib();
  }

  @failingTest
  test_type_reference_lib_to_part() async {
    await super.test_type_reference_lib_to_part();
  }

  @failingTest
  test_type_reference_part_to_lib() async {
    await super.test_type_reference_part_to_lib();
  }

  @failingTest
  test_type_reference_part_to_other_part() async {
    await super.test_type_reference_part_to_other_part();
  }

  @failingTest
  test_type_reference_part_to_part() async {
    await super.test_type_reference_part_to_part();
  }

  @failingTest
  test_type_reference_to_enum() async {
    await super.test_type_reference_to_enum();
  }

  @failingTest
  test_type_reference_to_import() async {
    await super.test_type_reference_to_import();
  }

  @failingTest
  test_type_reference_to_import_export() async {
    await super.test_type_reference_to_import_export();
  }

  @failingTest
  test_type_reference_to_import_export_export() async {
    await super.test_type_reference_to_import_export_export();
  }

  @failingTest
  test_type_reference_to_import_export_export_in_subdirs() async {
    await super.test_type_reference_to_import_export_export_in_subdirs();
  }

  @failingTest
  test_type_reference_to_import_export_in_subdirs() async {
    await super.test_type_reference_to_import_export_in_subdirs();
  }

  @failingTest
  test_type_reference_to_import_part() async {
    await super.test_type_reference_to_import_part();
  }

  @failingTest
  test_type_reference_to_import_part_in_subdir() async {
    await super.test_type_reference_to_import_part_in_subdir();
  }

  @failingTest
  test_type_reference_to_import_relative() async {
    await super.test_type_reference_to_import_relative();
  }

  @failingTest
  test_type_reference_to_typedef() async {
    await super.test_type_reference_to_typedef();
  }

  @failingTest
  test_type_reference_to_typedef_with_type_arguments() async {
    await super.test_type_reference_to_typedef_with_type_arguments();
  }

  @failingTest
  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    await super.test_type_reference_to_typedef_with_type_arguments_implicit();
  }

  @failingTest
  test_type_unresolved() async {
    await super.test_type_unresolved();
  }

  @failingTest
  test_type_unresolved_prefixed() async {
    await super.test_type_unresolved_prefixed();
  }

  @failingTest
  test_typedef_documented() async {
    await super.test_typedef_documented();
  }

  @failingTest
  test_typedef_generic() async {
    await super.test_typedef_generic();
  }

  @failingTest
  test_typedef_generic_asFieldType() async {
    await super.test_typedef_generic_asFieldType();
  }

  @failingTest
  test_typedef_parameter_parameters() async {
    await super.test_typedef_parameter_parameters();
  }

  @failingTest
  test_typedef_parameter_parameters_in_generic_class() async {
    await super.test_typedef_parameter_parameters_in_generic_class();
  }

  @failingTest
  test_typedef_parameter_return_type() async {
    await super.test_typedef_parameter_return_type();
  }

  @failingTest
  test_typedef_parameter_type() async {
    await super.test_typedef_parameter_type();
  }

  @failingTest
  test_typedef_parameter_type_generic() async {
    await super.test_typedef_parameter_type_generic();
  }

  @failingTest
  test_typedef_parameters() async {
    await super.test_typedef_parameters();
  }

  @failingTest
  test_typedef_return_type() async {
    await super.test_typedef_return_type();
  }

  @failingTest
  test_typedef_return_type_generic() async {
    await super.test_typedef_return_type_generic();
  }

  @failingTest
  test_typedef_return_type_implicit() async {
    await super.test_typedef_return_type_implicit();
  }

  @failingTest
  test_typedef_return_type_void() async {
    await super.test_typedef_return_type_void();
  }

  @failingTest
  test_typedef_type_parameters() async {
    await super.test_typedef_type_parameters();
  }

  @failingTest
  test_typedef_type_parameters_bound() async {
    await super.test_typedef_type_parameters_bound();
  }

  @failingTest
  test_typedef_type_parameters_bound_recursive() async {
    await super.test_typedef_type_parameters_bound_recursive();
  }

  @failingTest
  test_typedef_type_parameters_bound_recursive2() async {
    await super.test_typedef_type_parameters_bound_recursive2();
  }

  @failingTest
  test_typedef_type_parameters_f_bound_complex() async {
    await super.test_typedef_type_parameters_f_bound_complex();
  }

  @failingTest
  test_typedef_type_parameters_f_bound_simple() async {
    await super.test_typedef_type_parameters_f_bound_simple();
  }

  @failingTest
  test_unresolved_annotation_instanceCreation_argument_super() async {
    await super.test_unresolved_annotation_instanceCreation_argument_super();
  }

  @failingTest
  test_unresolved_annotation_instanceCreation_argument_this() async {
    await super.test_unresolved_annotation_instanceCreation_argument_this();
  }

  @failingTest
  test_unresolved_annotation_namedConstructorCall_noClass() async {
    await super.test_unresolved_annotation_namedConstructorCall_noClass();
  }

  @failingTest
  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    await super.test_unresolved_annotation_namedConstructorCall_noConstructor();
  }

  @failingTest
  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    await super.test_unresolved_annotation_prefixedIdentifier_badPrefix();
  }

  @failingTest
  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    await super.test_unresolved_annotation_prefixedIdentifier_noDeclaration();
  }

  @failingTest
  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    await super
        .test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix();
  }

  @failingTest
  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    await super
        .test_unresolved_annotation_prefixedNamedConstructorCall_noClass();
  }

  @failingTest
  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    await super
        .test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor();
  }

  @failingTest
  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    await super
        .test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix();
  }

  @failingTest
  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    await super
        .test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass();
  }

  @failingTest
  test_unresolved_annotation_simpleIdentifier() async {
    await super.test_unresolved_annotation_simpleIdentifier();
  }

  @failingTest
  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    await super.test_unresolved_annotation_unnamedConstructorCall_noClass();
  }

  @failingTest
  test_unresolved_export() async {
    await super.test_unresolved_export();
  }

  @failingTest
  test_unresolved_import() async {
    await super.test_unresolved_import();
  }

  @failingTest
  test_unresolved_part() async {
    await super.test_unresolved_part();
  }

  @failingTest
  test_unused_type_parameter() async {
    await super.test_unused_type_parameter();
  }

  @failingTest
  test_variable_documented() async {
    await super.test_variable_documented();
  }

  @failingTest
  test_variable_getterInLib_setterInPart() async {
    await super.test_variable_getterInLib_setterInPart();
  }

  @failingTest
  test_variable_getterInPart_setterInLib() async {
    await super.test_variable_getterInPart_setterInLib();
  }

  @failingTest
  test_variable_getterInPart_setterInPart() async {
    await super.test_variable_getterInPart_setterInPart();
  }

  @failingTest
  test_variable_propagatedType_final_dep_inPart() async {
    await super.test_variable_propagatedType_final_dep_inPart();
  }

  @failingTest
  test_variable_setterInPart_getterInPart() async {
    await super.test_variable_setterInPart_getterInPart();
  }
}

/**
 * Builder of [Expression]s from [kernel.Expression]s.
 */
class _ExprBuilder {
  final _KernelLibraryResynthesizerContextImpl _context;

  _ExprBuilder(this._context);

  Expression build(kernel.Expression expr) {
    if (expr is kernel.NullLiteral) {
      return AstTestFactory.nullLiteral();
    }
    if (expr is kernel.BoolLiteral) {
      return AstTestFactory.booleanLiteral(expr.value);
    }
    if (expr is kernel.IntLiteral) {
      return AstTestFactory.integer(expr.value);
    }
    if (expr is kernel.DoubleLiteral) {
      return AstTestFactory.doubleLiteral(expr.value);
    }
    if (expr is kernel.StringLiteral) {
      return AstTestFactory.string2(expr.value);
    }
    if (expr is kernel.StringConcatenation) {
      List<InterpolationElement> elements = expr.expressions
          .map(build)
          .map(_newInterpolationElement)
          .toList(growable: false);
      return AstTestFactory.string(elements);
    }
    if (expr is kernel.SymbolLiteral) {
      List<String> components = expr.value.split('.').toList();
      return AstTestFactory.symbolLiteral(components);
    }

    if (expr is kernel.ListLiteral) {
      Keyword keyword = expr.isConst ? Keyword.CONST : null;
      var typeArguments = _buildTypeArgumentList([expr.typeArgument]);
      var elements = expr.expressions.map(build).toList();
      return AstTestFactory.listLiteral2(keyword, typeArguments, elements);
    }

    if (expr is kernel.MapLiteral) {
      Keyword keyword = expr.isConst ? Keyword.CONST : null;
      var typeArguments =
          _buildTypeArgumentList([expr.keyType, expr.valueType]);

      int numberOfEntries = expr.entries.length;
      var entries = new List<MapLiteralEntry>(numberOfEntries);
      for (int i = 0; i < numberOfEntries; i++) {
        var entry = expr.entries[i];
        Expression key = build(entry.key);
        Expression value = build(entry.value);
        entries[i] = AstTestFactory.mapLiteralEntry2(key, value);
      }

      return AstTestFactory.mapLiteral(keyword, typeArguments, entries);
    }

    if (expr is kernel.StaticGet) {
      return _buildIdentifier(expr.targetReference, isGet: true);
    }

    if (expr is kernel.PropertyGet) {
      Expression target = build(expr.receiver);
      kernel.Reference reference = expr.interfaceTargetReference;
      SimpleIdentifier identifier = _buildSimpleIdentifier(reference);
      return AstTestFactory.propertyAccess(target, identifier);
    }

    if (expr is kernel.ConditionalExpression) {
      var condition = build(expr.condition);
      var then = build(expr.then);
      var otherwise = build(expr.otherwise);
      return AstTestFactory.conditionalExpression(condition, then, otherwise);
    }

    if (expr is kernel.Not) {
      kernel.Expression kernelOperand = expr.operand;
      var operand = build(kernelOperand);
      return AstTestFactory.prefixExpression(TokenType.BANG, operand);
    }

    if (expr is kernel.LogicalExpression) {
      var operator = _toBinaryOperatorTokenType(expr.operator);
      var left = build(expr.left);
      var right = build(expr.right);
      return AstTestFactory.binaryExpression(left, operator, right);
    }

    if (expr is kernel.MethodInvocation) {
      kernel.Member member = expr.interfaceTarget;
      if (member is kernel.Procedure) {
        if (member.kind == kernel.ProcedureKind.Operator) {
          var left = build(expr.receiver);
          String operatorName = expr.name.name;
          List<kernel.Expression> args = expr.arguments.positional;
          if (args.isEmpty) {
            if (operatorName == 'unary-') {
              return AstTestFactory.prefixExpression(TokenType.MINUS, left);
            }
            if (operatorName == '~') {
              return AstTestFactory.prefixExpression(TokenType.TILDE, left);
            }
          } else if (args.length == 1) {
            var operator = _toBinaryOperatorTokenType(operatorName);
            var right = build(args.single);
            return AstTestFactory.binaryExpression(left, operator, right);
          }
        }
      }
    }

    if (expr is kernel.ConstructorInvocation) {
      var element = _getElement(expr.targetReference);

      var kernelType = expr.getStaticType(_context._resynthesizer._types);
      var type = _context.getType(null, kernelType);
      TypeName typeName = _buildType(type);

      var constructorName = AstTestFactory.constructorName(
          typeName, element.name.isNotEmpty ? element.name : null);
      constructorName?.name?.staticElement = element;

      var keyword = expr.isConst ? Keyword.CONST : Keyword.NEW;
      var arguments = _toArguments(expr.arguments);
      return AstTestFactory.instanceCreationExpression(
          keyword, constructorName, arguments);
    }

    // TODO(scheglov): complete getExpression
    throw new UnimplementedError('kernel: (${expr.runtimeType}) $expr');
  }

  Expression _buildIdentifier(kernel.Reference reference, {bool isGet: false}) {
    Element element = _getElement(reference);
    if (isGet && element is PropertyInducingElement) {
      element = (element as PropertyInducingElement).getter;
    }
    SimpleIdentifier property = AstTestFactory.identifier3(element.displayName)
      ..staticElement = element;
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      SimpleIdentifier classRef = AstTestFactory
          .identifier3(enclosingElement.name)
            ..staticElement = enclosingElement;
      return AstTestFactory.propertyAccess(classRef, property);
    } else {
      return property;
    }
  }

  SimpleIdentifier _buildSimpleIdentifier(kernel.Reference reference) {
    String name = reference.canonicalName.name;
    SimpleIdentifier identifier = AstTestFactory.identifier3(name);
    Element element = _getElement(reference);
    identifier.staticElement = element;
    return identifier;
  }

  TypeAnnotation _buildType(DartType type) {
    if (type is InterfaceType) {
      var name = AstTestFactory.identifier3(type.element.name)
        ..staticElement = type.element
        ..staticType = type;
      List<TypeAnnotation> arguments = _buildTypeArguments(type.typeArguments);
      return AstTestFactory.typeName3(name, arguments)..type = type;
    }
    if (type is DynamicTypeImpl) {
      var name = AstTestFactory.identifier3('dynamic')
        ..staticElement = type.element
        ..staticType = type;
      return AstTestFactory.typeName3(name)..type = type;
    }
    // TODO(scheglov) Implement for other types.
    throw new UnimplementedError('type: $type');
  }

  TypeArgumentList _buildTypeArgumentList(List<kernel.DartType> kernels) {
    int length = kernels.length;
    var types = new List<TypeAnnotation>(length);
    for (int i = 0; i < length; i++) {
      DartType type = _context.getType(null, kernels[i]);
      TypeAnnotation typeAnnotation = _buildType(type);
      types[i] = typeAnnotation;
    }
    return AstTestFactory.typeArgumentList(types);
  }

  List<TypeAnnotation> _buildTypeArguments(List<DartType> types) {
    if (types.every((t) => t.isDynamic)) return null;
    return types.map(_buildType).toList();
  }

  ElementImpl _getElement(kernel.Reference reference) {
    return _context._getElement(reference?.canonicalName);
  }

  InterpolationElement _newInterpolationElement(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return astFactory.interpolationString(expr.literal, expr.value);
    } else {
      return AstTestFactory.interpolationExpression(expr);
    }
  }

  /// Return [Expression]s for the given [kernelArguments].
  List<Expression> _toArguments(kernel.Arguments kernelArguments) {
    int numPositional = kernelArguments.positional.length;
    int numNamed = kernelArguments.named.length;
    var arguments = new List<Expression>(numPositional + numNamed);

    int i = 0;
    for (kernel.Expression k in kernelArguments.positional) {
      arguments[i++] = build(k);
    }

    for (kernel.NamedExpression k in kernelArguments.named) {
      var value = build(k.value);
      arguments[i++] = AstTestFactory.namedExpression2(k.name, value);
    }

    return arguments;
  }

  /// Return the [TokenType] for the given operator [name].
  TokenType _toBinaryOperatorTokenType(String name) {
    if (name == '==') return TokenType.EQ_EQ;
    if (name == '&&') return TokenType.AMPERSAND_AMPERSAND;
    if (name == '||') return TokenType.BAR_BAR;
    if (name == '^') return TokenType.CARET;
    if (name == '&') return TokenType.AMPERSAND;
    if (name == '|') return TokenType.BAR;
    if (name == '>>') return TokenType.GT_GT;
    if (name == '<<') return TokenType.LT_LT;
    if (name == '+') return TokenType.PLUS;
    if (name == '-') return TokenType.MINUS;
    if (name == '*') return TokenType.STAR;
    if (name == '/') return TokenType.SLASH;
    if (name == '~/') return TokenType.TILDE_SLASH;
    if (name == '%') return TokenType.PERCENT;
    if (name == '>') return TokenType.GT;
    if (name == '<') return TokenType.LT;
    if (name == '>=') return TokenType.GT_EQ;
    if (name == '<=') return TokenType.LT_EQ;
    if (name == 'unary-') return TokenType.MINUS;
    throw new ArgumentError(name);
  }
}

class _FileSystemAdaptor implements FileSystem {
  final ResourceProvider provider;

  _FileSystemAdaptor(this.provider);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('file')) {
      var file = provider.getFile(uri.path);
      return new _FileSystemEntityAdaptor(uri, file);
    } else {
      throw new ArgumentError(
          'Only file:// URIs are supported, but $uri is given.');
    }
  }
}

class _FileSystemEntityAdaptor implements FileSystemEntity {
  final Uri uri;
  final File file;

  _FileSystemEntityAdaptor(this.uri, this.file);

  @override
  Future<bool> exists() async {
    return file.exists;
  }

  @override
  Future<List<int>> readAsBytes() async {
    return file.readAsBytesSync();
  }

  @override
  Future<String> readAsString() async {
    return file.readAsStringSync();
  }
}

class _KernelLibraryResynthesizerContextImpl
    implements KernelLibraryResynthesizerContext {
  final _KernelResynthesizer _resynthesizer;

  @override
  final kernel.Library library;

  _KernelLibraryResynthesizerContextImpl(this._resynthesizer, this.library);

  @override
  Expression getExpression(kernel.Expression expression) {
    return new _ExprBuilder(this).build(expression);
  }

  @override
  InterfaceType getInterfaceType(
      ElementImpl context, kernel.Supertype kernelType) {
    return _getInterfaceType(
        kernelType.className.canonicalName, kernelType.typeArguments);
  }

  @override
  LibraryElement getLibrary(String uriStr) {
    return _resynthesizer.getLibrary(uriStr);
  }

  DartType getType(ElementImpl context, kernel.DartType kernelType) {
    if (kernelType is kernel.DynamicType) return DynamicTypeImpl.instance;
    if (kernelType is kernel.VoidType) return VoidTypeImpl.instance;
    if (kernelType is kernel.InterfaceType) {
      return _getInterfaceType(
          kernelType.className.canonicalName, kernelType.typeArguments);
    }
    if (kernelType is kernel.TypeParameterType) {
      kernel.TypeParameter kTypeParameter = kernelType.parameter;
      return _getTypeParameter(context, kTypeParameter).type;
    }
    // TODO(scheglov) Support other kernel types.
    throw new UnimplementedError('For ${kernelType.runtimeType}');
  }

  /**
   * Return the [ElementImpl] that corresponds to the given [name], or `null`
   * if the corresponding element cannot be found.
   */
  ElementImpl _getElement(kernel.CanonicalName name) {
    if (name == null) return null;
    kernel.CanonicalName parentName = name.parent;

    // If the parent is the root, then this name is a library.
    if (parentName.isRoot) {
      return _resynthesizer.getLibrary(name.name);
    }

    // Skip qualifiers.
    bool isGetter = false;
    bool isSetter = false;
    bool isField = false;
    bool isConstructor = false;
    bool isMethod = false;
    if (parentName.name == '@getters') {
      isGetter = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@setters') {
      isSetter = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@fields') {
      isField = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@constructors') {
      isConstructor = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@methods') {
      isMethod = true;
      parentName = parentName.parent;
    }

    ElementImpl parentElement = _getElement(parentName);
    if (parentElement == null) return null;

    // Search in units of the library.
    if (parentElement is LibraryElementImpl) {
      for (CompilationUnitElement unit in parentElement.units) {
        CompilationUnitElementImpl unitImpl = unit;
        ElementImpl child = unitImpl.getChild(name.name);
        if (child != null) {
          return child;
        }
      }
      return null;
    }

    // Search in the class.
    if (parentElement is ClassElementImpl) {
      if (isGetter) {
        return parentElement.getGetter(name.name) as ElementImpl;
      } else if (isSetter) {
        return parentElement.getSetter(name.name) as ElementImpl;
      } else if (isField) {
        return parentElement.getField(name.name) as ElementImpl;
      } else if (isConstructor) {
        if (name.name.isEmpty) {
          return parentElement.unnamedConstructor as ConstructorElementImpl;
        }
        return parentElement.getNamedConstructor(name.name) as ElementImpl;
      } else if (isMethod) {
        return parentElement.getMethod(name.name) as ElementImpl;
      }
      return null;
    }

    throw new UnimplementedError('Should not be reached.');
  }

  InterfaceType _getInterfaceType(
      kernel.CanonicalName className, List<kernel.DartType> kernelArguments) {
    var libraryName = className.parent;
    var libraryElement = _resynthesizer.getLibrary(libraryName.name);
    ClassElementImpl classElement = libraryElement.getType(className.name);

    if (kernelArguments.isEmpty) {
      return classElement.type;
    }

    return new InterfaceTypeImpl.elementWithNameAndArgs(
        classElement, classElement.name, () {
      List<DartType> arguments = kernelArguments
          .map((kernel.DartType k) => getType(classElement, k))
          .toList(growable: false);
      return arguments;
    });
  }

  /// Return the [TypeParameterElement] for the given [kernelTypeParameter].
  TypeParameterElement _getTypeParameter(
      ElementImpl context, kernel.TypeParameter kernelTypeParameter) {
    String name = kernelTypeParameter.name;
    for (var ctx = context; ctx != null; ctx = ctx.enclosingElement) {
      if (ctx is TypeParameterizedElementMixin) {
        for (var typeParameter in ctx.typeParameters) {
          if (typeParameter.name == name) {
            return typeParameter;
          }
        }
      }
    }
    throw new StateError('Not found $kernelTypeParameter in $context');
  }
}

class _KernelResynthesizer {
  final AnalysisContext _analysisContext;
  final kernel.TypeEnvironment _types;
  final Map<String, kernel.Library> _kernelMap;
  final Map<String, LibraryElementImpl> _libraryMap = {};

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  _KernelResynthesizer(this._analysisContext, this._types, this._kernelMap);

  LibraryElementImpl getLibrary(String uriStr) {
    return _libraryMap.putIfAbsent(uriStr, () {
      var kernel = _kernelMap[uriStr];
      if (kernel == null) return null;

      var libraryContext =
          new _KernelLibraryResynthesizerContextImpl(this, kernel);
      Source librarySource = _getSource(uriStr);
      LibraryElementImpl libraryElement =
          new LibraryElementImpl.forKernel(_analysisContext, libraryContext);
      CompilationUnitElementImpl definingUnit =
          libraryElement.definingCompilationUnit;
      definingUnit.source = librarySource;
      definingUnit.librarySource = librarySource;
      return libraryElement;
    });
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(
        uri, () => _analysisContext.sourceFactory.forUri(uri));
  }
}
