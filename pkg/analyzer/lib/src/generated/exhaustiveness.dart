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
import 'package:_fe_analyzer_shared/src/types/shared_type.dart' show Variance;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:pub_semver/pub_semver.dart';

/// The buffer that accumulates types and elements as is, so that they
/// can be written latter into Dart code that considers imports. It also
/// accumulates fragments of text, such as syntax `(`, or names of properties.
class AnalyzerDartTemplateBuffer
    implements DartTemplateBuffer<DartObject, FieldElement, TypeImpl> {
  final List<MissingPatternPart> parts = [];
  bool isComplete = true;

  @override
  void write(String text) {
    parts.add(MissingPatternTextPart(text));
  }

  @override
  void writeBoolValue(bool value) {
    parts.add(MissingPatternTextPart('$value'));
  }

  @override
  void writeCoreType(String name) {
    parts.add(MissingPatternTextPart(name));
  }

  @override
  void writeEnumValue(FieldElement value, String name) {
    var enumElement = value.enclosingElement;
    if (enumElement is! EnumElement) {
      isComplete = false;
      return;
    }

    parts.add(
      MissingPatternEnumValuePart(enumElement2: enumElement, value2: value),
    );
  }

  @override
  void writeGeneralConstantValue(DartObject value, String name) {
    isComplete = false;
  }

  @override
  void writeGeneralType(TypeImpl type, String name) {
    parts.add(MissingPatternTypePart(type));
  }
}

class AnalyzerEnumOperations
    implements EnumOperations<TypeImpl, EnumElement, FieldElement, DartObject> {
  const AnalyzerEnumOperations();

  @override
  EnumElement? getEnumClass(TypeImpl type) {
    var element = type.element;
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
    for (var field in enumClass.fields) {
      if (field.isEnumConstant) {
        yield field;
      }
    }
  }

  @override
  InterfaceTypeImpl getEnumElementType(FieldElement enumField) {
    return enumField.type as InterfaceTypeImpl;
  }

  @override
  DartObject? getEnumElementValue(FieldElement enumField) {
    return enumField.computeConstantValue();
  }
}

class AnalyzerExhaustivenessCache
    extends
        ExhaustivenessCache<
          TypeImpl,
          InterfaceElement,
          EnumElement,
          FieldElement,
          DartObject
        > {
  final TypeSystemImpl typeSystem;

  AnalyzerExhaustivenessCache(this.typeSystem, LibraryElement enclosingLibrary)
    : super(
        AnalyzerTypeOperations(typeSystem, enclosingLibrary),
        const AnalyzerEnumOperations(),
        AnalyzerSealedClassOperations(typeSystem),
      );
}

