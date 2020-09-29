// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart';
import '../elements/types.dart';
import '../ir/scope_visitor.dart';
import '../js_model/elements.dart' show JField;
import '../js_model/js_world_builder.dart';
import '../kernel/element_map.dart';
import '../kernel/kernel_strategy.dart';
import '../kernel/kelements.dart' show KClass, KField, KConstructor;
import '../kernel/kernel_world.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/member_usage.dart';

/// AllocatorAnalysis
///
/// Analysis to determine features of the allocator functions. The allocator
/// function takes parameters for each field initializer and initializes the
/// fields.  Parameters may be omitted if the initializer is always the same
/// constant value.  How the allocator is emitted will determine what kind of
/// constants can be handled.  The initial implementation only permits `null`.

// TODO(sra): Analysis to determine field order. Current field order is
// essentially declaration order, subclass first. We can reorder fields so that
// fields initialized with the same constant are together to allow chained
// initialization. Fields of a class and superclass can be reordered to allow
// chaining, e.g.
//
//     this.x = this.z = null;
//
class KFieldAnalysis {
  final KernelToElementMap _elementMap;

  final Map<KClass, ClassData> _classData = {};
  final Map<KField, StaticFieldData> _staticFieldData = {};

  KFieldAnalysis(KernelFrontendStrategy kernelStrategy)
      : _elementMap = kernelStrategy.elementMap;

  // Register class during resolution. Use simple syntactic analysis to find
  // null-initialized fields.
  void registerInstantiatedClass(KClass class_) {
    ir.Class classNode = _elementMap.getClassNode(class_);

    List<KConstructor> constructors = [];
    Map<KField, AllocatorData> fieldData = {};
    for (ir.Field field in classNode.fields) {
      if (!field.isInstanceMember) continue;

      FieldEntity fieldElement = _elementMap.getField(field);
      ir.Expression expression = field.initializer;
      ConstantValue value = _elementMap.getConstantValue(
          _elementMap.getStaticTypeContext(fieldElement), expression,
          requireConstant: false, implicitNull: true);
      if (value != null && value.isConstant) {
        fieldData[fieldElement] = new AllocatorData(value);
      }
    }

    for (ir.Constructor constructor in classNode.constructors) {
      KConstructor constructorElement = _elementMap.getConstructor(constructor);
      ir.StaticTypeContext staticTypeContext =
          _elementMap.getStaticTypeContext(constructorElement);
      constructors.add(constructorElement);
      for (ir.Initializer initializer in constructor.initializers) {
        if (initializer is ir.FieldInitializer) {
          AllocatorData data =
              fieldData[_elementMap.getField(initializer.field)];
          if (data == null) {
            // TODO(johnniwinther): Support initializers with side-effects?

            // The field has a non-constant initializer.
            continue;
          }

          Initializer initializerValue = const Initializer.complex();
          ir.Expression value = initializer.value;
          ConstantValue constantValue = _elementMap.getConstantValue(
              staticTypeContext, value,
              requireConstant: false, implicitNull: true);
          if (constantValue != null && constantValue.isConstant) {
            initializerValue = new Initializer.direct(constantValue);
          } else if (value is ir.VariableGet) {
            ir.VariableDeclaration parameter = value.variable;
            int position =
                constructor.function.positionalParameters.indexOf(parameter);
            if (position != -1) {
              if (position >= constructor.function.requiredParameterCount) {
                constantValue = _elementMap.getConstantValue(
                    staticTypeContext, parameter.initializer,
                    requireConstant: false, implicitNull: true);
                if (constantValue != null && constantValue.isConstant) {
                  initializerValue =
                      new Initializer.positional(position, constantValue);
                }
              }
            } else {
              position =
                  constructor.function.namedParameters.indexOf(parameter);
              if (position != -1) {
                constantValue = _elementMap.getConstantValue(
                    staticTypeContext, parameter.initializer,
                    requireConstant: false, implicitNull: true);
                if (constantValue != null && constantValue.isConstant) {
                  initializerValue =
                      new Initializer.named(parameter.name, constantValue);
                }
              }
            }
          }
          data.initializers[constructorElement] = initializerValue;
        }
      }
    }
    _classData[class_] = new ClassData(constructors, fieldData);
  }

