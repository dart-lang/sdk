// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stub_core_library;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:path/path.dart' as p;

/// Returns the contents of a stub version of the library at [path].
///
/// A stub library has the same API as the original library, but none of the
/// implementation. Specifically, this guarantees that any code that worked with
/// the original library will be statically valid with the stubbed library, and
/// its only runtime errors will be [UnsupportedError]s. This means that
/// constants and const constructors are preserved.
///
/// [importReplacements] is a map from import URIs to their replacements. It's
/// used so that mutliple interrelated libraries can refer to their stubbed
/// versions rather than the originals.
String stubFile(String path, [Map<String, String> importReplacements]) {
  var visitor = new _StubVisitor(path, importReplacements);
  parseDartFile(path).accept(visitor);
  return visitor.toString();
}

/// Returns the contents of a stub version of the library parsed from [code].
///
/// If [code] contains `part` directives, they will be resolved relative to
/// [path]. The contents of the parted files will be stubbed and inlined.
String stubCode(String code, String path,
    [Map<String, String> importReplacements]) {
  var visitor = new _StubVisitor(path, importReplacements);
  parseCompilationUnit(code, name: path).accept(visitor);
  return visitor.toString();
}

/// An AST visitor that traverses the tree of the original library and writes
/// the stubbed version.
///
/// In order to avoid complex tree-shaking logic, this takes a conservative
/// approach to removing private code. Private classes may still be extended by
/// public classes; private constants may be referenced by public constants; and
/// private static and top-level methods may be referenced by public constants
/// or by superclass constructor calls. All of these are preserved even though
/// most could theoretically be eliminated.
class _StubVisitor extends ToSourceVisitor {
  /// The directory containing the library being visited.
  final String _root;

  /// Which imports to replace.
  final Map<String, String> _importReplacements;

  final PrintStringWriter _writer;

  // TODO(nweiz): Get rid of this when issue 19897 is fixed.
  /// The current class declaration being visited.
  ///
  /// This is `null` if there is no current class declaration.
  ClassDeclaration _class;

  _StubVisitor(String path, Map<String, String> importReplacements)
      : this._(path, importReplacements, new PrintStringWriter());

  _StubVisitor._(String path, Map<String, String> importReplacements,
          PrintStringWriter writer)
      : _root = p.dirname(path),
        _importReplacements = importReplacements == null ? const {} :
            importReplacements,
        _writer = writer,
        super(writer);

  String toString() => _writer.toString();

  visitImportDirective(ImportDirective node) {
    node = _modifyDirective(node);
    if (node != null) super.visitImportDirective(node);
  }

  visitExportDirective(ExportDirective node) {
    node = _modifyDirective(node);
    if (node != null) super.visitExportDirective(node);
  }

  visitPartDirective(PartDirective node) {
    // Inline parts directly in the output file.
    var path = p.url.join(_root, p.fromUri(node.uri.stringValue));
    parseDartFile(path).accept(new _StubVisitor._(path, const {}, _writer));
  }

  visitPartOfDirective(PartOfDirective node) {
    // Remove "part of", since parts are inlined.
  }

  visitClassDeclaration(ClassDeclaration node) {
    _class = _clone(node);
    _class.nativeClause = null;
    super.visitClassDeclaration(_class);
    _class = null;
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    node = _withoutExternal(node);

    // Remove field initializers and redirecting initializers but not superclass
    // initializers. The code is ugly because NodeList doesn't support
    // removeWhere.
    var superclassInitializers = node.initializers.where((initializer) =>
        initializer is SuperConstructorInvocation).toList();
    node.initializers.clear();
    node.initializers.addAll(superclassInitializers);

    // Add a space because ToSourceVisitor doesn't and it makes testing easier.
    _writer.print(" ");
    super.visitConstructorDeclaration(node);
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // If this is a const constructor, it should actually work, so don't screw
    // with the superclass constructor.
    if ((node.parent as ConstructorDeclaration).constKeyword != null) {
      return super.visitSuperConstructorInvocation(node);
    }

    _writer.print("super");
    _visitNodeWithPrefix(".", node.constructorName);
    _writer.print("(");

    // If one stubbed class extends another, we don't want to run the original
    // code for the superclass constructor call, and we do want an
    // UnsupportedException that points to the subclass rather than the
    // superclass. To do this, we null out all but the first superclass
    // constructor parameter and replace the first parameter with a throw.
    var positionalArguments = node.argumentList.arguments
        .where((argument) => argument is! NamedExpression);
    if (positionalArguments.isNotEmpty) {
      _writer.print(_unsupported(_functionName(node)));
      for (var i = 0; i < positionalArguments.length - 1; i++) {
        _writer.print(", null");
      }
    }

    _writer.print(")");
  }

