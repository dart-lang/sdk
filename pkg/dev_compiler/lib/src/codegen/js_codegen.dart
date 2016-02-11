// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_codegen;

import 'dart:collection' show HashSet, HashMap, SplayTreeSet;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/scanner.dart'
    show StringToken, Token, TokenType;
import 'package:analyzer/src/generated/type_system.dart'
    show StrongTypeSystemImpl;
import 'package:analyzer/src/task/dart.dart' show PublicNamespaceBuilder;

import 'ast_builder.dart' show AstBuilder;
import 'reify_coercions.dart' show CoercionReifier, Tuple2;

// TODO(jmesserly): import from its own package
import '../js/js_ast.dart' as JS;
import '../js/js_ast.dart' show js;

import '../closure/closure_annotator.dart' show ClosureAnnotator;
import '../compiler.dart'
    show AbstractCompiler, corelibOrder, getCorelibModuleName;
import '../info.dart';
import '../options.dart' show CodegenOptions;
import '../utils.dart';

import 'code_generator.dart';
import 'js_field_storage.dart';
import 'js_interop.dart';
import 'js_names.dart' as JS;
import 'js_metalet.dart' as JS;
import 'js_module_item_order.dart';
import 'js_names.dart';
import 'js_printer.dart' show writeJsLibrary;
import 'module_builder.dart';
import 'nullability_inferrer.dart';
import 'side_effect_analysis.dart';

part 'js_typeref_codegen.dart';

// Various dynamic helpers we call.
// If renaming these, make sure to check other places like the
// _runtime.js file and comments.
// TODO(jmesserly): ideally we'd have a "dynamic call" dart library we can
// import and generate calls to, rather than dart_runtime.js
const DPUT = 'dput';
const DLOAD = 'dload';
const DINDEX = 'dindex';
const DSETINDEX = 'dsetindex';
const DCALL = 'dcall';
const DSEND = 'dsend';

