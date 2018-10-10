// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show min, max;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart' show StringToken;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/constant.dart'
    show DartObject, DartObjectImpl;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, NamespaceBuilder;
import 'package:analyzer/src/generated/type_system.dart'
    show StrongTypeSystemImpl;
import 'package:analyzer/src/summary/idl.dart' show UnlinkedUnit;
import 'package:analyzer/src/summary/link.dart' as summary_link;
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart'
    show serializeAstUnlinked;
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/strong/ast_properties.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart' show SourceLocation;

import '../compiler/js_metalet.dart' as JS;
import '../compiler/js_names.dart' as JS;
import '../compiler/js_utils.dart' as JS;
import '../compiler/module_builder.dart' show pathToJSIdentifier;
import '../compiler/shared_compiler.dart';
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show NodeEnd, NodeSpan, HoverComment;
import 'ast_builder.dart';
import 'element_helpers.dart';
import 'error_helpers.dart';
import 'extension_types.dart' show ExtensionTypeSet;
import 'js_interop.dart';
import 'js_typerep.dart';
import 'module_compiler.dart' show CompilerOptions, JSModuleFile;
import 'nullable_type_inference.dart' show NullableTypeInference;
import 'property_model.dart';
import 'reify_coercions.dart' show CoercionReifier;
import 'side_effect_analysis.dart'
    show ConstFieldVisitor, isStateless, isPotentiallyMutated;
import 'type_utilities.dart';

