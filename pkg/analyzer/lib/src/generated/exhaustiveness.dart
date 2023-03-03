// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/constant.dart';

class AnalyzerEnumOperations
    implements EnumOperations<DartType, EnumElement, FieldElement, DartObject> {
  const AnalyzerEnumOperations();

  @override
  EnumElement? getEnumClass(DartType type) {
    Element? element = type.element;
    if (element is EnumElement) {
      return element;
    }
    return null;
  }

  @override
  String getEnumElementName(FieldElement enumField) {
    return '${enumField.enclosingElement.name}.${enumField.name}';
  }

  @override
  Iterable<FieldElement> getEnumElements(EnumElement enumClass) sync* {
    for (FieldElement field in enumClass.fields) {
      if (field.isEnumConstant) {
        yield field;
      }
    }
  }

  @override
  InterfaceType getEnumElementType(FieldElement enumField) {
    return enumField.type as InterfaceType;
  }

  @override
  DartObject getEnumElementValue(FieldElement enumField) {
    return enumField.computeConstantValue()!;
  }
}

class AnalyzerExhaustivenessCache extends ExhaustivenessCache<DartType,
    ClassElement, EnumElement, FieldElement, DartObject> {
  final TypeSystemImpl typeSystem;

  AnalyzerExhaustivenessCache(this.typeSystem)
      : super(
            AnalyzerTypeOperations(typeSystem),
            const AnalyzerEnumOperations(),
            AnalyzerSealedClassOperations(typeSystem));
}

class AnalyzerSealedClassOperations
    implements SealedClassOperations<DartType, ClassElement> {
  final TypeSystemImpl _typeSystem;

  AnalyzerSealedClassOperations(this._typeSystem);

  @override
  List<ClassElement> getDirectSubclasses(ClassElement sealedClass) {
    List<ClassElement> subclasses = [];
    LibraryElement library = sealedClass.library;
    outer:
    for (Element declaration in library.topLevelElements) {
      if (declaration != sealedClass && declaration is ClassElement) {
        bool checkType(InterfaceType? type) {
          if (type?.element == sealedClass) {
            subclasses.add(declaration);
            return true;
          }
          return false;
        }

        if (checkType(declaration.supertype)) {
          continue outer;
        }
        for (InterfaceType mixin in declaration.mixins) {
          if (checkType(mixin)) {
            continue outer;
          }
        }
        for (InterfaceType interface in declaration.interfaces) {
          if (checkType(interface)) {
            continue outer;
          }
        }
      }
    }
    return subclasses;
  }

  @override
  ClassElement? getSealedClass(DartType type) {
    Element? element = type.element;
    if (element is ClassElementImpl && element.isSealed) {
      return element;
    }
    return null;
  }

  @override
  DartType? getSubclassAsInstanceOf(
      ClassElement subClass, covariant InterfaceType sealedClassType) {
    InterfaceType thisType = subClass.thisType;
    InterfaceType asSealedClass =
        thisType.asInstanceOf(sealedClassType.element)!;
    if (thisType.typeArguments.isEmpty) {
      return thisType;
    }
    bool trivialSubstitution = true;
    if (thisType.typeArguments.length == asSealedClass.typeArguments.length) {
      for (int i = 0; i < thisType.typeArguments.length; i++) {
        if (thisType.typeArguments[i] != asSealedClass.typeArguments[i]) {
          trivialSubstitution = false;
          break;
        }
      }
      if (trivialSubstitution) {
        Substitution substitution = Substitution.fromPairs(
            subClass.typeParameters, sealedClassType.typeArguments);
        for (int i = 0; i < subClass.typeParameters.length; i++) {
          DartType? bound = subClass.typeParameters[i].bound;
          if (bound != null &&
              !_typeSystem.isSubtypeOf(sealedClassType.typeArguments[i],
                  substitution.substituteType(bound))) {
            trivialSubstitution = false;
            break;
          }
        }
      }
    } else {
      trivialSubstitution = false;
    }
    if (trivialSubstitution) {
      return subClass.instantiate(
          typeArguments: sealedClassType.typeArguments,
          nullabilitySuffix: NullabilitySuffix.none);
    } else {
      return TypeParameterReplacer.replaceTypeVariables(_typeSystem, thisType);
    }
  }
}

class AnalyzerTypeOperations implements TypeOperations<DartType> {
  final TypeSystemImpl _typeSystem;

  final Map<InterfaceType, Map<String, DartType>> _interfaceFieldTypesCaches =
      {};

  AnalyzerTypeOperations(this._typeSystem);

  @override
  DartType get boolType => _typeSystem.typeProvider.boolType;

  @override
  DartType get nullableObjectType => _typeSystem.objectQuestion;

