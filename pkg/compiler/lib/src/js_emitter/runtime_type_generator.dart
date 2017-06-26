// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.runtime_type_generator;

import '../closure.dart'
    show ClosureRepresentationInfo, ClosureFieldElement, ClosureConversionTask;
import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements;
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionFunctionType, ResolutionInterfaceType;
import '../elements/elements.dart'
    show ClassElement, Element, FunctionElement, MixinApplicationElement;
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
import '../util/util.dart' show Setlet;

import 'code_emitter_task.dart' show CodeEmitterTask;
import 'type_test_registry.dart' show TypeTestRegistry;

// Function signatures used in the generation of runtime type information.
typedef void FunctionTypeSignatureEmitter(
    Element method, ResolutionFunctionType methodType);

typedef void SubstitutionEmitter(Element element, {bool emitNull});

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
  /// JS constructor of the [ClassElement] for which the is checks were
  /// generated.
  final Map<jsAst.Name, jsAst.Node> properties = <jsAst.Name, jsAst.Node>{};
}

class RuntimeTypeGenerator {
  final CommonElements _commonElements;
  final ClosureConversionTask _closureDataLookup;
  final CodeEmitterTask emitterTask;
  final Namer _namer;
  final NativeData _nativeData;
  final RuntimeTypesChecks _rtiChecks;
  final RuntimeTypesEncoder _rtiEncoder;
  final RuntimeTypesNeed _rtiNeed;
  final RuntimeTypesSubstitutions _rtiSubstitutions;
  final JsInteropAnalysis _jsInteropAnalysis;