  void registerStaticField(KField field, EvaluationComplexity complexity) {
    ir.Field node = _elementMap.getMemberNode(field);
    ir.Expression expression = node.initializer;
    ConstantValue value = _elementMap.getConstantValue(
        _elementMap.getStaticTypeContext(field), expression,
        requireConstant: node.isConst, implicitNull: true);
    if (value != null && !value.isConstant) {
      value = null;
    }
    // TODO(johnniwinther): Remove evaluation of constant when [complexity]
    // holds the constant literal from CFE.
    _staticFieldData[field] = new StaticFieldData(value, complexity);
  }

  AllocatorData getAllocatorDataForTesting(KField field) {
    return _classData[field.enclosingClass].fieldData[field];
  }

  StaticFieldData getStaticFieldDataForTesting(KField field) {
    return _staticFieldData[field];
  }
}

class ClassData {
  final List<KConstructor> constructors;
  final Map<KField, AllocatorData> fieldData;

  ClassData(this.constructors, this.fieldData);
}

class StaticFieldData {
  final ConstantValue initialValue;
  final EvaluationComplexity complexity;

  StaticFieldData(this.initialValue, this.complexity);

  bool get hasDependencies => complexity != null && complexity.fields != null;
}

class AllocatorData {
  final ConstantValue initialValue;
  final Map<KConstructor, Initializer> initializers = {};

  AllocatorData(this.initialValue);

  @override
  String toString() =>
      'AllocatorData(initialValue=${initialValue?.toStructuredText(null)},'
      'initializers=$initializers)';
}

enum InitializerKind {
  direct,
  positional,
  named,
  complex,
}

class Initializer {
  final InitializerKind kind;
  final int index;
  final String name;
  final ConstantValue value;

  Initializer.direct(this.value)
      : kind = InitializerKind.direct,
        index = null,
        name = null;

  Initializer.positional(this.index, this.value)
      : kind = InitializerKind.positional,
        name = null;

  Initializer.named(this.name, this.value)
      : kind = InitializerKind.named,
        index = null;

  const Initializer.complex()
      : kind = InitializerKind.complex,
        index = null,
        name = null,
        value = null;

  String shortText(DartTypes dartTypes) {
    switch (kind) {
      case InitializerKind.direct:
        return value.toStructuredText(dartTypes);
      case InitializerKind.positional:
        return '$index:${value.toStructuredText(dartTypes)}';
      case InitializerKind.named:
        return '$name:${value.toStructuredText(dartTypes)}';
      case InitializerKind.complex:
        return '?';
    }
    throw new UnsupportedError('Unexpected kind $kind');
  }

  @override
  String toString() => shortText(null);
}

class JFieldAnalysis {
  /// Tag used for identifying serialized [JFieldAnalysis] objects in a
  /// debugging data stream.
  static const String tag = 'field-analysis';

  // --csp and --fast-startup have different constraints to the generated code.

  final Map<FieldEntity, FieldAnalysisData> _fieldData;

  JFieldAnalysis._(this._fieldData);

  /// Deserializes a [JFieldAnalysis] object from [source].
  factory JFieldAnalysis.readFromDataSource(
      DataSource source, CompilerOptions options) {
    source.begin(tag);
    Map<FieldEntity, FieldAnalysisData> fieldData = source.readMemberMap(
        (MemberEntity member) => new FieldAnalysisData.fromDataSource(source));
    source.end(tag);
    return new JFieldAnalysis._(fieldData);
  }

