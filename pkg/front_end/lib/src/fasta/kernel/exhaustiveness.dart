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
import 'package:front_end/src/fasta/kernel/constant_evaluator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/src/replacement_visitor.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

/// AST printer strategy used by default in `CfeTypeOperations.typeToString`.
const AstTextStrategy textStrategy = const AstTextStrategy(
    showNullableOnly: true, useQualifiedTypeParameterNames: false);

/// Data gathered by the exhaustiveness computation, retained for testing
/// purposes.
class ExhaustivenessDataForTesting {
  /// Access to interface for looking up `Object` members on non-interface
  /// types.
  ObjectFieldLookup? objectFieldLookup;

  /// Map from switch statement/expression nodes to the results of the
  /// exhaustiveness test.
  Map<Node, ExhaustivenessResult> switchResults = {};
}

class ExhaustivenessResult {
  final StaticType scrutineeType;
  final List<Space> caseSpaces;
  final List<int> caseOffsets;
  final List<ExhaustivenessError> errors;

  ExhaustivenessResult(
      this.scrutineeType, this.caseSpaces, this.caseOffsets, this.errors);
}

class CfeTypeOperations implements TypeOperations<DartType> {
  final TypeEnvironment _typeEnvironment;

  CfeTypeOperations(this._typeEnvironment);

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
        (type is NeverType && type.nullability == Nullability.nullable);
  }

  @override
  bool isNullable(DartType type) {
    return type.declaredNullability == Nullability.nullable;
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
    return _typeEnvironment.isSubtypeOf(
        s, t, SubtypeCheckMode.withNullabilities);
  }

  @override
  DartType get nonNullableObjectType =>
      _typeEnvironment.objectNonNullableRawType;

  @override
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
        if (member.name.isPrivate) {
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
                Substitution.fromInterfaceType(
                    _classHierarchy.getTypeAsInstanceOf(type, declaringClass,
                        isNonNullableByDefault: true)!);
            fieldType = substitution.substituteType(fieldType);
          }
          fieldTypes[new NameKey(member.name.text)] = fieldType;
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
    return TypeParameterReplacer.replaceTypeVariables(type);
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
    type = type.resolveTypeParameterType;
    if (type is InterfaceType) {
      InterfaceType? listType = _classHierarchy.getTypeAsInstanceOf(
          type, _typeEnvironment.coreTypes.listClass,
          isNonNullableByDefault: true);
      if (listType != null) {
        return listType.typeArguments[0];
      }
    }
    return null;
  }

  @override
  DartType? getListType(DartType type) {
    type = type.resolveTypeParameterType;
    if (type is InterfaceType) {
      return _classHierarchy.getTypeAsInstanceOf(
          type, _typeEnvironment.coreTypes.listClass,
          isNonNullableByDefault: true);
    }
    return null;
  }

  @override
  DartType? getMapValueType(DartType type) {
    type = type.resolveTypeParameterType;
    if (type is InterfaceType) {
      InterfaceType? mapType = _classHierarchy.getTypeAsInstanceOf(
          type, _typeEnvironment.coreTypes.mapClass,
          isNonNullableByDefault: true);
      if (mapType != null) {
        return mapType.typeArguments[1];
      }
    }
    return null;
  }

  @override
  bool hasSimpleName(DartType type) {
    return type is InterfaceType ||
        type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is InlineType ||
        // TODO(johnniwinther): What about intersection types?
        type is TypeParameterType;
  }
}

