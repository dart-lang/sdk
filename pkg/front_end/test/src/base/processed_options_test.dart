// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/codes/cfe_codes.dart';
import 'package:front_end/src/util/bytes_sink.dart' show BytesSink;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/kernel.dart'
    show CanonicalName, Library, Component, loadComponentFromBytes;
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

final String emptyPackageConfig = jsonEncode({
  "configVersion": 2,
  "packages": [],
});

final String fooBarPackageConfig = jsonEncode({
  "configVersion": 2,
  "packages": [
    {"name": "foo", "rootUri": "bar"},
  ],
});
final String fooBazPackageConfig = jsonEncode({
  "configVersion": 2,
  "packages": [
    {"name": "foo", "rootUri": "baz"},
  ],
});
final String fooBazDotDotPackageConfig = jsonEncode({
  "configVersion": 2,
  "packages": [
    {"name": "foo", "rootUri": "../baz"},
  ],
});

void main() {
  CompilerContext.runWithDefaultOptions((_) {
    defineReflectiveSuite(() {
      defineReflectiveTests(ProcessedOptionsTest);
    });
    return Future<void>.value();
  });
}

@reflectiveTest
class ProcessedOptionsTest {
  MemoryFileSystem fileSystem = new MemoryFileSystem(
    Uri.parse('org-dartlang-test:///'),
  );

  Component? _mockOutline;

  Component get mockSummary => _mockOutline ??= new Component(
    libraries: [
      new Library(
        Uri.parse('org-dartlang-test:///a/b.dart'),
        fileUri: Uri.parse('org-dartlang-test:///a/b.dart'),
      ),
    ],
  )..setMainMethodAndMode(null, false);

  void test_compileSdk_false() {
    for (var value in [false, true]) {
      var raw = new CompilerOptions()..compileSdk = value;
      var processed = new ProcessedOptions(options: raw);
      expect(processed.compileSdk, value);
    }
  }

  void test_sdk_summary_inferred() {
    // The sdk-summary is inferred by default form sdk-root, when compile-sdk is
    // false
    var raw = new CompilerOptions()
      ..sdkRoot = Uri.parse('org-dartlang-test:///sdk/dir/')
      ..compileSdk = false;
    expect(
      new ProcessedOptions(options: raw).sdkSummary,
      Uri.parse('org-dartlang-test:///sdk/dir/vm_platform.dill'),
    );

    // But it is left null when compile-sdk is true
    raw = new CompilerOptions()
      ..sdkRoot = Uri.parse('org-dartlang-test:///sdk/dir/')
      ..compileSdk = true;
    expect(new ProcessedOptions(options: raw).sdkSummary, null);
  }

  void test_fileSystem_noBazelRoots() {
    // When no bazel roots are specified, the filesystem should be passed
    // through unmodified.
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(options: raw);
    expect(processed.fileSystem, same(fileSystem));
  }

  Future<void> test_getSdkSummaryBytes_summaryLocationProvided() async {
    var uri = Uri.parse('org-dartlang-test:///sdkSummary');

    writeMockSummaryTo(uri);

    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkSummary = uri;
    var processed = new ProcessedOptions(options: raw);

    var bytes = (await processed.loadSdkSummaryBytes())!;
    expect(bytes, isNotEmpty);

    var sdkSummary = loadComponentFromBytes(bytes);
    expect(
      sdkSummary.libraries.single.importUri,
      mockSummary.libraries.single.importUri,
    );
  }

  Future<void> test_getSdkSummary_summaryLocationProvided() async {
    var uri = Uri.parse('org-dartlang-test:///sdkSummary');
    writeMockSummaryTo(uri);
    await checkMockSummary(
      new CompilerOptions()
        ..fileSystem = fileSystem
        ..sdkSummary = uri,
    );
  }

  void writeMockSummaryTo(Uri uri) {
    var sink = new BytesSink();
    new BinaryPrinter(sink).writeComponentFile(mockSummary);
    fileSystem.entityForUri(uri).writeAsBytesSync(sink.builder.takeBytes());
  }

  Future<Null> checkMockSummary(CompilerOptions raw) async {
    var processed = new ProcessedOptions(options: raw);
    var sdkSummary = (await processed.loadSdkSummary(
      new CanonicalName.root(),
    ))!;
    expect(
      sdkSummary.libraries.single.importUri,
      mockSummary.libraries.single.importUri,
    );
  }

