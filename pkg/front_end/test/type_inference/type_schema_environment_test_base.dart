// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/source/source_library_builder.dart';
import 'package:front_end/src/type_inference/type_constraint_gatherer.dart';
import 'package:front_end/src/type_inference/type_inference_engine.dart';
import 'package:front_end/src/type_inference/type_schema.dart';
import 'package:front_end/src/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/type_parser_environment.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';

abstract class TypeSchemaEnvironmentTestBase {
  late Env typeParserEnvironment;
  late TypeSchemaEnvironment typeSchemaEnvironment;

  final Map<String, DartType Function()> additionalTypes = {
    "UNKNOWN": () => new UnknownType(),
  };

  late Library _coreLibrary;
  late Library _testLibrary;

  Library get coreLibrary => _coreLibrary;
  Library get testLibrary => _testLibrary;

  Component get component => typeParserEnvironment.component;
  CoreTypes get coreTypes => typeParserEnvironment.coreTypes;

  late final OperationsCfe _operations;

  void parseTestLibrary(String testLibraryText) {
    typeParserEnvironment = new Env(testLibraryText);
    typeSchemaEnvironment = new TypeSchemaEnvironment(
        coreTypes, new ClassHierarchy(component, coreTypes));
    assert(
        typeParserEnvironment.component.libraries.length == 2,
        "The tests are supposed to have exactly two libraries: "
        "the core library and the test library.");
    _operations = new OperationsCfe(typeSchemaEnvironment,
        fieldNonPromotabilityInfo: FieldNonPromotabilityInfo(
            fieldNameInfo: {}, individualPropertyReasons: {}),
        typeCacheNonNullable: {},
        typeCacheNullable: {},
        typeCacheLegacy: {});
    Library firstLibrary = typeParserEnvironment.component.libraries.first;
    Library secondLibrary = typeParserEnvironment.component.libraries.last;
    if (firstLibrary.importUri.isScheme("dart") &&
        firstLibrary.importUri.path == "core") {
      _coreLibrary = firstLibrary;
      _testLibrary = secondLibrary;
    } else {
      assert(
          secondLibrary.importUri.isScheme("dart") &&
              secondLibrary.importUri.path == "core",
          "One of the libraries is expected to be 'dart:core'.");
      _coreLibrary == secondLibrary;
      _testLibrary = firstLibrary;
    }
  }

  void checkConstraintSolving(String constraint, String expected,
      {required bool grounded}) {
    expect(
        _operations.chooseTypeFromConstraint(parseConstraint(constraint),
            grounded: grounded, isContravariant: false),
        parseType(expected));
  }

  void checkConstraintUpperBound(
      {required String constraint, required String bound}) {
    expect(parseConstraint(constraint).upper, parseType(bound));
  }

  void checkConstraintLowerBound(
      {required String constraint, required String bound}) {
    expect(parseConstraint(constraint).lower, parseType(bound));
  }

  void checkTypeSatisfiesConstraint(String type, String constraint) {
    expect(
        typeSchemaEnvironment.typeSatisfiesConstraint(
            parseType(type), parseConstraint(constraint)),
        isTrue);
  }

  void checkTypeDoesntSatisfyConstraint(String type, String constraint) {
    expect(
        typeSchemaEnvironment.typeSatisfiesConstraint(
            parseType(type), parseConstraint(constraint)),
        isFalse);
  }

  void checkIsSubtype(String subtype, String supertype) {
    expect(
        typeSchemaEnvironment
            .performSubtypeCheck(parseType(subtype), parseType(supertype))
            .isSuccess(),
        isTrue);
  }

  void checkIsNotSubtype(String subtype, String supertype) {
    expect(
        typeSchemaEnvironment
            .performSubtypeCheck(parseType(subtype), parseType(supertype))
            .isSuccess(),
        isFalse);
  }

  void checkLowerBound(
      {required String type1,
      required String type2,
      required String lowerBound,
      String? typeParameters}) {
    typeParserEnvironment.withTypeParameters(typeParameters,
        (List<TypeParameter> typeParameterNodes) {
      expect(
          typeSchemaEnvironment.getStandardLowerBound(
              parseType(type1), parseType(type2)),
          parseType(lowerBound));
    });
  }

