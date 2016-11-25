// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:path/path.dart' as pathlib;
import 'package:test/test.dart';
import 'package:kernel/checks.dart';

final String testcaseDirectory = 'pkg/kernel/testcases';
final String inputDirectory = 'pkg/kernel/testcases/input';
final String sdkDirectory = 'sdk';

/// A target to be used for testing.
///
/// To simplify testing dependencies, we avoid transformations that rely on
/// a patched SDK or any SDK changes that have not landed in the main SDK.
abstract class TestTarget extends Target {
  /// Annotations to apply on the textual output.
  Annotator get annotator => null;

  List<String> transformProgram(Program program);
}

void runBaselineTests(String folderName, TestTarget target) {
  String outputDirectory = '$testcaseDirectory/$folderName';
  var batch = new DartLoaderBatch();
  Directory directory = new Directory(inputDirectory);
  for (FileSystemEntity file in directory.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      String name = pathlib.basename(file.path);
      test(name, () async {
        String dartPath = file.path;
        String shortName = pathlib.withoutExtension(name);
        String filenameOfBaseline = '$outputDirectory/$shortName.baseline.txt';
        String filenameOfCurrent = '$outputDirectory/$shortName.current.txt';

        var repository = new Repository();
        var loader = await batch.getLoader(
            repository,
            new DartOptions(
                strongMode: target.strongMode,
                sdk: sdkDirectory,
                declaredVariables: target.extraDeclaredVariables));
        var program = loader.loadProgram(dartPath, target: target);
        runSanityChecks(program);
        var errors = target.transformProgram(program);
        runSanityChecks(program);

        var buffer = new StringBuffer();
        for (var error in errors) {
          buffer.writeln('// $error');
        }
        new Printer(buffer, annotator: target.annotator)
            .writeLibraryFile(program.mainMethod.enclosingLibrary);
        String current = '$buffer';
        new File(filenameOfCurrent).writeAsStringSync(current);

        var baselineFile = new File(filenameOfBaseline);
        if (!baselineFile.existsSync()) {
          new File(filenameOfBaseline).writeAsStringSync(current);
        } else {
          var baseline = baselineFile.readAsStringSync();
          if (baseline != current) {
            fail('Output of `$name` changed for $folderName.\n'
                'Command to reset the baseline:\n'
                '  rm $filenameOfBaseline\n'
                'Command to see the diff:\n'
                '  diff -cd $outputDirectory/$shortName.{baseline,current}.txt'
                '\n');
          }
        }
      });
    }
  }
}