class CfeEnumOperations
    implements EnumOperations<DartType, Class, Field, Constant> {
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
  Constant getEnumElementValue(Field enumField) {
    // Enum field initializers might not have been replaced by
    // [ConstantExpression]s. Either because we haven't visited them yet during
    // normal constant evaluation or because they are from outlines that are
    // not part of the fully compiled libraries. Therefore we perform constant
    // evaluation here, to ensure that we have the [Constant] value for the
    // enum element.
    StaticTypeContext context =
        new StaticTypeContext(enumField, _constantEvaluator.typeEnvironment);
    return _constantEvaluator.evaluate(context, enumField.initializer!);
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
    InterfaceType asSealedType = _typeEnvironment.hierarchy.getTypeAsInstanceOf(
        thisType, sealedClassType.classNode,
        isNonNullableByDefault: true)!;
    if (thisType.typeArguments.isEmpty) {
      return thisType;
    }
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
          if (!_typeEnvironment.isSubtypeOf(sealedClassType.typeArguments[i],
              bound, SubtypeCheckMode.withNullabilities)) {
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
      return TypeParameterReplacer.replaceTypeVariables(thisType);
    }
  }
}

class CfeExhaustivenessCache
    extends ExhaustivenessCache<DartType, Class, Class, Field, Constant> {
  CfeExhaustivenessCache(ConstantEvaluator constantEvaluator)
      : super(
            new CfeTypeOperations(constantEvaluator.typeEnvironment),
            new CfeEnumOperations(constantEvaluator),
            new CfeSealedClassOperations(constantEvaluator.typeEnvironment));
}

class PatternConverter with SpaceCreator<Pattern, DartType> {
  final CfeExhaustivenessCache cache;
  final Map<ConstantPattern, Constant> constantPatternValues;
  final Map<MapPatternEntry, Constant> mapPatternKeyValues;
  final StaticTypeContext context;

  PatternConverter(this.cache, this.constantPatternValues,
      this.mapPatternKeyValues, this.context);

  Space convertExpressionToSpace(Expression expression, Path path) {
    Constant? constant = constantPatternValues[expression];
    return convertConstantToSpace(constant, path: path);
  }

  @override
  Space dispatchPattern(Path path, StaticType contextType, Pattern pattern,
      {required bool nonNull}) {
    if (pattern is ObjectPattern) {
      Map<String, Pattern> fields = {};
      for (NamedPattern field in pattern.fields) {
        fields[field.name] = field.pattern;
      }
      return createObjectSpace(path, contextType, pattern.lookupType!, fields,
          nonNull: nonNull);
    } else if (pattern is VariablePattern) {
      return createVariableSpace(path, contextType, pattern.variable.type,
          nonNull: nonNull);
    } else if (pattern is ConstantPattern) {
      return convertConstantToSpace(
          pattern.value ?? constantPatternValues[pattern],
          path: path);
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
      DartType elementType = pattern.typeArgument ?? const DynamicType();
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
          type: pattern.lookupType!,
          elementType: elementType,
          headElements: headPatterns,
          restElement: restPattern,
          tailElements: tailPatterns,
          hasRest: hasRest,
          hasExplicitTypeArgument: pattern.typeArgument != null);
    } else if (pattern is MapPattern) {
      DartType keyType = pattern.keyType ?? const DynamicType();
      DartType valueType = pattern.valueType ?? const DynamicType();
      bool hasRest = false;
      Map<MapKey, Pattern> entries = {};
      for (MapPatternEntry entry in pattern.entries) {
        if (entry is MapPatternRestEntry) {
          hasRest = true;
        } else {
          // TODO(johnniwinther): Assert that we have a constant value.
          Constant? constant = entry.keyValue ?? mapPatternKeyValues[entry];
          if (constant == null) {
            return createUnknownSpace(path);
          }
          MapKey key = new MapKey(constant, constant.toText(textStrategy));
          entries[key] = entry.value;
        }
      }
      return createMapSpace(path,
          type: pattern.lookupType!,
          keyType: keyType,
          valueType: valueType,
          entries: entries,
          hasRest: hasRest,
          hasExplicitTypeArguments:
              pattern.keyType != null && pattern.valueType != null);
    }
    assert(false, "Unexpected pattern $pattern (${pattern.runtimeType}).");
    return createUnknownSpace(path);
  }

  Space convertConstantToSpace(Constant? constant, {required Path path}) {
    if (constant != null) {
      if (constant is NullConstant) {
        return new Space(path, StaticType.nullType);
      } else if (constant is BoolConstant) {
        return new Space(path, cache.getBoolValueStaticType(constant.value));
      } else if (constant is InstanceConstant && constant.classNode.isEnum) {
        return new Space(
            path, cache.getEnumElementStaticType(constant.classNode, constant));
      } else if (constant is RecordConstant) {
        Map<Key, Space> fields = {};
        for (int index = 0; index < constant.positional.length; index++) {
          Key key = new RecordIndexKey(index);
          fields[key] = convertConstantToSpace(constant.positional[index],
              path: path.add(key));
        }
        for (MapEntry<String, Constant> entry in constant.named.entries) {
          Key key = new RecordNameKey(entry.key);
          fields[key] =
              convertConstantToSpace(entry.value, path: path.add(key));
        }
        return new Space(path, cache.getStaticType(constant.recordType),
            fields: fields);
      } else {
        return new Space(
            path,
            cache.getUniqueStaticType<Constant>(constant.getType(context),
                constant, constant.toText(textStrategy)));
      }
    } else {
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
      DartType type, ListTypeIdentity<DartType> identity) {
    return cache.getListStaticType(type, identity);
  }

  @override
  StaticType createMapType(DartType type, MapTypeIdentity<DartType> identity) {
    return cache.getMapStaticType(type, identity);
  }

  @override
  TypeOperations<DartType> get typeOperations => cache.typeOperations;

  @override
  ObjectFieldLookup get objectFieldLookup => cache;
}

