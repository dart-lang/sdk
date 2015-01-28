library ddc.src.codegen.dart_codegen;

import 'dart:io' show File;

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart' as java_core;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:analyzer/src/generated/source.dart' show UriKind;
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart' as logger;
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart' show SourceFile;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/utils.dart' as utils;
import 'ast_builder.dart';
import 'code_generator.dart' as codegenerator;
import 'reify_coercions.dart' as reifier;

final _log = new logger.Logger('ddc.dartgenerator');

// TODO(leafp): Make this modular in some way.
// Currently this just tries to mimic the logic for when a type is inferred
// in resolver.dart, restricting to the case where we have a single element
// to avoid dealing with computing a common type.
DartType _inferredTypeForVariableDeclarationList(VariableDeclarationList node) {
  TypeName type = node.type;
  if (type == null) {
    NodeList<VariableDeclaration> variables = node.variables;
    if (variables.length == 1) return variables[0].element.type;
  }
  return null;
}

class DdcRuntime {
  Identifier _ddcRuntimeId = AstBuilder.identifierFromString("DDC\$RT");

  Identifier _castId;
  Identifier _typeToTypeId;

  DdcRuntime() {
    _castId = _prefixId(AstBuilder.identifierFromString("cast"));
    _typeToTypeId = _prefixId(AstBuilder.identifierFromString("type"));
  }

  String get importString {
    var name = _ddcRuntimeId;
    var uri = "package:ddc/runtime/dart_logging_runtime.dart";
    return "import '$uri' as $name;";
  }

  Identifier _prefixId(Identifier id) =>
      AstBuilder.prefixedIdentifier(_ddcRuntimeId, id);

  Expression cast(Expression e, TypeName t, [SourceFile file]) {
    var args = <Expression>[e, typeToType(t)];
    if (file != null) {
      final begin = e is AnnotatedNode
          ? (e as AnnotatedNode).firstTokenAfterCommentAndMetadata.offset
          : e.offset;
      if (begin != 0) {
        var loc = file.location(begin).toolString;
        var s = "Cast failed: $loc";
        var msg = AstBuilder.stringLiteral(s);
        args.add(AstBuilder.namedParameter("key", msg));
      }
    }
    return AstBuilder.application(_castId, args);
  }

  Expression typeToType(TypeName t) {
    if (t.typeArguments != null && t.typeArguments.length > 0) {
      var w = AstBuilder.identifierFromString("_");
      var fp = AstBuilder.simpleFormal(w, t);
      var f = AstBuilder.blockFunction(<FormalParameter>[fp], <Statement>[]);
      return AstBuilder.application(_typeToTypeId, <Expression>[f]);
    }
    return t.name;
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
        _log.info("Formatting file $_path ");
        s = d.format(s, uri: _path);
      } catch (e) {
        _log.severe("Failed to format $_path: " + e.toString());
      }
    }
    _log.info("Writing file $_path");
    new File(_path).writeAsStringSync(s);
  }
}

