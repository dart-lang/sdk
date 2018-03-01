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
import '../deferred_load.dart' show OutputUnit, OutputUnitData;
import '../elements/elements.dart' show ClassElement, MethodElement;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/js_interop_analysis.dart';
import '../js_backend/namer.dart' show Namer;
import '../js_backend/runtime_types.dart'
    show
        RuntimeTypesChecks,
        RuntimeTypesEncoder,
        Substitution,
        TypeCheck,
        TypeChecks;
import '../js_emitter/sorter.dart';
import '../js_model/closure.dart' show JClosureField;
import '../util/util.dart' show Setlet;

import 'code_emitter_task.dart' show CodeEmitterTask;
import 'type_test_registry.dart' show TypeTestRegistry;

// Function signatures used in the generation of runtime type information.
typedef void FunctionTypeSignatureEmitter(
    FunctionEntity method, FunctionType methodType);

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
  final ClosureConversionTask _closureDataLookup;
  final OutputUnitData _outputUnitData;
  final CodeEmitterTask emitterTask;
  final Namer _namer;
  final RuntimeTypesChecks _rtiChecks;
  final RuntimeTypesEncoder _rtiEncoder;
  final JsInteropAnalysis _jsInteropAnalysis;
  final bool _useKernel;
  final bool _strongMode;
  final bool _disableRtiOptimization;

  RuntimeTypeGenerator(
      this._elementEnvironment,
      this._commonElements,
      this._closureDataLookup,
      this._outputUnitData,
      this.emitterTask,
      this._namer,
      this._rtiChecks,
      this._rtiEncoder,
      this._jsInteropAnalysis,
      this._useKernel,
      this._strongMode,
      this._disableRtiOptimization);

  TypeTestRegistry get _typeTestRegistry => emitterTask.typeTestRegistry;

  Iterable<ClassEntity> get checkedClasses =>
      _typeTestRegistry.rtiChecks.checkedClasses;

  Iterable<ClassEntity> get classesUsingTypeVariableTests =>
      _typeTestRegistry.rtiChecks.classesUsingTypeVariableTests;

  Iterable<FunctionType> get checkedFunctionTypes =>
      _typeTestRegistry.rtiChecks.checkedFunctionTypes;

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
      Map<MemberEntity, jsAst.Expression> generatedCode,
      {bool storeFunctionTypeInMetadata: true}) {
    TypeTestProperties result = new TypeTestProperties();

    assert(!(classElement is ClassElement && !classElement.isDeclaration),
        failedAt(classElement));

    // TODO(johnniwinther): Include function signatures in [ClassChecks].
    void generateFunctionTypeSignature(
        FunctionEntity method, FunctionType type) {
      assert(!(method is MethodElement && !method.isImplementation));
      jsAst.Expression thisAccess = new jsAst.This();
      if (method.enclosingClass.isClosure) {
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
        OutputUnit outputUnit = _outputUnitData.mainOutputUnit;
        result.functionTypeIndex =
            emitterTask.metadataCollector.reifyType(type, outputUnit);
      } else {
        jsAst.Expression encoding;
        MemberEntity signature = _elementEnvironment.lookupLocalClassMember(
            method.enclosingClass, Identifiers.signature);
        if (_useKernel &&
            signature != null &&
            generatedCode[signature] != null) {
          encoding = generatedCode[signature];
        } else {
          // With Dart 2, if disableRtiOptimization is true, then we might
          // generate some code for classes that are not actually called,
          // so following this path is "okay." Also, classes that have call
          // methods are no longer a subtype of Function (and therefore we don't
          // create a closure class), so this path is also acceptable.

          // TODO(efortuna, johnniwinther): Verify that closures that use this
          // path are in fact dead code. If this *not* actually dead code, we
          // get to this point because TrivialRuntimeTypesChecksBuilder
          // specifies that every subtype of Object and its types is "used"
          // (ClassUse = true). However, on the codegen side, we only codegen
          // entities that are actually reachable via treeshaking. To solve this
          // issue, if disableRtiOptimization is turned on, we could literally
          // in world_impact.dart loop through every subclass of Object and say
          // that all types related to JClosureClasses are "used" so the go
          // through the codegen queue and therefore we generate code for it.
          // This seems not ideal though.
          assert(!(_useKernel && _strongMode && !_disableRtiOptimization) ||
              (_useKernel && _strongMode && !method.enclosingClass.isClosure));
          encoding = _rtiEncoder.getSignatureEncoding(
              emitterTask.emitter, type, thisAccess);
        }
        jsAst.Name operatorSignature = _namer.asName(_namer.operatorSignature);
        result.addSignature(classElement, operatorSignature, encoding);
      }
    }

    void generateTypeCheck(TypeCheck check) {
      ClassEntity checkedClass = check.cls;
      if (check.needsIs) {
        result.addIsTest(
            checkedClass, _namer.operatorIs(checkedClass), js('1'));
      }
      Substitution substitution = check.substitution;
      if (substitution != null) {
        jsAst.Expression body =
            _rtiEncoder.getSubstitutionCode(emitterTask.emitter, substitution);
        result.addSubstitution(
            checkedClass, _namer.substitutionName(checkedClass), body);
      }
    }

    _generateIsTestsOn(
        classElement, generateFunctionTypeSignature, generateTypeCheck);

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
      FunctionTypeSignatureEmitter generateFunctionTypeSignature,
      void emitTypeCheck(TypeCheck check)) {
    Setlet<ClassEntity> generated = new Setlet<ClassEntity>();

    // Precomputed is checks.
    TypeChecks typeChecks = _rtiChecks.requiredChecks;
    Iterable<TypeCheck> classChecks = typeChecks[cls].checks;
    if (classChecks != null) {
      for (TypeCheck check in classChecks) {
        if (!generated.contains(check.cls)) {
          emitTypeCheck(check);
          generated.add(check.cls);
        }
      }
    }

    // A class that defines a `call` method implicitly implements
    // [Function] and needs checks for all typedefs that are used in is-checks.
    if (checkedClasses.contains(_commonElements.functionClass) ||
        checkedFunctionTypes.isNotEmpty) {
      MemberEntity call =
          _elementEnvironment.lookupLocalClassMember(cls, Identifiers.call);
      if (call != null && call.isFunction) {
        FunctionEntity callFunction = call;
        FunctionType callType =
            _elementEnvironment.getFunctionType(callFunction);
        generateFunctionTypeSignature(callFunction, callType);
      }
    }
  }
}
