// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.analyzer.loader;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:kernel/application_root.dart';
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';

import 'package:kernel/ast.dart' as ast;
import 'package:kernel/target/targets.dart' show Target;
import 'package:kernel/type_algebra.dart';
import 'package:analyzer/src/kernel/ast_from_analyzer.dart';

/// Options passed to the Dart frontend.
class DartOptions {
  /// True if user code should be loaded in strong mode.
  bool strongMode;

  /// True if the Dart SDK should be loaded in strong mode.
  bool strongModeSdk;

  /// Path to the sdk sources, ignored if sdkSummary is provided.
  String sdk;

  /// Path to a summary of the sdk sources.
  String sdkSummary;

  /// Path to the `.packages` file.
  String packagePath;

  /// Root used to relativize app file-urls, making them machine agnostic.
  ApplicationRoot applicationRoot;

  Map<Uri, Uri> customUriMappings;

  /// Environment definitions provided via `-Dkey=value`.
  Map<String, String> declaredVariables;

  DartOptions(
      {bool strongMode: false,
      bool strongModeSdk,
      this.sdk,
      this.sdkSummary,
      this.packagePath,
      ApplicationRoot applicationRoot,
      Map<Uri, Uri> customUriMappings,
      Map<String, String> declaredVariables})
      : this.customUriMappings = customUriMappings ?? <Uri, Uri>{},
        this.declaredVariables = declaredVariables ?? <String, String>{},
        this.strongMode = strongMode,
        this.strongModeSdk = strongModeSdk ?? strongMode,
        this.applicationRoot = applicationRoot ?? new ApplicationRoot.none();
}

abstract class ReferenceLevelLoader {
  ast.Library getLibraryReference(LibraryElement element);
  ast.Class getClassReference(ClassElement element);
  ast.Member getMemberReference(Element element);
  ast.Class getRootClassReference();
  ast.Constructor getRootClassConstructorReference();
  ast.Class getCoreClassReference(String className);
  ast.Constructor getCoreClassConstructorReference(String className,
      {String constructorName, String library});
  ast.TypeParameter tryGetClassTypeParameter(TypeParameterElement element);
  ast.Class getSharedMixinApplicationClass(
      ast.Library library, ast.Class supertype, ast.Class mixin);
  bool get strongMode;

  /// Whether or not to include redirecting factories in the output.
  bool get ignoreRedirectingFactories;
}

class DartLoader implements ReferenceLevelLoader {
  final ast.Program program;
  final ApplicationRoot applicationRoot;
  final Bimap<ClassElement, ast.Class> _classes =
      new Bimap<ClassElement, ast.Class>();
  final Bimap<Element, ast.Member> _members = new Bimap<Element, ast.Member>();
  final Map<TypeParameterElement, ast.TypeParameter> _classTypeParameters =
      <TypeParameterElement, ast.TypeParameter>{};
  final Map<ast.Library, Map<String, ast.Class>> _mixinApplications =
      <ast.Library, Map<String, ast.Class>>{};
  final Map<LibraryElement, ast.Library> _libraries =
      <LibraryElement, ast.Library>{};
  final AnalysisContext context;
  LibraryElement _dartCoreLibrary;
  final List errors = [];
  final List libraryElements = [];

  /// Classes that have been referenced, and must be promoted to type level
  /// so as not to expose partially initialized classes.
  final List<ast.Class> temporaryClassWorklist = [];

  final Map<LibraryElement, List<ClassElement>> mixinLibraryWorklist = {};

  final bool ignoreRedirectingFactories;

  LibraryElement _libraryBeingLoaded = null;
  ClassElement _classBeingPromotedToMixin = null;

  bool get strongMode => context.analysisOptions.strongMode;

  DartLoader(this.program, DartOptions options, Packages packages,
      {DartSdk dartSdk,
      AnalysisContext context,
      this.ignoreRedirectingFactories: true})
      : this.context =
            context ?? createContext(options, packages, dartSdk: dartSdk),
        this.applicationRoot = options.applicationRoot;

  String getLibraryName(LibraryElement element) {
    return element.name.isEmpty ? null : element.name;
  }

  LibraryElement getLibraryElementFromUri(Uri uri) {
    var source = context.sourceFactory.forUri2(uri);
    if (source == null) return null;
    return context.computeLibraryElement(source);
  }

