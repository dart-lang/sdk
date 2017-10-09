// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.runtime_type_generator;

import '../closure.dart'
    show
        ClosureRepresentationInfo,
        ClosureFieldElement,
        ClosureConversionTask,
        ScopeInfo;
import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../deferred_load.dart' show DeferredLoadTask, OutputUnit;
import '../elements/elements.dart'
    show ClassElement, MethodElement, MixinApplicationElement;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/js_interop_analysis.dart';
import '../js_backend/native_data.dart';
import '../js_backend/namer.dart' show Namer;
import '../js_backend/runtime_types.dart'
    show
        RuntimeTypesChecks,
        RuntimeTypesNeed,
        RuntimeTypesEncoder,
        RuntimeTypesSubstitutions,
        Substitution,
        TypeCheck,
        TypeChecks;
import '../js_emitter/sorter.dart';
import '../js_model/closure.dart' show JClosureField;
import '../util/util.dart' show Setlet;
import '../world.dart';

import 'code_emitter_task.dart' show CodeEmitterTask;
import 'type_test_registry.dart' show TypeTestRegistry;

// Function signatures used in the generation of runtime type information.
typedef void FunctionTypeSignatureEmitter(
    FunctionEntity method, FunctionType methodType);

typedef void SubstitutionEmitter(ClassEntity element, {bool emitNull});

class TypeTest {
  final jsAst.Name name;
  final jsAst.Node expression;

  TypeTest(this.name, this.expression);
}

class TypeTests {
  TypeTest isTest;
  TypeTest substitution;
  TypeTest signature;
}

class TypeTestProperties {
  /// The index of the function type into the metadata.
  ///
  /// If the class doesn't have a function type this field is `null`.
  ///
  /// If the is tests were generated with `storeFunctionTypeInMetadata` set to
  /// `false`, this field is `null`, and the [properties] contain a property
  /// that encodes the function type.
  jsAst.Expression functionTypeIndex;

  /// The properties that must be installed on the prototype of the
  /// JS constructor of the [ClassEntity] for which the is checks were
  /// generated.
  final Map<ClassEntity, TypeTests> _properties = <ClassEntity, TypeTests>{};

  void addIsTest(ClassEntity cls, jsAst.Name name, jsAst.Node expression) {
    TypeTests typeTests = _properties.putIfAbsent(cls, () => new TypeTests());
    typeTests.isTest = new TypeTest(name, expression);
  }

  void addSubstitution(
      ClassEntity cls, jsAst.Name name, jsAst.Node expression) {
    TypeTests typeTests = _properties.putIfAbsent(cls, () => new TypeTests());
    typeTests.substitution = new TypeTest(name, expression);
  }

  void addSignature(ClassEntity cls, jsAst.Name name, jsAst.Node expression) {
    TypeTests typeTests = _properties.putIfAbsent(cls, () => new TypeTests());
    typeTests.signature = new TypeTest(name, expression);
  }

  void forEachProperty(
      Sorter sorter, void f(jsAst.Name name, jsAst.Node expression)) {
    void handleTypeTest(TypeTest typeTest) {
      if (typeTest == null) return;
      f(typeTest.name, typeTest.expression);
    }

    for (ClassEntity cls in sorter.sortClasses(_properties.keys)) {
      TypeTests typeTests = _properties[cls];
      handleTypeTest(typeTests.isTest);
      handleTypeTest(typeTests.substitution);
      handleTypeTest(typeTests.signature);
    }
  }
}

class RuntimeTypeGenerator {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final DartTypes _types;
  final ClosedWorld _closedWorld;
  final ClosureConversionTask _closureDataLookup;
  final DeferredLoadTask _deferredLoadTask;
  final CodeEmitterTask emitterTask;
  final Namer _namer;
  final NativeData _nativeData;
  final RuntimeTypesChecks _rtiChecks;
  final RuntimeTypesEncoder _rtiEncoder;
  final RuntimeTypesNeed _rtiNeed;
  final RuntimeTypesSubstitutions _rtiSubstitutions;
  final JsInteropAnalysis _jsInteropAnalysis;

  RuntimeTypeGenerator(
      this._elementEnvironment,
      this._commonElements,
      this._types,
      this._closedWorld,
      this._closureDataLookup,
      this._deferredLoadTask,
      this.emitterTask,
      this._namer,
      this._nativeData,
      this._rtiChecks,
      this._rtiEncoder,
      this._rtiNeed,
      this._rtiSubstitutions,
      this._jsInteropAnalysis);

  TypeTestRegistry get _typeTestRegistry => emitterTask.typeTestRegistry;

  Set<ClassEntity> get checkedClasses => _typeTestRegistry.checkedClasses;

  Iterable<ClassEntity> get classesUsingTypeVariableTests =>
      _typeTestRegistry.classesUsingTypeVariableTests;

  Set<FunctionType> get checkedFunctionTypes =>
      _typeTestRegistry.checkedFunctionTypes;