  RuntimeTypeGenerator(
      this._commonElements,
      this._closureDataLookup,
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
  TypeTestProperties generateIsTests(ClassEntity cls,
      {bool storeFunctionTypeInMetadata: true}) {
    TypeTestProperties result = new TypeTestProperties();
    if (cls is! ClassElement) return result;

    // TODO(redemption): Handle class entities.
    ClassElement classElement = cls;
    assert(classElement.isDeclaration, failedAt(classElement));

    /// Generates an is-test if the test is not inherited from a superclass
    /// This assumes that for every class an is-tests is generated
    /// dynamically at runtime. We also always generate tests against
    /// native classes.
    /// TODO(herhut): Generate tests for native classes dynamically, as well.
    void generateIsTest(ClassElement other) {
      if (_nativeData.isNativeClass(classElement) ||
          !classElement.isSubclassOf(other)) {
        result.properties[_namer.operatorIs(other)] = js('1');
      }
    }

    void generateFunctionTypeSignature(
        FunctionElement method, ResolutionFunctionType type) {
      assert(method.isImplementation);
      jsAst.Expression thisAccess = new jsAst.This();
      if (!method.isAbstract) {
        ClosureRepresentationInfo closureData =
            _closureDataLookup.getClosureRepresentationInfo(method);
        if (closureData != null) {
          ClosureFieldElement thisLocal = closureData.thisFieldEntity;
          if (thisLocal != null) {
            jsAst.Name thisName = _namer.instanceFieldPropertyName(thisLocal);
            thisAccess = js('this.#', thisName);
          }
        }
      }

      if (storeFunctionTypeInMetadata && !type.containsTypeVariables) {
        result.functionTypeIndex =
            emitterTask.metadataCollector.reifyType(type);
      } else {
        jsAst.Expression encoding = _rtiEncoder.getSignatureEncoding(
            emitterTask.emitter, type, thisAccess);
        jsAst.Name operatorSignature = _namer.asName(_namer.operatorSignature);
        result.properties[operatorSignature] = encoding;
      }
    }

    void generateSubstitution(ClassElement cls, {bool emitNull: false}) {
      if (cls.typeVariables.isEmpty) return;
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
        result.properties[_namer.substitutionName(cls)] = expression;
      }
    }

    void generateTypeCheck(TypeCheck check) {
      ClassElement checkedClass = check.cls;
      generateIsTest(checkedClass);
      Substitution substitution = check.substitution;
      if (substitution != null) {
        jsAst.Expression body =
            _rtiEncoder.getSubstitutionCode(emitterTask.emitter, substitution);
        result.properties[_namer.substitutionName(checkedClass)] = body;
      }
    }

    _generateIsTestsOn(classElement, (Element e) {
      generateIsTest(e);
    }, (Element e, ResolutionFunctionType t) {
      generateFunctionTypeSignature(e, t);
    },
        (Element e, {bool emitNull: false}) =>
            generateSubstitution(e, emitNull: emitNull),
        generateTypeCheck);

    if (classElement == _commonElements.jsJavaScriptFunctionClass) {
      var type = _jsInteropAnalysis.buildJsFunctionType();
      if (type != null) {
        jsAst.Expression thisAccess = new jsAst.This();
        jsAst.Expression encoding = _rtiEncoder.getSignatureEncoding(
            emitterTask.emitter, type, thisAccess);
        jsAst.Name operatorSignature = _namer.asName(_namer.operatorSignature);
        result.properties[operatorSignature] = encoding;
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
      ClassElement cls,
      void generateIsTest(Element element),
      FunctionTypeSignatureEmitter generateFunctionTypeSignature,
      SubstitutionEmitter generateSubstitution,
      void emitTypeCheck(TypeCheck check)) {
    Setlet<ClassElement> generated = new Setlet<ClassElement>();

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

    ClassElement superclass = cls.superclass;

    bool haveSameTypeVariables(ClassElement a, ClassElement b) {
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
        superclass = superclass.superclass;
      }
      supertypesNeedSubstitutions = true;
    }

    if (cls is MixinApplicationElement) {
      supertypesNeedSubstitutions = true;
    }

    if (supertypesNeedSubstitutions) {
      for (ResolutionInterfaceType supertype in cls.allSupertypes) {
        ClassElement superclass = supertype.element;
        if (generated.contains(superclass)) continue;

        if (classesUsingTypeVariableTests.contains(superclass) ||
            _rtiNeed.classUsesTypeVariableExpression(superclass) ||
            checkedClasses.contains(superclass)) {
          // Generate substitution.  If no substitution is necessary, emit
          // `null` to overwrite a (possibly) existing substitution from the
          // super classes.
          generateSubstitution(superclass, emitNull: true);
        }
      }

      void emitNothing(_, {emitNull}) {}

      generateSubstitution = emitNothing;
    }

    // A class that defines a `call` method implicitly implements
    // [Function] and needs checks for all typedefs that are used in is-checks.
    if (checkedClasses.contains(_commonElements.functionClass) ||
        checkedFunctionTypes.isNotEmpty) {
      Element call = cls.lookupLocalMember(Identifiers.call);
      if (call == null) {
        // If [cls] is a closure, it has a synthetic call operator method.
        call = cls.lookupConstructorBody(Identifiers.call);
      }
      if (call != null && call.isFunction) {
        FunctionElement callFunction = call;
        // A superclass might already implement the Function interface. In such
        // a case, we can avoid emitting the is test here.
        if (!cls.superclass.implementsFunction(_commonElements)) {
          _generateInterfacesIsTests(_commonElements.functionClass,
              generateIsTest, generateSubstitution, generated);
        }
        ResolutionFunctionType callType = callFunction.type;
        generateFunctionTypeSignature(callFunction, callType);
      }
    }

    for (ResolutionDartType interfaceType in cls.interfaces) {
      _generateInterfacesIsTests(interfaceType.element, generateIsTest,
          generateSubstitution, generated);
    }
  }

  /**
   * Generate "is tests" where [cls] is being implemented.
   */
  void _generateInterfacesIsTests(
      ClassElement cls,
      void generateIsTest(ClassElement element),
      SubstitutionEmitter generateSubstitution,
      Set<Element> alreadyGenerated) {
    void tryEmitTest(ClassElement check) {
      if (!alreadyGenerated.contains(check) && checkedClasses.contains(check)) {
        alreadyGenerated.add(check);
        generateIsTest(check);
        generateSubstitution(check);
      }
    }

    tryEmitTest(cls);

    for (ResolutionDartType interfaceType in cls.interfaces) {
      Element element = interfaceType.element;
      tryEmitTest(element);
      _generateInterfacesIsTests(
          element, generateIsTest, generateSubstitution, alreadyGenerated);
    }

    // We need to also emit "is checks" for the superclass and its supertypes.
    ClassElement superclass = cls.superclass;
    if (superclass != null) {
      tryEmitTest(superclass);
      _generateInterfacesIsTests(
          superclass, generateIsTest, generateSubstitution, alreadyGenerated);
    }
  }
}
