// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:mirrors';

import 'protocol.dart';
import '../executor.dart';
import '../api.dart';

/// Spawns a new isolate for loading and executing macros.
void spawn(SendPort sendPort) {
  ReceivePort receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    if (message is LoadMacroRequest) {
      GenericResponse<MacroClassIdentifier> response =
          await _loadMacro(message);
      sendPort.send(response);
    } else if (message is InstantiateMacroRequest) {
      GenericResponse<MacroInstanceIdentifier> response =
          await _instantiateMacro(message);
      sendPort.send(response);
    } else if (message is ExecuteDefinitionsPhaseRequest) {
      GenericResponse<MacroExecutionResult> response =
          await _executeDefinitionsPhase(message);
      sendPort.send(response);
    } else {
      throw new StateError('Unrecognized event type $message');
    }
  });
}

/// Maps macro identifiers to class mirrors.
final _macroClasses = <_MacroClassIdentifier, ClassMirror>{};

/// Handles [LoadMacroRequest]s.
Future<GenericResponse<MacroClassIdentifier>> _loadMacro(
    LoadMacroRequest request) async {
  try {
    _MacroClassIdentifier identifier =
        new _MacroClassIdentifier(request.library, request.name);
    if (_macroClasses.containsKey(identifier)) {
      throw new UnsupportedError(
          'Reloading macros is not supported by this implementation');
    }
    LibraryMirror libMirror =
        await currentMirrorSystem().isolate.loadUri(request.library);
    ClassMirror macroClass =
        libMirror.declarations[new Symbol(request.name)] as ClassMirror;
    _macroClasses[identifier] = macroClass;
    return new GenericResponse(response: identifier, requestId: request.id);
  } catch (e) {
    return new GenericResponse(error: e, requestId: request.id);
  }
}

/// Maps macro instance identifiers to instances.
final _macroInstances = <_MacroInstanceIdentifier, Macro>{};

/// Handles [InstantiateMacroRequest]s.
Future<GenericResponse<MacroInstanceIdentifier>> _instantiateMacro(
    InstantiateMacroRequest request) async {
  try {
    ClassMirror? clazz = _macroClasses[request.macroClass];
    if (clazz == null) {
      throw new ArgumentError('Unrecognized macro class ${request.macroClass}');
    }
    Macro instance = clazz.newInstance(
        new Symbol(request.constructorName), request.arguments.positional, {
      for (MapEntry<String, Object?> entry in request.arguments.named.entries)
        new Symbol(entry.key): entry.value,
    }).reflectee as Macro;
    _MacroInstanceIdentifier identifier = new _MacroInstanceIdentifier();
    _macroInstances[identifier] = instance;
    return new GenericResponse<MacroInstanceIdentifier>(
        response: identifier, requestId: request.id);
  } catch (e) {
    return new GenericResponse(error: e, requestId: request.id);
  }
}

Future<GenericResponse<MacroExecutionResult>> _executeDefinitionsPhase(
    ExecuteDefinitionsPhaseRequest request) async {
  try {
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance ${request.macro}\n'
          'Known instances: $_macroInstances)');
    }
    Declaration declaration = request.declaration;
    if (instance is FunctionDefinitionMacro &&
        declaration is FunctionDeclaration) {
      _FunctionDefinitionBuilder builder = new _FunctionDefinitionBuilder(
          declaration,
          request.typeResolver,
          request.typeDeclarationResolver,
          request.classIntrospector);
      await instance.buildDefinitionForFunction(declaration, builder);
      return new GenericResponse(
          response: builder.result, requestId: request.id);
    } else {
      throw new UnsupportedError(
          ('Only FunctionDefinitionMacros are supported currently'));
    }
  } catch (e) {
    return new GenericResponse(error: e, requestId: request.id);
  }
}

/// Our implementation of [MacroClassIdentifier].
class _MacroClassIdentifier implements MacroClassIdentifier {
  final String id;

  _MacroClassIdentifier(Uri library, String name) : id = '$library#$name';

  operator ==(other) => other is _MacroClassIdentifier && id == other.id;