  /// Serializes this [JFieldAnalysis] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberMap(
        _fieldData,
        (MemberEntity member, FieldAnalysisData data) =>
            data.writeToDataSink(sink));
    sink.end(tag);
  }

  factory JFieldAnalysis.from(KClosedWorldImpl closedWorld, JsToFrontendMap map,
      CompilerOptions options) {
    Map<FieldEntity, FieldAnalysisData> fieldData = {};

    bool canBeElided(FieldEntity field) {
      return !closedWorld.annotationsData.hasNoElision(field) &&
          !closedWorld.nativeData.isNativeMember(field);
    }

    closedWorld.fieldAnalysis._classData
        .forEach((ClassEntity cls, ClassData classData) {
      classData.fieldData.forEach((KField kField, AllocatorData data) {
        JField jField = map.toBackendMember(kField);
        if (jField == null) {
          return;
        }

        // TODO(johnniwinther): Should elided static fields be removed from the
        // J model? Static setters might still assign to them.

        MemberUsage memberUsage = closedWorld.liveMemberUsage[kField];
        if (!memberUsage.hasRead) {
          if (canBeElided(kField)) {
            fieldData[jField] = const FieldAnalysisData(isElided: true);
          }
        } else {
          if (data.initialValue != null) {
            ConstantValue initialValue;
            bool isTooComplex = false;

            void includeInitialValue(ConstantValue value) {
              if (isTooComplex) return;
              if (initialValue == null) {
                initialValue = value;
              } else if (initialValue != value) {
                initialValue = null;
                isTooComplex = true;
              }
            }

            memberUsage.initialConstants.forEach(includeInitialValue);

            bool inAllConstructors = true;
            for (KConstructor constructor in classData.constructors) {
              if (isTooComplex) {
                break;
              }

              MemberUsage constructorUsage =
                  closedWorld.liveMemberUsage[constructor];
              if (constructorUsage == null) {
                // This constructor isn't called.
                continue;
              }
              ParameterStructure invokedParameters =
                  closedWorld.annotationsData.hasNoElision(constructor)
                      ? constructor.parameterStructure
                      : constructorUsage.invokedParameters;

              Initializer initializer = data.initializers[constructor];
              if (initializer == null) {
                inAllConstructors = false;
              } else {
                switch (initializer.kind) {
                  case InitializerKind.direct:
                    includeInitialValue(initializer.value);
                    break;
                  case InitializerKind.positional:
                    if (initializer.index >=
                        invokedParameters.positionalParameters) {
                      includeInitialValue(initializer.value);
                    } else {
                      isTooComplex = true;
                    }
                    break;
                  case InitializerKind.named:
                    if (!invokedParameters.namedParameters
                        .contains(initializer.name)) {
                      includeInitialValue(initializer.value);
                    } else {
                      isTooComplex = true;
                    }
                    break;
                  case InitializerKind.complex:
                    isTooComplex = true;
                    break;
                }
              }
            }
            if (!inAllConstructors) {
              includeInitialValue(data.initialValue);
            }
            if (!isTooComplex && initialValue != null) {
              ConstantValue value = map.toBackendConstant(initialValue);
              bool isEffectivelyConstant = false;
              bool isInitializedInAllocator = false;
              assert(value != null);
              if (!memberUsage.hasWrite && canBeElided(kField)) {
                isEffectivelyConstant = true;
              } else if (value.isNull ||
                  value.isInt ||
                  value.isBool ||
                  value.isString) {
                // TODO(johnniwinther,sra): Support non-primitive constants in
                // allocators when it does cause allocators to deoptimized
                // because of deferred loading.
                isInitializedInAllocator = true;
              }
              fieldData[jField] = new FieldAnalysisData(
                  initialValue: value,
                  isEffectivelyFinal: isEffectivelyConstant,
                  isElided: isEffectivelyConstant,
                  isInitializedInAllocator: isInitializedInAllocator);
            }
          }
        }
      });
    });

    List<KField> independentFields = [];
    List<KField> dependentFields = [];

    closedWorld.liveMemberUsage
        .forEach((MemberEntity member, MemberUsage memberUsage) {
      if (member.isField && !member.isInstanceMember) {
        StaticFieldData staticFieldData =
            closedWorld.fieldAnalysis._staticFieldData[member];
        if (staticFieldData.hasDependencies) {
          dependentFields.add(member);
        } else {
          independentFields.add(member);
        }
      }
    });

    // Fields already processed.
    Set<KField> processedFields = {};

    // Fields currently being processed. Use for detecting cyclic dependencies.
    Set<KField> currentFields = {};

    // Index ascribed to eager fields that depend on other fields. This is
    // used to sort the field in emission to ensure that used fields have been
    // initialized when read.
    int eagerCreationIndex = 0;

    /// Computes the [FieldAnalysisData] for the JField corresponding to
    /// [kField].
    ///
    /// If the data is currently been computed, that is, [kField] has a
    /// cyclic dependency, `null` is returned.
    FieldAnalysisData processField(KField kField) {
      JField jField = map.toBackendMember(kField);
      // TODO(johnniwinther): Can we assert that [jField] exists?
      if (jField == null) return null;

      FieldAnalysisData data = fieldData[jField];
      if (processedFields.contains(kField)) {
        // We only store data for non-trivial [FieldAnalysisData].
        return data ?? const FieldAnalysisData();
      }
      if (currentFields.contains(kField)) {
        // Cyclic dependency.
        return null;
      }
      currentFields.add(kField);
      MemberUsage memberUsage = closedWorld.liveMemberUsage[kField];
      if (!memberUsage.hasRead && canBeElided(kField)) {
        data = fieldData[jField] = const FieldAnalysisData(isElided: true);
      } else {
        bool isEffectivelyFinal = !memberUsage.hasWrite;
        StaticFieldData staticFieldData =
            closedWorld.fieldAnalysis._staticFieldData[kField];
        ConstantValue value = map
            .toBackendConstant(staticFieldData.initialValue, allowNull: true);

        // If the field is effectively final with a constant initializer we
        // elide the field, if allowed, because it is effectively constant.
        bool isElided =
            isEffectivelyFinal && value != null && canBeElided(kField);

        bool isEager;

        // If the field is eager and dependent on other eager fields,
        // [eagerFieldDependencies] holds these fields and [creationIndex] is
        // given the creation order index used to ensure that all dependencies
        // have been assigned their values before this field is initialized.
        //
        // Since we only need the values of [eagerFieldDependencies] for testing
        // and only the non-emptiness for determining the need for creation
        // order indices, [eagerFieldDependencies] is non-null if the field has
        // dependencies but only hold these when [retainDataForTesting] is
        // `true`.
        List<FieldEntity> eagerFieldDependencies;
        int creationIndex = null;

        if (isElided) {
          // If the field is elided it needs no initializer and is therefore
          // not eager.
          isEager = false;
        } else {
          // If the field has a constant initializer we know it can be
          // initialized eagerly.
          //
          // Ideally this should be the same as
          // `staticFieldData.complexity.isConstant` but currently the constant
          // evaluator handles cases that the analysis doesn't, so we use the
          // better result.
          isEager = value != null;
          if (!isEager) {
            // The field might be eager depending on the initializer complexity
            // and its dependencies.
            EvaluationComplexity complexity = staticFieldData.complexity;
            isEager = complexity?.isEager ?? false;
            if (isEager && complexity.fields != null) {
              for (ir.Field node in complexity.fields) {
                KField otherField = closedWorld.elementMap.getField(node);
                FieldAnalysisData otherData = processField(otherField);
                if (otherData == null) {
                  // Cyclic dependency on [otherField].
                  isEager = false;
                  break;
                }
                if (otherData.isLazy) {
                  // [otherField] needs lazy initialization.
                  isEager = false;
                  break;
                }
                if (!otherData.isEffectivelyFinal) {
                  // [otherField] might not hold its initial value when this field
                  // is accessed the first time, so we need to initialize this
                  // field lazily.
                  isEager = false;
                  break;
                }
                if (!otherData.isEffectivelyConstant) {
                  eagerFieldDependencies ??= [];
                  if (retainDataForTesting) {
                    eagerFieldDependencies.add(map.toBackendMember(otherField));
                  }
                }
              }
            }
          }

          if (isEager && eagerFieldDependencies != null) {
            creationIndex = eagerCreationIndex++;
            if (!retainDataForTesting) {
              eagerFieldDependencies = null;
            }
          } else {
            eagerFieldDependencies = null;
          }
        }

        data = fieldData[jField] = new FieldAnalysisData(
            initialValue: value,
            isEffectivelyFinal: isEffectivelyFinal,
            isElided: isElided,
            isEager: isEager,
            eagerCreationIndex: creationIndex,
            eagerFieldDependenciesForTesting: eagerFieldDependencies);
      }

      currentFields.remove(kField);
      processedFields.add(kField);
      return data;
    }

    // Process independent fields in no particular order. The emitter sorts
    // these later.
    independentFields.forEach(processField);

    // Process dependent fields in declaration order to make ascribed creation
    // indices stable. The emitter uses the creation indices for sorting
    // dependent fields.
    dependentFields.sort((KField a, KField b) {
      int result =
          compareLibrariesUris(a.library.canonicalUri, b.library.canonicalUri);
      if (result != 0) return result;
      ir.Location aLocation = closedWorld.elementMap.getMemberNode(a).location;
      ir.Location bLocation = closedWorld.elementMap.getMemberNode(b).location;
      result = compareSourceUris(aLocation.file, bLocation.file);
      if (result != 0) return result;
      result = aLocation.line.compareTo(bLocation.line);
      if (result != 0) return result;
      return aLocation.column.compareTo(bLocation.column);
    });

    dependentFields.forEach(processField);

    return new JFieldAnalysis._(fieldData);
  }

  // TODO(sra): Add way to let injected fields be initialized to a constant in
  // allocator.

  FieldAnalysisData getFieldData(JField field) {
    return _fieldData[field] ?? const FieldAnalysisData();
  }
}

