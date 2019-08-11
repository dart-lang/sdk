// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;
import 'dart:collection';
import 'package:analyzer/dart/element/element.dart' as a;
import 'package:analyzer/dart/element/type.dart' as a;
import 'package:analyzer/file_system/physical_file_system.dart' as a;
import 'package:analyzer/src/context/context.dart' as a;
import 'package:analyzer/src/dart/element/element.dart' as a;
import 'package:analyzer/src/dart/element/member.dart' as a;
import 'package:analyzer/src/dart/element/type.dart' as a;
import 'package:analyzer/src/generated/constant.dart' as a;
import 'package:analyzer/src/generated/engine.dart' as a;
import 'package:analyzer/src/generated/source.dart' as a;
import 'package:analyzer/src/generated/type_system.dart' as a;
import 'package:analyzer/src/summary/idl.dart' as a;
import 'package:analyzer/src/summary/package_bundle_reader.dart' as a;
import 'package:analyzer/src/summary/summary_sdk.dart' as a;
import 'package:analyzer/src/generated/resolver.dart' as a
    show NamespaceBuilder, TypeProvider;
import 'package:front_end/src/api_unstable/ddc.dart'
    show RedirectingFactoryBody;
import 'package:kernel/kernel.dart';
import 'package:kernel/type_algebra.dart';

import 'type_table.dart';

/// Converts an Analyzer summary file to a Kernel [Component].
///
/// The first step is to use Analyzer's [a.StoreBasedSummaryResynthesizer] to
/// deserialize the summary file into an [a.Element] model (that way we don't
/// depend directly on the file format). Once we have elements, we visit them
/// and construct the corresponding Kernel [Node]s.
///
/// The main entry points are [convertSdk] and [convertSummaries], which
/// convert the SDK and input summaries, respectively.
///
/// Because we only need to convert summaries, we do not need to handle method
/// bodies. This lets us avoid the complexity of converting Analyzer AST nodes
/// (e.g. expressions, statements).
///
/// For constants we use Analyzer's constant evaluator compute the value from
/// the data in the summary, and then create the appropriate Kernel node to
/// reconstruct the constant (e.g. ListLiteral, ConstructorInvocation, etc).
/// See [_visitConstant] for more information.
///
/// When something refers to an element, we normally create the [Reference] but
/// leave its corresponding [NamedNode] empty until that element is visited and
/// creates the Kernel node. This takes care of cycles, and avoids recursing too
/// deeply as we convert elements.
///
/// Sometimes we need to convert an element eagerly (e.g. if we need to call
/// members on an [InterfaceType] or [Supertype], we need to create its [Class]
/// node). In that case we handle cycles in the visit method (e.g.
/// [visitClassElement]) by creating the node and linking it to its reference
/// before visiting anything else that might recurse.
///
/// Special care must be taken to make sure we link up all [Reference]s with
/// their corresponding [NamedNode]. If we don't do this [verifyReferences]
/// will throw an error. The fix is to figure out why we didn't visit the
/// element for that reference (often this is due to Analyzer's synthetic
/// fields/accessor elements; care must be taken to always reference the real
/// element).
///
/// Because we're using Analyzer's summary resynthesizer, conversion is all or
/// nothing: all summaries must be in Analyzer format, including the SDK.
/// Now that we have this implementation, it may be possible to port code from
/// Analyzer and modify it to resynthesize directly into Kernel trees, if we
/// ever need to support a mix of Kernel and Analyzer summary files.
class AnalyzerToKernel {
  final a.StoreBasedSummaryResynthesizer _resynth;
  final a.SummaryDataStore _summaryData;
  final a.TypeProvider types;
  final a.Dart2TypeSystem rules;

  final _references = HashMap<a.Element, Reference>();
  final _typeParams = HashMap<a.TypeParameterElement, TypeParameter>();
  final _namespaceBuilder = a.NamespaceBuilder();

  AnalyzerToKernel._(this._resynth, this._summaryData)
      : types = _resynth.typeProvider,
        rules = _resynth.typeSystem as a.Dart2TypeSystem;

