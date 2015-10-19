// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.testing;

import 'dart:mirrors';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:path/path.dart' as path;

import 'package:dev_compiler/src/analysis_context.dart';

import 'package:dev_compiler/src/server/dependency_graph.dart'
    show runtimeFilesForServerMode;
import 'package:dev_compiler/src/options.dart';

/// Shared analysis context used for compilation.
final AnalysisContext realSdkContext = () {
  var context = createAnalysisContextWithSources(new SourceResolverOptions(
      dartSdkPath: getSdkDir().path,
      customUrlMappings: {
        'package:expect/expect.dart': _testCodegenPath('expect.dart'),
        'package:async_helper/async_helper.dart':
            _testCodegenPath('async_helper.dart'),
        'package:unittest/unittest.dart': _testCodegenPath('unittest.dart'),
        'package:dom/dom.dart': _testCodegenPath('sunflower', 'dom.dart')
      }));
  (context.analysisOptions as AnalysisOptionsImpl).cacheSize = 512;
  return context;
}();

String _testCodegenPath(String p1, [String p2]) =>
    path.join(testDirectory, 'codegen', p1, p2);

final String testDirectory =
    path.dirname((reflectClass(_TestUtils).owner as LibraryMirror).uri.path);

class _TestUtils {}

/// Creates a [MemoryResourceProvider] with test data
MemoryResourceProvider createTestResourceProvider(
    Map<String, String> testFiles) {
  var provider = new MemoryResourceProvider();
  runtimeFilesForServerMode.forEach((filepath) {
    testFiles['/dev_compiler_runtime/$filepath'] =
        '/* test contents of $filepath */';
  });
  testFiles.forEach((key, value) {
    var scheme = 'package:';
    if (key.startsWith(scheme)) {
      key = '/packages/${key.substring(scheme.length)}';
    }
    provider.newFile(key, value);
  });
  return provider;
}

class TestUriResolver extends ResourceUriResolver {
  final MemoryResourceProvider provider;
  TestUriResolver(provider)
      : provider = provider,
        super(provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.scheme == 'package') {
      return (provider.getResource('/packages/' + uri.path) as File)
          .createSource(uri);
    }
    return super.resolveAbsolute(uri, actualUri);
  }
}
