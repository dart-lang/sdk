// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_kernel_test;

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/libraries_specification.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/byte_store/byte_store.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart' as kernel;
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

/// Tests marked with this annotation fail because of a Fasta problem.
const fastaProblem = const Object();

@reflectiveTest
class ResynthesizeKernelStrongTest extends ResynthesizeTest {
  static const DEBUG = false;

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

    Map<String, LibraryInfo> dartLibraries = {};
    MockSdk.FULL_URI_MAP.forEach((dartUri, path) {
      var name = Uri.parse(dartUri).path;
      dartLibraries[name] =
          new LibraryInfo(name, Uri.parse('file://$path'), const []);
    });

    var uriTranslator = new UriTranslatorImpl(
        new TargetLibrariesSpecification('none', dartLibraries),
        Packages.noPackages);
    var options = new ProcessedOptions(new CompilerOptions()
      ..target = new NoneTarget(new TargetFlags(strongMode: isStrongMode))
      ..reportMessages = false
      ..logger = new PerformanceLog(null)
      ..fileSystem = new _FileSystemAdaptor(resourceProvider)
      ..byteStore = new MemoryByteStore());
    var driver = new KernelDriver(options, uriTranslator);

    KernelResult kernelResult = await driver.getKernel(testUri);

    var libraryMap = <String, kernel.Library>{};
    for (var cycleResult in kernelResult.results) {
      for (var library in cycleResult.kernelLibraries) {
        String uriStr = library.importUri.toString();
        libraryMap[uriStr] = library;
      }
    }

    if (DEBUG) {
      var library = libraryMap[testUriStr];
      print(_getLibraryText(library));
    }

