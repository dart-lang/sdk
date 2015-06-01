// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.dart_codegen;

import 'dart:io' show File;

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart' as java_core;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:logging/logging.dart' as logger;
import 'package:path/path.dart' as path;

import 'package:dev_compiler/devc.dart' show AbstractCompiler;
import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/utils.dart' as utils;
import 'ast_builder.dart';
import 'code_generator.dart' as codegenerator;
import 'reify_coercions.dart'
    show CoercionReifier, NewTypeIdDesc, InstrumentedRuntime;

final _log = new logger.Logger('dev_compiler.dart_codegen');

class DevCompilerRuntime extends InstrumentedRuntime {
  Identifier _runtimeId = AstBuilder.identifierFromString("DEVC\$RT");

  Identifier _castId;
  Identifier _typeToTypeId;
  Identifier _wrapId;

  DevCompilerRuntime() {
    _castId = _prefixId(AstBuilder.identifierFromString("cast"));
    _typeToTypeId = _prefixId(AstBuilder.identifierFromString("type"));
    _wrapId = _prefixId(AstBuilder.identifierFromString("wrap"));
  }

  String get importString {
    var name = _runtimeId;
    var uri = "package:dev_compiler/runtime/dart_logging_runtime.dart";
    return "import '$uri' as $name;";
  }

  Identifier _prefixId(Identifier id) =>
      AstBuilder.prefixedIdentifier(_runtimeId, id);

  Identifier runtimeId(RuntimeOperation oper) {
    if (oper.operation == "cast") return _castId;
    if (oper.operation == "wrap") return _wrapId;
    if (oper.operation == "type") return _typeToTypeId;
    assert(false);
    return null;
  }

  Expression runtimeOperation(RuntimeOperation oper) {
    var id = runtimeId(oper);
    var args = oper.arguments;
    return AstBuilder.application(id, args);
  }

  @override
  Expression wrap(Expression coercion, Expression e, Expression fromType,
      Expression toType, Expression dartIs, String kind, String location) {
    var k = AstBuilder.stringLiteral(kind);
    var key = AstBuilder.multiLineStringLiteral(location);
    var arguments = <Expression>[coercion, e, fromType, toType, k, key, dartIs];
    return new RuntimeOperation("wrap", arguments);
  }

  Expression cast(Expression e, Expression fromType, Expression toType,
      Expression dartIs, String kind, String location, bool ground) {
    var k = AstBuilder.stringLiteral(kind);
    var key = AstBuilder.multiLineStringLiteral(location);
    var g = AstBuilder.booleanLiteral(ground);
    var arguments = <Expression>[e, fromType, toType, k, key, dartIs, g];
    return new RuntimeOperation("cast", arguments);
  }

  Expression type(Expression witnessFunction) {
    return new RuntimeOperation("type", <Expression>[witnessFunction]);
  }
}

// TODO(leafp) This is kind of a hack, but it works for now.
class FileWriter extends java_core.PrintStringWriter {
  final CompilerOptions options;
  String _path;
  FileWriter(this.options, this._path);
  int indent = 0;
  int withinInterpolationExpression = 0;
  bool insideForLoop = false;

  void print(x) {
    if (!options.formatOutput) {
      super.print(x);
      return;
    }

    switch (x) {
      case '{':
        indent++;
        x = '{\n${"  " * indent}';
        break;
      case ';':
        if (!insideForLoop) {
          x = ';\n${"  " * indent}';
        }
        break;
      case 'for (':
        insideForLoop = true;
        break;
      case ') ':
        insideForLoop = false;
        break;
      case r'${':
        withinInterpolationExpression++;
        break;
      case '}':
        if (withinInterpolationExpression > 0) {
          withinInterpolationExpression--;
        } else {
          indent--;
          x = '}\n${"  " * indent}';
        }
        break;
    }
    super.print(x);
  }

  void finalize() {
    String s = toString();
    _log.fine("Writing file $_path");
    new File(_path).writeAsStringSync(s);
  }
}

bool _identifierNeedsQualification(Identifier id, NewTypeIdDesc desc) {
  var library = desc.importedFrom;
  if (library == null) return false;
  if (library.isDartCore) return false;
  if (desc.fromCurrent) return false;
  return true;
}

