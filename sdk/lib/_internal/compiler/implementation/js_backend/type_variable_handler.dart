// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Handles construction of TypeVariable constants needed at runtime.
 */
class TypeVariableHandler {
  JavaScriptBackend backend;
  FunctionElement typeVariableConstructor;
  CompileTimeConstantEvaluator evaluator;

  /**
   * Contains all instantiated classes that have type variables and are needed
   * for reflection.
   */
  List<ClassElement> typeVariableClasses = new List<ClassElement>();

  /**
   *  Maps a class element to a list with indices that point to type variables
   *  constants for each of the class' type variables.
   */
  Map<ClassElement, List<int>> typeVariables =
      new Map<ClassElement, List<int>>();

  /**
   *  Maps a TypeVariableType to the index pointing to the constant representing
   *  the corresponding type variable at runtime.
   */
  Map<TypeVariableElement, int> typeVariableConstants =
      new Map<TypeVariableElement, int>();

  TypeVariableHandler(this.backend);

  ClassElement get typeVariableClass => backend.typeVariableClass;
  CodeEmitterTask get task => backend.emitter;
  MetadataEmitter get emitter => task.metadataEmitter;
  Compiler get compiler => backend.compiler;

  void registerClassWithTypeVariables(ClassElement cls) {
    if (!backend.isTreeShakingDisabled || typeVariableConstructor == null) {
      typeVariableClasses.add(cls);
    } else {
      processTypeVariablesOf(cls);
    }
  }

  void processTypeVariablesOf(ClassElement cls) {
      //TODO(zarah): Running through all the members is suboptimal. Change this
      // as part of marking elements for reflection.
      bool hasMemberNeededForReflection(ClassElement cls) {
        bool result = false;
        cls.implementation.forEachMember((ClassElement cls, Element member) {
          result = result || backend.referencedFromMirrorSystem(member);
        });
        return result;
      }

      if (!backend.referencedFromMirrorSystem(cls) &&
          !hasMemberNeededForReflection(cls)) {
        return;
      }

      InterfaceType typeVariableType = typeVariableClass.thisType;
      List<int> constants = <int>[];
      evaluator = new CompileTimeConstantEvaluator(
          backend.constants,
          compiler.globalDependencies.mapping,
          compiler);

      for (TypeVariableType currentTypeVariable in cls.typeVariables) {
        List<Constant> createArguments(FunctionElement constructor) {
        if (constructor != typeVariableConstructor) {
            compiler.internalError(currentTypeVariable.element,
                'Unexpected constructor $constructor');
          }
          Constant name = backend.constantSystem.createString(
              new DartString.literal(currentTypeVariable.name));
          Constant bound = backend.constantSystem.createInt(
              emitter.reifyType(currentTypeVariable.element.bound));
          Constant type = backend.constants.createTypeConstant(cls);
          return [type, name, bound];
        }

        Constant c = evaluator.makeConstructedConstant(
            currentTypeVariable.element, typeVariableType,
            typeVariableConstructor, createArguments);
        backend.registerCompileTimeConstant(c, compiler.globalDependencies);
        backend.constants.addCompileTimeConstantForEmission(c);
        constants.add(
            reifyTypeVariableConstant(c, currentTypeVariable.element));
      }
      typeVariables[cls] = constants;
  }

  void onTreeShakingDisabled(Enqueuer enqueuer) {
    if (!enqueuer.isResolutionQueue || typeVariableClasses == null) return;
    backend.enqueueClass(
          enqueuer, typeVariableClass, compiler.globalDependencies);
    typeVariableClass.ensureResolved(compiler);
    Link constructors = typeVariableClass.constructors;
    if (constructors.isEmpty && constructors.tail.isEmpty) {
      compiler.internalError(typeVariableClass,
          "Class '$typeVariableClass' should only have one constructor");
    }
    typeVariableConstructor = typeVariableClass.constructors.head;
    backend.enqueueInResolution(typeVariableConstructor,
        compiler.globalDependencies);
    enqueuer.registerInstantiatedType(typeVariableClass.rawType,
        compiler.globalDependencies);
    List<ClassElement> worklist = typeVariableClasses;
    typeVariableClasses = null;
    worklist.forEach((cls) => processTypeVariablesOf(cls));
  }

  /**
   * Adds [c] to [emitter.globalMetadata] and returns the index pointing to
   * the entry.
   *
   * If the corresponding type variable has already been encountered an
   * entry in the list has already been reserved and the constant is added
   * there, otherwise a new entry for [c] is created.
   */
  int reifyTypeVariableConstant(Constant c, TypeVariableElement variable) {
    String name =
        jsAst.prettyPrint(task.constantReference(c), compiler).getText();
    int index;
    if (typeVariableConstants.containsKey(variable)) {
      index = typeVariableConstants[variable];
      emitter.globalMetadata[index] = name;
    } else {
      index = emitter.addGlobalMetadata(name);
      typeVariableConstants[variable] = index;
    }
    return index;
  }

  /**
   * Returns the index pointing to the constant in [emitter.globalMetadata]
   * representing this type variable
   *.
   *
   * If the constant has not yet been constructed, an entry is  allocated in
   * the global metadata list and the index pointing to this entry is returned.
   * When the corresponding constant is constructed later,
   * [reifyTypeVariableConstant] will be called and the constant will be added
   * on the allocated entry.
   */
  int reifyTypeVariable(TypeVariableElement variable) {
    if (typeVariableConstants.containsKey(variable)) {
      return typeVariableConstants[variable];
    }

    // TODO(15613): Remove quotes.
    emitter.globalMetadata.add('"Placeholder for ${variable}"');
    return typeVariableConstants[variable] = emitter.globalMetadata.length - 1;
  }

  List<int> typeVariablesOf(ClassElement classElement) {
    List<int> result = typeVariables[classElement];
    if (result == null) {
      result = const <int>[];
    }
    return result;
  }
}
