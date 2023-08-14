// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/dart_template_buffer.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/key.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/path.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/shared.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/types.dart';
import 'package:analyzer/dart/analysis/features.dart';
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

/// The buffer that accumulates types and elements as is, so that they
/// can be written latter into Dart code that considers imports. It also
/// accumulates fragments of text, such as syntax `(`, or names of properties.
class AnalyzerDartTemplateBuffer
    implements DartTemplateBuffer<DartObject, FieldElement, DartType> {
  final List<MissingPatternPart> parts = [];
  bool isComplete = true;

  @override
  void write(String text) {
    parts.add(
      MissingPatternTextPart(text),
    );
  }

  @override
  void writeBoolValue(bool value) {
    parts.add(
      MissingPatternTextPart('$value'),
    );
  }

  @override
  void writeCoreType(String name) {
    parts.add(
      MissingPatternTextPart(name),
    );
  }

  @override
  void writeEnumValue(FieldElement value, String name) {
    final enumElement = value.enclosingElement;
    if (enumElement is! EnumElement) {
      isComplete = false;
      return;
    }

    parts.add(
      MissingPatternEnumValuePart(
        enumElement: enumElement,
        value: value,
      ),
    );
  }

  @override
  void writeGeneralConstantValue(DartObject value, String name) {
    isComplete = false;
  }

  @override
  void writeGeneralType(DartType type, String name) {
    parts.add(
      MissingPatternTypePart(type),
    );
  }
}

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
  DartObject? getEnumElementValue(FieldElement enumField) {
    return enumField.computeConstantValue();
  }
}

class AnalyzerExhaustivenessCache extends ExhaustivenessCache<DartType,
    InterfaceElement, EnumElement, FieldElement, DartObject> {
  final TypeSystemImpl typeSystem;

  AnalyzerExhaustivenessCache(this.typeSystem, LibraryElement enclosingLibrary)
      : super(
            AnalyzerTypeOperations(typeSystem, enclosingLibrary),
            const AnalyzerEnumOperations(),
            AnalyzerSealedClassOperations(typeSystem));
}

