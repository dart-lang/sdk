// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show max, min;

import 'package:front_end/src/api_unstable/ddc.dart' show TypeSchemaEnvironment;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:source_span/source_span.dart' show SourceLocation;

import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../compiler/module_builder.dart' show pathToJSIdentifier;
import '../compiler/shared_command.dart' show SharedCompilerOptions;
import '../compiler/shared_compiler.dart';
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show NodeEnd, NodeSpan, HoverComment;
import 'constants.dart';
import 'js_interop.dart';
import 'js_typerep.dart';
import 'kernel_helpers.dart';
import 'native_types.dart';
import 'nullable_inference.dart';
import 'property_model.dart';
import 'type_table.dart';

class ProgramCompiler extends Object
    with SharedCompiler<Library, Class>
    implements
        StatementVisitor<JS.Statement>,
        ExpressionVisitor<JS.Expression>,
        DartTypeVisitor<JS.Expression>,
        ConstantVisitor<JS.Expression> {
  final SharedCompilerOptions options;

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  ///
  /// We sometimes special case codegen for a single library, as it simplifies
  /// name scoping requirements.
  final _libraries = Map<Library, JS.Identifier>.identity();

  /// Maps a library URI import, that is not in [_libraries], to the
  /// corresponding Kernel summary module we imported it with.
  final _importToSummary = Map<Library, Component>.identity();

  /// Maps a summary to the JS import name for the module.
  final _summaryToModule = Map<Component, String>.identity();

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = Map<Library, JS.TemporaryId>();

  /// The variable for the current catch clause
  VariableDeclaration _rethrowParameter;

  /// In an async* function, this represents the stream controller parameter.
  JS.TemporaryId _asyncStarController;

  JS.Identifier _extensionSymbolsModule;
  final _extensionSymbols = Map<String, JS.TemporaryId>();

  Set<Class> _pendingClasses;

  /// Temporary variables mapped to their corresponding JavaScript variable.
  final _tempVariables = <VariableDeclaration, JS.TemporaryId>{};

  /// Let variables collected for the given function.
  List<JS.TemporaryId> _letVariables;

  /// The class that is emitting its base class or mixin references, otherwise
  /// null.
  ///
  /// This is not used when inside the class method bodies, or for other type
  /// information such as `implements`.
  Class _classEmittingExtends;

  /// The class that is emitting its signature information, otherwise null.
  Class _classEmittingSignatures;

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentClass == _classEmittingTopLevel
  ///
  Class _currentClass;

  /// The current source file URI for emitting in the source map.
  Uri _currentUri;

  Component _component;

  Library _currentLibrary;

  FunctionNode _currentFunction;

  List<TypeParameter> _typeParamInConst;

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  /// Table of named and possibly hoisted types.
  TypeTable _typeTable;

  /// The global extension type table.
  // TODO(jmesserly): rename to `_nativeTypes`
  final NativeTypeSet _extensionTypes;

  final CoreTypes coreTypes;

  final TypeEnvironment types;

  final ClassHierarchy hierarchy;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  final virtualFields = VirtualFieldModel();

  final JSTypeRep _typeRep;

  bool _superAllowed = true;

  final _superHelpers = Map<String, JS.Method>();

  // Compilation of Kernel's [BreakStatement].
  //
  // Kernel represents Dart's `break` and `continue` uniformly as
  // [BreakStatement], by representing a loop continue as a break from the
  // loop's body.  [BreakStatement] always targets an enclosing
  // [LabeledStatement] statement directly without naming it.  (Continue to
  // a labeled switch case is not represented by a [BreakStatement].)
  //
  // We prefer to compile to `continue` where possible and to avoid labeling
  // statements where it is not necessary.  We maintain some state to track
  // which statements can be targets of break or continue without a label, which
  // statements must be labeled to be targets, and the labels that have been
  // assigned.

  /// A list of statements that can be the target of break without a label.
  ///
  /// A [BreakStatement] targeting any [LabeledStatement] in this list can be
  /// compiled to a break without a label.  All the statements in the list have
  /// the same effective target which must compile to something that can be
  /// targeted by break in JS.  This list and [_currentContinueTargets] are
  /// disjoint.
  List<LabeledStatement> _currentBreakTargets = [];

  /// A list of statements that can be the target of a continue without a label.
  ///
  /// A [BreakStatement] targeting any [LabeledStatement] in this list can be
  /// compiled to a continue without a label.  All the statements in this list
  /// have the same effective target which must compile to something that can be
  /// targeted by continue in JS.  This list and [_currentBreakTargets] are
  /// disjoint.
  List<LabeledStatement> _currentContinueTargets = [];

  /// A map from labeled statements to their 'effective targets'.
  ///
  /// The effective target of a labeled loop body is the enclosing loop.  A
  /// [BreakStatement] targeting this statement can be compiled to `continue`
  /// either with or without a label.  The effective target of a labeled
  /// statement that is not a loop body is the outermost non-labeled statement
  /// that it encloses.  A [BreakStatement] targeting this statement can be
  /// compiled to `break` either with or without a label.
  final _effectiveTargets = HashMap<LabeledStatement, Statement>.identity();

  /// A map from effective targets to their label names.
  ///
  /// If the target needs to be labeled when compiled to JS, because it was
  /// targeted by a break or continue with a label, then this map contains the
  /// label name that was assigned to it.
  final _labelNames = HashMap<Statement, String>.identity();

  final Class _jsArrayClass;
  final Class privateSymbolClass;
  final Class linkedHashMapImplClass;
  final Class identityHashMapImplClass;
  final Class linkedHashSetClass;
  final Class linkedHashSetImplClass;
  final Class identityHashSetImplClass;
  final Class syncIterableClass;
  final Class asyncStarImplClass;

  /// The dart:async `StreamIterator<T>` type.
  final Class _asyncStreamIteratorClass;

  final DevCompilerConstants _constants;

  final NullableInference _nullableInference;

  factory ProgramCompiler(Component component, ClassHierarchy hierarchy,
      SharedCompilerOptions options, Map<String, String> declaredVariables) {
    var coreTypes = CoreTypes(component);
    var types = TypeSchemaEnvironment(coreTypes, hierarchy);
    var constants = DevCompilerConstants(types, declaredVariables);
    var nativeTypes = NativeTypeSet(coreTypes, constants);
    var jsTypeRep = JSTypeRep(types, hierarchy);
    return ProgramCompiler._(coreTypes, coreTypes.index, nativeTypes, constants,
        types, hierarchy, jsTypeRep, NullableInference(jsTypeRep), options);
  }

  ProgramCompiler._(
      this.coreTypes,
      LibraryIndex sdk,
      this._extensionTypes,
      this._constants,
      this.types,
      this.hierarchy,
      this._typeRep,
      this._nullableInference,
      this.options)
      : _jsArrayClass = sdk.getClass('dart:_interceptors', 'JSArray'),
        _asyncStreamIteratorClass =
            sdk.getClass('dart:async', 'StreamIterator'),
        privateSymbolClass = sdk.getClass('dart:_js_helper', 'PrivateSymbol'),
        linkedHashMapImplClass = sdk.getClass('dart:_js_helper', 'LinkedMap'),
        identityHashMapImplClass =
            sdk.getClass('dart:_js_helper', 'IdentityMap'),
        linkedHashSetClass = sdk.getClass('dart:collection', 'LinkedHashSet'),
        linkedHashSetImplClass = sdk.getClass('dart:collection', '_HashSet'),
        identityHashSetImplClass =
            sdk.getClass('dart:collection', '_IdentityHashSet'),
        syncIterableClass = sdk.getClass('dart:_js_helper', 'SyncIterable'),
        asyncStarImplClass = sdk.getClass('dart:async', '_AsyncStarImpl');

  Uri get currentLibraryUri => _currentLibrary.importUri;

  bool get emitMetadata => options.emitMetadata;

  JS.Program emitModule(Component component, List<Component> summaries,
      List<Uri> summaryUris, Map<Uri, String> moduleImportForSummary) {
    if (moduleItems.isNotEmpty) {
      throw StateError('Can only call emitModule once.');
    }
    _component = component;

    for (var i = 0; i < summaries.length; i++) {
      var summary = summaries[i];
      var moduleImport = moduleImportForSummary[summaryUris[i]];
      for (var l in summary.libraries) {
        assert(!_importToSummary.containsKey(l));
        _importToSummary[l] = summary;
        _summaryToModule[summary] = moduleImport;
      }
    }

    var libraries = component.libraries.where((l) => !l.isExternal);
    var ddcRuntime =
        libraries.firstWhere(isSdkInternalRuntime, orElse: () => null);
    if (ddcRuntime != null) {
      // Don't allow these to be renamed when we're building the SDK.
      // There is JS code in dart:* that depends on their names.
      runtimeModule = JS.Identifier('dart');
      _extensionSymbolsModule = JS.Identifier('dartx');
      _nullableInference.allowNotNullDeclarations = true;
    } else {
      // Otherwise allow these to be renamed so users can write them.
      runtimeModule = JS.TemporaryId('dart');
      _extensionSymbolsModule = JS.TemporaryId('dartx');
    }
    _typeTable = TypeTable(runtimeModule);

    // Initialize our library variables.
    var items = <JS.ModuleItem>[];
    var exports = <JS.NameSpecifier>[];
    // TODO(jmesserly): this is a performance optimization for V8 to prevent it
    // from treating our Dart library objects as JS Maps.
    var root = JS.Identifier('_root');
    items.add(js.statement('const # = Object.create(null)', [root]));

    void emitLibrary(JS.Identifier id) {
      items.add(js.statement('const # = Object.create(#)', [id, root]));
      exports.add(JS.NameSpecifier(id));
    }

    for (var library in libraries) {
      var libraryTemp = library == ddcRuntime
          ? runtimeModule
          : JS.TemporaryId(jsLibraryName(library));
      _libraries[library] = libraryTemp;
      emitLibrary(libraryTemp);
    }

    // dart:_runtime has a magic module that holds extension method symbols.
    // TODO(jmesserly): find a cleaner design for this.
    if (ddcRuntime != null) emitLibrary(_extensionSymbolsModule);

    items.add(JS.ExportDeclaration(JS.ExportClause(exports)));

    // Collect all class/type Element -> Node mappings
    // in case we need to forward declare any classes.
    _pendingClasses = HashSet.identity();
    for (var l in libraries) {
      _pendingClasses.addAll(l.classes);
    }

    // Add implicit dart:core dependency so it is first.
    emitLibraryName(coreTypes.coreLibrary);

    // Visit each library and emit its code.
    //
    // NOTE: clases are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    libraries.forEach(_emitLibrary);

    // Visit directives (for exports)
    libraries.forEach(_emitExports);

    // Declare imports
    _finishImports(items);
    // Initialize extension symbols
    _extensionSymbols.forEach((name, id) {
      JS.Expression value =
          JS.PropertyAccess(_extensionSymbolsModule, _propertyName(name));
      if (ddcRuntime != null) {
        value = js.call('# = Symbol(#)', [value, js.string("dartx.$name")]);
      }
      items.add(js.statement('const # = #;', [id, value]));
    });

    // Discharge the type table cache variables and
    // hoisted definitions.
    items.addAll(_typeTable.discharge());

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, moduleItems);

    // Build the module.
    return JS.Program(items, name: options.moduleName);
  }

  /// Flattens blocks in [items] to a single list.
  ///
  /// This will not flatten blocks that are marked as being scopes.
  void _copyAndFlattenBlocks(
      List<JS.ModuleItem> result, Iterable<JS.ModuleItem> items) {
    for (var item in items) {
      if (item is JS.Block && !item.isScope) {
        _copyAndFlattenBlocks(result, item.statements);
      } else if (item != null) {
        result.add(item);
      }
    }
  }

  /// Returns the canonical name to refer to the Dart library.
  JS.Identifier emitLibraryName(Library library) {
    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(
            library, () => JS.TemporaryId(jsLibraryName(library)));
  }

  String _libraryToModule(Library library) {
    assert(!_libraries.containsKey(library));
    if (library.importUri.scheme == 'dart') {
      // TODO(jmesserly): we need to split out HTML.
      return JS.dartSdkModule;
    }
    var summary = _importToSummary[library];
    var moduleName = _summaryToModule[summary];
    if (moduleName == null) {
      throw StateError('Could not find module name for library "$library" '
          'from component "$summary".');
    }
    return moduleName;
  }

  void _finishImports(List<JS.ModuleItem> items) {
    var modules = Map<String, List<Library>>();

    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(coreTypes.coreLibrary)) {
      coreModuleName = _libraryToModule(coreTypes.coreLibrary);
    }
    modules.forEach((module, libraries) {
      // Generate import directives.
      //
      // Our import variables are temps and can get renamed. Since our renaming
      // is integrated into js_ast, it is aware of this possibility and will
      // generate an "as" if needed. For example:
      //
      //     import {foo} from 'foo';         // if no rename needed
      //     import {foo as foo$} from 'foo'; // if rename was needed
      //
      var imports =
          libraries.map((l) => JS.NameSpecifier(_imports[l])).toList();
      if (module == coreModuleName) {
        imports.add(JS.NameSpecifier(runtimeModule));
        imports.add(JS.NameSpecifier(_extensionSymbolsModule));
      }

      items.add(JS.ImportDeclaration(
          namedImports: imports, from: js.string(module, "'")));
    });
  }

  void _emitLibrary(Library library) {
    // NOTE: this method isn't the right place to initialize per-library state.
    // Classes can be visited out of order, so this is only to catch things that
    // haven't been emitted yet.
    //
    // See _emitClass.
    assert(_currentLibrary == null);
    _currentLibrary = library;

    if (isSdkInternalRuntime(library)) {
      // `dart:_runtime` uses a different order for bootstrapping.
      //
      // Functions are first because we use them to associate type info
      // (such as `dart.fn`), then classes/typedefs, then fields
      // (which instantiate classes).
      //
      // For other libraries, we start with classes/types, because functions
      // often use classes/types from the library in their signature.
      //
      // TODO(jmesserly): we can merge these once we change signatures to be
      // lazily associated at the tear-off point for top-level functions.
      _emitLibraryProcedures(library);
      _emitTopLevelFields(library.fields);
      library.classes.forEach(_emitClass);
    } else {
      library.classes.forEach(_emitClass);
      _emitLibraryProcedures(library);
      _emitTopLevelFields(library.fields);
    }

    _currentLibrary = null;
  }

  void _emitExports(Library library) {
    assert(_currentLibrary == null);
    _currentLibrary = library;

    library.additionalExports.forEach(_emitExport);

    _currentLibrary = null;
  }

  void _emitExport(Reference export) {
    var library = _currentLibrary;

    // We only need to export main as it is the only method part of the
    // publicly exposed JS API for a library.
    // TODO(jacobr): add a library level annotation indicating that all
    // contents of a library need to be exposed to JS.
    // https://github.com/dart-lang/sdk/issues/26368

    var node = export.node;
    if (node is Procedure && node.name.name == 'main') {
      // Don't allow redefining names from this library.
      var name = _emitTopLevelName(export.node);
      moduleItems.add(js.statement(
          '#.# = #;', [emitLibraryName(library), name.selector, name]));
    }
  }

  /// Called to emit class declarations.
  ///
  /// During the course of emitting one item, we may emit another. For example
  ///
  ///     class D extends B { C m() { ... } }
  ///
  /// Because D depends on B, we'll emit B first if needed. However C is not
  /// used by top-level JavaScript code, so we can ignore that dependency.
  void _emitClass(Class c) {
    if (!_pendingClasses.remove(c)) return;

    var savedClass = _currentClass;
    var savedLibrary = _currentLibrary;
    var savedUri = _currentUri;
    _currentClass = c;
    types.thisType = c.thisType;
    _currentLibrary = c.enclosingLibrary;
    _currentUri = c.fileUri;

    moduleItems.add(_emitClassDeclaration(c));

    _currentClass = savedClass;
    types.thisType = savedClass?.thisType;
    _currentLibrary = savedLibrary;
    _currentUri = savedUri;
  }

  /// To emit top-level classes, we sometimes need to reorder them.
  ///
  /// This function takes care of that, and also detects cases where reordering
  /// failed, and we need to resort to lazy loading, by marking the element as
  /// lazy. All elements need to be aware of this possibility and generate code
  /// accordingly.
  ///
  /// If we are not emitting top-level code, this does nothing, because all
  /// declarations are assumed to be available before we start execution.
  /// See [startTopLevel].
  void _declareBeforeUse(Class c) {
    if (c != null && _emittingClassExtends) _emitClass(c);
  }

  JS.Statement _emitClassDeclaration(Class c) {
    // Mixins are unrolled in _defineClass.
    if (c.isAnonymousMixin) return null;

    // If this class is annotated with `@JS`, then there is nothing to emit.
    if (findAnnotation(c, isPublicJSAnnotation) != null) return null;

    // Generic classes will be defined inside a function that closes over the
    // type parameter. So we can use their local variable name directly.
    //
    // TODO(jmesserly): the special case for JSArray is to support its special
    // type-tagging factory constructors. Those will go away once we fix:
    // https://github.com/dart-lang/sdk/issues/31003
    var className = c.typeParameters.isNotEmpty
        ? (c == _jsArrayClass
            ? JS.Identifier(c.name)
            : JS.TemporaryId(getLocalClassName(c)))
        : _emitTopLevelName(c);

    var savedClassProperties = _classProperties;
    _classProperties =
        ClassPropertyModel.build(types, _extensionTypes, virtualFields, c);

    var jsCtors = _defineConstructors(c, className);
    var jsMethods = _emitClassMethods(c);

    var body = <JS.Statement>[];
    _emitSuperHelperSymbols(body);
    var deferredSupertypes = <JS.Statement>[];

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(c, className, jsMethods, body, deferredSupertypes);
    body.addAll(jsCtors);

    // Emit things that come after the ES6 `class ... { ... }`.
    var jsPeerNames = _extensionTypes.getNativePeers(c);
    if (jsPeerNames.length == 1 && c.typeParameters.isNotEmpty) {
      // Special handling for JSArray<E>
      body.add(runtimeStatement('setExtensionBaseClass(#, #.global.#)',
          [className, runtimeModule, jsPeerNames[0]]));
    }

    var finishGenericTypeTest = _emitClassTypeTests(c, className, body);

    _emitVirtualFieldSymbols(c, body);
    _emitClassSignature(c, className, body);
    _initExtensionSymbols(c);
    if (!c.isMixinDeclaration) {
      _defineExtensionMembers(className, body);
    }
    _emitClassMetadata(c.annotations, className, body);

    var classDef = JS.Statement.from(body);
    var typeFormals = c.typeParameters;
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(
          c, typeFormals, classDef, className, deferredSupertypes);
    } else {
      body.addAll(deferredSupertypes);
    }

    body = [classDef];
    _emitStaticFields(c, body);
    if (finishGenericTypeTest != null) body.add(finishGenericTypeTest);
    for (var peer in jsPeerNames) {
      _registerExtensionType(c, peer, body);
    }

    _classProperties = savedClassProperties;
    return JS.Statement.from(body);
  }

  /// Wraps a possibly generic class in its type arguments.
  JS.Statement _defineClassTypeArguments(
      NamedNode c, List<TypeParameter> formals, JS.Statement body,
      [JS.Expression className, List<JS.Statement> deferredBaseClass]) {
    assert(formals.isNotEmpty);
    var name = getTopLevelName(c);
    var jsFormals = _emitTypeFormals(formals);
    var typeConstructor = js.call('(#) => { #; #; return #; }', [
      jsFormals,
      _typeTable.discharge(formals),
      body,
      className ?? JS.Identifier(name)
    ]);

    var genericArgs = [typeConstructor];
    if (deferredBaseClass != null && deferredBaseClass.isNotEmpty) {
      genericArgs.add(js.call('(#) => { #; }', [jsFormals, deferredBaseClass]));
    }

    var genericCall = runtimeCall('generic(#)', [genericArgs]);

    var genericName = _emitTopLevelNameNoInterop(c, suffix: '\$');
    return js.statement('{ # = #; # = #(); }',
        [genericName, genericCall, _emitTopLevelName(c), genericName]);
  }

  JS.Statement _emitClassStatement(Class c, JS.Expression className,
      JS.Expression heritage, List<JS.Method> methods) {
    if (c.typeParameters.isNotEmpty) {
      return JS.ClassExpression(className as JS.Identifier, heritage, methods)
          .toStatement();
    }
    var classExpr = JS.ClassExpression(
        JS.TemporaryId(getLocalClassName(c)), heritage, methods);
    return js.statement('# = #;', [className, classExpr]);
  }

  /// Like [_emitClassStatement] but emits a Dart 2.1 mixin represented by
  /// [c].
  ///
  /// Mixins work similar to normal classes, but their instance methods close
  /// over the actual superclass. Given a Dart class like:
  ///
  ///     mixin M on C {
  ///       foo() => super.foo() + 42;
  ///     }
  ///
  /// We generate a JS class like this:
  ///
  ///     lib.M = class M extends core.Object {}
  ///     lib.M[dart.mixinOn] = (C) => class M extends C {
  ///       foo() {
  ///         return super.foo() + 42;
  ///       }
  ///     };
  ///
  /// The special `dart.mixinOn` symbolized property is used by the runtime
  /// helper `dart.applyMixin`. The helper calls the function with the actual
  /// base class, and then copies the resulting members to the destination
  /// class.
  ///
  /// In the long run we may be able to improve this so we do not have the
  /// unnecessary class, but for now, this lets us get the right semantics with
  /// minimal compiler and runtime changes.
  void _emitMixinStatement(
      Class c,
      JS.Expression className,
      JS.Expression heritage,
      List<JS.Method> methods,
      List<JS.Statement> body) {
    var staticMethods = methods.where((m) => m.isStatic).toList();
    var instanceMethods = methods.where((m) => !m.isStatic).toList();

    body.add(_emitClassStatement(c, className, heritage, staticMethods));
    var superclassId = JS.TemporaryId(getLocalClassName(c.superclass));
    var classId = className is JS.Identifier
        ? className
        : JS.TemporaryId(getLocalClassName(c));

    var mixinMemberClass =
        JS.ClassExpression(classId, superclassId, instanceMethods);

    JS.Node arrowFnBody = mixinMemberClass;
    var extensionInit = <JS.Statement>[];
    _defineExtensionMembers(classId, extensionInit);
    if (extensionInit.isNotEmpty) {
      extensionInit.insert(0, mixinMemberClass.toStatement());
      extensionInit.add(classId.toReturn());
      arrowFnBody = JS.Block(extensionInit);
    }

    body.add(js.statement('#[#.mixinOn] = #', [
      className,
      runtimeModule,
      JS.ArrowFun([superclassId], arrowFnBody)
    ]));
  }

  void _defineClass(Class c, JS.Expression className, List<JS.Method> methods,
      List<JS.Statement> body, List<JS.Statement> deferredSupertypes) {
    if (c == coreTypes.objectClass) {
      body.add(_emitClassStatement(c, className, null, methods));
      return;
    }

    JS.Expression emitDeferredType(DartType t) {
      if (t is InterfaceType && t.typeArguments.isNotEmpty) {
        _declareBeforeUse(t.classNode);
        return _emitGenericClassType(t, t.typeArguments.map(emitDeferredType));
      }
      return _emitType(t);
    }

    bool shouldDefer(InterfaceType t) {
      var visited = Set<DartType>();
      bool defer(DartType t) {
        if (t is InterfaceType) {
          var tc = t.classNode;
          if (c == tc) return true;
          if (tc == coreTypes.objectClass || !visited.add(t)) return false;
          if (t.typeArguments.any(defer)) return true;
          var mixin = tc.mixedInType;
          return mixin != null && defer(mixin.asInterfaceType) ||
              defer(tc.supertype.asInterfaceType);
        }
        if (t is TypedefType) {
          return t.typeArguments.any(defer);
        }
        if (t is FunctionType) {
          return defer(t.returnType) ||
              t.positionalParameters.any(defer) ||
              t.namedParameters.any((np) => defer(np.type)) ||
              t.typeParameters.any((tp) => defer(tp.bound));
        }
        return false;
      }

      return defer(t);
    }

    emitClassRef(InterfaceType t) {
      // TODO(jmesserly): investigate this. It seems like `lazyJSType` is
      // invalid for use in an `extends` clause, hence this workaround.
      return _emitJSInterop(t.classNode) ?? visitInterfaceType(t);
    }

    getBaseClass(int count) {
      var base = emitDeferredType(c.thisType);
      while (--count >= 0) {
        base = js.call('#.__proto__', [base]);
      }
      return base;
    }

    // Find the real (user declared) superclass and the list of mixins.
    // We'll use this to unroll the intermediate classes.
    //
    // TODO(jmesserly): consider using Kernel's mixin unrolling.
    var mixinClasses = <Class>[];
    var superclass = getSuperclassAndMixins(c, mixinClasses);
    var supertype = identical(c.superclass, superclass)
        ? c.supertype.asInterfaceType
        : hierarchy.getClassAsInstanceOf(c, superclass).asInterfaceType;
    mixinClasses = mixinClasses.reversed.toList();
    var mixins = mixinClasses
        .map((m) => hierarchy.getClassAsInstanceOf(c, m).asInterfaceType)
        .toList();

    var hasUnnamedSuper = _hasUnnamedInheritedConstructor(superclass);

    void emitMixinConstructors(JS.Expression className, InterfaceType mixin) {
      JS.Statement mixinCtor;
      if (_hasUnnamedConstructor(mixin.classNode)) {
        mixinCtor = js.statement('#.#.call(this);', [
          emitClassRef(mixin),
          _usesMixinNew(mixin.classNode)
              ? runtimeCall('mixinNew')
              : _constructorName('')
        ]);
      }

      for (var ctor in superclass.constructors) {
        var savedUri = _currentUri;
        _currentUri = ctor.enclosingClass.fileUri;
        var jsParams = _emitParameters(ctor.function);
        _currentUri = savedUri;
        var ctorBody = <JS.Statement>[];
        if (mixinCtor != null) ctorBody.add(mixinCtor);
        var name = ctor.name.name;
        if (name != '' || hasUnnamedSuper) {
          ctorBody.add(_emitSuperConstructorCall(className, name, jsParams));
        }
        body.add(_addConstructorToClass(
            c, className, name, JS.Fun(jsParams, JS.Block(ctorBody))));
      }
    }

    var savedTopLevelClass = _classEmittingExtends;
    _classEmittingExtends = c;

    // Unroll mixins.
    if (shouldDefer(supertype)) {
      deferredSupertypes.add(runtimeStatement('setBaseClass(#, #)', [
        getBaseClass(isMixinAliasClass(c) ? 0 : mixins.length),
        emitDeferredType(supertype),
      ]));
      supertype = supertype.classNode.rawType;
    }
    var baseClass = emitClassRef(supertype);

    if (isMixinAliasClass(c)) {
      // Given `class C = Object with M [implements I1, I2 ...];`
      // The resulting class C should work as a mixin.
      //
      // TODO(jmesserly): is there any way to merge this with the other mixin
      // code paths, or will these always need special handling?
      body.add(_emitClassStatement(c, className, baseClass, []));

      var m = c.mixedInType.asInterfaceType;
      bool deferMixin = shouldDefer(m);
      var mixinBody = deferMixin ? deferredSupertypes : body;
      var mixinClass = deferMixin ? emitDeferredType(m) : emitClassRef(m);
      var classExpr = deferMixin ? getBaseClass(0) : className;

      mixinBody
          .add(runtimeStatement('applyMixin(#, #)', [classExpr, mixinClass]));

      if (methods.isNotEmpty) {
        // However we may need to add some methods to this class that call
        // `super` such as covariance checks.
        //
        // We do this with the following pattern:
        //
        //     applyMixin(C, class C$ extends M { <methods>  });
        mixinBody.add(runtimeStatement('applyMixin(#, #)', [
          classExpr,
          JS.ClassExpression(
              JS.TemporaryId(getLocalClassName(c)), mixinClass, methods)
        ]));
      }

      emitMixinConstructors(className, m);

      _classEmittingExtends = savedTopLevelClass;
      return;
    }

    // TODO(jmesserly): we need to unroll kernel mixins because the synthetic
    // classes lack required synthetic members, such as constructors.
    //
    // Also, we need to generate one extra level of nesting for alias classes.
    for (int i = 0; i < mixins.length; i++) {
      var m = mixins[i];
      var mixinName =
          getLocalClassName(superclass) + '_' + getLocalClassName(m.classNode);
      var mixinId = JS.TemporaryId(mixinName + '\$');
      // Bind the mixin class to a name to workaround a V8 bug with es6 classes
      // and anonymous function names.
      // TODO(leafp:) Eliminate this once the bug is fixed:
      // https://bugs.chromium.org/p/v8/issues/detail?id=7069
      body.add(js.statement("const # = #", [
        mixinId,
        JS.ClassExpression(JS.TemporaryId(mixinName), baseClass, [])
      ]));

      emitMixinConstructors(mixinId, m);
      hasUnnamedSuper = hasUnnamedSuper || _hasUnnamedConstructor(m.classNode);

      if (shouldDefer(m)) {
        deferredSupertypes.add(runtimeStatement('applyMixin(#, #)',
            [getBaseClass(mixins.length - i), emitDeferredType(m)]));
      } else {
        body.add(
            runtimeStatement('applyMixin(#, #)', [mixinId, emitClassRef(m)]));
      }

      baseClass = mixinId;
    }

    if (c.isMixinDeclaration) {
      _emitMixinStatement(c, className, baseClass, methods, body);
    } else {
      body.add(_emitClassStatement(c, className, baseClass, methods));
    }

    _classEmittingExtends = savedTopLevelClass;
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<JS.Statement> _defineConstructors(Class c, JS.Expression className) {
    var body = <JS.Statement>[];
    if (c.isAnonymousMixin || isMixinAliasClass(c)) {
      // We already handled this when we defined the class.
      return body;
    }

    addConstructor(String name, JS.Expression jsCtor) {
      body.add(_addConstructorToClass(c, className, name, jsCtor));
    }

    var fields = c.fields;
    for (var ctor in c.constructors) {
      if (ctor.isExternal) continue;
      addConstructor(ctor.name.name, _emitConstructor(ctor, fields, className));
    }

    // If classElement has only factory constructors, and it can be mixed in,
    // then we need to emit a special hidden default constructor for use by
    // mixins.
    if (_usesMixinNew(c)) {
      body.add(
          js.statement('(#[#] = function() { # }).prototype = #.prototype;', [
        className,
        runtimeCall('mixinNew'),
        [_initializeFields(fields)],
        className
      ]));
    }

    return body;
  }

  JS.Statement _emitClassTypeTests(
      Class c, JS.Expression className, List<JS.Statement> body) {
    JS.Expression getInterfaceSymbol(Class interface) {
      var library = interface.enclosingLibrary;
      if (library == coreTypes.coreLibrary ||
          library == coreTypes.asyncLibrary) {
        switch (interface.name) {
          case 'List':
          case 'Map':
          case 'Iterable':
          case 'Future':
          case 'Stream':
          case 'StreamSubscription':
            return runtimeCall('is' + interface.name);
        }
      }
      return null;
    }

    void markSubtypeOf(JS.Expression testSymbol) {
      body.add(js.statement('#.prototype[#] = true', [className, testSymbol]));
    }

    for (var iface in c.implementedTypes) {
      var prop = getInterfaceSymbol(iface.classNode);
      if (prop != null) markSubtypeOf(prop);
    }

    // TODO(jmesserly): share these hand coded type checks with the old back
    // end, perhaps by factoring them into a common file, or move them to be
    // static methdos in the SDK. (Or wait until we delete the old back end.)
    if (c.enclosingLibrary == coreTypes.coreLibrary) {
      if (c == coreTypes.objectClass) {
        // Everything is an Object.
        body.add(js.statement(
            '#.is = function is_Object(o) { return true; }', [className]));
        body.add(js.statement(
            '#.as = function as_Object(o) { return o; }', [className]));
        body.add(js.statement(
            '#._check = function check_Object(o) { return o; }', [className]));
        return null;
      }
      if (c == coreTypes.stringClass) {
        body.add(js.statement(
            '#.is = function is_String(o) { return typeof o == "string"; }',
            className));
        body.add(js.statement(
            '#.as = function as_String(o) {'
            '  if (typeof o == "string" || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_String(o) {'
            '  if (typeof o == "string" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.functionClass) {
        body.add(js.statement(
            '#.is = function is_Function(o) { return typeof o == "function"; }',
            className));
        body.add(js.statement(
            '#.as = function as_Function(o) {'
            '  if (typeof o == "function" || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_String(o) {'
            '  if (typeof o == "function" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.intClass) {
        body.add(js.statement(
            '#.is = function is_int(o) {'
            '  return typeof o == "number" && Math.floor(o) == o;'
            '}',
            className));
        body.add(js.statement(
            '#.as = function as_int(o) {'
            '  if ((typeof o == "number" && Math.floor(o) == o) || o == null)'
            '    return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_int(o) {'
            '  if ((typeof o == "number" && Math.floor(o) == o) || o == null)'
            '    return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.nullClass) {
        body.add(js.statement(
            '#.is = function is_Null(o) { return o == null; }', className));
        body.add(js.statement(
            '#.as = function as_Null(o) {'
            '  if (o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_Null(o) {'
            '  if (o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.numClass || c == coreTypes.doubleClass) {
        body.add(js.statement(
            '#.is = function is_num(o) { return typeof o == "number"; }',
            className));
        body.add(js.statement(
            '#.as = function as_num(o) {'
            '  if (typeof o == "number" || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_num(o) {'
            '  if (typeof o == "number" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
      if (c == coreTypes.boolClass) {
        body.add(js.statement(
            '#.is = function is_bool(o) { return o === true || o === false; }',
            className));
        body.add(js.statement(
            '#.as = function as_bool(o) {'
            '  if (o === true || o === false || o == null) return o;'
            '  return #.as(o, #, false);'
            '}',
            [className, runtimeModule, className]));
        body.add(js.statement(
            '#._check = function check_bool(o) {'
            '  if (o === true || o === false || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
    }
    if (c.enclosingLibrary == coreTypes.asyncLibrary) {
      if (c == coreTypes.futureOrClass) {
        var typeParam = TypeParameterType(c.typeParameters[0]);
        var typeT = visitTypeParameterType(typeParam);
        var futureOfT = visitInterfaceType(
            InterfaceType(coreTypes.futureClass, [typeParam]));
        body.add(js.statement('''
            #.is = function is_FutureOr(o) {
              return #.is(o) || #.is(o);
            }
            ''', [className, typeT, futureOfT]));
        // TODO(jmesserly): remove the fallback to `dart.as`. It's only for the
        // _ignoreTypeFailure logic.
        body.add(js.statement('''
            #.as = function as_FutureOr(o) {
              if (o == null || #.is(o) || #.is(o)) return o;
              return #.as(o, this, false);
            }
            ''', [className, typeT, futureOfT, runtimeModule]));
        body.add(js.statement('''
            #._check = function check_FutureOr(o) {
              if (o == null || #.is(o) || #.is(o)) return o;
              return #.as(o, this, true);
            }
            ''', [className, typeT, futureOfT, runtimeModule]));
        return null;
      }
    }

    body.add(runtimeStatement('addTypeTests(#)', [className]));

    if (c.typeParameters.isEmpty) return null;

    // For generics, testing against the default instantiation is common,
    // so optimize that.
    var isClassSymbol = getInterfaceSymbol(c);
    if (isClassSymbol == null) {
      // TODO(jmesserly): we could export these symbols, if we want to mark
      // implemented interfaces for user-defined classes.
      var id = JS.TemporaryId("_is_${getLocalClassName(c)}_default");
      moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      isClassSymbol = id;
    }
    // Marking every generic type instantiation as a subtype of its default
    // instantiation.
    markSubtypeOf(isClassSymbol);

    // Define the type tests on the default instantiation to check for that
    // marker.
    var defaultInst = _emitTopLevelName(c);

    // Return this `addTypeTests` call so we can emit it outside of the generic
    // type parameter scope.
    return runtimeStatement('addTypeTests(#, #)', [defaultInst, isClassSymbol]);
  }

  void _emitSymbols(Iterable<JS.TemporaryId> vars, List<JS.ModuleItem> body) {
    for (var id in vars) {
      body.add(js.statement('const # = Symbol(#)', [id, js.string(id.name)]));
    }
  }

  void _emitSuperHelperSymbols(List<JS.Statement> body) {
    _emitSymbols(
        _superHelpers.values.map((m) => m.name as JS.TemporaryId), body);
    _superHelpers.clear();
  }

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(Class c, List<JS.Statement> body) {
    var fields = c.fields
        .where((f) => f.isStatic && getRedirectingFactories(f) == null)
        .toList();
    if (c.isEnum) {
      // We know enum fields can be safely emitted as const fields, as long
      // as the `values` field is emitted last.
      var classRef = _emitTopLevelName(c);
      var valueField = fields.firstWhere((f) => f.name.name == 'values');
      fields.remove(valueField);
      fields.add(valueField);
      for (var f in fields) {
        assert(f.isConst);
        body.add(defineValueOnClass(
                c,
                classRef,
                _emitStaticMemberName(f.name.name),
                _visitInitializer(f.initializer, f.annotations))
            .toStatement());
      }
    } else if (fields.isNotEmpty) {
      body.add(_emitLazyFields(_emitTopLevelName(c), fields,
          (n) => _emitStaticMemberName(n.name.name)));
    }
  }

  void _emitClassMetadata(List<Expression> metadata, JS.Expression className,
      List<JS.Statement> body) {
    // Metadata
    if (emitMetadata && metadata.isNotEmpty) {
      body.add(js.statement('#[#.metadata] = #;', [
        className,
        runtimeModule,
        _arrowFunctionWithLetScope(() =>
            JS.ArrayInitializer(metadata.map(_instantiateAnnotation).toList()))
      ]));
    }
  }

  /// Ensure `dartx.` symbols we will use are present.
  void _initExtensionSymbols(Class c) {
    if (_extensionTypes.hasNativeSubtype(c) || c == coreTypes.objectClass) {
      for (var m in c.procedures) {
        if (!m.isAbstract && !m.isStatic && !m.name.isPrivate) {
          _declareMemberName(m, useExtension: true);
        }
      }
    }
  }

  /// If a concrete class implements one of our extensions, we might need to
  /// add forwarders.
  void _defineExtensionMembers(
      JS.Expression className, List<JS.Statement> body) {
    void emitExtensions(String helperName, Iterable<String> extensions) {
      if (extensions.isEmpty) return;

      var names = extensions
          .map((e) => _propertyName(JS.memberNameForDartMember(e)))
          .toList();
      body.add(js.statement('#.#(#, #);', [
        runtimeModule,
        helperName,
        className,
        JS.ArrayInitializer(names, multiline: names.length > 4)
      ]));
    }

    var props = _classProperties;
    emitExtensions('defineExtensionMethods', props.extensionMethods);
    emitExtensions('defineExtensionAccessors', props.extensionAccessors);
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(
      Class c, JS.Expression className, List<JS.Statement> body) {
    var savedClass = _classEmittingSignatures;
    _classEmittingSignatures = c;

    if (c.implementedTypes.isNotEmpty) {
      body.add(js.statement('#[#.implements] = () => [#];', [
        className,
        runtimeModule,
        c.implementedTypes.map((i) => _emitType(i.asInterfaceType))
      ]));
    }

    void emitSignature(String name, List<JS.Property> elements) {
      if (elements.isEmpty) return;

      if (!name.startsWith('Static')) {
        var proto = c == coreTypes.objectClass
            ? js.call('Object.create(null)')
            : runtimeCall('get${name}s(#.__proto__)', [className]);
        elements.insert(0, JS.Property(_propertyName('__proto__'), proto));
      }
      body.add(runtimeStatement('set${name}Signature(#, () => #)', [
        className,
        JS.ObjectInitializer(elements, multiline: elements.length > 1)
      ]));
    }

    var extMethods = _classProperties.extensionMethods;
    var extAccessors = _classProperties.extensionAccessors;
    var staticMethods = <JS.Property>[];
    var instanceMethods = <JS.Property>[];
    var staticGetters = <JS.Property>[];
    var instanceGetters = <JS.Property>[];
    var staticSetters = <JS.Property>[];
    var instanceSetters = <JS.Property>[];
    List<JS.Property> getSignatureList(Procedure p) {
      if (p.isStatic) {
        if (p.isGetter) {
          return staticGetters;
        } else if (p.isSetter) {
          return staticSetters;
        } else {
          return staticMethods;
        }
      } else {
        if (p.isGetter) {
          return instanceGetters;
        } else if (p.isSetter) {
          return instanceSetters;
        } else {
          return instanceMethods;
        }
      }
    }

    var classProcedures = c.procedures.where((p) => !p.isAbstract).toList();
    for (var member in classProcedures) {
      // Static getters/setters/methods cannot be called with dynamic dispatch,
      // nor can they be torn off.
      if (!emitMetadata && member.isStatic) continue;

      var name = member.name.name;
      var reifiedType = _getMemberRuntimeType(member, c) as FunctionType;

      // Don't add redundant signatures for inherited methods whose signature
      // did not change.  If we are not overriding, or if the thing we are
      // overriding has a different reified type from ourselves, we must
      // emit a signature on this class.  Otherwise we will inherit the
      // signature from the superclass.
      var memberOverride = c.superclass != null
          ? hierarchy.getDispatchTarget(c.superclass, member.name,
              setter: member.isSetter)
          : null;

      var needsSignature = memberOverride == null ||
          reifiedType != _getMemberRuntimeType(memberOverride, c);

      if (needsSignature) {
        JS.Expression type;
        if (member.isAccessor) {
          type = _emitAnnotatedResult(
              _emitType(member.isGetter
                  ? reifiedType.returnType
                  : reifiedType.positionalParameters[0]),
              member.annotations,
              member);
        } else {
          type = _emitAnnotatedFunctionType(reifiedType, member);
        }
        var property = JS.Property(_declareMemberName(member), type);
        var signatures = getSignatureList(member);
        signatures.add(property);
        if (!member.isStatic &&
            (extMethods.contains(name) || extAccessors.contains(name))) {
          signatures.add(JS.Property(
              _declareMemberName(member, useExtension: true), type));
        }
      }
    }

    emitSignature('Method', instanceMethods);
    emitSignature('StaticMethod', staticMethods);
    emitSignature('Getter', instanceGetters);
    emitSignature('Setter', instanceSetters);
    emitSignature('StaticGetter', staticGetters);
    emitSignature('StaticSetter', staticSetters);

    var instanceFields = <JS.Property>[];
    var staticFields = <JS.Property>[];

    var classFields = c.fields.toList();
    for (var field in classFields) {
      // Only instance fields need to be saved for dynamic dispatch.
      var isStatic = field.isStatic;
      if (!emitMetadata && isStatic) continue;

      var memberName = _declareMemberName(field);
      var fieldSig = _emitFieldSignature(field, c);
      (isStatic ? staticFields : instanceFields)
          .add(JS.Property(memberName, fieldSig));
    }
    emitSignature('Field', instanceFields);
    emitSignature('StaticField', staticFields);

    if (emitMetadata) {
      var constructors = <JS.Property>[];
      var allConstructors = List<Member>.from(c.constructors)
        ..addAll(c.procedures.where((p) => p.isFactory));
      for (var ctor in allConstructors) {
        var memberName = _constructorName(ctor.name.name);
        var type = _emitAnnotatedFunctionType(
            ctor.function.functionType.withoutTypeParameters, ctor);
        constructors.add(JS.Property(memberName, type));
      }
      emitSignature('Constructor', constructors);
    }

    // Add static property dart._runtimeType to Object.
    // All other Dart classes will (statically) inherit this property.
    if (c == coreTypes.objectClass) {
      body.add(runtimeStatement('lazyFn(#, () => #.#)',
          [className, emitLibraryName(coreTypes.coreLibrary), 'Type']));
    }

    _classEmittingSignatures = savedClass;
  }

  JS.Expression _emitFieldSignature(Field field, Class fromClass) {
    var type = _getTypeFromClass(field.type, field.enclosingClass, fromClass);
    var args = [_emitType(type)];
    var annotations = field.annotations;
    if (emitMetadata && annotations != null && annotations.isNotEmpty) {
      var savedUri = _currentUri;
      _currentUri = field.enclosingClass.fileUri;
      args.add(JS.ArrayInitializer(
          annotations.map(_instantiateAnnotation).toList()));
      _currentUri = savedUri;
    }
    return runtimeCall(
        field.isFinal ? 'finalFieldType(#)' : 'fieldType(#)', [args]);
  }

  DartType _getMemberRuntimeType(Member member, Class fromClass) {
    var f = member.function;
    if (f == null) {
      return (member as Field).type;
    }
    FunctionType result;
    if (!f.positionalParameters.any(isCovariantParameter) &&
        !f.namedParameters.any(isCovariantParameter)) {
      result = f.functionType;
    } else {
      reifyParameter(VariableDeclaration p) =>
          isCovariantParameter(p) ? coreTypes.objectClass.thisType : p.type;
      reifyNamedParameter(VariableDeclaration p) =>
          NamedType(p.name, reifyParameter(p));

      // TODO(jmesserly): do covariant type parameter bounds also need to be
      // reified as `Object`?
      result = FunctionType(
          f.positionalParameters.map(reifyParameter).toList(), f.returnType,
          namedParameters: f.namedParameters.map(reifyNamedParameter).toList()
            ..sort(),
          typeParameters: f.functionType.typeParameters,
          requiredParameterCount: f.requiredParameterCount);
    }
    return _getTypeFromClass(result, member.enclosingClass, fromClass)
        as FunctionType;
  }

  DartType _getTypeFromClass(DartType type, Class superclass, Class subclass) {
    if (identical(superclass, subclass)) return type;
    return Substitution.fromSupertype(
            hierarchy.getClassAsInstanceOf(subclass, superclass))
        .substituteType(type);
  }

  JS.Expression _emitConstructor(
      Constructor node, List<Field> fields, JS.Expression className) {
    var savedUri = _currentUri;
    _currentUri = node.fileUri ?? savedUri;
    var params = _emitParameters(node.function);
    var body = _withCurrentFunction(
        node.function,
        () => _superDisallowed(
            () => _emitConstructorBody(node, fields, className)));

    var end = _nodeEnd(node.fileEndOffset);
    _currentUri = savedUri;
    end ??= _nodeEnd(node.enclosingClass.fileEndOffset);

    return JS.Fun(params, JS.Block(body))..sourceInformation = end;
  }

  List<JS.Statement> _emitConstructorBody(
      Constructor node, List<Field> fields, JS.Expression className) {
    var cls = node.enclosingClass;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    var fn = node.function;
    var body = _emitArgumentInitializers(fn);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    var redirectCall = node.initializers
            .firstWhere((i) => i is RedirectingInitializer, orElse: () => null)
        as RedirectingInitializer;

    if (redirectCall != null) {
      body.add(_emitRedirectingConstructor(redirectCall, className));
      return body;
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(fields, node));

    // If no superinitializer is provided, an implicit superinitializer of the
    // form `super()` is added at the end of the initializer list, unless the
    // enclosing class is class Object.
    var superCall = node.initializers.firstWhere((i) => i is SuperInitializer,
        orElse: () => null) as SuperInitializer;
    var jsSuper = _emitSuperConstructorCallIfNeeded(cls, className, superCall);
    if (jsSuper != null) {
      body.add(jsSuper..sourceInformation = _nodeStart(superCall));
    }

    body.add(_emitFunctionScopedBody(fn));
    return body;
  }

  JS.Expression _constructorName(String name) {
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return _propertyName('new');
    }
    return _emitStaticMemberName(name);
  }

  JS.Statement _emitRedirectingConstructor(
      RedirectingInitializer node, JS.Expression className) {
    var ctor = node.target;
    // We can't dispatch to the constructor with `this.new` as that might hit a
    // derived class constructor with the same name.
    return js.statement('#.#.call(this, #);', [
      className,
      _constructorName(ctor.name.name),
      _emitArgumentList(node.arguments, types: false)
    ]);
  }

  JS.Statement _emitSuperConstructorCallIfNeeded(
      Class c, JS.Expression className,
      [SuperInitializer superInit]) {
    if (c == coreTypes.objectClass) return null;

    Constructor ctor;
    List<JS.Expression> args;
    if (superInit == null) {
      ctor = unnamedConstructor(c.superclass);
      args = [];
    } else {
      ctor = superInit.target;
      args = _emitArgumentList(superInit.arguments, types: false);
    }
    // We can skip the super call if it's empty. Most commonly this happens for
    // things that extend Object, and don't have any field initializers or their
    // own default constructor.
    if (ctor.name.name == '' && !_hasUnnamedSuperConstructor(c)) {
      return null;
    }
    return _emitSuperConstructorCall(className, ctor.name.name, args);
  }

  JS.Statement _emitSuperConstructorCall(
      JS.Expression className, String name, List<JS.Expression> args) {
    return js.statement('#.__proto__.#.call(this, #);',
        [className, _constructorName(name), args ?? []]);
  }

  bool _hasUnnamedInheritedConstructor(Class c) {
    if (c == null) return false;
    return _hasUnnamedConstructor(c) || _hasUnnamedSuperConstructor(c);
  }

  bool _hasUnnamedSuperConstructor(Class c) {
    return _hasUnnamedConstructor(c.mixedInClass) ||
        _hasUnnamedInheritedConstructor(c.superclass);
  }

  bool _hasUnnamedConstructor(Class c) {
    if (c == null || c == coreTypes.objectClass) return false;
    var ctor = unnamedConstructor(c);
    if (ctor != null && !ctor.isSynthetic) return true;
    return c.fields.any((f) => !f.isStatic);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  JS.Statement _initializeFields(List<Field> fields, [Constructor ctor]) {
    // Run field initializers if they can have side-effects.
    Set<Field> ctorFields;
    if (ctor != null) {
      ctorFields = ctor.initializers
          .map((c) => c is FieldInitializer ? c.field : null)
          .toSet()
            ..remove(null);
    }

    var body = <JS.Statement>[];
    emitFieldInit(Field f, Expression initializer, TreeNode hoverInfo) {
      var access = _classProperties.virtualFields[f] ?? _declareMemberName(f);
      var jsInit = _visitInitializer(initializer, f.annotations);
      body.add(jsInit
          .toAssignExpression(js.call('this.#', [access])
            ..sourceInformation = _nodeStart(hoverInfo))
          .toStatement());
    }

    for (var f in fields) {
      if (f.isStatic) continue;
      var init = f.initializer;
      if (ctorFields != null &&
          ctorFields.contains(f) &&
          (init == null || _constants.isConstant(init))) {
        continue;
      }
      emitFieldInit(f, init, f);
    }

    // Run constructor field initializers such as `: foo = bar.baz`
    if (ctor != null) {
      for (var init in ctor.initializers) {
        if (init is FieldInitializer) {
          emitFieldInit(init.field, init.value, init);
        } else if (init is LocalInitializer) {
          body.add(visitVariableDeclaration(init.variable));
        } else if (init is AssertInitializer) {
          body.add(visitAssertStatement(init.statement));
        }
      }
    }

    return JS.Statement.from(body);
  }

  JS.Expression _visitInitializer(
      Expression init, List<Expression> annotations) {
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    if (init == null) return JS.LiteralNull();
    return _annotatedNullCheck(annotations)
        ? notNull(init)
        : _visitExpression(init);
  }

  JS.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visitExpression(expr);
    if (!isNullable(expr)) return jsExpr;
    return runtimeCall('notNull(#)', jsExpr);
  }

  /// If the class has only factory constructors, and it can be mixed in,
  /// then we need to emit a special hidden default constructor for use by
  /// mixins.
  bool _usesMixinNew(Class mixin) {
    // TODO(jmesserly): mixin declarations don't get implicit constructor nodes,
    // even if they have fields, so we need to ensure they're getting generated.
    return mixin.isMixinDeclaration && _hasUnnamedConstructor(mixin) ||
        mixin.superclass?.superclass == null &&
            mixin.constructors.every((c) => c.isExternal);
  }

  JS.Statement _addConstructorToClass(
      Class c, JS.Expression className, String name, JS.Expression jsCtor) {
    jsCtor = defineValueOnClass(c, className, _constructorName(name), jsCtor);
    return js.statement('#.prototype = #.prototype;', [jsCtor, className]);
  }

  @override
  bool superclassHasStatic(Class c, String memberName) {
    // Note: because we're only considering statics, we can ignore mixins.
    // We're only trying to find conflicts due to JS inheriting statics.
    var name = Name(memberName, c.enclosingLibrary);
    while (true) {
      c = c.superclass;
      if (c == null) return false;
      for (var m in c.members) {
        if (m.name == name &&
            (m is Procedure && m.isStatic || m is Field && m.isStatic)) {
          return true;
        }
      }
    }
  }

  List<JS.Method> _emitClassMethods(Class c) {
    var virtualFields = _classProperties.virtualFields;

    var jsMethods = <JS.Method>[];
    bool hasJsPeer = _extensionTypes.isNativeClass(c);
    bool hasIterator = false;

    if (c == coreTypes.objectClass) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsMethods
          .add(JS.Method(_propertyName('constructor'), js.fun(r'''function() {
                  throw Error("use `new " + #.typeName(#.getReifiedType(this)) +
                      ".new(...)` to create a Dart object");
              }''', [runtimeModule, runtimeModule])));
    }

    Set<Member> redirectingFactories;
    for (var m in c.fields) {
      if (m.isStatic) {
        redirectingFactories ??= getRedirectingFactories(m)?.toSet();
      } else if (_extensionTypes.isNativeClass(c)) {
        jsMethods.addAll(_emitNativeFieldAccessors(m));
      } else if (virtualFields.containsKey(m)) {
        jsMethods.addAll(_emitVirtualFieldAccessor(m));
      }
    }

    var getters = Map<String, Procedure>();
    var setters = Map<String, Procedure>();
    for (var m in c.procedures) {
      if (m.isAbstract) continue;
      if (m.isGetter) {
        getters[m.name.name] = m;
      } else if (m.isSetter) {
        setters[m.name.name] = m;
      }
    }

    var savedUri = _currentUri;
    for (var m in c.procedures) {
      // For the Dart SDK, we use the member URI because it may be different
      // from the class (because of patch files). User code does not need this.
      //
      // TODO(jmesserly): CFE has a bug(?) where nSM forwarders sometimes have a
      // bogus file URI, that is mismatched compared to the offsets. This causes
      // a crash when we look up the location. So for those forwarders, we just
      // suppress source spans.
      _currentUri = m.isNoSuchMethodForwarder ? null : (m.fileUri ?? savedUri);
      if (_isForwardingStub(m)) {
        // TODO(jmesserly): is there any other kind of forwarding stub?
        jsMethods.addAll(_emitCovarianceCheckStub(m));
      } else if (m.isFactory) {
        // Skip redirecting factories (they've already been resolved).
        if (redirectingFactories?.contains(m) ?? false) continue;
        jsMethods.add(_emitFactoryConstructor(m));
      } else if (m.isAccessor) {
        jsMethods.add(_emitMethodDeclaration(m));
        jsMethods.add(_emitSuperAccessorWrapper(m, getters, setters));
        if (!hasJsPeer && m.isGetter && m.name.name == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(c));
        }
      } else {
        jsMethods.add(_emitMethodDeclaration(m));
      }
    }
    _currentUri = savedUri;

    // If the type doesn't have an `iterator`, but claims to implement Iterable,
    // we inject the adaptor method here, as it's less code size to put the
    // helper on a parent class. This pattern is common in the core libraries
    // (e.g. IterableMixin<E> and IterableBase<E>).
    //
    // (We could do this same optimization for any interface with an `iterator`
    // method, but that's more expensive to check for, so it doesn't seem worth
    // it. The above case for an explicit `iterator` method will catch those.)
    if (!hasJsPeer && !hasIterator) {
      jsMethods.add(_emitIterable(c));
    }

    // Add all of the super helper methods
    jsMethods.addAll(_superHelpers.values);

    return jsMethods.where((m) => m != null).toList();
  }

  bool _isForwardingStub(Procedure member) {
    if (member.isForwardingStub || member.isForwardingSemiStub) {
      if (_currentLibrary.importUri.scheme != 'dart') return true;
      // TODO(jmesserly): external methods in the SDK seem to get incorrectly
      // tagged as forwarding stubs even if they are patched. Perhaps there is
      // an ordering issue in CFE. So for now we pattern match to see if it
      // looks like an actual forwarding stub.
      //
      // We may be able to work around this in a cleaner way by simply emitting
      // the code, and letting the normal covariance check logic handle things.
      // But currently we use _emitCovarianceCheckStub to work around some
      // issues in the stubs.
      var body = member.function.body;
      if (body is ReturnStatement) {
        var expr = body.expression;
        return expr is SuperMethodInvocation || expr is SuperPropertySet;
      }
    }
    return false;
  }

  /// Emits a method, getter, or setter.
  JS.Method _emitMethodDeclaration(Procedure member) {
    if (member.isAbstract) {
      return null;
    }

    JS.Fun fn;
    if (member.isExternal && !member.isNoSuchMethodForwarder) {
      if (member.isStatic) {
        // TODO(vsm): Do we need to handle this case?
        return null;
      }
      fn = _emitNativeFunctionBody(member);
    } else {
      fn = _emitFunction(member.function, member.name.name);
    }

    return JS.Method(_declareMemberName(member), fn,
        isGetter: member.isGetter,
        isSetter: member.isSetter,
        isStatic: member.isStatic)
      ..sourceInformation = _nodeEnd(member.fileEndOffset);
  }

  JS.Fun _emitNativeFunctionBody(Procedure node) {
    String name = getAnnotationName(node, isJSAnnotation) ?? node.name.name;
    if (node.isGetter) {
      return JS.Fun([], js.block('{ return this.#; }', [name]));
    } else if (node.isSetter) {
      var params = _emitParameters(node.function);
      return JS.Fun(params, js.block('{ this.# = #; }', [name, params.last]));
    } else {
      return js.fun(
          'function (...args) { return this.#.apply(this, args); }', name);
    }
  }

  List<JS.Method> _emitCovarianceCheckStub(Procedure member) {
    // TODO(jmesserly): kernel stubs have a few problems:
    // - they're generated even when there is no concrete super member
    // - the stub parameter types don't match the types we need to check to
    //   ensure soundness of the super member, so we must lookup the super
    //   member and determine checks ourselves.
    // - it generates getter stubs, but these are not used
    if (member.isGetter) return const [];

    var enclosingClass = member.enclosingClass;
    var superMember = member.forwardingStubSuperTarget ??
        member.forwardingStubInterfaceTarget;

    if (superMember == null) return const [];

    substituteType(DartType t) {
      return _getTypeFromClass(t, superMember.enclosingClass, enclosingClass);
    }

    var name = _declareMemberName(member);
    if (member.isSetter) {
      if (superMember is Field && isCovariantField(superMember) ||
          superMember is Procedure &&
              isCovariantParameter(
                  superMember.function.positionalParameters[0])) {
        return const [];
      }
      var setterType = substituteType(superMember.setterType);
      if (types.isTop(setterType)) return const [];
      return [
        JS.Method(
            name,
            js.fun('function(x) { return super.# = #; }',
                [name, _emitCast(JS.Identifier('x'), setterType)]),
            isSetter: true),
        JS.Method(name, js.fun('function() { return super.#; }', [name]),
            isGetter: true)
      ];
    }
    assert(!member.isAccessor);

    var superMethodType =
        substituteType(superMember.function.functionType) as FunctionType;
    var function = member.function;

    var body = <JS.Statement>[];
    var typeParameters = superMethodType.typeParameters;
    _emitCovarianceBoundsCheck(typeParameters, body);

    var typeFormals = _emitTypeFormals(typeParameters);
    var jsParams = List<JS.Parameter>.from(typeFormals);
    var positionalParameters = function.positionalParameters;
    for (var i = 0, n = positionalParameters.length; i < n; i++) {
      var param = positionalParameters[i];
      var jsParam = JS.Identifier(param.name);
      jsParams.add(jsParam);

      if (isCovariantParameter(param) &&
          !isCovariantParameter(superMember.function.positionalParameters[i])) {
        var check = _emitCast(jsParam, superMethodType.positionalParameters[i]);
        if (i >= function.requiredParameterCount) {
          body.add(js.statement('if (# !== void 0) #;', [jsParam, check]));
        } else {
          body.add(check.toStatement());
        }
      }
    }
    var namedParameters = function.namedParameters;
    for (var param in namedParameters) {
      if (isCovariantParameter(param) &&
          !isCovariantParameter(superMember.function.namedParameters
              .firstWhere((n) => n.name == param.name))) {
        var name = _propertyName(param.name);
        var paramType = superMethodType.namedParameters
            .firstWhere((n) => n.name == param.name);
        body.add(js.statement('if (# in #) #;', [
          name,
          namedArgumentTemp,
          _emitCast(JS.PropertyAccess(namedArgumentTemp, name), paramType.type)
        ]));
      }
    }

    if (body.isEmpty) return const []; // No checks were needed.

    if (namedParameters.isNotEmpty) jsParams.add(namedArgumentTemp);
    body.add(js.statement('return super.#(#);', [name, jsParams]));
    return [JS.Method(name, JS.Fun(jsParams, JS.Block(body)))];
  }

  /// Emits a Dart factory constructor to a JS static method.
  JS.Method _emitFactoryConstructor(Procedure node) {
    if (isUnsupportedFactoryConstructor(node)) return null;

    var function = node.function;
    return JS.Method(_constructorName(node.name.name),
        JS.Fun(_emitParameters(function), _emitFunctionBody(function)),
        isStatic: true)
      ..sourceInformation = _nodeEnd(node.fileEndOffset);
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  JS.Expression emitConstructorAccess(InterfaceType type) {
    return _emitJSInterop(type.classNode) ?? visitInterfaceType(type);
  }

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<JS.Method> _emitVirtualFieldAccessor(Field field) {
    var virtualField = _classProperties.virtualFields[field];
    var name = _declareMemberName(field);

    var getter = js.fun('function() { return this[#]; }', [virtualField]);
    var jsGetter = JS.Method(name, getter, isGetter: true)
      ..sourceInformation = _nodeStart(field);

    var args = field.isFinal ? [JS.Super(), name] : [JS.This(), virtualField];

    JS.Expression value = JS.Identifier('value');
    if (!field.isFinal && isCovariantField(field)) {
      value = _emitCast(value, field.type);
    }
    args.add(value);

    var jsSetter = JS.Method(
        name, js.fun('function(value) { #[#] = #; }', args),
        isSetter: true)
      ..sourceInformation = _nodeStart(field);

    return [jsGetter, jsSetter];
  }

  /// Provide Dart getters and setters that forward to the underlying native
  /// field.  Note that the Dart names are always symbolized to avoid
  /// conflicts.  They will be installed as extension methods on the underlying
  /// native type.
  List<JS.Method> _emitNativeFieldAccessors(Field field) {
    // TODO(vsm): Can this by meta-programmed?
    // E.g., dart.nativeField(symbol, jsName)
    // Alternatively, perhaps it could be meta-programmed directly in
    // dart.registerExtensions?
    var jsMethods = <JS.Method>[];
    assert(!field.isStatic);

    var name = getAnnotationName(field, isJSName) ?? field.name.name;
    // Generate getter
    var fn = JS.Fun([], js.block('{ return this.#; }', [name]));
    var method = JS.Method(_declareMemberName(field), fn, isGetter: true);
    jsMethods.add(method);

    // Generate setter
    if (!field.isFinal) {
      var value = JS.TemporaryId('value');
      fn = JS.Fun([value], js.block('{ this.# = #; }', [name, value]));
      method = JS.Method(_declareMemberName(field), fn, isSetter: true);
      jsMethods.add(method);
    }

    return jsMethods;
  }

  /// Emit a getter (or setter) that simply forwards to the superclass getter
  /// (or setter).
  ///
  /// This is needed because in ES6, if you only override a getter
  /// (alternatively, a setter), then there is an implicit override of the
  /// setter (alternatively, the getter) that does nothing.
  JS.Method _emitSuperAccessorWrapper(Procedure member,
      Map<String, Procedure> getters, Map<String, Procedure> setters) {
    if (member.isAbstract) return null;

    var name = member.name.name;
    var memberName = _declareMemberName(member);
    if (member.isGetter) {
      if (!setters.containsKey(name) &&
          _classProperties.inheritedSetters.contains(name)) {
        // Generate a setter that forwards to super.
        var fn = js.fun('function(value) { super[#] = value; }', [memberName]);
        return JS.Method(memberName, fn, isSetter: true);
      }
    } else {
      assert(member.isSetter);
      if (!getters.containsKey(name) &&
          _classProperties.inheritedGetters.contains(name)) {
        // Generate a getter that forwards to super.
        var fn = js.fun('function() { return super[#]; }', [memberName]);
        return JS.Method(memberName, fn, isGetter: true);
      }
    }
    return null;
  }

  /// Support for adapting dart:core Iterable to ES6 versions.
  ///
  /// This lets them use for-of loops transparently:
  /// <https://github.com/lukehoban/es6features#iterators--forof>
  ///
  /// This will return `null` if the adapter was already added on a super type,
  /// otherwise it returns the adapter code.
  // TODO(jmesserly): should we adapt `Iterator` too?
  JS.Method _emitIterable(Class c) {
    var iterable = hierarchy.getClassAsInstanceOf(c, coreTypes.iterableClass);
    if (iterable == null) return null;

    // If a parent had an `iterator` (concrete or abstract) or implements
    // Iterable, we know the adapter is already there, so we can skip it as a
    // simple code size optimization.
    var parent = hierarchy.getDispatchTarget(c.superclass, Name('iterator'));
    if (parent != null) return null;

    var parentIterable =
        hierarchy.getClassAsInstanceOf(c.superclass, coreTypes.iterableClass);
    if (parentIterable != null) return null;

    if (c.enclosingLibrary.importUri.scheme == 'dart' &&
        c.procedures.any((m) => getJSExportName(m) == 'Symbol.iterator')) {
      return null;
    }

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return JS.Method(
        js.call('Symbol.iterator'),
        js.call('function() { return new #.JsIterator(this.#); }', [
          runtimeModule,
          _emitMemberName('iterator', memberClass: coreTypes.iterableClass)
        ]) as JS.Fun);
  }

  JS.Expression _instantiateAnnotation(Expression node) =>
      _visitExpression(node);

  void _registerExtensionType(
      Class c, String jsPeerName, List<JS.Statement> body) {
    var className = _emitTopLevelName(c);
    if (_typeRep.isPrimitive(c.rawType)) {
      body.add(
          runtimeStatement('definePrimitiveHashCode(#.prototype)', className));
    }
    body.add(runtimeStatement(
        'registerExtension(#, #)', [js.string(jsPeerName), className]));
  }

  void _emitTopLevelFields(List<Field> fields) {
    if (isSdkInternalRuntime(_currentLibrary)) {
      /// Treat dart:_runtime fields as safe to eagerly evaluate.
      // TODO(jmesserly): it'd be nice to avoid this special case.
      var lazyFields = <Field>[];
      var savedUri = _currentUri;
      for (var field in fields) {
        // Skip our magic undefined constant.
        if (field.name.name == 'undefined') continue;

        var init = field.initializer;
        if (init == null ||
            init is BasicLiteral ||
            init is StaticInvocation && isInlineJS(init.target)) {
          _currentUri = field.fileUri;
          moduleItems.add(js.statement('# = #;', [
            _emitTopLevelName(field),
            _visitInitializer(init, field.annotations)
          ]));
        } else {
          lazyFields.add(field);
        }
      }

      _currentUri = savedUri;
      fields = lazyFields;
    }

    if (fields.isEmpty) return;
    moduleItems.add(_emitLazyFields(
        emitLibraryName(_currentLibrary), fields, _emitTopLevelMemberName));
  }

  JS.Statement _emitLazyFields(JS.Expression objExpr, Iterable<Field> fields,
      JS.Expression Function(Field f) emitFieldName) {
    var accessors = <JS.Method>[];
    var savedUri = _currentUri;

    for (var field in fields) {
      _currentUri = field.fileUri;
      var access = emitFieldName(field);
      accessors.add(
          JS.Method(access, _emitStaticFieldInitializer(field), isGetter: true)
            ..sourceInformation = _hoverComment(
                JS.PropertyAccess(objExpr, access),
                field.fileOffset,
                field.name.name.length));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!field.isFinal && !field.isConst) {
        accessors.add(JS.Method(access, js.call('function(_) {}') as JS.Fun,
            isSetter: true));
      }
    }
    _currentUri = _currentLibrary.fileUri;

    _currentUri = savedUri;
    return runtimeStatement('defineLazy(#, { # })', [objExpr, accessors]);
  }

  JS.Fun _emitStaticFieldInitializer(Field field) {
    return JS.Fun(
        [],
        JS.Block(_withLetScope(() => [
              JS.Return(_visitInitializer(field.initializer, field.annotations))
            ])));
  }

  List<JS.Statement> _withLetScope(List<JS.Statement> visitBody()) {
    var savedLetVariables = _letVariables;
    _letVariables = [];

    var body = visitBody();
    var letVars = _initLetVariables();
    if (letVars != null) body.insert(0, letVars);

    _letVariables = savedLetVariables;
    return body;
  }

  JS.ArrowFun _arrowFunctionWithLetScope(JS.Expression visitBody()) {
    var savedLetVariables = _letVariables;
    _letVariables = [];

    var expr = visitBody();
    var letVars = _initLetVariables();

    _letVariables = savedLetVariables;
    return JS.ArrowFun(
        [], letVars == null ? expr : JS.Block([letVars, expr.toReturn()]));
  }

  JS.PropertyAccess _emitTopLevelName(NamedNode n, {String suffix = ''}) {
    return _emitJSInterop(n) ?? _emitTopLevelNameNoInterop(n, suffix: suffix);
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  JS.Expression _declareMemberName(Member m, {bool useExtension}) {
    return _emitMemberName(m.name.name,
        isStatic: m is Field ? m.isStatic : (m as Procedure).isStatic,
        useExtension:
            useExtension ?? _extensionTypes.isNativeClass(m.enclosingClass),
        member: m);
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
  /// This follows the same pattern as ECMAScript 6 Map:
  /// <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map>
  ///
  /// Unary minus looks like: `x._negate()`.
  ///
  /// Equality is a bit special, it is generated via the Dart `equals` runtime
  /// helper, that checks for null. The user defined method is called '=='.
  ///
  JS.Expression _emitMemberName(String name,
      {bool isStatic = false,
      bool useExtension,
      Member member,
      Class memberClass}) {
    // Static members skip the rename steps and may require JS interop renames.
    if (isStatic) {
      return _emitStaticMemberName(name, member);
    }

    // We allow some (illegal in Dart) member names to be used in our private
    // SDK code. These renames need to be included at every declaration,
    // including overrides in subclasses.
    if (member != null) {
      var runtimeName = getJSExportName(member);
      if (runtimeName != null) {
        var parts = runtimeName.split('.');
        if (parts.length < 2) return _propertyName(runtimeName);

        JS.Expression result = JS.Identifier(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          result = JS.PropertyAccess(result, _propertyName(parts[i]));
        }
        return result;
      }
    }

    if (name.startsWith('_')) {
      return emitPrivateNameSymbol(_currentLibrary, name);
    }

    memberClass ??= member?.enclosingClass;
    useExtension ??= _isSymbolizedMember(memberClass, name);
    name = JS.memberNameForDartMember(
        name, member is Procedure && member.isExternal);
    if (useExtension) {
      return _getExtensionSymbolInternal(name);
    }
    return _propertyName(name);
  }

  /// This is an internal method used by [_emitMemberName] and the
  /// optimized `dart:_runtime extensionSymbol` builtin to get the symbol
  /// for `dartx.<name>`.
  ///
  /// Do not call this directly; you want [_emitMemberName], which knows how to
  /// handle the many details involved in naming.
  JS.TemporaryId _getExtensionSymbolInternal(String name) {
    return _extensionSymbols.putIfAbsent(
        name,
        () => JS.TemporaryId(
            '\$${JS.friendlyNameForDartOperator[name] ?? name}'));
  }

  /// Don't symbolize native members that just forward to the underlying
  /// native member.  We limit this to non-renamed members as the receiver
  /// may be a mock type.
  ///
  /// Note, this is an underlying assumption here that, if another native type
  /// subtypes this one, it also forwards this member to its underlying native
  /// one without renaming.
  bool _isSymbolizedMember(Class c, String name) {
    if (c == null) {
      return isObjectMember(name);
    }
    c = _typeRep.getImplementationClass(c.rawType) ?? c;
    if (_extensionTypes.isNativeClass(c)) {
      var member = _lookupForwardedMember(c, name);

      // Fields on a native class are implicitly native.
      // Methods/getters/setters are marked external/native.
      if (member is Field || member is Procedure && member.isExternal) {
        var jsName = getAnnotationName(member, isJSName);
        return jsName != null && jsName != name;
      } else {
        // Non-external members must be symbolized.
        return true;
      }
    }
    // If the receiver *may* be a native type (i.e., an interface allowed to
    // be implemented by a native class), conservatively symbolize - we don't
    // know whether it'll be implemented via forwarding.
    // TODO(vsm): Consider CHA here to be less conservative.
    return _extensionTypes.isNativeInterface(c);
  }

  var _forwardingCache = HashMap<Class, Map<String, Member>>();

  Member _lookupForwardedMember(Class c, String name) {
    // We only care about public methods.
    if (name.startsWith('_')) return null;

    var map = _forwardingCache.putIfAbsent(c, () => {});

    return map.putIfAbsent(
        name,
        () =>
            hierarchy.getDispatchTarget(c, Name(name)) ??
            hierarchy.getDispatchTarget(c, Name(name), setter: true));
  }

  JS.Expression _emitStaticMemberName(String name, [NamedNode member]) {
    if (member != null) {
      var jsName = _emitJSInteropStaticMemberName(member);
      if (jsName != null) return jsName;
    }

    switch (name) {
      // Reserved for the compiler to do `x as T`.
      case 'as':
      // Reserved for the compiler to do implicit cast `T x = y`.
      case '_check':
      // Reserved for the SDK to compute `Type.toString()`.
      case 'name':
      // Reserved by JS, not a valid static member name.
      case 'prototype':
        name += '_';
        break;
      default:
        // All trailing underscores static names are reserved for the compiler
        // or SDK libraries.
        //
        // If user code uses them, add an extra `_`.
        //
        // This also avoids collision with the renames above, e.g. `static as`
        // and `static as_` will become `as_` and `as__`.
        if (name.endsWith('_')) {
          name += '_';
        }
    }
    return _propertyName(name);
  }

  JS.Expression _emitJSInteropStaticMemberName(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    var name = getAnnotationName(n, isPublicJSAnnotation);
    if (name != null) {
      if (name.contains('.')) {
        throw UnsupportedError(
            'static members do not support "." in their names. '
            'See https://github.com/dart-lang/sdk/issues/27926');
      }
    } else {
      name = getTopLevelName(n);
    }
    return js.escapedString(name, "'");
  }

  JS.PropertyAccess _emitTopLevelNameNoInterop(NamedNode n,
      {String suffix = ''}) {
    return JS.PropertyAccess(emitLibraryName(getLibrary(n)),
        _emitTopLevelMemberName(n, suffix: suffix));
  }

  /// Emits the member name portion of a top-level member.
  ///
  /// NOTE: usually you should use [_emitTopLevelName] instead of this. This
  /// function does not handle JS interop.
  JS.Expression _emitTopLevelMemberName(NamedNode n, {String suffix = ''}) {
    var name = getJSExportName(n) ?? getTopLevelName(n);
    return _propertyName(name + suffix);
  }

  String _getJSNameWithoutGlobal(NamedNode n) {
    if (!usesJSInterop(n)) return null;
    var libraryJSName = getAnnotationName(getLibrary(n), isPublicJSAnnotation);
    var jsName =
        getAnnotationName(n, isPublicJSAnnotation) ?? getTopLevelName(n);
    return libraryJSName != null ? '$libraryJSName.$jsName' : jsName;
  }

  JS.PropertyAccess _emitJSInterop(NamedNode n) {
    var jsName = _getJSNameWithoutGlobal(n);
    if (jsName == null) return null;
    return _emitJSInteropForGlobal(jsName);
  }

  JS.PropertyAccess _emitJSInteropForGlobal(String name) {
    var parts = name.split('.');
    if (parts.isEmpty) parts = [''];
    JS.PropertyAccess access;
    for (var part in parts) {
      access = JS.PropertyAccess(
          access ?? runtimeCall('global'), js.escapedString(part, "'"));
    }
    return access;
  }

  void _emitLibraryProcedures(Library library) {
    var procedures = library.procedures
        .where((p) => !p.isExternal && !p.isAbstract)
        .toList();
    moduleItems.addAll(procedures
        .where((p) => !p.isAccessor)
        .map(_emitLibraryFunction)
        .toList());
    _emitLibraryAccessors(procedures.where((p) => p.isAccessor).toList());
  }

  void _emitLibraryAccessors(Iterable<Procedure> accessors) {
    if (accessors.isEmpty) return;
    moduleItems.add(runtimeStatement('copyProperties(#, { # })', [
      emitLibraryName(_currentLibrary),
      accessors.map(_emitLibraryAccessor).toList()
    ]));
  }

  JS.Method _emitLibraryAccessor(Procedure node) {
    var savedUri = _currentUri;
    _currentUri = node.fileUri;

    var name = node.name.name;
    var result = JS.Method(
        _propertyName(name), _emitFunction(node.function, node.name.name),
        isGetter: node.isGetter, isSetter: node.isSetter)
      ..sourceInformation = _nodeEnd(node.fileEndOffset);

    _currentUri = savedUri;
    return result;
  }

  JS.Statement _emitLibraryFunction(Procedure p) {
    var savedUri = _currentUri;
    _currentUri = p.fileUri;

    var body = <JS.Statement>[];
    var fn = _emitFunction(p.function, p.name.name)
      ..sourceInformation = _nodeEnd(p.fileEndOffset);

    if (_currentLibrary.importUri.scheme == 'dart' &&
        _isInlineJSFunction(p.function.body)) {
      fn = JS.simplifyPassThroughArrowFunCallBody(fn);
    }

    var nameExpr = _emitTopLevelName(p);
    body.add(js.statement('# = #', [nameExpr, fn]));
    // Function types of top-level/static functions are only needed when
    // dart:mirrors is enabled.
    // TODO(jmesserly): do we even need this for mirrors, since statics are not
    // commonly reflected on?
    if (emitMetadata && _reifyFunctionType(p.function)) {
      body.add(
          _emitFunctionTagged(nameExpr, p.function.functionType, topLevel: true)
              .toStatement());
    }

    _currentUri = savedUri;
    return JS.Statement.from(body);
  }

  JS.Expression _emitFunctionTagged(JS.Expression fn, FunctionType type,
      {bool topLevel = false}) {
    var lazy = topLevel && !_canEmitTypeAtTopLevel(type);
    var typeRep = visitFunctionType(type, lazy: lazy);
    return runtimeCall(lazy ? 'lazyFn(#, #)' : 'fn(#, #)', [fn, typeRep]);
  }

  /// Whether the expression for [type] can be evaluated at this point in the JS
  /// module.
  ///
  /// Types cannot be evaluated if they depend on something that hasn't been
  /// defined yet. For example:
  ///
  ///     C foo() => null;
  ///     class C {}
  ///
  /// If we're emitting the type information for `foo`, we cannot refer to `C`
  /// yet, so we must evaluate foo's type lazily.
  bool _canEmitTypeAtTopLevel(DartType type) {
    if (type is InterfaceType) {
      return !_pendingClasses.contains(type.classNode) &&
          type.typeArguments.every(_canEmitTypeAtTopLevel);
    }
    if (type is FunctionType) {
      // Generic functions are always safe to emit, because they're lazy until
      // type arguments are applied.
      if (type.typeParameters.isNotEmpty) return true;

      return (_canEmitTypeAtTopLevel(type.returnType) &&
          type.positionalParameters.every(_canEmitTypeAtTopLevel) &&
          type.namedParameters.every((n) => _canEmitTypeAtTopLevel(n.type)));
    }
    if (type is TypedefType) {
      return type.typeArguments.every(_canEmitTypeAtTopLevel);
    }
    return true;
  }

  /// Emits a Dart [type] into code.
  JS.Expression _emitType(DartType type) => type.accept(this) as JS.Expression;

  JS.Expression _emitInvalidNode(Node node, [String message = '']) {
    if (message.isNotEmpty) message += ' ';
    return runtimeCall('throwUnimplementedError(#)',
        [js.escapedString('node <${node.runtimeType}> $message`$node`')]);
  }

  @override
  defaultDartType(type) => _emitInvalidNode(type);

  @override
  visitInvalidType(type) => defaultDartType(type);

  @override
  visitDynamicType(type) => runtimeCall('dynamic');

  @override
  visitVoidType(type) => runtimeCall('void');

  @override
  visitBottomType(type) => runtimeCall('bottom');

  @override
  visitInterfaceType(type) {
    var c = type.classNode;
    _declareBeforeUse(c);

    // Type parameters don't matter as JS interop types cannot be reified.
    // We have to use lazy JS types because until we have proper module
    // loading for JS libraries bundled with Dart libraries, we will sometimes
    // need to load Dart libraries before the corresponding JS libraries are
    // actually loaded.
    // Given a JS type such as:
    //     @JS('google.maps.Location')
    //     class Location { ... }
    // We can't emit a reference to MyType because the JS library that defines
    // it may be loaded after our code. So for now, we use a special lazy type
    // object to represent MyType.
    // Anonymous JS types do not have a corresponding concrete JS type so we
    // have to use a helper to define them.
    if (isJSAnonymousType(c)) {
      return runtimeCall(
          'anonymousJSType(#)', js.escapedString(getLocalClassName(c)));
    }
    var jsName = _getJSNameWithoutGlobal(c);
    if (jsName != null) {
      return runtimeCall('lazyJSType(() => #, #)',
          [_emitJSInteropForGlobal(jsName), js.escapedString(jsName)]);
    }

    var args = type.typeArguments;
    Iterable<JS.Expression> jsArgs = null;
    if (args.any((a) => a != const DynamicType())) {
      jsArgs = args.map(_emitType);
    }
    if (jsArgs != null) {
      var typeRep = _emitGenericClassType(type, jsArgs);
      return _cacheTypes ? _typeTable.nameType(type, typeRep) : typeRep;
    }

    return _emitTopLevelNameNoInterop(type.classNode);
  }

  bool get _emittingClassSignatures =>
      _currentClass != null &&
      identical(_currentClass, _classEmittingSignatures);

  bool get _emittingClassExtends =>
      _currentClass != null && identical(_currentClass, _classEmittingExtends);

  bool get _cacheTypes =>
      !_emittingClassExtends && !_emittingClassSignatures ||
      _currentFunction != null;

  JS.Expression _emitGenericClassType(
      InterfaceType t, Iterable<JS.Expression> typeArgs) {
    var genericName = _emitTopLevelNameNoInterop(t.classNode, suffix: '\$');
    return js.call('#(#)', [genericName, typeArgs]);
  }

  @override
  visitFunctionType(type, {Member member, bool lazy = false}) {
    var requiredTypes =
        type.positionalParameters.take(type.requiredParameterCount).toList();
    var function = member?.function;
    var requiredParams = function?.positionalParameters
        ?.take(type.requiredParameterCount)
        ?.toList();
    var optionalTypes =
        type.positionalParameters.skip(type.requiredParameterCount).toList();
    var optionalParams = function?.positionalParameters
        ?.skip(type.requiredParameterCount)
        ?.toList();

    var namedTypes = type.namedParameters;
    var rt = _emitType(type.returnType);
    var ra = _emitTypeNames(requiredTypes, requiredParams, member);

    List<JS.Expression> typeParts;
    if (namedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes);
      typeParts = [rt, ra, na];
    } else if (optionalTypes.isNotEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(optionalTypes, optionalParams, member);
      typeParts = [rt, ra, oa];
    } else {
      typeParts = [rt, ra];
    }

    var typeFormals = type.typeParameters;
    String helperCall;
    if (typeFormals.isNotEmpty) {
      var tf = _emitTypeFormals(typeFormals);

      addTypeFormalsAsParameters(List<JS.Expression> elements) {
        var names = _typeTable.discharge(typeFormals);
        return names.isEmpty
            ? js.call('(#) => [#]', [tf, elements])
            : js.call('(#) => {#; return [#];}', [tf, names, elements]);
      }

      typeParts = [addTypeFormalsAsParameters(typeParts)];

      helperCall = 'gFnType(#)';

      /// Whether the type parameter [t] has an explicit bound, like
      /// `<T extends C>`, `<T extends Object>` or `<T extends dynamic>`.
      ///
      /// In contrast, a type parameter like `<T>` has an implicit bound.
      /// Implicit bounds are a bit unusual, in that `Object` is used as the
      /// bound for checking, but `dynamic` is filled in as the default value.
      ///
      /// Kernel represents `<T>` as `<T extends Object = dynamic>`. We can find
      /// explicit bounds by looking for anything *except* that.
      typeParameterHasExplicitBound(TypeParameter t) =>
          t.bound != types.objectType || t.defaultType != const DynamicType();

      // If any explicit bounds were passed, emit them.
      if (typeFormals.any(typeParameterHasExplicitBound)) {
        /// Emits the bound of the type parameter [t] for use in runtime
        /// checking and the default value (e.g. for dynamic class).
        ///
        /// For most type parameters we can use [TypeParameter.bound]. However,
        /// for *implicit* bounds such as `<T>` (represented in Kernel as
        /// `<T extends Object = dynamic>`) we need to emit `dynamic` so we use
        /// the correct default value at runtime.
        ///
        /// Because `dynamic` and `Object` are both top types, they'll behave
        /// identically for the purposes of type checks.
        emitTypeParameterBound(TypeParameter t) =>
            typeParameterHasExplicitBound(t)
                ? _emitType(t.bound)
                : visitDynamicType(const DynamicType());

        var bounds = typeFormals.map(emitTypeParameterBound).toList();
        typeParts.add(addTypeFormalsAsParameters(bounds));
      }
    } else {
      helperCall = 'fnType(#)';
    }
    var typeRep = runtimeCall(helperCall, [typeParts]);
    return _cacheTypes
        ? _typeTable.nameFunctionType(type, typeRep, lazy: lazy)
        : typeRep;
  }

  JS.Expression _emitAnnotatedFunctionType(FunctionType type, Member member) {
    var result = visitFunctionType(type, member: member);

    var annotations = member.annotations;
    if (emitMetadata && annotations.isNotEmpty) {
      // TODO(jmesserly): should we disable source info for annotations?
      var savedUri = _currentUri;
      _currentUri = member.enclosingClass.fileUri;
      result = JS.ArrayInitializer(
          [result]..addAll(annotations.map(_instantiateAnnotation)));
      _currentUri = savedUri;
    }
    return result;
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  JS.Expression _emitConstructorAccess(InterfaceType type) {
    return _emitJSInterop(type.classNode) ?? _emitType(type);
  }

  JS.Expression _emitConstructorName(InterfaceType type, Member c) {
    return _emitJSInterop(type.classNode) ??
        JS.PropertyAccess(
            _emitConstructorAccess(type), _constructorName(c.name.name));
  }

  /// Emits an expression that lets you access statics on an [c] from code.
  JS.Expression _emitStaticClassName(Class c) {
    _declareBeforeUse(c);
    return _emitTopLevelName(c);
  }

  // Wrap a result - usually a type - with its metadata.  The runtime is
  // responsible for unpacking this.
  JS.Expression _emitAnnotatedResult(
      JS.Expression result, List<Expression> metadata, Member member) {
    if (emitMetadata && metadata.isNotEmpty) {
      // TODO(jmesserly): should we disable source info for annotations?
      var savedUri = _currentUri;
      _currentUri = member.enclosingClass.fileUri;
      result = JS.ArrayInitializer(
          [result]..addAll(metadata.map(_instantiateAnnotation)));
      _currentUri = savedUri;
    }
    return result;
  }

  JS.ObjectInitializer _emitTypeProperties(Iterable<NamedType> types) {
    return JS.ObjectInitializer(types
        .map((t) => JS.Property(_propertyName(t.name), _emitType(t.type)))
        .toList());
  }

  JS.ArrayInitializer _emitTypeNames(List<DartType> types,
      List<VariableDeclaration> parameters, Member member) {
    var result = <JS.Expression>[];
    for (int i = 0; i < types.length; ++i) {
      var type = _emitType(types[i]);
      if (parameters != null) {
        type = _emitAnnotatedResult(type, parameters[i].annotations, member);
      }
      result.add(type);
    }
    return JS.ArrayInitializer(result);
  }

  @override
  visitTypeParameterType(type) => _emitTypeParameter(type.parameter);

  JS.Identifier _emitTypeParameter(TypeParameter t) {
    _typeParamInConst?.add(t);
    return JS.Identifier(getTypeParameterName(t));
  }

  @override
  visitTypedefType(type) => visitFunctionType(type.unalias);

  JS.Fun _emitFunction(FunctionNode f, String name) {
    // normal function (sync), vs (sync*, async, async*)
    var isSync = f.asyncMarker == AsyncMarker.Sync;
    var formals = _emitParameters(f);
    var typeFormals = _emitTypeFormals(f.typeParameters);

    var parent = f.parent;
    if (_reifyGenericFunction(parent is Member ? parent : null)) {
      formals.insertAll(0, typeFormals);
    }

    // TODO(jmesserly): need a way of determining if parameters are
    // potentially mutated in Kernel. For now we assume all parameters are.
    super.enterFunction(name, formals, () => true);

    JS.Block code = isSync
        ? _emitFunctionBody(f)
        : JS.Block([
            _emitGeneratorFunction(f, name).toReturn()
              ..sourceInformation = _nodeStart(f)
          ]);

    code = super.exitFunction(name, formals, code);

    return JS.Fun(formals, code);
  }

  List<JS.Parameter> _emitParameters(FunctionNode f) {
    var positional = f.positionalParameters;
    var result = List<JS.Parameter>.from(positional.map(_emitVariableDef));
    if (positional.isNotEmpty &&
        f.requiredParameterCount == positional.length &&
        positional.last.annotations.any(isJsRestAnnotation)) {
      result.last = JS.RestParameter(result.last);
    }
    if (f.namedParameters.isNotEmpty) result.add(namedArgumentTemp);
    return result;
  }

  void _emitVirtualFieldSymbols(Class c, List<JS.Statement> body) {
    _classProperties.virtualFields.forEach((field, virtualField) {
      body.add(js.statement('const # = Symbol(#);', [
        virtualField,
        js.string('${getLocalClassName(c)}.${field.name.name}')
      ]));
    });
  }

  List<JS.Identifier> _emitTypeFormals(List<TypeParameter> typeFormals) {
    return typeFormals
        .map((t) => JS.Identifier(getTypeParameterName(t)))
        .toList();
  }

  JS.Expression _emitGeneratorFunction(FunctionNode function, String name) {
    // Transforms `sync*` `async` and `async*` function bodies
    // using ES6 generators.

    emitGeneratorFn(List<JS.Parameter> getParameters(JS.Block jsBody)) {
      var savedController = _asyncStarController;
      _asyncStarController = function.asyncMarker == AsyncMarker.AsyncStar
          ? JS.TemporaryId('stream')
          : null;

      JS.Expression gen;
      _superDisallowed(() {
        // Visit the body with our async* controller set.
        //
        // TODO(jmesserly): this will emit argument initializers (for default
        // values) inside the generator function body. Is that the best place?
        var jsBody = _emitFunctionBody(function);
        var genFn = JS.Fun(getParameters(jsBody), jsBody, isGenerator: true);

        // Name the function if possible, to get better stack traces.
        gen = genFn;
        if (name != null) {
          gen = JS.NamedFunction(
              JS.TemporaryId(JS.friendlyNameForDartOperator[name] ?? name),
              genFn);
        }

        gen.sourceInformation = _nodeEnd(function.fileEndOffset);
        if (JS.This.foundIn(gen)) gen = js.call('#.bind(this)', gen);
      });

      _asyncStarController = savedController;
      return gen;
    }

    if (function.asyncMarker == AsyncMarker.SyncStar) {
      // `sync*` wraps a generator in a Dart Iterable<E>:
      //
      // function name(<args>) {
      //   return new SyncIterator<E>(() => (function* name(<mutated args>) {
      //     <body>
      //   }(<mutated args>));
      // }
      //
      // In the body of a `sync*`, `yield` is generated simply as `yield`.
      //
      // We need to include all <mutated args> as parameters of the generator,
      // so each `.iterator` starts with the same initial values.
      //
      // We also need to ensure the correct `this` is available.
      //
      // In the future, we might be able to simplify this, see:
      // https://github.com/dart-lang/sdk/issues/28320
      var jsParams = _emitParameters(function);
      var gen = emitGeneratorFn((fnBody) => jsParams =
          jsParams.where(JS.findMutatedVariables(fnBody).contains).toList());
      if (jsParams.isNotEmpty) gen = js.call('() => #(#)', [gen, jsParams]);

      var returnType =
          _getExpectedReturnType(function, coreTypes.iterableClass);
      var syncIterable =
          _emitType(InterfaceType(syncIterableClass, [returnType]));
      return js.call('new #.new(#)', [syncIterable, gen]);
    }

    if (function.asyncMarker == AsyncMarker.AsyncStar) {
      // `async*` uses the `_AsyncStarImpl<T>` helper class. The generator
      // callback takes an instance of this class.
      //
      // `yield` is specially generated inside `async*` by visitYieldStatement.
      // `await` is generated as `yield`.
      //
      // _AsyncStarImpl has an example of the generated code.
      var gen = emitGeneratorFn((_) => [_asyncStarController]);

      var returnType = _getExpectedReturnType(function, coreTypes.streamClass);
      var asyncStarImpl = InterfaceType(asyncStarImplClass, [returnType]);
      return js.call('new #.new(#).stream', [_emitType(asyncStarImpl), gen]);
    }

    assert(function.asyncMarker == AsyncMarker.Async);

    // `async` works similar to `sync*`:
    //
    // function name(<args>) {
    //   return async.async(E, function* name() {
    //     <body>
    //   });
    // }
    //
    // In the body of an `async`, `await` is generated simply as `yield`.
    var gen = emitGeneratorFn((_) => []);
    // Return type of an async body is `Future<flatten(T)>`, where T is the
    // declared return type.
    var returnType = types.unfutureType(function.functionType.returnType);
    return js.call('#.async(#, #)',
        [emitLibraryName(coreTypes.asyncLibrary), _emitType(returnType), gen]);
  }

  /// Gets the expected return type of a `sync*` or `async*` body.
  DartType _getExpectedReturnType(FunctionNode f, Class expected) {
    var type = f.functionType.returnType;
    if (type is InterfaceType) {
      var match = hierarchy.getTypeAsInstanceOf(type, expected);
      if (match != null) return match.typeArguments[0];
    }
    return const DynamicType();
  }

  JS.Block _emitFunctionBody(FunctionNode f) {
    var block = _withCurrentFunction(f, () {
      var block = _emitArgumentInitializers(f);
      block.add(_emitFunctionScopedBody(f));
      return block;
    });

    return JS.Block(block);
  }

  List<JS.Statement> _withCurrentFunction(
      FunctionNode fn, List<JS.Statement> action()) {
    var savedFunction = _currentFunction;
    _currentFunction = fn;
    _nullableInference.enterFunction(fn);

    var result = _withLetScope(action);

    _nullableInference.exitFunction(fn);
    _currentFunction = savedFunction;
    return result;
  }

  T _superDisallowed<T>(T action()) {
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var result = action();
    _superAllowed = savedSuperAllowed;
    return result;
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  List<JS.Statement> _emitArgumentInitializers(FunctionNode f) {
    var body = <JS.Statement>[];

    _emitCovarianceBoundsCheck(f.typeParameters, body);

    initParameter(VariableDeclaration p, JS.Identifier jsParam) {
      if (isCovariantParameter(p)) {
        var castExpr = _emitCast(jsParam, p.type);
        if (!identical(castExpr, jsParam)) body.add(castExpr.toStatement());
      }
      if (_annotatedNullCheck(p.annotations)) {
        body.add(_nullParameterCheck(jsParam));
      }
    }

    for (var p in f.positionalParameters.take(f.requiredParameterCount)) {
      var jsParam = JS.Identifier(p.name);
      initParameter(p, jsParam);
    }
    for (var p in f.positionalParameters.skip(f.requiredParameterCount)) {
      var jsParam = JS.Identifier(p.name);
      var defaultValue = _defaultParamValue(p);
      if (defaultValue != null) {
        body.add(js.statement(
            'if (# === void 0) # = #;', [jsParam, jsParam, defaultValue]));
      }
      initParameter(p, jsParam);
    }
    for (var p in f.namedParameters) {
      // Parameters will be passed using their real names, not the (possibly
      // renamed) local variable.
      var jsParam = _emitVariableDef(p);
      var paramName = js.string(p.name, "'");
      var defaultValue = _defaultParamValue(p);
      if (defaultValue != null) {
        // TODO(ochafik): Fix `'prop' in obj` to please Closure's renaming.
        body.add(js.statement('let # = # && # in # ? #.# : #;', [
          jsParam,
          namedArgumentTemp,
          paramName,
          namedArgumentTemp,
          namedArgumentTemp,
          paramName,
          defaultValue,
        ]));
      } else {
        body.add(js.statement('let # = # && #.#;', [
          jsParam,
          namedArgumentTemp,
          namedArgumentTemp,
          paramName,
        ]));
      }
      initParameter(p, jsParam);
    }
    return body;
  }

  bool _annotatedNullCheck(List<Expression> annotations) =>
      annotations.any(_nullableInference.isNullCheckAnnotation);

  bool _reifyGenericFunction(Member m) =>
      m == null ||
      m.enclosingLibrary.importUri.scheme != 'dart' ||
      !m.annotations
          .any((a) => isBuiltinAnnotation(a, '_js_helper', 'NoReifyGeneric'));

  JS.Statement _nullParameterCheck(JS.Expression param) {
    var call = runtimeCall('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  JS.Expression _defaultParamValue(VariableDeclaration p) {
    if (p.initializer != null) {
      var value = p.initializer;
      return _isJSUndefined(value) ? null : _visitExpression(value);
    } else {
      return JS.LiteralNull();
    }
  }

  bool _isJSUndefined(Expression expr) {
    expr = expr is AsExpression ? expr.operand : expr;
    if (expr is StaticGet) {
      var t = expr.target;
      return isSdkInternalRuntime(getLibrary(t)) && t.name.name == 'undefined';
    }
    return false;
  }

  void _emitCovarianceBoundsCheck(
      List<TypeParameter> typeFormals, List<JS.Statement> body) {
    for (var t in typeFormals) {
      if (t.isGenericCovariantImpl && !types.isTop(t.bound)) {
        body.add(runtimeStatement('checkTypeBound(#, #, #)', [
          _emitType(TypeParameterType(t)),
          _emitType(t.bound),
          _propertyName(t.name)
        ]));
      }
    }
  }

  JS.Statement _visitStatement(Statement s) {
    if (s == null) return null;
    var result = s.accept(this) as JS.Statement;
    // TODO(jmesserly): is the `is! Block` still necessary?
    if (s is! Block) result.sourceInformation = _nodeStart(s);

    // The statement might be the target of a break or continue with a label.
    var name = _labelNames[s];
    if (name != null) result = JS.LabeledStatement(name, result);
    return result;
  }

  JS.Statement _emitFunctionScopedBody(FunctionNode f) {
    var jsBody = _visitStatement(f.body);
    if (f.positionalParameters.isNotEmpty || f.namedParameters.isNotEmpty) {
      // Handle shadowing of parameters by local varaibles, which is allowed in
      // Dart but not in JS.
      //
      // We need this for all function types, including generator-based ones
      // (sync*/async/async*). Our code generator assumes it can emit names for
      // named argument initialization, and sync* functions also emit locally
      // modified parameters into the function's scope.
      var parameterNames = HashSet<String>()
        ..addAll(f.positionalParameters.map((p) => p.name))
        ..addAll(f.namedParameters.map((p) => p.name));

      return jsBody.toScopedBlock(parameterNames);
    }
    return jsBody;
  }

  /// Visits [nodes] with [_visitExpression].
  List<JS.Expression> _visitExpressionList(Iterable<Expression> nodes) {
    return nodes?.map(_visitExpression)?.toList();
  }

  /// Generates an expression for a boolean conversion context (if, while, &&,
  /// etc.), where conversions and null checks are implemented via `dart.test`
  /// to give a more helpful message.
  // TODO(sra): When nullablility is available earlier, it would be cleaner to
  // build an input AST where the boolean conversion is a single AST node.
  JS.Expression _visitTest(Expression node) {
    if (node == null) return null;

    if (node is Not) {
      return visitNot(node);
    }
    if (node is LogicalExpression) {
      JS.Expression shortCircuit(String code) {
        return js.call(code, [_visitTest(node.left), _visitTest(node.right)]);
      }

      var op = node.operator;
      if (op == '&&') return shortCircuit('# && #');
      if (op == '||') return shortCircuit('# || #');
    }

    if (node is AsExpression && node.isTypeError) {
      assert(node.getStaticType(types) == types.boolType);
      return runtimeCall('dtest(#)', _visitExpression(node.operand));
    }

    var result = _visitExpression(node);
    if (isNullable(node)) result = runtimeCall('test(#)', result);
    return result;
  }

  JS.Expression _visitExpression(Expression e) {
    if (e == null) return null;
    var result = e.accept(this) as JS.Expression;
    result.sourceInformation ??= _nodeStart(e);
    return result;
  }

  /// Gets the start position of [node] for use in source mapping.
  ///
  /// This is the most common kind of marking, and is used for most expressions
  /// and statements.
  SourceLocation _nodeStart(TreeNode node) => _getLocation(node.fileOffset);

  /// Gets the end position of [node] for use in source mapping.
  ///
  /// This is mainly used for things that compile to JS functions. JS wants a
  /// marking on the end of all functions for stepping purposes.
  ///
  /// This can be used to complete a hover span, when we know the start position
  /// has already been emitted. For example, `foo.bar` we only need to mark the
  /// end of `.bar` to ensure `foo.bar` has a hover tooltip.
  NodeEnd _nodeEnd(int endOffset) {
    var loc = _getLocation(endOffset);
    return loc != null ? NodeEnd(loc) : null;
  }

  /// Combines [_nodeStart] with the variable name length to produce a hoverable
  /// span for the varaible.
  //
  // TODO(jmesserly): we need a lot more nodes to support hover.
  NodeSpan _variableSpan(int offset, int nameLength) {
    var start = _getLocation(offset);
    var end = _getLocation(offset + nameLength);
    return start != null && end != null ? NodeSpan(start, end) : null;
  }

  SourceLocation _getLocation(int offset) {
    if (offset == -1) return null;
    var fileUri = _currentUri;
    if (fileUri == null) return null;
    try {
      var loc = _component.getLocation(fileUri, offset);
      if (loc == null) return null;
      return SourceLocation(offset,
          sourceUrl: fileUri, line: loc.line - 1, column: loc.column - 1);
    } on StateError catch (_) {
      // TODO(jmesserly): figure out why this is throwing. Perhaps the file URI
      // and offset are mismatched and don't correspond to the same source?
      return null;
    }
  }

  /// Adds a hover comment for Dart node using JS expression [expr], where
  /// that expression would not otherwise not be generated into source code.
  ///
  /// For example, top-level and static fields are defined as lazy properties,
  /// on the library/class, so their access expressions do not appear in the
  /// source code.
  HoverComment _hoverComment(JS.Expression expr, int offset, int nameLength) {
    var start = _getLocation(offset);
    var end = _getLocation(offset + nameLength);
    return start != null && end != null ? HoverComment(expr, start, end) : null;
  }

  @override
  defaultStatement(Statement node) => _emitInvalidNode(node).toStatement();

  @override
  visitExpressionStatement(ExpressionStatement node) {
    var expr = node.expression;
    if (expr is StaticInvocation) {
      if (isInlineJS(expr.target)) {
        return _emitInlineJSCode(expr).toStatement();
      }
      if (_isDebuggerCall(expr.target)) {
        return _emitDebuggerCall(expr).toStatement();
      }
    }
    return _visitExpression(expr).toStatement();
  }

  @override
  visitBlock(Block node) {
    // If this is the block body of a function, don't mark it as a separate
    // scope, because the function is the scope. This avoids generating an
    // unncessary nested block.
    //
    // NOTE: we do sometimes need to handle this because Dart and JS rules are
    // slightly different (in Dart, there is a nested scope), but that's handled
    // by _emitFunctionBody.
    var isScope = !identical(node.parent, _currentFunction);
    return JS.Block(node.statements.map(_visitStatement).toList(),
        isScope: isScope);
  }

  @override
  visitEmptyStatement(EmptyStatement node) => JS.EmptyStatement();

  @override
  visitAssertBlock(AssertBlock node) {
    // AssertBlocks are introduced by the VM-specific async elimination
    // transformation.  We do not expect them to arise here.
    throw UnsupportedError('compilation of an assert block');
  }

  @override
  visitAssertStatement(AssertStatement node) {
    if (!options.enableAsserts) return JS.EmptyStatement();
    var condition = node.condition;
    var conditionType = condition.getStaticType(types);
    var jsCondition = _visitExpression(condition);

    var boolType = coreTypes.boolClass.rawType;
    if (conditionType is FunctionType &&
        conditionType.requiredParameterCount == 0 &&
        conditionType.returnType == boolType) {
      jsCondition = runtimeCall('test(#())', jsCondition);
    } else if (conditionType != boolType) {
      jsCondition = runtimeCall('dassert(#)', jsCondition);
    } else if (isNullable(condition)) {
      jsCondition = runtimeCall('test(#)', jsCondition);
    }
    return js.statement(' if (!#) #.assertFailed(#);', [
      jsCondition,
      runtimeModule,
      node.message != null ? [_visitExpression(node.message)] : []
    ]);
  }

  static bool isBreakable(Statement stmt) {
    // These are conservatively the things that compile to things that can be
    // the target of a break without a label.
    return stmt is ForStatement ||
        stmt is WhileStatement ||
        stmt is DoStatement ||
        stmt is ForInStatement ||
        stmt is SwitchStatement;
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    List<LabeledStatement> saved;
    var target = _effectiveTargets[node];
    // If the effective target is known then this statement is either contained
    // in a labeled statement or a loop.  It has already been processed when
    // the enclosing statement was visited.
    if (target == null) {
      // Find the effective target by bypassing and collecting labeled
      // statements.
      var statements = [node];
      target = node.body;
      while (target is LabeledStatement) {
        var labeled = target as LabeledStatement;
        statements.add(labeled);
        target = labeled.body;
      }
      for (var statement in statements) _effectiveTargets[statement] = target;

      // If the effective target will compile to something that can have a
      // break from it without a label (e.g., a loop but not a block), then any
      // of the labeled statements can have a break from them by breaking from
      // the effective target.  Otherwise breaks will need a label and a break
      // without a label can still target an outer breakable so the list of
      // current break targets does not change.
      if (isBreakable(target)) {
        saved = _currentBreakTargets;
        _currentBreakTargets = statements;
      }
    }

    var result = _visitStatement(node.body);
    if (saved != null) _currentBreakTargets = saved;
    return result;
  }

  @override
  visitBreakStatement(BreakStatement node) {
    // Can it be compiled to a break without a label?
    if (_currentBreakTargets.contains(node.target)) {
      return JS.Break(null);
    }
    // Can it be compiled to a continue without a label?
    if (_currentContinueTargets.contains(node.target)) {
      return JS.Continue(null);
    }

    // Ensure the effective target is labeled.  Labels are named globally per
    // Kernel binary.
    //
    // TODO(kmillikin): Preserve Dart label names in Kernel and here.
    var target = _effectiveTargets[node.target];
    var name = _labelNames[target];
    if (name == null) _labelNames[target] = name = 'L${_labelNames.length}';

    // It is a break if the target labeled statement encloses the effective
    // target.
    Statement current = node.target;
    while (current is LabeledStatement) {
      current = (current as LabeledStatement).body;
    }
    if (identical(current, target)) {
      return JS.Break(name);
    }
    // Otherwise it is a continue.
    return JS.Continue(name);
  }

  // Labeled loop bodies can be the target of a continue without a label
  // (targeting the loop).  Find the outermost non-labeled statement starting
  // from body and record all the intermediate labeled statements as continue
  // targets.
  Statement effectiveBodyOf(Statement loop, Statement body) {
    // In a loop whose body is not labeled, this list should be empty because
    // it is not possible to continue to an outer loop without a label.
    _currentContinueTargets = <LabeledStatement>[];
    while (body is LabeledStatement) {
      var labeled = body as LabeledStatement;
      _currentContinueTargets.add(labeled);
      _effectiveTargets[labeled] = loop;
      body = labeled.body;
    }
    return body;
  }

  T translateLoop<T extends JS.Statement>(Statement node, T action()) {
    List<LabeledStatement> savedBreakTargets;
    if (_currentBreakTargets.isNotEmpty &&
        _effectiveTargets[_currentBreakTargets.first] != node) {
      // If breaking without a label targets some other (outer) loop, then
      // this loop prevents breaking to that loop without a label.  This loop
      // was not labeled for a break in Kernel, otherwise it would be the
      // effective target of the current break targets, so it is not itself the
      // target of a break.
      savedBreakTargets = _currentBreakTargets;
      _currentBreakTargets = <LabeledStatement>[];
    }
    var savedContinueTargets = _currentContinueTargets;
    var result = action();
    if (savedBreakTargets != null) _currentBreakTargets = savedBreakTargets;
    _currentContinueTargets = savedContinueTargets;
    return result;
  }

  @override
  JS.While visitWhileStatement(WhileStatement node) {
    return translateLoop(node, () {
      var condition = _visitTest(node.condition);
      var body = _visitScope(effectiveBodyOf(node, node.body));
      return JS.While(condition, body);
    });
  }

  @override
  JS.Do visitDoStatement(DoStatement node) {
    return translateLoop(node, () {
      var body = _visitScope(effectiveBodyOf(node, node.body));
      var condition = _visitTest(node.condition);
      return JS.Do(body, condition);
    });
  }

  @override
  JS.For visitForStatement(ForStatement node) {
    return translateLoop(node, () {
      emitForInitializer(VariableDeclaration v) => JS.VariableInitialization(
          _emitVariableDef(v), _visitInitializer(v.initializer, v.annotations));

      var init = node.variables.map(emitForInitializer).toList();
      var initList =
          init.isEmpty ? null : JS.VariableDeclarationList('let', init);
      var updates = node.updates;
      JS.Expression update;
      if (updates.isNotEmpty) {
        update =
            JS.Expression.binary(updates.map(_visitExpression).toList(), ',')
                .toVoidExpression();
      }
      var condition = _visitTest(node.condition);
      var body = _visitScope(effectiveBodyOf(node, node.body));

      return JS.For(initList, condition, update, body);
    });
  }

  @override
  JS.Statement visitForInStatement(ForInStatement node) {
    return translateLoop(node, () {
      if (node.isAsync) {
        return _emitAwaitFor(node);
      }

      var iterable = _visitExpression(node.iterable);
      var body = _visitScope(effectiveBodyOf(node, node.body));

      var init = js.call('let #', _emitVariableDef(node.variable));
      if (_annotatedNullCheck(node.variable.annotations)) {
        body = JS.Block(
            [_nullParameterCheck(_emitVariableRef(node.variable)), body]);
      }

      if (variableIsReferenced(node.variable.name, iterable)) {
        var temp = JS.TemporaryId('iter');
        return JS.Block(
            [iterable.toVariableDeclaration(temp), JS.ForOf(init, temp, body)]);
      }
      return JS.ForOf(init, iterable, body);
    });
  }

  JS.Statement _emitAwaitFor(ForInStatement node) {
    // Emits `await for (var value in stream) ...`, which desugars as:
    //
    // var iter = new StreamIterator(stream);
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
    var streamIterator = _asyncStreamIteratorClass.rawType;
    var createStreamIter = JS.Call(
        _emitConstructorName(
            streamIterator,
            _asyncStreamIteratorClass.procedures
                .firstWhere((p) => p.isFactory && p.name.name == '')),
        [_visitExpression(node.iterable)]);

    var iter = JS.TemporaryId('iter');
    return js.statement(
        '{'
        '  let # = #;'
        '  try {'
        '    while (#) { let # = #.current; #; }'
        '  } finally { #; }'
        '}',
        [
          iter,
          createStreamIter,
          JS.Yield(js.call('#.moveNext()', iter))
            ..sourceInformation = _nodeStart(node.variable),
          _emitVariableDef(node.variable),
          iter,
          _visitStatement(node.body),
          JS.Yield(js.call('#.cancel()', iter))
            ..sourceInformation = _nodeStart(node.variable)
        ]);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    var cases = <JS.SwitchCase>[];
    var emptyBlock = JS.Block.empty();
    for (var c in node.cases) {
      // TODO(jmesserly): make sure we are statically checking fall through
      var body = _visitStatement(c.body).toBlock();
      var expressions = c.expressions;
      var last =
          expressions.isNotEmpty && !c.isDefault ? expressions.last : null;
      for (var e in expressions) {
        var jsExpr = _visitExpression(e);
        cases.add(JS.SwitchCase(jsExpr, e == last ? body : emptyBlock));
      }
      if (c.isDefault) cases.add(JS.SwitchCase.defaultCase(body));
    }

    return JS.Switch(_visitExpression(node.expression), cases);
  }

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    SwitchCase switchCase;
    for (Statement current = node;;) {
      var parent = current.parent;
      if (parent is Block && parent.statements.last == current) {
        current = parent;
        continue;
      }
      if (parent is SwitchCase) switchCase = parent;
      break;
    }
    if (switchCase != null) {
      var switchCases = (switchCase.parent as SwitchStatement).cases;
      var fromIndex = switchCases.indexOf(switchCase);
      var toIndex = switchCases.indexOf(node.target);
      if (toIndex == fromIndex + 1) {
        return JS.Comment('continue to next case');
      }
    }
    return _emitInvalidNode(
            node, 'see https://github.com/dart-lang/sdk/issues/29352')
        .toStatement();
  }

  @override
  visitIfStatement(IfStatement node) {
    return JS.If(_visitTest(node.condition), _visitScope(node.then),
        _visitScope(node.otherwise));
  }

  /// Visits a statement, and ensures the resulting AST handles block scope
  /// correctly. Essentially, we need to promote a variable declaration
  /// statement into a block in some cases, e.g.
  ///
  ///     do var x = 5; while (false); // Dart
  ///     do { let x = 5; } while (false); // JS
  JS.Statement _visitScope(Statement stmt) {
    var result = _visitStatement(stmt);
    if (result is JS.ExpressionStatement &&
        result.expression is JS.VariableDeclarationList) {
      return JS.Block([result]);
    }
    return result;
  }

  @override
  JS.Statement visitReturnStatement(ReturnStatement node) {
    return super.emitReturnStatement(_visitExpression(node.expression));
  }

  @override
  visitTryCatch(TryCatch node) {
    return JS.Try(
        _visitStatement(node.body).toBlock(), _visitCatch(node.catches), null);
  }

  JS.Catch _visitCatch(List<Catch> clauses) {
    if (clauses.isEmpty) return null;

    var caughtError = VariableDeclaration('#e');
    var savedRethrow = _rethrowParameter;
    _rethrowParameter = caughtError;

    // If we have more than one catch clause, always create a temporary so we
    // don't shadow any names.
    var exceptionParameter =
        (clauses.length == 1 ? clauses[0].exception : null) ??
            VariableDeclaration('#ex');

    var stackTraceParameter =
        (clauses.length == 1 ? clauses[0].stackTrace : null) ??
            (clauses.any((c) => c.stackTrace != null)
                ? VariableDeclaration('#st')
                : null);

    JS.Statement catchBody = JS.Throw(_emitVariableRef(caughtError));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(
          clause, catchBody, exceptionParameter, stackTraceParameter);
    }
    var catchStatements = [
      js.statement('let # = #.getThrown(#)', [
        _emitVariableDef(exceptionParameter),
        runtimeModule,
        _emitVariableRef(caughtError)
      ]),
    ];
    if (stackTraceParameter != null) {
      catchStatements.add(js.statement('let # = #.stackTrace(#)', [
        _emitVariableDef(stackTraceParameter),
        runtimeModule,
        _emitVariableRef(caughtError)
      ]));
    }
    catchStatements.add(catchBody);
    _rethrowParameter = savedRethrow;
    return JS.Catch(_emitVariableDef(caughtError), JS.Block(catchStatements));
  }

  JS.Statement _catchClauseGuard(
      Catch node,
      JS.Statement otherwise,
      VariableDeclaration exceptionParameter,
      VariableDeclaration stackTraceParameter) {
    var body = <JS.Statement>[];
    var vars = HashSet<String>();

    void declareVariable(
        VariableDeclaration variable, VariableDeclaration value) {
      if (variable == null) return;
      vars.add(variable.name);
      if (variable.name != value.name) {
        body.add(js.statement('let # = #',
            [_emitVariableDef(variable), _emitVariableRef(value)]));
      }
    }

    declareVariable(node.exception, exceptionParameter);
    declareVariable(node.stackTrace, stackTraceParameter);

    body.add(_visitStatement(node.body).toScopedBlock(vars));
    var then = JS.Block(body);

    // Discard following clauses, if any, as they are unreachable.
    if (types.isTop(node.guard)) return then;

    var condition =
        _emitIsExpression(VariableGet(exceptionParameter), node.guard);
    return JS.If(condition, then, otherwise)
      ..sourceInformation = _nodeStart(node);
  }

  @override
  visitTryFinally(TryFinally node) {
    var body = _visitStatement(node.body);
    var finallyBlock =
        _superDisallowed(() => _visitStatement(node.finalizer).toBlock());

    if (body is JS.Try && body.finallyPart == null) {
      // Kernel represents Dart try/catch/finally as try/catch nested inside of
      // try/finally.  Flatten that pattern in the output into JS try/catch/
      // finally.
      return JS.Try(body.body, body.catchPart, finallyBlock);
    }
    return JS.Try(body.toBlock(), null, finallyBlock);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    var jsExpr = _visitExpression(node.expression);
    var star = node.isYieldStar;
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
      return js.statement('{ if(#.#(#)) return; #; }', [
        _asyncStarController,
        helperName,
        jsExpr,
        JS.Yield(null)..sourceInformation = _nodeStart(node)
      ]);
    }
    // A normal yield in a sync*
    return jsExpr.toYieldStatement(star: star);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // TODO(jmesserly): casts are sometimes required here.
    // Kernel does not represent these explicitly.
    var v = _emitVariableDef(node);
    return js.statement('let # = #;',
        [v, _visitInitializer(node.initializer, node.annotations)]);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    var func = node.function;
    var fn = _emitFunction(func, node.variable.name);

    var name = _emitVariableDef(node.variable);
    JS.Statement declareFn;
    if (JS.This.foundIn(fn)) {
      declareFn = js.statement('const # = #.bind(this);', [name, fn]);
    } else {
      declareFn = JS.FunctionDeclaration(name, fn);
    }
    if (_reifyFunctionType(func)) {
      declareFn = JS.Block([
        declareFn,
        _emitFunctionTagged(_emitVariableRef(node.variable), func.functionType)
            .toStatement()
      ]);
    }
    return declareFn;
  }

  @override
  defaultExpression(Expression node) => _emitInvalidNode(node);

  @override
  defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);

  @override
  visitInvalidExpression(InvalidExpression node) => defaultExpression(node);

  @override
  visitConstantExpression(ConstantExpression node) =>
      node.constant.accept(this);

  @override
  visitVariableGet(VariableGet node) {
    var v = node.variable;
    var id = _emitVariableRef(v);
    if (id.name == v.name) {
      id.sourceInformation = _variableSpan(node.fileOffset, v.name.length);
    }
    return id;
  }

  JS.Identifier _emitVariableRef(VariableDeclaration v) {
    var name = v.name;
    if (name == null || name.startsWith('#')) {
      name = name == null ? 't${_tempVariables.length}' : name.substring(1);
      return _tempVariables.putIfAbsent(v, () => JS.TemporaryId(name));
    }
    return JS.Identifier(name);
  }

  /// Emits the declaration of a variable.
  ///
  /// This is similar to [_emitVariableRef] but it also attaches source
  /// location information, so hover will work as expected.
  JS.Identifier _emitVariableDef(VariableDeclaration v) {
    return _emitVariableRef(v)..sourceInformation = _nodeStart(v);
  }

  JS.Statement _initLetVariables() {
    if (_letVariables.isEmpty) return null;
    var result = JS.VariableDeclarationList(
            'let',
            _letVariables
                .map((v) => JS.VariableInitialization(v, null))
                .toList())
        .toStatement();
    _letVariables.clear();
    return result;
  }

  // TODO(jmesserly): resugar operators for kernel, such as ++x, x++, x+=.
  @override
  visitVariableSet(VariableSet node) => _visitExpression(node.value)
      .toAssignExpression(_emitVariableRef(node.variable));

  @override
  visitPropertyGet(PropertyGet node) {
    return _emitPropertyGet(
        node.receiver, node.interfaceTarget, node.name.name);
  }

  @override
  visitPropertySet(PropertySet node) {
    return _emitPropertySet(
        node.receiver, node.interfaceTarget, node.value, node.name.name);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    return _emitPropertyGet(node.receiver, node.target);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    return _emitPropertySet(node.receiver, node.target, node.value);
  }

  JS.Expression _emitPropertyGet(Expression receiver, Member member,
      [String memberName]) {
    memberName ??= member.name.name;
    // TODO(jmesserly): should tearoff of `.call` on a function type be
    // encoded as a different node, or possibly eliminated?
    // (Regardless, we'll still need to handle the callable JS interop classes.)
    if (memberName == 'call' &&
        _isDirectCallable(receiver.getStaticType(types))) {
      // Tearoff of `call` on a function type is a no-op;
      return _visitExpression(receiver);
    }
    var jsName = _emitMemberName(memberName, member: member);
    var jsReceiver = _visitExpression(receiver);

    // TODO(jmesserly): we need to mark an end span for property accessors so
    // they can be hovered. Unfortunately this is not possible as Kernel does
    // not store this data.
    if (isObjectMember(memberName)) {
      if (isNullable(receiver)) {
        // If the receiver is nullable, use a helper so calls like
        // `null.hashCode` and `null.runtimeType` will work.
        // Also method tearoffs like `null.toString`.
        if (_isObjectMethodTearoff(memberName)) {
          return runtimeCall('bind(#, #)', [jsReceiver, jsName]);
        }
        return runtimeCall('#(#)', [memberName, jsReceiver]);
      }
      // Otherwise generate this as a normal typed property get.
    } else if (member == null) {
      return runtimeCall('dload$_replSuffix(#, #)', [jsReceiver, jsName]);
    }

    if (_reifyTearoff(member)) {
      return runtimeCall('bind(#, #)', [jsReceiver, jsName]);
    } else {
      return JS.PropertyAccess(jsReceiver, jsName);
    }
  }

  // TODO(jmesserly): can we encapsulate REPL name lookups and remove this?
  // _emitMemberName would be a nice place to handle it, but we don't have
  // access to the target expression there (needed for `dart.replNameLookup`).
  String get _replSuffix => options.replCompile ? 'Repl' : '';

  JS.Expression _emitPropertySet(
      Expression receiver, Member member, Expression value,
      [String memberName]) {
    var jsName =
        _emitMemberName(memberName ?? member.name.name, member: member);

    var jsReceiver = _visitExpression(receiver);
    var jsValue = _visitExpression(value);

    if (member == null) {
      return runtimeCall(
          'dput$_replSuffix(#, #, #)', [jsReceiver, jsName, jsValue]);
    }
    return js.call('#.# = #', [jsReceiver, jsName, jsValue]);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    var target = node.interfaceTarget;
    var jsTarget = _emitSuperTarget(target);
    if (_reifyTearoff(target)) {
      return runtimeCall('bind(this, #, #)', [jsTarget.selector, jsTarget]);
    }
    return jsTarget;
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    var target = node.interfaceTarget;
    var jsTarget = _emitSuperTarget(target, setter: true);
    return _visitExpression(node.value).toAssignExpression(jsTarget);
  }

  @override
  visitStaticGet(StaticGet node) {
    var target = node.target;
    if (target is Field && target.isConst) {
      var value = _constants.evaluate(target.initializer, cache: true);
      if (value is PrimitiveConstant) return value.accept(this);
    }

    var result = _emitStaticTarget(target);
    if (_reifyTearoff(target)) {
      // TODO(jmesserly): we could tag static/top-level function types once
      // in the module initialization, rather than at the point where they
      // escape.
      return _emitFunctionTagged(result, target.function.functionType);
    }
    return result;
  }

  @override
  visitStaticSet(StaticSet node) {
    return _visitExpression(node.value)
        .toAssignExpression(_emitStaticTarget(node.target));
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    return _emitMethodCall(
        node.receiver, node.interfaceTarget, node.arguments, node);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    return _emitMethodCall(node.receiver, node.target, node.arguments, node);
  }

  JS.Expression _emitMethodCall(Expression receiver, Member target,
      Arguments arguments, InvocationExpression node) {
    var name = node.name.name;

    if (isOperatorMethodName(name) && arguments.named.isEmpty) {
      int argLength = arguments.positional.length;
      if (argLength == 0) {
        return _emitUnaryOperator(receiver, target, node);
      } else if (argLength == 1) {
        return _emitBinaryOperator(
            receiver, target, arguments.positional[0], node);
      }
    }

    var jsReceiver = _visitExpression(receiver);
    var args = _emitArgumentList(arguments, target: target);

    bool isCallingDynamicField = target is Member &&
        target.hasGetter &&
        _isDynamicOrFunction(target.getterType);
    if (name == 'call') {
      var receiverType = receiver.getStaticType(types);
      if (isCallingDynamicField || _isDynamicOrFunction(receiverType)) {
        return _emitDynamicInvoke(jsReceiver, null, args, arguments);
      } else if (_isDirectCallable(receiverType)) {
        // Call methods on function types should be handled as function calls.
        return JS.Call(jsReceiver, args);
      }
    }

    var jsName = _emitMemberName(name, member: target);

    // Handle Object methods that are supported by `null`.
    if (_isObjectMethodCall(name, arguments)) {
      if (isNullable(receiver)) {
        // If the receiver is nullable, use a helper so calls like
        // `null.toString()` will work.
        return runtimeCall('#(#, #)', [name, jsReceiver, args]);
      }
      // Otherwise generate this as a normal typed method call.
    } else if (target == null || isCallingDynamicField) {
      return _emitDynamicInvoke(jsReceiver, jsName, args, arguments);
    }
    // TODO(jmesserly): remove when Kernel desugars this for us.
    // Handle `o.m(a)` where `o.m` is a getter returning a class with `call`.
    if (target is Field || target is Procedure && target.isAccessor) {
      var fromType = target.getterType;
      if (fromType is InterfaceType) {
        var callName = _getImplicitCallTarget(fromType);
        if (callName != null) {
          return js.call('#.#.#(#)', [jsReceiver, jsName, callName, args]);
        }
      }
    }
    return js.call('#.#(#)', [jsReceiver, jsName, args]);
  }

  JS.Expression _emitDynamicInvoke(JS.Expression fn, JS.Expression methodName,
      Iterable<JS.Expression> args, Arguments arguments) {
    var jsArgs = <Object>[fn];
    String jsCode;

    var typeArgs = arguments.types;
    if (typeArgs.isNotEmpty) {
      jsArgs.add(args.take(typeArgs.length));
      args = args.skip(typeArgs.length);
      if (methodName != null) {
        jsCode = 'dgsend$_replSuffix(#, [#], #';
        jsArgs.add(methodName);
      } else {
        jsCode = 'dgcall(#, [#]';
      }
    } else if (methodName != null) {
      jsCode = 'dsend$_replSuffix(#, #';
      jsArgs.add(methodName);
    } else {
      jsCode = 'dcall(#';
    }

    var hasNamed = arguments.named.isNotEmpty;
    if (hasNamed) {
      jsCode += ', [#], #)';
      jsArgs.add(args.take(args.length - 1));
      jsArgs.add(args.last);
    } else {
      jsArgs.add(args);
      jsCode += ', [#])';
    }

    return runtimeCall(jsCode, jsArgs);
  }

  bool _isDirectCallable(DartType t) =>
      t is FunctionType || t is InterfaceType && usesJSInterop(t.classNode);

  JS.Expression _getImplicitCallTarget(InterfaceType from) {
    var c = from.classNode;
    var member = hierarchy.getInterfaceMember(c, Name("call"));
    if (member is Procedure && !member.isAccessor && !usesJSInterop(c)) {
      return _emitMemberName('call', member: member);
    }
    return null;
  }

  _isDynamicOrFunction(DartType t) =>
      t == coreTypes.functionClass.rawType || t == const DynamicType();

  JS.Expression _emitUnaryOperator(
      Expression expr, Member target, InvocationExpression node) {
    var op = node.name.name;
    if (target != null) {
      var dispatchType = target.enclosingClass.rawType;
      if (_typeRep.unaryOperationIsPrimitive(dispatchType)) {
        if (op == '~') {
          if (_typeRep.isNumber(dispatchType)) {
            return _coerceBitOperationResultToUnsigned(
                node, js.call('~#', notNull(expr)));
          }
          return _emitOperatorCall(expr, target, op, []);
        }
        if (op == 'unary-') op = '-';
        return js.call('$op#', notNull(expr));
      }
    }
    return _emitOperatorCall(expr, target, op, []);
  }

  /// Bit operations are coerced to values on [0, 2^32). The coercion changes
  /// the interpretation of the 32-bit value from signed to unsigned.  Most
  /// JavaScript operations interpret their operands as signed and generate
  /// signed results.
  JS.Expression _coerceBitOperationResultToUnsigned(
      Expression node, JS.Expression uncoerced) {
    // Don't coerce if the parent will coerce.
    var parent = node.parent;
    if (parent is InvocationExpression && _nodeIsBitwiseOperation(parent)) {
      return uncoerced;
    }

    // Don't do a no-op coerce if the most significant bit is zero.
    if (_is31BitUnsigned(node)) return uncoerced;

    // If the consumer of the expression is '==' or '!=' with a constant that
    // fits in 31 bits, adding a coercion does not change the result of the
    // comparison, e.g.  `a & ~b == 0`.
    if (parent is InvocationExpression &&
        parent.arguments.positional.length == 1) {
      var op = parent.name.name;
      var left = getInvocationReceiver(parent);
      var right = parent.arguments.positional[0];
      if (left != null && op == '==') {
        const int MAX = 0x7fffffff;
        if (_asIntInRange(right, 0, MAX) != null) return uncoerced;
        if (_asIntInRange(left, 0, MAX) != null) return uncoerced;
      } else if (left != null && op == '>>') {
        if (_isDefinitelyNonNegative(left) &&
            _asIntInRange(right, 0, 31) != null) {
          // Parent will generate `# >>> n`.
          return uncoerced;
        }
      }
    }
    return js.call('# >>> 0', uncoerced);
  }

  bool _nodeIsBitwiseOperation(InvocationExpression node) {
    switch (node.name.name) {
      case '&':
      case '|':
      case '^':
      case '~':
        return true;
    }
    return false;
  }

  int _asIntInRange(Expression expr, int low, int high) {
    if (expr is IntLiteral) {
      if (expr.value >= low && expr.value <= high) return expr.value;
      return null;
    }
    if (_constants.isConstant(expr)) {
      var c = _constants.evaluate(expr);
      if (c is IntConstant && c.value >= low && c.value <= high) return c.value;
    }
    return null;
  }

  bool _isDefinitelyNonNegative(Expression expr) {
    if (expr is IntLiteral) return expr.value >= 0;

    // TODO(sra): Lengths of known list types etc.
    return expr is InvocationExpression && _nodeIsBitwiseOperation(expr);
  }

  /// Does the parent of [node] mask the result to [width] bits or fewer?
  bool _parentMasksToWidth(Expression node, int width) {
    var parent = node.parent;
    if (parent == null) return false;
    if (parent is InvocationExpression && _nodeIsBitwiseOperation(parent)) {
      if (parent.name.name == '&' && parent.arguments.positional.length == 1) {
        var left = getInvocationReceiver(parent);
        var right = parent.arguments.positional[0];
        final int MAX = (1 << width) - 1;
        if (left != null) {
          if (_asIntInRange(right, 0, MAX) != null) return true;
          if (_asIntInRange(left, 0, MAX) != null) return true;
        }
      }
      return _parentMasksToWidth(parent, width);
    }
    return false;
  }

  /// Determines if the result of evaluating [expr] will be an non-negative
  /// value that fits in 31 bits.
  bool _is31BitUnsigned(Expression expr) {
    const int MAX = 32; // Includes larger and negative values.
    /// Determines how many bits are required to hold result of evaluation
    /// [expr].  [depth] is used to bound exploration of huge expressions.
    int bitWidth(Expression expr, int depth) {
      if (expr is IntLiteral) {
        return expr.value >= 0 ? expr.value.bitLength : MAX;
      }
      if (++depth > 5) return MAX;
      if (expr is InvocationExpression &&
          expr.arguments.positional.length == 1) {
        var left = getInvocationReceiver(expr);
        var right = expr.arguments.positional[0];
        if (left != null) {
          switch (expr.name.name) {
            case '&':
              return min(bitWidth(left, depth), bitWidth(right, depth));

            case '|':
            case '^':
              return max(bitWidth(left, depth), bitWidth(right, depth));

            case '>>':
              int shiftValue = _asIntInRange(right, 0, 31);
              if (shiftValue != null) {
                int leftWidth = bitWidth(left, depth);
                return leftWidth == MAX ? MAX : max(0, leftWidth - shiftValue);
              }
              return MAX;

            case '<<':
              int leftWidth = bitWidth(left, depth);
              int shiftValue = _asIntInRange(right, 0, 31);
              if (shiftValue != null) {
                return min(MAX, leftWidth + shiftValue);
              }
              int rightWidth = bitWidth(right, depth);
              if (rightWidth <= 5) {
                // e.g.  `1 << (x & 7)` has a rightWidth of 3, so shifts by up to
                // (1 << 3) - 1 == 7 bits.
                return min(MAX, leftWidth + ((1 << rightWidth) - 1));
              }
              return MAX;
            default:
              return MAX;
          }
        }
      }
      int value = _asIntInRange(expr, 0, 0x7fffffff);
      if (value != null) return value.bitLength;
      return MAX;
    }

    return bitWidth(expr, 0) < 32;
  }

  JS.Expression _emitBinaryOperator(Expression left, Member target,
      Expression right, InvocationExpression node) {
    var op = node.name.name;
    if (op == '==') return _emitEqualityOperator(left, target, right);

    // TODO(jmesserly): using the target type here to work around:
    // https://github.com/dart-lang/sdk/issues/33293
    if (target != null) {
      var targetClass = target.enclosingClass;
      var leftType = targetClass.rawType;
      var rightType = right.getStaticType(types);

      if (_typeRep.binaryOperationIsPrimitive(leftType, rightType) ||
          leftType == types.stringType && op == '+') {
        // Inline operations on primitive types where possible.
        // TODO(jmesserly): inline these from dart:core instead of hardcoding
        // the implementation details here.

        /// Emits an inlined binary operation using the JS [code], adding null
        /// checks if needed to ensure we throw the appropriate error.
        JS.Expression binary(String code) {
          return js.call(code, [notNull(left), notNull(right)]);
        }

        JS.Expression bitwise(String code) {
          return _coerceBitOperationResultToUnsigned(node, binary(code));
        }

        /// Similar to [binary] but applies a boolean conversion to the right
        /// operand, to match the boolean bitwise operators in dart:core.
        ///
        /// Short circuiting operators should not be used in [code], because the
        /// null checks for both operands must happen unconditionally.
        JS.Expression bitwiseBool(String code) {
          return js.call(code, [notNull(left), _visitTest(right)]);
        }

        switch (op) {
          case '~/':
            // `a ~/ b` is equivalent to `(a / b).truncate()`
            return js.call('(# / #).#()', [
              notNull(left),
              notNull(right),
              _emitMemberName('truncate', memberClass: targetClass)
            ]);

          case '%':
            // TODO(sra): We can generate `a % b + 0` if both are non-negative
            // (the `+ 0` is to coerce -0.0 to 0).
            return _emitOperatorCall(left, target, op, [right]);

          case '&':
            return _typeRep.isBoolean(leftType)
                ? bitwiseBool('!!(# & #)')
                : bitwise('# & #');

          case '|':
            return _typeRep.isBoolean(leftType)
                ? bitwiseBool('!!(# | #)')
                : bitwise('# | #');

          case '^':
            return _typeRep.isBoolean(leftType)
                ? bitwiseBool('# !== #')
                : bitwise('# ^ #');

          case '>>':
            int shiftCount = _asIntInRange(right, 0, 31);
            if (_is31BitUnsigned(left) && shiftCount != null) {
              return binary('# >> #');
            }
            if (_isDefinitelyNonNegative(left) && shiftCount != null) {
              return binary('# >>> #');
            }
            // If the context selects out only bits that can't be affected by the
            // sign position we can use any JavaScript shift, `(x >> 6) & 3`.
            if (shiftCount != null &&
                _parentMasksToWidth(node, 31 - shiftCount)) {
              return binary('# >> #');
            }
            return _emitOperatorCall(left, target, op, [right]);

          case '<<':
            if (_is31BitUnsigned(node)) {
              // Result is 31 bit unsigned which implies the shift count was small
              // enough not to pollute the sign bit.
              return binary('# << #');
            }
            if (_asIntInRange(right, 0, 31) != null) {
              return _coerceBitOperationResultToUnsigned(
                  node, binary('# << #'));
            }
            return _emitOperatorCall(left, target, op, [right]);

          default:
            // TODO(vsm): When do Dart ops not map to JS?
            return binary('# $op #');
        }
      }
    }

    return _emitOperatorCall(left, target, op, [right]);
  }

  JS.Expression _emitEqualityOperator(
      Expression left, Member target, Expression right,
      {bool negated = false}) {
    var targetClass = target?.enclosingClass;
    var leftType = targetClass?.rawType ?? left.getStaticType(types);

    // Conceptually `x == y` in Dart is defined as:
    //
    // If either x or y is null, then they are equal iff they are both null.
    // Otherwise, equality is the result of calling `x.==(y)`.
    //
    // In practice, `x.==(y)` is equivalent to `identical(x, y)` in many cases:
    // - when either side is known to be `null` (literal or Null type)
    // - left side is an enum
    // - left side is a primitive type
    //
    // We also compile `operator ==` methods to ensure they check the right side
    // for null`. This allows us to skip the check at call sites.
    //
    // TODO(leafp,jmesserly): we could use class hierarchy analysis to check
    // if `operator ==` was overridden, similar to how we devirtualize private
    // fields.
    //
    // If we know that the left type uses identity for equality, we can
    // sometimes emit better code, either `===` or `==`.
    var isEnum = leftType is InterfaceType && leftType.classNode.isEnum;
    var usesIdentity = _typeRep.isPrimitive(leftType) ||
        isEnum ||
        _isNull(left) ||
        _isNull(right);

    if (usesIdentity) {
      return _emitCoreIdenticalCall([left, right], negated: negated);
    }

    // If the left side is nullable, we need to use a runtime helper to check
    // for null. We could inline the null check, but it did not seem to have
    // a measurable performance effect (possibly the helper is simple enough to
    // be inlined).
    if (isNullable(left)) {
      return js.call(negated ? '!#.equals(#, #)' : '#.equals(#, #)',
          [runtimeModule, _visitExpression(left), _visitExpression(right)]);
    }

    // Otherwise we emit a call to the == method.
    return js.call(negated ? '!#[#](#)' : '#[#](#)', [
      _visitExpression(left),
      _emitMemberName('==', memberClass: targetClass),
      _visitExpression(right)
    ]);
  }

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  JS.Expression _emitOperatorCall(
      Expression receiver, Member target, String name, List<Expression> args) {
    // TODO(jmesserly): calls that don't pass `element` are probably broken for
    // `super` calls from disallowed super locations.
    var memberName = _emitMemberName(name, member: target);
    if (target == null) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return runtimeCall('$dynamicHelper(#, #)',
            [_visitExpression(receiver), _visitExpressionList(args)]);
      } else {
        return runtimeCall('dsend(#, #, [#])', [
          _visitExpression(receiver),
          memberName,
          _visitExpressionList(args)
        ]);
      }
    }

    // Generic dispatch to a statically known method.
    return js.call('#.#(#)',
        [_visitExpression(receiver), memberName, _visitExpressionList(args)]);
  }

  // TODO(jmesserly): optimize super operators for kernel
  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    var target = node.interfaceTarget;
    return JS.Call(_emitSuperTarget(target),
        _emitArgumentList(node.arguments, target: target));
  }

  /// Emits the [JS.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  JS.PropertyAccess _emitSuperTarget(Member member, {bool setter = false}) {
    var jsName = _emitMemberName(member.name.name, member: member);
    if (member is Field && !virtualFields.isVirtual(member)) {
      return JS.PropertyAccess(JS.This(), jsName);
    }
    if (_superAllowed) return JS.PropertyAccess(JS.Super(), jsName);

    // If we can't emit `super` in this context, generate a helper that does it
    // for us, and call the helper.
    var name = member.name.name;
    var jsMethod = _superHelpers.putIfAbsent(name, () {
      var isAccessor = member is Procedure ? member.isAccessor : true;
      if (isAccessor) {
        assert(member is Procedure
            ? member.isSetter == setter
            : !setter || !(member as Field).isFinal);
        var fn = js.fun(
            setter
                ? 'function(x) { super[#] = x; }'
                : 'function() { return super[#]; }',
            [jsName]);

        return JS.Method(JS.TemporaryId(name), fn,
            isGetter: !setter, isSetter: setter);
      } else {
        var function = member.function;
        var params = _emitTypeFormals(function.typeParameters);
        for (var param in function.positionalParameters) {
          params.add(JS.Identifier(param.name));
        }
        if (function.namedParameters.isNotEmpty) {
          params.add(namedArgumentTemp);
        }

        var fn = js.fun(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        name = JS.friendlyNameForDartOperator[name] ?? name;
        return JS.Method(JS.TemporaryId(name), fn);
      }
    });
    return JS.PropertyAccess(JS.This(), jsMethod.name);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    var target = node.target;
    if (isInlineJS(target)) return _emitInlineJSCode(node) as JS.Expression;
    if (target.isFactory) return _emitFactoryInvocation(node);

    // Optimize some internal SDK calls.
    if (isSdkInternalRuntime(target.enclosingLibrary) &&
        node.arguments.positional.length == 1) {
      var name = target.name.name;
      var firstArg = node.arguments.positional[0];
      if (name == 'getGenericClass' && firstArg is TypeLiteral) {
        var type = firstArg.type;
        if (type is InterfaceType) {
          return _emitTopLevelNameNoInterop(type.classNode, suffix: '\$');
        }
      }
      if (name == 'unwrapType' && firstArg is TypeLiteral) {
        return _emitType(firstArg.type);
      }
      if (name == 'extensionSymbol' && firstArg is StringLiteral) {
        return _getExtensionSymbolInternal(firstArg.value);
      }
    }
    if (target == coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(node.arguments.positional);
    }
    if (_isDebuggerCall(target)) {
      return _emitDebuggerCall(node) as JS.Expression;
    }

    var fn = _emitStaticTarget(target);
    var args = _emitArgumentList(node.arguments, target: target);
    return JS.Call(fn, args);
  }

  bool _isDebuggerCall(Procedure target) {
    return target.name.name == 'debugger' &&
        target.enclosingLibrary.importUri.toString() == 'dart:developer';
  }

  JS.Node _emitDebuggerCall(StaticInvocation node) {
    var args = node.arguments.named;
    var isStatement = node.parent is ExpressionStatement;
    if (args.isEmpty) {
      // Inline `debugger()` with no arguments, as a statement if possible,
      // otherwise as an immediately invoked function.
      return isStatement
          ? js.statement('debugger;')
          : js.call('(() => { debugger; return true})()');
    }

    // The signature of `debugger()` is:
    //
    //     bool debugger({bool when: true, String message})
    //
    // This code path handles the named arguments `when` and/or `message`.
    // Both must be evaluated in the supplied order, and then `when` is used
    // to decide whether to break or not.
    //
    // We also need to return the value of `when`.
    var jsArgs = args.map(_emitNamedExpression).toList();
    var when = args.length == 1
        // For a single `when` argument, use it.
        //
        // For a single `message` argument, use `{message: ...}`, which
        // coerces to true (the default value of `when`).
        ? (args[0].name == 'when'
            ? jsArgs[0].value
            : JS.ObjectInitializer(jsArgs))
        // If we have both `message` and `when` arguments, evaluate them in
        // order, then extract the `when` argument.
        : js.call('#.when', JS.ObjectInitializer(jsArgs));
    return isStatement
        ? js.statement('if (#) debugger;', when)
        : js.call('# && (() => { debugger; return true })()', when);
  }

  /// Emits the target of a [StaticInvocation], [StaticGet], or [StaticSet].
  JS.Expression _emitStaticTarget(Member target) {
    var c = target.enclosingClass;
    if (c != null) {
      // A static native element should just forward directly to the
      // JS type's member.
      if (target is Procedure && target.isStatic && target.isExternal) {
        var nativeName = _extensionTypes.getNativePeers(c);
        if (nativeName.isNotEmpty) {
          var memberName = getAnnotationName(target, isJSName) ??
              _emitStaticMemberName(target.name.name, target);
          return runtimeCall('global.#.#', [nativeName[0], memberName]);
        }
      }
      return JS.PropertyAccess(_emitStaticClassName(c),
          _emitStaticMemberName(target.name.name, target));
    }
    return _emitTopLevelName(target);
  }

  List<JS.Expression> _emitArgumentList(Arguments node,
      {bool types = true, Member target}) {
    types = types && _reifyGenericFunction(target);
    var args = <JS.Expression>[];
    if (types) {
      for (var typeArg in node.types) {
        args.add(_emitType(typeArg));
      }
    }
    for (var arg in node.positional) {
      if (arg is StaticInvocation &&
          isJSSpreadInvocation(arg.target) &&
          arg.arguments.positional.length == 1) {
        args.add(JS.Spread(_visitExpression(arg.arguments.positional[0])));
      } else {
        args.add(_visitExpression(arg));
      }
    }
    if (node.named.isNotEmpty) {
      args.add(
          JS.ObjectInitializer(node.named.map(_emitNamedExpression).toList()));
    }
    return args;
  }

  JS.Property _emitNamedExpression(NamedExpression arg) {
    return JS.Property(_propertyName(arg.name), _visitExpression(arg.value));
  }

  /// Emits code for the `JS(...)` macro.
  JS.Node _emitInlineJSCode(StaticInvocation node) {
    var args = node.arguments.positional;
    // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
    var code = args[1];
    List<Expression> templateArgs;
    String source;
    if (code is StringConcatenation) {
      if (code.expressions.every((e) => e is StringLiteral)) {
        templateArgs = args.skip(2).toList();
        source = code.expressions.map((e) => (e as StringLiteral).value).join();
      } else {
        if (args.length > 2) {
          throw ArgumentError(
              "Can't mix template args and string interpolation in JS calls: "
              "`$node`");
        }
        templateArgs = <Expression>[];
        source = code.expressions.map((expression) {
          if (expression is StringLiteral) {
            return expression.value;
          } else {
            templateArgs.add(expression);
            return '#';
          }
        }).join();
      }
    } else {
      templateArgs = args.skip(2).toList();
      source = (code as StringLiteral).value;
    }

    // TODO(jmesserly): arguments to JS() that contain type literals evaluate to
    // the raw runtime type instead of the wrapped Type object.
    // We can clean this up by switching to `unwrapType(<type literal>)`, which
    // the compiler will then optimize.
    var wasInForeignJS = _isInForeignJS;
    _isInForeignJS = true;
    var jsArgs = templateArgs.map(_visitExpression).toList();
    _isInForeignJS = wasInForeignJS;

    var result = js.parseForeignJS(source).instantiate(jsArgs);

    assert(result is JS.Expression ||
        result is JS.Statement && node.parent is ExpressionStatement);
    return result;
  }

  bool _isNull(Expression expr) =>
      expr is NullLiteral ||
      expr.getStaticType(types) == coreTypes.nullClass.rawType;

  bool _doubleEqIsIdentity(Expression left, Expression right) {
    // If we statically know LHS or RHS is null we can use ==.
    if (_isNull(left) || _isNull(right)) return true;
    // If the representation of the  two types will not induce conversion in
    // JS then we can use == .
    return !_typeRep.equalityMayConvert(
        left.getStaticType(types), right.getStaticType(types));
  }

  bool _tripleEqIsIdentity(Expression left, Expression right) {
    // If either is non-nullable, then we don't need to worry about
    // equating null and undefined, and so we can use triple equals.
    return !isNullable(left) || !isNullable(right);
  }

  /// Returns true if [expr] can be null, optionally using [localIsNullable]
  /// for locals.
  ///
  /// If [localIsNullable] is not supplied, this will use the known list of
  /// [_notNullLocals].
  bool isNullable(Expression expr) => _nullableInference.isNullable(expr);

  JS.Expression _emitJSDoubleEq(List<JS.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# != #' : '# == #';
    return js.call(op, args);
  }

  JS.Expression _emitJSTripleEq(List<JS.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# !== #' : '# === #';
    return js.call(op, args);
  }

  JS.Expression _emitCoreIdenticalCall(List<Expression> args,
      {bool negated = false}) {
    if (args.length != 2) {
      // Shouldn't happen in typechecked code
      return runtimeCall(
          'throw(Error("compile error: calls to `identical` require 2 args")');
    }
    var left = args[0];
    var right = args[1];
    var jsArgs = [_visitExpression(left), _visitExpression(right)];
    if (_tripleEqIsIdentity(left, right)) {
      return _emitJSTripleEq(jsArgs, negated: negated);
    }
    if (_doubleEqIsIdentity(left, right)) {
      return _emitJSDoubleEq(jsArgs, negated: negated);
    }
    var code = negated ? '!#' : '#';
    return js.call(
        code, JS.Call(_emitTopLevelName(coreTypes.identicalProcedure), jsArgs));
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    var ctor = node.target;
    var args = node.arguments;
    JS.Expression emitNew() {
      return JS.New(_emitConstructorName(node.constructedType, ctor),
          _emitArgumentList(args, types: false));
    }

    return node.isConst ? _emitConst(emitNew) : emitNew();
  }

  JS.Expression _emitFactoryInvocation(StaticInvocation node) {
    var args = node.arguments;
    var ctor = node.target;
    var ctorClass = ctor.enclosingClass;
    if (ctor.isExternal && hasJSInteropAnnotation(ctorClass)) {
      return _emitJSInteropNew(ctor, args);
    }

    var type = ctorClass.typeParameters.isEmpty
        ? ctorClass.rawType
        : InterfaceType(ctorClass, args.types);

    if (isFromEnvironmentInvocation(coreTypes, node)) {
      var value = _constants.evaluate(node);
      if (value is PrimitiveConstant) return value.accept(this);
    }

    if (args.positional.isEmpty &&
        args.named.isEmpty &&
        ctorClass.enclosingLibrary.importUri.scheme == 'dart') {
      // Skip the slow SDK factory constructors when possible.
      switch (ctorClass.name) {
        case 'Map':
        case 'HashMap':
        case 'LinkedHashMap':
          if (ctor.name.name == '') {
            return js.call('new #.new()', _emitMapImplType(type));
          } else if (ctor.name.name == 'identity') {
            return js.call(
                'new #.new()', _emitMapImplType(type, identity: true));
          }
          break;
        case 'Set':
        case 'HashSet':
        case 'LinkedHashSet':
          if (ctor.name.name == '') {
            return js.call('new #.new()', _emitSetImplType(type));
          } else if (ctor.name.name == 'identity') {
            return js.call(
                'new #.new()', _emitSetImplType(type, identity: true));
          }
          break;
        case 'List':
          if (ctor.name.name == '' && type is InterfaceType) {
            return _emitList(type.typeArguments[0], []);
          }
          break;
      }
    }

    JS.Expression emitNew() {
      return JS.Call(_emitConstructorName(type, ctor),
          _emitArgumentList(args, types: false));
    }

    return node.isConst ? _emitConst(emitNew) : emitNew();
  }

  JS.Expression _emitJSInteropNew(Member ctor, Arguments args) {
    var ctorClass = ctor.enclosingClass;
    if (isJSAnonymousType(ctorClass)) return _emitObjectLiteral(args);
    return JS.New(_emitConstructorName(ctorClass.rawType, ctor),
        _emitArgumentList(args, types: false));
  }

  JS.Expression _emitMapImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= _typeRep.isPrimitive(typeArgs[0]);
    var c = identity ? identityHashMapImplClass : linkedHashMapImplClass;
    return _emitType(InterfaceType(c, typeArgs));
  }

  JS.Expression _emitSetImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= _typeRep.isPrimitive(typeArgs[0]);
    var c = identity ? identityHashSetImplClass : linkedHashSetImplClass;
    return _emitType(InterfaceType(c, typeArgs));
  }

  JS.Expression _emitObjectLiteral(Arguments node) {
    var args = _emitArgumentList(node, types: false);
    if (args.isEmpty) return js.call('{}');
    assert(args.single is JS.ObjectInitializer);
    return args.single;
  }

  @override
  visitNot(Not node) {
    var operand = node.operand;
    if (operand is MethodInvocation && operand.name.name == '==') {
      return _emitEqualityOperator(operand.receiver, operand.interfaceTarget,
          operand.arguments.positional[0],
          negated: true);
    } else if (operand is DirectMethodInvocation && operand.name.name == '==') {
      return _emitEqualityOperator(
          operand.receiver, operand.target, operand.arguments.positional[0],
          negated: true);
    } else if (operand is StaticInvocation &&
        operand.target == coreTypes.identicalProcedure) {
      return _emitCoreIdenticalCall(operand.arguments.positional,
          negated: true);
    }

    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    return js.call('!#', _visitTest(operand));
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    // The operands of logical boolean operators are subject to boolean
    // conversion.
    return _visitTest(node);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visitTest(node.condition),
      _visitExpression(node.then),
      _visitExpression(node.otherwise)
    ])
      ..sourceInformation = _nodeStart(node.condition);
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    var parts = <JS.Expression>[];
    for (var e in node.expressions) {
      var jsExpr = _visitExpression(e);
      if (jsExpr is JS.LiteralString && jsExpr.valueWithoutQuotes.isEmpty) {
        continue;
      }
      parts.add(e.getStaticType(types) == types.stringType && !isNullable(e)
          ? jsExpr
          : runtimeCall('str(#)', jsExpr));
    }
    if (parts.isEmpty) return js.string('');
    return JS.Expression.binary(parts, '+');
  }

  @override
  visitIsExpression(IsExpression node) {
    return _emitIsExpression(node.operand, node.type);
  }

  JS.Expression _emitIsExpression(Expression operand, DartType type) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    var lhs = _visitExpression(operand);
    var typeofName = _typeRep.typeFor(type).primitiveTypeOf;
    // Inline primitives other than int (which requires a Math.floor check).
    if (typeofName != null && type != types.intType) {
      return js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      return js.call('#.is(#)', [_emitType(type), lhs]);
    }
  }

  @override
  visitAsExpression(AsExpression node) {
    Expression fromExpr = node.operand;
    var to = node.type;
    var jsFrom = _visitExpression(fromExpr);
    var from = fromExpr.getStaticType(types);

    // If the check was put here by static analysis to ensure soundness, we
    // can't skip it. For example, one could implement covariant generic caller
    // side checks like this:
    //
    //      typedef F<T>(T t);
    //      class C<T> {
    //        F<T> f;
    //        add(T t) {
    //          // required check `t as T`
    //        }
    //      }
    //      main() {
    //        C<Object> c = new C<int>()..f = (int x) => x.isEven;
    //        c.f('hi'); // required check `c.f as F<Object>`
    //        c.add('hi);
    //      }
    //
    var isTypeError = node.isTypeError;
    if (!isTypeError && types.isSubtypeOf(from, to)) return jsFrom;

    // All Dart number types map to a JS double.
    if (_typeRep.isNumber(from) && _typeRep.isNumber(to)) {
      // Make sure to check when converting to int.
      if (from != coreTypes.intClass.rawType &&
          to == coreTypes.intClass.rawType) {
        // TODO(jmesserly): fuse this with notNull check.
        // TODO(jmesserly): this does not correctly distinguish user casts from
        // required-for-soundness casts.
        return runtimeCall('asInt(#)', jsFrom);
      }

      // A no-op in JavaScript.
      return jsFrom;
    }

    return _emitCast(jsFrom, to, implicit: isTypeError);
  }

  JS.Expression _emitCast(JS.Expression expr, DartType type,
      {bool implicit = true}) {
    if (types.isTop(type)) return expr;

    var code = implicit ? '#._check(#)' : '#.as(#)';
    return js.call(code, [_emitType(type), expr]);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    JS.Expression emitSymbol() {
      // TODO(vsm): Handle qualified symbols correctly.
      var last = node.value.split('.').last;
      var name = js.escapedString(node.value, "'");
      if (last.startsWith('_')) {
        var nativeSymbol = emitPrivateNameSymbol(_currentLibrary, last);
        return js.call('new #.new(#, #)', [
          _emitConstructorAccess(privateSymbolClass.rawType),
          name,
          nativeSymbol
        ]);
      } else {
        return js.call('new #.new(#)', [
          _emitConstructorAccess(coreTypes.internalSymbolClass.rawType),
          name
        ]);
      }
    }

    return _emitConst(emitSymbol);
  }

  JS.Expression _cacheConst(JS.Expression expr()) {
    var savedTypeParams = _typeParamInConst;
    _typeParamInConst = [];

    var jsExpr = expr();

    bool usesTypeParams = _typeParamInConst.isNotEmpty;
    _typeParamInConst = savedTypeParams;

    // TODO(jmesserly): if it uses type params we can still hoist it up as far
    // as it will go, e.g. at the level the generic class is defined where type
    // params are available.
    if (_currentFunction == null || usesTypeParams) return jsExpr;

    var temp = JS.TemporaryId('const');
    moduleItems.add(js.statement('let #;', [temp]));
    return js.call('# || (# = #)', [temp, temp, jsExpr]);
  }

  JS.Expression _emitConst(JS.Expression expr()) =>
      _cacheConst(() => runtimeCall('const(#)', expr()));

  @override
  visitTypeLiteral(TypeLiteral node) {
    var typeRep = _emitType(node.type);
    // If the type is a type literal expression in Dart code, wrap the raw
    // runtime type in a "Type" instance.
    return _isInForeignJS ? typeRep : runtimeCall('wrapType(#)', typeRep);
  }

  @override
  visitThisExpression(ThisExpression node) => JS.This();

  @override
  visitRethrow(Rethrow node) {
    return runtimeCall('rethrow(#)', _emitVariableRef(_rethrowParameter));
  }

  @override
  visitThrow(Throw node) =>
      runtimeCall('throw(#)', _visitExpression(node.expression));

  @override
  visitListLiteral(ListLiteral node) {
    var elementType = node.typeArgument;
    if (!node.isConst) {
      return _emitList(elementType, _visitExpressionList(node.expressions));
    }
    return _cacheConst(() =>
        _emitConstList(elementType, _visitExpressionList(node.expressions)));
  }

  @override
  visitSetLiteral(SetLiteral node) {
    if (!node.isConst) {
      var setType = visitInterfaceType(
          InterfaceType(linkedHashSetClass, [node.typeArgument]));
      if (node.expressions.isEmpty) {
        return js.call('#.new()', [setType]);
      }
      return js.call(
          '#.from([#])', [setType, _visitExpressionList(node.expressions)]);
    }
    return _cacheConst(() => runtimeCall('constSet(#, [#])', [
          _emitType(node.typeArgument),
          _visitExpressionList(node.expressions)
        ]));
  }

  JS.Expression _emitConstList(
      DartType elementType, List<JS.Expression> elements) {
    // dart.constList helper internally depends on _interceptors.JSArray.
    _declareBeforeUse(_jsArrayClass);
    return runtimeCall('constList([#], #)', [elements, _emitType(elementType)]);
  }

  JS.Expression _emitList(DartType itemType, List<JS.Expression> items) {
    var list = JS.ArrayInitializer(items);

    // TODO(jmesserly): analyzer will usually infer `List<Object>` because
    // that is the least upper bound of the element types. So we rarely
    // generate a plain `List<dynamic>` anymore.
    if (itemType == const DynamicType()) return list;

    // Call `new JSArray<E>.of(list)`
    var arrayType = InterfaceType(_jsArrayClass, [itemType]);
    return js.call('#.of(#)', [_emitType(arrayType), list]);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    emitEntries() {
      var entries = <JS.Expression>[];
      for (var e in node.entries) {
        entries.add(_visitExpression(e.key));
        entries.add(_visitExpression(e.value));
      }
      return JS.ArrayInitializer(entries);
    }

    if (!node.isConst) {
      var mapType =
          _emitMapImplType(node.getStaticType(types) as InterfaceType);
      if (node.entries.isEmpty) {
        return js.call('new #.new()', [mapType]);
      }
      return js.call('new #.from(#)', [mapType, emitEntries()]);
    }
    return _cacheConst(() => runtimeCall('constMap(#, #, #)',
        [_emitType(node.keyType), _emitType(node.valueType), emitEntries()]));
  }

  @override
  visitAwaitExpression(AwaitExpression node) =>
      JS.Yield(_visitExpression(node.operand));

  @override
  visitFunctionExpression(FunctionExpression node) {
    var fn = _emitArrowFunction(node);
    if (!_reifyFunctionType(node.function)) return fn;
    return _emitFunctionTagged(fn, node.getStaticType(types) as FunctionType);
  }

  JS.ArrowFun _emitArrowFunction(FunctionExpression node) {
    JS.Fun f = _emitFunction(node.function, null);
    JS.Node body = f.body;

    // Simplify `=> { return e; }` to `=> e`
    if (body is JS.Block) {
      JS.Block block = body;
      if (block.statements.length == 1) {
        JS.Statement s = block.statements[0];
        if (s is JS.Block) {
          block = s;
          s = block.statements.length == 1 ? block.statements[0] : null;
        }
        if (s is JS.Return && s.value != null) body = s.value;
      }
    }

    // Convert `function(...) { ... }` to `(...) => ...`
    // This is for readability, but it also ensures correct `this` binding.
    return JS.ArrowFun(f.params, body);
  }

  @override
  visitStringLiteral(StringLiteral node) => js.escapedString(node.value, '"');

  @override
  visitIntLiteral(IntLiteral node) => js.uint64(node.value);

  @override
  visitDoubleLiteral(DoubleLiteral node) => js.number(node.value);

  @override
  visitBoolLiteral(BoolLiteral node) => JS.LiteralBool(node.value);

  @override
  visitNullLiteral(NullLiteral node) => JS.LiteralNull();

  @override
  visitLet(Let node) {
    var v = node.variable;
    var init = _visitExpression(v.initializer);
    var body = _visitExpression(node.body);
    var temp = _tempVariables.remove(v);
    if (temp != null) {
      if (_letVariables != null) {
        init = JS.Assignment(temp, init);
        _letVariables.add(temp);
      } else {
        // TODO(jmesserly): make sure this doesn't happen on any performance
        // critical call path.
        //
        // Annotations on a top-level, non-lazy function type should be the only
        // remaining use.
        return JS.Call(JS.ArrowFun([temp], body), [init]);
      }
    }
    return JS.Binary(',', init, body);
  }

  @override
  visitInstantiation(Instantiation node) {
    return runtimeCall('gbind(#, #)', [
      _visitExpression(node.expression),
      node.typeArguments.map(_emitType).toList()
    ]);
  }

  @override
  visitLoadLibrary(LoadLibrary node) => runtimeCall('loadLibrary()');

  // TODO(jmesserly): DDC loads all libraries eagerly.
  // See
  // https://github.com/dart-lang/sdk/issues/27776
  // https://github.com/dart-lang/sdk/issues/27777
  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) => js.boolean(true);

  bool _reifyFunctionType(FunctionNode f) {
    if (_currentLibrary.importUri.scheme != 'dart') return true;
    var parent = f.parent;

    // SDK libraries can skip reification if they request it.
    reifyFunctionTypes(Expression a) =>
        isBuiltinAnnotation(a, '_js_helper', 'ReifyFunctionTypes');
    while (parent != null) {
      var a = findAnnotation(parent, reifyFunctionTypes);
      if (a is ConstructorInvocation) {
        var args = a.arguments.positional;
        if (args.length == 1) {
          var arg = args[0];
          if (arg is BoolLiteral) return arg.value;
        }
      }
      parent = parent.parent;
    }
    return true;
  }

  bool _reifyTearoff(Member member) {
    return member is Procedure &&
        !member.isAccessor &&
        !member.isFactory &&
        !_isInForeignJS &&
        !usesJSInterop(member) &&
        _reifyFunctionType(member.function);
  }

  /// Returns the name value of the `JSExportName` annotation (when compiling
  /// the SDK), or `null` if there's none. This is used to control the name
  /// under which functions are compiled and exported.
  String getJSExportName(NamedNode n) {
    var library = getLibrary(n);
    if (library == null || library.importUri.scheme != 'dart') return null;

    return getAnnotationName(n, isJSExportNameAnnotation);
  }

  /// If [node] has annotation matching [test] and the first argument is a
  /// string, this returns the string value.
  ///
  /// Calls [findAnnotation] followed by [getNameFromAnnotation].
  String getAnnotationName(NamedNode node, bool test(Expression value)) {
    return _constants.getNameFromAnnotation(findAnnotation(node, test));
  }

  @override
  visitNullConstant(NullConstant node) => JS.LiteralNull();
  @override
  visitBoolConstant(BoolConstant node) => js.boolean(node.value);
  @override
  visitIntConstant(IntConstant node) => js.number(node.value);
  @override
  visitDoubleConstant(DoubleConstant node) => js.number(node.value);
  @override
  visitStringConstant(StringConstant node) => js.escapedString(node.value, '"');

  // DDC does not currently use the non-primivite constant nodes; rather these
  // are emitted via their normal expression nodes.
  @override
  defaultConstant(Constant node) => _emitInvalidNode(node);
  @override
  visitSymbolConstant(node) => defaultConstant(node);
  @override
  visitMapConstant(node) => defaultConstant(node);
  @override
  visitListConstant(node) => defaultConstant(node);
  @override
  visitInstanceConstant(node) => defaultConstant(node);
  @override
  visitTearOffConstant(node) => defaultConstant(node);
  @override
  visitTypeLiteralConstant(node) => defaultConstant(node);
  @override
  visitPartialInstantiationConstant(node) => defaultConstant(node);
  @override
  visitUnevaluatedConstant(node) => defaultConstant(node);
}

bool isSdkInternalRuntime(Library l) =>
    l.importUri.toString() == 'dart:_runtime';

/// Choose a canonical name from the [library] element.
///
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(Library library) {
  var uri = library.importUri;
  if (uri.scheme == 'dart') return uri.path;

  // TODO(vsm): This is not necessarily unique if '__' appears in a file name.
  Iterable<String> segments;
  if (uri.scheme == 'package') {
    // Strip the package name.
    // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
    // E.g., "foo/bar.dart" and "foo__bar.dart" would collide.
    segments = uri.pathSegments.skip(1);
  } else {
    // TODO(jmesserly): this is not unique typically.
    segments = [uri.pathSegments.last];
  }

  var qualifiedPath = segments.map((p) => p == '..' ? '' : p).join('__');
  return pathToJSIdentifier(qualifiedPath);
}

/// Shorthand for identifier-like property names.
/// For now, we emit them as strings and the printer restores them to
/// identifiers if it can.
// TODO(jmesserly): avoid the round tripping through quoted form.
JS.LiteralString _propertyName(String name) => js.string(name, "'");

bool _isInlineJSFunction(Statement body) {
  var block = body;
  if (block is Block) {
    var statements = block.statements;
    if (statements.length != 1) return false;
    body = statements[0];
  }
  if (body is ReturnStatement) {
    var expr = body.expression;
    return expr is StaticInvocation && isInlineJS(expr.target);
  }
  return false;
}

/// Return true if this is one of the methods/properties on all Dart Objects
/// (toString, hashCode, noSuchMethod, runtimeType).
///
/// Operator == is excluded, as it is handled as part of the equality binary
/// operator.
bool isObjectMember(String name) {
  // We could look these up on Object, but we have hard coded runtime helpers
  // so it's not really providing any benefit.
  switch (name) {
    case 'hashCode':
    case 'toString':
    case 'noSuchMethod':
    case 'runtimeType':
    case '==':
      return true;
  }
  return false;
}

bool _isObjectMethodTearoff(String name) =>
    name == 'toString' || name == 'noSuchMethod';

bool _isObjectMethodCall(String name, Arguments args) {
  if (name == 'toString') {
    return args.positional.isEmpty && args.named.isEmpty && args.types.isEmpty;
  } else if (name == 'noSuchMethod') {
    return args.positional.length == 1 &&
        args.named.isEmpty &&
        args.types.isEmpty;
  }
  return false;
}
