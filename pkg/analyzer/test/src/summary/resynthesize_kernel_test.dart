// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_kernel_test;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/kernel_metadata.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:front_end/byte_store.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/libraries_specification.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart' as kernel;
import 'package:kernel/type_environment.dart' as kernel;
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;
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

    KernelResynthesizer resynthesizer = await _createResynthesizer(testUri);
    return resynthesizer.getLibrary(testUriStr);
  }

  @override
  AnalysisOptionsImpl createOptions() =>
      super.createOptions()..strongMode = true;

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_class_constructor_field_formal_multiple_matching_fields() async {
    await super.test_class_constructor_field_formal_multiple_matching_fields();
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

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30266')
  test_const_invalid_intLiteral() async {
    await super.test_const_invalid_intLiteral();
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

  @failingTest
  @notForDart2
  test_export_configurations_useDefault() async {
    await super.test_export_configurations_useDefault();
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
  test_exportImport_configurations_useDefault() async {
    await super.test_exportImport_configurations_useDefault();
  }

  @failingTest
  @notForDart2
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
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
  test_import_configurations_useDefault() async {
    await super.test_import_configurations_useDefault();
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

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30724')
  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    await super.test_instantiateToBounds_boundRefersToEarlierTypeArgument();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30724')
  test_instantiateToBounds_boundRefersToItself() async {
    await super.test_instantiateToBounds_boundRefersToItself();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30724')
  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    await super.test_instantiateToBounds_boundRefersToLaterTypeArgument();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30724')
  test_instantiateToBounds_simple() async {
    await super.test_instantiateToBounds_simple();
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
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_setterParameter_fieldFormalParameter() async {
    await super.test_invalid_setterParameter_fieldFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30725')
  test_invalidUri_part_emptyUri() async {
    await super.test_invalidUri_part_emptyUri();
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

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30725')
  test_parts_invalidUri_nullStringValue() async {
    await super.test_parts_invalidUri_nullStringValue();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31213')
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
  test_unresolved_annotation_simpleIdentifier() {
    return super.test_unresolved_annotation_simpleIdentifier();
  }

  Future<KernelResynthesizer> _createResynthesizer(Uri testUri) async {
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
    var driver = new KernelDriver(options, uriTranslator,
        metadataFactory: new AnalyzerMetadataFactory());

    KernelResult kernelResult = await driver.getKernel(testUri);

    var libraryMap = <String, kernel.Library>{};
    var libraryExistMap = <String, bool>{};

    void addLibrary(kernel.Library library) {
      String uriStr = library.importUri.toString();
      libraryMap[uriStr] = library;
      libraryExistMap[uriStr] = true;
    }

    kernelResult.dependencies.forEach(addLibrary);
    addLibrary(kernelResult.library);

    if (DEBUG) {
      String testUriStr = testUri.toString();
      var library = libraryMap[testUriStr];
      print(_getLibraryText(library));
    }

    var resynthesizer = new KernelResynthesizer(
        context, kernelResult.types, libraryMap, libraryExistMap);
    return resynthesizer;
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
