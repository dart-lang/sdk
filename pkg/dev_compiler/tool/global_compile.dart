#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/analyzer.dart'
    show
        ExportDirective,
        ImportDirective,
        PartDirective,
        StringLiteral,
        UriBasedDirective,
        parseDirectives;
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:args/args.dart' show ArgParser;
import 'package:path/path.dart' as path;

const ENTRY = "main";

void main(List<String> args) {
  // Parse flags.
  var parser = new ArgParser()
    ..addOption('out',
        help: 'Output file (defaults to "out.js")',
        abbr: 'o',
        defaultsTo: 'out.js')
    ..addFlag('unsafe-force-compile',
        help: 'Generate code with undefined behavior', negatable: false)
    ..addFlag('emit-metadata',
        help: 'Preserve annotations in generated code', negatable: false)
    ..addOption('package-root',
        help: 'Directory containing packages',
        abbr: 'p',
        defaultsTo: 'packages/')
    ..addFlag('log', help: 'Show individual build commands')
    ..addOption('tmp',
        help:
            'Directory for temporary artifacts (defaults to a system tmp directory)');

  var options = parser.parse(args);
  if (options.rest.length != 1) {
    throw 'Expected a single dart entrypoint.';
  }
  var entry = options.rest.first;
  var outfile = options['out'] as String;
  var packageRoot = options['package-root'] as String;
  var unsafe = options['unsafe-force-compile'] as bool;
  var log = options['log'] as bool;
  var tmp = options['tmp'] as String;
  var metadata = options['emit-metadata'] as bool;

  // Build an invocation to dartdevc
  var dartPath = Platform.resolvedExecutable;
  var ddcPath = path.dirname(path.dirname(Platform.script.toFilePath()));
  var template = [
    '$ddcPath/bin/dartdevc.dart',
    '--modules=legacy', // TODO(vsm): Change this to use common format.
    '--single-out-file',
    '--inline-source-map',
    '-p',
    packageRoot
  ];
  if (metadata) {
    template.add('--emit-metadata');
  }
  if (unsafe) {
    template.add('--unsafe-force-compile');
  }

  // Compute the transitive closure
  var total = new Stopwatch()..start();
  var partial = new Stopwatch()..start();

  // TODO(vsm): We're using the analyzer just to compute the import/export/part
  // dependence graph.  This is expensive.  Is there a lighterweight way to do
  // this?
  transitiveFiles(entry, Directory.current.path, packageRoot);
  orderModules();
  computeTransitiveDependences();

  var graphTime = partial.elapsedMilliseconds / 1000;
  print('Computed global build graph in $graphTime seconds');

  // Prepend Dart runtime files to the output
  var out = new File(outfile);
  var dartLibrary =
      new File(path.join(ddcPath, 'lib', 'js', 'legacy', 'dart_library.js'))
          .readAsStringSync();
  out.writeAsStringSync(dartLibrary);
  var dartSdk =
      new File(path.join(ddcPath, 'lib', 'js', 'legacy', 'dart_sdk.js'))
          .readAsStringSync();
  out.writeAsStringSync(dartSdk, mode: FileMode.APPEND);

  // Linearize module concatenation for deterministic output
  var last = new Future.value();
  for (var module in orderedModules) {
    linearizerMap[module] = last;
    var completer = new Completer();
    completerMap[module] = completer;
    last = completer.future;
  }

  // Build modules asynchronously
  var tmpdir = (tmp == null)
      ? Directory.systemTemp
          .createTempSync(outfile.replaceAll(path.separator, '__'))
      : new Directory(tmp)..createSync();
  for (var module in orderedModules) {
    var file = tmpdir.path + path.separator + module + '.js';
    var command = template.toList()..addAll(['-o', file]);
    var dependences = transitiveDependenceMap[module];
    for (var dependence in dependences) {
      var summary = tmpdir.path + path.separator + dependence + '.sum';
      command.addAll(['-s', summary]);
    }
    var infiles = fileMap[module];
    command.addAll(infiles);

    var waitList = dependenceMap.containsKey(module)
        ? dependenceMap[module].map((dep) => readyMap[dep])
        : <Future>[];
    var future = Future.wait(waitList);
    readyMap[module] = future.then((_) {
      var ready = Process.run(dartPath, command);
      if (log) {
        print(command.join(' '));
      }
      return ready.then((result) {
        if (result.exitCode != 0) {
          print('ERROR: compiling $module');
          print(result.stdout);
          print(result.stderr);
          out.deleteSync();
          exit(1);
        }
        print('Compiled $module (${infiles.length} files)');
        print(result.stdout);

        // Schedule module append once the previous module is written
        var codefile = new File(file);
        linearizerMap[module]
            .then((_) => codefile.readAsString())
            .then((code) =>
                out.writeAsString(code, mode: FileMode.APPEND, flush: true))
            .then((_) => completerMap[module].complete());
      });
    });
  }

  last.then((_) {
    var time = total.elapsedMilliseconds / 1000;
    print('Successfully compiled ${inputSet.length} files in $time seconds');

    // Append the entry point invocation.
    var libraryName =
        path.withoutExtension(entry).replaceAll(path.separator, '__');
    out.writeAsStringSync('dart_library.start("$ENTRY", "$libraryName");\n',
        mode: FileMode.APPEND);
  });
}

