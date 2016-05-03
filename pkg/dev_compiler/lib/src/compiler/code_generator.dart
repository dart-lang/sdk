// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet;
import 'dart:math' show min, max;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart' show StringToken;
//TODO(leafp): Remove deprecated dependency
//ignore: DEPRECATED_MEMBER_USE
import 'package:analyzer/src/generated/element.dart'
    show DynamicTypeImpl, LocalVariableElementImpl;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, NamespaceBuilder;
import 'package:analyzer/src/generated/type_system.dart'
    show StrongTypeSystemImpl;
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/src/task/strong/info.dart' show DynamicInvoke;
import 'package:source_maps/source_maps.dart';

import '../closure/closure_annotator.dart' show ClosureAnnotator;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import 'ast_builder.dart' show AstBuilder;
import 'compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleFormat;
import 'element_helpers.dart';
import 'element_loader.dart' show ElementLoader;
import 'extension_types.dart' show ExtensionTypeSet;
import 'js_field_storage.dart' show checkForPropertyOverride, getSuperclasses;
import 'js_interop.dart';
import 'js_metalet.dart' as JS;
import 'js_names.dart' as JS;
import 'js_typeref_codegen.dart' show JsTypeRefCodegen;
import 'module_builder.dart'
    show LegacyModuleBuilder, NodeModuleBuilder, pathToJSIdentifier;
import 'nullable_type_inference.dart' show NullableTypeInference;
import 'reify_coercions.dart' show CoercionReifier;
import 'side_effect_analysis.dart' show ConstFieldVisitor, isStateless;
import 'source_map_printer.dart' show SourceMapPrintingContext;

