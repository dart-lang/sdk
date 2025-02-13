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
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show Variance;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:pub_semver/pub_semver.dart';

/// The buffer that accumulates types and elements as is, so that they
/// can be written latter into Dart code that considers imports. It also
/// accumulates fragments of text, such as syntax `(`, or names of properties.
class AnalyzerDartTemplateBuffer
    implements DartTemplateBuffer<DartObject, FieldElement2, DartType> {
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
  void writeEnumValue(FieldElement2 value, String name) {
    var enumElement = value.enclosingElement2;
    if (enumElement is! EnumElement2) {
      isComplete = false;
      return;
    }

    parts.add(
      MissingPatternEnumValuePart(
        enumElement2: enumElement,
        value2: value,
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
    implements
        EnumOperations<DartType, EnumElement2, FieldElement2, DartObject> {
  const AnalyzerEnumOperations();

  @override
  EnumElement2? getEnumClass(DartType type) {
    var element = type.element3;
    if (element is EnumElement2) {
      return element;
    }
    return null;
  }

  @override
  String getEnumElementName(FieldElement2 enumField) {
    return '${enumField.enclosingElement2.name3}.${enumField.name3}';
  }

  @override
  Iterable<FieldElement2> getEnumElements(EnumElement2 enumClass) sync* {
    for (var field in enumClass.fields2) {
      if (field.isEnumConstant) {
        yield field;
      }
    }
  }

  @override
  InterfaceType getEnumElementType(FieldElement2 enumField) {
    return enumField.type as InterfaceType;
  }

  @override
  DartObject? getEnumElementValue(FieldElement2 enumField) {
    return enumField.computeConstantValue();
  }
}

class AnalyzerExhaustivenessCache extends ExhaustivenessCache<DartType,
    InterfaceElement2, EnumElement2, FieldElement2, DartObject> {
  final TypeSystemImpl typeSystem;

  AnalyzerExhaustivenessCache(this.typeSystem, LibraryElement2 enclosingLibrary)
      : super(
            AnalyzerTypeOperations(typeSystem, enclosingLibrary),
            const AnalyzerEnumOperations(),
            AnalyzerSealedClassOperations(typeSystem));
}

class AnalyzerSealedClassOperations
    implements SealedClassOperations<DartType, InterfaceElement2> {
  final TypeSystemImpl _typeSystem;

  AnalyzerSealedClassOperations(this._typeSystem);

  @override
  List<InterfaceElement2> getDirectSubclasses(InterfaceElement2 sealedClass) {
    List<InterfaceElement2> subclasses = [];
    var library = sealedClass.library2;
    outer:
    for (var declaration in library.children2) {
      if (declaration is ExtensionTypeElement2) {
        continue;
      }
      if (declaration != sealedClass && declaration is InterfaceElement2) {
        bool checkType(InterfaceType? type) {
          if (type?.element3 == sealedClass) {
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
        if (declaration is MixinElement2) {
          for (var type in declaration.superclassConstraints) {
            if (checkType(type)) {
              continue outer;
            }
          }
        }
      }
    }
    return subclasses;
  }

  @override
  ClassElement2? getSealedClass(DartType type) {
    var element = type.element3;
    if (element is ClassElement2 && element.isSealed) {
      return element;
    }
    return null;
  }

  @override
  DartType? getSubclassAsInstanceOf(
      InterfaceElement2 subClass, covariant InterfaceType sealedClassType) {
    InterfaceType thisType = subClass.thisType;
    InterfaceType asSealedClass =
        thisType.asInstanceOf2(sealedClassType.element3)!;
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
        Substitution substitution = Substitution.fromPairs2(
            subClass.typeParameters2, sealedClassType.typeArguments);
        for (int i = 0; i < subClass.typeParameters2.length; i++) {
          DartType? bound = subClass.typeParameters2[i].bound;
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
  final LibraryElement2 _enclosingLibrary;

  final Map<InterfaceType, Map<Key, DartType>> _interfaceFieldTypesCaches = {};

  AnalyzerTypeOperations(this._typeSystem, this._enclosingLibrary);

  @override
  DartType get boolType => _typeSystem.typeProvider.boolType;

  @override
  DartType get nonNullableObjectType => _typeSystem.objectNone;

  @override
  DartType get nullableObjectType => _typeSystem.objectQuestion;

  @override
  DartType getExtensionTypeErasure(DartType type) {
    return type.extensionTypeErasure;
  }

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
  bool isPotentiallyNullable(DartType type) =>
      _typeSystem.isPotentiallyNullable(type);

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
      for (var getter in type.getters) {
        if (getter.isPrivate && getter.library2 != _enclosingLibrary) {
          continue;
        }
        var name = getter.name3;
        if (name == null) {
          continue;
        }
        if (!getter.isStatic) {
          fieldTypes[NameKey(name)] = getter.type.returnType;
        }
      }
      for (var method in type.methods2) {
        if (method.isPrivate && method.library2 != _enclosingLibrary) {
          continue;
        }
        var name = method.name3;
        if (name == null) {
          continue;
        }
        if (!method.isStatic) {
          fieldTypes[NameKey(name)] = method.type;
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

  /// Map from unreachable switch case nodes to information about their
  /// unreachability.
  Map<AstNode, CaseUnreachability> caseUnreachabilities = {};

  /// Map from switch statement nodes that are erroneous due to being
  /// non-exhaustive, to information about their non-exhaustiveness.
  Map<AstNode, NonExhaustiveness> nonExhaustivenesses = {};

  ExhaustivenessDataForTesting(this.objectFieldLookup);
}

class MissingPatternEnumValuePart extends MissingPatternPart {
  final EnumElement2 enumElement2;
  final FieldElement2 value2;

  MissingPatternEnumValuePart({
    required this.enumElement2,
    required this.value2,
  });

  @override
  String toString() => value2.name3!;
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
    return type.getDisplayString();
  }
}

class PatternConverter with SpaceCreator<DartPattern, DartType> {
  final Version languageVersion;
  final FeatureSet featureSet;
  final AnalyzerExhaustivenessCache cache;
  final Map<Expression, DartObjectImpl> mapPatternKeyValues;
  final Map<ConstantPattern, DartObjectImpl> constantPatternValues;

  /// If we saw an invalid type, we already have a diagnostic reported,
  /// and there is no need to verify exhaustiveness.
  bool hasInvalidType = false;

  PatternConverter({
    required this.languageVersion,
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
          path, contextType, pattern.declaredElement2!.type,
          nonNull: nonNull);
    } else if (pattern is ObjectPattern) {
      var properties = <String, DartPattern>{};
      var extensionPropertyTypes = <String, DartType>{};
      for (var field in pattern.fields) {
        var name = field.effectiveName;
        if (name == null) {
          // Error case, skip field.
          continue;
        }
        properties[name] = field.pattern;
        var element = field.element2;
        DartType? extensionPropertyType;
        if (element is PropertyAccessorElement2 &&
            (element.enclosingElement2 is ExtensionElement2 ||
                element.enclosingElement2 is ExtensionTypeElement2)) {
          extensionPropertyType = element.returnType;
        } else if (element is ExecutableElement2 &&
            (element.enclosingElement2 is ExtensionElement2 ||
                element.enclosingElement2 is ExtensionTypeElement2)) {
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
      var positionalTypes = <DartType>[];
      var positionalPatterns = <DartPattern>[];
      var namedTypes = <String, DartType>{};
      var namedPatterns = <String, DartPattern>{};
      for (var field in pattern.fields) {
        var nameNode = field.name;
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
      var recordType = RecordType(
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
      assert(type.element3 == cache.typeSystem.typeProvider.listElement2 &&
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
      assert(type.element3 == cache.typeSystem.typeProvider.mapElement2 &&
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
      var value = constantPatternValues[pattern];
      if (value != null) {
        return _convertConstantValue(value, path);
      }
      hasInvalidType = true;
      return createUnknownSpace(path);
    }
    assert(false, "Unexpected pattern $pattern (${pattern.runtimeType})");
    return createUnknownSpace(path);
  }

  @override
  bool hasLanguageVersion(int major, int minor) {
    return languageVersion >= Version(major, minor, 0);
  }

  Space _convertConstantValue(DartObjectImpl value, Path path) {
    var state = value.state;
    if (value.isNull) {
      return Space(path, StaticType.nullType);
    } else if (state is BoolState) {
      var value = state.value;
      if (value != null) {
        return Space(path, cache.getBoolValueStaticType(state.value!));
      }
    } else if (state is RecordState) {
      var properties = <Key, Space>{};
      for (var index = 0; index < state.positionalFields.length; index++) {
        var key = RecordIndexKey(index);
        var value = state.positionalFields[index];
        properties[key] = _convertConstantValue(value, path.add(key));
      }
      for (var entry in state.namedFields.entries) {
        var key = RecordNameKey(entry.key);
        properties[key] = _convertConstantValue(entry.value, path.add(key));
      }
      return Space(path, cache.getStaticType(value.type),
          properties: properties);
    }
    var type = value.type;
    if (type is InterfaceType) {
      var element = type.element3;
      if (element is EnumElement2) {
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
      var element = node.element3 as TypeParameterElementImpl2;
      var defaultType = element.defaultType!;
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
