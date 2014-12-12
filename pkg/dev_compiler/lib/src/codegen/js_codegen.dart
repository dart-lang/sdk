library ddc.src.codegen.js_codegen;

import 'dart:async' show Future;
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/info.dart';
import 'package:ddc/src/utils.dart';
import 'code_generator.dart';

class UnitGenerator extends GeneralizingAstVisitor {
  final Uri uri;
  final Directory directory;
  final String libName;
  final CompilationUnit unit;
  final Map<AstNode, SemanticNode> infoMap;
  final TypeRules rules;
  OutWriter out = null;

  UnitGenerator(this.uri, this.unit, this.directory, this.libName, this.infoMap,
      this.rules);

  void _reportUnimplementedConversions(AstNode node) {
    final info = infoMap[node];
    if (info != null && info.conversion != null) {
      out.write('/* Unimplemented: ');
      out.write('${info.conversion.description}');
      out.write(' */ ');
    }
  }

  String get outputPath {
    var tail = uri.pathSegments.last;
    return directory.path + Platform.pathSeparator + tail + '.js';
  }

  Future generate() {
    out = new OutWriter(outputPath);

    out.write("""
var $libName;
(function ($libName) {
""", 2);
    unit.visitChildren(this);
    out.write("""
})($libName || ($libName = {}));
""", -2);
    return out.close();
  }

  bool isPublic(String name) => !name.startsWith('_');

  visitFunctionTypeAlias(FunctionTypeAlias node) {
    // TODO(vsm): Do we need to record type info the generated code for a
    // typedef?
    _reportUnimplementedConversions(node);
    return node;
  }

  void generateInitializer(
      ClassDeclaration node, List<String> initializedFields) {
    // TODO: generate one field initialzing function per-class and one
    // initializer list function per constructor. Inline if possible.
    var params = (['_this']..addAll(initializedFields)).join(', ');
    out.write("""
var _initializer = (function ($params) {
""", 2);
    var members = node.members;
    for (var member in members) {
      if (member is FieldDeclaration) {
        if (!member.isStatic) {
          for (var field in member.fields.variables) {
            var name = field.name.name;
            var initializer = field.initializer;

            if (initializer != null) {
              // TODO(vsm): Check for conversion.
              out.write("_this.$name = ");
              initializer.accept(this);
              out.write(";\n");
            } else if (!initializedFields.contains(name)) {
              out.write("_this.$name = null;\n");
            }
            if (initializedFields.contains(name)) {
              // TODO: track whether this field is always constructor
              // initialized, if so, don't emit the check for undefined
              out.write("_this.$name = ($name === void 0) ? null : $name;\n");
            }
          }
        }
      }
    }
    out.write("""
});
""", -2);
  }

  Iterable<String> getFieldFormalParameters(ConstructorDeclaration ctor) =>
      ctor.parameters.parameters
          .where((p) => p is FieldFormalParameter)
          .map((FieldFormalParameter p) => p.identifier.name);

  void generateConstructor(ConstructorDeclaration ctor, String name,
      List<String> initializedFields, bool needsInitializer) {
    var fieldParameters = ctor == null ? [] : getFieldFormalParameters(ctor);

    var initializers = ctor == null ?
        {} : new Map.fromIterable(ctor.initializers
            .where((i) => i is ConstructorFieldInitializer), key: (i) =>
            i.fieldName.name);

    out.write("function $name(");
    if (ctor != null) ctor.parameters.accept(this);
    out.write(") {\n");

    if (needsInitializer) {
      out.write("  _initializer(this");

      for (var field in initializedFields) {
        out.write(", ");
        if (fieldParameters.contains(field)) {
          out.write(field);
        } else if (initializers.containsKey(field)) {
          initializers[field].expression.accept(this);
        } else {
          out.write('undefined');
        }
      }
      out.write(");\n");
    }

    if (ctor != null) {
      var superCall = ctor.initializers.firstWhere((i) =>
          i is SuperConstructorInvocation, orElse: () => null);
      if (superCall != null) {
        var superName = superCall.constructorName;
        var args = superCall.argumentList.arguments.map((a) => a.toString());
        var superArgs = (['this']..addAll(args)).join(', ');
        var superSelector = superName == null ? '' : '.$superName';
        out.write("  _super$superSelector.call($superArgs);\n");
      }
    }

//    ctor.body.accept(this);

    out.write("};\n");
  }

  void generateDefaultConstructor(ClassDeclaration node,
      List<String> initializedFields, bool needsInitializer) {
    var name = node.name.name;
    var ctors = node.members.where((m) => m is ConstructorDeclaration);
    var ctor = ctors.firstWhere((m) => m.name == null, orElse: () => null);

    if (ctor == null && ctors.isNotEmpty) {
      out.write(
          """
var constructor = function $name() {
  throw "no default constructor";
}\n""");
    } else {
      out.write("var constructor = ");
      generateConstructor(ctor, name, initializedFields, needsInitializer);
    }
    out.write("dart_runtime.dextend(constructor, _super);\n");
  }

