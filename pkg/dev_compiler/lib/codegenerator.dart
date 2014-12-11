library codegenerator;

import 'dart:async' show Future;
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';

import 'src/static_info.dart';
import 'src/type_rules.dart';

abstract class CodeGenerator {
  final String outDir;
  final Uri root;
  final Map<Uri, LibraryInfo> libraries;
  final Map<AstNode, SemanticNode> info;
  final TypeRules rules;

  CodeGenerator(this.outDir, this.root, this.libraries, this.info, this.rules);

  String _libName(LibraryInfo lib) {
    for (var directive in lib.lib.directives) {
      if (directive is LibraryDirective) return directive.name.toString();
    }
    // Fall back on the file name.
    var tail = lib.uri.pathSegments.last;
    if (tail.endsWith('.dart')) tail = tail.substring(0, tail.length - 5);
    return tail;
  }

  Future generateUnit(
      Uri uri, CompilationUnit unit, Directory dir, String name);

  Future generateLibrary(String name, LibraryInfo library, Directory dir) {
    var done = [];
    done.add(generateUnit(library.uri, library.lib, dir, name));
    library.parts.forEach((Uri uri, CompilationUnit unit) {
      done.add(generateUnit(uri, unit, dir, name));
    });
    return Future.wait(done);
  }

  Future generate() {
    var base = Uri.base;
    var out = base.resolve(outDir + '/');
    var top = new Directory.fromUri(out);
    top.createSync();

    var done = [];
    libraries.forEach((Uri uri, LibraryInfo lib) {
      var name = _libName(lib);
      var dir = new Directory.fromUri(out.resolve(name))..createSync();
      done.add(generateLibrary(name, lib, dir));
    });
    return Future.wait(done);
  }
}