  /// Generates all properties necessary for is-checks on the [classElement].
  ///
  /// Returns an instance of [TypeTestProperties] that contains the properties
  /// that must be installed on the prototype of the JS constructor of the
  /// [classElement].
  ///
  /// If [storeFunctionTypeInMetadata] is `true`, stores the reified function
  /// type (if class has one) in the metadata object and stores its index in
  /// the result. This is only possible for function types that do not contain
  /// type variables.
  TypeTestProperties generateIsTests(ClassEntity classElement,
      {bool storeFunctionTypeInMetadata: true}) {
    TypeTestProperties result = new TypeTestProperties();

    assert(!(classElement is ClassElement && !classElement.isDeclaration),
        failedAt(classElement));

    /// Generates an is-test if the test is not inherited from a superclass
    /// This assumes that for every class an is-tests is generated
    /// dynamically at runtime. We also always generate tests against
    /// native classes.
    /// TODO(herhut): Generate tests for native classes dynamically, as well.
    void generateIsTest(ClassEntity other) {
      if (_nativeData.isNativeClass(classElement) ||
          !_closedWorld.isSubclassOf(classElement, other)) {
        result.addIsTest(other, _namer.operatorIs(other), js('1'));
      }
    }

    void generateFunctionTypeSignature(
        FunctionEntity method, FunctionType type) {
      assert(!(method is MethodElement && !method.isImplementation));
      jsAst.Expression thisAccess = new jsAst.This();
      if (!method.isAbstract) {
        ScopeInfo scopeInfo = _closureDataLookup.getScopeInfo(method);
        if (scopeInfo is ClosureRepresentationInfo) {
          FieldEntity thisLocal = scopeInfo.thisFieldEntity;
          if (thisLocal != null) {
            assert(
                thisLocal is ClosureFieldElement || thisLocal is JClosureField);
            jsAst.Name thisName = _namer.instanceFieldPropertyName(thisLocal);
            thisAccess = js('this.#', thisName);
          }
        }
      }

      if (storeFunctionTypeInMetadata && !type.containsTypeVariables) {
        // TODO(sigmund): use output unit of `method` (Issue #31032)
        OutputUnit outputUnit = _deferredLoadTask.mainOutputUnit;
        result.functionTypeIndex =
            emitterTask.metadataCollector.reifyType(type, outputUnit);
      } else {
        jsAst.Expression encoding = _rtiEncoder.getSignatureEncoding(
            emitterTask.emitter, type, thisAccess);
        jsAst.Name operatorSignature = _namer.asName(_namer.operatorSignature);
        result.addSignature(classElement, operatorSignature, encoding);
      }
    }

    void generateSubstitution(ClassEntity cls, {bool emitNull: false}) {
      if (!_elementEnvironment.isGenericClass(cls)) return;
      jsAst.Expression expression;
      bool needsNativeCheck =
          emitterTask.nativeEmitter.requiresNativeIsCheck(cls);
      Substitution substitution =
          _rtiSubstitutions.getSubstitution(classElement, cls);
      if (substitution != null) {
        expression =
            _rtiEncoder.getSubstitutionCode(emitterTask.emitter, substitution);
      }
      if (expression == null && (emitNull || needsNativeCheck)) {
        expression = new jsAst.LiteralNull();
      }
      if (expression != null) {
        result.addSubstitution(cls, _namer.substitutionName(cls), expression);
      }
    }

    void generateTypeCheck(TypeCheck check) {
      ClassEntity checkedClass = check.cls;
      generateIsTest(checkedClass);
      Substitution substitution = check.substitution;
      if (substitution != null) {
        jsAst.Expression body =
            _rtiEncoder.getSubstitutionCode(emitterTask.emitter, substitution);
        result.addSubstitution(
            checkedClass, _namer.substitutionName(checkedClass), body);
      }
    }

    _generateIsTestsOn(
        classElement,
        generateIsTest,
        generateFunctionTypeSignature,
        (ClassEntity e, {bool emitNull: false}) =>
            generateSubstitution(e, emitNull: emitNull),
        generateTypeCheck);

    if (classElement == _commonElements.jsJavaScriptFunctionClass) {
      var type = _jsInteropAnalysis.buildJsFunctionType();
      if (type != null) {
        jsAst.Expression thisAccess = new jsAst.This();
        jsAst.Expression encoding = _rtiEncoder.getSignatureEncoding(
            emitterTask.emitter, type, thisAccess);
        jsAst.Name operatorSignature = _namer.asName(_namer.operatorSignature);
        result.addSignature(classElement, operatorSignature, encoding);
      }
    }
    return result;
  }

