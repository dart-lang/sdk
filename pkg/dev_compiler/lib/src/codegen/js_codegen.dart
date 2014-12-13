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

// This must match the optional parameter name used in runtime.js
const String optionalParameters = r'opt$';

class UnitGenerator extends GeneralizingAstVisitor with ConversionVisitor {
  final Uri uri;
  final Directory directory;
  final String libName;
  final CompilationUnit unit;
  final Map<AstNode, SemanticNode> infoMap;
  final TypeRules rules;
  OutWriter out = null;

  ClassDeclaration currentClass;

  UnitGenerator(this.uri, this.unit, this.directory, this.libName, this.infoMap,
      this.rules);

  void visitConversion(Conversion node) {
    out.write('/* Unimplemented: ');
    out.write('${node.description}');
    out.write(' */ ');
    node.expression.accept(this);
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

  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // TODO(vsm): Do we need to record type info the generated code for a
    // typedef?
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
    out.write(") {");

    var indent = 0;
    if (needsInitializer || ctor != null) {
      indent = 2;
      out.write('\n', indent);
    }

    if (needsInitializer) {
      out.write("_initializer(this");

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
        out.write("_super$superSelector.call($superArgs);\n");
      }

      generateArgumentInitializers(ctor.parameters);
    }

    out.write("};\n", -indent);
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

  void visitClassDeclaration(ClassDeclaration node) {
    currentClass = node;
    var name = node.name.name;
    var superclassName = getSuperclassExpression(node);

    out.write("""
// Class $name
var $name = (function (_super) {
""", 2);
    var needsInitializer = node.members
        .where((m) => m is FieldDeclaration).isNotEmpty;
    var initializedFields = getConstructorInitializedFields(node).toList();
    if (needsInitializer) {
      generateInitializer(node, initializedFields);
    }
    generateDefaultConstructor(node, initializedFields, needsInitializer);
    generateNamedConstructors(node, initializedFields, needsInitializer);

    generateProperties(node);

    node.members
        .where((m) => m is MethodDeclaration)
        .forEach((m) => m.accept(this));

    out.write("""
  return constructor;
})($superclassName);
""", -2);

    if (isPublic(name)) out.write("$libName.$name = $name;\n");
    out.write("\n");
    currentClass = null;
  }

  generateArgumentInitializers(FormalParameterList parameters) {
    for (var param in parameters.parameters) {
      // TODO(justinfagnani): rename identifier if neccessary
      var name = param.identifier.name;

      if (param.kind == ParameterKind.NAMED) {
        out.write('var $name = opt\$.$name === undefined ? ');
        if (param is DefaultFormalParameter && param.defaultValue != null) {
          param.defaultValue.accept(this);
        } else {
          out.write('null');
        }
        out.write(' : opt\$.$name;\n');
      } else if (param.kind == ParameterKind.POSITIONAL) {
        out.write('if ($name !== undefined) { $name = ');
        if (param is DefaultFormalParameter && param.defaultValue != null) {
          param.defaultValue.accept(this);
        } else {
          out.write('null');
        }
        out.write(';}\n');
      }
    }
  }