// This class just holds some additional syntactic helpers and
// fixes to the general ToSourceVisitor for use by subclasses.
abstract class UnitGeneratorCommon extends analyzer.ToSourceVisitor {
  UnitGeneratorCommon(java_core.PrintWriter out) : super(out);

  void output(String s);
  void outputln(String s);

  // Copied from ast.dart
  void visitNodeListWithSeparatorAndSuffix(
      NodeList<AstNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            output(separator);
          }
          nodes[i].accept(this);
        }
        output(suffix);
      }
    }
  }

  // Copied from ast.dart
  void visitListWithSeparatorAndPrefix(
      String prefix, List<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        output(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            output(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }

  // Copied from ast.dart
  void visitNodeListWithSeparatorAndPrefix(
      String prefix, NodeList<AstNode> nodes, String separator) {
    visitListWithSeparatorAndPrefix(prefix, nodes, separator);
  }

  // Copied from ast.dart
  void visitTokenWithSuffix(Token token, String suffix) {
    if (token != null) {
      output(token.lexeme);
      output(suffix);
    }
  }

  // Copied from ast.dart
  void safelyVisitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  // Copied from ast.dart
  void visitNodeWithPrefix(String prefix, AstNode node) {
    if (node != null) {
      output(prefix);
      node.accept(this);
    }
  }

  // Copied from ast.dart
  void visitNodeWithSuffix(AstNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      output(suffix);
    }
  }

  // Overridden to add external keyword if present
  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    visitTokenWithSuffix(node.externalKeyword, " ");
    visitNodeWithSuffix(node.returnType, " ");
    visitTokenWithSuffix(node.propertyKeyword, " ");
    safelyVisitNode(node.name);
    safelyVisitNode(node.functionExpression);
    return null;
  }
}

// TODO(leafp) Not sure if this is the right way to generate
// Dart source going forward, but it's a quick way to get started.
class UnitGenerator extends UnitGeneratorCommon with ConversionVisitor<Object> {
  CompilationUnit unit;
  final java_core.PrintWriter _out;
  final String outDir;
  Set<LibraryElement> _extraImports;
  final _runtime;
  bool _qualifyNames = true;
  Map<Identifier, NewTypeIdDesc> _newIdentifiers;

  UnitGenerator(this.unit, java_core.PrintWriter out, String this.outDir,
      this._extraImports, this._newIdentifiers, this._runtime)
      : _out = out,
        super(out);

  void output(String s) => _out.print(s);
  void outputln(String s) => _out.println(s);

  // Choose a canonical prefix for a library that we are adding.
  // Currently just chooses something unlikely to conflict with a user
  // prefix.
  // TODO(leafp): Make this robust.
  String canonizeLibraryName(String name) {
    name = name.replaceAll(".", "DOT");
    name = "DDC\$$name\$";
    return name;
  }

  // Split the directives into the various kinds (since there are restrictions
  // in the syntax as to order of directives).
  Map<String, List<Directive>> splitDirectives(NodeList<Directive> directives) {
    return {
      'export': directives.where((d) => d is ExportDirective).toList(),
      'import': directives.where((d) => d is ImportDirective).toList(),
      'library': directives.where((d) => d is LibraryDirective).toList(),
      'part': directives.where((d) => d is PartDirective).toList(),
      'partof': directives.where((d) => d is PartOfDirective).toList(),
    };
  }

  // Build the set of import directives corresponding to the
  // extra imports required by the types that we add in via
  // inference
  List<String> buildExtraImportDirectives() {
    return _extraImports.map((lib) {
      var name = utils.canonicalLibraryName(lib);
      name = canonizeLibraryName(name);
      var uri = codegenerator.CodeGenerator.uriFor(lib);
      return "import '$uri' as $name;";
    }).toList();
  }

  // Rewrite the import directives with additional library imports
  // covering the inferred types added in as part of this pass.
  void _visitDirectives(String prefix, List<Directive> directives) {
    _qualifyNames = false;
    var ds = splitDirectives(directives);
    visitListWithSeparatorAndPrefix(prefix, ds['library'], " ");
    if (ds['library'].length != 0) {
      assert(ds['partof'].length == 0);
      var es = buildExtraImportDirectives();
      es.add(_runtime.importString);
      es.forEach(outputln);
    }
    visitListWithSeparatorAndPrefix(prefix, ds['partof'], " ");
    visitListWithSeparatorAndPrefix(prefix, ds['import'], " ");
    visitListWithSeparatorAndPrefix(prefix, ds['export'], " ");
    visitListWithSeparatorAndPrefix(prefix, ds['part'], " ");
    _qualifyNames = true;
  }