// TODO(johnniwinther): Merge this into [FieldData].
class FieldAnalysisData {
  static const String tag = 'field-analysis-data';

  final ConstantValue initialValue;
  final bool isInitializedInAllocator;
  final bool isEffectivelyFinal;
  final bool isElided;

  /// If `true` the field is not effectively constant but the initializer can be
  /// generated eagerly without the need for lazy initialization wrapper.
  final bool isEager;

  /// Index ascribed to eager fields that depend on other fields. This is
  /// used to sort the field in emission to ensure that used fields have been
  /// initialized when read.
  final int eagerCreationIndex;

  final List<FieldEntity> eagerFieldDependenciesForTesting;

  const FieldAnalysisData(
      {this.initialValue,
      this.isInitializedInAllocator: false,
      this.isEffectivelyFinal: false,
      this.isElided: false,
      this.isEager: false,
      this.eagerCreationIndex: null,
      this.eagerFieldDependenciesForTesting: null});

  factory FieldAnalysisData.fromDataSource(DataSource source) {
    source.begin(tag);

    ConstantValue initialValue = source.readConstantOrNull();
    bool isInitializedInAllocator = source.readBool();
    bool isEffectivelyFinal = source.readBool();
    bool isElided = source.readBool();
    bool isEager = source.readBool();
    int eagerCreationIndex = source.readIntOrNull();
    List<FieldEntity> eagerFieldDependencies =
        source.readMembers<FieldEntity>(emptyAsNull: true);
    source.end(tag);
    return new FieldAnalysisData(
        initialValue: initialValue,
        isInitializedInAllocator: isInitializedInAllocator,
        isEffectivelyFinal: isEffectivelyFinal,
        isElided: isElided,
        isEager: isEager,
        eagerCreationIndex: eagerCreationIndex,
        eagerFieldDependenciesForTesting: eagerFieldDependencies);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeConstantOrNull(initialValue);
    sink.writeBool(isInitializedInAllocator);
    sink.writeBool(isEffectivelyFinal);
    sink.writeBool(isElided);
    sink.writeBool(isEager);
    sink.writeIntOrNull(eagerCreationIndex);
    sink.writeMembers(eagerFieldDependenciesForTesting, allowNull: true);
    sink.end(tag);
  }

  /// If `true` the initializer for this field requires a lazy initialization
  /// wrapper.
  bool get isLazy => initialValue == null && !isEager;

  bool get isEffectivelyConstant =>
      isEffectivelyFinal && isElided && initialValue != null;

  ConstantValue get constantValue => isEffectivelyFinal ? initialValue : null;

  @override
  String toString() =>
      'FieldAnalysisData(initialValue=${initialValue?.toStructuredText(null)},'
      'isInitializedInAllocator=$isInitializedInAllocator,'
      'isEffectivelyFinal=$isEffectivelyFinal,isElided=$isElided,'
      'isEager=$isEager,eagerCreationIndex=$eagerCreationIndex,'
      'eagerFieldDependencies=$eagerFieldDependenciesForTesting)';
}
