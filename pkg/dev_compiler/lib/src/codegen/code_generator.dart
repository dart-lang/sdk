library ddc.src.codegen.code_generator;

import 'dart:async' show Future;
import 'dart:io';

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

  Future generateUnit(
      CompilationUnitElementImpl unit, LibraryInfo info, String libraryDir);

  Future generateLibrary(String name, LibraryInfo info) {
    var done = [];
    var library = info.library;
    var libraryDir = path.join(outDir, name);
    new Directory(libraryDir)..createSync(recursive: true);
    done.add(generateUnit(library.definingCompilationUnit, info, libraryDir));
    for (var unit in library.units) {
      done.add(generateUnit(unit, info, libraryDir));
    }
    return Future.wait(done);
  }

  Future generate() {
    var done = [];
    for (var libraryInfo in libraries) {
      var name = libraryInfo.name;
      done.add(generateLibrary(name, libraryInfo));
    }
    return Future.wait(done);
  }
}