class AnalyzerSealedClassOperations
    implements SealedClassOperations<TypeImpl, InterfaceElementImpl> {
  final TypeSystemImpl _typeSystem;

  AnalyzerSealedClassOperations(this._typeSystem);

  @override
  List<InterfaceElementImpl> getDirectSubclasses(
    InterfaceElementImpl sealedClass,
  ) {
    List<InterfaceElementImpl> subclasses = [];
    var library = sealedClass.library;
    outer:
    for (var declaration in library.children) {
      if (declaration is ExtensionTypeElement) {
        continue;
      }
      if (declaration != sealedClass && declaration is InterfaceElementImpl) {
        bool checkType(InterfaceTypeImpl? type) {
          if (type?.element == sealedClass) {
            subclasses.add(declaration);
            return true;
          }
          return false;
        }

        if (checkType(declaration.supertype)) {
          continue outer;
        }
        for (var mixin in declaration.mixins) {
          if (checkType(mixin)) {
            continue outer;
          }
        }
        for (var interface in declaration.interfaces) {
          if (checkType(interface)) {
            continue outer;
          }
        }
        if (declaration is MixinElementImpl) {
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
  ClassElementImpl? getSealedClass(TypeImpl type) {
    var element = type.element;
    if (element is ClassElementImpl && element.isSealed) {
      return element;
    }
    return null;
  }

  @override
  TypeImpl? getSubclassAsInstanceOf(
    InterfaceElementImpl subClass,
    covariant InterfaceTypeImpl sealedClassType,
  ) {
    var thisType = subClass.thisType;
    var asSealedClass = thisType.asInstanceOf(sealedClassType.element)!;
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
          subClass.typeParameters,
          sealedClassType.typeArguments,
        );
        for (int i = 0; i < subClass.typeParameters.length; i++) {
          var bound = subClass.typeParameters[i].bound;
          if (bound != null &&
              !_typeSystem.isSubtypeOf(
                sealedClassType.typeArguments[i],
                substitution.substituteType(bound),
              )) {
            trivialSubstitution = false;
            break;
          }
        }
      }
    } else {
      trivialSubstitution = false;
    }
    if (trivialSubstitution) {
      return subClass.instantiateImpl(
        typeArguments: sealedClassType.typeArguments,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    } else {
      return TypeParameterReplacer.replaceTypeVariables(_typeSystem, thisType);
    }
  }
}

class AnalyzerTypeOperations implements TypeOperations<TypeImpl> {
  final TypeSystemImpl _typeSystem;
  final LibraryElement _enclosingLibrary;

  final Map<InterfaceTypeImpl, Map<Key, TypeImpl>> _interfaceFieldTypesCaches =
      {};

  AnalyzerTypeOperations(this._typeSystem, this._enclosingLibrary);

  @override
  TypeImpl get boolType => _typeSystem.typeProvider.boolType;

  @override
  TypeImpl get nonNullableObjectType => _typeSystem.objectNone;

  @override
  TypeImpl get nullableObjectType => _typeSystem.objectQuestion;

  @override
  TypeImpl getExtensionTypeErasure(TypeImpl type) {
    return type.extensionTypeErasure;
  }

  @override
  Map<Key, TypeImpl> getFieldTypes(TypeImpl type) {
    if (type is InterfaceTypeImpl) {
      return _getInterfaceFieldTypes(type);
    } else if (type is RecordTypeImpl) {
      Map<Key, TypeImpl> fieldTypes = {};
      fieldTypes.addAll(getFieldTypes(_typeSystem.typeProvider.objectType));
      for (int index = 0; index < type.positionalFields.length; index++) {
        var field = type.positionalFields[index];
        fieldTypes[RecordIndexKey(index)] = field.type;
      }
      for (var field in type.namedFields) {
        fieldTypes[RecordNameKey(field.name)] = field.type;
      }
      return fieldTypes;
    }
    return getFieldTypes(_typeSystem.typeProvider.objectType);
  }

  @override
  TypeImpl? getFutureOrTypeArgument(TypeImpl type) {
    return type.isDartAsyncFutureOr ? _typeSystem.futureOrBase(type) : null;
  }

  @override
  TypeImpl? getListElementType(TypeImpl type) {
    var listType = type.asInstanceOf(_typeSystem.typeProvider.listElement);
    if (listType != null) {
      return listType.typeArguments[0];
    }
    return null;
  }

  @override
  TypeImpl? getListType(TypeImpl type) {
    return type.asInstanceOf(_typeSystem.typeProvider.listElement);
  }

  @override
  TypeImpl? getMapValueType(TypeImpl type) {
    var mapType = type.asInstanceOf(_typeSystem.typeProvider.mapElement);
    if (mapType != null) {
      return mapType.typeArguments[1];
    }
    return null;
  }

  @override
  TypeImpl getNonNullable(TypeImpl type) {
    return _typeSystem.promoteToNonNull(type);
  }

  @override
  TypeImpl? getTypeVariableBound(TypeImpl type) {
    if (type is TypeParameterTypeImpl) {
      return type.bound;
    }
    return null;
  }

  @override
  bool hasSimpleName(TypeImpl type) {
    return type is InterfaceTypeImpl ||
        type is DynamicTypeImpl ||
        type is VoidTypeImpl ||
        type is NeverTypeImpl ||
        // TODO(johnniwinther): What about intersection types?
        type is TypeParameterTypeImpl;
  }

  @override
  TypeImpl instantiateFuture(TypeImpl type) {
    return _typeSystem.typeProvider.futureType(type);
  }

  @override
  bool isBoolType(TypeImpl type) {
    return type.isDartCoreBool && !isNullable(type);
  }

  @override
  bool isDynamic(TypeImpl type) {
    return type is DynamicTypeImpl;
  }

  @override
  bool isGeneric(TypeImpl type) {
    return type is InterfaceTypeImpl && type.typeArguments.isNotEmpty;
  }

  @override
  bool isNeverType(TypeImpl type) {
    return type is NeverTypeImpl;
  }

  @override
  bool isNonNullableObject(TypeImpl type) {
    return type.isDartCoreObject && !isNullable(type);
  }

  @override
  bool isNullable(TypeImpl type) {
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  @override
  bool isNullableObject(TypeImpl type) {
    return type.isDartCoreObject && isNullable(type);
  }

  @override
  bool isNullType(TypeImpl type) {
    return type.isDartCoreNull;
  }

  @override
  bool isPotentiallyNullable(TypeImpl type) =>
      _typeSystem.isPotentiallyNullable(type);

  @override
  bool isRecordType(TypeImpl type) {
    return type is RecordTypeImpl && !isNullable(type);
  }

  @override
  bool isSubtypeOf(TypeImpl s, TypeImpl t) {
    return _typeSystem.isSubtypeOf(s, t);
  }

  @override
  TypeImpl overapproximate(TypeImpl type) {
    return TypeParameterReplacer.replaceTypeVariables(_typeSystem, type);
  }

  @override
  String typeToString(TypeImpl type) => type.toString();

  Map<Key, TypeImpl> _getInterfaceFieldTypes(InterfaceTypeImpl type) {
    var fieldTypes = _interfaceFieldTypesCaches[type];
    if (fieldTypes == null) {
      _interfaceFieldTypesCaches[type] = fieldTypes = {};
      for (var supertype in type.allSupertypes) {
        fieldTypes.addAll(_getInterfaceFieldTypes(supertype));
      }
      for (var getter in type.getters) {
        if (getter.isPrivate && getter.library != _enclosingLibrary) {
          continue;
        }
        var name = getter.name;
        if (name == null) {
          continue;
        }
        if (!getter.isStatic) {
          fieldTypes[NameKey(name)] = getter.type.returnType;
        }
      }
      for (var method in type.methods) {
        if (method.isPrivate && method.library != _enclosingLibrary) {
          continue;
        }
        var name = method.name;
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
  final EnumElement enumElement2;
  final FieldElement value2;

  MissingPatternEnumValuePart({
    required this.enumElement2,
    required this.value2,
  });

  @override
  String toString() => value2.name!;
}

abstract class MissingPatternPart {
  /// Expando associating each
  /// [CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION] or
  /// [CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT] diagnostic with a
  /// list of missing patterns; this data is used by the analysis server to add
  /// missing switch cases.
  static final byDiagnostic = Expando<List<List<MissingPatternPart>>>();
}

class MissingPatternTextPart extends MissingPatternPart {
  final String text;

  MissingPatternTextPart(this.text);

  @override
  String toString() => text;
}

class MissingPatternTypePart extends MissingPatternPart {
  final TypeImpl type;

  MissingPatternTypePart(this.type);

  @override
  String toString() {
    return type.getDisplayString();
  }
}

class PatternConverter with SpaceCreator<DartPattern, TypeImpl> {
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
  TypeOperations<TypeImpl> get typeOperations => cache.typeOperations;

  @override
  StaticType createListType(
    TypeImpl type,
    ListTypeRestriction<TypeImpl> restriction,
  ) {
    return cache.getListStaticType(type, restriction);
  }

  @override
  StaticType createMapType(
    TypeImpl type,
    MapTypeRestriction<TypeImpl> restriction,
  ) {
    return cache.getMapStaticType(type, restriction);
  }

  @override
  StaticType createStaticType(TypeImpl type) {
    hasInvalidType |= type is InvalidTypeImpl;
    return cache.getStaticType(type);
  }

  @override
  StaticType createUnknownStaticType() {
    return cache.getUnknownStaticType();
  }

  @override
  Space dispatchPattern(
    Path path,
    StaticType contextType,
    DartPattern pattern, {
    required bool nonNull,
  }) {
    if (pattern is DeclaredVariablePatternImpl) {
      return createVariableSpace(
        path,
        contextType,
        pattern.declaredFragment!.element.type,
        nonNull: nonNull,
      );
    } else if (pattern is ObjectPattern) {
      var properties = <String, DartPattern>{};
      var extensionPropertyTypes = <String, TypeImpl>{};
      for (var field in pattern.fields) {
        var name = field.effectiveName;
        if (name == null) {
          // Error case, skip field.
          continue;
        }
        properties[name] = field.pattern;
        var element = field.element;
        TypeImpl? extensionPropertyType;
        if (element is InternalPropertyAccessorElement &&
            (element.enclosingElement is ExtensionElementImpl ||
                element.enclosingElement is ExtensionTypeElementImpl)) {
          extensionPropertyType = element.returnType;
        } else if (element is InternalExecutableElement &&
            (element.enclosingElement is ExtensionElementImpl ||
                element.enclosingElement is ExtensionTypeElementImpl)) {
          extensionPropertyType = element.type;
        }
        if (extensionPropertyType != null) {
          extensionPropertyTypes[name] = extensionPropertyType;
        }
      }
      return createObjectSpace(
        path,
        contextType,
        pattern.type.typeOrThrow,
        properties,
        extensionPropertyTypes,
        nonNull: nonNull,
      );
    } else if (pattern is WildcardPattern) {
      return createWildcardSpace(
        path,
        contextType,
        pattern.type?.typeOrThrow,
        nonNull: nonNull,
      );
    } else if (pattern is RecordPatternImpl) {
      var positionalTypes = <TypeImpl>[];
      var positionalPatterns = <DartPattern>[];
      var namedTypes = <String, TypeImpl>{};
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
      var recordType = RecordTypeImpl.fromApi(
        positional: positionalTypes,
        named: namedTypes,
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return createRecordSpace(
        path,
        contextType,
        recordType,
        positionalPatterns,
        namedPatterns,
      );
    } else if (pattern is LogicalOrPattern) {
      return createLogicalOrSpace(
        path,
        contextType,
        pattern.leftOperand,
        pattern.rightOperand,
        nonNull: nonNull,
      );
    } else if (pattern is NullCheckPattern) {
      return createNullCheckSpace(path, contextType, pattern.pattern);
    } else if (pattern is ParenthesizedPattern) {
      return dispatchPattern(
        path,
        contextType,
        pattern.pattern,
        nonNull: nonNull,
      );
    } else if (pattern is NullAssertPattern) {
      return createNullAssertSpace(path, contextType, pattern.pattern);
    } else if (pattern is CastPattern) {
      return createCastSpace(
        path,
        contextType,
        pattern.type.typeOrThrow,
        pattern.pattern,
        nonNull: nonNull,
      );
    } else if (pattern is LogicalAndPattern) {
      return createLogicalAndSpace(
        path,
        contextType,
        pattern.leftOperand,
        pattern.rightOperand,
        nonNull: nonNull,
      );
    } else if (pattern is RelationalPattern) {
      return createRelationalSpace(path);
    } else if (pattern is ListPattern) {
      var type = pattern.requiredType as InterfaceTypeImpl;
      assert(
        type.element == cache.typeSystem.typeProvider.listElement &&
            type.typeArguments.length == 1,
      );
      var elementType = type.typeArguments[0];
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
      return createListSpace(
        path,
        type: type,
        elementType: elementType,
        headElements: headElements,
        tailElements: tailElements,
        restElement: restElement,
        hasRest: hasRest,
        hasExplicitTypeArgument: pattern.typeArguments != null,
      );
    } else if (pattern is MapPattern) {
      var type = pattern.requiredType as InterfaceTypeImpl;
      assert(
        type.element == cache.typeSystem.typeProvider.mapElement &&
            type.typeArguments.length == 2,
      );
      var keyType = type.typeArguments[0];
      var valueType = type.typeArguments[1];
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

      return createMapSpace(
        path,
        type: cache.typeSystem.typeProvider.mapType(keyType, valueType),
        keyType: keyType,
        valueType: valueType,
        entries: entries,
        hasExplicitTypeArguments: pattern.typeArguments != null,
      );
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
    var type = value.type;
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
      return Space(path, cache.getStaticType(type), properties: properties);
    }
    if (type is InterfaceTypeImpl) {
      var element = type.element;
      if (element is EnumElementImpl) {
        return Space(path, cache.getEnumElementStaticType(element, value));
      }
    }

    StaticType staticType;
    if (value.hasPrimitiveEquality(featureSet)) {
      staticType = cache.getUniqueStaticType<DartObjectImpl>(
        type,
        value,
        value.state.toString(),
      );
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
  TypeImpl? visitTypeParameterBound(covariant TypeImpl type) {
    Variance savedVariance = _variance;
    _variance = Variance.invariant;
    var result = type.accept(this);
    _variance = savedVariance;
    return result;
  }

  @override
  TypeImpl? visitTypeParameterType(covariant TypeParameterTypeImpl node) {
    if (_variance == Variance.contravariant) {
      return _replaceTypeParameterTypes(_typeSystem.typeProvider.neverType);
    } else {
      var element = node.element;
      var defaultType = element.defaultType!;
      return _replaceTypeParameterTypes(defaultType);
    }
  }

  TypeImpl _replaceTypeParameterTypes(TypeImpl type) {
    return type.accept(this) ?? type;
  }

  static TypeImpl replaceTypeVariables(
    TypeSystemImpl typeSystem,
    TypeImpl type,
  ) {
    return TypeParameterReplacer(typeSystem)._replaceTypeParameterTypes(type);
  }
}