  @override
  Object visitNode(AstNode node) {
    if (node != null) {
      node.visitChildren(this);
    }
    return null;
  }

  @override
  Object visitRuntimeOperation(RuntimeOperation oper) {
    var e = _runtime.runtimeOperation(oper);
    e.accept(this);
    return null;
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _log.severe("Unlowered as expression");
    assert(false);
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    safelyVisitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    _visitDirectives(prefix, directives);
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier id) {
    safelyVisitNode(id.prefix);
    output('.');
    output(id.identifier.token.lexeme);
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier id) {
    if (!(_qualifyNames &&
        _newIdentifiers.containsKey(id) &&
        _identifierNeedsQualification(id, _newIdentifiers[id]))) {
      return super.visitSimpleIdentifier(id);
    }
    var library = _newIdentifiers[id].importedFrom;
    if (!utils.isDartPrivateLibrary(library)) {
      var lib = utils.canonicalLibraryName(library);
      var libname = canonizeLibraryName(lib);
      output(libname);
      output('.');
    }
    output(id.name);
    return null;
  }

  void generate() {
    visitCompilationUnit(unit);
  }
}

class DartGenerator extends codegenerator.CodeGenerator {
  final DevCompilerRuntime _runtime = new DevCompilerRuntime();

  DartGenerator(AbstractCompiler compiler) : super(compiler);

  Set<LibraryElement> computeExtraImports(Map<Identifier, NewTypeIdDesc> ids) {
    var imports = new Set<LibraryElement>();
    void process(Identifier id, NewTypeIdDesc desc) {
      if (_identifierNeedsQualification(id, desc)) {
        var library = desc.importedFrom;
        if (utils.isDartPrivateLibrary(library)) {
          _log.severe("Dropping import of private library ${library}\n");
          return;
        }
        imports.add(library);
      }
    }
    ids.forEach(process);
    return imports;
  }

  String generateLibrary(LibraryUnit library, LibraryInfo info) {
    var r = new CoercionReifier(library, compiler, _runtime);
    var ids = r.reify();
    var extraImports = computeExtraImports(ids);

    for (var unit in library.partsThenLibrary) {
      var libraryDir = makeOutputDirectory(info, unit);
      var uri = unit.element.source.uri;
      _log.fine("Generating unit $uri");
      FileWriter out = new FileWriter(
          options, path.join(libraryDir, '${uri.pathSegments.last}'));
      var unitGen =
          new UnitGenerator(unit, out, outDir, extraImports, ids, _runtime);
      unitGen.generate();
      out.finalize();
    }

    return null;
  }
}

class EmptyUnitGenerator extends UnitGeneratorCommon {
  final java_core.PrintWriter _out;
  CompilationUnit unit;

  EmptyUnitGenerator(this.unit, java_core.PrintWriter out)
      : _out = out,
        super(out);

  void output(String s) => _out.print(s);
  void outputln(String s) => _out.println(s);

  void generate() {
    unit.visitChildren(this);
  }
}

// This class emits the code unchanged, for comparison purposes.
class EmptyDartGenerator extends codegenerator.CodeGenerator {
  EmptyDartGenerator(AbstractCompiler compiler) : super(compiler);

  String generateLibrary(LibraryUnit library, LibraryInfo info) {
    for (var unit in library.partsThenLibrary) {
      var outputDir = makeOutputDirectory(info, unit);
      generateUnit(unit, info, outputDir);
    }
    return null;
  }

  void generateUnit(CompilationUnit unit, LibraryInfo info, String libraryDir) {
    var uri = unit.element.source.uri;
    _log.fine("Emitting original unit " + uri.toString());
    FileWriter out = new FileWriter(
        options, path.join(libraryDir, '${uri.pathSegments.last}'));
    var unitGen = new EmptyUnitGenerator(unit, out);
    unitGen.generate();
    out.finalize();
  }
}
