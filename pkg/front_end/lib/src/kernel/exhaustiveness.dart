// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/key.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/path.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/shared.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/types.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/src/replacement_visitor.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import 'constant_evaluator.dart';

/// AST printer strategy used by default in `CfeTypeOperations.typeToString`.
const AstTextStrategy textStrategy = const AstTextStrategy(
    showNullableOnly: true, useQualifiedTypeParameterNames: false);

/// Data gathered by the exhaustiveness computation, retained for testing
/// purposes.
class ExhaustivenessDataForTesting {
  /// Access to interface for looking up `Object` members on non-interface
  /// types.
  ObjectPropertyLookup? objectFieldLookup;

  /// Map from switch statement/expression nodes to the results of the
  /// exhaustiveness test.
  Map<Node, ExhaustivenessResult> switchResults = {};
}

// Coverage-ignore(suite): Not run.
class ExhaustivenessResult {
  final StaticType scrutineeType;
  final List<Space> caseSpaces;
  final List<int> caseOffsets;
  final Set<int> unreachableCases;
  final NonExhaustiveness? nonExhaustiveness;

  ExhaustivenessResult(this.scrutineeType, this.caseSpaces, this.caseOffsets,
      this.unreachableCases, this.nonExhaustiveness);
}

class CfeTypeOperations implements TypeOperations<DartType> {
  final TypeEnvironment _typeEnvironment;
  final Library _enclosingLibrary;

  CfeTypeOperations(this._typeEnvironment, this._enclosingLibrary);

  ClassHierarchy get _classHierarchy => _typeEnvironment.hierarchy;

  @override
  DartType getNonNullable(DartType type) {
    return type.toNonNull();
  }

  @override
  bool isNeverType(DartType type) {
    return type is NeverType && type.nullability == Nullability.nonNullable;
  }

  @override
  bool isNonNullableObject(DartType type) {
    return type is InterfaceType &&
        type.classNode == _typeEnvironment.objectClass &&
        type.nullability == Nullability.nonNullable;
  }

  @override
  bool isNullType(DartType type) {
    return type is NullType ||
        (type is NeverType &&
            // Coverage-ignore(suite): Not run.
            type.nullability == Nullability.nullable);
  }

  @override
  bool isNullable(DartType type) {
    return type.declaredNullability == Nullability.nullable;
  }

  @override
  bool isPotentiallyNullable(DartType type) {
    return type.nullability != Nullability.nonNullable;
  }

  @override
  bool isNullableObject(DartType type) {
    return type == _typeEnvironment.objectNullableRawType;
  }

  @override
  bool isDynamic(DartType type) {
    return type is DynamicType;
  }

  @override
  bool isRecordType(DartType type) {
    return type is RecordType && !isNullable(type);
  }

  @override
  bool isSubtypeOf(DartType s, DartType t) {
    return _typeEnvironment.isSubtypeOf(s, t);
  }

  @override
  DartType get nonNullableObjectType =>
      _typeEnvironment.objectNonNullableRawType;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get nullableObjectType => _typeEnvironment.objectNullableRawType;

  @override
  DartType get boolType => _typeEnvironment.coreTypes.boolNonNullableRawType;

  @override
  bool isBoolType(DartType type) {
    return type == _typeEnvironment.coreTypes.boolNonNullableRawType;
  }

