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
      : this.customUriMappings = <Uri, Uri>{},
        this.declaredVariables = <String, String>{};
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
  final LoadMap<ClassElement, ast.Class> _classes =
      new LoadMap<ClassElement, ast.Class>();
  final LoadMap<Element, ast.Member> _members =
      new LoadMap<Element, ast.Member>();
  final Map<TypeParameterElement, ast.TypeParameter> _classTypeParameters =
      <TypeParameterElement, ast.TypeParameter>{};
  final Map<ast.Library, Map<String, ast.Class>> _mixinApplications =
      <ast.Library, Map<String, ast.Class>>{};
  final AnalysisContext context;
  LibraryElement _dartCoreLibrary;
  final List errors = [];

  bool get strongMode => context.analysisOptions.strongMode;

  DartLoader(this.repository, DartOptions options, Packages packages,
      {DartSdk dartSdk})
      : this.context = createContext(options, packages, dartSdk: dartSdk);

  LibraryElement getLibraryElement(ast.Library node) {
    return context
        .getLibraryElement(context.sourceFactory.forUri2(node.importUri));
  }

  ast.Library getLibraryReference(LibraryElement element) {
    return repository.getLibraryReference(element.source.uri);
  }

  ast.Library getLibraryBody(LibraryElement element) {
    var library = getLibraryReference(element);
    if (!library.isLoaded) {
      _buildLibraryBody(element, library);
    }
    return library;
  }

  void _buildLibraryBody(LibraryElement element, ast.Library library) {
    library.name = element.name.isEmpty ? null : element.name;
    _mixinApplications[library] = <String, ast.Class>{};
    for (var unit in element.units) {
      for (var type in unit.types) {
        library.addClass(getClassReference(type));
      }
      for (var type in unit.enums) {
        library.addClass(getClassReference(type));
      }
      for (var accessor in unit.accessors) {
        if (!accessor.isSynthetic) {
          library.addMember(getMemberReference(accessor));
        }
      }
      for (var function in unit.functions) {
        library.addMember(getMemberReference(function));
      }
      for (var field in unit.topLevelVariables) {
        if (!field.isSynthetic) {
          library.addMember(getMemberReference(field));
        }
      }
    }
    library.isLoaded = true;
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

  ast.Class getClassReference(ClassElement element) {
    return _classes.getReference(element, _buildClassReference);
  }

  ast.Class _buildClassReference(ClassElement element) {
    var classNode =
        new ast.Class(name: element.name, isAbstract: element.isAbstract);
    for (TypeParameterElement parameter in element.typeParameters) {
      var parameterNode = new ast.TypeParameter(parameter.name);
      _classTypeParameters[parameter] = parameterNode;
      classNode.typeParameters.add(parameterNode);
      parameterNode.parent = classNode;
    }
    return classNode;
  }

  ast.Class getClassBody(ClassElement element) {
    var classNode = getClassReference(element);
    if (_classes.level[classNode] == LoadingLevel.Reference) {
      _buildClassBody(element, classNode);
    }
    return classNode;
  }

  void _buildClassBody(ClassElement element, ast.Class classNode) {
    // Ensure that the enclosing library is loaded first.
    var library = getLibraryBody(element.library);
    assert(classNode.enclosingLibrary == library);
    new ClassBodyBuilder(this, classNode, element).build(element.computeNode());
    _classes.level[classNode] = LoadingLevel.Body;
  }

  ast.TypeParameter tryGetClassTypeParameter(TypeParameterElement element) {
    return _classTypeParameters[element];
  }

  Element getMemberElement(ast.Member node) {
    return _members.inverse[node];
  }

  ast.Member getMemberReference(Element element) {
    return _members.getReference(element, _buildMemberReference);
  }

  ast.Member _buildMemberReference(Element element) {
    assert(element is! Member); // Use the "base element".
    switch (element.kind) {
      case ElementKind.CONSTRUCTOR:
        ConstructorElement constructor = element;
        if (constructor.isFactory) {
          return new ast.Procedure(
              _nameOfMember(constructor), ast.ProcedureKind.Factory, null,
              isAbstract: false,
              isStatic: true,
              isExternal: constructor.isExternal,
              isConst: constructor.isConst);
        }
        return new ast.Constructor(null,
            name: _nameOfMember(element),
            isConst: constructor.isConst,
            isExternal: constructor.isExternal);

      case ElementKind.FIELD:
      case ElementKind.TOP_LEVEL_VARIABLE:
        VariableElement variable = element;
        return new ast.Field(_nameOfMember(variable),
            isStatic: variable.isStatic,
            isFinal: variable.isFinal,
            isConst: variable.isConst);

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
            _nameOfMember(element), _procedureKindOf(executable), null,
            isAbstract: executable.isAbstract,
            isStatic: executable.isStatic,
            isExternal: executable.isExternal);

      default:
        throw 'Unexpected member kind: $element';
    }
  }

  ast.Member getMemberBody(Element element) {
    var member = getMemberReference(element);
    if (_members.level[member] == LoadingLevel.Reference) {
      _buildMemberBody(element, member);
    }
    return member;
  }

  void _buildMemberBody(Element element, ast.Member member) {
    // Ensure the enclosing library and class are loaded.
    var libraryNode = getLibraryBody(element.library);
    var enclosing = element.enclosingElement;
    if (enclosing is ClassElement) {
      var classNode = getClassBody(enclosing);
      assert(classNode.parent == libraryNode);
      assert(member.parent == classNode);
    } else {
      assert(member.parent == libraryNode);
    }
    new MemberBodyBuilder(this, member, element).build(element.computeNode());
    _members.level[member] = LoadingLevel.Body;
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
    return _mixinApplications[library].putIfAbsent(name, () {
      List<ast.TypeParameter> typeParameters = <ast.TypeParameter>[];
      ast.InterfaceType makeSuper(ast.Class class_) {
        if (class_.typeParameters.isEmpty) return class_.rawType;
        // We need to copy over type parameters from the given super type,
        // including its bounds.  We handle two cases separately:
        //
        //   1. The super class is derived from a ClassElement.
        //      At this point, the IR node can only be assumed to be loaded as
        //      a reference, meaning its type parameter bound are not yet
        //      initialized.
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
          mixedInType: mixedInType);
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
    if (node.isLoaded) return;
    var source = context.sourceFactory.forUri2(node.importUri);
    assert(source != null);
    var element = context.computeLibraryElement(source);
    context.resolveCompilationUnit(source, element);
    _buildLibraryBody(element, node);
    for (var unit in element.units) {
      LineInfo lines;
      for (var error in context.computeErrors(unit.source)) {
        if (error.errorCode is CompileTimeErrorCode ||
            error.errorCode is ParserErrorCode ||
            error.errorCode is ScannerErrorCode ||
            error.errorCode is StrongModeCode) {
          if (error.errorCode == ParserErrorCode.CONST_FACTORY &&
              node.importUri.scheme == 'dart') {
            // Ignore warnings about 'const' factories in the patched SDK.
            continue;
          }
          lines ??= context.computeLineInfo(source);
          errors.add(formatErrorMessage(error, source.shortName, lines));
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
    int libraryIndex = 0;
    bool changed = true;
    while (changed) {
      changed = false;
      while (libraryIndex < repository.libraries.length) {
        ensureLibraryIsLoaded(repository.libraries[libraryIndex]);
        ++libraryIndex;
      }
      while (_classes.referencedNodes.isNotEmpty) {
        getClassBody(_classes.referencedNodes.removeLast());
        changed = true;
      }
      while (_members.referencedNodes.isNotEmpty) {
        getMemberBody(_members.referencedNodes.removeLast());
        changed = true;
      }
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

  ast.Program loadProgram(String mainLibrary, {Target target}) {
    ast.Library library = repository.getLibrary(mainLibrary);
    ensureLibraryIsLoaded(library);
    loadEverything(target: target);
    var program = new ast.Program(repository.libraries);
    program.mainMethod = library.procedures.firstWhere(
        (member) => member.name?.name == 'main',
        orElse: () => null);
    return program;
  }

  ast.Library loadLibrary(String mainLibrary) {
    ast.Library library = repository.getLibrary(mainLibrary);
    ensureLibraryIsLoaded(library);
    return library;
  }
}

enum LoadingLevel {
  /// A library, member, or class whose object has been created so it can
  /// be referenced, but its contents have not been completely initialized.
  ///
  /// Classes contain their name and type parameter arity.
  ///
  /// Members contain their name and modifiers (abstract, static, etc).
  ///
  /// At this level, a class may be used in an [ast.InterfaceType].
  Reference,

  /// Everything is loaded.
  Body,
}

class LoadMap<K, V> {
  final Map<K, V> nodeMap = <K, V>{};
  final Map<V, K> inverse = <V, K>{};
  final Map<V, LoadingLevel> level = <V, LoadingLevel>{};
  final List<K> referencedNodes = <K>[];

  V getReference(K key, V build(K key)) {
    return nodeMap.putIfAbsent(key, () {
      var result = build(key);
      referencedNodes.add(key);
      level[result] = LoadingLevel.Reference;
      inverse[result] = key;
      return result;
    });
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
      dartSdk = createDartSdk(options.sdk, options.strongMode);
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
    ..generateImplicitErrors = true
    ..generateSdkErrors = true
    ..preserveComments = false
    ..hint = false
    ..enableSuperMixins = true;
}

DartSdk createDartSdk(String path, bool strongMode) {
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
  dartSdk ??= createDartSdk(options.sdk, options.strongMode);

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
