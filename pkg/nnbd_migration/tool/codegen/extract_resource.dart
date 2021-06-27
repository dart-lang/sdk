// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script provides a quick way, via the command line, to extract one of the
// resources encoded in the file lib/src/front_end/resources/resources.g.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

main(List<String> args) {
  var argResults = argParser.parse(args);
  if (argResults['help'] as bool) {
    fail(null, showUsage: true);
  }
  if (argResults.rest.isNotEmpty) {
    fail('Unexpected extra arguments', showUsage: true);
  }
  bool list = argResults['list'] as bool;
  String? path = argResults['path'] as String?;
  String? resource = argResults['resource'] as String?;
  if (list && resource != null) {
    fail('Only one of --resource and --list may be provided');
  } else if (!list && resource == null) {
    fail('Either --resource or --list must be provided');
  }
  var file = locateResourcesFile(path);
  var parseResult =
      parseString(content: file.readAsStringSync(), path: file.path);
  final variableNameRegExp = RegExp(r'^_(.*)_base64$');
  for (var declaration in parseResult.unit.declarations) {
    if (declaration is TopLevelVariableDeclaration) {
      for (var variable in declaration.variables.variables) {
        if (variable.initializer == null) continue;
        var match = variableNameRegExp.matchAsPrefix(variable.name.name);
        if (match == null) continue;
        var shortName = match.group(1);
        if (list) {
          stdout.writeln(shortName);
        } else if (resource == shortName) {
          stdout.add(decodeVariableDeclaration(variable));
          return;
        }
      }
    }
  }
  if (list) {
    return;
  } else {
    fail('Resource $resource not found in ${file.path}');
  }
}

final argParser = ArgParser()
  ..addOption('resource',
      abbr: 'r', valueHelp: 'RESOURCE', help: 'Extract resource RESOURCE')
  ..addFlag('list',
      negatable: false, abbr: 'l', help: 'List which resources are present')
  ..addOption('path',
      abbr: 'p',
      valueHelp: 'PATH',
      help:
          'Search for resources.g.dart inside PATH rather than current working '
          'directory')
  ..addFlag('help', negatable: false, abbr: 'h');

Uint8List decodeVariableDeclaration(VariableDeclaration variable) {
  var initializer = variable.initializer as StringLiteral;
  var stringValue = initializer.stringValue!;
  return base64.decode(stringValue.replaceAll('\n', '').trim());
}

void fail(String? message, {bool showUsage = false}) {
  if (message != null) {
    stderr.writeln(message);
  }
  if (showUsage) {
    stderr.writeln('''
usage: dart pkg/nnbd_migration/tool/codegen/extract_resource.dart -r <resource>

Reads the file `resources.g.dart` from the appropriate directory, extracts the
embedded resource named `<resource>`, and prints it to standard out.
''');
    stderr.writeln(argParser.usage);
  }
  exit(1);
}

/// Tries to guess the location of `resources.g.dart` using optional [pathHint]
/// as a starting point.
File locateResourcesFile(String? pathHint) {
  pathHint ??= '.';
  final pathParts =
      'pkg/nnbd_migration/lib/src/front_end/resources/resources.g.dart'
          .split('/');
  var currentPath = path.normalize(pathHint);
  while (true) {
    for (int i = 0; i <= pathParts.length; i++) {
      var pathToTry = path.normalize(path.join(
          currentPath, path.joinAll(pathParts.sublist(pathParts.length - i))));
      var file = File(pathToTry);
      var type = file.statSync().type;
      if (type == FileSystemEntityType.notFound && i == 0) {
        fail('No such file or directory: $pathToTry');
      }
      if (type == FileSystemEntityType.link) {
        type = File(file.resolveSymbolicLinksSync()).statSync().type;
      }
      if (type == FileSystemEntityType.file) {
        return file;
      }
    }
    if (currentPath == '.') {
      currentPath = Directory.current.path;
    }
    var nextPath = path.dirname(currentPath);
    if (nextPath == currentPath) {
      fail('Could not find file `resources.g.dart` starting at $pathHint');
    }
    currentPath = nextPath;
  }
}
