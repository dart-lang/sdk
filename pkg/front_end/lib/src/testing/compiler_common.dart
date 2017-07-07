// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common compiler options and helper functions used for testing.
library front_end.testing.compiler_options_common;

import 'dart:async';

import 'package:front_end/front_end.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/fasta/testing/patched_sdk_location.dart';
import 'package:front_end/src/testing/hybrid_file_system.dart';
import 'package:kernel/ast.dart';

/// Generate kernel for a script.
///
/// [scriptOrSources] can be a String, in which case it is the script to be
/// compiled, or a Map containing source files. In which case, this function
/// compiles the entry whose name is [fileName].
///
/// Wraps [kernelForProgram] with some default testing options (see [setup]).
Future<Program> compileScript(dynamic scriptOrSources,
    {fileName: 'main.dart',
    List<String> inputSummaries: const [],
    List<String> linkedDependencies: const [],
    CompilerOptions options}) async {
  options ??= new CompilerOptions();
  Map<String, dynamic> sources;
  if (scriptOrSources is String) {
    sources = {fileName: scriptOrSources};
  } else {
    assert(scriptOrSources is Map);
    sources = scriptOrSources;
  }
  await setup(options, sources,
      inputSummaries: inputSummaries, linkedDependencies: linkedDependencies);
  return await kernelForProgram(toTestUri(fileName), options);
}

/// Generate a program for a modular complation unit.
///
/// Wraps [kernelForBuildUnit] with some default testing options (see [setup]).
Future<Program> compileUnit(List<String> inputs, Map<String, dynamic> sources,
    {List<String> inputSummaries: const [],
    List<String> linkedDependencies: const [],
    CompilerOptions options}) async {
  options ??= new CompilerOptions();
  await setup(options, sources,
      inputSummaries: inputSummaries, linkedDependencies: linkedDependencies);
  return await kernelForBuildUnit(inputs.map(toTestUri).toList(), options);
}

/// Generate a summary for a modular complation unit.
///
/// Wraps [summaryFor] with some default testing options (see [setup]).
Future<List<int>> summarize(List<String> inputs, Map<String, dynamic> sources,
    {List<String> inputSummaries: const [], CompilerOptions options}) async {
  options ??= new CompilerOptions();
  await setup(options, sources, inputSummaries: inputSummaries);
  return await summaryFor(inputs.map(toTestUri).toList(), options);
}

/// Defines a default set of options for testing:
///
///   * create a hybrid file system that stores [sources] in memory but allows
///   access to the physical file system to load the SDK. [sources] can
///   contain either source files (value is [String]) or .dill files (value
///   is [List<int>]).
///
///   * define an empty .packages file
///
///   * specify the location of the sdk and sdk summaries based on
///     the path where the `patched_sdk` is generated in the sdk-repo.
Future<Null> setup(CompilerOptions options, Map<String, dynamic> sources,
    {List<String> inputSummaries: const [],
    List<String> linkedDependencies: const []}) async {
  var fs = new MemoryFileSystem(_defaultDir);
  sources.forEach((name, data) {
    var entity = fs.entityForUri(toTestUri(name));
    if (data is String) {
      entity.writeAsStringSync(data);
    } else {
      entity.writeAsBytesSync(data);
    }
  });
  fs.entityForUri(toTestUri('.packages')).writeAsStringSync('');
  options
    ..verify = true
    ..fileSystem = new HybridFileSystem(fs)
    ..inputSummaries = inputSummaries.map(toTestUri).toList()
    ..linkedDependencies = linkedDependencies.map(toTestUri).toList()
    ..packagesFileUri = toTestUri('.packages');

  if (options.sdkSummary == null) {
    options.sdkRoot = await computePatchedSdk();
  }
}

/// A fake absolute directory used as the root of a memory-file system in the
/// helpers above.
Uri _defaultDir = Uri.parse('file:///a/b/c/');

/// Convert relative file paths into an absolute Uri as expected by the test
/// helpers above.
Uri toTestUri(String relativePath) => _defaultDir.resolve(relativePath);

/// A map defining the location of core libraries that purposely provides
/// invalid Uris. Used by tests that want to ensure that the sdk libraries are
/// not loaded from sources, but read from a .dill file.
Map<String, Uri> invalidCoreLibs = {
  'core': Uri.parse('file:///non_existing_file/core.dart'),
  'async': Uri.parse('file:///non_existing_file/async.dart'),
};

bool isDartCoreLibrary(Library lib) => isDartCore(lib.importUri);
bool isDartCore(Uri uri) => uri.scheme == 'dart' && uri.path == 'core';

/// Find a library in [program] whose Uri ends with the given [suffix]
Library findLibrary(Program program, String suffix) {
  return program.libraries
      .firstWhere((lib) => lib.importUri.path.endsWith(suffix));
}
