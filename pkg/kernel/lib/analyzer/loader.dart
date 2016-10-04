// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.analyzer.loader;

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';

import '../ast.dart' as ast;
import '../repository.dart';
import '../target/targets.dart' show Target;
import '../type_algebra.dart';
import 'analyzer.dart';
import 'ast_from_analyzer.dart';

/// Options passed to the Dart frontend.
class DartOptions {
  bool strongMode;
  String sdk;
  String packagePath;
  Map<Uri, Uri> customUriMappings;
  Map<String, String> declaredVariables;

  DartOptions(
      {this.strongMode: false,
      this.sdk,
      this.packagePath,
      Map<Uri, Uri> customUriMappings,
      Map<String, String> declaredVariables})
      : this.customUriMappings = customUriMappings ?? <Uri, Uri>{},
        this.declaredVariables = declaredVariables ?? <String, String>{};
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
  ast.Class getMixinApplicationClass(
      ast.Library library, ast.Class supertype, ast.Class mixin);
  bool get strongMode;
}

class DartLoader implements ReferenceLevelLoader {
  final Repository repository;
  final Bimap<ClassElement, ast.Class> _classes =
      new Bimap<ClassElement, ast.Class>();
  final Bimap<Element, ast.Member> _members = new Bimap<Element, ast.Member>();
  final Map<TypeParameterElement, ast.TypeParameter> _classTypeParameters =
      <TypeParameterElement, ast.TypeParameter>{};
  final Map<ast.Library, Map<String, ast.Class>> _mixinApplications =
      <ast.Library, Map<String, ast.Class>>{};
  final AnalysisContext context;
  LibraryElement _dartCoreLibrary;
  final List errors = [];
  final List libraryElements = [];

  /// Classes that have been referenced, and must be promoted to type level
  /// so as not to expose partially initialized classes.
  final List<ast.Class> temporaryClassWorklist = [];

  LibraryElement _libraryBeingLoaded = null;

  bool get strongMode => context.analysisOptions.strongMode;

  DartLoader(this.repository, DartOptions options, Packages packages,
      {DartSdk dartSdk})
      : this.context = createContext(options, packages, dartSdk: dartSdk);

  LibraryElement getLibraryElement(ast.Library node) {
    return context
        .getLibraryElement(context.sourceFactory.forUri2(node.importUri));
  }

  String getLibraryName(LibraryElement element) {
    return element.name.isEmpty ? null : element.name;
  }

  ast.Library getLibraryReference(LibraryElement element) {
    return repository.getLibraryReference(element.source.uri)
      ..name ??= getLibraryName(element)
      ..fileUri = "file://${element.source.fullName}";
  }