  /// Create an Analyzer summary to Kernel tree converter, using the provided
  /// [analyzerSdkSummary] and [summaryPaths].
  ///
  /// Once the converter is created, [convertSdk] should be called to convert
  /// & return the SDK, followed by [convertSummaries] to convert & return the
  /// converted summaries.
  factory AnalyzerToKernel(
      String analyzerSdkSummary, List<String> summaryPaths) {
    var summaryData = a.SummaryDataStore(summaryPaths,
        resourceProvider: a.PhysicalResourceProvider.INSTANCE,
        disallowOverlappingSummaries: false);
    var resynthesizer =
        _createSummaryResynthesizer(summaryData, analyzerSdkSummary);
    return AnalyzerToKernel._(resynthesizer, summaryData);
  }

  /// Converts the SDK summary to a Kernel component and returns it.
  Component convertSdk() {
    // _createContextForSummaries puts the SDK summary last in the summary data.
    var sdkBundle = _summaryData.bundles.last;
    assert(sdkBundle.linkedLibraryUris.every((u) => u.startsWith('dart:')));
    var result = _toComponent(sdkBundle);
    verifyReferences();
    return result;
  }

  /// Converts the input summaries to Kernel components and return them.
  ///
  /// [convertSdk] must be called before this.
  List<Component> convertSummaries() {
    // Take all summaries except the SDK one, which is placed last in the list
    // by _createContextForSummaries.
    var bundles = _summaryData.bundles.take(_summaryData.bundles.length - 1);
    var result = bundles.map(_toComponent).toList();
    verifyReferences(); // assumption: convertSdk() is called first
    return result;
  }

  /// Dispose the Analysis Context used for summary conversion.
  void dispose() => _resynth.context.dispose();

  void verifyReferences() {
    _references.forEach((element, reference) {
      // Ensure each reference has a corresponding node.
      //
      // If it's missing a node, CFE will fail and it is difficult to debug at
      // that point because the name and element cannot be accessed.
      //
      // Typically this error means:
      // - we didn't visit an element.
      // - we didn't set the `reference: _reference(e)` for the Kernel node.
      // - we referenced a synthetic element by mistake, such as referencing the
      //   synthetic getter/setter, when we should've used the field.
      if (reference.node == null) {
        throw StateError('missing node for reference, element was: $element' +
            (element.isSynthetic ? ' (synthetic)' : ''));
      }
    });
  }

  Component _toComponent(a.PackageBundle bundle) {
    var libraries = <Library>[];
    var uriToSource = <Uri, Source>{};

    void addCompilationUnit(a.CompilationUnitElement unit) {
      uriToSource[unit.source.uri] = Source(
          unit.lineInfo.lineStarts,
          [],
          unit.uri != null ? Uri.base.resolve(unit.uri) : unit.source.uri,
          unit.source.uri);
    }

    for (var uri in bundle.unlinkedUnitUris) {
      var unitInfo = _resynth.getUnlinkedSummary(uri);
      if (unitInfo.isPartOf) {
        // Library parts are handled by their corresponding library.
        continue;
      }

      var element = _resynth.getLibraryElement(uri);
      libraries.add(visitLibraryElement(element));
      addCompilationUnit(element.definingCompilationUnit);
      element.parts.forEach(addCompilationUnit);
    }
    return Component(libraries: libraries, uriToSource: uriToSource);
  }

  Class visitClassElement(a.ClassElement e, [Library library]) {
    var ref = _reference(e);
    if (ref.node != null) return ref.asClass;

    // Construct the Class first and link the reference. This ensures the
    // (not yet finished) Class node will be returned on the line above, if we
    // happen to re-enter this visit method.
    var class_ = Class(
        name: e.name,
        isAbstract: e.isAbstract,
        fileUri: e.source.uri,
        reference: ref);

    // Classes can be visited before their library (e.g. because they're a
    // supertype of another class), so make sure to visit the library now.
    library ??= visitLibraryElement(e.library);
    library.addClass(class_);

    class_.isMixinDeclaration = e.isMixin;
    class_.typeParameters
        .addAll(e.typeParameters.map(visitTypeParameterElement));

    setParents(class_.typeParameters, class_);
    class_.implementedTypes.addAll(e.interfaces.map(_typeToSupertype));

    var fields = class_.fields;
    var constructors = class_.constructors;
    var procedures = class_.procedures;

    fields.addAll(e.fields.where((f) => !f.isSynthetic).map(visitFieldElement));

    var redirectingFactories = <Procedure>[];
    for (var ctor in e.constructors) {
      if (ctor.isFactory) {
        var factory_ = _visitFactory(ctor);
        procedures.add(factory_);
        if (ctor.redirectedConstructor != null) {
          redirectingFactories.add(factory_);
        }
      } else {
        constructors.add(visitConstructorElement(ctor));
      }
    }
    if (redirectingFactories.isNotEmpty) {
      fields.add(_createRedirectingFactoryField(redirectingFactories, e));
    }
    procedures.addAll(e.methods.map(visitMethodElement));
    procedures.addAll(e.accessors
        .where((a) => !a.isSynthetic)
        .map(visitPropertyAccessorElement));

    setParents(fields, class_);
    setParents(constructors, class_);
    setParents(procedures, class_);

    if (e.isMixinApplication) {
      class_.mixedInType = _typeToSupertype(e.mixins.last);
    }

    var supertype = _typeToSupertype(e.supertype);
    class_.supertype = _unrollMixinClasses(e, supertype, library);
    _visitAnnotations(e.metadata, class_.addAnnotation);

    // TODO(jmesserly): do we need covariance check stubs? We may be okay as
    // since we're only handling dependencies here.
    //
    // But this may lead to redundant stubs (if CFE doesn't see one on a
    // superclass) and/or break some assumptions in CFE.
    return class_;
  }

