// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.js_codegen;

import 'dart:collection' show HashSet, HashMap;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/scanner.dart'
    show StringToken, Token, TokenType;
import 'package:path/path.dart' as path;

import 'package:dev_compiler/src/codegen/ast_builder.dart' show AstBuilder;
import 'package:dev_compiler/src/codegen/reify_coercions.dart'
    show CoercionReifier;

// TODO(jmesserly): import from its own package
import 'package:dev_compiler/src/js/js_ast.dart' as JS;
import 'package:dev_compiler/src/js/js_ast.dart' show js;

import 'package:dev_compiler/src/checker/rules.dart';
import 'package:dev_compiler/src/dependency_graph.dart';
import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/utils.dart';

import 'code_generator.dart';
import 'js_field_storage.dart';
import 'js_names.dart' as JS;
import 'js_metalet.dart' as JS;
import 'js_printer.dart' show writeJsLibrary;
import 'side_effect_analysis.dart';

// Various dynamic helpers we call.
// If renaming these, make sure to check other places like the
// dart_runtime.js file and comments.
// TODO(jmesserly): ideally we'd have a "dynamic call" dart library we can
// import and generate calls to, rather than dart_runtime.js
const DPUT = 'dput';
const DLOAD = 'dload';
const DINDEX = 'dindex';
const DSETINDEX = 'dsetindex';
const DCALL = 'dcall';
const DSEND = 'dsend';

class JSCodegenVisitor extends GeneralizingAstVisitor with ConversionVisitor {
  final CompilerOptions options;
  final TypeRules rules;
  final LibraryInfo libraryInfo;

  /// The global extension method table.
  final HashMap<String, List<InterfaceType>> _extensionMethods;

  /// Information that is precomputed for this library, indicates which fields
  /// need storage slots.
  final HashSet<FieldElement> _fieldsNeedingStorage;

  /// The variable for the target of the current `..` cascade expression.
  SimpleIdentifier _cascadeTarget;

  /// The variable for the current catch clause
  SimpleIdentifier _catchParameter;

  ConstantEvaluator _constEvaluator;

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<LibraryElement, JS.TemporaryId>();
  final _exports = new Set<String>();
  final _lazyFields = <VariableDeclaration>[];
  final _properties = <FunctionDeclaration>[];
  final _privateNames = new HashMap<String, JS.TemporaryId>();
  final _extensionMethodNames = new HashSet<String>();
  final _pendingStatements = <JS.Statement>[];
  final _temps = new HashMap<Element, JS.TemporaryId>();

  /// The name for the library's exports inside itself.
  /// `exports` was chosen as the most similar to ES module patterns.
  final _exportsVar = new JS.TemporaryId('exports');
  final _namedArgTemp = new JS.TemporaryId('opts');

  /// Classes we have not emitted yet. Values can be [ClassDeclaration] or
  /// [ClassTypeAlias].
  final _pendingClasses = new HashMap<Element, CompilationUnitMember>();

  /// Memoized results of [_lazyClass].
  final _lazyClassMemo = new HashMap<Element, bool>();

  /// Memoized results of [_inLibraryCycle].
  final _libraryCycleMemo = new HashMap<LibraryElement, bool>();

  JSCodegenVisitor(this.options, this.rules, this.libraryInfo,
      this._extensionMethods, this._fieldsNeedingStorage);

  LibraryElement get currentLibrary => libraryInfo.library;
  TypeProvider get types => rules.provider;

  JS.Program emitLibrary(LibraryUnit library) {
    String jsDefaultValue = null;

    // Modify the AST to make coercions explicit.
    new CoercionReifier(library, rules, options).reify();

    var unit = library.library;
    if (unit.directives.isNotEmpty) {
      var libraryDir = unit.directives.first;
      if (libraryDir is LibraryDirective) {
        var jsName = getAnnotationValue(libraryDir, _isJsNameAnnotation);
        jsDefaultValue = getConstantField(jsName, 'name', types.stringType);
      }
    }
    if (jsDefaultValue == null) jsDefaultValue = '{}';

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

    var name = new JS.Identifier(jsLibraryName(currentLibrary));

    // TODO(jmesserly): it would be great to run the renamer on the body,
    // then figure out if we really need each of these parameters.
    // See ES6 modules: https://github.com/dart-lang/dev_compiler/issues/34
    var program = [
      js.statement('var # = dart.defineLibrary(#, #);', [
        name,
        name,
        js.call(jsDefaultValue)
      ])
    ];

    var params = [_exportsVar];
    var args = [name];
    _imports.forEach((library, temp) {
      var name = new JS.Identifier(temp.name);
      params.add(temp);
      args.add(name);
      var helper = _libraryMightNotBeLoaded(library) ? 'lazyImport' : 'import';
      program.add(js.statement('var # = dart.#(#);', [name, helper, name]));
    });

    program.add(js.statement(
        "(function(#) { 'use strict'; #; })(#);", [params, body, args]));

    return new JS.Program(program);
  }

  JS.Identifier _initSymbol(JS.Identifier id) {
    var s = js.statement('let # = $_SYMBOL(#);', [id, js.string(id.name, "'")]);
    _pendingStatements.add(s);
    return id;
  }

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

    _constEvaluator = new ConstantEvaluator(source, types);

    // TODO(jmesserly): scriptTag, directives.
    var body = <JS.Statement>[];
    for (var child in node.declarations) {
      // Attempt to group adjacent fields/properties.
      if (child is! TopLevelVariableDeclaration) _flushLazyFields(body);
      if (child is! FunctionDeclaration) _flushLibraryProperties(body);

      var code = _visit(child);
      if (code != null) {
        _flushPendingStatements(body);
        body.add(code);
      }
    }

    // Flush any unwritten fields/properties.
    _flushLazyFields(body);
    _flushLibraryProperties(body);

