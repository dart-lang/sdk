library ddc.src.codegen.js_codegen;

import 'dart:io' show Directory;

import 'package:ddc_analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:ddc_analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:ddc_analyzer/src/generated/constant.dart';
import 'package:ddc_analyzer/src/generated/element.dart';
import 'package:ddc_analyzer/src/generated/scanner.dart'
    show StringToken, Token, TokenType;
import 'package:path/path.dart' as path;

import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/info.dart';
import 'package:ddc/src/report.dart';
import 'package:ddc/src/utils.dart';
import 'code_generator.dart';

// This must match the optional parameter name used in runtime.js
const String optionalParameters = r'opt$';

class JSCodegenVisitor extends GeneralizingAstVisitor with ConversionVisitor {
  final LibraryInfo libraryInfo;
  final TypeRules rules;
  final OutWriter out;
  final String _libraryName;

  /// The variable for the target of the current `..` cascade expression.
  SimpleIdentifier _cascadeTarget;

  ClassDeclaration currentClass;
  ConstantEvaluator _constEvaluator;

  final _exports = <String>[];
  final _lazyFields = <VariableDeclaration>[];
  final _properties = <FunctionDeclaration>[];

  static final int _indexExpressionPrecedence =
      new IndexExpression.forTarget(null, null, null, null).precedence;

  static final int _prefixExpressionPrecedence =
      new PrefixExpression(null, null).precedence;

  JSCodegenVisitor(LibraryInfo libraryInfo, TypeRules rules, this.out)
      : libraryInfo = libraryInfo,
        rules = rules,
        _libraryName = jsLibraryName(libraryInfo.library);

  Element get currentLibrary => libraryInfo.library;

  void generateLibrary(
      Iterable<CompilationUnit> units, CheckerReporter reporter) {
    out.write("""
var $_libraryName;
(function ($_libraryName) {
  'use strict';
""", 2);

    for (var unit in units) {
      // TODO(jmesserly): this is needed because RestrictedTypeRules can send
      // messages to CheckerReporter, for things like missing types.
      // We should probably refactor so this can't happen.

      var source = unit.element.source;
      _constEvaluator = new ConstantEvaluator(source, rules.provider);
      reporter.enterSource(source);
      unit.accept(this);
      reporter.leaveSource();
    }

    if (_exports.isNotEmpty) out.write('// Exports:\n');

    // TODO(jmesserly): make these immutable in JS?
    for (var name in _exports) {
      out.write('${_libraryName}.$name = $name;\n');
    }

    out.write("""
})($_libraryName || ($_libraryName = {}));
""", -2);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _visitNode(node.scriptTag);
    _visitNodeList(node.directives);
    for (var child in node.declarations) {
      // Attempt to group adjacent fields/properties.
      if (child is! TopLevelVariableDeclaration) _flushLazyFields();
      if (child is! FunctionDeclaration) _flushLibraryProperties();

      child.accept(this);
    }
    // Flush any unwritten fields/properties.
    _flushLazyFields();
    _flushLibraryProperties();
  }

  bool isPublic(String name) => !name.startsWith('_');

  /// Conversions that we don't handle end up here.
  @override
  void visitConversion(Conversion node) {
    var from = node.baseType;
    var to = node.convertedType;

    // All Dart number types map to a JS double.
    if (rules.isNumType(from) &&
        (rules.isIntType(to) || rules.isDoubleType(to))) {
      // TODO(jmesserly): a lot of these checks are meaningless, as people use
      // `num` to mean "any kind of number" rather than "could be null".
      // The core libraries especially suffer from this problem, with many of
      // the `num` methods returning `num`.
      if (!rules.isNonNullableType(from) && rules.isNonNullableType(to)) {
        // Converting from a nullable number to a non-nullable number
        // only requires a null check.
        out.write('dart.notNull(');
        node.expression.accept(this);
        out.write(')');
      } else {
        // A no-op in JavaScript.
        node.expression.accept(this);
      }
      return;
    }

    _writeCast(node.expression, to);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _writeCast(node.expression, node.type.type);
  }

  void _writeCast(Expression node, DartType type) {
    out.write('dart.as(');
    node.accept(this);
    out.write(', ');
    _writeTypeName(type);
    out.write(')');
  }

  @override
  void visitIsExpression(IsExpression node) {
    // Generate `is` as `instanceof` or `typeof` depending on the RHS type.
    if (node.notOperator != null) out.write('!');

    var type = node.type.type;
    var lhs = node.expression;
    var typeofName = _jsTypeofName(type);
    if (typeofName != null) {
      if (node.notOperator != null) out.write('(');
      out.write('typeof ');
      // We're going to replace the `is` operator with higher-precedence prefix
      // `typeof` operator, so add parens around the left side if necessary.
      _visitExpression(lhs, _prefixExpressionPrecedence);
      out.write(' == "$typeofName"');
      if (node.notOperator != null) out.write(')');
    } else {
      // Always go through a runtime helper, because implicit interfaces.
      out.write('dart.is(');
      lhs.accept(this);
      out.write(', ');
      _writeTypeName(type);
      out.write(')');
    }
  }

  String _jsTypeofName(DartType t) {
    if (rules.isIntType(t) || rules.isDoubleType(t)) return 'number';
    if (rules.isStringType(t)) return 'string';
    if (rules.isBoolType(t)) return 'boolean';
    return null;
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // TODO(vsm): Do we need to record type info the generated code for a
    // typedef?
  }

  @override
  void visitTypeName(TypeName node) {
    _visitNode(node.name);
    _visitNode(node.typeArguments);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    out.write('\$(');
    _visitNodeList(node.arguments, separator: ', ');
    out.write(')');
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    var name = node.name.name;
    _beginTypeParameters(node.typeParameters, name);
    out.write('class $name extends dart.mixin(');
    _visitNodeList(node.withClause.mixinTypes, separator: ', ');
    out.write(') {}\n\n');
    _endTypeParameters(node.typeParameters, name);
    if (isPublic(name)) _exports.add(name);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    out.write(node.name.name);
  }

  void _beginTypeParameters(TypeParameterList node, String name) {
    if (node == null) return;
    out.write('let ${name}\$ = dart.generic(function(');
    _visitNodeList(node.typeParameters, separator: ', ');
    out.write(') {\n', 2);
  }