  Supertype _unrollMixinClasses(
      a.ClassElement e, Supertype supertype, Library library) {
    // TODO(jmesserly): is this enough for mixin desugaring? It only does
    // enough to create the intermediate classes.

    // Documentation below assumes the given mixin application is in one of
    // these forms:
    //
    //     class C extends S with M1, M2, M3;
    //     class Named = S with M1, M2, M3;
    //
    // When we refer to the subclass, we mean `C` or `Named`.

    /// The number of mixin classes to unroll.
    ///
    /// Named mixin applications have one less class. This can be illustrated
    /// here:
    ///
    ///     class C extends S with M1, M2, M3 {}
    ///     class Named = S with M1, M2, M3;
    ///
    /// For `C` we unroll 3 classes: _C&S&M1, _C&S&M1&M2, _C&S&M1&M2&M3.
    /// For `Named` we unroll 2 classes: _Named&S&M1, _Named&S&M1&M2.
    ///
    /// The classes themselves will be generated as:
    ///
    ///     class C extends _C&S&M1&M2&M3 {}
    ///     class Named = _Named&S&M1&M2 with M3;
    ///
    var unrollLength = e.mixins.length;
    if (e.isMixinApplication) unrollLength--;
    if (unrollLength <= 0) return supertype;

    /// The mixin application's synthetic name.
    ///
    /// The full name of the mixin application is obtained by prepending the
    /// name of the subclass (`C` or `Named` in the above examples) to the
    /// running name. For the example `C`, that leads to these names:
    ///
    /// 1. `_C&S&M1`
    /// 2. `_C&S&M1&M2`
    /// 3. `_C&S&M1&M2&M3`.
    var runningName = '_${e.name}&${e.supertype.name}';

    /// The type variables used in the current supertype and mixin, or null
    /// if this class doesn't have any type parameters.
    var usedTypeVars = e.typeParameters.isNotEmpty
        ? freeTypeParameters(supertype.asInterfaceType)
        : null;

    for (int i = 0; i < unrollLength; i++) {
      var mixin = e.mixins[i];
      runningName += "&${mixin.name}";

      var mixedInType = _typeToSupertype(mixin);
      List<TypeParameter> typeParameters;
      if (usedTypeVars != null) {
        // Any type params used by superclasses will continue to be used, plus
        // anything additional that this mixin uses.
        usedTypeVars.addAll(freeTypeParameters(mixedInType.asInterfaceType));
        if (usedTypeVars.isNotEmpty) {
          // Make fresh type parameters for this class, and then substitute them
          // into supertype and mixin type arguments (if any).
          var fresh = getFreshTypeParameters(usedTypeVars.toList());
          typeParameters = fresh.freshTypeParameters;
          supertype = fresh.substituteSuper(supertype);
          mixedInType = fresh.substituteSuper(mixedInType);
        }
      }

      var c = Class(
          name: runningName,
          isAbstract: true,
          mixedInType: mixedInType,
          supertype: supertype,
          typeParameters: typeParameters,
          fileUri: e.source.uri);

      library.addClass(c);

      // Compute the superclass to use for the next iteration of this loop.
      //
      // Any type arguments are in terms of the original class type parameters.
      // This allows us to perform consistent substitutions and have the correct
      // type arguments for the final supertype (that we return).
      supertype = Supertype(
          c,
          typeParameters != null
              ? List.of(usedTypeVars.map((t) => TypeParameterType(t)))
              : []);
    }

    return supertype;
  }