  ast.Library getLibraryReference(LibraryElement element) {
    var uri = applicationRoot.relativeUri(element.source.uri);
    var library = _libraries[element];
    if (library == null) {
      library = new ast.Library(uri)
        ..isExternal = true
        ..name = getLibraryName(element)
        ..fileUri = '${element.source.uri}';
      program.libraries.add(library..parent = program);
      _libraries[element] = library;
    }
    return library;
  }

  ast.Library getLibraryReferenceFromUri(Uri uri) {
    return getLibraryReference(getLibraryElementFromUri(uri));
  }

  void _buildTopLevelMember(
      ast.Member member, Element element, Declaration astNode) {
    assert(member.parent != null);
    new MemberBodyBuilder(this, member, element).build(astNode);
  }

  /// True if [element] is in the process of being loaded by
  /// [_buildLibraryBody].
  ///
  /// If this is the case, we should avoid adding new members to the classes
  /// in the library, since the AST builder will rebuild the member lists.
  bool isLibraryBeingLoaded(LibraryElement element) {
    return _libraryBeingLoaded == element;
  }

  bool isClassBeingPromotedToMixin(ClassElement element) {
    return _classBeingPromotedToMixin == element;
  }

  void _buildLibraryBody(LibraryElement element, ast.Library library,
      List<CompilationUnit> units) {
    assert(_libraryBeingLoaded == null);
    _libraryBeingLoaded = element;
    var classes = <ast.Class>[];
    var procedures = <ast.Procedure>[];
    var fields = <ast.Field>[];

    void loadClass(NamedCompilationUnitMember declaration) {
      // [declaration] can be a ClassDeclaration, EnumDeclaration, or a
      // ClassTypeAlias.
      ClassElement element = declaration.element;
      var node = getClassReference(element);
      promoteToBodyLevel(node, element, declaration);
      classes.add(node);
    }

    void loadProcedure(FunctionDeclaration declaration) {
      var element = declaration.element;
      var node = getMemberReference(element);
      _buildTopLevelMember(node, element, declaration);
      procedures.add(node);
    }

    void loadField(TopLevelVariableDeclaration declaration) {
      for (var field in declaration.variables.variables) {
        var element = field.element;
        // Ignore fields inserted through error recovery.
        if (element.name == '') continue;
        var node = getMemberReference(element);
        _buildTopLevelMember(node, element, field);
        fields.add(node);
      }
    }

    for (var unit in units) {
      for (CompilationUnitMember declaration in unit.declarations) {
        if (declaration is ClassDeclaration ||
            declaration is EnumDeclaration ||
            declaration is ClassTypeAlias) {
          loadClass(declaration);
        } else if (declaration is FunctionDeclaration) {
          loadProcedure(declaration);
        } else if (declaration is TopLevelVariableDeclaration) {
          loadField(declaration);
        } else if (declaration is FunctionTypeAlias) {
          // Nothing to do. Typedefs are handled lazily while constructing type
          // references.
        } else {
          throw "unexpected node: ${declaration.runtimeType} $declaration";
        }
      }
    }
    libraryElements.add(element);
    _iterateTemporaryClassWorklist();
    // Ensure everything is stored in the original declaration order.
    library.classes
      ..clear()
      ..addAll(classes)
      ..addAll(_mixinApplications[library]?.values ?? const []);
    library.fields
      ..clear()
      ..addAll(fields);
    library.procedures
      ..clear()
      ..addAll(procedures);
    _libraryBeingLoaded = null;
  }

  LibraryElement getDartCoreLibrary() {
    return _dartCoreLibrary ??= _findLibraryElement('dart:core');
  }

  LibraryElement _findLibraryElement(String uri) {
    var source = context.sourceFactory.forUri(uri);
    if (source == null) return null;
    return context.computeLibraryElement(source);
  }

  ast.Class getRootClassReference() {
    return getCoreClassReference('Object');
  }

  ast.Constructor getRootClassConstructorReference() {
    var element = getDartCoreLibrary().getType('Object').constructors[0];
    return getMemberReference(element);
  }

  ast.Class getCoreClassReference(String className) {
    return getClassReference(getDartCoreLibrary().getType(className));
  }

  ast.Constructor getCoreClassConstructorReference(String className,
      {String constructorName, String library}) {
    LibraryElement libraryElement =
        library != null ? _findLibraryElement(library) : getDartCoreLibrary();
    ClassElement element = libraryElement.getType(className);
    if (element == null) {
      throw 'Missing core class $className from ${libraryElement.name}';
    }
    var constructor = element.constructors.firstWhere((constructor) {
      return (constructorName == null)
          ? (constructor.nameLength == 0)
          : (constructor.name == constructorName);
    });
    return getMemberReference(constructor);
  }