  void _endTypeParameters(TypeParameterList node, String name) {
    if (node == null) return;
    // Return the specialized class.
    out.write('return $name;\n');
    out.write('});\n', -2);
    // Construct the "default" version of the generic type for easy interop.
    out.write('let $name = ${name}\$(');
    for (int i = 0, len = node.typeParameters.length; i < len; i++) {
      if (i > 0) out.write(', ');
      // TODO(jmesserly): we may not want this to be `dynamic` if the generic
      // has a lower bound, e.g. `<T extends SomeType>`.
      // https://github.com/dart-lang/dart-dev-compiler/issues/38
      out.write('dynamic');
    }
    out.write(');\n');
    // TODO(jmesserly): is it worth exporting both names? Alternatively we could
    // put the generic type constructor on the <dynamic> instance.
    if (isPublic(name)) _exports.add('${name}\$');
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    currentClass = node;

    var name = node.name.name;
    _beginTypeParameters(node.typeParameters, name);
    out.write('class $name extends ');

    if (node.withClause != null) {
      out.write('dart.mixin(');
    }
    if (node.extendsClause != null) {
      _visitNode(node.extendsClause.superclass);
    } else {
      out.write('dart.Object');
    }
    if (node.withClause != null) {
      _visitNodeList(node.withClause.mixinTypes, prefix: ', ', separator: ', ');
      out.write(')');
    }

    out.write(' {\n', 2);

    var ctors = new List<ConstructorDeclaration>();
    var fields = new List<FieldDeclaration>();
    var staticFields = new List<FieldDeclaration>();
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        ctors.add(member);
      } else if (member is FieldDeclaration) {
        (member.isStatic ? staticFields : fields).add(member);
      }
    }

    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    if (ctors.isEmpty && !node.element.type.isObject) {
      _generateImplicitConstructor(node, name, fields);
    }

    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        _generateConstructor(member, name, fields);
      } else if (member is MethodDeclaration) {
        member.accept(this);
      }
    }

    out.write('}\n', -2);

    if (isPublic(name)) _exports.add(name);

    // Named constructors
    for (ConstructorDeclaration member in ctors) {
      if (member.name != null) {
        var ctorName = member.name.name;
        out.write('dart.defineNamedConstructor($name, "$ctorName");\n');
      }
    }

    // Static fields
    var lazyStatics = <VariableDeclaration>[];
    for (FieldDeclaration member in staticFields) {
      for (VariableDeclaration field in member.fields.variables) {
        var prefix = '$name.${field.name.name}';
        if (field.initializer == null) {
          out.write('$prefix = null;\n');
        } else if (field.isConst || _isFieldInitConstant(field)) {
          out.write('$prefix = ');
          field.initializer.accept(this);
          out.write(';\n');
        } else {
          lazyStatics.add(field);
        }
      }
    }
    _writeLazyFields(name, lazyStatics);

    // Support for adapting dart:core Iterator/Iterable to ES6 versions.
    // This lets them use for-of loops transparently.
    // https://github.com/lukehoban/es6features#iterators--forof
    // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-iterable-interface
    // TODO(jmesserly): put this straight in the class as an instance method,
    // once V8 supports symbols for method names: `[Symbol.iterator]() { ... }`.
    if (node.element.library.isDartCore && node.element.name == 'Iterable') {
      out.write('''
$name.prototype[Symbol.iterator] = function() {
  var iterator = this.iterator;
  return {
    next: function() {
      var done = iterator.moveNext();
      return { done: done, current: done ? void 0 : iterator.current };
    }
  };
};
''');
    }

    _endTypeParameters(node.typeParameters, name);

    out.write('\n');
    currentClass = null;
  }

  /// Generates the implicit default constructor for class C of the form
  /// `C() : super() {}`.
  void _generateImplicitConstructor(
      ClassDeclaration node, String name, List<FieldDeclaration> fields) {
    // If we don't have a method body, skip this.
    if (fields.isEmpty) return;

    out.write('$name() {\n', 2);
    _initializeFields(fields);
    _superConstructorCall(node);
    out.write('}\n', -2);
  }

  void _generateConstructor(ConstructorDeclaration node, String className,
      List<FieldDeclaration> fields) {
    if (node.externalKeyword != null) {
      out.write('/* Unimplemented $node */\n');
      return;
    }

    // We generate constructors as initializer methods in the class;
    // this allows use of `super` for instance methods/properties.
    // It also avoids V8 restrictions on `super` in default constructors.
    out.write(className);
    if (node.name != null) {
      out.write('\$${node.name.name}');
    }
    out.write('(');
    _visitNode(node.parameters);
    out.write(') {\n', 2);
    _generateConstructorBody(node, fields);
    out.write('}\n', -2);
  }

  void _generateConstructorBody(
      ConstructorDeclaration node, List<FieldDeclaration> fields) {
    // Wacky factory redirecting constructors: factory Foo.q(x, y) = Bar.baz;
    if (node.redirectedConstructor != null) {
      out.write('return new ');
      node.redirectedConstructor.accept(this);
      out.write('(');
      _visitNode(node.parameters);
      out.write(');\n');
      return;
    }

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    _generateArgumentInitializers(node.parameters);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers.firstWhere(
        (i) => i is RedirectingConstructorInvocation, orElse: () => null);

    if (redirectCall != null) {
      redirectCall.accept(this);
      return;
    }

    // Initializers only run for non-factory constructors.
    if (node.factoryKeyword == null) {
      // Generate field initializers.
      // These are expanded into each non-redirecting constructor.
      // In the future we may want to create an initializer function if we have
      // multiple constructors, but it needs to be balanced against readability.
      _initializeFields(fields, node.parameters, node.initializers);

      var superCall = node.initializers.firstWhere(
          (i) => i is SuperConstructorInvocation, orElse: () => null);

      // If no superinitializer is provided, an implicit superinitializer of the
      // form `super()` is added at the end of the initializer list, unless the
      // enclosing class is class Object.
      if (superCall == null) {
        _superConstructorCall(node.parent);
      } else {
        _superConstructorCall(node.parent, node.name, superCall.constructorName,
            superCall.argumentList);
      }
    }

    var body = node.body;
    if (body is BlockFunctionBody) {
      body.block.statements.accept(this);
    } else if (body is ExpressionFunctionBody) {
      _visitNode(body.expression, prefix: 'return ', suffix: ';\n');
    } else {
      assert(body is EmptyFunctionBody);
    }
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var parent = node.parent as ConstructorDeclaration;

    if (parent.name != null) {
      out.write(parent.name.name);
    } else {
      _writeTypeName((parent.parent as ClassDeclaration).element.type);
    }
    out.write('.call(this');
    _visitArgumentsWithCommaPrefix(node.argumentList);
    out.write(');\n');
  }

  void _superConstructorCall(ClassDeclaration clazz, [SimpleIdentifier ctorName,
      SimpleIdentifier superCtorName, ArgumentList args]) {
    var element = clazz.element;
    if (superCtorName == null &&
        (element.type.isObject || element.supertype.isObject)) {
      return;
    }

    var supertypeName = element.supertype.name;
    out.write('super.$supertypeName');
    if (superCtorName != null) out.write('\$${superCtorName.name}');
    out.write('(');
    _visitNode(args);
    out.write(');\n');
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  void _initializeFields(List<FieldDeclaration> fields,
      [FormalParameterList parameters,
      NodeList<ConstructorInitializer> initializers]) {

    // Run field initializers if they can have side-effects.
    var unsetFields = new Map<String, VariableDeclaration>();
    for (var declaration in fields) {
      for (var field in declaration.fields.variables) {
        if (_isFieldInitConstant(field)) {
          unsetFields[field.name.name] = field;
        } else {
          _visitNode(field, suffix: ';\n');
        }
      }
    }

    // Initialize fields from `this.fieldName` parameters.
    if (parameters != null) {
      for (var p in parameters.parameters) {
        if (p is DefaultFormalParameter) p = p.parameter;
        if (p is FieldFormalParameter) {
          var name = p.identifier.name;
          out.write('this.$name = $name;\n');
          unsetFields.remove(name);
        }
      }
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (initializers != null) {
      for (var init in initializers) {
        if (init is ConstructorFieldInitializer) {
          init.fieldName.accept(this);
          out.write(' = ');
          init.expression.accept(this);
          out.write(';\n');
          unsetFields.remove(init.fieldName.name);
        }
      }
    }

    // Initialize all remaining fields
    unsetFields.forEach((name, field) {
      out.write('this.$name = ');
      var expression = field.initializer;
      if (expression != null) {
        expression.accept(this);
      } else {
        var type = rules.elementType(field.element);
        if (rules.maybeNonNullableType(type)) {
          out.write('dart.as(null, ');
          _writeTypeName(type);
          out.write(')');
        } else {
          out.write('null');
        }
      }
      out.write(';\n');
    });
  }

  FormalParameterList _parametersOf(node) {
    if (node is MethodDeclaration) return node.parameters;
    if (node is FunctionDeclaration) node = node.functionExpression;
    if (node is FunctionExpression) return node.parameters;
    return null;
  }

  bool _hasArgumentInitializers(FormalParameterList parameters) {
    if (parameters == null) return false;
    return parameters.parameters.any((p) => p.kind != ParameterKind.REQUIRED);
  }

  void _generateArgumentInitializers(FormalParameterList parameters) {
    if (parameters == null) return;
    for (var param in parameters.parameters) {
      // TODO(justinfagnani): rename identifier if necessary
      var name = param.identifier.name;

      if (param.kind == ParameterKind.NAMED) {
        out.write('let $name = opt\$.$name === undefined ? ');
        if (param is DefaultFormalParameter && param.defaultValue != null) {
          param.defaultValue.accept(this);
        } else {
          out.write('null');
        }
        out.write(' : opt\$.$name;\n');
      } else if (param.kind == ParameterKind.POSITIONAL) {
        out.write('if ($name === undefined) $name = ');
        if (param is DefaultFormalParameter && param.defaultValue != null) {
          param.defaultValue.accept(this);
        } else {
          out.write('null');
        }
        out.write(';\n');
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAbstract) return;
    if (node.externalKeyword != null) {
      out.write('/* Unimplemented $node */\n');
      return;
    }

    if (node.isStatic) {
      out.write('static ');
    }
    if (node.isGetter) {
      out.write('get ');
    } else if (node.isSetter) {
      out.write('set ');
    }

    var name = _canonicalMethodName(node.name.name);
    out.write('$name(');
    _visitNode(node.parameters);
    out.write(') ');
    _visitNode(node.body);
    out.write('\n');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.parent is CompilationUnit);

    if (node.externalKeyword != null) {
      // TODO(jmesserly): the toString visitor in Analyzer doesn't include the
      // external keyword for FunctionDeclaration.
      out.write('/* Unimplemented external $node */\n');
      return;
    }

    if (node.isGetter || node.isSetter) {
      // Add these later so we can use getter/setter syntax.
      _properties.add(node);
    } else {
      _flushLibraryProperties();
      _writeFunctionDeclaration(node);
    }
  }

  void _writeFunctionDeclaration(FunctionDeclaration node) {
    var name = node.name.name;

    if (node.isGetter) {
      out.write('get ');
    } else if (node.isSetter) {
      out.write('set ');
    } else {
      out.write("// Function $name: ${node.element.type}\n");
      out.write('function ');
    }

    out.write('$name');
    node.functionExpression.accept(this);

    if (!node.isGetter && !node.isSetter) {
      out.write('\n');
      if (isPublic(name)) _exports.add(name);
      out.write('\n');
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      out.write('(');
      _visitNode(node.parameters);
      out.write(') ');
      node.body.accept(this);
    } else {
      var bindThis = _needsBindThis(node.body);
      if (bindThis) out.write("(");
      out.write("(");
      _visitNode(node.parameters);
      out.write(") => ");
      var body = node.body;
      if (body is ExpressionFunctionBody) body = body.expression;
      body.accept(this);
      if (bindThis) out.write(").bind(this)");
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      out.write('/* Unimplemented function get/set statement: $node */');
      return;
    }

    var name = func.name.name;
    out.write("// Function $name: ${func.element.type}\n");
    out.write('function $name');
    func.functionExpression.accept(this);
    out.write('\n');
  }

  /// Writes a simple identifier. This can handle implicit `this` as well as
  /// going through the qualified library name if necessary.
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var e = node.staticElement;
    if (e.enclosingElement is CompilationUnitElement &&
        (e.library != libraryInfo.library || _needsModuleGetter(e))) {
      out.write('${jsLibraryName(e.library)}.');
    } else if (currentClass != null && _needsImplicitThis(e)) {
      out.write('this.');
    }
    out.write(node.name);
  }

  void _writeTypeName(DartType type) {
    var name = type.name;
    var lib = type.element.library;
    if (name == '') {
      // TODO(jmesserly): remove when we're using coercion reifier.
      out.write('/* Unimplemented type $type */');
      return;
    }

    if (lib != currentLibrary && lib != null) {
      out.write(jsLibraryName(lib));
      out.write('.');
    }
    out.write(name);

    if (type is ParameterizedType) {
      // TODO(jmesserly): this is a workaround for an analyzer bug, see:
      // https://github.com/dart-lang/dart-dev-compiler/commit/a212d59ad046085a626dd8d16881cdb8e8b9c3fa
      if (type is! FunctionType || type.element is FunctionTypeAlias) {
        var args = type.typeArguments;
        if (args.any((a) => a != rules.provider.dynamicType)) {
          out.write('\$(');
          for (var arg in args) {
            if (arg != args.first) out.write(', ');
            _writeTypeName(arg);
          }
          out.write(')');
        }
      }
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var lhs = node.leftHandSide;
    var rhs = node.rightHandSide;
    if (lhs is IndexExpression) {
      var target = _getTarget(lhs);
      if (rules.isDynamicTarget(target)) {
        out.write('dart.dsetindex(');
        target.accept(this);
        out.write(', ');
        lhs.index.accept(this);
        out.write(', ');
        rhs.accept(this);
        out.write(')');
      } else {
        target.accept(this);
        out.write('.set(');
        lhs.index.accept(this);
        out.write(', ');
        rhs.accept(this);
        out.write(')');
      }
      return;
    }

    if (lhs is PropertyAccess) {
      var target = _getTarget(lhs);
      if (rules.isDynamicTarget(target)) {
        out.write('dart.dput(');
        target.accept(this);
        out.write(', "${lhs.propertyName.name}", ');
        rhs.accept(this);
        out.write(')');
        return;
      }
    }

    lhs.accept(this);
    out.write(' = ');
    rhs.accept(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var parameters = _parametersOf(node.parent);
    var initArgs = parameters != null && _hasArgumentInitializers(parameters);
    if (initArgs) {
      out.write('{\n', 2);
      _generateArgumentInitializers(parameters);
    } else {
      out.write('{ ');
    }
    out.write('return ');
    node.expression.accept(this);
    if (initArgs) {
      out.write('\n}', -2);
    } else {
      out.write('; }');
    }
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    out.write('{}');
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    out.write('{\n', 2);
    _generateArgumentInitializers(_parametersOf(node.parent));
    _visitNodeList(node.block.statements);
    out.write('}', -2);
  }

  @override
  void visitBlock(Block node) {
    out.write("{\n", 2);
    node.statements.accept(this);
    out.write("}\n", -2);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var target = node.isCascaded ? _cascadeTarget : node.target;

    if (rules.isDynamicCall(node.methodName)) {
      if (target != null) {
        out.write('dart.dinvoke(');
        target.accept(this);
        out.write(', "${node.methodName.name}"');
      } else {
        out.write('dart.dinvokef(');
        node.methodName.accept(this);
      }

      _visitArgumentsWithCommaPrefix(node.argumentList);
      out.write(')');
      return;
    }

    // TODO(jmesserly): if this resolves to a getter returning a function with
    // a call method, we don't generate the `.call` correctly.
    if (target != null) {
      target.accept(this);
      out.write('.${node.methodName.name}');
    } else {
      node.methodName.accept(this);
    }

    out.write('(');
    node.argumentList.accept(this);
    out.write(')');
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (rules.isDynamicCall(node.function)) {
      out.write('dart.dinvokef(');
      node.function.accept(this);
      _visitArgumentsWithCommaPrefix(node.argumentList);
      out.write(')');
    } else {
      node.function.accept(this);
      out.write('(');
      node.argumentList.accept(this);
      out.write(')');
    }
  }

  /// Writes an argument list. This does not write the parens, because sometimes
  /// a parameter will need to be added before the start of the list, so
  /// writing parens is the responsibility of the parent node.
  @override
  void visitArgumentList(ArgumentList node) {
    var args = node.arguments;

    bool hasNamed = false;
    for (int i = 0; i < args.length; i++) {
      if (i > 0) out.write(', ');

      var arg = args[i];
      if (arg is NamedExpression) {
        if (!hasNamed) out.write('{');
        hasNamed = true;
      }
      arg.accept(this);
    }
    if (hasNamed) out.write('}');
  }

  void _visitArgumentsWithCommaPrefix(ArgumentList node) {
    if (node == null) return;
    if (node.arguments.isNotEmpty) out.write(', ');
    visitArgumentList(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    assert(node.parent is ArgumentList);
    node.name.accept(this);
    out.write(' ');
    node.expression.accept(this);
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
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
    out.write(';\n');
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    out.write(';\n');
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    // TODO(jmesserly): only emit in checked mode.
    _visitNode(node.condition, prefix: 'dart.assert(', suffix: ');\n');
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    out.write('return');
    _visitNode(node.expression, prefix: ' ');
    out.write(';\n');
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var field in node.variables.variables) {
      var name = field.name.name;
      if (field.isConst) {
        // constant fields don't change, so we can generate them as `let`
        // but add them to the module's exports
        _visitNode(field, prefix: 'let ', suffix: ';\n');
        if (isPublic(name)) _exports.add(name);
      } else if (_isFieldInitConstant(field)) {
        _visitNode(field, suffix: ';\n');
      } else {
        _lazyFields.add(field);
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _visitNodeList(node.variables, prefix: 'let ', separator: ', ');
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    node.name.accept(this);
    out.write(' = ');
    if (node.initializer != null) {
      node.initializer.accept(this);
    } else {
      // explicitly initialize to null, so we don't need to worry about
      // `undefined`.
      // TODO(jmesserly): do this only for vars that aren't definitely assigned.
      out.write('null');
    }
  }

  void _flushLazyFields() {
    if (_lazyFields.isEmpty) return;

    _writeLazyFields(_libraryName, _lazyFields);
    out.write('\n');

    _lazyFields.clear();
  }

  void _writeLazyFields(String objExpr, List<VariableDeclaration> fields) {
    if (fields.isEmpty) return;

    out.write('dart.defineLazyProperties($objExpr, {\n', 2);
    for (var node in fields) {
      var name = node.name.name;
      out.write('get $name() { return ');
      node.initializer.accept(this);
      out.write(' },\n');
      // TODO(jmesserly): we're using a dummy setter to indicate writable.
      if (!node.isFinal) out.write('set $name(x) {},\n');
    }
    out.write('});\n', -2);
  }

  void _flushLibraryProperties() {
    if (_properties.isEmpty) return;

    out.write('dart.copyProperties($_libraryName, {\n', 2);
    for (var node in _properties) {
      _writeFunctionDeclaration(node);
      out.write(',\n');
    }
    out.write('});\n\n', -2);

    _properties.clear();
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitNode(node.variables);
    out.write(';\n');
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

  /// True if this type is built-in to JS, and we use the values unwrapped.
  /// For these types we generate a calling convention via static
  /// "extension methods". This allows types to be extended without adding
  /// extensions directly on the prototype.
  bool _isJSBuiltinType(DartType t) =>
      rules.isNumType(t) || rules.isStringType(t) || rules.isBoolType(t);

  bool typeIsPrimitiveInJS(DartType t) => rules.isIntType(t) ||
      rules.isDoubleType(t) ||
      rules.isBoolType(t) ||
      rules.isNumType(t);

  bool typeIsNonNullablePrimitiveInJS(DartType t) =>
      typeIsPrimitiveInJS(t) && rules.isNonNullableType(t);

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) =>
      typeIsPrimitiveInJS(leftT) && typeIsPrimitiveInJS(rightT);

  bool unaryOperationIsPrimitive(DartType t) => typeIsPrimitiveInJS(t);

  void notNull(Expression expr) {
    var type = rules.getStaticType(expr);
    if (rules.isNonNullableType(type)) {
      expr.accept(this);
    } else {
      out.write('dart.notNull(');
      expr.accept(this);
      out.write(')');
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    var lhs = node.leftOperand;
    var rhs = node.rightOperand;

    var dispatchType = rules.getStaticType(lhs);
    var otherType = rules.getStaticType(rhs);

    if (op.type.isEqualityOperator) {
      // If we statically know LHS or RHS is null we can generate a clean check.
      // We can also do this if the left hand side is a primitive type, because
      // we know then it doesn't have an overridden.
      if (_isNull(lhs) || _isNull(rhs) || typeIsPrimitiveInJS(dispatchType)) {
        lhs.accept(this);
        // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-strict-equality-comparison
        out.write(op.type == TokenType.EQ_EQ ? ' === ' : ' !== ');
        rhs.accept(this);
      } else {
        // TODO(jmesserly): it would be nice to use just "equals", perhaps
        // by importing this name.
        if (op.type == TokenType.BANG_EQ) out.write('!');
        out.write('dart.equals(');
        lhs.accept(this);
        out.write(', ');
        rhs.accept(this);
        out.write(')');
      }
    } else if (binaryOperationIsPrimitive(dispatchType, otherType)) {
      // special cases where we inline the operation
      // these values are assumed to be non-null (determined by the checker)
      // TODO(jmesserly): it would be nice to just inline the method from core,
      // instead of special cases here.

      if (op.type == TokenType.TILDE_SLASH) {
        // `a ~/ b` is equivalent to `(a / b).truncate()`
        out.write('(');
        notNull(lhs);
        out.write(' / ');
        notNull(rhs);
        out.write(').truncate()');
      } else {
        // TODO(vsm): When do Dart ops not map to JS?
        notNull(lhs);
        out.write(' $op ');
        notNull(rhs);
      }
    } else if (rules.isDynamicTarget(lhs)) {
      // dynamic dispatch
      out.write('dart.dbinary(');
      lhs.accept(this);
      out.write(', "${op.lexeme}", ');
      rhs.accept(this);
      out.write(')');
    } else if (_isJSBuiltinType(dispatchType)) {
      // TODO(jmesserly): we'd get better readability from the static-dispatch
      // pattern below. Consider:
      //
      //     "hello"['+']"world"
      // vs
      //     core.String['+']("hello", "world")
      //
      // Infix notation is much more readable, which is a bit part of why
      // C# added its extension methods feature. However this would require
      // adding these methods to String.prototype/Number.prototype in JS.
      _writeTypeName(dispatchType);
      out.write(_canonicalMethodInvoke(op.lexeme));
      out.write('(');
      lhs.accept(this);
      out.write(', ');
      rhs.accept(this);
      out.write(')');
    } else {
      // Generic static-dispatch, user-defined operator code path.

      // We're going to replace the operator with high-precedence "." or "[]",
      // so add parens around the left side if necessary.
      _visitExpression(lhs, _indexExpressionPrecedence);
      out.write(_canonicalMethodInvoke(op.lexeme));
      out.write('(');
      rhs.accept(this);
      out.write(')');
    }
  }

  bool _isNull(Expression expr) => expr is NullLiteral;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = rules.getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      // TODO(vsm): When do Dart ops not map to JS?
      notNull(expr);
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
      notNull(expr);
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
    var savedCascadeTemp = _cascadeTarget;

    var parent = node.parent;
    var grandparent = parent.parent;
    if (_isStateless(node.target, node)) {
      // Special case: target is stateless, so we can just reuse it.
      _cascadeTarget = node.target;

      if (parent is ExpressionStatement) {
        _visitNodeList(node.cascadeSections, separator: ';\n');
      } else {
        // Use comma expression. For example:
        //    (sb.write(1), sb.write(2), sb)
        out.write('(');
        _visitNodeList(node.cascadeSections, separator: ', ', suffix: ', ');
        _cascadeTarget.accept(this);
        out.write(')');
      }
    } else if (parent is AssignmentExpression &&
        grandparent is ExpressionStatement &&
        _isStateless(parent.leftHandSide, node)) {

      // Special case: assignment to a variable in a statement.
      // We can reuse the variable to desugar it:
      //    result = []..length = length;
      // becomes:
      //    result = [];
      //    result.length = length;
      _cascadeTarget = parent.leftHandSide;
      node.target.accept(this);
      out.write(';\n');
      _visitNodeList(node.cascadeSections, separator: ';\n');
    } else if (parent is VariableDeclaration &&
        grandparent is VariableDeclarationList &&
        grandparent.variables.last == parent) {

      // Special case: variable declaration
      // We can reuse the variable to desugar it:
      //    var result = []..length = length;
      // becomes:
      //    var result = [];
      //    result.length = length;
      _cascadeTarget = parent.name;
      node.target.accept(this);
      out.write(';\n');
      _visitNodeList(node.cascadeSections, separator: ';\n');
    } else {
      // In the general case we need to capture the target expression into
      // a temporary. This uses a lambda to get a temporary scope, and it also
      // remains valid in an expression context.
      // TODO(jmesserly): need a better way to handle temps.
      // TODO(jmesserly): special case for parent is ExpressionStatement?
      _cascadeTarget =
          new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '_', 0));
      _cascadeTarget.staticElement =
          new LocalVariableElementImpl.forNode(_cascadeTarget);
      _cascadeTarget.staticType = node.target.staticType;

      out.write('((${_cascadeTarget.name}) => {\n', 2);
      _visitNodeList(node.cascadeSections, separator: ';\n', suffix: ';\n');
      if (node.parent is! ExpressionStatement) {
        out.write('return ${_cascadeTarget.name};\n');
      }
      out.write('})', -2);
      if (_needsBindThis(node.cascadeSections)) out.write('.bind(this)');
      out.write('(');
      node.target.accept(this);
      out.write(')');
    }

    _cascadeTarget = savedCascadeTemp;
  }

  /// True is the expression can be evaluated multiple times without causing
  /// code execution. This is true for final fields. This can be true for local
  /// variables, if:
  /// * they are not assigned within the [context].
  /// * they are not assigned in a function closure anywhere.
  bool _isStateless(Expression node, [AstNode context]) {
    if (node is SimpleIdentifier) {
      var e = node.staticElement;
      if (e is PropertyAccessorElement) e = e.variable;
      if (e is VariableElementImpl && !e.isSynthetic) {
        if (e.isFinal) return true;
        if (e is LocalVariableElementImpl || e is ParameterElementImpl) {
          // make sure the local isn't mutated in the context.
          return !_isPotentiallyMutated(e, context);
        }
      }
    }
    return false;
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
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.identifier.accept(this);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    out.write('this');
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    out.write('super');
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.staticElement is PrefixElement) {
      node.identifier.accept(this);
    } else {
      _visitGet(node.prefix, node.identifier);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _visitGet(_getTarget(node), node.propertyName);
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  void _visitGet(Expression target, SimpleIdentifier name) {
    if (rules.isDynamicTarget(target)) {
      // TODO(jmesserly): this won't work if we're left hand side of assignment.
      out.write('dart.dload(');
      target.accept(this);
      out.write(', "${name.name}")');
    } else {
      target.accept(this);
      out.write('.${name.name}');
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var target = _getTarget(node);
    if (rules.isDynamicTarget(target)) {
      out.write('dart.dindex(');
      target.accept(this);
      out.write(', ');
      node.index.accept(this);
      out.write(')');
    } else {
      target.accept(this);
      out.write(_canonicalMethodInvoke('[]'));
      out.write('(');
      node.index.accept(this);
      out.write(')');
    }
  }

  /// Gets the target of a [PropertyAccess] or [IndexExpression].
  /// Those two nodes are special because they're both allowed on left side of
  /// an assignment expression and cascades.
  Expression _getTarget(node) {
    assert(node is IndexExpression || node is PropertyAccess);
    return node.isCascaded ? _cascadeTarget : node.target;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    out.write(' ? ');
    node.thenExpression.accept(this);
    out.write(' : ');
    node.elseExpression.accept(this);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (node.parent is ExpressionStatement) {
      out.write('throw ');
      node.expression.accept(this);
    } else {
      // TODO(jmesserly): move this into runtime helper?
      out.write('(function(e) { throw e }(');
      node.expression.accept(this);
      out.write(')');
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    out.write('if (');
    node.condition.accept(this);
    out.write(') ');
    var then = node.thenStatement;
    if (then is Block) {
      out.write('{\n', 2);
      _visitNodeList((then as Block).statements);
      out.write('}', -2);
    } else {
      _visitNode(then);
    }
    var elseClause = node.elseStatement;
    if (elseClause != null) {
      out.write(' else ');
      elseClause.accept(this);
    } else if (then is Block) {
      out.write('\n');
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
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    out.write("while (");
    _visitNode(node.condition);
    out.write(") ");
    _visitNode(node.body);
  }

  @override
  void visitDoStatement(DoStatement node) {
    out.write("do ");
    _visitNode(node.body);
    if (node.body is! Block) out.write(' ');
    out.write("while (");
    _visitNode(node.condition);
    out.write(");\n");
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    out.write('for (');
    if (node.loopVariable != null) {
      _visitNode(node.loopVariable.identifier, prefix: 'let ');
    } else {
      _visitNode(node.identifier);
    }
    out.write(' of ');
    _visitNode(node.iterable);
    out.write(') ');
    _visitNode(node.body);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    out.write("break");
    _visitNode(node.label, prefix: " ");
    out.write(";\n");
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    out.write("continue");
    _visitNode(node.label, prefix: " ");
    out.write(";\n");
  }

  @override
  void visitTryStatement(TryStatement node) {
    out.write('try ');
    _visitNode(node.body);
    if (node.body is! Block) out.write(' ');

    var clauses = node.catchClauses;
    if (clauses != null && clauses.isNotEmpty) {
      // TODO(jmesserly): need a better way to get a temporary variable.
      // This could incorrectly shadow a user's name.
      var name = '\$e';

      if (clauses.length == 1) {
        // Special case for a single catch.
        var clause = clauses.single;
        if (clause.exceptionParameter != null) {
          name = clause.exceptionParameter.name;
        }
      }

      out.write('catch ($name) {\n', 2);
      for (var clause in clauses) {
        _visitCatchClause(clause, name);
      }
      out.write('}\n', -2);
    }
    _visitNode(node.finallyBlock, prefix: 'finally ');
  }

  void _visitCatchClause(CatchClause node, String varName) {
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        out.write('if (dart.is($varName, ');
        _writeTypeName(node.exceptionType.type);
        out.write(')) {\n', 2);
      }

      var name = node.exceptionParameter;
      if (name != null && name.name != varName) {
        out.write('let $name = $varName;\n');
      }

      if (node.stackTraceParameter != null) {
        var stackName = node.stackTraceParameter.name;
        out.write('let $stackName = dart.stackTrace($name);\n');
      }
    }

    // If we can, avoid generating a nested { ... } block.
    var body = node.body;
    if (body is Block) {
      body.statements.accept(this);
    } else {
      body.accept(this);
    }

    if (node.exceptionType != null) out.write('}\n', -2);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _visitNodeList(node.labels, separator: " ", suffix: " ");
    out.write("case ");
    _visitNode(node.expression);
    out.write(":\n", 2);
    _visitNodeList(node.statements);
    out.write('', -2);
    // TODO(jmesserly): make sure we are statically checking fall through
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _visitNodeList(node.labels, separator: " ", suffix: " ");
    out.write("default:\n", 2);
    _visitNodeList(node.statements);
    out.write('', -2);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    out.write("switch (");
    _visitNode(node.expression);
    out.write(") {\n", 2);
    _visitNodeList(node.members);
    out.write("}\n", -2);
  }

  @override
  void visitLabel(Label node) {
    _visitNode(node.label);
    out.write(':');
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _visitNodeList(node.labels, separator: " ", suffix: " ");
    _visitNode(node.statement);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    out.write('${node.value}');
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    out.write('${node.value}');
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    out.write('null');
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      out.write('/* Unimplemented const */');
    }
    // TODO(jmesserly): make this faster.
    out.write('new List.from([');
    _visitNodeList(node.elements, separator: ', ');
    out.write('])');
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    out.write('dart.map(');
    var entries = node.entries;
    if (entries != null && entries.isNotEmpty) {
      // Use JS object literal notation if possible, otherwise use an array.
      if (entries.every((e) => e.key is SimpleStringLiteral)) {
        out.write('{\n', 2);
        _visitMapLiteralEntries(entries, separator: ': ');
        out.write('\n}', -2);
      } else {
        out.write('[\n', 2);
        _visitMapLiteralEntries(entries, separator: ', ');
        out.write('\n]', -2);
      }
    }
    out.write(')');
  }

  void _visitMapLiteralEntries(NodeList<MapLiteralEntry> nodes,
      {String separator}) {
    if (nodes == null) return;
    int size = nodes.length;
    if (size == 0) return;

    for (int i = 0; i < size; i++) {
      if (i > 0) out.write(',\n');
      var node = nodes[i];
      node.key.accept(this);
      out.write(separator);
      node.value.accept(this);
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isSingleQuoted) {
      var escaped = _escapeForJs(node.stringValue, "'");
      out.write("'$escaped'");
    } else {
      var escaped = _escapeForJs(node.stringValue, '"');
      out.write('"$escaped"');
    }
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // These are typically used for splitting long strings across lines, so
    // generate accordingly, with each on its own line and +4 indent.

    // TODO(jmesserly): we could linebreak before the first string too, but
    // that means inserting a linebreak in expression context, which might
    // not be valid and leaves trailing whitespace.
    for (int i = 0, last = node.strings.length - 1; i <= last; i++) {
      if (i == 1) {
        out.write(' +\n', 4);
      } else if (i > 1) {
        out.write(' +\n');
      }
      node.strings[i].accept(this);
      if (i == last && i > 0) {
        out.write('', -4);
      }
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    out.write('`');
    _visitNodeList(node.elements);
    out.write('`');
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    out.write(_escapeForJs(node.value, '`'));
  }

  /// Escapes the string from [value], handling escape sequences as needed.
  /// The surrounding [quote] style must be supplied to know which quotes to
  /// escape, but quotes are not added to the resulting string.
  String _escapeForJs(String value, String quote) {
    // Start by escaping the backslashes.
    String escaped = value.replaceAll('\\', '\\\\');
    // Do not escape unicode characters and ' because they are allowed in the
    // string literal anyway.
    return escaped.replaceAllMapped(new RegExp('\n|$quote|\b|\t|\v'), (m) {
      switch (m.group(0)) {
        case "\n":
          return r"\n";
        case "\b":
          return r"\b";
        case "\t":
          return r"\t";
        case "\f":
          return r"\f";
        case "\v":
          return r"\v";
        // Quotes are only replaced if they conflict with the containing quote
        case '"':
          return r'\"';
        case "'":
          return r"\'";
        case "`":
          return r"\`";
      }
    });
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    out.write('\${');
    node.expression.accept(this);
    // Assuming we implement toString() on our objects, we can avoid calling it
    // in most cases. Builtin types may differ though.
    // For example, Dart's concrete List type does not have the same toString
    // as Array.prototype.toString().
    out.write('}');
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    out.write('${node.value}');
  }

  @override
  void visitDirective(Directive node) {}

  @override
  void visitNode(AstNode node) {
    out.write('/* Unimplemented ${node.runtimeType}: $node */');
  }

  // TODO(jmesserly): this is used to determine if the field initialization is
  // side effect free. We should make the check more general, as things like
  // list/map literals/regexp are also side effect free and fairly common
  // to use as field initializers.
  bool _isFieldInitConstant(VariableDeclaration field) =>
      field.initializer == null || _computeConstant(field).isValid;

  EvaluationResult _computeConstant(VariableDeclaration field) {
    // If the constant is already computed by ConstantEvaluator, just return it.
    VariableElementImpl element = field.element;
    var result = element.evaluationResult;
    if (result != null) return result;

    // ConstantEvaluator will not compute constants for non-const fields
    // at least for cases like `int x = 0;`, so run ConstantVisitor for those.
    // TODO(jmesserly): ideally we'd only do this if we're sure it was skipped
    // by ConstantEvaluator.
    var initializer = field.initializer;
    if (initializer == null) return null;

    return _constEvaluator.evaluate(initializer);
  }

  /// Returns true if [element] is a getter in JS, therefore needs
  /// `lib.topLevel` syntax instead of just `topLevel`.
  bool _needsModuleGetter(Element element) {
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    return element is TopLevelVariableElement && !element.isConst;
  }

  /// Safely visit the expression, adding parentheses if necessary
  void _visitExpression(Expression node, int newPrecedence) {
    if (node == null) return;

    // If we're going to replace an expression with a higher-precedence
    // operator, add parenthesis around it if needed.
    var needParens = node.precedence < newPrecedence;
    if (needParens) out.write('(');
    node.accept(this);
    if (needParens) out.write(')');
  }

  /// Safely visit the given node, with an optional prefix or suffix.
  void _visitNode(AstNode node, {String prefix: '', String suffix: ''}) {
    if (node == null) return;

    out.write(prefix);
    node.accept(this);
    out.write(suffix);
  }

  /// Print a list of nodes, with an optional prefix, suffix, and separator.
  void _visitNodeList(List<AstNode> nodes,
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
  void visitToken(Token token, {String prefix: '', String suffix: ''}) {
    if (token == null) return;
    out.write(prefix);
    out.write(token.lexeme);
    out.write(suffix);
  }

  /// The following names are allowed for user-defined operators:
  ///
  ///     <, >, <=, >=, ==, -, +, /, ˜/, *, %, |, ˆ, &, <<, >>, []=, [], ˜
  ///
  /// For the indexing operators, we use `get` and `set` instead:
  ///
  ///     x.get('hi')
  ///     x.set('hi', 123)
  ///
  /// This follows the same pattern as EcmaScript 6 Map:
  /// <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map>
  ///
  /// For all others we use the operator name:
  ///
  ///     x['+'](y)
  ///
  /// Equality is a bit special, it is generated via the Dart `equals` runtime
  /// helper, that checks for null. The user defined method is called '=='.
  String _canonicalMethodName(String name) {
    switch (name) {
      case '[]':
        return 'get';
      case '[]=':
        return 'set';
      case '<':
      case '>':
      case '<=':
      case '>=':
      case '==':
      case '-':
      case '+':
      case '/':
      case '~/':
      case '*':
      case '%':
      case '|':
      case '^':
      case '&':
      case '<<':
      case '>>':
      case '~':
        return "['$name']";
      default:
        return name;
    }
  }

  /// The string to invoke a canonical method name, for example:
  ///
  ///     "[]" returns ".get"
  ///      "+" returns "['+']"
  String _canonicalMethodInvoke(String name) {
    name = _canonicalMethodName(name);
    return name.startsWith('[') ? name : '.$name';
  }

  bool _needsBindThis(node) {
    if (currentClass == null) return false;
    var visitor = _BindThisVisitor._instance;
    visitor._bindThis = false;
    node.accept(visitor);
    return visitor._bindThis;
  }

  static bool _needsImplicitThis(Element e) =>
      e is PropertyAccessorElement && !e.variable.isStatic ||
          e is ClassMemberElement && !e.isStatic && e is! ConstructorElement;
}

/// Returns true if the local variable is potentially mutated within [context].
/// This accounts for closures that may have been created outside of [context].
bool _isPotentiallyMutated(VariableElementImpl e, [AstNode context]) {
  if (e.isPotentiallyMutatedInClosure) {
    // TODO(jmesserly): this returns true incorrectly in some cases, because
    // VariableResolverVisitor only checks that enclosingElement is not the
    // function element, but enclosingElement can be something else in some
    // cases (the block scope?). So it's more conservative than it could be.
    return true;
  }
  if (e.isPotentiallyMutatedInScope) {
    // Need to visit the context looking for assignment to this local.
    if (context != null) {
      var visitor = new _AssignmentFinder(e);
      context.accept(visitor);
      return visitor._potentiallyMutated;
    }
    return true;
  }
  return false;
}

/// Adapted from VariableResolverVisitor. Finds an assignment to a given
/// local variable.
class _AssignmentFinder extends RecursiveAstVisitor {
  final VariableElementImpl _variable;
  bool _potentiallyMutated = false;

  _AssignmentFinder(this._variable);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if qualified.
    AstNode parent = node.parent;
    if (parent is PrefixedIdentifier &&
        identical(parent.identifier, node)) return;
    if (parent is PropertyAccess &&
        identical(parent.propertyName, node)) return;
    if (parent is MethodInvocation &&
        identical(parent.methodName, node)) return;
    if (parent is ConstructorName) return;
    if (parent is Label) return;

    if (node.inSetterContext() && node.staticElement == _variable) {
      _potentiallyMutated = true;
    }
  }
}

/// This is a workaround for V8 arrow function bindings being not yet
/// implemented. See issue #43
class _BindThisVisitor extends RecursiveAstVisitor {
  static _BindThisVisitor _instance = new _BindThisVisitor();
  bool _bindThis = false;

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (JSCodegenVisitor._needsImplicitThis(node.staticElement)) {
      _bindThis = true;
    }
  }

  @override
  visitThisExpression(ThisExpression node) {
    _bindThis = true;
  }
}

class JSGenerator extends CodeGenerator {
  JSGenerator(String outDir, Uri root, TypeRules rules)
      : super(outDir, root, rules);

  void generateLibrary(Iterable<CompilationUnit> units, LibraryInfo info,
      CheckerReporter reporter) {
    var outputPath = path.join(outDir, jsOutputPath(info));
    new Directory(path.dirname(outputPath)).createSync(recursive: true);
    var out = new OutWriter(outputPath);
    new JSCodegenVisitor(info, rules, out).generateLibrary(units, reporter);
    out.close();
  }
}

/// Choose a canonical name from the library element.
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(LibraryElement library) => canonicalLibraryName(library);

/// Path to file that will be generated for [info].
// TODO(jmesserly): library directory should be relative to its package
// root. For example, "package:ddc/src/codegen/js_codegen.dart" would be:
// "ddc/src/codegen/js_codegen.js" under the output directory.
String jsOutputPath(LibraryInfo info) => '${info.name}/${info.name}.js';
