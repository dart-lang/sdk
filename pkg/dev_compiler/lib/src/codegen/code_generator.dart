library ddc.src.codegen.code_generator;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart' show CompilationUnit;
import 'package:path/path.dart' as path;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/report.dart';
import 'package:ddc/src/checker/rules.dart';

abstract class CodeGenerator {
  final String outDir;
  final Uri root;
  final TypeRules rules;

  CodeGenerator(String outDir, this.root, this.rules)
      : outDir = path.absolute(outDir);

  // TODO(jmesserly): JS generates per library outputs, so it does not use this
  // method and instead overrides generateLibrary.
  void generateUnit(CompilationUnit unit, LibraryInfo info, String libraryDir) {
  }

  void generateLibrary(Iterable<CompilationUnit> units, LibraryInfo info,
      CheckerReporter reporter) {
    var libraryDir = path.join(outDir, info.name);
    new Directory(libraryDir)..createSync(recursive: true);
    for (var unit in units) {
      reporter.enterSource(unit.element.source);
      generateUnit(unit, info, libraryDir);
      reporter.leaveSource();
    }
  }
}