  ClassElement getClassElement(ast.Class node) {
    return _classes.inverse[node];
  }

  void addMixinClassToLibrary(ast.Class class_, ast.Library library) {
    assert(class_.parent == null);
    library.addClass(class_);
    var map =
        _mixinApplications.putIfAbsent(library, () => <String, ast.Class>{});
    map[class_.name] = class_;
  }

  /// Returns the IR for a class, at a temporary loading level.
  ///
  /// The returned class has the correct name, flags, type parameter arity,
  /// and enclosing library.
  ast.Class getClassReference(ClassElement element) {
    var classNode = _classes[element];
    if (classNode != null) return classNode;
    _classes[element] = classNode = new ast.Class(
        name: element.name,
        isAbstract: element.isAbstract,
        fileUri: '${element.source.uri}')..fileOffset = element.nameOffset;
    classNode.level = ast.ClassLevel.Temporary;
    var library = getLibraryReference(element.library);
    library.addClass(classNode);
    // Initialize type parameter list without bounds.
    for (var parameter in element.typeParameters) {
      var parameterNode = new ast.TypeParameter(parameter.name);
      _classTypeParameters[parameter] = parameterNode;
      classNode.typeParameters.add(parameterNode);
      parameterNode.parent = classNode;
    }
    // Ensure the class is at least promoted to type level before exposing it
    // to kernel consumers.
    temporaryClassWorklist.add(classNode);
    return classNode;
  }

  /// Ensures the supertypes and type parameter bounds have been generated for
  /// the given class.
  void promoteToTypeLevel(ast.Class classNode) {
    if (classNode.level.index >= ast.ClassLevel.Type.index) return;
    classNode.level = ast.ClassLevel.Type;
    var element = getClassElement(classNode);
    assert(element != null);
    var library = getLibraryReference(element.library);
    var scope = new ClassScope(this, library);
    // Initialize bounds on type parameters.
    for (int i = 0; i < classNode.typeParameters.length; ++i) {
      var parameter = element.typeParameters[i];
      var parameterNode = classNode.typeParameters[i];
      parameterNode.bound = parameter.bound == null
          ? scope.defaultTypeParameterBound
          : scope.buildType(parameter.bound);
    }
    // Initialize supertypes.
    Iterable<InterfaceType> mixins = element.mixins;
    if (element.isMixinApplication && mixins.isNotEmpty) {
      classNode.mixedInType = scope.buildSupertype(mixins.last);
      mixins = mixins.take(mixins.length - 1);
    }
    if (element.supertype != null) {
      ast.Supertype supertype = scope.buildSupertype(element.supertype);
      bool useSharedMixin = true;
      for (var mixin in mixins) {
        var mixinType = scope.buildSupertype(mixin);
        if (useSharedMixin &&
            areDistinctUnboundTypeVariables(supertype, mixinType)) {
          // Use a shared mixin application class for this library.
          var mixinClass = getSharedMixinApplicationClass(
              scope.currentLibrary, supertype.classNode, mixinType.classNode);
          if (mixinClass.fileOffset < 0) {
            mixinClass.fileOffset = element.nameOffset;
          }
          supertype = new ast.Supertype(
              mixinClass,
              supertype.typeArguments.length > mixinType.typeArguments.length
                  ? supertype.typeArguments
                  : mixinType.typeArguments);
        } else {
          // Generate a new class specific for this mixin application.
          var freshParameters =
              getFreshTypeParameters(classNode.typeParameters);
          var mixinClass = new ast.Class(
              name: '${classNode.name}^${mixinType.classNode.name}',
              isAbstract: true,
              typeParameters: freshParameters.freshTypeParameters,
              supertype: freshParameters.substituteSuper(supertype),
              mixedInType: freshParameters.substituteSuper(mixinType),
              fileUri: classNode.fileUri)..fileOffset = element.nameOffset;
          mixinClass.level = ast.ClassLevel.Type;
          addMixinClassToLibrary(mixinClass, classNode.enclosingLibrary);
          supertype = new ast.Supertype(mixinClass,
              classNode.typeParameters.map(makeTypeParameterType).toList());
          // This class cannot be used from anywhere else, so don't try to
          // generate shared mixin applications using it.
          useSharedMixin = false;
        }
      }
      classNode.supertype = supertype;
      for (var implementedType in element.interfaces) {
        classNode.implementedTypes.add(scope.buildSupertype(implementedType));
      }
    }
  }