  @override
  Map<Key, DartType> getFieldTypes(DartType type) {
    if (type is InterfaceType) {
      Map<Key, DartType> fieldTypes = {};
      Map<Class, Substitution> substitutions = {};
      for (Member member
          in _classHierarchy.getInterfaceMembers(type.classNode)) {
        if (member.name.isPrivate && member.name.library != _enclosingLibrary) {
          continue;
        }
        DartType? fieldType;
        if (member is Field) {
          fieldType = member.getterType;
        } else if (member is Procedure && !member.isSetter) {
          fieldType = member.getterType;
        }
        if (fieldType != null) {
          Class declaringClass = member.enclosingClass!;
          if (declaringClass.typeParameters.isNotEmpty) {
            Substitution substitution = substitutions[declaringClass] ??=
                Substitution.fromInterfaceType(_classHierarchy
                    .getInterfaceTypeAsInstanceOfClass(type, declaringClass)!);
            fieldType = substitution.substituteType(fieldType);
          }
          fieldTypes[new NameKey(member.name.text)] = fieldType;
        }
      }
      return fieldTypes;
    } else if (type is ExtensionType) {
      // Coverage-ignore-block(suite): Not run.
      ExtensionTypeDeclaration extensionTypeDeclaration =
          type.extensionTypeDeclaration;
      Map<Key, DartType> fieldTypes = {};
      for (TypeDeclarationType implementedType
          in extensionTypeDeclaration.implements) {
        Map<Key, DartType> implementedFieldTypes =
            getFieldTypes(implementedType);
        if (implementedType.typeDeclaration.typeParameters.isNotEmpty) {
          Substitution substitution = Substitution.fromTypeDeclarationType(
              _classHierarchy.getTypeAsInstanceOf(
                  type, implementedType.typeDeclaration)!);
          for (MapEntry<Key, DartType> entry in implementedFieldTypes.entries) {
            fieldTypes[entry.key] = substitution.substituteType(entry.value);
          }
        } else {
          fieldTypes.addAll(implementedFieldTypes);
        }
      }
      Substitution substitution = Substitution.fromExtensionType(type);
      for (Procedure procedure in extensionTypeDeclaration.procedures) {
        if (!procedure.isSetter) {
          DartType fieldType =
              substitution.substituteType(procedure.getterType);
          fieldTypes[new NameKey(procedure.name.text)] = fieldType;
        }
      }
      for (ExtensionTypeMemberDescriptor descriptor
          in extensionTypeDeclaration.memberDescriptors) {
        if (descriptor.isStatic) {
          continue;
        }
        switch (descriptor.kind) {
          case ExtensionTypeMemberKind.Method:
            Procedure tearOff = descriptor.tearOffReference!.asProcedure;
            FunctionType functionType = tearOff.getterType as FunctionType;
            if (extensionTypeDeclaration.typeParameters.isNotEmpty) {
              functionType = FunctionTypeInstantiator.instantiate(
                  functionType, type.typeArguments);
            }
            fieldTypes[new NameKey(descriptor.name.text)] =
                functionType.returnType;
          case ExtensionTypeMemberKind.Getter:
            Procedure member = descriptor.memberReference!.asProcedure;
            FunctionType functionType = member.getterType as FunctionType;
            if (extensionTypeDeclaration.typeParameters.isNotEmpty) {
              functionType = FunctionTypeInstantiator.instantiate(
                  functionType, type.typeArguments);
            }
            fieldTypes[new NameKey(descriptor.name.text)] =
                functionType.returnType;
          case ExtensionTypeMemberKind.Field:
          case ExtensionTypeMemberKind.Constructor:
          case ExtensionTypeMemberKind.Factory:
          case ExtensionTypeMemberKind.Setter:
          case ExtensionTypeMemberKind.Operator:
          case ExtensionTypeMemberKind.RedirectingFactory:
            break;
        }
      }
      return fieldTypes;
    } else if (type is RecordType) {
      Map<Key, DartType> fieldTypes = {};
      fieldTypes.addAll(
          getFieldTypes(_typeEnvironment.coreTypes.objectNonNullableRawType));
      for (int index = 0; index < type.positional.length; index++) {
        fieldTypes[new RecordIndexKey(index)] = type.positional[index];
      }
      for (NamedType field in type.named) {
        fieldTypes[new RecordNameKey(field.name)] = field.type;
      }
      return fieldTypes;
    } else {
      return getFieldTypes(_typeEnvironment.coreTypes.objectNonNullableRawType);
    }
  }

  @override
  String typeToString(DartType type) => type.toText(textStrategy);

