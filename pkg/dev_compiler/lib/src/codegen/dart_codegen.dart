// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ddc.src.codegen.dart_codegen;

import 'dart:io' show File;

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart' as java_core;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart' as logger;
import 'package:path/path.dart' as path;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/report.dart';
import 'package:ddc/src/utils.dart' as utils;
import 'ast_builder.dart';
import 'code_generator.dart' as codegenerator;
import 'reify_coercions.dart' as reifier;

final _log = new logger.Logger('ddc.dartgenerator');

class DdcRuntime {
  Identifier _ddcRuntimeId = AstBuilder.identifierFromString("DDC\$RT");

  Identifier _castId;
  Identifier _typeToTypeId;
  Identifier _wrapId;

  DdcRuntime() {
    _castId = _prefixId(AstBuilder.identifierFromString("cast"));
    _typeToTypeId = _prefixId(AstBuilder.identifierFromString("type"));
    _wrapId = _prefixId(AstBuilder.identifierFromString("wrap"));
  }

  String get importString {
    var name = _ddcRuntimeId;
    var uri = "package:ddc/runtime/dart_logging_runtime.dart";
    return "import '$uri' as $name;";
  }

  Identifier _prefixId(Identifier id) =>
      AstBuilder.prefixedIdentifier(_ddcRuntimeId, id);

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
}

// TODO(leafp) This is kind of a hack, but it works for now.
class FileWriter extends java_core.PrintStringWriter {
  bool _format;
  String _path;
  FileWriter(this._format, this._path);

  void finalize() {
    String s = toString();
    if (_format) {
      DartFormatter d = new DartFormatter();
      try {
        _log.fine("Formatting file $_path ");
        s = d.format(s, uri: _path);
      } catch (e) {
        _log.severe("Failed to format $_path: " + e.toString());
      }
    }
    _log.fine("Writing file $_path");
    new File(_path).writeAsStringSync(s);
  }
}

bool _identifierNeedsQualification(
    Identifier id, LibraryElement current, Set<Identifier> restrict) {
  var element = id.bestElement;
  return restrict.contains(id) &&
      element != null &&
      element.library != null &&
      (element is ClassElement || element is FunctionTypeAliasElement) &&
      !element.library.isDartCore &&
      element.library != current;
}

// For every type name to which we add a reference, record the library from
// which it comes so that we may add it to the list of imports.
class UnitImportResolver extends analyzer.GeneralizingAstVisitor
    with ConversionVisitor {
  final CompilationUnit unit;
  final Set<LibraryElement> imports;
  final _currentLibrary;
  final _newIdentifiers;

  UnitImportResolver(
      this.unit, this._currentLibrary, this.imports, this._newIdentifiers);

  void compute() {
    visitCompilationUnit(unit);
    return;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.declarations.forEach((node) => node.accept(this));
    return;
  }

  @override
  void visitIdentifier(Identifier id) {
    if (id is PrefixedIdentifier) {
      id.prefix.accept(this);
      return;
    }
    if (_identifierNeedsQualification(id, _currentLibrary, _newIdentifiers)) {
      if (utils.isDartPrivateLibrary(id.bestElement.library)) {
        _log.severe(
            "Dropping import of private library ${id.bestElement.library}\n");
        return;
      }
      imports.add(id.bestElement.library);
    }
    return;
  }
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
  final ddc = new DdcRuntime();
  LibraryElement _currentLibrary;
  bool _qualifyNames = true;
  Set<Identifier> _newIdentifiers;

  UnitGenerator(this.unit, java_core.PrintWriter out, String this.outDir,
      this._extraImports, this._newIdentifiers)
      : _out = out,
        super(out) {
    _currentLibrary = unit.element.enclosingElement;
    final UnitImportResolver r = new UnitImportResolver(
        unit, _currentLibrary, _extraImports, _newIdentifiers);
    r.compute();
  }

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
      es.add(ddc.importString);
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
    var e = ddc.runtimeOperation(oper);
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
    var element = id.bestElement;
    if (!(_qualifyNames &&
        _identifierNeedsQualification(id, _currentLibrary, _newIdentifiers))) {
      return super.visitSimpleIdentifier(id);
    }
    if (!utils.isDartPrivateLibrary(element.library)) {
      var lib = utils.canonicalLibraryName(element.library);
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
  bool _format;
  reifier.VariableManager _vm;
  Set<LibraryElement> _extraImports;
  TypeRules _rules;

  DartGenerator(String outDir, Uri root, TypeRules rules, this._format)
      : _rules = rules,
        super(outDir, root, rules);

  void generateUnit(CompilationUnit unit, LibraryInfo info, String libraryDir) {
    var uri = unit.element.source.uri;
    _log.fine("Generating unit " + uri.toString());
    FileWriter out = new FileWriter(
        _format, path.join(libraryDir, '${uri.pathSegments.last}'));
    var tm = new reifier.TypeManager(_vm);
    var r = new reifier.UnitCoercionReifier(tm, _vm, _rules);
    r.reify(unit);
    var ids = new Set<Identifier>.from(tm.addedTypes.map((tn) => tn.name));
    var unitGen = new UnitGenerator(unit, out, outDir, _extraImports, ids);
    unitGen.generate();
    out.finalize();
  }

  void _generateLibrary(Iterable<CompilationUnit> units, LibraryInfo info,
      CheckerReporter reporter) {
    doOne(unit) {
      var outputDir = makeOutputDirectory(info, unit);
      reporter.enterSource(unit.element.source);
      generateUnit(unit, info, outputDir);
      reporter.leaveSource();
    }
    isLib(unit) => unit.directives.any((d) => d is LibraryDirective);
    isNotLib(unit) => !isLib(unit);
    var libs = units.where(isLib);
    var parts = units.where(isNotLib);
    assert(libs.length == 1 || (libs.length == 0 && parts.length == 1));
    parts.forEach(doOne);
    libs.forEach(doOne);
  }

  void generateLibrary(Iterable<CompilationUnit> units, LibraryInfo info,
      CheckerReporter reporter) {
    _vm = new reifier.VariableManager();
    _extraImports = new Set<LibraryElement>();
    _generateLibrary(units, info, reporter);
    _extraImports = null;
    _vm = null;
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
  bool _format;

  EmptyDartGenerator(String outDir, Uri root, TypeRules rules, this._format)
      : super(outDir, root, rules);

  void generateUnit(CompilationUnit unit, LibraryInfo info, String libraryDir) {
    var uri = unit.element.source.uri;
    _log.fine("Emitting original unit " + uri.toString());
    FileWriter out = new FileWriter(
        _format, path.join(libraryDir, '${uri.pathSegments.last}'));
    var unitGen = new EmptyUnitGenerator(unit, out);
    unitGen.generate();
    out.finalize();
  }
}
