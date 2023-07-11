// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart" hide Visitor;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/src/bounds_checks.dart' show calculateBounds;

import 'package:kernel/testing/mock_sdk.dart' show mockSdk;

import 'package:kernel/testing/type_parser.dart' as type_parser show parse;

import 'package:kernel/testing/type_parser.dart';

Component parseComponent(String source, Uri uri) {
  Uri coreUri = Uri.parse("dart:core");
  TypeParserEnvironment coreEnvironment =
      new TypeParserEnvironment(coreUri, coreUri);
  Library coreLibrary =
      parseLibrary(coreUri, mockSdk, environment: coreEnvironment);
  TypeParserEnvironment libraryEnvironment = new TypeParserEnvironment(uri, uri)
      ._extend(coreEnvironment._declarations);
  Library library = parseLibrary(uri, source, environment: libraryEnvironment);
  library.name = "lib";
  return new Component(libraries: <Library>[coreLibrary, library]);
}

Library parseLibrary(Uri uri, String text,
    {Uri? fileUri, TypeParserEnvironment? environment}) {
  fileUri ??= uri;
  environment ??= new TypeParserEnvironment(uri, fileUri);
  Library library =
      new Library(uri, fileUri: fileUri, name: uri.path.replaceAll("/", "."))
        ..isNonNullableByDefault = true;
  List<ParsedType> types = type_parser.parse(text);
  for (ParsedType type in types) {
    if (type is ParsedClass) {
      String name = type.name;
      environment._registerDeclaration(
          name,
          new Class(fileUri: fileUri, name: name)
            ..typeParameters.addAll(new List<TypeParameter>.generate(
                type.typeVariables.length,
                (int i) => new TypeParameter('T$i'))));
    } else if (type is ParsedExtension) {
      String name = type.name;
      environment._registerDeclaration(
          name,
          new Extension(fileUri: fileUri, name: name)
            ..typeParameters.addAll(new List<TypeParameter>.generate(
                type.typeVariables.length,
                (int i) => new TypeParameter('T$i'))));
    }
  }
  for (ParsedType type in types) {
    Node node = environment._kernelFromParsedType(type);
    if (node is Class) {
      library.addClass(node);
    } else if (node is Typedef) {
      library.addTypedef(node);
    } else if (node is Extension) {
      library.addExtension(node);
    } else {
      throw "Unsupported: $node";
    }
  }
  return library;
}

class Env {
  late Component component;

  late CoreTypes coreTypes;

  late TypeParserEnvironment _libraryEnvironment;

  final bool isNonNullableByDefault;

  Env(String source, {required this.isNonNullableByDefault}) {
    Uri libraryUri = Uri.parse('memory:main.dart');
    Uri coreUri = Uri.parse("dart:core");
    TypeParserEnvironment coreEnvironment =
        new TypeParserEnvironment(coreUri, coreUri);
    Library coreLibrary =
        parseLibrary(coreUri, mockSdk, environment: coreEnvironment)
          ..isNonNullableByDefault = isNonNullableByDefault;
    _libraryEnvironment = new TypeParserEnvironment(libraryUri, libraryUri)
        ._extend(coreEnvironment._declarations);
    Library library =
        parseLibrary(libraryUri, source, environment: _libraryEnvironment)
          ..isNonNullableByDefault = isNonNullableByDefault;
    library.name = "lib";
    component = new Component(libraries: <Library>[coreLibrary, library]);
    coreTypes = new CoreTypes(component);
  }

  DartType parseType(String text,
      {Map<String, DartType Function()>? additionalTypes}) {
    return _libraryEnvironment.parseType(text,
        additionalTypes: additionalTypes);
  }

  List<DartType> parseTypes(String text,
      {Map<String, DartType Function()>? additionalTypes}) {
    return _libraryEnvironment.parseTypes(text,
        additionalTypes: additionalTypes);
  }