  Future<void> test_getUriTranslator_explicitLibrariesSpec() async {
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(emptyPackageConfig);
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///libraries.json'))
        .writeAsStringSync('{"none":{"libraries":{"foo":{"uri":"bar.dart"}}}}');
    var raw = new CompilerOptions()
      ..packagesFileUri = Uri.parse(
        'org-dartlang-test:///.dart_tool/package_config.json',
      )
      ..fileSystem = fileSystem
      ..librariesSpecificationUri = Uri.parse(
        'org-dartlang-test:///libraries.json',
      );
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(
      uriTranslator.dartLibraries.libraryInfoFor('foo')!.uri.path,
      '/bar.dart',
    );
  }

  Future<void> test_getUriTranslator_inferredLibrariesSpec() async {
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(emptyPackageConfig);
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///mysdk/lib/libraries.json'),
        )
        .writeAsStringSync('{"none":{"libraries":{"foo":{"uri":"bar.dart"}}}}');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse(
        'org-dartlang-test:///.dart_tool/package_config.json',
      )
      ..compileSdk = true
      ..sdkRoot = Uri.parse('org-dartlang-test:///mysdk/');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(
      uriTranslator.dartLibraries.libraryInfoFor('foo')!.uri.path,
      '/mysdk/lib/bar.dart',
    );
  }

  Future<void> test_getUriTranslator_notInferredLibrariesSpec() async {
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(emptyPackageConfig);
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///mysdk/lib/libraries.json'),
        )
        .writeAsStringSync('{"none":{"libraries":{"foo":{"uri":"bar.dart"}}}}');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse(
        'org-dartlang-test:///.dart_tool/package_config.json',
      )
      ..compileSdk =
          false // libraries.json is only inferred if true
      ..sdkRoot = Uri.parse('org-dartlang-test:///mysdk/');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.dartLibraries.libraryInfoFor('foo'), isNull);
  }

  void checkPackageExpansion(
    String packageName,
    String packageDir,
    PackageConfig packages,
  ) {
    var input = Uri.parse('package:$packageName/a.dart');
    var expected = Uri.parse('org-dartlang-test:///$packageDir/a.dart');
    expect(packages.resolve(input), expected);
  }

  Future<void> test_getUriTranslator_explicitPackagesFile() async {
    // This .dart_tool/package_config.json file should be ignored.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///explicit.json'))
        .writeAsStringSync(fooBazPackageConfig);
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('org-dartlang-test:///explicit.json');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'baz', uriTranslator.packages);
  }

  Future<void>
  test_getUriTranslator_explicitPackagesFile_withBaseLocation() async {
    // This .dart_tool/package_config.json file should be ignored.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    // This one should be used.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///base/location/explicit.json'),
        )
        .writeAsStringSync(fooBazPackageConfig);
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse(
        'org-dartlang-test:///base/location/explicit.json',
      );
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/location/baz', uriTranslator.packages);
  }

  Future<void> test_getUriTranslator_implicitPackagesFile_ambiguous() async {
    // This .dart_tool/package_config.json file should be ignored.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///explicit.json'))
        .writeAsStringSync(fooBazPackageConfig);
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('org-dartlang-test:///explicit.json');
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'baz', uriTranslator.packages);
  }

  Future<void> test_getUriTranslator_implicitPackagesFile_nextToScript() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();
    // Packages directory should be ignored (.dart_tool/package_config.json is
    // the only one that will be automatically found).
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/packages/'))
        .createDirectory();
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync("foo:packages1");
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/.packages'))
        .writeAsStringSync("foo:packages2");
    // This .dart_tool/package_config.json file should be ignored.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    // This one should be used.
    fileSystem
        .entityForUri(
          Uri.parse(
            'org-dartlang-test:///base/location/.dart_tool/package_config.json',
          ),
        )
        .writeAsStringSync(fooBazDotDotPackageConfig);
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')],
    );
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/location/baz', uriTranslator.packages);
  }

  Future<void> test_getUriTranslator_implicitPackagesFile_searchAbove() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();
    // This .dart_tool/package_config.json file should be ignored.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    // This one should be used.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///base/.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBazDotDotPackageConfig);
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')],
    );
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/baz', uriTranslator.packages);
  }

  Future<void>
  test_getUriTranslator_implicitPackagesFile_packagesDirectory() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();

    // packages/ directory is deprecated and should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/packages/'))
        .createDirectory();

    // .packages is deprecated and should be ignored.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///.packages'))
        .writeAsStringSync('foo:packages1\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/.packages'))
        .writeAsStringSync('foo:packages2\n');

    // .dart_tool/package_config.json
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///base/.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBazDotDotPackageConfig);
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')],
    );
    var uriTranslator = await processed.getUriTranslator();
    checkPackageExpansion('foo', 'base/baz', uriTranslator.packages);
  }

  Future<void> test_getUriTranslator_implicitPackagesFile_noPackages() async {
    // Create the base directory.
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///base/location/'))
        .createDirectory();
    var errors = [];
    // There is no .dart_tool/package_config.json file.
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var processed = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('org-dartlang-test:///base/location/script.dart')],
    );
    var uriTranslator = await processed.getUriTranslator();
    expect(errors, isEmpty);
    expect(uriTranslator.packages.packages, isEmpty);
  }

  Future<void> test_getUriTranslator_noPackages() async {
    var errors = <CfeDiagnosticMessage>[];
    // .dart_tool/package_config.json file should be ignored when specifying
    // empty Uri.
    fileSystem
        .entityForUri(
          Uri.parse('org-dartlang-test:///.dart_tool/package_config.json'),
        )
        .writeAsStringSync(fooBarPackageConfig);
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = new Uri()
      ..onDiagnostic = errors.add;
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.packages.packages, isEmpty);
  }

  Future<void> test_getUriTranslator_missingPackages() async {
    var errors = <CfeDiagnosticMessage>[];
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = new Uri(path: '/')
      ..onDiagnostic = errors.add;
    var processed = new ProcessedOptions(options: raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.packages.packages, isEmpty);
    expect(
      (errors.single as FormattedMessage).locatedMessage.code,
      codeCantReadFile,
    );
  }

  Future<void> test_validateOptions_noInputs() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var errors = <CfeDiagnosticMessage>[];
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(options: raw);
    var result = await options.validateOptions();
    expect(
      (errors.single as FormattedMessage).problemMessage,
      codeMissingInput.problemMessage,
    );
    expect(result, isFalse);
  }

  Future<void> test_validateOptions_input_doesnt_exist() async {
    var errors = [];
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  Future<void> test_validateOptions_root_exists() async {
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root/');
    fileSystem
        // Note: this test is a bit hackish because the memory file system
        // doesn't have the notion of directories.
        .entityForUri(sdkRoot)
        .writeAsStringSync('\n');
    fileSystem
        .entityForUri(sdkRoot.resolve('vm_platform.dill'))
        .writeAsStringSync('\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    var result = await options.validateOptions();
    // Note: we check this first so test failures show the cause directly.
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  Future<void> test_validateOptions_root_doesnt_exists() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root');
    var errors = <CfeDiagnosticMessage>[];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    expect(await options.validateOptions(), isFalse);
    expect(
      (errors.first as FormattedMessage).locatedMessage.code,
      codeSdkRootNotFound,
    );
  }

  Future<void> test_validateOptions_summary_exists() async {
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
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  Future<void> test_validateOptions_summary_doesnt_exists() async {
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var sdkSummary = Uri.parse('org-dartlang-test:///sdk/root/outline.dill');
    var errors = <CfeDiagnosticMessage>[];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    expect(await options.validateOptions(), isFalse);
    expect(
      (errors.single as FormattedMessage).locatedMessage.code,
      codeSdkSummaryNotFound,
    );
  }

  Future<void> test_validateOptions_inferred_summary_exists() async {
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root/');
    var sdkSummary = Uri.parse(
      'org-dartlang-test:///sdk/root/vm_platform.dill',
    );
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
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  Future<void> test_validateOptions_inferred_summary_doesnt_exists() async {
    var sdkRoot = Uri.parse('org-dartlang-test:///sdk/root/');
    var sdkSummary = Uri.parse('org-dartlang-test:///sdk/root/outline.dill');
    fileSystem.entityForUri(sdkRoot).writeAsStringSync('\n');
    fileSystem
        .entityForUri(Uri.parse('org-dartlang-test:///foo.dart'))
        .writeAsStringSync('main(){}\n');
    var errors = <CfeDiagnosticMessage>[];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onDiagnostic = errors.add;
    var options = new ProcessedOptions(
      options: raw,
      inputs: [Uri.parse('foo.dart')],
    );
    expect(await options.validateOptions(), isFalse);
    expect(
      (errors.single as FormattedMessage).locatedMessage.code,
      codeSdkSummaryNotFound,
    );
  }
}
