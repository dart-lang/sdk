// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_propagation/builder.dart';
import 'package:kernel/type_propagation/solver.dart';
import 'package:kernel/type_propagation/visualizer.dart';
import 'package:path/path.dart' as pathlib;
import 'package:test/test.dart';

const String testcaseDirectory = 'test/type_propagation/testcases';
const String binaryDirectory = 'test/type_propagation/binary';
const String textDirectory = 'test/type_propagation/text';

/// Returns true if [derivedFile] exists and is newer than [baseFile].
bool isUpToDate(String derivedFile, String baseFile) {
  FileStat statDerived = new File(derivedFile).statSync();
  if (statDerived.type == FileSystemEntityType.NOT_FOUND) return false;
  FileStat statBase = new File(baseFile).statSync();
  if (statBase.type == FileSystemEntityType.NOT_FOUND) {
    throw 'Missing file: $baseFile';
  }
  return statDerived.modified.isAfter(statBase.modified);
}

void main() {
  String sdk = pathlib.dirname(pathlib.dirname(Platform.resolvedExecutable));
  Directory directory = new Directory(testcaseDirectory);
  for (FileSystemEntity file in directory.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      String name = pathlib.basename(file.path);
      test(name, () {
        String dartPath = file.path;
        String shortName = pathlib.withoutExtension(name);
        String binaryPath = '$binaryDirectory/$shortName.dill';
        String baselineTextPath = '$textDirectory/$shortName.baseline.txt';
        String currentTextPath = '$textDirectory/$shortName.current.txt';

        Program program;
        if (isUpToDate(binaryPath, dartPath)) {
          program = loadProgramFromBinary(binaryPath);
        } else {
          Repository repository = new Repository(sdk: sdk);
          program = loadProgramFromDart(dartPath, repository);
          writeProgramToBinary(program, binaryPath);
        }

        // Run type propagation.
        Visualizer visualizer = new Visualizer(program);
        Builder builder = new Builder(program, visualizer: visualizer);
        Solver solver = new Solver(builder);
        solver.solve();
        visualizer.solver = solver;

        // Generate annotated text for the main library.
        StringBuffer buffer = new StringBuffer();
        Printer printer =
            new Printer(buffer, annotator: visualizer.getTextAnnotator());
        printer.writeLibraryFile(program.mainMethod.enclosingLibrary);
        String newText = '$buffer';
        new File(currentTextPath).writeAsStringSync(newText);

        // Compare with the baseline file.
        if (!isUpToDate(baselineTextPath, dartPath)) {
          // Set this file as the new baseline.
          new File(baselineTextPath).writeAsStringSync(newText);
        } else {
          String oldText = new File(baselineTextPath).readAsStringSync();
          if (oldText != newText) {
            fail('Inferred types changed in: `$name`.\n'
                'Command to reset the baseline:\n'
                '  rm $baselineTextPath\n'
                'Command to see the diff:\n'
                '  diff -cd $textDirectory/$shortName.{baseline,current}.txt'
                '\n');
          }
        }
      });
    }
  }
}