  void generateProperties(ClassDeclaration node) {
    Map<String, _Property> properties = {};

    for (var member in node.members) {
      if (member is MethodDeclaration && !member.isAbstract &&
          !member.isStatic) {
        if (member.isGetter) {
          var property =
              properties.putIfAbsent(member.name.name, () => new _Property());
          property.getter = member;
        } else if (member.isSetter) {
          var property =
              properties.putIfAbsent(member.name.name, () => new _Property());
          property.setter = member;
        }
      }
    }

    if (properties.isNotEmpty) {
      out.write('\nObject.defineProperties(constructor.prototype, {\n', 2);

      for (var name in properties.keys) {
        var property = properties[name];

        out.write('$name: {\n', 2);

        if (property.getter != null) {
          out.write('"get": function() {\n', 2);
          property.getter.body.accept(this);
          out.write('},\n', -2);
        }
        if (property.setter != null) {
          out.write('"set": function(');
          property.setter.parameters.accept(this);
          out.write(') {\n', 2);
          property.setter.body.accept(this);
          out.write('},\n', -2);
        }
        out.write('},\n', -2);
      }

      out.write('});\n', -2);
    }
  }

  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAbstract || node.isGetter || node.isSetter || node.isStatic) {
      return;
    }

    var name = node.name;

    out.write("\nconstructor.prototype.$name = ");

    out.write("function $name(");
    node.parameters.accept(this);
    out.write(") {\n", 2);
    generateArgumentInitializers(node.parameters);
    node.body.accept(this);
    out.write("}\n", -2);
  }

  void visitFunctionDeclaration(FunctionDeclaration node) {
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
  }

  void visitFunctionExpression(FunctionExpression node) {
    // Bind all free variables.
    out.write('/* Unimplemented: bind any free variables. */');

    out.write("function (");
    node.parameters.accept(this);
    out.write(") {\n", 2);
    node.body.accept(this);
    out.write("}\n", -2);
  }

  void visitSimpleIdentifier(SimpleIdentifier node) {
    // TODO(justinfagnani): check that 'this' isn't prepended to static
    // references
    if (node.staticElement != null && currentClass != null &&
        node.parent is! PropertyAccess &&
        node.staticElement.enclosingElement == currentClass.element) {
      out.write('this.');
    }
    out.write(node.name);
  }

  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    out.write("return ");
    // TODO(vsm): Check for conversion.
    node.expression.accept(this);
    out.write(";\n");
  }

  void visitMethodInvocation(MethodInvocation node) {
    // TODO(vsm): Check dynamic.
    writeQualifiedName(node.target, node.methodName);
    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
  }

  void visitArgumentList(ArgumentList node) {
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
  }

  void visitFormalParameterList(FormalParameterList node) {
    int length = node.parameters.length;
    bool hasOptionalParameters = false;
    bool hasPositionalParameters = false;

    for (int i = 0; i < length; i++) {
      var param = node.parameters[i];
      if (param.kind == ParameterKind.NAMED) {
        hasOptionalParameters = true;
      } else {
        if (hasPositionalParameters) out.write(', ');
        hasPositionalParameters = true;
        param.accept(this);
      }
    }
    if (hasOptionalParameters) {
      if (hasPositionalParameters) out.write(', ');
      out.write(optionalParameters);
    }
  }

  void visitFieldFormalParameter(FieldFormalParameter node) {
    // Named parameters are handled as a single object, so we skip individual
    // parameters
    if (node.kind != ParameterKind.NAMED) {
      out.write(node.identifier.name);
    }
  }

  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    // Named parameters are handled as a single object, so we skip individual
    // parameters
    if (node.kind != ParameterKind.NAMED) {
      out.write(node.identifier.name);
    }
  }

  void visitBlockFunctionBody(BlockFunctionBody node) {
    var statements = node.block.statements;
    for (var statement in statements) statement.accept(this);
  }

  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
    out.write(';\n');
  }

  void visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      out.write('return;\n');
    } else {
      out.write('return ');
      node.expression.accept(this);
      out.write(';\n');
    }
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

  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _generateVariableList(node.variables, true);
  }

  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _generateVariableList(node.variables, false);
  }

  void visitConstructorName(ConstructorName node) {
    node.type.name.accept(this);
    if (node.name != null) {
      out.write('.');
      node.name.accept(this);
    }
  }

  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    out.write('new ');
    node.constructorName.accept(this);
    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
  }

  void visitBinaryExpression(BinaryExpression node) {
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
  }

  void visitParenthesizedExpression(ParenthesizedExpression node) {
    out.write('(');
    node.expression.accept(this);
    out.write(')');
  }

  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.identifier.accept(this);
  }
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
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
  }

  void visitIntegerLiteral(IntegerLiteral node) {
    out.write('${node.value}');
  }

  void visitStringLiteral(StringLiteral node) {
    out.write('"${node.stringValue}"');
  }

  void visitBooleanLiteral(BooleanLiteral node) {
    out.write('${node.value}');
  }

  void visitDirective(Directive node) {
  }

  void visitNode(AstNode node) {
    out.write('/* Unimplemented ${node.runtimeType}: $node */');
  }

  static const Map<String, String> _builtins = const <String, String>{
    'dart.core': 'dart_core',
  };

  String getSuperclassExpression(ClassDeclaration node) {
    var element = node.element;
    var superclass = node.element.supertype.element;

    if (superclass.library == element.library) {
      return superclass.name;
    }
    return '${getLibraryId(superclass.library)}.${superclass.name}';
  }

  String getLibraryId(LibraryElement element) {
    var libraryName = element.name;
    return _builtins.containsKey(libraryName)
        ? _builtins[libraryName]
        : libraryName;
  }

  void writeQualifiedName(Expression target, SimpleIdentifier id) {
    if (target != null) {
      target.accept(this);
      out.write('.');
    } else {
      var element = id.staticElement;
      if (element.enclosingElement is CompilationUnitElement) {
        var library = element.enclosingElement.enclosingElement;
        assert(library is LibraryElement);
        out.write('${getLibraryId(library)}.');
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

class _Property {
  MethodDeclaration getter;
  MethodDeclaration setter;
}