  void promoteToHierarchyLevel(ast.Class classNode) {
    if (classNode.level.index >= ast.ClassLevel.Hierarchy.index) return;
    promoteToTypeLevel(classNode);
    classNode.level = ast.ClassLevel.Hierarchy;
    var element = getClassElement(classNode);
    if (element != null) {
      // Ensure all instance members are at present.
      for (var field in element.fields) {
        if (!field.isStatic && !field.isSynthetic) {
          getMemberReference(field);
        }
      }
      for (var accessor in element.accessors) {
        if (!accessor.isStatic && !accessor.isSynthetic) {
          getMemberReference(accessor);
        }
      }
      for (var method in element.methods) {
        if (!method.isStatic && !method.isSynthetic) {
          getMemberReference(method);
        }
      }
    }
    for (var supertype in classNode.supers) {
      promoteToHierarchyLevel(supertype.classNode);
    }
  }

  void promoteToMixinLevel(ast.Class classNode, ClassElement element,
      NamedCompilationUnitMember astNode) {
    if (classNode.level.index >= ast.ClassLevel.Mixin.index) return;
    _classBeingPromotedToMixin = element;
    promoteToHierarchyLevel(classNode);
    classNode.level = ast.ClassLevel.Mixin;
    // Clear out the member references that were put in the class.
    // The AST builder will load them all put back in the right order.
    classNode..fields.clear()..procedures.clear()..constructors.clear();
    new ClassBodyBuilder(this, classNode, element).build(astNode);
    _classBeingPromotedToMixin = null;

    // Ensure mixed-in classes are available.
    for (var mixin in element.mixins) {
      _ensureMixinBecomesLoaded(mixin.element);
    }
  }

  /// Ensures that [element] eventually becomes loaded at least at mixin level.
  void _ensureMixinBecomesLoaded(ClassElement element) {
    if (isClassBeingPromotedToMixin(element)) {
      return;
    }
    var class_ = getClassReference(element);
    if (class_.level.index >= ast.ClassLevel.Mixin.index) {
      return;
    }
    var list = mixinLibraryWorklist[element.library] ??= <ClassElement>[];
    list.add(element);
  }

  void promoteToBodyLevel(ast.Class classNode, ClassElement element,
      NamedCompilationUnitMember astNode) {
    if (classNode.level == ast.ClassLevel.Body) return;
    promoteToMixinLevel(classNode, element, astNode);
    classNode.level = ast.ClassLevel.Body;
    // This frontend delivers the same contents for classes at body and mixin
    // levels, even though as specified, the mixin level does not require all
    // the static members to be present.  So no additional work is needed.
  }

  ast.TypeParameter tryGetClassTypeParameter(TypeParameterElement element) {
    return _classTypeParameters[element];
  }

  Element getMemberElement(ast.Member node) {
    return _members.inverse[node];
  }

  ast.Member getMemberReference(Element element) {
    assert(element != null);
    assert(element is! Member); // Use the "base element".
    return _members[element] ??= _buildMemberReference(element);
  }

  ast.Member _buildMemberReference(Element element) {
    assert(element != null);
    var member = _buildOrphanedMemberReference(element);
    // Set the parent pointer and store it in the enclosing class or library.
    // If the enclosing library is being built from the AST, do not add the
    // member, since the AST builder will put it in there.
    var parent = element.enclosingElement;
    if (parent is ClassElement) {
      var class_ = getClassReference(parent);
      member.parent = class_;
      if (!isLibraryBeingLoaded(element.library)) {
        class_.addMember(member);
      }
    } else {
      var library = getLibraryReference(element.library);
      member.parent = library;
      if (!isLibraryBeingLoaded(element.library)) {
        library.addMember(member);
      }
    }
    return member;
  }

