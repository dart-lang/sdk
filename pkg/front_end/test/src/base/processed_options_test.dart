// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/summary/format.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProcessedOptionsTest);
  });
}

@reflectiveTest
class ProcessedOptionsTest {
  final fileSystem = new MemoryFileSystem(pathos.posix, Uri.parse('file:///'));

  PackageBundleBuilder _mockSdkSummary;

  PackageBundleBuilder get mockSdkSummary => _mockSdkSummary ??=
      new PackageBundleBuilder(apiSignature: 'mock summary signature');

  Future<Null> checkMockSummary(CompilerOptions raw) async {
    var processed = new ProcessedOptions(raw);
    var sdkSummary = await processed.getSdkSummary();
    expect(sdkSummary.apiSignature, mockSdkSummary.apiSignature);
  }

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

  test_getSdkSummary_sdkLocationProvided_noTrailingSlash() async {
    var uri = Uri.parse('file:///sdk');
    writeMockSummaryTo(Uri.parse('$uri/lib/_internal/strong.sum'));
    checkMockSummary(new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkRoot = uri);
  }

  test_getSdkSummary_sdkLocationProvided_spec() async {
    var uri = Uri.parse('file:///sdk');
    writeMockSummaryTo(Uri.parse('$uri/lib/_internal/spec.sum'));
    checkMockSummary(new CompilerOptions()
      ..fileSystem = fileSystem
      ..strongMode = false
      ..sdkRoot = uri);
  }

  test_getSdkSummary_sdkLocationProvided_trailingSlash() async {
    var uri = Uri.parse('file:///sdk');
    writeMockSummaryTo(Uri.parse('$uri/lib/_internal/strong.sum'));
    checkMockSummary(new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkRoot = Uri.parse('$uri/'));
  }

  test_getSdkSummary_summaryLocationProvided() async {
    var uri = Uri.parse('file:///sdkSummary');
    writeMockSummaryTo(uri);
    checkMockSummary(new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkSummary = uri);
  }

  test_getUriResolver_explicitPackagesFile() async {
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
    var uriResolver = await processed.getUriResolver();
    expect(uriResolver.packages, {'foo': Uri.parse('file:///baz/')});
  }

  test_getUriResolver_explicitPackagesFile_withBaseLocation() async {
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
    var uriResolver = await processed.getUriResolver();
    expect(
        uriResolver.packages, {'foo': Uri.parse('file:///base/location/baz/')});
  }

  test_getUriResolver_noPackages() async {
    // .packages file should be ignored.
    fileSystem
        .entityForUri(Uri.parse('file:///.packages'))
        .writeAsStringSync('foo:bar\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFileUri = new Uri();
    var processed = new ProcessedOptions(raw);
    var uriResolver = await processed.getUriResolver();
    expect(uriResolver.packages, isEmpty);
  }

  void writeMockSummaryTo(Uri uri) {
    fileSystem.entityForUri(uri).writeAsBytesSync(mockSdkSummary.toBuffer());
  }
}