bool computeIsAlwaysExhaustiveType(DartType type, CoreTypes coreTypes) {
  return type.accept1(const ExhaustiveDartTypeVisitor(), coreTypes);
}

class ExhaustiveDartTypeVisitor implements DartTypeVisitor1<bool, CoreTypes> {
  const ExhaustiveDartTypeVisitor();

  @override
  bool defaultDartType(DartType type, CoreTypes coreTypes) {
    throw new UnsupportedError('Unsupported type $type');
  }

  @override
  bool visitDynamicType(DynamicType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitExtensionType(ExtensionType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitFunctionType(FunctionType type, CoreTypes coreTypes) {
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType type, CoreTypes coreTypes) {
    // TODO(johnniwinther): Why? This doesn't work if the value is a Future.
    return type.typeArgument.accept1(this, coreTypes);
  }

  @override
  bool visitInlineType(InlineType type, CoreTypes coreTypes) {
    return type.instantiatedRepresentationType.accept1(this, coreTypes);
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
    // TODO(johnniwinther): Why don't we use the bound?
    return false;
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
    // TODO(johnniwinther): Why don't we use the bound?
    return false;
  }

  @override
  bool visitTypedefType(TypedefType type, CoreTypes coreTypes) {
    return type.unalias.accept1(this, coreTypes);
  }

  @override
  bool visitVoidType(VoidType type, CoreTypes coreTypes) {
    return false;
  }
}

class TypeParameterReplacer extends ReplacementVisitor {
  const TypeParameterReplacer();

  @override
  DartType? visitTypeParameterType(TypeParameterType node, int variance) {
    DartType replacement = super.visitTypeParameterType(node, variance) ?? node;
    if (replacement is TypeParameterType) {
      if (variance == Variance.contravariant) {
        return _replaceTypeParameterTypes(
            const NeverType.nonNullable(), variance);
      } else {
        return _replaceTypeParameterTypes(
            replacement.parameter.defaultType, variance);
      }
    }
    return replacement;
  }

  DartType _replaceTypeParameterTypes(DartType type, int variance) {
    return type.accept1(this, variance) ?? type;
  }

  static DartType replaceTypeVariables(DartType type) {
    return const TypeParameterReplacer()
        ._replaceTypeParameterTypes(type, Variance.covariant);
  }
}