  void generateNamedConstructors(ClassDeclaration node,
      List<String> initializedFields, bool needsInitializer) {
    var ctors = node.members
        .where((m) => m is ConstructorDeclaration && m.name != null);
    for (var ctor in ctors) {
      var name = ctor.name.name;
      out.write("constructor.$name = ");
      generateConstructor(
          ctor, node.name.name, initializedFields, needsInitializer);
      out.write("""
constructor.$name.prototype = constructor.prototype;
""");
    }
  }

  /**
   * Returns a list of fields set via constructors. This forms the parameter
   * list for _initialize().
   */
  Set<String> getConstructorInitializedFields(ClassDeclaration node) {
    var ctors = node.members.where((m) => m is ConstructorDeclaration);
    var fields = new Set<String>();

    for (var ctor in ctors) {
      ConstructorDeclaration c = ctor;

      // initializer list
      var initializers = c.initializers
          .where((i) => i is ConstructorFieldInitializer)
          .map((ConstructorFieldInitializer i) => i.fieldName.name);
      fields.addAll(initializers);

      // field parameters: this.foo
      var parameters = getFieldFormalParameters(ctor);
      fields.addAll(parameters);
    }
    return fields;
  }

  String getSuperclassName(ClassDeclaration node) {
    var element = node.element;
    var superclass = node.element.supertype.element;

    if (superclass.library == element.library) return superclass.name;

    var libName = superclass.library.name;
    if (libName == 'dart.core') libName = 'dart_core';

    return '$libName.${superclass.name}';
  }

  AstNode visitClassDeclaration(ClassDeclaration node) {
    _reportUnimplementedConversions(node);

    var name = node.name.name;
    var superclassName = getSuperclassName(node);

    out.write("""
// Class $name
var $name = (function (_super) {
""", 2);
    // TODO(vsm): Process constructors, fields, and methods properly.
    // Generate default only when needed.
    var needsInitializer = node.members
        .where((m) => m is FieldDeclaration).isNotEmpty;
    var initializedFields = getConstructorInitializedFields(node).toList();
    if (needsInitializer) {
      generateInitializer(node, initializedFields);
    }
    generateDefaultConstructor(node, initializedFields, needsInitializer);
    generateNamedConstructors(node, initializedFields, needsInitializer);
    // TODO(vsm): What should we generate if there is no unnamed constructor
    // for this class?
    out.write("""
  return constructor;
})($superclassName);
""", -2);
    if (isPublic(name)) out.write("$libName.$name = $name;\n");
    out.write("\n");

    return node;
  }

  AstNode visitFunctionDeclaration(FunctionDeclaration node) {
    _reportUnimplementedConversions(node);

    var name = node.name.name;
    assert(node.parent is CompilationUnit);
    out.write("// Function $name: ${node.element.type}\n");
    out.write("function $name(");
    node.functionExpression.parameters.accept(this);
    out.write(") {\n", 2);
    node.functionExpression.body.accept(this);
    out.write("}\n", -2);
    if (isPublic(name)) out.write("$libName.$name = $name;\n");
    out.write("\n");
    return node;
  }

  AstNode visitFunctionExpression(FunctionExpression node) {
    _reportUnimplementedConversions(node);

    // Bind all free variables.
    out.write('/* Unimplemented: bind any free variables. */');

    out.write("function (");
    node.parameters.accept(this);
    out.write(") {\n", 2);
    node.body.accept(this);
    out.write("}\n", -2);
    return node;
  }

  AstNode visitSimpleIdentifier(SimpleIdentifier node) {
    _reportUnimplementedConversions(node);

    out.write(node.name);
    return node;
  }

  AstNode visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _reportUnimplementedConversions(node);