  List<TypeParameter> extendWithTypeParameters(String? typeParameters) {
    if (typeParameters == null || typeParameters.isEmpty) {
      return <TypeParameter>[];
    }
    ParameterEnvironment parameterEnvironment =
        _libraryEnvironment.extendToParameterEnvironment(typeParameters);
    _libraryEnvironment = parameterEnvironment.environment;
    return parameterEnvironment.parameters;
  }

  void withTypeParameters(
      String? typeParameters, void Function(List<TypeParameter>) f) {
    if (typeParameters == null || typeParameters.isEmpty) {
      f(<TypeParameter>[]);
    } else {
      TypeParserEnvironment oldLibraryEnvironment = _libraryEnvironment;
      List<TypeParameter> typeParameterNodes =
          extendWithTypeParameters(typeParameters);
      f(typeParameterNodes);
      _libraryEnvironment = oldLibraryEnvironment;
    }
  }
}

class TypeParserEnvironment {
  final Uri uri;

  final Uri fileUri;

  final Map<String, TreeNode> _declarations = <String, TreeNode>{};

  final TypeParserEnvironment? _parent;

  /// Collects types to set their nullabilities after type parameters are ready.
  ///
  /// [TypeParameterType]s may receive their nullability at the declaration or
  /// from the bound of the [TypeParameter]s they refer to.  If a
  /// [TypeParameterType] is allocated at the time when the bound of the
  /// [TypeParameter] is not set yet, that is, if it's encountered in that
  /// bound or the bound of other [TypeParameter] from the same scope, and the
  /// nullability of that [TypeParameterType] is not set at declaration, the
  /// [TypeParameterType] is added to [pendingNullabilities], so that it can be
  /// updated when the bound of the [TypeParameter] is ready.
  final List<TypeParameterType> pendingNullabilities = <TypeParameterType>[];

  TypeParserEnvironment(this.uri, this.fileUri, [this._parent]);

  Node _kernelFromParsedType(ParsedType type,
      {Map<String, DartType Function()>? additionalTypes}) {
    Node node = type.accept(
        new _KernelFromParsedType(additionalTypes: additionalTypes), this);
    return node;
  }

  /// Parses a single type.
  DartType parseType(String text,
      {Map<String, DartType Function()>? additionalTypes}) {
    return _kernelFromParsedType(type_parser.parse(text).single,
        additionalTypes: additionalTypes) as DartType;
  }

  /// Parses a list of types separated by commas.
  List<DartType> parseTypes(String text,
      {Map<String, DartType Function()>? additionalTypes}) {
    return (parseType("(${text}) -> void", additionalTypes: additionalTypes)
            as FunctionType)
        .positionalParameters;
  }

  bool isObject(String name) => name == "Object" && "$uri" == "dart:core";

  Class get objectClass => lookupDeclaration("Object") as Class;

  TreeNode lookupDeclaration(String name) {
    TreeNode? result = _declarations[name];
    if (result == null && _parent != null) {
      return _parent!.lookupDeclaration(name);
    }
    if (result == null) throw "Not found: $name";
    return result;
  }

  T _registerDeclaration<T extends TreeNode>(String name, T declaration) {
    TreeNode? existing = _declarations[name];
    if (existing != null) {
      throw "Duplicated declaration: $name";
    }
    return _declarations[name] = declaration;
  }

  TypeParserEnvironment _extend(Map<String, TreeNode> declarations) {
    return new TypeParserEnvironment(uri, fileUri, this)
      .._declarations.addAll(declarations);
  }

  TypeParserEnvironment extendWithTypeParameters(String? typeParameters) {
    if (typeParameters?.isEmpty ?? true) return this;
    return extendToParameterEnvironment(typeParameters!).environment;
  }

  ParameterEnvironment extendToParameterEnvironment(String typeParameters) {
    assert(typeParameters.isNotEmpty);
    return const _KernelFromParsedType().computeTypeParameterEnvironment(
        parseTypeVariables("<${typeParameters}>"), this);
  }

  /// Returns the predefined type by the [name], if any.
  ///
  /// Use this in subclasses to add support for additional predefined types.
  DartType? getPredefinedNamedType(String name) {
    if (_parent != null) {
      return _parent!.getPredefinedNamedType(name);
    }
    return null;
  }
}

