// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/util/bytes_sink.dart' show BytesSink;
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/kernel.dart'
    show
        CanonicalName,
        Library,
        Component,
        loadComponentFromBytes,
        NonNullableByDefaultCompiledMode;
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  CompilerContext.runWithDefaultOptions((_) {
    defineReflectiveSuite(() {
      defineReflectiveTests(ProcessedOptionsTest);
    });
    return Future<void>.value();
  });
}

@reflectiveTest
class ProcessedOptionsTest {
  MemoryFileSystem fileSystem =
      new MemoryFileSystem(Uri.parse('org-dartlang-test:///'));

  Component _mockOutline;

  Component get mockSummary => _mockOutline ??= new Component(
      libraries: [new Library(Uri.parse('org-dartlang-test:///a/b.dart'))])
    ..setMainMethodAndMode(null, false, NonNullableByDefaultCompiledMode.Weak);

  test_compileSdk_false() {
    for (var value in [false, true]) {
      var raw = new CompilerOptions()..compileSdk = value;
      var processed = new ProcessedOptions(options: raw);
      expect(processed.compileSdk, value);
    }
  }

  test_sdk_summary_inferred() {
    // The sdk-summary is inferred by default form sdk-root, when compile-sdk is
    // false
    var raw = new CompilerOptions()
      ..sdkRoot = Uri.parse('org-dartlang-test:///sdk/dir/')
      ..compileSdk = false;
    expect(new ProcessedOptions(options: raw).sdkSummary,
        Uri.parse('org-dartlang-test:///sdk/dir/vm_platform_strong.dill'));

    // But it is left null when compile-sdk is true
    raw = new CompilerOptions()
      ..sdkRoot = Uri.parse('org-dartlang-test:///sdk/dir/')
      ..compileSdk = true;
    expect(new ProcessedOptions(options: raw).sdkSummary, null);
  }

  test_fileSystem_noBazelRoots() {
    // When no bazel roots are specified, the filesystem should be passed
    // through unmodified.
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(options: raw);
    expect(processed.fileSystem, same(fileSystem));
  }

  test_getSdkSummaryBytes_summaryLocationProvided() async {
    var uri = Uri.parse('org-dartlang-test:///sdkSummary');

    writeMockSummaryTo(uri);

    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkSummary = uri;
    var processed = new ProcessedOptions(options: raw);

    var bytes = await processed.loadSdkSummaryBytes();
    expect(bytes, isNotEmpty);

    var sdkSummary = loadComponentFromBytes(bytes);
    expect(sdkSummary.libraries.single.importUri,
        mockSummary.libraries.single.importUri);
  }

  test_getSdkSummary_summaryLocationProvided() async {
    var uri = Uri.parse('org-dartlang-test:///sdkSummary');
    writeMockSummaryTo(uri);
    await checkMockSummary(new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkSummary = uri);
  }

  void writeMockSummaryTo(Uri uri) {
    var sink = new BytesSink();
    new BinaryPrinter(sink).writeComponentFile(mockSummary);
    fileSystem.entityForUri(uri).writeAsBytesSync(sink.builder.takeBytes());
  }

  Future<Null> checkMockSummary(CompilerOptions raw) async {
    var processed = new ProcessedOptions(options: raw);
    var sdkSummary = await processed.loadSdkSummary(new CanonicalName.root());
    expect(sdkSummary.libraries.single.importUri,
        mockSummary.libraries.single.importUri);
  }