    out.write("return ");
    // TODO(vsm): Check for conversion.
    node.expression.accept(this);
    out.write(";\n");
    return node;
  }

  AstNode visitMethodInvocation(MethodInvocation node) {
    // TODO(vsm): Check dynamic.
    _reportUnimplementedConversions(node);

    writeQualifiedName(node.target, node.methodName);
    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
    return node;
  }

  AstNode visitArgumentList(ArgumentList node) {
    _reportUnimplementedConversions(node);

    // TODO(vsm): Optional parameters.
    var arguments = node.arguments;
    var length = arguments.length;
    if (length > 0) {
      // TODO(vsm): Check for conversion.
      arguments[0].accept(this);
      for (var i = 1; i < length; ++i) {
        out.write(', ');
        // TODO(vsm): Check for conversion.
        arguments[i].accept(this);
      }
    }
    return node;
  }

  AstNode visitFormalParameterList(FormalParameterList node) {
    _reportUnimplementedConversions(node);

    // TODO(vsm): Optional parameters.
    var arguments = node.parameters;
    var length = arguments.length;
    if (length > 0) {
      arguments[0].accept(this);
      for (var i = 1; i < length; ++i) {
        out.write(', ');
        arguments[i].accept(this);
      }
    }
    return node;
  }

  AstNode visitFieldFormalParameter(FieldFormalParameter node) {
    _reportUnimplementedConversions(node);

    out.write(node.identifier.name);
    return node;
  }

  AstNode visitBlockFunctionBody(BlockFunctionBody node) {
    _reportUnimplementedConversions(node);

    var statements = node.block.statements;
    for (var statement in statements) statement.accept(this);
    return node;
  }

  AstNode visitExpressionStatement(ExpressionStatement node) {
    _reportUnimplementedConversions(node);

    node.expression.accept(this);
    out.write(';\n');
    return node;
  }

  AstNode visitReturnStatement(ReturnStatement node) {
    _reportUnimplementedConversions(node);

    if (node.expression == null) {
      out.write('return;\n');
    } else {
      out.write('return ');
      node.expression.accept(this);
      out.write(';\n');
    }
    return node;
  }

  void _generateVariableList(VariableDeclarationList list, bool lazy) {
    // TODO(vsm): Detect when we can avoid wrapping in function.
    var prefix = lazy ? 'function () { return ' : '';
    var postfix = lazy ? '; }()' : '';
    var declarations = list.variables;
    for (var declaration in declarations) {
      var name = declaration.name.name;
      var initializer = declaration.initializer;
      if (initializer == null) {
        out.write('var $name;\n');
      } else {
        out.write('var $name = $prefix');
        initializer.accept(this);
        out.write('$postfix;\n');
      }
    }
  }

  AstNode visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _reportUnimplementedConversions(node);
    _generateVariableList(node.variables, true);
    return node;
  }

  AstNode visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _reportUnimplementedConversions(node);
    _generateVariableList(node.variables, false);
    return node;
  }

  AstNode visitConstructorName(ConstructorName node) {
    _reportUnimplementedConversions(node);

    node.type.name.accept(this);
    if (node.name != null) {
      out.write('.');
      node.name.accept(this);
    }
    return node;
  }

  AstNode visitInstanceCreationExpression(InstanceCreationExpression node) {
    _reportUnimplementedConversions(node);

    out.write('new ');
    node.constructorName.accept(this);
    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
    return node;
  }

  AstNode visitBinaryExpression(BinaryExpression node) {
    _reportUnimplementedConversions(node);

    var op = node.operator;
    var lhs = node.leftOperand;
    var rhs = node.rightOperand;

    var dispatchType = rules.getStaticType(lhs);
    if (rules.isPrimitive(dispatchType)) {
      // TODO(vsm): When do Dart ops not map to JS?
      assert(rules.isPrimitive(rules.getStaticType(rhs)));
      lhs.accept(this);
      out.write(' $op ');
      rhs.accept(this);
    } else {
      // TODO(vsm): Figure out operator calling convention / dispatch.
      out.write('/* Unimplemented binary operator: $node */');
    }

    return node;
  }

  AstNode visitParenthesizedExpression(ParenthesizedExpression node) {
    _reportUnimplementedConversions(node);
    out.write('(');
    node.expression.accept(this);
    out.write(')');
    return node;
  }

  AstNode visitSimpleFormalParameter(SimpleFormalParameter node) {
    _reportUnimplementedConversions(node);

    node.identifier.accept(this);
    return node;
  }
  AstNode visitPrefixedIdentifier(PrefixedIdentifier node) {
    _reportUnimplementedConversions(node);

    final info = infoMap[node];
    if (info != null && info.dynamicInvoke != null) {
      out.write('dart_runtime.dload(');
      node.prefix.accept(this);
      out.write(', "');
      node.identifier.accept(this);
      out.write('")');
    } else {
      node.prefix.accept(this);
      out.write('.');
      node.identifier.accept(this);
    }
    return node;
  }

  AstNode visitIntegerLiteral(IntegerLiteral node) {
    _reportUnimplementedConversions(node);

    out.write('${node.value}');
    return node;
  }

  AstNode visitStringLiteral(StringLiteral node) {
    _reportUnimplementedConversions(node);

    out.write('"${node.stringValue}"');
    return node;
  }

  AstNode visitBooleanLiteral(BooleanLiteral node) {
    _reportUnimplementedConversions(node);

    out.write('${node.value}');
    return node;
  }

  AstNode visitDirective(Directive node) {
    _reportUnimplementedConversions(node);

    return node;
  }

  AstNode visitNode(AstNode node) {
    _reportUnimplementedConversions(node);
    out.write('/* Unimplemented ${node.runtimeType}: $node */');
    return node;
  }

  static const Map<String, String> _builtins = const <String, String>{
    'dart.core': 'dart_core',
  };

  void writeQualifiedName(Expression target, SimpleIdentifier id) {
    if (target != null) {
      target.accept(this);
      out.write('.');
    } else {
      var element = id.staticElement;
      if (element.enclosingElement is CompilationUnitElement) {
        var library = element.enclosingElement.enclosingElement;
        assert(library is LibraryElement);
        var package = library.name;
        var libname = _builtins
            .containsKey(package) ? _builtins[package] : package;
        out.write('$libname.');
      }
    }
    id.accept(this);
  }
}

class JSGenerator extends CodeGenerator {
  JSGenerator(outDir, root, libraries, info, rules)
      : super(outDir, root, libraries, info, rules);

  Future generateUnit(
      Uri uri, CompilationUnit unit, Directory dir, String name) =>
      new UnitGenerator(uri, unit, dir, name, info, rules).generate();
}
