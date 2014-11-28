// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class TypeTestRegistry {
  /**
   * Raw ClassElement symbols occuring in is-checks and type assertions.  If the
   * program contains parameterized checks `x is Set<int>` and
   * `x is Set<String>` then the ClassElement `Set` will occur once in
   * [checkedClasses].
   */
  Set<ClassElement> checkedClasses;

  /**
   * The set of function types that checked, both explicity through tests of
   * typedefs and implicitly through type annotations in checked mode.
   */
  Set<FunctionType> checkedFunctionTypes;

  /// Initially contains all classes that need RTI. After
  /// [computeNeededClasses]
  /// this set only contains classes that are only used for RTI.
  final Set<ClassElement> rtiNeededClasses = new Set<ClassElement>();

  Iterable<ClassElement> cachedClassesUsingTypeVariableTests;

  Iterable<ClassElement> get classesUsingTypeVariableTests {
    if (cachedClassesUsingTypeVariableTests == null) {
      cachedClassesUsingTypeVariableTests = compiler.codegenWorld.isChecks
          .where((DartType t) => t is TypeVariableType)
          .map((TypeVariableType v) => v.element.enclosingClass)
          .toList();
    }
    return cachedClassesUsingTypeVariableTests;
  }

  final Compiler compiler;

  TypeTestRegistry(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  /**
   * Returns the classes with constructors used as a 'holder' in
   * [emitRuntimeTypeSupport].
   * TODO(9556): Some cases will go away when the class objects are created as
   * complete.  Not all classes will go away while constructors are referenced
   * from type substitutions.
   */
  Set<ClassElement> classesModifiedByEmitRuntimeTypeSupport() {
    TypeChecks typeChecks = backend.rti.requiredChecks;
    Set<ClassElement> result = new Set<ClassElement>();
    for (ClassElement cls in typeChecks) {
      for (TypeCheck check in typeChecks[cls]) {
        result.add(cls);
        break;
      }
    }
    return result;
  }

  Set<ClassElement> computeRtiNeededClasses() {
    void addClassWithSuperclasses(ClassElement cls) {
      rtiNeededClasses.add(cls);
      for (ClassElement superclass = cls.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        rtiNeededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassElement> classes) {
      for (ClassElement cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1.  Add classes that are referenced by type arguments or substitutions in
    //     argument checks.
    // TODO(karlklose): merge this case with 2 when unifying argument and
    // object checks.
    RuntimeTypes rti = backend.rti;
    rti.getRequiredArgumentClasses(backend)
       .forEach(addClassWithSuperclasses);

    // 2.  Add classes that are referenced by substitutions in object checks and
    //     their superclasses.
    TypeChecks requiredChecks =
        rti.computeChecks(rtiNeededClasses, checkedClasses);
    Set<ClassElement> classesUsedInSubstitutions =
        rti.getClassesUsedInSubstitutions(backend, requiredChecks);
    addClassesWithSuperclasses(classesUsedInSubstitutions);

    // 3.  Add classes that contain checked generic function types. These are
    //     needed to store the signature encoding.
    for (FunctionType type in checkedFunctionTypes) {
      ClassElement contextClass = Types.getClassContext(type);
      if (contextClass != null) {
        rtiNeededClasses.add(contextClass);
      }
    }

    bool canTearOff(Element function) {
      if (!function.isFunction ||
          function.isConstructor ||
          function.isAccessor) {
        return false;
      } else if (function.isInstanceMember) {
        if (!function.enclosingClass.isClosure) {
          return compiler.codegenWorld.hasInvokedGetter(
              function, compiler.world);
        }
      }
      return false;
    }

    bool canBeReflectedAsFunction(Element element) {
      return element.kind == ElementKind.FUNCTION ||
          element.kind == ElementKind.GETTER ||
          element.kind == ElementKind.SETTER ||
          element.kind == ElementKind.GENERATIVE_CONSTRUCTOR;
    }

    bool canBeReified(Element element) {
      return (canTearOff(element) || backend.isAccessibleByReflection(element));
    }

    // Find all types referenced from the types of elements that can be
    // reflected on 'as functions'.
    backend.generatedCode.keys.where((element) {
      return canBeReflectedAsFunction(element) && canBeReified(element);
    }).forEach((FunctionElement function) {
      DartType type = function.computeType(compiler);
      for (ClassElement cls in backend.rti.getReferencedClasses(type)) {
        while (cls != null) {
          rtiNeededClasses.add(cls);
          cls = cls.superclass;
        }
      }
    });

    return rtiNeededClasses;
  }

  void computeRequiredTypeChecks() {
    assert(checkedClasses == null && checkedFunctionTypes == null);

    backend.rti.addImplicitChecks(compiler.codegenWorld,
                                  classesUsingTypeVariableTests);

    checkedClasses = new Set<ClassElement>();
    checkedFunctionTypes = new Set<FunctionType>();
    compiler.codegenWorld.isChecks.forEach((DartType t) {
      if (t is InterfaceType) {
        checkedClasses.add(t.element);
      } else if (t is FunctionType) {
        checkedFunctionTypes.add(t);
      }
    });
  }
}
