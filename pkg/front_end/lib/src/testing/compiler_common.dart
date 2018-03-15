// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common compiler options and helper functions used for testing.
library front_end.testing.compiler_options_common;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Library, Component;

import '../api_prototype/front_end.dart'
    show CompilerOptions, kernelForComponent, kernelForProgram, summaryFor;

import '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

import '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import '../testing/hybrid_file_system.dart' show HybridFileSystem;

/// Generate kernel for a script.
///
/// [scriptOrSources] can be a String, in which case it is the script to be
/// compiled, or a Map containing source files. In which case, this function
/// compiles the entry whose name is [fileName].
///
/// Wraps [kernelForProgram] with some default testing options (see [setup]).
Future<Component> compileScript(dynamic scriptOrSources,
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

/// Generate a component for a modular complation unit.
///
/// Wraps [kernelForComponent] with some default testing options (see [setup]).
Future<Component> compileUnit(List<String> inputs, Map<String, dynamic> sources,
    {List<String> inputSummaries: const [],
    List<String> linkedDependencies: const [],
    CompilerOptions options}) async {
  options ??= new CompilerOptions();
  await setup(options, sources,
      inputSummaries: inputSummaries, linkedDependencies: linkedDependencies);
  return await kernelForComponent(inputs.map(toTestUri).toList(), options);
}

/// Generate a summary for a modular complation unit.
///
/// Wraps [summaryFor] with some default testing options (see [setup]).
Future<List<int>> summarize(List<String> inputs, Map<String, dynamic> sources,
    {List<String> inputSummaries: const [],
    CompilerOptions options,
    bool truncate: false}) async {
  options ??= new CompilerOptions();
  await setup(options, sources, inputSummaries: inputSummaries);
  return await summaryFor(inputs.map(toTestUri).toList(), options,
      truncate: truncate);
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
///   * specify the location of the sdk summaries.
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
  fs
      .entityForUri(invalidCoreLibsSpecUri)
      .writeAsStringSync(_invalidLibrariesSpec);
  options
    ..verify = true
    ..fileSystem = new HybridFileSystem(fs)
    ..inputSummaries = inputSummaries.map(toTestUri).toList()
    ..linkedDependencies = linkedDependencies.map(toTestUri).toList()
    ..packagesFileUri = toTestUri('.packages');

  if (options.sdkSummary == null) {
    options.sdkRoot = computePlatformBinariesLocation();
  }
}

/// A fake absolute directory used as the root of a memory-file system in the
/// helpers above.
Uri _defaultDir = Uri.parse('org-dartlang-test:///a/b/c/');

/// Convert relative file paths into an absolute Uri as expected by the test
/// helpers above.
Uri toTestUri(String relativePath) => _defaultDir.resolve(relativePath);

/// Uri to a libraries specification file that purposely provides
/// invalid Uris to dart:core and dart:async. Used by tests that want to ensure
/// that the sdk libraries are not loaded from sources, but read from a .dill
/// file.
Uri invalidCoreLibsSpecUri = toTestUri('invalid_sdk_libraries.json');

String _invalidLibrariesSpec = '''
{
  "vm": {
    "libraries": {
      "core":  {"uri": "/non_existing_file/core.dart"},
      "async": {"uri": "/non_existing_file/async.dart"}
    }
  }
}
''';

bool isDartCoreLibrary(Library lib) => isDartCore(lib.importUri);
bool isDartCore(Uri uri) => uri.scheme == 'dart' && uri.path == 'core';

/// Find a library in [component] whose Uri ends with the given [suffix]
Library findLibrary(Component component, String suffix) {
  return component.libraries
      .firstWhere((lib) => lib.importUri.path.endsWith(suffix));
}
