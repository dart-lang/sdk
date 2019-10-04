// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@JS()
library dev_compiler.web.web_command;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:html' show HttpRequest;
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart' show ResourceUriResolver;
import 'package:analyzer/file_system/memory_file_system.dart'
    show MemoryResourceProvider;
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show SummaryDataStore;
import 'package:analyzer/src/dart/resolver/scope.dart' show Scope;

import 'package:args/command_runner.dart';

import 'package:dev_compiler/src/analyzer/context.dart' show AnalyzerOptions;
import 'package:dev_compiler/src/analyzer/command.dart';
import 'package:dev_compiler/src/analyzer/driver.dart';
import 'package:dev_compiler/src/analyzer/module_compiler.dart';

import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:js/js.dart';
import 'package:path/path.dart' as p;

typedef void MessageHandler(Object message);

@JS()
@anonymous
class JSIterator<V> {}

@JS('Map')
class JSMap<K, V> {
  external V get(K v);
  external set(K k, V v);
  external JSIterator<K> keys();
  external JSIterator<V> values();
  external int get size;
}

@JS('Array.from')
external List<V> iteratorToList<V>(JSIterator<V> iterator);

@JS()
@anonymous
class CompileResult {
  external factory CompileResult(
      {String code, List<String> errors, bool isValid});
}

typedef CompileModule(String imports, String body, String libraryName,
    String existingLibrary, String fileName);

/// The command for invoking the modular compiler.
class WebCompileCommand extends Command {
  @override
  get name => 'compile';

  @override
  get description => 'Compile a set of Dart files into a JavaScript module.';
  final MessageHandler messageHandler;

  WebCompileCommand({MessageHandler messageHandler})
      : this.messageHandler = messageHandler ?? print {
    ddcArgParser(argParser: argParser, help: false);
  }

  @override
  Function run() {
    return requestSummaries;
  }

  Future<Null> requestSummaries(String sdkUrl, JSMap<String, String> summaryMap,
      Function onCompileReady, Function onError, Function onProgress) async {
    var sdkRequest;
    var progress = 0;
    // Add 1 to the count for the SDK summary.
    var total = summaryMap.size + 1;
    // No need to report after every  summary is loaded. Posting about 100
    // progress updates should be more than sufficient for users to understand
    // how long loading will take.
    num progressDelta = math.max(total / 100, 1);
    num nextProgressToReport = 0;
    maybeReportProgress() {
      if (nextProgressToReport > progress && progress != total) return;
      nextProgressToReport += progressDelta;
      if (onProgress != null) onProgress(progress, total);
    }

    try {
      sdkRequest = await HttpRequest.request(sdkUrl,
          responseType: "arraybuffer",
          mimeType: "application/octet-stream",
          withCredentials: true);
    } catch (error) {
      onError('Dart sdk summaries failed to load: $error. url: $sdkUrl');
      return null;
    }
    progress++;
    maybeReportProgress();

    var sdkBytes = (sdkRequest.response as ByteBuffer).asUint8List();

    // Map summary URLs to HttpRequests.

    var summaryRequests =
        iteratorToList(summaryMap.values()).map((String summaryUrl) async {
      var request = await HttpRequest.request(summaryUrl,
          responseType: "arraybuffer", mimeType: "application/octet-stream");
      progress++;
      maybeReportProgress();
      return request;
    }).toList();
    try {
      var summaryResponses = await Future.wait(summaryRequests);
      // Map summary responses to summary bytes.
      List<List<int>> summaryBytes = summaryResponses
          .map((response) => (response.response as ByteBuffer).asUint8List())
          .toList();
      onCompileReady(setUpCompile(
          sdkBytes, summaryBytes, iteratorToList(summaryMap.keys())));
    } catch (error) {
      onError('Summaries failed to load: $error');
    }
  }

