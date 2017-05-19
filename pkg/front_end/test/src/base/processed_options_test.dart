// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/fasta.dart' show ByteSink;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/kernel.dart' show Program, Library;

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
    var sdkSummary = await processed.sdkSummaryProgram;
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
}
