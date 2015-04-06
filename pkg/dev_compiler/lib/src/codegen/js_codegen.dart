// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.js_codegen;

import 'dart:collection' show HashSet, HashMap;
import 'dart:io' show Directory, File;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart'
    show StringToken, Token, TokenType;
import 'package:source_maps/source_maps.dart' as srcmaps show Printer;
import 'package:source_maps/source_maps.dart' show SourceMapSpan;
import 'package:source_span/source_span.dart' show SourceLocation;
import 'package:path/path.dart' as path;

import 'package:dev_compiler/src/codegen/ast_builder.dart' show AstBuilder;

// TODO(jmesserly): import from its own package
import 'package:dev_compiler/src/js/js_ast.dart' as JS;
import 'package:dev_compiler/src/js/js_ast.dart' show js;

import 'package:dev_compiler/src/checker/rules.dart';
import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:dev_compiler/src/utils.dart';

import 'code_generator.dart';
import 'js_names.dart';

bool _isAnnotationType(Annotation m, String name) => m.name.name == name;

Annotation _getAnnotation(AnnotatedNode node, String name) => node.metadata
    .firstWhere((annotation) => _isAnnotationType(annotation, name),
        orElse: () => null);

Annotation _getJsNameAnnotation(AnnotatedNode node) =>
    _getAnnotation(node, "JsName");

// TODO(jacobr): we would like to do something like the following
// but we don't have summary support yet.
// bool _supportJsExtensionMethod(AnnotatedNode node) =>
//    _getAnnotation(node, "SupportJsExtensionMethod") != null;

class JSCodegenVisitor extends GeneralizingAstVisitor with ConversionVisitor {
  final LibraryInfo libraryInfo;
  final TypeRules rules;

  // TODO(jmesserly): this is needed because RestrictedTypeRules can send
  // messages to CheckerReporter, for things like missing types.
  // We should probably refactor so this can't happen, as codegen would be too
  // late to be issuing these messages.
  final CheckerReporter _checkerReporter;

  /// The variable for the target of the current `..` cascade expression.
  SimpleIdentifier _cascadeTarget;
  /// The variable for the current catch clause
  SimpleIdentifier _catchParameter;

  ClassDeclaration currentClass;
  ConstantEvaluator _constEvaluator;

  final _exports = new Set<String>();
  final _lazyFields = <VariableDeclaration>[];
  final _properties = <FunctionDeclaration>[];
  final _privateNames = new HashSet<String>();
  final _pendingPrivateNames = <String>[];
  final _extensionMethodNames = new HashSet<String>();
  final _pendingExtensionMethodNames = <String>[];

  InterfaceType _fillDynamicTypeArgs(InterfaceType t) {
    var d = rules.provider.dynamicType;
    return t.substitute4(new List.filled(t.typeArguments.length, d));
  }
  // TODO(jacobr): determine the the set of types with extension methods from
  // the annotations rather than hard coding the list once the analyzer
  // supports summaries.
  List<InterfaceType> _jsExtensionMethodTypes;
  List<InterfaceType> get jsExtensionMethodTypes {
    if (_jsExtensionMethodTypes != null) return _jsExtensionMethodTypes;
    _jsExtensionMethodTypes = <InterfaceType>[
      rules.provider.listType,
      rules.provider.iterableType
    ].map(_fillDynamicTypeArgs).toList();
    return _jsExtensionMethodTypes;
  }

  Map<ClassElement, Set<String>> _extensionMethods;

  Map<ClassElement, Set<String>> get extensionMethods {
    if (_extensionMethods != null) return _extensionMethods;
    _extensionMethods = new HashMap<ClassElement, HashSet<String>>();

    for (var type in jsExtensionMethodTypes) {
      var names = new HashSet<String>();
      var e = type.element;
      names.addAll(e.methods.map((m) => m.name));
      names.addAll(e.accessors.map((m) => m.name));
      _extensionMethods[e] = names;
    }
    return _extensionMethods;
  }

  /// Classes we have not emitted yet. Values can be [ClassDeclaration] or
  /// [ClassTypeAlias].
  final _pendingClasses = new HashMap<Element, CompilationUnitMember>();

  /// Memoized results of [_lazyClass].
  final _lazyClassMemo = new HashMap<Element, bool>();

  /// Memoized results of [_inLibraryCycle].
  final _libraryCycleMemo = new HashMap<LibraryElement, bool>();

  JSCodegenVisitor(this.libraryInfo, this.rules, this._checkerReporter);

  LibraryElement get currentLibrary => libraryInfo.library;

  /// The name for the library's exports inside itself.
  /// This much be a constant because we interpolate it into template strings,
  /// and otherwise it would break caching for them.
  /// `exports` was chosen as the most similar to ES module patterns.
  final JSTemporary _exportsVar = new JSTemporary('exports');
  final JSTemporary _namedArgTemp = new JSTemporary('opts');

  JS.Program emitLibrary(LibraryUnit library) {
    var jsDefaultValue = '{}';
    var unit = library.library;
    if (unit.directives.isNotEmpty) {
      var annotation = _getJsNameAnnotation(unit.directives.first);
      if (annotation != null) {
        var arguments = annotation.arguments.arguments;
        if (!arguments.isEmpty) {
          var namedExpression = arguments.first as NamedExpression;
          var literal = namedExpression.expression as SimpleStringLiteral;
          jsDefaultValue = literal.stringValue;
        }
      }
    }
    var body = <JS.Statement>[];

    // Collect classes we need to emit, used for:
    // * tracks what we've emitted so we don't emit twice
    // * provides a mapping from ClassElement back to the ClassDeclaration.
    for (var unit in library.partsThenLibrary) {
      for (var decl in unit.declarations) {
        if (decl is ClassDeclaration ||
            decl is ClassTypeAlias ||
            decl is FunctionTypeAlias) {
          _pendingClasses[decl.element] = decl;
        }
      }
    }

    for (var unit in library.partsThenLibrary) body.add(_visit(unit));

    assert(_pendingClasses.isEmpty);

    if (_exports.isNotEmpty) body.add(js.comment('Exports:'));

    // TODO(jmesserly): make these immutable in JS?
    for (var name in _exports) {
      body.add(js.statement('#.# = #;', [_exportsVar, name, name]));
    }

    var name = jsLibraryName(libraryInfo.library);

    var defaultValue = js.call(jsDefaultValue);
    return new JS.Program([
      js.statement('var #;', name),
      js.statement("(function(#) { 'use strict'; #; })(# || (# = #));", [
        _exportsVar,
        body,
        name,
        name,
        defaultValue
      ])
    ]);
  }

  JS.Statement _initPrivateSymbol(String name) => js.statement(
      'let # = $_SYMBOL(#);', [new JSTemporary(name), js.string(name, "'")]);

  JS.Statement _initExtensionMethodSymbol(String name) => js.statement(
      'let # = $_SYMBOL(#);', [new JS.Identifier(name), js.string(name, "'")]);

  // TODO(jmesserly): this is a temporary workaround for `Symbol` in core,
  // until we have better name tracking.
  String get _SYMBOL {
    var name = currentLibrary.name;
    if (name == 'dart.core' || name == 'dart._internal') return 'dart.JsSymbol';
    return 'Symbol';
  }

  @override
  JS.Statement visitCompilationUnit(CompilationUnit node) {
    var source = node.element.source;

    _constEvaluator = new ConstantEvaluator(source, rules.provider);
    _checkerReporter.enterSource(source);

    // TODO(jmesserly): scriptTag, directives.
    var body = <JS.Statement>[];
    for (var child in node.declarations) {
      // Attempt to group adjacent fields/properties.
      if (child is! TopLevelVariableDeclaration) _flushLazyFields(body);
      if (child is! FunctionDeclaration) _flushLibraryProperties(body);

      var code = _visit(child);

      if (code != null) {
        if (_pendingPrivateNames.isNotEmpty) {
          body.addAll(_pendingPrivateNames.map(_initPrivateSymbol));
          _pendingPrivateNames.clear();
        }
        if (_pendingExtensionMethodNames.isNotEmpty) {
          body.addAll(
              _pendingExtensionMethodNames.map(_initExtensionMethodSymbol));
          _pendingExtensionMethodNames.clear();
        }
        body.add(code);
      }
    }

    // Flush any unwritten fields/properties.
    _flushLazyFields(body);
    _flushLibraryProperties(body);

    _checkerReporter.leaveSource();

    assert(_pendingPrivateNames.isEmpty);
    return _statement(body);
  }

  bool isPublic(String name) => !name.startsWith('_');