  Constructor visitConstructorElement(a.ConstructorElement e) {
    assert(!e.isFactory);
    var ref = _reference(e);
    if (ref.node != null) return ref.asConstructor;
    // By convention, instance constructors return `void` in Kernel.
    var function = _createFunction(e)..returnType = const VoidType();
    var result = Constructor(function,
        name: _getName(e),
        isConst: e.isConst,
        isExternal: e.isExternal,
        isSynthetic: e.isSynthetic,
        fileUri: e.source.uri,
        reference: ref);
    if (!result.isSynthetic) {
      // TODO(jmesserly): CFE does not respect the synthetic bit on constructors
      // so we set a bogus offset. This causes CFE to treat it as not synthetic.
      //
      // (The bug is in DillMemberBuilder.isSynthetic. Synthetic constructors
      // have different semantics/optimizations in some cases, so it is
      // important that the constructor is correctly marked.)
      result.fileOffset = 1;
    }
    _visitAnnotations(e.metadata, result.addAnnotation);
    return result;
  }

  Procedure _visitFactory(a.ConstructorElement e) {
    var ref = _reference(e);
    if (ref.node != null) return ref.asProcedure;

    var result = Procedure.byReference(_getName(e), ProcedureKind.Factory, null,
        isExternal: e.isExternal,
        isConst: e.isConst,
        isStatic: true,
        fileUri: e.source.uri,
        reference: ref);

    _visitAnnotations(e.metadata, result.addAnnotation);

    // Since the factory is static, we need to create fresh type parameters that
    // match the ones in the enclosing class.
    FreshTypeParameters fresh;
    DartType Function(a.DartType) visitType;

    if (e.enclosingElement.typeParameters.isNotEmpty) {
      fresh = getFreshTypeParameters(
          visitClassElement(e.enclosingElement).typeParameters);
      visitType = (t) => fresh.substitute(_visitDartType(t, ensureNode: true));
    } else {
      visitType = _visitDartType;
    }

    result.function = _createFunction(e, fresh?.freshTypeParameters, visitType);
    result.function.parent = result;

    var redirect = e.redirectedConstructor;
    if (redirect == null) return result;

    // Get the raw constructor element before the type is applied.
    var rawRedirect =
        redirect is a.ConstructorMember ? redirect.baseElement : redirect;

    // TODO(jmesserly): conceptually we only need a reference here, but
    // RedirectingFactoryBody requires the complete node.
    var ctor = rawRedirect.isFactory
        ? _visitFactory(rawRedirect)
        : visitConstructorElement(rawRedirect);

    var redirectedType = redirect.type.returnType as a.InterfaceType;
    var typeArgs = redirectedType.typeArguments.map(visitType).toList();
    result.function.body = RedirectingFactoryBody(ctor, typeArgs);
    return result;
  }

  Field _createRedirectingFactoryField(
      List<Procedure> factories, a.ClassElement c) {
    return Field(_getName(c, "_redirecting#"),
        isStatic: true,
        initializer: ListLiteral(List.of(factories.map((f) => StaticGet(f)))),
        fileUri: c.source.uri);
  }

  LibraryDependency visitExportElement(a.ExportElement e) =>
      LibraryDependency.byReference(
          LibraryDependency.ExportFlag,
          const [],
          _reference(e.exportedLibrary),
          null,
          e.combinators.map(_visitCombinator).toList());

  Field visitFieldElement(a.FieldElement e) {
    var result = Field(_getName(e),
        type: _visitDartType(e.type),
        initializer: null,
        isFinal: e.isFinal,
        isConst: e.isConst,
        isStatic: e.isStatic,
        fileUri: e.source.uri,
        reference: _reference(e));
    if (!e.isFinal && !e.isConst) {
      var class_ = e.enclosingElement as a.ClassElement;
      if (class_.typeParameters.isNotEmpty) {
        result.isGenericCovariantImpl = _isGenericCovariant(class_, e.type);
      }
    }
    _visitAnnotations(e.metadata, result.addAnnotation);
    return result;
  }

  Procedure visitFunctionElement(a.FunctionElement e) {
    var result = Procedure.byReference(
        _getName(e), ProcedureKind.Method, _createFunction(e),
        isExternal: e.isExternal,
        fileUri: e.source.uri,
        isStatic: true,
        reference: _reference(e));
    _visitAnnotations(e.metadata, result.addAnnotation);
    return result;
  }