  void _buildTopLevelMember(ast.Member member, Element element) {
    var astNode = element.computeNode();
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

  void _buildLibraryBody(LibraryElement element, ast.Library library) {
    assert(_libraryBeingLoaded == null);
    _libraryBeingLoaded = element;
    var classes = <ast.Class>[];
    var procedures = <ast.Procedure>[];
    var fields = <ast.Field>[];
    void loadClass(ClassElement classElement) {
      var node = getClassReference(classElement);
      promoteToBodyLevel(node);
      classes.add(node);
    }
    void loadProcedure(Element memberElement) {
      var node = getMemberReference(memberElement);
      _buildTopLevelMember(node, memberElement);
      procedures.add(node);
    }
    void loadField(Element memberElement) {
      var node = getMemberReference(memberElement);
      _buildTopLevelMember(node, memberElement);
      fields.add(node);
    }
    for (var unit in element.units) {
      unit.types.forEach(loadClass);
      unit.enums.forEach(loadClass);
      for (var accessor in unit.accessors) {
        if (!accessor.isSynthetic) {
          loadProcedure(accessor);
        }
      }
      for (var function in unit.functions) {
        loadProcedure(function);
      }
      for (var field in unit.topLevelVariables) {
        if (!field.isSynthetic) {
          loadField(field);
        }
      }
    }
    libraryElements.add(element);
    _iterateWorklist();
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

  /// Returns the IR for a class, at a temporary loading level.
  ///
  /// The returned class has the correct name, flags, type parameter arity,
  /// and enclosing library.
  ast.Class getClassReference(ClassElement element) {
    var classNode = _classes[element];
    if (classNode != null) return classNode;
    _classes[element] = classNode =
        new ast.Class(name: element.name, isAbstract: element.isAbstract,
        fileUri: "file://${element.source.fullName}");
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
          ? const ast.DynamicType()
          : scope.buildType(parameter.bound);
    }
    // Initialize supertypes.
    Iterable<InterfaceType> mixins = element.mixins;
    if (element.isMixinApplication && mixins.isNotEmpty) {
      var last = scope.buildType(mixins.last);
      if (last is ast.InterfaceType) {
        classNode.mixedInType = last;
      }
      mixins = mixins.take(mixins.length - 1);
    }
    if (element.supertype != null) {
      ast.InterfaceType supertype = scope.buildType(element.supertype);
      for (var mixin in mixins) {
        var mixinType = scope.buildType(mixin);
        if (mixinType is ast.InterfaceType) {
          var mixinClass = getMixinApplicationClass(
              library, supertype.classNode, mixinType.classNode);
          var typeArguments = <ast.DartType>[]
            ..addAll(supertype.typeArguments)
            ..addAll(mixinType.typeArguments);
          supertype = new ast.InterfaceType(mixinClass, typeArguments);
        }
      }
      classNode.supertype = supertype;
      for (var implementedType in element.interfaces) {
        classNode.implementedTypes.add(scope.buildType(implementedType));
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

  void promoteToBodyLevel(ast.Class classNode) {
    if (classNode.level == ast.ClassLevel.Body) return;
    promoteToHierarchyLevel(classNode);
    classNode.level = ast.ClassLevel.Body;
    var element = getClassElement(classNode);
    if (element == null) return;
    var astNode = element.computeNode();
    // Clear out the member references that were put in the class.
    // The AST builder will load them all put back in the right order.
    classNode..fields.clear()..procedures.clear()..constructors.clear();
    new ClassBodyBuilder(this, classNode, element).build(astNode);
  }

  ast.TypeParameter tryGetClassTypeParameter(TypeParameterElement element) {
    return _classTypeParameters[element];
  }

  Element getMemberElement(ast.Member node) {
    return _members.inverse[node];
  }

  ast.Member getMemberReference(Element element) {
    assert(element is! Member); // Use the "base element".
    return _members[element] ??= _buildMemberReference(element);
  }

  ast.Member _buildMemberReference(Element element) {
    var node = _buildOrphanedMemberReference(element);
    // Set the parent pointer and store it in the enclosing class or library.
    // If the enclosing library is being built from the AST, do not add the
    // member, since the AST builder will put it in there.
    var parent = element.enclosingElement;
    if (parent is ClassElement) {
      var class_ = getClassReference(parent);
      node.parent = class_;
      if (!isLibraryBeingLoaded(element.library)) {
        class_.addMember(node);
      }
    } else {
      var library = getLibraryReference(element.library);
      node.parent = library;
      if (!isLibraryBeingLoaded(element.library)) {
        library.addMember(node);
      }
    }
    return node;
  }

  ast.Member _buildOrphanedMemberReference(Element element) {
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
              fileUri: "file://${element.source.fullName}");
        }
        return new ast.Constructor(scope.buildFunctionInterface(constructor),
            name: _nameOfMember(element),
            isConst: constructor.isConst,
            isExternal: constructor.isExternal);

      case ElementKind.FIELD:
      case ElementKind.TOP_LEVEL_VARIABLE:
        VariableElement variable = element;
        return new ast.Field(_nameOfMember(variable),
            isStatic: variable.isStatic,
            isFinal: variable.isFinal,
            isConst: variable.isConst,
            type: scope.buildType(variable.type),
            fileUri: "file://${element.source.fullName}")
          ..fileOffset = element.nameOffset;

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
            fileUri: "file://${element.source.fullName}");

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

  /// Returns the canonical mixin application of [superclass] and [mixedInClass]
  /// in the given [library].
  ast.Class getMixinApplicationClass(
      ast.Library library, ast.Class superclass, ast.Class mixedInClass) {
    // TODO(asgerf): Avoid potential name clash due to associativity.
    // As it is, these mixins get the same name:
    //   (A with B) with C
    //   A with (B with C)
    String name = '${superclass.name}&${mixedInClass.name}';
    return _mixinApplications
        .putIfAbsent(library, () => <String, ast.Class>{})
        .putIfAbsent(name, () {
      List<ast.TypeParameter> typeParameters = <ast.TypeParameter>[];
      ast.InterfaceType makeSuper(ast.Class class_) {
        if (class_.typeParameters.isEmpty) return class_.rawType;
        // We need to copy over type parameters from the given super type,
        // including its bounds.  We handle two cases separately:
        //
        //   1. The super class is derived from a ClassElement.
        //      At this point, the IR node cannot be assumed to have its type
        //      parameter bounds initialized.
        //      Build the type parameters based on the element model.
        //
        //   2. The super class is a mixin application previously created here.
        //      In this case, there does not exist a corresponding ClassElement.
        //      However, we know the class has its type parameter bounds
        //      already initialized since it was created here.
        //      Copy the type parameters based on the IR of the super class.
        //
        ClassElement element = getClassElement(class_);
        if (element != null) {
          var scope = new TypeScope(this);
          // Build type parameter objects and put them in our local scope.
          for (var parameter in element.typeParameters) {
            var parameterNode = new ast.TypeParameter(parameter.name);
            scope.localTypeParameters[parameter] = parameterNode;
            typeParameters.add(parameterNode);
          }
          // Build the bounds, with all the type parameters in scope.
          for (var parameter in element.typeParameters) {
            if (parameter.bound != null) {
              var parameterNode = scope.getTypeParameterReference(parameter);
              parameterNode.bound = scope.buildType(parameter.bound);
            }
          }
          return scope.buildType(element.type);
        } else {
          // Build copies of the existing type parameters.
          var parameters = getFreshTypeParameters(class_.typeParameters);
          typeParameters.addAll(parameters.freshTypeParameters);
          return parameters.substitute(class_.thisType);
        }
      }
      var supertype = makeSuper(superclass);
      var mixedInType = makeSuper(mixedInClass);
      var result = new ast.Class(
          name: name,
          typeParameters: typeParameters,
          supertype: supertype,
          mixedInType: mixedInType,
          fileUri: mixedInClass.fileUri);
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
    if (!node.isExternal) return;
    node.isExternal = false;
    var source = context.sourceFactory.forUri2(node.importUri);
    assert(source != null);
    var element = context.computeLibraryElement(source);
    context.resolveCompilationUnit(source, element);
    _buildLibraryBody(element, node);
    if (node.importUri.scheme != 'dart') {
      for (var unit in element.units) {
        LineInfo lines;
        for (var error in context.computeErrors(unit.source)) {
          if (error.errorCode is CompileTimeErrorCode ||
              error.errorCode is ParserErrorCode ||
              error.errorCode is ScannerErrorCode ||
              error.errorCode is StrongModeCode) {
            lines ??= context.computeLineInfo(source);
            errors.add(formatErrorMessage(error, source.shortName, lines));
          }
        }
      }
    }
  }

  void loadEverything({Target target}) {
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
    for (int i = 0; i < repository.libraries.length; ++i) {
      ensureLibraryIsLoaded(repository.libraries[i]);
    }
  }

  /// Builds a list of sources that have been loaded.
  ///
  /// This operation may be expensive and should only be used for diagnostics.
  List<String> getLoadedFileNames() {
    var list = <String>[];
    for (var library in repository.libraries) {
      LibraryElement element = context.computeLibraryElement(
          context.sourceFactory.forUri2(library.importUri));
      for (var unit in element.units) {
        list.add(unit.source.fullName);
      }
    }
    return list;
  }

  void _iterateWorklist() {
    while (temporaryClassWorklist.isNotEmpty) {
      var element = temporaryClassWorklist.removeLast();
      promoteToTypeLevel(element);
    }
  }

  ast.Program loadProgram(String mainLibrary, {Target target}) {
    ast.Library library = repository.getLibrary(mainLibrary);
    ensureLibraryIsLoaded(library);
    loadEverything(target: target);
    var program = new ast.Program(repository.libraries);
    program.mainMethod = library.procedures.firstWhere(
        (member) => member.name?.name == 'main',
        orElse: () => null);
    for (LibraryElement libraryElement in libraryElements) {
      for (CompilationUnitElement compilationUnitElement
          in libraryElement.units) {
        // TODO(jensj): Get this another way?
        LineInfo lineInfo = compilationUnitElement.computeNode().lineInfo;
        program.uriToLineStarts[
                "file://${compilationUnitElement.source.source.fullName}"] =
            new List<int>.generate(lineInfo.lineCount, lineInfo.getOffsetOfLine,
                growable: false);
      }
    }
    return program;
  }

  ast.Library loadLibrary(String mainLibrary) {
    ast.Library library = repository.getLibrary(mainLibrary);
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

  Future<DartLoader> getLoader(Repository repository, DartOptions options,
      {String packageDiscoveryPath}) async {
    if (dartSdk == null ||
        lastSdk != options.sdk ||
        lastStrongMode != options.strongMode) {
      lastSdk = options.sdk;
      lastStrongMode = options.strongMode;
      dartSdk = createDartSdk(options.sdk, strongMode: options.strongMode);
    }
    if (packages == null ||
        lastPackagePath != options.packagePath ||
        packageDiscoveryPath != null) {
      lastPackagePath = options.packagePath;
      packages = await createPackages(options.packagePath,
          discoveryPath: packageDiscoveryPath);
    }
    return new DartLoader(repository, options, packages, dartSdk: dartSdk);
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
    ..enableGenericMethods = strongMode
    ..generateImplicitErrors = false
    ..generateSdkErrors = false
    ..preserveComments = false
    ..hint = false
    ..enableSuperMixins = true;
}

DartSdk createDartSdk(String path, {bool strongMode}) {
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
  dartSdk ??= createDartSdk(options.sdk, strongMode: options.strongMode);

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