/// The code generator for Dart Dev Compiler.
///
/// Takes as input resolved Dart ASTs for every compilation unit in every
/// library in the module. Produces a single JavaScript AST for the module as
// output, along with its source map.
///
/// This class attempts to preserve identifier names and structure of the input
/// Dart code, whenever this is possible to do in the generated code.
///
// TODO(jmesserly): we should use separate visitors for statements and
// expressions. Declarations are handled directly, and many minor component
// AST nodes aren't visited, so the visitor pattern isn't helping except for
// expressions (which result in JS.Expression) and statements
// (which result in (JS.Statement).
class CodeGenerator extends Object
    with NullableTypeInference, SharedCompiler<LibraryElement>
    implements AstVisitor<JS.Node> {
  final AnalysisContext context;
  final SummaryDataStore summaryData;

  final CompilerOptions options;
  final StrongTypeSystemImpl rules;

  /// Errors that were produced during compilation, if any.
  final List<AnalysisError> errors;

  JSTypeRep jsTypeRep;

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  ///
  /// We sometimes special case codegen for a single library, as it simplifies
  /// name scoping requirements.
  final _libraries = Map<LibraryElement, JS.Identifier>();

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = Map<LibraryElement, JS.TemporaryId>();

  /// The list of dart:_runtime SDK functions; these are assumed by other code
  /// in the SDK to be generated before anything else.
  final _internalSdkFunctions = <JS.ModuleItem>[];

  /// Table of named and possibly hoisted types.
  TypeTable _typeTable;

  /// The global extension type table.
  final ExtensionTypeSet _extensionTypes;

  /// The variable for the target of the current `..` cascade expression.
  ///
  /// Usually a [SimpleIdentifier], but it can also be other expressions
  /// that are safe to evaluate multiple times, such as `this`.
  Expression _cascadeTarget;

  /// The variable for the current catch clause
  SimpleIdentifier _catchParameter;

  /// In an async* function, this represents the stream controller parameter.
  JS.TemporaryId _asyncStarController;

  final _initializingFormalTemps = HashMap<ParameterElement, JS.TemporaryId>();

  JS.Identifier _extensionSymbolsModule;
  final _extensionSymbols = Map<String, JS.TemporaryId>();

  /// The  type provider from the current Analysis [context].
  final TypeProvider types;

  final LibraryElement coreLibrary;
  final LibraryElement dartJSLibrary;

  /// The dart:async `StreamIterator<T>` type.
  final InterfaceType _asyncStreamIterator;

  /// The dart:core `identical` element.
  final FunctionElement _coreIdentical;

  /// Classes and types defined in the SDK.
  final ClassElement _jsArray;
  final ClassElement boolClass;
  final ClassElement intClass;
  final ClassElement doubleClass;
  final ClassElement interceptorClass;
  final ClassElement nullClass;
  final ClassElement numClass;
  final ClassElement objectClass;
  final ClassElement stringClass;
  final ClassElement functionClass;
  final ClassElement privateSymbolClass;
  final InterfaceType linkedHashMapImplType;
  final InterfaceType identityHashMapImplType;
  final InterfaceType linkedHashSetImplType;
  final InterfaceType identityHashSetImplType;
  final InterfaceType syncIterableType;
  final InterfaceType asyncStarImplType;

  ConstFieldVisitor _constants;

  /// The current function body being compiled.
  FunctionBody _currentFunction;

  Map<TypeDefiningElement, AstNode> _declarationNodes;

  /// The class that's currently emitting top-level (module-level) JS code.
  ///
  /// This is primarily used to forward declare classes so they are available
  /// to JS class `extends`.
  ///
  /// This is not set when inside method bodies, because they are run after we
  /// load modules, so they can freely access all classes.
  TypeDefiningElement _topLevelClass;

  /// The current element being loaded.
  /// We can use this to determine if we're loading top-level code or not:
  ///
  ///     _currentElement == _topLevelClass
  ///
  /// This is also used to find the current compilation unit for emitting source
  /// mappings.
  Element _currentElement;

  final _deferredProperties = HashMap<PropertyAccessorElement, JS.Method>();

  String _libraryRoot;

  bool _superAllowed = true;

  final _superHelpers = Map<String, JS.Method>();

  List<TypeParameterType> _typeParamInConst;

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  final virtualFields = VirtualFieldModel();

  final _usedCovariantPrivateMembers = HashSet<ExecutableElement>();

  CodeGenerator(AnalysisContext c, this.summaryData, this.options,
      this._extensionTypes, this.errors)
      : context = c,
        rules = StrongTypeSystemImpl(c.typeProvider),
        types = c.typeProvider,
        _asyncStreamIterator = getClass(c, 'dart:async', 'StreamIterator').type,
        _coreIdentical = _getLibrary(c, 'dart:core')
            .publicNamespace
            .get('identical') as FunctionElement,
        _jsArray = getClass(c, 'dart:_interceptors', 'JSArray'),
        interceptorClass = getClass(c, 'dart:_interceptors', 'Interceptor'),
        coreLibrary = _getLibrary(c, 'dart:core'),
        boolClass = getClass(c, 'dart:core', 'bool'),
        intClass = getClass(c, 'dart:core', 'int'),
        doubleClass = getClass(c, 'dart:core', 'double'),
        numClass = getClass(c, 'dart:core', 'num'),
        nullClass = getClass(c, 'dart:core', 'Null'),
        objectClass = getClass(c, 'dart:core', 'Object'),
        stringClass = getClass(c, 'dart:core', 'String'),
        functionClass = getClass(c, 'dart:core', 'Function'),
        privateSymbolClass = getClass(c, 'dart:_js_helper', 'PrivateSymbol'),
        linkedHashMapImplType =
            getClass(c, 'dart:_js_helper', 'LinkedMap').type,
        identityHashMapImplType =
            getClass(c, 'dart:_js_helper', 'IdentityMap').type,
        linkedHashSetImplType = getClass(c, 'dart:collection', '_HashSet').type,
        identityHashSetImplType =
            getClass(c, 'dart:collection', '_IdentityHashSet').type,
        syncIterableType = getClass(c, 'dart:_js_helper', 'SyncIterable').type,
        asyncStarImplType = getClass(c, 'dart:async', '_AsyncStarImpl').type,
        dartJSLibrary = _getLibrary(c, 'dart:js') {
    jsTypeRep = JSTypeRep(rules, c);
  }

  LibraryElement get currentLibrary => _currentElement.library;

  Uri get currentLibraryUri => _currentElement.librarySource.uri;

  CompilationUnitElement get _currentCompilationUnit {
    for (var e = _currentElement;; e = e.enclosingElement) {
      if (e is CompilationUnitElement) return e;
    }
  }

  /// The main entry point to JavaScript code generation.
  ///
  /// Takes the metadata for the build unit, as well as resolved trees and
  /// errors, and computes the output module code and optionally the source map.
  JSModuleFile compile(List<CompilationUnit> compilationUnits) {
    _libraryRoot = options.libraryRoot;
    if (!_libraryRoot.endsWith(path.separator)) {
      _libraryRoot += path.separator;
    }

    var name = options.moduleName;
    invalidModule() =>
        JSModuleFile.invalid(name, formatErrors(context, errors), options);

    if (!options.unsafeForceCompile && errors.any(_isFatalError)) {
      return invalidModule();
    }

    try {
      var module = _emitModule(compilationUnits, name);
      if (!options.unsafeForceCompile && errors.any(_isFatalError)) {
        return invalidModule();
      }

      var dartApiSummary = _summarizeModule(compilationUnits);
      return JSModuleFile(
          name, formatErrors(context, errors), options, module, dartApiSummary);
    } catch (e) {
      if (errors.any(_isFatalError)) {
        // Force compilation failed.  Suppress the exception and report
        // the static errors instead.
        assert(options.unsafeForceCompile);
        return invalidModule();
      }
      rethrow;
    }
  }

  bool _isFatalError(AnalysisError e) {
    if (errorSeverity(context, e) != ErrorSeverity.ERROR) return false;

    // These errors are not fatal in the REPL compile mode as we
    // allow access to private members across library boundaries
    // and those accesses will show up as undefined members unless
    // additional analyzer changes are made to support them.
    // TODO(jacobr): consider checking that the identifier name
    // referenced by the error is private.
    return !options.replCompile ||
        (e.errorCode != StaticTypeWarningCode.UNDEFINED_GETTER &&
            e.errorCode != StaticTypeWarningCode.UNDEFINED_SETTER &&
            e.errorCode != StaticTypeWarningCode.UNDEFINED_METHOD);
  }

  List<int> _summarizeModule(List<CompilationUnit> units) {
    if (!options.summarizeApi) return null;

    if (!units.any((u) => u.declaredElement.source.isInSystemLibrary)) {
      var sdk = context.sourceFactory.dartSdk;
      summaryData.addBundle(
          null,
          sdk is SummaryBasedDartSdk
              ? sdk.bundle
              : (sdk as FolderBasedDartSdk).getSummarySdkBundle());
    }

    var assembler = PackageBundleAssembler();

    var uriToUnit = Map<String, UnlinkedUnit>.fromIterables(
        units.map((u) => u.declaredElement.source.uri.toString()),
        units.map((unit) {
      var unlinked = serializeAstUnlinked(unit);
      assembler.addUnlinkedUnit(unit.declaredElement.source, unlinked);
      return unlinked;
    }));

    summary_link
        .link(
            uriToUnit.keys.toSet(),
            (uri) => summaryData.linkedMap[uri],
            (uri) => summaryData.unlinkedMap[uri] ?? uriToUnit[uri],
            context.declaredVariables.get)
        .forEach(assembler.addLinkedLibrary);

    var bundle = assembler.assemble();
    // Preserve only API-level information in the summary.
    bundle.flushInformative();
    return bundle.toBuffer();
  }

  JS.Program _emitModule(List<CompilationUnit> compilationUnits, String name) {
    if (moduleItems.isNotEmpty) {
      throw StateError('Can only call emitModule once.');
    }

    for (var unit in compilationUnits) {
      _usedCovariantPrivateMembers.addAll(getCovariantPrivateMembers(unit));
    }

    // Transform the AST to make coercions explicit.
    compilationUnits = CoercionReifier.reify(compilationUnits);
    var items = <JS.ModuleItem>[];
    var root = JS.Identifier('_root');
    items.add(js.statement('const # = Object.create(null)', [root]));

    var isBuildingSdk = compilationUnits
        .any((u) => isSdkInternalRuntime(u.declaredElement.library));
    if (isBuildingSdk) {
      // Don't allow these to be renamed when we're building the SDK.
      // There is JS code in dart:* that depends on their names.
      runtimeModule = JS.Identifier('dart');
      _extensionSymbolsModule = JS.Identifier('dartx');
    } else {
      // Otherwise allow these to be renamed so users can write them.
      runtimeModule = JS.TemporaryId('dart');
      _extensionSymbolsModule = JS.TemporaryId('dartx');
    }
    _typeTable = TypeTable(runtimeModule);

    // Initialize our library variables.
    var exports = <JS.NameSpecifier>[];
    void emitLibrary(JS.Identifier id) {
      items.add(js.statement('const # = Object.create(#)', [id, root]));
      exports.add(JS.NameSpecifier(id));
    }

    for (var unit in compilationUnits) {
      var library = unit.declaredElement.library;
      if (unit.declaredElement != library.definingCompilationUnit) continue;

      var libraryTemp = isSdkInternalRuntime(library)
          ? runtimeModule
          : JS.TemporaryId(jsLibraryName(_libraryRoot, library));
      _libraries[library] = libraryTemp;
      emitLibrary(libraryTemp);
    }

    // dart:_runtime has a magic module that holds extension method symbols.
    // TODO(jmesserly): find a cleaner design for this.
    if (isBuildingSdk) emitLibrary(_extensionSymbolsModule);

    items.add(JS.ExportDeclaration(JS.ExportClause(exports)));

    // Collect all class/type Element -> Node mappings
    // in case we need to forward declare any classes.
    _declarationNodes = HashMap<TypeDefiningElement, AstNode>.identity();
    for (var unit in compilationUnits) {
      for (var declaration in unit.declarations) {
        var element = declaration.declaredElement;
        if (element is TypeDefiningElement) {
          _declarationNodes[element] = declaration;
        }
      }
    }
    if (compilationUnits.isNotEmpty) {
      _constants = ConstFieldVisitor(context,
          dummySource: resolutionMap
              .elementDeclaredByCompilationUnit(compilationUnits.first)
              .source);
    }

    // Add implicit dart:core dependency so it is first.
    emitLibraryName(coreLibrary);

    // Visit each compilation unit and emit its code.
    //
    // NOTE: declarations are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    compilationUnits.forEach(visitCompilationUnit);
    assert(_deferredProperties.isEmpty);

    // Visit directives (for exports)
    compilationUnits.forEach(_emitExportDirectives);

    // Declare imports
    _finishImports(items);
    // Initialize extension symbols
    _extensionSymbols.forEach((name, id) {
      JS.Expression value =
          JS.PropertyAccess(_extensionSymbolsModule, _propertyName(name));
      if (isBuildingSdk) {
        value = js.call('# = Symbol(#)', [value, js.string("dartx.$name")]);
      }
      items.add(js.statement('const # = #;', [id, value]));
    });

    _emitDebuggerExtensionInfo(name);

    // Discharge the type table cache variables and
    // hoisted definitions.
    items.addAll(_typeTable.discharge());
    items.addAll(_internalSdkFunctions);

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, moduleItems);

    // Build the module.
    return JS.Program(items, name: options.moduleName);
  }

  void _emitDebuggerExtensionInfo(String name) {
    var properties = <JS.Property>[];
    _libraries.forEach((library, value) {
      // TODO(jacobr): we could specify a short library name instead of the
      // full library uri if we wanted to save space.
      properties.add(JS.Property(
          js.escapedString(jsLibraryDebuggerName(_libraryRoot, library)),
          value));
    });

    // Track the module name for each library in the module.
    // This data is only required for debugging.
    moduleItems.add(js
        .statement('#.trackLibraries(#, #, ${JSModuleFile.sourceMapHoleID});', [
      runtimeModule,
      js.string(name),
      JS.ObjectInitializer(properties, multiline: true)
    ]));
  }

  /// If [e] is a property accessor element, this returns the
  /// (possibly synthetic) field that corresponds to it, otherwise returns [e].
  Element _getNonAccessorElement(Element e) =>
      e is PropertyAccessorElement ? e.variable : e;

  /// Returns the name of [e] but removes trailing `=` from setter names.
  // TODO(jmesserly): it would be nice if Analyzer had something like this.
  // `Element.displayName` is close, but it also normalizes operator names in
  // a way we don't want.
  String _getElementName(Element e) => _getNonAccessorElement(e).name;

  bool _isExternal(Element e) =>
      e is ExecutableElement && e.isExternal ||
      e is PropertyInducingElement &&
          ((e.getter?.isExternal ?? false) || (e.setter?.isExternal ?? false));

  /// Returns true iff this element is a JS interop member.
  ///
  /// The element's library must have `@JS(...)` annotation from `package:js`.
  ///
  /// If the element is a class, it must also be marked with `@JS`. Other
  /// elements, such as class members and top-level functions/accessors, should
  /// be marked `external`.
  //
  // TODO(jmesserly): if the element is a member, shouldn't we check that the
  // class is a JS interop class?
  bool _usesJSInterop(Element e) =>
      e?.library != null &&
      _hasJSInteropAnnotation(e.library) &&
      (_isExternal(e) || e is ClassElement && _hasJSInteropAnnotation(e));

  String _getJSNameWithoutGlobal(Element e) {
    if (!_usesJSInterop(e)) return null;
    var libraryJSName = getAnnotationName(e.library, isPublicJSAnnotation);
    var jsName =
        getAnnotationName(e, isPublicJSAnnotation) ?? _getElementName(e);
    return libraryJSName != null ? '$libraryJSName.$jsName' : jsName;
  }

  JS.PropertyAccess _emitJSInterop(Element e) {
    var jsName = _getJSNameWithoutGlobal(e);
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

  JS.Expression _emitJSInteropStaticMemberName(Element e) {
    if (!_usesJSInterop(e)) return null;
    var name = getAnnotationName(e, isPublicJSAnnotation);
    if (name != null) {
      if (name.contains('.')) {
        throw UnsupportedError(
            'static members do not support "." in their names. '
            'See https://github.com/dart-lang/sdk/issues/27926');
      }
    } else {
      name = _getElementName(e);
    }
    return js.escapedString(name, "'");
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

  String _libraryToModule(LibraryElement library) {
    assert(!_libraries.containsKey(library));
    var source = library.source;
    // TODO(jmesserly): we need to split out HTML.
    if (source.uri.scheme == 'dart') {
      return JS.dartSdkModule;
    }
    var summaryPath = (source as InSummarySource).summaryPath;
    var moduleName = options.summaryModules[summaryPath];
    if (moduleName == null) {
      throw StateError('Could not find module name for library "$library" '
          'from summary path "$summaryPath".');
    }
    return moduleName;
  }

  void _finishImports(List<JS.ModuleItem> items) {
    var modules = Map<String, List<LibraryElement>>();

    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(coreLibrary)) {
      coreModuleName = _libraryToModule(coreLibrary);
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

  /// Called to emit class declarations.
  ///
  /// During the course of emitting one item, we may emit another. For example
  ///
  ///     class D extends B { C m() { ... } }
  ///
  /// Because D depends on B, we'll emit B first if needed. However C is not
  /// used by top-level JavaScript code, so we can ignore that dependency.
  void _emitTypeDeclaration(TypeDefiningElement e) {
    var node = _declarationNodes.remove(e);
    if (node == null) return; // not from this module or already loaded.

    var savedElement = _currentElement;
    _currentElement = e;

    // TODO(jmesserly): this is not really the right place for this.
    // Ideally we do this per function body.
    //
    // We'll need to be consistent about when we're generating functions, and
    // only run this on the outermost function, and not any closures.
    inferNullableTypes(node);

    moduleItems.add(node.accept(this) as JS.ModuleItem);

    _currentElement = savedElement;
  }

  /// To emit top-level module items, we sometimes need to reorder them.
  ///
  /// This function takes care of that, and also detects cases where reordering
  /// failed, and we need to resort to lazy loading, by marking the element as
  /// lazy. All elements need to be aware of this possibility and generate code
  /// accordingly.
  ///
  /// If we are not emitting top-level code, this does nothing, because all
  /// declarations are assumed to be available before we start execution.
  /// See [startTopLevel].
  void _declareBeforeUse(TypeDefiningElement e) {
    if (e == null) return;

    if (_topLevelClass != null && identical(_currentElement, _topLevelClass)) {
      // If the item is from our library, try to emit it now.
      _emitTypeDeclaration(e);
    }
  }

  @override
  visitCompilationUnit(CompilationUnit unit) {
    // NOTE: this method isn't the right place to initialize
    // per-compilation-unit state. Declarations can be visited out of order,
    // this is only to catch things that haven't been emitted yet.
    //
    // See _emitTypeDeclaration.
    var savedElement = _currentElement;
    _currentElement = unit.declaredElement;
    var isInternalSdk = isSdkInternalRuntime(currentLibrary);
    List<VariableDeclaration> fields;
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        inferNullableTypes(declaration);
        var variables = declaration.variables.variables;
        var lazyFields =
            isInternalSdk ? _emitInternalSdkFields(variables) : variables;
        if (lazyFields.isNotEmpty) {
          (fields ??= []).addAll(lazyFields);
        }
        continue;
      }

      if (fields != null) {
        _emitTopLevelFields(fields);
        fields = null;
      }

      var element = declaration.declaredElement;
      if (element is TypeDefiningElement) {
        _emitTypeDeclaration(element);
        continue;
      }

      inferNullableTypes(declaration);
      var item = declaration.accept(this) as JS.ModuleItem;
      if (isInternalSdk && element is FunctionElement) {
        _internalSdkFunctions.add(item);
      } else {
        moduleItems.add(item);
      }
    }

    if (fields != null) _emitTopLevelFields(fields);

    _currentElement = savedElement;
    return null;
  }

  void _emitExportDirectives(CompilationUnit unit) {
    var savedElement = _currentElement;
    for (var directive in unit.directives) {
      _currentElement = directive.element;
      directive.accept(this);
    }
    _currentElement = savedElement;
  }

  @override
  visitLibraryDirective(LibraryDirective node) => null;

  @override
  visitImportDirective(ImportDirective node) {
    // We don't handle imports here.
    //
    // Instead, we collect imports whenever we need to generate a reference
    // to another library. This has the effect of collecting the actually used
    // imports.
    //
    // TODO(jmesserly): if this is a prefixed import, consider adding the prefix
    // as an alias?
    return null;
  }

  @override
  visitPartDirective(PartDirective node) => null;

  @override
  visitPartOfDirective(PartOfDirective node) => null;

  @override
  visitExportDirective(ExportDirective node) {
    ExportElement element = node.element;
    var currentLibrary = element.library;

    var currentNames = currentLibrary.publicNamespace.definedNames;
    var exportedNames =
        NamespaceBuilder().createExportNamespaceForDirective(element);

    // We only need to export main as it is the only method part of the
    // publicly exposed JS API for a library.
    // TODO(jacobr): add a library level annotation indicating that all
    // contents of a library need to be exposed to JS.
    // https://github.com/dart-lang/sdk/issues/26368
    var export = exportedNames.get('main');

    if (export is FunctionElement) {
      // Don't allow redefining names from this library.
      if (currentNames.containsKey(export.name)) return null;

      var name = _emitTopLevelName(export);
      moduleItems.add(js.statement(
          '#.# = #;', [emitLibraryName(currentLibrary), name.selector, name]));
    }
    return null;
  }

  @override
  visitAsExpression(AsExpression node) {
    Expression fromExpr = node.expression;
    var from = getStaticType(fromExpr);
    var to = node.type.type;
    var jsFrom = _visitExpression(fromExpr);

    // If the check was put here by static analysis to ensure soundness, we
    // can't skip it. This happens because of unsound covariant generics:
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
    // NOTE: due to implementation details, we do not currently reify the the
    // `C<T>.add` check in CoercionReifier, so it does not reach this point;
    // rather we check for it explicitly when emitting methods and fields.
    // However we do reify the `c.f` check, so we must not eliminate it.
    var isImplicit = CoercionReifier.isImplicit(node);
    if (!isImplicit && rules.isSubtypeOf(from, to)) return jsFrom;

    // Handle implicit tearoff of the `.call` method.
    //
    // TODO(jmesserly): this is handled here rather than in CoercionReifier, in
    // hopes that we can remove that extra visit and tree cloning step (which
    // has been error prone because AstCloner isn't used much, and making
    // synthetic resolved Analyzer ASTs is difficult).
    if (isImplicit &&
        from is InterfaceType &&
        rules.acceptsFunctionType(to) &&
        !_usesJSInterop(from.element)) {
      // Dart allows an implicit coercion from an interface type to a function
      // type, via a tearoff of the `call` method.
      var callMethod = from.lookUpInheritedMethod('call');
      if (callMethod != null) {
        var callName = _emitMemberName('call', type: from, element: callMethod);
        var callTearoff = runtimeCall('bindCall(#, #)', [jsFrom, callName]);
        if (rules.isSubtypeOf(callMethod.type, to)) return callTearoff;

        // We may still need an implicit coercion as well, if another downcast
        // is involved.
        return _emitCast(to, callTearoff);
      }
    }

    // All Dart number types map to a JS double.
    if (jsTypeRep.isNumber(from) && jsTypeRep.isNumber(to)) {
      // Make sure to check when converting to int.
      if (from != types.intType && to == types.intType) {
        // TODO(jmesserly): fuse this with notNull check.
        // TODO(jmesserly): this does not correctly distinguish user casts from
        // required-for-soundness casts.
        return runtimeCall('asInt(#)', jsFrom);
      }

      // A no-op in JavaScript.
      return jsFrom;
    }

    return _emitCast(to, jsFrom, implicit: isImplicit);
  }

  JS.Expression _emitCast(DartType type, JS.Expression expr,
      {bool implicit = true}) {
    // If [type] is a top type we can omit the cast.
    if (rules.isSubtypeOf(types.objectType, type)) {
      return expr;
    }
    var code = implicit ? '#._check(#)' : '#.as(#)';
    return js.call(code, [_emitType(type), expr]);
  }

  @override
  visitIsExpression(IsExpression node) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    JS.Expression result;
    var type = node.type.type;
    var lhs = _visitExpression(node.expression);
    var typeofName = jsTypeRep.typeFor(type).primitiveTypeOf;
    // Inline primitives other than int (which requires a Math.floor check).
    if (typeofName != null && type != types.intType) {
      result = js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      result = js.call('#.is(#)', [_emitType(type), lhs]);
    }

    if (node.notOperator != null) {
      return js.call('!#', result);
    }
    return result;
  }

  /// No-op, typedefs are emitted as their corresponding function type.
  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) => null;

  /// No-op, typedefs are emitted as their corresponding function type.
  @override
  visitGenericTypeAlias(GenericTypeAlias node) => null;

  @override
  JS.Expression visitTypeName(node) => _emitTypeAnnotation(node);

  @override
  JS.Expression visitGenericFunctionType(node) => _emitTypeAnnotation(node);

  JS.Expression _emitTypeAnnotation(TypeAnnotation node) {
    var type = node.type;
    if (type == null) {
      // TODO(jmesserly): if the type fails to resolve, should we generate code
      // that throws instead?
      assert(options.unsafeForceCompile || options.replCompile);
      type = types.dynamicType;
    }
    return _emitType(type);
  }

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    return _emitClassDeclaration(
        node, node.declaredElement as ClassElement, []);
  }

  @override
  JS.Statement visitClassDeclaration(ClassDeclaration node) {
    return _emitClassDeclaration(node, node.declaredElement, node.members);
  }

  JS.Statement _emitClassDeclaration(Declaration classNode,
      ClassElement classElem, List<ClassMember> members) {
    // If this class is annotated with `@JS`, then there is nothing to emit.
    if (_hasJSInteropAnnotation(classElem)) return null;

    // Generic classes will be defined inside a function that closes over the
    // type parameter. So we can use their local variable name directly.
    //
    // TODO(jmesserly): the special case for JSArray is to support its special
    // type-tagging factory constructors. Those will go away once we fix:
    // https://github.com/dart-lang/sdk/issues/31003
    var className = classElem.typeParameters.isNotEmpty
        ? (classElem == _jsArray
            ? JS.Identifier(classElem.name)
            : JS.TemporaryId(classElem.name))
        : _emitTopLevelName(classElem);

    var savedClassProperties = _classProperties;
    _classProperties = ClassPropertyModel.build(
        _extensionTypes,
        virtualFields,
        classElem,
        getClassCovariantParameters(classNode),
        _usedCovariantPrivateMembers);

    var memberMap = Map<Element, Declaration>();
    for (var m in members) {
      if (m is FieldDeclaration) {
        for (var f in m.fields.variables) {
          memberMap[f.declaredElement as FieldElement] = f;
        }
      } else {
        memberMap[m.declaredElement] = m;
      }
    }

    var jsCtors =
        _defineConstructors(classElem, className, memberMap, classNode);
    var jsMethods = _emitClassMethods(classElem, members);
    _emitSuperclassCovarianceChecks(classNode, jsMethods);

    var body = <JS.Statement>[];
    _emitSuperHelperSymbols(body);
    var deferredSupertypes = <JS.Statement>[];

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(classElem, className, jsMethods, body, deferredSupertypes);
    body.addAll(jsCtors);

    // Emit things that come after the ES6 `class ... { ... }`.
    var jsPeerNames = _extensionTypes.getNativePeers(classElem);
    if (jsPeerNames.length == 1 && classElem.typeParameters.isNotEmpty) {
      // Special handling for JSArray<E>
      body.add(runtimeStatement('setExtensionBaseClass(#, #.global.#)',
          [className, runtimeModule, jsPeerNames[0]]));
    }

    var finishGenericTypeTest = _emitClassTypeTests(classElem, className, body);

    _emitVirtualFieldSymbols(classElem, body);
    _emitClassSignature(classElem, className, memberMap, body);
    _initExtensionSymbols(classElem);
    if (!classElem.isMixin) {
      _defineExtensionMembers(className, body);
    }
    _emitClassMetadata(classNode.metadata, className, body);

    var classDef = JS.Statement.from(body);
    var typeFormals = classElem.typeParameters;
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(
          classElem, typeFormals, classDef, className, deferredSupertypes);
    } else {
      body.addAll(deferredSupertypes);
    }

    body = [classDef];
    _emitStaticFields(classElem, memberMap, body);
    if (finishGenericTypeTest != null) body.add(finishGenericTypeTest);
    for (var peer in jsPeerNames) {
      _registerExtensionType(classElem, peer, body);
    }

    _classProperties = savedClassProperties;
    return JS.Statement.from(body);
  }

  JS.Statement _emitClassTypeTests(ClassElement classElem,
      JS.Expression className, List<JS.Statement> body) {
    JS.Expression getInterfaceSymbol(ClassElement c) {
      var library = c.library;
      if (library.isDartCore || library.isDartAsync) {
        switch (c.name) {
          case 'List':
          case 'Map':
          case 'Iterable':
          case 'Future':
          case 'Stream':
          case 'StreamSubscription':
            return runtimeCall('is' + c.name);
        }
      }
      return null;
    }

    void markSubtypeOf(JS.Expression testSymbol) {
      body.add(js.statement('#.prototype[#] = true', [className, testSymbol]));
    }

    for (var iface in classElem.interfaces) {
      var prop = getInterfaceSymbol(iface.element);
      if (prop != null) markSubtypeOf(prop);
    }

    if (classElem.library.isDartCore) {
      if (classElem == objectClass) {
        // Everything is an Object.
        body.add(js.statement(
            '#.is = function is_Object(o) { return true; }', [className]));
        body.add(js.statement(
            '#.as = function as_Object(o) { return o; }', [className]));
        body.add(js.statement(
            '#._check = function check_Object(o) { return o; }', [className]));
        return null;
      }
      if (classElem == stringClass) {
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
      if (classElem == functionClass) {
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
            '#._check = function check_Function(o) {'
            '  if (typeof o == "function" || o == null) return o;'
            '  return #.as(o, #, true);'
            '}',
            [className, runtimeModule, className]));
        return null;
      }
      if (classElem == intClass) {
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
      if (classElem == nullClass) {
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
      if (classElem == numClass || classElem == doubleClass) {
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
      if (classElem == boolClass) {
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
    if (classElem.library.isDartAsync) {
      if (classElem == types.futureOrType.element) {
        var typeParamT = classElem.typeParameters[0].type;
        var typeT = _emitType(typeParamT);
        var futureOfT = _emitType(types.futureType.instantiate([typeParamT]));
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

    if (classElem.typeParameters.isEmpty) return null;

    // For generics, testing against the default instantiation is common,
    // so optimize that.
    var isClassSymbol = getInterfaceSymbol(classElem);
    if (isClassSymbol == null) {
      // TODO(jmesserly): we could export these symbols, if we want to mark
      // implemented interfaces for user-defined classes.
      var id = JS.TemporaryId("_is_${classElem.name}_default");
      moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      isClassSymbol = id;
    }
    // Marking every generic type instantiation as a subtype of its default
    // instantiation.
    markSubtypeOf(isClassSymbol);

    // Define the type tests on the default instantiation to check for that
    // marker.
    var defaultInst = _emitTopLevelName(classElem);

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

  void _emitVirtualFieldSymbols(
      ClassElement classElement, List<JS.Statement> body) {
    _classProperties.virtualFields.forEach((field, virtualField) {
      body.add(js.statement('const # = Symbol(#);',
          [virtualField, js.string('${classElement.name}.${field.name}')]));
    });
  }

  List<JS.Identifier> _emitTypeFormals(List<TypeParameterElement> typeFormals) {
    return typeFormals
        .map((t) => JS.Identifier(t.name))
        .toList(growable: false);
  }

  @override
  JS.Statement visitEnumDeclaration(EnumDeclaration node) {
    return _emitClassDeclaration(node, node.declaredElement, []);
  }

  @override
  JS.Statement visitMixinDeclaration(MixinDeclaration node) {
    return _emitClassDeclaration(node, node.declaredElement, node.members);
  }

  /// Wraps a possibly generic class in its type arguments.
  JS.Statement _defineClassTypeArguments(TypeDefiningElement element,
      List<TypeParameterElement> formals, JS.Statement body,
      [JS.Expression className, List<JS.Statement> deferredBaseClass]) {
    assert(formals.isNotEmpty);
    var jsFormals = _emitTypeFormals(formals);
    var typeConstructor = js.call('(#) => { #; #; return #; }', [
      jsFormals,
      _typeTable.discharge(formals),
      body,
      className ?? JS.Identifier(element.name)
    ]);

    var genericArgs = [typeConstructor];
    if (deferredBaseClass != null && deferredBaseClass.isNotEmpty) {
      genericArgs.add(js.call('(#) => { #; }', [jsFormals, deferredBaseClass]));
    }

    var genericCall = runtimeCall('generic(#)', [genericArgs]);

    var genericName = _emitTopLevelNameNoInterop(element, suffix: '\$');
    return js.statement('{ # = #; # = #(); }',
        [genericName, genericCall, _emitTopLevelName(element), genericName]);
  }

  JS.Statement _emitClassStatement(
      ClassElement classElem,
      JS.Expression className,
      JS.Expression heritage,
      List<JS.Method> methods) {
    if (classElem.typeParameters.isNotEmpty) {
      return JS.ClassExpression(className as JS.Identifier, heritage, methods)
          .toStatement();
    }
    var classExpr =
        JS.ClassExpression(JS.TemporaryId(classElem.name), heritage, methods);
    return js.statement('# = #;', [className, classExpr]);
  }

  /// Like [_emitClassStatement] but emits a Dart 2.1 mixin represented by
  /// [classElem].
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
      ClassElement classElem,
      JS.Expression className,
      JS.Expression heritage,
      List<JS.Method> methods,
      List<JS.Statement> body) {
    assert(classElem.isMixin);

    var staticMethods = methods.where((m) => m.isStatic).toList();
    var instanceMethods = methods.where((m) => !m.isStatic).toList();
    body.add(
        _emitClassStatement(classElem, className, heritage, staticMethods));

    var superclassId = JS.TemporaryId(
        classElem.superclassConstraints.map((t) => t.name).join('_'));
    var classId =
        className is JS.Identifier ? className : JS.TemporaryId(classElem.name);

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

  void _defineClass(
      ClassElement classElem,
      JS.Expression className,
      List<JS.Method> methods,
      List<JS.Statement> body,
      List<JS.Statement> deferredSupertypes) {
    if (classElem.type.isObject) {
      body.add(_emitClassStatement(classElem, className, null, methods));
      return;
    }

    JS.Expression emitDeferredType(DartType t) {
      if (t is InterfaceType && t.typeArguments.isNotEmpty) {
        _declareBeforeUse(t.element);
        return _emitGenericClassType(
            t, t.typeArguments.map(emitDeferredType).toList());
      }
      return _emitType(t, cacheType: false);
    }

    bool shouldDefer(DartType t) {
      var visited = Set<DartType>();
      bool defer(DartType t) {
        if (classElem == t.element) return true;
        if (t.isObject) return false;
        if (t is ParameterizedType) {
          if (!visited.add(t)) return false;
          if (t.typeArguments.any(defer)) return true;
          if (t is InterfaceType) {
            var e = t.element;
            if (e.mixins.any(defer)) return true;
            var supertype = e.supertype;
            return supertype != null && defer(supertype);
          }
        }
        return false;
      }

      return defer(t);
    }

    emitClassRef(InterfaceType t) {
      // TODO(jmesserly): investigate this. It seems like `lazyJSType` is
      // invalid for use in an `extends` clause, hence this workaround.
      return _emitJSInterop(t.element) ?? _emitType(t, cacheType: false);
    }

    getBaseClass(int count) {
      var base = emitDeferredType(classElem.type);
      while (--count >= 0) {
        base = js.call('#.__proto__', [base]);
      }
      return base;
    }

    var supertype = classElem.isMixin ? types.objectType : classElem.supertype;
    var hasUnnamedSuper = _hasUnnamedConstructor(supertype.element);

    void emitMixinConstructors(JS.Expression className, [InterfaceType mixin]) {
      var supertype = classElem.supertype;
      JS.Statement mixinCtor;
      if (mixin != null && _hasUnnamedConstructor(mixin.element)) {
        mixinCtor = js.statement('#.#.call(this);', [
          emitClassRef(mixin),
          _usesMixinNew(mixin.element)
              ? runtimeCall('mixinNew')
              : _constructorName('')
        ]);
      }

      for (var ctor in supertype.constructors) {
        var jsParams = _emitParametersForElement(ctor);
        var ctorBody = <JS.Statement>[];
        if (mixinCtor != null) ctorBody.add(mixinCtor);
        if (ctor.name != '' || hasUnnamedSuper) {
          ctorBody
              .add(_emitSuperConstructorCall(className, ctor.name, jsParams));
        }
        body.add(_addConstructorToClass(
            className, ctor.name, JS.Fun(jsParams, JS.Block(ctorBody))));
      }
    }

    var savedTopLevel = _topLevelClass;
    _topLevelClass = classElem;

    // Unroll mixins.
    var mixinLength = classElem.mixins.length;
    if (shouldDefer(supertype)) {
      deferredSupertypes.add(runtimeStatement('setBaseClass(#, #)', [
        getBaseClass(isMixinAliasClass(classElem) ? 0 : mixinLength),
        emitDeferredType(supertype),
      ]));
      supertype = fillDynamicTypeArgsForClass(supertype);
    }
    var baseClass = emitClassRef(supertype);

    // TODO(jmesserly): conceptually we could use isMixinApplication, however,
    // avoiding the extra level of nesting is only required if the class itself
    // is a valid mixin.
    if (isMixinAliasClass(classElem)) {
      // Given `class C = Object with M [implements I1, I2 ...];`
      // The resulting class C should work as a mixin.
      body.add(_emitClassStatement(classElem, className, baseClass, []));

      var m = classElem.mixins.single;
      bool deferMixin = shouldDefer(m);
      var mixinBody = deferMixin ? deferredSupertypes : body;
      var mixinClass = deferMixin ? emitDeferredType(m) : emitClassRef(m);
      var classExpr = deferMixin ? getBaseClass(0) : className;

      mixinBody
          .add(runtimeStatement('applyMixin(#, #)', [classExpr, mixinClass]));

      _topLevelClass = savedTopLevel;

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
              JS.TemporaryId(classElem.name), mixinClass, methods)
        ]));
      }

      emitMixinConstructors(className, m);
      return;
    }

    for (int i = 0; i < mixinLength; i++) {
      var m = classElem.mixins[i];

      var mixinString = classElem.supertype.name + '_' + m.name;
      var mixinClassName = JS.TemporaryId(mixinString);
      var mixinId = JS.TemporaryId(mixinString + '\$');
      var mixinClassExpression =
          JS.ClassExpression(mixinClassName, baseClass, []);
      // Bind the mixin class to a name to workaround a V8 bug with es6 classes
      // and anonymous function names.
      // TODO(leafp:) Eliminate this once the bug is fixed:
      // https://bugs.chromium.org/p/v8/issues/detail?id=7069
      var mixinClassDef =
          js.statement("const # = #", [mixinId, mixinClassExpression]);
      body.add(mixinClassDef);
      // Add constructors

      emitMixinConstructors(mixinId, m);
      hasUnnamedSuper = hasUnnamedSuper || _hasUnnamedConstructor(m.element);

      if (shouldDefer(m)) {
        deferredSupertypes.add(runtimeStatement('applyMixin(#, #)',
            [getBaseClass(mixinLength - i), emitDeferredType(m)]));
      } else {
        body.add(
            runtimeStatement('applyMixin(#, #)', [mixinId, emitClassRef(m)]));
      }

      baseClass = mixinId;
    }

    _topLevelClass = savedTopLevel;

    if (classElem.isMixin) {
      // TODO(jmesserly): we could make this more efficient, as this creates
      // an extra unnecessary class. But it's the easiest way to handle the
      // current system.
      _emitMixinStatement(classElem, className, baseClass, methods, body);
    } else {
      body.add(_emitClassStatement(classElem, className, baseClass, methods));
    }

    if (classElem.isMixinApplication) emitMixinConstructors(className);
  }

  /// Provide Dart getters and setters that forward to the underlying native
  /// field.  Note that the Dart names are always symbolized to avoid
  /// conflicts.  They will be installed as extension methods on the underlying
  /// native type.
  List<JS.Method> _emitNativeFieldAccessors(FieldDeclaration node) {
    // TODO(vsm): Can this by meta-programmed?
    // E.g., dart.nativeField(symbol, jsName)
    // Alternatively, perhaps it could be meta-programmed directly in
    // dart.registerExtensions?
    var jsMethods = <JS.Method>[];
    if (!node.isStatic) {
      for (var decl in node.fields.variables) {
        var field = decl.declaredElement as FieldElement;
        var name = getAnnotationName(field, isJSName) ?? field.name;
        // Generate getter
        var fn = JS.Fun([], js.block('{ return this.#; }', [name]));
        var method =
            JS.Method(_declareMemberName(field.getter), fn, isGetter: true);
        jsMethods.add(method);

        // Generate setter
        if (!decl.isFinal) {
          var value = JS.TemporaryId('value');
          fn = JS.Fun([value], js.block('{ this.# = #; }', [name, value]));
          method =
              JS.Method(_declareMemberName(field.setter), fn, isSetter: true);
          jsMethods.add(method);
        }
      }
    }
    return jsMethods;
  }

  List<JS.Method> _emitClassMethods(
      ClassElement classElem, List<ClassMember> memberNodes) {
    var type = classElem.type;
    var virtualFields = _classProperties.virtualFields;

    var jsMethods = <JS.Method>[];
    bool hasJsPeer = _extensionTypes.isNativeClass(classElem);
    bool hasIterator = false;

    if (type.isObject) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsMethods
          .add(JS.Method(_propertyName('constructor'), js.fun(r'''function() {
                  throw Error("use `new " + #.typeName(#.getReifiedType(this)) +
                      ".new(...)` to create a Dart object");
              }''', [runtimeModule, runtimeModule])));
    } else if (classElem.isEnum) {
      // Generate Enum.toString()
      var fields = classElem.fields.where((f) => f.type == type).toList();
      var mapMap = List<JS.Property>(fields.length);
      for (var i = 0; i < fields.length; ++i) {
        mapMap[i] = JS.Property(
            js.number(i), js.string('${type.name}.${fields[i].name}'));
      }
      jsMethods.add(JS.Method(
          _declareMemberName(types.objectType.getMethod('toString')),
          js.fun('function() { return #[this.index]; }',
              JS.ObjectInitializer(mapMap, multiline: true))));
    }

    for (var m in memberNodes) {
      if (m is ConstructorDeclaration) {
        if (m.factoryKeyword != null &&
            m.externalKeyword == null &&
            m.body is! NativeFunctionBody) {
          jsMethods.add(_emitFactoryConstructor(m));
        }
      } else if (m is MethodDeclaration) {
        jsMethods.add(_emitMethodDeclaration(m));

        if (m.declaredElement is PropertyAccessorElement) {
          jsMethods.add(_emitSuperAccessorWrapper(m, type));
        }

        if (!hasJsPeer && m.isGetter && m.name.name == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(type));
        }
      } else if (m is FieldDeclaration) {
        if (_extensionTypes.isNativeClass(classElem)) {
          jsMethods.addAll(_emitNativeFieldAccessors(m));
          continue;
        }
        if (m.isStatic) continue;
        for (VariableDeclaration field in m.fields.variables) {
          if (virtualFields.containsKey(field.declaredElement)) {
            jsMethods.addAll(_emitVirtualFieldAccessor(field));
          }
        }
      }
    }

    jsMethods.addAll(_classProperties.mockMembers.values
        .map((e) => _implementMockMember(e, type)));

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

    // Add all of the super helper methods
    jsMethods.addAll(_superHelpers.values);

    return jsMethods.where((m) => m != null).toList();
  }

  void _emitSuperclassCovarianceChecks(
      Declaration node, List<JS.Method> methods) {
    var covariantParams = getSuperclassCovariantParameters(node);
    if (covariantParams == null) return;

    for (var member in covariantParams
        .map((p) => p.enclosingElement as ExecutableElement)
        .toSet()) {
      var name = _declareMemberName(member);
      if (member is PropertyAccessorElement) {
        var param =
            covariantParams.lookup(member.parameters[0]) as ParameterElement;
        methods.add(JS.Method(
            name,
            js.fun('function(x) { return super.# = #; }',
                [name, _emitCast(param.type, JS.Identifier('x'))]),
            isSetter: true));
        methods.add(JS.Method(
            name, js.fun('function() { return super.#; }', [name]),
            isGetter: true));
      } else if (member is MethodElement) {
        var type = member.type;

        var body = <JS.Statement>[];
        _emitCovarianceBoundsCheck(type.typeFormals, covariantParams, body);

        var typeFormals = _emitTypeFormals(type.typeFormals);
        var jsParams = List<JS.Parameter>.from(typeFormals);
        bool foundNamedParams = false;
        for (var param in member.parameters) {
          param = covariantParams.lookup(param) as ParameterElement;

          if (param == null) continue;
          if (param.kind == ParameterKind.NAMED) {
            foundNamedParams = true;

            var name = _propertyName(param.name);
            body.add(js.statement('if (# in #) #;', [
              name,
              namedArgumentTemp,
              _emitCast(param.type, JS.PropertyAccess(namedArgumentTemp, name))
            ]));
          } else {
            var jsParam = _emitParameter(param);
            jsParams.add(jsParam);

            if (param.kind == ParameterKind.POSITIONAL) {
              body.add(js.statement('if (# !== void 0) #;',
                  [jsParam, _emitCast(param.type, jsParam)]));
            } else {
              body.add(_emitCast(param.type, jsParam).toStatement());
            }
          }
        }

        if (foundNamedParams) jsParams.add(namedArgumentTemp);

        if (typeFormals.isEmpty) {
          body.add(js.statement('return super.#(#);', [name, jsParams]));
        } else {
          body.add(js.statement(
              'return super.#(#)(#);', [name, typeFormals, jsParams]));
        }
        var fn = JS.Fun(jsParams, JS.Block(body));
        methods.add(JS.Method(name, fn));
      } else {
        throw StateError(
            'unable to generate a covariant check for element: `$member` '
            '(${member.runtimeType})');
      }
    }
  }

  /// Emits a Dart factory constructor to a JS static method.
  JS.Method _emitFactoryConstructor(ConstructorDeclaration node) {
    if (isUnsupportedFactoryConstructor(node)) return null;

    var element = node.declaredElement;
    var name = _constructorName(element.name);
    JS.Fun fun;

    var savedFunction = _currentFunction;
    _currentFunction = node.body;

    var redirect = node.redirectedConstructor;
    if (redirect != null) {
      // Wacky factory redirecting constructors: factory Foo.q(x, y) = Bar.baz;

      var newKeyword = redirect.staticElement.isFactory ? '' : 'new';
      // Pass along all arguments verbatim, and let the callee handle them.
      // TODO(jmesserly): we'll need something different once we have
      // rest/spread support, but this should work for now.
      var params = _emitParameters(node.parameters?.parameters);

      fun = JS.Fun(
          params,
          JS.Block([
            js.statement('return $newKeyword #(#)',
                [visitConstructorName(redirect), params])
              ..sourceInformation = _nodeStart(redirect)
          ]));
    } else {
      // Normal factory constructor
      var body = <JS.Statement>[];
      var init = _emitArgumentInitializers(element, node.parameters);
      if (init != null) body.add(init);
      body.add(_visitStatement(node.body));

      var params = _emitParameters(node.parameters?.parameters);
      fun = JS.Fun(params, JS.Block(body));
    }

    _currentFunction = savedFunction;

    return JS.Method(name, fun, isStatic: true)
      ..sourceInformation = _functionEnd(node);
  }

  /// Given a class C that implements method M from interface I, but does not
  /// declare M, this will generate an implementation that forwards to
  /// noSuchMethod.
  ///
  /// For example:
  ///
  ///     class Cat {
  ///       bool eatFood(String food) => true;
  ///     }
  ///     class MockCat implements Cat {
  ///        noSuchMethod(Invocation invocation) => 3;
  ///     }
  ///
  /// It will generate an `eatFood` that looks like:
  ///
  ///     eatFood(food) {
  ///       return core.bool.as(this.noSuchMethod(
  ///           new dart.InvocationImpl.new('eatFood', [food])));
  ///     }
  JS.Method _implementMockMember(ExecutableElement method, InterfaceType type) {
    var invocationProps = <JS.Property>[];
    addProperty(String name, JS.Expression value) {
      invocationProps.add(JS.Property(js.string(name), value));
    }

    var typeParams = _emitTypeFormals(method.type.typeFormals);
    var fnArgs = List<JS.Parameter>.from(typeParams);
    var args = _emitParametersForElement(method);
    fnArgs.addAll(args);
    var argInit = _emitArgumentInitializers(method);

    if (method is PropertyAccessorElement) {
      if (method.isGetter) {
        addProperty('isGetter', js.boolean(true));
      } else {
        assert(method.isSetter);
        addProperty('isSetter', js.boolean(true));
      }
    } else {
      addProperty('isMethod', js.boolean(true));
    }

    var positionalArgs = args;
    var namedParameterTypes = method.type.namedParameterTypes;
    if (namedParameterTypes.isNotEmpty) {
      // Sort the names to match dart2js order.
      var sortedNames = (namedParameterTypes.keys.toList())..sort();
      var named = sortedNames
          .map((n) => JS.Property(_propertyName(n), JS.Identifier(n)));
      addProperty('namedArguments', JS.ObjectInitializer(named.toList()));
      positionalArgs.removeLast();
    }
    if (typeParams.isNotEmpty) {
      addProperty('typeArguments', JS.ArrayInitializer(typeParams));
    }

    var fnBody =
        js.call('this.noSuchMethod(new #.InvocationImpl.new(#, [#], #))', [
      runtimeModule,
      _declareMemberName(method),
      args,
      JS.ObjectInitializer(invocationProps)
    ]);

    fnBody = _emitCast(method.returnType, fnBody);

    var fnBlock = argInit != null
        ? JS.Block([argInit, fnBody.toReturn()])
        : fnBody.toReturn().toBlock();

    return JS.Method(
        _declareMemberName(method,
            useExtension: _extensionTypes.isNativeClass(type.element)),
        JS.Fun(fnArgs, fnBlock),
        isGetter: method is PropertyAccessorElement && method.isGetter,
        isSetter: method is PropertyAccessorElement && method.isSetter,
        isStatic: false);
  }

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<JS.Method> _emitVirtualFieldAccessor(VariableDeclaration field) {
    var element = field.declaredElement as FieldElement;
    var virtualField = _classProperties.virtualFields[element];
    var result = <JS.Method>[];
    var name = _declareMemberName(element.getter);

    var mocks = _classProperties.mockMembers;
    if (!mocks.containsKey(element.name)) {
      var getter = js.fun('function() { return this[#]; }', [virtualField]);
      result.add(JS.Method(name, getter, isGetter: true)
        ..sourceInformation = _functionSpan(field.name));
    }

    if (!mocks.containsKey(element.name + '=')) {
      var args = field.isFinal ? [JS.Super(), name] : [JS.This(), virtualField];

      var setter = element.setter;
      var covariantParams = _classProperties.covariantParameters;
      JS.Expression value = JS.Identifier('value');
      if (setter != null &&
          covariantParams != null &&
          covariantParams.contains(setter.parameters[0])) {
        value = _emitCast(setter.parameters[0].type, value);
      }
      args.add(value);

      result.add(JS.Method(name, js.fun('function(value) { #[#] = #; }', args),
          isSetter: true)
        ..sourceInformation = _functionSpan(field.name));
    }

    return result;
  }

  /// Emit a getter or setter that simply forwards to the superclass getter or
  /// setter. This is needed because in ES6, if you only override a getter
  /// (alternatively, a setter), then there is an implicit override of the
  /// setter (alternatively, the getter) that does nothing.
  JS.Method _emitSuperAccessorWrapper(
      MethodDeclaration member, InterfaceType type) {
    var accessorElement = member.declaredElement as PropertyAccessorElement;
    var field = accessorElement.variable;
    if (!field.isSynthetic || accessorElement.isAbstract) return null;

    // Generate a corresponding virtual getter / setter.
    var name = _declareMemberName(accessorElement);
    if (member.isGetter) {
      var setter = field.setter;
      if ((setter == null || setter.isAbstract) &&
          _classProperties.inheritedSetters.contains(field.name)) {
        // Generate a setter that forwards to super.
        var fn = js.fun('function(value) { super[#] = value; }', [name]);
        return JS.Method(name, fn, isSetter: true);
      }
    } else {
      var getter = field.getter;
      if ((getter == null || getter.isAbstract) &&
          _classProperties.inheritedGetters.contains(field.name)) {
        // Generate a getter that forwards to super.
        var fn = js.fun('function() { return super[#]; }', [name]);
        return JS.Method(name, fn, isGetter: true);
      }
    }
    return null;
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

    if (t.element.source.isInSystemLibrary &&
        t.methods.any((m) => getJSExportName(m) == 'Symbol.iterator')) {
      return null;
    }

    // Otherwise, emit the adapter method, which wraps the Dart iterator in
    // an ES6 iterator.
    return JS.Method(
        js.call('Symbol.iterator'),
        js.call('function() { return new #.JsIterator(this.#); }',
            [runtimeModule, _emitMemberName('iterator', type: t)]) as JS.Fun);
  }

  JS.Expression _instantiateAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement) {
      return _emitInstanceCreationExpression(
          element,
          element.returnType as InterfaceType,
          () => _emitArgumentList(node.arguments),
          isConst: true);
    } else {
      return _visitExpression(node.name);
    }
  }

  void _registerExtensionType(
      ClassElement classElem, String jsPeerName, List<JS.Statement> body) {
    var className = _emitTopLevelName(classElem);
    if (jsTypeRep.isPrimitive(classElem.type)) {
      body.add(
          runtimeStatement('definePrimitiveHashCode(#.prototype)', className));
    }
    body.add(runtimeStatement(
        'registerExtension(#, #)', [js.string(jsPeerName), className]));
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<JS.Statement> _defineConstructors(
      ClassElement classElem,
      JS.Expression className,
      Map<Element, Declaration> memberMap,
      Declaration classNode) {
    var body = <JS.Statement>[];
    if (classElem.isMixinApplication) {
      // We already handled this when we defined the class.
      return body;
    }

    addConstructor(String name, JS.Expression jsCtor) {
      body.add(_addConstructorToClass(className, name, jsCtor));
    }

    if (classElem.isEnum) {
      addConstructor('', js.call('function(x) { this.index = x; }'));
      return body;
    }

    var fields = List<VariableDeclaration>.from(memberMap.values.where((m) =>
        m is VariableDeclaration &&
        !(m.declaredElement as FieldElement).isStatic));

    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    var defaultCtor = classElem.unnamedConstructor;
    if (defaultCtor != null && defaultCtor.isSynthetic) {
      assert(classElem.constructors.length == 1,
          'default constructor only if no other constructors');
      var superCall = _emitSuperConstructorCallIfNeeded(classElem, className);
      var ctorBody = <JS.Statement>[_initializeFields(fields)];
      if (superCall != null) ctorBody.add(superCall);

      addConstructor(
          '',
          JS.Fun([], JS.Block(ctorBody))
            ..sourceInformation = _functionEnd(classNode));
      return body;
    }

    for (var element in classElem.constructors) {
      if (element.isSynthetic || element.isFactory || element.isExternal) {
        continue;
      }
      var ctor = memberMap[element] as ConstructorDeclaration;
      if (ctor.body is NativeFunctionBody) continue;

      addConstructor(element.name, _emitConstructor(ctor, fields, className));
    }

    // If classElement has only factory constructors, and it can be mixed in,
    // then we need to emit a special hidden default constructor for use by
    // mixins.
    if (_usesMixinNew(classElem)) {
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

  /// If classElement has only factory constructors, and it can be mixed in,
  /// then we need to emit a special hidden default constructor for use by
  /// mixins.
  bool _usesMixinNew(ClassElement mixin) {
    return (mixin.supertype?.isObject ?? false) &&
        mixin.constructors.every((c) =>
            c.isSynthetic && c.name != '' || c.isFactory || c.isExternal);
  }

  JS.Statement _addConstructorToClass(
      JS.Expression className, String name, JS.Expression jsCtor) {
    jsCtor = defineValueOnClass(className, _constructorName(name), jsCtor);
    return js.statement('#.prototype = #.prototype;', [jsCtor, className]);
  }

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(ClassElement classElem,
      Map<Element, Declaration> members, List<JS.Statement> body) {
    if (classElem.isEnum) {
      // Emit enum static fields
      var type = classElem.type;
      void addField(FieldElement e, JS.Expression value) {
        body.add(defineValueOnClass(_emitStaticClassName(classElem),
                _declareMemberName(e.getter), value)
            .toStatement());
      }

      int index = 0;
      var values = <JS.Expression>[];
      for (var f in classElem.fields) {
        if (f.type != type) continue;
        // static const E id_i = const E(i);
        values.add(JS.PropertyAccess(
            _emitStaticClassName(classElem), _declareMemberName(f.getter)));
        var enumValue = runtimeCall('const(new (#.#)(#))', [
          _emitConstructorAccess(type),
          _constructorName(''),
          js.number(index++)
        ]);
        addField(f, enumValue);
      }
      // static const List<E> values = const <E>[id_0 . . . id_n−1];
      addField(classElem.getField('values'), _emitConstList(type, values));
      return;
    }

    var lazyStatics = classElem.fields
        .where((f) => f.isStatic && !f.isSynthetic)
        .map((f) => members[f] as VariableDeclaration)
        .toList();
    if (lazyStatics.isNotEmpty) {
      body.add(_emitLazyFields(_emitStaticClassName(classElem), lazyStatics,
          (e) => _emitStaticMemberName(e.name, e)));
    }
  }

  void _emitClassMetadata(List<Annotation> metadata, JS.Expression className,
      List<JS.Statement> body) {
    // Metadata
    if (options.emitMetadata && metadata.isNotEmpty) {
      body.add(js.statement('#[#.metadata] = () => [#];',
          [className, runtimeModule, metadata.map(_instantiateAnnotation)]));
    }
  }

  /// Ensure `dartx.` symbols we will use are present.
  void _initExtensionSymbols(ClassElement classElem) {
    if (_extensionTypes.hasNativeSubtype(classElem.type) ||
        classElem.type.isObject) {
      for (var members in [classElem.methods, classElem.accessors]) {
        for (var m in members) {
          if (!m.isAbstract && !m.isStatic && m.isPublic) {
            _declareMemberName(m, useExtension: true);
          }
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
  void _emitClassSignature(ClassElement classElem, JS.Expression className,
      Map<Element, Declaration> annotatedMembers, List<JS.Statement> body) {
    if (classElem.interfaces.isNotEmpty ||
        classElem.superclassConstraints.isNotEmpty) {
      var interfaces = classElem.interfaces.toList()
        ..addAll(classElem.superclassConstraints);

      body.add(js.statement('#[#.implements] = () => [#];',
          [className, runtimeModule, interfaces.map(_emitType)]));
    }

    void emitSignature(String name, List<JS.Property> elements) {
      if (elements.isEmpty) return;

      if (!name.startsWith('Static')) {
        var proto = classElem.type.isObject
            ? js.call('Object.create(null)')
            : runtimeCall('get${name}s(#.__proto__)', [className]);
        elements.insert(0, JS.Property(_propertyName('__proto__'), proto));
      }
      body.add(runtimeStatement('set${name}Signature(#, () => #)', [
        className,
        JS.ObjectInitializer(elements, multiline: elements.length > 1)
      ]));
    }

    var mockMembers = _classProperties.mockMembers;

    {
      var extMembers = _classProperties.extensionMethods;
      var staticMethods = <JS.Property>[];
      var instanceMethods = <JS.Property>[];
      var classMethods = classElem.methods.where((m) => !m.isAbstract).toList();
      for (var m in mockMembers.values) {
        if (m is MethodElement) classMethods.add(m);
      }

      for (var method in classMethods) {
        var isStatic = method.isStatic;
        if (isStatic && !options.emitMetadata) continue;

        var name = method.name;
        var reifiedType = _getMemberRuntimeType(method);
        var memberOverride =
            classElem.type.lookUpMethodInSuperclass(name, currentLibrary);
        // Don't add redundant signatures for inherited methods whose signature
        // did not change.  If we are not overriding, or if the thing we are
        // overriding has a different reified type from ourselves, we must
        // emit a signature on this class.  Otherwise we will inherit the
        // signature from the superclass.
        var needsSignature = memberOverride == null ||
            memberOverride.isAbstract ||
            _getMemberRuntimeType(memberOverride) != reifiedType;

        if (needsSignature) {
          var annotationNode = annotatedMembers[method] as MethodDeclaration;

          var type = _emitAnnotatedFunctionType(
              reifiedType, annotationNode?.metadata,
              parameters: annotationNode?.parameters?.parameters);
          var property = JS.Property(_declareMemberName(method), type);
          if (isStatic) {
            staticMethods.add(property);
          } else {
            instanceMethods.add(property);
            if (extMembers.contains(name)) {
              instanceMethods.add(JS.Property(
                  _declareMemberName(method, useExtension: true), type));
            }
          }
        }
      }

      emitSignature('Method', instanceMethods);
      emitSignature('StaticMethod', staticMethods);
    }

    {
      var extMembers = _classProperties.extensionAccessors;
      var staticGetters = <JS.Property>[];
      var instanceGetters = <JS.Property>[];
      var staticSetters = <JS.Property>[];
      var instanceSetters = <JS.Property>[];

      var classAccessors = classElem.accessors
          .where((m) => !m.isAbstract && !m.isSynthetic)
          .toList();
      for (var m in mockMembers.values) {
        if (m is PropertyAccessorElement) classAccessors.add(m);
      }

      for (var accessor in classAccessors) {
        // Static getters/setters cannot be called with dynamic dispatch, nor
        // can they be torn off.
        var isStatic = accessor.isStatic;
        if (isStatic && !options.emitMetadata) continue;

        var name = accessor.name;
        var isGetter = accessor.isGetter;
        var memberOverride = isGetter
            ? classElem.type.lookUpGetterInSuperclass(name, currentLibrary)
            : classElem.type.lookUpSetterInSuperclass(name, currentLibrary);

        var reifiedType = accessor.type;
        // Don't add redundant signatures for inherited methods whose signature
        // did not change.  If we are not overriding, or if the thing we are
        // overriding has a different reified type from ourselves, we must
        // emit a signature on this class.  Otherwise we will inherit the
        // signature from the superclass.
        var needsSignature = memberOverride == null ||
            memberOverride.isAbstract ||
            memberOverride.type != reifiedType;

        if (needsSignature) {
          var annotationNode = annotatedMembers[accessor] as MethodDeclaration;
          var type = _emitAnnotatedResult(
              _emitType(
                  isGetter
                      ? reifiedType.returnType
                      : reifiedType.parameters[0].type,
                  cacheType: false),
              annotationNode?.metadata);

          var property = JS.Property(_declareMemberName(accessor), type);
          if (isStatic) {
            (isGetter ? staticGetters : staticSetters).add(property);
          } else {
            var accessors = isGetter ? instanceGetters : instanceSetters;
            accessors.add(property);
            if (extMembers.contains(accessor.variable.name)) {
              accessors.add(JS.Property(
                  _declareMemberName(accessor, useExtension: true), type));
            }
          }
        }
      }
      emitSignature('Getter', instanceGetters);
      emitSignature('Setter', instanceSetters);
      emitSignature('StaticGetter', staticGetters);
      emitSignature('StaticSetter', staticSetters);
    }

    {
      var instanceFields = <JS.Property>[];
      var staticFields = <JS.Property>[];

      for (var field in classElem.fields) {
        if (field.isSynthetic && !classElem.isEnum) continue;
        // Only instance fields need to be saved for dynamic dispatch.
        var isStatic = field.isStatic;
        if (isStatic && !options.emitMetadata) continue;

        var fieldNode = annotatedMembers[field] as VariableDeclaration;
        var metadata = fieldNode != null
            ? (fieldNode.parent.parent as FieldDeclaration).metadata
            : null;

        var memberName = _declareMemberName(field.getter);
        var fieldSig = _emitFieldSignature(field.type,
            metadata: metadata, isFinal: field.isFinal);
        (isStatic ? staticFields : instanceFields)
            .add(JS.Property(memberName, fieldSig));
      }
      emitSignature('Field', instanceFields);
      emitSignature('StaticField', staticFields);
    }

    if (options.emitMetadata) {
      var constructors = <JS.Property>[];
      for (var ctor in classElem.constructors) {
        var annotationNode = annotatedMembers[ctor] as ConstructorDeclaration;
        var memberName = _constructorName(ctor.name);
        var type = _emitAnnotatedFunctionType(
            ctor.type, annotationNode?.metadata,
            parameters: annotationNode?.parameters?.parameters);
        constructors.add(JS.Property(memberName, type));
      }

      emitSignature('Constructor', constructors);
    }

    // Add static property dart._runtimeType to Object.
    //
    // All other Dart classes will (statically) inherit this property.
    if (classElem == objectClass) {
      body.add(runtimeStatement('lazyFn(#, () => #.#)',
          [className, emitLibraryName(coreLibrary), 'Type']));
    }
  }

  JS.Expression _emitConstructor(ConstructorDeclaration node,
      List<VariableDeclaration> fields, JS.Expression className) {
    var params = _emitParameters(node.parameters?.parameters);

    var savedFunction = _currentFunction;
    _currentFunction = node.body;

    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var body = _emitConstructorBody(node, fields, className);
    _superAllowed = savedSuperAllowed;
    _currentFunction = savedFunction;

    return JS.Fun(params, body)..sourceInformation = _functionEnd(node);
  }

  FunctionType _getMemberRuntimeType(ExecutableElement element) {
    // Check whether we have any covariant parameters.
    // Usually we don't, so we can use the same type.
    if (!element.parameters.any(_isCovariant)) return element.type;

    var parameters = element.parameters
        .map((p) => ParameterElementImpl.synthetic(p.name,
            _isCovariant(p) ? objectClass.type : p.type, p.parameterKind))
        .toList();

    var function = FunctionElementImpl("", -1)
      ..isSynthetic = true
      ..returnType = element.returnType
      // TODO(jmesserly): do covariant type parameter bounds also need to be
      // reified as `Object`?
      ..shareTypeParameters(element.typeParameters)
      ..parameters = parameters;
    return function.type = FunctionTypeImpl(function);
  }

  JS.Expression _constructorName(String name) {
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return _propertyName('new');
    }
    return _emitStaticMemberName(name);
  }

  JS.Block _emitConstructorBody(ConstructorDeclaration node,
      List<VariableDeclaration> fields, JS.Expression className) {
    var body = <JS.Statement>[];
    ClassDeclaration cls = node.parent;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
    var init = _emitArgumentInitializers(node.declaredElement, node.parameters);
    if (init != null) body.add(init);

    // Redirecting constructors: these are not allowed to have initializers,
    // and the redirecting ctor invocation runs before field initializers.
    for (var init in node.initializers) {
      if (init is RedirectingConstructorInvocation) {
        body.add(_emitRedirectingConstructor(init, className));
        return JS.Block(body);
      }
    }

    // Generate field initializers.
    // These are expanded into each non-redirecting constructor.
    // In the future we may want to create an initializer function if we have
    // multiple constructors, but it needs to be balanced against readability.
    body.add(_initializeFields(fields, node));

    var superCall = node.initializers.firstWhere(
        (i) => i is SuperConstructorInvocation,
        orElse: () => null) as SuperConstructorInvocation;

    // If no superinitializer is provided, an implicit superinitializer of the
    // form `super()` is added at the end of the initializer list, unless the
    // enclosing class is class Object.
    var superCallArgs =
        superCall != null ? _emitArgumentList(superCall.argumentList) : null;
    var jsSuper = _emitSuperConstructorCallIfNeeded(cls.declaredElement,
        className, superCall?.staticElement, superCallArgs);
    if (jsSuper != null) {
      if (superCall != null) jsSuper.sourceInformation = _nodeStart(superCall);
      body.add(jsSuper);
    }

    body.add(_emitFunctionScopedBody(node.body, node.declaredElement));
    return JS.Block(body);
  }

  JS.Statement _emitRedirectingConstructor(
      RedirectingConstructorInvocation node, JS.Expression className) {
    var ctor = node.staticElement;
    // We can't dispatch to the constructor with `this.new` as that might hit a
    // derived class constructor with the same name.
    return js.statement('#.#.call(this, #);', [
      className,
      _constructorName(ctor.name),
      _emitArgumentList(node.argumentList)
    ]);
  }

  JS.Statement _emitSuperConstructorCallIfNeeded(
      ClassElement element, JS.Expression className,
      [ConstructorElement superCtor, List<JS.Expression> args]) {
    // Get the supertype's unnamed constructor.
    superCtor ??= element.supertype?.element?.unnamedConstructor;
    if (superCtor == null) {
      assert(element.type.isObject ||
          element.isMixin ||
          options.unsafeForceCompile);
      return null;
    }

    // We can skip the super call if it's empty. Typically this happens for
    // things that extend Object.
    if (superCtor.name == '' && !_hasUnnamedSuperConstructor(element)) {
      return null;
    }

    return _emitSuperConstructorCall(className, superCtor.name, args);
  }

  JS.Statement _emitSuperConstructorCall(
      JS.Expression className, String name, List<JS.Expression> args) {
    return js.statement('#.__proto__.#.call(this, #);',
        [className, _constructorName(name), args ?? []]);
  }

  bool _hasUnnamedSuperConstructor(ClassElement e) {
    var supertype = e.supertype;
    // Object or mixin declaration.
    if (supertype == null) return false;
    if (_hasUnnamedConstructor(supertype.element)) return true;
    for (var mixin in e.mixins) {
      if (_hasUnnamedConstructor(mixin.element)) return true;
    }
    return false;
  }

  bool _hasUnnamedConstructor(ClassElement e) {
    if (e.type.isObject) return false;
    var ctor = e.unnamedConstructor;
    if (ctor == null) return false;
    if (!ctor.isSynthetic) return true;
    if (e.fields.any((f) => !f.isStatic && !f.isSynthetic)) return true;
    return _hasUnnamedSuperConstructor(e);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  JS.Statement _initializeFields(List<VariableDeclaration> fieldDecls,
      [ConstructorDeclaration ctor]) {
    Set<FieldElement> ctorFields;
    emitFieldInit(FieldElement f, Expression initializer, AstNode hoverInfo) {
      ctorFields?.add(f);
      var access =
          _classProperties.virtualFields[f] ?? _declareMemberName(f.getter);
      var jsInit = _visitInitializer(initializer, f);
      return jsInit
          .toAssignExpression(js.call('this.#', [access])
            ..sourceInformation = _nodeSpan(hoverInfo))
          .toStatement();
    }

    var body = <JS.Statement>[];
    if (ctor != null) {
      ctorFields = HashSet<FieldElement>();

      // Run constructor parameter initializers such as `this.foo`
      for (var p in ctor.parameters.parameters) {
        var element = p.declaredElement;
        if (element is FieldFormalParameterElement) {
          body.add(emitFieldInit(element.field, p.identifier, p.identifier));
        }
      }

      // Run constructor field initializers such as `: foo = bar.baz`
      for (var init in ctor.initializers) {
        if (init is ConstructorFieldInitializer) {
          var field = init.fieldName;
          var element = field.staticElement as FieldElement;
          body.add(emitFieldInit(element, init.expression, field));
        } else if (init is AssertInitializer) {
          body.add(_emitAssert(init.condition, init.message));
        }
      }
    }

    // Run field initializers if needed.
    //
    // We can skip fields where the initializer doesn't have side effects
    // (for example, it's a literal value such as implicit `null`) and where
    // there's another explicit initialization (either in the initializer list
    // like `field = value`, or via a `this.field` parameter).
    var fieldInit = <JS.Statement>[];
    for (var field in fieldDecls) {
      var f = field.declaredElement as FieldElement;
      if (f.isStatic) continue;
      if (ctorFields != null &&
          ctorFields.contains(f) &&
          _constants.isFieldInitConstant(field)) {
        continue;
      }
      fieldInit.add(emitFieldInit(f, field.initializer, field.name));
    }
    // Run field initializers before the other ones.
    fieldInit.addAll(body);
    return JS.Statement.from(fieldInit);
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  JS.Statement _emitArgumentInitializers(ExecutableElement element,
      [FormalParameterList parameterNodes]) {
    var body = <JS.Statement>[];

    _emitCovarianceBoundsCheck(
        element.typeParameters, _classProperties?.covariantParameters, body);
    for (int i = 0, n = element.parameters.length; i < n; i++) {
      var param = element.parameters[i];
      var paramNode =
          parameterNodes != null ? parameterNodes.parameters[i] : null;
      var jsParam = _emitParameter(param);
      if (parameterNodes != null) {
        jsParam.sourceInformation = _nodeStart(paramNode.identifier);
      }

      if (param.isOptional) {
        JS.Expression defaultValue;
        if (paramNode != null) {
          var paramDefault = (paramNode as DefaultFormalParameter).defaultValue;
          if (paramDefault == null) {
            defaultValue = JS.LiteralNull();
          } else if (_isJSUndefined(paramDefault)) {
            defaultValue = null;
          } else {
            defaultValue = _visitExpression(paramDefault);
          }
        } else {
          // TODO(jmesserly): it would be cleaner to emit the initializer
          // Expression AST, but it does not seem to be fully resolved
          // (for example, a list literal will not have the list type).
          //
          // So instead we use constant evaluation and emit the constant.
          defaultValue = _emitDartObject(param.computeConstantValue());
        }
        if (param.isNamed) {
          // Parameters will be passed using their real names, not the (possibly
          // renamed) local variable.
          var paramName = js.string(param.name, "'");
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
        } else {
          assert(param.isOptionalPositional);
          if (defaultValue != null) {
            body.add(js.statement(
                'if (# === void 0) # = #;', [jsParam, jsParam, defaultValue]));
          }
        }
      }

      if (_isCovariant(param)) {
        body.add(_emitCast(param.type, jsParam).toStatement());
      }
      if (_annotatedNullCheck(param)) {
        body.add(_nullParameterCheck(jsParam));
      }
    }
    return body.isEmpty ? null : JS.Statement.from(body);
  }

  bool _isCovariant(ParameterElement p) {
    return p.isCovariant ||
        (_classProperties?.covariantParameters?.contains(p) ?? false);
  }

  bool _isJSUndefined(Expression expr) {
    expr = expr is AsExpression ? expr.expression : expr;
    if (expr is Identifier) {
      var element = expr.staticElement;
      return isSdkInternalRuntime(element.library) &&
          element.name == 'undefined';
    }
    return false;
  }

  JS.Fun _emitNativeFunctionBody(MethodDeclaration node) {
    String name = getAnnotationName(node.declaredElement, isJSAnnotation) ??
        node.name.name;
    if (node.isGetter) {
      return JS.Fun([], js.block('{ return this.#; }', [name]));
    } else if (node.isSetter) {
      var params = _emitParameters(node.parameters?.parameters);
      return JS.Fun(params, js.block('{ this.# = #; }', [name, params.last]));
    } else {
      return js.fun(
          'function (...args) { return this.#.apply(this, args); }', name);
    }
  }

  JS.Method _emitMethodDeclaration(MethodDeclaration node) {
    if (node.isAbstract) {
      return null;
    }

    JS.Fun fn;
    if (node.externalKeyword != null || node.body is NativeFunctionBody) {
      if (node.isStatic) {
        // TODO(vsm): Do we need to handle this case?
        return null;
      }
      fn = _emitNativeFunctionBody(node);
    } else {
      fn = _emitFunction(node.declaredElement, node.parameters, node.body);
    }

    return JS.Method(_declareMemberName(node.declaredElement), fn,
        isGetter: node.isGetter,
        isSetter: node.isSetter,
        isStatic: node.isStatic)
      ..sourceInformation = _functionEnd(node);
  }

  @override
  JS.Statement visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.parent is CompilationUnit);

    if (node.externalKeyword != null ||
        node.functionExpression.body is NativeFunctionBody) {
      return null;
    }

    if (node.isGetter || node.isSetter) {
      PropertyAccessorElement element = node.declaredElement;
      var pairAccessor = node.isGetter
          ? element.correspondingSetter
          : element.correspondingGetter;

      var jsCode = _emitTopLevelProperty(node);
      var props = <JS.Method>[jsCode];
      if (pairAccessor != null) {
        // If we have a getter/setter pair, they need to be defined together.
        // If this is the first one, save the generated code for later.
        // If this is the second one, get the saved code and emit both.
        var pairCode = _deferredProperties.remove(pairAccessor);
        if (pairCode == null) {
          _deferredProperties[element] = jsCode;
          return null;
        }
        props.add(pairCode);
      }
      return runtimeStatement(
          'copyProperties(#, { # })', [emitLibraryName(currentLibrary), props]);
    }

    var body = <JS.Statement>[];
    var fn = _emitFunctionExpression(node.functionExpression);

    if (currentLibrary.source.isInSystemLibrary &&
        _isInlineJSFunction(node.functionExpression)) {
      fn = JS.simplifyPassThroughArrowFunCallBody(fn);
    }
    fn.sourceInformation = _functionEnd(node);

    var element = resolutionMap.elementDeclaredByFunctionDeclaration(node);
    var nameExpr = _emitTopLevelName(element);
    body.add(js.statement('# = #', [nameExpr, fn]));
    // Function types of top-level/static functions are only needed when
    // dart:mirrors is enabled.
    // TODO(jmesserly): do we even need this for mirrors, since statics are not
    // commonly reflected on?
    if (options.emitMetadata && _reifyFunctionType(element)) {
      body.add(_emitFunctionTagged(nameExpr, element.type, topLevel: true)
          .toStatement());
    }

    return JS.Statement.from(body);
  }

  bool _isInlineJSFunction(FunctionExpression functionExpression) {
    var body = functionExpression.body;
    if (body is ExpressionFunctionBody) {
      return _isJSInvocation(body.expression);
    } else if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length == 1) {
        var stat = statements[0];
        if (stat is ReturnStatement) {
          return _isJSInvocation(stat.expression);
        }
      }
    }
    return false;
  }

  bool _isJSInvocation(Expression expr) =>
      expr is MethodInvocation && isInlineJS(expr.methodName.staticElement);

  JS.Method _emitTopLevelProperty(FunctionDeclaration node) {
    var name = node.name.name;
    return JS.Method(
        _propertyName(name), _emitFunctionExpression(node.functionExpression),
        isGetter: node.isGetter, isSetter: node.isSetter)
      ..sourceInformation = _functionEnd(node);
  }

  bool _executesAtTopLevel(AstNode node) {
    var ancestor = node.getAncestor((n) =>
        n is FunctionBody ||
        n is FieldDeclaration && n.staticKeyword == null ||
        n is ConstructorDeclaration && n.constKeyword == null);
    return ancestor == null;
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
    if (type is FunctionType) {
      // Generic functions are always safe to emit, because they're lazy until
      // type arguments are applied.
      if (type.typeFormals.isNotEmpty) return true;

      return _canEmitTypeAtTopLevel(type.returnType) &&
          type.optionalParameterTypes.every(_canEmitTypeAtTopLevel) &&
          type.namedParameterTypes.values.every(_canEmitTypeAtTopLevel) &&
          type.normalParameterTypes.every(_canEmitTypeAtTopLevel);
    }
    if (type.isDynamic || type.isVoid || type.isBottom) return true;
    if (type is ParameterizedType &&
        !type.typeArguments.every(_canEmitTypeAtTopLevel)) {
      return false;
    }
    return !_declarationNodes.containsKey(type.element);
  }

  JS.Expression _emitFunctionTagged(JS.Expression fn, FunctionType type,
      {bool topLevel = false}) {
    var lazy = topLevel && !_canEmitTypeAtTopLevel(type);
    var typeRep = _emitFunctionType(type, lazy: lazy);
    return runtimeCall(lazy ? 'lazyFn(#, #)' : 'fn(#, #)', [fn, typeRep]);
  }

  /// Emits an arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears and the function is actually in an Expression context. These
  /// correspond to arrow functions in Dart.
  ///
  /// Contrast with [_emitFunctionExpression].
  @override
  JS.Expression visitFunctionExpression(FunctionExpression node) {
    assert(node.parent is! FunctionDeclaration &&
        node.parent is! MethodDeclaration);
    var fn = _emitArrowFunction(node);
    if (!_reifyFunctionType(node.declaredElement)) return fn;
    return _emitFunctionTagged(fn, getStaticType(node) as FunctionType,
        topLevel: _executesAtTopLevel(node));
  }

  JS.ArrowFun _emitArrowFunction(FunctionExpression node) {
    var f = _emitFunction(node.declaredElement, node.parameters, node.body);
    JS.Node body = f.body;

    // Simplify `=> { return e; }` to `=> e`
    if (body is JS.Block) {
      JS.Block block = body;
      if (block.statements.length == 1) {
        JS.Statement s = block.statements[0];
        if (s is JS.Return && s.value != null) body = s.value;
      }
    }

    // Convert `function(...) { ... }` to `(...) => ...`
    // This is for readability, but it also ensures correct `this` binding.
    return JS.ArrowFun(f.params, body);
  }

  /// Emits a non-arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears but the function is not actually in an Expression context, such
  /// as methods, properties, and top-level functions.
  ///
  /// Contrast with [visitFunctionExpression].
  JS.Fun _emitFunctionExpression(FunctionExpression node) {
    return _emitFunction(node.declaredElement, node.parameters, node.body);
  }

  JS.Fun _emitFunction(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    FunctionType type = element.type;

    // normal function (sync), vs (sync*, async, async*)
    var isSync = !(element.isAsynchronous || element.isGenerator);
    var formals = _emitParameters(parameters?.parameters);
    var typeFormals = _emitTypeFormals(type.typeFormals);
    if (_reifyGeneric(element)) formals.insertAll(0, typeFormals);

    super.enterFunction(
        element.name,
        formals,
        () => isPotentiallyMutated(
            body, parameters.parameters.last.declaredElement));

    JS.Block code = isSync
        ? _emitFunctionBody(element, parameters, body)
        : JS.Block([
            _emitGeneratorFunction(element, parameters, body).toReturn()
              ..sourceInformation = _nodeStart(body)
          ]);

    code = super.exitFunction(element.name, formals, code);
    return JS.Fun(formals, code);
  }

  JS.Block _emitFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    var savedFunction = _currentFunction;
    _currentFunction = body;

    var initArgs = _emitArgumentInitializers(element, parameters);
    var block = _emitFunctionScopedBody(body, element);

    if (initArgs != null) block = JS.Block([initArgs, block]);

    _currentFunction = savedFunction;

    if (block.isScope) {
      // TODO(jmesserly: JS AST printer does not understand the need to emit a
      // nested scoped block in a JS function. So we need to add a non-scoped
      // wrapper to ensure it gets printed.
      block = JS.Block([block]);
    }
    return block;
  }

  JS.Block _emitFunctionScopedBody(
      FunctionBody body, ExecutableElement element) {
    var block = body.accept(this) as JS.Block;
    if (element.parameters.isNotEmpty) {
      // Handle shadowing of parameters by local variables, which is allowed in
      // Dart but not in JS.
      //
      // We need this for all function types, including generator-based ones
      // (sync*/async/async*). Our code generator assumes it can emit names for
      // named argument initialization, and sync* functions also emit locally
      // modified parameters into the function's scope.
      var parameterNames =
          HashSet<String>.from(element.parameters.map((e) => e.name));
      return block.toScopedBlock(parameterNames);
    }
    return block;
  }

  void _emitCovarianceBoundsCheck(List<TypeParameterElement> typeFormals,
      Set<Element> covariantParams, List<JS.Statement> body) {
    if (covariantParams == null) return;
    for (var t in typeFormals) {
      t = covariantParams.lookup(t) as TypeParameterElement;
      if (t != null) {
        body.add(runtimeStatement('checkTypeBound(#, #, #)',
            [_emitType(t.type), _emitType(t.bound), _propertyName(t.name)]));
      }
    }
  }

  JS.Expression _emitGeneratorFunction(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    // Transforms `sync*` `async` and `async*` function bodies
    // using ES6 generators.

    var returnType = _getExpectedReturnType(element);

    emitGeneratorFn(List<JS.Parameter> jsParams, [JS.TemporaryId asyncStar]) {
      var savedSuperAllowed = _superAllowed;
      var savedController = _asyncStarController;
      _superAllowed = false;
      _asyncStarController = asyncStar;

      // Visit the body with our async* controller set.
      //
      // TODO(jmesserly): this will emit argument initializers (for default
      // values) inside the generator function body. Is that the best place?
      var jsBody = _emitFunctionBody(element, parameters, body);
      var genFn = JS.Fun(jsParams, jsBody, isGenerator: true);

      // Name the function if possible, to get better stack traces.
      var name = element.name;
      JS.Expression gen = genFn;
      if (name.isNotEmpty) {
        gen = JS.NamedFunction(
            JS.TemporaryId(JS.friendlyNameForDartOperator[name] ?? name),
            genFn);
      }
      gen.sourceInformation = _functionEnd(body);
      if (JS.This.foundIn(gen)) gen = js.call('#.bind(this)', gen);

      _superAllowed = savedSuperAllowed;
      _asyncStarController = savedController;
      return gen;
    }

    if (element.isSynchronous) {
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
      assert(element.isGenerator);

      var params = parameters?.parameters;

      var jsParams = _emitParameters(
          params?.where((p) => isPotentiallyMutated(body, p.declaredElement)));

      var gen = emitGeneratorFn(jsParams);
      if (jsParams.isNotEmpty) gen = js.call('() => #(#)', [gen, jsParams]);

      var syncIterable = _emitType(syncIterableType.instantiate([returnType]));
      return js.call('new #.new(#)', [syncIterable, gen]);
    }

    if (element.isGenerator) {
      // `async*` uses the `_AsyncStarImpl<T>` helper class. The generator
      // callback takes an instance of this class.
      //
      // `yield` is specially generated inside `async*` by visitYieldStatement.
      // `await` is generated as `yield`.
      //
      // _AsyncStarImpl has an example of the generated code.
      var asyncStarParam = JS.TemporaryId('stream');
      var gen = emitGeneratorFn([asyncStarParam], asyncStarParam);

      var asyncStarImpl = asyncStarImplType.instantiate([returnType]);
      return js.call('new #.new(#).stream', [_emitType(asyncStarImpl), gen]);
    }

    // `async` works similar to `sync*`:
    //
    // function name(<args>) {
    //   return async.async(E, function* name() {
    //     <body>
    //   });
    // }
    //
    // In the body of an `async`, `await` is generated simply as `yield`.
    var gen = emitGeneratorFn([]);
    var dartAsync = types.futureType.element.library;
    return js.call('#.async(#, #)',
        [emitLibraryName(dartAsync), _emitType(returnType), gen]);
  }

  @override
  JS.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    var fn = _emitFunctionExpression(func.functionExpression);

    var name = _emitVariableDef(func.name);
    JS.Statement declareFn;
    if (JS.This.foundIn(fn)) {
      declareFn = js.statement('const # = #.bind(this);', [name, fn]);
    } else {
      declareFn = JS.FunctionDeclaration(name, fn);
    }
    var element = func.declaredElement;
    if (_reifyFunctionType(element)) {
      declareFn = JS.Block(
          [declareFn, _emitFunctionTagged(name, element.type).toStatement()]);
    }
    return declareFn;
  }

  /// Emits a simple identifier, including handling an inferred generic
  /// function instantiation.
  @override
  JS.Expression visitSimpleIdentifier(SimpleIdentifier node,
      [PrefixedIdentifier prefix]) {
    var typeArgs = _getTypeArgs(node.staticElement, node.staticType);
    var simpleId = _emitSimpleIdentifier(node, prefix)
      ..sourceInformation = _nodeSpan(node);
    if (prefix != null &&
        // Check that the JS AST is for a Dart property and not JS interop.
        simpleId is JS.PropertyAccess &&
        simpleId.receiver is JS.Identifier) {
      // Attach the span to the library prefix.
      simpleId.receiver.sourceInformation = _nodeSpan(prefix.prefix);
    }
    if (typeArgs == null) return simpleId;
    return runtimeCall('gbind(#, #)', [simpleId, typeArgs]);
  }

  /// Emits a simple identifier, handling implicit `this` as well as
  /// going through the qualified library name if necessary, but *not* handling
  /// inferred generic function instantiation.
  JS.Expression _emitSimpleIdentifier(SimpleIdentifier node,
      [PrefixedIdentifier prefix]) {
    var accessor = resolutionMap.staticElementForIdentifier(node);
    if (accessor == null) {
      return _throwUnsafe('unresolved identifier: ' + (node.name ?? '<null>'));
    }

    // Get the original declaring element. If we had a property accessor, this
    // indirects back to a (possibly synthetic) field.
    var element = accessor;
    if (accessor is PropertyAccessorElement) element = accessor.variable;

    // If this is one of our compiler's temporary variables, return its JS form.
    if (element is TemporaryVariableElement) {
      return element.jsVariable;
    }

    // As an optimization, directly emit simple constants.
    // (This is not required for correctness.)
    if (element is VariableElement && element.isStatic && element.isConst) {
      var value = element.computeConstantValue() as DartObjectImpl;
      // TODO(jmesserly): value should always be non-null unless the program has
      // errors. However constants seem to be missing in some cases, see:
      // https://github.com/dart-lang/sdk/issues/33885
      //
      // This may be an Analyzer bug. This workaround prevents a compiler crash
      // until we can track down the root cause (or migrate to CFE+Kernel).
      //
      // If the constant is not a primitive (or we fail to evaluate it), then
      // we can fall through and emit a reference to it at runtime.
      //
      // TODO(jmesserly): avoid inlining strings depending on their length.
      if (value != null && value.isBoolNumStringOrNull) {
        var result = _emitDartObject(value);
        if (result != null) return result;
      }
    }

    // type literal
    if (element is TypeDefiningElement) {
      _declareBeforeUse(element);
      var typeName = _emitTypeDefiningElement(element);

      // If the type is a type literal expression in Dart code, wrap the raw
      // runtime type in a "Type" instance.
      if (!_isInForeignJS && _isTypeLiteral(node)) {
        typeName = runtimeCall('wrapType(#)', typeName);
      }

      return typeName;
    }

    // library member
    if (element.enclosingElement is CompilationUnitElement) {
      return _emitLibraryMemberElement(accessor, prefix ?? node);
    }

    // Unqualified class member. This could mean implicit-this, or implicit
    // call to a static from the same class.
    if (element is ClassMemberElement && element is! ConstructorElement) {
      return _emitClassMemberElement(element, accessor, prefix ?? node);
    }

    if (element is ParameterElement) {
      return _emitParameter(element);
    }

    return JS.Identifier(element.name);
  }

  JS.Expression _emitLibraryMemberElement(Element element, Expression node) {
    var result = _emitTopLevelName(element);
    if (element is FunctionElement && _reifyTearoff(element, node)) {
      return _emitFunctionTagged(result, element.type);
    }
    return result;
  }

  JS.Expression _emitClassMemberElement(
      ClassMemberElement element, Element accessor, Expression node) {
    bool isStatic = element.isStatic;
    var classElem = element.enclosingElement;
    var type = classElem.type;
    var member = _emitMemberName(element.name,
        isStatic: isStatic, type: type, element: accessor);

    // A static native element should just forward directly to the
    // JS type's member.
    //
    // TODO(jmesserly): this code path seems broken. It doesn't exist
    // elsewhere, such as [_emitAccess], so it will only take affect for
    // unqualified static access inside of the the same class.
    //
    // If we want this feature to work, we'll need to implement it in the
    // standard [_emitStaticClassName] code path, which will need to know the
    // member we're calling so it can determine whether to use the Dart class
    // name or the native JS class name.
    if (isStatic && _isExternal(element)) {
      var nativeName = _extensionTypes.getNativePeers(classElem);
      if (nativeName.isNotEmpty) {
        var memberName = getAnnotationName(element, isJSName) ?? member;
        return runtimeCall('global.#.#', [nativeName[0], memberName]);
      }
    }

    // For instance members, we add implicit-this.
    // For method tear-offs, we ensure it's a bound method.
    var target = isStatic ? _emitStaticClassName(classElem) : JS.This();
    if (element is MethodElement && _reifyTearoff(element, node)) {
      if (isStatic) {
        // TODO(jmesserly): we could tag static/top-level function types once
        // in the module initialization, rather than at the point where they
        // escape.
        return _emitFunctionTagged(
            JS.PropertyAccess(target, member), element.type);
      }
      return runtimeCall('bind(#, #)', [target, member]);
    }
    return JS.PropertyAccess(target, member);
  }

  JS.Identifier _emitVariableDef(SimpleIdentifier id) {
    return JS.Identifier(id.name)..sourceInformation = _nodeStart(id);
  }

  /// Returns `true` if the type name referred to by [node] is used in a
  /// position where it should evaluate as a type literal -- an object of type
  /// Type.
  bool _isTypeLiteral(SimpleIdentifier node) {
    var parent = node.parent;

    // Static member call.
    if (parent is MethodInvocation || parent is PropertyAccess) return false;

    // An expression like "a.b".
    if (parent is PrefixedIdentifier) {
      // In "a.b", "b" may be a type literal, but "a", is not.
      if (node != parent.identifier) return false;

      // If the prefix expression is itself used as an invocation, like
      // "a.b.c", then "b" is not a type literal.
      var grand = parent.parent;
      if (grand is MethodInvocation || grand is PropertyAccess) return false;

      return true;
    }

    // In any other context, it's a type literal.
    return true;
  }

  JS.Identifier _emitParameter(ParameterElement element,
      {bool declaration = false}) {
    // initializing formal parameter, e.g. `Point(this._x)`
    // TODO(jmesserly): type ref is not attached in this case.
    if (element.isInitializingFormal && element.isPrivate) {
      /// Rename private names so they don't shadow the private field symbol.
      /// The renamer would handle this, but it would prefer to rename the
      /// temporary used for the private symbol. Instead rename the parameter.
      return _initializingFormalTemps.putIfAbsent(
          element, () => JS.TemporaryId(element.name.substring(1)));
    }

    return JS.Identifier(element.name);
  }

  List<Annotation> _parameterMetadata(FormalParameter p) =>
      (p is NormalFormalParameter)
          ? p.metadata
          : (p as DefaultFormalParameter).parameter.metadata;

  // Wrap a result - usually a type - with its metadata.  The runtime is
  // responsible for unpacking this.
  JS.Expression _emitAnnotatedResult(
      JS.Expression result, List<Annotation> metadata) {
    if (options.emitMetadata && metadata != null && metadata.isNotEmpty) {
      result = JS.ArrayInitializer(
          [result]..addAll(metadata.map(_instantiateAnnotation)));
    }
    return result;
  }

  JS.Expression _emitFieldSignature(DartType type,
      {List<Annotation> metadata, bool isFinal = true}) {
    var args = [_emitType(type)];
    if (options.emitMetadata && metadata != null && metadata.isNotEmpty) {
      args.add(
          JS.ArrayInitializer(metadata.map(_instantiateAnnotation).toList()));
    }
    return runtimeCall(isFinal ? 'finalFieldType(#)' : 'fieldType(#)', [args]);
  }

  JS.ArrayInitializer _emitTypeNames(
      List<DartType> types, List<FormalParameter> parameters,
      {bool cacheType = true}) {
    var result = <JS.Expression>[];
    for (int i = 0; i < types.length; ++i) {
      var metadata =
          parameters != null ? _parameterMetadata(parameters[i]) : null;
      var typeName = _emitType(types[i], cacheType: cacheType);
      result.add(_emitAnnotatedResult(typeName, metadata));
    }
    return JS.ArrayInitializer(result);
  }

  JS.ObjectInitializer _emitTypeProperties(Map<String, DartType> types,
      {bool cacheType = true}) {
    var properties = <JS.Property>[];
    types.forEach((name, type) {
      var key = _propertyName(name);
      var value = _emitType(type, cacheType: cacheType);
      properties.add(JS.Property(key, value));
    });
    return JS.ObjectInitializer(properties);
  }

  /// Emit the pieces of a function type, as an array of return type,
  /// regular args, and optional/named args.
  JS.Expression _emitFunctionType(FunctionType type,
      {List<FormalParameter> parameters,
      bool cacheType = true,
      bool lazy = false}) {
    var parameterTypes = type.normalParameterTypes;
    var optionalTypes = type.optionalParameterTypes;
    var namedTypes = type.namedParameterTypes;
    var rt = _emitType(type.returnType, cacheType: cacheType);

    var ra = _emitTypeNames(parameterTypes, parameters, cacheType: cacheType);

    List<JS.Expression> typeParts;
    if (namedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes, cacheType: cacheType);
      typeParts = [rt, ra, na];
    } else if (optionalTypes.isNotEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(
          optionalTypes, parameters?.sublist(parameterTypes.length),
          cacheType: cacheType);
      typeParts = [rt, ra, oa];
    } else {
      typeParts = [rt, ra];
    }

    JS.Expression fullType;
    String helperCall;
    var typeFormals = type.typeFormals;
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
      // If any explicit bounds were passed, emit them.
      if (typeFormals.any((t) => t.bound != null)) {
        var bounds = typeFormals
            .map((t) => _emitType(t.type.bound, cacheType: cacheType))
            .toList();
        typeParts.add(addTypeFormalsAsParameters(bounds));
      }
    } else {
      helperCall = 'fnType(#)';
    }
    fullType = runtimeCall(helperCall, [typeParts]);
    if (!cacheType) return fullType;
    return _typeTable.nameFunctionType(type, fullType, lazy: lazy);
  }

  JS.Expression _emitAnnotatedFunctionType(
      FunctionType type, List<Annotation> metadata,
      {List<FormalParameter> parameters}) {
    var result =
        _emitFunctionType(type, parameters: parameters, cacheType: false);
    return _emitAnnotatedResult(result, metadata);
  }

  /// Emits an expression that lets you access statics on a [type] from code.
  JS.Expression _emitConstructorAccess(DartType type) {
    return _emitJSInterop(type.element) ?? _emitType(type);
  }

  /// Emits an expression that lets you access statics on an [c] from code.
  JS.Expression _emitStaticClassName(ClassElement c) {
    _declareBeforeUse(c);
    return _emitTopLevelName(c);
  }

  /// Emits a Dart [type] into code.
  ///
  /// If [cacheType] is true, then the type will be cached for the module.
  JS.Expression _emitType(DartType type, {bool cacheType = true}) {
    // The void and dynamic types are not defined in core.
    if (type.isVoid) {
      return runtimeCall('void');
    } else if (type.isDynamic) {
      return runtimeCall('dynamic');
    } else if (type.isBottom) {
      return runtimeCall('bottom');
    }

    var element = type.element;
    if (element is TypeDefiningElement) {
      _declareBeforeUse(element);
    }

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
    if (_isObjectLiteral(element)) {
      return runtimeCall('anonymousJSType(#)', js.escapedString(element.name));
    }
    var jsName = _getJSNameWithoutGlobal(element);
    if (jsName != null) {
      return runtimeCall('lazyJSType(() => #, #)',
          [_emitJSInteropForGlobal(jsName), js.escapedString(jsName)]);
    }

    var name = type.name;
    if (type is TypeParameterType) {
      _typeParamInConst?.add(type);
      return JS.Identifier(name);
    }

    if (type is ParameterizedType) {
      if (type is FunctionType) {
        return _emitFunctionType(type, cacheType: cacheType);
      }
      var args = type.typeArguments;
      List<JS.Expression> jsArgs;
      if (args.any((a) => !a.isDynamic)) {
        jsArgs = args.map((x) => _emitType(x, cacheType: cacheType)).toList();
      }
      if (jsArgs != null) {
        var typeRep = _emitGenericClassType(type, jsArgs);
        return cacheType ? _typeTable.nameType(type, typeRep) : typeRep;
      }
    }

    return _emitTopLevelNameNoInterop(element);
  }

  /// Emits the raw type corresponding to the [element].
  JS.Expression _emitTypeDefiningElement(TypeDefiningElement element) {
    return _emitType(fillDynamicTypeArgsForElement(element));
  }

  JS.Expression _emitGenericClassType(
      ParameterizedType t, List<JS.Expression> typeArgs) {
    var genericName = _emitTopLevelNameNoInterop(t.element, suffix: '\$');
    return js.call('#(#)', [genericName, typeArgs]);
  }

  JS.PropertyAccess _emitTopLevelName(Element e, {String suffix = ''}) {
    return _emitJSInterop(e) ?? _emitTopLevelNameNoInterop(e, suffix: suffix);
  }

  JS.PropertyAccess _emitTopLevelNameNoInterop(Element e,
      {String suffix = ''}) {
    return JS.PropertyAccess(
        emitLibraryName(e.library), _emitTopLevelMemberName(e, suffix: suffix));
  }

  /// Emits the member name portion of a top-level member.
  ///
  /// NOTE: usually you should use [_emitTopLevelName] instead of this. This
  /// function does not handle JS interop.
  JS.Expression _emitTopLevelMemberName(Element e, {String suffix = ''}) {
    var name = getJSExportName(e) ?? _getElementName(e);
    return _propertyName(name + suffix);
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
      // are also evaluated only once. This is similar to desugaring for
      // postfix expressions like `i++`.

      // Handle the left hand side, to ensure each of its subexpressions are
      // evaluated only once.
      var vars = <JS.MetaLetVariable, JS.Expression>{};
      var x = _bindLeftHandSide(vars, left, context: left);
      // Capture the result of evaluating the left hand side in a temp.
      var t = _bindValue(vars, 't', x, context: x);
      return JS.MetaLet(vars, [
        js.call('# == null ? # : #',
            [_visitExpression(t), _emitSet(x, right), _visitExpression(t)])
      ]);
    }

    // Desugar `x += y` as `x = x + y`, ensuring that if `x` has subexpressions
    // (for example, x is IndexExpression) we evaluate those once.
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var lhs = _bindLeftHandSide(vars, left, context: context);
    // TODO(leafp): The element for lhs here will be the setter element
    // instead of the getter element if lhs is a property access. This
    // interferes with nullability analysis.
    Expression inc = ast.binaryExpression(lhs, op, right)
      ..staticElement = element
      ..staticType = getStaticType(lhs);

    var castTo = getImplicitOperationCast(left);
    if (castTo != null) inc = CoercionReifier.castExpression(inc, castTo);
    return JS.MetaLet(vars, [_emitSet(lhs, inc)]);
  }

  JS.Expression _emitSet(Expression left, Expression right) {
    if (left is IndexExpression) {
      var target = _getTarget(left);
      if (_useNativeJsIndexer(target.staticType)) {
        return js.call('#[#] = #', [
          _visitExpression(target),
          _visitExpression(left.index),
          _visitExpression(right)
        ]);
      }
      return _emitOperatorCall(
          target, '[]=', [left.index, right], left.staticElement);
    }

    if (left is SimpleIdentifier) {
      return _emitSetSimpleIdentifier(left, right);
    }

    Expression target = null;
    SimpleIdentifier id;
    if (left is PropertyAccess) {
      if (left.operator.lexeme == '?.') {
        return _emitNullSafeSet(left, right);
      }
      target = _getTarget(left);
      id = left.propertyName;
    } else if (left is PrefixedIdentifier) {
      if (isLibraryPrefix(left.prefix)) {
        return _emitSet(left.identifier, right);
      }
      target = left.prefix;
      id = left.identifier;
    } else {
      assert(false);
    }

    if (isDynamicInvoke(target)) {
      return runtimeCall('dput$_replSuffix(#, #, #)', [
        _visitExpression(target),
        _emitMemberName(id.name),
        _visitExpression(right)
      ]);
    }

    var accessor = id.staticElement;
    if (accessor is PropertyAccessorElement) {
      var field = accessor.variable;
      if (field is FieldElement) {
        return _emitSetField(right, field, _visitExpression(target), id);
      }
    }

    return _badAssignment('Unhandled assignment', left, right);
  }

  // TODO(jmesserly): can we encapsulate REPL name lookups and remove this?
  // _emitMemberName would be a nice place to handle it, but we don't have
  // access to the target expression there (needed for `dart.replNameLookup`).
  String get _replSuffix => options.replCompile ? 'Repl' : '';

  JS.Expression _badAssignment(String problem, Expression lhs, Expression rhs) {
    // TODO(sra): We should get here only for compiler bugs or weirdness due to
    // --unsafe-force-compile. Once those paths have been addressed, throw at
    // compile time.
    assert(options.unsafeForceCompile);
    return runtimeCall('throwUnimplementedError((#, #, #))',
        [js.string('$lhs ='), _visitExpression(rhs), js.string(problem)]);
  }

  /// Emits assignment to a simple identifier. Handles all legal simple
  /// identifier assignment targets (local, top level library member, implicit
  /// `this` or class, etc.)
  JS.Expression _emitSetSimpleIdentifier(
      SimpleIdentifier node, Expression right) {
    JS.Expression unimplemented() {
      return _badAssignment("Unimplemented: unknown name '$node'", node, right);
    }

    var accessor = resolutionMap.staticElementForIdentifier(node);
    if (accessor == null) return unimplemented();

    // Get the original declaring element. If we had a property accessor, this
    // indirects back to a (possibly synthetic) field.
    var element = accessor;
    if (accessor is PropertyAccessorElement) element = accessor.variable;

    if (element is TypeDefiningElement) {
      _declareBeforeUse(element);
    }

    if (element is LocalVariableElement || element is ParameterElement) {
      return _emitSetLocal(element, right, node);
    }

    if (accessor is PropertyAccessorElement &&
        element.enclosingElement is CompilationUnitElement) {
      // Top level library member.
      return _emitSetTopLevel(accessor, right);
    }

    // Unqualified class member. This could mean implicit `this`, or implicit
    // static from the same class.
    if (element is FieldElement) {
      return _emitSetField(right, element, JS.This(), node);
    }

    // We should not get here.
    return unimplemented();
  }

  /// Emits assignment to a simple local variable or parameter.
  JS.Expression _emitSetLocal(Element element, Expression rhs, AstNode left) {
    JS.Expression target;
    if (element is TemporaryVariableElement) {
      // If this is one of our compiler's temporary variables, use its JS form.
      target = element.jsVariable;
    } else if (element is ParameterElement) {
      target = _emitParameter(element);
    } else {
      target = JS.Identifier(element.name);
    }
    target.sourceInformation = _nodeSpan(left);
    return _visitExpression(rhs).toAssignExpression(target);
  }

  /// Emits assignment to library scope element [element].
  JS.Expression _emitSetTopLevel(
      PropertyAccessorElement element, Expression rhs) {
    return _visitExpression(rhs).toAssignExpression(_emitTopLevelName(element));
  }

  /// Emits assignment to a static field element or property.
  JS.Expression _emitSetField(Expression right, FieldElement field,
      JS.Expression jsTarget, SimpleIdentifier id) {
    var classElem = field.enclosingElement;
    var isStatic = field.isStatic;
    var member = _emitMemberName(field.name,
        isStatic: isStatic, type: classElem.type, element: field.setter);
    jsTarget = isStatic
        ? (JS.PropertyAccess(_emitStaticClassName(classElem), member)
          ..sourceInformation = _nodeSpan(id))
        : _emitTargetAccess(jsTarget, member, field.setter, id);
    return _visitExpression(right).toAssignExpression(jsTarget);
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
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var left = _bindValue(vars, 'l', node.target);
    var body = js.call('# == null ? null : #', [
      _visitExpression(left),
      _emitSet(_stripNullAwareOp(node, left), right)
    ]);
    return JS.MetaLet(vars, [body]);
  }

  @override
  JS.Block visitExpressionFunctionBody(ExpressionFunctionBody node) {
    return JS.Block([_visitExpression(node.expression).toReturn()]);
  }

  @override
  JS.Block visitEmptyFunctionBody(EmptyFunctionBody node) => JS.Block([]);

  @override
  JS.Block visitBlockFunctionBody(BlockFunctionBody node) {
    return JS.Block(_visitStatementList(node.block.statements));
  }

  @override
  JS.Block visitBlock(Block node) =>
      JS.Block(_visitStatementList(node.statements), isScope: true);

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (_isDeferredLoadLibrary(node.target, node.methodName)) {
      // We are calling loadLibrary() on a deferred library prefix.
      return runtimeCall('loadLibrary()');
    }

    if (node.operator?.lexeme == '?.' && isNullable(node.target)) {
      return _emitNullSafe(node);
    }

    var e = node.methodName.staticElement;
    var result = _emitForeignJS(node, e);
    if (result != null) return result;

    // Optimize some internal SDK calls.
    if (e != null &&
        isSdkInternalRuntime(e.library) &&
        node.argumentList.arguments.length == 1) {
      var firstArg = node.argumentList.arguments[0];
      if (e.name == 'getGenericClass' && firstArg is SimpleIdentifier) {
        var typeElem = firstArg.staticElement;
        if (typeElem is TypeDefiningElement &&
            typeElem.type is ParameterizedType) {
          return _emitTopLevelNameNoInterop(typeElem, suffix: '\$');
        }
      }
      if (e.name == 'unwrapType' && firstArg is SimpleIdentifier) {
        var typeElem = firstArg.staticElement;
        if (typeElem is TypeDefiningElement) {
          return _emitTypeDefiningElement(typeElem);
        }
      }
      if (e.name == 'extensionSymbol' && firstArg is StringLiteral) {
        return _getExtensionSymbolInternal(firstArg.stringValue);
      }
    }

    var target = _getTarget(node);
    if (target == null || isLibraryPrefix(target)) {
      return _emitFunctionCall(node);
    }
    if (node.methodName.name == 'call' &&
        _isDirectCallable(target.staticType)) {
      // Call methods on function types should be handled as regular function
      // invocations.
      return _emitFunctionCall(node, node.target);
    }

    return _emitMethodCall(target, node);
  }

  JS.Expression _emitTarget(Expression target, Element member, bool isStatic) {
    if (isStatic) {
      if (member is ConstructorElement) {
        return _emitConstructorAccess(member.enclosingElement.type)
          ..sourceInformation = _nodeSpan(target);
      }
      if (member is PropertyAccessorElement) {
        var field = member.variable;
        if (field is FieldElement) {
          return _emitStaticClassName(field.enclosingElement)
            ..sourceInformation = _nodeSpan(target);
        }
      }
      if (member is MethodElement) {
        return _emitStaticClassName(member.enclosingElement)
          ..sourceInformation = _nodeSpan(target);
      }
    }
    var result = _visitExpression(target);
    if (target == _cascadeTarget) {
      // Don't attach source information to a cascade target, as that would
      // result in marking the same location from different lines.
      result.sourceInformation = null;
    }
    return result;
  }

  /// Emits the [JS.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  JS.Expression _emitTargetAccess(JS.Expression jsTarget, JS.Expression jsName,
      Element member, AstNode node) {
    JS.Expression result;
    if (!_superAllowed && jsTarget is JS.Super && member != null) {
      result = _getSuperHelper(member, jsName);
    } else {
      result = JS.PropertyAccess(jsTarget, jsName);
    }
    if (node != null) {
      // Use the full span for a cascade property so we can hover over `bar` in
      // `..bar()` and see the `bar` method.
      var cascade = _cascadeTarget;
      var parent = node.parent;
      var isCascade = cascade != null &&
          parent is Expression &&
          _getTarget(parent) == cascade;
      result.sourceInformation = isCascade ? _nodeSpan(node) : _nodeEnd(node);
    }
    return result;
  }

  JS.Expression _getSuperHelper(Element member, JS.Expression jsName) {
    var jsMethod = _superHelpers.putIfAbsent(member.name, () {
      if (member is PropertyAccessorElement) {
        var isSetter = member.isSetter;
        var fn = js.fun(
            isSetter
                ? 'function(x) { super[#] = x; }'
                : 'function() { return super[#]; }',
            [jsName]);
        return JS.Method(JS.TemporaryId(member.variable.name), fn,
            isGetter: !isSetter, isSetter: isSetter);
      } else {
        var method = member as MethodElement;
        var params =
            List<JS.Identifier>.from(_emitTypeFormals(method.typeParameters));
        for (var param in method.parameters) {
          if (param.isNamed) {
            params.add(namedArgumentTemp);
            break;
          }
          params.add(JS.Identifier(param.name));
        }

        var fn = js.fun(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        var name = method.name;
        name = JS.friendlyNameForDartOperator[name] ?? name;
        return JS.Method(JS.TemporaryId(name), fn);
      }
    });
    return JS.PropertyAccess(JS.This(), jsMethod.name);
  }

  JS.Expression _emitMethodCall(Expression target, MethodInvocation node) {
    var argumentList = node.argumentList;
    var args = _emitArgumentList(argumentList);
    var typeArgs = _emitInvokeTypeArguments(node);

    var type = getStaticType(target);
    var element = node.methodName.staticElement;
    bool isStatic = element is ExecutableElement && element.isStatic;
    var name = node.methodName.name;
    var jsName =
        _emitMemberName(name, type: type, isStatic: isStatic, element: element);

    if (isDynamicInvoke(target) || isDynamicInvoke(node.methodName)) {
      JS.Expression jsTarget = _emitTarget(target, element, isStatic);
      if (jsTarget is JS.Super) {
        jsTarget =
            _emitTargetAccess(jsTarget, jsName, element, node.methodName);
        jsName = null;
      }
      return _emitDynamicInvoke(jsTarget, typeArgs, jsName, args, argumentList);
    }

    JS.Expression jsTarget = _emitTarget(target, element, isStatic);

    // Handle Object methods that are supported by `null`.
    if (_isObjectMethodCall(name, argumentList.arguments) &&
        isNullable(target)) {
      assert(typeArgs == null); // Object methods don't take type args.
      return runtimeCall('#(#, #)', [name, jsTarget, args]);
    }

    jsTarget = _emitTargetAccess(jsTarget, jsName, element, node.methodName);
    // Handle `o.m(a)` where `o.m` is a getter returning a class with `call`.
    if (element is PropertyAccessorElement) {
      var fromType = element.returnType;
      if (fromType is InterfaceType) {
        var callName = _getImplicitCallTarget(fromType);
        if (callName != null) {
          jsTarget = JS.PropertyAccess(jsTarget, callName);
        }
      }
    }
    var castTo = getImplicitOperationCast(node);
    if (castTo != null) {
      jsTarget = _emitCast(castTo, jsTarget);
    }
    if (typeArgs != null) args.insertAll(0, typeArgs);
    return JS.Call(jsTarget, args);
  }

  JS.Expression _emitDynamicInvoke(
      JS.Expression fn,
      List<JS.Expression> typeArgs,
      JS.Expression methodName,
      List<JS.Expression> args,
      ArgumentList argumentList) {
    var jsArgs = <Object>[fn];
    String jsCode;
    if (typeArgs != null) {
      jsArgs.add(typeArgs);
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

    var hasNamed = argumentList.arguments.any((a) => a is NamedExpression);
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

  bool _doubleEqIsIdentity(Expression left, Expression right) {
    // If we statically know LHS or RHS is null we can use ==.
    if (_isNull(left) || _isNull(right)) return true;
    // If the representation of the  two types will not induce conversion in
    // JS then we can use == .
    return !jsTypeRep.equalityMayConvert(left.staticType, right.staticType);
  }

  bool _tripleEqIsIdentity(Expression left, Expression right) {
    // If either is non-nullable, then we don't need to worry about
    // equating null and undefined, and so we can use triple equals.
    return !isNullable(left) || !isNullable(right);
  }

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

  JS.Expression _emitCoreIdenticalCall(List<Expression> arguments,
      {bool negated = false}) {
    if (arguments.length != 2) {
      // Shouldn't happen in typechecked code
      return runtimeCall(
          'throw(Error("compile error: calls to `identical` require 2 args")');
    }
    var left = arguments[0];
    var right = arguments[1];
    var args = [_visitExpression(left), _visitExpression(right)];
    if (_tripleEqIsIdentity(left, right)) {
      return _emitJSTripleEq(args, negated: negated);
    }
    if (_doubleEqIsIdentity(left, right)) {
      return _emitJSDoubleEq(args, negated: negated);
    }
    var code = negated ? '!#' : '#';
    return js.call(code, JS.Call(_emitTopLevelName(_coreIdentical), args));
  }

  /// Emits a function call, to a top-level function, local function, or
  /// an expression.
  JS.Node _emitFunctionCall(InvocationExpression node, [Expression function]) {
    function ??= node.function;
    var castTo = getImplicitOperationCast(function);
    if (castTo != null) {
      function = CoercionReifier.castExpression(function, castTo);
    }
    if (function is Identifier) {
      var element = function.staticElement;
      if (element == _coreIdentical) {
        return _emitCoreIdenticalCall(node.argumentList.arguments);
      }
      var uri = element.librarySource.uri;
      if (uri.scheme == 'dart' &&
          uri.path.startsWith('developer') &&
          element.name == 'debugger') {
        return _emitDebuggerCall(node);
      }
    }

    var args = _emitArgumentList(node.argumentList);
    var typeArgs = _emitInvokeTypeArguments(node);
    var fn = _visitExpression(function);
    if (isDynamicInvoke(function)) {
      return _emitDynamicInvoke(fn, typeArgs, null, args, node.argumentList);
    }
    if (typeArgs != null) args.insertAll(0, typeArgs);

    var targetType = function.staticType;
    if (targetType is InterfaceType) {
      var callName = _getImplicitCallTarget(targetType);
      if (callName != null) {
        return js.call('#.#(#)', [fn, callName, args]);
      }
    }

    return JS.Call(fn, args);
  }

  JS.Node _emitDebuggerCall(InvocationExpression node) {
    var args = node.argumentList.arguments;
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
    var jsArgs = <JS.Property>[];
    var foundWhen = false;
    for (var arg in args) {
      var namedArg = arg as NamedExpression;
      if (namedArg.name.label.name == 'when') foundWhen = true;
      jsArgs.add(visitNamedExpression(namedArg));
    }
    var when = jsArgs.length == 1
        // For a single `when` argument, use it.
        //
        // For a single `message` argument, use `{message: ...}`, which
        // coerces to true (the default value of `when`).
        ? (foundWhen ? jsArgs[0].value : JS.ObjectInitializer(jsArgs))
        // If we have both `message` and `when` arguments, evaluate them in
        // order, then extract the `when` argument.
        : js.call('#.when', JS.ObjectInitializer(jsArgs));
    return isStatement
        ? js.statement('if (#) debugger;', when)
        : js.call('# && (() => { debugger; return true })()', when);
  }

  List<JS.Expression> _emitInvokeTypeArguments(InvocationExpression node) {
    // add no reify generic check here: if (node.function)
    // node is Identifier
    var function = node.function;
    if (function is Identifier && !_reifyGeneric(function.staticElement)) {
      return null;
    }
    return _emitFunctionTypeArguments(
        function.staticType, node.staticInvokeType, node.typeArguments);
  }

  /// If `g` is a generic function type, and `f` is an instantiation of it,
  /// then this will return the type arguments to apply, otherwise null.
  List<JS.Expression> _emitFunctionTypeArguments(DartType g, DartType f,
      [TypeArgumentList typeArgs]) {
    if (g is FunctionType &&
        g.typeFormals.isNotEmpty &&
        f is FunctionType &&
        f.typeFormals.isEmpty) {
      return _recoverTypeArguments(g, f).map(_emitType).toList(growable: false);
    } else if (typeArgs != null) {
      // Dynamic calls may have type arguments, even though the function types
      // are not known.
      return _visitExpressionList(typeArgs.arguments);
    }
    return null;
  }

  /// Given a generic function type [g] and an instantiated function type [f],
  /// find a list of type arguments TArgs such that `g<TArgs> == f`,
  /// and return TArgs.
  ///
  /// This function must be called with type [f] that was instantiated from [g].
  Iterable<DartType> _recoverTypeArguments(FunctionType g, FunctionType f) {
    // TODO(jmesserly): this design is a bit unfortunate. It would be nice if
    // resolution could simply create a synthetic type argument list.
    assert(g.typeFormals.isNotEmpty && f.typeFormals.isEmpty);
    assert(g.typeFormals.length <= f.typeArguments.length);

    // Instantiation in Analyzer works like this:
    // Given:
    //     {U/T} <S> T -> S
    // Where {U/T} represents the typeArguments (U) and typeParameters (T) list,
    // and <S> represents the typeFormals.
    //
    // Now instantiate([V]), and the result should be:
    //     {U/T, V/S} T -> S.
    //
    // Therefore, we can recover the typeArguments from our instantiated
    // function.
    return f.typeArguments.skip(f.typeArguments.length - g.typeFormals.length);
  }

  /// Emits code for the `JS(...)` macro.
  JS.Node _emitForeignJS(MethodInvocation node, Element e) {
    if (!isInlineJS(e)) return null;

    var args = node.argumentList.arguments;
    // arg[0] is static return type, used in `RestrictedStaticTypeAnalyzer`
    var code = args[1];
    List<Expression> templateArgs;
    String source;
    if (code is StringInterpolation) {
      if (args.length > 2) {
        throw ArgumentError(
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
      templateArgs = args.skip(2).toList();
      source = (code as StringLiteral).stringValue;
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

    // `throw` is emitted as a statement by `parseForeignJS`.
    assert(result is JS.Expression ||
        result is JS.Statement && node.parent is ExpressionStatement);
    return result;
  }

  @override
  JS.Node visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      _emitFunctionCall(node);

  List<JS.Expression> _emitArgumentList(ArgumentList node) {
    var args = <JS.Expression>[];
    var named = <JS.Property>[];
    for (var arg in node.arguments) {
      if (arg is NamedExpression) {
        named.add(visitNamedExpression(arg));
      } else if (arg is MethodInvocation && isJsSpreadInvocation(arg)) {
        args.add(JS.Spread(_visitExpression(arg.argumentList.arguments[0])));
      } else {
        args.add(_visitExpression(arg));
      }
    }
    if (named.isNotEmpty) {
      args.add(JS.ObjectInitializer(named));
    }
    return args;
  }

  @override
  JS.Property visitNamedExpression(NamedExpression node) {
    assert(node.parent is ArgumentList);
    return JS.Property(
        _propertyName(node.name.label.name), _visitExpression(node.expression));
  }

  List<JS.Parameter> _emitParametersForElement(ExecutableElement member) {
    var jsParams = <JS.Identifier>[];
    for (var p in member.parameters) {
      if (p.isPositional) {
        jsParams.add(JS.Identifier(p.name));
      } else {
        jsParams.add(namedArgumentTemp);
        break;
      }
    }
    return jsParams;
  }

  List<JS.Parameter> _emitParameters(Iterable<FormalParameter> parameters) {
    if (parameters == null) return [];

    var result = <JS.Parameter>[];
    for (var param in parameters) {
      if (param.isNamed) {
        result.add(namedArgumentTemp);
        break;
      }
      result.add(_emitFormalParameter(param));
    }

    return result;
  }

  @override
  JS.Statement visitExpressionStatement(ExpressionStatement node) =>
      node.expression.accept(this).toStatement();

  @override
  JS.EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      JS.EmptyStatement();

  @override
  JS.Statement visitAssertStatement(AssertStatement node) =>
      _emitAssert(node.condition, node.message);

  JS.Statement _emitAssert(Expression condition, Expression message) {
    if (!options.enableAsserts) return JS.EmptyStatement();
    // TODO(jmesserly): only emit in checked mode.
    var conditionType = condition.staticType;
    var jsCondition = _visitExpression(condition);

    if (conditionType is FunctionType &&
        conditionType.parameters.isEmpty &&
        conditionType.returnType == types.boolType) {
      jsCondition = runtimeCall('test(#())', jsCondition);
    } else if (conditionType != types.boolType) {
      jsCondition = runtimeCall('dassert(#)', jsCondition);
    } else if (isNullable(condition)) {
      jsCondition = runtimeCall('test(#)', jsCondition);
    }
    return js.statement(' if (!#) #.assertFailed(#);', [
      jsCondition,
      runtimeModule,
      message != null ? [_visitExpression(message)] : []
    ]);
  }

  @override
  JS.Statement visitReturnStatement(ReturnStatement node) {
    return super.emitReturnStatement(_visitExpression(node.expression));
  }

  @override
  JS.Statement visitYieldStatement(YieldStatement node) {
    var jsExpr = _visitExpression(node.expression);
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
  JS.Expression visitAwaitExpression(AwaitExpression node) {
    return JS.Yield(_visitExpression(node.expression));
  }

  /// This is not used--we emit top-level fields as we are emitting the
  /// compilation unit, see [visitCompilationUnit].
  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    return _unreachable(node);
  }

  /// This is not used--we emit fields as we are emitting the class,
  /// see [visitClassDeclaration].
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    return _unreachable(node);
  }

  @override
  JS.Statement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    // Special case a single variable with an initializer.
    // This helps emit cleaner code for things like:
    //     var result = []..add(1)..add(2);
    var variables = node.variables.variables;
    if (variables.length == 1) {
      var variable = variables[0];
      var initializer = variable.initializer;
      if (initializer != null) {
        var name = _emitVariableDef(variable.name);
        JS.Expression value;
        if (_annotatedNullCheck(variable.declaredElement)) {
          value = notNull(initializer);
        } else if (initializer is FunctionExpression) {
          // This improve stack traces for the pattern:
          //
          //     var f = (y) => y.doesNotExist();
          //
          // ... by moving the type tagging after of the variable declaration:
          //
          //     let f = (y) => y.doesNotExist();
          //     dart.fn(f, typeOfF);
          //
          value = _emitArrowFunction(initializer);
          return JS.Block([
            value.toVariableDeclaration(name),
            _emitFunctionTagged(
                    name, getStaticType(initializer) as FunctionType,
                    topLevel: _executesAtTopLevel(node))
                .toStatement()
          ]);
        } else {
          value = _visitExpression(initializer);
        }
        return value.toVariableDeclaration(name);
      }
    }
    return visitVariableDeclarationList(node.variables).toStatement();
  }

  @override
  JS.VariableDeclarationList visitVariableDeclarationList(
      VariableDeclarationList node) {
    if (node == null) return null;
    return JS.VariableDeclarationList(
        'let', node.variables?.map(visitVariableDeclaration)?.toList());
  }

  @override
  JS.VariableInitialization visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredElement is PropertyInducingElement) {
      // All fields are handled elsewhere.
      assert(false);
      return null;
    }

    var name = _emitVariableDef(node.name);
    return JS.VariableInitialization(
        name, _visitInitializer(node.initializer, node.declaredElement));
  }

  /// Emits a list of top-level field.
  void _emitTopLevelFields(List<VariableDeclaration> fields) {
    moduleItems.add(_emitLazyFields(
        emitLibraryName(currentLibrary), fields, _emitTopLevelMemberName));
  }

  /// Treat dart:_runtime fields as safe to eagerly evaluate.
  // TODO(jmesserly): it'd be nice to avoid this special case.
  List<VariableDeclaration> _emitInternalSdkFields(
      List<VariableDeclaration> fields) {
    var lazyFields = <VariableDeclaration>[];
    for (var field in fields) {
      // Skip our magic undefined constant.
      var element = field.declaredElement as TopLevelVariableElement;
      if (element.name == 'undefined') continue;

      var init = field.initializer;
      if (init == null ||
          init is Literal ||
          _isJSInvocation(init) ||
          init is InstanceCreationExpression &&
              isSdkInternalRuntime(init.staticElement.library)) {
        moduleItems.add(js.statement('# = #;', [
          _emitTopLevelName(field.declaredElement),
          _visitInitializer(field.initializer, field.declaredElement)
        ]));
      } else {
        lazyFields.add(field);
      }
    }
    return lazyFields;
  }

  JS.Expression _visitInitializer(Expression init, Element variable) {
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    if (init == null) return JS.LiteralNull();
    return _annotatedNullCheck(variable)
        ? notNull(init)
        : _visitExpression(init);
  }

  JS.Statement _emitLazyFields(
      JS.Expression objExpr,
      List<VariableDeclaration> fields,
      JS.Expression Function(Element e) emitFieldName) {
    var accessors = <JS.Method>[];

    for (var node in fields) {
      var element = node.declaredElement;
      var access = emitFieldName(element);
      accessors.add(JS.Method(
          access,
          js.call('function() { return #; }',
              _visitInitializer(node.initializer, element)) as JS.Fun,
          isGetter: true)
        ..sourceInformation =
            _hoverComment(JS.PropertyAccess(objExpr, access), node.name));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!node.isFinal && !node.isConst) {
        accessors.add(JS.Method(access, js.call('function(_) {}') as JS.Fun,
            isSetter: true));
      }
    }

    return runtimeStatement('defineLazy(#, { # })', [objExpr, accessors]);
  }

  JS.Expression _emitConstructorName(DartType type, String name) {
    return _emitJSInterop(type.element) ??
        JS.PropertyAccess(_emitConstructorAccess(type), _constructorName(name));
  }

  @override
  JS.Expression visitConstructorName(ConstructorName node) {
    return _emitConstructorName(node.type.type, node.staticElement.name);
  }

  JS.Expression _emitInstanceCreationExpression(ConstructorElement element,
      InterfaceType type, List<JS.Expression> Function() emitArguments,
      {bool isConst = false, ConstructorName ctorNode}) {
    if (element == null) {
      return _throwUnsafe('unresolved constructor: ${type?.name ?? '<null>'}'
          '.${ctorNode?.name?.name ?? '<unnamed>'}');
    }

    var classElem = type.element;
    if (_isObjectLiteral(classElem)) {
      var args = emitArguments();
      return args.isEmpty ? js.call('{}') : args.single as JS.ObjectInitializer;
    }

    var name = element.name;
    JS.Expression emitNew() {
      var args = emitArguments();
      if (args.isEmpty && classElem.source.isInSystemLibrary) {
        // Skip the slow SDK factory constructors when possible.
        switch (classElem.name) {
          case 'Map':
          case 'HashMap':
          case 'LinkedHashMap':
            if (name == '') {
              return js.call('new #.new()', _emitMapImplType(type));
            } else if (name == 'identity') {
              return js.call(
                  'new #.new()', _emitMapImplType(type, identity: true));
            }
            break;
          case 'Set':
          case 'HashSet':
          case 'LinkedHashSet':
            if (name == '') {
              return js.call('new #.new()', _emitSetImplType(type));
            } else if (name == 'identity') {
              return js.call(
                  'new #.new()', _emitSetImplType(type, identity: true));
            }
            break;
          case 'List':
            if (name == '' && type is InterfaceType) {
              return _emitList(type.typeArguments[0], []);
            }
            break;
        }
      }
      // Native factory constructors are JS constructors - use new here.
      var ctor = _emitConstructorName(type, name);
      if (ctorNode != null) ctor.sourceInformation = _nodeSpan(ctorNode);
      return element.isFactory && !_hasJSInteropAnnotation(classElem)
          ? JS.Call(ctor, args)
          : JS.New(ctor, args);
    }

    return isConst ? _emitConst(emitNew) : emitNew();
  }

  bool _isObjectLiteral(Element classElem) {
    return _hasJSInteropAnnotation(classElem) &&
        findAnnotation(classElem, isJSAnonymousAnnotation) != null;
  }

  /// Returns true iff the class has an `@JS(...)` annotation from `package:js`.
  ///
  /// Note: usually [_usesJSInterop] should be used instead of this.
  //
  // TODO(jmesserly): I think almost all uses of this should be replaced with
  // [_usesJSInterop], which also checks that the library is marked with `@JS`.
  //
  // Right now we have inconsistencies: sometimes we'll respect `@JS` on the
  // class itself, other places we require it on the library. Also members are
  // inconsistent: sometimes they need to have `@JS` on them, other times they
  // need to be `external` in an `@JS` class.
  bool _hasJSInteropAnnotation(Element e) =>
      findAnnotation(e, isPublicJSAnnotation) != null;

  /// If the constant [value] is primitive, directly emit the
  /// corresponding JavaScript.  Otherwise, return null.
  JS.Expression _emitDartObject(DartObject value,
      {bool handleUnknown = false}) {
    if (value == null || value.isNull) {
      return JS.LiteralNull();
    }
    var type = value.type;
    // Handle unknown value: when the declared variable wasn't found, and no
    // explicit default value was passed either.
    // TODO(jmesserly): ideally Analyzer would simply resolve this to the
    // default value that is specified in the SDK. Instead we implement that
    // here. `bool.fromEnvironment` defaults to `false`, the others to `null`:
    // https://api.dartlang.org/stable/1.20.1/dart-core/bool/bool.fromEnvironment.html
    if (!value.hasKnownValue) {
      if (!handleUnknown) return null;
      return type == types.boolType ? js.boolean(false) : JS.LiteralNull();
    }
    if (type == types.boolType) {
      return js.boolean(value.toBoolValue());
    }
    if (type == types.intType) {
      return js.number(value.toIntValue());
    }
    if (type == types.doubleType) {
      return js.number(value.toDoubleValue());
    }
    if (type == types.stringType) {
      var stringValue = value.toStringValue();
      return js.escapedString(stringValue);
    }
    if (type == types.symbolType) {
      return _emitDartSymbol(value.toSymbolValue());
    }
    if (type == types.typeType) {
      return _emitType(value.toTypeValue());
    }
    if (type is InterfaceType) {
      if (type.element == types.listType.element) {
        return _cacheConst(() => _emitConstList(type.typeArguments[0],
            value.toListValue().map(_emitDartObject).toList()));
      }
      if (type.element == types.mapType.element) {
        return _cacheConst(() {
          var entries = <JS.Expression>[];
          value.toMapValue().forEach((key, value) {
            entries.add(_emitDartObject(key));
            entries.add(_emitDartObject(value));
          });
          return _emitConstMap(type, entries);
        });
      }
      if (value is DartObjectImpl && value.isUserDefinedObject) {
        var ctor = value.getInvocation();
        var classElem = type.element;
        if (classElem.isEnum) {
          // TODO(jmesserly): we should be able to use `getField('index')` but
          // in some cases Analyzer uses the name of the static field that
          // contains the enum, rather than the `index` field, due to a bug.
          //
          // So we just grab the one instance field, regardless of its name.
          var index = value.fields.values.single.toIntValue();
          var field =
              classElem.fields.where((f) => f.type == type).elementAt(index);
          return _emitClassMemberElement(field, field.getter, null);
        }
        return _emitInstanceCreationExpression(ctor.constructor, type, () {
          var args = ctor.positionalArguments.map(_emitDartObject).toList();
          var named = <JS.Property>[];
          ctor.namedArguments.forEach((name, value) {
            named.add(JS.Property(_propertyName(name), _emitDartObject(value)));
          });
          if (named.isNotEmpty) args.add(JS.ObjectInitializer(named));
          return args;
        }, isConst: true);
      }
    }
    if (value is DartObjectImpl && type is FunctionType) {
      Element element = value.toFunctionValue();
      if (element.enclosingElement is CompilationUnitElement) {
        return _emitLibraryMemberElement(element, null);
      }
      if (element is ClassMemberElement) {
        return _emitClassMemberElement(element, element, null);
      }
    }
    return _unreachable(value);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = resolutionMap.staticElementForConstructorReference(node);
    var constructor = node.constructorName;
    if (node.isConst &&
        element?.name == 'fromEnvironment' &&
        element.library.isDartCore) {
      var value = node.accept(_constants.constantVisitor);

      var result = _emitDartObject(value, handleUnknown: true);
      if (result != null) {
        return result;
      }
      throw StateError('failed to evaluate $node');
    }

    // TODO(jmesserly): this is a workaround for Analyzer's type not
    // correctly tracking typedefs used in type arguments.
    DartType getType(TypeAnnotation typeNode) {
      if (typeNode is NamedType && typeNode.typeArguments != null) {
        var e = typeNode.name.staticElement;
        if (e is TypeParameterizedElement) {
          return e.type.instantiate(
              typeNode.typeArguments.arguments.map(getType).toList());
        }
      }
      return typeNode.type;
    }

    return _emitInstanceCreationExpression(
        element,
        getType(constructor.type) as InterfaceType,
        () => _emitArgumentList(node.argumentList),
        isConst: node.isConst,
        ctorNode: constructor);
  }

  JS.Statement _nullParameterCheck(JS.Expression param) {
    var call = runtimeCall('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  JS.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visitExpression(expr);
    if (!isNullable(expr)) return jsExpr;
    return runtimeCall('notNull(#)', jsExpr);
  }

  JS.Expression _emitEqualityOperator(BinaryExpression node, Token op) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var leftType = left.staticType;
    var negated = op.type == TokenType.BANG_EQ;

    if (left is SuperExpression) {
      return _emitOperatorCall(left, op.lexeme, [right], node.staticElement);
    }

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
    var isEnum = leftType is InterfaceType && leftType.element.isEnum;
    var usesIdentity = jsTypeRep.isPrimitive(leftType) ||
        isEnum ||
        _isNull(left) ||
        _isNull(right);

    // If we know that the left type uses identity for equality, we can
    // sometimes emit better code, either `===` or `==`.
    if (usesIdentity) {
      return _emitCoreIdenticalCall([left, right], negated: negated);
    }

    // If the left side is nullable, we need to use a runtime helper to check
    // for null. We could inline the null check, but it did not seem to have
    // a measurable performance effect (possibly the helper is simple enough to
    // be inlined).
    if (isNullable(left)) {
      var code = negated ? '!#.equals(#, #)' : '#.equals(#, #)';
      return js.call(code,
          [runtimeModule, _visitExpression(left), _visitExpression(right)]);
    }

    // Otherwise we emit a call to the == method.
    var name = _emitMemberName('==', type: leftType);
    var code = negated ? '!#[#](#)' : '#[#](#)';
    return js
        .call(code, [_visitExpression(left), name, _visitExpression(right)]);
  }

  @override
  JS.Expression visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;

    // The operands of logical boolean operators are subject to boolean
    // conversion.
    if (op.type == TokenType.BAR_BAR ||
        op.type == TokenType.AMPERSAND_AMPERSAND) {
      return _visitTest(node)
        ..sourceInformation = _getLocation(node.operator.offset);
    }

    if (op.type.isEqualityOperator) return _emitEqualityOperator(node, op);

    var left = node.leftOperand;
    var right = node.rightOperand;

    if (op.type.lexeme == '??') {
      // TODO(jmesserly): leave RHS for debugging?
      // This should be a hint or warning for dead code.
      if (!isNullable(left)) return _visitExpression(left);

      var vars = <JS.MetaLetVariable, JS.Expression>{};
      // Desugar `l ?? r` as `l != null ? l : r`
      var l = _visitExpression(_bindValue(vars, 'l', left, context: left));
      return JS.MetaLet(vars, [
        js.call('# != null ? # : #', [l, l, _visitExpression(right)])
      ]);
    }

    var leftType = getStaticType(left);
    var rightType = getStaticType(right);

    JS.Expression operatorCall() {
      return _emitOperatorCall(left, op.lexeme, [right])
        ..sourceInformation = _getLocation(node.operator.offset);
    }

    if (jsTypeRep.binaryOperationIsPrimitive(leftType, rightType) ||
        leftType == types.stringType && op.type == TokenType.PLUS) {
      // Inline operations on primitive types where possible.
      // TODO(jmesserly): inline these from dart:core instead of hardcoding
      // the implementation details here.

      /// Emits an inlined binary operation using the JS [code], adding null
      /// checks if needed to ensure we throw the appropriate error.
      JS.Expression binary(String code) {
        return js.call(code, [notNull(left), notNull(right)])
          ..sourceInformation = _getLocation(node.operator.offset);
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
        return js.call(code, [notNull(left), _visitTest(right)])
          ..sourceInformation = _getLocation(node.operator.offset);
      }

      switch (op.type) {
        case TokenType.TILDE_SLASH:
          // `a ~/ b` is equivalent to `(a / b).truncate()`
          var div = ast.binaryExpression(left, '/', right)
            ..staticType = node.staticType;
          return _emitOperatorCall(div, 'truncate', [])
            ..sourceInformation = _getLocation(node.operator.offset);

        case TokenType.PERCENT:
          // TODO(sra): We can generate `a % b + 0` if both are non-negative
          // (the `+ 0` is to coerce -0.0 to 0).
          return operatorCall();

        case TokenType.AMPERSAND:
          return jsTypeRep.isBoolean(leftType)
              ? bitwiseBool('!!(# & #)')
              : bitwise('# & #');

        case TokenType.BAR:
          return jsTypeRep.isBoolean(leftType)
              ? bitwiseBool('!!(# | #)')
              : bitwise('# | #');

        case TokenType.CARET:
          return jsTypeRep.isBoolean(leftType)
              ? bitwiseBool('# !== #')
              : bitwise('# ^ #');

        case TokenType.GT_GT:
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
          return operatorCall();

        case TokenType.LT_LT:
          if (_is31BitUnsigned(node)) {
            // Result is 31 bit unsigned which implies the shift count was small
            // enough not to pollute the sign bit.
            return binary('# << #');
          }
          if (_asIntInRange(right, 0, 31) != null) {
            return _coerceBitOperationResultToUnsigned(node, binary('# << #'));
          }
          return operatorCall();

        default:
          // TODO(vsm): When do Dart ops not map to JS?
          return binary('# $op #');
      }
    }

    return operatorCall();
  }

  /// Bit operations are coerced to values on [0, 2^32). The coercion changes
  /// the interpretation of the 32-bit value from signed to unsigned.  Most
  /// JavaScript operations interpret their operands as signed and generate
  /// signed results.
  JS.Expression _coerceBitOperationResultToUnsigned(
      Expression node, JS.Expression uncoerced) {
    // Don't coerce if the parent will coerce.
    AstNode parent = _parentOperation(node);
    if (_nodeIsBitwiseOperation(parent)) return uncoerced;

    // Don't do a no-op coerce if the most significant bit is zero.
    if (_is31BitUnsigned(node)) return uncoerced;

    // If the consumer of the expression is '==' or '!=' with a constant that
    // fits in 31 bits, adding a coercion does not change the result of the
    // comparison, e.g.  `a & ~b == 0`.
    if (parent is BinaryExpression) {
      var tokenType = parent.operator.type;
      Expression left = parent.leftOperand;
      Expression right = parent.rightOperand;
      if (tokenType == TokenType.EQ_EQ || tokenType == TokenType.BANG_EQ) {
        const int MAX = 0x7fffffff;
        if (_asIntInRange(right, 0, MAX) != null) return uncoerced;
        if (_asIntInRange(left, 0, MAX) != null) return uncoerced;
      } else if (tokenType == TokenType.GT_GT) {
        if (_isDefinitelyNonNegative(left) &&
            _asIntInRange(right, 0, 31) != null) {
          // Parent will generate `# >>> n`.
          return uncoerced;
        }
      }
    }
    return js.call('# >>> 0', uncoerced);
  }

  AstNode _parentOperation(AstNode node) {
    node = node.parent;
    while (node is ParenthesizedExpression) node = node.parent;
    return node;
  }

  bool _nodeIsBitwiseOperation(AstNode node) {
    if (node is BinaryExpression) {
      switch (node.operator.type) {
        case TokenType.AMPERSAND:
        case TokenType.BAR:
        case TokenType.CARET:
          return true;
      }
      return false;
    }
    if (node is PrefixExpression) {
      return node.operator.type == TokenType.TILDE;
    }
    return false;
  }

  int _asIntInRange(Expression expr, int low, int high) {
    expr = expr.unParenthesized;
    if (expr is IntegerLiteral) {
      var value = getLiteralBigIntValue(expr);
      if (value != null &&
          value >= BigInt.from(low) &&
          value <= BigInt.from(high)) {
        return expr.value;
      }
      return null;
    }

    Identifier id;
    if (expr is SimpleIdentifier) {
      id = expr;
    } else if (expr is PrefixedIdentifier && !expr.isDeferred) {
      id = expr.identifier;
    } else {
      return null;
    }
    var element = id.staticElement;
    if (element is PropertyAccessorElement && element.isGetter) {
      var variable = element.variable;
      int value = variable?.computeConstantValue()?.toIntValue();
      if (value != null && value >= low && value <= high) return value;
    }
    return null;
  }

  bool _isDefinitelyNonNegative(Expression expr) {
    expr = expr.unParenthesized;
    if (expr is IntegerLiteral) {
      var value = getLiteralBigIntValue(expr);
      return value != null && value >= BigInt.from(0);
    }
    if (_nodeIsBitwiseOperation(expr)) return true;
    // TODO(sra): Lengths of known list types etc.
    return false;
  }

  /// Does the parent of [node] mask the result to [width] bits or fewer?
  bool _parentMasksToWidth(AstNode node, int width) {
    AstNode parent = _parentOperation(node);
    if (parent == null) return false;
    if (_nodeIsBitwiseOperation(parent)) {
      if (parent is BinaryExpression &&
          parent.operator.type == TokenType.AMPERSAND) {
        Expression left = parent.leftOperand;
        Expression right = parent.rightOperand;
        final int MAX = (1 << width) - 1;
        if (_asIntInRange(right, 0, MAX) != null) return true;
        if (_asIntInRange(left, 0, MAX) != null) return true;
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
      if (expr is IntegerLiteral && expr.value != null) {
        return expr.value >= 0 ? expr.value.bitLength : MAX;
      }
      if (++depth > 5) return MAX;
      if (expr is BinaryExpression) {
        var left = expr.leftOperand.unParenthesized;
        var right = expr.rightOperand.unParenthesized;
        switch (expr.operator.type) {
          case TokenType.AMPERSAND:
            return min(bitWidth(left, depth), bitWidth(right, depth));

          case TokenType.BAR:
          case TokenType.CARET:
            return max(bitWidth(left, depth), bitWidth(right, depth));

          case TokenType.GT_GT:
            int shiftValue = _asIntInRange(right, 0, 31);
            if (shiftValue != null) {
              int leftWidth = bitWidth(left, depth);
              return leftWidth == MAX ? MAX : max(0, leftWidth - shiftValue);
            }
            return MAX;

          case TokenType.LT_LT:
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
      int value = _asIntInRange(expr, 0, 0x7fffffff);
      if (value != null) return value.bitLength;
      return MAX;
    }

    return bitWidth(expr, 0) < 32;
  }

  bool _isNull(Expression expr) =>
      expr is NullLiteral || getStaticType(expr).isDartCoreNull;

  SimpleIdentifier _createTemporary(String name, DartType type,
      {bool nullable = true, JS.Expression variable, bool dynamicInvoke}) {
    // We use an invalid source location to signal that this is a temporary.
    // See [_isTemporary].
    // TODO(jmesserly): alternatives are
    // * (ab)use Element.isSynthetic, which isn't currently used for
    //   LocalVariableElementImpl, so we could repurpose to mean "temp".
    // * add a new property to LocalVariableElementImpl.
    // * create a new subtype of LocalVariableElementImpl to mark a temp.
    var id = astFactory
        .simpleIdentifier(StringToken(TokenType.IDENTIFIER, name, -1));

    variable ??= JS.TemporaryId(name);

    var idElement = TemporaryVariableElement.forNode(id, variable)
      ..enclosingElement = _currentElement;
    id.staticElement = idElement;
    id.staticType = type;
    setIsDynamicInvoke(id, dynamicInvoke ?? type.isDynamic);
    addTemporaryVariable(idElement, nullable: nullable);
    return id;
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
      Map<JS.MetaLetVariable, JS.Expression> scope, Expression expr,
      {Expression context}) {
    Expression result;
    if (expr is IndexExpression) {
      IndexExpression index = expr;
      result = astFactory.indexExpressionForTarget(
          _bindValue(scope, 'o', index.target, context: context),
          index.leftBracket,
          _bindValue(scope, 'i', index.index, context: context),
          index.rightBracket);
    } else if (expr is PropertyAccess) {
      PropertyAccess prop = expr;
      result = astFactory.propertyAccess(
          _bindValue(scope, 'o', _getTarget(prop), context: context),
          prop.operator,
          prop.propertyName);
    } else if (expr is PrefixedIdentifier) {
      PrefixedIdentifier ident = expr;
      if (isLibraryPrefix(ident.prefix)) {
        return expr;
      }
      result = astFactory.prefixedIdentifier(
          _bindValue(scope, 'o', ident.prefix, context: context)
              as SimpleIdentifier,
          ident.period,
          ident.identifier);
    } else {
      return expr as SimpleIdentifier;
    }
    result.staticType = expr.staticType;
    setIsDynamicInvoke(result, isDynamicInvoke(expr));
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
  Expression _bindValue(Map<JS.MetaLetVariable, JS.Expression> scope,
      String name, Expression expr,
      {Expression context}) {
    // No need to do anything for stateless expressions.
    if (isStateless(_currentFunction, expr, context)) return expr;

    var variable = JS.MetaLetVariable(name);
    var t = _createTemporary(name, getStaticType(expr),
        variable: variable,
        dynamicInvoke: isDynamicInvoke(expr),
        nullable: isNullable(expr));
    scope[variable] = _visitExpression(expr);
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
  ///     // pseudocode mix of Scheme and JS:
  ///     (let* (x1=expr1, x2=expr2, t=expr1[expr2]) { x1[x2] = t + 1; t })
  ///
  /// The [JS.MetaLet] nodes automatically simplify themselves if they can.
  /// For example, if the result value is not used, then `t` goes away.
  @override
  JS.Expression visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (jsTypeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (!isNullable(expr)) {
        return js.call('#$op', _visitExpression(expr));
      }
    }

    assert(op.lexeme == '++' || op.lexeme == '--');

    // Handle the left hand side, to ensure each of its subexpressions are
    // evaluated only once.
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var left = _bindLeftHandSide(vars, expr, context: expr);

    // Desugar `x++` as `(x1 = x0 + 1, x0)` where `x0` is the original value
    // and `x1` is the new value for `x`.
    var x = _bindValue(vars, 'x', left, context: expr);

    var one = ast.integerLiteral(1)..staticType = types.intType;
    var increment = ast.binaryExpression(x, op.lexeme[0], one)
      ..staticElement = node.staticElement
      ..staticType = getStaticType(expr);

    var body = <JS.Expression>[_emitSet(left, increment), _visitExpression(x)];
    return JS.MetaLet(vars, body, statelessResult: true);
  }

  @override
  JS.Expression visitPrefixExpression(PrefixExpression node) {
    var op = node.operator;

    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    if (op.lexeme == '!') return _visitTest(node);

    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (jsTypeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (op.lexeme == '~') {
        if (jsTypeRep.isNumber(dispatchType)) {
          JS.Expression jsExpr = js.call('~#', notNull(expr));
          return _coerceBitOperationResultToUnsigned(node, jsExpr);
        }
        return _emitOperatorCall(expr, op.lexeme[0], []);
      }
      if (!isNullable(expr)) {
        return js.call('$op#', _visitExpression(expr));
      }
      if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var vars = <JS.MetaLetVariable, JS.Expression>{};
        var x = _bindLeftHandSide(vars, expr, context: expr);

        var one = ast.integerLiteral(1)..staticType = types.intType;
        var increment = ast.binaryExpression(x, op.lexeme[0], one)
          ..staticElement = node.staticElement
          ..staticType = getStaticType(expr);

        return JS.MetaLet(vars, [_emitSet(x, increment)]);
      }
      return js.call('$op#', notNull(expr));
    }

    if (op.lexeme == '++' || op.lexeme == '--') {
      // Increment or decrement requires expansion.
      // Desugar `++x` as `x = x + 1`, ensuring that if `x` has subexpressions
      // (for example, x is IndexExpression) we evaluate those once.
      var one = ast.integerLiteral(1)..staticType = types.intType;
      return _emitOpAssign(expr, one, op.lexeme[0], node.staticElement,
          context: expr);
    }

    var operatorName = op.lexeme;
    // Use the name from the Dart spec.
    if (operatorName == '-') operatorName = 'unary-';
    return _emitOperatorCall(expr, operatorName, []);
  }

  // Cascades can contain [IndexExpression], [MethodInvocation] and
  // [PropertyAccess]. The code generation for those is handled in their
  // respective visit methods.
  @override
  visitCascadeExpression(CascadeExpression node) {
    var savedCascadeTemp = _cascadeTarget;

    var vars = <JS.MetaLetVariable, JS.Expression>{};
    _cascadeTarget = _bindValue(vars, '_', node.target, context: node);
    var sections = _visitExpressionList(node.cascadeSections);
    sections.add(_visitExpression(_cascadeTarget));
    var result = JS.MetaLet(vars, sections, statelessResult: true);
    _cascadeTarget = savedCascadeTemp;
    return result;
  }

  @override
  JS.Expression visitParenthesizedExpression(ParenthesizedExpression node) =>
      // The printer handles precedence so we don't need to.
      _visitExpression(node.expression);

  JS.Parameter _emitFormalParameter(FormalParameter node) {
    var id = _emitParameter(node.declaredElement, declaration: true)
      ..sourceInformation = _nodeSpan(node);
    var isRestArg = node is! DefaultFormalParameter &&
        findAnnotation(node.declaredElement, isJsRestAnnotation) != null;
    return isRestArg ? JS.RestParameter(id) : id;
  }

  @override
  JS.This visitThisExpression(ThisExpression node) => JS.This();

  @override
  JS.Expression visitSuperExpression(SuperExpression node) => JS.Super();

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isDeferredLoadLibrary(node.prefix, node.identifier)) {
      // We are tearing off "loadLibrary" on a library prefix.
      return runtimeCall('loadLibrary');
    }

    if (isLibraryPrefix(node.prefix)) {
      return visitSimpleIdentifier(node.identifier, node);
    } else {
      return _emitPropertyGet(node.prefix, node.identifier, node);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.operator.lexeme == '?.' && isNullable(node.target)) {
      return _emitNullSafe(node);
    }
    return _emitPropertyGet(_getTarget(node), node.propertyName, node);
  }

  JS.Expression _emitNullSafe(Expression node) {
    // Desugar `obj?.name` as ((x) => x == null ? null : x.name)(obj)
    var target = _getTarget(node);
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var t = _bindValue(vars, 't', target, context: target);

    var desugared = _stripNullAwareOp(node, t);
    return JS.MetaLet(vars, [
      js.call('# == null ? null : #',
          [_visitExpression(t), _visitExpression(desugared)])
    ]);
  }

  // TODO(jmesserly): this is dropping source location.
  Expression _stripNullAwareOp(Expression node, Expression newTarget) {
    if (node is PropertyAccess) {
      return ast.propertyAccess(newTarget, node.propertyName);
    } else {
      var invoke = node as MethodInvocation;
      return ast.methodInvoke(newTarget, invoke.methodName,
          invoke.typeArguments, invoke.argumentList.arguments)
        ..staticInvokeType = invoke.staticInvokeType;
    }
  }

  List<JS.Expression> _getTypeArgs(Element member, DartType instantiated) {
    DartType type;
    if (member is ExecutableElement) {
      type = member.type;
    } else if (member is VariableElement) {
      type = member.type;
    }

    // TODO(jmesserly): handle explicitly passed type args.
    if (type == null) return null;
    return _emitFunctionTypeArguments(type, instantiated);
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  JS.Expression _emitPropertyGet(
      Expression receiver, SimpleIdentifier memberId, Expression accessNode) {
    var resultType = accessNode.staticType;
    var accessor = memberId.staticElement;
    var memberName = memberId.name;
    var receiverType = getStaticType(receiver);
    if (memberName == 'call' && _isDirectCallable(receiverType)) {
      // Tearoff of `call` on a function type is a no-op;
      return _visitExpression(receiver);
    }

    // If `member` is a getter/setter, get the corresponding
    var field = _getNonAccessorElement(accessor);
    bool isStatic = field is ClassMemberElement && field.isStatic;
    var jsName = _emitMemberName(memberName,
        type: receiverType, isStatic: isStatic, element: accessor);
    if (isDynamicInvoke(receiver)) {
      return runtimeCall(
          'dload$_replSuffix(#, #)', [_visitExpression(receiver), jsName]);
    }

    var jsTarget = _emitTarget(receiver, accessor, isStatic);
    var isSuper = jsTarget is JS.Super;
    if (isSuper &&
        accessor.isSynthetic &&
        field is FieldElementImpl &&
        !virtualFields.isVirtual(field)) {
      // If super.x is a sealed field, then x is an instance property since
      // subclasses cannot override x.
      jsTarget = JS.This()..sourceInformation = jsTarget.sourceInformation;
    }

    JS.Expression result;
    if (isObjectMember(memberName) && isNullable(receiver)) {
      if (_isObjectMethodTearoff(memberName)) {
        result = runtimeCall('bind(#, #)', [jsTarget, jsName]);
      } else {
        result = runtimeCall('#(#)', [memberName, jsTarget]);
      }
    } else if (accessor is MethodElement &&
        _reifyTearoff(accessor, accessNode)) {
      if (isStatic) {
        result = _emitFunctionTagged(
            _emitTargetAccess(jsTarget, jsName, accessor, memberId),
            accessor.type);
      } else if (isSuper) {
        result = runtimeCall('bind(this, #, #)',
            [jsName, _emitTargetAccess(jsTarget, jsName, accessor, memberId)]);
      } else {
        result = runtimeCall('bind(#, #)', [jsTarget, jsName]);
      }
    } else {
      result = _emitTargetAccess(jsTarget, jsName, accessor, memberId);
    }

    var typeArgs = _getTypeArgs(accessor, resultType);
    return typeArgs == null
        ? result
        : runtimeCall('gbind(#, #)', [result, typeArgs]);
  }

  bool _reifyTearoff(ExecutableElement element, Expression node) {
    return !inInvocationContext(node) &&
        !_usesJSInterop(element) &&
        !_isInForeignJS &&
        _reifyFunctionType(element);
  }

  bool _isDirectCallable(DartType t) =>
      t is FunctionType || t is InterfaceType && _usesJSInterop(t.element);

  JS.Expression _getImplicitCallTarget(InterfaceType fromType) {
    var callMethod = fromType.lookUpInheritedMethod('call');
    if (callMethod == null || _usesJSInterop(fromType.element)) return null;
    return _emitMemberName('call', type: fromType, element: callMethod);
  }

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  JS.Expression _emitOperatorCall(
      Expression target, String name, List<Expression> args,
      [Element element]) {
    // TODO(jmesserly): calls that don't pass `element` are probably broken for
    // `super` calls from disallowed super locations.
    var type = getStaticType(target);
    var memberName = _emitMemberName(name, type: type);
    if (isDynamicInvoke(target)) {
      // dynamic dispatch
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return runtimeCall('$dynamicHelper(#, #)',
            [_visitExpression(target), _visitExpressionList(args)]);
      } else {
        return runtimeCall('dsend(#, #, [#])',
            [_visitExpression(target), memberName, _visitExpressionList(args)]);
      }
    }

    // Generic dispatch to a statically known method.
    return js.call('#(#)', [
      _emitTargetAccess(_visitExpression(target), memberName, element, null),
      _visitExpressionList(args)
    ]);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    var target = _getTarget(node);
    if (_useNativeJsIndexer(target.staticType)) {
      return JS.PropertyAccess(
          _visitExpression(target), _visitExpression(node.index));
    }
    return _emitOperatorCall(target, '[]', [node.index], node.staticElement);
  }

  // TODO(jmesserly): ideally we'd check the method and see if it is marked
  // `external`, but that doesn't work because it isn't in the element model.
  bool _useNativeJsIndexer(DartType type) =>
      findAnnotation(type.element, isJSAnnotation) != null;

  /// Gets the target of a [PropertyAccess], [IndexExpression], or
  /// [MethodInvocation]. These three nodes can appear in a [CascadeExpression].
  Expression _getTarget(Expression node) {
    if (node is IndexExpression) {
      return node.isCascaded ? _cascadeTarget : node.target;
    } else if (node is PropertyAccess) {
      return node.isCascaded ? _cascadeTarget : node.target;
    } else if (node is MethodInvocation) {
      return node.isCascaded ? _cascadeTarget : node.target;
    } else {
      return null;
    }
  }

  @override
  JS.Expression visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visitTest(node.condition),
      _visitExpression(node.thenExpression),
      _visitExpression(node.elseExpression)
    ]);
  }

  @override
  JS.Expression visitThrowExpression(ThrowExpression node) {
    return runtimeCall('throw(#)', _visitExpression(node.expression));
  }

  @override
  JS.Expression visitRethrowExpression(RethrowExpression node) {
    return runtimeCall('rethrow(#)', _visitExpression(_catchParameter));
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
  JS.If visitIfStatement(IfStatement node) {
    return JS.If(_visitTest(node.condition), _visitScope(node.thenStatement),
        _visitScope(node.elseStatement));
  }

  @override
  JS.For visitForStatement(ForStatement node) {
    var init = _visitExpression(node.initialization) ??
        visitVariableDeclarationList(node.variables);
    var updaters = node.updaters;
    JS.Expression update;
    if (updaters != null && updaters.isNotEmpty) {
      update =
          JS.Expression.binary(updaters.map(_visitExpression).toList(), ',')
              .toVoidExpression();
    }
    var condition = _visitTest(node.condition);
    return JS.For(init, condition, update, _visitScope(node.body));
  }

  @override
  JS.While visitWhileStatement(WhileStatement node) {
    return JS.While(_visitTest(node.condition), _visitScope(node.body));
  }

  @override
  JS.Do visitDoStatement(DoStatement node) {
    return JS.Do(_visitScope(node.body), _visitTest(node.condition));
  }

  @override
  JS.Statement visitForEachStatement(ForEachStatement node) {
    if (node.awaitKeyword != null) {
      return _emitAwaitFor(node);
    }

    var init = _visitExpression(node.identifier);
    var iterable = _visitExpression(node.iterable);
    var body = _visitScope(node.body);
    if (init == null) {
      var id = node.loopVariable.identifier;
      init = js.call('let #', _emitVariableDef(id));
      if (_annotatedNullCheck(node.loopVariable.declaredElement)) {
        body = JS.Block([_nullParameterCheck(JS.Identifier(id.name)), body]);
      }
    }
    return JS.ForOf(init, iterable, body);
  }

  JS.Statement _emitAwaitFor(ForEachStatement node) {
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
    var streamIterator =
        rules.instantiateToBounds(_asyncStreamIterator) as InterfaceType;
    var createStreamIter = _emitInstanceCreationExpression(
        streamIterator.element.unnamedConstructor,
        streamIterator,
        () => [_visitExpression(node.iterable)]);
    var iter = JS.TemporaryId('iter');
    var variable = node.identifier ?? node.loopVariable.identifier;
    var init = _visitExpression(node.identifier);
    if (init == null) {
      init = js.call('let # = #.current', [_emitVariableDef(variable), iter]);
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
          JS.Yield(js.call('#.moveNext()', iter))
            ..sourceInformation = _nodeStart(variable),
          init,
          _visitStatement(node.body),
          JS.Yield(js.call('#.cancel()', iter))
            ..sourceInformation = _nodeStart(variable)
        ]);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    var label = node.label;
    return JS.Break(label?.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    var label = node.label;
    return JS.Continue(label?.name);
  }

  @override
  visitTryStatement(TryStatement node) {
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var finallyBlock = _visitStatement(node.finallyBlock)?.toBlock();
    _superAllowed = savedSuperAllowed;
    return JS.Try(_visitStatement(node.body).toBlock(),
        _visitCatch(node.catchClauses), finallyBlock);
  }

  JS.Catch _visitCatch(NodeList<CatchClause> clauses) {
    if (clauses == null || clauses.isEmpty) return null;

    // TODO(jmesserly): need a better way to get a temporary variable.
    // This could incorrectly shadow a user's name.
    var savedCatch = _catchParameter;

    var isSingleCatch =
        clauses.length == 1 && clauses.single.exceptionParameter != null;
    if (isSingleCatch) {
      // Special case for a single catch.
      _catchParameter = clauses.single.exceptionParameter;
    } else {
      _catchParameter = _createTemporary('e', types.dynamicType);
    }

    JS.Statement catchBody =
        js.statement('throw #;', _emitSimpleIdentifier(_catchParameter));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(clause, catchBody);
    }

    var catchVarDecl = _emitSimpleIdentifier(_catchParameter) as JS.Identifier;
    if (isSingleCatch) {
      catchVarDecl..sourceInformation = _nodeStart(_catchParameter);
    }
    _catchParameter = savedCatch;
    return JS.Catch(catchVarDecl, JS.Block([catchBody]));
  }

  JS.Statement _catchClauseGuard(CatchClause clause, JS.Statement otherwise) {
    var then = visitCatchClause(clause);

    // Discard following clauses, if any, as they are unreachable.
    if (clause.exceptionType == null) return then;

    // TODO(jmesserly): this is inconsistent with [visitIsExpression], which
    // has special case for typeof.
    var castType = _emitType(clause.exceptionType.type);

    return JS.If(
        js.call('#.is(#)', [castType, _emitSimpleIdentifier(_catchParameter)]),
        then,
        otherwise)
      ..sourceInformation = _nodeStart(clause);
  }

  /// Visits the catch clause body. This skips the exception type guard, if any.
  /// That is handled in [_visitCatch].
  @override
  JS.Statement visitCatchClause(CatchClause node) {
    var body = <JS.Statement>[];

    var savedCatch = _catchParameter;
    var vars = HashSet<String>();
    if (node.catchKeyword != null) {
      var name = node.exceptionParameter;
      if (name == _catchParameter) {
        vars.add(name.name);
      } else if (name != null) {
        vars.add(name.name);
        body.add(js.statement('let # = #;',
            [_emitVariableDef(name), _emitSimpleIdentifier(_catchParameter)]));
        _catchParameter = name;
      }
      var stackVar = node.stackTraceParameter;
      if (stackVar != null) {
        vars.add(stackVar.name);
        body.add(js.statement('let # = #.stackTrace(#);', [
          _emitVariableDef(stackVar),
          runtimeModule,
          _emitSimpleIdentifier(name)
        ]));
      }
    }

    body.add(_visitStatement(node.body).toScopedBlock(vars));
    _catchParameter = savedCatch;
    return JS.Statement.from(body);
  }

  @override
  JS.SwitchCase visitSwitchCase(SwitchCase node) {
    var expr = _visitExpression(node.expression);
    var body = _visitStatementList(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return JS.SwitchCase(expr, JS.Block(body));
  }

  @override
  JS.SwitchCase visitSwitchDefault(SwitchDefault node) {
    var body = _visitStatementList(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return JS.SwitchCase.defaultCase(JS.Block(body));
  }

  JS.SwitchCase _emitSwitchMember(SwitchMember node) {
    if (node is SwitchCase) {
      return visitSwitchCase(node);
    } else {
      return visitSwitchDefault(node as SwitchDefault);
    }
  }

  @override
  JS.Switch visitSwitchStatement(SwitchStatement node) => JS.Switch(
      _visitExpression(node.expression),
      node.members?.map(_emitSwitchMember)?.toList());

  @override
  JS.Statement visitLabeledStatement(LabeledStatement node) {
    var result = _visitStatement(node.statement);
    for (var label in node.labels.reversed) {
      result = JS.LabeledStatement(label.label.name, result);
    }
    return result;
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    var value = getLiteralBigIntValue(node);

    // Report an error if the integer literal cannot be exactly represented in
    // JS (because JS only has support for doubles).
    //
    // This applies regardless in an int or double context.
    var valueInJS = BigInt.from(value.toDouble());
    if (value != valueInJS) {
      assert(node.staticType == intClass.type || options.unsafeForceCompile,
          'int literals in double contexts should be checked by Analyzer.');

      var lexeme = node.literal.lexeme;
      var nearest = (lexeme.startsWith("0x") || lexeme.startsWith("0X"))
          ? '0x${valueInJS.toRadixString(16)}'
          : '$valueInJS';
      errors.add(AnalysisError(_currentCompilationUnit.source, node.offset,
          node.length, invalidJSInteger, [lexeme, nearest]));
    }
    return JS.LiteralNumber('$valueInJS');
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) => js.number(node.value);

  @override
  visitNullLiteral(NullLiteral node) => JS.LiteralNull();

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    return _emitConst(() => _emitDartSymbol(node.components.join('.')));
  }

  JS.Expression _emitDartSymbol(String name) {
    // TODO(vsm): Handle qualified symbols correctly.
    var last = name.substring(name.lastIndexOf('.') + 1);
    var jsName = js.string(name, "'");
    if (last.startsWith('_')) {
      var nativeSymbol = emitPrivateNameSymbol(currentLibrary, last);
      return js.call('new #.new(#, #)', [
        _emitConstructorAccess(privateSymbolClass.type),
        jsName,
        nativeSymbol
      ]);
    } else {
      return js
          .call('#.new(#)', [_emitConstructorAccess(types.symbolType), jsName]);
    }
  }

  @override
  JS.Expression visitListLiteral(ListLiteral node) {
    var elementType = (node.staticType as InterfaceType).typeArguments[0];
    if (!node.isConst) {
      return _emitList(elementType, _visitExpressionList(node.elements));
    }
    return _cacheConst(
        () => _emitConstList(elementType, _visitExpressionList(node.elements)));
  }

  JS.Expression _emitConstList(
      DartType elementType, List<JS.Expression> elements) {
    // dart.constList helper internally depends on _interceptors.JSArray.
    _declareBeforeUse(_jsArray);
    return runtimeCall('constList([#], #)', [elements, _emitType(elementType)]);
  }

  JS.Expression _emitList(DartType itemType, List<JS.Expression> items) {
    var list = JS.ArrayInitializer(items);

    // TODO(jmesserly): analyzer will usually infer `List<Object>` because
    // that is the least upper bound of the element types. So we rarely
    // generate a plain `List<dynamic>` anymore.
    if (itemType.isDynamic) return list;

    // Call `new JSArray<E>.of(list)`
    var arrayType = _jsArray.type.instantiate([itemType]);
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
      return entries;
    }

    var type = node.staticType as InterfaceType;
    if (!node.isConst) {
      var mapType = _emitMapImplType(type);
      if (node.entries.isEmpty) {
        return js.call('new #.new()', [mapType]);
      }
      return js.call('new #.from([#])', [mapType, emitEntries()]);
    }
    return _cacheConst(() => _emitConstMap(type, emitEntries()));
  }

  JS.Expression _emitConstMap(InterfaceType type, List<JS.Expression> entries) {
    var typeArgs = type.typeArguments;
    return runtimeCall('constMap(#, #, [#])',
        [_emitType(typeArgs[0]), _emitType(typeArgs[1]), entries]);
  }

  JS.Expression _emitMapImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= jsTypeRep.isPrimitive(typeArgs[0]);
    type = identity ? identityHashMapImplType : linkedHashMapImplType;
    return _emitType(type.instantiate(typeArgs));
  }

  JS.Expression _emitSetImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= jsTypeRep.isPrimitive(typeArgs[0]);
    type = identity ? identityHashSetImplType : linkedHashSetImplType;
    return _emitType(type.instantiate(typeArgs));
  }

  @override
  JS.LiteralString visitSimpleStringLiteral(SimpleStringLiteral node) =>
      js.escapedString(node.value, '"');

  @override
  JS.Expression visitAdjacentStrings(AdjacentStrings node) {
    var nodes = node.strings;
    if (nodes == null || nodes.isEmpty) return null;
    return JS.Expression.binary(_visitExpressionList(nodes), '+');
  }

  @override
  JS.Expression visitStringInterpolation(StringInterpolation node) {
    var parts = <JS.Expression>[];
    for (var elem in node.elements) {
      if (elem is InterpolationString) {
        if (elem.value.isEmpty) continue;
        parts.add(js.escapedString(elem.value, '"'));
      } else {
        var e = (elem as InterpolationExpression).expression;
        var jsExpr = _visitExpression(e);
        parts.add(e.staticType == types.stringType && !isNullable(e)
            ? jsExpr
            : runtimeCall('str(#)', jsExpr));
      }
    }
    if (parts.isEmpty) return js.string('');
    return JS.Expression.binary(parts, '+');
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) =>
      _visitExpression(node.expression);

  @override
  visitBooleanLiteral(BooleanLiteral node) => js.boolean(node.value);

  /// Visit a Dart [node] that produces a JS expression, and attaches a source
  /// location.
  // TODO(jmesserly): parameter type should be `Expression`
  JS.Expression _visitExpression(AstNode node) {
    if (node == null) return null;
    var e = node.accept<JS.Node>(this) as JS.Expression;
    e.sourceInformation ??= _nodeStart(node);
    return e;
  }

  /// Visit a Dart [node] that produces a JS statement, and marks its source
  /// location for debugging.
  JS.Statement _visitStatement(AstNode node) {
    if (node == null) return null;
    var s = node.accept<JS.Node>(this) as JS.Statement;
    if (s is! Block) s.sourceInformation = _nodeStart(node);
    return s;
  }

  /// Visits [nodes] with [_visitStatement].
  List<JS.Statement> _visitStatementList(Iterable<AstNode> nodes) {
    return nodes?.map(_visitStatement)?.toList();
  }

  /// Visits [nodes] with [_visitExpression].
  List<JS.Expression> _visitExpressionList(Iterable<AstNode> nodes) {
    return nodes?.map(_visitExpression)?.toList();
  }

  /// Gets the start position of [node] for use in source mapping.
  ///
  /// This is the most common kind of marking, and is used for most expressions
  /// and statements.
  SourceLocation _nodeStart(AstNode node) => _getLocation(node.offset);

  /// Gets the end position of [node] for use in source mapping.
  ///
  /// This is used to complete a hover span, when we know the start position has
  /// already been emitted. For example, `foo.bar` we only need to mark the end
  /// of `.bar` to ensure `foo.bar` has a hover tooltip.
  NodeEnd _nodeEnd(AstNode node) {
    var loc = _getLocation(node.end);
    return loc != null ? NodeEnd(loc) : null;
  }

  /// Gets the end of a function for source mapping.
  ///
  /// JS wants a marking before the closing brace/semicolon, rather than after,
  /// so this adjusts appropriately (it uses [node.endToken.offset] rather than
  /// [node.end]).
  ///
  /// Every JS function should have an end marking for stepping out of it.
  /// Alternatively this can be supplied with [_functionSpan].
  NodeEnd _functionEnd(AstNode node) {
    var loc = _getLocation(node.endToken.offset);
    return loc != null ? NodeEnd(loc) : null;
  }

  /// Similar to [_functionEnd] but also marks the start of the function.
  ///
  /// This is used when we want to support hovering.
  NodeSpan _functionSpan(AstNode node) {
    var start = _getLocation(node.offset);
    var end = _getLocation(node.endToken.offset);
    return start != null && end != null ? NodeSpan(start, end) : null;
  }

  /// Combines [_nodeStart] and [_nodeEnd], used when we want to support
  /// hovering on the [node].
  NodeSpan _nodeSpan(AstNode node) {
    var start = _getLocation(node.offset);
    var end = _getLocation(node.end);
    return start != null && end != null ? NodeSpan(start, end) : null;
  }

  /// Adds a hover comment for Dart [node] using JS expression [expr], where
  /// that expression would not otherwise not be generated into source code.
  ///
  /// For example, top-level and static fields are defined as lazy properties,
  /// on the library/class, so their access expressions do not appear in the
  /// source code.
  HoverComment _hoverComment(JS.Expression expr, AstNode node) {
    var start = _getLocation(node.offset);
    var end = _getLocation(node.end);
    return start != null && end != null ? HoverComment(expr, start, end) : null;
  }

  SourceLocation _getLocation(int offset) {
    if (offset == -1) return null;
    var unit = _currentCompilationUnit;
    Uri fileUri;
    if (unit.source.isInSystemLibrary) {
      fileUri = unit.source.uri;
    } else {
      // TODO(jmesserly): this needs serious cleanup.
      // There does appear to be something strange going on with Analyzer
      // URIs if we try and use them directly on Windows.
      // See also compiler.dart placeSourceMap, which could use cleanup too.
      var sourcePath = unit.source.fullName;
      fileUri = sourcePath.startsWith('package:')
          ? Uri.parse(sourcePath)
          // TODO(jmesserly): shouldn't this be path.toUri?
          : Uri.file(sourcePath);
    }
    var loc = unit.lineInfo.getLocation(offset);
    return SourceLocation(offset,
        sourceUrl: fileUri,
        line: loc.lineNumber - 1,
        column: loc.columnNumber - 1);
  }

  /// Generates an expression for a boolean conversion context (if, while, &&,
  /// etc.), where conversions and null checks are implemented via `dart.test`
  /// to give a more helpful message.
  // TODO(sra): When nullablility is available earlier, it would be cleaner to
  // build an input AST where the boolean conversion is a single AST node.
  JS.Expression _visitTest(Expression node) {
    if (node == null) return null;

    if (node is PrefixExpression && node.operator.lexeme == '!') {
      // TODO(leafp): consider a peephole opt for identical
      // and == here.
      return js.call('!#', _visitTest(node.operand));
    }
    if (node is ParenthesizedExpression) {
      return _visitTest(node.expression);
    }
    if (node is BinaryExpression) {
      JS.Expression shortCircuit(String code) {
        return js.call(code,
            [_visitTest(node.leftOperand), _visitTest(node.rightOperand)]);
      }

      var op = node.operator.type.lexeme;
      if (op == '&&') return shortCircuit('# && #');
      if (op == '||') return shortCircuit('# || #');
    }
    if (node is AsExpression && CoercionReifier.isImplicit(node)) {
      assert(node.staticType == types.boolType);
      return runtimeCall('dtest(#)', _visitExpression(node.expression));
    }
    var result = _visitExpression(node);
    if (isNullable(node)) result = runtimeCall('test(#)', result);
    return result;
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  JS.Expression _declareMemberName(ExecutableElement e, {bool useExtension}) {
    return _emitMemberName(_getElementName(e),
        isStatic: e.isStatic,
        useExtension:
            useExtension ?? _extensionTypes.isNativeClass(e.enclosingElement),
        element: e);
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
      {DartType type,
      bool isStatic = false,
      bool useExtension,
      Element element}) {
    // Static members skip the rename steps and may require JS interop renames.
    if (isStatic) {
      return _emitStaticMemberName(name, element);
    }

    // We allow some (illegal in Dart) member names to be used in our private
    // SDK code. These renames need to be included at every declaration,
    // including overrides in subclasses.
    if (element != null) {
      var runtimeName = getJSExportName(element);
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
      return emitPrivateNameSymbol(currentLibrary, name);
    }

    useExtension ??= _isSymbolizedMember(type, name);
    // Rename members that conflict with standard JS members unless we are
    // actually try to access those JS members via interop.
    name = JS.memberNameForDartMember(name, _isExternal(element));
    if (useExtension) {
      return _getExtensionSymbolInternal(name);
    }
    return _propertyName(name);
  }

  JS.Expression _emitStaticMemberName(String name, [Element element]) {
    if (element != null) {
      var jsName = _emitJSInteropStaticMemberName(element);
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

  var _forwardingCache = HashMap<Element, Map<String, Element>>();

  Element _lookupForwardedMember(ClassElement element, String name) {
    // We only care about public methods.
    if (name.startsWith('_')) return null;

    var map = _forwardingCache.putIfAbsent(element, () => {});
    if (map.containsKey(name)) return map[name];

    // Note, for a public member, the library should not matter.
    var library = element.library;
    var member = element.lookUpMethod(name, library) ??
        element.lookUpGetter(name, library) ??
        element.lookUpSetter(name, library);
    var classMember = (member != null &&
            member.isSynthetic &&
            member is PropertyAccessorElement)
        ? member.variable
        : member;
    map[name] = classMember;
    return classMember;
  }

  /// Don't symbolize native members that just forward to the underlying
  /// native member.  We limit this to non-renamed members as the receiver
  /// may be a mock type.
  ///
  /// Note, this is an underlying assumption here that, if another native type
  /// subtypes this one, it also forwards this member to its underlying native
  /// one without renaming.
  bool _isSymbolizedMember(DartType type, String name) {
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).bound;
    }
    if (type == null || type.isDynamic || type.isObject) {
      return isObjectMember(name);
    } else if (type is InterfaceType) {
      var interfaceType = jsTypeRep.getImplementationType(type) ?? type;
      var element = interfaceType.element;
      if (_extensionTypes.isNativeClass(element)) {
        var member = _lookupForwardedMember(element, name);

        // Fields on a native class are implicitly native.
        // Methods/getters/setters are marked external/native.
        if (member is FieldElement ||
            member is ExecutableElement && member.isExternal) {
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
      return _extensionTypes.isNativeInterface(element);
    } else if (type is FunctionType) {
      return true;
    }
    return false;
  }

  /// Returns the canonical name to refer to the Dart library.
  JS.Identifier emitLibraryName(LibraryElement library) {
    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(library,
            () => JS.TemporaryId(jsLibraryName(_libraryRoot, library)));
  }

  /// Return true if this is one of the methods/properties on all Dart Objects
  /// (toString, hashCode, noSuchMethod, runtimeType, ==).
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

  bool _isObjectMethodCall(String name, List<Expression> args) {
    if (name == 'toString') {
      return args.isEmpty;
    } else if (name == 'noSuchMethod') {
      return args.length == 1 && args[0] is! NamedExpression;
    }
    return false;
  }

  // TODO(leafp): Various analyzer pieces computed similar things.
  // Share this logic somewhere?
  DartType _getExpectedReturnType(ExecutableElement element) {
    FunctionType functionType = element.type;
    if (functionType == null) {
      return DynamicTypeImpl.instance;
    }
    var type = functionType.returnType;

    InterfaceType expectedType = null;
    if (element.isAsynchronous) {
      if (element.isGenerator) {
        // Stream<T> -> T
        expectedType = types.streamType;
      } else {
        // Future<T> -> T
        expectedType = types.futureType;
      }
    } else {
      if (element.isGenerator) {
        // Iterable<T> -> T
        expectedType = types.iterableType;
      } else {
        // T -> T
        return type;
      }
    }
    if (type.isDynamic) return type;
    if (type is InterfaceType &&
        (type.element == expectedType.element ||
            expectedType == types.futureType &&
                type.element == types.futureOrType.element)) {
      return type.typeArguments[0];
    }
    // TODO(leafp): The above only handles the case where the return type
    // is exactly Future/Stream/Iterable.  Handle the subtype case.
    return DynamicTypeImpl.instance;
  }

  JS.Expression _throwUnsafe(String message) => runtimeCall(
      'throw(Error(#))', js.escapedString("compile error: $message"));

  JS.Node _unreachable(Object node) {
    throw UnsupportedError('tried to generate an unreachable node: `$node`');
  }

  /// Unused, see methods for emitting declarations.
  @override
  visitAnnotation(node) => _unreachable(node);

  /// Unused, see [_emitArgumentList].
  @override
  visitArgumentList(ArgumentList node) => _unreachable(node);

  /// Unused, see [_emitFieldInitializers].
  @override
  visitAssertInitializer(node) => _unreachable(node);

  /// Not visited, but maybe they should be?
  /// See <https://github.com/dart-lang/sdk/issues/29347>
  @override
  visitComment(node) => _unreachable(node);

  /// Not visited, but maybe they should be?
  /// See <https://github.com/dart-lang/sdk/issues/29347>
  @override
  visitCommentReference(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitConfiguration(node) => _unreachable(node);

  /// Unused, see [_emitConstructor].
  @override
  visitConstructorDeclaration(node) => _unreachable(node);

  /// Unused, see [_emitFieldInitializers].
  @override
  visitConstructorFieldInitializer(node) => _unreachable(node);

  /// Unused, see [_emitRedirectingConstructor].
  @override
  visitRedirectingConstructorInvocation(node) => _unreachable(node);

  /// Unused. Handled in [visitForEachStatement].
  @override
  visitDeclaredIdentifier(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitDottedName(node) => _unreachable(node);

  /// Unused, handled by [_emitFormalParameter].
  @override
  visitDefaultFormalParameter(node) => _unreachable(node);

  /// Unused, handled by [_emitFormalParameter].
  @override
  visitSimpleFormalParameter(node) => _unreachable(node);

  /// Unused, handled by [_emitFormalParameter].
  @override
  visitFieldFormalParameter(node) => _unreachable(node);

  /// Unused, handled by [_emitFormalParameter].
  @override
  visitFunctionTypedFormalParameter(node) => _unreachable(node);

  /// Unused, handled by [visitEnumDeclaration].
  @override
  visitEnumConstantDeclaration(node) => _unreachable(node); // see

  /// Unused, see [_defineClass].
  @override
  visitExtendsClause(node) => _unreachable(node);

  /// Unused, see [_emitParameters].
  @override
  visitFormalParameterList(node) => _unreachable(node);

  /// Unused, handled by [visitMixinDeclaration].
  @override
  JS.Node visitOnClause(OnClause node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitShowCombinator(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitHideCombinator(node) => _unreachable(node);

  /// Unused, see [_defineClass].
  @override
  visitImplementsClause(node) => _unreachable(node);

  /// Unused, handled by [visitStringInterpolation].
  @override
  visitInterpolationString(node) => _unreachable(node);

  /// Unused, labels are handled by containing statements.
  @override
  visitLabel(node) => _unreachable(node);

  /// Unused, handled by imports/exports.
  @override
  visitLibraryIdentifier(node) => _unreachable(node);

  /// Unused, see [visitMapLiteral].
  @override
  visitMapLiteralEntry(node) => _unreachable(node);

  /// Unused, see [_emitMethodDeclaration].
  @override
  visitMethodDeclaration(node) => _unreachable(node);

  /// Unused, these are not visited.
  @override
  visitNativeClause(node) => _unreachable(node);

  /// Unused, these are not visited.
  @override
  visitNativeFunctionBody(node) => _unreachable(node);

  /// Unused, handled by [_emitConstructor].
  @override
  visitSuperConstructorInvocation(node) => _unreachable(node);

  /// Unused, this can be handled when emitting the module if needed.
  @override
  visitScriptTag(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitTypeArgumentList(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitTypeParameter(node) => _unreachable(node);

  /// Unused, see [_emitType].
  @override
  visitTypeParameterList(node) => _unreachable(node);

  /// Unused, see [_defineClass].
  @override
  visitWithClause(node) => _unreachable(node);
}

/// Choose a canonical name from the [library] element.
///
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(String libraryRoot, LibraryElement library) {
  var uri = library.source.uri;
  if (uri.scheme == 'dart') {
    return uri.path;
  }
  // TODO(vsm): This is not necessarily unique if '__' appears in a file name.
  var encodedSeparator = '__';
  String qualifiedPath;
  if (uri.scheme == 'package') {
    // Strip the package name.
    // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
    // E.g., "foo/bar.dart" and "foo$47bar.dart" would collide.
    qualifiedPath = uri.pathSegments.skip(1).join(encodedSeparator);
  } else if (path.isWithin(libraryRoot, uri.toFilePath())) {
    qualifiedPath = path
        .relative(uri.toFilePath(), from: libraryRoot)
        .replaceAll(path.separator, encodedSeparator);
  } else {
    // We don't have a unique name.
    throw 'Invalid library root. $libraryRoot does not contain '
        '${uri.toFilePath()}';
  }
  return pathToJSIdentifier(qualifiedPath);
}

/// Debugger friendly name for a Dart Library.
String jsLibraryDebuggerName(String libraryRoot, LibraryElement library) {
  var uri = library.source.uri;
  // For package: and dart: uris show the entire
  if (uri.scheme == 'dart' || uri.scheme == 'package') return uri.toString();

  var filePath = uri.toFilePath();
  if (!path.isWithin(libraryRoot, filePath)) {
    throw 'Invalid library root. $libraryRoot does not contain '
        '${uri.toFilePath()}';
  }
  // Relative path to the library.
  return path.relative(filePath, from: libraryRoot);
}

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
  final JS.Expression jsVariable;

  TemporaryVariableElement.forNode(Identifier name, this.jsVariable)
      : super.forNode(name);

  int get hashCode => identityHashCode(this);

  bool operator ==(Object other) => identical(this, other);
}

LibraryElement _getLibrary(AnalysisContext c, String uri) =>
    c.computeLibraryElement(c.sourceFactory.forUri(uri));

/// Returns `true` if [target] is a prefix for a deferred library and [name]
/// is "loadLibrary".
///
/// If so, the expression should be compiled to call the runtime's
/// "loadLibrary" helper function.
bool _isDeferredLoadLibrary(Expression target, SimpleIdentifier name) {
  if (name.name != "loadLibrary") return false;

  if (target is! SimpleIdentifier) return false;
  var targetIdentifier = target as SimpleIdentifier;

  if (targetIdentifier.staticElement is! PrefixElement) return false;
  var prefix = targetIdentifier.staticElement as PrefixElement;

  // The library the prefix is referring to must come from a deferred import.
  var containingLibrary = resolutionMap
      .elementDeclaredByCompilationUnit(target.root as CompilationUnit)
      .library;
  var imports = containingLibrary.getImportsWithPrefix(prefix);
  return imports.length == 1 && imports[0].isDeferred;
}

bool _annotatedNullCheck(Element e) =>
    e != null && findAnnotation(e, isNullCheckAnnotation) != null;

bool _reifyGeneric(Element e) =>
    e == null ||
    !e.source.isInSystemLibrary ||
    findAnnotation(
            e, (a) => isBuiltinAnnotation(a, '_js_helper', 'NoReifyGeneric')) ==
        null;

bool _reifyFunctionType(Element e) {
  if (e == null) return true;
  var library = e.library;
  if (!library.source.isInSystemLibrary) return true;
  // SDK libraries can skip reification if they request it.
  reifyFunctionTypes(DartObjectImpl a) =>
      isBuiltinAnnotation(a, '_js_helper', 'ReifyFunctionTypes');
  while (e != null) {
    var a = findAnnotation(e, reifyFunctionTypes);
    if (a != null) return a.getField('value').toBoolValue();
    e = e.enclosingElement;
  }
  return true;
}
