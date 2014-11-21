library ddc.typechecker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:logging/logging.dart' as logger;

import 'src/static_info.dart';
import 'src/type_rules.dart';

logger.Logger log;

class Library {
  final Uri uri;
  final Source source;
  final CompilationUnit lib;
  final Map<Uri, CompilationUnit> parts = new Map<Uri, CompilationUnit>();
  final Map<Uri, Library> imports = new Map<Uri, Library>();

  Library(this.uri, this.source, this.lib);
}

class WorkListItem {
  final Uri uri;
  final Source source;
  final bool isLibrary;
  WorkListItem(this.uri, this.source, this.isLibrary);
}

class ProgramChecker extends RecursiveAstVisitor {
  final AnalysisContext _context;
  final TypeRules _rules;
  final Uri _root;
  final bool _checkSdk;
  final Map<Uri, CompilationUnit> _unitMap;
  final Map<Uri, Library> libraries;
  final List<Library> _stack;
  final List<WorkListItem> workList = [];
  final List<WorkListItem> partWorkList = [];

  Uri _uri = null;

  Uri toUri(String string) {
    // FIXME: Use analyzer's resolver logic.
    if (string.startsWith('package:')) {
      String package = string.substring(8);
      string = 'packages/' + package;
      return _root.resolve(string);
    } else {
      return _stack.last.uri.resolve(string);
    }
  }

  void add(Uri uri, Source source, bool isLibrary) {
    if (isLibrary) {
      workList.add(new WorkListItem(uri, source, isLibrary));
      if (_stack.isNotEmpty) {
        // This is an import / export.
        // Record the key.  Fill in the library later.
        Library lib = _stack.last;
        lib.imports[uri] = null;
      }
    } else {
      partWorkList.add(new WorkListItem(uri, source, isLibrary));
    }
  }

  void finalizeImports() {
    libraries.forEach((Uri uri, Library lib) {
      for (Uri key in lib.imports.keys) {
        lib.imports[key] = libraries[key];
      }
    });
  }

  CompilationUnit load(Uri uri, Source source, bool isLibrary) {
    if (!_checkSdk && uri.scheme == 'dart') {
      return null;
    }
    if (_unitMap.containsKey(uri)) {
      assert(isLibrary);
      return _unitMap[uri];
    }
    // print(' loading $uri');
    _uri = uri;
    final unit = getCompilationUnit(source, isLibrary);
    _rules.setCompilationUnit(unit);
    _unitMap[uri] = unit;
    if (isLibrary) {
      assert(!libraries.containsKey(uri));
      Library lib = new Library(uri, source, unit);
      libraries[uri] = lib;
      _stack.add(lib);
    } else {
      Library lib = _stack.last;
      assert(!lib.parts.containsKey(uri));
      lib.parts[uri] = unit;
    }
    unit.visitChildren(this);
    if (isLibrary) {
      while (partWorkList.isNotEmpty) {
        WorkListItem item = partWorkList.removeAt(0);
        assert(!item.isLibrary);
        load(item.uri, item.source, item.isLibrary);
      }
      final last = _stack.removeLast();
      assert(last.uri == uri);
    }
    return unit;
  }

  void loadFromDirective(UriBasedDirective directive, bool isLibrary) {
    String content = directive.uri.stringValue;
    Uri uri = toUri(content);
    Source source = directive.source;
    add(uri, source, isLibrary);
  }

  CompilationUnit getCompilationUnit(Source source, bool isLibrary) {
    Source container = isLibrary ? source : _stack.last.source;
    return _context.getResolvedCompilationUnit2(source, container);
  }

  ProgramChecker(this._context, this._rules, this._root, Source source,
                 this._checkSdk)
      : _unitMap = new Map<Uri, CompilationUnit>(),
        libraries = new Map<Uri, Library>(),
        _stack = new List<Library>() {
    add(_root, source, true);
  }

  void check() {
    while (workList.isNotEmpty) {
      WorkListItem item = workList.removeAt(0);
      assert(item.isLibrary);
      load(item.uri, item.source, item.isLibrary);
    }
  }