  /// Conversions that we don't handle end up here.
  @override
  visitConversion(Conversion node) {
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
        return js.call('dart.notNull(#)', _visit(node.expression));
      } else {
        // A no-op in JavaScript.
        return _visit(node.expression);
      }
    }

    return _emitCast(node.expression, to);
  }

  // TODO(vsm): This should go away in the future.  I'm passing in the type
  // as a String for now to avoid breaking any existing code.  In most cases,
  // we currently throw for function types.
  @override
  visitClosureWrapBase(ClosureWrapBase node) {
    var expression = _visit(node.expression);
    var typeString = js.escapedString(node.convertedType.toString());
    return js.call('dart.closureWrap(#, #)', [expression, typeString]);
  }

  @override
  visitAsExpression(AsExpression node) =>
      _emitCast(node.expression, node.type.type);

  _emitCast(Expression node, DartType type) =>
      js.call('dart.as(#)', [[_visit(node), _emitTypeName(type)]]);

  @override
  visitIsExpression(IsExpression node) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    JS.Expression result;
    var type = node.type.type;
    var lhs = _visit(node.expression);
    var typeofName = _jsTypeofName(type);
    if (typeofName != null) {
      result = js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      // Always go through a runtime helper, because implicit interfaces.
      result = js.call('dart.is(#, #)', [lhs, _emitTypeName(type)]);
    }

    if (node.notOperator != null) {
      return js.call('!#', result);
    }
    return result;
  }

  String _jsTypeofName(DartType t) {
    if (rules.isIntType(t) || rules.isDoubleType(t)) return 'number';
    if (rules.isStringType(t)) return 'string';
    if (rules.isBoolType(t)) return 'boolean';
    return null;
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    // If we've already emitted this class, skip it.
    var type = node.element.type;
    if (_pendingClasses.remove(node.element) == null) return null;

    var classDecl = new JS.ClassDeclaration(new JS.ClassExpression(
        new JS.Identifier(type.name),
        _emitTypeName(rules.provider.functionType), []));

    return _finishClassDef(type, classDecl);
  }

  @override
  JS.Expression visitTypeName(TypeName node) => _emitTypeName(node.type);

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    // If we've already emitted this class, skip it.
    var type = node.element.type;
    if (_pendingClasses.remove(node.element) == null) return null;

    var name = node.name.name;
    var heritage =
        js.call('dart.mixin(#)', [_visitList(node.withClause.mixinTypes)]);
    var classDecl = new JS.ClassDeclaration(
        new JS.ClassExpression(new JS.Identifier(name), heritage, []));

    return _finishClassDef(type, classDecl);
  }

  @override
  JS.Statement visitClassDeclaration(ClassDeclaration node) {
    // If we've already emitted this class, skip it.
    var type = node.element.type;
    if (_pendingClasses.remove(node.element) == null) return null;
    if (_getJsNameAnnotation(node) != null) return null;

    currentClass = node;

    var ctors = <ConstructorDeclaration>[];
    var fields = <FieldDeclaration>[];
    var staticFields = <FieldDeclaration>[];
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        ctors.add(member);
      } else if (member is FieldDeclaration) {
        (member.isStatic ? staticFields : fields).add(member);
      }
    }

    var classExpr = new JS.ClassExpression(new JS.Identifier(type.name),
        _classHeritage(node), _emitClassMethods(node, ctors, fields));

    var body =
        _finishClassMembers(node.element, classExpr, ctors, staticFields);
    currentClass = null;

    return _finishClassDef(type, body);
  }

  @override
  JS.Statement visitEnumDeclaration(EnumDeclaration node) =>
      _unimplementedCall("Unimplemented enum: $node").toStatement();

  /// Given a class element and body, complete the class declaration.
  /// This handles generic type parameters, laziness (in library-cycle cases),
  /// and ensuring dependencies are loaded first.
  JS.Statement _finishClassDef(ParameterizedType type, JS.Statement body) {
    var name = type.name;
    var genericName = '$name\$';

    JS.Statement genericDef;
    JS.Expression genericInst;
    if (type.typeParameters.isNotEmpty) {
      genericDef = _emitGenericClassDef(type, body);
      var target = genericName;
      if (_needQualifiedName(type.element)) {
        target = js.call('#.#', [_exportsVar, genericName]);
      }
      genericInst = js.call('#()', [target]);
    }

    // The base class and all mixins must be declared before this class.
    if (_lazyClass(type)) {
      // TODO(jmesserly): the lazy class def is a simple solution for now.
      // We may want to consider other options in the future.

      if (genericDef != null) {
        return js.statement(
            '{ #; dart.defineLazyClassGeneric(#, #, { get: # }); }', [
          genericDef,
          _exportsVar,
          js.string(name, "'"),
          genericName
        ]);
      }

      return js.statement(
          'dart.defineLazyClass(#, { get #() { #; return #; } });', [
        _exportsVar,
        _propertyName(name),
        body,
        name
      ]);
    }

    if (isPublic(name)) _addExport(name);

    if (genericDef != null) {
      body = js.statement('{ #; let # = #; }', [genericDef, name, genericInst]);
    }

    if (type.isObject) return body;

    // If we're not lazy, we still need to ensure our dependencies are
    // generated first.
    var classDefs = <JS.Statement>[];
    if (type is InterfaceType) {
      _emitClassIfNeeded(classDefs, type.superclass);
      for (var m in type.element.mixins) {
        _emitClassIfNeeded(classDefs, m);
      }
    } else if (type is FunctionType) {
      _emitClassIfNeeded(classDefs, rules.provider.functionType);
    }
    classDefs.add(body);
    return _statement(classDefs);
  }

  void _emitClassIfNeeded(List<JS.Statement> defs, DartType base) {
    // We can only emit classes from this library.
    if (base.element.library != currentLibrary) return;

    var baseNode = _pendingClasses[base.element];
    if (baseNode != null) defs.add(visitClassDeclaration(baseNode));
  }

  /// Returns true if the supertype or mixins aren't loaded.
  /// If that is the case, we'll emit a lazy class definition.
  bool _lazyClass(DartType type) {
    if (type.isObject) return false;

    // Use the element as the key, as those are unique whereas generic types
    // can have their arguments substituted.
    assert(type.element.library == currentLibrary);
    var result = _lazyClassMemo[type.element];
    if (result != null) return result;

    if (type is InterfaceType) {
      result = _typeMightNotBeLoaded(type.superclass) ||
          type.mixins.any(_typeMightNotBeLoaded);
    } else if (type is FunctionType) {
      result = _typeMightNotBeLoaded(rules.provider.functionType);
    }
    return _lazyClassMemo[type.element] = result;
  }

  /// Curated order to minimize lazy classes needed by dart:core and its
  /// transitive SDK imports.
  static const CORELIB_ORDER = const [
    'dart.core',
    'dart.collection',
    'dart._internal'
  ];

  /// Returns true if the class might not be loaded.
  ///
  /// If the class is from our library, this can happen because it's lazy.
  ///
  /// If the class is from a different library, it could happen if we're in
  /// a library cycle. In other words, if that different library depends back
  /// on this library via some transitive import path.
  ///
  /// If we could control the global import ordering, we could eliminate some
  /// of these cases, by ordering the imports of the cyclic libraries in an
  /// optimal way. For example, we could order the libraries in a cycle to
  /// minimize laziness. However, we currently assume we cannot control the
  /// order that the cycle of libraries will be loaded in.
  bool _typeMightNotBeLoaded(DartType type) {
    var library = type.element.library;
    if (library == currentLibrary) return _lazyClass(type);

    // The SDK is a special case: we optimize the order to prevent laziness.
    if (library.isInSdk) {
      // SDK is loaded before non-SDK libraies
      if (!currentLibrary.isInSdk) return false;

      // Compute the order of both SDK libraries. If unknown, assume it's after.
      var classOrder = CORELIB_ORDER.indexOf(library.name);
      if (classOrder == -1) classOrder = CORELIB_ORDER.length;

      var currentOrder = CORELIB_ORDER.indexOf(currentLibrary.name);
      if (currentOrder == -1) currentOrder = CORELIB_ORDER.length;

      // If the dart:* library we are currently compiling is loaded after the
      // class's library, then we know the class is available.
      if (classOrder != currentOrder) return currentOrder < classOrder;

      // If we don't know the order of the class's library or the current
      // library, do the normal cycle check. (Not all SDK libs are cycles.)
    }

    return _inLibraryCycle(library);
  }

  /// Returns true if [library] depends on the [currentLibrary] via some
  /// transitive import.
  bool _inLibraryCycle(LibraryElement library) {
    // SDK libs don't depend on things outside the SDK.
    // (We can reach this via the recursive call below.)
    if (library.isInSdk && !currentLibrary.isInSdk) return false;

    var result = _libraryCycleMemo[library];
    if (result != null) return result;

    result = library == currentLibrary;
    _libraryCycleMemo[library] = result;
    for (var e in library.imports) {
      if (result) break;
      result = _inLibraryCycle(e.importedLibrary);
    }
    for (var e in library.exports) {
      if (result) break;
      result = _inLibraryCycle(e.exportedLibrary);
    }
    return _libraryCycleMemo[library] = result;
  }

  JS.Statement _emitGenericClassDef(ParameterizedType type, JS.Statement body) {
    var name = type.name;
    var genericName = '$name\$';
    var typeParams = type.typeParameters.map((p) => p.name);
    if (isPublic(name)) _exports.add(genericName);
    return js.statement('let # = dart.generic(function(#) { #; return #; });', [
      genericName,
      typeParams,
      body,
      name
    ]);
  }

  JS.Expression _classHeritage(ClassDeclaration node) {
    if (node.element.type.isObject) return null;

    JS.Expression heritage = null;
    if (node.extendsClause != null) {
      heritage = _visit(node.extendsClause.superclass);
    } else {
      heritage = _emitTypeName(rules.provider.objectType);
    }
    if (node.withClause != null) {
      var mixins = _visitList(node.withClause.mixinTypes);
      mixins.insert(0, heritage);
      heritage = js.call('dart.mixin(#)', [mixins]);
    }
    return heritage;
  }

  /// Emit class members that can be generated as methods.
  /// Anything not handled here will be addressed in [_finishClassMembers].
  Iterable<InterfaceType> getMatchingExtensionMethodTypes(InterfaceType type) =>
      jsExtensionMethodTypes.where((t) => rules.isSubTypeOf(type, t));

  LibraryElement getExtensionLibrary(
      Iterable<InterfaceType> extensionTypes, String name) {
    var library = null;
    for (var type in extensionTypes) {
      var element = type.element;
      if (extensionMethods[element].contains(name)) {
        assert(library == null || library == element.library);
        library = element.library;
      }
    }
    return library;
  }

  JS.Expression nameIfExtension(Expression target, String name) {
    var targetType = rules.getStaticType(target);
    if (targetType is! InterfaceType) return null;
    var extensionLibrary =
        getExtensionLibrary(getMatchingExtensionMethodTypes(targetType), name);
    if (extensionLibrary == null) return null;
    return js.call('#.#', [
      _libraryName(extensionLibrary),
      _emitExtensionMethodName(name)
    ]);
  }

  List<JS.Method> _emitClassMethods(ClassDeclaration node,
      List<ConstructorDeclaration> ctors, List<FieldDeclaration> fields) {
    var element = node.element;
    var isObject = element.type.isObject;
    var name = node.name.name;

    var jsMethods = <JS.Method>[];
    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    if (ctors.isEmpty && !isObject) {
      jsMethods.add(_emitImplicitConstructor(node, name, fields));
    }
    var extensionTypes = getMatchingExtensionMethodTypes(element.type);
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        jsMethods.add(_emitConstructor(member, name, fields, isObject));
      } else if (member is MethodDeclaration) {
        jsMethods.add(_emitMethodDeclaration(member, extensionTypes));
      }
    }

    // Support for adapting dart:core Iterator/Iterable to ES6 versions.
    // This lets them use for-of loops transparently.
    // https://github.com/lukehoban/es6features#iterators--forof
    if (element.library.isDartCore && element.name == 'Iterable') {
      JS.Fun body = js.call('''function() {
        var iterator = this.iterator;
        return {
          next() {
            var done = iterator.moveNext();
            return { done: done, current: done ? void 0 : iterator.current };
          }
        };
      }''');
      jsMethods.add(new JS.Method(js.call('$_SYMBOL.iterator'), body));
    }
    return jsMethods.where((m) => m != null).toList(growable: false);
  }

  /// Emit class members that need to come after the class declaration, such
  /// as static fields. See [_emitClassMethods] for things that are emitted
  /// insite the ES6 `class { ... }` node.
  JS.Statement _finishClassMembers(ClassElement classElem,
      JS.ClassExpression cls, List<ConstructorDeclaration> ctors,
      List<FieldDeclaration> staticFields) {
    var name = classElem.name;

    var body = <JS.Statement>[];
    body.add(new JS.ClassDeclaration(cls));

    // Interfaces
    if (classElem.interfaces.isNotEmpty) {
      body.add(js.statement('#[dart.implements] = () => #;', [
        name,
        new JS.ArrayInitializer(
            classElem.interfaces.map(_emitTypeName).toList())
      ]));
    }

    // Named constructors
    for (ConstructorDeclaration member in ctors) {
      if (member.name != null) {
        body.add(js.statement('dart.defineNamedConstructor(#, #);', [
          name,
          _emitMemberName(member.name.name, isStatic: true)
        ]));
      }
    }

    // Static fields
    var lazyStatics = <VariableDeclaration>[];
    for (FieldDeclaration member in staticFields) {
      for (VariableDeclaration field in member.fields.variables) {
        var fieldName = field.name.name;
        if (field.isConst || _isFieldInitConstant(field)) {
          var init = _visit(field.initializer);
          if (init == null) init = new JS.LiteralNull();
          body.add(js.statement('#.# = #;', [name, fieldName, init]));
        } else {
          lazyStatics.add(field);
        }
      }
    }
    var lazy = _emitLazyFields(new JS.Identifier(name), lazyStatics);
    if (lazy != null) body.add(lazy);

    return _statement(body);
  }

  /// Generates the implicit default constructor for class C of the form
  /// `C() : super() {}`.
  JS.Method _emitImplicitConstructor(
      ClassDeclaration node, String name, List<FieldDeclaration> fields) {
    // If we don't have a method body, skip this.
    if (fields.isEmpty) return null;

    dynamic body = _initializeFields(fields);
    var superCall = _superConstructorCall(node);
    if (superCall != null) body = [[body, superCall]];
    return new JS.Method(
        _propertyName(name), js.call('function() { #; }', body));
  }

  JS.Method _emitConstructor(ConstructorDeclaration node, String className,
      List<FieldDeclaration> fields, bool isObject) {
    if (_externalOrNative(node)) return null;

    var name = _constructorName(className, node.name);

    // Code generation for Object's constructor.
    JS.Block body;
    if (isObject &&
        node.body is EmptyFunctionBody &&
        node.constKeyword != null &&
        node.name == null) {
      // Implements Dart constructor behavior. Because of V8 `super`
      // [constructor restrictions]
      // (https://code.google.com/p/v8/issues/detail?id=3330#c65)
      // we cannot currently emit actual ES6 constructors with super calls.
      // Instead we use the same trick as named constructors, and do them as
      // instance methods that perform initialization.
      // TODO(jmesserly): we'll need to rethink this once the ES6 spec and V8
      // settles. See <https://github.com/dart-lang/dev_compiler/issues/51>.
      // Performance of this pattern is likely to be bad.
      name = js.string('constructor', "'");
      // Mark the parameter as no-rename.
      var args = new JS.Identifier('arguments', allowRename: false);
      body = js.statement('''{
        // Get the class name for this instance.
        let name = this.constructor.name;
        // Call the default constructor.
        let init = this[name];
        let result = void 0;
        if (init) result = init.apply(this, #);
        return result === void 0 ? this : result;
      }''', args);
    } else {
      body = _emitConstructorBody(node, fields);
    }

    // We generate constructors as initializer methods in the class;
    // this allows use of `super` for instance methods/properties.
    // It also avoids V8 restrictions on `super` in default constructors.
    return new JS.Method(name, new JS.Fun(_visit(node.parameters), body))
      ..sourceInformation = node;
  }

  JS.Expression _constructorName(String className, SimpleIdentifier name) {
    if (name == null) return js.string(className, "'");
    return _emitMemberName(name.name, isStatic: true);
  }

  JS.Block _emitConstructorBody(
      ConstructorDeclaration node, List<FieldDeclaration> fields) {
    // Wacky factory redirecting constructors: factory Foo.q(x, y) = Bar.baz;
    if (node.redirectedConstructor != null) {
      return js.statement('{ return new #(#); }', [
        _visit(node.redirectedConstructor),
        _visit(node.parameters)
      ]);
    }

    var body = <JS.Statement>[];

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    var init = _emitArgumentInitializers(node.parameters);
    if (init != null) body.add(init);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers.firstWhere(
        (i) => i is RedirectingConstructorInvocation, orElse: () => null);

    if (redirectCall != null) {
      body.add(_visit(redirectCall));
      return new JS.Block(body);
    }

    // Initializers only run for non-factory constructors.
    if (node.factoryKeyword == null) {
      // Generate field initializers.
      // These are expanded into each non-redirecting constructor.
      // In the future we may want to create an initializer function if we have
      // multiple constructors, but it needs to be balanced against readability.
      body.add(_initializeFields(fields, node.parameters, node.initializers));

      var superCall = node.initializers.firstWhere(
          (i) => i is SuperConstructorInvocation, orElse: () => null);

      // If no superinitializer is provided, an implicit superinitializer of the
      // form `super()` is added at the end of the initializer list, unless the
      // enclosing class is class Object.
      var jsSuper = _superConstructorCall(node.parent, superCall);
      if (jsSuper != null) body.add(jsSuper);
    }

    body.add(_visit(node.body));
    return new JS.Block(body)..sourceInformation = node;
  }

  @override
  JS.Statement visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    ClassDeclaration classDecl = node.parent.parent;
    var className = classDecl.name.name;

    var name = _constructorName(className, node.constructorName);
    return js.statement('this.#(#);', [name, _visit(node.argumentList)]);
  }

  JS.Statement _superConstructorCall(ClassDeclaration clazz,
      [SuperConstructorInvocation node]) {
    var superCtorName = node != null ? node.constructorName : null;

    var element = clazz.element;
    if (superCtorName == null &&
        (element.type.isObject || element.supertype.isObject)) {
      return null;
    }

    var supertypeName = element.supertype.name;
    var name = _constructorName(supertypeName, superCtorName);

    var args = node != null ? _visit(node.argumentList) : [];
    return js.statement('super.#(#);', [name, args])..sourceInformation = node;
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  JS.Statement _initializeFields(List<FieldDeclaration> fields,
      [FormalParameterList parameters,
      NodeList<ConstructorInitializer> initializers]) {
    var body = <JS.Statement>[];

    // Run field initializers if they can have side-effects.
    var unsetFields = new Map<String, VariableDeclaration>();
    for (var declaration in fields) {
      for (var field in declaration.fields.variables) {
        if (_isFieldInitConstant(field)) {
          unsetFields[field.name.name] = field;
        } else {
          body.add(js.statement(
              '# = #;', [_visit(field.name), _visitInitializer(field)]));
        }
      }
    }

    // Initialize fields from `this.fieldName` parameters.
    if (parameters != null) {
      for (var p in parameters.parameters) {
        if (p is DefaultFormalParameter) p = p.parameter;
        if (p is FieldFormalParameter) {
          var name = p.identifier.name;
          body.add(
              js.statement('this.# = #;', [_emitMemberName(name), _visit(p)]));
          unsetFields.remove(name);
        }
      }
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (initializers != null) {
      for (var init in initializers) {
        if (init is ConstructorFieldInitializer) {
          body.add(js.statement(
              '# = #;', [_visit(init.fieldName), _visit(init.expression)]));
          unsetFields.remove(init.fieldName.name);
        }
      }
    }

    // Initialize all remaining fields
    unsetFields.forEach((name, field) {
      JS.Expression value;
      if (field.initializer != null) {
        value = _visit(field.initializer);
      } else {
        var type = rules.elementType(field.element);
        if (rules.maybeNonNullableType(type)) {
          value = js.call('dart.as(null, #)', _emitTypeName(type));
        } else {
          value = new JS.LiteralNull();
        }
      }
      body.add(js.statement('this.# = #;', [_emitMemberName(name), value]));
    });

    return _statement(body);
  }

  FormalParameterList _parametersOf(node) {
    // Note: ConstructorDeclaration is intentionally skipped here so we can
    // emit the argument initializers in a different place.
    // TODO(jmesserly): clean this up. If we can model ES6 spread/rest args, we
    // could handle argument initializers more consistently in a separate
    // lowering pass.
    if (node is MethodDeclaration) return node.parameters;
    if (node is FunctionDeclaration) node = node.functionExpression;
    if (node is FunctionExpression) return node.parameters;
    return null;
  }

  bool _hasArgumentInitializers(FormalParameterList parameters) {
    if (parameters == null) return false;
    return parameters.parameters.any((p) => p.kind != ParameterKind.REQUIRED);
  }

  JS.Statement _emitArgumentInitializers(FormalParameterList parameters) {
    if (parameters == null || !_hasArgumentInitializers(parameters)) {
      return null;
    }

    var body = [];
    for (var param in parameters.parameters) {
      // TODO(justinfagnani): rename identifier if necessary
      var name = param.identifier.name;

      if (param.kind == ParameterKind.NAMED) {
        body.add(js.statement('let # = # && # in # ? #.# : #;', [
          name,
          _namedArgTemp,
          js.string(name, "'"),
          _namedArgTemp,
          _namedArgTemp,
          name,
          _defaultParamValue(param),
        ]));
      } else if (param.kind == ParameterKind.POSITIONAL) {
        body.add(js.statement('if (# === void 0) # = #;', [
          name,
          name,
          _defaultParamValue(param)
        ]));
      }
    }
    return _statement(body);
  }

  JS.Expression _defaultParamValue(FormalParameter param) {
    if (param is DefaultFormalParameter && param.defaultValue != null) {
      return _visit(param.defaultValue);
    } else {
      return new JS.LiteralNull();
    }
  }

  JS.Method _emitMethodDeclaration(
      MethodDeclaration node, Iterable<InterfaceType> extensionTypes) {
    if (node.isAbstract || _externalOrNative(node)) {
      return null;
    }

    var params = _visit(node.parameters);
    if (params == null) params = [];

    var memberName;
    var extensionLibrary;

    if (!node.isStatic) {
      extensionLibrary = getExtensionLibrary(extensionTypes, node.name.name);
    }

    if (extensionLibrary != null) {
      var extensionMethodName = _extensionMethodName(node.name.name);
      if (extensionLibrary == libraryInfo.library.library) {
        // TODO(jacobr): need to do a better job ensuring that extension method
        // name symbols do not conflict with other symbols before we can let
        // user defined libraries define extension methods.
        if (_extensionMethodNames.add(extensionMethodName)) {
          _pendingExtensionMethodNames.add(extensionMethodName);
          _addExport(extensionMethodName);
        }
      }
      memberName = js.call('#.#', [
        _libraryName(extensionLibrary),
        js.string(extensionMethodName, "'")
      ]);
    } else {
      memberName = _emitMemberName(node.name.name, isStatic: node.isStatic);
    }
    return new JS.Method(memberName, new JS.Fun(params, _visit(node.body)),
        isGetter: node.isGetter,
        isSetter: node.isSetter,
        isStatic: node.isStatic);
  }

  @override
  JS.Statement visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.parent is CompilationUnit);

    if (_externalOrNative(node)) return null;

    if (node.isGetter || node.isSetter) {
      // Add these later so we can use getter/setter syntax.
      _properties.add(node);
      return null;
    }

    var body = <JS.Statement>[];
    _flushLibraryProperties(body);

    var name = node.name.name;
    body.add(js.comment('Function $name: ${node.element.type}'));

    body.add(new JS.FunctionDeclaration(
        new JS.Identifier(name), _visit(node.functionExpression)));

    if (isPublic(name)) _addExport(name);
    return _statement(body);
  }

  JS.Method _emitTopLevelProperty(FunctionDeclaration node) {
    var name = node.name.name;
    return new JS.Method(_propertyName(name), _visit(node.functionExpression),
        isGetter: node.isGetter, isSetter: node.isSetter);
  }

  @override
  JS.Expression visitFunctionExpression(FunctionExpression node) {
    var params = _visit(node.parameters);
    if (params == null) params = [];

    if (node.parent is FunctionDeclaration) {
      return new JS.Fun(params, _visit(node.body));
    } else {
      String code;
      AstNode body;
      var nodeBody = node.body;
      if (nodeBody is ExpressionFunctionBody) {
        code = '(#) => #';
        body = nodeBody.expression;
      } else {
        code = '(#) => { #; }';
        body = nodeBody;
      }
      return js.call(code, [params, _visit(body)]);
    }
  }

  @override
  JS.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    var name = new JS.Identifier(func.name.name);
    return new JS.Block([
      js.comment("// Function ${func.name.name}: ${func.element.type}\n"),
      new JS.FunctionDeclaration(name, _visit(func.functionExpression))
    ]);
  }

  /// Writes a simple identifier. This can handle implicit `this` as well as
  /// going through the qualified library name if necessary.
  @override
  JS.Expression visitSimpleIdentifier(SimpleIdentifier node) {
    var e = node.staticElement;
    if (e == null) {
      return js.commentExpression(
          'Unimplemented unknown name', new JS.Identifier(node.name));
    }

    var name = node.name;
    var variable = e is PropertyAccessorElement ? e.variable : e;

    // library member
    if (e.enclosingElement is CompilationUnitElement &&
        (e.library != libraryInfo.library ||
            variable is TopLevelVariableElement && !variable.isConst)) {
      return js.call('#.#', [_libraryName(e.library), name]);
    }

    // instance member
    if (currentClass != null && _needsImplicitThis(e)) {
      return js.call('this.#', _emitMemberName(name));
    }

    // static member
    if (e is ExecutableElement &&
        e.isStatic &&
        variable.enclosingElement is ClassElement) {
      var className = (variable.enclosingElement as ClassElement).name;
      return js.call('#.#', [className, _emitMemberName(name, isStatic: true)]);
    }

    // initializing formal parameter, e.g. `Point(this.x)`
    if (e is ParameterElement && e.isInitializingFormal && e.isPrivate) {
      /// Rename private names so they don't shadow the private field symbol.
      /// The renamer would handle this, but it would prefer to rename the
      /// temporary used for the private symbol. Instead rename the parameter.
      return new JSTemporary('${name.substring(1)}');
    }

    if (_isTemporary(e)) return new JSTemporary(e.name);

    return new JS.Identifier(name);
  }

  JS.Expression _emitTypeName(DartType type) {
    var name = type.name;
    var element = type.element;
    if (name == '') {
      // TODO(jmesserly): remove when we're using coercion reifier.
      return _unimplementedCall('Unimplemented type $type');
    }

    var typeArgs = null;
    if (type is ParameterizedType) {
      // TODO(jmesserly): this is a workaround for an analyzer bug, see:
      // https://github.com/dart-lang/dev_compiler/commit/a212d59ad046085a626dd8d16881cdb8e8b9c3fa
      if (type is! FunctionType || element is FunctionTypeAlias) {
        var args = type.typeArguments;
        if (args.any((a) => a != rules.provider.dynamicType)) {
          name = '$name\$';
          typeArgs = args.map(_emitTypeName);
        }
      }
    }

    JS.Expression result;
    if (_needQualifiedName(element)) {
      result = js.call('#.#', [_libraryName(element.library), name]);
    } else {
      result = new JS.Identifier(name);
    }

    if (typeArgs != null) {
      result = js.call('#(#)', [result, typeArgs]);
    }
    return result;
  }

  bool _needQualifiedName(Element element) {
    var lib = element.library;
    if (lib == null) return false;
    if (lib != currentLibrary) return true;
    if (element is ClassElement) return _lazyClass(element.type);
    if (element is FunctionTypeAliasElement) return _lazyClass(element.type);
    return false;
  }

  JS.Node _emitDSetIfDynamic(
      Expression target, SimpleIdentifier id, Expression rhs) {
    if (rules.isDynamicTarget(target)) {
      return js.call('dart.dput(#, #, #)', [
        _visit(target),
        js.string(id.name, "'"),
        _visit(rhs)
      ]);
    } else {
      return null;
    }
  }

  @override
  JS.Node visitAssignmentExpression(AssignmentExpression node) {
    var lhs = node.leftHandSide;
    var rhs = node.rightHandSide;
    return _emitSet(lhs, rhs, node.parent);
  }

  JS.Node _emitSet(Expression lhs, Expression rhs, [AstNode parent]) {
    if (lhs is IndexExpression) {
      String code;
      var target = _getTarget(lhs);
      if (rules.isDynamicTarget(target)) {
        code = 'dart.dsetindex(#, #, #)';
        return js.call(code, [_visit(target), _visit(lhs.index), _visit(rhs)]);
      }
      return js.call('#.#(#, #)', [
        _visit(target),
        _emitMemberName('[]=', target: target),
        _visit(lhs.index),
        _visit(rhs)
      ]);
    }

    if (lhs is PropertyAccess) {
      var result = _emitDSetIfDynamic(_getTarget(lhs), lhs.propertyName, rhs);
      if (result != null) return result;
    } else if (lhs is PrefixedIdentifier) {
      // TODO(vsm): Is this the right code if the prefix is a library?
      var result = _emitDSetIfDynamic(lhs.prefix, lhs.identifier, rhs);
      if (result != null) return result;
    }

    if (parent is ExpressionStatement &&
        rhs is CascadeExpression &&
        _isStateless(lhs, rhs)) {
      // Special case: cascade assignment to a variable in a statement.
      // We can reuse the variable to desugar it:
      //    result = []..length = length;
      // becomes:
      //    result = [];
      //    result.length = length;
      var savedCascadeTemp = _cascadeTarget;
      _cascadeTarget = lhs;

      var body = [];
      body.add(js.statement('# = #;', [_visit(lhs), _visit(rhs.target)]));
      for (var section in rhs.cascadeSections) {
        body.add(new JS.ExpressionStatement(_visit(section)));
      }

      _cascadeTarget = savedCascadeTemp;
      return _statement(body);
    }

    return js.call('# = #', [_visit(lhs), _visit(rhs)]);
  }

  @override
  JS.Block visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var initArgs = _emitArgumentInitializers(_parametersOf(node.parent));
    var ret = new JS.Return(_visit(node.expression));
    return new JS.Block(initArgs != null ? [initArgs, ret] : [ret]);
  }

  @override
  JS.Block visitEmptyFunctionBody(EmptyFunctionBody node) => new JS.Block([]);

  @override
  JS.Block visitBlockFunctionBody(BlockFunctionBody node) {
    var initArgs = _emitArgumentInitializers(_parametersOf(node.parent));
    var block = visitBlock(node.block);
    if (initArgs != null) return new JS.Block([initArgs, block]);
    return block;
  }

  @override
  JS.Block visitBlock(Block node) => new JS.Block(_visitList(node.statements));

  @override
  visitMethodInvocation(MethodInvocation node) {
    var target = node.isCascaded ? _cascadeTarget : node.target;

    var result = _emitForeignJS(node);
    if (result != null) return result;

    if (rules.isDynamicCall(node.methodName)) {
      var args = _visit(node.argumentList);
      if (target != null) {
        return js.call('dart.dinvoke(#, #, #)', [
          _visit(target),
          js.string(node.methodName.name, "'"),
          args
        ]);
      } else {
        return js.call('dart.dinvokef(#, #)', [_visit(node.methodName), args]);
      }
    }

    // TODO(jmesserly): if this resolves to a getter returning a function with
    // a call method, we don't generate the `.call` correctly.

    var targetJs;
    if (target != null) {
      targetJs = js.call('#.#', [
        _visit(target),
        _emitMemberName(node.methodName.name, target: target)
      ]);
    } else {
      targetJs = _visit(node.methodName);
    }

    return js.call('#(#)', [targetJs, _visit(node.argumentList)]);
  }

  /// Emits code for the `JS(...)` builtin.
  _emitForeignJS(MethodInvocation node) {
    var e = node.methodName.staticElement;
    if (e is FunctionElement &&
        e.library.name == '_foreign_helper' &&
        e.name == 'JS') {
      var args = node.argumentList.arguments;
      // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
      var code = args[1] as StringLiteral;

      var template = js.parseForeignJS(code.stringValue);
      var result = template.instantiate(_visitList(args.skip(2)));
      // `throw` is emitted as a statement by `parseForeignJS`.
      assert(result is JS.Expression || node.parent is ExpressionStatement);
      return result;
    }
    return null;
  }

  @override
  JS.Expression visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    var code;
    if (rules.isDynamicCall(node.function)) {
      code = 'dart.dinvokef(#, #)';
    } else {
      code = '#(#)';
    }
    return js.call(code, [_visit(node.function), _visit(node.argumentList)]);
  }

  @override
  List<JS.Expression> visitArgumentList(ArgumentList node) {
    var args = <JS.Expression>[];
    var named = <JS.Property>[];
    for (var arg in node.arguments) {
      if (arg is NamedExpression) {
        named.add(visitNamedExpression(arg));
      } else {
        args.add(_visit(arg));
      }
    }
    if (named.isNotEmpty) {
      args.add(new JS.ObjectInitializer(named));
    }
    return args;
  }

  @override
  JS.Property visitNamedExpression(NamedExpression node) {
    assert(node.parent is ArgumentList);
    return new JS.Property(
        _propertyName(node.name.label.name), _visit(node.expression));
  }

  @override
  List<JS.Identifier> visitFormalParameterList(FormalParameterList node) {
    var result = <JS.Identifier>[];
    for (FormalParameter param in node.parameters) {
      if (param.kind == ParameterKind.NAMED) {
        result.add(_namedArgTemp);
        break;
      }
      result.add(_visit(param));
    }
    return result;
  }

  @override
  JS.Statement visitExpressionStatement(ExpressionStatement node) =>
      _expressionStatement(_visit(node.expression));

  // Some expressions may choose to generate themselves as JS statements
  // if their parent is in a statement context.
  // TODO(jmesserly): refactor so we handle the special cases here, and
  // can use better return types on the expression visit methods.
  JS.Statement _expressionStatement(expr) =>
      expr is JS.Statement ? expr : new JS.ExpressionStatement(expr);

  @override
  JS.EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      new JS.EmptyStatement();

  @override
  JS.Statement visitAssertStatement(AssertStatement node) =>
      // TODO(jmesserly): only emit in checked mode.
      js.statement('dart.assert(#);', _visit(node.condition));

  @override
  JS.Return visitReturnStatement(ReturnStatement node) =>
      new JS.Return(_visit(node.expression));

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    var body = <JS.Statement>[];

    for (var field in node.variables.variables) {
      if (field.isConst) {
        // constant fields don't change, so we can generate them as `let`
        // but add them to the module's exports
        var name = field.name.name;
        body.add(js.statement(
            'let # = #;', [new JS.Identifier(name), _visitInitializer(field)]));
        if (isPublic(name)) _addExport(name);
      } else if (_isFieldInitConstant(field)) {
        body.add(js.statement(
            '# = #;', [_visit(field.name), _visitInitializer(field)]));
      } else {
        _lazyFields.add(field);
      }
    }

    return _statement(body);
  }

  _addExport(String name) {
    if (!_exports.add(name)) throw 'Duplicate top level name found: $name';
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    var last = node.variables.last;
    var lastInitializer = last.initializer;

    List<JS.VariableInitialization> variables;
    if (lastInitializer is CascadeExpression &&
        node.parent is VariableDeclarationStatement) {
      // Special case: cascade as variable initializer
      //
      // We can reuse the variable to desugar it:
      //    var result = []..length = length;
      // becomes:
      //    var result = [];
      //    result.length = length;
      var savedCascadeTemp = _cascadeTarget;
      _cascadeTarget = last.name;

      variables = _visitList(node.variables.take(node.variables.length - 1));
      variables.add(new JS.VariableInitialization(
          new JS.Identifier(last.name.name), _visit(lastInitializer.target)));

      var result =
          <JS.Expression>[new JS.VariableDeclarationList('let', variables)];
      result.addAll(_visitList(lastInitializer.cascadeSections));
      _cascadeTarget = savedCascadeTemp;
      return _statement(result.map((e) => new JS.ExpressionStatement(e)));
    } else {
      variables = _visitList(node.variables);
    }

    return new JS.VariableDeclarationList('let', variables);
  }

  @override
  JS.VariableInitialization visitVariableDeclaration(VariableDeclaration node) {
    var name = new JS.Identifier(node.name.name);
    return new JS.VariableInitialization(name, _visitInitializer(node));
  }

  JS.Expression _visitInitializer(VariableDeclaration node) {
    var value = _visit(node.initializer);
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    return value != null ? value : new JS.LiteralNull();
  }

  void _flushLazyFields(List<JS.Statement> body) {
    var code = _emitLazyFields(_exportsVar, _lazyFields);
    if (code != null) body.add(code);
    _lazyFields.clear();
  }

  JS.Statement _emitLazyFields(
      JS.Expression objExpr, List<VariableDeclaration> fields) {
    if (fields.isEmpty) return null;

    var methods = [];
    for (var node in fields) {
      var name = node.name.name;
      methods.add(new JS.Method(_propertyName(name),
          js.call('function() { return #; }', _visit(node.initializer)),
          isGetter: true));

      // TODO(jmesserly): use a dummy setter to indicate writable.
      if (!node.isFinal) {
        methods.add(new JS.Method(
            _propertyName(name), js.call('function(_) {}'), isSetter: true));
      }
    }

    return js.statement(
        'dart.defineLazyProperties(#, { # });', [objExpr, methods]);
  }

  void _flushLibraryProperties(List<JS.Statement> body) {
    if (_properties.isEmpty) return;
    body.add(js.statement('dart.copyProperties(#, { # });', [
      _exportsVar,
      _properties.map(_emitTopLevelProperty)
    ]));
    _properties.clear();
  }

  @override
  JS.Statement visitVariableDeclarationStatement(
          VariableDeclarationStatement node) =>
      _expressionStatement(_visit(node.variables));

  @override
  visitConstructorName(ConstructorName node) {
    var typeName = _visit(node.type);
    if (node.name != null) {
      return js.call(
          '#.#', [typeName, _emitMemberName(node.name.name, isStatic: true)]);
    }
    return typeName;
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    return js.call(
        'new #(#)', [_visit(node.constructorName), _visit(node.argumentList)]);
  }

  /// True if this type is built-in to JS, and we use the values unwrapped.
  /// For these types we generate a calling convention via static
  /// "extension methods". This allows types to be extended without adding
  /// extensions directly on the prototype.
  bool _isJSBuiltinType(DartType t) =>
      rules.isNumType(t) || rules.isStringType(t) || rules.isBoolType(t);

  bool typeIsPrimitiveInJS(DartType t) => !rules.isDynamic(t) &&
      (rules.isIntType(t) ||
          rules.isDoubleType(t) ||
          rules.isBoolType(t) ||
          rules.isNumType(t));

  bool typeIsNonNullablePrimitiveInJS(DartType t) =>
      typeIsPrimitiveInJS(t) && rules.isNonNullableType(t);

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) =>
      typeIsPrimitiveInJS(leftT) && typeIsPrimitiveInJS(rightT);

  bool unaryOperationIsPrimitive(DartType t) => typeIsPrimitiveInJS(t);

  bool _isNonNullableExpression(Expression expr) {
    // If the type is non-nullable, no further checking needed.
    if (rules.isNonNullableType(rules.getStaticType(expr))) return true;

    // TODO(vsm): Revisit whether we really need this when we get
    // better non-nullability in the type system.

    if (expr is Literal && expr is! NullLiteral) {
      return true;
    }
    if (expr is ParenthesizedExpression) {
      return _isNonNullableExpression(expr.expression);
    }
    DartType type = null;
    if (expr is BinaryExpression) {
      type = rules.getStaticType(expr.leftOperand);
    } else if (expr is PrefixExpression) {
      type = rules.getStaticType(expr.operand);
    } else if (expr is PostfixExpression) {
      type = rules.getStaticType(expr.operand);
    }
    if (type != null && typeIsPrimitiveInJS(type)) {
      return true;
    }
    if (expr is MethodInvocation) {
      // TODO(vsm): This logic overlaps with the resolver.
      // Where is the best place to put this?
      var e = expr.methodName.staticElement;
      if (e is FunctionElement &&
          e.library.name == '_foreign_helper' &&
          e.name == 'JS') {
        // Fix types for JS builtin calls.
        //
        // This code was taken from analyzer. It's not super sophisticated:
        // only looks for the type name in dart:core, so we just copy it here.
        //
        // TODO(jmesserly): we'll likely need something that can handle a wider
        // variety of types, especially when we get to JS interop.
        var args = expr.argumentList.arguments;
        if (args.isNotEmpty && args.first is SimpleStringLiteral) {
          var types = args.first.stringValue;
          if (!types.split('|').contains('Null')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  JS.Expression notNull(Expression expr) {
    if (_isNonNullableExpression(expr)) {
      return _visit(expr);
    } else {
      return js.call('dart.notNull(#)', _visit(expr));
    }
  }

  @override
  JS.Expression visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    var left = node.leftOperand;
    var right = node.rightOperand;
    var leftType = rules.getStaticType(left);
    var rightType = rules.getStaticType(right);

    var code;
    if (op.type.isEqualityOperator) {
      // If we statically know LHS or RHS is null we can generate a clean check.
      // We can also do this if both sides are the same primitive type.
      if (_canUsePrimitiveEquality(left, right)) {
        code = op.type == TokenType.EQ_EQ ? '# == #' : '# != #';
      } else {
        var bang = op.type == TokenType.BANG_EQ ? '!' : '';
        code = '${bang}dart.equals(#, #)';
      }
      return js.call(code, [_visit(left), _visit(right)]);
    } else if (binaryOperationIsPrimitive(leftType, rightType)) {
      // special cases where we inline the operation
      // these values are assumed to be non-null (determined by the checker)
      // TODO(jmesserly): it would be nice to just inline the method from core,
      // instead of special cases here.
      if (op.type == TokenType.TILDE_SLASH) {
        // `a ~/ b` is equivalent to `(a / b).truncate()`
        code = '(# / #).truncate()';
      } else {
        // TODO(vsm): When do Dart ops not map to JS?
        code = '# $op #';
      }
      return js.call(code, [notNull(left), notNull(right)]);
    } else {
      var opString = js.string(op.lexeme, "'");
      if (rules.isDynamicTarget(left)) {
        // dynamic dispatch
        return js.call(
            'dart.dbinary(#, #, #)', [_visit(left), opString, _visit(right)]);
      } else if (_isJSBuiltinType(leftType)) {
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
        return js.call('#.#(#, #)', [
          _emitTypeName(leftType),
          opString,
          _visit(left),
          _visit(right)
        ]);
      } else {
        // Generic static-dispatch, user-defined operator code path.
        return js.call('#.#(#)', [_visit(left), opString, _visit(right)]);
      }
    }
  }

  /// If the type [t] is [int] or [double], returns [num].
  /// Otherwise returns [t].
  DartType _canonicalizeNumTypes(DartType t) {
    var numType = rules.provider.numType;
    if (t is InterfaceType && t.superclass == numType) return numType;
    return t;
  }

  bool _canUsePrimitiveEquality(Expression left, Expression right) {
    if (_isNull(left) || _isNull(right)) return true;

    var leftType = _canonicalizeNumTypes(rules.getStaticType(left));
    var rightType = _canonicalizeNumTypes(rules.getStaticType(right));
    return _isJSBuiltinType(leftType) && leftType == rightType;
  }

  bool _isNull(Expression expr) => expr is NullLiteral;

  SimpleIdentifier _createTemporary(String name, DartType type) {
    // We use an invalid source location to signal that this is a temporary.
    // See [_isTemporary].
    // TODO(jmesserly): alternatives are
    // * (ab)use Element.isSynthetic, which isn't currently used for
    //   LocalVariableElementImpl, so we could repurpose to mean "temp".
    // * add a new property to LocalVariableElementImpl.
    // * create a new subtype of LocalVariableElementImpl to mark a temp.
    var id =
        new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, name, -1));
    id.staticElement = new LocalVariableElementImpl.forNode(id);
    id.staticType = type;
    return id;
  }

  bool _isTemporary(Element node) => node.nameOffset == -1;

  JS.Expression _emitPostfixIncrement(Expression expr, Token op) {
    var type = rules.getStaticType(expr);
    assert(type != null);
    var tmp = _createTemporary('x', type);

    // Increment and write
    var one = AstBuilder.integerLiteral(1);
    one.staticType = rules.provider.intType;
    var increment = AstBuilder.binaryExpression(tmp, op.lexeme[0], one);
    increment.staticType = type;
    var write = _emitSet(expr, increment);

    return js.call(
        "((#) => (#, #))(#)", [_visit(tmp), write, _visit(tmp), _visit(expr)]);
  }

  @override
  JS.Expression visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    if (node.parent is Statement) {
      // Prefix code is simpler.  If the expr result isn't used, fall to that.
      return _emitPrefixExpression(op, expr);
    }

    var dispatchType = rules.getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      if (_isNonNullableExpression(expr)) {
        return js.call('#$op', _visit(expr));
      }
    }

    assert(op.lexeme == '++' || op.lexeme == '--');
    return _emitPostfixIncrement(expr, op);
  }

  JS.Expression _emitPrefixIncrement(Token op, Expression expr) {
    var one = AstBuilder.integerLiteral(1);
    one.staticType = rules.provider.intType;
    var increment = AstBuilder.binaryExpression(expr, op.lexeme[0], one);
    return _emitSet(expr, increment);
  }

  @override
  JS.Expression visitPrefixExpression(PrefixExpression node) {
    return _emitPrefixExpression(node.operator, node.operand);
  }

  JS.Expression _emitPrefixExpression(Token op, Expression expr) {
    var dispatchType = rules.getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      if (_isNonNullableExpression(expr)) {
        return js.call('$op#', _visit(expr));
      } else if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var mathop = op.lexeme[0];
        return js.call('# = # $mathop 1', [_visit(expr), notNull(expr)]);
      } else {
        return js.call('$op#', notNull(expr));
      }
    } else {
      // Increment or decrement requires expansion.
      if (op.lexeme == '++' || op.lexeme == '--') {
        return _emitPrefixIncrement(op, expr);
      }
    }

    // Call the operator
    var opString = _emitMemberName(op.lexeme, unary: true);
    if (rules.isDynamicTarget(expr)) {
      // dynamic dispatch
      return js.call('dart.dunary(#, #)', [opString, _visit(expr)]);
    } else if (_isJSBuiltinType(dispatchType)) {
      return js.call(
          '#.#(#)', [_emitTypeName(dispatchType), opString, _visit(expr)]);
    } else {
      // Generic static-dispatch, user-defined operator code path.
      return js.call('#.#()', [_visit(expr), opString]);
    }
  }

  // Cascades can contain [IndexExpression], [MethodInvocation] and
  // [PropertyAccess]. The code generation for those is handled in their
  // respective visit methods.
  @override
  JS.Node visitCascadeExpression(CascadeExpression node) {
    var savedCascadeTemp = _cascadeTarget;

    var parent = node.parent;
    JS.Node result;
    if (_isStateless(node.target, node)) {
      // Special case: target is stateless, so we can just reuse it.
      _cascadeTarget = node.target;

      if (parent is ExpressionStatement) {
        var sections = _visitList(node.cascadeSections);
        result = _statement(sections.map((e) => new JS.ExpressionStatement(e)));
      } else {
        // Use comma expression. For example:
        //    (sb.write(1), sb.write(2), sb)
        var sections = _visitListToBinary(node.cascadeSections, ',');
        result = new JS.Binary(',', sections, _visit(_cascadeTarget));
      }
    } else {
      // In the general case we need to capture the target expression into
      // a temporary. This uses a lambda to get a temporary scope, and it also
      // remains valid in an expression context.
      _cascadeTarget = _createTemporary('_', node.target.staticType);

      var body = _visitList(node.cascadeSections);
      if (node.parent is! ExpressionStatement) {
        body.add(js.statement('return #;', _visit(_cascadeTarget)));
      }

      result = js.call('((#) => { # })(#)', [
        _visit(_cascadeTarget),
        body,
        _visit(node.target)
      ]);
    }

    _cascadeTarget = savedCascadeTemp;
    return result;
  }

  /// True is the expression can be evaluated multiple times without causing
  /// code execution. This is true for final fields. This can be true for local
  /// variables, if:
  ///
  /// * they are not assigned within the [context] scope.
  /// * they are not assigned in a function closure anywhere.
  ///
  /// This method is used to avoid creating temporaries in cases where we know
  /// we can safely re-evaluate [node] multiple times in [context]. This lets
  /// us generate prettier code.
  ///
  /// This method is conservative: it should never return `true` unless it is
  /// certain the [node] is stateless, because generated code may rely on the
  /// correctness of a `true` value. However it may return `false` for things
  /// that are in fact, stateless.
  bool _isStateless(Expression node, [AstNode context]) {
    if (node is SimpleIdentifier) {
      var e = node.staticElement;
      if (e is PropertyAccessorElement) e = e.variable;
      if (e is VariableElement && !e.isSynthetic) {
        if (e.isFinal) return true;

        // TODO(jmesserly): remove this when isPotentiallyMutated* is available
        // without the implementation class. Technically we shouldn't hit the
        // ParameterMember case based on current usage of _isStateless, but this
        // makes it clear we shouldn't rely on *Impl class.
        if (e is Member) e = e.baseElement;

        if (e is LocalVariableElementImpl || e is ParameterElementImpl) {
          // make sure the local isn't mutated in the context.
          return !_isPotentiallyMutated(e, context);
        }
      }
    }
    return false;
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) =>
      // The printer handles precedence so we don't need to.
      _visit(node.expression);

  @override
  visitFormalParameter(FormalParameter node) =>
      visitSimpleIdentifier(node.identifier);

  @override
  JS.This visitThisExpression(ThisExpression node) => new JS.This();

  @override
  JS.Super visitSuperExpression(SuperExpression node) => new JS.Super();

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.staticElement is PrefixElement) {
      return _visit(node.identifier);
    } else {
      return _emitGet(node.prefix, node.identifier);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) =>
      _emitGet(_getTarget(node), node.propertyName);

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  _emitGet(Expression target, SimpleIdentifier name) {
    if (rules.isDynamicTarget(target)) {
      return js.call(
          'dart.dload(#, #)', [_visit(target), js.string(name.name, "'")]);
    } else {
      var e = name.staticElement;
      var ret = js.call('#.#', [
        _visit(target),
        _emitMemberName(name.name,
            isStatic: e is ExecutableElement && e.isStatic, target: target)
      ]);
      return ret;
    }
  }

  @override
  visitIndexExpression(IndexExpression node) {
    var target = _getTarget(node);
    if (rules.isDynamicTarget(target)) {
      return js.call('dart.dindex(#, #)', [_visit(target), _visit(node.index)]);
    }

    return js.call('#.#(#)', [
      _visit(target),
      _emitMemberName('[]', target: target),
      _visit(node.index)
    ]);
  }

  /// Gets the target of a [PropertyAccess] or [IndexExpression].
  /// Those two nodes are special because they're both allowed on left side of
  /// an assignment expression and cascades.
  Expression _getTarget(node) {
    assert(node is IndexExpression || node is PropertyAccess);
    return node.isCascaded ? _cascadeTarget : node.target;
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visit(node.condition),
      _visit(node.thenExpression),
      _visit(node.elseExpression)
    ]);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    var expr = _visit(node.expression);
    if (node.parent is ExpressionStatement) {
      return js.statement('throw #;', expr);
    } else {
      return js.call('dart.throw_(#)', expr);
    }
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    if (node.parent is ExpressionStatement) {
      return js.statement('throw #;', _visit(_catchParameter));
    } else {
      return js.call('dart.throw_(#)', _visit(_catchParameter));
    }
  }

  @override
  JS.If visitIfStatement(IfStatement node) {
    return new JS.If(_visit(node.condition), _visit(node.thenStatement),
        _visit(node.elseStatement));
  }

  @override
  JS.For visitForStatement(ForStatement node) {
    var init = _visit(node.initialization);
    if (init == null) init = _visit(node.variables);
    return new JS.For(init, _visit(node.condition),
        _visitListToBinary(node.updaters, ','), _visit(node.body));
  }

  @override
  JS.While visitWhileStatement(WhileStatement node) {
    return new JS.While(_visit(node.condition), _visit(node.body));
  }

  @override
  JS.Do visitDoStatement(DoStatement node) {
    return new JS.Do(_visit(node.body), _visit(node.condition));
  }

  @override
  JS.ForOf visitForEachStatement(ForEachStatement node) {
    var init = _visit(node.identifier);
    if (init == null) {
      init = js.call('let #', node.loopVariable.identifier.name);
    }
    return new JS.ForOf(init, _visit(node.iterable), _visit(node.body));
  }

  @override
  visitBreakStatement(BreakStatement node) {
    var label = node.label;
    return new JS.Break(label != null ? label.name : null);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    var label = node.label;
    return new JS.Continue(label != null ? label.name : null);
  }

  @override
  visitTryStatement(TryStatement node) {
    return new JS.Try(_visit(node.body), _visitCatch(node.catchClauses),
        _visit(node.finallyBlock));
  }

  _visitCatch(NodeList<CatchClause> clauses) {
    if (clauses == null || clauses.isEmpty) return null;

    // TODO(jmesserly): need a better way to get a temporary variable.
    // This could incorrectly shadow a user's name.
    var savedCatch = _catchParameter;

    if (clauses.length == 1) {
      // Special case for a single catch.
      _catchParameter = clauses.single.exceptionParameter;
    } else {
      _catchParameter = _createTemporary('e', rules.provider.dynamicType);
    }

    JS.Statement catchBody = null;
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(clause, catchBody);
    }

    var catchVarDecl = _visit(_catchParameter);
    _catchParameter = savedCatch;
    return new JS.Catch(catchVarDecl, new JS.Block([catchBody]));
  }

  JS.Statement _catchClauseGuard(CatchClause clause, JS.Statement otherwise) {
    var then = visitCatchClause(clause);

    // Discard following clauses, if any, as they are unreachable.
    if (clause.exceptionType == null) return then;

    // TODO(jmesserly): this is inconsistent with [visitIsExpression], which
    // has special case for typeof.
    return new JS.If(js.call('dart.is(#, #)', [
      _visit(_catchParameter),
      _emitTypeName(clause.exceptionType.type),
    ]), then, otherwise);
  }

  JS.Statement _statement(Iterable stmts) {
    var s = stmts is List ? stmts : new List<JS.Statement>.from(stmts);
    // TODO(jmesserly): empty block singleton?
    if (s.length == 0) return new JS.Block([]);
    if (s.length == 1) return s[0];
    return new JS.Block(s);
  }

  /// Visits the catch clause body. This skips the exception type guard, if any.
  /// That is handled in [_visitCatch].
  @override
  JS.Statement visitCatchClause(CatchClause node) {
    var body = [];

    var savedCatch = _catchParameter;
    if (node.catchKeyword != null) {
      var name = node.exceptionParameter;
      if (name != null && name != _catchParameter) {
        body.add(js.statement(
            'let # = #;', [_visit(name), _visit(_catchParameter)]));
        _catchParameter = name;
      }
      if (node.stackTraceParameter != null) {
        var stackVar = node.stackTraceParameter.name;
        body.add(js.statement(
            'let # = dart.stackTrace(#);', [stackVar, _visit(name)]));
      }
    }

    body.add(_visit(node.body));
    _catchParameter = savedCatch;
    return _statement(body);
  }

  @override
  JS.Case visitSwitchCase(SwitchCase node) {
    var expr = _visit(node.expression);
    var body = _visitList(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return new JS.Case(expr, new JS.Block(body));
  }

  @override
  JS.Default visitSwitchDefault(SwitchDefault node) {
    var body = _visitList(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return new JS.Default(new JS.Block(body));
  }

  @override
  JS.Switch visitSwitchStatement(SwitchStatement node) =>
      new JS.Switch(_visit(node.expression), _visitList(node.members));

  @override
  JS.Statement visitLabeledStatement(LabeledStatement node) {
    var result = _visit(node.statement);
    for (var label in node.labels.reversed) {
      result = new JS.LabeledStatement(label.label.name, result);
    }
    return result;
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) => js.number(node.value);

  @override
  visitDoubleLiteral(DoubleLiteral node) => js.number(node.value);

  @override
  visitNullLiteral(NullLiteral node) => new JS.LiteralNull();

  @override
  visitListLiteral(ListLiteral node) {
    // TODO(jmesserly): make this faster. We're wasting an array.
    var list = js.call('new #.from(#)', [
      _emitTypeName(node.staticType),
      new JS.ArrayInitializer(_visitList(node.elements))
    ]);
    if (node.constKeyword != null) {
      list = js.commentExpression('Unimplemented const', list);
    }
    return list;
  }

  @override
  visitMapLiteral(MapLiteral node) {
    var entries = node.entries;
    var mapArguments = null;
    if (entries.isEmpty) return js.call('dart.map()');

    // Use JS object literal notation if possible, otherwise use an array.
    // We could do this any time all keys are non-nullable String type.
    // For now, support StringLiteral as the common non-nullable String case.
    if (entries.every((e) => e.key is StringLiteral)) {
      var props = [];
      for (var e in entries) {
        props.add(new JS.Property(_visit(e.key), _visit(e.value)));
      }
      mapArguments = new JS.ObjectInitializer(props);
    } else {
      var values = [];
      for (var e in entries) {
        values.add(_visit(e.key));
        values.add(_visit(e.value));
      }
      mapArguments = new JS.ArrayInitializer(values);
    }
    return js.call('dart.map(#)', [mapArguments]);
  }

  @override
  JS.LiteralString visitSimpleStringLiteral(SimpleStringLiteral node) =>
      js.escapedString(node.value, node.isSingleQuoted ? "'" : '"');

  @override
  JS.Expression visitAdjacentStrings(AdjacentStrings node) =>
      _visitListToBinary(node.strings, '+');

  @override
  JS.TemplateString visitStringInterpolation(StringInterpolation node) {
    // Assuming we implement toString() on our objects, we can avoid calling it
    // in most cases. Builtin types may differ though. We could handle this with
    // a tagged template.
    return new JS.TemplateString(_visitList(node.elements));
  }

  @override
  String visitInterpolationString(InterpolationString node) {
    // TODO(jmesserly): this call adds quotes, and then we strip them off.
    var str = js.escapedString(node.value, '`').value;
    return str.substring(1, str.length - 1);
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) =>
      _visit(node.expression);

  @override
  visitBooleanLiteral(BooleanLiteral node) => js.boolean(node.value);

  @override
  JS.Expression visitExpression(Expression node) =>
      _unimplementedCall('Unimplemented ${node.runtimeType}: $node');

  @override
  JS.Statement visitYieldStatement(YieldStatement node) =>
      _unimplementedCall('Unimplemented yield: $node').toStatement();

  JS.Expression _unimplementedCall(String comment) {
    return js.call('dart.throw_(#)', [js.escapedString(comment)]);
  }

  @override
  visitNode(AstNode node) {
    // TODO(jmesserly): verify this is unreachable.
    throw 'Unimplemented ${node.runtimeType}: $node';
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

  _visit(AstNode node) {
    if (node == null) return null;
    var result = node.accept(this);
    if (result is JS.Node) result.sourceInformation = node;
    return result;
  }

  List _visitList(Iterable<AstNode> nodes) {
    if (nodes == null) return null;
    var result = [];
    for (var node in nodes) result.add(_visit(node));
    return result;
  }

  /// Visits a list of expressions, creating a comma expression if needed in JS.
  JS.Expression _visitListToBinary(List<Expression> nodes, String operator) {
    if (nodes == null || nodes.isEmpty) return null;

    JS.Expression result = null;
    for (var node in nodes) {
      var jsExpr = _visit(node);
      if (result == null) {
        result = jsExpr;
      } else {
        result = new JS.Binary(operator, result, jsExpr);
      }
    }
    return result;
  }

  /// This handles member renaming for private names and operators.
  ///
  /// Private names are generated using ES6 symbols:
  ///
  ///     // At the top of the module:
  ///     let _x = Symbol('_x');
  ///     let _y = Symbol('_y');
  ///     ...
  ///
  ///     class Point {
  ///       Point(x, y) {
  ///         this[_x] = x;
  ///         this[_y] = y;
  ///       }
  ///       get x() { return this[_x]; }
  ///       get y() { return this[_y]; }
  ///     }
  ///
  /// For user-defined operators the following names are allowed:
  ///
  ///     <, >, <=, >=, ==, -, +, /, ˜/, *, %, |, ˆ, &, <<, >>, []=, [], ˜
  ///
  /// They generate code like:
  ///
  ///     x['+'](y)
  ///
  /// There are three exceptions: [], []= and unary -.
  /// The indexing operators we use `get` and `set` instead:
  ///
  ///     x.get('hi')
  ///     x.set('hi', 123)
  ///
  /// This follows the same pattern as EcmaScript 6 Map:
  /// <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map>
  ///
  /// Unary minus looks like: `x['unary-']()`. Note that [unary] must be passed
  /// for this transformation to happen, otherwise binary minus is assumed.
  ///
  /// Equality is a bit special, it is generated via the Dart `equals` runtime
  /// helper, that checks for null. The user defined method is called '=='.
  ///
  JS.Expression _emitMemberName(String name,
      {bool unary: false, bool isStatic: false, Expression target}) {
    if (isStatic == false && target != null) {
      var ret = nameIfExtension(target, name);
      if (ret != null) return ret;
    }
    if (name.startsWith('_')) {
      if (_privateNames.add(name)) _pendingPrivateNames.add(name);
      return new JSTemporary(name);
    }
    return _propertyName(_jsMemberName(name, unary: unary, isStatic: isStatic));
  }

  String _jsMemberName(String name, {bool unary: false, bool isStatic: false}) {
    if (name == '[]') return 'get';
    if (name == '[]=') return 'set';
    if (unary && name == '-') return 'unary-';
    if (isStatic && invalidJSStaticMethodName(name)) {
      // Choose an string name. Use an invalid identifier so it won't conflict
      // with any valid member names.
      // TODO(jmesserly): this works around the problem, but I'm pretty sure we
      // don't need it, as static methods seemed to work. The only concrete
      // issue we saw was in the defineNamedConstructor helper function.
      return '$name*';
    }
    return name;
  }

  JS.LiteralString _emitExtensionMethodName(String name) =>
      js.string(_extensionMethodName(name), "'");

  String _extensionMethodName(String name) => '\$${_jsMemberName(name)}';

  bool _externalOrNative(node) =>
      node.externalKeyword != null || _functionBody(node) is NativeFunctionBody;

  FunctionBody _functionBody(node) =>
      node is FunctionDeclaration ? node.functionExpression.body : node.body;

  /// Choose a canonical name from the library element.
  /// This never uses the library's name (the identifier in the `library`
  /// declaration) as it doesn't have any meaningful rules enforced.
  JS.Identifier _libraryName(LibraryElement library) {
    if (library == libraryInfo.library) return _exportsVar;
    return new JS.Identifier(jsLibraryName(library));
  }

  static bool _needsImplicitThis(Element e) =>
      e is PropertyAccessorElement && !e.variable.isStatic ||
          e is ClassMemberElement && !e.isStatic && e is! ConstructorElement;
}

/// Returns true if the local variable is potentially mutated within [context].
/// This accounts for closures that may have been created outside of [context].
// TODO(jmesserly): change type annotation to not be *Impl once
// isPotentiallyMutated is available on VariableElement.
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

class JSGenerator extends CodeGenerator {
  final JSCodeOptions options;

  JSGenerator(String outDir, Uri root, TypeRules rules, this.options)
      : super(outDir, root, rules);

  String generateLibrary(
      LibraryUnit unit, LibraryInfo info, CheckerReporter reporter) {
    var jsTree = new JSCodegenVisitor(info, rules, reporter).emitLibrary(unit);

    var outputPath = path.join(outDir, jsOutputPath(info, root));
    new Directory(path.dirname(outputPath)).createSync(recursive: true);

    if (options.emitSourceMaps) {
      var outFilename = path.basename(outputPath);
      var printer = new srcmaps.Printer(outFilename);
      _writeNode(
          new SourceMapPrintingContext(printer, path.dirname(outputPath)),
          jsTree);
      printer.add('//# sourceMappingURL=$outFilename.map');
      // Write output file and source map
      var text = printer.text;
      new File(outputPath).writeAsStringSync(text);
      new File('$outputPath.map').writeAsStringSync(printer.map);
      return computeHash(text);
    } else {
      var text = jsNodeToString(jsTree);
      new File(outputPath).writeAsStringSync(text);
      return computeHash(text);
    }
  }
}

void _writeNode(JS.JavaScriptPrintingContext context, JS.Node node) {
  var opts = new JS.JavaScriptPrintingOptions(allowKeywordsInProperties: true);
  node.accept(new JS.Printer(opts, context, localNamer: new JSNamer(node)));
}

/// This is a debugging helper to print a JS node.
String jsNodeToString(JS.Node node) {
  var context = new JS.SimpleJavaScriptPrintingContext();
  _writeNode(context, node);
  return context.getText();
}

/// Choose a canonical name from the library element.
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(LibraryElement library) => canonicalLibraryName(library);

/// Shorthand for identifier-like property names.
/// For now, we emit them as strings and the printer restores them to
/// identifiers if it can.
// TODO(jmesserly): avoid the round tripping through quoted form.
JS.LiteralString _propertyName(String name) => js.string(name, "'");

/// Path to file that will be generated for [info]. In case it's url is a
/// `file:` url, we use [root] to determine the relative path from the entry
/// point file.
String jsOutputPath(LibraryInfo info, Uri root) {
  var uri = info.library.source.uri;
  var filepath = '${path.withoutExtension(uri.path)}.js';
  if (uri.scheme == 'dart') {
    filepath = 'dart/$filepath';
  } else if (uri.scheme == 'file') {
    filepath = path.relative(filepath, from: path.dirname(root.path));
  } else {
    assert(uri.scheme == 'package');
    // filepath is good here, we want the output to start with a directory
    // matching the package name.
  }
  return filepath;
}

class SourceMapPrintingContext extends JS.JavaScriptPrintingContext {
  final srcmaps.Printer printer;
  final String outputDir;

  CompilationUnit unit;
  Uri uri;

  SourceMapPrintingContext(this.printer, this.outputDir);

  void emit(String string) {
    printer.add(string);
  }

  void enterNode(JS.Node jsNode) {
    AstNode node = jsNode.sourceInformation;
    if (node is CompilationUnit) {
      unit = node;
      uri = _makeRelativeUri(unit.element.source.uri);
      return;
    }
    if (unit == null || node == null || node.offset == -1) return;

    var loc = _location(node.offset);
    var name = _getIdentifier(node);
    if (name != null) {
      // TODO(jmesserly): mark only uses the beginning of the span, but
      // we're required to pass this as a valid span.
      var end = _location(node.end);
      printer.mark(new SourceMapSpan(loc, end, name, isIdentifier: true));
    } else {
      printer.mark(loc);
    }
  }

  SourceLocation _location(int offset) => locationForOffset(unit, uri, offset);

  Uri _makeRelativeUri(Uri src) {
    return new Uri(path: path.relative(src.path, from: outputDir));
  }

  void exitNode(JS.Node jsNode) {
    AstNode node = jsNode.sourceInformation;
    if (node is CompilationUnit) {
      unit = null;
      uri = null;
      return;
    }
    if (unit == null || node == null || node.offset == -1) return;

    // TODO(jmesserly): in many cases marking the end will be unncessary.
    printer.mark(_location(node.end));
  }

  String _getIdentifier(AstNode node) {
    if (node is SimpleIdentifier) return node.name;
    return null;
  }
}
