library ddc.src.codegen.js_codegen;

import 'dart:async' show Future;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart'
    show StringToken, Token, TokenType;
import 'package:path/path.dart' as path;

import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/info.dart';
import 'package:ddc/src/utils.dart';
import 'code_generator.dart';

// This must match the optional parameter name used in runtime.js
const String optionalParameters = r'opt$';

class UnitGenerator extends GeneralizingAstVisitor with ConversionVisitor {
  final Uri uri;
  final String outDir;
  final CompilationUnit unit;
  final LibraryInfo libraryInfo;
  final TypeRules rules;
  OutWriter out = null;

  /// The variable for the target of the current `..` cascade expression.
  SimpleIdentifier _cascadeTarget;

  ClassDeclaration currentClass;

  UnitGenerator(CompilationUnitElementImpl unit, this.outDir, this.libraryInfo,
      this.rules)
      : unit = unit.node,
        uri = unit.source.uri;

  String get outputPath => path.join(outDir, '${uri.pathSegments.last}.js');

  Future generate() {
    out = new OutWriter(outputPath);
    var libName = libraryInfo.name;

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

  /// Conversions that we don't handle end up here.
  @override
  void visitConversion(Conversion node) {
    out.write('/* Unimplemented: ');
    out.write('${node.description}');
    out.write(' */ ');
    node.expression.accept(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    out.write('/* Unimplemented: as ${node.type.name.name}. */');
    node.expression.accept(this);
  }

  @override
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

    var initializers = ctor == null ? {} : new Map.fromIterable(
        ctor.initializers.where((i) => i is ConstructorFieldInitializer),
        key: (i) => i.fieldName.name);

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
      var superCall = ctor.initializers.firstWhere(
          (i) => i is SuperConstructorInvocation, orElse: () => null);
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
    var ctors = node.members.where(
        (m) => m is ConstructorDeclaration && m.name != null);
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

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    currentClass = node;
    var name = node.name.name;
    var superclassName = getSuperclassExpression(node);

    out.write("""
// Class $name
var $name = (function (_super) {
""", 2);
    var needsInitializer =
        node.members.where((m) => m is FieldDeclaration).isNotEmpty;
    var initializedFields = getConstructorInitializedFields(node).toList();
    if (needsInitializer) {
      generateInitializer(node, initializedFields);
    }
    generateDefaultConstructor(node, initializedFields, needsInitializer);
    generateNamedConstructors(node, initializedFields, needsInitializer);

    generateProperties(node);

    node.members.where((m) => m is MethodDeclaration).forEach(
        (m) => m.accept(this));

    out.write("""
  return constructor;
})($superclassName);
""", -2);

    if (isPublic(name)) out.write("${libraryInfo.name}.$name = $name;\n");
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
      if (member is MethodDeclaration &&
          !member.isAbstract &&
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
          out.write('"get": function() ');
          property.getter.body.accept(this);
          out.write(',\n');
        }
        if (property.setter != null) {
          out.write('"set": function(');
          property.setter.parameters.accept(this);
          out.write(') ');
          property.setter.body.accept(this);
          out.write(',\n');
        }
        out.write('},\n', -2);
      }

      out.write('});\n', -2);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAbstract || node.isGetter || node.isSetter || node.isStatic) {
      return;
    }

    var name = node.name;

    out.write("\nconstructor.prototype.$name = ");

    out.write("function $name(");
    node.parameters.accept(this);
    out.write(") {\n", 2);
    // TODO(jmesserly): if we don't have argument initializers, we can avoid
    // generating the curly braces here, and let Block handle that. This is
    // also nice for ExpressionFunctionBody, which can avoid some newlines.
    generateArgumentInitializers(node.parameters);
    var body = node.body;
    if (body is BlockFunctionBody) {
      body.block.statements.accept(this);
    } else if (body is ExpressionFunctionBody) {
      out.write('return ');
      body.expression.accept(this);
      out.write(';\n');
    } else {
      assert(body is EmptyFunctionBody);
    }
    out.write("}\n", -2);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var name = node.name.name;
    assert(node.parent is CompilationUnit);
    out.write("// Function $name: ${node.element.type}\n");
    out.write("function $name(");
    var function = node.functionExpression;
    function.parameters.accept(this);
    out.write(") ");
    function.body.accept(this);
    out.write("\n");
    if (isPublic(name)) out.write("${libraryInfo.name}.$name = $name;\n");
    out.write("\n");
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Bind all free variables.
    out.write('/* Unimplemented: bind any free variables. */');

