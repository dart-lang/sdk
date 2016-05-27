// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.analyzer.loader;

import 'analyzer.dart';
import '../repository.dart';
import '../ast.dart' as ast;
import 'ast_from_analyzer.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/engine.dart';

abstract class ReferenceLevelLoader {
  ast.Library getLibraryReference(LibraryElement element);
  ast.Class getClassReference(ClassElement element);
  ast.Member getMemberReference(Element element);
  ast.Class getRootClassReference();
  ast.Constructor getRootClassConstructorReference();
  ast.Class getCoreClassReference(String className);
  ast.TypeParameter tryGetClassTypeParameter(TypeParameterElement element);
  bool get strongMode;
}

class AnalyzerLoader implements ReferenceLevelLoader {
  final Repository repository;
  final LoadMap<ClassElement, ast.Class> _classes =
      new LoadMap<ClassElement, ast.Class>();
  final LoadMap<Element, ast.Member> _members =
      new LoadMap<Element, ast.Member>();
  final Map<TypeParameterElement, ast.TypeParameter> _classTypeParameters =
      <TypeParameterElement, ast.TypeParameter>{};
  final AnalysisContext context;
  LibraryElement _dartCoreLibrary;

  bool get strongMode => context.analysisOptions.strongMode;

  AnalyzerLoader(Repository repository,
      {AnalysisContext context, bool strongMode: false})
      : this.repository = repository,
        this.context = context ?? createContext(repository, strongMode);

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
    return _dartCoreLibrary ??= context
        .computeLibraryElement(context.sourceFactory.forUri('dart:core'));
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

  ClassElement getClassElement(ast.Class node) {
    return _classes.inverse[node];
  }

  ast.Class getClassReference(ClassElement element) {
    return _classes.getReference(element, _buildClassReference);
  }

  ast.Class _buildClassReference(ClassElement element) {
    var classNode = element.isMixinApplication
        ? new ast.MixinClass(null, null,
            name: element.name, isAbstract: element.isAbstract)
        : new ast.NormalClass(null,
            name: element.name, isAbstract: element.isAbstract);
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
    String name = element is PropertyAccessorElement
        ? element.displayName
        : element.name;
    return new ast.Name(name, getLibraryReference(element.library));
  }

  void ensureLibraryIsLoaded(ast.Library node) {
    if (node.isLoaded) return;
    var source = context.sourceFactory.forUri2(node.importUri);
    assert(source != null);
    var element = context.computeLibraryElement(source);
    context.resolveCompilationUnit(source, element);
    _buildLibraryBody(element, node);
  }

  void loadEverything() {
    ensureLibraryIsLoaded(getLibraryReference(getDartCoreLibrary()));
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

AnalysisContext createContext(Repository repository, bool strongMode) {
  if (repository.sdk != null) {
    JavaSystemIO.setProperty("com.google.dart.sdk", repository.sdk);
  }
  DartSdk dartSdk = DirectoryBasedDartSdk.defaultSdk;

  List<UriResolver> resolvers = [
    new DartUriResolver(dartSdk),
    new FileUriResolver()
  ];

  if (repository.packageRoot != null) {
    var packageDirectory = new JavaFile(repository.packageRoot);
    resolvers.add(new PackageUriResolver([packageDirectory]));
  }

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers);

  context.analysisOptions = new AnalysisOptionsImpl()
    ..strongMode = strongMode
    ..preserveComments = false
    ..hint = false
    ..generateImplicitErrors = false;

  return context;
}