  @override
  DartType overapproximate(DartType type) {
    return TypeParameterReplacer.replaceTypeParameters(type);
  }

  @override
  bool isGeneric(DartType type) {
    return type is InterfaceType && type.typeArguments.isNotEmpty;
  }

  @override
  DartType instantiateFuture(DartType type) {
    return _typeEnvironment.futureType(type, Nullability.nonNullable);
  }

  @override
  DartType? getFutureOrTypeArgument(DartType type) {
    return type is FutureOrType ? type.typeArgument : null;
  }

  @override
  DartType? getListElementType(DartType type) {
    type = type.nonTypeParameterBound;
    if (type is TypeDeclarationType) {
      List<DartType>? typeArguments =
          _classHierarchy.getTypeArgumentsAsInstanceOf(
              type, _typeEnvironment.coreTypes.listClass);
      if (typeArguments != null) {
        return typeArguments[0];
      }
    }
    return null;
  }

  @override
  DartType? getListType(DartType type) {
    type = type.nonTypeParameterBound;
    if (type is TypeDeclarationType) {
      return _classHierarchy.getTypeAsInstanceOf(
          type, _typeEnvironment.coreTypes.listClass);
    }
    return null;
  }

  @override
  DartType? getMapValueType(DartType type) {
    type = type.nonTypeParameterBound;
    if (type is TypeDeclarationType) {
      List<DartType>? typeArguments =
          _classHierarchy.getTypeArgumentsAsInstanceOf(
              type, _typeEnvironment.coreTypes.mapClass);
      if (typeArguments != null) {
        return typeArguments[1];
      }
    }
    return null;
  }

  @override
  bool hasSimpleName(DartType type) {
    return type is InterfaceType ||
        // Coverage-ignore(suite): Not run.
        type is DynamicType ||
        // Coverage-ignore(suite): Not run.
        type is VoidType ||
        // Coverage-ignore(suite): Not run.
        type is NeverType ||
        // Coverage-ignore(suite): Not run.
        type is NullType ||
        // Coverage-ignore(suite): Not run.
        type is ExtensionType ||
        // Coverage-ignore(suite): Not run.
        // TODO(johnniwinther): What about intersection types?
        type is TypeParameterType;
  }

  @override
  DartType? getTypeVariableBound(DartType type) {
    if (type is TypeParameterType) {
      return type.bound;
    } else if (type is IntersectionType) {
      return type.right;
    }
    return null;
  }

  @override
  DartType getExtensionTypeErasure(DartType type) {
    return type.extensionTypeErasure;
  }
}

class EnumValue {
  final Class enumClass;
  final String name;

  EnumValue(this.enumClass, this.name);

  @override
  int get hashCode => Object.hash(enumClass, name);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is EnumValue &&
        enumClass == other.enumClass &&
        name == other.name;
  }
}

EnumValue? constantToEnumValue(CoreTypes coreTypes, Constant constant) {
  if (constant is InstanceConstant && constant.classNode.isEnum) {
    StringConstant name = constant
        .fieldValues[coreTypes.enumNameField.fieldReference] as StringConstant;
    return new EnumValue(constant.classNode, name.value);
  } else if (constant is UnevaluatedConstant) {
    Expression expression = constant.expression;
    if (expression is FileUriExpression) {
      expression = expression.expression;
    }
    if (expression is InstanceCreation && expression.classNode.isEnum) {
      ConstantExpression name =
          expression.fieldValues[coreTypes.enumNameField.fieldReference]
              as ConstantExpression;
      return new EnumValue(
          expression.classNode, (name.constant as StringConstant).value);
    }
  }
  return null;
}