class JSCodegenVisitor extends GeneralizingAstVisitor
    with ClosureAnnotator, JsTypeRefCodegen {
  final AbstractCompiler compiler;
  final CodegenOptions options;
  final LibraryElement currentLibrary;
  final StrongTypeSystemImpl rules;

  /// The global extension type table.
  final HashSet<ClassElement> _extensionTypes;

  /// Information that is precomputed for this library, indicates which fields
  /// need storage slots.
  final HashSet<FieldElement> _fieldsNeedingStorage;

  /// The variable for the target of the current `..` cascade expression.
  ///
  /// Usually a [SimpleIdentifier], but it can also be other expressions
  /// that are safe to evaluate multiple times, such as `this`.
  Expression _cascadeTarget;

  /// The variable for the current catch clause
  SimpleIdentifier _catchParameter;

  /// In an async* function, this represents the stream controller parameter.
  JS.TemporaryId _asyncStarController;

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<LibraryElement, JS.TemporaryId>();
  final _exports = <String, String>{};
  final _properties = <FunctionDeclaration>[];
  final _privateNames = new HashMap<String, JS.TemporaryId>();
  final _moduleItems = <JS.Statement>[];
  final _temps = new HashMap<Element, JS.TemporaryId>();
  final _qualifiedIds = new List<Tuple2<Element, JS.MaybeQualifiedId>>();

  /// The name for the library's exports inside itself.
  /// `exports` was chosen as the most similar to ES module patterns.
  final _dartxVar = new JS.Identifier('dartx');
  final _exportsVar = new JS.TemporaryId('exports');
  final _runtimeLibVar = new JS.Identifier('dart');
  final _namedArgTemp = new JS.TemporaryId('opts');

  final TypeProvider _types;

  ConstFieldVisitor _constField;

  ModuleItemLoadOrder _loader;

  /// _interceptors.JSArray<E>, used for List literals.
  ClassElement _jsArray;

  /// The default value of the module object. See [visitLibraryDirective].
  String _jsModuleValue;

  bool _isDartRuntime;

  JSCodegenVisitor(AbstractCompiler compiler, this.rules, this.currentLibrary,
      this._extensionTypes, this._fieldsNeedingStorage)
      : compiler = compiler,
        options = compiler.options.codegenOptions,
        _types = compiler.context.typeProvider {
    _loader = new ModuleItemLoadOrder(_emitModuleItem);

    var context = compiler.context;
    var src = context.sourceFactory.forUri('dart:_interceptors');
    var interceptors = context.computeLibraryElement(src);
    _jsArray = interceptors.getType('JSArray');
    _isDartRuntime = currentLibrary.source.uri.toString() == 'dart:_runtime';
  }

  TypeProvider get types => _types;

  NullableExpressionPredicate _isNullable;

  JS.Program emitLibrary(LibraryUnit library) {
    // Modify the AST to make coercions explicit.
    new CoercionReifier(library, rules).reify();

    // Build the public namespace for this library. This allows us to do
    // constant time lookups (contrast with `Element.getChild(name)`).
    if (currentLibrary.publicNamespace == null) {
      (currentLibrary as LibraryElementImpl).publicNamespace =
          new PublicNamespaceBuilder().build(currentLibrary);
    }

    library.library.directives.forEach(_visit);

    // Rather than directly visit declarations, we instead use [_loader] to
    // visit them. It has the ability to sort elements on demand, so
    // dependencies between top level items are handled with a minimal
    // reordering of the user's input code. The loader will call back into
    // this visitor via [_emitModuleItem] when it's ready to visit the item
    // for real.
    _loader.collectElements(currentLibrary, library.partsThenLibrary);

    var units = library.partsThenLibrary;
    // TODO(ochafik): Move this down to smaller scopes (method, top-levels) to
    // save memory.
    _isNullable = new NullabilityInferrer(units,
            getStaticType: getStaticType, isJSBuiltinType: _isJSBuiltinType)
        .buildNullabilityPredicate();

    for (var unit in units) {
      _constField = new ConstFieldVisitor(types, unit);

      for (var decl in unit.declarations) {
        if (decl is TopLevelVariableDeclaration) {
          visitTopLevelVariableDeclaration(decl);
        } else {
          _loader.loadDeclaration(decl, decl.element);
        }
      }
    }

    // Flush any unwritten fields/properties.
    _flushLibraryProperties(_moduleItems);

    // Mark all qualified names as qualified or not, depending on if they need
    // to be loaded lazily or not.
    for (var elementIdPairs in _qualifiedIds) {
      var element = elementIdPairs.e0;
      var id = elementIdPairs.e1;
      id.setQualified(!_loader.isLoaded(element));
    }

    var moduleBuilder = new ModuleBuilder(options.moduleFormat);

    _exports.forEach(moduleBuilder.addExport);

    var currentModuleName = compiler.getModuleName(currentLibrary.source.uri);
    var items = <JS.ModuleItem>[];
    if (!_isDartRuntime) {
      if (currentLibrary.source.isInSystemLibrary) {
        // Force the import order of runtime libs.
        // TODO(ochafik): Reduce this to a minimum.
        for (var libUri in corelibOrder.reversed) {
          var moduleName = compiler.getModuleName(libUri);
          if (moduleName == currentModuleName) continue;
          moduleBuilder.addImport(moduleName, null);
        }
      }
      moduleBuilder.addImport('dart/_runtime', _runtimeLibVar);

      var dartxImport =
          js.statement("let # = #.dartx;", [_dartxVar, _runtimeLibVar]);
      items.add(dartxImport);
    }
    items.addAll(_moduleItems);

    _imports.forEach((LibraryElement lib, JS.TemporaryId temp) {
      moduleBuilder.addImport(compiler.getModuleName(lib.source.uri), temp,
          isLazy: _isDartRuntime || !_loader.libraryIsLoaded(lib));
    });

    // TODO(jmesserly): scriptTag support.
    // Enable this if we know we're targetting command line environment?
    // It doesn't work in browser.
    // var jsBin = compiler.options.runnerOptions.v8Binary;
    // String scriptTag = null;
    // if (library.library.scriptTag != null) scriptTag = '/usr/bin/env $jsBin';
    return moduleBuilder.build(
        currentModuleName, _jsModuleValue, _exportsVar, items);
  }

  void _emitModuleItem(AstNode node) {
    // Attempt to group adjacent properties.
    if (node is! FunctionDeclaration) _flushLibraryProperties(_moduleItems);

    var code = _visit(node);
    if (code != null) _moduleItems.add(code);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    assert(_jsModuleValue == null);

    var jsName = findAnnotation(node.element, isJSAnnotation);
    _jsModuleValue =
        getConstantField(jsName, 'name', types.stringType)?.toStringValue();
  }

  @override
  void visitImportDirective(ImportDirective node) {
    // Nothing to do yet, but we'll want to convert this to an ES6 import once
    // we have support for modules.
  }

  @override void visitPartDirective(PartDirective node) {}
  @override void visitPartOfDirective(PartOfDirective node) {}

  @override
  void visitExportDirective(ExportDirective node) {
    var exportName = _libraryName(node.uriElement);

    var currentLibNames = currentLibrary.publicNamespace.definedNames;

    var args = [_exportsVar, exportName];
    if (node.combinators.isNotEmpty) {
      var shownNames = <JS.Expression>[];
      var hiddenNames = <JS.Expression>[];

      var show = node.combinators.firstWhere((c) => c is ShowCombinator,
          orElse: () => null) as ShowCombinator;
      var hide = node.combinators.firstWhere((c) => c is HideCombinator,
          orElse: () => null) as HideCombinator;
      if (show != null) {
        shownNames.addAll(show.shownNames
            .map((i) => i.name)
            .where((s) => !currentLibNames.containsKey(s))
            .map((s) => js.string(s, "'")));
      }
      if (hide != null) {
        hiddenNames.addAll(hide.hiddenNames.map((i) => js.string(i.name, "'")));
      }
      args.add(new JS.ArrayInitializer(shownNames));
      args.add(new JS.ArrayInitializer(hiddenNames));
    }

    _moduleItems.add(js.statement('dart.export(#);', [args]));
  }

  JS.Identifier _initSymbol(JS.Identifier id) {
    var s =
        js.statement('const # = $_SYMBOL(#);', [id, js.string(id.name, "'")]);
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

  @override
  visitAsExpression(AsExpression node) {
    var from = getStaticType(node.expression);
    var to = node.type.type;

    var fromExpr = _visit(node.expression);

    // Skip the cast if it's not needed.
    if (rules.isSubtypeOf(from, to)) return fromExpr;

    // All Dart number types map to a JS double.
    if (_isNumberInJS(from) && _isNumberInJS(to)) {
      // Make sure to check when converting to int.
      if (from != _types.intType && to == _types.intType) {
        return js.call('dart.asInt(#)', [fromExpr]);
      }

      // A no-op in JavaScript.
      return fromExpr;
    }

    return js.call('dart.as(#, #)', [fromExpr, _emitTypeName(to)]);
  }

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
    if (_isNumberInJS(t)) return 'number';
    if (t == _types.stringType) return 'string';
    if (t == _types.boolType) return 'boolean';
    return null;
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    var element = node.element;
    var type = element.type;
    var name = element.name;

    var fnType = annotate(
        js.statement('const # = dart.typedef(#, () => #);', [
          name,
          js.string(name, "'"),
          _emitTypeName(type, lowerTypedef: true)
        ]),
        node,
        node.element);

    return _finishClassDef(type, fnType);
  }

  @override
  JS.Expression visitTypeName(TypeName node) => _emitTypeName(node.type);

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    var element = node.element;

    // Forward all generative constructors from the base class.
    var body = <JS.Method>[];

    var supertype = element.supertype;
    if (!supertype.isObject) {
      for (var ctor in element.constructors) {
        var parentCtor = supertype.lookUpConstructor(ctor.name, ctor.library);
        var fun = js.call('function() { super.#(...arguments); }',
            [_constructorName(parentCtor)]) as JS.Fun;
        body.add(new JS.Method(_constructorName(ctor), fun));
      }
    }

    var classExpr = new JS.ClassExpression(
        new JS.Identifier(element.name), _classHeritage(element), body);

    return _finishClassDef(
        element.type, _emitClassHeritageWorkaround(classExpr));
  }

  JS.Statement _emitJsType(String dartClassName, DartObject jsName) {
    var jsTypeName =
        getConstantField(jsName, 'name', types.stringType)?.toStringValue();

    if (jsTypeName != null && jsTypeName != dartClassName) {
      // We export the JS type as if it was a Dart type. For example this allows
      // `dom.InputElement` to actually be HTMLInputElement.
      // TODO(jmesserly): if we had the JS name on the Element, we could just
      // generate it correctly when we refer to it.
      if (isPublic(dartClassName)) _addExport(dartClassName);
      return js.statement('const # = #;', [dartClassName, jsTypeName]);
    }
    return null;
  }

  @override
  JS.Statement visitClassDeclaration(ClassDeclaration node) {
    var classElem = node.element;
    var type = classElem.type;
    var jsName = findAnnotation(classElem, isJSAnnotation);

    if (jsName != null) return _emitJsType(node.name.name, jsName);

    var ctors = <ConstructorDeclaration>[];
    var fields = <FieldDeclaration>[];
    var staticFields = <FieldDeclaration>[];
    var methods = <MethodDeclaration>[];
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        ctors.add(member);
      } else if (member is FieldDeclaration) {
        (member.isStatic ? staticFields : fields).add(member);
      } else if (member is MethodDeclaration) {
        methods.add(member);
      }
    }

    var classExpr = new JS.ClassExpression(new JS.Identifier(type.name),
        _classHeritage(classElem), _emitClassMethods(node, ctors, fields),
        typeParams: _emitTypeParams(classElem).toList(),
        fields:
            _emitFieldDeclarations(classElem, fields, staticFields).toList());

    String jsPeerName;
    var jsPeer = findAnnotation(classElem, isJsPeerInterface);
    // Only look at "Native" annotations on registered extension types.
    // E.g., we're current ignoring the ones in dart:html.
    if (jsPeer == null && _extensionTypes.contains(classElem)) {
      jsPeer = findAnnotation(classElem, isNativeAnnotation);
    }
    if (jsPeer != null) {
      jsPeerName =
          getConstantField(jsPeer, 'name', types.stringType)?.toStringValue();
      if (jsPeerName.contains(',')) {
        jsPeerName = jsPeerName.split(',')[0];
      }
    }

    var body = _finishClassMembers(classElem, classExpr, ctors, fields,
        staticFields, methods, node.metadata, jsPeerName);

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
          'dart.registerExtension(dart.global.#, #);',
          [_propertyName(jsPeerName), classElem.name]);
      return _statement([result, copyMembers]);
    }
    return result;
  }

  Iterable<JS.Identifier> _emitTypeParams(TypeParameterizedElement e) sync* {
    if (!options.closure) return;
    for (var typeParam in e.typeParameters) {
      yield new JS.Identifier(typeParam.name);
    }
  }

  /// Emit field declarations for TypeScript & Closure's ES6_TYPED
  /// (e.g. `class Foo { i: string; }`)
  Iterable<JS.VariableDeclarationList> _emitFieldDeclarations(
      ClassElement classElem,
      List<FieldDeclaration> fields,
      List<FieldDeclaration> staticFields) sync* {
    if (!options.closure) return;

    makeInitialization(VariableDeclaration decl) =>
        new JS.VariableInitialization(
            new JS.Identifier(
                // TODO(ochafik): use a refactored _emitMemberName instead.
                decl.name.name,
                type: emitTypeRef(decl.element.type)),
            null);

    for (var field in fields) {
      yield new JS.VariableDeclarationList(
          null, field.fields.variables.map(makeInitialization).toList());
    }
    for (var field in staticFields) {
      yield new JS.VariableDeclarationList(
          'static', field.fields.variables.map(makeInitialization).toList());
    }
  }

  @override
  JS.Statement visitEnumDeclaration(EnumDeclaration node) {
    var element = node.element;
    var type = element.type;
    var name = js.string(type.name);
    var id = new JS.Identifier(type.name);

    // Generate a class per section 13 of the spec.
    // TODO(vsm): Generate any accompanying metadata

    // Create constructor and initialize index
    var constructor = new JS.Method(
        name, js.call('function(index) { this.index = index; }') as JS.Fun);
    var fields = new List<ConstFieldElementImpl>.from(
        element.fields.where((f) => f.type == type));

    // Create toString() method
    var properties = new List<JS.Property>();
    for (var i = 0; i < fields.length; ++i) {
      properties.add(new JS.Property(
          js.number(i), js.string('${type.name}.${fields[i].name}')));
    }
    var nameMap = new JS.ObjectInitializer(properties, multiline: true);
    var toStringF = new JS.Method(js.string('toString'),
        js.call('function() { return #[this.index]; }', nameMap) as JS.Fun);

    // Create enum class
    var classExpr = new JS.ClassExpression(
        id, _classHeritage(element), [constructor, toStringF]);
    var result = <JS.Statement>[js.statement('#', classExpr)];

    // Create static fields for each enum value
    for (var i = 0; i < fields.length; ++i) {
      result.add(js.statement('#.# = dart.const(new #(#));',
          [id, fields[i].name, id, js.number(i)]));
    }

    // Create static values list
    var values = new JS.ArrayInitializer(new List<JS.Expression>.from(
        fields.map((f) => js.call('#.#', [id, f.name]))));
    result.add(js.statement('#.values = dart.const(dart.list(#, #));',
        [id, values, _emitTypeName(type)]));

    if (isPublic(type.name)) _addExport(type.name);
    return _statement(result);
  }

  /// Given a class element and body, complete the class declaration.
  /// This handles generic type parameters, laziness (in library-cycle cases),
  /// and ensuring dependencies are loaded first.
  JS.Statement _finishClassDef(ParameterizedType type, JS.Statement body) {
    var name = type.name;
    var genericName = '$name\$';

    JS.Statement genericDef = null;
    if (_typeFormalsOf(type).isNotEmpty) {
      genericDef = _emitGenericClassDef(type, body);
    }
    // The base class and all mixins must be declared before this class.
    if (!_loader.isLoaded(type.element)) {
      // TODO(jmesserly): the lazy class def is a simple solution for now.
      // We may want to consider other options in the future.

      if (genericDef != null) {
        return js.statement(
            '{ #; dart.defineLazyClassGeneric(#, #, { get: # }); }',
            [genericDef, _exportsVar, _propertyName(name), genericName]);
      }

      return js.statement(
          'dart.defineLazyClass(#, { get #() { #; return #; } });',
          [_exportsVar, _propertyName(name), body, name]);
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
    var typeParams = _typeFormalsOf(type).map((p) => p.name);
    if (isPublic(name)) _addExport(genericName);
    return js.statement('const # = dart.generic(function(#) { #; return #; });',
        [genericName, typeParams, body, name]);
  }

  final _hasDeferredSupertype = new HashSet<ClassElement>();

  bool _deferIfNeeded(DartType type, ClassElement current) {
    if (type is ParameterizedType) {
      var typeArguments = type.typeArguments;
      for (var typeArg in typeArguments) {
        var typeElement = typeArg.element;
        // FIXME(vsm): This does not track mutual recursive dependences.
        if (current == typeElement || _deferIfNeeded(typeArg, current)) {
          return true;
        }
      }
    }
    return false;
  }

  JS.Expression _classHeritage(ClassElement element) {
    var type = element.type;
    if (type.isObject) return null;

    // Assume we can load eagerly, until proven otherwise.
    _loader.startTopLevel(element);

    // Find the super type
    JS.Expression heritage;
    var supertype = type.superclass;
    if (_deferIfNeeded(supertype, element)) {
      // Fall back to raw type.
      supertype = fillDynamicTypeArgs(supertype.element.type, _types);
      _hasDeferredSupertype.add(element);
    }
    heritage = _emitTypeName(supertype);

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

    bool hasJsPeer = findAnnotation(element, isJsPeerInterface) != null;

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
    var parentType = findSupertype(t, _implementsIterable);
    if (parentType != null) return null;

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return new JS.Method(
        js.call('$_SYMBOL.iterator'),
        js.call('function() { return new dart.JsIterator(this.#); }',
            [_emitMemberName('iterator', type: t)]) as JS.Fun);
  }

  JS.Expression _instantiateAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement) {
      return _emitInstanceCreationExpression(element, element.returnType,
          node.constructorName, node.arguments, true);
    } else {
      return _visit(node.name);
    }
  }

  _isQualifiedPath(JS.Expression node) =>
      node is JS.Identifier ||
      node is JS.PropertyAccess &&
          _isQualifiedPath(node.receiver) &&
          node.selector is JS.LiteralString;

  /// Workaround for Closure: super classes must be qualified paths.
  JS.Statement _emitClassHeritageWorkaround(JS.ClassExpression cls) {
    if (options.closure &&
        cls.heritage != null &&
        !_isQualifiedPath(cls.heritage)) {
      var superVar = new JS.TemporaryId(cls.name.name + r'$super');
      return _statement([
        js.statement('const # = #;', [superVar, cls.heritage]),
        new JS.ClassDeclaration(new JS.ClassExpression(
            cls.name, superVar, cls.methods,
            typeParams: cls.typeParams, fields: cls.fields))
      ]);
    }
    return new JS.ClassDeclaration(cls);
  }

  /// Emit class members that need to come after the class declaration, such
  /// as static fields. See [_emitClassMethods] for things that are emitted
  /// inside the ES6 `class { ... }` node.
  JS.Statement _finishClassMembers(
      ClassElement classElem,
      JS.ClassExpression cls,
      List<ConstructorDeclaration> ctors,
      List<FieldDeclaration> fields,
      List<FieldDeclaration> staticFields,
      List<MethodDeclaration> methods,
      List<Annotation> metadata,
      String jsPeerName) {
    var name = classElem.name;
    var body = <JS.Statement>[];

    if (_extensionTypes.contains(classElem)) {
      var dartxNames = <JS.Expression>[];
      for (var m in methods) {
        if (!m.isAbstract && !m.isStatic && m.element.isPublic) {
          dartxNames.add(_elementMemberName(m.element, allowExtensions: false));
        }
      }
      if (dartxNames.isNotEmpty) {
        body.add(js.statement('dart.defineExtensionNames(#)',
            [new JS.ArrayInitializer(dartxNames, multiline: true)]));
      }
    }

    body.add(_emitClassHeritageWorkaround(cls));

    // TODO(jmesserly): we should really just extend native Array.
    if (jsPeerName != null && classElem.typeParameters.isNotEmpty) {
      body.add(js.statement('dart.setBaseClass(#, dart.global.#);',
          [classElem.name, _propertyName(jsPeerName)]));
    }

    // Deferred Superclass
    if (_hasDeferredSupertype.contains(classElem)) {
      body.add(js.statement('#.prototype.__proto__ = #.prototype;',
          [name, _emitTypeName(classElem.type.superclass)]));
    }

    // Interfaces
    if (classElem.interfaces.isNotEmpty) {
      body.add(js.statement('#[dart.implements] = () => #;', [
        name,
        new JS.ArrayInitializer(new List<JS.Expression>.from(
            classElem.interfaces.map(_emitTypeName)))
      ]));
    }

    // Named constructors
    for (ConstructorDeclaration member in ctors) {
      if (member.name != null && member.factoryKeyword == null) {
        body.add(js.statement('dart.defineNamedConstructor(#, #);',
            [name, _emitMemberName(member.name.name, isStatic: true)]));
      }
    }

    // Emits instance fields, if they are virtual
    // (in other words, they override a getter/setter pair).
    for (FieldDeclaration member in fields) {
      for (VariableDeclaration field in member.fields.variables) {
        if (_fieldsNeedingStorage.contains(field.element)) {
          body.add(_overrideField(field.element));
        }
      }
    }

    // Emit the signature on the class recording the runtime type information
    var extensions = _extensionsToImplement(classElem);
    {
      var tStatics = <JS.Property>[];
      var tMethods = <JS.Property>[];
      var sNames = <JS.Expression>[];
      for (MethodDeclaration node in methods) {
        if (!(node.isSetter || node.isGetter || node.isAbstract)) {
          var name = node.name.name;
          var element = node.element;
          var inheritedElement =
              classElem.lookUpInheritedConcreteMethod(name, currentLibrary);
          if (inheritedElement != null &&
              inheritedElement.type == element.type) {
            continue;
          }
          var memberName = _elementMemberName(element);
          var parts = _emitFunctionTypeParts(element.type);
          var property =
              new JS.Property(memberName, new JS.ArrayInitializer(parts));
          if (node.isStatic) {
            tStatics.add(property);
            sNames.add(memberName);
          } else {
            tMethods.add(property);
          }
        }
      }

      var tCtors = <JS.Property>[];
      for (ConstructorDeclaration node in ctors) {
        var memberName = _constructorName(node.element);
        var element = node.element;
        var parts = _emitFunctionTypeParts(element.type, node.parameters);
        var property =
            new JS.Property(memberName, new JS.ArrayInitializer(parts));
        tCtors.add(property);
      }

      JS.Property build(String name, List<JS.Property> elements) {
        var o =
            new JS.ObjectInitializer(elements, multiline: elements.length > 1);
        var e = js.call('() => #', o);
        return new JS.Property(_propertyName(name), e);
      }
      var sigFields = <JS.Property>[];
      if (!tCtors.isEmpty) sigFields.add(build('constructors', tCtors));
      if (!tMethods.isEmpty) sigFields.add(build('methods', tMethods));
      if (!tStatics.isEmpty) {
        assert(!sNames.isEmpty);
        var aNames = new JS.Property(
            _propertyName('names'), new JS.ArrayInitializer(sNames));
        sigFields.add(build('statics', tStatics));
        sigFields.add(aNames);
      }
      if (!sigFields.isEmpty || extensions.isNotEmpty) {
        var sig = new JS.ObjectInitializer(sigFields);
        var classExpr = new JS.Identifier(name);
        body.add(js.statement('dart.setSignature(#, #);', [classExpr, sig]));
      }
    }

    // If a concrete class implements one of our extensions, we might need to
    // add forwarders.
    if (extensions.isNotEmpty) {
      var methodNames = <JS.Expression>[];
      for (var e in extensions) {
        methodNames.add(_elementMemberName(e));
      }
      body.add(js.statement('dart.defineExtensionMembers(#, #);', [
        name,
        new JS.ArrayInitializer(methodNames, multiline: methodNames.length > 4)
      ]));
    }

    // TODO(vsm): Make this optional per #268.
    // Metadata
    if (metadata.isNotEmpty) {
      body.add(js.statement('#[dart.metadata] = () => #;', [
        name,
        new JS.ArrayInitializer(
            new List<JS.Expression>.from(metadata.map(_instantiateAnnotation)))
      ]));
    }

    // Emits static fields. These are eager initialized if possible, otherwise
    // they are made lazy.
    var lazyStatics = <VariableDeclaration>[];
    for (FieldDeclaration member in staticFields) {
      for (VariableDeclaration field in member.fields.variables) {
        JS.Statement eagerField = _emitConstantStaticField(classElem, field);
        if (eagerField != null) {
          body.add(eagerField);
        } else {
          lazyStatics.add(field);
        }
      }
    }
    if (lazyStatics.isNotEmpty) {
      body.add(_emitLazyFields(classElem, lazyStatics));
    }

    return _statement(body);
  }

  List<ExecutableElement> _extensionsToImplement(ClassElement element) {
    var members = <ExecutableElement>[];
    if (_extensionTypes.contains(element)) return members;

    // Collect all extension types we implement.
    var type = element.type;
    var types = new Set<ClassElement>();
    _collectExtensions(type, types);
    if (types.isEmpty) return members;

    // Collect all possible extension method names.
    var extensionMembers = new HashSet<String>();
    for (var t in types) {
      for (var m in [t.methods, t.accessors].expand((e) => e)) {
        if (!m.isStatic) extensionMembers.add(m.name);
      }
    }

    // Collect all of extension methods this type implements.
    for (var m in [type.methods, type.accessors].expand((e) => e)) {
      if (!m.isStatic && !m.isAbstract && extensionMembers.contains(m.name)) {
        members.add(m);
      }
    }
    return members;
  }

  /// Collections the type and all supertypes, including interfaces, but
  /// excluding [Object].
  void _collectExtensions(InterfaceType type, Set<ClassElement> types) {
    if (type.isObject) return;
    var element = type.element;
    if (_extensionTypes.contains(element)) types.add(element);
    for (var m in type.mixins.reversed) {
      _collectExtensions(m, types);
    }
    for (var i in type.interfaces) {
      _collectExtensions(i, types);
    }
    _collectExtensions(type.superclass, types);
  }

  JS.Statement _overrideField(FieldElement e) {
    var cls = e.enclosingElement;
    return js.statement('dart.virtualField(#, #)',
        [cls.name, _emitMemberName(e.name, type: cls.type)]);
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
    if (superCall != null) {
      body = [
        [body, superCall]
      ];
    }
    var name = _constructorName(node.element.unnamedConstructor);
    return annotate(
        new JS.Method(name, js.call('function() { #; }', body) as JS.Fun),
        node,
        node.element);
  }

  JS.Method _emitConstructor(ConstructorDeclaration node, InterfaceType type,
      List<FieldDeclaration> fields, bool isObject) {
    if (_externalOrNative(node)) return null;

    var name = _constructorName(node.element);
    var returnType = emitTypeRef(node.element.enclosingElement.type);

    // Wacky factory redirecting constructors: factory Foo.q(x, y) = Bar.baz;
    var redirect = node.redirectedConstructor;
    if (redirect != null) {
      var newKeyword = redirect.staticElement.isFactory ? '' : 'new';
      // Pass along all arguments verbatim, and let the callee handle them.
      // TODO(jmesserly): we'll need something different once we have
      // rest/spread support, but this should work for now.
      var params =
          _emitFormalParameterList(node.parameters, allowDestructuring: false);

      var fun = new JS.Fun(
          params,
          js.statement(
              '{ return $newKeyword #(#); }', [_visit(redirect), params]),
          returnType: returnType);
      return annotate(
          new JS.Method(name, fun, isStatic: true), node, node.element);
    }

    // For const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    ClassDeclaration cls = node.parent;
    if (node.constKeyword != null) _loader.startTopLevel(cls.element);
    var params = _emitFormalParameterList(node.parameters);
    if (node.constKeyword != null) _loader.finishTopLevel(cls.element);

    // Factory constructors are essentially static methods.
    if (node.factoryKeyword != null) {
      var body = <JS.Statement>[];
      var init = _emitArgumentInitializers(node, constructor: true);
      if (init != null) body.add(init);
      body.add(_visit(node.body));
      var fun = new JS.Fun(params, new JS.Block(body), returnType: returnType);
      return annotate(
          new JS.Method(name, fun, isStatic: true), node, node.element);
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
      body = js.statement('''{
        // Get the class name for this instance.
        let name = this.constructor.name;
        // Call the default constructor.
        let result = void 0;
        if (name in this) result = this[name](...arguments);
        return result === void 0 ? this : result;
      }''') as JS.Block;
    } else {
      body = _emitConstructorBody(node, fields);
    }

    // We generate constructors as initializer methods in the class;
    // this allows use of `super` for instance methods/properties.
    // It also avoids V8 restrictions on `super` in default constructors.
    return annotate(
        new JS.Method(name, new JS.Fun(params, body, returnType: returnType)),
        node,
        node.element);
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
        (i) => i is RedirectingConstructorInvocation,
        orElse: () => null);

    if (redirectCall != null) {
      body.add(_visit(redirectCall));
      return new JS.Block(body);
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(cls, fields, node));

    var superCall = node.initializers.firstWhere(
        (i) => i is SuperConstructorInvocation,
        orElse: () => null) as SuperConstructorInvocation;

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

    if (superCtor == null) {
      print('Error generating: ${element.displayName}');
    }
    if (superCtor.name == '' && !_shouldCallUnnamedSuperCtor(element)) {
      return null;
    }

    var name = _constructorName(superCtor);
    var args = node != null ? _visit(node.argumentList) : [];
    return annotate(js.statement('super.#(#);', [name, args]), node);
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
    var unit = cls.getAncestor((a) => a is CompilationUnit) as CompilationUnit;
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
          unsetFields[element as FieldElement] = fieldNode;
        } else {
          fields[element as FieldElement] = _visitInitializer(fieldNode);
        }
      }
    }

    // Initialize fields from `this.fieldName` parameters.
    if (ctor != null) {
      for (var p in ctor.parameters.parameters) {
        var element = p.element;
        if (element is FieldFormalParameterElement) {
          fields[element.field] = _emitFormalParameter(p, allowType: false);
        }
      }

      // Run constructor field initializers such as `: foo = bar.baz`
      for (var init in ctor.initializers) {
        if (init is ConstructorFieldInitializer) {
          fields[init.fieldName.staticElement as FieldElement] =
              _visit(init.expression);
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
        value = new JS.LiteralNull();
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

    var body = <JS.Statement>[];
    for (var param in parameters.parameters) {
      var jsParam = _emitSimpleIdentifier(param.identifier, allowType: false);

      if (param.kind == ParameterKind.NAMED) {
        if (!options.destructureNamedParams) {
          // Parameters will be passed using their real names, not the (possibly
          // renamed) local variable.
          var paramName = js.string(param.identifier.name, "'");

          // TODO(ochafik): Fix `'prop' in obj` to please Closure's renaming.
          body.add(js.statement('let # = # && # in # ? #.# : #;', [
            jsParam,
            _namedArgTemp,
            paramName,
            _namedArgTemp,
            _namedArgTemp,
            paramName,
            _defaultParamValue(param),
          ]));
        }
      } else if (param.kind == ParameterKind.POSITIONAL &&
          !options.destructureNamedParams) {
        body.add(js.statement('if (# === void 0) # = #;',
            [jsParam, jsParam, _defaultParamValue(param)]));
      }

      // TODO(jmesserly): various problems here, see:
      // https://github.com/dart-lang/dev_compiler/issues/161
      var paramType = param.element.type;
      if (!constructor && _hasUnsoundTypeParameter(paramType)) {
        body.add(js
            .statement('dart.as(#, #);', [jsParam, _emitTypeName(paramType)]));
      }
    }
    return body.isEmpty ? null : _statement(body);
  }

  bool _isUnsoundTypeParameter(DartType t) =>
      t is TypeParameterType && t.element.enclosingElement is ClassElement;

  bool _hasUnsoundTypeParameter(DartType t) =>
      _isUnsoundTypeParameter(t) ||
      t is ParameterizedType && t.typeArguments.any(_hasUnsoundTypeParameter);

  JS.Expression _defaultParamValue(FormalParameter param) {
    if (param is DefaultFormalParameter && param.defaultValue != null) {
      return _visit(param.defaultValue);
    } else {
      return new JS.LiteralNull();
    }
  }

  JS.Fun _emitNativeFunctionBody(
      List<JS.Parameter> params, MethodDeclaration node) {
    if (node.isStatic) {
      // TODO(vsm): Do we need to handle this case?
      return null;
    }

    String name = node.name.name;
    var annotation = findAnnotation(node.element, isJsName);
    if (annotation != null) {
      name = getConstantField(annotation, 'name', types.stringType)
          ?.toStringValue();
    }
    if (node.isGetter) {
      return new JS.Fun(params, js.statement('{ return this.#; }', [name]));
    } else if (node.isSetter) {
      return new JS.Fun(
          params, js.statement('{ this.# = #; }', [name, params.last]));
    } else {
      return new JS.Fun(
          params, js.statement('{ return this.#(#); }', [name, params]));
    }
  }

  JS.Method _emitMethodDeclaration(DartType type, MethodDeclaration node) {
    if (node.isAbstract) {
      return null;
    }

    var params = _visit(node.parameters) as List<JS.Parameter>;
    if (params == null) params = <JS.Parameter>[];

    JS.Fun fn;
    if (_externalOrNative(node)) {
      fn = _emitNativeFunctionBody(params, node);
      // TODO(vsm): Remove if / when we handle the static case above.
      if (fn == null) return null;
    } else {
      var typeParams = _emitTypeParams(node.element).toList();
      var returnType = emitTypeRef(node.element.returnType);
      fn = _emitFunctionBody(params, node.body, typeParams, returnType);
    }

    if (node.operatorKeyword != null &&
        node.name.name == '[]=' &&
        params.isNotEmpty) {
      // []= methods need to return the value. We could also address this at
      // call sites, but it's cleaner to instead transform the operator method.
      var returnValue = new JS.Return(params.last);
      var body = fn.body;
      if (JS.Return.foundIn(fn)) {
        // If a return is inside body, transform `(params) { body }` to
        // `(params) { (() => { body })(); return value; }`.
        // TODO(jmesserly): we could instead generate the return differently,
        // and avoid the immediately invoked function.
        body = new JS.Call(new JS.ArrowFun([], fn.body), []).toStatement();
      }
      // Rewrite the function to include the return.
      fn = new JS.Fun(fn.params, new JS.Block([body, returnValue]),
          typeParams: fn.typeParams,
          returnType: fn.returnType)..sourceInformation = fn.sourceInformation;
    }

    return annotate(
        new JS.Method(_elementMemberName(node.element), fn,
            isGetter: node.isGetter,
            isSetter: node.isSetter,
            isStatic: node.isStatic),
        node,
        node.element);
  }

  /// Returns the name value of the `JSExportName` annotation (when compiling
  /// the SDK), or `null` if there's none. This is used to control the name
  /// under which functions are compiled and exported.
  String _getJSExportName(Element e) {
    if (!e.source.isInSystemLibrary) {
      return null;
    }
    var jsName = findAnnotation(e, isJSExportNameAnnotation);
    return getConstantField(jsName, 'name', types.stringType)?.toStringValue();
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

    var fn = _visit(node.functionExpression);

    if (currentLibrary.source.isInSystemLibrary &&
        _isInlineJSFunction(node.functionExpression)) {
      fn = _simplifyPassThroughArrowFunCallBody(fn);
    }

    var id = new JS.Identifier(name);
    body.add(annotate(new JS.FunctionDeclaration(id, fn), node, node.element));
    if (!_isDartRuntime) {
      body.add(_emitFunctionTagged(id, node.element.type, topLevel: true)
          .toStatement());
    }

    if (isPublic(name)) {
      _addExport(name, _getJSExportName(node.element) ?? name);
    }
    return _statement(body);
  }

  bool _isInlineJSFunction(FunctionExpression functionExpression) {
    var body = functionExpression.body;
    if (body is ExpressionFunctionBody) {
      return _isJSInvocation(body.expression);
    } else if (body is BlockFunctionBody) {
      if (body.block.statements.length == 1) {
        var stat = body.block.statements.single;
        if (stat is ReturnStatement) {
          return _isJSInvocation(stat.expression);
        }
      }
    }
    return false;
  }

  bool _isJSInvocation(Expression expr) =>
      expr is MethodInvocation && isInlineJS(expr.methodName.staticElement);

  // Simplify `(args) => (() => { ... })()` to `(args) => { ... }`.
  // Note: this allows silently passing args through to the body, which only
  // works if we don't do weird renamings of Dart params.
  JS.Fun _simplifyPassThroughArrowFunCallBody(JS.Fun fn) {
    if (fn.body is JS.Block && fn.body.statements.length == 1) {
      var stat = fn.body.statements.single;
      if (stat is JS.Return && stat.value is JS.Call) {
        JS.Call call = stat.value;
        if (call.target is JS.ArrowFun && call.arguments.isEmpty) {
          JS.ArrowFun innerFun = call.target;
          if (innerFun.params.isEmpty) {
            return new JS.Fun(fn.params, innerFun.body,
                typeParams: fn.typeParams, returnType: fn.returnType);
          }
        }
      }
    }
    return fn;
  }

  JS.Method _emitTopLevelProperty(FunctionDeclaration node) {
    var name = node.name.name;
    return annotate(
        new JS.Method(_propertyName(name), _visit(node.functionExpression),
            isGetter: node.isGetter, isSetter: node.isSetter),
        node,
        node.element);
  }

  bool _executesAtTopLevel(AstNode node) {
    var ancestor = node.getAncestor((n) =>
        n is FunctionBody ||
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
      return js.call('dart.fn(#, #)', [clos, _emitFunctionTypeParts(type)]);
    }
    throw 'Function has non function type: $type';
  }

  @override
  JS.Expression visitFunctionExpression(FunctionExpression node) {
    var params = _visit(node.parameters) as List<JS.Parameter>;
    if (params == null) params = <JS.Parameter>[];

    var parent = node.parent;
    var inStmt = parent.parent is FunctionDeclarationStatement;
    var typeParams = _emitTypeParams(node.element).toList();
    var returnType = emitTypeRef(node.element.returnType);
    if (parent is FunctionDeclaration) {
      return _emitFunctionBody(params, node.body, typeParams, returnType);
    } else {
      // Chrome Canary does not accept default values with destructuring in
      // arrow functions yet (e.g. `({a} = {}) => 1`) but happily accepts them
      // with regular functions (e.g. `function({a} = {}) { return 1 }`).
      // Note that Firefox accepts both syntaxes just fine.
      // TODO(ochafik): Simplify this code when Chrome Canary catches up.
      var canUseArrowFun = !node.parameters.parameters.any(_isNamedParam);

      JS.Node jsBody;
      var body = node.body;
      if (body.isGenerator || body.isAsynchronous) {
        jsBody = _emitGeneratorFunctionBody(params, body, returnType);
      } else if (body is ExpressionFunctionBody) {
        jsBody = _visit(body.expression);
      } else {
        jsBody = _visit(body);
      }
      if (jsBody is JS.Expression && !canUseArrowFun) {
        jsBody = js.statement("{ return #; }", [jsBody]);
      }
      var clos = canUseArrowFun
          ? new JS.ArrowFun(params, jsBody,
              typeParams: typeParams, returnType: returnType)
          : new JS.Fun(params, jsBody,
              typeParams: typeParams, returnType: returnType);
      if (!inStmt) {
        var type = getStaticType(node);
        return _emitFunctionTagged(clos, type,
            topLevel: _executesAtTopLevel(node));
      }
      return clos;
    }
  }

  JS.Fun _emitFunctionBody(List<JS.Parameter> params, FunctionBody body,
      List<JS.Identifier> typeParams, JS.TypeRef returnType) {
    // sync*, async, async*
    if (body.isAsynchronous || body.isGenerator) {
      return new JS.Fun(
          params,
          js.statement('{ return #; }',
              [_emitGeneratorFunctionBody(params, body, returnType)]),
          returnType: returnType);
    }
    // normal function (sync)
    return new JS.Fun(params, _visit(body),
        typeParams: typeParams, returnType: returnType);
  }

  JS.Expression _emitGeneratorFunctionBody(
      List<JS.Parameter> params, FunctionBody body, JS.TypeRef returnType) {
    var kind = body.isSynchronous ? 'sync' : 'async';
    if (body.isGenerator) kind += 'Star';

    // Transforms `sync*` `async` and `async*` function bodies
    // using ES6 generators.
    //
    // `sync*` wraps a generator in a Dart Iterable<T>:
    //
    // function name(<args>) {
    //   return dart.syncStar(function*(<args>) {
    //     <body>
    //   }, T, <args>).bind(this);
    // }
    //
    // We need to include <args> in case any are mutated, so each `.iterator`
    // gets the same initial values.
    //
    // TODO(jmesserly): we could omit the args for the common case where args
    // are not mutated inside the generator.
    //
    // In the future, we might be able to simplify this, see:
    // https://github.com/dart-lang/dev_compiler/issues/247.
    //
    // `async` works the same, but uses the `dart.async` helper.
    //
    // In the body of a `sync*` and `async`, `yield`/`await` are both generated
    // simply as `yield`.
    //
    // `async*` uses the `dart.asyncStar` helper, and also has an extra `stream`
    // argument to the generator, which is used for passing values to the
    // _AsyncStarStreamController implementation type.
    // `yield` is specially generated inside `async*`, see visitYieldStatement.
    // `await` is generated as `yield`.
    // runtime/_generators.js has an example of what the code is generated as.
    var savedController = _asyncStarController;
    List jsParams;
    if (kind == 'asyncStar') {
      _asyncStarController = new JS.TemporaryId('stream');
      jsParams = [_asyncStarController]..addAll(params);
    } else {
      _asyncStarController = null;
      jsParams = params;
    }
    JS.Expression gen = new JS.Fun(jsParams, _visit(body),
        isGenerator: true, returnType: returnType);
    if (JS.This.foundIn(gen)) {
      gen = js.call('#.bind(this)', gen);
    }
    _asyncStarController = savedController;

    var T = _emitTypeName(_getExpectedReturnType(body));
    return js.call('dart.#(#)', [
      kind,
      [gen, T]..addAll(params)
    ]);
  }

  @override
  JS.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    var fn = _visit(func.functionExpression);

    var name = new JS.Identifier(func.name.name);
    JS.Statement declareFn;
    if (JS.This.foundIn(fn)) {
      declareFn = js.statement('const # = #.bind(this);', [name, fn]);
    } else {
      declareFn = new JS.FunctionDeclaration(name, fn);
    }
    declareFn = annotate(declareFn, node, node.functionDeclaration.element);

    return new JS.Block([
      declareFn,
      _emitFunctionTagged(name, func.element.type).toStatement()
    ]);
  }

  @override
  JS.Expression visitSimpleIdentifier(SimpleIdentifier node) =>
      _emitSimpleIdentifier(node);

  /// Writes a simple identifier. This can handle implicit `this` as well as
  /// going through the qualified library name if necessary.
  JS.Expression _emitSimpleIdentifier(SimpleIdentifier node,
      {bool allowType: false}) {
    var accessor = node.staticElement;
    if (accessor == null) {
      return js.commentExpression(
          'Unimplemented unknown name', new JS.Identifier(node.name));
    }

    // Get the original declaring element. If we had a property accessor, this
    // indirects back to a (possibly synthetic) field.
    var element = accessor;
    if (accessor is PropertyAccessorElement) element = accessor.variable;

    _loader.declareBeforeUse(element);

    // type literal
    if (element is ClassElement ||
        element is DynamicElementImpl ||
        element is FunctionTypeAliasElement) {
      return _emitTypeName(
          fillDynamicTypeArgs((element as dynamic).type, types));
    }

    // library member
    if (element.enclosingElement is CompilationUnitElement) {
      return _emitTopLevelName(element);
    }

    var name = element.name;

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

    return annotate(
        new JS.Identifier(name,
            type: allowType ? emitTypeRef(node.bestType) : null),
        node);
  }

  JS.TemporaryId _getTemp(Element key, String name) =>
      _temps.putIfAbsent(key, () => new JS.TemporaryId(name));

  List<Annotation> _parameterMetadata(FormalParameter p) =>
      (p is NormalFormalParameter)
          ? p.metadata
          : (p as DefaultFormalParameter).parameter.metadata;

  JS.ArrayInitializer _emitTypeNames(List<DartType> types,
      [List<FormalParameter> parameters]) {
    var result = <JS.Expression>[];
    for (int i = 0; i < types.length; ++i) {
      var metadata =
          parameters != null ? _parameterMetadata(parameters[i]) : [];
      var typeName = _emitTypeName(types[i]);
      var value = typeName;
      // TODO(vsm): Make this optional per #268.
      if (metadata.isNotEmpty) {
        metadata = metadata.map(_instantiateAnnotation).toList();
        value = new JS.ArrayInitializer([typeName]..addAll(metadata));
      }
      result.add(value);
    }
    return new JS.ArrayInitializer(result);
  }

  JS.ObjectInitializer _emitTypeProperties(Map<String, DartType> types) {
    var properties = <JS.Property>[];
    types.forEach((name, type) {
      var key = _propertyName(name);
      var value = _emitTypeName(type);
      properties.add(new JS.Property(key, value));
    });
    return new JS.ObjectInitializer(properties);
  }

  /// Emit the pieces of a function type, as an array of return type,
  /// regular args, and optional/named args.
  List<JS.Expression> _emitFunctionTypeParts(FunctionType type,
      [FormalParameterList parameterList]) {
    var parameters = parameterList?.parameters;
    var returnType = type.returnType;
    var parameterTypes = type.normalParameterTypes;
    var optionalTypes = type.optionalParameterTypes;
    var namedTypes = type.namedParameterTypes;
    var rt = _emitTypeName(returnType);
    var ra = _emitTypeNames(parameterTypes, parameters);
    if (!namedTypes.isEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes);
      return [rt, ra, na];
    }
    if (!optionalTypes.isEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(
          optionalTypes, parameters?.sublist(parameterTypes.length));
      return [rt, ra, oa];
    }
    return [rt, ra];
  }

  JS.Expression _emitFunctionRTTI(FunctionType type) {
    var parts = _emitFunctionTypeParts(type);
    return js.call('dart.definiteFunctionType(#)', [parts]);
  }

  /// Emits a Dart [type] into code.
  ///
  /// If [lowerTypedef] is set, a typedef will be expanded as if it were a
  /// function type. Similarly if [lowerGeneric] is set, the `List$()` form
  /// will be used instead of `List`. These flags are used when generating
  /// the definitions for typedefs and generic types, respectively.
  JS.Expression _emitTypeName(DartType type,
      {bool lowerTypedef: false, bool lowerGeneric: false}) {
    // The void and dynamic types are not defined in core.
    if (type.isVoid) {
      return js.call('dart.void');
    } else if (type.isDynamic) {
      return js.call('dart.dynamic');
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
    // For now, reify generic method parameters as dynamic
    bool _isGenericTypeParameter(DartType type) =>
        (type is TypeParameterType) &&
        !(type.element.enclosingElement is ClassElement ||
            type.element.enclosingElement is FunctionTypeAliasElement);

    if (_isGenericTypeParameter(type)) {
      return js.call('dart.dynamic');
    }

    if (type is TypeParameterType) {
      return new JS.Identifier(name);
    }

    if (type is ParameterizedType) {
      var args = type.typeArguments;
      var isCurrentClass =
          args.isNotEmpty && _loader.isCurrentElement(type.element);
      Iterable jsArgs = null;
      if (args
          .any((a) => a != types.dynamicType && !_isGenericTypeParameter(a))) {
        jsArgs = args.map(_emitTypeName);
      } else if (lowerGeneric || isCurrentClass) {
        // When creating a `new S<dynamic>` we try and use the raw form
        // `new S()`, but this does not work if we're inside the same class,
        // because `S` refers to the current S<T> we are generating.
        jsArgs = [];
      }
      if (jsArgs != null) {
        var genericName = _emitTopLevelName(element, suffix: '\$');
        return js.call('#(#)', [genericName, jsArgs]);
      }
    }

    return _emitTopLevelName(element);
  }

  JS.Expression _emitTopLevelName(Element e, {String suffix: ''}) {
    var libName = _libraryName(e.library);

    // Always qualify:
    // * mutable top-level fields
    // * elements from other libraries
    bool mutableTopLevel = e is TopLevelVariableElement &&
        !e.isConst &&
        !_isFinalJSDecl(e.computeNode());
    bool fromAnotherLibrary = e.library != currentLibrary;
    var nameExpr;
    if (fromAnotherLibrary) {
      nameExpr = _propertyName((_getJSExportName(e) ?? e.name) + suffix);
    } else {
      nameExpr = _propertyName(e.name + suffix);
    }
    if (mutableTopLevel || fromAnotherLibrary) {
      return new JS.PropertyAccess(libName, nameExpr);
    }

    var id = new JS.MaybeQualifiedId(libName, nameExpr);
    _qualifiedIds.add(new Tuple2(e, id));
    return id;
  }

  @override
  JS.Expression visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;
    if (node.operator.type == TokenType.EQ) return _emitSet(left, right);
    var op = node.operator.lexeme;
    assert(op.endsWith('='));
    op = op.substring(0, op.length - 1); // remove trailing '='
    return _emitOpAssign(left, right, op, node.staticElement, context: node);
  }

  JS.MetaLet _emitOpAssign(
      Expression left, Expression right, String op, MethodElement element,
      {Expression context}) {
    if (op == '??') {
      // Desugar `l ??= r` as ((x) => x == null ? l = r : x)(l)
      // Note that if `x` contains subexpressions, we need to ensure those
      // are also evaluated only once. This is similar to desguaring for
      // postfix expressions like `i++`.

      // Handle the left hand side, to ensure each of its subexpressions are
      // evaluated only once.
      var vars = <String, JS.Expression>{};
      var x = _bindLeftHandSide(vars, left, context: left);
      // Capture the result of evaluating the left hand side in a temp.
      var t = _bindValue(vars, 't', x, context: x);
      return new JS.MetaLet(vars, [
        js.call('# == null ? # : #', [_visit(t), _emitSet(x, right), _visit(t)])
      ]);
    }

    // Desugar `x += y` as `x = x + y`, ensuring that if `x` has subexpressions
    // (for example, x is IndexExpression) we evaluate those once.
    var vars = <String, JS.Expression>{};
    var lhs = _bindLeftHandSide(vars, left, context: context);
    var inc = AstBuilder.binaryExpression(lhs, op, right);
    inc.staticElement = element;
    inc.staticType = getStaticType(left);
    return new JS.MetaLet(vars, [_emitSet(lhs, inc)]);
  }

  JS.Expression _emitSet(Expression lhs, Expression rhs) {
    if (lhs is IndexExpression) {
      var target = _getTarget(lhs);
      if (_useNativeJsIndexer(target.staticType)) {
        return js
            .call('#[#] = #', [_visit(target), _visit(lhs.index), _visit(rhs)]);
      }
      return _emitSend(target, '[]=', [lhs.index, rhs]);
    }

    Expression target = null;
    SimpleIdentifier id;
    if (lhs is PropertyAccess) {
      if (lhs.operator.lexeme == '?.') {
        return _emitNullSafeSet(lhs, rhs);
      }

      target = _getTarget(lhs);
      id = lhs.propertyName;
    } else if (lhs is PrefixedIdentifier) {
      target = lhs.prefix;
      id = lhs.identifier;
    }

    if (target != null && DynamicInvoke.get(target)) {
      return js.call('dart.$DPUT(#, #, #)', [
        _visit(target),
        _emitMemberName(id.name, type: getStaticType(target)),
        _visit(rhs)
      ]);
    }

    return _visit(rhs).toAssignExpression(_visit(lhs));
  }

  JS.Expression _emitNullSafeSet(PropertyAccess node, Expression right) {
    // Emit `obj?.prop = expr` as:
    //
    //     (_ => _ == null ? null : _.prop = expr)(obj).
    //
    // We could use a helper, e.g.:  `nullSafeSet(e1, _ => _.v = e2)`
    //
    // However with MetaLet, we get clean code in statement or void context,
    // or when one of the expressions is stateless, which seems common.
    var vars = <String, JS.Expression>{};
    var left = _bindValue(vars, 'l', node.target);
    var body = js.call('# == null ? null : #',
        [_visit(left), _emitSet(_stripNullAwareOp(node, left), right)]);
    return new JS.MetaLet(vars, [body]);
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
    var stmts = _visitList(node.block.statements) as List<JS.Statement>;
    if (initArgs != null) stmts.insert(0, initArgs);
    return new JS.Block(stmts);
  }

  @override
  JS.Block visitBlock(Block node) =>
      new JS.Block(_visitList(node.statements) as List<JS.Statement>,
          isScope: true);

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.operator != null && node.operator.lexeme == '?.') {
      return _emitNullSafe(node);
    }

    var target = _getTarget(node);
    var result = _emitForeignJS(node);
    if (result != null) return result;

    String code;
    if (target == null || isLibraryPrefix(target)) {
      if (DynamicInvoke.get(node.methodName)) {
        code = 'dart.$DCALL(#, #)';
      } else {
        code = '#(#)';
      }
      return js
          .call(code, [_visit(node.methodName), _visit(node.argumentList)]);
    }

    var type = getStaticType(target);
    var name = node.methodName.name;
    var element = node.methodName.staticElement;
    bool isStatic = element is ExecutableElement && element.isStatic;
    var memberName = _emitMemberName(name, type: type, isStatic: isStatic);

    if (DynamicInvoke.get(target)) {
      code = 'dart.$DSEND(#, #, #)';
    } else if (DynamicInvoke.get(node.methodName)) {
      // This is a dynamic call to a statically known target. For example:
      //     class Foo { Function bar; }
      //     new Foo().bar(); // dynamic call
      code = 'dart.$DCALL(#.#, #)';
    } else if (_requiresStaticDispatch(target, name)) {
      // Object methods require a helper for null checks.
      return js.call('dart.#(#, #)',
          [memberName, _visit(target), _visit(node.argumentList)]);
    } else {
      code = '#.#(#)';
    }

    return js
        .call(code, [_visit(target), memberName, _visit(node.argumentList)]);
  }

  /// Emits code for the `JS(...)` builtin.
  _emitForeignJS(MethodInvocation node) {
    var e = node.methodName.staticElement;
    if (isInlineJS(e)) {
      var args = node.argumentList.arguments;
      // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
      var code = args[1];
      var templateArgs;
      var source;
      if (code is StringInterpolation) {
        if (args.length > 2) {
          throw new ArgumentError(
              "Can't mix template args and string interpolation in JS calls.");
        }
        templateArgs = <Expression>[];
        source = code.elements.map((element) {
          if (element is InterpolationExpression) {
            templateArgs.add(element.expression);
            return '#';
          } else {
            return (element as InterpolationString).value;
          }
        }).join();
      } else {
        templateArgs = args.skip(2);
        source = (code as StringLiteral).stringValue;
      }

      var template = js.parseForeignJS(source);
      var result = template.instantiate(_visitList(templateArgs));
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
    if (DynamicInvoke.get(node.function)) {
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
      } else if (arg is MethodInvocation && isJsSpreadInvocation(arg)) {
        args.add(
            new JS.RestParameter(_visit(arg.argumentList.arguments.single)));
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

  bool _isNamedParam(FormalParameter param) =>
      param.kind == ParameterKind.NAMED;

  @override
  List<JS.Parameter> visitFormalParameterList(FormalParameterList node) =>
      _emitFormalParameterList(node);

  List<JS.Parameter> _emitFormalParameterList(FormalParameterList node,
      {bool allowDestructuring: true}) {
    var result = <JS.Parameter>[];

    var namedVars = <JS.DestructuredVariable>[];
    var destructure = allowDestructuring && options.destructureNamedParams;
    var hasNamedArgsConflictingWithObjectProperties = false;
    var needsOpts = false;

    for (FormalParameter param in node.parameters) {
      if (param.kind == ParameterKind.NAMED) {
        if (destructure) {
          if (_jsObjectProperties.contains(param.identifier.name)) {
            hasNamedArgsConflictingWithObjectProperties = true;
          }
          JS.Expression name;
          JS.SimpleBindingPattern structure = null;
          String paramName = param.identifier.name;
          if (invalidVariableName(paramName)) {
            name = js.string(paramName);
            structure = new JS.SimpleBindingPattern(_visit(param.identifier));
          } else {
            name = _visit(param.identifier);
          }
          namedVars.add(new JS.DestructuredVariable(
              name: name,
              structure: structure,
              defaultValue: _defaultParamValue(param)));
        } else {
          needsOpts = true;
        }
      } else {
        var jsParam = _visit(param);
        result.add(
            param is DefaultFormalParameter && options.destructureNamedParams
                ? new JS.DestructuredVariable(
                    name: jsParam, defaultValue: _defaultParamValue(param))
                : jsParam);
      }
    }

    if (needsOpts) {
      result.add(_namedArgTemp);
    } else if (namedVars.isNotEmpty) {
      // Note: `var {valueOf} = {}` extracts `Object.prototype.valueOf`, so
      // in case there are conflicting names we create an object without
      // any prototype.
      var defaultOpts = hasNamedArgsConflictingWithObjectProperties
          ? js.call('Object.create(null)')
          : js.call('{}');
      result.add(new JS.DestructuredVariable(
          structure: new JS.ObjectBindingPattern(namedVars),
          type: emitNamedParamsArgType(node.parameterElements),
          defaultValue: defaultOpts));
    }
    return result;
  }

  /// See ES6 spec (and `Object.getOwnPropertyNames(Object.prototype)`):
  /// http://www.ecma-international.org/ecma-262/6.0/#sec-properties-of-the-object-prototype-object
  /// http://www.ecma-international.org/ecma-262/6.0/#sec-additional-properties-of-the-object.prototype-object
  static final Set<String> _jsObjectProperties = new Set<String>()
    ..addAll([
      "constructor",
      "toString",
      "toLocaleString",
      "valueOf",
      "hasOwnProperty",
      "isPrototypeOf",
      "propertyIsEnumerable",
      "__defineGetter__",
      "__lookupGetter__",
      "__defineSetter__",
      "__lookupSetter__",
      "__proto__"
    ]);

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
    return (_visit(e) as JS.Expression).toReturn();
  }

  @override
  JS.Statement visitYieldStatement(YieldStatement node) {
    JS.Expression jsExpr = _visit(node.expression);
    var star = node.star != null;
    if (_asyncStarController != null) {
      // async* yields are generated differently from sync* yields. `yield e`
      // becomes:
      //
      //     if (stream.add(e)) return;
      //     yield;
      //
      // `yield* e` becomes:
      //
      //     if (stream.addStream(e)) return;
      //     yield;
      var helperName = star ? 'addStream' : 'add';
      return js.statement('{ if(#.#(#)) return; #; }',
          [_asyncStarController, helperName, jsExpr, new JS.Yield(null)]);
    }
    // A normal yield in a sync*
    return jsExpr.toYieldStatement(star: star);
  }

  @override
  JS.Expression visitAwaitExpression(AwaitExpression node) {
    return new JS.Yield(_visit(node.expression));
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var v in node.variables.variables) {
      _loader.loadDeclaration(v, v.element);
    }
  }

  /// Emits static fields.
  ///
  /// Instance fields are emitted in [_initializeFields].
  ///
  /// These are generally treated the same as top-level fields, see
  /// [visitTopLevelVariableDeclaration].
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) return;

    for (var f in node.fields.variables) {
      _loader.loadDeclaration(f, f.element);
    }
  }

  _addExport(String name, [String exportName]) {
    if (_exports.containsKey(name)) {
      throw 'Duplicate top level name found: $name';
    }
    _exports[name] = exportName ?? name;
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
    return new JS.VariableDeclarationList(
        'let', _visitList(node.variables) as List<JS.VariableInitialization>);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.element is PropertyInducingElement) {
      // Static and instance fields are handled elsewhere.
      assert(node.element is TopLevelVariableElement);
      return _emitTopLevelField(node);
    }

    var name =
        new JS.Identifier(node.name.name, type: emitTypeRef(node.element.type));
    return new JS.VariableInitialization(name, _visitInitializer(node));
  }

  bool _isFinalJSDecl(AstNode field) =>
      field is VariableDeclaration &&
      field.isFinal &&
      _isJSInvocation(field.initializer);

  /// Try to emit a constant static field.
  ///
  /// If the field's initializer does not cause side effects, and if all of
  /// dependencies are safe to refer to while we are initializing the class,
  /// then we can initialize it eagerly:
  ///
  ///     // Baz must be const constructor, and the name "Baz" must be defined
  ///     // by this point.
  ///     Foo.bar = dart.const(new Baz(42));
  ///
  /// Otherwise, we'll need to generate a lazy-static field. That ensures
  /// correct visible behavior, as well as avoiding referencing something that
  /// isn't defined yet (because it is defined later in the module).
  JS.Statement _emitConstantStaticField(
      ClassElement classElem, VariableDeclaration field) {
    PropertyInducingElement element = field.element;
    assert(element.isStatic);

    _loader.startCheckingReferences();
    JS.Expression jsInit = _visitInitializer(field);
    bool isLoaded = _loader.finishCheckingReferences();

    bool eagerInit =
        isLoaded && (field.isConst || _constField.isFieldInitConstant(field));

    var fieldName = field.name.name;
    if (eagerInit && !JS.invalidStaticFieldName(fieldName)) {
      return annotate(
          js.statement('#.# = #;', [
            classElem.name,
            _emitMemberName(fieldName, isStatic: true),
            jsInit
          ]),
          field,
          field.element);
    }

    // This means it should be treated as a lazy field.
    // TODO(jmesserly): we're throwing away the initializer expression,
    // which will force us to regenerate it.
    return null;
  }

  /// Emits a top-level field.
  JS.Statement _emitTopLevelField(VariableDeclaration field) {
    TopLevelVariableElement element = field.element;
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
      // TODO(jmesserly): we're visiting the initializer here, and again
      // later on when we emit lazy fields. That seems busted.
      jsInit = _visitInitializer(field);
      eagerInit = false;
    }

    // Treat `final x = JS('', '...')` as a const (non-lazy) to help compile
    // runtime helpers.
    var isJSTopLevel = field.isFinal && _isFinalJSDecl(field);
    if (isJSTopLevel) eagerInit = true;

    var fieldName = field.name.name;
    var exportName = fieldName;
    if (element is TopLevelVariableElement) {
      exportName = _getJSExportName(element) ?? fieldName;
    }
    if ((field.isConst && eagerInit && element is TopLevelVariableElement) ||
        isJSTopLevel) {
      // constant fields don't change, so we can generate them as `let`
      // but add them to the module's exports. However, make sure we generate
      // anything they depend on first.

      if (isPublic(fieldName)) _addExport(fieldName, exportName);
      var declKeyword = field.isConst || field.isFinal ? 'const' : 'let';
      if (isJSTopLevel && jsInit is JS.ClassExpression) {
        return new JS.ClassDeclaration(jsInit);
      }
      return js.statement('#;', [
        annotate(
            new JS.VariableDeclarationList(declKeyword, [
              new JS.VariableInitialization(
                  new JS.Identifier(fieldName,
                      type: emitTypeRef(field.element.type)),
                  jsInit)
            ]),
            field,
            field.element)
      ]);
    }

    if (eagerInit && !JS.invalidStaticFieldName(fieldName)) {
      return annotate(js.statement('# = #;', [_visit(field.name), jsInit]),
          field, field.element);
    }

    return _emitLazyFields(currentLibrary, [field]);
  }

  JS.Expression _visitInitializer(VariableDeclaration node) {
    var value = _visit(node.initializer);
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    return value ?? new JS.LiteralNull();
  }

  JS.Statement _emitLazyFields(
      Element target, List<VariableDeclaration> fields) {
    var methods = [];
    for (var node in fields) {
      var name = node.name.name;
      var element = node.element;
      var access = _emitMemberName(name, isStatic: true);
      methods.add(annotate(
          new JS.Method(
              access,
              js.call('function() { return #; }', _visit(node.initializer))
              as JS.Fun,
              isGetter: true),
          node,
          _findAccessor(element, getter: true)));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!node.isFinal && !node.isConst) {
        methods.add(annotate(
            new JS.Method(access, js.call('function(_) {}') as JS.Fun,
                isSetter: true),
            node,
            _findAccessor(element, getter: false)));
      }
    }

    JS.Expression objExpr;
    if (target is ClassElement) {
      objExpr = new JS.Identifier(target.type.name);
    } else {
      objExpr = _libraryName(target);
    }

    return js
        .statement('dart.defineLazyProperties(#, { # });', [objExpr, methods]);
  }

  PropertyAccessorElement _findAccessor(VariableElement element,
      {bool getter}) {
    var parent = element.enclosingElement;
    if (parent is ClassElement) {
      return getter
          ? parent.getGetter(element.name)
          : parent.getSetter(element.name);
    }
    return null;
  }

  void _flushLibraryProperties(List<JS.Statement> body) {
    if (_properties.isEmpty) return;
    body.add(js.statement('dart.copyProperties(#, { # });',
        [_exportsVar, _properties.map(_emitTopLevelProperty)]));
    _properties.clear();
  }

  JS.Expression _emitConstructorName(
      ConstructorElement element, DartType type, SimpleIdentifier name) {
    var typeName = _emitTypeName(type);
    if (name != null || element.isFactory) {
      var namedCtor = _constructorName(element);
      return new JS.PropertyAccess(typeName, namedCtor);
    }
    return typeName;
  }

  @override
  visitConstructorName(ConstructorName node) {
    return _emitConstructorName(node.staticElement, node.type.type, node.name);
  }

  JS.Expression _emitInstanceCreationExpression(
      ConstructorElement element,
      DartType type,
      SimpleIdentifier name,
      ArgumentList argumentList,
      bool isConst) {
    JS.Expression emitNew() {
      JS.Expression ctor;
      bool isFactory = false;
      // var element = node.staticElement;
      if (element == null) {
        // TODO(jmesserly): this only happens if we had a static error.
        // Should we generate a throw instead?
        ctor = _emitTypeName(type);
        if (name != null) {
          ctor = new JS.PropertyAccess(ctor, _propertyName(name.name));
        }
      } else {
        ctor = _emitConstructorName(element, type, name);
        isFactory = element.isFactory;
      }
      var args = _visit(argumentList) as List<JS.Expression>;
      return isFactory ? new JS.Call(ctor, args) : new JS.New(ctor, args);
    }
    if (isConst) return _emitConst(emitNew);
    return emitNew();
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.staticElement;
    var constructor = node.constructorName;
    var name = constructor.name;
    var type = constructor.type.type;
    return _emitInstanceCreationExpression(
        element, type, name, node.argumentList, node.isConst);
  }

  /// True if this type is built-in to JS, and we use the values unwrapped.
  /// For these types we generate a calling convention via static
  /// "extension methods". This allows types to be extended without adding
  /// extensions directly on the prototype.
  bool _isJSBuiltinType(DartType t) =>
      typeIsPrimitiveInJS(t) || t == _types.stringType;

  bool typeIsPrimitiveInJS(DartType t) =>
      _isNumberInJS(t) || t == _types.boolType;

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) =>
      typeIsPrimitiveInJS(leftT) && typeIsPrimitiveInJS(rightT);

  bool unaryOperationIsPrimitive(DartType t) => typeIsPrimitiveInJS(t);

  JS.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visit(expr);
    if (!_isNullable(expr)) return jsExpr;
    return js.call('dart.notNull(#)', jsExpr);
  }

  @override
  JS.Expression visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    var left = node.leftOperand;
    var right = node.rightOperand;

    var leftType = getStaticType(left);
    var rightType = getStaticType(right);

    var code;
    if (op.type.isEqualityOperator) {
      // If we statically know LHS or RHS is null we can generate a clean check.
      // We can also do this if both sides are the same primitive type.
      if (_canUsePrimitiveEquality(left, right)) {
        code = op.type == TokenType.EQ_EQ ? '# == #' : '# != #';
      } else if (left is SuperExpression) {
        return _emitSend(left, op.lexeme, [right]);
      } else {
        var bang = op.type == TokenType.BANG_EQ ? '!' : '';
        code = '${bang}dart.equals(#, #)';
      }
      return js.call(code, [_visit(left), _visit(right)]);
    }

    if (op.type.lexeme == '??') {
      // TODO(jmesserly): leave RHS for debugging?
      // This should be a hint or warning for dead code.
      if (!_isNullable(left)) return _visit(left);

      var vars = <String, JS.Expression>{};
      // Desugar `l ?? r` as `l != null ? l : r`
      var l = _visit(_bindValue(vars, 'l', left, context: left));
      return new JS.MetaLet(vars, [
        js.call('# != null ? # : #', [l, l, _visit(right)])
      ]);
    }

    if (binaryOperationIsPrimitive(leftType, rightType) ||
        leftType == _types.stringType && op.type == TokenType.PLUS) {
      // special cases where we inline the operation
      // these values are assumed to be non-null (determined by the checker)
      // TODO(jmesserly): it would be nice to just inline the method from core,
      // instead of special cases here.
      if (op.type == TokenType.TILDE_SLASH) {
        // `a ~/ b` is equivalent to `(a / b).truncate()`
        var div = AstBuilder.binaryExpression(left, '/', right)
          ..staticType = node.staticType;
        return _emitSend(div, 'truncate', []);
      } else {
        // TODO(vsm): When do Dart ops not map to JS?
        code = '# $op #';
      }
      return js.call(code, [notNull(left), notNull(right)]);
    }

    return _emitSend(left, op.lexeme, [right]);
  }

  /// If the type [t] is [int] or [double], or a type parameter
  /// bounded by [int], [double] or [num] returns [num].
  /// Otherwise returns [t].
  DartType _canonicalizeNumTypes(DartType t) {
    var numType = types.numType;
    if (rules.isSubtypeOf(t, numType)) return numType;
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
    DynamicInvoke.set(id, type.isDynamic);
    return id;
  }

  JS.Expression _emitConst(JS.Expression expr()) {
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
      Map<String, JS.Expression> scope, Expression expr,
      {Expression context}) {
    Expression result;
    if (expr is IndexExpression) {
      IndexExpression index = expr;
      result = new IndexExpression.forTarget(
          _bindValue(scope, 'o', index.target, context: context),
          index.leftBracket,
          _bindValue(scope, 'i', index.index, context: context),
          index.rightBracket);
    } else if (expr is PropertyAccess) {
      PropertyAccess prop = expr;
      result = new PropertyAccess(
          _bindValue(scope, 'o', _getTarget(prop), context: context),
          prop.operator,
          prop.propertyName);
    } else if (expr is PrefixedIdentifier) {
      PrefixedIdentifier ident = expr;
      if (isLibraryPrefix(ident.prefix)) {
        return expr;
      }
      result = new PrefixedIdentifier(
          _bindValue(scope, 'o', ident.prefix, context: context)
          as SimpleIdentifier,
          ident.period,
          ident.identifier);
    } else {
      return expr as SimpleIdentifier;
    }
    result.staticType = expr.staticType;
    DynamicInvoke.set(result, DynamicInvoke.get(expr));
    return result;
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

    var t = _createTemporary('#$name', getStaticType(expr));
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
      if (!_isNullable(expr)) {
        return js.call('#$op', _visit(expr));
      }
    }

    assert(op.lexeme == '++' || op.lexeme == '--');

    // Handle the left hand side, to ensure each of its subexpressions are
    // evaluated only once.
    var vars = <String, JS.Expression>{};
    var left = _bindLeftHandSide(vars, expr, context: expr);

    // Desugar `x++` as `(x1 = x0 + 1, x0)` where `x0` is the original value
    // and `x1` is the new value for `x`.
    var x = _bindValue(vars, 'x', left, context: expr);

    var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
    var increment = AstBuilder.binaryExpression(x, op.lexeme[0], one)
      ..staticElement = node.staticElement
      ..staticType = getStaticType(expr);

    var body = <JS.Expression>[_emitSet(left, increment), _visit(x)];
    return new JS.MetaLet(vars, body, statelessResult: true);
  }

  @override
  JS.Expression visitPrefixExpression(PrefixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      if (!_isNullable(expr)) {
        return js.call('$op#', _visit(expr));
      } else if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var vars = <String, JS.Expression>{};
        var x = _bindLeftHandSide(vars, expr, context: expr);

        var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
        var increment = AstBuilder.binaryExpression(x, op.lexeme[0], one)
          ..staticElement = node.staticElement
          ..staticType = getStaticType(expr);

        return new JS.MetaLet(vars, [_emitSet(x, increment)]);
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

    var vars = <String, JS.Expression>{};
    _cascadeTarget = _bindValue(vars, '_', node.target, context: node);
    var sections = _visitList(node.cascadeSections) as List<JS.Expression>;
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
  visitFormalParameter(FormalParameter node) => _emitFormalParameter(node);

  _emitFormalParameter(FormalParameter node, {bool allowType: true}) {
    var id = _emitSimpleIdentifier(node.identifier, allowType: allowType);

    var isRestArg = findAnnotation(node.element, isJsRestAnnotation) != null;
    return isRestArg ? new JS.RestParameter(id) : id;
  }

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
  visitPropertyAccess(PropertyAccess node) {
    if (node.operator.lexeme == '?.') {
      return _emitNullSafe(node);
    }
    return _emitGet(_getTarget(node), node.propertyName);
  }

  JS.Expression _emitNullSafe(Expression node) {
    // Desugar ?. sequence by passing a sequence of callbacks that applies
    // each operation in sequence:
    //
    //     obj?.foo()?.bar
    // -->
    //     nullSafe(obj, _ => _.foo(), _ => _.bar);
    //
    // This pattern has the benefit of preserving order, as well as minimizing
    // code expansion: each `?.` becomes `, _ => _`, plus one helper call.
    //
    // TODO(jmesserly): we could desugar with MetaLet instead, which may
    // lead to higher performing code, but at the cost of readability.
    var tail = <JS.Expression>[];
    for (;;) {
      var op = _getOperator(node);
      if (op != null && op.lexeme == '?.') {
        var nodeTarget = _getTarget(node);
        if (!_isNullable(nodeTarget)) {
          node = _stripNullAwareOp(node, nodeTarget);
          break;
        }

        var param = _createTemporary('_', nodeTarget.staticType);
        var baseNode = _stripNullAwareOp(node, param);
        tail.add(new JS.ArrowFun([_visit(param)], _visit(baseNode)));
        node = nodeTarget;
      } else {
        break;
      }
    }
    if (tail.isEmpty) return _visit(node);
    return js.call('dart.nullSafe(#, #)', [_visit(node), tail.reversed]);
  }

  static Token _getOperator(Expression node) {
    if (node is PropertyAccess) return node.operator;
    if (node is MethodInvocation) return node.operator;
    return null;
  }

  // TODO(jmesserly): this is dropping source location.
  Expression _stripNullAwareOp(Expression node, Expression newTarget) {
    if (node is PropertyAccess) {
      return AstBuilder.propertyAccess(newTarget, node.propertyName);
    } else {
      var invoke = node as MethodInvocation;
      return AstBuilder.methodInvoke(
          newTarget, invoke.methodName, invoke.argumentList.arguments);
    }
  }

  bool _requiresStaticDispatch(Expression target, String memberName) {
    var type = getStaticType(target);
    if (!_isObjectProperty(memberName)) {
      return false;
    }
    if (!type.isObject &&
        !_isJSBuiltinType(type) &&
        !_extensionTypes.contains(type.element) &&
        !_isNullable(target)) {
      return false;
    }
    return true;
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  JS.Expression _emitGet(Expression target, SimpleIdentifier memberId) {
    var member = memberId.staticElement;
    if (member is PropertyAccessorElement) {
      member = (member as PropertyAccessorElement).variable;
    }
    bool isStatic = member is ClassMemberElement && member.isStatic;
    var name = _emitMemberName(memberId.name,
        type: getStaticType(target), isStatic: isStatic);
    if (DynamicInvoke.get(target)) {
      return js.call('dart.$DLOAD(#, #)', [_visit(target), name]);
    }

    String code;
    if (member != null && member is MethodElement && !isStatic) {
      // Tear-off methods: explicitly bind it.
      if (target is SuperExpression) {
        return js.call('dart.bind(this, #, #.#)', [name, _visit(target), name]);
      } else if (_requiresStaticDispatch(target, memberId.name)) {
        var type = member.type;
        var clos = js.call('dart.#.bind(#)', [name, _visit(target)]);
        return js.call('dart.fn(#, #)', [clos, _emitFunctionTypeParts(type)]);
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
    if (DynamicInvoke.get(target)) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': DINDEX, '[]=': DSETINDEX}[name];
      if (dynamicHelper != null) {
        return js.call(
            'dart.$dynamicHelper(#, #)', [_visit(target), _visitList(args)]);
      }
      return js.call('dart.$DSEND(#, #, #)',
          [_visit(target), memberName, _visitList(args)]);
    }

    // Generic dispatch to a statically known method.
    return js.call('#.#(#)', [_visit(target), memberName, _visitList(args)]);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    var target = _getTarget(node);
    if (_useNativeJsIndexer(target.staticType)) {
      return new JS.PropertyAccess(_visit(target), _visit(node.index));
    }
    return _emitSend(target, '[]', [node.index]);
  }

  // TODO(jmesserly): ideally we'd check the method and see if it is marked
  // `external`, but that doesn't work because it isn't in the element model.
  bool _useNativeJsIndexer(DartType type) =>
      findAnnotation(type.element, isJSAnnotation) != null;

  /// Gets the target of a [PropertyAccess], [IndexExpression], or
  /// [MethodInvocation]. These three nodes can appear in a [CascadeExpression].
  Expression _getTarget(node) {
    assert(node is IndexExpression ||
        node is PropertyAccess ||
        node is MethodInvocation);
    return node.isCascaded ? _cascadeTarget : node.target;
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      notNull(node.condition),
      _visit(node.thenExpression),
      _visit(node.elseExpression)
    ]);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    var expr = _visit(node.expression);
    if (node.parent is ExpressionStatement) {
      return js.statement('dart.throw(#);', expr);
    } else {
      return js.call('dart.throw(#)', expr);
    }
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    if (node.parent is ExpressionStatement) {
      return js.statement('throw #;', _visit(_catchParameter));
    } else {
      return js.call('throw #', _visit(_catchParameter));
    }
  }

  /// Visits a statement, and ensures the resulting AST handles block scope
  /// correctly. Essentially, we need to promote a variable declaration
  /// statement into a block in some cases, e.g.
  ///
  ///     do var x = 5; while (false); // Dart
  ///     do { let x = 5; } while (false); // JS
  JS.Statement _visitScope(Statement stmt) {
    var result = _visit(stmt);
    if (result is JS.ExpressionStatement &&
        result.expression is JS.VariableDeclarationList) {
      return new JS.Block([result]);
    }
    return result;
  }

  @override
  JS.If visitIfStatement(IfStatement node) {
    return new JS.If(notNull(node.condition), _visitScope(node.thenStatement),
        _visitScope(node.elseStatement));
  }

  @override
  JS.For visitForStatement(ForStatement node) {
    var init = _visit(node.initialization);
    if (init == null) init = _visit(node.variables);
    var update = _visitListToBinary(node.updaters, ',');
    if (update != null) update = update.toVoidExpression();
    return new JS.For(
        init, notNull(node.condition), update, _visitScope(node.body));
  }

  @override
  JS.While visitWhileStatement(WhileStatement node) {
    return new JS.While(notNull(node.condition), _visitScope(node.body));
  }

  @override
  JS.Do visitDoStatement(DoStatement node) {
    return new JS.Do(_visitScope(node.body), notNull(node.condition));
  }

  @override
  JS.Statement visitForEachStatement(ForEachStatement node) {
    if (node.awaitKeyword != null) {
      return _emitAwaitFor(node);
    }

    var init = _visit(node.identifier);
    if (init == null) {
      init = js.call('let #', node.loopVariable.identifier.name);
    }
    return new JS.ForOf(init, _visit(node.iterable), _visitScope(node.body));
  }

  JS.Statement _emitAwaitFor(ForEachStatement node) {
    // Emits `await for (var value in stream) ...`, which desugars as:
    //
    // var iter = new StreamIterator<T>(stream);
    // try {
    //   while (await iter.moveNext()) {
    //     var value = iter.current;
    //     ...
    //   }
    // } finally {
    //   await iter.cancel();
    // }
    //
    // Like the Dart VM, we call cancel() always, as it's safe to call if the
    // stream has already been cancelled.
    //
    // TODO(jmesserly): we may want a helper if these become common. For now the
    // full desugaring seems okay.
    var context = compiler.context;
    var dart_async = context
        .computeLibraryElement(context.sourceFactory.forUri('dart:async'));
    var T = node.loopVariable.element.type;
    var StreamIterator_T =
        dart_async.getType('StreamIterator').type.substitute4([T]);

    var createStreamIter = _emitInstanceCreationExpression(
        StreamIterator_T.element.unnamedConstructor,
        StreamIterator_T,
        null,
        AstBuilder.argumentList([node.iterable]),
        false);
    var iter = _visit(_createTemporary('it', StreamIterator_T));

    var init = _visit(node.identifier);
    if (init == null) {
      init = js
          .call('let # = #.current', [node.loopVariable.identifier.name, iter]);
    } else {
      init = js.call('# = #.current', [init, iter]);
    }
    return js.statement(
        '{'
        '  let # = #;'
        '  try {'
        '    while (#) { #; #; }'
        '  } finally { #; }'
        '}',
        [
          iter,
          createStreamIter,
          new JS.Yield(js.call('#.moveNext()', iter)),
          init,
          _visit(node.body),
          new JS.Yield(js.call('#.cancel()', iter))
        ]);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    var label = node.label;
    return new JS.Break(label?.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    var label = node.label;
    return new JS.Continue(label?.name);
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
    return new JS.If(
        js.call('dart.is(#, #)', [
          _visit(_catchParameter),
          _emitTypeName(clause.exceptionType.type),
        ]),
        then,
        otherwise);
  }

  JS.Statement _statement(List<JS.Statement> statements) {
    // TODO(jmesserly): empty block singleton?
    if (statements.length == 0) return new JS.Block([]);
    if (statements.length == 1) return statements[0];
    return new JS.Block(statements);
  }

  /// Visits the catch clause body. This skips the exception type guard, if any.
  /// That is handled in [_visitCatch].
  @override
  JS.Statement visitCatchClause(CatchClause node) {
    var body = <JS.Statement>[];

    var savedCatch = _catchParameter;
    if (node.catchKeyword != null) {
      var name = node.exceptionParameter;
      if (name != null && name != _catchParameter) {
        body.add(js
            .statement('let # = #;', [_visit(name), _visit(_catchParameter)]));
        _catchParameter = name;
      }
      if (node.stackTraceParameter != null) {
        var stackVar = node.stackTraceParameter.name;
        body.add(js.statement(
            'let # = dart.stackTrace(#);', [stackVar, _visit(name)]));
      }
    }

    body.add(
        new JS.Block(_visitList(node.body.statements) as List<JS.Statement>));
    _catchParameter = savedCatch;
    return _statement(body);
  }

  @override
  JS.Case visitSwitchCase(SwitchCase node) {
    var expr = _visit(node.expression);
    var body = _visitList(node.statements) as List<JS.Statement>;
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return new JS.Case(expr, new JS.Block(body));
  }

  @override
  JS.Default visitSwitchDefault(SwitchDefault node) {
    var body = _visitList(node.statements) as List<JS.Statement>;
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return new JS.Default(new JS.Block(body));
  }

  @override
  JS.Switch visitSwitchStatement(SwitchStatement node) => new JS.Switch(
      _visit(node.expression),
      _visitList(node.members) as List<JS.SwitchClause>);

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
    JS.New emitSymbol() {
      // TODO(vsm): When we canonicalize, we need to treat private symbols
      // correctly.
      var name = js.string(node.components.join('.'), "'");
      return new JS.New(_emitTypeName(types.symbolType), [name]);
    }
    return _emitConst(emitSymbol);
  }

  @override
  visitListLiteral(ListLiteral node) {
    JS.Expression emitList() {
      JS.Expression list = new JS.ArrayInitializer(
          _visitList(node.elements) as List<JS.Expression>);
      ParameterizedType type = node.staticType;
      var elementType = type.typeArguments.single;
      if (elementType != types.dynamicType) {
        // dart.list helper internally depends on _interceptors.JSArray.
        _loader.declareBeforeUse(_jsArray);
        list = js.call('dart.list(#, #)', [list, _emitTypeName(elementType)]);
      }
      return list;
    }
    if (node.constKeyword != null) return _emitConst(emitList);
    return emitList();
  }

  @override
  visitMapLiteral(MapLiteral node) {
    // TODO(jmesserly): we can likely make these faster.
    JS.Expression emitMap() {
      var entries = node.entries;
      var mapArguments = null;
      var typeArgs = node.typeArguments;
      if (entries.isEmpty && typeArgs == null) {
        mapArguments = [];
      } else if (entries.every((e) => e.key is StringLiteral)) {
        // Use JS object literal notation if possible, otherwise use an array.
        // We could do this any time all keys are non-nullable String type.
        // For now, support StringLiteral as the common non-nullable String case.
        var props = <JS.Property>[];
        for (var e in entries) {
          props.add(new JS.Property(_visit(e.key), _visit(e.value)));
        }
        mapArguments = new JS.ObjectInitializer(props);
      } else {
        var values = <JS.Expression>[];
        for (var e in entries) {
          values.add(_visit(e.key));
          values.add(_visit(e.value));
        }
        mapArguments = new JS.ArrayInitializer(values);
      }
      var types = <JS.Expression>[];
      if (typeArgs != null) {
        types.addAll(typeArgs.arguments.map((e) => _emitTypeName(e.type)));
      }
      return js.call('dart.map(#, #)', [mapArguments, types]);
    }
    if (node.constKeyword != null) return _emitConst(emitMap);
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

  JS.Expression _unimplementedCall(String comment) {
    return js.call('dart.throw(#)', [js.escapedString(comment)]);
  }

  @override
  visitNode(AstNode node) {
    // TODO(jmesserly): verify this is unreachable.
    throw 'Unimplemented ${node.runtimeType}: $node';
  }

  _visit(AstNode node) {
    if (node == null) return null;
    var result = node.accept(this);
    if (result is JS.Node) result = annotate(result, node);
    return result;
  }

  // TODO(jmesserly): this will need to be a generic method, if we ever want to
  // self-host strong mode.
  List /*<T>*/ _visitList /*<T>*/ (Iterable<AstNode> nodes) {
    if (nodes == null) return null;
    var result = /*<T>*/ [];
    for (var node in nodes) result.add(_visit(node));
    return result;
  }

  /// Visits a list of expressions, creating a comma expression if needed in JS.
  JS.Expression _visitListToBinary(List<Expression> nodes, String operator) {
    if (nodes == null || nodes.isEmpty) return null;
    return new JS.Expression.binary(
        _visitList(nodes) as List<JS.Expression>, operator);
  }

  /// Return the bound type parameters for a ParameterizedType
  List<TypeParameterElement> _typeFormalsOf(ParameterizedType type) {
    return type is FunctionType ? type.typeFormals : type.typeParameters;
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  JS.Expression _elementMemberName(ExecutableElement e,
      {bool allowExtensions: true}) {
    String name;
    if (e is PropertyAccessorElement) {
      name = e.variable.name;
    } else {
      name = e.name;
    }
    return _emitMemberName(name,
        type: (e.enclosingElement as ClassElement).type,
        unary: e.parameters.isEmpty,
        isStatic: e.isStatic,
        allowExtensions: allowExtensions);
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
  ///     <, >, <=, >=, ==, -, +, /, ~/, *, %, |, ^, &, <<, >>, []=, [], ~
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
      {DartType type,
      bool unary: false,
      bool isStatic: false,
      bool allowExtensions: true}) {
    // Static members skip the rename steps.
    if (isStatic) return _propertyName(name);

    if (name.startsWith('_')) {
      return _privateNames.putIfAbsent(
          name, () => _initSymbol(new JS.TemporaryId(name)) as JS.TemporaryId);
    }

    if (name == '[]') {
      name = 'get';
    } else if (name == '[]=') {
      name = 'set';
    } else if (name == '-' && unary) {
      name = 'unary-';
    } else if (name == 'constructor' || name == 'prototype') {
      // This uses an illegal (in Dart) character for a member, avoiding the
      // conflict. We could use practically any character for this.
      name = '+$name';
    }

    // Dart "extension" methods. Used for JS Array, Boolean, Number, String.
    var baseType = type;
    while (baseType is TypeParameterType) {
      baseType = baseType.element.bound;
    }
    if (allowExtensions &&
        _extensionTypes.contains(baseType.element) &&
        !_isObjectProperty(name)) {
      return js.call('dartx.#', _propertyName(name));
    }

    return _propertyName(name);
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
    if (library.name == 'dart._runtime') return _runtimeLibVar;
    return _imports.putIfAbsent(
        library, () => new JS.TemporaryId(jsLibraryName(library)));
  }

  DartType getStaticType(Expression e) =>
      e.staticType ?? DynamicTypeImpl.instance;

  JS.Node annotate(JS.Node node, AstNode original, [Element element]) {
    if (options.closure && element != null) {
      node = node.withClosureAnnotation(
          closureAnnotationFor(node, original, element, _namedArgTemp.name));
    }
    return node..sourceInformation = original;
  }

  /// Returns true if this is any kind of object represented by `Number` in JS.
  ///
  /// In practice, this is 4 types: num, int, double, and JSNumber.
  ///
  /// JSNumber is the type that actually "implements" all numbers, hence it's
  /// a subtype of int and double (and num). It's in our "dart:_interceptors".
  bool _isNumberInJS(DartType t) => rules.isSubtypeOf(t, _types.numType);

  bool _isObjectGetter(String name) {
    PropertyAccessorElement element = _types.objectType.element.getGetter(name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectMethod(String name) {
    MethodElement element = _types.objectType.element.getMethod(name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectProperty(String name) {
    return _isObjectGetter(name) || _isObjectMethod(name);
  }

  // TODO(leafp): Various analyzer pieces computed similar things.
  // Share this logic somewhere?
  DartType _getExpectedReturnType(FunctionBody body) {
    FunctionType functionType;
    var parent = body.parent;
    if (parent is Declaration) {
      functionType = (parent.element as dynamic)?.type;
    } else {
      assert(parent is FunctionExpression);
      functionType = parent.staticType;
    }
    if (functionType == null) {
      return DynamicTypeImpl.instance;
    }
    var type = functionType.returnType;

    InterfaceType expectedType = null;
    if (body.isAsynchronous) {
      if (body.isGenerator) {
        // Stream<T> -> T
        expectedType = _types.streamType;
      } else {
        // Future<T> -> T
        // TODO(vsm): Revisit with issue #228.
        expectedType = _types.futureType;
      }
    } else {
      if (body.isGenerator) {
        // Iterable<T> -> T
        expectedType = _types.iterableType;
      } else {
        // T -> T
        return type;
      }
    }
    if (type.isDynamic) {
      return type;
    } else if (type is InterfaceType && type.element == expectedType.element) {
      return type.typeArguments[0];
    } else {
      // TODO(leafp): The above only handles the case where the return type
      // is exactly Future/Stream/Iterable.  Handle the subtype case.
      return DynamicTypeImpl.instance;
    }
  }
}

class _ExtensionFinder extends GeneralizingElementVisitor {
  final AnalysisContext _context;
  final HashSet<ClassElement> _extensionTypes;
  final TypeProvider _types;

  _ExtensionFinder(this._context, this._extensionTypes, this._types);

  visitClassElement(ClassElement element) {
    if (findAnnotation(element, isJsPeerInterface) != null ||
        findAnnotation(element, isNativeAnnotation) != null) {
      _addExtensionType(element.type);
    }
  }

  void _addExtensionType(InterfaceType t) {
    if (t.isObject || !_extensionTypes.add(t.element)) return;
    t = fillDynamicTypeArgs(t, _types) as InterfaceType;
    t.interfaces.forEach(_addExtensionType);
    t.mixins.forEach(_addExtensionType);
    _addExtensionType(t.superclass);
  }

  void _addExtensionTypes(String libraryUri) {
    var sourceFactory = _context.sourceFactory.forUri(libraryUri);
    var library = _context.computeLibraryElement(sourceFactory);
    visitLibraryElement(library);
  }
}

class JSGenerator extends CodeGenerator {
  final _extensionTypes = new HashSet<ClassElement>();
  final TypeProvider _types;

  JSGenerator(AbstractCompiler compiler)
      : _types = compiler.context.typeProvider,
        super(compiler) {
    // TODO(vsm): Eventually, we want to make this extensible - i.e., find
    // annotations in user code as well.  It would need to be summarized in
    // the element model - not searched this way on every compile.
    var finder = new _ExtensionFinder(context, _extensionTypes, _types);
    finder._addExtensionTypes('dart:_interceptors');
    finder._addExtensionTypes('dart:_native_typed_data');

    // TODO(vsm): If we're analyzing against the main SDK, those
    // types are not explicitly annotated.
    finder._addExtensionType(_types.intType);
    finder._addExtensionType(_types.doubleType);
    finder._addExtensionType(_types.boolType);
    finder._addExtensionType(_types.stringType);
  }

  String generateLibrary(LibraryUnit unit) {
    // Clone the AST first, so we can mutate it.
    unit = unit.clone();
    var library = unit.library.element.library;
    var fields = findFieldsNeedingStorage(unit, _extensionTypes);
    var rules = new StrongTypeSystemImpl();
    var codegen =
        new JSCodegenVisitor(compiler, rules, library, _extensionTypes, fields);
    var module = codegen.emitLibrary(unit);
    var out = compiler.getOutputPath(library.source.uri);
    var flags = compiler.options;
    var serverUri = flags.serverMode
        ? Uri.parse('http://${flags.host}:${flags.port}/')
        : null;
    return writeJsLibrary(module, out, compiler.inputBaseDir, serverUri,
        emitSourceMaps: options.emitSourceMaps,
        fileSystem: compiler.fileSystem);
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