  @override
  Map<String, DartType> getFieldTypes(DartType type) {
    if (type is InterfaceType) {
      return _getInterfaceFieldTypes(type);
    } else if (type is RecordType) {
      Map<String, DartType> fieldTypes = {};
      for (int index = 0; index < type.positionalFields.length; index++) {
        RecordTypePositionalField field = type.positionalFields[index];
        fieldTypes['\$${index + 1}'] = field.type;
      }
      for (RecordTypeNamedField field in type.namedFields) {
        fieldTypes[field.name] = field.type;
      }
      return fieldTypes;
    }
    return const {};
  }

  @override
  DartType? getFutureOrTypeArgument(DartType type) {
    return type.isDartAsyncFutureOr ? _typeSystem.futureOrBase(type) : null;
  }

  @override
  DartType getNonNullable(DartType type) {
    return _typeSystem.promoteToNonNull(type);
  }

  @override
  DartType instantiateFuture(DartType type) {
    return _typeSystem.typeProvider.futureType(type);
  }

  @override
  bool isBoolType(DartType type) {
    return type.isDartCoreBool && !isNullable(type);
  }

  @override
  bool isDynamic(DartType type) {
    return type is DynamicType;
  }

  @override
  bool isGeneric(DartType type) {
    return type is InterfaceType && type.typeArguments.isNotEmpty;
  }

  @override
  bool isNeverType(DartType type) {
    return type is NeverType;
  }

  @override
  bool isNonNullableObject(DartType type) {
    return type.isDartCoreObject && !isNullable(type);
  }

  @override
  bool isNullable(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  @override
  bool isNullableObject(DartType type) {
    return type.isDartCoreObject && isNullable(type);
  }

  @override
  bool isNullType(DartType type) {
    return type.isDartCoreNull;
  }

  @override
  bool isRecordType(DartType type) {
    return type is RecordType && !isNullable(type);
  }

  @override
  bool isSubtypeOf(DartType s, DartType t) {
    return _typeSystem.isSubtypeOf(s, t);
  }

  @override
  DartType overapproximate(DartType type) {
    return TypeParameterReplacer.replaceTypeVariables(_typeSystem, type);
  }

  @override
  String typeToString(DartType type) => type.toString();

  Map<String, DartType> _getInterfaceFieldTypes(InterfaceType type) {
    Map<String, DartType>? fieldTypes = _interfaceFieldTypesCaches[type];
    if (fieldTypes == null) {
      _interfaceFieldTypesCaches[type] = fieldTypes = {};
      for (InterfaceType supertype in type.allSupertypes) {
        fieldTypes.addAll(_getInterfaceFieldTypes(supertype));
      }
      for (PropertyAccessorElement accessor in type.accessors) {
        if (accessor.isGetter && !accessor.isStatic) {
          fieldTypes[accessor.name] = accessor.type.returnType;
        }
      }
    }
    return fieldTypes;
  }
}

/// Data gathered by the exhaustiveness computation, retained for testing
/// purposes.
class ExhaustivenessDataForTesting {
  /// Map from switch statement/expression nodes to the static type of the
  /// scrutinee.
  Map<AstNode, StaticType> switchScrutineeType = {};

  /// Map from switch case nodes to the space for its pattern/expression.
  Map<AstNode, Space> caseSpaces = {};

  /// Map from switch case nodes to the remaining space before the case or
  /// from statement/expression nodes to the remaining space after all cases.
  Map<AstNode, Space> remainingSpaces = {};

  /// Map from switch statement/expression/case nodes to the error reported
  /// on the node.
  Map<AstNode, ExhaustivenessError> errors = {};
}

class PatternConverter {
  final AnalyzerExhaustivenessCache cache;
  final Map<ConstantPattern, DartObjectImpl> constantPatternValues;

  PatternConverter({
    required this.cache,
    required this.constantPatternValues,
  });