  ast.Member _buildOrphanedMemberReference(Element element) {
    assert(element != null);
    ClassElement classElement = element.enclosingElement is ClassElement
        ? element.enclosingElement
        : null;
    TypeScope scope = classElement != null
        ? new ClassScope(this, getLibraryReference(element.library))
        : new TypeScope(this);
    if (classElement != null) {
      getClassReference(classElement);
    }
    switch (element.kind) {
      case ElementKind.CONSTRUCTOR:
        ConstructorElement constructor = element;
        if (constructor.isFactory) {
          return new ast.Procedure(
              _nameOfMember(constructor),
              ast.ProcedureKind.Factory,
              scope.buildFunctionInterface(constructor),
              isAbstract: false,
              isStatic: true,
              isExternal: constructor.isExternal,
              isConst: constructor.isConst,
              fileUri: '${element.source.uri}')
            ..fileOffset = element.nameOffset;
        }
        return new ast.Constructor(scope.buildFunctionInterface(constructor),
            name: _nameOfMember(element),
            isConst: constructor.isConst,
            isExternal: constructor.isExternal)
          ..fileOffset = element.nameOffset;

      case ElementKind.FIELD:
      case ElementKind.TOP_LEVEL_VARIABLE:
        VariableElement variable = element;
        return new ast.Field(_nameOfMember(variable),
            isStatic: variable.isStatic,
            isFinal: variable.isFinal,
            isConst: variable.isConst,
            type: scope.buildType(variable.type),
            fileUri: '${element.source.uri}')..fileOffset = element.nameOffset;

      case ElementKind.METHOD:
      case ElementKind.GETTER:
      case ElementKind.SETTER:
      case ElementKind.FUNCTION:
        if (element is FunctionElement &&
            element.enclosingElement is! CompilationUnitElement) {
          throw 'Function $element is nested in ${element.enclosingElement} '
              'and hence is not a member';
        }
        ExecutableElement executable = element;
        return new ast.Procedure(
            _nameOfMember(element),
            _procedureKindOf(executable),
            scope.buildFunctionInterface(executable),
            isAbstract: executable.isAbstract,
            isStatic: executable.isStatic,
            isExternal: executable.isExternal,
            fileUri: '${element.source.uri}')..fileOffset = element.nameOffset;

      default:
        throw 'Unexpected member kind: $element';
    }
  }

  ast.ProcedureKind _procedureKindOf(ExecutableElement element) {
    if (element is PropertyAccessorElement) {
      return element.isGetter
          ? ast.ProcedureKind.Getter
          : ast.ProcedureKind.Setter;
    }
    if (element is MethodElement) {
      if (element.isOperator) return ast.ProcedureKind.Operator;
      return ast.ProcedureKind.Method;
    }
    if (element is FunctionElement) {
      return ast.ProcedureKind.Method;
    }
    if (element is ConstructorElement) {
      assert(element.isFactory);
      return ast.ProcedureKind.Factory;
    }
    throw 'Unexpected procedure: $element';
  }

  ast.Name _nameOfMember(Element element) {
    // Use 'displayName' to avoid a trailing '=' for setters and 'name' to
    // ensure unary minus is called 'unary-'.
    String name =
        element is PropertyAccessorElement ? element.displayName : element.name;
    return new ast.Name(name, getLibraryReference(element.library));
  }

  /// True if the two types have form `C<T1 ... Tm>` and `D<T1 ... Tn>`, and
  /// `T1 ... TN` are distinct type variables with no upper bound, where
  /// `N = max(m,n)`.
  bool areDistinctUnboundTypeVariables(
      ast.Supertype first, ast.Supertype second) {
    var seen = new Set<ast.TypeParameter>();
    if (first.typeArguments.length < second.typeArguments.length) {
      var tmp = first;
      first = second;
      second = tmp;
    }
    for (int i = 0; i < first.typeArguments.length; ++i) {
      var firstArg = first.typeArguments[i];
      if (!(firstArg is ast.TypeParameterType &&
          seen.add(firstArg.parameter) &&
          firstArg.parameter.bound is ast.DynamicType)) {
        return false;
      }
      if (i < second.typeArguments.length &&
          firstArg != second.typeArguments[i]) {
        return false;
      }
    }
    return true;
  }