  AstNode visitExportDirective(ExportDirective node) {
    loadFromDirective(node, true);
    node.visitChildren(this);
    return node;
  }

  AstNode visitImportDirective(ImportDirective node) {
    loadFromDirective(node, true);
    node.visitChildren(this);
    return node;
  }

  AstNode visitPartDirective(PartDirective node) {
    loadFromDirective(node, false);
    node.visitChildren(this);
    return node;
  }

  AstNode visitFunctionDeclaration(FunctionDeclaration node) {
    String name = node.name.name;
    // print('Found $name in ${_stack.last.uri}');
    node.visitChildren(this);
    return node;
  }

  AstNode visitAssignmentExpression(AssignmentExpression node) {
    DartType staticType = _rules.getStaticType(node.leftHandSide);
    checkAssignment(node.rightHandSide, staticType);
    node.visitChildren(this);
    return node;
  }

  // Check that member declarations soundly override any overridden declarations.
  InvalidOverride findInvalidOverride(AstNode node, ExecutableElement element,
      InterfaceType type, [bool allowFieldOverride = null]) {
    // FIXME: This can be done a lot more efficiently.
    assert(!element.isStatic);

    // TODO(vsm): Move this out.
    FunctionType subType = _rules.elementType(element);

    ExecutableElement baseMethod;
    String memberName = element.name;

    final isGetter = element is PropertyAccessorElement && element.isGetter;
    final isSetter = element is PropertyAccessorElement && element.isSetter;

    int kind;
    if (isGetter) {
      assert(!isSetter);
      // Look for getter or field.
      // FIXME: Verify that this handles fields.
      baseMethod = type.getGetter(memberName);
    } else if (isSetter) {
      baseMethod = type.getSetter(memberName);
    } else {
      if (memberName == '-') {
        // operator- can be overloaded!
        final len = subType.parameters.length;
        for (final method in type.methods) {
          if (method.name == memberName && method.parameters.length == len) {
            baseMethod = method;
            break;
          }
        }
      } else {
        baseMethod = type.getMethod(memberName);
      }
    }
    if (baseMethod != null) {
      // TODO(vsm): Test for generic
      FunctionType baseType = _rules.elementType(baseMethod);
      if (!_rules.isAssignable(subType, baseType)) {
        return new InvalidOverride(node, element, type, subType, baseType);
      }

      // Test that we're not overriding a field.
      if (allowFieldOverride == false) {
        for (FieldElement field in type.element.fields) {
          if (field.name == memberName) {
            // TODO(vsm): Is this the right test?
            bool syn = field.isSynthetic;
            if (!syn) {
              return new InvalidOverride(
                  node, element, type, subType, baseType, true);
            }
          }
        }
      }
    }

    if (type.isObject) return null;

    allowFieldOverride = allowFieldOverride == null ? false :
        allowFieldOverride;
    InvalidOverride base =
        findInvalidOverride(node, element, type.superclass, allowFieldOverride);
    if (base != null) return base;

    for (final parent in type.interfaces) {
      base = findInvalidOverride(node, element, parent, true);
      if (base != null) return base;
    }

    for (final parent in type.mixins) {
      base = findInvalidOverride(node, element, parent, true);
      if (base != null) return base;
    }

    return null;
  }

  void checkInvalidOverride(
      AstNode node, ExecutableElement element, InterfaceType type) {
    InvalidOverride invalid = findInvalidOverride(node, element, type);
    record(invalid);
  }

