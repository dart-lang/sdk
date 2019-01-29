// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart"
    show
        Class,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        Library,
        NamedType,
        Node,
        Supertype,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        Typedef,
        VoidType,
        setParents;

import "type_parser.dart" as type_parser show parse;

import "type_parser.dart"
    show
        ParsedClass,
        ParsedIntersectionType,
        ParsedFunctionType,
        ParsedInterfaceType,
        ParsedType,
        ParsedTypeVariable,
        ParsedTypedef,
        ParsedVoidType,
        Visitor;

Library parseLibrary(Uri uri, String text,
    {Uri fileUri, KernelEnvironment environment}) {
  fileUri ??= uri;
  environment ??= new KernelEnvironment(uri, fileUri);
  Library library =
      new Library(uri, fileUri: fileUri, name: uri.path.replaceAll("/", "."));
  for (ParsedType type in type_parser.parse(text)) {
    Node node = environment.kernelFromParsedType(type);
    if (node is Class) {
      library.addClass(node);
    } else {
      throw "Unsupported: $node";
    }
  }
  return library;
}

class KernelEnvironment {
  final Uri uri;

  final Uri fileUri;

  final Map<String, TreeNode> declarations = <String, TreeNode>{};

  KernelEnvironment(this.uri, this.fileUri);

  Node kernelFromParsedType(ParsedType type) {
    Node node = type.accept(const KernelFromParsedType(), this);
    return node;
  }

  bool isObject(String name) => name == "Object" && "$uri" == "dart:core";

  Class get objectClass => this["Object"];

  TreeNode operator [](String name) {
    return declarations[name] ?? (throw "Not found: $name");
  }

  void operator []=(String name, TreeNode declaration) {
    TreeNode existing = declarations[name];
    if (existing != null) {
      throw "Duplicated declaration: $name";
    }
    declarations[name] = declaration;
  }

  KernelEnvironment extend(Map<String, TreeNode> declarations) {
    return new KernelEnvironment(uri, fileUri)
      ..declarations.addAll(this.declarations)
      ..declarations.addAll(declarations);
  }
}

class KernelFromParsedType implements Visitor<Node, KernelEnvironment> {
  const KernelFromParsedType();

  DartType visitInterfaceType(
      ParsedInterfaceType node, KernelEnvironment environment) {
    TreeNode declaration = environment[node.name];
    List<ParsedType> arguments = node.arguments;
    List<DartType> kernelArguments =
        new List<DartType>.filled(arguments.length, null);
    for (int i = 0; i < arguments.length; i++) {
      kernelArguments[i] =
          arguments[i].accept<Node, KernelEnvironment>(this, environment);
    }
    if (declaration is Class) {
      return new InterfaceType(declaration, kernelArguments);
    } else if (declaration is TypeParameter) {
      if (arguments.isNotEmpty) {
        throw "Type variable can't have arguments (${node.name})";
      }
      return new TypeParameterType(declaration);
    } else {
      throw "Unhandled ${declaration.runtimeType}";
    }
  }

  Class visitClass(ParsedClass node, KernelEnvironment environment) {
    String name = node.name;
    Class cls =
        environment[name] = new Class(fileUri: environment.fileUri, name: name);
    ParameterEnvironment parameterEnvironment =
        computeTypeParameterEnvironment(node.typeVariables, environment);
    List<TypeParameter> parameters = parameterEnvironment.parameters;
    setParents(parameters, cls);
    cls.typeParameters.addAll(parameters);
    {
      KernelEnvironment environment = parameterEnvironment.environment;
      InterfaceType type =
          node.supertype?.accept<Node, KernelEnvironment>(this, environment);
      if (type == null) {
        if (!environment.isObject(name)) {
          cls.supertype = environment.objectClass.asRawSupertype;
        }
      } else {
        cls.supertype = toSupertype(type);
      }
      List<ParsedType> interfaces = node.interfaces;
      for (int i = 0; i < interfaces.length; i++) {
        cls.implementedTypes.add(toSupertype(
            interfaces[i].accept<Node, KernelEnvironment>(this, environment)));
      }
    }
    return cls;
  }

  Typedef visitTypedef(ParsedTypedef node, KernelEnvironment environment) {
    throw "not implemented: $node";
  }

  FunctionType visitFunctionType(
      ParsedFunctionType node, KernelEnvironment environment) {
    ParameterEnvironment parameterEnvironment =
        computeTypeParameterEnvironment(node.typeVariables, environment);
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType> namedParameters = <NamedType>[];
    DartType returnType;
    {
      KernelEnvironment environment = parameterEnvironment.environment;
      returnType =
          node.returnType?.accept<Node, KernelEnvironment>(this, environment);
      for (ParsedType argument in node.arguments.required) {
        positionalParameters
            .add(argument.accept<Node, KernelEnvironment>(this, environment));
      }
      List<Object> optional = node.arguments.optional;
      for (int i = 0; i < optional.length; i++) {
        ParsedType parsedType = optional[i];
        DartType type =
            parsedType.accept<Node, KernelEnvironment>(this, environment);
        if (node.arguments.optionalAreNamed) {
          namedParameters.add(new NamedType(optional[++i], type));
        } else {
          positionalParameters.add(type);
        }
      }
    }
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: node.arguments.required.length,
        typeParameters: parameterEnvironment.parameters);
  }

  VoidType visitVoidType(ParsedVoidType node, KernelEnvironment environment) {
    return const VoidType();
  }

  TypeParameter visitTypeVariable(
      ParsedTypeVariable node, KernelEnvironment environment) {
    throw "not implemented: $node";
  }

  TypeParameterType visitIntersectionType(
      ParsedIntersectionType node, KernelEnvironment environment) {
    TypeParameterType type =
        node.a.accept<Node, KernelEnvironment>(this, environment);
    DartType bound = node.b.accept<Node, KernelEnvironment>(this, environment);
    return new TypeParameterType(type.parameter, bound);
  }

  Supertype toSupertype(InterfaceType type) {
    return new Supertype.byReference(type.className, type.typeArguments);
  }

  ParameterEnvironment computeTypeParameterEnvironment(
      List<ParsedTypeVariable> typeVariables, KernelEnvironment environment) {
    List<TypeParameter> typeParameters =
        new List<TypeParameter>.filled(typeVariables.length, null);
    Map<String, TypeParameter> typeParametersByName = <String, TypeParameter>{};
    for (int i = 0; i < typeVariables.length; i++) {
      String name = typeVariables[i].name;
      typeParametersByName[name] = typeParameters[i] = new TypeParameter(name);
    }
    KernelEnvironment nestedEnvironment =
        environment.extend(typeParametersByName);
    for (int i = 0; i < typeVariables.length; i++) {
      ParsedType bound = typeVariables[i].bound;
      TypeParameter typeParameter = typeParameters[i];
      if (bound == null) {
        typeParameter
          ..bound = environment.objectClass.rawType
          ..defaultType = const DynamicType();
      } else {
        DartType type =
            bound.accept<Node, KernelEnvironment>(this, nestedEnvironment);
        typeParameter
          ..bound = type
          ..defaultType = type; // TODO(ahe): Is this correct?

      }
    }
    return new ParameterEnvironment(typeParameters, nestedEnvironment);
  }
}

class ParameterEnvironment {
  final List<TypeParameter> parameters;
  final KernelEnvironment environment;

  const ParameterEnvironment(this.parameters, this.environment);
}