  Typedef visitFunctionTypeAliasElement(a.FunctionTypeAliasElement e,
      [Library library]) {
    var ref = _reference(e);
    if (ref.node != null) return ref.asTypedef;

    var t = Typedef(e.name, null, reference: ref, fileUri: e.source.uri);
    library ??= visitLibraryElement(e.library);
    library.addTypedef(t);

    a.FunctionType type;
    var typeParams = e.typeParameters;
    if (e is a.GenericTypeAliasElement) {
      type = e.function.type;
    } else {
      type = e.type;
      if (typeParams.isNotEmpty) {
        // Skip past the type formals, we'll add them back below, so these
        // type parameter names will end up in scope in the generated JS.
        type = type.instantiate(typeParams.map((f) => f.type).toList());
      }
    }
    t.typeParameters.addAll(typeParams.map(visitTypeParameterElement));
    setParents(t.typeParameters, t);
    t.type = _visitDartType(type, originTypedef: t.thisType);
    _visitAnnotations(e.metadata, t.addAnnotation);
    return t;
  }

  LibraryDependency visitImportElement(a.ImportElement e) =>
      LibraryDependency.byReference(0, const [], _reference(e.importedLibrary),
          null, e.combinators.map(_visitCombinator).toList());

  Library visitLibraryElement(a.LibraryElement e) {
    var ref = _reference(e);
    if (ref.node != null) return ref.asLibrary;

    var library = Library(e.source.uri,
        name: e.name,
        fileUri: e.definingCompilationUnit.source.uri,
        reference: ref);
    library.fileOffset = 0;

    _visitAnnotations(e.metadata, library.addAnnotation);
    e.imports.map(visitImportElement).forEach(library.addDependency);
    e.exports.map(visitExportElement).forEach(library.addDependency);
    e.parts.map((p) => LibraryPart(const [], p.uri)).forEach(library.addPart);

    _visitUnit(a.CompilationUnitElement u) {
      for (var t in u.types) {
        visitClassElement(t, library);
      }
      for (var t in u.mixins) {
        visitClassElement(t, library);
      }
      for (var t in u.functionTypeAliases) {
        visitFunctionTypeAliasElement(t, library);
      }
      u.functions.map(visitFunctionElement).forEach(library.addMember);
      u.accessors
          .where((a) => !a.isSynthetic)
          .map(visitPropertyAccessorElement)
          .forEach(library.addMember);
      u.topLevelVariables
          .map(visitTopLevelVariableElement)
          .forEach(library.addMember);
    }

    _visitUnit(e.definingCompilationUnit);
    e.parts.forEach(_visitUnit);

    var libraryImpl = e as a.LibraryElementImpl;
    libraryImpl.publicNamespace ??=
        _namespaceBuilder.createPublicNamespaceForLibrary(e);
    libraryImpl.exportNamespace ??=
        _namespaceBuilder.createExportNamespaceForLibrary(e);
    var publicNames = libraryImpl.publicNamespace.definedNames;
    var exportNames = libraryImpl.exportNamespace.definedNames;
    exportNames.forEach((name, value) {
      if (!publicNames.containsKey(name)) {
        value = value is a.PropertyAccessorElement && value.isSynthetic
            ? value.variable
            : value;
        library.additionalExports.add(_reference(value));
      }
    });
    return library;
  }

  Procedure visitMethodElement(a.MethodElement e) {
    var result = Procedure.byReference(
        _getName(e),
        e.isOperator ? ProcedureKind.Operator : ProcedureKind.Method,
        _createFunction(e),
        isAbstract: e.isAbstract,
        isStatic: e.isStatic,
        isExternal: e.isExternal,
        fileUri: e.source.uri,
        reference: _reference(e));
    _visitAnnotations(e.metadata, result.addAnnotation);
    return result;
  }

  Procedure visitPropertyAccessorElement(a.PropertyAccessorElement e) {
    var result = Procedure.byReference(
        _getName(e, e.variable.name),
        e.isGetter ? ProcedureKind.Getter : ProcedureKind.Setter,
        _createFunction(e),
        isAbstract: e.isAbstract,
        isStatic: e.isStatic,
        isExternal: e.isExternal,
        fileUri: e.source.uri,
        reference: _reference(e));
    _visitAnnotations(e.metadata, result.addAnnotation);
    return result;
  }