    out.write("function(");
    node.parameters.accept(this);
    out.write(") ");
    node.body.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // TODO(justinfagnani): check that 'this' isn't prepended to static
    // references
    if (node.staticElement != null &&
        currentClass != null &&
        node.parent is! PropertyAccess &&
        node.staticElement.enclosingElement == currentClass.element) {
      out.write('this.');
    }
    out.write(node.name);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    out.write(' = ');
    node.rightHandSide.accept(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    // TODO(jmesserly): generate arrow functions in ES6 mode
    // TODO(jmesserly): generate newlines if it's a long expression?
    out.write("{ return ");
    node.expression.accept(this);
    out.write("; }");
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    out.write('{}');
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (rules.isDynamicCall(node.methodName)) {
      _unimplemented(node);
      return;
    }

    var target = node.isCascaded ? _cascadeTarget : node.target;
    writeQualifiedName(target, node.methodName);
    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
  }

  @override
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

  @override
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

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    // Named parameters are handled as a single object, so we skip individual
    // parameters
    if (node.kind != ParameterKind.NAMED) {
      out.write(node.identifier.name);
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    // Named parameters are handled as a single object, so we skip individual
    // parameters
    if (node.kind != ParameterKind.NAMED) {
      out.write(node.identifier.name);
    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    node.block.accept(this);
  }

  @override
  void visitBlock(Block node) {
    out.write("{\n", 2);
    node.statements.accept(this);
    out.write("}", -2);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
    out.write(';\n');
  }

  @override
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
    var prefix = lazy ? 'function() { return ' : '';
    var postfix = lazy ? '; }()' : '';
    var declarations = list.variables;
    for (var declaration in declarations) {
      var name = declaration.name.name;
      var initializer = declaration.initializer;
      if (initializer == null) {
        out.write('var $name');
      } else {
        out.write('var $name = $prefix');
        initializer.accept(this);
        out.write('$postfix');
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _generateVariableList(node.variables, true);
    out.write(';\n');
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.variables.accept(this);
    out.write(';\n');
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _generateVariableList(node, false);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.name.accept(this);
    if (node.name != null) {
      out.write('.');
      node.name.accept(this);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    out.write('new ');
    node.constructorName.accept(this);
    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
  }

  bool typeIsPrimitiveInJS(DartType t) {
    if (rules.isIntType(t) ||
        rules.isDoubleType(t) ||
        rules.isBoolType(t) ||
        rules.isNumType(t)) return true;
    return false;
  }

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) {
    return typeIsPrimitiveInJS(leftT) && typeIsPrimitiveInJS(rightT);
  }

  bool unaryOperationIsPrimitive(DartType t) {
    return typeIsPrimitiveInJS(t);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    var lhs = node.leftOperand;
    var rhs = node.rightOperand;

    var dispatchType = rules.getStaticType(lhs);
    var otherType = rules.getStaticType(rhs);
    if (binaryOperationIsPrimitive(dispatchType, otherType)) {
      // TODO(vsm): When do Dart ops not map to JS?
      lhs.accept(this);
      out.write(' $op ');
      rhs.accept(this);
    } else {
      // TODO(vsm): Figure out operator calling convention / dispatch.
      out.write('/* Unimplemented binary operator: $node */');
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = rules.getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      // TODO(vsm): When do Dart ops not map to JS?
      expr.accept(this);
      out.write('$op');
    } else {
      // TODO(vsm): Figure out operator calling convention / dispatch.
      out.write('/* Unimplemented postfix operator: $node */');
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = rules.getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      // TODO(vsm): When do Dart ops not map to JS?
      out.write('$op');
      expr.accept(this);
    } else {
      // TODO(vsm): Figure out operator calling convention / dispatch.
      out.write('/* Unimplemented postfix operator: $node */');
    }
  }

  // Cascades can contain [IndexExpression], [MethodInvocation] and
  // [PropertyAccess]. The code generation for those is handled in their
  // respective visit methods.
  @override
  void visitCascadeExpression(CascadeExpression node) {
    // TODO(jmesserly): we need to handle the cascade target better. Ideally
    // it should be assigned to a temp. Note that even simple identifier isn't
    // safe in the face of getters.
    if (node.target is! SimpleIdentifier) {
      _unimplemented(node);
      return;
    }

    var savedCascadeTemp = _cascadeTarget;
    _cascadeTarget = node.target;
    out.write('(', 2);
    _visitNodeList(node.cascadeSections, separator: ',\n');
    if (node.parent is! ExpressionStatement) {
      if (node.cascadeSections.isNotEmpty) out.write(',\n');
      _cascadeTarget.accept(this);
    }
    out.write(')', -2);
    _cascadeTarget = savedCascadeTemp;
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    out.write('(');
    node.expression.accept(this);
    out.write(')');
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.identifier.accept(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _visitGet(node.prefix, node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var target = node.isCascaded ? _cascadeTarget : node.target;
    _visitGet(target, node.propertyName);
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  void _visitGet(Expression target, SimpleIdentifier name) {
    if (rules.isDynamicGet(target)) {
      out.write('dart_runtime.dload(');
      target.accept(this);
      out.write(', "');
      name.accept(this);
      out.write('")');
    } else {
      target.accept(this);
      out.write('.');
      name.accept(this);
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Expression initialization = node.initialization;
    out.write("for (");
    if (initialization != null) {
      initialization.accept(this);
    } else if (node.variables != null) {
      _visitNode(node.variables);
    }
    out.write(";");
    _visitNode(node.condition, prefix: " ");
    out.write(";");
    _visitNodeList(node.updaters, prefix: " ", separator: ", ");
    out.write(") ");
    _visitNode(node.body);
    out.write("\n");
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    out.write('${node.value}');
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // TODO(jmesserly): does this work for other quote styles?
    out.write('"${node.stringValue}"');
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _visitNodeList(node.strings, separator: ' + ');
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _visitNodeList(node.elements, separator: ' + ');
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    out.write('"${node.value}"');
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    // TODO(jmesserly): skip parens if not needed.
    out.write('(');
    node.expression.accept(this);
    // Assuming we implement toString() on our objects, we can avoid calling it
    // in most cases. The potential is builtin types which may differ.
    // For example, Dart's concrete List type does not have the same toString
    // as Array.prototype.toString().
    // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-addition-operator-plus-runtime-semantics-evaluation
    out.write(')');
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    out.write('${node.value}');
  }

  @override
  void visitDirective(Directive node) {}

  @override
  void visitNode(AstNode node) => _unimplemented(node);

  void _unimplemented(AstNode node) {
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
    return _builtins.containsKey(libraryName) ? _builtins[libraryName] :
        libraryName;
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

  /// Safely visit the given node, with an optional prefix or suffix.
  void _visitNode(AstNode node, {String prefix: '', String suffix: ''}) {
    if (node == null) return;

    out.write(prefix);
    node.accept(this);
    out.write(suffix);
  }

  /// Print a list of nodes, with an optional prefix, suffix, and separator.
  void _visitNodeList(NodeList<AstNode> nodes,
      {String prefix: '', String suffix: '', String separator: ''}) {
    if (nodes == null) return;

    int size = nodes.length;
    if (size == 0) return;

    out.write(prefix);
    for (int i = 0; i < size; i++) {
      if (i > 0) out.write(separator);
      nodes[i].accept(this);
    }
    out.write(suffix);
  }

  /// Safely visit the given node, printing the suffix after the node if it is
  /// non-`null`.
  void _visitToken(Token token, {String prefix: '', String suffix: ''}) {
    if (token == null) return;
    out.write(prefix);
    out.write(token.lexeme);
    out.write(suffix);
  }
}

class JSGenerator extends CodeGenerator {
  JSGenerator(
      String outDir, Uri root, List<LibraryInfo> libraries, TypeRules rules)
      : super(outDir, root, libraries, rules);

  Future generateUnit(
      CompilationUnitElementImpl unit, LibraryInfo info, String libraryDir) {
    return new UnitGenerator(unit, libraryDir, info, rules).generate();
  }
}

class _Property {
  MethodDeclaration getter;
  MethodDeclaration setter;
}