class _KernelFromParsedType implements Visitor<Node, TypeParserEnvironment> {
  final Map<String, DartType Function()>? additionalTypes; // Can be null.

  const _KernelFromParsedType({this.additionalTypes});

  DartType _parseType(ParsedType type, TypeParserEnvironment environment) {
    return type.accept<Node, TypeParserEnvironment>(this, environment)
        as DartType;
  }

  InterfaceType? _parseOptionalInterfaceType(
      ParsedType? type, TypeParserEnvironment environment) {
    return type?.accept<Node, TypeParserEnvironment>(this, environment)
        as InterfaceType?;
  }

  @override
  DartType visitInterfaceType(
      ParsedInterfaceType node, TypeParserEnvironment environment) {
    String name = node.name;
    DartType? predefined = environment.getPredefinedNamedType(name);
    if (predefined != null) {
      return predefined;
    } else if (name == "dynamic") {
      // Don't return a const object to ensure we test implementations that use
      // identical.
      return new DynamicType();
    } else if (name == "void") {
      // Don't return a const object to ensure we test implementations that use
      // identical.
      return new VoidType();
    } else if (name == "Never") {
      // Don't return a const object to ensure we test implementations that use
      // identical.
      return NeverType.fromNullability(
          interpretParsedNullability(node.parsedNullability));
    } else if (name == "Null") {
      // Don't return a const object to ensure we test implementations that use
      // identical.
      return new NullType();
    } else if (name == "invalid") {
      // Don't return a const object to ensure we test implementations that use
      // identical.
      return new InvalidType();
    } else if (additionalTypes != null && additionalTypes!.containsKey(name)) {
      return additionalTypes![name]!.call();
    }
    TreeNode declaration = environment.lookupDeclaration(name);
    List<ParsedType> arguments = node.arguments;
    List<DartType> kernelArguments =
        new List<DartType>.filled(arguments.length, dummyDartType);
    for (int i = 0; i < arguments.length; i++) {
      kernelArguments[i] = _parseType(arguments[i], environment);
    }
    if (name == "FutureOr") {
      return new FutureOrType(kernelArguments.single,
          interpretParsedNullability(node.parsedNullability));
    }
    if (declaration is Class) {
      Nullability nullability =
          interpretParsedNullability(node.parsedNullability);
      if (declaration.name == 'Null' &&
          declaration.enclosingLibrary.importUri.isScheme('dart') &&
          declaration.enclosingLibrary.importUri.path == 'core') {
        if (node.parsedNullability != ParsedNullability.omitted) {
          throw "Null type must be written without explicit nullability";
        }
        nullability = Nullability.nullable;
      }
      List<TypeParameter> typeVariables = declaration.typeParameters;
      if (kernelArguments.isEmpty && typeVariables.isNotEmpty) {
        kernelArguments =
            new List<DartType>.filled(typeVariables.length, dummyDartType);
        for (int i = 0; i < typeVariables.length; i++) {
          kernelArguments[i] = typeVariables[i].defaultType;
        }
      } else if (kernelArguments.length != typeVariables.length) {
        throw "Expected ${typeVariables.length} type arguments: $node";
      }
      return new InterfaceType(declaration, nullability, kernelArguments);
    } else if (declaration is TypeParameter) {
      if (arguments.isNotEmpty) {
        throw "Type variable can't have arguments (${node.name})";
      }
      Nullability nullability =
          identical(declaration.bound, TypeParameter.unsetBoundSentinel)
              ? Nullability.nonNullable
              : TypeParameterType.computeNullabilityFromBound(declaration);
      TypeParameterType type = new TypeParameterType(
          declaration,
          interpretParsedNullability(node.parsedNullability,
              ifOmitted: nullability));
      // If the nullability was omitted on the type and can't be computed from
      // the bound because it's not yet available, it will be set to null.  In
      // that case, put it to the list to be updated later, when the bound is
      // available.
      // ignore: unnecessary_null_comparison
      if (type.declaredNullability == null) {
        environment.pendingNullabilities.add(type);
      }
      return type;
    } else if (declaration is Typedef) {
      return new TypedefType(declaration,
          interpretParsedNullability(node.parsedNullability), kernelArguments);
    } else if (declaration is Extension) {
      return new ExtensionType(declaration,
          interpretParsedNullability(node.parsedNullability), kernelArguments);
    } else {
      throw "Unhandled ${declaration.runtimeType}";
    }
  }