    var resynthesizer =
        new KernelResynthesizer(context, kernelResult.types, libraryMap);
    return resynthesizer.getLibrary(testUriStr);
  }

  @failingTest
  @fastaProblem
  test_class_constructor_field_formal_multiple_matching_fields() async {
    // Fasta does not generate the class.
    // main() with a fatal error is generated instead.
    await super.test_class_constructor_field_formal_multiple_matching_fields();
  }

  @failingTest
  @fastaProblem
  test_class_type_parameters_bound() async {
    // Fasta does not provide a flag for explicit vs. implicit Object bound.
    await super.test_class_type_parameters_bound();
  }

  @failingTest
  @fastaProblem
  test_const_invalid_field_const() async {
    // Fasta generates additional `#errors` top-level variable.
    await super.test_const_invalid_field_const();
  }

  @failingTest
  @fastaProblem
  test_const_invalid_intLiteral() async {
    // https://github.com/dart-lang/sdk/issues/30266
    await super.test_const_invalid_intLiteral();
  }

  @failingTest
  @fastaProblem
  test_const_invalid_topLevel() async {
    // Fasta generates additional `#errors` top-level variable.
    await super.test_const_invalid_topLevel();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_named_unresolved() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_named_unresolved();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_named_unresolved2() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_named_unresolved2();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_named_unresolved3() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_named_unresolved3();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_named_unresolved4() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_named_unresolved4();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_named_unresolved5() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_named_unresolved5();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_named_unresolved6() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_named_unresolved6();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_unnamed_unresolved() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_unnamed_unresolved();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_unnamed_unresolved2() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_unnamed_unresolved2();
  }

  @failingTest
  @fastaProblem
  test_const_invokeConstructor_unnamed_unresolved3() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_invokeConstructor_unnamed_unresolved3();
  }

  @failingTest
  test_const_reference_type_imported_withPrefix() async {
    await super.test_const_reference_type_imported_withPrefix();
  }

  @failingTest
  @fastaProblem
  test_const_reference_unresolved_prefix0() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_reference_unresolved_prefix0();
  }

  @failingTest
  @fastaProblem
  test_const_reference_unresolved_prefix1() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_reference_unresolved_prefix1();
  }

  @failingTest
  @fastaProblem
  test_const_reference_unresolved_prefix2() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_reference_unresolved_prefix2();
  }

  @failingTest
  @fastaProblem
  test_const_topLevel_super() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_topLevel_super();
  }

  @failingTest
  @fastaProblem
  test_const_topLevel_this() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_const_topLevel_this();
  }

  @failingTest
  @fastaProblem
  test_constructor_initializers_field_notConst() async {
    // Fasta generates additional `#errors` top-level variable.
    await super.test_constructor_initializers_field_notConst();
  }

  @failingTest
  @fastaProblem
  test_constructor_redirected_factory_named_generic() async {
    // https://github.com/dart-lang/sdk/issues/30258
    await super.test_constructor_redirected_factory_named_generic();
  }

  @failingTest
  @fastaProblem
  test_constructor_redirected_factory_named_imported_generic() async {
    // https://github.com/dart-lang/sdk/issues/30258
    await super.test_constructor_redirected_factory_named_imported_generic();
  }

  @failingTest
  @fastaProblem
  test_constructor_redirected_factory_named_prefixed_generic() async {
    // https://github.com/dart-lang/sdk/issues/30258
    await super.test_constructor_redirected_factory_named_prefixed_generic();
  }

  @failingTest
  @fastaProblem
  test_constructor_redirected_factory_unnamed_generic() async {
    // https://github.com/dart-lang/sdk/issues/30258
    await super.test_constructor_redirected_factory_unnamed_generic();
  }

  @failingTest
  @fastaProblem
  test_constructor_redirected_factory_unnamed_imported_generic() async {
    // https://github.com/dart-lang/sdk/issues/30258
    await super.test_constructor_redirected_factory_unnamed_imported_generic();
  }

  @failingTest
  @fastaProblem
  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    // https://github.com/dart-lang/sdk/issues/30258
    await super.test_constructor_redirected_factory_unnamed_prefixed_generic();
  }

  @failingTest
  test_error_extendsEnum() async {
    await super.test_error_extendsEnum();
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
  test_exportImport_configurations_useDefault() async {
    await super.test_exportImport_configurations_useDefault();
  }

  @failingTest
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
  }

  @failingTest
  test_genericFunction_asGenericFunctionReturnType() async {
    await super.test_genericFunction_asGenericFunctionReturnType();
  }

  @failingTest
  test_genericFunction_asParameterType() async {
    await super.test_genericFunction_asParameterType();
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
  test_import_invalidUri_metadata() async {
    await super.test_import_invalidUri_metadata();
  }

  @failingTest
  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    await super
        .test_inferred_type_refers_to_function_typed_parameter_type_generic_class();
  }

  @failingTest
  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    await super
        .test_inferred_type_refers_to_method_function_typed_parameter_type();
  }

  @failingTest
  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    await super
        .test_inferred_type_refers_to_setter_function_typed_parameter_type();
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
  @fastaProblem
  test_invalid_annotation_prefixed_constructor() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_invalid_annotation_prefixed_constructor();
  }

  @failingTest
  @fastaProblem
  test_invalid_annotation_unprefixed_constructor() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_invalid_annotation_unprefixed_constructor();
  }

  @failingTest
  test_invalid_importPrefix_asTypeArgument() async {
    await super.test_invalid_importPrefix_asTypeArgument();
  }

  @failingTest
  @fastaProblem
  test_invalid_nameConflict_imported() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_invalid_nameConflict_imported();
  }

  @failingTest
  @fastaProblem
  test_invalid_nameConflict_imported_exported() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_invalid_nameConflict_imported_exported();
  }

  @failingTest
  @fastaProblem
  test_invalid_nameConflict_local() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_invalid_nameConflict_local();
  }

  @failingTest
  @fastaProblem
  test_invalid_setterParameter_fieldFormalParameter() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_invalid_setterParameter_fieldFormalParameter();
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
  test_metadata_classTypeAlias() async {
    await super.test_metadata_classTypeAlias();
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
  test_metadata_fieldFormalParameter() async {
    await super.test_metadata_fieldFormalParameter();
  }

  @failingTest
  test_metadata_fieldFormalParameter_withDefault() async {
    await super.test_metadata_fieldFormalParameter_withDefault();
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
  @fastaProblem
  test_metadata_invalid_classDeclaration() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_metadata_invalid_classDeclaration();
  }

  @failingTest
  test_metadata_libraryDirective() async {
    await super.test_metadata_libraryDirective();
  }

  @failingTest
  test_metadata_partDirective() async {
    await super.test_metadata_partDirective();
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
  test_parameter_checked() async {
    await super.test_parameter_checked();
  }

  @failingTest
  test_parameter_checked_inherited() async {
    await super.test_parameter_checked_inherited();
  }

  @failingTest
  test_parameter_covariant_inherited() async {
    await super.test_parameter_covariant_inherited();
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
  test_syntheticFunctionType_genericClosure() async {
    await super.test_syntheticFunctionType_genericClosure();
  }

  @failingTest
  test_syntheticFunctionType_inGenericClass() async {
    await super.test_syntheticFunctionType_inGenericClass();
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
  test_typedef_parameters_named() async {
    await super.test_typedef_parameters_named();
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
  @fastaProblem
  test_unresolved_annotation_instanceCreation_argument_super() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_instanceCreation_argument_super();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_instanceCreation_argument_this() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_instanceCreation_argument_this();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_namedConstructorCall_noClass() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_namedConstructorCall_noClass();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_namedConstructorCall_noConstructor();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_prefixedIdentifier_badPrefix();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_prefixedIdentifier_noDeclaration();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super
        .test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super
        .test_unresolved_annotation_prefixedNamedConstructorCall_noClass();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    await super
        .test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super
        .test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super
        .test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_simpleIdentifier() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_simpleIdentifier();
  }

  @failingTest
  @fastaProblem
  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    // https://github.com/dart-lang/sdk/issues/30267
    await super.test_unresolved_annotation_unnamedConstructorCall_noClass();
  }

  @failingTest
  test_unresolved_import() async {
    await super.test_unresolved_import();
  }

  String _getLibraryText(kernel.Library library) {
    StringBuffer buffer = new StringBuffer();
    new kernel.Printer(buffer, syntheticNames: new kernel.NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
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