  AstNode visitMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
    if (node.isStatic) return node;
    final parent = node.parent;
    if (parent is! ClassDeclaration) {
      throw 'Unexpected parent: $parent';
    }
    ClassDeclaration cls = parent as ClassDeclaration;
    // TODO(vsm): Check for generic.
    InterfaceType type = _rules.elementType(cls.element);
    checkInvalidOverride(node, node.element, type);
    return node;
  }

  AstNode visitFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
    // TODO(vsm): Is there always a corresponding synthetic method?  If not, we need to validate here.
    final parent = node.parent;
    if (!node.isStatic && parent is ClassDeclaration) {
      InterfaceType type = _rules.elementType(parent.element);
      for (VariableDeclaration decl in node.fields.variables) {
        final getter = type.getGetter(decl.name.name);
        if (getter != null) checkInvalidOverride(node, getter, type);
        final setter = type.getSetter(decl.name.name);
        if (setter != null) checkInvalidOverride(node, setter, type);
      }
    }
    return node;
  }

  // Check invocations
  bool checkArgumentList(ArgumentList node, [FunctionType type]) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression arg = list[i];
      ParameterElement element = node.getStaticParameterElementFor(arg);
      if (element == null) {
        element = type.parameters[i];
        // TODO(vsm): When can this happen?
        assert(element != null);
      }
      DartType expectedType = _rules
          .mapGenericType(_rules.elementType(element));
      if (expectedType == null) expectedType = _rules.provider.dynamicType;
      checkAssignment(arg, expectedType);
    }
    return true;
  }

  void checkFunctionApplication(
      Expression node, Expression f, ArgumentList list) {
    DartType type = _rules.getStaticType(f);
    if (type.isDynamic || type.isDartCoreFunction) {
      record(new DynamicInvoke(_rules, node));
    } else if (type is! FunctionType) {
      // TODO(vsm): Function object.  Should still be able to derive a function type
      // from this.
      record(new DynamicInvoke(_rules, node));
    } else {
      assert(type is FunctionType);
      checkArgumentList(list, type);
    }
  }

  AstNode visitMethodInvocation(MethodInvocation node) {
    checkFunctionApplication(node, node.methodName, node.argumentList);
    node.visitChildren(this);
    return node;
  }

  AstNode visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    checkFunctionApplication(node, node.function, node.argumentList);
    node.visitChildren(this);
    return node;
  }

  AstNode visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    bool checked = checkArgumentList(node.argumentList);
    assert(checked);
    node.visitChildren(this);
    return node;
  }

  AstNode visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    bool checked = checkArgumentList(node.argumentList);
    assert(checked);
    node.visitChildren(this);
    return node;
  }

  AstNode visitPropertyAccess(PropertyAccess node) {
    final target = node.realTarget;
    DartType receiverType = _rules.getStaticType(target);
    assert(receiverType != null);
    if (receiverType.isDynamic) {
      record(new DynamicInvoke(_rules, node));
    }
    node.visitChildren(this);
    return node;
  }

  AstNode visitPrefixedIdentifier(PrefixedIdentifier node) {
    final target = node.prefix;
    DartType receiverType = _rules.getStaticType(target);
    assert(receiverType != null);
    if (receiverType.isDynamic) {
      record(new DynamicInvoke(_rules, node));
    }
    node.visitChildren(this);
    return node;
  }

  AstNode visitVariableDeclarationList(VariableDeclarationList node) {
    TypeName type = node.type;
    if (type == null) {
      // No checks are needed when the type is var, but we can infer from the
      // RHS a more precise type for the variable declaration.
      node.variables.forEach(_rules.inferType);
    } else {
      var dartType = getType(type);
      for (VariableDeclaration variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) checkAssignment(initializer, dartType);
      }
    }
    node.visitChildren(this);
    return node;
  }

  DartType getType(TypeName name) {
    return (name == null) ? _rules.provider.dynamicType : name.type;
  }

  bool checkAssignment(Expression expr, DartType type) {
    TypeMismatch result = _rules.checkAssignment(expr, type);
    return !record(result);
  }

  Map<AstNode, List<StaticInfo>> infoMap = new Map<AstNode, List<StaticInfo>>();
  bool failure = false;

  bool record(StaticInfo info) {
    if (info != null) {
      if (info.level >= logger.Level.SEVERE) failure = true;
      if (!infoMap.containsKey(info.node)) {
        infoMap[info.node] = new List<StaticInfo>();
      }
      infoMap[info.node].add(info);
      log.log(info.level, info.message, info.node);
      return true;
    }
    return false;
  }
}
