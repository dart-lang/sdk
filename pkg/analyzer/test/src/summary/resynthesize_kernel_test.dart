// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_kernel_test;

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/frontend_resolution.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/text/ast_to_text.dart' as kernel;
import 'package:kernel/type_environment.dart' as kernel;
import 'package:test/src/frontend/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context/mock_sdk.dart';
import 'element_text.dart';
import 'resynthesize_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeKernelStrongTest);
  });
}

/// Tests marked with this annotation fail because they test features that
/// were implemented in Analyzer, but are intentionally not included into
/// the Dart 2.0 plan, so will not be implemented by Fasta.
const notForDart2 = const Object();

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class ResynthesizeKernelStrongTest extends ResynthesizeTest {
  static const DEBUG = false;

  final resourceProvider = new MemoryResourceProvider();

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

    String testPath = resourceProvider.convertPath('/test.dart');
    File testFile = resourceProvider.newFile(testPath, text);
    Uri testUri = testFile.toUri();
    String testUriStr = testUri.toString();

    KernelResynthesizer resynthesizer = await _createResynthesizer(testUri);
    return resynthesizer.getLibrary(testUriStr);
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_class_constructor_field_formal_multiple_matching_fields() async {
    await super.test_class_constructor_field_formal_multiple_matching_fields();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_class_constructor_fieldFormal_named_withDefault() async {
    await super.test_class_constructor_fieldFormal_named_withDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_class_constructor_fieldFormal_optional_withDefault() async {
    await super.test_class_constructor_fieldFormal_optional_withDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_class_field_const() async {
    await super.test_class_field_const();
  }

  @override
  test_class_setter_invalid_named_parameter() async {
    var library = await checkLibrary('class C { void set x({a}) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @override
  test_class_setter_invalid_no_parameter() async {
    var library = await checkLibrary('class C { void set x() {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @override
  test_class_setter_invalid_optional_parameter() async {
    var library = await checkLibrary('class C { void set x([a]) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @override
  test_class_setter_invalid_too_many_parameters() async {
    var library = await checkLibrary('class C { void set x(a, b) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_class_type_parameters_bound() async {
    // https://github.com/dart-lang/sdk/issues/29561
    // Fasta does not provide a flag for explicit vs. implicit Object bound.
    await super.test_class_type_parameters_bound();
  }

  @failingTest // See dartbug.com/32290
  test_const_constructor_inferred_args() =>
      super.test_const_constructor_inferred_args();

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_finalField_hasConstConstructor() async {
    await super.test_const_finalField_hasConstConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invalid_field_const() async {
    await super.test_const_invalid_field_const();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invalid_intLiteral() async {
    await super.test_const_invalid_intLiteral();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invalid_topLevel() async {
    await super.test_const_invalid_topLevel();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_named() async {
    await super.test_const_invokeConstructor_generic_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_named_imported() async {
    await super.test_const_invokeConstructor_generic_named_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_named_imported_withPrefix() async {
    return super
        .test_const_invokeConstructor_generic_named_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_noTypeArguments() async {
    await super.test_const_invokeConstructor_generic_noTypeArguments();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_unnamed() async {
    await super.test_const_invokeConstructor_generic_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_unnamed_imported() async {
    await super.test_const_invokeConstructor_generic_unnamed_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() async {
    return super
        .test_const_invokeConstructor_generic_unnamed_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named() async {
    await super.test_const_invokeConstructor_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_imported() async {
    await super.test_const_invokeConstructor_named_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_imported_withPrefix() async {
    await super.test_const_invokeConstructor_named_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_unresolved() async {
    await super.test_const_invokeConstructor_named_unresolved();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_unresolved2() async {
    await super.test_const_invokeConstructor_named_unresolved2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_unresolved3() async {
    await super.test_const_invokeConstructor_named_unresolved3();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_unresolved4() async {
    await super.test_const_invokeConstructor_named_unresolved4();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_unresolved5() async {
    await super.test_const_invokeConstructor_named_unresolved5();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_named_unresolved6() async {
    await super.test_const_invokeConstructor_named_unresolved6();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_unnamed() async {
    await super.test_const_invokeConstructor_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_unnamed_imported() async {
    await super.test_const_invokeConstructor_unnamed_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_unnamed_imported_withPrefix() async {
    await super.test_const_invokeConstructor_unnamed_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_unnamed_unresolved() async {
    await super.test_const_invokeConstructor_unnamed_unresolved();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_unnamed_unresolved2() async {
    await super.test_const_invokeConstructor_unnamed_unresolved2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_invokeConstructor_unnamed_unresolved3() async {
    await super.test_const_invokeConstructor_unnamed_unresolved3();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofClassConstField() async {
    await super.test_const_length_ofClassConstField();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofClassConstField_imported() async {
    await super.test_const_length_ofClassConstField_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofClassConstField_imported_withPrefix() async {
    await super.test_const_length_ofClassConstField_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofStringLiteral() async {
    await super.test_const_length_ofStringLiteral();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofTopLevelVariable() async {
    await super.test_const_length_ofTopLevelVariable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofTopLevelVariable_imported() async {
    await super.test_const_length_ofTopLevelVariable_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_ofTopLevelVariable_imported_withPrefix() async {
    await super.test_const_length_ofTopLevelVariable_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_length_staticMethod() async {
    await super.test_const_length_staticMethod();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_list_inferredType() async {
    await super.test_const_list_inferredType();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_map_inferredType() async {
    await super.test_const_map_inferredType();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_parameterDefaultValue_initializingFormal_functionTyped() async {
    return super
        .test_const_parameterDefaultValue_initializingFormal_functionTyped();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_parameterDefaultValue_initializingFormal_named() async {
    await super.test_const_parameterDefaultValue_initializingFormal_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_parameterDefaultValue_initializingFormal_positional() async {
    return super
        .test_const_parameterDefaultValue_initializingFormal_positional();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_parameterDefaultValue_normal() async {
    await super.test_const_parameterDefaultValue_normal();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_staticField() async {
    await super.test_const_reference_staticField();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_staticField_imported() async {
    await super.test_const_reference_staticField_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_staticField_imported_withPrefix() async {
    await super.test_const_reference_staticField_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_staticMethod() async {
    await super.test_const_reference_staticMethod();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_staticMethod_imported() async {
    await super.test_const_reference_staticMethod_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_staticMethod_imported_withPrefix() async {
    await super.test_const_reference_staticMethod_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelFunction() async {
    await super.test_const_reference_topLevelFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelFunction_generic() async {
    await super.test_const_reference_topLevelFunction_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelFunction_imported() async {
    await super.test_const_reference_topLevelFunction_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelFunction_imported_withPrefix() async {
    await super.test_const_reference_topLevelFunction_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelVariable() async {
    await super.test_const_reference_topLevelVariable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelVariable_imported() async {
    await super.test_const_reference_topLevelVariable_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_topLevelVariable_imported_withPrefix() async {
    await super.test_const_reference_topLevelVariable_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_type() async {
    await super.test_const_reference_type();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_type_imported() async {
    await super.test_const_reference_type_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_type_imported_withPrefix() async {
    await super.test_const_reference_type_imported_withPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_unresolved_prefix0() async {
    await super.test_const_reference_unresolved_prefix0();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_unresolved_prefix1() async {
    await super.test_const_reference_unresolved_prefix1();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_reference_unresolved_prefix2() async {
    await super.test_const_reference_unresolved_prefix2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_binary() async {
    await super.test_const_topLevel_binary();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_conditional() async {
    await super.test_const_topLevel_conditional();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_identical() async {
    await super.test_const_topLevel_identical();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_ifNull() async {
    await super.test_const_topLevel_ifNull();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_literal() async {
    await super.test_const_topLevel_literal();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_parenthesis() async {
    await super.test_const_topLevel_parenthesis();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_prefix() async {
    await super.test_const_topLevel_prefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_super() async {
    await super.test_const_topLevel_super();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_this() async {
    await super.test_const_topLevel_this();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_typedList() async {
    await super.test_const_topLevel_typedList();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_typedList_imported() async {
    await super.test_const_topLevel_typedList_imported();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_typedList_importedWithPrefix() async {
    await super.test_const_topLevel_typedList_importedWithPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_typedList_typedefArgument() async {
    await super.test_const_topLevel_typedList_typedefArgument();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_typedMap() async {
    await super.test_const_topLevel_typedMap();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_untypedList() async {
    await super.test_const_topLevel_untypedList();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_const_topLevel_untypedMap() async {
    await super.test_const_topLevel_untypedMap();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constExpr_pushReference_field_simpleIdentifier() async {
    await super.test_constExpr_pushReference_field_simpleIdentifier();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    await super.test_constExpr_pushReference_staticMethod_simpleIdentifier();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_assertInvocation() async {
    await super.test_constructor_initializers_assertInvocation();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_assertInvocation_message() async {
    await super.test_constructor_initializers_assertInvocation_message();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_field() async {
    await super.test_constructor_initializers_field();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_field_notConst() async {
    await super.test_constructor_initializers_field_notConst();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_field_withParameter() async {
    await super.test_constructor_initializers_field_withParameter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_superInvocation_named() async {
    await super.test_constructor_initializers_superInvocation_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_superInvocation_named_underscore() async {
    return super
        .test_constructor_initializers_superInvocation_named_underscore();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_superInvocation_namedExpression() async {
    return super
        .test_constructor_initializers_superInvocation_namedExpression();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_superInvocation_unnamed() async {
    await super.test_constructor_initializers_superInvocation_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_thisInvocation_named() async {
    await super.test_constructor_initializers_thisInvocation_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_thisInvocation_namedExpression() async {
    await super.test_constructor_initializers_thisInvocation_namedExpression();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_initializers_thisInvocation_unnamed() async {
    await super.test_constructor_initializers_thisInvocation_unnamed();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_named_generic() async {
    await super.test_constructor_redirected_factory_named_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_named_imported_generic() async {
    await super.test_constructor_redirected_factory_named_imported_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_named_prefixed_generic() async {
    await super.test_constructor_redirected_factory_named_prefixed_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_unnamed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_unnamed_imported_generic() async {
    await super.test_constructor_redirected_factory_unnamed_imported_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_redirected_thisInvocation_named() async {
    await super.test_constructor_redirected_thisInvocation_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_redirected_thisInvocation_named_generic() async {
    await super.test_constructor_redirected_thisInvocation_named_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_redirected_thisInvocation_unnamed() async {
    await super.test_constructor_redirected_thisInvocation_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_redirected_thisInvocation_unnamed_generic() async {
    await super.test_constructor_redirected_thisInvocation_unnamed_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_constructor_withCycles_const() async {
    await super.test_constructor_withCycles_const();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_defaultValue_refersToGenericClass_constructor() async {
    await super.test_defaultValue_refersToGenericClass_constructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_defaultValue_refersToGenericClass_constructor2() async {
    await super.test_defaultValue_refersToGenericClass_constructor2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_defaultValue_refersToGenericClass_functionG() async {
    await super.test_defaultValue_refersToGenericClass_functionG();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_defaultValue_refersToGenericClass_methodG() async {
    await super.test_defaultValue_refersToGenericClass_methodG();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_defaultValue_refersToGenericClass_methodG_classG() async {
    await super.test_defaultValue_refersToGenericClass_methodG_classG();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_defaultValue_refersToGenericClass_methodNG() async {
    await super.test_defaultValue_refersToGenericClass_methodNG();
  }

  @failingTest
  @notForDart2
  test_export_configurations_useFirst() async {
    await super.test_export_configurations_useFirst();
  }

  @failingTest
  @notForDart2
  test_export_configurations_useSecond() async {
    await super.test_export_configurations_useSecond();
  }

  @failingTest
  @notForDart2
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_field_propagatedType_const_noDep() async {
    await super.test_field_propagatedType_const_noDep();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_function_async() async {
    await super.test_function_async();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_function_asyncStar() async {
    await super.test_function_asyncStar();
  }

  @failingTest
  @override
  test_futureOr() async {
    // TODO(brianwilkerson) Triage this failure.
    fail('Inconsistent results');
  }

  @failingTest
  @override
  test_futureOr_const() async {
    // TODO(brianwilkerson) Triage this failure.
    fail('Inconsistent results');
  }

  @failingTest
  @override
  test_futureOr_inferred() async {
    // TODO(brianwilkerson) Triage this failure.
    fail('Inconsistent results');
  }

  test_getElement_unit() async {
    String text = 'class C {}';
    Source source = addLibrarySource('/test.dart', text);

    new MockSdk(resourceProvider: resourceProvider);
    var resynthesizer = await _createResynthesizer(source.uri);

    CompilationUnitElement unitElement = resynthesizer.getElement(
        new ElementLocationImpl.con3(
            [source.uri.toString(), source.uri.toString()]));
    expect(unitElement.librarySource, source);
    expect(unitElement.source, source);

    // TODO(scheglov) Add some more checks?
    // TODO(scheglov) Add tests for other elements
  }

  @failingTest
  @notForDart2
  test_import_configurations_useFirst() async {
    await super.test_import_configurations_useFirst();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30725')
  test_import_invalidUri_metadata() async {
    await super.test_import_invalidUri_metadata();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_infer_generic_typedef_simple() async {
    await super.test_infer_generic_typedef_simple();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_instantiateToBounds_functionTypeAlias_simple() async {
    await super.test_instantiateToBounds_functionTypeAlias_simple();
  }

  @override
  @failingTest
  test_invalid_annotation_prefixed_constructor() {
    return super.test_invalid_annotation_prefixed_constructor();
  }

  @override
  @failingTest
  test_invalid_annotation_unprefixed_constructor() {
    return super.test_invalid_annotation_unprefixed_constructor();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_nameConflict_imported() async {
    await super.test_invalid_nameConflict_imported();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_nameConflict_imported_exported() async {
    await super.test_invalid_nameConflict_imported_exported();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_nameConflict_local() async {
    await super.test_invalid_nameConflict_local();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30725')
  test_invalidUri_part_emptyUri() async {
    await super.test_invalidUri_part_emptyUri();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUris() async {
    await super.test_invalidUris();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_member_function_async() async {
    await super.test_member_function_async();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_member_function_asyncStar() async {
    await super.test_member_function_asyncStar();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_member_function_syncStar() async {
    await super.test_member_function_syncStar();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_classDeclaration() async {
    await super.test_metadata_classDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_classTypeAlias() async {
    await super.test_metadata_classTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructor_call_named() async {
    await super.test_metadata_constructor_call_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructor_call_named_prefixed() async {
    await super.test_metadata_constructor_call_named_prefixed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructor_call_unnamed() async {
    await super.test_metadata_constructor_call_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructor_call_unnamed_prefixed() async {
    await super.test_metadata_constructor_call_unnamed_prefixed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructor_call_with_args() async {
    await super.test_metadata_constructor_call_with_args();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructorDeclaration_named() async {
    await super.test_metadata_constructorDeclaration_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_constructorDeclaration_unnamed() async {
    await super.test_metadata_constructorDeclaration_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_enumConstantDeclaration() async {
    await super.test_metadata_enumConstantDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_enumDeclaration() async {
    await super.test_metadata_enumDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_exportDirective() async {
    await super.test_metadata_exportDirective();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_fieldDeclaration() async {
    await super.test_metadata_fieldDeclaration();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_fieldFormalParameter() async {
    await super.test_metadata_fieldFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_fieldFormalParameter_withDefault() async {
    await super.test_metadata_fieldFormalParameter_withDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_functionDeclaration_function() async {
    await super.test_metadata_functionDeclaration_function();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_functionDeclaration_getter() async {
    await super.test_metadata_functionDeclaration_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_functionDeclaration_setter() async {
    await super.test_metadata_functionDeclaration_setter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_functionTypeAlias() async {
    await super.test_metadata_functionTypeAlias();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_functionTypedFormalParameter() async {
    await super.test_metadata_functionTypedFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_functionTypedFormalParameter_withDefault() async {
    await super.test_metadata_functionTypedFormalParameter_withDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_importDirective() async {
    await super.test_metadata_importDirective();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_invalid_classDeclaration() async {
    await super.test_metadata_invalid_classDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_libraryDirective() async {
    await super.test_metadata_libraryDirective();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_methodDeclaration_getter() async {
    await super.test_metadata_methodDeclaration_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_methodDeclaration_method() async {
    await super.test_metadata_methodDeclaration_method();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_methodDeclaration_setter() async {
    await super.test_metadata_methodDeclaration_setter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_partDirective() async {
    await super.test_metadata_partDirective();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_prefixed_variable() async {
    await super.test_metadata_prefixed_variable();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_simpleFormalParameter() async {
    await super.test_metadata_simpleFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_simpleFormalParameter_withDefault() async {
    await super.test_metadata_simpleFormalParameter_withDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_topLevelVariableDeclaration() async {
    await super.test_metadata_topLevelVariableDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_typeParameter_ofClass() async {
    await super.test_metadata_typeParameter_ofClass();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_typeParameter_ofClassTypeAlias() async {
    await super.test_metadata_typeParameter_ofClassTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_typeParameter_ofFunction() async {
    await super.test_metadata_typeParameter_ofFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_metadata_typeParameter_ofTypedef() async {
    await super.test_metadata_typeParameter_ofTypedef();
  }

  @failingTest
  @notForDart2
  test_parameter_checked() async {
    // @checked is deprecated, use `covariant` instead.
    await super.test_parameter_checked();
  }

  @failingTest
  @notForDart2
  test_parameter_checked_inherited() async {
    // @checked is deprecated, use `covariant` instead.
    await super.test_parameter_checked_inherited();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_parameterTypeNotInferred_constructor() async {
    await super.test_parameterTypeNotInferred_constructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_parameterTypeNotInferred_initializingFormal() async {
    await super.test_parameterTypeNotInferred_initializingFormal();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_parameterTypeNotInferred_staticMethod() async {
    await super.test_parameterTypeNotInferred_staticMethod();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_parameterTypeNotInferred_topLevelFunction() async {
    await super.test_parameterTypeNotInferred_topLevelFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_setter_inferred_type_conflictingInheritance() async {
    await super.test_setter_inferred_type_conflictingInheritance();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_type_reference_to_typedef_with_type_arguments() async {
    await super.test_type_reference_to_typedef_with_type_arguments();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    await super.test_type_reference_to_typedef_with_type_arguments_implicit();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31711')
  test_typedef_generic_asFieldType() async {
    await super.test_typedef_generic_asFieldType();
  }

  @failingTest
  @potentialAnalyzerProblem
  test_typedef_type_parameters_bound() async {
    // https://github.com/dart-lang/sdk/issues/29561
    await super.test_typedef_type_parameters_bound();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_unresolved_annotation_instanceCreation_argument_super() async {
    await super.test_unresolved_annotation_instanceCreation_argument_super();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_instanceCreation_argument_this() async {
    await super.test_unresolved_annotation_instanceCreation_argument_this();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_namedConstructorCall_noClass() async {
    await super.test_unresolved_annotation_namedConstructorCall_noClass();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    return super
        .test_unresolved_annotation_namedConstructorCall_noConstructor();
  }

  @override
  @failingTest
  test_unresolved_annotation_prefixedIdentifier_badPrefix() {
    return super.test_unresolved_annotation_prefixedIdentifier_badPrefix();
  }

  @override
  @failingTest
  test_unresolved_annotation_prefixedIdentifier_noDeclaration() {
    return super.test_unresolved_annotation_prefixedIdentifier_noDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    return super
        .test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    return super
        .test_unresolved_annotation_prefixedNamedConstructorCall_noClass();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    return super
        .test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    return super
        .test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    return super
        .test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass();
  }

  @override
  @failingTest
  test_unresolved_annotation_simpleIdentifier() {
    return super.test_unresolved_annotation_simpleIdentifier();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    await super.test_unresolved_annotation_unnamedConstructorCall_noClass();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_variable_const() async {
    await super.test_variable_const();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_variable_propagatedType_const_noDep() async {
    await super.test_variable_propagatedType_const_noDep();
  }

  Future<KernelResynthesizer> _createResynthesizer(Uri testUri) async {
    var logger = new PerformanceLog(null);
    var byteStore = new MemoryByteStore();
    var analysisOptions = new AnalysisOptionsImpl()..strongMode = true;

    var fsState = new FileSystemState(
        logger,
        byteStore,
        new FileContentOverlay(),
        resourceProvider,
        sourceFactory,
        analysisOptions,
        new Uint32List(0));

    var compiler = new FrontEndCompiler(
        logger,
        new MemoryByteStore(),
        analysisOptions,
        null,
        sourceFactory,
        fsState,
        resourceProvider.pathContext);

    LibraryOutlineResult libraryResult = await compiler.getOutline(testUri);

    // Remember Kernel libraries produced by the compiler.
    var libraryMap = <String, kernel.Library>{};
    var libraryExistMap = <String, bool>{};
    for (var library in libraryResult.component.libraries) {
      String uriStr = library.importUri.toString();
      libraryMap[uriStr] = library;
      FileState file = fsState.getFileForUri(library.importUri);
      libraryExistMap[uriStr] = file?.exists ?? false;
    }

    if (DEBUG) {
      String testUriStr = testUri.toString();
      var library = libraryMap[testUriStr];
      print(_getLibraryText(library));
    }

    var resynthesizer = new KernelResynthesizer(
        context, libraryResult.types, libraryMap, libraryExistMap);
    return resynthesizer;
  }

  String _getLibraryText(kernel.Library library) {
    StringBuffer buffer = new StringBuffer();
    new kernel.Printer(buffer, syntheticNames: new kernel.NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
  }
}