  List<Function> setUpCompile(List<int> sdkBytes, List<List<int>> summaryBytes,
      List<String> moduleIds) {
    var dartSdkSummaryPath = '/dart-sdk/lib/_internal/web_sdk.sum';

    var resources = MemoryResourceProvider()
      ..newFileWithBytes(dartSdkSummaryPath, sdkBytes);

    var options = AnalyzerOptions.basic(
        dartSdkPath: '/dart-sdk', dartSdkSummaryPath: dartSdkSummaryPath);

    var summaryData = SummaryDataStore([], resourceProvider: resources);
    var compilerOptions = CompilerOptions.fromArguments(argResults);
    compilerOptions.replCompile = true;
    compilerOptions.libraryRoot = '/';
    for (var i = 0; i < summaryBytes.length; i++) {
      var bytes = summaryBytes[i];

      // Packages with no dart source files will have empty invalid summaries.
      if (bytes.isEmpty) continue;

      var moduleId = moduleIds[i];
      var url = '/$moduleId.api.ds';
      summaryData.addBundle(url, PackageBundle.fromBuffer(bytes));
      compilerOptions.summaryModules[url] = moduleId;
    }
    options.analysisRoot = '/web-compile-root';
    options.fileResolvers = [ResourceUriResolver(resources)];
    options.resourceProvider = resources;

    var driver = CompilerAnalysisDriver(options, summaryData: summaryData);

    var resolveFn = (String url) {
      var packagePrefix = 'package:';
      var uri = Uri.parse(url);
      var base = p.basename(url);
      var parts = uri.pathSegments;
      var match;
      int bestScore = 0;
      for (var candidate in summaryData.uriToSummaryPath.keys) {
        if (p.basename(candidate) != base) continue;
        List<String> candidateParts = p.dirname(candidate).split('/');
        var first = candidateParts.first;

        // Process and strip "package:" prefix.
        if (first.startsWith(packagePrefix)) {
          first = first.substring(packagePrefix.length);
          candidateParts[0] = first;
          // Handle convention that directory foo/bar/baz is given package name
          // foo.bar.baz
          if (first.contains('.')) {
            candidateParts = (first.split('.'))..addAll(candidateParts.skip(1));
          }
        }

        // If file name and extension don't match... give up.
        int i = parts.length - 1;
        int j = candidateParts.length - 1;

        int score = 1;
        // Greedy algorithm finding matching path segments from right to left
        // skipping segments on the candidate path unless the target path
        // segment is named lib.
        while (i >= 0 && j >= 0) {
          if (parts[i] == candidateParts[j]) {
            i--;
            j--;
            score++;
            if (j == 0 && i == 0) {
              // Arbitrary bonus if we matched all parts of the input
              // and used up all parts of the output.
              score += 10;
            }
          } else {
            // skip unmatched lib directories from the input
            // otherwise skip unmatched parts of the candidate.
            if (parts[i] == 'lib') {
              i--;
            } else {
              j--;
            }
          }
        }

        if (score > bestScore) {
          match = candidate;
        }
      }
      return match;
    };

    CompileModule compileFn = (String imports, String body, String libraryName,
        String existingLibrary, String fileName) {
      // Instead of returning a single function, return a pair of functions.
      // Create a new virtual File that contains the given Dart source.
      String sourceCode;
      if (existingLibrary == null) {
        sourceCode = imports + body;
      } else {
        var dir = p.dirname(existingLibrary);
        // Need to pull in all the imports from the existing library and
        // re-export all privates as privates in this library.
        // Assumption: summaries are available for all libraries, including any
        // source files that were compiled; we do not need to reconstruct any
        // summary data here.
        var unlinked = driver.summaryData.unlinkedMap[existingLibrary];
        if (unlinked == null) {
          throw "Unable to get library element for `$existingLibrary`.";
        }
        var sb = StringBuffer(imports);
        sb.write('\n');

        // TODO(jacobr): we need to add a proper Analyzer flag specifing that
        // cross-library privates should be in scope instead of this hack.
        // We set the private name prefix for scope resolution to an invalid
        // character code so that the analyzer ignores normal Dart private
        // scoping rules for top level names allowing REPL users to access
        // privates in arbitrary libraries. The downside of this scheme is it is
        // possible to get errors if privates in the current library and
        // imported libraries happen to have exactly the same name.
        Scope.PRIVATE_NAME_PREFIX = -1;

        // We emulate running code in the context of an existing library by
        // importing that library and all libraries it imports.
        sb.write('import ${json.encode(existingLibrary)};\n');

        for (var import in unlinked.imports) {
          if (import.uri == null || import.isImplicit) continue;
          var uri = import.uri;
          // dart: and package: uris are not relative but the path package
          // thinks they are. We have to provide absolute uris as our library
          // has a different directory than the library we are pretending to be.
          if (p.isRelative(uri) &&
              !uri.startsWith('package:') &&
              !uri.startsWith('dart:')) {
            uri = p.normalize(p.join(dir, uri));
          }
          sb.write('import ${json.encode(uri)}');
          if (import.prefixReference != 0) {
            var prefix = unlinked.references[import.prefixReference].name;
            sb.write(' as $prefix');
          }
          for (var combinator in import.combinators) {
            if (combinator.shows.isNotEmpty) {
              sb.write(' show ${combinator.shows.join(', ')}');
            } else if (combinator.hides.isNotEmpty) {
              sb.write(' hide ${combinator.hides.join(', ')}');
            } else {
              throw 'Unexpected element combinator';
            }
          }
          sb.write(';\n');
        }
        sb.write(body);
        sourceCode = sb.toString();
      }
      resources.newFile(fileName, sourceCode);

      var name = p.toUri(libraryName).toString();
      compilerOptions.moduleName = name;
      JSModuleFile module =
          compileWithAnalyzer(driver, [fileName], options, compilerOptions);

      var moduleCode = '';
      if (module.isValid) {
        moduleCode =
            module.getCode(ModuleFormat.legacyConcat, name, name + '.map').code;
      }

      return CompileResult(
          code: moduleCode, isValid: module.isValid, errors: module.errors);
    };

    return [allowInterop(compileFn), allowInterop(resolveFn)];
  }
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  @override
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}
