// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:kernel/ast.dart';

import 'incremental_suite.dart' as helper;
import 'utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

void main() async {
  print(await getAllTokens());
}

Future<Set<Class>> getAllTokens() async {
  Uri scannerDir = repoDir.resolve("pkg/_fe_analyzer_shared/lib/src/scanner/");
  return await findIn(Directory.fromUri(scannerDir), "Token", "/token.dart");
}

/// Compiles either a File or a Directory and finds all subtypes of (including)
/// the specified [className] in a file containing [classFilename].
Future<Set<Class>> findIn(
    FileSystemEntity where, String className, String classFilename) async {
  List<Uri> files = [];
  if (where is File) {
    files.add(where.uri);
  } else if (where is Directory) {
    for (FileSystemEntity subEntity in where.listSync(recursive: true)) {
      if (subEntity is File) {
        files.add(subEntity.uri);
      }
    }
  }

  Class? foundTarget;
  Map<Class, Set<Class>> subclassMap = {};
  Component component = await compileOutline(files);
  for (Library lib in component.libraries) {
    for (Class c in lib.classes) {
      if (c.name == className && c.fileUri.toString().contains(classFilename)) {
        if (foundTarget != null) throw "Found both $foundTarget and $c";
        foundTarget = c;
      }
      for (Supertype s in c.supers) {
        (subclassMap[s.classNode] ??= {}).add(c);
      }
    }
  }
  if (foundTarget == null) throw "Didn't find '$className' in '$classFilename'";
  Set<Class> result = {foundTarget};
  List<Class> worklist = [foundTarget];
  while (worklist.isNotEmpty) {
    Class c = worklist.removeLast();
    for (Class child in subclassMap[c] ?? const []) {
      if (result.add(child)) {
        worklist.add(child);
      }
    }
  }
  return result;
}

Future<Component> compileOutline(List<Uri> input) async {
  CompilerOptions options = helper.getOptions();
  options.omitPlatform = true;
  // Give only one input so it automatically finds the packages file.
  helper.TestIncrementalCompiler compiler =
      new helper.TestIncrementalCompiler(options, input.first, null, true);
  IncrementalCompilerResult compilerResult =
      await compiler.computeDelta(entryPoints: input);
  return compilerResult.component;
}