class CfeEnumOperations
    implements EnumOperations<DartType, Class, Field, EnumValue> {
  final ConstantEvaluator _constantEvaluator;

  CfeEnumOperations(this._constantEvaluator);

  @override
  Class? getEnumClass(DartType type) {
    if (type is InterfaceType && type.classNode.isEnum) {
      return type.classNode;
    }
    return null;
  }

  @override
  String getEnumElementName(Field enumField) {
    return '${enumField.enclosingClass!.name}.${enumField.name}';
  }

  @override
  InterfaceType getEnumElementType(Field enumField) {
    return enumField.type as InterfaceType;
  }

  @override
  EnumValue? getEnumElementValue(Field enumField) {
    // Enum field initializers might not have been replaced by
    // [ConstantExpression]s. Either because we haven't visited them yet during
    // normal constant evaluation or because they are from outlines that are
    // not part of the fully compiled libraries. Therefore we perform constant
    // evaluation here, to ensure that we have the [Constant] value for the
    // enum element.
    StaticTypeContext context =
        new StaticTypeContext(enumField, _constantEvaluator.typeEnvironment);
    return constantToEnumValue(_constantEvaluator.coreTypes,
        _constantEvaluator.evaluate(context, enumField.initializer!));
  }

  @override
  Iterable<Field> getEnumElements(Class enumClass) sync* {
    for (Field field in enumClass.fields) {
      if (field.isEnumElement) {
        yield field;
      }
    }
  }
}

class CfeSealedClassOperations
    implements SealedClassOperations<DartType, Class> {
  final TypeEnvironment _typeEnvironment;

  CfeSealedClassOperations(this._typeEnvironment);

  @override
  List<Class> getDirectSubclasses(Class sealedClass) {
    Library library = sealedClass.enclosingLibrary;
    List<Class> list = [];
    outer:
    for (Class cls in library.classes) {
      if (cls == sealedClass) continue;
      Class? superclass = cls.superclass;
      while (superclass != null) {
        if (!superclass.isMixinApplication) {
          if (superclass == sealedClass) {
            list.add(cls);
            continue outer;
          }
          break;
        } else {
          // Mixed in class are encoded through unnamed mixin applications:
          //
          //    class Class extends Super with Mixin {}
          //
          // =>
          //
          //    class _Super&Mixin extends Super /* mixedInClass = Mixin */
          //    class Class extends _Super&Mixin {}
          //
          if (superclass.mixedInClass == sealedClass) {
            // Coverage-ignore-block(suite): Not run.
            list.add(cls);
            continue outer;
          }
          superclass = superclass.superclass;
        }
      }
      for (Supertype interface in cls.implementedTypes) {
        if (interface.classNode == sealedClass) {
          list.add(cls);
          continue outer;
        }
      }
    }
    return list;
  }

  @override
  Class? getSealedClass(DartType type) {
    if (type is InterfaceType && type.classNode.isSealed) {
      return type.classNode;
    }
    return null;
  }

  @override
  DartType? getSubclassAsInstanceOf(
      Class subClass, covariant InterfaceType sealedClassType) {
    InterfaceType thisType = subClass.getThisType(
        _typeEnvironment.coreTypes, Nullability.nonNullable);
    InterfaceType asSealedType = _typeEnvironment.hierarchy
        .getInterfaceTypeAsInstanceOfClass(
            thisType, sealedClassType.classNode)!;
    if (thisType.typeArguments.isEmpty) {
      return thisType;
    }
    // Coverage-ignore-block(suite): Not run.
    bool trivialSubstitution = true;
    if (thisType.typeArguments.length == asSealedType.typeArguments.length) {
      for (int i = 0; i < thisType.typeArguments.length; i++) {
        if (thisType.typeArguments[i] != asSealedType.typeArguments[i]) {
          trivialSubstitution = false;
          break;
        }
      }
      if (trivialSubstitution) {
        Substitution substitution = Substitution.fromPairs(
            subClass.typeParameters, sealedClassType.typeArguments);
        for (int i = 0; i < subClass.typeParameters.length; i++) {
          DartType bound =
              substitution.substituteType(subClass.typeParameters[i].bound);
          if (!_typeEnvironment.isSubtypeOf(
              sealedClassType.typeArguments[i], bound)) {
            trivialSubstitution = false;
            break;
          }
        }
      }
    } else {
      trivialSubstitution = false;
    }
    if (trivialSubstitution) {
      return new InterfaceType(
          subClass, Nullability.nonNullable, sealedClassType.typeArguments);
    } else {
      return TypeParameterReplacer.replaceTypeParameters(thisType);
    }
  }
}