class AnalyzerSealedClassOperations
    implements SealedClassOperations<DartType, InterfaceElement> {
  final TypeSystemImpl _typeSystem;

  AnalyzerSealedClassOperations(this._typeSystem);

  @override
  List<InterfaceElement> getDirectSubclasses(InterfaceElement sealedClass) {
    List<InterfaceElement> subclasses = [];
    LibraryElement library = sealedClass.library;
    outer:
    for (Element declaration in library.topLevelElements) {
      if (declaration != sealedClass && declaration is InterfaceElement) {
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
    if (element is ClassElement && element.isSealed) {
      return element;
    }
    return null;
  }

  @override
  DartType? getSubclassAsInstanceOf(
      InterfaceElement subClass, covariant InterfaceType sealedClassType) {
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
  final LibraryElement _enclosingLibrary;

  final Map<InterfaceType, Map<Key, DartType>> _interfaceFieldTypesCaches = {};

  AnalyzerTypeOperations(this._typeSystem, this._enclosingLibrary);

  @override
  DartType get boolType => _typeSystem.typeProvider.boolType;

  @override
  DartType get nonNullableObjectType => _typeSystem.objectNone;

  @override
  DartType get nullableObjectType => _typeSystem.objectQuestion;

  @override
  Map<Key, DartType> getFieldTypes(DartType type) {
    if (type is InterfaceType) {
      return _getInterfaceFieldTypes(type);
    } else if (type is RecordType) {
      Map<Key, DartType> fieldTypes = {};
      fieldTypes.addAll(getFieldTypes(_typeSystem.typeProvider.objectType));
      for (int index = 0; index < type.positionalFields.length; index++) {
        RecordTypePositionalField field = type.positionalFields[index];
        fieldTypes[RecordIndexKey(index)] = field.type;
      }
      for (RecordTypeNamedField field in type.namedFields) {
        fieldTypes[RecordNameKey(field.name)] = field.type;
      }
      return fieldTypes;
    }
    return getFieldTypes(_typeSystem.typeProvider.objectType);
  }

  @override
  DartType? getFutureOrTypeArgument(DartType type) {
    return type.isDartAsyncFutureOr ? _typeSystem.futureOrBase(type) : null;
  }

  @override
  DartType? getListElementType(DartType type) {
    InterfaceType? listType =
        type.asInstanceOf(_typeSystem.typeProvider.listElement);
    if (listType != null) {
      return listType.typeArguments[0];
    }
    return null;
  }

  @override
  DartType? getListType(DartType type) {
    return type.asInstanceOf(_typeSystem.typeProvider.listElement);
  }

  @override
  DartType? getMapValueType(DartType type) {
    InterfaceType? mapType =
        type.asInstanceOf(_typeSystem.typeProvider.mapElement);
    if (mapType != null) {
      return mapType.typeArguments[1];
    }
    return null;
  }

  @override
  DartType getNonNullable(DartType type) {
    return _typeSystem.promoteToNonNull(type);
  }

  @override
  DartType? getTypeVariableBound(DartType type) {
    if (type is TypeParameterType) {
      return type.bound;
    }
    return null;
  }

  @override
  bool hasSimpleName(DartType type) {
    return type is InterfaceType ||
        type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        // TODO(johnniwinther): What about intersection types?
        type is TypeParameterType;
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

  Map<Key, DartType> _getInterfaceFieldTypes(InterfaceType type) {
    Map<Key, DartType>? fieldTypes = _interfaceFieldTypesCaches[type];
    if (fieldTypes == null) {
      _interfaceFieldTypesCaches[type] = fieldTypes = {};
      for (InterfaceType supertype in type.allSupertypes) {
        fieldTypes.addAll(_getInterfaceFieldTypes(supertype));
      }
      for (PropertyAccessorElement accessor in type.accessors) {
        if (accessor.isPrivate && accessor.library != _enclosingLibrary) {
          continue;
        }
        if (accessor.isGetter && !accessor.isStatic) {
          fieldTypes[NameKey(accessor.name)] = accessor.type.returnType;
        }
      }
      for (MethodElement method in type.methods) {
        if (method.isPrivate && method.library != _enclosingLibrary) {
          continue;
        }
        if (!method.isStatic) {
          fieldTypes[NameKey(method.name)] = method.type;
        }
      }
    }
    return fieldTypes;
  }
}

/// Data gathered by the exhaustiveness computation, retained for testing
/// purposes.
class ExhaustivenessDataForTesting {
  /// Access to interface for looking up `Object` members on non-interface
  /// types.
  final ObjectPropertyLookup objectFieldLookup;

  /// Map from switch statement/expression nodes to the static type of the
  /// scrutinee.
  Map<AstNode, StaticType> switchScrutineeType = {};

  /// Map from switch statement/expression nodes the spaces for its cases.
  Map<AstNode, List<Space>> switchCases = {};

  /// Map from switch case nodes to the space for its pattern/expression.
  Map<AstNode, Space> caseSpaces = {};

  /// Map from switch statement/expression/case nodes to the error reported
  /// on the node.
  Map<AstNode, ExhaustivenessError> errors = {};

  ExhaustivenessDataForTesting(this.objectFieldLookup);
}

class MissingPatternEnumValuePart extends MissingPatternPart {
  final EnumElement enumElement;
  final FieldElement value;

  MissingPatternEnumValuePart({
    required this.enumElement,
    required this.value,
  });

  @override
  String toString() => value.name;
}

abstract class MissingPatternPart {}

class MissingPatternTextPart extends MissingPatternPart {
  final String text;

  MissingPatternTextPart(this.text);

  @override
  String toString() => text;
}

class MissingPatternTypePart extends MissingPatternPart {
  final DartType type;

  MissingPatternTypePart(this.type);

  @override
  String toString() {
    return type.getDisplayString(withNullability: true);
  }
}

class PatternConverter with SpaceCreator<DartPattern, DartType> {
  final FeatureSet featureSet;
  final AnalyzerExhaustivenessCache cache;
  final Map<Expression, DartObjectImpl> mapPatternKeyValues;
  final Map<ConstantPattern, DartObjectImpl> constantPatternValues;

  /// If we saw an invalid type, we already have a diagnostic reported,
  /// and there is no need to verify exhaustiveness.
  bool hasInvalidType = false;

  PatternConverter({
    required this.featureSet,
    required this.cache,
    required this.mapPatternKeyValues,
    required this.constantPatternValues,
  });

  @override
  ObjectPropertyLookup get objectFieldLookup => cache;

  @override
  TypeOperations<DartType> get typeOperations => cache.typeOperations;

  @override
  StaticType createListType(
      DartType type, ListTypeRestriction<DartType> restriction) {
    return cache.getListStaticType(type, restriction);
  }

  @override
  StaticType createMapType(
      DartType type, MapTypeRestriction<DartType> restriction) {
    return cache.getMapStaticType(type, restriction);
  }

  @override
  StaticType createStaticType(DartType type) {
    hasInvalidType |= type is InvalidType;
    return cache.getStaticType(type);
  }

  @override
  StaticType createUnknownStaticType() {
    return cache.getUnknownStaticType();
  }

  @override
  Space dispatchPattern(Path path, StaticType contextType, DartPattern pattern,
      {required bool nonNull}) {
    if (pattern is DeclaredVariablePatternImpl) {
      return createVariableSpace(
          path, contextType, pattern.declaredElement!.type,
          nonNull: nonNull);
    } else if (pattern is ObjectPattern) {
      final properties = <String, DartPattern>{};
      final extensionPropertyTypes = <String, DartType>{};
      for (final field in pattern.fields) {
        final name = field.effectiveName;
        if (name == null) {
          // Error case, skip field.
          continue;
        }
        properties[name] = field.pattern;
        Element? element = field.element;
        DartType? extensionPropertyType;
        if (element is PropertyAccessorElement &&
            element.enclosingElement is ExtensionElement) {
          extensionPropertyType = element.returnType;
        } else if (element is ExecutableElement &&
            element.enclosingElement is ExtensionElement) {
          extensionPropertyType = element.type;
        }
        if (extensionPropertyType != null) {
          extensionPropertyTypes[name] = extensionPropertyType;
        }
      }
      return createObjectSpace(path, contextType, pattern.type.typeOrThrow,
          properties, extensionPropertyTypes,
          nonNull: nonNull);
    } else if (pattern is WildcardPattern) {
      return createWildcardSpace(path, contextType, pattern.type?.typeOrThrow,
          nonNull: nonNull);
    } else if (pattern is RecordPatternImpl) {
      final positionalTypes = <DartType>[];
      final positionalPatterns = <DartPattern>[];
      final namedTypes = <String, DartType>{};
      final namedPatterns = <String, DartPattern>{};
      for (final field in pattern.fields) {
        final nameNode = field.name;
        if (nameNode == null) {
          positionalTypes.add(cache.typeSystem.typeProvider.dynamicType);
          positionalPatterns.add(field.pattern);
        } else {
          String? name = field.effectiveName;
          if (name != null) {
            namedTypes[name] = cache.typeSystem.typeProvider.dynamicType;
            namedPatterns[name] = field.pattern;
          } else {
            // Error case, skip field.
            continue;
          }
        }
      }
      final recordType = RecordType(
        positional: positionalTypes,
        named: namedTypes,
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return createRecordSpace(
          path, contextType, recordType, positionalPatterns, namedPatterns);
    } else if (pattern is LogicalOrPattern) {
      return createLogicalOrSpace(
          path, contextType, pattern.leftOperand, pattern.rightOperand,
          nonNull: nonNull);
    } else if (pattern is NullCheckPattern) {
      return createNullCheckSpace(path, contextType, pattern.pattern);
    } else if (pattern is ParenthesizedPattern) {
      return dispatchPattern(path, contextType, pattern.pattern,
          nonNull: nonNull);
    } else if (pattern is NullAssertPattern) {
      return createNullAssertSpace(path, contextType, pattern.pattern);
    } else if (pattern is CastPattern) {
      return createCastSpace(
          path, contextType, pattern.type.typeOrThrow, pattern.pattern,
          nonNull: nonNull);
    } else if (pattern is LogicalAndPattern) {
      return createLogicalAndSpace(
          path, contextType, pattern.leftOperand, pattern.rightOperand,
          nonNull: nonNull);
    } else if (pattern is RelationalPattern) {
      return createRelationalSpace(path);
    } else if (pattern is ListPattern) {
      InterfaceType type = pattern.requiredType as InterfaceType;
      assert(type.element == cache.typeSystem.typeProvider.listElement &&
          type.typeArguments.length == 1);
      DartType elementType = type.typeArguments[0];
      List<DartPattern> headElements = [];
      DartPattern? restElement;
      List<DartPattern> tailElements = [];
      bool hasRest = false;
      for (ListPatternElement element in pattern.elements) {
        if (element is RestPatternElement) {
          restElement = element.pattern;
          hasRest = true;
        } else if (hasRest) {
          tailElements.add(element as DartPattern);
        } else {
          headElements.add(element as DartPattern);
        }
      }
      return createListSpace(path,
          type: type,
          elementType: elementType,
          headElements: headElements,
          tailElements: tailElements,
          restElement: restElement,
          hasRest: hasRest,
          hasExplicitTypeArgument: pattern.typeArguments != null);
    } else if (pattern is MapPattern) {
      InterfaceType type = pattern.requiredType as InterfaceType;
      assert(type.element == cache.typeSystem.typeProvider.mapElement &&
          type.typeArguments.length == 2);
      DartType keyType = type.typeArguments[0];
      DartType valueType = type.typeArguments[1];
      Map<MapKey, DartPattern> entries = {};
      for (MapPatternElement entry in pattern.elements) {
        if (entry is RestPatternElement) {
          // Rest patterns are illegal in map patterns, so just skip over it.
        } else {
          Expression expression = (entry as MapPatternEntry).key;
          // TODO(johnniwinther): Assert that we have a constant value.
          DartObjectImpl? constant = mapPatternKeyValues[expression];
          if (constant == null) {
            return createUnknownSpace(path);
          }
          MapKey key = MapKey(constant, constant.state.toString());
          entries[key] = entry.value;
        }
      }

      return createMapSpace(path,
          type: cache.typeSystem.typeProvider.mapType(keyType, valueType),
          keyType: keyType,
          valueType: valueType,
          entries: entries,
          hasExplicitTypeArguments: pattern.typeArguments != null);
    } else if (pattern is ConstantPattern) {
      final value = constantPatternValues[pattern];
      if (value != null) {
        return _convertConstantValue(value, path);
      }
      hasInvalidType = true;
      return createUnknownSpace(path);
    }
    assert(false, "Unexpected pattern $pattern (${pattern.runtimeType})");
    return createUnknownSpace(path);
  }

  Space _convertConstantValue(DartObjectImpl value, Path path) {
    final state = value.state;
    if (value.isNull) {
      return Space(path, StaticType.nullType);
    } else if (state is BoolState) {
      final value = state.value;
      if (value != null) {
        return Space(path, cache.getBoolValueStaticType(state.value!));
      }
    } else if (state is RecordState) {
      final properties = <Key, Space>{};
      for (var index = 0; index < state.positionalFields.length; index++) {
        final key = RecordIndexKey(index);
        final value = state.positionalFields[index];
        properties[key] = _convertConstantValue(value, path.add(key));
      }
      for (final entry in state.namedFields.entries) {
        final key = RecordNameKey(entry.key);
        properties[key] = _convertConstantValue(entry.value, path.add(key));
      }
      return Space(path, cache.getStaticType(value.type),
          properties: properties);
    }
    final type = value.type;
    if (type is InterfaceType) {
      final element = type.element;
      if (element is EnumElement) {
        return Space(path, cache.getEnumElementStaticType(element, value));
      }
    }

    StaticType staticType;
    if (value.hasPrimitiveEquality(featureSet)) {
      staticType = cache.getUniqueStaticType<DartObjectImpl>(
          type, value, value.state.toString());
    } else {
      // If [value] doesn't have primitive equality we cannot tell if it is
      // equal to itself.
      staticType = cache.getUnknownStaticType();
    }

    return Space(path, staticType);
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
      final element = node.element as TypeParameterElementImpl;
      final defaultType = element.defaultType!;
      return _replaceTypeParameterTypes(defaultType);
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