  visitMethodDeclaration(MethodDeclaration node) {
    // Private non-static methods aren't public and aren't accessible from
    // constant expressions, so can be safely removed.
    if (Identifier.isPrivateName(node.name.name) && !node.isStatic) return;
    _writer.print(" ");
    super.visitMethodDeclaration(_withoutExternal(node));
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(_withoutExternal(node));
  }

  visitBlockFunctionBody(BlockFunctionBody node) => _emitFunctionBody(node);

  visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      _emitFunctionBody(node);

  visitNativeFunctionBody(NativeFunctionBody node) => _emitFunctionBody(node);

  visitEmptyFunctionBody(FunctionBody node) {
    // Preserve empty function bodies for abstract methods, since there's no
    // reason not to. Note that "empty" here means "foo();" not "foo() {}".
    var isAbstractMethod = node.parent is MethodDeclaration &&
        !(node.parent as MethodDeclaration).isStatic && _class != null &&
        _class.isAbstract;

    // Preserve empty function bodies for const constructors because we want
    // them to continue to work.
    var isConstConstructor = node.parent is ConstructorDeclaration &&
        (node.parent as ConstructorDeclaration).constKeyword != null;

    if (isAbstractMethod || isConstConstructor) {
      super.visitEmptyFunctionBody(node);
      _writer.print(" ");
    } else {
      _writer.print(" ");
      _emitFunctionBody(node);
    }
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    // Remove "this." because instance variables are replaced with getters and
    // setters or just set to null.
    _emitTokenWithSuffix(node.keyword, " ");

    // Make sure the parameter is still typed by grabbing the type from the
    // associated instance variable.
    var type = node.type;
    if (type == null) {
      var variable = _class.members
          .where((member) => member is FieldDeclaration)
          .expand((member) => member.fields.variables)
          .firstWhere((variable) => variable.name.name == node.identifier.name,
              orElse: () => null);
      if (variable != null) type = variable.parent.type;
    }

    _visitNodeWithSuffix(type, " ");
    _visitNode(node.identifier);
    _visitNode(node.parameters);
  }

  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.variables.forEach(_emitVariableDeclaration);
  }

  visitFieldDeclaration(FieldDeclaration node) {
    _writer.print(" ");
    node.fields.variables.forEach(_emitVariableDeclaration);
  }

  /// Modifies a directive to respect [importReplacements] and ignore hidden
  /// core libraries.
  ///
  /// This can return `null`, indicating that the directive should not be
  /// emitted.
  UriBasedDirective _modifyDirective(UriBasedDirective node) {
    // Ignore internal "dart:" libraries.
    if (node.uri.stringValue.startsWith('dart:_')) return null;

    // Replace libraries in [importReplacements].
    if (_importReplacements.containsKey(node.uri.stringValue)) {
      node = _clone(node);
      var token = new StringToken(TokenType.STRING,
          '"${_importReplacements[node.uri.stringValue]}"', 0);
      node.uri = new SimpleStringLiteral(token, null);
    }

    return node;
  }

  /// Emits a variable declaration, either as a literal variable or as a getter
  /// and maybe a setter that throw [UnsupportedError]s.
  _emitVariableDeclaration(VariableDeclaration node) {
    VariableDeclarationList parent = node.parent;
    var isStatic = node.parent.parent is FieldDeclaration &&
        (node.parent.parent as FieldDeclaration).isStatic;

    // Preserve constants as-is.
    if (node.isConst) {
      if (isStatic) _writer.print("static ");
      _writer.print("const ");
      _visitNode(node);
      _writer.print("; ");
      return;
    }

    // Ignore non-const private variables.
    if (Identifier.isPrivateName(node.name.name)) return;

    // There's no need to throw errors for instance fields of classes that can't
    // be constructed.
    if (!isStatic && _class != null && !_inConstructableClass) {
      _emitTokenWithSuffix(parent.keyword, " ");
      _visitNodeWithSuffix(parent.type, " ");
      _visitNode(node.name);
      // Add an initializer to make sure that final variables are initialized.
      if (node.isFinal) _writer.print(" = null; ");
      return;
    }

    var name = node.name.name;
    if (_class != null) name = "${_class.name}.$name";

    // Convert public variables into getters and setters that throw
    // UnsupportedErrors.
    if (isStatic) _writer.print("static ");
    _visitNodeWithSuffix(parent.type, " ");
    _writer.print("get ");
    _visitNode(node.name);
    _writer.print(" => ${_unsupported(name)}; ");
    if (node.isFinal) return;

    if (isStatic) _writer.print("static ");
    _writer.print("set ");
    _visitNode(node.name);
    _writer.print("(");
    _visitNodeWithSuffix(parent.type, " ");
    _writer.print("_) { ${_unsupported("$name=")}; } ");
  }

  /// Emits a function body.
  ///
  /// This usually emits a body that throws an [UnsupportedError], but it can
  /// emit an empty body as well.
  void _emitFunctionBody(FunctionBody node) {
    // There's no need to throw errors for instance methods of classes that
    // can't be constructed.
    var parent = node.parent;
    if (parent is MethodDeclaration && !parent.isStatic &&
        !_inConstructableClass) {
      _writer.print('{} ');
      return;
    }

    _writer.print('{ ${_unsupported(_functionName(node))}; } ');
  }

  // Returns a human-readable name for the function containing [node].
  String _functionName(AstNode node) {
    // Come up with a nice name for the error message so users can tell exactly
    // what unsupported method they're calling.
    var function = node.getAncestor((ancestor) =>
        ancestor is FunctionDeclaration || ancestor is MethodDeclaration);
    if (function != null) {
      var name = function.name.name;
      if (function.isSetter) {
        name = "$name=";
      } else if (!function.isGetter &&
          !(function is MethodDeclaration && function.isOperator)) {
        name = "$name()";
      }
      if (_class != null) name = "${_class.name}.$name";
      return name;
    }

    var constructor = node.getAncestor((ancestor) =>
        ancestor is ConstructorDeclaration);
    if (constructor == null) return "This function";

    var name = "new ${constructor.returnType.name}";
    if (constructor.name != null) name = "$name.${constructor.name}";
    return "$name()";
  }

  /// Returns a deep copy of [node].
  AstNode _clone(AstNode node) => node.accept(new AstCloner());

  /// Returns a deep copy of [node] without the "external" keyword.
  AstNode _withoutExternal(node) {
    var clone = node.accept(new AstCloner());
    clone.externalKeyword = null;
    return clone;
  }

  /// Visits [node] if it's non-`null`.
  void _visitNode(AstNode node) {
    if (node != null) node.accept(this);
  }

  /// Visits [node] then emits [suffix] if [node] isn't `null`.
  void _visitNodeWithSuffix(AstNode node, String suffix) {
    if (node == null) return;
    node.accept(this);
    _writer.print(suffix);
  }

  /// Emits [prefix] then visits [node] if [node] isn't `null`.
  void _visitNodeWithPrefix(String prefix, AstNode node) {
    if (node == null) return;
    _writer.print(prefix);
    node.accept(this);
  }

  /// Emits [token] followed by [suffix] if [token] isn't `null`.
  void _emitTokenWithSuffix(Token token, String suffix) {
    if (token == null) return;
    _writer.print(token.lexeme);
    _writer.print(suffix);
  }

  /// Returns an expression that throws an [UnsupportedError] explaining that
  /// [name] isn't supported.
  String _unsupported(String name) => 'throw new UnsupportedError("$name is '
      'unsupported on this platform.")';

  /// Returns whether or not the visitor is currently visiting a class that can
  /// be constructed without error after it's stubbed.
  ///
  /// There are two cases where a class will be constructable once it's been
  /// stubbed. First, a class with a const constructor will be preserved, since
  /// making the const constructor fail would statically break code. Second, a
  /// class with a default constructor is preserved since adding a constructor
  /// that throws an error could statically break uses of the class as a mixin.
  bool get _inConstructableClass {
    if (_class == null) return false;

    var constructors = _class.members.where((member) =>
        member is ConstructorDeclaration);
    if (constructors.isEmpty) return true;

    return constructors.any((constructor) => constructor.constKeyword != null);
  }
}