class CodeGenerator extends GeneralizingAstVisitor
    with ClosureAnnotator, JsTypeRefCodegen, NullableTypeInference {
  final AnalysisContext context;
  final CompilerOptions options;
  final rules = new StrongTypeSystemImpl();

  /// The set of libraries we are currently compiling, and the temporaries used
  /// to refer to them.
  ///
  /// We sometimes special case codegen for a single library, as it simplifies
  /// name scoping requirements.
  final _libraries = new Map<LibraryElement, JS.Identifier>();

  /// Imported libraries, and the temporaries used to refer to them.
  final _imports = new Map<LibraryElement, JS.TemporaryId>();

  /// The list of output module items, in the order they need to be emitted in.
  final _moduleItems = <JS.ModuleItem>[];

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

  final _privateNames =
      new HashMap<LibraryElement, HashMap<String, JS.TemporaryId>>();
  final _initializingFormalTemps =
      new HashMap<ParameterElement, JS.TemporaryId>();

  final _dartxVar = new JS.Identifier('dartx');
  final _runtimeLibVar = new JS.Identifier('dart');
  final namedArgumentTemp = new JS.TemporaryId('opts');

  final _hasDeferredSupertype = new HashSet<ClassElement>();

  final _eagerTopLevelFields = new HashSet<Element>.identity();

  /// The  type provider from the current Analysis [context].
  final TypeProvider types;

  final LibraryElement dartCoreLibrary;
  final LibraryElement dartJSLibrary;

  /// The dart:async `StreamIterator<>` type.
  final InterfaceType _asyncStreamIterator;

  /// The dart:_interceptors JSArray element.
  final ClassElement _jsArray;

  ConstFieldVisitor _constField;

  /// The current function body being compiled.
  FunctionBody _currentFunction;

  /// Helper class for emitting elements in the proper order to allow
  /// JS to load the module.
  ElementLoader _loader;

  BuildUnit _buildUnit;

  String _buildRoot;

  /// Whether we are currently generating code for the body of a `JS()` call.
  bool _isInForeignJS = false;

  CodeGenerator(AnalysisContext c, this.options, this._extensionTypes)
      : context = c,
        types = c.typeProvider,
        _asyncStreamIterator =
            _getLibrary(c, 'dart:async').getType('StreamIterator').type,
        _jsArray = _getLibrary(c, 'dart:_interceptors').getType('JSArray'),
        dartCoreLibrary = _getLibrary(c, 'dart:core'),
        dartJSLibrary = _getLibrary(c, 'dart:js');

  LibraryElement get currentLibrary => _loader.currentElement.library;

  /// The main entry point to JavaScript code generation.
  ///
  /// Takes the metadata for the build unit, as well as resolved trees and
  /// errors, and computes the output module code and optionally the source map.
  JSModuleFile compile(BuildUnit unit, List<CompilationUnit> compilationUnits,
      List<String> errors) {
    _buildUnit = unit;
    _buildRoot = _buildUnit.buildRoot;
    if (!_buildRoot.endsWith('/')) {
      _buildRoot = '$_buildRoot/';
    }

    var jsTree = _emitModule(compilationUnits);
    var codeAndSourceMap = _writeJSText(unit, jsTree);

    List<int> summary;
    if (options.summarizeApi) {
      var assembler = new PackageBundleAssembler();
      compilationUnits
          .map((u) => u.element.library)
          .toSet()
          .forEach(assembler.serializeLibraryElement);
      summary = assembler.assemble().toBuffer();
    }

    return new JSModuleFile(
        unit.name, errors, codeAndSourceMap.e0, codeAndSourceMap.e1, summary);
  }

  Tuple2<String, Map> _writeJSText(BuildUnit unit, JS.Program jsTree) {
    var opts = new JS.JavaScriptPrintingOptions(
        emitTypes: options.closure,
        allowKeywordsInProperties: true,
        allowSingleLineIfStatements: true);
    JS.SimpleJavaScriptPrintingContext printer;
    SourceMapBuilder sourceMap;
    if (options.sourceMap) {
      var sourceMapContext = new SourceMapPrintingContext();
      sourceMap = sourceMapContext.sourceMap;
      printer = sourceMapContext;
    } else {
      printer = new JS.SimpleJavaScriptPrintingContext();
    }

    jsTree.accept(new JS.Printer(opts, printer,
        localNamer: new JS.TemporaryNamer(jsTree)));

    if (options.sourceMap && options.sourceMapComment) {
      printer.emit('\n//# sourceMappingURL=${unit.name}.js.map\n');
    }

    return new Tuple2(printer.getText(), sourceMap?.build(unit.name + '.js'));
  }

  JS.Program _emitModule(List<CompilationUnit> compilationUnits) {
    if (_moduleItems.isNotEmpty) {
      throw new StateError('Can only call emitModule once.');
    }

    // Transform the AST to make coercions explicit.
    compilationUnits = CoercionReifier.reify(compilationUnits);

    // Initialize our library variables.
    var items = <JS.ModuleItem>[];
    for (var unit in compilationUnits) {
      var library = unit.element.library;
      if (unit.element != library.definingCompilationUnit) continue;

      var libraryTemp = _isDartRuntime(library)
          ? _runtimeLibVar
          : new JS.TemporaryId(jsLibraryName(_buildRoot, library));
      _libraries[library] = libraryTemp;
      items.add(new JS.ExportDeclaration(
          js.call('const # = Object.create(null)', [libraryTemp])));

      // dart:_runtime has a magic module that holds extenstion method symbols.
      // TODO(jmesserly): find a cleaner design for this.
      if (_isDartRuntime(library)) {
        items.add(new JS.ExportDeclaration(
            js.call('const # = Object.create(null)', [_dartxVar])));
      }
    }

    // Collect all Element -> Node mappings, in case we need to forward declare
    // any nodes.
    var nodes = new HashMap<Element, AstNode>.identity();
    compilationUnits.map(_collectElements).forEach(nodes.addAll);
    _loader = new ElementLoader(_emitModuleItem, nodes);

    // Add implicit dart:core dependency so it is first.
    emitLibraryName(dartCoreLibrary);

    // Visit each compilation unit and emit its code.
    //
    // NOTE: declarations are not necessarily emitted in this order.
    // Order will be changed as needed so the resulting code can execute.
    // This is done by forward declaring items.
    compilationUnits.forEach(visitCompilationUnit);

    // Declare imports
    _finishImports(items);

    // Add the module's code (produced by visiting compilation units, above)
    _copyAndFlattenBlocks(items, _moduleItems);

    // Build the module.
    var module = new JS.Program(items, name: _buildUnit.name);

    // Optional: lower module format. Otherwise just return it.
    switch (options.moduleFormat) {
      case ModuleFormat.legacy:
        return new LegacyModuleBuilder().build(module);
      case ModuleFormat.node:
        return new NodeModuleBuilder().build(module);
      case ModuleFormat.es6:
        return module;
    }
  }

  /// Flattens blocks in [items] to a single list.
  ///
  /// This will not flatten blocks that are marked as being scopes.
  void _copyAndFlattenBlocks(
      List<JS.ModuleItem> result, Iterable<JS.ModuleItem> items) {
    for (var item in items) {
      if (item is JS.Block && !item.isScope) {
        _copyAndFlattenBlocks(result, item.statements);
      } else {
        result.add(item);
      }
    }
  }

  String _libraryToModule(LibraryElement library) {
    assert(!_libraries.containsKey(library));
    var source = library.source;
    // TODO(jmesserly): we need to split out HTML.
    if (source.uri.scheme == 'dart') {
      return 'dart_sdk';
    }
    var moduleName = _buildUnit.libraryToModule(source);
    if (moduleName == null) {
      throw new StateError('Could not find module containing "$library".');
    }
    return moduleName;
  }

  void _finishImports(List<JS.ModuleItem> items) {
    var modules = new Map<String, List<LibraryElement>>();

    for (var import in _imports.keys) {
      modules.putIfAbsent(_libraryToModule(import), () => []).add(import);
    }

    String coreModuleName;
    if (!_libraries.containsKey(dartCoreLibrary)) {
      coreModuleName = _libraryToModule(dartCoreLibrary);
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
          libraries.map((l) => new JS.NameSpecifier(_imports[l])).toList();
      if (module == coreModuleName) {
        imports.add(new JS.NameSpecifier(_runtimeLibVar));
        imports.add(new JS.NameSpecifier(_dartxVar));
      }
      items.add(new JS.ImportDeclaration(
          namedImports: imports, from: js.string(module, "'")));
    });
  }

  /// Collect toplevel elements and nodes we need to emit, and returns
  /// an ordered map of these.
  static Map<Element, AstNode> _collectElements(CompilationUnit unit) {
    var map = <Element, AstNode>{};
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (var field in declaration.variables.variables) {
          map[field.element] = field;
        }
      } else {
        map[declaration.element] = declaration;
      }
    }
    return map;
  }

  void _emitModuleItem(AstNode node) {
    // TODO(jmesserly): ideally we could do this at a smaller granularity.
    // We'll need to be consistent about when we're generating functions, and
    // only run this on the outermost function.
    inferNullableTypes(node);

    var code = _visit(node);
    if (code != null) _moduleItems.add(code);
  }

  @override
  void visitCompilationUnit(CompilationUnit unit) {
    _constField = new ConstFieldVisitor(types, unit.element.source);

    for (var declaration in unit.declarations) {
      var element = declaration.element;
      if (element != null) {
        _loader.emitDeclaration(element);
      } else {
        declaration.accept(this);
      }
    }
    for (var directive in unit.directives) {
      directive.accept(this);
    }
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {}

  @override
  void visitImportDirective(ImportDirective node) {
    // We don't handle imports here.
    //
    // Instead, we collect imports whenever we need to generate a reference
    // to another library. This has the effect of collecting the actually used
    // imports.
    //
    // TODO(jmesserly): if this is a prefixed import, consider adding the prefix
    // as an alias?
  }

  @override
  void visitPartDirective(PartDirective node) {}

  @override
  void visitPartOfDirective(PartOfDirective node) {}

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement element = node.element;
    var currentLibrary = element.library;

    var currentNames = currentLibrary.publicNamespace.definedNames;
    var exportedNames =
        new NamespaceBuilder().createExportNamespaceForDirective(element);

    var libraryName = emitLibraryName(currentLibrary);

    // TODO(jmesserly): we could collect all of the names for bulk re-export,
    // but this is easier to implement for now.
    void emitExport(Element export, {String suffix: ''}) {
      var name = _emitTopLevelName(export, suffix: suffix);

      if (export is TypeDefiningElement ||
          export is FunctionElement ||
          _eagerTopLevelFields.contains(export)) {
        // classes, typedefs, functions, and eager init fields can be assigned
        // directly.
        // TODO(jmesserly): we don't know about eager init fields from other
        // modules we import, so we will never go down this code path for them.
        _moduleItems
            .add(js.statement('#.# = #;', [libraryName, name.selector, name]));
      } else {
        // top-level fields, getters, setters need to copy the property
        // descriptor.
        _moduleItems.add(js.statement('dart.export(#, #, #);',
            [libraryName, name.receiver, name.selector]));
      }
    }

    for (var export in exportedNames.definedNames.values) {
      if (export is PropertyAccessorElement) {
        export = (export as PropertyAccessorElement).variable;
      }

      // Don't allow redefining names from this library.
      if (currentNames.containsKey(export.name)) continue;

      _loader.emitDeclaration(export);
      if (export is ClassElement && export.typeParameters.isNotEmpty) {
        // Export the generic name as well.
        // TODO(jmesserly): revisit generic classes
        emitExport(export, suffix: r'$');
      }
      emitExport(export);
    }
  }

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
      if (from != types.intType && to == types.intType) {
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
    if (t == types.stringType) return 'string';
    if (t == types.boolType) return 'boolean';
    return null;
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement element = node.element;

    JS.Expression body = annotate(
        js.call('dart.typedef(#, () => #)', [
          js.string(element.name, "'"),
          _emitTypeName(element.type, lowerTypedef: true)
        ]),
        node,
        element);

    var typeFormals = element.typeParameters;
    if (typeFormals.isNotEmpty) {
      return _defineClassTypeArguments(element, typeFormals,
          js.statement('const # = #;', [element.name, body]));
    } else {
      return js.statement('# = #;', [_emitTopLevelName(element), body]);
    }
  }

  @override
  JS.Expression visitTypeName(TypeName node) {
    // TODO(jmesserly): should only happen for erroneous code.
    if (node.type == null) return js.call('dart.dynamic');
    return _emitTypeName(node.type);
  }

  @override
  JS.Statement visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement element = node.element;

    // Forward all generative constructors from the base class.
    var methods = <JS.Method>[];

    var supertype = element.supertype;
    if (!supertype.isObject) {
      for (var ctor in element.constructors) {
        var parentCtor = supertype.lookUpConstructor(ctor.name, ctor.library);
        var fun = js.call('function() { super.#(...arguments); }',
            [_constructorName(parentCtor)]) as JS.Fun;
        methods.add(new JS.Method(_constructorName(ctor), fun));
      }
    }

    var classExpr = _emitClassExpression(element, methods);

    var typeFormals = element.typeParameters;
    if (typeFormals.isNotEmpty) {
      return _defineClassTypeArguments(
          element, typeFormals, new JS.ClassDeclaration(classExpr));
    } else {
      return js.statement('# = #;', [_emitTopLevelName(element), classExpr]);
    }
  }

  JS.Statement _emitJsType(Element e) {
    var jsTypeName = getAnnotationName(e, isJSAnnotation);
    if (jsTypeName == null || jsTypeName == e.name) return null;

    // We export the JS type as if it was a Dart type. For example this allows
    // `dom.InputElement` to actually be HTMLInputElement.
    // TODO(jmesserly): if we had the JS name on the Element, we could just
    // generate it correctly when we refer to it.
    return js.statement('# = #;', [_emitTopLevelName(e), jsTypeName]);
  }

  @override
  JS.Statement visitClassDeclaration(ClassDeclaration node) {
    var classElem = node.element;

    // If this is a JavaScript type, emit it now and then exit.
    var jsTypeDef = _emitJsType(classElem);
    if (jsTypeDef != null) return jsTypeDef;

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

    JS.Expression className;
    if (classElem.typeParameters.isNotEmpty) {
      // Generic classes will be defined inside a function that closes over the
      // type parameter. So we can use their local variable name directly.
      className = new JS.Identifier(classElem.name);
    } else {
      className = _emitTopLevelName(classElem);
    }

    var allFields = new List.from(fields)..addAll(staticFields);
    var superclasses = getSuperclasses(classElem);
    var virtualFields = <FieldElement, JS.TemporaryId>{};
    var virtualFieldSymbols = <JS.Statement>[];
    var staticFieldOverrides = new HashSet<FieldElement>();
    _registerPropertyOverrides(classElem, className, superclasses, allFields,
        virtualFields, virtualFieldSymbols, staticFieldOverrides);

    var classExpr = _emitClassExpression(classElem,
        _emitClassMethods(node, ctors, fields, superclasses, virtualFields),
        fields: allFields);

    var body = <JS.Statement>[];
    var extensions = _extensionsToImplement(classElem);
    _initExtensionSymbols(classElem, methods, fields, body);

    // Emit the class, e.g. `core.Object = class Object { ... }`
    _defineClass(classElem, className, classExpr, body);

    // Emit things that come after the ES6 `class ... { ... }`.
    _setBaseClass(classElem, className, body);
    _defineNamedConstructors(ctors, body, className);
    _emitVirtualFieldSymbols(virtualFieldSymbols, body);
    _emitClassSignature(methods, classElem, ctors, extensions, className, body);
    _defineExtensionMembers(extensions, className, body);
    _emitClassMetadata(node.metadata, className, body);

    JS.Statement classDef = _statement(body);
    var typeFormals = classElem.typeParameters;
    if (typeFormals.isNotEmpty) {
      classDef = _defineClassTypeArguments(classElem, typeFormals, classDef);
    }

    body = <JS.Statement>[classDef];
    _emitStaticFields(staticFields, staticFieldOverrides, classElem, body);
    _registerExtensionType(classElem, body);
    return _statement(body);
  }

  void _registerPropertyOverrides(
      ClassElement classElem,
      JS.Expression className,
      List<ClassElement> superclasses,
      List<FieldDeclaration> fields,
      Map<FieldElement, JS.TemporaryId> virtualFields,
      List<JS.Statement> virtualFieldSymbols,
      Set<FieldElement> staticFieldOverrides) {
    for (var field in fields) {
      for (VariableDeclaration field in field.fields.variables) {
        var overrideInfo = checkForPropertyOverride(
            field.element, superclasses, _extensionTypes);
        if (overrideInfo.foundGetter || overrideInfo.foundSetter) {
          if (field.element.isStatic) {
            staticFieldOverrides.add(field.element);
          } else {
            var fieldName =
                _emitMemberName(field.element.name, type: classElem.type);
            var virtualField = new JS.TemporaryId(field.element.name);
            virtualFields[field.element] = virtualField;
            virtualFieldSymbols.add(js.statement(
                'const # = Symbol(#.name + "." + #.toString());',
                [virtualField, className, fieldName]));
          }
        }
      }
    }
  }

  void _defineClass(ClassElement classElem, JS.Expression className,
      JS.ClassExpression classExpr, List<JS.Statement> body) {
    if (classElem.typeParameters.isNotEmpty) {
      body.add(new JS.ClassDeclaration(classExpr));
    } else {
      body.add(js.statement('# = #;', [className, classExpr]));
    }
  }

  void _emitVirtualFieldSymbols(
      List<JS.Statement> virtualFields, List<JS.Statement> body) {
    body.addAll(virtualFields);
  }

  List<JS.Identifier> _emitTypeFormals(List<TypeParameterElement> typeFormals) {
    return typeFormals
        .map((t) => new JS.Identifier(t.name))
        .toList(growable: false);
  }

  /// Emits a field declaration for TypeScript & Closure's ES6_TYPED
  /// (e.g. `class Foo { i: string; }`)
  JS.VariableDeclarationList _emitTypeScriptField(FieldDeclaration field) {
    return new JS.VariableDeclarationList(
        field.isStatic ? 'static' : null,
        field.fields.variables
            .map((decl) => new JS.VariableInitialization(
                new JS.Identifier(
                    // TODO(ochafik): use a refactored _emitMemberName instead.
                    decl.name.name,
                    type: emitTypeRef(decl.element.type)),
                null))
            .toList(growable: false));
  }

  @override
  JS.Statement visitEnumDeclaration(EnumDeclaration node) {
    var element = node.element;
    var type = element.type;
    var name = js.string(type.name);

    // Generate a class per section 13 of the spec.
    // TODO(vsm): Generate any accompanying metadata

    // Create constructor and initialize index
    var constructor = new JS.Method(
        name, js.call('function(index) { this.index = index; }') as JS.Fun);
    var fields = new List<FieldElement>.from(
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
    var classExpr = new JS.ClassExpression(new JS.Identifier(type.name),
        _emitClassHeritage(element), [constructor, toStringF]);
    var id = _emitTopLevelName(element);
    var result = [
      js.statement('# = #', [id, classExpr])
    ];

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

    return _statement(result);
  }

  /// Wraps a possibly generic class in its type arguments.
  JS.Statement _defineClassTypeArguments(TypeDefiningElement element,
      List<TypeParameterElement> formals, JS.Statement body) {
    assert(formals.isNotEmpty);
    var genericDef =
        js.statement('# = dart.generic((#) => { #; return #; });', [
      _emitTopLevelName(element, suffix: r'$'),
      _emitTypeFormals(formals),
      body,
      element.name
    ]);

    var dynType = fillDynamicTypeArgs(element.type);
    var genericInst = _emitTypeName(dynType, lowerGeneric: true);
    return js.statement(
        '{ #; # = #; }', [genericDef, _emitTopLevelName(element), genericInst]);
  }

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

  JS.ClassExpression _emitClassExpression(
      ClassElement element, List<JS.Method> methods,
      {List<FieldDeclaration> fields}) {
    String name = element.name;
    var heritage = _emitClassHeritage(element);
    var typeParams = _emitTypeFormals(element.typeParameters);
    var jsFields = fields?.map(_emitTypeScriptField)?.toList();

    return new JS.ClassExpression(new JS.Identifier(name), heritage, methods,
        typeParams: typeParams, fields: jsFields);
  }

  JS.Expression _emitClassHeritage(ClassElement element) {
    var type = element.type;
    if (type.isObject) return null;

    _loader.startTopLevel(element);

    // Find the super type
    JS.Expression heritage;
    var supertype = type.superclass;
    if (_deferIfNeeded(supertype, element)) {
      // Fall back to raw type.
      supertype = fillDynamicTypeArgs(supertype.element.type);
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
        var field = decl.element;
        var name = getAnnotationName(field, isJsName) ?? field.name;
        // Generate getter
        var fn = new JS.Fun([], js.statement('{ return this.#; }', [name]));
        var method =
            new JS.Method(_elementMemberName(field.getter), fn, isGetter: true);
        jsMethods.add(method);

        // Generate setter
        if (!decl.isFinal) {
          var value = new JS.TemporaryId('value');
          fn = new JS.Fun(
              [value], js.statement('{ this.# = #; }', [name, value]));
          method = new JS.Method(_elementMemberName(field.setter), fn,
              isSetter: true);
          jsMethods.add(method);
        }
      }
    }
    return jsMethods;
  }

  List<JS.Method> _emitClassMethods(
      ClassDeclaration node,
      List<ConstructorDeclaration> ctors,
      List<FieldDeclaration> fields,
      List<ClassElement> superclasses,
      Map<FieldElement, JS.TemporaryId> virtualFields) {
    var element = node.element;
    var type = element.type;
    var isObject = type.isObject;

    // Iff no constructor is specified for a class C, it implicitly has a
    // default constructor `C() : super() {}`, unless C is class Object.
    var jsMethods = <JS.Method>[];
    if (ctors.isEmpty && !isObject) {
      jsMethods.add(_emitImplicitConstructor(node, fields, virtualFields));
    }

    bool hasJsPeer = findAnnotation(element, isJsPeerInterface) != null;

    bool hasIterator = false;
    for (var m in node.members) {
      if (m is ConstructorDeclaration) {
        jsMethods
            .add(_emitConstructor(m, type, fields, virtualFields, isObject));
      } else if (m is MethodDeclaration) {
        jsMethods.add(_emitMethodDeclaration(type, m));

        if (m.element is PropertyAccessorElement) {
          jsMethods.add(_emitSuperAccessorWrapper(m, type, superclasses));
        }

        if (!hasJsPeer && m.isGetter && m.name.name == 'iterator') {
          hasIterator = true;
          jsMethods.add(_emitIterable(type));
        }
      } else if (m is FieldDeclaration) {
        if (_extensionTypes.contains(element)) {
          jsMethods.addAll(_emitNativeFieldAccessors(m));
          continue;
        }
        if (m.isStatic) continue;
        for (VariableDeclaration field in m.fields.variables) {
          if (virtualFields.containsKey(field.element)) {
            jsMethods.addAll(_emitVirtualFieldAccessor(field, virtualFields));
          }
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

  /// This is called whenever a derived class needs to introduce a new field,
  /// shadowing a field or getter/setter pair on its parent.
  ///
  /// This is important because otherwise, trying to read or write the field
  /// would end up calling the getter or setter, and one of those might not even
  /// exist, resulting in a runtime error. Even if they did exist, that's the
  /// wrong behavior if a new field was declared.
  List<JS.Method> _emitVirtualFieldAccessor(VariableDeclaration field,
      Map<FieldElement, JS.TemporaryId> virtualFields) {
    var virtualField = virtualFields[field.element];
    var result = <JS.Method>[];
    var name = _emitMemberName(field.element.name,
        type: (field.element.enclosingElement as ClassElement).type);
    var getter = js.call('function() { return this[#]; }', [virtualField]);
    result.add(new JS.Method(name, getter, isGetter: true));

    if (field.isFinal) {
      var setter = js.call('function(value) { super[#] = value; }', [name]);
      result.add(new JS.Method(name, setter, isSetter: true));
    } else {
      var setter =
          js.call('function(value) { this[#] = value; }', [virtualField]);
      result.add(new JS.Method(name, setter, isSetter: true));
    }

    return result;
  }

  /// Emit a getter or setter that simply forwards to the superclass getter or
  /// setter. This is needed because in ES6, if you only override a getter
  /// (alternatively, a setter), then there is an implicit override of the
  /// setter (alternatively, the getter) that does nothing.
  JS.Method _emitSuperAccessorWrapper(MethodDeclaration method,
      InterfaceType type, List<ClassElement> superclasses) {
    var methodElement = method.element as PropertyAccessorElement;
    var field = methodElement.variable;
    if (!field.isSynthetic) return null;
    var propertyOverrideResult = checkForPropertyOverride(
        methodElement.variable, superclasses, _extensionTypes);

    // Generate a corresponding virtual getter / setter.
    var name = _elementMemberName(methodElement,
        allowExtensions: _extensionTypes.contains(type.element));
    if (method.isGetter) {
      // Generate a setter
      if (field.setter != null || !propertyOverrideResult.foundSetter)
        return null;
      var fn = js.call('function(value) { super[#] = value; }', [name]);
      return new JS.Method(name, fn, isSetter: true);
    } else {
      // Generate a getter
      if (field.getter != null || !propertyOverrideResult.foundGetter)
        return null;
      var fn = js.call('function() { return super[#]; }', [name]);
      return new JS.Method(name, fn, isGetter: true);
    }
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
        js.call('Symbol.iterator'),
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

  /// Gets the JS peer for this Dart type if any, otherwise null.
  ///
  /// For example for dart:_interceptors `JSArray` this will return "Array",
  /// referring to the JavaScript built-in `Array` type.
  String _getJSPeerName(ClassElement classElem) {
    var jsPeerName = getAnnotationName(
        classElem,
        (a) =>
            isJsPeerInterface(a) ||
            isNativeAnnotation(a) && _extensionTypes.contains(classElem));
    if (jsPeerName != null && jsPeerName.contains(',')) {
      jsPeerName = jsPeerName.split(',')[0];
    }
    return jsPeerName;
  }

  void _registerExtensionType(ClassElement classElem, List<JS.Statement> body) {
    var jsPeerName = _getJSPeerName(classElem);
    if (jsPeerName != null) {
      // TODO(jmesserly): this copies the dynamic members.
      // Probably fine for objects coming from JS, but not if we actually
      // want to support construction of instances with generic types other
      // than dynamic. See issue #154 for Array and List<E> related bug.
      body.add(js.statement('dart.registerExtension(dart.global.#, #);',
          [_propertyName(jsPeerName), _emitTopLevelName(classElem)]));
    }
  }

  void _setBaseClass(ClassElement classElem, JS.Expression className,
      List<JS.Statement> body) {
    String jsPeerName = _getJSPeerName(classElem);
    JS.Expression newBaseClass;
    if (jsPeerName != null && classElem.typeParameters.isNotEmpty) {
      // TODO(jmesserly): we should really just extend Array in the first place.
      newBaseClass = js.call('dart.global.#', [jsPeerName]);
    } else if (_hasDeferredSupertype.contains(classElem)) {
      newBaseClass = _emitTypeName(classElem.type.superclass);
    }
    if (newBaseClass != null) {
      body.add(
          js.statement('dart.setBaseClass(#, #);', [className, newBaseClass]));
    }
  }

  void _defineNamedConstructors(List<ConstructorDeclaration> ctors,
      List<JS.Statement> body, JS.Expression className) {
    for (ConstructorDeclaration member in ctors) {
      if (member.name != null && member.factoryKeyword == null) {
        body.add(js.statement('dart.defineNamedConstructor(#, #);',
            [className, _emitMemberName(member.name.name, isStatic: true)]));
      }
    }
  }

  /// Emits static fields for a class, and initialize them eagerly if possible,
  /// otherwise define them as lazy properties.
  void _emitStaticFields(
      List<FieldDeclaration> staticFields,
      Set<FieldElement> staticFieldOverrides,
      ClassElement classElem,
      List<JS.Statement> body) {
    var lazyStatics = <VariableDeclaration>[];
    for (FieldDeclaration member in staticFields) {
      for (VariableDeclaration field in member.fields.variables) {
        JS.Statement eagerField =
            _emitConstantStaticField(classElem, field, staticFieldOverrides);
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
  }

  void _emitClassMetadata(List<Annotation> metadata, JS.Expression className,
      List<JS.Statement> body) {
    // TODO(vsm): Make this optional per #268.
    // Metadata
    if (metadata.isNotEmpty) {
      body.add(js.statement('#[dart.metadata] = () => #;', [
        className,
        new JS.ArrayInitializer(
            new List<JS.Expression>.from(metadata.map(_instantiateAnnotation)))
      ]));
    }
  }

  /// If a concrete class implements one of our extensions, we might need to
  /// add forwarders.
  void _defineExtensionMembers(List<ExecutableElement> extensions,
      JS.Expression className, List<JS.Statement> body) {
    // If a concrete class implements one of our extensions, we might need to
    // add forwarders.
    if (extensions.isNotEmpty) {
      var methodNames = <JS.Expression>[];
      for (var e in extensions) {
        methodNames.add(_elementMemberName(e));
      }
      body.add(js.statement('dart.defineExtensionMembers(#, #);', [
        className,
        new JS.ArrayInitializer(methodNames, multiline: methodNames.length > 4)
      ]));
    }
  }

  /// Emit the signature on the class recording the runtime type information
  void _emitClassSignature(
      List<MethodDeclaration> methods,
      ClassElement classElem,
      List<ConstructorDeclaration> ctors,
      List<ExecutableElement> extensions,
      JS.Expression className,
      List<JS.Statement> body) {
    if (classElem.interfaces.isNotEmpty) {
      body.add(js.statement('#[dart.implements] = () => #;', [
        className,
        new JS.ArrayInitializer(new List<JS.Expression>.from(
            classElem.interfaces.map(_emitTypeName)))
      ]));
    }

    var tStatics = <JS.Property>[];
    var tMethods = <JS.Property>[];
    var sNames = <JS.Expression>[];
    for (MethodDeclaration node in methods) {
      if (!(node.isSetter || node.isGetter || node.isAbstract)) {
        var name = node.name.name;
        var element = node.element;
        var inheritedElement =
            classElem.lookUpInheritedConcreteMethod(name, currentLibrary);
        if (inheritedElement != null && inheritedElement.type == element.type) {
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
      var parts = _emitFunctionTypeParts(element.type,
          parameters: node.parameters.parameters);
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
      body.add(js.statement('dart.setSignature(#, #);', [className, sig]));
    }
  }

  /// Ensure `dartx.` symbols we will use are present.
  void _initExtensionSymbols(
      ClassElement classElem,
      List<MethodDeclaration> methods,
      List<FieldDeclaration> fields,
      List<JS.Statement> body) {
    if (_extensionTypes.contains(classElem)) {
      var dartxNames = <JS.Expression>[];
      for (var m in methods) {
        if (!m.isAbstract && !m.isStatic && m.element.isPublic) {
          dartxNames.add(_elementMemberName(m.element, allowExtensions: false));
        }
      }
      for (var f in fields) {
        if (!f.isStatic) {
          for (var d in f.fields.variables) {
            if (d.element.isPublic) {
              dartxNames.add(
                  _elementMemberName(d.element.getter, allowExtensions: false));
            }
          }
        }
      }
      if (dartxNames.isNotEmpty) {
        body.add(js.statement('dart.defineExtensionNames(#)',
            [new JS.ArrayInitializer(dartxNames, multiline: true)]));
      }
    }
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

  /// Generates the implicit default constructor for class C of the form
  /// `C() : super() {}`.
  JS.Method _emitImplicitConstructor(
      ClassDeclaration node,
      List<FieldDeclaration> fields,
      Map<FieldElement, JS.TemporaryId> virtualFields) {
    assert(_hasUnnamedConstructor(node.element) == fields.isNotEmpty);

    // If we don't have a method body, skip this.
    var superCall = _superConstructorCall(node.element);
    if (fields.isEmpty && superCall == null) return null;

    dynamic body = _initializeFields(node, fields, virtualFields);
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

  JS.Method _emitConstructor(
      ConstructorDeclaration node,
      InterfaceType type,
      List<FieldDeclaration> fields,
      Map<FieldElement, JS.TemporaryId> virtualFields,
      bool isObject) {
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
          visitFormalParameterList(node.parameters, destructure: false);

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
    var params = visitFormalParameterList(node.parameters);
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
      var savedFunction = _currentFunction;
      _currentFunction = node.body;
      body = _emitConstructorBody(node, fields, virtualFields);
      _currentFunction = savedFunction;
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
      ConstructorDeclaration node,
      List<FieldDeclaration> fields,
      Map<FieldElement, JS.TemporaryId> virtualFields) {
    var body = <JS.Statement>[];
    ClassDeclaration cls = node.parent;

    // Generate optional/named argument value assignment. These can not have
    // side effects, and may be used by the constructor's initializers, so it's
    // nice to do them first.
    // Also for const constructors we need to ensure default values are
    // available for use by top-level constant initializers.
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
    body.add(_initializeFields(cls, fields, virtualFields, node));

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
        assert(options.unsafeForceCompile);
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
      ClassDeclaration cls,
      List<FieldDeclaration> fieldDecls,
      Map<FieldElement, JS.TemporaryId> virtualFields,
      [ConstructorDeclaration ctor]) {
    bool isConst = ctor != null && ctor.constKeyword != null;
    if (isConst) _loader.startTopLevel(cls.element);

    // Run field initializers if they can have side-effects.
    var fields = new Map<FieldElement, JS.Expression>();
    var unsetFields = new Map<FieldElement, VariableDeclaration>();
    for (var declaration in fieldDecls) {
      for (var fieldNode in declaration.fields.variables) {
        var element = fieldNode.element;
        if (_constField.isFieldInitConstant(fieldNode)) {
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
          fields[element.field] = _emitSimpleIdentifier(p.identifier);
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
      if (virtualFields.containsKey(e)) {
        body.add(
            js.statement('this[#] = #;', [virtualFields[e], initialValue]));
      } else {
        var access = _emitMemberName(e.name, type: e.enclosingElement.type);
        body.add(js.statement('this.# = #;', [access, initialValue]));
      }
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
      var jsParam = _emitSimpleIdentifier(param.identifier);

      if (!options.destructureNamedParams) {
        if (param.kind == ParameterKind.NAMED) {
          // Parameters will be passed using their real names, not the (possibly
          // renamed) local variable.
          var paramName = js.string(param.identifier.name, "'");

          // TODO(ochafik): Fix `'prop' in obj` to please Closure's renaming.
          body.add(js.statement('let # = # && # in # ? #.# : #;', [
            jsParam,
            namedArgumentTemp,
            paramName,
            namedArgumentTemp,
            namedArgumentTemp,
            paramName,
            _defaultParamValue(param),
          ]));
        } else if (param.kind == ParameterKind.POSITIONAL) {
          body.add(js.statement('if (# === void 0) # = #;',
              [jsParam, jsParam, _defaultParamValue(param)]));
        }
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

  JS.Fun _emitNativeFunctionBody(MethodDeclaration node) {
    if (node.isStatic) {
      // TODO(vsm): Do we need to handle this case?
      return null;
    }

    var params = visitFormalParameterList(node.parameters, destructure: false);
    String name =
        getAnnotationName(node.element, isJSAnnotation) ?? node.name.name;
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

    JS.Fun fn;
    if (_externalOrNative(node)) {
      fn = _emitNativeFunctionBody(node);
      // TODO(vsm): Remove if / when we handle the static case above.
      if (fn == null) return null;
    } else {
      fn = _emitFunctionBody(node.element, node.parameters, node.body);

      if (node.operatorKeyword != null &&
          node.name.name == '[]=' &&
          fn.params.isNotEmpty) {
        // []= methods need to return the value. We could also address this at
        // call sites, but it's cleaner to instead transform the operator method.
        fn = _alwaysReturnLastParameter(fn);
      }

      fn = _makeGenericFunction(fn);
    }

    return annotate(
        new JS.Method(_elementMemberName(node.element), fn,
            isGetter: node.isGetter,
            isSetter: node.isSetter,
            isStatic: node.isStatic),
        node,
        node.element);
  }

  /// Transform the function so the last parameter is always returned.
  ///
  /// This is useful for indexed set methods, which otherwise would not have
  /// the right return value in JS.
  JS.Fun _alwaysReturnLastParameter(JS.Fun fn) {
    var body = fn.body;
    if (JS.Return.foundIn(fn)) {
      // If a return is inside body, transform `(params) { body }` to
      // `(params) { (() => { body })(); return value; }`.
      // TODO(jmesserly): we could instead generate the return differently,
      // and avoid the immediately invoked function.
      body = new JS.Call(new JS.ArrowFun([], fn.body), []).toStatement();
    }
    // Rewrite the function to include the return.
    return new JS.Fun(
        fn.params, new JS.Block([body, new JS.Return(fn.params.last)]),
        typeParams: fn.typeParams,
        returnType: fn.returnType)..sourceInformation = fn.sourceInformation;
  }

  @override
  JS.Statement visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.parent is CompilationUnit);

    if (_externalOrNative(node)) return null;

    if (node.isGetter || node.isSetter) {
      // If we have a getter/setter pair, they need to be defined together.
      PropertyAccessorElement element = node.element;
      var props = <JS.Method>[];
      var getter = element.variable.getter;
      if (getter != null) {
        props.add(_loader.customEmitDeclaration(getter, _emitTopLevelProperty));
      }
      var setter = element.variable.setter;
      if (setter != null) {
        props.add(_loader.customEmitDeclaration(setter, _emitTopLevelProperty));
      }

      return js.statement('dart.copyProperties(#, { # });',
          [emitLibraryName(currentLibrary), props]);
    }

    var body = <JS.Statement>[];
    var fn = _emitFunction(node.functionExpression);

    if (currentLibrary.source.isInSystemLibrary &&
        _isInlineJSFunction(node.functionExpression)) {
      fn = _simplifyPassThroughArrowFunCallBody(fn);
    }

    var element = node.element;
    var nameExpr = _emitTopLevelName(element);
    body.add(annotate(js.statement('# = #', [nameExpr, fn]), node, element));
    if (!_isDartRuntime(element.library)) {
      body.add(_emitFunctionTagged(nameExpr, element.type, topLevel: true)
          .toStatement());
    }

    return _statement(body);
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
        new JS.Method(
            _propertyName(name), _emitFunction(node.functionExpression),
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

  JS.Expression _emitFunctionTagged(JS.Expression fn, DartType type,
      {topLevel: false}) {
    var name = type.name;
    var lazy = topLevel && !_typeIsLoaded(type);

    if (type is FunctionType && (name == '' || name == null)) {
      if (type.typeFormals.isEmpty &&
          type.returnType.isDynamic &&
          type.optionalParameterTypes.isEmpty &&
          type.namedParameterTypes.isEmpty &&
          type.normalParameterTypes.every((t) => t.isDynamic)) {
        return js.call('dart.fn(#)', [fn]);
      }

      var parts = _emitFunctionTypeParts(type);
      if (lazy) {
        return js.call(
            'dart.lazyFn(#, () => #)', [fn, new JS.ArrayInitializer(parts)]);
      } else {
        return js.call('dart.fn(#, #)', [fn, parts]);
      }
    }
    throw 'Function has non function type: $type';
  }

  /// Emits an arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears and the function is actually in an Expression context. These
  /// correspond to arrow functions in Dart.
  ///
  /// Contrast with [_emitFunction].
  @override
  JS.Expression visitFunctionExpression(FunctionExpression node) {
    assert(node.parent is! FunctionDeclaration &&
        node.parent is! MethodDeclaration);
    return _emitFunctionTagged(_emitArrowFunction(node), getStaticType(node),
        topLevel: _executesAtTopLevel(node));
  }

  JS.ArrowFun _emitArrowFunction(FunctionExpression node) {
    JS.Fun f = _emitFunctionBody(node.element, node.parameters, node.body);
    var body = f.body;

    // Simplify `=> { return e; }` to `=> e`
    if (body is JS.Block) {
      JS.Block block = body;
      if (block.statements.length == 1) {
        JS.Statement s = block.statements[0];
        if (s is JS.Return) body = s.value;
      }
    }

    // Convert `function(...) { ... }` to `(...) => ...`
    // This is for readability, but it also ensures correct `this` binding.
    var fn = new JS.ArrowFun(f.params, body,
        typeParams: f.typeParams, returnType: f.returnType);

    return annotate(_makeGenericFunction(fn), node);
  }

  JS.FunctionExpression/*=T*/ _makeGenericFunction
  /*<T extends JS.FunctionExpression>*/(JS.FunctionExpression/*=T*/ fn) {
    if (fn.typeParams == null || fn.typeParams.isEmpty) return fn;

    // TODO(jmesserly): we could make these default to `dynamic`.
    var typeParams = fn.typeParams;
    if (fn is JS.ArrowFun) {
      return new JS.ArrowFun(typeParams, fn);
    }
    var f = fn as JS.Fun;
    return new JS.Fun(
        typeParams,
        new JS.Block([
          // Convert the function to an => function, to ensure `this` binding.
          new JS.Return(new JS.ArrowFun(f.params, f.body,
              typeParams: f.typeParams, returnType: f.returnType))
        ]));
  }

  /// Emits a non-arrow FunctionExpression node.
  ///
  /// This should be used for all places in Dart's AST where FunctionExpression
  /// appears but the function is not actually in an Expression context, such
  /// as methods, properties, and top-level functions.
  ///
  /// Contrast with [visitFunctionExpression].
  JS.Fun _emitFunction(FunctionExpression node) {
    var fn = _emitFunctionBody(node.element, node.parameters, node.body);
    return annotate(_makeGenericFunction(fn), node);
  }

  JS.Fun _emitFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    FunctionType type = element.type;

    // sync*, async, async*
    if (element.isAsynchronous || element.isGenerator) {
      return new JS.Fun(
          visitFormalParameterList(parameters, destructure: false),
          new JS.Block([
            _emitGeneratorFunctionBody(element, parameters, body).toReturn()
          ]),
          typeParams: _emitTypeFormals(type.typeFormals),
          returnType: emitTypeRef(type.returnType));
    }

    // normal function (sync)
    return new JS.Fun(visitFormalParameterList(parameters), _visit(body),
        typeParams: _emitTypeFormals(type.typeFormals),
        returnType: emitTypeRef(type.returnType));
  }

  JS.Expression _emitGeneratorFunctionBody(ExecutableElement element,
      FormalParameterList parameters, FunctionBody body) {
    var kind = element.isSynchronous ? 'sync' : 'async';
    if (element.isGenerator) kind += 'Star';

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
    List jsParams = visitFormalParameterList(parameters);
    if (kind == 'asyncStar') {
      _asyncStarController = new JS.TemporaryId('stream');
      jsParams.insert(0, _asyncStarController);
    } else {
      _asyncStarController = null;
    }
    // Visit the body with our async* controller set.
    var jsBody = _visit(body);
    _asyncStarController = savedController;

    DartType returnType = _getExpectedReturnType(element);
    JS.Expression gen = new JS.Fun(jsParams, jsBody,
        isGenerator: true, returnType: emitTypeRef(returnType));
    if (JS.This.foundIn(gen)) {
      gen = js.call('#.bind(this)', gen);
    }

    var T = _emitTypeName(returnType);
    return js.call('dart.#(#)', [
      kind,
      [gen, T]..addAll(visitFormalParameterList(parameters, destructure: false))
    ]);
  }

  @override
  JS.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var func = node.functionDeclaration;
    if (func.isGetter || func.isSetter) {
      return js.comment('Unimplemented function get/set statement: $node');
    }

    var fn = _emitFunction(func.functionExpression);

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

  /// Emits a simple identifier, including handling an inferred generic
  /// function instantiation.
  @override
  JS.Expression visitSimpleIdentifier(SimpleIdentifier node) {
    return _applyFunctionTypeArguments(
        _emitSimpleIdentifier(node), node.staticElement, node.staticType);
  }

  /// Emits a simple identifier, handling implicit `this` as well as
  /// going through the qualified library name if necessary, but *not* handling
  /// inferred generic function instantiation.
  JS.Expression _emitSimpleIdentifier(SimpleIdentifier node) {
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
    if (element is TypeDefiningElement) {
      var typeName = _emitTypeName(fillDynamicTypeArgs(element.type));

      // If the type is a type literal expression in Dart code, wrap the raw
      // runtime type in a "Type" instance.
      if (!_isInForeignJS &&
          node.parent is! MethodInvocation &&
          node.parent is! PrefixedIdentifier &&
          node.parent is! PropertyAccess) {
        typeName = js.call('dart.wrapType(#)', typeName);
      }

      return typeName;
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
        var dynType = _emitTypeName(fillDynamicTypeArgs(type));
        return new JS.PropertyAccess(dynType, member);
      }

      // For instance members, we add implicit-this.
      // For method tear-offs, we ensure it's a bound method.
      var tearOff = element is MethodElement && !inInvocationContext(node);
      var code = (tearOff) ? 'dart.bind(this, #)' : 'this.#';
      return js.call(code, member);
    }

    if (element is ParameterElement) {
      return _emitParameter(element);
    }

    // If this is one of our compiler's temporary variables, return its JS form.
    if (element is TemporaryVariableElement) {
      return element.jsVariable;
    }

    return new JS.Identifier(name);
  }

  JS.Identifier _emitParameter(ParameterElement element,
      {bool declaration: false}) {
    // initializing formal parameter, e.g. `Point(this._x)`
    // TODO(jmesserly): type ref is not attached in this case.
    if (element.isInitializingFormal && element.isPrivate) {
      /// Rename private names so they don't shadow the private field symbol.
      /// The renamer would handle this, but it would prefer to rename the
      /// temporary used for the private symbol. Instead rename the parameter.
      return _initializingFormalTemps.putIfAbsent(
          element, () => new JS.TemporaryId(element.name.substring(1)));
    }

    var type = declaration ? emitTypeRef(element.type) : null;
    return new JS.Identifier(element.name, type: type);
  }

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
      {List<FormalParameter> parameters, bool lowerTypedef: false}) {
    var parameterTypes = type.normalParameterTypes;
    var optionalTypes = type.optionalParameterTypes;
    var namedTypes = type.namedParameterTypes;
    var rt = _emitTypeName(type.returnType);
    var ra = _emitTypeNames(parameterTypes, parameters);

    List<JS.Expression> typeParts;
    if (namedTypes.isNotEmpty) {
      assert(optionalTypes.isEmpty);
      // TODO(vsm): Pass in annotations here as well.
      var na = _emitTypeProperties(namedTypes);
      typeParts = [rt, ra, na];
    } else if (optionalTypes.isNotEmpty) {
      assert(namedTypes.isEmpty);
      var oa = _emitTypeNames(
          optionalTypes, parameters?.sublist(parameterTypes.length));
      typeParts = [rt, ra, oa];
    } else {
      typeParts = [rt, ra];
    }

    var typeFormals = type.typeFormals;
    if (typeFormals.isNotEmpty && !lowerTypedef) {
      // TODO(jmesserly): this is a suboptimal representation for universal
      // function types (as callable functions). See discussion at:
      // https://github.com/dart-lang/dev_compiler/issues/526
      var tf = _emitTypeFormals(typeFormals);
      typeParts = [new JS.ArrowFun(tf, new JS.ArrayInitializer(typeParts))];
    }
    return typeParts;
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
      // TODO(jmesserly): should we change how typedefs work? They currently
      // go through use similar logic as generic classes. This makes them
      // different from universal function types.
      var ft = type as FunctionType;
      var parts = _emitFunctionTypeParts(ft, lowerTypedef: lowerTypedef);
      return js.call('dart.functionType(#)', [parts]);
    }

    if (type is TypeParameterType) {
      return new JS.Identifier(name);
    }

    if (type is ParameterizedType) {
      var args = type.typeArguments;
      Iterable jsArgs = null;
      if (args.any((a) => !a.isDynamic)) {
        jsArgs = args.map(_emitTypeName);
      } else if (lowerGeneric) {
        jsArgs = [];
      }
      if (jsArgs != null) {
        var genericName = _emitTopLevelName(element, suffix: '\$');
        return js.call('#(#)', [genericName, jsArgs]);
      }
    }

    return _emitTopLevelName(element);
  }

  JS.PropertyAccess _emitTopLevelName(Element e, {String suffix: ''}) {
    String name = getJSExportName(e) + suffix;
    return new JS.PropertyAccess(
        emitLibraryName(e.library), _propertyName(name));
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
      var vars = <JS.MetaLetVariable, JS.Expression>{};
      var x = _bindLeftHandSide(vars, left, context: left);
      // Capture the result of evaluating the left hand side in a temp.
      var t = _bindValue(vars, 't', x, context: x);
      return new JS.MetaLet(vars, [
        js.call('# == null ? # : #', [_visit(t), _emitSet(x, right), _visit(t)])
      ]);
    }

    // Desugar `x += y` as `x = x + y`, ensuring that if `x` has subexpressions
    // (for example, x is IndexExpression) we evaluate those once.
    var vars = <JS.MetaLetVariable, JS.Expression>{};
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
      return js.call('dart.dput(#, #, #)',
          [_visit(target), _emitMemberName(id.name), _visit(rhs)]);
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
    var vars = <JS.MetaLetVariable, JS.Expression>{};
    var left = _bindValue(vars, 'l', node.target);
    var body = js.call('# == null ? null : #',
        [_visit(left), _emitSet(_stripNullAwareOp(node, left), right)]);
    return new JS.MetaLet(vars, [body]);
  }

  @override
  JS.Block visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var savedFunction = _currentFunction;
    _currentFunction = node;
    var initArgs = _emitArgumentInitializers(node.parent);
    var ret = new JS.Return(_visit(node.expression));
    _currentFunction = savedFunction;
    return new JS.Block(initArgs != null ? [initArgs, ret] : [ret]);
  }

  @override
  JS.Block visitEmptyFunctionBody(EmptyFunctionBody node) => new JS.Block([]);

  @override
  JS.Block visitBlockFunctionBody(BlockFunctionBody node) {
    var savedFunction = _currentFunction;
    _currentFunction = node;
    var initArgs = _emitArgumentInitializers(node.parent);
    var stmts = _visitList(node.block.statements) as List<JS.Statement>;
    if (initArgs != null) stmts.insert(0, initArgs);
    _currentFunction = savedFunction;
    return new JS.Block(stmts);
  }

  @override
  JS.Block visitBlock(Block node) =>
      new JS.Block(_visitList(node.statements) as List<JS.Statement>,
          isScope: true);

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.operator?.lexeme == '?.') {
      return _emitNullSafe(node);
    }

    var result = _emitForeignJS(node);
    if (result != null) return result;

    var target = _getTarget(node);
    if (target == null || isLibraryPrefix(target)) {
      return _emitFunctionCall(node);
    }

    return _emitMethodCall(target, node);
  }

  /// Emits a (possibly generic) instance method call.
  JS.Expression _emitMethodCall(Expression target, MethodInvocation node) {
    var type = getStaticType(target);
    var name = node.methodName.name;
    var element = node.methodName.staticElement;
    bool isStatic = element is ExecutableElement && element.isStatic;
    var memberName = _emitMemberName(name, type: type, isStatic: isStatic);

    JS.Expression jsTarget = _visit(target);
    var typeArgs = _emitInvokeTypeArguments(node);
    List<JS.Expression> args = _visit(node.argumentList);
    if (DynamicInvoke.get(target)) {
      if (typeArgs != null) {
        return js.call('dart.dgsend(#, #, #, #)',
            [jsTarget, new JS.ArrayInitializer(typeArgs), memberName, args]);
      } else {
        return js.call('dart.dsend(#, #, #)', [jsTarget, memberName, args]);
      }
    }
    if (_isObjectMemberCall(target, name)) {
      // Object methods require a helper for null checks & native types.
      assert(typeArgs == null); // Object methods don't take type args.
      return js.call('dart.#(#, #)', [memberName, jsTarget, args]);
    }

    jsTarget = new JS.PropertyAccess(jsTarget, memberName);
    if (typeArgs != null) jsTarget = new JS.Call(jsTarget, typeArgs);

    if (DynamicInvoke.get(node.methodName)) {
      // This is a dynamic call to a statically known target. For example:
      //     class Foo { Function bar; }
      //     new Foo().bar(); // dynamic call
      return js.call('dart.dcall(#, #)', [jsTarget, args]);
    }

    return new JS.Call(jsTarget, args);
  }

  /// Emits a function call, to a top-level function, local function, or
  /// an expression.
  JS.Expression _emitFunctionCall(InvocationExpression node) {
    var fn = _visit(node.function);
    var args = _visit(node.argumentList);
    if (DynamicInvoke.get(node.function)) {
      var typeArgs = _emitInvokeTypeArguments(node);
      if (typeArgs != null) {
        return js.call('dart.dgcall(#, #, #)',
            [fn, new JS.ArrayInitializer(typeArgs), args]);
      } else {
        return js.call('dart.dcall(#, #)', [fn, args]);
      }
    } else {
      return new JS.Call(_applyInvokeTypeArguments(fn, node), args);
    }
  }

  JS.Expression _applyInvokeTypeArguments(
      JS.Expression target, InvocationExpression node) {
    var typeArgs = _emitInvokeTypeArguments(node);
    if (typeArgs == null) return target;
    return new JS.Call(target, typeArgs);
  }

  List<JS.Expression> _emitInvokeTypeArguments(InvocationExpression node) {
    return _emitFunctionTypeArguments(
        node.function.staticType, node.staticInvokeType, node.typeArguments);
  }

  /// If `g` is a generic function type, and `f` is an instantiation of it,
  /// then this will return the type arguments to apply, otherwise null.
  List<JS.Expression> _emitFunctionTypeArguments(DartType g, DartType f,
      [TypeArgumentList typeArgs]) {
    if (g is FunctionType &&
        g.typeFormals.isNotEmpty &&
        f is FunctionType &&
        f.typeFormals.isEmpty) {
      return _recoverTypeArguments(g, f)
          .map(_emitTypeName)
          .toList(growable: false);
    } else if (typeArgs != null) {
      // Dynamic calls may have type arguments, even though the function types
      // are not known.
      // TODO(jmesserly): seems to be mostly broken in Analyzer at the moment:
      // https://github.com/dart-lang/sdk/issues/26368
      return typeArgs.arguments.map(visitTypeName).toList(growable: false);
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
    assert(identical(g.element, f.element));
    assert(g.typeFormals.isNotEmpty && f.typeFormals.isEmpty);
    assert(g.typeFormals.length + g.typeArguments.length ==
        f.typeArguments.length);

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
    return f.typeArguments.skip(g.typeArguments.length);
  }

  /// Emits code for the `JS(...)` macro.
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

      // TODO(rnystrom): The JS() calls are almost never nested, and probably
      // really shouldn't be, but there are at least a couple of calls in the
      // HTML library where an argument to JS() is itself a JS() call. If those
      // go away, this can just assert(!_isInForeignJS).
      // Inside JS(), type names evaluate to the raw runtime type, not the
      // wrapped Type object.
      var wasInForeignJS = _isInForeignJS;
      _isInForeignJS = true;

      var template = js.parseForeignJS(source);
      var result = template.instantiate(_visitList(templateArgs));

      _isInForeignJS = wasInForeignJS;

      // `throw` is emitted as a statement by `parseForeignJS`.
      assert(result is JS.Expression || node.parent is ExpressionStatement);
      return result;
    }
    return null;
  }

  @override
  JS.Expression visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      _emitFunctionCall(node);

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

  @override
  List<JS.Parameter> visitFormalParameterList(FormalParameterList node,
      {bool destructure: true}) {
    if (node == null) return [];

    destructure = destructure && options.destructureNamedParams;

    var result = <JS.Parameter>[];
    var namedVars = <JS.DestructuredVariable>[];
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
          if (JS.invalidVariableName(paramName)) {
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
        result.add(param is DefaultFormalParameter && destructure
            ? new JS.DestructuredVariable(
                name: jsParam, defaultValue: _defaultParamValue(param))
            : jsParam);
      }
    }

    if (needsOpts) {
      result.add(namedArgumentTemp);
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
    for (var variable in node.variables.variables) {
      _loader.emitDeclaration(variable.element);
    }
  }

  /// This is not used--we emit fields as we are emitting the class,
  /// see [visitClassDeclaration].
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    assert(false);
  }

  @override
  JS.Statement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    // Special case a single variable with an initializer.
    // This helps emit cleaner code for things like:
    //     var result = []..add(1)..add(2);
    var variables = node.variables.variables;
    if (variables.length == 1) {
      var v = variables[0];
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
  JS.Statement _emitConstantStaticField(ClassElement classElem,
      VariableDeclaration field, Set<FieldElement> staticFieldOverrides) {
    PropertyInducingElement element = field.element;
    assert(element.isStatic);

    _loader.startCheckingReferences();
    JS.Expression jsInit = _visitInitializer(field);
    bool isLoaded = _loader.finishCheckingReferences();

    bool eagerInit =
        isLoaded && (field.isConst || _constField.isFieldInitConstant(field));

    var fieldName = field.name.name;
    if (eagerInit &&
        !JS.invalidStaticFieldName(fieldName) &&
        !staticFieldOverrides.contains(element)) {
      return annotate(
          js.statement('#.# = #;', [
            _emitTopLevelName(classElem),
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
  JS.ModuleItem _emitTopLevelField(VariableDeclaration field) {
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
    // TODO(jmesserly): we don't track dependencies correctly for these.
    var isJSTopLevel = field.isFinal && _isFinalJSDecl(field);
    if (eagerInit || isJSTopLevel) {
      // Remember that we emitted it this way, so re-export can take advantage
      // of this fact.
      _eagerTopLevelFields.add(element);

      return annotate(
          js.statement('# = #;', [_emitTopLevelName(element), jsInit]),
          field,
          element);
    }

    assert(element.library == currentLibrary);
    return _emitLazyFields(element.library, [field]);
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
      objExpr = _emitTopLevelName(target);
    } else {
      objExpr = emitLibraryName(target);
    }

    return js.statement('dart.defineLazy(#, { # });', [objExpr, methods]);
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
  bool isPrimitiveType(DartType t) =>
      typeIsPrimitiveInJS(t) || t == types.stringType;

  bool typeIsPrimitiveInJS(DartType t) =>
      _isNumberInJS(t) || t == types.boolType;

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) =>
      typeIsPrimitiveInJS(leftT) && typeIsPrimitiveInJS(rightT);

  bool unaryOperationIsPrimitive(DartType t) => typeIsPrimitiveInJS(t);

  JS.Expression notNull(Expression expr) {
    if (expr == null) return null;
    var jsExpr = _visit(expr);
    if (!isNullable(expr)) return jsExpr;
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
      if (!isNullable(left)) return _visit(left);

      var vars = <JS.MetaLetVariable, JS.Expression>{};
      // Desugar `l ?? r` as `l != null ? l : r`
      var l = _visit(_bindValue(vars, 'l', left, context: left));
      return new JS.MetaLet(vars, [
        js.call('# != null ? # : #', [l, l, _visit(right)])
      ]);
    }

    if (binaryOperationIsPrimitive(leftType, rightType) ||
        leftType == types.stringType && op.type == TokenType.PLUS) {
      // special cases where we inline the operation
      // these values are assumed to be non-null (determined by the checker)
      // TODO(jmesserly): it would be nice to just inline the method from core,
      // instead of special cases here.
      JS.Expression binary(String code) {
        return js.call(code, [notNull(left), notNull(right)]);
      }

      JS.Expression bitwise(String code) {
        return _coerceBitOperationResultToUnsigned(node, binary(code));
      }

      switch (op.type) {
        case TokenType.TILDE_SLASH:
          // `a ~/ b` is equivalent to `(a / b).truncate()`
          var div = AstBuilder.binaryExpression(left, '/', right)
            ..staticType = node.staticType;
          return _emitSend(div, 'truncate', []);

        case TokenType.PERCENT:
          // TODO(sra): We can generate `a % b + 0` if both are non-negative
          // (the `+ 0` is to coerce -0.0 to 0).
          return _emitSend(left, op.lexeme, [right]);

        case TokenType.AMPERSAND:
          return bitwise('# & #');

        case TokenType.BAR:
          return bitwise('# | #');

        case TokenType.CARET:
          return bitwise('# ^ #');

        case TokenType.GT_GT:
          int shiftCount = _asIntInRange(right, 0, 31);
          if (_is31BitUnsigned(left) && shiftCount != null) {
            return binary('# >> #');
          }
          if (_isDefinitelyNonNegative(left) && shiftCount != null) {
            return binary('# >>> #');
          }
          // TODO(sra): If the context selects out only bits that can't be
          // affected by the sign position we can use any JavaScript shift.
          // E.g. `(x >> 6) & 3`.
          return _emitSend(left, op.lexeme, [right]);

        case TokenType.LT_LT:
          if (_is31BitUnsigned(node)) {
            // Result is 31 bit unsigned which implies the shift count was small
            // enough not to pollute the sign bit.
            return binary('# << #');
          }
          if (_asIntInRange(right, 0, 31) != null) {
            return _coerceBitOperationResultToUnsigned(node, binary('# << #'));
          }
          return _emitSend(left, op.lexeme, [right]);

        default:
          // TODO(vsm): When do Dart ops not map to JS?
          return binary('# $op #');
      }
    }

    return _emitSend(left, op.lexeme, [right]);
  }

  /// Bit operations are coerced to values on [0, 2^32). The coercion changes
  /// the interpretation of the 32-bit value from signed to unsigned.  Most
  /// JavaScript operations interpret their operands as signed and generate
  /// signed results.
  JS.Expression _coerceBitOperationResultToUnsigned(
      Expression node, JS.Expression operation) {
    // Don't coerce if the parent will coerce.
    AstNode parent = _parentOperation(node);
    if (_nodeIsBitwiseOperation(parent)) return operation;

    // Don't do a no-op coerce if the most significant bit is zero.
    if (_is31BitUnsigned(node)) return operation;

    // TODO(sra): If the consumer of the expression is '==' or '!=' to a
    // constant that fits in 31 bits, adding a coercion does not change the
    // result of the comparision, e.g.  `a & ~b == 0`.
    return js.call('# >>> 0', operation);
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

  Expression _skipParentheses(Expression expr) {
    while (expr is ParenthesizedExpression) {
      ParenthesizedExpression parenExpr = expr;
      expr = parenExpr.expression;
    }
    return expr;
  }

  int _asIntInRange(Expression expr, int low, int high) {
    expr = _skipParentheses(expr);
    if (expr is IntegerLiteral) {
      if (expr.value >= low && expr.value <= high) return expr.value;
    }
    return null;
  }

  bool _isDefinitelyNonNegative(Expression expr) {
    expr = _skipParentheses(expr);
    if (expr is IntegerLiteral) {
      return expr.value >= 0;
    }
    if (_nodeIsBitwiseOperation(expr)) return true;
    // TODO(sra): Lengths of known list types etc.
    return false;
  }

  /// Determines if the result of evaluating [expr] will be an non-negative
  /// value that fits in 31 bits.
  bool _is31BitUnsigned(Expression expr) {
    const int MAX = 32; // Includes larger and negative values.
    /// Determines how many bits are required to hold result of evaluation
    /// [expr].  [depth] is used to bound exploration of huge expressions.
    int bitWidth(Expression expr, int depth) {
      if (expr is IntegerLiteral) {
        return expr.value >= 0 ? expr.value.bitLength : MAX;
      }
      if (++depth > 5) return MAX;
      if (expr is BinaryExpression) {
        var left = _skipParentheses(expr.leftOperand);
        var right = _skipParentheses(expr.rightOperand);
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
      return MAX;
    }
    return bitWidth(expr, 0) < 32;
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
    return isPrimitiveType(leftType) && leftType == rightType;
  }

  bool _isNull(Expression expr) => expr is NullLiteral;

  SimpleIdentifier _createTemporary(String name, DartType type,
      {bool nullable: true, JS.Expression variable}) {
    // We use an invalid source location to signal that this is a temporary.
    // See [_isTemporary].
    // TODO(jmesserly): alternatives are
    // * (ab)use Element.isSynthetic, which isn't currently used for
    //   LocalVariableElementImpl, so we could repurpose to mean "temp".
    // * add a new property to LocalVariableElementImpl.
    // * create a new subtype of LocalVariableElementImpl to mark a temp.
    var id =
        new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, name, -1));

    variable ??= new JS.TemporaryId(name);

    id.staticElement = new TemporaryVariableElement.forNode(id, variable);
    id.staticType = type;
    DynamicInvoke.set(id, type.isDynamic);
    addTemporaryVariable(id.staticElement, nullable: nullable);
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
      Map<JS.MetaLetVariable, JS.Expression> scope, Expression expr,
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
  Expression _bindValue(Map<JS.MetaLetVariable, JS.Expression> scope,
      String name, Expression expr,
      {Expression context}) {
    // No need to do anything for stateless expressions.
    if (isStateless(_currentFunction, expr, context)) return expr;

    var variable = new JS.MetaLetVariable(name);
    var t = _createTemporary(name, getStaticType(expr), variable: variable);
    scope[variable] = _visit(expr);
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
  /// The [JS.MetaLet] nodes automatically simplify themselves if they can.
  /// For example, if the result value is not used, then `t` goes away.
  @override
  JS.Expression visitPostfixExpression(PostfixExpression node) {
    var op = node.operator;
    var expr = node.operand;

    var dispatchType = getStaticType(expr);
    if (unaryOperationIsPrimitive(dispatchType)) {
      if (!isNullable(expr)) {
        return js.call('#$op', _visit(expr));
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
      if (op.lexeme == '~') {
        if (_isNumberInJS(dispatchType)) {
          JS.Expression jsExpr = js.call('~#', notNull(expr));
          return _coerceBitOperationResultToUnsigned(node, jsExpr);
        }
        return _emitSend(expr, op.lexeme[0], []);
      }
      if (!isNullable(expr)) {
        return js.call('$op#', _visit(expr));
      }
      if (op.lexeme == '++' || op.lexeme == '--') {
        // We need a null check, so the increment must be expanded out.
        var vars = <JS.MetaLetVariable, JS.Expression>{};
        var x = _bindLeftHandSide(vars, expr, context: expr);

        var one = AstBuilder.integerLiteral(1)..staticType = types.intType;
        var increment = AstBuilder.binaryExpression(x, op.lexeme[0], one)
          ..staticElement = node.staticElement
          ..staticType = getStaticType(expr);

        return new JS.MetaLet(vars, [_emitSet(x, increment)]);
      }
      return js.call('$op#', notNull(expr));
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

    var vars = <JS.MetaLetVariable, JS.Expression>{};
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
  visitFormalParameter(FormalParameter node) {
    var id = _emitParameter(node.element, declaration: true);
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
      return _emitAccess(node.prefix, node.identifier, node.staticType);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.operator.lexeme == '?.') {
      return _emitNullSafe(node);
    }
    return _emitAccess(_getTarget(node), node.propertyName, node.staticType);
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
        if (!isNullable(nodeTarget)) {
          node = _stripNullAwareOp(node, nodeTarget);
          break;
        }

        var param =
            _createTemporary('_', nodeTarget.staticType, nullable: false);
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

  /// Everything in Dart is an Object and supports the 4 members on Object,
  /// so we have to use a runtime helper to handle values such as `null` and
  /// native types.
  ///
  /// For example `null.toString()` is legal in Dart, so we need to generate
  /// that as `dart.toString(obj)`.
  bool _isObjectMemberCall(Expression target, String memberName) {
    // Is this a member on `Object`?
    if (!isObjectProperty(memberName)) {
      return false;
    }

    // Check if the target could be `null`, is dynamic, or may be an extension
    // native type. In all of those cases we need defensive code generation.
    var type = getStaticType(target);
    return isNullable(target) ||
        type.isDynamic ||
        (_extensionTypes.contains(type.element) && target is! SuperExpression);
  }

  /// Shared code for [PrefixedIdentifier] and [PropertyAccess].
  JS.Expression _emitAccess(
      Expression target, SimpleIdentifier memberId, DartType resultType) {
    Element member = memberId.staticElement;
    if (member is PropertyAccessorElement) {
      member = (member as PropertyAccessorElement).variable;
    }
    bool isStatic = member is ClassMemberElement && member.isStatic;
    var name = _emitMemberName(memberId.name,
        type: getStaticType(target), isStatic: isStatic);
    if (DynamicInvoke.get(target)) {
      return js.call('dart.dload(#, #)', [_visit(target), name]);
    }

    var jsTarget = _visit(target);
    bool isSuper = jsTarget is JS.Super;

    if (isSuper && member is FieldElement && !member.isSynthetic) {
      // If super.x is actually a field, then x is an instance property since
      // subclasses cannot override x.
      jsTarget = new JS.This();
    }

    JS.Expression result;
    if (member != null && member is MethodElement && !isStatic) {
      // Tear-off methods: explicitly bind it.
      if (isSuper) {
        result = js.call('dart.bind(this, #, #.#)', [name, jsTarget, name]);
      } else if (_isObjectMemberCall(target, memberId.name)) {
        result = js.call('dart.bind(#, #, dart.#)', [jsTarget, name, name]);
      } else {
        result = js.call('dart.bind(#, #)', [jsTarget, name]);
      }
    } else if (_isObjectMemberCall(target, memberId.name)) {
      result = js.call('dart.#(#)', [name, jsTarget]);
    } else {
      result = js.call('#.#', [jsTarget, name]);
    }
    return _applyFunctionTypeArguments(result, member, resultType);
  }

  /// If this is an inferred instantiation of a generic function/method, this
  /// will add the inferred type arguments.
  JS.Expression _applyFunctionTypeArguments(
      JS.Expression result, Element member, DartType instantiated) {
    DartType type;
    if (member is ExecutableElement) {
      type = member.type;
    } else if (member is VariableElement) {
      type = member.type;
    }

    // TODO(jmesserly): handle explicitly passed type args.
    if (type == null) return result;
    var typeArgs = _emitFunctionTypeArguments(type, instantiated);
    if (typeArgs == null) return result;
    return js.call('dart.gbind(#, #)', [result, typeArgs]);
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
      var dynamicHelper = const {'[]': 'dindex', '[]=': 'dsetindex'}[name];
      if (dynamicHelper != null) {
        return js.call(
            'dart.$dynamicHelper(#, #)', [_visit(target), _visitList(args)]);
      }
      return js.call('dart.dsend(#, #, #)',
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
    var streamIterator = rules.instantiateToBounds(_asyncStreamIterator);
    var createStreamIter = _emitInstanceCreationExpression(
        streamIterator.element.unnamedConstructor,
        streamIterator,
        null,
        AstBuilder.argumentList([node.iterable]),
        false);
    var iter = _visit(_createTemporary('it', streamIterator, nullable: false));

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
    JS.Expression emitSymbol() {
      // TODO(vsm): When we canonicalize, we need to treat private symbols
      // correctly.
      var name = js.string(node.components.join('.'), "'");
      return js.call('#.new(#)', [_emitTypeName(types.symbolType), name]);
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
      // TODO(jmesserly): analyzer will usually infer `List<Object>` because
      // that is the least upper bound of the element types. So we rarely
      // generate a plain `List<dynamic>` anymore.
      if (!elementType.isDynamic) {
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

  List/*<T>*/ _visitList/*<T extends AstNode>*/(Iterable/*<T>*/ nodes) {
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
      return _emitPrivateNameSymbol(currentLibrary, name);
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
        baseType != null &&
        _extensionTypes.contains(baseType.element) &&
        !isObjectProperty(name)) {
      return js.call('dartx.#', _propertyName(name));
    }

    return _propertyName(name);
  }

  JS.TemporaryId _emitPrivateNameSymbol(LibraryElement library, String name) {
    return _privateNames
        .putIfAbsent(library, () => new HashMap())
        .putIfAbsent(name, () {
      var id = new JS.TemporaryId(name);
      _moduleItems.add(
          js.statement('const # = Symbol(#);', [id, js.string(id.name, "'")]));
      return id;
    });
  }

  bool _externalOrNative(node) =>
      node.externalKeyword != null || _functionBody(node) is NativeFunctionBody;

  FunctionBody _functionBody(node) =>
      node is FunctionDeclaration ? node.functionExpression.body : node.body;

  /// Returns the canonical name to refer to the Dart library.
  JS.Identifier emitLibraryName(LibraryElement library) {
    // It's either one of the libraries in this module, or it's an import.
    return _libraries[library] ??
        _imports.putIfAbsent(library,
            () => new JS.TemporaryId(jsLibraryName(_buildRoot, library)));
  }

  JS.Node/*=T*/ annotate/*<T extends JS.Node>*/(
      JS.Node/*=T*/ node, AstNode original,
      [Element element]) {
    if (options.closure && element != null) {
      node = node.withClosureAnnotation(closureAnnotationFor(
          node, original, element, namedArgumentTemp.name));
    }
    return node..sourceInformation = original;
  }

  /// Returns true if this is any kind of object represented by `Number` in JS.
  ///
  /// In practice, this is 4 types: num, int, double, and JSNumber.
  ///
  /// JSNumber is the type that actually "implements" all numbers, hence it's
  /// a subtype of int and double (and num). It's in our "dart:_interceptors".
  bool _isNumberInJS(DartType t) => rules.isSubtypeOf(t, types.numType);

  bool _isObjectGetter(String name) {
    PropertyAccessorElement element = types.objectType.element.getGetter(name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectMethod(String name) {
    MethodElement element = types.objectType.element.getMethod(name);
    return (element != null && !element.isStatic);
  }

  bool isObjectProperty(String name) {
    return _isObjectGetter(name) || _isObjectMethod(name);
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
        // TODO(vsm): Revisit with issue #228.
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

/// Choose a canonical name from the library element.
/// This never uses the library's name (the identifier in the `library`
/// declaration) as it doesn't have any meaningful rules enforced.
String jsLibraryName(String buildRoot, LibraryElement library) {
  var uri = library.source.uri;
  if (uri.scheme == 'dart') {
    return uri.path;
  }
  // TODO(vsm): This is not necessarily unique if '__' appears in a file name.
  var separator = '__';
  String qualifiedPath;
  if (uri.scheme == 'package') {
    // Strip the package name.
    // TODO(vsm): This is not unique if an escaped '/'appears in a filename.
    // E.g., "foo/bar.dart" and "foo$47bar.dart" would collide.
    qualifiedPath = uri.pathSegments.skip(1).join(separator);
  } else if (uri.path.startsWith(buildRoot)) {
    qualifiedPath =
        uri.path.substring(buildRoot.length).replaceAll('/', separator);
  } else {
    // We don't have a unique name.
    throw 'Invalid build root.  $buildRoot does not contain ${uri.path}';
  }
  return pathToJSIdentifier(qualifiedPath);
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

bool isLibraryPrefix(Expression node) =>
    node is SimpleIdentifier && node.staticElement is PrefixElement;

LibraryElement _getLibrary(AnalysisContext c, String uri) =>
    c.computeLibraryElement(c.sourceFactory.forUri(uri));

bool _isDartRuntime(LibraryElement l) =>
    l.isInSdk && l.source.uri.toString() == 'dart:_runtime';
