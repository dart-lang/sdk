// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Handles construction of TypeVariable constants needed at runtime.
 */
class TypeVariableHandler {
  final Compiler _compiler;
  FunctionElement _typeVariableConstructor;

  /**
   * Set to 'true' on first encounter of a class with type variables.
   */
  bool _seenClassesWithTypeVariables = false;

  /**
   *  Maps a class element to a list with indices that point to type variables
   *  constants for each of the class' type variables.
   */
  Map<ClassElement, List<jsAst.Expression>> _typeVariables =
      new Map<ClassElement, List<jsAst.Expression>>();

  /**
   *  Maps a TypeVariableType to the index pointing to the constant representing
   *  the corresponding type variable at runtime.
   */
  Map<TypeVariableElement, jsAst.Expression> _typeVariableConstants =
      new Map<TypeVariableElement, jsAst.Expression>();

  TypeVariableHandler(this._compiler);

  ClassElement get _typeVariableClass => _backend.typeVariableClass;
  CodeEmitterTask get _task => _backend.emitter;
  MetadataCollector get _metadataCollector => _task.metadataCollector;
  JavaScriptBackend get _backend => _compiler.backend;
  DiagnosticReporter get reporter => _compiler.reporter;

  void registerClassWithTypeVariables(ClassElement cls, Enqueuer enqueuer,
                                      Registry registry) {
    if (enqueuer.isResolutionQueue) {
      // On first encounter, we have to ensure that the support classes get
      // resolved.
      if (!_seenClassesWithTypeVariables) {
        _backend.enqueueClass(enqueuer, _typeVariableClass, registry);
        _typeVariableClass.ensureResolved(_compiler.resolution);
        Link constructors = _typeVariableClass.constructors;
        if (constructors.isEmpty && constructors.tail.isEmpty) {
          reporter.internalError(_typeVariableClass,
              "Class '$_typeVariableClass' should only have one constructor");
        }
        _typeVariableConstructor = _typeVariableClass.constructors.head;
        _backend.enqueueInResolution(_typeVariableConstructor, registry);
        _backend.registerInstantiatedType(
            _typeVariableClass.rawType, enqueuer, registry);
        enqueuer.registerStaticUse(
            _backend.registerBackendUse(_backend.helpers.createRuntimeType));
        _seenClassesWithTypeVariables = true;
      }
    } else {
      if (_backend.isAccessibleByReflection(cls)) {
        processTypeVariablesOf(cls);
      }
    }
  }

  void processTypeVariablesOf(ClassElement cls) {
    // Do not process classes twice.
    if (_typeVariables.containsKey(cls)) return;

    InterfaceType typeVariableType = _typeVariableClass.thisType;
    List<jsAst.Expression> constants = <jsAst.Expression>[];

    for (TypeVariableType currentTypeVariable in cls.typeVariables) {
      TypeVariableElement typeVariableElement = currentTypeVariable.element;

      AstConstant name = new AstConstant(
          typeVariableElement,
          typeVariableElement.node,
          new StringConstantExpression(currentTypeVariable.name),
          _backend.constantSystem.createString(
              new DartString.literal(currentTypeVariable.name)));
      jsAst.Expression boundIndex =
          _metadataCollector.reifyType(typeVariableElement.bound);
      ConstantValue boundValue =
          new SyntheticConstantValue(
              SyntheticConstantKind.TYPEVARIABLE_REFERENCE,
              boundIndex);
      ConstantExpression boundExpression =
          new SyntheticConstantExpression(boundValue);
      AstConstant bound = new AstConstant(
          typeVariableElement,
          typeVariableElement.node,
          boundExpression,
          boundValue);
      AstConstant type = new AstConstant(
          typeVariableElement,
          typeVariableElement.node,
          new TypeConstantExpression(cls.rawType),
          _backend.constantSystem.createType(_backend.compiler, cls.rawType));
      List<AstConstant> arguments = [type, name, bound];

      // TODO(johnniwinther): Support a less front-end specific creation of
      // constructed constants.
      AstConstant constant =
          CompileTimeConstantEvaluator.makeConstructedConstant(
              _compiler,
              _backend.constants,
              typeVariableElement,
              typeVariableElement.node,
              typeVariableType,
              _typeVariableConstructor,
              typeVariableType,
              _typeVariableConstructor,
              const CallStructure.unnamed(3),
              arguments,
              arguments);
      ConstantValue value = constant.value;
      _backend.registerCompileTimeConstant(value, _compiler.globalDependencies);
      _backend.constants.addCompileTimeConstantForEmission(value);
      constants.add(
          _reifyTypeVariableConstant(value, currentTypeVariable.element));
    }
    _typeVariables[cls] = constants;
  }

  /**
   * Adds [c] to [emitter.metadataCollector] and returns the index pointing to
   * the entry.
   *
   * If the corresponding type variable has already been encountered an
   * entry in the list has already been reserved and the constant is added
   * there, otherwise a new entry for [c] is created.
   */
  jsAst.Expression _reifyTypeVariableConstant(ConstantValue c,
                                              TypeVariableElement variable) {
    jsAst.Expression name = _task.constantReference(c);
    jsAst.Expression result = _metadataCollector.reifyExpression(name);
    if (_typeVariableConstants.containsKey(variable)) {
      Placeholder placeholder = _typeVariableConstants[variable];
      placeholder.bind(result);
    }
    _typeVariableConstants[variable] = result;
    return result;
  }

  /**
   * Returns the index pointing to the constant in [emitter.metadataCollector]
   * representing this type variable.
   *
   * If the constant has not yet been constructed, an entry is  allocated in
   * the global metadata list and the index pointing to this entry is returned.
   * When the corresponding constant is constructed later,
   * [reifyTypeVariableConstant] will be called and the constant will be added
   * on the allocated entry.
   */
  jsAst.Expression reifyTypeVariable(TypeVariableElement variable) {
    if (_typeVariableConstants.containsKey(variable)) {
      return _typeVariableConstants[variable];
    }

    Placeholder placeholder =
        _metadataCollector.getMetadataPlaceholder(variable);
    return _typeVariableConstants[variable] = placeholder;
  }

  List<jsAst.Expression> typeVariablesOf(ClassElement classElement) {
    List<jsAst.Expression> result = _typeVariables[classElement];
    if (result == null) {
      result = const <jsAst.Expression>[];
    }
    return result;
  }
}
