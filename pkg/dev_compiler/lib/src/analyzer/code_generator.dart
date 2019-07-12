// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show min, max;

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart' show StringToken;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart'
    show DartObject, DartObjectImpl;
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, NamespaceBuilder;
import 'package:analyzer/src/generated/type_system.dart' show Dart2TypeSystem;
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/task/strong/ast_properties.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart' show SourceLocation;

import '../compiler/js_metalet.dart' as js_ast;
import '../compiler/js_names.dart' as js_ast;
import '../compiler/js_utils.dart' as js_ast;
import '../compiler/module_builder.dart' show pathToJSIdentifier;
import '../compiler/shared_compiler.dart';
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show NodeEnd, NodeSpan, HoverComment;
import 'ast_builder.dart';
import 'driver.dart';
import 'element_helpers.dart';
import 'error_helpers.dart';
import 'extension_types.dart' show ExtensionTypeSet;
import 'js_interop.dart';
import 'js_typerep.dart';
import 'module_compiler.dart' show CompilerOptions;
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
    with
        NullableTypeInference,
        SharedCompiler<LibraryElement, ClassElement, InterfaceType,
            FunctionBody>
    implements
        AstVisitor<js_ast.Node> {
  final SummaryDataStore summaryData;

  final CompilerOptions options;
  final Dart2TypeSystem rules;

  /// Errors that were produced during compilation, if any.
  final ErrorCollector errors;

  @override
  JSTypeRep jsTypeRep;

  /// The list of dart:_runtime SDK functions; these are assumed by other code
  /// in the SDK to be generated before anything else.
  final _internalSdkFunctions = <js_ast.ModuleItem>[];

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
  SimpleIdentifier _rethrowParameter;

  /// In an async* function, this represents the stream controller parameter.
  js_ast.TemporaryId _asyncStarController;

  final _initializingFormalTemps =
      HashMap<ParameterElement, js_ast.TemporaryId>();

  /// The  type provider from the current Analysis [context].
  final TypeProvider types;

  @override
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
  final ClassElement internalSymbolClass;
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

  final _deferredProperties = HashMap<PropertyAccessorElement, js_ast.Method>();

  String _libraryRoot;

  bool _superAllowed = true;

  final _superHelpers = Map<String, js_ast.Method>();

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  /// Information about virtual and overridden fields/getters/setters in the
  /// class we're currently compiling, or `null` if we aren't compiling a class.
  ClassPropertyModel _classProperties;

  /// Information about virtual fields for all libraries in the current build
  /// unit.
  @override
  final virtualFields = VirtualFieldModel();

  final _usedCovariantPrivateMembers = HashSet<ExecutableElement>();

  final DeclaredVariables declaredVariables;

  /// Tracks the temporary variable used to build collections containing
  /// control flow [IfElement] and [ForElement] nodes. Should be saved when
  /// visiting a new control flow tree and restored after.
  js_ast.Expression _currentCollectionVariable;

  CodeGenerator(LinkedAnalysisDriver driver, this.types, this.summaryData,
      this.options, this._extensionTypes, this.errors)
      : rules = Dart2TypeSystem(types),
        declaredVariables = driver.declaredVariables,
        _asyncStreamIterator =
            driver.getClass('dart:async', 'StreamIterator').type,
        _coreIdentical = driver
            .getLibrary('dart:core')
            .publicNamespace
            .get('identical') as FunctionElement,
        _jsArray = driver.getClass('dart:_interceptors', 'JSArray'),
        interceptorClass = driver.getClass('dart:_interceptors', 'Interceptor'),
        coreLibrary = driver.getLibrary('dart:core'),
        boolClass = driver.getClass('dart:core', 'bool'),
        intClass = driver.getClass('dart:core', 'int'),
        doubleClass = driver.getClass('dart:core', 'double'),
        numClass = driver.getClass('dart:core', 'num'),
        nullClass = driver.getClass('dart:core', 'Null'),
        objectClass = driver.getClass('dart:core', 'Object'),
        stringClass = driver.getClass('dart:core', 'String'),
        functionClass = driver.getClass('dart:core', 'Function'),
        internalSymbolClass = driver.getClass('dart:_internal', 'Symbol'),
        privateSymbolClass =
            driver.getClass('dart:_js_helper', 'PrivateSymbol'),
        linkedHashMapImplType =
            driver.getClass('dart:_js_helper', 'LinkedMap').type,
        identityHashMapImplType =
            driver.getClass('dart:_js_helper', 'IdentityMap').type,
        linkedHashSetImplType =
            driver.getClass('dart:collection', '_HashSet').type,
        identityHashSetImplType =
            driver.getClass('dart:collection', '_IdentityHashSet').type,
        syncIterableType =
            driver.getClass('dart:_js_helper', 'SyncIterable').type,
        asyncStarImplType =
            driver.getClass('dart:async', '_AsyncStarImpl').type,
        dartJSLibrary = driver.getLibrary('dart:js') {
    jsTypeRep = JSTypeRep(rules, driver);
  }

  @override
  LibraryElement get currentLibrary => _currentElement.library;

  @override
  Uri get currentLibraryUri => _currentElement.librarySource.uri;

  @override
  FunctionBody get currentFunction => _currentFunction;

  @override
  InterfaceType get privateSymbolType => privateSymbolClass.type;

  @override
  InterfaceType get internalSymbolType => internalSymbolClass.type;

  CompilationUnitElement get _currentCompilationUnit {
    for (var e = _currentElement;; e = e.enclosingElement) {
      if (e is CompilationUnitElement) return e;
    }
  }

  /// The main entry point to JavaScript code generation.
  ///
  /// Takes the metadata for the build unit, as well as resolved trees and
  /// errors, and computes the output module code and optionally the source map.
  js_ast.Program compile(List<CompilationUnit> compilationUnits) {
    _libraryRoot = options.libraryRoot;
    if (!_libraryRoot.endsWith(p.separator)) {
      _libraryRoot += p.separator;
    }

    if (moduleItems.isNotEmpty) {
      throw StateError('Can only call emitModule once.');
    }

    for (var unit in compilationUnits) {
      _usedCovariantPrivateMembers.addAll(getCovariantPrivateMembers(unit));
    }

    // Transform the AST to make coercions explicit.
    compilationUnits = CoercionReifier.reify(compilationUnits);
    var libraries = compilationUnits
        .where((unit) {
          var library = unit.declaredElement.library;
          return unit.declaredElement == library.definingCompilationUnit;
        })
        .map((unit) => unit.declaredElement.library)
        .toList();

    var items = startModule(libraries);
    _typeTable = TypeTable(runtimeModule);

    // Collect all class/type Element -> Node mappings
    // in case we need to forward declare any classes.
    _declarationNodes = HashMap<TypeDefiningElement, AstNode>();
    for (var unit in compilationUnits) {
      for (var declaration in unit.declarations) {
        var element = declaration.declaredElement;
        if (element is TypeDefiningElement) {
          _declarationNodes[element] = declaration;
        }
      }
    }
    if (compilationUnits.isNotEmpty) {
      _constants = ConstFieldVisitor(types, declaredVariables,
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

    moduleItems.addAll(afterClassDefItems);
    afterClassDefItems.clear();

    // Visit directives (for exports)
    compilationUnits.forEach(_emitExportDirectives);

    // Declare imports and extension symbols
    emitImportsAndExtensionSymbols(items);

    // Discharge the type table cache variables and
    // hoisted definitions.
    items.addAll(_typeTable.discharge());
    items.addAll(_internalSdkFunctions);

    return finishModule(items, options.moduleName);
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

  js_ast.PropertyAccess _emitJSInterop(Element e) {
    var jsName = _getJSNameWithoutGlobal(e);
    if (jsName == null) return null;
    return _emitJSInteropForGlobal(jsName);
  }

  js_ast.PropertyAccess _emitJSInteropForGlobal(String name) {
    var parts = name.split('.');
    if (parts.isEmpty) parts = [''];
    js_ast.PropertyAccess access;
    for (var part in parts) {
      access = js_ast.PropertyAccess(
          access ?? runtimeCall('global'), js.escapedString(part, "'"));
    }
    return access;
  }

  /// If the element [e] uses JS interop, this returns the string containing the
  /// JS member's name, otherwise returns null.
  ///
  /// The member name is specified by the parameter to the `@JS()` annotation,
  /// defaulting to the member's name in Dart, for example:
  ///
  ///     @JS('foo')
  ///     external static bar(); // JS name is "foo"
  ///
  ///     @JS()
  ///     external static bar(); // JS name is "bar"
  ///
  ///     static bar() { /* ... */ } // not a JS member; JS name is null
  ///
  String _getJSInteropStaticMemberName(Element e) {
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
    return name;
  }

  /// Choose a canonical name from the [library] element.
  ///
  /// This never uses the library's name (the identifier in the `library`
  /// declaration) as it doesn't have any meaningful rules enforced.
  @override
  String jsLibraryName(LibraryElement library) {
    var uri = library.source.uri;
    if (uri.scheme == 'dart') {
      return isSdkInternalRuntime(library) ? 'dart' : uri.path;
    }
    // TODO(vsm): This is not necessarily unique if '__' appears in a file name.
    var encodedSeparator = '__';
    String qualifiedPath;
    if (uri.scheme == 'package') {
      // Strip the package name.
      // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
      // E.g., "foo/bar.dart" and "foo$47bar.dart" would collide.
      qualifiedPath = uri.pathSegments.skip(1).join(encodedSeparator);
    } else {
      qualifiedPath = p
          .relative(uri.toFilePath(), from: _libraryRoot)
          .replaceAll(p.separator, encodedSeparator)
          .replaceAll('..', encodedSeparator);
    }
    return pathToJSIdentifier(qualifiedPath);
  }

  /// Debugger friendly name for a Dart Library.
  @override
  String jsLibraryDebuggerName(LibraryElement library) {
    var uri = library.source.uri;
    // For package: and dart: uris show the entire
    if (uri.scheme == 'dart' || uri.scheme == 'package') return uri.toString();

    var filePath = uri.toFilePath();
    // Relative path to the library.
    return p.relative(filePath, from: _libraryRoot);
  }

  /// Returns true if the library [l] is dart:_runtime.
  @override
  bool isSdkInternalRuntime(LibraryElement l) {
    var uri = l.source.uri;
    return uri.scheme == 'dart' && uri.path == '_runtime';
  }

  @override
  Iterable<String> jsPartDebuggerNames(LibraryElement library) =>
      library.parts.map((part) => part.uri);

  @override
  String libraryToModule(LibraryElement library) {
    var source = library.source;
    // TODO(jmesserly): we need to split out HTML.
    if (source.uri.scheme == 'dart') {
      return js_ast.dartSdkModule;
    }
    var summaryPath = (source as InSummarySource).summaryPath;
    var moduleName = options.summaryModules[summaryPath];
    if (moduleName == null) {
      throw StateError('Could not find module name for library "$library" '
          'from summary path "$summaryPath".');
    }
    return moduleName;
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

    moduleItems.add(node.accept(this) as js_ast.ModuleItem);

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

    if (_topLevelClass != null && _currentElement == _topLevelClass) {
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
      var item = declaration.accept(this) as js_ast.ModuleItem;
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
    var element = node.element as ExportElement;
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
        return runtimeCall('asInt(#)', [jsFrom]);
      }

      // A no-op in JavaScript.
      return jsFrom;
    }

    return _emitCast(to, jsFrom, implicit: isImplicit);
  }

  js_ast.Expression _emitCast(DartType type, js_ast.Expression expr,
      {bool implicit = true}) {
    // If [type] is a top type we can omit the cast.
    if (rules.isSubtypeOf(types.objectType, type)) {
      return expr;
    }
    var code = implicit ? '#._check(#)' : '#.as(#)';
    return js.call(code, [_emitType(type), expr]);
  }

  @override
  js_ast.Expression visitIsExpression(IsExpression node) {
    return _emitIsExpression(
        node.expression, node.type.type, node.notOperator != null);
  }

  js_ast.Expression _emitIsExpression(Expression operand, DartType type,
      [bool negated = false]) {
    // Generate `is` as `dart.is` or `typeof` depending on the RHS type.
    js_ast.Expression result;
    var lhs = _visitExpression(operand);
    var typeofName = jsTypeRep.typeFor(type).primitiveTypeOf;
    // Inline primitives other than int (which requires a Math.floor check).
    if (typeofName != null && type != types.intType) {
      result = js.call('typeof # == #', [lhs, js.string(typeofName, "'")]);
    } else {
      result = js.call('#.is(#)', [_emitType(type), lhs]);
    }

    return negated ? js.call('!#', result) : result;
  }

  /// No-op, typedefs are emitted as their corresponding function type.
  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) => null;

  /// No-op, typedefs are emitted as their corresponding function type.
  @override
  visitGenericTypeAlias(GenericTypeAlias node) => null;

  @override
  js_ast.Expression visitTypeName(node) => _emitTypeAnnotation(node);

  @override
  js_ast.Expression visitGenericFunctionType(node) => _emitTypeAnnotation(node);

  js_ast.Expression _emitTypeAnnotation(TypeAnnotation node) {
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
  js_ast.Statement visitClassTypeAlias(ClassTypeAlias node) {
    return _emitClassDeclaration(node, node.declaredElement, []);
  }

  @override
  js_ast.Statement visitClassDeclaration(ClassDeclaration node) {
    return _emitClassDeclaration(node, node.declaredElement, node.members);
  }

  js_ast.Statement _emitClassDeclaration(Declaration classNode,
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
            ? js_ast.Identifier(classElem.name)
            : js_ast.TemporaryId(classElem.name))
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

    var body = <js_ast.Statement>[];
    _emitSuperHelperSymbols(body);
    var deferredSupertypes = <js_ast.Statement>[];

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

    var classDef = js_ast.Statement.from(body);
    var typeFormals = classElem.typeParameters;
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(
          classElem, typeFormals, classDef, className, deferredSupertypes);
    } else {
      afterClassDefItems.addAll(deferredSupertypes);
    }

    body = [classDef];
    _emitStaticFields(classElem, memberMap, body);
    if (finishGenericTypeTest != null) body.add(finishGenericTypeTest);
    for (var peer in jsPeerNames) {
      _registerExtensionType(classElem, peer, body);
    }

    _classProperties = savedClassProperties;
    return js_ast.Statement.from(body);
  }

  js_ast.Statement _emitClassTypeTests(ClassElement classElem,
      js_ast.Expression className, List<js_ast.Statement> body) {
    js_ast.Expression getInterfaceSymbol(ClassElement c) {
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

    void markSubtypeOf(js_ast.Expression testSymbol) {
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
      var id = js_ast.TemporaryId("_is_${classElem.name}_default");
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

  void _emitSymbols(
      Iterable<js_ast.TemporaryId> vars, List<js_ast.ModuleItem> body) {
    for (var id in vars) {
      body.add(js.statement('const # = Symbol(#)', [id, js.string(id.name)]));
    }
  }

  void _emitSuperHelperSymbols(List<js_ast.Statement> body) {
    _emitSymbols(
        _superHelpers.values.map((m) => m.name as js_ast.TemporaryId), body);
    _superHelpers.clear();
  }

  void _emitVirtualFieldSymbols(
      ClassElement classElement, List<js_ast.Statement> body) {
    _classProperties.virtualFields.forEach((field, virtualField) {
      body.add(js.statement('const # = Symbol(#);',
          [virtualField, js.string('${classElement.name}.${field.name}')]));
    });
  }

  List<js_ast.Identifier> _emitTypeFormals(
      List<TypeParameterElement> typeFormals) {
    return typeFormals
        .map((t) => js_ast.Identifier(t.name))
        .toList(growable: false);
  }

  @override
  js_ast.Statement visitEnumDeclaration(EnumDeclaration node) {
    return _emitClassDeclaration(node, node.declaredElement, []);
  }

  @override
  js_ast.Statement visitMixinDeclaration(MixinDeclaration node) {
    return _emitClassDeclaration(node, node.declaredElement, node.members);
  }

  /// Wraps a possibly generic class in its type arguments.
  js_ast.Statement _defineClassTypeArguments(TypeDefiningElement element,
      List<TypeParameterElement> formals, js_ast.Statement body,
      [js_ast.Expression className, List<js_ast.Statement> deferredBaseClass]) {
    assert(formals.isNotEmpty);
    var jsFormals = _emitTypeFormals(formals);
    var typeConstructor = js.call('(#) => { #; #; return #; }', [
      jsFormals,
      _typeTable.discharge(formals),
      body,
      className ?? js_ast.Identifier(element.name)
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

  js_ast.Statement _emitClassStatement(
      ClassElement classElem,
      js_ast.Expression className,
      js_ast.Expression heritage,
      List<js_ast.Method> methods) {
    if (classElem.typeParameters.isNotEmpty) {
      return js_ast.ClassExpression(
              className as js_ast.Identifier, heritage, methods)
          .toStatement();
    }
    var classExpr = js_ast.ClassExpression(
        js_ast.TemporaryId(classElem.name), heritage, methods);
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
      js_ast.Expression className,
      js_ast.Expression heritage,
      List<js_ast.Method> methods,
      List<js_ast.Statement> body) {
    assert(classElem.isMixin);

    var staticMethods = methods.where((m) => m.isStatic).toList();
    var instanceMethods = methods.where((m) => !m.isStatic).toList();
    body.add(
        _emitClassStatement(classElem, className, heritage, staticMethods));

    var superclassId = js_ast.TemporaryId(
        classElem.superclassConstraints.map((t) => t.name).join('_'));
    var classId = className is js_ast.Identifier
        ? className
        : js_ast.TemporaryId(classElem.name);

    var mixinMemberClass =
        js_ast.ClassExpression(classId, superclassId, instanceMethods);

    js_ast.Node arrowFnBody = mixinMemberClass;
    var extensionInit = <js_ast.Statement>[];
    _defineExtensionMembers(classId, extensionInit);
    if (extensionInit.isNotEmpty) {
      extensionInit.insert(0, mixinMemberClass.toStatement());
      extensionInit.add(classId.toReturn());
      arrowFnBody = js_ast.Block(extensionInit);
    }

    body.add(js.statement('#[#.mixinOn] = #', [
      className,
      runtimeModule,
      js_ast.ArrowFun([superclassId], arrowFnBody)
    ]));
  }

  void _defineClass(
      ClassElement classElem,
      js_ast.Expression className,
      List<js_ast.Method> methods,
      List<js_ast.Statement> body,
      List<js_ast.Statement> deferredSupertypes) {
    if (classElem.type.isObject) {
      body.add(_emitClassStatement(classElem, className, null, methods));
      return;
    }

    js_ast.Expression emitDeferredType(DartType t) {
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
    var hasUnnamedSuper = _hasUnnamedInheritedConstructor(supertype.element);

    void emitMixinConstructors(js_ast.Expression className,
        [InterfaceType mixin]) {
      var supertype = classElem.supertype;
      js_ast.Statement mixinCtor;
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
        var ctorBody = <js_ast.Statement>[];
        if (mixinCtor != null) ctorBody.add(mixinCtor);
        if (ctor.name != '' || hasUnnamedSuper) {
          ctorBody
              .add(_emitSuperConstructorCall(className, ctor.name, jsParams));
        }
        body.add(_addConstructorToClass(classElem, className, ctor.name,
            js_ast.Fun(jsParams, js_ast.Block(ctorBody))));
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
          js_ast.ClassExpression(
              js_ast.TemporaryId(classElem.name), mixinClass, methods)
        ]));
      }

      emitMixinConstructors(className, m);
      return;
    }

    for (int i = 0; i < mixinLength; i++) {
      var m = classElem.mixins[i];

      var mixinString = classElem.supertype.name + '_' + m.name;
      var mixinClassName = js_ast.TemporaryId(mixinString);
      var mixinId = js_ast.TemporaryId(mixinString + '\$');
      var mixinClassExpression =
          js_ast.ClassExpression(mixinClassName, baseClass, []);
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
  List<js_ast.Method> _emitNativeFieldAccessors(FieldDeclaration node) {
    // TODO(vsm): Can this by meta-programmed?
    // E.g., dart.nativeField(symbol, jsName)
    // Alternatively, perhaps it could be meta-programmed directly in
    // dart.registerExtensions?
    var jsMethods = <js_ast.Method>[];
    if (!node.isStatic) {
      for (var decl in node.fields.variables) {
        var field = decl.declaredElement as FieldElement;
        var name = getAnnotationName(field, isJSName) ?? field.name;
        // Generate getter
        var fn = js_ast.Fun([], js.block('{ return this.#; }', [name]));
        var method =
            js_ast.Method(_declareMemberName(field.getter), fn, isGetter: true);
        jsMethods.add(method);

        // Generate setter
        if (!decl.isFinal) {
          var value = js_ast.TemporaryId('value');
          fn = js_ast.Fun([value], js.block('{ this.# = #; }', [name, value]));
          method = js_ast.Method(_declareMemberName(field.setter), fn,
              isSetter: true);
          jsMethods.add(method);
        }
      }
    }
    return jsMethods;
  }

  List<js_ast.Method> _emitClassMethods(
      ClassElement classElem, List<ClassMember> memberNodes) {
    var type = classElem.type;
    var virtualFields = _classProperties.virtualFields;

    var jsMethods = <js_ast.Method>[];
    bool hasJsPeer = _extensionTypes.isNativeClass(classElem);
    bool hasIterator = false;

    if (type.isObject) {
      // Dart does not use ES6 constructors.
      // Add an error to catch any invalid usage.
      jsMethods.add(
          js_ast.Method(propertyName('constructor'), js.fun(r'''function() {
                  throw Error("use `new " + #.typeName(#.getReifiedType(this)) +
                      ".new(...)` to create a Dart object");
              }''', [runtimeModule, runtimeModule])));
    } else if (classElem == _jsArray) {
      // Provide access to the Array constructor property, so it works like
      // other native types (rather than calling the Dart Object "constructor"
      // above, which throws).
      //
      // This will become obsolete when
      // https://github.com/dart-lang/sdk/issues/31003 is addressed.
      jsMethods.add(js_ast.Method(
          propertyName('constructor'), js.fun(r'function() { return []; }')));
    } else if (classElem.isEnum) {
      // Generate Enum.toString()
      var fields = classElem.fields.where((f) => f.type == type).toList();
      var mapMap = List<js_ast.Property>(fields.length);
      for (var i = 0; i < fields.length; ++i) {
        mapMap[i] = js_ast.Property(
            js.number(i), js.string('${type.name}.${fields[i].name}'));
      }
      jsMethods.add(js_ast.Method(
          _declareMemberName(types.objectType.getMethod('toString')),
          js.fun('function() { return #[this.index]; }',
              js_ast.ObjectInitializer(mapMap, multiline: true))));
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
      Declaration node, List<js_ast.Method> methods) {
    var covariantParams = getSuperclassCovariantParameters(node);
    if (covariantParams == null) return;

    for (var member in covariantParams
        .map((p) => p.enclosingElement as ExecutableElement)
        .toSet()) {
      var name = _declareMemberName(member);
      if (member is PropertyAccessorElement) {
        var param =
            covariantParams.lookup(member.parameters[0]) as ParameterElement;
        methods.add(js_ast.Method(
            name,
            js.fun('function(x) { return super.# = #; }',
                [name, _emitCast(param.type, js_ast.Identifier('x'))]),
            isSetter: true));
        methods.add(js_ast.Method(
            name, js.fun('function() { return super.#; }', [name]),
            isGetter: true));
      } else if (member is MethodElement) {
        var type = member.type;

        var body = <js_ast.Statement>[];
        _emitCovarianceBoundsCheck(type.typeFormals, covariantParams, body);

        var typeFormals = _emitTypeFormals(type.typeFormals);
        var jsParams = List<js_ast.Parameter>.from(typeFormals);
        bool foundNamedParams = false;
        for (var param in member.parameters) {
          param = covariantParams.lookup(param) as ParameterElement;

          if (param == null) continue;
          if (param.isNamed) {
            foundNamedParams = true;

            var name = propertyName(param.name);
            body.add(js.statement('if (# in #) #;', [
              name,
              namedArgumentTemp,
              _emitCast(
                  param.type, js_ast.PropertyAccess(namedArgumentTemp, name))
            ]));
          } else {
            var jsParam = _emitParameter(param);
            jsParams.add(jsParam);

            if (param.isPositional) {
              body.add(js.statement('if (# !== void 0) #;',
                  [jsParam, _emitCast(param.type, jsParam)]));
            } else {
              //TODO(nshahan) Cleanup this logic. Do we need this else branch?
              // https://github.com/dart-lang/sdk/issues/37123
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
        var fn = js_ast.Fun(jsParams, js_ast.Block(body));
        methods.add(js_ast.Method(name, fn));
      } else {
        throw StateError(
            'unable to generate a covariant check for element: `$member` '
            '(${member.runtimeType})');
      }
    }
  }

  /// Emits a Dart factory constructor to a JS static method.
  js_ast.Method _emitFactoryConstructor(ConstructorDeclaration node) {
    if (isUnsupportedFactoryConstructor(node)) return null;

    var element = node.declaredElement;
    var name = _constructorName(element.name);
    js_ast.Fun fun;

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

      fun = js_ast.Fun(
          params,
          js_ast.Block([
            js.statement('return $newKeyword #(#)',
                [visitConstructorName(redirect), params])
              ..sourceInformation = _nodeStart(redirect)
          ]));
    } else {
      // Normal factory constructor
      var body = <js_ast.Statement>[];
      var init = _emitArgumentInitializers(element, node.parameters);
      if (init != null) body.add(init);
      body.add(_visitStatement(node.body));

      var params = _emitParameters(node.parameters?.parameters);
      fun = js_ast.Fun(params, js_ast.Block(body));
    }

    _currentFunction = savedFunction;

    return js_ast.Method(name, fun, isStatic: true)
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
  js_ast.Method _implementMockMember(
      ExecutableElement method, InterfaceType type) {
    var invocationProps = <js_ast.Property>[];
    addProperty(String name, js_ast.Expression value) {
      invocationProps.add(js_ast.Property(js.string(name), value));
    }

    var typeParams = _emitTypeFormals(method.type.typeFormals);
    var fnArgs = List<js_ast.Parameter>.from(typeParams);
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
          .map((n) => js_ast.Property(propertyName(n), js_ast.Identifier(n)));
      addProperty('namedArguments', js_ast.ObjectInitializer(named.toList()));
      positionalArgs.removeLast();
    }
    if (typeParams.isNotEmpty) {
      addProperty('typeArguments', js_ast.ArrayInitializer(typeParams));
    }

    var fnBody =
        js.call('this.noSuchMethod(new #.InvocationImpl.new(#, [#], #))', [
      runtimeModule,
      _declareMemberName(method),
      args,
      js_ast.ObjectInitializer(invocationProps)
    ]);

    fnBody = _emitCast(method.returnType, fnBody);

    var fnBlock = argInit != null
        ? js_ast.Block([argInit, fnBody.toReturn()])
        : fnBody.toReturn().toBlock();

    return js_ast.Method(
        _declareMemberName(method,
            useExtension: _extensionTypes.isNativeClass(type.element)),
        js_ast.Fun(fnArgs, fnBlock),
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
  List<js_ast.Method> _emitVirtualFieldAccessor(VariableDeclaration field) {
    var element = field.declaredElement as FieldElement;
    var virtualField = _classProperties.virtualFields[element];
    var result = <js_ast.Method>[];
    var name = _declareMemberName(element.getter);

    var mocks = _classProperties.mockMembers;
    if (!mocks.containsKey(element.name)) {
      var getter = js.fun('function() { return this[#]; }', [virtualField]);
      result.add(js_ast.Method(name, getter, isGetter: true)
        ..sourceInformation = _functionSpan(field.name));
    }

    if (!mocks.containsKey(element.name + '=')) {
      var args = field.isFinal
          ? [js_ast.Super(), name]
          : [js_ast.This(), virtualField];

      js_ast.Expression value = js_ast.Identifier('value');

      var setter = element.setter;
      if (setter != null) {
        var covariantParams = _classProperties.covariantParameters;
        var param = setter.parameters[0];
        if (param.isCovariant ||
            covariantParams != null && covariantParams.contains(param)) {
          value = _emitCast(param.type, value);
        }
      }
      args.add(value);

      result.add(js_ast.Method(
          name, js.fun('function(value) { #[#] = #; }', args),
          isSetter: true)
        ..sourceInformation = _functionSpan(field.name));
    }

    return result;
  }

  /// Emit a getter or setter that simply forwards to the superclass getter or
  /// setter. This is needed because in ES6, if you only override a getter
  /// (alternatively, a setter), then there is an implicit override of the
  /// setter (alternatively, the getter) that does nothing.
  js_ast.Method _emitSuperAccessorWrapper(
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
        return js_ast.Method(name, fn, isSetter: true);
      }
    } else {
      var getter = field.getter;
      if ((getter == null || getter.isAbstract) &&
          _classProperties.inheritedGetters.contains(field.name)) {
        // Generate a getter that forwards to super.
        var fn = js.fun('function() { return super[#]; }', [name]);
        return js_ast.Method(name, fn, isGetter: true);
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
  js_ast.Method _emitIterable(InterfaceType t) {
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
    return js_ast.Method(
        js.call('Symbol.iterator'),
        js.call('function() { return new #.JsIterator(this.#); }', [
          runtimeModule,
          _emitMemberName('iterator', type: t)
        ]) as js_ast.Fun);
  }

  js_ast.Expression _instantiateAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement) {
      return _emitInstanceCreationExpression(
          element,
          element.returnType as InterfaceType,
          _emitArgumentList(node.arguments),
          isConst: true);
    } else {
      return _visitExpression(node.name);
    }
  }

  void _registerExtensionType(
      ClassElement classElem, String jsPeerName, List<js_ast.Statement> body) {
    var className = _emitTopLevelName(classElem);
    if (jsTypeRep.isPrimitive(classElem.type)) {
      body.add(runtimeStatement(
          'definePrimitiveHashCode(#.prototype)', [className]));
    }
    body.add(runtimeStatement(
        'registerExtension(#, #)', [js.string(jsPeerName), className]));
  }

  /// Defines all constructors for this class as ES5 constructors.
  List<js_ast.Statement> _defineConstructors(
      ClassElement classElem,
      js_ast.Expression className,
      Map<Element, Declaration> memberMap,
      Declaration classNode) {
    var body = <js_ast.Statement>[];
    if (classElem.isMixinApplication) {
      // We already handled this when we defined the class.
      return body;
    }

    addConstructor(String name, js_ast.Expression jsCtor) {
      body.add(_addConstructorToClass(classElem, className, name, jsCtor));
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
      var ctorBody = <js_ast.Statement>[_initializeFields(fields)];
      if (superCall != null) ctorBody.add(superCall);

      addConstructor(
          '',
          js_ast.Fun([], js_ast.Block(ctorBody))
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

  js_ast.Statement _addConstructorToClass(ClassElement c,
      js_ast.Expression className, String name, js_ast.Expression jsCtor) {
    jsCtor = defineValueOnClass(c, className, _constructorName(name), jsCtor);
    return js.statement('#.prototype = #.prototype;', [jsCtor, className]);
  }

  @override
  bool superclassHasStatic(ClassElement c, String name) {
    // Note: because we're only considering statics, we can ignore mixins.
    // We're only trying to find conflicts due to JS inheriting statics.
    var library = c.library;
    while (true) {
      var supertype = c.supertype;
      if (supertype == null) return false;
      c = supertype.element;
      for (var members in [c.methods, c.accessors]) {
        for (var m in members) {
          if (m.isStatic && m.name == name && m.isAccessibleIn(library)) {
            return true;
          }
        }
      }
    }
  }

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(ClassElement classElem,
      Map<Element, Declaration> members, List<js_ast.Statement> body) {
    if (classElem.isEnum) {
      // Emit enum static fields
      var type = classElem.type;
      void addField(FieldElement e, js_ast.Expression value) {
        body.add(defineValueOnClass(classElem, _emitStaticClassName(e),
                _declareMemberName(e.getter), value)
            .toStatement());
      }

      int index = 0;
      var values = <js_ast.Expression>[];
      for (var f in classElem.fields) {
        if (f.type != type) continue;
        // static const E id_i = const E(i);
        values.add(js_ast.PropertyAccess(
            _emitStaticClassName(f), _declareMemberName(f.getter)));
        var enumValue = runtimeCall('const(new (#.#)(#))', [
          emitConstructorAccess(type),
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
        .where((f) => f.isStatic && !f.isSynthetic && !_isExternal(f))
        .map((f) => members[f] as VariableDeclaration)
        .toList();
    if (lazyStatics.isNotEmpty) {
      // Because we filtered out external fields, we don't need to use
      // `_emitStaticClassName` here as we normally would.
      _declareBeforeUse(classElem);
      body.add(_emitLazyFields(_emitTopLevelName(classElem), lazyStatics,
          (e) => _emitStaticMemberName(e.name, e)));
    }
  }

  void _emitClassMetadata(List<Annotation> metadata,
      js_ast.Expression className, List<js_ast.Statement> body) {
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
      js_ast.Expression className, List<js_ast.Statement> body) {
    void emitExtensions(String helperName, Iterable<String> extensions) {
      if (extensions.isEmpty) return;

      var names = extensions
          .map((e) => propertyName(js_ast.memberNameForDartMember(e)))
          .toList();
      body.add(js.statement('#.#(#, #);', [
        runtimeModule,
        helperName,
        className,
        js_ast.ArrayInitializer(names, multiline: names.length > 4)
      ]));
    }

    var props = _classProperties;
    emitExtensions('defineExtensionMethods', props.extensionMethods);
    emitExtensions('defineExtensionAccessors', props.extensionAccessors);
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(ClassElement classElem, js_ast.Expression className,
      Map<Element, Declaration> annotatedMembers, List<js_ast.Statement> body) {
    if (classElem.interfaces.isNotEmpty ||
        classElem.superclassConstraints.isNotEmpty) {
      var interfaces = classElem.interfaces.toList()
        ..addAll(classElem.superclassConstraints);

      body.add(js.statement('#[#.implements] = () => [#];',
          [className, runtimeModule, interfaces.map(_emitType)]));
    }

    void emitSignature(String name, List<js_ast.Property> elements) {
      if (elements.isEmpty) return;

      if (!name.startsWith('Static')) {
        var proto = classElem.type.isObject
            ? js.call('Object.create(null)')
            : runtimeCall('get${name}s(#.__proto__)', [className]);
        elements.insert(0, js_ast.Property(propertyName('__proto__'), proto));
      }
      body.add(runtimeStatement('set${name}Signature(#, () => #)', [
        className,
        js_ast.ObjectInitializer(elements, multiline: elements.length > 1)
      ]));
    }

    var mockMembers = _classProperties.mockMembers;

    {
      var extMembers = _classProperties.extensionMethods;
      var staticMethods = <js_ast.Property>[];
      var instanceMethods = <js_ast.Property>[];
      var classMethods = List.of(classElem.methods.where((m) => !m.isAbstract));
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
          var property = js_ast.Property(_declareMemberName(method), type);
          if (isStatic) {
            staticMethods.add(property);
          } else {
            instanceMethods.add(property);
            if (extMembers.contains(name)) {
              instanceMethods.add(js_ast.Property(
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
      var staticGetters = <js_ast.Property>[];
      var instanceGetters = <js_ast.Property>[];
      var staticSetters = <js_ast.Property>[];
      var instanceSetters = <js_ast.Property>[];

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

          var property = js_ast.Property(_declareMemberName(accessor), type);
          if (isStatic) {
            (isGetter ? staticGetters : staticSetters).add(property);
          } else {
            var accessors = isGetter ? instanceGetters : instanceSetters;
            accessors.add(property);
            if (extMembers.contains(accessor.variable.name)) {
              accessors.add(js_ast.Property(
                  _declareMemberName(accessor, useExtension: true), type));
            }
          }
        }
      }
      emitSignature('Getter', instanceGetters);
      emitSignature('Setter', instanceSetters);
      emitSignature('StaticGetter', staticGetters);
      emitSignature('StaticSetter', staticSetters);
      body.add(runtimeStatement('setLibraryUri(#, #)', [
        className,
        js.escapedString(jsLibraryDebuggerName(classElem.library))
      ]));
    }

    {
      var instanceFields = <js_ast.Property>[];
      var staticFields = <js_ast.Property>[];

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
            .add(js_ast.Property(memberName, fieldSig));
      }
      emitSignature('Field', instanceFields);
      emitSignature('StaticField', staticFields);
    }

    if (options.emitMetadata) {
      var constructors = <js_ast.Property>[];
      for (var ctor in classElem.constructors) {
        var annotationNode = annotatedMembers[ctor] as ConstructorDeclaration;
        var memberName = _constructorName(ctor.name);
        var type = _emitAnnotatedFunctionType(
            ctor.type, annotationNode?.metadata,
            parameters: annotationNode?.parameters?.parameters);
        constructors.add(js_ast.Property(memberName, type));
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

  js_ast.Expression _emitConstructor(ConstructorDeclaration node,
      List<VariableDeclaration> fields, js_ast.Expression className) {
    var params = _emitParameters(node.parameters?.parameters);

    var savedFunction = _currentFunction;
    _currentFunction = node.body;

    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var body = _emitConstructorBody(node, fields, className);
    _superAllowed = savedSuperAllowed;
    _currentFunction = savedFunction;

    return js_ast.Fun(params, body)..sourceInformation = _functionEnd(node);
  }

  FunctionType _getMemberRuntimeType(ExecutableElement element) {
    // Check whether we have any covariant parameters.
    // Usually we don't, so we can use the same type.
    if (!element.parameters.any(_isCovariant)) return element.type;

    var parameters = element.parameters
        .map((p) => ParameterElementImpl.synthetic(
            p.name,
            _isCovariant(p) ? objectClass.type : p.type,
            // ignore: deprecated_member_use
            p.parameterKind))
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

  js_ast.Expression _constructorName(String name) {
    if (name == '') {
      // Default constructors (factory or not) use `new` as their name.
      return propertyName('new');
    }
    return _emitStaticMemberName(name);
  }

  js_ast.Block _emitConstructorBody(ConstructorDeclaration node,
      List<VariableDeclaration> fields, js_ast.Expression className) {
    var body = <js_ast.Statement>[];
    var cls = node.parent as ClassDeclaration;

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
        return js_ast.Block(body);
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
    return js_ast.Block(body);
  }

  js_ast.Statement _emitRedirectingConstructor(
      RedirectingConstructorInvocation node, js_ast.Expression className) {
    var ctor = node.staticElement;
    // We can't dispatch to the constructor with `this.new` as that might hit a
    // derived class constructor with the same name.
    return js.statement('#.#.call(this, #);', [
      className,
      _constructorName(ctor.name),
      _emitArgumentList(node.argumentList)
    ]);
  }

  js_ast.Statement _emitSuperConstructorCallIfNeeded(
      ClassElement element, js_ast.Expression className,
      [ConstructorElement superCtor, List<js_ast.Expression> args]) {
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

  js_ast.Statement _emitSuperConstructorCall(
      js_ast.Expression className, String name, List<js_ast.Expression> args) {
    return js.statement('#.__proto__.#.call(this, #);',
        [className, _constructorName(name), args ?? []]);
  }

  bool _hasUnnamedInheritedConstructor(ClassElement e) {
    if (e == null) return false;
    return _hasUnnamedConstructor(e) || _hasUnnamedSuperConstructor(e);
  }

  bool _hasUnnamedSuperConstructor(ClassElement e) {
    for (var mixin in e.mixins) {
      if (_hasUnnamedConstructor(mixin.element)) return true;
    }
    return _hasUnnamedInheritedConstructor(e.supertype?.element);
  }

  bool _hasUnnamedConstructor(ClassElement e) {
    if (e.type.isObject) return false;
    var ctor = e.unnamedConstructor;
    if (ctor != null && !ctor.isSynthetic) return true;
    return e.fields.any((f) => !f.isStatic && !f.isSynthetic);
  }

  /// Initialize fields. They follow the sequence:
  ///
  ///   1. field declaration initializer if non-const,
  ///   2. field initializing parameters,
  ///   3. constructor field initializers,
  ///   4. initialize fields not covered in 1-3
  js_ast.Statement _initializeFields(List<VariableDeclaration> fieldDecls,
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

    var body = <js_ast.Statement>[];
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
    var fieldInit = <js_ast.Statement>[];
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
    return js_ast.Statement.from(fieldInit);
  }

  /// Emits argument initializers, which handles optional/named args, as well
  /// as generic type checks needed due to our covariance.
  js_ast.Statement _emitArgumentInitializers(ExecutableElement element,
      [FormalParameterList parameterNodes]) {
    var body = <js_ast.Statement>[];

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
        js_ast.Expression defaultValue;
        if (findAnnotation(param, isUndefinedAnnotation) != null) {
          defaultValue = null;
        } else if (paramNode != null) {
          var paramDefault = (paramNode as DefaultFormalParameter).defaultValue;
          if (paramDefault == null) {
            defaultValue = js_ast.LiteralNull();
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
    return body.isEmpty ? null : js_ast.Statement.from(body);
  }

  bool _isCovariant(ParameterElement p) {
    return p.isCovariant ||
        (_classProperties?.covariantParameters?.contains(p) ?? false);
  }

  js_ast.Fun _emitNativeFunctionBody(MethodDeclaration node) {
    String name = getAnnotationName(node.declaredElement, isJSAnnotation) ??
        node.name.name;
    if (node.isGetter) {
      return js_ast.Fun([], js.block('{ return this.#; }', [name]));
    } else if (node.isSetter) {
      var params = _emitParameters(node.parameters?.parameters);
      return js_ast.Fun(
          params, js.block('{ this.# = #; }', [name, params.last]));
    } else {
      return js.fun(
          'function (...args) { return this.#.apply(this, args); }', name);
    }
  }

  js_ast.Method _emitMethodDeclaration(MethodDeclaration node) {
    if (node.isAbstract) {
      return null;
    }

    js_ast.Fun fn;
    if (node.externalKeyword != null || node.body is NativeFunctionBody) {
      if (node.isStatic) {
        // TODO(vsm): Do we need to handle this case?
        return null;
      }
      fn = _emitNativeFunctionBody(node);
    } else {
      fn = _emitFunction(node.declaredElement, node.parameters, node.body);
    }

    return js_ast.Method(_declareMemberName(node.declaredElement), fn,
        isGetter: node.isGetter,
        isSetter: node.isSetter,
        isStatic: node.isStatic)
      ..sourceInformation = _functionEnd(node);
  }

  @override
  js_ast.Statement visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.parent is CompilationUnit);

    if (node.externalKeyword != null ||
        node.functionExpression.body is NativeFunctionBody) {
      return null;
    }

    if (node.isGetter || node.isSetter) {
      var element = node.declaredElement as PropertyAccessorElement;
      var pairAccessor = node.isGetter
          ? element.correspondingSetter
          : element.correspondingGetter;

      var jsCode = _emitTopLevelProperty(node);
      var props = <js_ast.Method>[jsCode];
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

    var body = <js_ast.Statement>[];
    var fn = _emitFunctionExpression(node.functionExpression);

    if (currentLibrary.source.isInSystemLibrary &&
        _isInlineJSFunction(node.functionExpression)) {
      fn = js_ast.simplifyPassThroughArrowFunCallBody(fn);
    }
    fn.sourceInformation = _functionEnd(node);

    var element = resolutionMap.elementDeclaredByFunctionDeclaration(node);
    var nameExpr = _emitTopLevelName(element);
    body.add(js.statement('# = #', [
      nameExpr,
      js_ast.NamedFunction(js_ast.TemporaryId(element.name), fn)
    ]));
    // Function types of top-level/static functions are only needed when
    // dart:mirrors is enabled.
    // TODO(jmesserly): do we even need this for mirrors, since statics are not
    // commonly reflected on?
    if (options.emitMetadata && _reifyFunctionType(element)) {
      body.add(_emitFunctionTagged(nameExpr, element.type, topLevel: true)
          .toStatement());
    }

    return js_ast.Statement.from(body);
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

  js_ast.Method _emitTopLevelProperty(FunctionDeclaration node) {
    var name = node.name.name;
    return js_ast.Method(
        propertyName(name), _emitFunctionExpression(node.functionExpression),
        isGetter: node.isGetter, isSetter: node.isSetter)
      ..sourceInformation = _functionEnd(node);
  }

  bool _executesAtTopLevel(AstNode node) {
    for (var n = node.parent; n != null; n = n.parent) {
      if (n is FunctionBody ||
          n is FieldDeclaration && n.staticKeyword == null ||
          n is ConstructorDeclaration && n.constKeyword == null) {
        return false;
      }
    }
    return true;
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

  js_ast.Expression _emitFunctionTagged(js_ast.Expression fn, FunctionType type,
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
  js_ast.Expression visitFunctionExpression(FunctionExpression node) {
    assert(node.parent is! FunctionDeclaration &&
        node.parent is! MethodDeclaration);
    var fn = _emitArrowFunction(node);
    if (!_reifyFunctionType(node.declaredElement)) return fn;
    return _emitFunctionTagged(fn, getStaticType(node) as FunctionType,
        topLevel: _executesAtTopLevel(node));
  }

  js_ast.ArrowFun _emitArrowFunction(FunctionExpression node) {
    var f = _emitFunction(node.declaredElement, node.parameters, node.body);
    js_ast.Node body = f.body;

    // Simplify `=> { return e; }` to `=> e`
    if (body is js_ast.Block) {
      var block = body as js_ast.Block;
      if (block.statements.length == 1) {
        js_ast.Statement s = block.statements[0];
        if (s is js_ast.Return && s.value != null) body = s.value;
      }
    }

    // Convert `function(...) { ... }` to `(...) => ...`
    // This is for readability, but it also ensures correct `this` binding.
    return js_ast.ArrowFun(f.params, body);
  }

  /// Emits a non-arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears but the function is not actually in an Expression context, such
  /// as methods, properties, and top-level functions.
  ///
  /// Contrast with [visitFunctionExpression].
  js_ast.Fun _emitFunctionExpression(FunctionExpression node) {
    return _emitFunction(node.declaredElement, node.parameters, node.body);
  }

  js_ast.Fun _emitFunction(ExecutableElement element,
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

    js_ast.Block code = isSync
        ? _emitSyncFunctionBody(element, parameters, body)
        : _emitGeneratorFunctionBody(element, parameters, body);

    code = super.exitFunction(element.name, formals, code);
    return js_ast.Fun(formals, code);
  }

  /// Emits a `sync` function body (the default in Dart)
  ///
  /// To emit an `async`, `sync*`, or `async*` function body, use
  /// [_emitGeneratorFunctionBody] instead.
  js_ast.Block _emitSyncFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    var savedFunction = _currentFunction;
    _currentFunction = body;

    var initArgs = _emitArgumentInitializers(element, parameters);
    var block = _emitFunctionScopedBody(body, element);

    if (initArgs != null) block = js_ast.Block([initArgs, block]);

    _currentFunction = savedFunction;

    if (block.isScope) {
      // TODO(jmesserly: JS AST printer does not understand the need to emit a
      // nested scoped block in a JS function. So we need to add a non-scoped
      // wrapper to ensure it gets printed.
      block = js_ast.Block([block]);
    }
    return block;
  }

  /// Emits an `async`, `sync*`, or `async*` function body.
  ///
  /// The body will perform these steps:
  ///
  /// - Run the argument initializers. These must be run synchronously
  ///   (e.g. covariance checks), and this helps performance.
  /// - Return the generator function, wrapped with the appropriate type
  ///   (`Future`, `Itearble`, and `Stream` respectively).
  ///
  /// To emit a `sync` function body (the default in Dart), use
  /// [_emitSyncFunctionBody] instead.
  js_ast.Block _emitGeneratorFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    var savedFunction = _currentFunction;
    _currentFunction = body;

    var initArgs = _emitArgumentInitializers(element, parameters);
    var block = js_ast.Block([
      _emitGeneratorFunction(element, parameters, body).toReturn()
        ..sourceInformation = _nodeStart(body)
    ]);
    if (initArgs != null) block = js_ast.Block([initArgs, block]);

    _currentFunction = savedFunction;

    if (block.isScope) {
      // TODO(jmesserly: JS AST printer does not understand the need to emit a
      // nested scoped block in a JS function. So we need to add a non-scoped
      // wrapper to ensure it gets printed.
      block = js_ast.Block([block]);
    }
    return block;
  }

  js_ast.Block _emitFunctionScopedBody(
      FunctionBody body, ExecutableElement element) {
    var block = body.accept(this) as js_ast.Block;
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
      Set<Element> covariantParams, List<js_ast.Statement> body) {
    if (covariantParams == null) return;
    for (var t in typeFormals) {
      t = covariantParams.lookup(t) as TypeParameterElement;
      if (t != null) {
        body.add(runtimeStatement('checkTypeBound(#, #, #)',
            [_emitType(t.type), _emitType(t.bound), propertyName(t.name)]));
      }
    }
  }

  js_ast.Expression _emitGeneratorFunction(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    // Transforms `sync*` `async` and `async*` function bodies
    // using ES6 generators.

    var returnType = _getExpectedReturnType(element);

    emitGeneratorFn(List<js_ast.Parameter> jsParams,
        [js_ast.TemporaryId asyncStar]) {
      var savedSuperAllowed = _superAllowed;
      var savedController = _asyncStarController;
      _superAllowed = false;
      _asyncStarController = asyncStar;

      // Visit the body with our async* controller set.
      //
      // Note: we intentionally don't emit argument initializers here, because
      // they were already emitted outside of the generator expression.
      var savedFunction = _currentFunction;
      _currentFunction = body;
      var jsBody = _emitFunctionScopedBody(body, element);
      _currentFunction = savedFunction;

      var genFn = js_ast.Fun(jsParams, jsBody, isGenerator: true);

      // Name the function if possible, to get better stack traces.
      var name = element.name;
      js_ast.Expression gen = genFn;
      if (name.isNotEmpty) {
        gen = js_ast.NamedFunction(
            js_ast.TemporaryId(
                js_ast.friendlyNameForDartOperator[name] ?? name),
            genFn);
      }
      gen.sourceInformation = _functionEnd(body);
      if (usesThisOrSuper(gen)) gen = js.call('#.bind(this)', gen);

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
      var asyncStarParam = js_ast.TemporaryId('stream');
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
  js_ast.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    var fn = _emitFunctionExpression(func.functionExpression);
    var name = _emitVariableDef(func.name);
    js_ast.Statement declareFn;
    declareFn = toBoundFunctionStatement(fn, name);
    var element = func.declaredElement;
    if (_reifyFunctionType(element)) {
      declareFn = js_ast.Block(
          [declareFn, _emitFunctionTagged(name, element.type).toStatement()]);
    }
    return declareFn;
  }

  /// Emits a simple identifier, including handling an inferred generic
  /// function instantiation.
  @override
  js_ast.Expression visitSimpleIdentifier(SimpleIdentifier node,
      [PrefixedIdentifier prefix]) {
    var typeArgs = _getTypeArgs(node.staticElement, node.staticType);
    var simpleId = _emitSimpleIdentifier(node, prefix)
      ..sourceInformation = _nodeSpan(node);
    if (prefix != null &&
        // Check that the JS AST is for a Dart property and not JS interop.
        simpleId is js_ast.PropertyAccess &&
        simpleId.receiver is js_ast.Identifier) {
      // Attach the span to the library prefix.
      simpleId.receiver.sourceInformation = _nodeSpan(prefix.prefix);
    }
    if (typeArgs == null) return simpleId;
    return runtimeCall('gbind(#, #)', [simpleId, typeArgs]);
  }

  /// Emits a simple identifier, handling implicit `this` as well as
  /// going through the qualified library name if necessary, but *not* handling
  /// inferred generic function instantiation.
  js_ast.Expression _emitSimpleIdentifier(SimpleIdentifier node,
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
        typeName = runtimeCall('wrapType(#)', [typeName]);
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

    return js_ast.Identifier(element.name);
  }

  js_ast.Expression _emitLibraryMemberElement(
      Element element, Expression node) {
    var result = _emitTopLevelName(element);
    if (element is FunctionElement && _reifyTearoff(element, node)) {
      return _emitFunctionTagged(result, element.type);
    }
    return result;
  }

  js_ast.Expression _emitClassMemberElement(
      ClassMemberElement element, Element accessor, Expression node) {
    bool isStatic = element.isStatic;
    var classElem = element.enclosingElement as ClassElement;
    var type = classElem.type;
    var member = _emitMemberName(element.name,
        isStatic: isStatic, type: type, element: accessor);

    // For instance members, we add implicit-this.
    // For method tear-offs, we ensure it's a bound method.
    var target = isStatic ? _emitStaticClassName(element) : js_ast.This();
    if (element is MethodElement && _reifyTearoff(element, node)) {
      if (isStatic) {
        // TODO(jmesserly): we could tag static/top-level function types once
        // in the module initialization, rather than at the point where they
        // escape.
        return _emitFunctionTagged(
            js_ast.PropertyAccess(target, member), element.type);
      }
      return runtimeCall('bind(#, #)', [target, member]);
    }
    return js_ast.PropertyAccess(target, member);
  }

  js_ast.Identifier _emitVariableDef(SimpleIdentifier id) {
    return js_ast.Identifier(id.name)..sourceInformation = _nodeStart(id);
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

  js_ast.Identifier _emitParameter(ParameterElement element,
      {bool declaration = false}) {
    // initializing formal parameter, e.g. `Point(this._x)`
    // TODO(jmesserly): type ref is not attached in this case.
    if (element.isInitializingFormal && element.isPrivate) {
      /// Rename private names so they don't shadow the private field symbol.
      /// The renamer would handle this, but it would prefer to rename the
      /// temporary used for the private symbol. Instead rename the parameter.
      return _initializingFormalTemps.putIfAbsent(
          element, () => js_ast.TemporaryId(element.name.substring(1)));
    }

    return js_ast.Identifier(element.name);
  }

  List<Annotation> _parameterMetadata(FormalParameter p) =>
      (p is NormalFormalParameter)
          ? p.metadata
          : (p as DefaultFormalParameter).parameter.metadata;

  // Wrap a result - usually a type - with its metadata.  The runtime is
  // responsible for unpacking this.
  js_ast.Expression _emitAnnotatedResult(
      js_ast.Expression result, List<Annotation> metadata) {
    if (options.emitMetadata && metadata != null && metadata.isNotEmpty) {
      result = js_ast.ArrayInitializer(
          [result]..addAll(metadata.map(_instantiateAnnotation)));
    }
    return result;
  }

  js_ast.Expression _emitFieldSignature(DartType type,
      {List<Annotation> metadata, bool isFinal = true}) {
    var args = [_emitType(type)];
    if (options.emitMetadata && metadata != null && metadata.isNotEmpty) {
      args.add(js_ast.ArrayInitializer(
          metadata.map(_instantiateAnnotation).toList()));
    }
    return runtimeCall(isFinal ? 'finalFieldType(#)' : 'fieldType(#)', [args]);
  }

  js_ast.ArrayInitializer _emitTypeNames(
      List<DartType> types, List<FormalParameter> parameters,
      {bool cacheType = true}) {
    var result = <js_ast.Expression>[];
    for (int i = 0; i < types.length; ++i) {
      var metadata =
          parameters != null ? _parameterMetadata(parameters[i]) : null;
      var typeName = _emitType(types[i], cacheType: cacheType);
      result.add(_emitAnnotatedResult(typeName, metadata));
    }
    return js_ast.ArrayInitializer(result);
  }

  js_ast.ObjectInitializer _emitTypeProperties(Map<String, DartType> types,
      {bool cacheType = true}) {
    var properties = <js_ast.Property>[];
    types.forEach((name, type) {
      var key = propertyName(name);
      var value = _emitType(type, cacheType: cacheType);
      properties.add(js_ast.Property(key, value));
    });
    return js_ast.ObjectInitializer(properties);
  }

  /// Emit the pieces of a function type, as an array of return type,
  /// regular args, and optional/named args.
  js_ast.Expression _emitFunctionType(FunctionType type,
      {List<FormalParameter> parameters,
      bool cacheType = true,
      bool lazy = false}) {
    var parameterTypes = type.normalParameterTypes;
    var optionalTypes = type.optionalParameterTypes;
    var namedTypes = type.namedParameterTypes;
    var rt = _emitType(type.returnType, cacheType: cacheType);

    var ra = _emitTypeNames(parameterTypes, parameters, cacheType: cacheType);

    List<js_ast.Expression> typeParts;
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

    js_ast.Expression fullType;
    String helperCall;
    var typeFormals = type.typeFormals;
    if (typeFormals.isNotEmpty) {
      var tf = _emitTypeFormals(typeFormals);

      addTypeFormalsAsParameters(List<js_ast.Expression> elements) {
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

  js_ast.Expression _emitAnnotatedFunctionType(
      FunctionType type, List<Annotation> metadata,
      {List<FormalParameter> parameters}) {
    var result =
        _emitFunctionType(type, parameters: parameters, cacheType: false);
    return _emitAnnotatedResult(result, metadata);
  }

  @override
  js_ast.Expression emitConstructorAccess(DartType type) {
    return _emitJSInterop(type.element) ?? _emitType(type);
  }

  /// Emits an expression referring to the class of static [member].
  ///
  /// Typically this is equivalent to [_declareBeforeUse] followed by
  /// [_emitTopLevelName] on the class, but if the member is external, then the
  /// native class name will be used, for direct access to the native member.
  js_ast.Expression _emitStaticClassName(ClassMemberElement member) {
    var c = member.enclosingElement as ClassElement;
    _declareBeforeUse(c);

    // A static native element should just forward directly to the JS type's
    // member, for example `Css.supports(...)` in dart:html should be replaced
    // by a direct call to the DOM API: `global.CSS.supports`.
    if (_isExternal(member)) {
      var nativeName = _extensionTypes.getNativePeers(c);
      if (nativeName.isNotEmpty) {
        return runtimeCall('global.#', [nativeName[0]]);
      }
    }
    return _emitTopLevelName(c);
  }

  /// Emits a Dart [type] into code.
  ///
  /// If [cacheType] is true, then the type will be cached for the module.
  js_ast.Expression _emitType(DartType type, {bool cacheType = true}) {
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
      return runtimeCall(
          'anonymousJSType(#)', [js.escapedString(element.name)]);
    }
    var jsName = _getJSNameWithoutGlobal(element);
    if (jsName != null) {
      return runtimeCall('lazyJSType(() => #, #)',
          [_emitJSInteropForGlobal(jsName), js.escapedString(jsName)]);
    }

    var name = type.name;
    if (type is TypeParameterType) {
      return js_ast.Identifier(name);
    }

    if (type is ParameterizedType) {
      if (type is FunctionType) {
        return _emitFunctionType(type, cacheType: cacheType);
      }
      var args = type.typeArguments;
      List<js_ast.Expression> jsArgs;
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
  js_ast.Expression _emitTypeDefiningElement(TypeDefiningElement e) {
    return _emitType(instantiateElementTypeToBounds(rules, e));
  }

  js_ast.Expression _emitGenericClassType(
      ParameterizedType t, List<js_ast.Expression> typeArgs) {
    var genericName = _emitTopLevelNameNoInterop(t.element, suffix: '\$');
    return js.call('#(#)', [genericName, typeArgs]);
  }

  js_ast.PropertyAccess _emitTopLevelName(Element e, {String suffix = ''}) {
    return _emitJSInterop(e) ?? _emitTopLevelNameNoInterop(e, suffix: suffix);
  }

  js_ast.PropertyAccess _emitTopLevelNameNoInterop(Element e,
      {String suffix = ''}) {
    return js_ast.PropertyAccess(
        emitLibraryName(e.library), _emitTopLevelMemberName(e, suffix: suffix));
  }

  /// Emits the member name portion of a top-level member.
  ///
  /// NOTE: usually you should use [_emitTopLevelName] instead of this. This
  /// function does not handle JS interop.
  js_ast.Expression _emitTopLevelMemberName(Element e, {String suffix = ''}) {
    var name = getJSExportName(e) ?? _getElementName(e);
    return propertyName(name + suffix);
  }

  @override
  js_ast.Expression visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;
    if (node.operator.type == TokenType.EQ) return _emitSet(left, right);
    var op = node.operator.lexeme;
    assert(op.endsWith('='));
    op = op.substring(0, op.length - 1); // remove trailing '='
    return _emitOpAssign(left, right, op, node.staticElement, context: node);
  }

  js_ast.MetaLet _emitOpAssign(
      Expression left, Expression right, String op, MethodElement element,
      {Expression context}) {
    if (op == '??') {
      // Desugar `l ??= r` as ((x) => x == null ? l = r : x)(l)
      // Note that if `x` contains subexpressions, we need to ensure those
      // are also evaluated only once. This is similar to desugaring for
      // postfix expressions like `i++`.

      // Handle the left hand side, to ensure each of its subexpressions are
      // evaluated only once.
      var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
      var x = _bindLeftHandSide(vars, left, context: left);
      // Capture the result of evaluating the left hand side in a temp.
      var t = _bindValue(vars, 't', x, context: x);
      return js_ast.MetaLet(vars, [
        js.call('# == null ? # : #',
            [_visitExpression(t), _emitSet(x, right), _visitExpression(t)])
      ]);
    }

    // Desugar `x += y` as `x = x + y`, ensuring that if `x` has subexpressions
    // (for example, x is IndexExpression) we evaluate those once.
    var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
    var lhs = _bindLeftHandSide(vars, left, context: context);
    // TODO(leafp): The element for lhs here will be the setter element
    // instead of the getter element if lhs is a property access. This
    // interferes with nullability analysis.
    Expression inc = ast.binaryExpression(lhs, op, right)
      ..staticElement = element
      ..staticType = getStaticType(lhs);

    var castTo = getImplicitOperationCast(left);
    if (castTo != null) inc = CoercionReifier.castExpression(inc, castTo);
    return js_ast.MetaLet(vars, [_emitSet(lhs, inc)]);
  }

  js_ast.Expression _emitSet(Expression left, Expression right) {
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

    Expression target;
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

  js_ast.Expression _badAssignment(
      String problem, Expression lhs, Expression rhs) {
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
  js_ast.Expression _emitSetSimpleIdentifier(
      SimpleIdentifier node, Expression right) {
    js_ast.Expression unimplemented() {
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
      return _emitSetField(right, element, js_ast.This(), node);
    }

    // We should not get here.
    return unimplemented();
  }

  /// Emits assignment to a simple local variable or parameter.
  js_ast.Expression _emitSetLocal(
      Element element, Expression rhs, AstNode left) {
    js_ast.Expression target;
    if (element is TemporaryVariableElement) {
      // If this is one of our compiler's temporary variables, use its JS form.
      target = element.jsVariable;
    } else if (element is ParameterElement) {
      target = _emitParameter(element);
    } else {
      target = js_ast.Identifier(element.name);
    }
    target.sourceInformation = _nodeSpan(left);
    return _visitExpression(rhs).toAssignExpression(target);
  }

  /// Emits assignment to library scope element [element].
  js_ast.Expression _emitSetTopLevel(
      PropertyAccessorElement element, Expression rhs) {
    return _visitExpression(rhs).toAssignExpression(_emitTopLevelName(element));
  }

  /// Emits assignment to a static field element or property.
  js_ast.Expression _emitSetField(Expression right, FieldElement field,
      js_ast.Expression jsTarget, SimpleIdentifier id) {
    var classElem = field.enclosingElement as ClassElement;
    var isStatic = field.isStatic;
    var member = _emitMemberName(field.name,
        isStatic: isStatic, type: classElem.type, element: field.setter);
    jsTarget = isStatic
        ? (js_ast.PropertyAccess(_emitStaticClassName(field), member)
          ..sourceInformation = _nodeSpan(id))
        : _emitTargetAccess(jsTarget, member, field.setter, id);
    return _visitExpression(right).toAssignExpression(jsTarget);
  }

  js_ast.Expression _emitNullSafeSet(PropertyAccess node, Expression right) {
    // Emit `obj?.prop = expr` as:
    //
    //     (_ => _ == null ? null : _.prop = expr)(obj).
    //
    // We could use a helper, e.g.:  `nullSafeSet(e1, _ => _.v = e2)`
    //
    // However with MetaLet, we get clean code in statement or void context,
    // or when one of the expressions is stateless, which seems common.
    var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
    var left = _bindValue(vars, 'l', node.target);
    var body = js.call('# == null ? null : #', [
      _visitExpression(left),
      _emitSet(_stripNullAwareOp(node, left), right)
    ]);
    return js_ast.MetaLet(vars, [body]);
  }

  @override
  js_ast.Block visitExpressionFunctionBody(ExpressionFunctionBody node) {
    return js_ast.Block([_visitExpression(node.expression).toReturn()]);
  }

  @override
  js_ast.Block visitEmptyFunctionBody(EmptyFunctionBody node) =>
      js_ast.Block([]);

  @override
  js_ast.Block visitBlockFunctionBody(BlockFunctionBody node) {
    return js_ast.Block(_visitStatementList(node.block.statements));
  }

  @override
  js_ast.Block visitBlock(Block node) =>
      js_ast.Block(_visitStatementList(node.statements), isScope: true);

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
        return getExtensionSymbolInternal(firstArg.stringValue);
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

  js_ast.Expression _emitTarget(
      Expression target, Element member, bool isStatic) {
    if (isStatic) {
      if (member is ConstructorElement) {
        return emitConstructorAccess(member.enclosingElement.type)
          ..sourceInformation = _nodeSpan(target);
      }
      if (member is PropertyAccessorElement) {
        var field = member.variable;
        if (field is FieldElement) {
          return _emitStaticClassName(field)
            ..sourceInformation = _nodeSpan(target);
        }
      }
      if (member is MethodElement) {
        return _emitStaticClassName(member)
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

  /// Emits the [js_ast.PropertyAccess] for accessors or method calls to
  /// [jsTarget].[jsName], replacing `super` if it is not allowed in scope.
  js_ast.Expression _emitTargetAccess(js_ast.Expression jsTarget,
      js_ast.Expression jsName, Element member, AstNode node) {
    js_ast.Expression result;
    if (!_superAllowed && jsTarget is js_ast.Super && member != null) {
      result = _getSuperHelper(member, jsName);
    } else {
      result = js_ast.PropertyAccess(jsTarget, jsName);
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

  js_ast.Expression _getSuperHelper(Element member, js_ast.Expression jsName) {
    var jsMethod = _superHelpers.putIfAbsent(member.name, () {
      if (member is PropertyAccessorElement) {
        var isSetter = member.isSetter;
        var fn = js.fun(
            isSetter
                ? 'function(x) { super[#] = x; }'
                : 'function() { return super[#]; }',
            [jsName]);
        return js_ast.Method(js_ast.TemporaryId(member.variable.name), fn,
            isGetter: !isSetter, isSetter: isSetter);
      } else {
        var method = member as MethodElement;
        var params = List<js_ast.Identifier>.from(
            _emitTypeFormals(method.typeParameters));
        for (var param in method.parameters) {
          if (param.isNamed) {
            params.add(namedArgumentTemp);
            break;
          }
          params.add(js_ast.Identifier(param.name));
        }

        var fn = js.fun(
            'function(#) { return super[#](#); }', [params, jsName, params]);
        var name = method.name;
        name = js_ast.friendlyNameForDartOperator[name] ?? name;
        return js_ast.Method(js_ast.TemporaryId(name), fn);
      }
    });
    return js_ast.PropertyAccess(js_ast.This(), jsMethod.name);
  }

  js_ast.Expression _emitMethodCall(Expression target, MethodInvocation node) {
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
      js_ast.Expression jsTarget = _emitTarget(target, element, isStatic);
      if (jsTarget is js_ast.Super) {
        jsTarget =
            _emitTargetAccess(jsTarget, jsName, element, node.methodName);
        jsName = null;
      }
      return _emitDynamicInvoke(jsTarget, typeArgs, jsName, args, argumentList);
    }

    js_ast.Expression jsTarget = _emitTarget(target, element, isStatic);

    // Handle Object methods that are supported by `null`.
    if (_isObjectMethodCall(name, argumentList.arguments) &&
        isNullable(target)) {
      assert(typeArgs == null ||
          typeArgs.isEmpty); // Object methods don't take type args.
      return runtimeCall('#(#, #)', [name, jsTarget, args]);
    }

    jsTarget = _emitTargetAccess(jsTarget, jsName, element, node.methodName);
    // Handle `o.m(a)` where `o.m` is a getter returning a class with `call`.
    if (element is PropertyAccessorElement) {
      var fromType = element.returnType;
      if (fromType is InterfaceType) {
        var callName = _getImplicitCallTarget(fromType);
        if (callName != null) {
          jsTarget = js_ast.PropertyAccess(jsTarget, callName);
        }
      }
    }
    var castTo = getImplicitOperationCast(node);
    if (castTo != null) {
      jsTarget = _emitCast(castTo, jsTarget);
    }
    if (typeArgs != null) args.insertAll(0, typeArgs);
    return js_ast.Call(jsTarget, args);
  }

  js_ast.Expression _emitDynamicInvoke(
      js_ast.Expression fn,
      List<js_ast.Expression> typeArgs,
      js_ast.Expression methodName,
      List<js_ast.Expression> args,
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

  js_ast.Expression _emitJSDoubleEq(List<js_ast.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# != #' : '# == #';
    return js.call(op, args);
  }

  js_ast.Expression _emitJSTripleEq(List<js_ast.Expression> args,
      {bool negated = false}) {
    var op = negated ? '# !== #' : '# === #';
    return js.call(op, args);
  }

  js_ast.Expression _emitCoreIdenticalCall(List<Expression> arguments,
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
    return js.call(code, js_ast.Call(_emitTopLevelName(_coreIdentical), args));
  }

  /// Emits a function call, to a top-level function, local function, or
  /// an expression.
  js_ast.Node _emitFunctionCall(InvocationExpression node,
      [Expression function]) {
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

    return js_ast.Call(fn, args);
  }

  js_ast.Node _emitDebuggerCall(InvocationExpression node) {
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
    var jsArgs = <js_ast.Property>[];
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
        ? (foundWhen ? jsArgs[0].value : js_ast.ObjectInitializer(jsArgs))
        // If we have both `message` and `when` arguments, evaluate them in
        // order, then extract the `when` argument.
        : js.call('#.when', js_ast.ObjectInitializer(jsArgs));
    return isStatement
        ? js.statement('if (#) debugger;', when)
        : js.call('# && (() => { debugger; return true })()', when);
  }

  List<js_ast.Expression> _emitInvokeTypeArguments(InvocationExpression node) {
    // add no reify generic check here: if (node.function)
    // node is Identifier
    var function = node.function;
    if (function is Identifier && !_reifyGeneric(function.staticElement)) {
      return null;
    }
    return _emitFunctionTypeArguments(
        node, function.staticType, node.staticInvokeType, node.typeArguments);
  }

  /// If `g` is a generic function type, and `f` is an instantiation of it,
  /// then this will return the type arguments to apply, otherwise null.
  List<js_ast.Expression> _emitFunctionTypeArguments(
      AstNode node, DartType g, DartType f,
      [TypeArgumentList typeArgs]) {
    if (node is InvocationExpression) {
      if (g is! FunctionType && typeArgs == null) {
        return null;
      }
      var typeArguments = node.typeArgumentTypes;
      return typeArguments.map(_emitType).toList(growable: false);
    }

    if (g is FunctionType &&
        g.typeFormals.isNotEmpty &&
        f is FunctionType &&
        f.typeFormals.isEmpty) {
      var typeArguments = _recoverTypeArguments(g, f);
      return typeArguments.map(_emitType).toList(growable: false);
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
  js_ast.Node _emitForeignJS(MethodInvocation node, Element e) {
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
    assert(result is js_ast.Expression ||
        result is js_ast.Statement && node.parent is ExpressionStatement);
    return result;
  }

  @override
  js_ast.Node visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      _emitFunctionCall(node);

  List<js_ast.Expression> _emitArgumentList(ArgumentList node) {
    var args = <js_ast.Expression>[];
    var named = <js_ast.Property>[];
    for (var arg in node.arguments) {
      if (arg is NamedExpression) {
        named.add(visitNamedExpression(arg));
      } else if (arg is MethodInvocation && isJsSpreadInvocation(arg)) {
        args.add(
            js_ast.Spread(_visitExpression(arg.argumentList.arguments[0])));
      } else {
        args.add(_visitExpression(arg));
      }
    }
    if (named.isNotEmpty) {
      args.add(js_ast.ObjectInitializer(named));
    }
    return args;
  }

  @override
  js_ast.Property visitNamedExpression(NamedExpression node) {
    assert(node.parent is ArgumentList);
    return js_ast.Property(
        propertyName(node.name.label.name), _visitExpression(node.expression));
  }

  List<js_ast.Parameter> _emitParametersForElement(ExecutableElement member) {
    var jsParams = <js_ast.Identifier>[];
    for (var p in member.parameters) {
      if (p.isPositional) {
        jsParams.add(js_ast.Identifier(p.name));
      } else {
        jsParams.add(namedArgumentTemp);
        break;
      }
    }
    return jsParams;
  }

  List<js_ast.Parameter> _emitParameters(Iterable<FormalParameter> parameters) {
    if (parameters == null) return [];

    var result = <js_ast.Parameter>[];
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
  js_ast.Statement visitExpressionStatement(ExpressionStatement node) =>
      node.expression.accept(this).toStatement();

  @override
  js_ast.EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      js_ast.EmptyStatement();

  @override
  js_ast.Statement visitAssertStatement(AssertStatement node) =>
      _emitAssert(node.condition, node.message);

  js_ast.Statement _emitAssert(Expression condition, Expression message) {
    if (!options.enableAsserts) return js_ast.EmptyStatement();
    // TODO(jmesserly): only emit in checked mode.
    var conditionType = condition.staticType;
    var jsCondition = _visitExpression(condition);

    if (conditionType is FunctionType &&
        conditionType.parameters.isEmpty &&
        conditionType.returnType == types.boolType) {
      jsCondition = runtimeCall('test(#())', [jsCondition]);
    } else if (conditionType != types.boolType) {
      jsCondition = runtimeCall('dassert(#)', [jsCondition]);
    } else if (isNullable(condition)) {
      jsCondition = runtimeCall('test(#)', [jsCondition]);
    }

    var location = _getLocation(condition.offset);
    return js.statement(' if (!#) #.assertFailed(#, #, #, #, #);', [
      jsCondition,
      runtimeModule,
      if (message == null)
        js_ast.LiteralNull()
      else
        _visitExpression(message),
      js.escapedString(location.sourceUrl.toString()),
      // Lines and columns are typically printed with 1 based indexing.
      js.number(location.line + 1),
      js.number(location.column + 1),
      js.escapedString(condition.toSource()),
    ]);
  }

  @override
  js_ast.Statement visitReturnStatement(ReturnStatement node) {
    return super.emitReturnStatement(_visitExpression(node.expression));
  }

  @override
  js_ast.Statement visitYieldStatement(YieldStatement node) {
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
        js_ast.Yield(null)..sourceInformation = _nodeStart(node)
      ]);
    }
    // A normal yield in a sync*
    return jsExpr.toYieldStatement(star: star);
  }

  @override
  js_ast.Expression visitAwaitExpression(AwaitExpression node) {
    return js_ast.Yield(_visitExpression(node.expression));
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
  js_ast.Statement visitVariableDeclarationStatement(
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
        js_ast.Expression value;
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
          return js_ast.Block([
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
  js_ast.VariableDeclarationList visitVariableDeclarationList(
      VariableDeclarationList node) {
    if (node == null) return null;
    return js_ast.VariableDeclarationList(
        'let', node.variables?.map(visitVariableDeclaration)?.toList());
  }

  @override
  js_ast.VariableInitialization visitVariableDeclaration(
      VariableDeclaration node) {
    if (node.declaredElement is PropertyInducingElement) {
      // All fields are handled elsewhere.
      assert(false);
      return null;
    }

    var name = _emitVariableDef(node.name);
    return js_ast.VariableInitialization(
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

  js_ast.Expression _visitInitializer(Expression init, Element variable) {
    // explicitly initialize to null, to avoid getting `undefined`.
    // TODO(jmesserly): do this only for vars that aren't definitely assigned.
    if (init == null) return js_ast.LiteralNull();
    return _annotatedNullCheck(variable)
        ? notNull(init)
        : _visitExpression(init);
  }

  js_ast.Statement _emitLazyFields(
      js_ast.Expression objExpr,
      List<VariableDeclaration> fields,
      js_ast.Expression Function(Element e) emitFieldName) {
    var accessors = <js_ast.Method>[];

    for (var node in fields) {
      var element = node.declaredElement;
      var access = emitFieldName(element);
      accessors.add(js_ast.Method(
          access,
          js.call('function() { return #; }',
              _visitInitializer(node.initializer, element)) as js_ast.Fun,
          isGetter: true)
        ..sourceInformation =
            _hoverComment(js_ast.PropertyAccess(objExpr, access), node.name));

      // TODO(jmesserly): currently uses a dummy setter to indicate writable.
      if (!node.isFinal && !node.isConst) {
        accessors.add(js_ast.Method(
            access, js.call('function(_) {}') as js_ast.Fun,
            isSetter: true));
      }
    }

    return runtimeStatement('defineLazy(#, { # })', [objExpr, accessors]);
  }

  js_ast.Expression _emitConstructorName(DartType type, String name) {
    return _emitJSInterop(type.element) ??
        js_ast.PropertyAccess(
            emitConstructorAccess(type), _constructorName(name));
  }

  @override
  js_ast.Expression visitConstructorName(ConstructorName node) {
    return _emitConstructorName(node.type.type, node.staticElement.name);
  }

  js_ast.Expression _emitInstanceCreationExpression(ConstructorElement element,
      InterfaceType type, List<js_ast.Expression> args,
      {bool isConst = false, ConstructorName ctorNode}) {
    if (element == null) {
      return _throwUnsafe('unresolved constructor: ${type?.name ?? '<null>'}'
          '.${ctorNode?.name?.name ?? '<unnamed>'}');
    }

    var classElem = type.element;
    if (_isObjectLiteral(classElem)) {
      return args.isEmpty
          ? js.call('{}')
          : args.single as js_ast.ObjectInitializer;
    }

    js_ast.Expression emitNew() {
      var name = element.name;
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
          ? js_ast.Call(ctor, args)
          : js_ast.New(ctor, args);
    }

    var result = emitNew();
    return isConst ? canonicalizeConstObject(result) : result;
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
  js_ast.Expression _emitDartObject(DartObject value,
      {bool handleUnknown = false}) {
    if (value == null || value.isNull) {
      return js_ast.LiteralNull();
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
      return type == types.boolType ? js.boolean(false) : js_ast.LiteralNull();
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
      return emitDartSymbol(value.toSymbolValue());
    }
    if (type == types.typeType) {
      return _emitType(value.toTypeValue());
    }
    if (type is InterfaceType) {
      if (type.element == types.listType.element) {
        return _emitConstList(type.typeArguments[0],
            value.toListValue().map(_emitDartObject).toList());
      }
      if (type.element == types.setType.element) {
        return _emitConstSet(type.typeArguments[0],
            value.toSetValue().map(_emitDartObject).toList());
      }
      if (type.element == types.mapType.element) {
        var entries = <js_ast.Expression>[];
        value.toMapValue().forEach((key, value) {
          entries.add(_emitDartObject(key));
          entries.add(_emitDartObject(value));
        });
        return _emitConstMap(type, entries);
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
        var args = ctor.positionalArguments.map(_emitDartObject).toList();
        var named = <js_ast.Property>[];
        ctor.namedArguments.forEach((name, value) {
          named
              .add(js_ast.Property(propertyName(name), _emitDartObject(value)));
        });
        if (named.isNotEmpty) args.add(js_ast.ObjectInitializer(named));
        return _emitInstanceCreationExpression(ctor.constructor, type, args,
            isConst: true);
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
        if (e is ClassElement) {
          return e.type.instantiate(
              typeNode.typeArguments.arguments.map(getType).toList());
        } else if (e is FunctionTypedElement) {
          return e.type.instantiate(
              typeNode.typeArguments.arguments.map(getType).toList());
        }
      }
      return typeNode.type;
    }

    return _emitInstanceCreationExpression(
        element,
        getType(constructor.type) as InterfaceType,
        _emitArgumentList(node.argumentList),
        isConst: node.isConst,
        ctorNode: constructor);
  }

  js_ast.Statement _nullParameterCheck(js_ast.Expression param) {
    var call = runtimeCall('argumentError((#))', [param]);
    return js.statement('if (# == null) #;', [param, call]);
  }

  js_ast.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visitExpression(expr);
    if (!isNullable(expr)) return jsExpr;
    return runtimeCall('notNull(#)', [jsExpr]);
  }

  js_ast.Expression _emitEqualityOperator(BinaryExpression node, Token op) {
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
  js_ast.Expression visitBinaryExpression(BinaryExpression node) {
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

      var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
      // Desugar `l ?? r` as `l != null ? l : r`
      var l = _visitExpression(_bindValue(vars, 'l', left, context: left));
      return js_ast.MetaLet(vars, [
        js.call('# != null ? # : #', [l, l, _visitExpression(right)])
      ]);
    }

    var leftType = getStaticType(left);
    var rightType = getStaticType(right);

    js_ast.Expression operatorCall() {
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
      js_ast.Expression binary(String code) {
        return js.call(code, [notNull(left), notNull(right)])
          ..sourceInformation = _getLocation(node.operator.offset);
      }

      js_ast.Expression bitwise(String code) {
        return _coerceBitOperationResultToUnsigned(node, binary(code));
      }

      /// Similar to [binary] but applies a boolean conversion to the right
      /// operand, to match the boolean bitwise operators in dart:core.
      ///
      /// Short circuiting operators should not be used in [code], because the
      /// null checks for both operands must happen unconditionally.
      js_ast.Expression bitwiseBool(String code) {
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
  js_ast.Expression _coerceBitOperationResultToUnsigned(
      Expression node, js_ast.Expression uncoerced) {
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
    while (node is ParenthesizedExpression) {
      node = node.parent;
    }
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
      {bool nullable = true, js_ast.Expression variable, bool dynamicInvoke}) {
    // We use an invalid source location to signal that this is a temporary.
    // See [_isTemporary].
    // TODO(jmesserly): alternatives are
    // * (ab)use Element.isSynthetic, which isn't currently used for
    //   LocalVariableElementImpl, so we could repurpose to mean "temp".
    // * add a new property to LocalVariableElementImpl.
    // * create a new subtype of LocalVariableElementImpl to mark a temp.
    var id = astFactory
        .simpleIdentifier(StringToken(TokenType.IDENTIFIER, name, -1));

    variable ??= js_ast.TemporaryId(name);

    var idElement =
        TemporaryVariableElement.forNode(id, variable, _currentElement);
    id.staticElement = idElement;
    id.staticType = type;
    setIsDynamicInvoke(id, dynamicInvoke ?? type.isDynamic);
    addTemporaryVariable(idElement, nullable: nullable);
    return id;
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
      Map<js_ast.MetaLetVariable, js_ast.Expression> scope, Expression expr,
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
  Expression _bindValue(Map<js_ast.MetaLetVariable, js_ast.Expression> scope,
      String name, Expression expr,
      {Expression context}) {
    // No need to do anything for stateless expressions.
    if (isStateless(_currentFunction, expr, context)) return expr;

    var variable = js_ast.MetaLetVariable(name);
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
  /// The [js_ast.MetaLet] nodes automatically simplify themselves if they can.
  /// For example, if the result value is not used, then `t` goes away.
  @override
  js_ast.Expression visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    if (op.type == TokenType.BANG) {
      // If the expression is non-nullable already, this is a no-op.
      return isNullable(expr) ? notNull(expr) : _visitExpression(expr);
    }

    var dispatchType = getStaticType(expr);
    if (jsTypeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (!isNullable(expr)) {
        return js.call('#$op', _visitExpression(expr));
      }
    }

    assert(op.lexeme == '++' || op.lexeme == '--');

    // Handle the left hand side, to ensure each of its subexpressions are
    // evaluated only once.
    var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
    var left = _bindLeftHandSide(vars, expr, context: expr);

    // Desugar `x++` as `(x1 = x0 + 1, x0)` where `x0` is the original value
    // and `x1` is the new value for `x`.
    var x = _bindValue(vars, 'x', left, context: expr);

    var one = ast.integerLiteral(1)..staticType = types.intType;
    var increment = ast.binaryExpression(x, op.lexeme[0], one)
      ..staticElement = node.staticElement
      ..staticType = getStaticType(expr);

    var body = <js_ast.Expression>[
      _emitSet(left, increment),
      _visitExpression(x)
    ];
    return js_ast.MetaLet(vars, body, statelessResult: true);
  }

  @override
  js_ast.Expression visitPrefixExpression(PrefixExpression node) {
    var op = node.operator;

    // Logical negation, `!e`, is a boolean conversion context since it is
    // defined as `e ? false : true`.
    if (op.lexeme == '!') return _visitTest(node);

    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (jsTypeRep.unaryOperationIsPrimitive(dispatchType)) {
      if (op.lexeme == '~') {
        if (jsTypeRep.isNumber(dispatchType)) {
          js_ast.Expression jsExpr = js.call('~#', notNull(expr));
          return _coerceBitOperationResultToUnsigned(node, jsExpr);
        }
        return _emitOperatorCall(expr, op.lexeme[0], []);
      }
      if (!isNullable(expr)) {
        return js.call('$op#', _visitExpression(expr));
      }
      if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
        var x = _bindLeftHandSide(vars, expr, context: expr);

        var one = ast.integerLiteral(1)..staticType = types.intType;
        var increment = ast.binaryExpression(x, op.lexeme[0], one)
          ..staticElement = node.staticElement
          ..staticType = getStaticType(expr);

        return js_ast.MetaLet(vars, [_emitSet(x, increment)]);
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

    var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
    _cascadeTarget = _bindValue(vars, '_', node.target, context: node);
    var sections = _visitExpressionList(node.cascadeSections);
    sections.add(_visitExpression(_cascadeTarget));
    var result = js_ast.MetaLet(vars, sections, statelessResult: true);
    _cascadeTarget = savedCascadeTemp;
    return result;
  }

  @override
  js_ast.Expression visitParenthesizedExpression(
          ParenthesizedExpression node) =>
      // The printer handles precedence so we don't need to.
      _visitExpression(node.expression);

  js_ast.Parameter _emitFormalParameter(FormalParameter node) {
    var id = _emitParameter(node.declaredElement, declaration: true)
      ..sourceInformation = _nodeSpan(node);
    var isRestArg = node is! DefaultFormalParameter &&
        findAnnotation(node.declaredElement, isJsRestAnnotation) != null;
    return isRestArg ? js_ast.RestParameter(id) : id;
  }

  @override
  js_ast.This visitThisExpression(ThisExpression node) => js_ast.This();

  @override
  js_ast.Expression visitSuperExpression(SuperExpression node) =>
      js_ast.Super();

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

  js_ast.Expression _emitNullSafe(Expression node) {
    // Desugar `obj?.name` as ((x) => x == null ? null : x.name)(obj)
    var target = _getTarget(node);
    var vars = <js_ast.MetaLetVariable, js_ast.Expression>{};
    var t = _bindValue(vars, 't', target, context: target);

    var desugared = _stripNullAwareOp(node, t);
    return js_ast.MetaLet(vars, [
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
      var newNode = ast.methodInvoke(newTarget, invoke.methodName,
          invoke.typeArguments, invoke.argumentList.arguments)
        ..staticInvokeType = invoke.staticInvokeType;
      (newNode as MethodInvocationImpl).typeArgumentTypes =
          invoke.typeArgumentTypes;
      return newNode;
    }
  }

  List<js_ast.Expression> _getTypeArgs(Element member, DartType instantiated) {
    DartType type;
    if (member is ExecutableElement) {
      type = member.type;
    } else if (member is VariableElement) {
      type = member.type;
    }

    // TODO(jmesserly): handle explicitly passed type args.
    if (type == null) return null;
    return _emitFunctionTypeArguments(null, type, instantiated);
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  js_ast.Expression _emitPropertyGet(
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
    var isSuper = jsTarget is js_ast.Super;
    if (isSuper &&
        accessor.isSynthetic &&
        field is FieldElementImpl &&
        !virtualFields.isVirtual(field)) {
      // If super.x is a sealed field, then x is an instance property since
      // subclasses cannot override x.
      jsTarget = js_ast.This()..sourceInformation = jsTarget.sourceInformation;
    }

    js_ast.Expression result;
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

  js_ast.Expression _getImplicitCallTarget(InterfaceType fromType) {
    var callMethod = fromType.lookUpInheritedMethod('call');
    if (callMethod == null || _usesJSInterop(fromType.element)) return null;
    return _emitMemberName('call', type: fromType, element: callMethod);
  }

  /// Emits a generic send, like an operator method.
  ///
  /// **Please note** this function does not support method invocation syntax
  /// `obj.name(args)` because that could be a getter followed by a call.
  /// See [visitMethodInvocation].
  js_ast.Expression _emitOperatorCall(
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
      return js_ast.PropertyAccess(
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
  js_ast.Expression visitConditionalExpression(ConditionalExpression node) {
    return js.call('# ? # : #', [
      _visitTest(node.condition),
      _visitExpression(node.thenExpression),
      _visitExpression(node.elseExpression)
    ]);
  }

  @override
  js_ast.Expression visitThrowExpression(ThrowExpression node) {
    return runtimeCall('throw(#)', [_visitExpression(node.expression)]);
  }

  @override
  js_ast.Expression visitRethrowExpression(RethrowExpression node) {
    return runtimeCall(
        'rethrow(#)', [_emitSimpleIdentifier(_rethrowParameter)]);
  }

  /// Visits a statement, and ensures the resulting AST handles block scope
  /// correctly. Essentially, we need to promote a variable declaration
  /// statement into a block in some cases, e.g.
  ///
  ///     do var x = 5; while (false); // Dart
  ///     do { let x = 5; } while (false); // JS
  js_ast.Statement _visitScope(Statement stmt) {
    var result = _visitStatement(stmt);
    if (result is js_ast.ExpressionStatement &&
        result.expression is js_ast.VariableDeclarationList) {
      return js_ast.Block([result]);
    }
    return result;
  }

  @override
  js_ast.Statement visitIfStatement(IfStatement node) {
    return js_ast.If(_visitTest(node.condition),
        _visitScope(node.thenStatement), _visitScope(node.elseStatement));
  }

  @override
  js_ast.While visitWhileStatement(WhileStatement node) {
    return js_ast.While(_visitTest(node.condition), _visitScope(node.body));
  }

  @override
  js_ast.Do visitDoStatement(DoStatement node) {
    return js_ast.Do(_visitScope(node.body), _visitTest(node.condition));
  }

  js_ast.Statement _emitAwaitFor(
      ForEachParts forParts, js_ast.Statement jsBody) {
    // Emits `await for (var value in stream) ...`, which desugars as:
    //
    // let iter = new StreamIterator(stream);
    // try {
    //   while (await iter.moveNext()) {
    //     let value = iter.current;
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
        [_visitExpression(forParts.iterable)]);
    var iter = js_ast.TemporaryId('iter');
    SimpleIdentifier variable;
    js_ast.Expression init;
    if (forParts is ForEachPartsWithIdentifier) {
      variable = forParts.identifier;
      init = js
          .call('# = #.current', [_visitExpression(forParts.identifier), iter]);
    } else if (forParts is ForEachPartsWithDeclaration) {
      variable = forParts.loopVariable.identifier;
      init = js.call('let # = #.current', [_emitVariableDef(variable), iter]);
    } else {
      throw StateError('Unrecognized for loop parts');
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
          js_ast.Yield(js.call('#.moveNext()', iter))
            ..sourceInformation = _nodeStart(variable),
          init,
          jsBody,
          js_ast.Yield(js.call('#.cancel()', iter))
            ..sourceInformation = _nodeStart(variable)
        ]);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    var label = node.label;
    return js_ast.Break(label?.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    var label = node.label;
    if (node.label != null) {
      var parent = node.parent;
      if (parent is SwitchCase) {
        // If this is the last statement in this case, and we're jumping to the
        // next statement in the following case, just omit the continue.  JS
        // will fall through.
        if (parent.statements.last == node) {
          var grandparent = parent.parent;
          if (grandparent is SwitchStatement) {
            var members = grandparent.members;
            for (int i = 0; i < members.length; ++i) {
              if (members[i] == parent) {
                if (i < members.length - 1) {
                  var next = members[i + 1];
                  if (next is SwitchMember &&
                      next.labels
                          .map((l) => l.label.name)
                          .contains(node.label.name)) {
                    return js.comment('continue to next case');
                  }
                }
                break;
              }
            }
          }
        }
      }
    }
    return js_ast.Continue(label?.name);
  }

  @override
  visitTryStatement(TryStatement node) {
    var savedSuperAllowed = _superAllowed;
    _superAllowed = false;
    var finallyBlock = _visitStatement(node.finallyBlock)?.toBlock();
    _superAllowed = savedSuperAllowed;
    return js_ast.Try(_visitStatement(node.body).toBlock(),
        _visitCatch(node.catchClauses), finallyBlock);
  }

  js_ast.Catch _visitCatch(NodeList<CatchClause> clauses) {
    if (clauses == null || clauses.isEmpty) return null;

    var caughtError = _createTemporary('e', types.dynamicType);
    var savedRethrow = _rethrowParameter;
    _rethrowParameter = caughtError;

    // If we have more than one catch clause, always create a temporary so we
    // don't shadow any names.
    var exceptionParameter =
        (clauses.length == 1 ? clauses[0].exceptionParameter : null) ??
            _createTemporary('ex', types.dynamicType);

    var stackTraceParameter =
        (clauses.length == 1 ? clauses[0].stackTraceParameter : null) ??
            (clauses.any((c) => c.stackTraceParameter != null)
                ? _createTemporary('st', types.dynamicType)
                : null);

    // Rethrow if the exception type didn't match.
    js_ast.Statement catchBody =
        js_ast.Throw(_emitSimpleIdentifier(caughtError));
    for (var clause in clauses.reversed) {
      catchBody = _catchClauseGuard(
          clause, catchBody, exceptionParameter, stackTraceParameter);
    }
    var catchStatements = [
      js.statement('let # = #.getThrown(#)', [
        _emitVariableDef(exceptionParameter),
        runtimeModule,
        _emitSimpleIdentifier(caughtError)
      ]),
    ];
    if (stackTraceParameter != null) {
      catchStatements.add(js.statement('let # = #.stackTrace(#)', [
        _emitVariableDef(stackTraceParameter),
        runtimeModule,
        _emitSimpleIdentifier(caughtError)
      ]));
    }
    catchStatements.add(catchBody);

    var catchVarDecl = _emitSimpleIdentifier(caughtError) as js_ast.Identifier;
    _rethrowParameter = savedRethrow;
    return js_ast.Catch(catchVarDecl, js_ast.Block(catchStatements));
  }

  js_ast.Statement _catchClauseGuard(
      CatchClause node,
      js_ast.Statement otherwise,
      SimpleIdentifier exceptionParameter,
      SimpleIdentifier stackTraceParameter) {
    var body = <js_ast.Statement>[];
    var vars = HashSet<String>();

    void declareVariable(SimpleIdentifier variable, SimpleIdentifier value) {
      if (variable == null) return;
      vars.add(variable.name);
      if (variable.name != value.name) {
        body.add(js.statement('let # = #',
            [visitSimpleIdentifier(variable), _emitSimpleIdentifier(value)]));
      }
    }

    if (node.catchKeyword != null) {
      declareVariable(node.exceptionParameter, exceptionParameter);
      declareVariable(node.stackTraceParameter, stackTraceParameter);
    }

    body.add(_visitStatement(node.body).toScopedBlock(vars));
    var then = js_ast.Statement.from(body);

    // Discard following clauses, if any, as they are unreachable.
    if (node.exceptionType == null ||
        rules.isSubtypeOf(types.objectType, node.exceptionType.type)) {
      return then;
    }

    var condition =
        _emitIsExpression(exceptionParameter, node.exceptionType.type);
    return js_ast.If(condition, then, otherwise)
      ..sourceInformation = _nodeStart(node);
  }

  @override
  js_ast.SwitchCase visitSwitchCase(SwitchCase node) {
    var expr = _visitExpression(node.expression);
    var body = _visitStatementList(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return js_ast.SwitchCase(expr, js_ast.Block(body));
  }

  @override
  js_ast.SwitchCase visitSwitchDefault(SwitchDefault node) {
    var body = _visitStatementList(node.statements);
    if (node.labels.isNotEmpty) {
      body.insert(0, js.comment('Unimplemented case labels: ${node.labels}'));
    }
    // TODO(jmesserly): make sure we are statically checking fall through
    return js_ast.SwitchCase.defaultCase(js_ast.Block(body));
  }

  js_ast.SwitchCase _emitSwitchMember(SwitchMember node) {
    if (node is SwitchCase) {
      return visitSwitchCase(node);
    } else {
      return visitSwitchDefault(node as SwitchDefault);
    }
  }

  @override
  js_ast.Switch visitSwitchStatement(SwitchStatement node) => js_ast.Switch(
      _visitExpression(node.expression),
      node.members?.map(_emitSwitchMember)?.toList());

  @override
  js_ast.Statement visitLabeledStatement(LabeledStatement node) {
    var result = _visitStatement(node.statement);
    for (var label in node.labels.reversed) {
      result = js_ast.LabeledStatement(label.label.name, result);
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
      errors.add(
          _currentCompilationUnit.lineInfo,
          AnalysisError(_currentCompilationUnit.source, node.offset,
              node.length, invalidJSInteger, [lexeme, nearest]));
    }
    return js_ast.LiteralNumber('$valueInJS');
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) => js.number(node.value);

  @override
  visitNullLiteral(NullLiteral node) => js_ast.LiteralNull();

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    return emitDartSymbol(node.components.join('.'));
  }

  @override
  js_ast.Expression visitListLiteral(ListLiteral node) {
    var elementType = (node.staticType as InterfaceType).typeArguments[0];
    var elements = _visitCollectionElementList(node.elements, elementType);
    if (!node.isConst) {
      return _emitList(elementType, elements);
    }
    return _emitConstList(elementType, elements);
  }

  js_ast.Expression _emitSetLiteral(SetOrMapLiteral node) {
    var type = node.staticType as InterfaceType;
    var elementType = type.typeArguments[0];
    var jsElements = _visitCollectionElementList(node.elements, elementType);
    if (!node.isConst) {
      var setType = _emitType(type);
      if (node.elements.isEmpty) {
        return js.call('#.new()', [setType]);
      }
      return js.call('#.from([#])', [setType, jsElements]);
    }
    return cacheConst(
        runtimeCall('constSet(#, [#])', [_emitType(elementType), jsElements]));
  }

  js_ast.Expression _emitConstList(
      DartType elementType, List<js_ast.Expression> elements) {
    // dart.constList helper internally depends on _interceptors.JSArray.
    _declareBeforeUse(_jsArray);
    return cacheConst(
        runtimeCall('constList([#], #)', [elements, _emitType(elementType)]));
  }

  js_ast.Expression _emitList(
      DartType itemType, List<js_ast.Expression> items) {
    var list = js_ast.ArrayInitializer(items);

    // TODO(jmesserly): analyzer will usually infer `List<Object>` because
    // that is the least upper bound of the element types. So we rarely
    // generate a plain `List<dynamic>` anymore.
    if (itemType.isDynamic) return list;

    // Call `new JSArray<E>.of(list)`
    var arrayType = _jsArray.type.instantiate([itemType]);
    return js.call('#.of(#)', [_emitType(arrayType), list]);
  }

  js_ast.Expression _emitMapLiteral(SetOrMapLiteral node) {
    var type = node.staticType as InterfaceType;
    var elementType = type.typeArguments[0];
    var jsElements = _visitCollectionElementList(node.elements, elementType);
    if (!node.isConst) {
      var mapType = _emitMapImplType(type);
      if (node.elements.isEmpty) {
        return js.call('new #.new()', [mapType]);
      }
      return js.call('new #.from([#])', [mapType, jsElements]);
    }
    return _emitConstMap(type, jsElements);
  }

  js_ast.Expression _emitConstMap(
      InterfaceType type, List<js_ast.Expression> entries) {
    var typeArgs = type.typeArguments;
    return cacheConst(runtimeCall('constMap(#, #, [#])',
        [_emitType(typeArgs[0]), _emitType(typeArgs[1]), entries]));
  }

  js_ast.Expression _emitMapImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= jsTypeRep.isPrimitive(typeArgs[0]);
    type = identity ? identityHashMapImplType : linkedHashMapImplType;
    return _emitType(type.instantiate(typeArgs));
  }

  js_ast.Expression _emitConstSet(
      DartType elementType, List<js_ast.Expression> elements) {
    return cacheConst(
        runtimeCall('constSet([#], #)', [elements, _emitType(elementType)]));
  }

  js_ast.Expression _emitSetImplType(InterfaceType type, {bool identity}) {
    var typeArgs = type.typeArguments;
    if (typeArgs.isEmpty) return _emitType(type);
    identity ??= jsTypeRep.isPrimitive(typeArgs[0]);
    type = identity ? identityHashSetImplType : linkedHashSetImplType;
    return _emitType(type.instantiate(typeArgs));
  }

  @override
  js_ast.LiteralString visitSimpleStringLiteral(SimpleStringLiteral node) =>
      js.escapedString(node.value, '"');

  @override
  js_ast.Expression visitAdjacentStrings(AdjacentStrings node) {
    var nodes = node.strings;
    if (nodes == null || nodes.isEmpty) return null;
    return js_ast.Expression.binary(_visitExpressionList(nodes), '+');
  }

  @override
  js_ast.Expression visitStringInterpolation(StringInterpolation node) {
    var parts = <js_ast.Expression>[];
    for (var elem in node.elements) {
      if (elem is InterpolationString) {
        if (elem.value.isEmpty) continue;
        parts.add(js.escapedString(elem.value, '"'));
      } else {
        var e = (elem as InterpolationExpression).expression;
        var jsExpr = _visitExpression(e);
        parts.add(e.staticType == types.stringType && !isNullable(e)
            ? jsExpr
            : runtimeCall('str(#)', [jsExpr]));
      }
    }
    if (parts.isEmpty) return js.string('');
    return js_ast.Expression.binary(parts, '+');
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) =>
      _visitExpression(node.expression);

  @override
  visitBooleanLiteral(BooleanLiteral node) => js.boolean(node.value);

  /// Visit a Dart [node] that produces a JS expression, and attaches a source
  /// location.
  // TODO(jmesserly): parameter type should be `Expression`
  js_ast.Expression _visitExpression(AstNode node) {
    if (node == null) return null;
    var e = node.accept<js_ast.Node>(this) as js_ast.Expression;
    e.sourceInformation ??= _nodeStart(node);
    return e;
  }

  /// Visits [nodes] with [_visitExpression].
  List<js_ast.Expression> _visitExpressionList(Iterable<AstNode> nodes) {
    return nodes?.map(_visitExpression)?.toList();
  }

  /// Visit a Dart [node] that produces a JS statement, and marks its source
  /// location for debugging.
  js_ast.Statement _visitStatement(AstNode node) {
    if (node == null) return null;
    var s = node.accept<js_ast.Node>(this) as js_ast.Statement;
    if (s is! Block) s.sourceInformation = _nodeStart(node);
    return s;
  }

  /// Visits [nodes] with [_visitStatement].
  List<js_ast.Statement> _visitStatementList(Iterable<AstNode> nodes) {
    return nodes?.map(_visitStatement)?.toList();
  }

  /// Returns a [js_ast.Expression] for each [CollectionElement] in [nodes].
  ///
  /// Visits all [nodes] in order and nested [CollectionElement]s depth first
  /// to produce [JS.Expresison]s intended to be used when outputing a
  /// collection literal.
  ///
  /// [IfElement]s and [ForElement]s will be transformed into a spread of a
  /// self invoking function that reutrns a list.
  ///
  /// Example Dart:
  ///     [1, if(true) for (var i=2; i<10; i++) i, 10]
  ///
  /// JS:
  ///     [1, ...(() => {
  ///       let temp = JSArrayOfint().of([]);
  ///       if (true) for (let i = 2; i < 10; i++) temp.push(i);
  ///       return temp;
  ///     })(), 10]
  List<js_ast.Expression> _visitCollectionElementList(
      Iterable<CollectionElement> nodes, DartType elementType) {
    /// Returns [body] wrapped in a function and a call.
    ///
    /// Alternatively if [body] contains a yield, will wrap body in a gerarator
    /// fucntion, call it, and yield the result of [yieldType].
    /// TODO(nshahan) Move to share between compilers. Need to work out a common
    /// emitLibraryName().
    js_ast.Expression detectYieldAndCall(
        js_ast.Block body, InterfaceType yieldType) {
      var finder = YieldFinder();
      body.accept(finder);
      if (finder.hasYield) {
        var genFn = js_ast.Fun([], body, isGenerator: true);
        var asyncLibrary = emitLibraryName(types.futureType.element.library);
        return js_ast.Yield(js.call(
            '#.async(#, #)', [asyncLibrary, _emitType(yieldType), genFn]));
      }
      return js_ast.Call(js_ast.ArrowFun([], body), []);
    }

    var expressions = <js_ast.Expression>[];
    for (var node in nodes) {
      if (_isUiAsCodeElement(node)) {
        // Create a temporary variable to build a new collection from.
        var previousCollectionVariable = _currentCollectionVariable;
        var arrayType = _jsArray.type.instantiate([elementType]);
        var temporaryIdentifier = _createTemporary('items', arrayType);
        _currentCollectionVariable = _emitSimpleIdentifier(temporaryIdentifier);
        var items = js.statement('let # = #',
            [_currentCollectionVariable, _emitList(elementType, [])]);

        // Build up a list for the control-flow-collections element and wrap in
        // a function call that returns the list.
        var functionBody = js_ast.Block([
          items,
          node.accept<js_ast.Node>(this) as js_ast.Statement,
          js_ast.Return(_currentCollectionVariable)
        ]);
        var functionCall = detectYieldAndCall(functionBody, arrayType);

        // Finally, spread the temporary control-flow-collections list.
        expressions.add(js_ast.Spread(functionCall));
        _currentCollectionVariable = previousCollectionVariable;
      } else if (node is MapLiteralEntry) {
        expressions.add(_visitExpression(node.key));
        expressions.add(_visitExpression(node.value));
      } else {
        expressions.add(_visitExpression(node));
      }
    }
    return expressions;
  }

  /// Visits [node] with [_visitExpression] and wraps the result in a call to
  /// append it to the list tracked by [_currentCollectionVariable].
  js_ast.Statement _visitNestedCollectionElement(CollectionElement node) {
    js_ast.Statement pushToCurrentCollection(Expression value) => js.statement(
        '#.push(#)', [_currentCollectionVariable, _visitExpression(value)]);

    if (node is MapLiteralEntry) {
      return js_ast.Block([
        pushToCurrentCollection(node.key),
        pushToCurrentCollection(node.value)
      ]);
    }

    return pushToCurrentCollection(node as Expression);
  }

  /// Returns `true` if [node] is a UI-as-Code [CollectionElement].
  bool _isUiAsCodeElement(node) =>
      node is IfElement || node is ForElement || node is SpreadElement;

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
  HoverComment _hoverComment(js_ast.Expression expr, AstNode node) {
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
  js_ast.Expression _visitTest(Expression node) {
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
      js_ast.Expression shortCircuit(String code) {
        return js.call(code,
            [_visitTest(node.leftOperand), _visitTest(node.rightOperand)]);
      }

      var op = node.operator.type.lexeme;
      if (op == '&&') return shortCircuit('# && #');
      if (op == '||') return shortCircuit('# || #');
    }
    if (node is AsExpression && CoercionReifier.isImplicit(node)) {
      assert(node.staticType == types.boolType);
      return runtimeCall('dtest(#)', [_visitExpression(node.expression)]);
    }
    var result = _visitExpression(node);
    if (isNullable(node)) result = runtimeCall('test(#)', [result]);
    return result;
  }

  /// Like [_emitMemberName], but for declaration sites.
  ///
  /// Unlike call sites, we always have an element available, so we can use it
  /// directly rather than computing the relevant options for [_emitMemberName].
  js_ast.Expression _declareMemberName(ExecutableElement e,
      {bool useExtension}) {
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
  js_ast.Expression _emitMemberName(String name,
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
        if (parts.length < 2) return propertyName(runtimeName);

        js_ast.Expression result = js_ast.Identifier(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          result = js_ast.PropertyAccess(result, propertyName(parts[i]));
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
    name = js_ast.memberNameForDartMember(name, _isExternal(element));
    if (useExtension) {
      return getExtensionSymbolInternal(name);
    }
    return propertyName(name);
  }

  /// Emits the name of a static member, suitable for use in a JS property
  /// access when combined with [_emitStaticClassName].
  ///
  /// The member [name] should be passed, as well as its [element] when it's
  /// available. If the element is `external`, the element is used to statically
  /// resolve the JS interop/dart:html static member. Otherwise it is ignored.
  js_ast.Expression _emitStaticMemberName(String name, [Element element]) {
    if (element != null && _isExternal(element)) {
      var newName = getAnnotationName(element, isJSName) ??
          _getJSInteropStaticMemberName(element);
      if (newName != null) return js.escapedString(newName, "'");
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
    return propertyName(name);
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

  /// Return true if this is one of the methods/properties on all Dart Objects
  /// (toString, hashCode, noSuchMethod, runtimeType, ==).
  @override
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

    InterfaceType expectedType;
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

  js_ast.Expression _throwUnsafe(String message) => runtimeCall(
      'throw(Error(#))', [js.escapedString("compile error: $message")]);

  Null _unreachable(Object node) {
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

  /// Unused, see [_catchClauseGuard].
  @override
  visitCatchClause(CatchClause node) => _unreachable(node);

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

  /// Unused. Handled in [visitForStatement].
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
  js_ast.Node visitOnClause(OnClause node) => _unreachable(node);

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

  /// Unused, see [visitSetOrMapLiteral].
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

  js_ast.For _emitFor(ForParts forParts, js_ast.Statement body) {
    js_ast.Expression init;
    if (forParts is ForPartsWithExpression) {
      init = _visitExpression(forParts.initialization);
    } else if (forParts is ForPartsWithDeclarations) {
      init = visitVariableDeclarationList(forParts.variables);
    } else {
      throw StateError('Unrecognized for loop parts');
    }
    js_ast.Expression update;
    if (forParts.updaters != null && forParts.updaters.isNotEmpty) {
      update = js_ast.Expression.binary(
              forParts.updaters.map(_visitExpression).toList(), ',')
          .toVoidExpression();
    }
    return js_ast.For(init, _visitTest(forParts.condition), update, body);
  }

  js_ast.Statement _emitForEach(
      ForEachParts forParts, js_ast.Statement jsBody) {
    var jsIterable = _visitExpression(forParts.iterable);
    js_ast.Expression jsLeftExpression;
    if (forParts is ForEachPartsWithIdentifier) {
      jsLeftExpression = _visitExpression(forParts.identifier);
    } else if (forParts is ForEachPartsWithDeclaration) {
      var id = _emitVariableDef(forParts.loopVariable.identifier);
      jsLeftExpression = js.call('let #', id);
      if (_annotatedNullCheck(forParts.loopVariable.declaredElement)) {
        jsBody = js_ast.Block(
            [_nullParameterCheck(js_ast.Identifier(id.name)), jsBody]);
      }
      if (variableIsReferenced(id.name, jsIterable)) {
        var temp = js_ast.TemporaryId('iter');
        return js_ast.Block([
          jsIterable.toVariableDeclaration(temp),
          js_ast.ForOf(jsLeftExpression, temp, jsBody)
        ]);
      }
    } else {
      throw StateError('Unrecognized for loop parts');
    }
    return js_ast.ForOf(jsLeftExpression, jsIterable, jsBody);
  }

  @override
  js_ast.Statement visitForElement(ForElement node) {
    var jsBody = _isUiAsCodeElement(node.body)
        ? node.body.accept(this) as js_ast.Statement
        : _visitNestedCollectionElement(node.body);
    return _forAdaptor(node.forLoopParts, node.awaitKeyword, jsBody);
  }

  @override
  js_ast.Statement visitIfElement(IfElement node) {
    var thenElement = _isUiAsCodeElement(node.thenElement)
        ? node.thenElement.accept(this) as js_ast.Statement
        : _visitNestedCollectionElement(node.thenElement);

    js_ast.Statement elseElement;
    if (node.elseElement != null) {
      if (_isUiAsCodeElement(node.elseElement)) {
        elseElement =
            node.elseElement.accept<js_ast.Node>(this) as js_ast.Statement;
      } else {
        elseElement = _visitNestedCollectionElement(node.elseElement);
      }
    }

    return js_ast.If(_visitTest(node.condition), thenElement, elseElement);
  }

  @override
  visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) =>
      _unreachable(node);

  @override
  visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) =>
      _unreachable(node);

  @override
  js_ast.Statement visitForStatement(ForStatement node) =>
      _forAdaptor(node.forLoopParts, node.awaitKeyword, _visitScope(node.body));

  js_ast.Statement _forAdaptor(
      ForLoopParts forParts, Token awaitKeyword, js_ast.Statement jsBody) {
    /// Returns a new scoped block starting with [first] followed by [rest].
    ///
    /// Performs one level of scope flattening when [rest] is already a scoped
    /// block.
    js_ast.Block insertFirst(js_ast.Statement first, js_ast.Statement rest) {
      var bodyStatements = [first];
      if (rest is js_ast.Block) {
        bodyStatements.addAll(rest.statements);
      } else {
        bodyStatements.add(rest);
      }
      return js_ast.Block(bodyStatements);
    }

    if (forParts is ForParts) {
      return _emitFor(forParts, jsBody);
    } else if (forParts is ForEachParts) {
      // If needed, assert a cast inside the body before the variable is read.
      SimpleIdentifier variable;
      if (forParts is ForEachPartsWithIdentifier) {
        variable = forParts.identifier;
      } else if (forParts is ForEachPartsWithDeclaration) {
        variable = forParts.loopVariable.identifier;
      } else {
        throw StateError('Unrecognized for loop parts');
      }
      var castType = getImplicitCast(variable);
      if (castType != null) {
        var castStatement =
            _emitCast(castType, _visitExpression(variable)).toStatement();
        jsBody = insertFirst(castStatement, jsBody);
      }
      if (awaitKeyword == null) {
        return _emitForEach(forParts, jsBody);
      } else {
        return _emitAwaitFor(forParts, jsBody);
      }
    }
    return _unreachable(forParts);
  }

  @override
  visitSetOrMapLiteral(SetOrMapLiteral node) =>
      node.isSet ? _emitSetLiteral(node) : _emitMapLiteral(node);

  @override
  js_ast.Statement visitSpreadElement(SpreadElement node) {
    /// Returns `true` if [node] is or is a child element of a map literal.
    bool isMap(AstNode node) {
      if (node is SetOrMapLiteral) return node.isMap;
      if (node is ListLiteral) return false;
      return isMap(node.parent);
    }

    /// Returns [expression] wrapped in an implict cast to [castType] or
    /// [expression] as provided if [castType] is `null` signifying that
    /// no cast is needed.
    js_ast.Expression wrapInImplicitCast(
            js_ast.Expression expression, DartType castType) =>
        castType == null ? expression : _emitCast(castType, expression);

    /// Returns a statement spreading the elements of [expression] into
    /// [_currentCollectionVariable].
    ///
    /// Expects the collection literal containing [expression] to be a list or
    /// set literal. Inserts implicit casts to [elementCastType] for each
    /// element if needed.
    js_ast.Statement emitListOrSetSpread(
        js_ast.Expression expression, DartType elementCastType) {
      var forEachTemp =
          _emitSimpleIdentifier(_createTemporary('i', types.dynamicType));
      return js.statement('#.forEach((#) => #.push(#))', [
        expression,
        forEachTemp,
        _currentCollectionVariable,
        wrapInImplicitCast(forEachTemp, elementCastType)
      ]);
    }

    /// Returns a statement spreading the key/value pairs of [expression]
    /// into [_currentCollectionVariable].
    ///
    /// Expects the collection literal containing [expression] to be a map
    /// literal. Inserts implicit casts to [keyCastType] for keys and
    /// [valueCastType] for values if needed.
    js_ast.Statement emitMapSpread(js_ast.Expression expression,
        DartType keyCastType, DartType valueCastType) {
      var keyTemp =
          _emitSimpleIdentifier(_createTemporary('k', types.dynamicType));
      var valueTemp =
          _emitSimpleIdentifier(_createTemporary('v', types.dynamicType));
      return js.statement('#.forEach((#, #) => {#.push(#); #.push(#)})', [
        expression,
        keyTemp,
        valueTemp,
        _currentCollectionVariable,
        wrapInImplicitCast(keyTemp, keyCastType),
        _currentCollectionVariable,
        wrapInImplicitCast(valueTemp, valueCastType)
      ]);
    }

    /// Appends all elements in [expression] to the collection being built.
    ///
    /// Uses implict cast information from [node] to insert the correct casts
    /// for the collection elements when spreading. Inspects parents of [node]
    /// to determine the type of the enclosing collection literal.
    js_ast.Statement emitSpread(js_ast.Expression expression, Expression node) {
      expression = wrapInImplicitCast(expression, getImplicitCast(node));

      // Start searching for a map literal at the parent of the SpreadElement.
      if (isMap(node.parent.parent)) {
        return emitMapSpread(expression, getImplicitSpreadKeyCast(node),
            getImplicitSpreadValueCast(node));
      }
      return emitListOrSetSpread(expression, getImplicitSpreadCast(node));
    }

    /// Emits a null check on [expression] then appends all elements to the
    /// collection being built.
    ///
    /// Uses implict cast information from [node] to insert the correct casts
    /// for the collection elements when spreading. Inspects parents of [node]
    /// to determine the type of the enclosing collection literal.
    js_ast.Statement emitNullSafeSpread(
        js_ast.Expression expression, Expression node) {
      // TODO(nshahan) Could optimize out if we know the value is null.
      var spreadItems =
          _emitSimpleIdentifier(_createTemporary('items', getStaticType(node)));
      return js_ast.Block([
        js.statement('let # = #', [spreadItems, expression]),
        js.statement(
            'if (# != null) #', [spreadItems, emitSpread(spreadItems, node)])
      ]);
    }

    var expression = _visitExpression(node.expression);
    return node.beginToken.lexeme == '...?'
        ? emitNullSafeSpread(expression, node.expression)
        : emitSpread(expression, node.expression);
  }

  @override
  visitForPartsWithDeclarations(ForPartsWithDeclarations node) =>
      _unreachable(node);

  @override
  visitForPartsWithExpression(ForPartsWithExpression node) =>
      _unreachable(node);

  @override
  visitExtensionDeclaration(ExtensionDeclaration node) => _unreachable(node);

  @override
  visitExtensionOverride(ExtensionOverride node) => _unreachable(node);
}

// TODO(jacobr): we would like to do something like the following
// but we don't have summary support yet.
// bool _supportJsExtensionMethod(AnnotatedNode node) =>
//    _getAnnotation(node, "SupportJsExtensionMethod") != null;

/// A special kind of element created by the compiler, signifying a temporary
/// variable. These objects use instance equality, and should be shared
/// everywhere in the tree where they are treated as the same variable.
class TemporaryVariableElement extends LocalVariableElementImpl {
  final js_ast.Expression jsVariable;

  TemporaryVariableElement.forNode(
      Identifier name, this.jsVariable, Element enclosingElement)
      : super.forNode(name) {
    this.enclosingElement = enclosingElement is ElementHandle
        ? enclosingElement.actualElement
        : enclosingElement;
  }

  @override
  int get hashCode => identityHashCode(this);

  @override
  bool operator ==(Object other) => identical(this, other);
}

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
