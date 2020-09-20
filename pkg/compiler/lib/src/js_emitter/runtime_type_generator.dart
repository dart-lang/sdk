// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.runtime_type_generator;

import '../common_elements.dart' show CommonElements;
import '../deferred_load.dart' show OutputUnit, OutputUnitData;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/namer.dart' show Namer;
import '../js_backend/runtime_types.dart' show RuntimeTypesChecks;
import '../js_backend/runtime_types_codegen.dart'
    show ClassChecks, ClassFunctionType, TypeCheck;
import '../js_emitter/sorter.dart';
import '../util/util.dart' show Setlet;

import 'code_emitter_task.dart' show CodeEmitterTask;

// Function signatures used in the generation of runtime type information.
typedef void FunctionTypeSignatureEmitter(ClassFunctionType classFunctionType);

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
  final OutputUnitData _outputUnitData;
  final CodeEmitterTask emitterTask;
  final Namer _namer;
  final RuntimeTypesChecks _rtiChecks;
  final _TypeContainedInOutputUnitVisitor _outputUnitVisitor;

  RuntimeTypeGenerator(CommonElements _commonElements, this._outputUnitData,
      this.emitterTask, this._namer, this._rtiChecks)
      : _outputUnitVisitor = new _TypeContainedInOutputUnitVisitor(
            _commonElements, _outputUnitData);

  /// Generate "is tests" for [cls] itself, and the "is tests" for the
  /// classes it implements and type argument substitution functions for these
  /// tests.   We don't need to add the "is tests" of the super class because
  /// they will be inherited at runtime, but we may need to generate the
  /// substitutions, because they may have changed.

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

    // TODO(johnniwinther): Include function signatures in [ClassChecks].
    void generateFunctionTypeSignature(ClassFunctionType classFunctionType) {
      FunctionEntity method = classFunctionType.callFunction;
      FunctionType type = classFunctionType.callType;

      // TODO(johnniwinther): Avoid unneeded function type indices or
      // signatures. We either need them for mirrors or because [type] is
      // potentially a subtype of a checked function. Currently we eagerly
      // generate a function type index or signature for all callable classes.
      jsAst.Expression functionTypeIndex;
      bool isDeferred = false;
      if (!type.containsTypeVariables) {
        // TODO(sigmund): use output unit of [method] when the classes mentioned
        // in [type] aren't in the main output unit. (Issue #31032)
        OutputUnit mainOutputUnit = _outputUnitData.mainOutputUnit;
        if (_outputUnitVisitor.isTypeContainedIn(type, mainOutputUnit)) {
          functionTypeIndex =
              emitterTask.metadataCollector.reifyType(type, mainOutputUnit);
        } else if (!storeFunctionTypeInMetadata) {
          // TODO(johnniwinther): Support sharing deferred signatures with the
          // full emitter.
          isDeferred = true;
          functionTypeIndex = emitterTask.metadataCollector
              .reifyType(type, _outputUnitData.outputUnitForMember(method));
        }
      }
      if (storeFunctionTypeInMetadata && functionTypeIndex != null) {
        result.functionTypeIndex = functionTypeIndex;
      } else {
        jsAst.Expression encoding =
            generatedCode[classFunctionType.signatureFunction];
        if (classFunctionType.signatureFunction == null) {
          // The signature function isn't live.
          return;
        }
        if (functionTypeIndex != null) {
          if (isDeferred) {
            // The function type index must be offset by the number of types
            // already loaded.
            encoding = new jsAst.Binary(
                '+',
                new jsAst.VariableUse(_namer.typesOffsetName),
                functionTypeIndex);
          } else {
            encoding = functionTypeIndex;
          }
        }
        if (encoding != null) {
          jsAst.Name operatorSignature =
              _namer.asName(_namer.fixedNames.operatorSignature);
          result.addSignature(classElement, operatorSignature, encoding);
        }
      }
    }

    void generateTypeCheck(TypeCheck check) {
      ClassEntity checkedClass = check.cls;
      if (check.needsIs) {
        result.addIsTest(
            checkedClass, _namer.operatorIs(checkedClass), js('1'));
      }
    }

    _generateIsTestsOn(
        classElement, generateFunctionTypeSignature, generateTypeCheck);

    return result;
  }

  void _generateIsTestsOn(
      ClassEntity cls,
      FunctionTypeSignatureEmitter generateFunctionTypeSignature,
      void emitTypeCheck(TypeCheck check)) {
    Setlet<ClassEntity> generated = new Setlet<ClassEntity>();

    // Precomputed is checks.
    ClassChecks classChecks = _rtiChecks.requiredChecks[cls];
    Iterable<TypeCheck> typeChecks = classChecks.checks;
    if (typeChecks != null) {
      for (TypeCheck typeCheck in typeChecks) {
        if (!generated.contains(typeCheck.cls)) {
          emitTypeCheck(typeCheck);
          generated.add(typeCheck.cls);
        }
      }
    }

    if (classChecks.functionType != null) {
      generateFunctionTypeSignature(classChecks.functionType);
    }
  }
}

/// Visitor that checks whether a type is contained within one output unit.
class _TypeContainedInOutputUnitVisitor
    implements DartTypeVisitor<bool, OutputUnit> {
  final CommonElements _commonElements;
  final OutputUnitData _outputUnitData;

  _TypeContainedInOutputUnitVisitor(this._commonElements, this._outputUnitData);

  /// Returns `true` if all classes mentioned in [type] are in [outputUnit].
  bool isTypeContainedIn(DartType type, OutputUnit outputUnit) =>
      visit(type, outputUnit);

  @override
  bool visit(DartType type, OutputUnit argument) => type.accept(this, argument);

  bool visitList(List<DartType> types, OutputUnit argument) {
    for (DartType type in types) {
      if (!visit(type, argument)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool visitLegacyType(LegacyType type, OutputUnit argument) =>
      visit(type.baseType, argument);

  @override
  bool visitNullableType(NullableType type, OutputUnit argument) =>
      visit(type.baseType, argument);

  @override
  bool visitNeverType(NeverType type, OutputUnit argument) => true;

  @override
  bool visitFutureOrType(FutureOrType type, OutputUnit argument) {
    if (_outputUnitData.outputUnitForClass(_commonElements.functionClass) !=
        argument) {
      return false;
    }
    return visit(type.typeArgument, argument);
  }

  @override
  bool visitDynamicType(DynamicType type, OutputUnit argument) => true;

  @override
  bool visitErasedType(ErasedType type, OutputUnit argument) => true;

  @override
  bool visitAnyType(AnyType type, OutputUnit argument) => true;

  @override
  bool visitInterfaceType(InterfaceType type, OutputUnit argument) {
    if (_outputUnitData.outputUnitForClassType(type.element) != argument) {
      return false;
    }
    return visitList(type.typeArguments, argument);
  }

  @override
  bool visitFunctionType(FunctionType type, OutputUnit argument) {
    bool result = visit(type.returnType, argument) &&
        visitList(type.parameterTypes, argument) &&
        visitList(type.optionalParameterTypes, argument) &&
        visitList(type.namedParameterTypes, argument);
    if (!result) return false;
    for (FunctionTypeVariable typeVariable in type.typeVariables) {
      if (!visit(typeVariable.bound, argument)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool visitFunctionTypeVariable(
      FunctionTypeVariable type, OutputUnit argument) {
    return true;
  }

  @override
  bool visitTypeVariableType(TypeVariableType type, OutputUnit argument) {
    return false;
  }

  @override
  bool visitVoidType(VoidType type, OutputUnit argument) {
    return true;
  }
}