  Field visitTopLevelVariableElement(a.TopLevelVariableElement e) {
    var result = Field(_getName(e),
        type: _visitDartType(e.type),
        initializer: null,
        isFinal: e.isFinal,
        isConst: e.isConst,
        isStatic: e.isStatic,
        fileUri: e.source.uri,
        reference: _reference(e));
    _visitAnnotations(e.metadata, result.addAnnotation);
    return result;
  }

  TypeParameter visitTypeParameterElement(a.TypeParameterElement e) {
    var t = _typeParams[e];
    if (t != null) return t;
    _typeParams[e] = t = TypeParameter(e.name);

    var hasBound = e.bound != null;
    t.bound =
        hasBound ? _visitDartType(e.bound) : _visitDartType(types.objectType);
    t.defaultType = hasBound ? t.bound : const DynamicType();

    var enclosingElement = e.enclosingElement;
    if (hasBound && enclosingElement is a.ClassMemberElement) {
      var class_ = enclosingElement.enclosingElement;
      if (class_ is a.ClassElement && class_.typeParameters.isNotEmpty) {
        t.isGenericCovariantImpl = _isGenericCovariant(class_, e.bound);
      }
    }
    return t;
  }

  Name _getName(a.Element e, [String name]) {
    name ??= e.name;
    return Name.byReference(
        name, name.startsWith('_') ? _reference(e.library) : null);
  }

  /// Converts an Analyzer [type] to a Kernel type.
  ///
  /// If [ensureNode] is set, the reference to the [Class] or [Typedef] will
  /// populated with the node (creating it if needed). Many members on
  /// [InterfaceType] and [TypedefType] rely on having a node present, so this
  /// enables the use of those members if they're needed by the converter.
  DartType _visitDartType(a.DartType type,
      {bool ensureNode = false, TypedefType originTypedef}) {
    if (type.isVoid) {
      return const VoidType();
    } else if (type.isDynamic) {
      return const DynamicType();
    } else if (type.isBottom) {
      return const BottomType();
    } else if (type is a.TypeParameterType) {
      return TypeParameterType(visitTypeParameterElement(type.element));
    }

    visit(a.DartType t) => _visitDartType(t, ensureNode: ensureNode);

    if (type is a.InterfaceType) {
      var ref = ensureNode
          ? visitClassElement(type.element).reference
          : _reference(type.element);
      var typeArgs = type.typeArguments;
      var newTypeArgs = typeArgs.isNotEmpty
          ? typeArgs.map(visit).toList()
          : const <DartType>[];
      return InterfaceType.byReference(ref, newTypeArgs);
    }

    var f = type as a.FunctionType;
    if (f.name != null && f.name != '') {
      var ref = ensureNode
          ? visitFunctionTypeAliasElement(
                  f.element as a.FunctionTypeAliasElement)
              .reference
          : _reference(f.element);
      return TypedefType.byReference(ref, f.typeArguments.map(visit).toList());
    }
    var params = f.parameters;
    var positional = f.normalParameterTypes.map(visit).toList();
    positional.addAll(f.optionalParameterTypes.map(visit));

    var named = <NamedType>[];
    f.namedParameterTypes.forEach((name, type) {
      named.add(NamedType(name, visit(type)));
    });

    return FunctionType(positional, visit(f.returnType),
        typeParameters: f.typeFormals.map(visitTypeParameterElement).toList(),
        namedParameters: named,
        requiredParameterCount: params.where((p) => !p.isOptional).length,
        typedefType: originTypedef);
  }

  Supertype _typeToSupertype(a.InterfaceType t) {
    if (t == null) return null;
    return Supertype(
        visitClassElement(t.element),
        t.typeArguments
            .map((a) => _visitDartType(a, ensureNode: true))
            .toList());
  }

  Combinator _visitCombinator(a.NamespaceCombinator combinator) {
    bool isShow;
    List<String> names;
    if (combinator is a.ShowElementCombinator) {
      isShow = true;
      names = combinator.shownNames;
    } else {
      isShow = false;
      names = (combinator as a.HideElementCombinator).hiddenNames;
    }
    return Combinator(isShow, names);
  }