  test_getUriTranslator_explicitLibrariesSpec() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///libraries.json'))
        .writeAsStringSync('{"none":{"libraries":{"foo":{"uri":"bar.dart"}}}}');
    var raw = new CompilerOptions()
      ..packagesFileUri = Uri.parse('org-dartlang-test:///.packages')
      ..fileSystem = fileSystem
      ..librariesSpecificationUri =
          Uri.parse('org-dartlang-test:///libraries.json');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.dartLibraries.libraryInfoFor('foo').uri.path,
        '/bar.dart');
  }

  test_getUriTranslator_inferredLibrariesSpec() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('');
    fileSystem
        .entityForUri(
            Uri.parse('org-dartlang-test:///mysdk/lib/libraries.json'))
        .writeAsStringSync('{"none":{"libraries":{"foo":{"uri":"bar.dart"}}}}');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('org-dartlang-test:///.packages')
      ..compileSdk = true
      ..sdkRoot = Uri.parse('org-dartlang-test:///mysdk/');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.dartLibraries.libraryInfoFor('foo').uri.path,
        '/mysdk/lib/bar.dart');
  }

  test_getUriTranslator_notInferredLibrariesSpec() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('');
    fileSystem
        .entityForUri(
            Uri.parse('org-dartlang-test:///mysdk/lib/libraries.json'))
        .writeAsStringSync('{"none":{"libraries":{"foo":{"uri":"bar.dart"}}}}');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('org-dartlang-test:///.packages')
      ..compileSdk = false // libraries.json is only inferred if true
      ..sdkRoot = Uri.parse('org-dartlang-test:///mysdk/');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.dartLibraries.libraryInfoFor('foo'), isNull);
  }

  checkPackageExpansion(
      String packageName, String packageDir, PackageConfig packages) {
    var input = Uri.parse('package:$packageName/a.dart');
    var expected = Uri.parse('org-dartlang-test:///$packageDir/a.dart');
    expect(packages.resolve(input), expected);
  }

  test_getUriTranslator_explicitPackagesFile() async {
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///explicit.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('org-dartlang-test:///explicit.packages');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'baz', uriTranslator.packages);
  }

  test_getUriTranslator_explicitPackagesFile_withBaseLocation() async {
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(
            Uri.parse('org-dartlang-test:///base/location/explicit.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri =
          Uri.parse('org-dartlang-test:///base/location/explicit.packages');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/location/baz', uriTranslator.packages);
  }

  test_getUriTranslator_implicitPackagesFile_ambiguous() async {
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///explicit.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('org-dartlang-test:///explicit.packages');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'baz', uriTranslator.packages);
  }

  test_getUriTranslator_implicitPackagesFile_nextToScript() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();
    // Packages directory should be ignored (.packages file takes precedence).
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/packages/'))
        .createDirectory();
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(
        options: raw,
        inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')]);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/location/baz', uriTranslator.packages);
  }

  test_getUriTranslator_implicitPackagesFile_searchAbove() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(
        options: raw,
        inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')]);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/baz', uriTranslator.packages);
  }

  test_getUriTranslator_implicitPackagesFile_packagesDirectory() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();

    // packages/ directory is deprecated and should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/packages/'))
        .createDirectory();

    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(
        options: raw,
        inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')]);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/baz', uriTranslator.packages);
  }

  test_getUriTranslator_implicitPackagesFile_noPackages() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();
    var errors = [];
    // .packages file should be ignored.
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var processed = new ProcessedOptions(
        options: raw,
        inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')]);
    var uriTranslator = await processed.getUriTranslator();
    expect(errors, isEmpty);
    expect(uriTranslator.packages.packages, isEmpty);
  }

  test_getUriTranslator_noPackages() async {
    var errors = [];
    // .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:bar\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = new Uri()
      ..onDiagnostic = errors.add;
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.packages.packages, isEmpty);
    expect(errors.single.message,
        startsWith(_stringPrefixOf(templateCantReadFile)));
  }

  test_validateOptions_noInputs() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var errors = [];
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(options: raw);
    var result = await options.validateOptions();
    expect(errors.single.message, messageMissingInput.message);
    expect(result, isFalse);
  }

  test_validateOptions_input_doesnt_exist() async {
    var errors = [];
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_root_exists() async {
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root/');
    fileSystem
        // Note: this test is a bit hackish because the memory file system
        // doesn't have the notion of directories.
        .entityForUri(sdkRoot)
        .writeAsStringSync('\n');
    fileSystem
        .entityForUri(sdkRoot.resolve('vm_platform_strong.dill'))
        .writeAsStringSync('\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    var result = await options.validateOptions();
    // Note: we check this first so test failures show the cause directly.
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_root_doesnt_exists() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root');
    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    expect(await options.validateOptions(), isFalse);
    expect(errors.first.message,
        startsWith(_stringPrefixOf(templateSdkRootNotFound)));
  }

  test_validateOptions_summary_exists() async {
    var sdkSummary = Uri.parse('org-dartlang-test:///sdk/root/outline.dill');
    fileSystem.entityForUri(sdkSummary).writeAsStringSync('\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_summary_doesnt_exists() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var sdkSummary = Uri.parse('org-dartlang-test:///sdk/root/outline.dill');
    var errors = [];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    expect(await options.validateOptions(), isFalse);
    expect(errors.single.message,
        startsWith(_stringPrefixOf(templateSdkSummaryNotFound)));
  }

  test_validateOptions_inferred_summary_exists() async {
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root/');
    var sdkSummary =
        Uri.parse('org-dartlang-test:///sdk/root/vm_platform_strong.dill');
    fileSystem.entityForUri(sdkRoot).writeAsStringSync('\n');
    fileSystem.entityForUri(sdkSummary).writeAsStringSync('\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_inferred_summary_doesnt_exists() async {
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root/');
    var sdkSummary = Uri.parse('org-dartlang-test:///sdk/root/outline.dill');
    fileSystem.entityForUri(sdkRoot).writeAsStringSync('\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var errors = [];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options =
        new ProcessedOptions(options: raw, inputs: [Uri.parse('foo.dart')]);
    expect(await options.validateOptions(), isFalse);
    expect(errors.single.message,
        startsWith(_stringPrefixOf(templateSdkSummaryNotFound)));
  }

  /// Returns the longest prefix of the text in a message template that doesn't
  /// mention a template argument.
  _stringPrefixOf(Template template) {
    var messageTemplate = template.messageTemplate;
    var index = messageTemplate.indexOf('#');
    var prefix = messageTemplate.substring(0, index - 1);

    // Check that the prefix is not empty and that it contains more than one
    // word.
    expect(prefix.length > 0, isTrue);
    expect(prefix.contains(' '), isTrue);
    return prefix;
  }
}