class CfeExhaustivenessCache
    extends ExhaustivenessCache<DartType, Class, Class, Field, EnumValue> {
  final TypeEnvironment typeEnvironment;

  CfeExhaustivenessCache(
      ConstantEvaluator constantEvaluator, Library enclosingLibrary)
      : typeEnvironment = constantEvaluator.typeEnvironment,
        super(
            new CfeTypeOperations(
                constantEvaluator.typeEnvironment, enclosingLibrary),
            new CfeEnumOperations(constantEvaluator),
            new CfeSealedClassOperations(constantEvaluator.typeEnvironment));
}

class PatternConverter with SpaceCreator<Pattern, DartType> {
  final Version languageVersion;
  final CfeExhaustivenessCache cache;
  final StaticTypeContext context;
  final bool Function(Constant) hasPrimitiveEquality;

  PatternConverter(this.languageVersion, this.cache, this.context,
      {required this.hasPrimitiveEquality});

  @override
  bool hasLanguageVersion(int major, int minor) {
    return languageVersion >= new Version(major, minor);
  }

  @override
  Space dispatchPattern(Path path, StaticType contextType, Pattern pattern,
      {required bool nonNull}) {
    if (pattern is ObjectPattern) {
      Map<String, Pattern> properties = {};
      Map<String, DartType> extensionPropertyTypes = {};
      for (NamedPattern field in pattern.fields) {
        properties[field.name] = field.pattern;
        switch (field.accessKind) {
          case ObjectAccessKind.Extension:
          case ObjectAccessKind.ExtensionType:
          case ObjectAccessKind.Direct:
            extensionPropertyTypes[field.name] = field.resultType!;
          case ObjectAccessKind.Object:
          case ObjectAccessKind.Instance:
          case ObjectAccessKind.RecordNamed:
          case ObjectAccessKind.RecordIndexed:
          case ObjectAccessKind.Dynamic:
          case ObjectAccessKind.Never:
          case ObjectAccessKind.Invalid:
          case ObjectAccessKind.FunctionTearOff:
          case ObjectAccessKind.Error:
        }
      }
      return createObjectSpace(path, contextType, pattern.requiredType,
          properties, extensionPropertyTypes,
          nonNull: nonNull);
    } else if (pattern is VariablePattern) {
      return createVariableSpace(path, contextType, pattern.variable.type,
          nonNull: nonNull);
    } else if (pattern is ConstantPattern) {
      return convertConstantToSpace(pattern.value!, path: path);
    } else if (pattern is RecordPattern) {
      List<Pattern> positional = [];
      Map<String, Pattern> named = {};
      for (Pattern field in pattern.patterns) {
        if (field is NamedPattern) {
          named[field.name] = field.pattern;
        } else {
          positional.add(field);
        }
      }
      return createRecordSpace(
          path, contextType, pattern.requiredType!, positional, named);
    } else if (pattern is WildcardPattern) {
      return createWildcardSpace(path, contextType, pattern.type,
          nonNull: nonNull);
    } else if (pattern is OrPattern) {
      return createLogicalOrSpace(
          path, contextType, pattern.left, pattern.right,
          nonNull: nonNull);
    } else if (pattern is NullCheckPattern) {
      return createNullCheckSpace(path, contextType, pattern.pattern);
    } else if (pattern is NullAssertPattern) {
      return createNullAssertSpace(path, contextType, pattern.pattern);
    } else if (pattern is CastPattern) {
      return createCastSpace(path, contextType, pattern.type, pattern.pattern,
          nonNull: nonNull);
    } else if (pattern is AndPattern) {
      return createLogicalAndSpace(
          path, contextType, pattern.left, pattern.right,
          nonNull: nonNull);
    } else if (pattern is InvalidPattern) {
      // These pattern do not add to the exhaustiveness coverage.
      return createUnknownSpace(path);
    } else if (pattern is RelationalPattern) {
      return createRelationalSpace(path);
    } else if (pattern is ListPattern) {
      InterfaceType type = pattern.requiredType as InterfaceType;
      assert(type.classNode == cache.typeEnvironment.coreTypes.listClass &&
          type.typeArguments.length == 1);
      DartType elementType = type.typeArguments[0];
      bool hasRest = false;
      List<Pattern> headPatterns = [];
      Pattern? restPattern;
      List<Pattern> tailPatterns = [];
      for (Pattern element in pattern.patterns) {
        if (element is RestPattern) {
          hasRest = true;
          restPattern = element.subPattern;
        } else if (hasRest) {
          tailPatterns.add(element);
        } else {
          headPatterns.add(element);
        }
      }
      return createListSpace(path,
          type: pattern.requiredType!,
          elementType: elementType,
          headElements: headPatterns,
          restElement: restPattern,
          tailElements: tailPatterns,
          hasRest: hasRest,
          hasExplicitTypeArgument: pattern.typeArgument != null);
    } else if (pattern is MapPattern) {
      InterfaceType type = pattern.requiredType as InterfaceType;
      assert(type.classNode == cache.typeEnvironment.coreTypes.mapClass &&
          type.typeArguments.length == 2);
      DartType keyType = type.typeArguments[0];
      DartType valueType = type.typeArguments[1];
      Map<MapKey, Pattern> entries = {};
      for (MapPatternEntry entry in pattern.entries) {
        if (entry is MapPatternRestEntry) {
          // Rest patterns are illegal in map patterns, so just skip over it.
        } else {
          Constant constant = entry.keyValue!;
          MapKey key = new MapKey(constant, constant.toText(textStrategy));
          entries[key] = entry.value;
        }
      }
      return createMapSpace(path,
          type: pattern.lookupType!,
          keyType: keyType,
          valueType: valueType,
          entries: entries,
          hasExplicitTypeArguments:
              pattern.keyType != null && pattern.valueType != null);
    }
    // Coverage-ignore-block(suite): Not run.
    assert(false, "Unexpected pattern $pattern (${pattern.runtimeType}).");
    return createUnknownSpace(path);
  }