  @override
  Class visitClass(ParsedClass node, TypeParserEnvironment environment) {
    String name = node.name;
    Class cls = environment.lookupDeclaration(name) as Class;
    ParameterEnvironment parameterEnvironment =
        computeTypeParameterEnvironment(node.typeVariables, environment);
    List<TypeParameter> parameters = parameterEnvironment.parameters;
    setParents(parameters, cls);
    cls.typeParameters
      ..clear()
      ..addAll(parameters);
    {
      TypeParserEnvironment environment = parameterEnvironment.environment;
      InterfaceType? type =
          _parseOptionalInterfaceType(node.supertype, environment);
      if (type == null) {
        if (!environment.isObject(name)) {
          cls.supertype = environment.objectClass.asRawSupertype;
        }
      } else {
        cls.supertype = toSupertype(type);
      }
      InterfaceType? mixedInType =
          _parseOptionalInterfaceType(node.mixedInType, environment);
      if (mixedInType != null) {
        cls.mixedInType = toSupertype(mixedInType);
      }
      List<ParsedType> interfaces = node.interfaces;
      for (int i = 0; i < interfaces.length; i++) {
        cls.implementedTypes.add(toSupertype(
            _parseOptionalInterfaceType(interfaces[i], environment)!));
      }
    }
    return cls;
  }

  @override
  Extension visitExtension(
      ParsedExtension node, TypeParserEnvironment environment) {
    String name = node.name;
    Extension ext = environment.lookupDeclaration(name) as Extension;
    ParameterEnvironment parameterEnvironment =
        computeTypeParameterEnvironment(node.typeVariables, environment);
    List<TypeParameter> parameters = parameterEnvironment.parameters;
    setParents(parameters, ext);
    ext.typeParameters
      ..clear()
      ..addAll(parameters);
    {
      TypeParserEnvironment environment = parameterEnvironment.environment;
      DartType onType = node.onType
          .accept<Node, TypeParserEnvironment>(this, environment) as DartType;
      ext.onType = onType;
    }
    return ext;
  }

  @override
  Typedef visitTypedef(ParsedTypedef node, TypeParserEnvironment environment) {
    String name = node.name;
    Typedef def = environment._registerDeclaration(
        name, new Typedef(name, null, fileUri: environment.fileUri));
    ParameterEnvironment parameterEnvironment =
        computeTypeParameterEnvironment(node.typeVariables, environment);
    def.typeParameters.addAll(parameterEnvironment.parameters);
    DartType type;
    {
      TypeParserEnvironment environment = parameterEnvironment.environment;
      type = _parseType(node.type, environment);
      if (type is FunctionType) {
        FunctionType f = type;
        type = new FunctionType(
            f.positionalParameters, f.returnType, Nullability.nonNullable,
            namedParameters: f.namedParameters,
            typeParameters: f.typeParameters,
            requiredParameterCount: f.requiredParameterCount);
      }
    }
    return def..type = type;
  }