  /// Returns the canonical mixin application of two classes, instantiated with
  /// the same list of unbound type variables.
  ///
  /// Given two classes:
  ///     class C<C1 ... Cm>
  ///     class D<D1 ... Dn>
  ///
  /// This creates or reuses a mixin application class in the library of form:
  ///
  ///     abstract class C&D<T1 ... TN> = C<T1 ... Tm> with D<T1 ... Tn>
  ///
  /// where `N = max(m,n)`.
  ///
  /// Such a class can in general contain type errors due to incompatible
  /// inheritance from `C` and `D`.  This method therefore should only be called
  /// if a mixin application `C<S1 ... Sm> with D<S1 ... Sn>` is seen, where
  /// `S1 ... SN` are distinct, unbound type variables.
  ast.Class getSharedMixinApplicationClass(
      ast.Library library, ast.Class superclass, ast.Class mixedInClass) {
    // TODO(asgerf): Avoid potential name clash due to associativity.
    // As it is, these mixins get the same name:
    //   (A with B) with C
    //   A with (B with C)
    String name = '${superclass.name}&${mixedInClass.name}';
    return _mixinApplications
        .putIfAbsent(library, () => <String, ast.Class>{})
        .putIfAbsent(name, () {
      var fresh =
          superclass.typeParameters.length >= mixedInClass.typeParameters.length
              ? getFreshTypeParameters(superclass.typeParameters)
              : getFreshTypeParameters(mixedInClass.typeParameters);
      var typeArguments =
          fresh.freshTypeParameters.map(makeTypeParameterType).toList();
      var superArgs = typeArguments.length != superclass.typeParameters.length
          ? typeArguments.sublist(0, superclass.typeParameters.length)
          : typeArguments;
      var mixinArgs = typeArguments.length != mixedInClass.typeParameters.length
          ? typeArguments.sublist(0, mixedInClass.typeParameters.length)
          : typeArguments;
      var result = new ast.Class(
          name: name,
          isAbstract: true,
          typeParameters: fresh.freshTypeParameters,
          supertype: new ast.Supertype(superclass, superArgs),
          mixedInType: new ast.Supertype(mixedInClass, mixinArgs),
          fileUri: library.fileUri);
      result.level = ast.ClassLevel.Type;
      library.addClass(result);
      return result;
    });
  }

  String formatErrorMessage(
      AnalysisError error, String filename, LineInfo lines) {
    var location = lines.getLocation(error.offset);
    return '[error] ${error.message} ($filename, '
        'line ${location.lineNumber}, '
        'col ${location.columnNumber})';
  }

  void ensureLibraryIsLoaded(ast.Library node) {
    _ensureLibraryIsLoaded(node);
    _iterateMixinLibraryWorklist();
  }

  void _ensureLibraryIsLoaded(ast.Library node) {
    if (!node.isExternal) return;
    node.isExternal = false;
    var source = context.sourceFactory
        .forUri2(applicationRoot.absoluteUri(node.importUri));
    assert(source != null);
    var element = context.computeLibraryElement(source);
    var units = <CompilationUnit>[];
    bool reportErrors = node.importUri.scheme != 'dart';
    var tree = context.resolveCompilationUnit(source, element);
    units.add(tree);
    if (reportErrors) _processErrors(source);
    for (var part in element.parts) {
      var source = part.source;
      units.add(context.resolveCompilationUnit(source, element));
      if (reportErrors) _processErrors(source);
    }
    _buildLibraryBody(element, node, units);
  }

  void _processErrors(Source source) {
    LineInfo lines;
    for (var error in context.computeErrors(source)) {
      if (error.errorCode is CompileTimeErrorCode ||
          error.errorCode is ParserErrorCode ||
          error.errorCode is ScannerErrorCode ||
          error.errorCode is StrongModeCode) {
        lines ??= context.computeLineInfo(source);
        errors.add(formatErrorMessage(error, source.shortName, lines));
      }
    }
  }

  void loadSdkInterface(ast.Program program, Target target) {
    var requiredSdkMembers = target.requiredSdkClasses;
    for (var libraryUri in requiredSdkMembers.keys) {
      var source = context.sourceFactory.forUri2(Uri.parse(libraryUri));
      var libraryElement = context.computeLibraryElement(source);
      for (var member in requiredSdkMembers[libraryUri]) {
        var type = libraryElement.getType(member);
        if (type == null) {
          throw 'Could not find $member in $libraryUri';
        }
        promoteToTypeLevel(getClassReference(type));
      }
    }
    _iterateTemporaryClassWorklist();
    _iterateMixinLibraryWorklist();
  }

  void loadEverything({Target target, bool compileSdk}) {
    compileSdk ??= true;
    if (compileSdk) {
      ensureLibraryIsLoaded(getLibraryReference(getDartCoreLibrary()));
      if (target != null) {
        for (var uri in target.extraRequiredLibraries) {
          var library = _findLibraryElement(uri);
          if (library == null) {
            errors.add('Could not find required library $uri');
            continue;
          }
          ensureLibraryIsLoaded(getLibraryReference(library));
        }
      }
    }
    for (int i = 0; i < program.libraries.length; ++i) {
      var library = program.libraries[i];
      if (compileSdk || library.importUri.scheme != 'dart') {
        ensureLibraryIsLoaded(library);
      }
    }
  }