  Space convertConstantToSpace(Constant? constant, {required Path path}) {
    if (constant != null) {
      EnumValue? enumValue =
          constantToEnumValue(cache.typeEnvironment.coreTypes, constant);
      if (enumValue != null) {
        return new Space(path,
            cache.getEnumElementStaticType(enumValue.enumClass, enumValue));
      } else if (constant is NullConstant) {
        return new Space(path, StaticType.nullType);
      } else if (constant is BoolConstant) {
        return new Space(path, cache.getBoolValueStaticType(constant.value));
      } else if (constant is RecordConstant) {
        Map<Key, Space> properties = {};
        for (int index = 0;
            index < constant.positional.length;
            // Coverage-ignore(suite): Not run.
            index++) {
          // Coverage-ignore-block(suite): Not run.
          Key key = new RecordIndexKey(index);
          properties[key] = convertConstantToSpace(constant.positional[index],
              path: path.add(key));
        }
        for (MapEntry<String, Constant> entry in constant.named.entries) {
          // Coverage-ignore-block(suite): Not run.
          Key key = new RecordNameKey(entry.key);
          properties[key] =
              convertConstantToSpace(entry.value, path: path.add(key));
        }
        return new Space(path, cache.getStaticType(constant.recordType),
            properties: properties);
      } else if (hasPrimitiveEquality(constant)) {
        // Only if [constant] has primitive equality can we tell if it is equal
        // to itself.
        return new Space(
            path,
            cache.getUniqueStaticType<Constant>(constant.getType(context),
                constant, constant.toText(textStrategy)));
      } else {
        return new Space(path, cache.getUnknownStaticType());
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      // TODO(johnniwinther): Assert that constant value is available when the
      // exhaustiveness checking is complete.
      return new Space(path, cache.getUnknownStaticType());
    }
  }

  @override
  StaticType createUnknownStaticType() {
    return cache.getUnknownStaticType();
  }

  @override
  StaticType createStaticType(DartType type) {
    return cache.getStaticType(type);
  }

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
  TypeOperations<DartType> get typeOperations => cache.typeOperations;

  @override
  ObjectPropertyLookup get objectFieldLookup => cache;
}

bool computeIsAlwaysExhaustiveType(DartType type, CoreTypes coreTypes) {
  return type.accept1(const ExhaustiveDartTypeVisitor(), coreTypes);
}

class ExhaustiveDartTypeVisitor implements DartTypeVisitor1<bool, CoreTypes> {
  const ExhaustiveDartTypeVisitor();