  /**
   * Generate "is tests" for [cls] itself, and the "is tests" for the
   * classes it implements and type argument substitution functions for these
   * tests.   We don't need to add the "is tests" of the super class because
   * they will be inherited at runtime, but we may need to generate the
   * substitutions, because they may have changed.
   */
  void _generateIsTestsOn(
      ClassEntity cls,
      void generateIsTest(ClassEntity element),
      FunctionTypeSignatureEmitter generateFunctionTypeSignature,
      SubstitutionEmitter generateSubstitution,
      void emitTypeCheck(TypeCheck check)) {
    Setlet<ClassEntity> generated = new Setlet<ClassEntity>();

    if (checkedClasses.contains(cls)) {
      generateIsTest(cls);
      generateSubstitution(cls);
      generated.add(cls);
    }

    // Precomputed is checks.
    TypeChecks typeChecks = _rtiChecks.requiredChecks;
    Iterable<TypeCheck> classChecks = typeChecks[cls];
    if (classChecks != null) {
      for (TypeCheck check in classChecks) {
        if (!generated.contains(check.cls)) {
          emitTypeCheck(check);
          generated.add(check.cls);
        }
      }
    }

    ClassEntity superclass = _elementEnvironment.getSuperClass(cls);

    bool haveSameTypeVariables(ClassEntity a, ClassEntity b) {
      if (a.isClosure) return true;
      return _rtiSubstitutions.isTrivialSubstitution(a, b);
    }

    bool supertypesNeedSubstitutions = false;

    if (superclass != null &&
        superclass != _commonElements.objectClass &&
        !haveSameTypeVariables(cls, superclass)) {
      // We cannot inherit the generated substitutions, because the type
      // variable layout for this class is different.  Instead we generate
      // substitutions for all checks and make emitSubstitution a NOP for the
      // rest of this function.

      // TODO(karlklose): move the computation of these checks to
      // RuntimeTypeInformation.
      while (superclass != null) {
        if (_rtiNeed.classNeedsRti(superclass)) {
          generateSubstitution(superclass, emitNull: true);
          generated.add(superclass);
        }
        superclass = _elementEnvironment.getSuperClass(superclass);
      }
      supertypesNeedSubstitutions = true;
    }

    if (cls is MixinApplicationElement) {
      supertypesNeedSubstitutions = true;
    }

    if (supertypesNeedSubstitutions) {
      _elementEnvironment.forEachSupertype(cls, (InterfaceType supertype) {
        ClassEntity superclass = supertype.element;
        if (generated.contains(superclass)) return;

        if (classesUsingTypeVariableTests.contains(superclass) ||
            _rtiNeed.classUsesTypeVariableExpression(superclass) ||
            checkedClasses.contains(superclass)) {
          // Generate substitution.  If no substitution is necessary, emit
          // `null` to overwrite a (possibly) existing substitution from the
          // super classes.
          generateSubstitution(superclass, emitNull: true);
        }
      });

      void emitNothing(_, {emitNull}) {}

      generateSubstitution = emitNothing;
    }

    // A class that defines a `call` method implicitly implements
    // [Function] and needs checks for all typedefs that are used in is-checks.
    if (checkedClasses.contains(_commonElements.functionClass) ||
        checkedFunctionTypes.isNotEmpty) {
      MemberEntity call =
          _elementEnvironment.lookupClassMember(cls, Identifiers.call);
      if (call != null && call.isFunction) {
        FunctionEntity callFunction = call;
        // A superclass might already implement the Function interface. In such
        // a case, we can avoid emitting the is test here.
        ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
        if (!_closedWorld.isSubtypeOf(
            superclass, _commonElements.functionClass)) {
          _generateInterfacesIsTests(_commonElements.functionClass,
              generateIsTest, generateSubstitution, generated);
        }
        FunctionType callType =
            _elementEnvironment.getFunctionType(callFunction);
        generateFunctionTypeSignature(callFunction, callType);
      }
    }

    for (InterfaceType interfaceType in _types.getInterfaces(cls)) {
      _generateInterfacesIsTests(interfaceType.element, generateIsTest,
          generateSubstitution, generated);
    }
  }

  /**
   * Generate "is tests" where [cls] is being implemented.
   */
  void _generateInterfacesIsTests(
      ClassEntity cls,
      void generateIsTest(ClassEntity element),
      SubstitutionEmitter generateSubstitution,
      Set<ClassEntity> alreadyGenerated) {
    void tryEmitTest(ClassEntity check) {
      if (!alreadyGenerated.contains(check) && checkedClasses.contains(check)) {
        alreadyGenerated.add(check);
        generateIsTest(check);
        generateSubstitution(check);
      }
    }

    tryEmitTest(cls);

    for (InterfaceType interfaceType in _types.getInterfaces(cls)) {
      ClassEntity element = interfaceType.element;
      tryEmitTest(element);
      _generateInterfacesIsTests(
          element, generateIsTest, generateSubstitution, alreadyGenerated);
    }

    // We need to also emit "is checks" for the superclass and its supertypes.
    ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
    if (superclass != null) {
      tryEmitTest(superclass);
      _generateInterfacesIsTests(
          superclass, generateIsTest, generateSubstitution, alreadyGenerated);
    }
  }
}
