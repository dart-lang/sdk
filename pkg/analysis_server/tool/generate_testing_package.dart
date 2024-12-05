// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This script generates a test package with a specified number of libraries,
/// classes, methods, and doc comment references, in order to test analyzer's
/// performance, scalability, and stability characteristics.
///
/// Call with `--help` to see all of the args.
library;

import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main(List<String> args) async {
  // TODO(srawlins): Support multiple packages which depend on each other, in a
  // DAG similar to the import graph.
  var argParser = ArgParser()
    ..addOption(
      'library-count',
      defaultsTo: '1',
      help: 'the number of libraries',
    )
    ..addOption(
      'class-count',
      defaultsTo: '1',
      help: 'the number of classes per library',
    )
    ..addOption(
      'method-count',
      defaultsTo: '1',
      help: 'the number of methods per class',
    )
    ..addOption(
      'parameter-count',
      defaultsTo: '1',
      help: 'the number of parameters per method',
    )
    ..addFlag('use-barrel-file', help: 'Whether to add a barrel import')
    ..addFlag('use-json-serializable',
        help: 'Whether to declare @JsonSerializable classes');
  var argResults = argParser.parse(args);
  var libraryCount = int.parse(argResults['library-count'] as String);
  var classCount = int.parse(argResults['class-count'] as String);
  var methodCount = int.parse(argResults['method-count'] as String);
  var parameterCount = int.parse(argResults['parameter-count'] as String);
  var useBarrelFile = argResults['use-barrel-file'] as bool;
  var useJsonSerializable = argResults['use-json-serializable'] as bool;
  var testDataDir = Directory('test_data')..createSync();
  var libFiles = <d.Descriptor>[];
  var classCounter = 1;
  var methodCounter = 1;
  var middleImportIndex = libraryCount ~/ 2;
  // We need a global index for the names of top-level variables, to avoid
  // ambiguous elements from imports.
  var topLevelVariableIndex = 1;
  for (var lIndex = 1; lIndex <= libraryCount; lIndex++) {
    var libraryName = 'lib$lIndex'.padLeft(3, '0');
    // Each library has an index, starting at 1. The libraries depend on each
    // other in tiers. The "tier" of a library is the base-2 logarithm of its
    // index. Libraries in higher tiers depend on libraries in lower tiers.
    // Libraries in higher tiers depend on more libraries than those in lower
    // tiers.
    //
    // In a package with 10 libraries, we have the following tiers and
    // dependencies:
    // * T0: lib1 - no imports
    // * T1: lib2 - imports lib1
    // * T2: lib3, lib4 - each imports two libraries from T0, T1
    // * T3: lib5, lib6, lib7, lib8 - each imports three libraries from T0, T1,
    //       and T2
    // * T4: lib9, lib10 - each imports four libraries from T0, T1, T2, T3
    //
    // In a package with 1000 libraries, there are 11 tiers, and libraries in
    // the last have 10 imports each.
    // TODO(srawlins): Make the "connectedness" of the import graph
    // configurable.
    var importGraphTier = (log(lIndex) / ln2).ceil();
    var importIndexStep =
        importGraphTier == 0 ? -1 : (lIndex - 1) ~/ importGraphTier;
    var content = StringBuffer();
    if (useJsonSerializable) {
      content.writeln("import 'package:json_annotation/json_annotation.dart';");
    }
    // Add imports in a library above tier 0.
    if (importGraphTier > 0) {
      if (useBarrelFile && lIndex > middleImportIndex) {
        content.writeln(import(testPackageLibUri('barrel.dart')));
      }
      for (var tierIndex = 1; tierIndex <= importGraphTier; tierIndex++) {
        var importIndex = tierIndex * importIndexStep;
        if (useBarrelFile) {
          if (lIndex <= middleImportIndex || importIndex > middleImportIndex) {
            content.writeln(import(testPackageLibUri('lib$importIndex.dart')));
          }
        } else {
          content.writeln(import(testPackageLibUri('lib$importIndex.dart')));
        }
      }
      content.writeln();
    }

    if (useJsonSerializable) {
      content.writeln("part '$libraryName.g.dart';");
      content.writeln();
    }

    // Add top-level variables above tier 0.
    if (importGraphTier > 0) {
      for (var tierIndex = 1; tierIndex <= importGraphTier; tierIndex++) {
        var importIndex = tierIndex * importIndexStep;
        // We instantiate a class which is guaranteed to be found in
        // `lib$importIndex.dart`.
        var classReferenceIndex = classCount * importIndex;
        content
            .writeln('var x$topLevelVariableIndex = C$classReferenceIndex();');
        topLevelVariableIndex++;
      }
      content.writeln();
    }

    for (var cIndex = 1; cIndex <= classCount; cIndex++) {
      content.writeln('/// Doc comment.');
      if (useJsonSerializable) {
        content.writeln('@JsonSerializable()');
      }
      content.writeln('class C$classCounter {');
      if (useJsonSerializable) {
        content.writeln('  C$classCounter();');
        content.writeln(
            '  factory C$classCounter.fromJson(Map<String, dynamic> json) => '
            '_\$C${classCounter}FromJson(json);');
        content.writeln('  Map<String, dynamic> toJson() => '
            '_\$C${classCounter}ToJson(this);');
      }
      for (var mIndex = 1; mIndex <= methodCount; mIndex++) {
        content.write('  void m$methodCounter(');
        content.write(List.generate(parameterCount, (pIndex) => 'int p$pIndex')
            .join(', '));
        content.writeln(') {}');
        methodCounter++;
      }
      content.writeln('}');
      classCounter++;
    }
    libFiles.add(d.file('$libraryName.dart', content.toString()));
  }

  if (useBarrelFile) {
    // Write the barrel file, which exports the first half of the libraries.
    var content = StringBuffer();
    for (var j = 1; j <= middleImportIndex; j++) {
      content.writeln(export(testPackageLibUri('lib$j.dart')));
    }
    libFiles.add(d.file('barrel.dart', content.toString()));
  }

  var testPackageDir = d.dir('test_package', [
    d.file('pubspec.yaml', pubspec(useJsonSerializable: useJsonSerializable)),
    d.dir('lib', libFiles),
  ]);
  await testPackageDir.create(testDataDir.path);
}

String export(String uri) => "export '$uri';";

String import(String uri) => "import '$uri';";

/// Returns the text of a 'pubspec.yaml' file.
///
/// With [useJsonSerializable], several packages are added to the dependencies
/// in order to test using build_runner.
String pubspec({required bool useJsonSerializable}) {
  var dependencies = useJsonSerializable
      ? '''
dependencies:
  json_annotation: any
  json_serializable: any
'''
      : '';
  var devDependencies = useJsonSerializable
      ? '''
dev_dependencies:
  build_runner: any
'''
      : '';
  return '''
name: test_package
version: 0.0.1
environment:
  sdk: '>=2.12.0 <3.0.0'
$dependencies
$devDependencies
''';
}

String testPackageLibUri(String path) => 'package:test_package/$path';