  /// Builds a list of sources that have been loaded.
  ///
  /// This operation may be expensive and should only be used for diagnostics.
  List<String> getLoadedFileNames() {
    var list = <String>[];
    for (var library in program.libraries) {
      LibraryElement element = context.computeLibraryElement(context
          .sourceFactory
          .forUri2(applicationRoot.absoluteUri(library.importUri)));
      for (var unit in element.units) {
        list.add(unit.source.fullName);
      }
    }
    return list;
  }

  void _iterateTemporaryClassWorklist() {
    while (temporaryClassWorklist.isNotEmpty) {
      var element = temporaryClassWorklist.removeLast();
      promoteToTypeLevel(element);
    }
  }

  void _iterateMixinLibraryWorklist() {
    // The worklist groups classes in the same library together so that we
    // request resolved ASTs for each library only once.
    while (mixinLibraryWorklist.isNotEmpty) {
      LibraryElement library = mixinLibraryWorklist.keys.first;
      _libraryBeingLoaded = library;
      List<ClassElement> classes = mixinLibraryWorklist.remove(library);
      for (var class_ in classes) {
        var classNode = getClassReference(class_);
        promoteToMixinLevel(classNode, class_, class_.computeNode());
      }
      _libraryBeingLoaded = null;
    }
    _iterateTemporaryClassWorklist();
  }

  ast.Procedure _getMainMethod(Uri uri) {
    Source source = context.sourceFactory.forUri2(uri);
    LibraryElement library = context.computeLibraryElement(source);
    var mainElement = library.entryPoint;
    if (mainElement == null) return null;
    var mainMember = getMemberReference(mainElement);
    if (mainMember is ast.Procedure && !mainMember.isAccessor) {
      return mainMember;
    }
    // Top-level 'main' getters are not supported at the moment.
    return null;
  }

  ast.Procedure _makeMissingMainMethod(ast.Library library) {
    var main = new ast.Procedure(
        new ast.Name('main'),
        ast.ProcedureKind.Method,
        new ast.FunctionNode(new ast.ExpressionStatement(new ast.Throw(
            new ast.StringLiteral('Program has no main method')))),
        isStatic: true)..fileUri = library.fileUri;
    library.addMember(main);
    return main;
  }

  void loadProgram(Uri mainLibrary, {Target target, bool compileSdk}) {
    ast.Library library = getLibraryReferenceFromUri(mainLibrary);
    ensureLibraryIsLoaded(library);
    var mainMethod = _getMainMethod(mainLibrary);
    loadEverything(target: target, compileSdk: compileSdk);
    if (mainMethod == null) {
      mainMethod = _makeMissingMainMethod(library);
    }
    program.mainMethod = mainMethod;
    for (LibraryElement libraryElement in libraryElements) {
      for (CompilationUnitElement compilationUnitElement
          in libraryElement.units) {
        var source = compilationUnitElement.source;
        LineInfo lineInfo = context.computeLineInfo(source);
        List<int> sourceCode;
        try {
          sourceCode =
              const Utf8Encoder().convert(context.getContents(source).data);
        } catch (e) {
          // The source's contents could not be accessed.
          sourceCode = const <int>[];
        }
        program.uriToSource['${source.uri}'] =
            new ast.Source(lineInfo.lineStarts, sourceCode);
      }
    }
  }

  ast.Library loadLibrary(Uri uri) {
    ast.Library library = getLibraryReferenceFromUri(uri);
    ensureLibraryIsLoaded(library);
    return library;
  }
}

class Bimap<K, V> {
  final Map<K, V> nodeMap = <K, V>{};
  final Map<V, K> inverse = <V, K>{};

  bool containsKey(K key) => nodeMap.containsKey(key);

  V operator [](K key) => nodeMap[key];

  void operator []=(K key, V value) {
    assert(!nodeMap.containsKey(key));
    nodeMap[key] = value;
    inverse[value] = key;
  }
}

/// Creates [DartLoader]s for a given configuration, while reusing the
/// [DartSdk] and [Packages] object if possible.
class DartLoaderBatch {
  Packages packages;
  DartSdk dartSdk;

  String lastSdk;
  String lastPackagePath;
  bool lastStrongMode;