    assert(_pendingStatements.isEmpty);
    return _statement(body);
  }

  bool isPublic(String name) => !name.startsWith('_');

  /// Conversions that we don't handle end up here.
  @override
  visitConversion(Conversion node) {
    throw 'Unlowered conversion ${node.runtimeType}: $node';
  }

  @override
  visitAsExpression(AsExpression node) {
    var from = getStaticType(node.expression);
    var to = node.type.type;

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

    var name = type.name;
    var result = js.statement('let # = dart.typedef(#, () => #);', [
      new JS.Identifier(name),
      js.string(name, "'"),
      _emitTypeName(node.element.type, lowerTypedef: true)
    ]);

    return _finishClassDef(type, result);
  }

  @override
  JS.Expression visitTypeName(TypeName node) => _emitTypeName(node.type);

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    // If we've already emitted this class, skip it.
    var type = node.element.type;
    if (_pendingClasses.remove(node.element) == null) return null;

    var name = node.name.name;
    var classDecl = new JS.ClassDeclaration(new JS.ClassExpression(
        new JS.Identifier(name), _classHeritage(node), []));

    return _finishClassDef(type, classDecl);
  }

  JS.Statement _emitJsType(String dartClassName, DartObjectImpl jsName) {
    var jsTypeName = getConstantField(jsName, 'name', types.stringType);

    if (jsTypeName != null && jsTypeName != dartClassName) {
      // We export the JS type as if it was a Dart type. For example this allows
      // `dom.InputElement` to actually be HTMLInputElement.
      // TODO(jmesserly): if we had the JsName on the Element, we could just
      // generate it correctly when we refer to it.
      if (isPublic(dartClassName)) _addExport(dartClassName);
      return js.statement('let # = #;', [dartClassName, jsTypeName]);
    }
    return null;
  }

  @override
  JS.Statement visitClassDeclaration(ClassDeclaration node) {
    // If we've already emitted this class, skip it.
    var classElem = node.element;
    var type = classElem.type;
    if (_pendingClasses.remove(classElem) == null) return null;

    var jsName = getAnnotationValue(node, _isJsNameAnnotation);

    if (jsName != null) return _emitJsType(node.name.name, jsName);

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

    String jsPeerName;
    var jsPeer = getAnnotationValue(node, _isJsPeerInterface);
    if (jsPeer != null) {
      jsPeerName = getConstantField(jsPeer, 'name', types.stringType);
    }

    var body = _finishClassMembers(
        classElem, classExpr, ctors, fields, staticFields, jsPeerName);

    var result = _finishClassDef(type, body);

    if (jsPeerName != null) {
      // This class isn't allowed to be lazy, because we need to set up
      // the native JS type eagerly at this point.
      // If we wanted to support laziness, we could defer the hookup until
      // the end of the Dart library cycle load.
      assert(!_lazyClass(type));

      // TODO(jmesserly): this copies the dynamic members.
      // Probably fine for objects coming from JS, but not if we actually
      // want to support construction of instances with generic types other
      // than dynamic. See issue #154 for Array and List<E> related bug.
      var copyMembers = js.statement(
          'dart.registerExtension(dart.global.#, #);', [
        _propertyName(jsPeerName),
        classElem.name
      ]);
      return _statement([result, copyMembers]);
    }
    return result;
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
          _propertyName(name),
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
      _emitClassIfNeeded(classDefs, types.functionType);
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
      result = _typeMightNotBeLoaded(types.functionType);
    }
    return _lazyClassMemo[type.element] = result;
  }

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
    return _libraryMightNotBeLoaded(library);
  }

  bool _libraryMightNotBeLoaded(LibraryElement library) {
    // The SDK is a special case: we optimize the order to prevent laziness.
    if (library.isInSdk) {
      // SDK is loaded before non-SDK libraies
      if (!currentLibrary.isInSdk) return false;

      // Compute the order of both SDK libraries. If unknown, assume it's after.
      var classOrder = corelibOrder.indexOf(library.name);
      if (classOrder == -1) classOrder = corelibOrder.length;

      var currentOrder = corelibOrder.indexOf(currentLibrary.name);
      if (currentOrder == -1) currentOrder = corelibOrder.length;

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

  JS.Expression _classHeritage(node) {
    if (node.element.type.isObject) return null;

    DartType supertype;
    if (node is ClassDeclaration) {
      var ext = node.extendsClause;
      supertype = ext != null ? ext.superclass.type : types.objectType;
    } else {
      supertype = (node as ClassTypeAlias).superclass.type;
    }

    JS.Expression heritage = _emitTypeName(supertype);

    if (node.withClause != null) {
      var mixins = _visitList(node.withClause.mixinTypes);
      mixins.insert(0, heritage);
      heritage = js.call('dart.mixin(#)', [mixins]);
    }

    return heritage;
  }

  List<JS.Method> _emitClassMethods(ClassDeclaration node,
      List<ConstructorDeclaration> ctors, List<FieldDeclaration> fields) {
    var element = node.element;
    var type = element.type;
    var isObject = type.isObject;
    var name = node.name.name;

    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    var jsMethods = <JS.Method>[];
    if (ctors.isEmpty && !isObject) {
      jsMethods.add(_emitImplicitConstructor(node, name, fields));
    }

    bool hasJsPeer = getAnnotationValue(node, _isJsPeerInterface) != null;

    bool hasIterator = false;
    for (var m in node.members) {
      if (m is ConstructorDeclaration) {
        jsMethods.add(_emitConstructor(m, name, fields, isObject));
      } else if (m is MethodDeclaration) {
        jsMethods.add(_emitMethodDeclaration(type, m));

        if (!hasJsPeer && m.isGetter && m.name.name == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(type));
        }
      }
    }

    // If the type doesn't have an `iterator`, but claims to implement Iterable,
    // we inject the adaptor method here, as it's less code size to put the
    // helper on a parent class. This pattern is common in the core libraries
    // (e.g. IterableMixin<E> and IterableBase<E>).
    //
    // (We could do this same optimization for any interface with an `iterator`
    // method, but that's more expensive to check for, so it doesn't seem worth
    // it. The above case for an explicit `iterator` method will catch those.)
    if (!hasJsPeer && !hasIterator && _implementsIterable(type)) {
      jsMethods.add(_emitIterable(type));
    }

    return jsMethods.where((m) => m != null).toList(growable: false);
  }

  bool _implementsIterable(InterfaceType t) =>
      t.interfaces.any((i) => i.element.type == types.iterableType);

  /// Support for adapting dart:core Iterable to ES6 versions.
  ///
  /// This lets them use for-of loops transparently:
  /// <https://github.com/lukehoban/es6features#iterators--forof>
  ///
  /// This will return `null` if the adapter was already added on a super type,
  /// otherwise it returns the adapter code.
  // TODO(jmesserly): should we adapt `Iterator` too?
  JS.Method _emitIterable(InterfaceType t) {
    // If a parent had an `iterator` (concrete or abstract) or implements
    // Iterable, we know the adapter is already there, so we can skip it as a
    // simple code size optimization.
    var parent = t.lookUpGetterInSuperclass('iterator', t.element.library);
    if (parent != null) return null;
    parent = findSupertype(t, _implementsIterable);
    if (parent != null) return null;

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return new JS.Method(js.call('$_SYMBOL.iterator'), js.call(
        'function() { return new dart.JsIterator(this.#); }',
        [_emitMemberName('iterator', type: t)]));
  }

  /// Emit class members that need to come after the class declaration, such
  /// as static fields. See [_emitClassMethods] for things that are emitted
  /// inside the ES6 `class { ... }` node.
  JS.Statement _finishClassMembers(ClassElement classElem,
      JS.ClassExpression cls, List<ConstructorDeclaration> ctors,
      List<FieldDeclaration> fields, List<FieldDeclaration> staticFields,
      String jsPeerName) {
    var name = classElem.name;
    var body = <JS.Statement>[];
    body.add(new JS.ClassDeclaration(cls));

    // TODO(jmesserly): we should really just extend native Array.
    if (jsPeerName != null && classElem.typeParameters.isNotEmpty) {
      body.add(js.statement('dart.setBaseClass(#, dart.global.#);', [
        classElem.name,
        _propertyName(jsPeerName)
      ]));
    }

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

    // Instance fields, if they override getter/setter pairs
    for (FieldDeclaration member in fields) {
      for (VariableDeclaration fieldDecl in member.fields.variables) {
        var field = fieldDecl.element;
        if (_fieldsNeedingStorage.contains(field)) {
          body.add(_overrideField(field));
        }
      }
    }

    // Static fields
    var lazyStatics = <VariableDeclaration>[];
    for (FieldDeclaration member in staticFields) {
      for (VariableDeclaration field in member.fields.variables) {
        var fieldName = field.name.name;
        if ((field.isConst || _isFieldInitConstant(field)) &&
            !JS.invalidStaticFieldName(fieldName)) {
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

  JS.Statement _overrideField(FieldElement e) {
    var cls = e.enclosingElement;
    return js.statement('dart.virtualField(#, #)', [
      cls.name,
      _emitMemberName(e.name, type: cls.type)
    ]);
  }

  /// Generates the implicit default constructor for class C of the form
  /// `C() : super() {}`.
  JS.Method _emitImplicitConstructor(
      ClassDeclaration node, String name, List<FieldDeclaration> fields) {
    assert(_hasUnnamedConstructor(node.element) == fields.isNotEmpty);

    // If we don't have a method body, skip this.
    var superCall = _superConstructorCall(node);
    if (fields.isEmpty && superCall == null) return null;

    dynamic body = _initializeFields(fields);
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
      name = _propertyName('constructor');
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
    if (name == null) return _propertyName(className);
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
    var init = _emitArgumentInitializers(node, constructor: true);
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
    if (superCtorName == null && !_shouldCallUnnamedSuperCtor(element)) {
      return null;
    }

    var supertypeName = element.supertype.name;
    var name = _constructorName(supertypeName, superCtorName);

    var args = node != null ? _visit(node.argumentList) : [];
    return js.statement('super.#(#);', [name, args])..sourceInformation = node;
  }

  bool _shouldCallUnnamedSuperCtor(ClassElement e) {
    var supertype = e.supertype;
    if (supertype == null) return false;
    if (_hasUnnamedConstructor(supertype.element)) return true;
    for (var mixin in e.mixins) {
      if (_hasUnnamedConstructor(mixin.element)) return true;
    }
    return false;
  }

  bool _hasUnnamedConstructor(ClassElement e) {
    if (e.type.isObject) return false;
    if (!e.unnamedConstructor.isSynthetic) return true;
    return e.fields.any((f) => !f.isStatic && !f.isSynthetic);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  JS.Statement _initializeFields(List<FieldDeclaration> fieldDecls,
      [FormalParameterList parameters,
      NodeList<ConstructorInitializer> initializers]) {

    // Run field initializers if they can have side-effects.
    var fields = new Map<FieldElement, JS.Expression>();
    var unsetFields = new Map<FieldElement, VariableDeclaration>();
    for (var declaration in fieldDecls) {
      for (var fieldNode in declaration.fields.variables) {
        var element = fieldNode.element;
        if (_isFieldInitConstant(fieldNode)) {
          unsetFields[element] = fieldNode;
        } else {
          fields[element] = _visitInitializer(fieldNode);
        }
      }
    }

    // Initialize fields from `this.fieldName` parameters.
    if (parameters != null) {
      for (var p in parameters.parameters) {
        var element = p.element;
        if (element is FieldFormalParameterElement) {
          fields[element.field] = _visit(p);
        }
      }
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (initializers != null) {
      for (var init in initializers) {
        if (init is ConstructorFieldInitializer) {
          fields[init.fieldName.staticElement] = _visit(init.expression);
        }
      }
    }

    for (var f in fields.keys) unsetFields.remove(f);

    // Initialize all remaining fields
    unsetFields.forEach((element, fieldNode) {
      JS.Expression value;
      if (fieldNode.initializer != null) {
        value = _visit(fieldNode.initializer);
      } else {
        var type = rules.elementType(element);
        value = new JS.LiteralNull();
        if (rules.maybeNonNullableType(type)) {
          value = js.call('dart.as(#, #)', [value, _emitTypeName(type)]);
        }
      }
      fields[element] = value;
    });

    var body = <JS.Statement>[];
    fields.forEach((FieldElement e, JS.Expression initialValue) {
      var access = _emitMemberName(e.name, type: e.enclosingElement.type);
      body.add(js.statement('this.# = #;', [access, initialValue]));
    });
    return _statement(body);
  }

  FormalParameterList _parametersOf(node) {
    // TODO(jmesserly): clean this up. If we can model ES6 spread/rest args, we
    // could handle argument initializers more consistently in a separate
    // lowering pass.
    if (node is ConstructorDeclaration) return node.parameters;
    if (node is MethodDeclaration) return node.parameters;
    if (node is FunctionDeclaration) node = node.functionExpression;
    return (node as FunctionExpression).parameters;
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  JS.Statement _emitArgumentInitializers(node, {bool constructor: false}) {
    // Constructor argument initializers are emitted earlier in the code, rather
    // than always when we visit the function body, so we control it explicitly.
    if (node is ConstructorDeclaration != constructor) return null;

    var parameters = _parametersOf(node);
    if (parameters == null) return null;

    var body = [];
    for (var param in parameters.parameters) {
      var jsParam = _visit(param.identifier);

      if (param.kind == ParameterKind.NAMED) {
        // Parameters will be passed using their real names, not the (possibly
        // renamed) local variable.
        var paramName = js.string(param.identifier.name, "'");
        body.add(js.statement('let # = # && # in # ? #.# : #;', [
          jsParam,
          _namedArgTemp,
          paramName,
          _namedArgTemp,
          _namedArgTemp,
          paramName,
          _defaultParamValue(param),
        ]));
      } else if (param.kind == ParameterKind.POSITIONAL) {
        body.add(js.statement('if (# === void 0) # = #;', [
          jsParam,
          jsParam,
          _defaultParamValue(param)
        ]));
      }

      // TODO(jmesserly): various problems here, see:
      // https://github.com/dart-lang/dev_compiler/issues/161
      var paramType = param.element.type;
      if (!constructor && _hasTypeParameter(paramType)) {
        body.add(js.statement(
            'dart.as(#, #);', [jsParam, _emitTypeName(paramType)]));
      }
    }
    return body.isEmpty ? null : _statement(body);
  }

  bool _hasTypeParameter(DartType t) => t is TypeParameterType ||
      t is ParameterizedType && t.typeArguments.any(_hasTypeParameter);

  JS.Expression _defaultParamValue(FormalParameter param) {
    if (param is DefaultFormalParameter && param.defaultValue != null) {
      return _visit(param.defaultValue);
    } else {
      return new JS.LiteralNull();
    }
  }

  JS.Method _emitMethodDeclaration(DartType type, MethodDeclaration node) {
    if (node.isAbstract || _externalOrNative(node)) {
      return null;
    }

    var params = _visit(node.parameters);
    if (params == null) params = [];

    var memberName = _emitMemberName(node.name.name,
        type: type, unary: params.isEmpty, isStatic: node.isStatic);
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
    var accessor = node.staticElement;
    if (accessor == null) {
      return js.commentExpression(
          'Unimplemented unknown name', new JS.Identifier(node.name));
    }

    // Get the original declaring element. If we had a property accessor, this
    // indirects back to a (possibly synthetic) field.
    var element = accessor;
    if (element is PropertyAccessorElement) element = accessor.variable;
    var name = element.name;

    // library member
    if (element.enclosingElement is CompilationUnitElement &&
        (element.library != currentLibrary ||
            element is TopLevelVariableElement && !element.isConst)) {
      var memberName = _emitMemberName(name, isStatic: true);
      return js.call('#.#', [_libraryName(element.library), memberName]);
    }

    // Unqualified class member. This could mean implicit-this, or implicit
    // call to a static from the same class.
    if (element is ClassMemberElement && element is! ConstructorElement) {
      bool isStatic = element.isStatic;
      var type = element.enclosingElement.type;
      var member = _emitMemberName(name, isStatic: isStatic, type: type);

      // For static methods, we add the raw type name, without generics or
      // library prefix. We don't need those because static calls can't use
      // the generic type.
      if (isStatic) {
        return js.call('#.#', [type.name, member]);
      }

      // For instance members, we add implicit-this.
      // For method tear-offs, we ensure it's a bound method.
      var code = 'this.#';
      if (element is MethodElement && !inInvocationContext(node)) {
        code += '.bind(this)';
      }
      return js.call(code, member);
    }

    // initializing formal parameter, e.g. `Point(this.x)`
    if (element is ParameterElement &&
        element.isInitializingFormal &&
        element.isPrivate) {
      /// Rename private names so they don't shadow the private field symbol.
      /// The renamer would handle this, but it would prefer to rename the
      /// temporary used for the private symbol. Instead rename the parameter.
      return _getTemp(element, '${name.substring(1)}');
    }

    if (_isTemporary(element)) {
      if (name[0] == '#') {
        return new JS.InterpolatedExpression(name.substring(1));
      } else {
        return _getTemp(element, name);
      }
    }

    return new JS.Identifier(name);
  }

  JS.TemporaryId _getTemp(Object key, String name) =>
      _temps.putIfAbsent(key, () => new JS.TemporaryId(name));

  JS.ArrayInitializer _emitTypeNames(List<DartType> types) {
    return new JS.ArrayInitializer(types.map(_emitTypeName).toList());
  }

  JS.ObjectInitializer _emitTypeProperties(Map<String, DartType> types) {
    var properties = <JS.Property>[];
    types.forEach((name, type) {
      var key = new JS.LiteralString(name);
      var value = _emitTypeName(type);
      properties.add(new JS.Property(key, value));
    });
    return new JS.ObjectInitializer(properties);
  }

  JS.Expression _emitTypeName(DartType type, {bool lowerTypedef: false}) {
    // The void and dynamic types are not defined in core.
    if (type.isVoid) {
      return js.call('dart.void');
    } else if (type.isDynamic) {
      return js.call('dart.dynamic');
    }

    var name = type.name;
    var element = type.element;
    if (name == '' || lowerTypedef && type is FunctionType) {
      if (type is FunctionType) {
        var returnType = type.returnType;
        var parameterTypes = type.normalParameterTypes;
        var optionalTypes = type.optionalParameterTypes;
        var namedTypes = type.namedParameterTypes;
        if (namedTypes.isEmpty) {
          if (optionalTypes.isEmpty) {
            return js.call('dart.functionType(#, #)', [
              _emitTypeName(returnType),
              _emitTypeNames(parameterTypes)
            ]);
          } else {
            return js.call('dart.functionType(#, #, #)', [
              _emitTypeName(returnType),
              _emitTypeNames(parameterTypes),
              _emitTypeNames(optionalTypes)
            ]);
          }
        } else {
          assert(optionalTypes.isEmpty);
          return js.call('dart.functionType(#, #, #)', [
            _emitTypeName(returnType),
            _emitTypeNames(parameterTypes),
            _emitTypeProperties(namedTypes)
          ]);
        }
      }
      // TODO(jmesserly): remove when we're using coercion reifier.
      return _unimplementedCall('Unimplemented type $type');
    }

    var typeArgs = null;
    if (type is ParameterizedType) {
      var args = type.typeArguments;
      if (args.any((a) => a != types.dynamicType)) {
        name = '$name\$';
        typeArgs = args.map(_emitTypeName);
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

  @override
  JS.Expression visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;
    if (node.operator.type == TokenType.EQ) return _emitSet(left, right);
    return _emitOpAssign(
        left, right, node.operator.lexeme[0], node.staticElement,
        context: node);
  }

  JS.MetaLet _emitOpAssign(
      Expression left, Expression right, String op, ExecutableElement element,
      {Expression context}) {
    // Desugar `x += y` as `x = x + y`, ensuring that if `x` has subexpressions
    // (for example, x is IndexExpression) we evaluate those once.
    var vars = {};
    var lhs = _bindLeftHandSide(vars, left, context: context);
    var inc = AstBuilder.binaryExpression(lhs, op, right);
    inc.staticElement = element;
    inc.staticType = getStaticType(left);
    return new JS.MetaLet(vars, [_emitSet(lhs, inc)]);
  }

  JS.Expression _emitSet(Expression lhs, Expression rhs) {
    if (lhs is IndexExpression) {
      return _emitSend(_getTarget(lhs), '[]=', [lhs.index, rhs]);
    }

    Expression target = null;
    SimpleIdentifier id;
    if (lhs is PropertyAccess) {
      target = _getTarget(lhs);
      id = lhs.propertyName;
    } else if (lhs is PrefixedIdentifier) {
      target = lhs.prefix;
      id = lhs.identifier;
    }

    if (target != null && rules.isDynamicTarget(target)) {
      return js.call('dart.$DPUT(#, #, #)', [
        _visit(target),
        _emitMemberName(id.name, type: getStaticType(target)),
        _visit(rhs)
      ]);
    }

    return _visit(rhs).toAssignExpression(_visit(lhs));
  }

  @override
  JS.Block visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var initArgs = _emitArgumentInitializers(node.parent);
    var ret = new JS.Return(_visit(node.expression));
    return new JS.Block(initArgs != null ? [initArgs, ret] : [ret]);
  }

  @override
  JS.Block visitEmptyFunctionBody(EmptyFunctionBody node) => new JS.Block([]);

  @override
  JS.Block visitBlockFunctionBody(BlockFunctionBody node) {
    var initArgs = _emitArgumentInitializers(node.parent);
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

    String code;
    if (target == null || isLibraryPrefix(target)) {
      if (rules.isDynamicCall(node.methodName)) {
        code = 'dart.$DCALL(#, #)';
      } else {
        code = '#(#)';
      }
      return js.call(
          code, [_visit(node.methodName), _visit(node.argumentList)]);
    }

    var type = getStaticType(target);
    var name = node.methodName.name;
    var element = node.methodName.staticElement;
    bool isStatic = element is ExecutableElement && element.isStatic;
    var memberName = _emitMemberName(name, type: type, isStatic: isStatic);

    if (rules.isDynamicTarget(target)) {
      code = 'dart.$DSEND(#, #, #)';
    } else if (rules.isDynamicCall(node.methodName)) {
      // This is a dynamic call to a statically know target. For example:
      //     class Foo { Function bar; }
      //     new Foo().bar(); // dynamic call
      code = 'dart.$DCALL(#.#, #)';
    } else if (_requiresStaticDispatch(target, name)) {
      assert(rules.objectMembers[name] is FunctionType);
      // Object methods require a helper for null checks.
      return js.call('dart.#(#, #)', [
        memberName,
        _visit(target),
        _visit(node.argumentList)
      ]);
    } else {
      code = '#.#(#)';
    }

    return js.call(
        code, [_visit(target), memberName, _visit(node.argumentList)]);
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
      code = 'dart.$DCALL(#, #)';
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
        named.add(_visit(arg));
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
      _visit(node.expression).toStatement();

  @override
  JS.EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      new JS.EmptyStatement();

  @override
  JS.Statement visitAssertStatement(AssertStatement node) =>
      // TODO(jmesserly): only emit in checked mode.
      js.statement('dart.assert(#);', _visit(node.condition));

  @override
  JS.Statement visitReturnStatement(ReturnStatement node) {
    var e = node.expression;
    if (e == null) return new JS.Return();
    return _visit(e).toReturn();
  }

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
  JS.Statement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    // Special case a single variable with an initializer.
    // This helps emit cleaner code for things like:
    //     var result = []..add(1)..add(2);
    if (node.variables.variables.length == 1) {
      var v = node.variables.variables.single;
      if (v.initializer != null) {
        var name = new JS.Identifier(v.name.name);
        return _visit(v.initializer).toVariableDeclaration(name);
      }
    }
    return _visit(node.variables).toStatement();
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    return new JS.VariableDeclarationList('let', _visitList(node.variables));
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

  void _flushPendingStatements(List<JS.Statement> body) {
    if (_pendingStatements.isNotEmpty) {
      body.addAll(_pendingStatements);
      _pendingStatements.clear();
    }
  }

  void _flushLazyFields(List<JS.Statement> body) {
    var code = _emitLazyFields(_exportsVar, _lazyFields);
    if (code != null) {
      // Ensure symbols for private fields are defined.
      _flushPendingStatements(body);
      body.add(code);
    }
    _lazyFields.clear();
  }

  JS.Statement _emitLazyFields(
      JS.Expression objExpr, List<VariableDeclaration> fields) {
    if (fields.isEmpty) return null;

    var methods = [];
    for (var node in fields) {
      var name = node.name.name;
      var element = node.element;
      var access = _emitMemberName(name, type: element.type, isStatic: true);
      methods.add(new JS.Method(
          access, js.call('function() { return #; }', _visit(node.initializer)),
          isGetter: true));

      // TODO(jmesserly): use a dummy setter to indicate writable.
      if (!node.isFinal) {
        methods.add(
            new JS.Method(access, js.call('function(_) {}'), isSetter: true));
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
    var newExpr = js.call(
        'new #(#)', [_visit(node.constructorName), _visit(node.argumentList)]);
    if (node.isConst) return _const(node, newExpr);
    return newExpr;
  }

  /// True if this type is built-in to JS, and we use the values unwrapped.
  /// For these types we generate a calling convention via static
  /// "extension methods". This allows types to be extended without adding
  /// extensions directly on the prototype.
  bool _isJSBuiltinType(DartType t) =>
      typeIsPrimitiveInJS(t) || rules.isStringType(t);

  bool typeIsPrimitiveInJS(DartType t) => rules.isIntType(t) ||
      rules.isDoubleType(t) ||
      rules.isBoolType(t) ||
      rules.isNumType(t);

  bool typeIsNonNullablePrimitiveInJS(DartType t) =>
      typeIsPrimitiveInJS(t) && rules.isNonNullableType(t);

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) =>
      typeIsPrimitiveInJS(leftT) && typeIsPrimitiveInJS(rightT);

  bool unaryOperationIsPrimitive(DartType t) => typeIsPrimitiveInJS(t);

  bool _isNonNullableExpression(Expression expr) {
    // If the type is non-nullable, no further checking needed.
    if (rules.isNonNullableType(getStaticType(expr))) return true;

    // TODO(vsm): Revisit whether we really need this when we get
    // better non-nullability in the type system.

    if (expr is Literal && expr is! NullLiteral) return true;
    if (expr is IsExpression) return true;
    if (expr is ThisExpression) return true;
    if (expr is SuperExpression) return true;
    if (expr is ParenthesizedExpression) {
      return _isNonNullableExpression(expr.expression);
    }
    if (expr is Conversion) {
      return _isNonNullableExpression(expr.expression);
    }
    if (expr is SimpleIdentifier) {
      // Type literals are not null.
      Element e = expr.staticElement;
      if (e is ClassElement || e is FunctionTypeAliasElement) return true;
    }
    DartType type = null;
    if (expr is BinaryExpression) {
      type = getStaticType(expr.leftOperand);
    } else if (expr is PrefixExpression) {
      type = getStaticType(expr.operand);
    } else if (expr is PostfixExpression) {
      type = getStaticType(expr.operand);
    }
    if (type != null && _isJSBuiltinType(type)) {
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
    var leftType = getStaticType(left);
    var rightType = getStaticType(right);

    // TODO(jmesserly): this may not work correctly with options.ignoreTypes,
    // because that results in unreliable type annotations. See issue #134,
    // probably the checker/resolver is the right place to implement that, by
    // replacing staticTypes with `dynamic` as needed, so codegen "just works".
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
    }

    if (binaryOperationIsPrimitive(leftType, rightType) ||
        rules.isStringType(leftType) && op.type == TokenType.PLUS) {

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
    }

    return _emitSend(left, op.lexeme, [right]);
  }

  /// If the type [t] is [int] or [double], returns [num].
  /// Otherwise returns [t].
  DartType _canonicalizeNumTypes(DartType t) {
    var numType = types.numType;
    if (t is InterfaceType && t.superclass == numType) return numType;
    return t;
  }

  bool _canUsePrimitiveEquality(Expression left, Expression right) {
    if (_isNull(left) || _isNull(right)) return true;

    var leftType = _canonicalizeNumTypes(getStaticType(left));
    var rightType = _canonicalizeNumTypes(getStaticType(right));
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

  JS.Expression _const(Expression node, JS.Expression expr, [String nameHint]) {
    var value = js.call('dart.const(#)', expr);

    // If we're inside a method or function, capture the value into a
    // global temporary, so we don't do the expensive canonicalization step.
    var ancestor = node.getAncestor((n) => n is FunctionBody ||
        (n is FieldDeclaration && n.staticKeyword == null));
    if (ancestor == null) return value;

    if (nameHint == null) {
      nameHint = 'const_' + getStaticType(node).name;
    }

    // TODO(jmesserly): enable this once we fix
    // https://github.com/dart-lang/dev_compiler/issues/131
    /*var temp = new JSTemporary(nameHint);
    _pendingStatements.add(js.statement('let # = #;', [temp, value]));
    return temp;*/
    assert(nameHint != null); // so it's not marked unused
    return value;
  }

  bool _isTemporary(Element node) => node.nameOffset == -1;

  /// Returns a new expression, which can be be used safely *once* on the
  /// left hand side, and *once* on the right side of an assignment.
  /// For example: `expr1[expr2] += y` can be compiled as
  /// `expr1[expr2] = expr1[expr2] + y`.
  ///
  /// The temporary scope will ensure `expr1` and `expr2` are only evaluated
  /// once: `((x1, x2) => x1[x2] = x1[x2] + y)(expr1, expr2)`.
  ///
  /// If the expression does not end up using `x1` or `x2` more than once, or
  /// if those expressions can be treated as stateless (e.g. they are
  /// non-mutated variables), then the resulting code will be simplified
  /// automatically.
  ///
  /// [scope] can be mutated to contain any new temporaries that were created,
  /// unless [expr] is a SimpleIdentifier, in which case a temporary is not
  /// needed.
  Expression _bindLeftHandSide(
      Map<String, JS.Expression> scope, Expression expr, {Expression context}) {
    if (expr is IndexExpression) {
      IndexExpression index = expr;
      return new IndexExpression.forTarget(
          _bindValue(scope, 'o', index.target, context: context),
          index.leftBracket,
          _bindValue(scope, 'i', index.index, context: context),
          index.rightBracket)..staticType = expr.staticType;
    } else if (expr is PropertyAccess) {
      PropertyAccess prop = expr;
      return new PropertyAccess(
          _bindValue(scope, 'o', _getTarget(prop), context: context),
          prop.operator, prop.propertyName)..staticType = expr.staticType;
    } else if (expr is PrefixedIdentifier) {
      PrefixedIdentifier ident = expr;
      return new PrefixedIdentifier(
          _bindValue(scope, 'o', ident.prefix, context: context), ident.period,
          ident.identifier)..staticType = expr.staticType;
    }
    return expr as SimpleIdentifier;
  }

  /// Creates a temporary to contain the value of [expr]. The temporary can be
  /// used multiple times in the resulting expression. For example:
  /// `expr ** 2` could be compiled as `expr * expr`. The temporary scope will
  /// ensure `expr` is only evaluated once: `(x => x * x)(expr)`.
  ///
  /// If the expression does not end up using `x` more than once, or if those
  /// expressions can be treated as stateless (e.g. they are non-mutated
  /// variables), then the resulting code will be simplified automatically.
  ///
  /// [scope] will be mutated to contain the new temporary's initialization.
  Expression _bindValue(
      Map<String, JS.Expression> scope, String name, Expression expr,
      {Expression context}) {
    // No need to do anything for stateless expressions.
    if (isStateless(expr, context)) return expr;

    var t = _createTemporary('#$name', expr.staticType);
    scope[name] = _visit(expr);
    return t;
  }

  /// Desugars postfix increment.
  ///
  /// In the general case [expr] can be one of [IndexExpression],
  /// [PrefixExpression] or [PropertyAccess] and we need to
  /// ensure sub-expressions are evaluated once.
  ///
  /// We also need to ensure we can return the original value of the expression,
  /// and that it is only evaluated once.
  ///
  /// We desugar this using let*.
  ///
  /// For example, `expr1[expr2]++` can be transformed to this:
  ///
  ///     // psuedocode mix of Scheme and JS:
  ///     (let* (x1=expr1, x2=expr2, t=expr1[expr2]) { x1[x2] = t + 1; t })
  ///
  /// The [JS.JS.MetaLet] nodes automatically simplify themselves if they can.
  /// For example, if the result value is not used, then `t` goes away.
  @override
  JS.Expression visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      if (_isNonNullableExpression(expr)) {
        return js.call('#$op', _visit(expr));
      }
    }

    assert(op.lexeme == '++' || op.lexeme == '--');

    // Handle the left hand side, to ensure each of its subexpressions are
    // evaluated only once.
    var vars = {};
    var left = _bindLeftHandSide(vars, expr, context: expr);

    // Desugar `x++` as `(x1 = x0 + 1, x0)` where `x0` is the original value
    // and `x1` is the new value for `x`.
    var x = _bindValue(vars, 'x', left, context: expr);

    var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
    var increment = AstBuilder.binaryExpression(x, op.lexeme[0], one)
      ..staticElement = node.staticElement
      ..staticType = getStaticType(expr);

    var body = [_emitSet(left, increment), _visit(x)];
    return new JS.MetaLet(vars, body, statelessResult: true);
  }

  @override
  JS.Expression visitPrefixExpression(PrefixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      if (_isNonNullableExpression(expr)) {
        return js.call('$op#', _visit(expr));
      } else if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var mathop = op.lexeme[0];
        var vars = {};
        var x = _bindLeftHandSide(vars, expr, context: expr);
        var body = js.call('# = # $mathop 1', [_visit(x), notNull(x)]);
        return new JS.MetaLet(vars, [body]);
      } else {
        return js.call('$op#', notNull(expr));
      }
    }

    if (op.lexeme == '++' || op.lexeme == '--') {
      // Increment or decrement requires expansion.
      // Desugar `++x` as `x = x + 1`, ensuring that if `x` has subexpressions
      // (for example, x is IndexExpression) we evaluate those once.
      var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
      return _emitOpAssign(expr, one, op.lexeme[0], node.staticElement,
          context: expr);
    }

    return _emitSend(expr, op.lexeme[0], []);
  }

  // Cascades can contain [IndexExpression], [MethodInvocation] and
  // [PropertyAccess]. The code generation for those is handled in their
  // respective visit methods.
  @override
  JS.Node visitCascadeExpression(CascadeExpression node) {
    var savedCascadeTemp = _cascadeTarget;

    var vars = {};
    _cascadeTarget = _bindValue(vars, '_', node.target, context: node);
    var sections = _visitList(node.cascadeSections);
    sections.add(_visit(_cascadeTarget));
    var result = new JS.MetaLet(vars, sections, statelessResult: true);
    _cascadeTarget = savedCascadeTemp;
    return result;
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
    if (isLibraryPrefix(node.prefix)) {
      return _visit(node.identifier);
    } else {
      return _emitGet(node.prefix, node.identifier);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) =>
      _emitGet(_getTarget(node), node.propertyName);

  bool _requiresStaticDispatch(Expression target, String memberName) {
    var type = getStaticType(target);
    if (!rules.objectMembers.containsKey(memberName)) {
      return false;
    }
    if (!type.isObject &&
        !_isJSBuiltinType(type) &&
        _isNonNullableExpression(target)) {
      return false;
    }
    return true;
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  JS.Expression _emitGet(Expression target, SimpleIdentifier memberId) {
    var member = memberId.staticElement;
    bool isStatic = member is ExecutableElement && member.isStatic;
    var name = _emitMemberName(memberId.name,
        type: getStaticType(target), isStatic: isStatic);
    if (rules.isDynamicTarget(target)) {
      return js.call('dart.$DLOAD(#, #)', [_visit(target), name]);
    }

    String code;
    if (member != null && member is MethodElement) {
      // Tear-off methods: explicitly bind it.
      if (_requiresStaticDispatch(target, memberId.name)) {
        return js.call('dart.#.bind(#)', [name, _visit(target)]);
      }
      if (isStateless(target, target)) {
        return js.call('#.#.bind(#)', [_visit(target), name, _visit(target)]);
      }
      code = 'dart.bind(#, #)';
    } else if (_requiresStaticDispatch(target, memberId.name)) {
      return js.call('dart.#(#)', [name, _visit(target)]);
    } else {
      code = '#.#';
    }

    return js.call(code, [_visit(target), name]);
  }

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  JS.Expression _emitSend(
      Expression target, String name, List<Expression> args) {
    var type = getStaticType(target);
    var memberName = _emitMemberName(name, unary: args.isEmpty, type: type);
    if (rules.isDynamicTarget(target)) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': DINDEX, '[]=': DSETINDEX}[name];
      if (dynamicHelper != null) {
        return js.call(
            'dart.$dynamicHelper(#, #)', [_visit(target), _visitList(args)]);
      }
      return js.call('dart.$DSEND(#, #, #)', [
        _visit(target),
        memberName,
        _visitList(args)
      ]);
    }

    if (_isJSBuiltinType(type)) {
      // static call pattern for builtins.
      return js.call('#.#(#, #)', [
        _emitTypeName(type),
        memberName,
        _visit(target),
        _visitList(args)
      ]);
    }
    // Generic dispatch to a statically known method.
    return js.call('#.#(#)', [_visit(target), memberName, _visitList(args)]);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    return _emitSend(_getTarget(node), '[]', [node.index]);
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
    var update = _visitListToBinary(node.updaters, ',');
    if (update != null) update = update.toVoidExpression();
    return new JS.For(init, _visit(node.condition), update, _visit(node.body));
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

    if (clauses.length == 1 && clauses.single.exceptionParameter != null) {
      // Special case for a single catch.
      _catchParameter = clauses.single.exceptionParameter;
    } else {
      _catchParameter = _createTemporary('e', types.dynamicType);
    }

    JS.Statement catchBody = js.statement('throw #;', _visit(_catchParameter));
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
  visitSymbolLiteral(SymbolLiteral node) {
    // TODO(vsm): When we canonicalize, we need to treat private symbols
    // correctly.
    var name = js.string(node.components.join('.'), "'");
    var nameHint = 'symbol_' + node.components.join('_');
    return _const(
        node, new JS.New(_emitTypeName(types.symbolType), [name]), nameHint);
  }

  @override
  visitListLiteral(ListLiteral node) {
    JS.Expression list = new JS.ArrayInitializer(_visitList(node.elements));

    ParameterizedType type = node.staticType;
    if (type.typeArguments.any((a) => a != types.dynamicType)) {
      list = js.call('dart.setType(#, #)', [list, _emitTypeName(type)]);
    }
    if (node.constKeyword != null) return _const(node, list);
    return list;
  }

  @override
  visitMapLiteral(MapLiteral node) {
    // TODO(jmesserly): we can likely make these faster.
    var entries = node.entries;
    var mapArguments = null;
    if (entries.isEmpty) {
      mapArguments = [];
    } else if (entries.every((e) => e.key is StringLiteral)) {
      // Use JS object literal notation if possible, otherwise use an array.
      // We could do this any time all keys are non-nullable String type.
      // For now, support StringLiteral as the common non-nullable String case.
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
    // TODO(jmesserly): add generic types args.
    var map = js.call('dart.map(#)', [mapArguments]);
    if (node.constKeyword != null) return _const(node, map);
    return map;
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
    return new JS.Expression.binary(_visitList(nodes), operator);
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
      {DartType type, bool unary: false, bool isStatic: false}) {

    // Static members skip the rename steps.
    if (isStatic) return _propertyName(name);

    if (name.startsWith('_')) {
      return _privateNames.putIfAbsent(
          name, () => _initSymbol(new JS.TemporaryId(name)));
    }

    // Check for extension method:
    var extLibrary = _findExtensionLibrary(name, type);

    if (name == '[]') {
      name = 'get';
    } else if (name == '[]=') {
      name = 'set';
    } else if (name == '-' && unary) {
      name = 'unary-';
    }

    if (extLibrary != null) {
      return _extensionMethodName(name, extLibrary);
    }

    return _propertyName(name);
  }

  LibraryElement _findExtensionLibrary(String name, DartType type) {
    if (type is! InterfaceType) return null;

    var extLibrary = null;
    var extensionTypes = _extensionMethods[name];
    if (extensionTypes != null) {
      // Normalize the type to ignore generics.
      type = fillDynamicTypeArgs(type, types);
      for (var t in extensionTypes) {
        if (rules.isSubTypeOf(type, t)) {
          assert(extLibrary == null || extLibrary == t.element.library);
          extLibrary = t.element.library;
        }
      }
    }
    return extLibrary;
  }

  JS.Expression _extensionMethodName(String name, LibraryElement library) {
    var extName = '\$$name';
    if (library == currentLibrary) {
      // TODO(jacobr): need to do a better job ensuring that extension method
      // name symbols do not conflict with other symbols before we can let
      // user defined libraries define extension methods.
      if (_extensionMethodNames.add(extName)) {
        _initSymbol(new JS.Identifier(extName));
        _addExport(extName);
      }
      return new JS.Identifier(extName);
    }
    return js.call('#.#', [_libraryName(library), _propertyName(extName)]);
  }

  bool _externalOrNative(node) =>
      node.externalKeyword != null || _functionBody(node) is NativeFunctionBody;

  FunctionBody _functionBody(node) =>
      node is FunctionDeclaration ? node.functionExpression.body : node.body;

  /// Choose a canonical name from the library element.
  /// This never uses the library's name (the identifier in the `library`
  /// declaration) as it doesn't have any meaningful rules enforced.
  JS.Identifier _libraryName(LibraryElement library) {
    if (library == currentLibrary) return _exportsVar;
    return _imports.putIfAbsent(
        library, () => new JS.TemporaryId(jsLibraryName(library)));
  }

  DartType getStaticType(Expression e) => rules.getStaticType(e);
}

class JSGenerator extends CodeGenerator {
  final CompilerOptions options;

  /// For fast lookup of extension methods, we first check the name, then do a
  /// (possibly expensive) subtype test to see if it matches one of the types
  /// that declares that method.
  final _extensionMethods = new HashMap<String, List<InterfaceType>>();

  JSGenerator(String outDir, Uri root, TypeRules rules, this.options)
      : super(outDir, root, rules) {

    // TODO(jacobr): determine the the set of types with extension methods from
    // the annotations rather than hard coding the list once the analyzer
    // supports summaries.
    var extensionTypes = [types.listType, types.iterableType];
    for (var type in extensionTypes) {
      type = fillDynamicTypeArgs(type, rules.provider);
      var e = type.element;
      var names = new HashSet<String>()
        ..addAll(e.methods.map((m) => m.name))
        ..addAll(e.accessors.map((m) => m.name));
      for (var name in names) {
        _extensionMethods.putIfAbsent(name, () => []).add(type);
      }
    }
  }

  TypeProvider get types => rules.provider;

  String generateLibrary(LibraryUnit unit, LibraryInfo info) {
    var fields = findFieldsNeedingStorage(unit);
    var codegen =
        new JSCodegenVisitor(options, rules, info, _extensionMethods, fields);
    var module = codegen.emitLibrary(unit);
    var dir = path.join(outDir, jsOutputPath(info, root));
    return writeJsLibrary(module, dir, emitSourceMaps: options.emitSourceMaps);
  }
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

// TODO(jmesserly): validate the library. See issue #135.
bool _isJsNameAnnotation(DartObjectImpl value) => value.type.name == 'JsName';

bool _isJsPeerInterface(DartObjectImpl value) =>
    value.type.name == 'JsPeerInterface';

// TODO(jacobr): we would like to do something like the following
// but we don't have summary support yet.
// bool _supportJsExtensionMethod(AnnotatedNode node) =>
//    _getAnnotation(node, "SupportJsExtensionMethod") != null;