  @override
  bool visitAuxiliaryType(AuxiliaryType node, CoreTypes coreTypes) {
    throw new UnsupportedError(
        "Unsupported auxiliary type $node (${node.runtimeType}).");
  }

  @override
  bool visitDynamicType(DynamicType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool visitFunctionType(FunctionType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType type, CoreTypes coreTypes) {
    return type.typeArgument.accept1(this, coreTypes);
  }

  @override
  bool visitExtensionType(ExtensionType type, CoreTypes coreTypes) {
    return type.extensionTypeErasure.accept1(this, coreTypes);
  }

  @override
  bool visitInterfaceType(InterfaceType type, CoreTypes coreTypes) {
    if (type.classNode == coreTypes.boolClass) {
      return true;
    } else if (type.classNode.isEnum) {
      return true;
    } else if (type.classNode.isSealed) {
      return true;
    } else {
      return false;
    }
  }

  @override
  bool visitIntersectionType(IntersectionType type, CoreTypes coreTypes) {
    return type.right.accept1(this, coreTypes);
  }

  @override
  bool visitInvalidType(InvalidType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitNeverType(NeverType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitNullType(NullType type, CoreTypes coreTypes) {
    return true;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool visitRecordType(RecordType type, CoreTypes coreTypes) {
    for (DartType positional in type.positional) {
      if (!positional.accept1(this, coreTypes)) {
        return false;
      }
    }
    for (NamedType named in type.named) {
      if (!named.type.accept1(this, coreTypes)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool visitTypeParameterType(TypeParameterType type, CoreTypes coreTypes) {
    return type.bound.accept1(this, coreTypes);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool visitStructuralParameterType(
      StructuralParameterType type, CoreTypes coreTypes) {
    return type.bound.accept1(this, coreTypes);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool visitTypedefType(TypedefType type, CoreTypes coreTypes) {
    return type.unalias.accept1(this, coreTypes);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool visitVoidType(VoidType type, CoreTypes coreTypes) {
    return false;
  }
}

class TypeParameterReplacer extends ReplacementVisitor {
  const TypeParameterReplacer();

  @override
  DartType? visitTypeParameterType(TypeParameterType node, Variance variance) {
    DartType replacement = super.visitTypeParameterType(node, variance) ?? node;
    if (replacement is TypeParameterType) {
      if (variance == Variance.contravariant) {
        // Coverage-ignore-block(suite): Not run.
        return _replaceTypeParameterTypes(
            const NeverType.nonNullable(), variance);
      } else {
        return _replaceTypeParameterTypes(
            replacement.parameter.defaultType, variance);
      }
    }
    return replacement;
  }

  DartType _replaceTypeParameterTypes(DartType type, Variance variance) {
    return type.accept1(this, variance) ?? type;
  }

  static DartType replaceTypeParameters(DartType type) {
    return const TypeParameterReplacer()
        ._replaceTypeParameterTypes(type, Variance.covariant);
  }
}