  Future<DartLoader> getLoader(ast.Program program, DartOptions options,
      {String packageDiscoveryPath}) async {
    if (dartSdk == null ||
        lastSdk != options.sdk ||
        lastStrongMode != options.strongMode) {
      lastSdk = options.sdk;
      lastStrongMode = options.strongMode;
      dartSdk = createDartSdk(options.sdk, strongMode: options.strongModeSdk);
    }
    if (packages == null ||
        lastPackagePath != options.packagePath ||
        packageDiscoveryPath != null) {
      lastPackagePath = options.packagePath;
      packages = await createPackages(options.packagePath,
          discoveryPath: packageDiscoveryPath);
    }
    return new DartLoader(program, options, packages, dartSdk: dartSdk);
  }
}

Future<Packages> createPackages(String packagePath,
    {String discoveryPath}) async {
  if (packagePath != null) {
    var absolutePath = new io.File(packagePath).absolute.path;
    if (await new io.Directory(packagePath).exists()) {
      return getPackagesDirectory(new Uri.file(absolutePath));
    } else if (await new io.File(packagePath).exists()) {
      return loadPackagesFile(new Uri.file(absolutePath));
    } else {
      throw 'Packages not found: $packagePath';
    }
  }
  if (discoveryPath != null) {
    return findPackagesFromFile(Uri.parse(discoveryPath));
  }
  return Packages.noPackages;
}

AnalysisOptions createAnalysisOptions(bool strongMode) {
  return new AnalysisOptionsImpl()
    ..strongMode = strongMode
    ..generateImplicitErrors = false
    ..generateSdkErrors = false
    ..preserveComments = false
    ..hint = false
    ..enableSuperMixins = true;
}

DartSdk createDartSdk(String path, {bool strongMode, bool isSummary}) {
  if (isSummary ?? false) {
    return new SummaryBasedDartSdk(path, strongMode);
  }
  var resources = PhysicalResourceProvider.INSTANCE;
  return new FolderBasedDartSdk(resources, resources.getFolder(path))
    ..context
        .analysisOptions
        .setCrossContextOptionsFrom(createAnalysisOptions(strongMode));
}

class CustomUriResolver extends UriResolver {
  final ResourceUriResolver _resourceUriResolver;
  final Map<Uri, Uri> _customUrlMappings;

  CustomUriResolver(this._resourceUriResolver, this._customUrlMappings);

  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    // TODO(kustermann): Once dartk supports configurable imports we should be
    // able to get rid of this.
    if (uri.toString() == 'package:mojo/src/internal_contract.dart') {
      uri = actualUri = Uri.parse('dart:mojo.internal');
    }

    Uri baseUri = uri;
    String relative;
    String path = uri.path;
    int index = path.indexOf('/');
    if (index > 0) {
      baseUri = uri.replace(path: path.substring(0, index));
      relative = path.substring(index + 1);
    }
    Uri baseMapped = _customUrlMappings[baseUri];
    if (baseMapped == null) return null;

    Uri mapped = relative != null ? baseMapped.resolve(relative) : baseMapped;
    return _resourceUriResolver.resolveAbsolute(mapped, actualUri);
  }

  Uri restoreAbsolute(Source source) {
    return _resourceUriResolver.restoreAbsolute(source);
  }
}

AnalysisContext createContext(DartOptions options, Packages packages,
    {DartSdk dartSdk}) {
  bool fromSummary = options.sdkSummary != null;
  dartSdk ??= createDartSdk(fromSummary ? options.sdkSummary : options.sdk,
      strongMode: options.strongModeSdk, isSummary: fromSummary);

  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var resourceUriResolver = new ResourceUriResolver(resourceProvider);
  List<UriResolver> resolvers = [];
  var customUriMappings = options.customUriMappings;
  if (customUriMappings != null && customUriMappings.length > 0) {
    resolvers
        .add(new CustomUriResolver(resourceUriResolver, customUriMappings));
  }
  resolvers.add(new DartUriResolver(dartSdk));
  resolvers.add(resourceUriResolver);

  if (packages != null) {
    var folderMap = <String, List<Folder>>{};
    packages.asMap().forEach((String packagePath, Uri uri) {
      String path = resourceProvider.pathContext.fromUri(uri);
      folderMap[packagePath] = [resourceProvider.getFolder(path)];
    });
    resolvers.add(new PackageMapUriResolver(resourceProvider, folderMap));
  }

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers)
    ..analysisOptions = createAnalysisOptions(options.strongMode);

  options.declaredVariables.forEach((String name, String value) {
    context.declaredVariables.define(name, value);
  });

  return context;
}