  /// Creates a function node for the executable element [e], optionally using
  /// the supplied [typeParameters] and calling [visitType] so it can perform
  /// any necessary substitutions.
  FunctionNode _createFunction(a.ExecutableElement e,
      [List<TypeParameter> typeParameters,
      DartType Function(a.DartType) visitType]) {
    visitType ??= _visitDartType;

    var enclosingElement = e.enclosingElement;
    var class_ = enclosingElement is a.ClassElement ? enclosingElement : null;

    visitParameter(a.ParameterElement e) {
      var result = VariableDeclaration(e.name,
          type: visitType(e.type),
          isFinal: e.isFinal,
          isFieldFormal: e.isInitializingFormal,
          isCovariant: e.isCovariant,
          initializer:
              e.isOptional ? _visitConstant(e.computeConstantValue()) : null);
      if (class_ != null && class_.typeParameters.isNotEmpty) {
        result.isGenericCovariantImpl = _isGenericCovariant(class_, e.type);
      }
      return result;
    }

    var params = e.parameters;
    var asyncMarker = _getAsyncMarker(e);
    return FunctionNode(null,
        typeParameters: typeParameters ??
            e.typeParameters.map(visitTypeParameterElement).toList(),
        positionalParameters:
            params.where((p) => !p.isNamed).map(visitParameter).toList(),
        namedParameters:
            params.where((p) => p.isNamed).map(visitParameter).toList(),
        requiredParameterCount: params.where((p) => !p.isOptional).length,
        returnType: visitType(e.returnType),
        asyncMarker: asyncMarker,
        dartAsyncMarker: asyncMarker);
  }

  Reference _reference(a.Element e) {
    if (e == null) throw ArgumentError('null element');
    return _references.putIfAbsent(e, () => Reference());
  }

  bool _isGenericCovariant(a.ClassElement c, a.DartType type) {
    var classUpperBound = rules.instantiateToBounds(c.type) as a.InterfaceType;
    var typeUpperBound = type.substitute2(classUpperBound.typeArguments,
        a.TypeParameterTypeImpl.getTypes(classUpperBound.typeParameters));
    // Is it safe to assign the upper bound of the field/parameter to it?
    // If not then we'll need a runtime check.
    return !rules.isSubtypeOf(typeUpperBound, type);
  }

  /// Transforms a metadata annotation from Analyzer to Kernel format.
  ///
  /// If needed this uses Analyzer's constant evaluation to evaluate the AST,
  /// and then converts the resulting constant value into a Kernel tree.
  /// By first computing the expression's constant value, we avoid having to
  /// convert a bunch of Analyzer ASTs nodes. Instead we can convert the more
  /// limited set of constant values allowed in Dart (see [_visitConstant]).
  void _visitAnnotations(List<a.ElementAnnotation> metadata,
      void Function(Expression) addAnnotation) {
    if (metadata.isEmpty) return;

    for (a.ElementAnnotation annotation in metadata) {
      var ast = (annotation as a.ElementAnnotationImpl).annotationAst;
      var arguments = ast.arguments;
      if (arguments == null) {
        var e = ast.element;
        e = e is a.PropertyAccessorElement && e.isSynthetic ? e.variable : e;
        addAnnotation(StaticGet.byReference(_reference(e)));
      } else {
        // Use Analyzer's constant evaluation to produce the constant, then
        // emit the resulting value. We do this to avoid handling all of the
        // AST nodes that might be needed for constant evaluation. Instead we
        // just serialize the resulting value to a Kernel expression that will
        // reproduce it.
        addAnnotation(_visitConstant(annotation.computeConstantValue()));
      }
    }
  }

