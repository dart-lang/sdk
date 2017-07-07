// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/fasta.dart' show ByteSink;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/kernel.dart' show Program, Library, CanonicalName;

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProcessedOptionsTest);
  });
}

@reflectiveTest
class ProcessedOptionsTest {
  final fileSystem = new MemoryFileSystem(Uri.parse('file:///'));

  Program _mockOutline;

  Program get mockSummary => _mockOutline ??=
      new Program(libraries: [new Library(Uri.parse('file:///a/b.dart'))]);

  test_compileSdk_false() {
    for (var value in [false, true]) {
      var raw = new CompilerOptions()..compileSdk = value;
      var processed = new ProcessedOptions(raw);
      expect(processed.compileSdk, value);
    }
  }

  test_sdk_summary_inferred() {
    // The sdk-summary is inferred by default form sdk-root, when compile-sdk is
    // false
    var raw = new CompilerOptions()
      ..sdkRoot = Uri.parse('file:///sdk/dir/')
      ..compileSdk = false;
    expect(new ProcessedOptions(raw).sdkSummary,
        Uri.parse('file:///sdk/dir/outline.dill'));

    // But it is left null when compile-sdk is true
    raw = new CompilerOptions()
      ..sdkRoot = Uri.parse('file:///sdk/dir/')
      ..compileSdk = true;
    expect(new ProcessedOptions(raw).sdkSummary, null);
  }

  test_fileSystem_noBazelRoots() {
    // When no bazel roots are specified, the filesystem should be passed
    // through unmodified.
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(raw);
    expect(processed.fileSystem, same(fileSystem));
  }

  test_getSdkSummary_summaryLocationProvided() async {
    var uri = Uri.parse('file:///sdkSummary');
    writeMockSummaryTo(uri);
    checkMockSummary(new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkSummary = uri);
  }

  void writeMockSummaryTo(Uri uri) {
    var sink = new ByteSink();
    new BinaryPrinter(sink).writeProgramFile(mockSummary);
    fileSystem.entityForUri(uri).writeAsBytesSync(sink.builder.takeBytes());
  }

  Future<Null> checkMockSummary(CompilerOptions raw) async {
    var processed = new ProcessedOptions(raw);
    var sdkSummary = await processed.loadSdkSummary(new CanonicalName.root());
    expect(sdkSummary.libraries.single.importUri,
        mockSummary.libraries.single.importUri);
  }

  test_getUriTranslator_explicitPackagesFile() async {
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('file:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('file:///explicit.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('file:///explicit.packages');
    var processed = new ProcessedOptions(raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.packages, {'foo': Uri.parse('file:///baz/')});
  }

  test_getUriTranslator_explicitPackagesFile_withBaseLocation() async {
    // This .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('file:///.packages'))
        .writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForUri(Uri.parse('file:///base/location/explicit.packages'))
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = Uri.parse('file:///base/location/explicit.packages');
    var processed = new ProcessedOptions(raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.packages,
        {'foo': Uri.parse('file:///base/location/baz/')});
  }

  test_getUriTranslator_noPackages() async {
    // .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('file:///.packages'))
        .writeAsStringSync('foo:bar\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = new Uri();
    var processed = new ProcessedOptions(raw);
    var uriTranslator = await processed.getUriTranslator();
    expect(uriTranslator.packages, isEmpty);
  }

  test_validateOptions_root_exists() async {
    var sdkRoot = Uri.parse('file:///sdk/root/');
    fileSystem
        // Note: this test is a bit hackish because the memory file system
        // doesn't have the notion of directories.
        .entityForUri(sdkRoot)
        .writeAsStringSync('\n');
    fileSystem
        .entityForUri(sdkRoot.resolve('outline.dill'))
        .writeAsStringSync('\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onError = (e) => errors.add(e);
    var options = new ProcessedOptions(raw);
    var result = await options.validateOptions();
    // Note: we check this first so test failures show the cause directly.
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_root_doesnt_exists() async {
    var sdkRoot = Uri.parse('file:///sdk/root');
    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onError = (e) => errors.add(e);
    var options = new ProcessedOptions(raw);
    expect(await options.validateOptions(), isFalse);
    expect('${errors.first}', contains("SDK root directory not found"));
  }

  test_validateOptions_summary_exists() async {
    var sdkSummary = Uri.parse('file:///sdk/root/outline.dill');
    fileSystem.entityForUri(sdkSummary).writeAsStringSync('\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onError = (e) => errors.add(e);
    var options = new ProcessedOptions(raw);
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_summary_doesnt_exists() async {
    var sdkSummary = Uri.parse('file:///sdk/root/outline.dill');
    var errors = [];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onError = (e) => errors.add(e);
    var options = new ProcessedOptions(raw);
    expect(await options.validateOptions(), isFalse);
    expect('${errors.first}', contains("SDK summary not found"));
  }

  test_validateOptions_inferred_summary_exists() async {
    var sdkRoot = Uri.parse('file:///sdk/root/');
    var sdkSummary = Uri.parse('file:///sdk/root/outline.dill');
    fileSystem.entityForUri(sdkRoot).writeAsStringSync('\n');
    fileSystem.entityForUri(sdkSummary).writeAsStringSync('\n');

    var errors = [];
    var raw = new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..fileSystem = fileSystem
      ..onError = (e) => errors.add(e);
    var options = new ProcessedOptions(raw);
    var result = await options.validateOptions();
    expect(errors, isEmpty);
    expect(result, isTrue);
  }

  test_validateOptions_inferred_summary_doesnt_exists() async {
    var sdkRoot = Uri.parse('file:///sdk/root/');
    var sdkSummary = Uri.parse('file:///sdk/root/outline.dill');
    fileSystem.entityForUri(sdkRoot).writeAsStringSync('\n');
    var errors = [];
    var raw = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..fileSystem = fileSystem
      ..onError = (e) => errors.add(e);
    var options = new ProcessedOptions(raw);
    expect(await options.validateOptions(), isFalse);
    expect('${errors.first}', contains("SDK summary not found"));
  }
}