// For every type name to which we add a reference, record the library from
// which it comes so that we may add it to the list of imports.
class UnitImportResolver extends analyzer.GeneralizingAstVisitor<Object>
    with ConversionVisitor<Object> {
  final CompilationUnit unit;
  final Set<LibraryElement> imports = new Set<LibraryElement>();

  UnitImportResolver(this.unit);

  List<LibraryElement> compute() {
    visitCompilationUnit(unit);
    return imports.toList();
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    DartType type = _inferredTypeForVariableDeclarationList(node);
    if (type != null) {
      var element = type.element;
      if (element.library != null) {
        if (!imports.contains(element.library)) {
          if (!element.library.isDartCore) imports.add(element.library);
        }
      }
    }
    return super.visitVariableDeclarationList(node);
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
  void visitNode(AstNode node) {
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
    visitNode(node.name);
    visitNode(node.functionExpression);
    return null;
  }
}

// TODO(leafp) Not sure if this is the right way to generate
// Dart source going forward, but it's a quick way to get started.
class UnitGenerator extends UnitGeneratorCommon {
  CompilationUnit unit;
  final java_core.PrintWriter _out;
  final String outDir;
  List<LibraryElement> extraImports = null;
  final ddc = new DdcRuntime();
  SourceFile _file;

  UnitGenerator(this.unit, java_core.PrintWriter out, String this.outDir)
      : _out = out,
        super(out) {
    UnitImportResolver r = new UnitImportResolver(unit);
    extraImports = r.compute();
    _file = new SourceFile(unit.element.source.contents.data,
        url: unit.element.source.uri);
  }

  void output(String s) => _out.print(s);
  void outputln(String s) => _out.println(s);

  Uri _rewriteDirectiveUri(LibraryElement library, Uri uri) {
    var name = utils.libraryNameFromLibraryElement(library);
    var file = '${uri.pathSegments.last}';
    var absFile = path.join(outDir, path.join(name, file));
    return new Uri(scheme: 'file', path: absFile);
  }

  Uri _rewriteLibraryElementUri(LibraryElement library) {
    if (library.source.uriKind == UriKind.DART_URI) return library.source.uri;
    var newUri = _rewriteDirectiveUri(library, library.source.uri);
    return newUri;
  }

  void _visitLibraryElementUri(LibraryElement library) {
    var uri = _rewriteLibraryElementUri(library);
    output("'$uri'");
  }

  void _visitCompilationUnitElementUri(CompilationUnitElement unit) {
    var library = unit.enclosingElement;
    var uri = _rewriteDirectiveUri(library, unit.source.uri);
    output("'$uri'");
  }

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
    return extraImports.map((lib) {
      var name = utils.libraryNameFromLibraryElement(lib);
      name = canonizeLibraryName(name);
      var uri = _rewriteLibraryElementUri(lib);
      return "import '$uri' as $name;";
    }).toList();
  }

  // Rewrite the import directives with additional library imports
  // covering the inferred types added in as part of this pass.
  void _visitDirectives(String prefix, List<Directive> directives) {
    var ds = splitDirectives(directives);
    var es = buildExtraImportDirectives();
    es.add(ddc.importString);
    visitListWithSeparatorAndPrefix(prefix, ds['library'], " ");
    if (ds['partof'].length == 0) {
      es.forEach((e) => outputln(e));
    } else {
      // TODO(leafp): penance.
      // This is horrible and wrong.  Really we need to add the imports
      // to the library that we are part of if we're in a part.  For now,
      // just skip the imports and hope it all works out.
      visitListWithSeparatorAndPrefix(prefix, ds['partof'], " ");
    }
    visitListWithSeparatorAndPrefix(prefix, ds['import'], " ");
    visitListWithSeparatorAndPrefix(prefix, ds['export'], " ");
    visitListWithSeparatorAndPrefix(prefix, ds['part'], " ");
  }

  @override
  Object visitAsExpression(AsExpression node) {
    var call = ddc.cast(node.expression, node.type, _file);
    call.accept(this);
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    visitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    _visitDirectives(prefix, directives);
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    output("part ");
    _visitCompilationUnitElementUri(node.uriElement);
    output(';');
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    output("import ");
    _visitLibraryElementUri(node.element.importedLibrary);
    if (node.deferredToken != null) {
      output(" deferred");
    }
    visitNodeWithPrefix(" as ", node.prefix);
    visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    output(';');
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    output("export ");
    _visitLibraryElementUri(node.element.exportedLibrary);
    visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    output(';');
    return null;
  }

  // Get a qualified name for a dart type that we are adding
  // by prepending a library name if necessary.
  String _qualifiedTypeName(DartType type) {
    // TODO(leafp) Name function types
    if (type is FunctionType) return null;
    if (type.name != null && type.element != null) {
      String name = type.name;
      if (type is TypeParameterType) return name;
      // type.element is the declaring element
      var element = type.element;
      // If we have a library for it
      if (element.library != null) {
        if (element.library.isDartCore) return name;
        var lib = utils.libraryNameFromLibraryElement(element.library);
        var libname = canonizeLibraryName(lib);
        return "$libname.$name";
      }
    }
    return null;
  }

  // Add in inferred type information where possible.
  Object _addInferredType(VariableDeclarationList node) {
    DartType inferredType = _inferredTypeForVariableDeclarationList(node);
    if (inferredType != null) {
      String name = _qualifiedTypeName(inferredType);
      if (name != null) {
        visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
        if (node.keyword != null && node.keyword.lexeme != "var") {
          visitTokenWithSuffix(node.keyword, " ");
        }
        output("$name ");
        NodeList<VariableDeclaration> variables = node.variables;
        variables[0].accept(this);
        return null;
      }
    }
    return super.visitVariableDeclarationList(node);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    return _addInferredType(node);
  }

  void generate() {
    visitCompilationUnit(unit);
  }
}

class DartGenerator extends codegenerator.CodeGenerator {
  bool _format;
  reifier.UnitCoercionReifier _reifier;

  DartGenerator(String outDir, Uri root, TypeRules rules, this._format)
      : _reifier = new reifier.UnitCoercionReifier(
          new reifier.VariableManager()),
        super(outDir, root, rules);

  void generateUnit(CompilationUnit unit, LibraryInfo info, String libraryDir) {
    var uri = unit.element.source.uri;
    _log.info("Generating unit " + uri.toString());
    FileWriter out = new FileWriter(
        _format, path.join(libraryDir, '${uri.pathSegments.last}'));
    _reifier.reify(unit);
    var unitGen = new UnitGenerator(unit, out, outDir);
    unitGen.generate();
    out.finalize();
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
    _log.info("Emitting original unit " + uri.toString());
    FileWriter out = new FileWriter(
        _format, path.join(libraryDir, '${uri.pathSegments.last}'));
    var unitGen = new EmptyUnitGenerator(unit, out);
    unitGen.generate();
    out.finalize();
  }
}
