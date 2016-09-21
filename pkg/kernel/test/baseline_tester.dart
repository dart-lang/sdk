// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:analyzer/src/generated/sdk.dart';
import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:path/path.dart' as pathlib;
import 'package:test/test.dart';

final String inputDirectory = 'testcases/input';

/// A target to be used for testing.
///
/// To simplify testing dependencies, we avoid transformations that rely on
/// a patched SDK or any SDK changes that have not landed in the main SDK.
abstract class TestTarget extends Target {
  /// Annotations to apply on the textual output.
  Annotator get annotator => null;
}

void runBaselineTests(String folderName, TestTarget target) {
  bool strongMode = target.strongMode;
  String outputDirectory = 'testcases/$folderName';
  String sdk = pathlib.dirname(pathlib.dirname(Platform.resolvedExecutable));
  DartSdk dartSdk = createDartSdk(sdk, strongMode);
  Directory directory = new Directory(inputDirectory);
  for (FileSystemEntity file in directory.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      String name = pathlib.basename(file.path);
      test(name, () {
        String dartPath = file.path;
        String shortName = pathlib.withoutExtension(name);
        String filenameOfBaseline = '$outputDirectory/$shortName.baseline.txt';
        String filenameOfCurrent = '$outputDirectory/$shortName.current.txt';

        var repository = new Repository(sdk: sdk);
        var context = createContext(sdk, null, strongMode, dartSdk: dartSdk);
        var loader = new AnalyzerLoader(repository,
            context: context, strongMode: strongMode);
        var program = loader.loadProgram(dartPath, target: target);
        target.transformProgram(program);

        var buffer = new StringBuffer();
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
