library ddc.src.codegen.code_generator;

import 'dart:async' show Future;
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart'
    show LibraryElement, CompilationUnitElement;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/checker/rules.dart';

abstract class CodeGenerator {
  final String outDir;
  final Uri root;
  final List<LibraryElement> libraries;
  final Map<AstNode, SemanticNode> info;
  final TypeRules rules;

  CodeGenerator(this.outDir, this.root, this.libraries, this.info, this.rules);

  String _libName(LibraryElement lib) {
    if (lib.name != null && lib.name != '') return lib.name;

    // Fall back on the file name.
    var tail = lib.source.uri.pathSegments.last;
    if (tail.endsWith('.dart')) tail = tail.substring(0, tail.length - 5);
    return tail;
  }

  Future generateUnit(
      Uri uri, CompilationUnit unit, Directory dir, String name);

  Future generateLibrary(String name, LibraryElement library, Directory dir) {
    var done = [];
    var uri = library.source.uri;
    var unit = library.definingCompilationUnit.node;
    done.add(generateUnit(uri, unit, dir, name));
    for (var unit in library.units) {
      var partUri = unit.source.uri;
      done.add(generateUnit(partUri, unit.node, dir, name));
    }
    return Future.wait(done);
  }

  Future generate() {
    var base = Uri.base;
    var out = base.resolve(outDir + '/');
    var top = new Directory.fromUri(out);
    top.createSync();

    var done = [];
    for (var lib in libraries) {
      var name = _libName(lib);
      var dir = new Directory.fromUri(out.resolve(name))..createSync();
      done.add(generateLibrary(name, lib, dir));
    }
    return Future.wait(done);
  }
}
