library ddc.src.codegen.code_generator;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart' show CompilationUnit;
import 'package:path/path.dart' as path;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/checker/rules.dart';

abstract class CodeGenerator {
  final String outDir;
  final Uri root;
  final List<LibraryInfo> libraries;
  final TypeRules rules;

  CodeGenerator(String outDir, this.root, this.libraries, this.rules)
      : outDir = path.absolute(outDir);

  void generateUnit(
      CompilationUnit unit, LibraryInfo info, String libraryDir);

  void generateLibrary(Iterable<CompilationUnit> units, LibraryInfo info) {
    var libraryDir = path.join(outDir, info.name);
    new Directory(libraryDir)..createSync(recursive: true);
    for (var unit in units) {
      generateUnit(unit, info, libraryDir);
    }
  }
}