  int get hashCode => id.hashCode;
}

/// Our implementation of [MacroInstanceIdentifier].
class _MacroInstanceIdentifier implements MacroInstanceIdentifier {
  static int _next = 0;

  final int id;

  _MacroInstanceIdentifier() : id = _next++;

  operator ==(other) => other is _MacroInstanceIdentifier && id == other.id;

  int get hashCode => id;
}

/// Our implementation of [MacroExecutionResult].
class _MacroExecutionResult implements MacroExecutionResult {
  @override
  final List<DeclarationCode> augmentations = <DeclarationCode>[];

  @override
  final List<DeclarationCode> imports = <DeclarationCode>[];
}

/// Custom implementation of [FunctionDefinitionBuilder].
class _FunctionDefinitionBuilder implements FunctionDefinitionBuilder {
  final TypeResolver typeResolver;
  final TypeDeclarationResolver typeDeclarationResolver;
  final ClassIntrospector classIntrospector;

  /// The declaration this is a builder for.
  final FunctionDeclaration declaration;

  /// The final result, will be built up over `augment` calls.
  final _MacroExecutionResult result = new _MacroExecutionResult();

  _FunctionDefinitionBuilder(this.declaration, this.typeResolver,
      this.typeDeclarationResolver, this.classIntrospector);

  @override
  void augment(FunctionBodyCode body) {
    result.augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      declaration.returnType.code,
      ' ',
      declaration.name,
      if (declaration.typeParameters.isNotEmpty) ...[
        '<',
        for (TypeParameterDeclaration typeParam
            in declaration.typeParameters) ...[
          typeParam.name,
          if (typeParam.bounds != null) ...['extends ', typeParam.bounds!.code],
          if (typeParam != declaration.typeParameters.last) ', ',
        ],
        '>',
      ],
      '(',
      for (ParameterDeclaration positionalRequired
          in declaration.positionalParameters.where((p) => p.isRequired)) ...[
        new ParameterCode.fromParts([
          positionalRequired.type.code,
          ' ',
          positionalRequired.name,
        ]),
        ', '
      ],
      if (declaration.positionalParameters.any((p) => !p.isRequired)) ...[
        '[',
        for (ParameterDeclaration positionalOptional in declaration
            .positionalParameters
            .where((p) => !p.isRequired)) ...[
          new ParameterCode.fromParts([
            positionalOptional.type.code,
            ' ',
            positionalOptional.name,
          ]),
          ', ',
        ],
        ']',
      ],
      if (declaration.namedParameters.isNotEmpty) ...[
        '{',
        for (ParameterDeclaration named in declaration.namedParameters) ...[
          new ParameterCode.fromParts([
            if (named.isRequired) 'required ',
            named.type.code,
            ' ',
            named.name,
            if (named.defaultValue != null) ...[
              ' = ',
              named.defaultValue!,
            ],
          ]),
          ', ',
        ],
        '}',
      ],
      ') ',
      body,
    ]));
  }

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(ClassDeclaration clazz) =>
      classIntrospector.constructorsOf(clazz);

  @override
  Future<List<FieldDeclaration>> fieldsOf(ClassDeclaration clazz) =>
      classIntrospector.fieldsOf(clazz);

  @override
  Future<List<ClassDeclaration>> interfacesOf(ClassDeclaration clazz) =>
      classIntrospector.interfacesOf(clazz);

  @override
  Future<List<MethodDeclaration>> methodsOf(ClassDeclaration clazz) =>
      classIntrospector.methodsOf(clazz);

  @override
  Future<List<ClassDeclaration>> mixinsOf(ClassDeclaration clazz) =>
      classIntrospector.mixinsOf(clazz);

  @override
  Future<TypeDeclaration> declarationOf(NamedStaticType annotation) =>
      typeDeclarationResolver.declarationOf(annotation);

  @override
  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) =>
      classIntrospector.superclassOf(clazz);

  @override
  Future<StaticType> resolve(TypeAnnotation typeAnnotation) =>
      typeResolver.resolve(typeAnnotation);
}