  void checkInference(
      {required String typeParametersToInfer,
      required String functionType,
      String? actualParameterTypes,
      String? returnContextType,
      String? inferredTypesFromDownwardPhase,
      required String expectedTypes}) {
    typeParserEnvironment.withStructuralParameters(typeParametersToInfer,
        (List<StructuralParameter> typeParameterNodesToInfer) {
      FunctionType functionTypeNode = parseType(functionType) as FunctionType;
      DartType? returnContextTypeNode =
          returnContextType == null ? null : parseType(returnContextType);
      List<DartType>? actualTypeNodes = actualParameterTypes == null
          ? null
          : parseTypes(actualParameterTypes);
      List<DartType> expectedTypeNodes = parseTypes(expectedTypes);
      DartType declaredReturnTypeNode = functionTypeNode.returnType;
      List<DartType>? formalTypeNodes = actualParameterTypes == null
          ? null
          : functionTypeNode.positionalParameters;

      List<DartType>? inferredTypeNodes;
      if (inferredTypesFromDownwardPhase == null) {
        inferredTypeNodes = null;
      } else {
        inferredTypeNodes = parseTypes(inferredTypesFromDownwardPhase);
      }

      TypeConstraintGatherer gatherer =
          typeSchemaEnvironment.setupGenericTypeInference(
              declaredReturnTypeNode,
              typeParameterNodesToInfer,
              returnContextTypeNode,
              inferenceUsingBoundsIsEnabled: false,
              typeOperations: new OperationsCfe(typeSchemaEnvironment,
                  fieldNonPromotabilityInfo: new FieldNonPromotabilityInfo(
                      fieldNameInfo: {}, individualPropertyReasons: {}),
                  typeCacheNonNullable: {},
                  typeCacheNullable: {},
                  typeCacheLegacy: {}),
              inferenceResultForTesting: null,
              treeNodeForTesting: null);
      if (formalTypeNodes == null) {
        inferredTypeNodes = typeSchemaEnvironment.choosePreliminaryTypes(
            gatherer, typeParameterNodesToInfer, inferredTypeNodes,
            inferenceUsingBoundsIsEnabled: true,
            dataForTesting: null,
            treeNodeForTesting: null);
      } else {
        gatherer.constrainArguments(formalTypeNodes, actualTypeNodes!,
            treeNodeForTesting: null);
        inferredTypeNodes = typeSchemaEnvironment.chooseFinalTypes(
            gatherer, typeParameterNodesToInfer, inferredTypeNodes!,
            inferenceUsingBoundsIsEnabled: true,
            dataForTesting: null,
            treeNodeForTesting: null);
      }

      assert(
          inferredTypeNodes.length == expectedTypeNodes.length,
          "The numbers of expected types and type parameters to infer "
          "mismatch.");
      for (int i = 0; i < inferredTypeNodes.length; ++i) {
        expect(inferredTypeNodes[i], expectedTypeNodes[i]);
      }
    });
  }

  void checkInferenceFromConstraints(
      {required String typeParameter,
      required String constraints,
      String? inferredTypeFromDownwardPhase,
      required bool downwardsInferPhase,
      required String expected}) {
    assert(inferredTypeFromDownwardPhase == null || !downwardsInferPhase);

    typeParserEnvironment.withStructuralParameters(typeParameter,
        (List<StructuralParameter> typeParameterNodes) {
      assert(typeParameterNodes.length == 1);

      MergedTypeConstraint typeConstraint = parseConstraint(constraints);
      DartType expectedTypeNode = parseType(expected);
      StructuralParameter typeParameterNode = typeParameterNodes.single;
      List<DartType>? inferredTypeNodes = inferredTypeFromDownwardPhase == null
          ? null
          : <DartType>[parseType(inferredTypeFromDownwardPhase)];

      inferredTypeNodes = typeSchemaEnvironment.inferTypeFromConstraints(
          {typeParameterNode: typeConstraint},
          [typeParameterNode],
          inferredTypeNodes,
          preliminary: downwardsInferPhase,
          inferenceUsingBoundsIsEnabled: true,
          dataForTesting: null,
          operations: _operations);

      expect(inferredTypeNodes.single, expectedTypeNode);
    });
  }

  void checkTypeShapeCheckSufficiency(
      {required String expressionStaticType,
      required String checkTargetType,
      required String typeParameters,
      required TypeShapeCheckSufficiency sufficiency});

  /// Parses a string like "<: T <: S >: R" into a [TypeConstraint].
  ///
  /// The [constraint] string is assumed to be a sequence of bounds added to the
  /// constraint.  Each element of the sequence is either "<: T" or ":> T",
  /// where the former adds an upper bound and the latter adds a lower bound.
  /// The bounds are added to the constraint in the order they are mentioned in
  /// the [constraint] string, from left to right.
  MergedTypeConstraint parseConstraint(String constraint) {
    MergedTypeConstraint result = new MergedTypeConstraint(
        lower: SharedTypeSchemaView(const UnknownType()),
        upper: SharedTypeSchemaView(const UnknownType()),
        origin: const UnknownTypeConstraintOrigin());
    List<String> upperBoundSegments = constraint.split("<:");
    bool firstUpperBoundSegment = true;
    for (String upperBoundSegment in upperBoundSegments) {
      if (firstUpperBoundSegment) {
        firstUpperBoundSegment = false;
        if (upperBoundSegment.isEmpty) {
          continue;
        }
      }
      List<String> lowerBoundSegments = upperBoundSegment.split(":>");
      bool firstLowerBoundSegment = true;
      for (String segment in lowerBoundSegments) {
        if (firstLowerBoundSegment) {
          firstLowerBoundSegment = false;
          if (segment.isNotEmpty) {
            result.mergeInTypeSchemaUpper(
                SharedTypeSchemaView(parseType(segment)), _operations);
          }
        } else {
          result.mergeInTypeSchemaLower(
              SharedTypeSchemaView(parseType(segment)), _operations);
        }
      }
    }
    return result;
  }

  DartType parseType(String type) {
    return typeParserEnvironment.parseType(type,
        additionalTypes: additionalTypes);
  }

  List<DartType> parseTypes(String types) {
    return typeParserEnvironment.parseTypes(types,
        additionalTypes: additionalTypes);
  }
}