  /// Converts an Analyzer constant value in [obj] to a Kernel expression
  /// (usually a Literal or ConstructorInvocation) that will recreate that
  /// constant value.
  Expression _visitConstant(a.DartObject obj) {
    if (obj == null || obj.isNull || !obj.hasKnownValue) return NullLiteral();

    var type = obj.type;
    if (identical(type, types.boolType)) {
      var value = obj.toBoolValue();
      return value != null ? BoolLiteral(value) : NullLiteral();
    }
    if (identical(type, types.intType)) {
      return IntLiteral(obj.toIntValue());
    }
    if (identical(type, types.doubleType)) {
      return DoubleLiteral(obj.toDoubleValue());
    }
    if (identical(type, types.stringType)) {
      return StringLiteral(obj.toStringValue());
    }
    if (identical(type, types.symbolType)) {
      return SymbolLiteral(obj.toSymbolValue());
    }
    if (identical(type, types.typeType)) {
      return TypeLiteral(_visitDartType(obj.toTypeValue()));
    }
    if (type is a.InterfaceType) {
      if (type.element == types.listType.element) {
        return ListLiteral(obj.toListValue().map(_visitConstant).toList(),
            typeArgument: _visitDartType(type.typeArguments[0]), isConst: true);
      }
      if (type.element == types.mapType.element) {
        var entries = obj
            .toMapValue()
            .entries
            .map(
                (e) => MapEntry(_visitConstant(e.key), _visitConstant(e.value)))
            .toList();
        return MapLiteral(entries,
            keyType: _visitDartType(type.typeArguments[0]),
            valueType: _visitDartType(type.typeArguments[1]),
            isConst: true);
      }
      if (obj is a.DartObjectImpl && obj.isUserDefinedObject) {
        var classElem = type.element;
        if (classElem.isEnum) {
          // TODO(jmesserly): we should be able to use `getField('index')` but
          // in some cases Analyzer uses the name of the static field that
          // contains the enum, rather than the `index` field, due to a bug.
          //
          // So we just grab the one instance field, regardless of its name.
          var index = obj.fields.values.single.toIntValue();
          var field =
              classElem.fields.where((f) => f.type == type).elementAt(index);
          return StaticGet.byReference(_reference(field));
        }
        var invocation = obj.getInvocation();
        var constructor = invocation.constructor;
        // For a redirecting const factory, the constant constructor will be
        // from the original one, but the `type` will match the redirected type.
        //
        // This leads to mismatch in how we call this constructor. So we need to
        // find the redirected one.
        for (a.ConstructorElement rc;
            (rc = constructor.redirectedConstructor) != null;) {
          constructor = rc;
        }
        constructor = constructor is a.ConstructorMember
            ? constructor.baseElement
            : constructor;
        return ConstructorInvocation.byReference(
            _reference(constructor),
            Arguments(
                invocation.positionalArguments.map(_visitConstant).toList(),
                named: invocation.namedArguments.entries
                    .map((e) => NamedExpression(e.key, _visitConstant(e.value)))
                    .toList(),
                types: type.typeArguments.map(_visitDartType).toList()),
            isConst: true);
      }
    }
    if (obj is a.DartObjectImpl && type is a.FunctionType) {
      var e = obj.toFunctionValue();
      e = e is a.PropertyAccessorElement && e.isSynthetic
          ? e.variable as a.ExecutableElement
          : e;
      // TODO(jmesserly): support generic tear-off implicit instantiation.
      return StaticGet.byReference(_reference(e));
    }
    throw UnsupportedError('unknown constant type `$type`: $obj');
  }
}

AsyncMarker _getAsyncMarker(a.ExecutableElement e) {
  return e.isGenerator
      ? (e.isAsynchronous ? AsyncMarker.AsyncStar : AsyncMarker.SyncStar)
      : (e.isAsynchronous ? AsyncMarker.Async : AsyncMarker.Sync);
}

a.StoreBasedSummaryResynthesizer _createSummaryResynthesizer(
    a.SummaryDataStore summaryData, String dartSdkPath) {
  var context = _createContextForSummaries(summaryData, dartSdkPath);
  var resynthesizer = a.StoreBasedSummaryResynthesizer(
      context, null, context.sourceFactory, /*strongMode*/ true, summaryData);
  resynthesizer.finishCoreAsyncLibraries();
  context.typeProvider = resynthesizer.typeProvider;
  return resynthesizer;
}

/// Creates a dummy Analyzer context so we can use summary resynthesizer.
///
/// This is similar to Analyzer's `LibraryContext._createResynthesizingContext`.
a.AnalysisContextImpl _createContextForSummaries(
    a.SummaryDataStore summaryData, String dartSdkPath) {
  var sdk = a.SummaryBasedDartSdk(dartSdkPath, true,
      resourceProvider: a.PhysicalResourceProvider.INSTANCE);
  var sdkSummaryBundle = sdk.getLinkedBundle();
  if (sdkSummaryBundle != null) {
    summaryData.addBundle(null, sdkSummaryBundle);
  }

  // TODO(jmesserly): use RestrictedAnalysisContext.
  var context = a.AnalysisEngine.instance.createAnalysisContext()
      as a.AnalysisContextImpl;
  context.sourceFactory = a.SourceFactory(
      [a.DartUriResolver(sdk), a.InSummaryUriResolver(null, summaryData)]);
  context.useSdkCachePartition = false;
  // TODO(jmesserly): do we need to set analysisOptions or declaredVariables?
  return context;
}