  Space convertPattern(
    DartPattern pattern, {
    required bool nonNull,
  }) {
    if (pattern is DeclaredVariablePatternImpl) {
      final type = pattern.declaredElement!.type;
      final staticType = _asStaticType(type, nonNull: nonNull);
      return Space(staticType);
    } else if (pattern is ObjectPattern) {
      final fields = <String, Space>{};
      for (final field in pattern.fields) {
        final name = field.effectiveName;
        if (name == null) {
          // TODO(johnniwinther): How do we handle error cases?
          continue;
        }
        fields[name] = convertPattern(field.pattern, nonNull: false);
      }
      final type = pattern.type.typeOrThrow;
      final staticType = _asStaticType(type, nonNull: nonNull);
      return Space(staticType, fields);
    } else if (pattern is WildcardPattern) {
      final typeNode = pattern.type;
      if (typeNode == null) {
        if (nonNull) {
          return Space(StaticType.nonNullableObject);
        } else {
          return Space.top;
        }
      } else {
        final type = typeNode.typeOrThrow;
        final staticType = _asStaticType(type, nonNull: nonNull);
        return Space(staticType);
      }
    } else if (pattern is RecordPatternImpl) {
      var index = 1;
      final positional = <DartType>[];
      final named = <String, DartType>{};
      final fields = <String, Space>{};
      for (final field in pattern.fields) {
        final nameNode = field.name;
        String? name;
        if (nameNode == null) {
          name = '\$${index++}';
          positional.add(cache.typeSystem.typeProvider.dynamicType);
        } else {
          name = field.effectiveName;
          if (name != null) {
            named[name] = cache.typeSystem.typeProvider.dynamicType;
          } else {
            // Error case, skip field.
            continue;
          }
        }
        fields[name] = convertPattern(field.pattern, nonNull: false);
      }
      final recordType = RecordType(
        positional: positional,
        named: named,
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return Space(cache.getStaticType(recordType), fields);
    } else if (pattern is LogicalOrPattern) {
      return Space.union([
        convertPattern(pattern.leftOperand, nonNull: nonNull),
        convertPattern(pattern.rightOperand, nonNull: nonNull)
      ]);
    } else if (pattern is NullCheckPattern) {
      return convertPattern(pattern.pattern, nonNull: true);
    } else if (pattern is ParenthesizedPattern) {
      return convertPattern(pattern.pattern, nonNull: nonNull);
    } else if (pattern is NullAssertPattern) {
      Space space = convertPattern(pattern.pattern, nonNull: true);
      return Space.union([space, Space.nullSpace]);
    } else if (pattern is CastPattern ||
        pattern is RelationalPattern ||
        pattern is LogicalAndPattern) {
      // These pattern do not add to the exhaustiveness coverage.
      // TODO(johnniwinther): Handle `Null` aspect implicitly covered by
      // [NullAssertPattern] and `as Null`.
      // TODO(johnniwinther): Handle top in [AndPattern] branches.
      return Space(cache.getUnknownStaticType());
    } else if (pattern is ListPattern || pattern is MapPattern) {
      // TODO(johnniwinther): Support list and map patterns. This not only
      //  requires a new interpretation of [Space] fields that handles the
      //  relation between concrete lengths, rest patterns with/without
      //  subpattern, and list/map of arbitrary size and content, but also for the
      //  runtime to check for lengths < 0.
      return Space(cache.getUnknownStaticType());
    } else if (pattern is ConstantPattern) {
      final value = constantPatternValues[pattern];
      if (value != null) {
        return _convertConstantValue(value);
      }
      return Space(cache.getUnknownStaticType());
    }
    assert(false, "Unexpected pattern $pattern (${pattern.runtimeType})");
    return Space(cache.getUnknownStaticType());
  }

  StaticType _asStaticType(DartType type, {required bool nonNull}) {
    final staticType = cache.getStaticType(type);
    return nonNull ? staticType.nonNullable : staticType;
  }

  Space _convertConstantValue(DartObjectImpl value) {
    final state = value.state;
    if (value.isNull) {
      return Space.nullSpace;
    } else if (state is BoolState) {
      final value = state.value;
      if (value != null) {
        return Space(cache.getBoolValueStaticType(value));
      }
    } else if (state is RecordState) {
      final fields = <String, Space>{};
      for (var index = 0; index < state.positionalFields.length; index++) {
        final value = state.positionalFields[index];
        fields['\$${1 + index}'] = _convertConstantValue(value);
      }
      for (final entry in state.namedFields.entries) {
        fields[entry.key] = _convertConstantValue(entry.value);
      }
      return Space(cache.getStaticType(value.type), fields);
    }
    final type = value.type;
    if (type is InterfaceType) {
      final element = type.element;
      if (element is EnumElement) {
        return Space(cache.getEnumElementStaticType(element, value));
      }
    }
    return Space(cache.getUniqueStaticType(type, value, value.toString()));
  }
}

class TypeParameterReplacer extends ReplacementVisitor {
  final TypeSystemImpl _typeSystem;
  Variance _variance = Variance.covariant;

  TypeParameterReplacer(this._typeSystem);

  @override
  void changeVariance() {
    if (_variance == Variance.covariant) {
      _variance = Variance.contravariant;
    } else if (_variance == Variance.contravariant) {
      _variance = Variance.covariant;
    }
  }

  @override
  DartType? visitTypeParameterBound(DartType type) {
    Variance savedVariance = _variance;
    _variance = Variance.invariant;
    DartType? result = type.accept(this);
    _variance = savedVariance;
    return result;
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node) {
    if (_variance == Variance.contravariant) {
      return _replaceTypeParameterTypes(_typeSystem.typeProvider.neverType);
    } else {
      return _replaceTypeParameterTypes(
          (node.element as TypeParameterElementImpl).defaultType!);
    }
  }

  DartType _replaceTypeParameterTypes(DartType type) {
    return type.accept(this) ?? type;
  }

  static DartType replaceTypeVariables(
      TypeSystemImpl typeSystem, DartType type) {
    return TypeParameterReplacer(typeSystem)._replaceTypeParameterTypes(type);
  }
}
