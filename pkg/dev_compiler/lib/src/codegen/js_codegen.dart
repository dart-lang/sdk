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

import 'package:dev_compiler/devc.dart' show AbstractCompiler;
import 'package:dev_compiler/src/checker/rules.dart';
import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/utils.dart';

import 'code_generator.dart';
import 'js_field_storage.dart';
import 'js_names.dart' as JS;
import 'js_metalet.dart' as JS;
import 'js_module_item_order.dart';
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
  final AbstractCompiler compiler;
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

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<LibraryElement, JS.TemporaryId>();
  final _exports = new Set<String>();
  final _lazyFields = <VariableDeclaration>[];
  final _properties = <FunctionDeclaration>[];
  final _privateNames = new HashMap<String, JS.TemporaryId>();
  final _extensionMethodNames = new HashSet<String>();
  final _moduleItems = <JS.Statement>[];
  final _temps = new HashMap<Element, JS.TemporaryId>();
  final _qualifiedIds = new HashMap<Element, JS.MaybeQualifiedId>();
  final _qualifiedGenericIds = new HashMap<Element, JS.MaybeQualifiedId>();

  /// The name for the library's exports inside itself.
  /// `exports` was chosen as the most similar to ES module patterns.
  final _exportsVar = new JS.TemporaryId('exports');
  final _namedArgTemp = new JS.TemporaryId('opts');

  ConstFieldVisitor _constField;

  ModuleItemLoadOrder _loader;

  JSCodegenVisitor(AbstractCompiler compiler, this.libraryInfo,
      this._extensionMethods, this._fieldsNeedingStorage)
      : compiler = compiler,
        options = compiler.options,
        rules = compiler.rules {
    _loader = new ModuleItemLoadOrder(_emitModuleItem);
  }

  LibraryElement get currentLibrary => libraryInfo.library;
  TypeProvider get types => rules.provider;

  JS.Program emitLibrary(LibraryUnit library) {
    String jsDefaultValue = null;

    // Modify the AST to make coercions explicit.
    new CoercionReifier(library, compiler).reify();

    var unit = library.library;
    if (unit.directives.isNotEmpty) {
      var libraryDir = unit.directives.first;
      if (libraryDir is LibraryDirective) {
        var jsName = getAnnotationValue(libraryDir, _isJsNameAnnotation);
        jsDefaultValue = getConstantField(jsName, 'name', types.stringType);
      }
    }
    if (jsDefaultValue == null) jsDefaultValue = '{}';

    // TODO(jmesserly): visit scriptTag, directives?

    _loader.collectElements(currentLibrary, library.partsThenLibrary);

    for (var unit in library.partsThenLibrary) {
      _constField = new ConstFieldVisitor(types, unit);

      for (var decl in unit.declarations) {
        if (decl is TopLevelVariableDeclaration) {
          _visit(decl);
        } else {
          _loader.loadDeclaration(decl, decl.element);
        }
        if (decl is ClassDeclaration) {
          // Static fields can be emitted into the top-level code, so they need
          // to potentially be ordered independently of the class.
          for (var member in decl.members) {
            if (member is FieldDeclaration && member.isStatic) {
              for (var f in member.fields.variables) {
                _loader.loadDeclaration(f, f.element);
              }
            }
          }
        }
      }
    }

    // Flush any unwritten fields/properties.
    _flushLazyFields(_moduleItems);
    _flushLibraryProperties(_moduleItems);

    // Mark all qualified names as qualified or not, depending on if they need
    // to be loaded lazily or not.
    unqualifyIfNeeded(Element e, JS.MaybeQualifiedId id) {
      id.setQualified(!_loader.isLoaded(e));
    }
    _qualifiedIds.forEach(unqualifyIfNeeded);
    _qualifiedGenericIds.forEach(unqualifyIfNeeded);

    if (_exports.isNotEmpty) _moduleItems.add(js.comment('Exports:'));

    // TODO(jmesserly): make these immutable in JS?
    for (var name in _exports) {
      _moduleItems.add(js.statement('#.# = #;', [_exportsVar, name, name]));
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
      var helper = _loader.libraryIsLoaded(library) ? 'import' : 'lazyImport';
      program.add(js.statement('var # = dart.#(#);', [name, helper, name]));
    });

    program.add(js.statement("(function(#) { 'use strict'; #; })(#);", [
      params,
      _moduleItems,
      args
    ]));

    return new JS.Program(program);
  }

  void _emitModuleItem(AstNode node) {
    // Attempt to group adjacent fields/properties.
    if (node is! VariableDeclaration) _flushLazyFields(_moduleItems);
    if (node is! FunctionDeclaration) _flushLibraryProperties(_moduleItems);

    var code = _visit(node);
    if (code != null) _moduleItems.add(code);
  }

  JS.Identifier _initSymbol(JS.Identifier id) {
    var s = js.statement('let # = $_SYMBOL(#);', [id, js.string(id.name, "'")]);
    _moduleItems.add(s);
    return id;
  }

  // TODO(jmesserly): this is a temporary workaround for `Symbol` in core,
  // until we have better name tracking.
  String get _SYMBOL {
    var name = currentLibrary.name;
    if (name == 'dart.core' || name == 'dart._internal') return 'dart.JsSymbol';
    return 'Symbol';
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
    var element = node.element;
    var type = element.type;
    var name = element.name;

    var fnType = js.statement('let # = dart.typedef(#, () => #);', [
      name,
      js.string(name, "'"),
      _emitTypeName(type, lowerTypedef: true)
    ]);

    return _finishClassDef(type, fnType);
  }

  @override
  JS.Expression visitTypeName(TypeName node) => _emitTypeName(node.type);

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    // If we've already emitted this class, skip it.
    var element = node.element;

    var classDecl = new JS.ClassDeclaration(new JS.ClassExpression(
        new JS.Identifier(element.name), _classHeritage(element), []));

    return _finishClassDef(element.type, classDecl);
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
    var jsName = getAnnotationValue(node, _isJsNameAnnotation);

    if (jsName != null) return _emitJsType(node.name.name, jsName);

    var ctors = <ConstructorDeclaration>[];
    var fields = <FieldDeclaration>[];
    var methods = <MethodDeclaration>[];
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        ctors.add(member);
      } else if (member is FieldDeclaration && !member.isStatic) {
        fields.add(member);
      } else if (member is MethodDeclaration) {
        methods.add(member);
      }
    }

    var classExpr = new JS.ClassExpression(new JS.Identifier(type.name),
        _classHeritage(classElem), _emitClassMethods(node, ctors, fields));

    String jsPeerName;
    var jsPeer = getAnnotationValue(node, _isJsPeerInterface);
    if (jsPeer != null) {
      jsPeerName = getConstantField(jsPeer, 'name', types.stringType);
    }

    var body = _finishClassMembers(
        classElem, classExpr, ctors, fields, methods, jsPeerName);

    var result = _finishClassDef(type, body);

    if (jsPeerName != null) {
      // This class isn't allowed to be lazy, because we need to set up
      // the native JS type eagerly at this point.
      // If we wanted to support laziness, we could defer the hookup until
      // the end of the Dart library cycle load.
      assert(_loader.isLoaded(classElem));

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

    JS.Statement genericDef = null;
    if (type.typeParameters.isNotEmpty) {
      genericDef = _emitGenericClassDef(type, body);
    }

    // The base class and all mixins must be declared before this class.
    if (!_loader.isLoaded(type.element)) {
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
      var dynType = fillDynamicTypeArgs(type, types);
      var genericInst = _emitTypeName(dynType, lowerGeneric: true);
      return js.statement('{ #; let # = #; }', [genericDef, name, genericInst]);
    }
    return body;
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

  JS.Expression _classHeritage(ClassElement element) {
    var type = element.type;
    if (type.isObject) return null;

    // Assume we can load eagerly, until proven otherwise.
    _loader.startTopLevel(element);

    JS.Expression heritage = _emitTypeName(type.superclass);
    if (type.mixins.isNotEmpty) {
      var mixins = type.mixins.map(_emitTypeName).toList();
      mixins.insert(0, heritage);
      heritage = js.call('dart.mixin(#)', [mixins]);
    }

    _loader.finishTopLevel(element);
    return heritage;
  }

  List<JS.Method> _emitClassMethods(ClassDeclaration node,
      List<ConstructorDeclaration> ctors, List<FieldDeclaration> fields) {
    var element = node.element;
    var type = element.type;
    var isObject = type.isObject;

    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    var jsMethods = <JS.Method>[];
    if (ctors.isEmpty && !isObject) {
      jsMethods.add(_emitImplicitConstructor(node, fields));
    }

    bool hasJsPeer = getAnnotationValue(node, _isJsPeerInterface) != null;

    bool hasIterator = false;
    for (var m in node.members) {
      if (m is ConstructorDeclaration) {
        jsMethods.add(_emitConstructor(m, type, fields, isObject));
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
      List<FieldDeclaration> fields, List<MethodDeclaration> methods,
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
      if (member.name != null && member.factoryKeyword == null) {
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

    // Emit the signature on the class recording the runtime type information
    {
      var tStatics = [];
      var tMethods = [];
      var sNames = [];
      var cType = classElem.type;
      for (MethodDeclaration node in methods) {
        if (!(node.isSetter || node.isGetter || node.isAbstract)) {
          var name = node.name.name;
          var element = node.element;
          var inheritedElement =
              classElem.lookUpInheritedConcreteMethod(name, currentLibrary);
          if (inheritedElement != null &&
              inheritedElement.type == element.type) continue;
          var unary = node.parameters.parameters.isEmpty;
          var memberName = _emitMemberName(name,
              type: cType, unary: unary, isStatic: node.isStatic);
          var parts =
              _emitFunctionTypeParts(element.type, dynamicIsBottom: false);
          var property =
              new JS.Property(memberName, new JS.ArrayInitializer(parts));
          if (node.isStatic) {
            tStatics.add(property);
            sNames.add(memberName);
          } else tMethods.add(property);
        }
      }
      var tCtors = [];
      for (ConstructorDeclaration node in ctors) {
        var memberName = _constructorName(node.element);
        var element = node.element;
        var parts =
            _emitFunctionTypeParts(element.type, dynamicIsBottom: false);
        var property =
            new JS.Property(memberName, new JS.ArrayInitializer(parts));
        tCtors.add(property);
      }
      build(name, elements) {
        var o =
            new JS.ObjectInitializer(elements, vertical: elements.length > 1);
        var e = js.call('() => #', o);
        var p = new JS.Property(_propertyName(name), e);
        return p;
      }
      var sigFields = [];
      if (!tCtors.isEmpty) sigFields.add(build('constructors', tCtors));
      if (!tMethods.isEmpty) sigFields.add(build('methods', tMethods));
      if (!tStatics.isEmpty) {
        assert(!sNames.isEmpty);
        var aNames = new JS.Property(
            _propertyName('names'), new JS.ArrayInitializer(sNames));
        sigFields.add(build('statics', tStatics));
        sigFields.add(aNames);
      }
      if (!sigFields.isEmpty) {
        var sig = new JS.ObjectInitializer(sigFields);
        var classExpr = new JS.Identifier(name);
        body.add(js.statement('dart.setSignature(#, #);', [classExpr, sig]));
      }
    }

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
      ClassDeclaration node, List<FieldDeclaration> fields) {
    assert(_hasUnnamedConstructor(node.element) == fields.isNotEmpty);

    // If we don't have a method body, skip this.
    var superCall = _superConstructorCall(node.element);
    if (fields.isEmpty && superCall == null) return null;

    dynamic body = _initializeFields(node, fields);
    if (superCall != null) body = [[body, superCall]];
    var name = _constructorName(node.element.unnamedConstructor);
    return new JS.Method(name, js.call('function() { #; }', body));
  }

  JS.Method _emitConstructor(ConstructorDeclaration node, InterfaceType type,
      List<FieldDeclaration> fields, bool isObject) {
    if (_externalOrNative(node)) return null;

    var name = _constructorName(node.element);

    // Wacky factory redirecting constructors: factory Foo.q(x, y) = Bar.baz;
    var redirect = node.redirectedConstructor;
    if (redirect != null) {
      var newKeyword = redirect.staticElement.isFactory ? '' : 'new';
      // Pass along all arguments verbatim, and let the callee handle them.
      // TODO(jmesserly): we'll need something different once we have
      // rest/spread support, but this should work for now.
      var params = _visit(node.parameters);
      var fun = js.call('function(#) { return $newKeyword #(#); }', [
        params,
        _visit(redirect),
        params,
      ]);
      return new JS.Method(name, fun, isStatic: true)..sourceInformation = node;
    }

    // Factory constructors are essentially static methods.
    if (node.factoryKeyword != null) {
      var body = <JS.Statement>[];
      var init = _emitArgumentInitializers(node, constructor: true);
      if (init != null) body.add(init);
      body.add(_visit(node.body));
      var fun = new JS.Fun(_visit(node.parameters), new JS.Block(body));
      return new JS.Method(name, fun, isStatic: true)..sourceInformation = node;
    }

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

  JS.Expression _constructorName(ConstructorElement ctor) {
    var name = ctor.name;
    if (name != '') {
      return _emitMemberName(name, isStatic: true);
    }

    // Factory default constructors use `new` as their name, for readability
    // Other default constructors use the class name, as they aren't called
    // from call sites, but rather from Object's constructor.
    // TODO(jmesserly): revisit in the context of Dart metaclasses, and cleaning
    // up constructors to integrate more closely with ES6.
    return _propertyName(ctor.isFactory ? 'new' : ctor.enclosingElement.name);
  }

  JS.Block _emitConstructorBody(
      ConstructorDeclaration node, List<FieldDeclaration> fields) {
    var body = <JS.Statement>[];

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    ClassDeclaration cls = node.parent;
    if (node.constKeyword != null) _loader.startTopLevel(cls.element);
    var init = _emitArgumentInitializers(node, constructor: true);
    if (node.constKeyword != null) _loader.finishTopLevel(cls.element);
    if (init != null) body.add(init);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers.firstWhere(
        (i) => i is RedirectingConstructorInvocation, orElse: () => null);

    if (redirectCall != null) {
      body.add(_visit(redirectCall));
      return new JS.Block(body);
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(node.parent, fields, node));

    var superCall = node.initializers.firstWhere(
        (i) => i is SuperConstructorInvocation, orElse: () => null);

    // If no superinitializer is provided, an implicit superinitializer of the
    // form `super()` is added at the end of the initializer list, unless the
    // enclosing class is class Object.
    var jsSuper = _superConstructorCall(cls.element, superCall);
    if (jsSuper != null) body.add(jsSuper);

    body.add(_visit(node.body));
    return new JS.Block(body)..sourceInformation = node;
  }

  @override
  JS.Statement visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var name = _constructorName(node.staticElement);
    return js.statement('this.#(#);', [name, _visit(node.argumentList)]);
  }

  JS.Statement _superConstructorCall(ClassElement element,
      [SuperConstructorInvocation node]) {

    ConstructorElement superCtor;
    if (node != null) {
      superCtor = node.staticElement;
    } else {
      // Get the supertype's unnamed constructor.
      superCtor = element.supertype.element.unnamedConstructor;
      if (superCtor == null) {
        // This will only happen if the code has errors:
        // we're trying to generate an implicit constructor for a type where
        // we don't have a default constructor in the supertype.
        assert(options.forceCompile);
        return null;
      }
    }

    if (superCtor.name == '' && !_shouldCallUnnamedSuperCtor(element)) {
      return null;
    }

    var name = _constructorName(superCtor);
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
  JS.Statement _initializeFields(
      ClassDeclaration cls, List<FieldDeclaration> fieldDecls,
      [ConstructorDeclaration ctor]) {
    var unit = cls.getAncestor((a) => a is CompilationUnit);
    var constField = new ConstFieldVisitor(types, unit);
    bool isConst = ctor != null && ctor.constKeyword != null;
    if (isConst) _loader.startTopLevel(cls.element);

    // Run field initializers if they can have side-effects.
    var fields = new Map<FieldElement, JS.Expression>();
    var unsetFields = new Map<FieldElement, VariableDeclaration>();
    for (var declaration in fieldDecls) {
      for (var fieldNode in declaration.fields.variables) {
        var element = fieldNode.element;
        if (constField.isFieldInitConstant(fieldNode)) {
          unsetFields[element] = fieldNode;
        } else {
          fields[element] = _visitInitializer(fieldNode);
        }
      }
    }

    // Initialize fields from `this.fieldName` parameters.
    if (ctor != null) {
      for (var p in ctor.parameters.parameters) {
        var element = p.element;
        if (element is FieldFormalParameterElement) {
          fields[element.field] = _visit(p);
        }
      }

      // Run constructor field initializers such as `: foo = bar.baz`
      for (var init in ctor.initializers) {
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

    if (isConst) _loader.finishTopLevel(cls.element);
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

    var id = new JS.Identifier(name);
    body.add(new JS.FunctionDeclaration(id, _visit(node.functionExpression)));
    body.add(_emitFunctionTagged(id, node.element.type, topLevel: true)
        .toStatement());

    if (isPublic(name)) _addExport(name);
    return _statement(body);
  }

  JS.Method _emitTopLevelProperty(FunctionDeclaration node) {
    var name = node.name.name;
    return new JS.Method(_propertyName(name), _visit(node.functionExpression),
        isGetter: node.isGetter, isSetter: node.isSetter);
  }

  bool _executesAtTopLevel(AstNode node) {
    var ancestor = node.getAncestor((n) => n is FunctionBody ||
        (n is FieldDeclaration && n.staticKeyword == null) ||
        (n is ConstructorDeclaration && n.constKeyword == null));
    return ancestor == null;
  }

  bool _typeIsLoaded(DartType type) {
    if (type is FunctionType && (type.name == '' || type.name == null)) {
      return (_typeIsLoaded(type.returnType) &&
          type.optionalParameterTypes.every(_typeIsLoaded) &&
          type.namedParameterTypes.values.every(_typeIsLoaded) &&
          type.normalParameterTypes.every(_typeIsLoaded));
    }
    if (type.isDynamic || type.isVoid || type.isBottom) return true;
    if (type is ParameterizedType && !type.typeArguments.every(_typeIsLoaded)) {
      return false;
    }
    return _loader.isLoaded(type.element);
  }

  JS.Expression _emitFunctionTagged(JS.Expression clos, DartType type,
      {topLevel: false}) {
    var name = type.name;
    var lazy = topLevel && !_typeIsLoaded(type);

    if (type is FunctionType && (name == '' || name == null)) {
      if (type.returnType.isDynamic &&
          type.optionalParameterTypes.isEmpty &&
          type.namedParameterTypes.isEmpty &&
          type.normalParameterTypes.every((t) => t.isDynamic)) {
        return js.call('dart.fn(#)', [clos]);
      }
      if (lazy) {
        return js.call('dart.fn(#, () => #)', [clos, _emitFunctionRTTI(type)]);
      }
      return js.call('dart.fn(#, #)', [
        clos,
        _emitFunctionTypeParts(type, dynamicIsBottom: false)
      ]);
    }
    throw 'Function has non function type: $type';
  }

  @override
  JS.Expression visitFunctionExpression(FunctionExpression node) {
    var params = _visit(node.parameters);
    if (params == null) params = [];

    var parent = node.parent;
    var inDecl = parent is FunctionDeclaration;
    var inStmt = parent.parent is FunctionDeclarationStatement;
    if (inDecl && !inStmt) {
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
      var clos = js.call(code, [params, _visit(body)]);
      if (!inStmt) {
        var type = getStaticType(node);
        return _emitFunctionTagged(clos, type,
            topLevel: _executesAtTopLevel(node));
      }
      return clos;
    }
  }

  @override
  JS.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    // Use an => function to bind this.
    // Technically we only need to do this if the function actually closes over
    // `this`, but it seems harmless enough to just do it always.
    var name = new JS.Identifier(func.name.name);
    return new JS.Block([
      js.statement('let # = #;', [name, _visit(func.functionExpression)]),
      _emitFunctionTagged(name, func.element.type).toStatement()
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

    _loader.declareBeforeUse(element);

    var name = element.name;

    // type literal
    if (element is ClassElement ||
        element is DynamicElementImpl ||
        element is FunctionTypeAliasElement) {
      return _emitTypeName(fillDynamicTypeArgs(element.type, types));
    }

    // library member
    if (element.enclosingElement is CompilationUnitElement) {
      return _maybeQualifiedName(
          element, _emitMemberName(name, isStatic: true));
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
        var dynType = _emitTypeName(fillDynamicTypeArgs(type, types));
        return new JS.PropertyAccess(dynType, member);
      }

      // For instance members, we add implicit-this.
      // For method tear-offs, we ensure it's a bound method.
      var tearOff = element is MethodElement && !inInvocationContext(node);
      var code = (tearOff) ? 'dart.bind(this, #)' : 'this.#';
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

    if (element is TemporaryVariableElement) {
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

  JS.ArrayInitializer _emitTypeNames(List<DartType> types,
      {dynamicIsBottom: false}) {
    var build = (t) => _emitTypeName(t, dynamicIsBottom: dynamicIsBottom);
    return new JS.ArrayInitializer(types.map(build).toList());
  }

  JS.ObjectInitializer _emitTypeProperties(Map<String, DartType> types,
      {dynamicIsBottom: false}) {
    var properties = <JS.Property>[];
    types.forEach((name, type) {
      var key = _propertyName(name);
      var value = _emitTypeName(type, dynamicIsBottom: dynamicIsBottom);
      properties.add(new JS.Property(key, value));
    });
    return new JS.ObjectInitializer(properties);
  }

  /// Emit the pieces of a function type, as an array of return type,
  /// regular args, and optional/named args.
  /// If [dynamicIsBottom] is true, then dynamics in argument positions
  /// will be lowered to bottom instead of Object.
  List<JS.Expression> _emitFunctionTypeParts(FunctionType type,
      {bool dynamicIsBottom: true}) {
    var returnType = type.returnType;
    var parameterTypes = type.normalParameterTypes;
    var optionalTypes = type.optionalParameterTypes;
    var namedTypes = type.namedParameterTypes;
    var rt = _emitTypeName(returnType);
    var ra = _emitTypeNames(parameterTypes, dynamicIsBottom: dynamicIsBottom);
    if (!namedTypes.isEmpty) {
      assert(optionalTypes.isEmpty);
      var na =
          _emitTypeProperties(namedTypes, dynamicIsBottom: dynamicIsBottom);
      return [rt, ra, na];
    }
    if (!optionalTypes.isEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(optionalTypes, dynamicIsBottom: dynamicIsBottom);
      return [rt, ra, oa];
    }
    return [rt, ra];
  }

  JS.Expression _emitFunctionRTTI(FunctionType type) {
    var parts = _emitFunctionTypeParts(type, dynamicIsBottom: false);
    return js.call('dart.functionType(#)', [parts]);
  }

  /// Emits a Dart [type] into code.
  ///
  /// If [lowerTypedef] is set, a typedef will be expanded as if it were a
  /// function type. Similarly if [lowerGeneric] is set, the `List$()` form
  /// will be used instead of `List`. These flags are used when generating
  /// the definitions for typedefs and generic types, respectively.
  JS.Expression _emitTypeName(DartType type, {bool lowerTypedef: false,
      bool lowerGeneric: false, bool dynamicIsBottom: false}) {

    // The void and dynamic types are not defined in core.
    if (type.isVoid) {
      return js.call('dart.void');
    } else if (type.isDynamic) {
      if (dynamicIsBottom) return js.call('dart.bottom');
      return _emitTypeName(types.objectType);
    } else if (type.isBottom) {
      return js.call('dart.bottom');
    }

    _loader.declareBeforeUse(type.element);

    // TODO(jmesserly): like constants, should we hoist function types out of
    // methods? Similar issue with generic types. For all of these, we may want
    // to canonicalize them too, at least when inside the same library.
    var name = type.name;
    var element = type.element;
    if (name == '' || name == null || lowerTypedef) {
      var parts = _emitFunctionTypeParts(type as FunctionType);
      return js.call('dart.functionType(#)', [parts]);
    }

    if (type is TypeParameterType) {
      return new JS.Identifier(name);
    }

    if (type is ParameterizedType) {
      var args = type.typeArguments;
      var isCurrentClass =
          args.isNotEmpty && _loader.isCurrentElement(type.element);
      Iterable jsArgs = null;
      if (args.any((a) => a != types.dynamicType)) {
        jsArgs = args.map(_emitTypeName);
      } else if (lowerGeneric || isCurrentClass) {
        // When creating a `new S<dynamic>` we try and use the raw form
        // `new S()`, but this does not work if we're inside the same class,
        // because `S` refers to the current S<T> we are generating.
        jsArgs = [];
      }
      if (jsArgs != null) {
        var genericName = _maybeQualifiedName(
            element, _propertyName('$name\$'), _qualifiedGenericIds);
        return js.call('#(#)', [genericName, jsArgs]);
      }
    }

    return _maybeQualifiedName(element, _propertyName(name));
  }

  JS.Expression _maybeQualifiedName(Element e, JS.Expression name,
      [Map<Element, JS.MaybeQualifiedId> idTable]) {
    var libName = _libraryName(e.library);
    if (idTable == null) idTable = _qualifiedIds;

    // Mutable top-level fields should always be qualified.
    bool mutableTopLevel = e is TopLevelVariableElement && !e.isConst;
    if (e.library != currentLibrary || mutableTopLevel) {
      return new JS.PropertyAccess(libName, name);
    }

    return idTable.putIfAbsent(e, () => new JS.MaybeQualifiedId(libName, name));
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
    for (var v in node.variables.variables) {
      _loader.loadDeclaration(v, v.element);
    }
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
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.element is PropertyInducingElement) return _emitStaticField(node);

    var name = new JS.Identifier(node.name.name);
    return new JS.VariableInitialization(name, _visitInitializer(node));
  }

  /// Emits a static or top-level field.
  JS.Statement _emitStaticField(VariableDeclaration field) {
    PropertyInducingElement element = field.element;
    assert(element.isStatic);

    bool eagerInit;
    JS.Expression jsInit;
    if (field.isConst || _constField.isFieldInitConstant(field)) {
      // If the field is constant, try and generate it at the top level.
      _loader.startTopLevel(element);
      jsInit = _visitInitializer(field);
      _loader.finishTopLevel(element);
      eagerInit = _loader.isLoaded(element);
    } else {
      jsInit = _visitInitializer(field);
      eagerInit = false;
    }

    var fieldName = field.name.name;
    if (field.isConst && eagerInit && element is TopLevelVariableElement) {
      // constant fields don't change, so we can generate them as `let`
      // but add them to the module's exports. However, make sure we generate
      // anything they depend on first.

      if (isPublic(fieldName)) _addExport(fieldName);
      return js.statement('let # = #;', [new JS.Identifier(fieldName), jsInit]);
    }

    if (eagerInit && !JS.invalidStaticFieldName(fieldName)) {
      return js.statement('# = #;', [_visit(field.name), jsInit]);
    }

    var body = [];
    if (_lazyFields.isNotEmpty) {
      var existingTarget = _lazyFields[0].element.enclosingElement;
      if (existingTarget != element.enclosingElement) {
        _flushLazyFields(body);
      }
    }

    _lazyFields.add(field);

    return _statement(body);
  }

  JS.Expression _visitInitializer(VariableDeclaration node) {
    var value = _visit(node.initializer);
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    return value != null ? value : new JS.LiteralNull();
  }

  void _flushLazyFields(List<JS.Statement> body) {
    if (_lazyFields.isEmpty) return;
    body.add(_emitLazyFields(_lazyFields));
    _lazyFields.clear();
  }

  JS.Statement _emitLazyFields(List<VariableDeclaration> fields) {
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

    JS.Expression objExpr = _exportsVar;
    var target = _lazyFields[0].element.enclosingElement;
    if (target is ClassElement) {
      objExpr = new JS.Identifier(target.type.name);
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
    if (node.name != null || node.staticElement.isFactory) {
      var namedCtor = _constructorName(node.staticElement);
      return new JS.PropertyAccess(typeName, namedCtor);
    }
    return typeName;
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    emitNew() {
      var ctor = _visit(node.constructorName);
      var args = _visit(node.argumentList);
      var isFactory = node.staticElement.isFactory;
      return isFactory ? new JS.Call(ctor, args) : new JS.New(ctor, args);
    }
    if (node.isConst) return _emitConst(node, emitNew);
    return emitNew();
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
    id.staticElement = new TemporaryVariableElement.forNode(id);
    id.staticType = type;
    return id;
  }

  JS.Expression _emitConst(Expression node, JS.Expression expr()) {
    // TODO(jmesserly): emit the constants at top level if possible.
    // This wasn't quite working, so disabled for now.
    return js.call('dart.const(#)', expr());
  }

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
    if (member is PropertyAccessorElement) member = member.variable;
    bool isStatic = member is ClassMemberElement && member.isStatic;
    if (isStatic) {
      _loader.declareBeforeUse(member);
    }
    var name = _emitMemberName(memberId.name,
        type: getStaticType(target), isStatic: isStatic);
    if (rules.isDynamicTarget(target)) {
      return js.call('dart.$DLOAD(#, #)', [_visit(target), name]);
    }

    String code;
    if (member != null && member is MethodElement && !isStatic) {
      // Tear-off methods: explicitly bind it.
      // TODO(leafp): Attach runtime types to these static tearoffs
      if (_requiresStaticDispatch(target, memberId.name)) {
        return js.call('dart.#.bind(#)', [name, _visit(target)]);
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
    emitSymbol() {
      // TODO(vsm): When we canonicalize, we need to treat private symbols
      // correctly.
      var name = js.string(node.components.join('.'), "'");
      return new JS.New(_emitTypeName(types.symbolType), [name]);
    }
    return _emitConst(node, emitSymbol);
  }

  @override
  visitListLiteral(ListLiteral node) {
    emitList() {
      JS.Expression list = new JS.ArrayInitializer(_visitList(node.elements));
      ParameterizedType type = node.staticType;
      if (type.typeArguments.any((a) => a != types.dynamicType)) {
        list = js.call('dart.setType(#, #)', [list, _emitTypeName(type)]);
      }
      return list;
    }
    if (node.constKeyword != null) return _emitConst(node, emitList);
    return emitList();
  }

  @override
  visitMapLiteral(MapLiteral node) {
    // TODO(jmesserly): we can likely make these faster.
    emitMap() {
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
      return js.call('dart.map(#)', [mapArguments]);
    }
    if (node.constKeyword != null) return _emitConst(node, emitMap);
    return emitMap();
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
  /// For fast lookup of extension methods, we first check the name, then do a
  /// (possibly expensive) subtype test to see if it matches one of the types
  /// that declares that method.
  final _extensionMethods = new HashMap<String, List<InterfaceType>>();

  JSGenerator(AbstractCompiler context) : super(context) {

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
        new JSCodegenVisitor(compiler, info, _extensionMethods, fields);
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

/// A special kind of element created by the compiler, signifying a temporary
/// variable. These objects use instance equality, and should be shared
/// everywhere in the tree where they are treated as the same variable.
class TemporaryVariableElement extends LocalVariableElementImpl {
  TemporaryVariableElement.forNode(Identifier name) : super.forNode(name);

  int get hashCode => identityHashCode(this);
  bool operator ==(Object other) => identical(this, other);
}