final inputSet = new Set<String>();
final dependenceMap = new Map<String, Set<String>>();
final transitiveDependenceMap = new Map<String, Set<String>>();
final fileMap = new Map<String, Set<String>>();

final readyMap = new Map<String, Future>();
final linearizerMap = new Map<String, Future>();
final completerMap = new Map<String, Completer>();

final orderedModules = new List<String>();
final visitedModules = new Set<String>();

void orderModules(
    [String module = ENTRY, List<String> stack, Set<String> visited]) {
  if (stack == null) {
    assert(visited == null);
    stack = new List<String>();
    visited = new Set<String>();
  }
  if (visited.contains(module)) return;
  visited.add(module);
  if (stack.contains(module)) {
    print(stack);
    throw 'Circular dependence on $module';
  }
  stack.add(module);
  var dependences = dependenceMap[module];
  if (dependences != null) {
    for (var dependence in dependences) {
      orderModules(dependence, stack, visited);
    }
  }
  orderedModules.add(module);
  assert(module == stack.last);
  stack.removeLast();
}

void computeTransitiveDependences() {
  for (var module in orderedModules) {
    var transitiveSet = new Set<String>();
    if (dependenceMap.containsKey(module)) {
      transitiveSet.addAll(dependenceMap[module]);
      for (var dependence in dependenceMap[module]) {
        transitiveSet.addAll(transitiveDependenceMap[dependence]);
      }
    }
    transitiveDependenceMap[module] = transitiveSet;
  }
}

String getModule(String uri) {
  var sourceUri = Uri.parse(uri);
  if (sourceUri.scheme == 'dart') {
    return 'dart';
  } else if (sourceUri.scheme == 'package') {
    return path.split(sourceUri.path)[0];
  } else {
    return ENTRY;
  }
}

bool processFile(String file) {
  inputSet.add(file);

  var module = getModule(file);
  fileMap.putIfAbsent(module, () => new Set<String>());
  return fileMap[module].add(file);
}

void processDependence(String from, String to) {
  var fromModule = getModule(from);
  var toModule = getModule(to);
  if (fromModule == toModule || toModule == 'dart') return;
  dependenceMap.putIfAbsent(fromModule, () => new Set<String>());
  dependenceMap[fromModule].add(toModule);
}

String canonicalize(String uri, String root) {
  var sourceUri = Uri.parse(uri);
  if (sourceUri.scheme == '') {
    sourceUri = path.toUri(
        path.isAbsolute(uri) ? path.absolute(uri) : path.join(root, uri));
    return sourceUri.path;
  }
  return sourceUri.toString();
}

/// Simplified from ParseDartTask.resolveDirective.
String _resolveDirective(UriBasedDirective directive) {
  StringLiteral uriLiteral = directive.uri;
  String uriContent = uriLiteral.stringValue;
  if (uriContent != null) {
    uriContent = uriContent.trim();
    directive.uriContent = uriContent;
  }
  return (directive as UriBasedDirectiveImpl).validate() == null
      ? uriContent
      : null;
}

String _loadFile(String uri, String packageRoot) {
  if (uri.startsWith('package:')) {
    uri = path.join(packageRoot, uri.substring(8));
  }
  return new File(uri).readAsStringSync();
}

void transitiveFiles(String entryPoint, String root, String packageRoot) {
  entryPoint = canonicalize(entryPoint, root);
  if (entryPoint.startsWith('dart:')) return;
  if (processFile(entryPoint)) {
    // Process this
    var source = _loadFile(entryPoint, packageRoot);
    var entryDir = path.dirname(entryPoint);
    var unit = parseDirectives(source, name: entryPoint, suppressErrors: true);
    for (var d in unit.directives) {
      if (d is ImportDirective || d is ExportDirective) {
        var uri = _resolveDirective(d);
        processDependence(entryPoint, canonicalize(uri, entryDir));
        transitiveFiles(uri, entryDir, packageRoot);
      } else if (d is PartDirective) {
        var uri = _resolveDirective(d);
        processFile(canonicalize(uri, entryDir));
      }
    }
  }
}