  @override
  FunctionType visitFunctionType(
      ParsedFunctionType node, TypeParserEnvironment environment) {
    ParameterEnvironment parameterEnvironment =
        computeTypeParameterEnvironment(node.typeVariables, environment);
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType> namedParameters = <NamedType>[];
    DartType returnType;
    {
      TypeParserEnvironment environment = parameterEnvironment.environment;
      returnType = _parseType(node.returnType, environment);
      for (ParsedType argument in node.arguments.required) {
        positionalParameters.add(_parseType(argument, environment));
      }
      for (ParsedType argument in node.arguments.positional) {
        positionalParameters.add(_parseType(argument, environment));
      }
      for (ParsedNamedArgument argument in node.arguments.named) {
        namedParameters.add(new NamedType(
            argument.name, _parseType(argument.type, environment),
            isRequired: argument.isRequired));
      }
    }
    namedParameters.sort();
    return new FunctionType(positionalParameters, returnType,
        interpretParsedNullability(node.parsedNullability),
        namedParameters: namedParameters,
        requiredParameterCount: node.arguments.required.length,
        typeParameters: parameterEnvironment.parameters);
  }

  @override
  RecordType visitRecordType(
      ParsedRecordType node, TypeParserEnvironment environment) {
    List<DartType> positional = <DartType>[];
    List<NamedType> named = <NamedType>[];
    {
      for (ParsedType positionalField in node.positional) {
        positional.add(_parseType(positionalField, environment));
      }
      for (ParsedNamedArgument namedField in node.named) {
        named.add(new NamedType(
            namedField.name, _parseType(namedField.type, environment)));
      }
    }
    named.sort();
    return new RecordType(
        positional, named, interpretParsedNullability(node.parsedNullability));
  }

  @override
  VoidType visitVoidType(
      ParsedVoidType node, TypeParserEnvironment environment) {
    return const VoidType();
  }

  @override
  TypeParameter visitTypeVariable(
      ParsedTypeVariable node, TypeParserEnvironment environment) {
    throw "not implemented: $node";
  }

  @override
  IntersectionType visitIntersectionType(
      ParsedIntersectionType node, TypeParserEnvironment environment) {
    TypeParameterType type =
        _parseType(node.a, environment) as TypeParameterType;
    DartType bound = _parseType(node.b, environment);
    return new IntersectionType(type, bound);
  }

  Supertype toSupertype(InterfaceType type) {
    return new Supertype.byReference(type.classReference, type.typeArguments);
  }

  ParameterEnvironment computeTypeParameterEnvironment(
      List<ParsedTypeVariable> typeVariables,
      TypeParserEnvironment environment) {
    List<TypeParameter> typeParameters = new List<TypeParameter>.filled(
        typeVariables.length, dummyTypeParameter);
    Map<String, TypeParameter> typeParametersByName = <String, TypeParameter>{};
    for (int i = 0; i < typeVariables.length; i++) {
      String name = typeVariables[i].name;
      typeParametersByName[name] = typeParameters[i] = new TypeParameter(name);
    }
    TypeParserEnvironment nestedEnvironment =
        environment._extend(typeParametersByName);
    Class objectClass = environment.objectClass;
    for (int i = 0; i < typeVariables.length; i++) {
      ParsedType? bound = typeVariables[i].bound;
      TypeParameter typeParameter = typeParameters[i];
      if (bound == null) {
        typeParameter
          ..bound = new InterfaceType(
              objectClass, Nullability.nullable, const <DartType>[])
          ..defaultType = const DynamicType();
      } else {
        DartType type = _parseType(bound, nestedEnvironment);
        typeParameter
          ..bound = type
          // The default type will be overridden below, but we need to set it
          // so [calculateBounds] can distinguish between explicit and implicit
          // bounds.
          ..defaultType = type;
      }
    }
    List<DartType> defaultTypes = calculateBounds(typeParameters, objectClass,
        isNonNullableByDefault: true);
    for (int i = 0; i < typeParameters.length; i++) {
      typeParameters[i].defaultType = defaultTypes[i];
    }

    for (TypeParameterType type in nestedEnvironment.pendingNullabilities) {
      type.declaredNullability =
          TypeParameterType.computeNullabilityFromBound(type.parameter);
    }
    nestedEnvironment.pendingNullabilities.clear();
    return new ParameterEnvironment(typeParameters, nestedEnvironment);
  }
}

class ParameterEnvironment {
  final List<TypeParameter> parameters;
  final TypeParserEnvironment environment;

  const ParameterEnvironment(this.parameters, this.environment);
}
