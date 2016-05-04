#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:args/args.dart' show ArgParser;
import 'package:dev_compiler/src/analyzer/context.dart'
    show createAnalysisContextWithSources;
import 'package:dev_compiler/src/analyzer/context.dart'
    show createAnalysisContextWithSources, AnalyzerOptions;
import 'package:path/path.dart' as path;

void main(List<String> args) {
  // Parse flags.
  var parser = new ArgParser()
    ..addOption('out', abbr: 'o', defaultsTo: 'out.js')
    ..addFlag('unsafe-force-compile', negatable: false)
    ..addOption('package-root', abbr: 'p', defaultsTo: 'packages/');

  var options = parser.parse(args);
  if (options.rest.length != 1) {
    throw 'Expected a single dart entrypoint.';
  }
  var entry = options.rest.first;
  var outfile = options['out'];
  var packageRoot = options['package-root'];
  var unsafe = options['unsafe-force-compile'];

  // Build an invocation to dartdevc.
  var dartPath = Platform.resolvedExecutable;
  var ddcPath = path.dirname(path.dirname(Platform.script.toFilePath()));
  var command = [
    '$ddcPath/bin/dartdevc.dart',
    'compile',
    '--no-source-map', // Invalid as we're just concatenating files below
    '-p',
    packageRoot,
    '-o',
    outfile
  ];
  if (unsafe) {
    command.add('--unsafe-force-compile');
  }

  // Compute the transitive closure
  var watch = new Stopwatch()..start();
  var context = createAnalysisContextWithSources(new AnalyzerOptions());
  var inputSet = new Set<String>();
  transitiveFiles(inputSet, context, entry, Directory.current.path);
  command.addAll(inputSet);
  var result = Process.runSync(dartPath, command);

  if (result.exitCode == 0) {
    print(result.stdout);
  } else {
    print('ERROR:');
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }
  var time = watch.elapsedMilliseconds / 1000;
  print('Successfully compiled ${inputSet.length} files in $time seconds');

  // Prepend Dart runtime files to the output.
  var out = new File(outfile);
  var code = out.readAsStringSync();
  var dartLibrary =
      new File(path.join(ddcPath, 'lib', 'runtime', 'dart_library.js'))
          .readAsStringSync();
  var dartSdk = new File(path.join(ddcPath, 'lib', 'runtime', 'dart_sdk.js'))
      .readAsStringSync();
  out.writeAsStringSync(dartLibrary);
  out.writeAsStringSync(dartSdk, mode: FileMode.APPEND);
  out.writeAsStringSync(code, mode: FileMode.APPEND);

  // Append the entry point invocation.
  var moduleName = path.basenameWithoutExtension(outfile);
  var libraryName =
      path.withoutExtension(entry).replaceAll(path.separator, '__');
  out.writeAsStringSync('dart_library.start("$moduleName", "$libraryName");\n',
      mode: FileMode.APPEND);
}

String canonicalize(String uri, String root) {
  var sourceUri = Uri.parse(uri);
  if (sourceUri.scheme == '') {
    sourceUri = path.toUri(
        path.isAbsolute(uri) ? path.absolute(uri) : path.join(root, uri));
  }
  return sourceUri.toString();
}

void transitiveFiles(Set<String> results, AnalysisContext context,
    String entryPoint, String root) {
  entryPoint = canonicalize(entryPoint, root);
  if (entryPoint.startsWith('dart:')) return;
  var entryDir = path.dirname(entryPoint);
  if (results.add(entryPoint)) {
    // Process this
    var source = context.sourceFactory.forUri(entryPoint);
    if (source == null) {
      throw new Exception('could not create a source for $entryPoint.'
          ' The file name is in the wrong format or was not found.');
    }
    var library = context.computeLibraryElement(source);
    for (var entry in library.imports) {
      if (entry.uri == null) continue;
      transitiveFiles(results, context, entry.uri, entryDir);
    }
    for (var entry in library.exports) {
      transitiveFiles(results, context, entry.uri, entryDir);
    }
    for (var part in library.parts) {
      results.add(canonicalize(part.uri, entryDir));
    }
  }
}
