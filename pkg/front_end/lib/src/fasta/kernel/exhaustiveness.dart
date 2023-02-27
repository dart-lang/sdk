// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_types.dart';
import 'package:front_end/src/fasta/kernel/constant_evaluator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/src/replacement_visitor.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'internal_ast.dart';

/// AST printer strategy used by default in `CfeTypeOperations.typeToString`.
const AstTextStrategy textStrategy = const AstTextStrategy(
    showNullableOnly: true, useQualifiedTypeParameterNames: false);

/// Data gathered by the exhaustiveness computation, retained for testing
/// purposes.
class ExhaustivenessDataForTesting {
  /// Map from switch statement/expression nodes to the results of the
  /// exhaustiveness test.
  Map<Node, ExhaustivenessResult> switchResults = {};
}

class ExhaustivenessResult {
  final StaticType scrutineeType;
  final List<Space> caseSpaces;
  final List<int> caseOffsets;
  final List<Space> remainingSpaces;
  final List<ExhaustivenessError> errors;

  ExhaustivenessResult(this.scrutineeType, this.caseSpaces, this.caseOffsets,
      this.remainingSpaces, this.errors);
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
    return type.isPotentiallyNullable;
  }

  @override
  bool isNullableObject(DartType type) {
    return type == _typeEnvironment.objectNullableRawType;
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
  DartType get nullableObjectType => _typeEnvironment.objectNullableRawType;

  @override
  DartType get boolType => _typeEnvironment.coreTypes.boolNonNullableRawType;

  @override
  bool isBoolType(DartType type) {
    return type == _typeEnvironment.coreTypes.boolNonNullableRawType;
  }

  @override
  Map<String, DartType> getFieldTypes(DartType type) {
    Map<String, DartType> fieldTypes = {};
    if (type is InterfaceType) {
      Map<Class, Substitution> substitutions = {};
      for (Member member
          in _classHierarchy.getInterfaceMembers(type.classNode)) {
        if (member.name.isPrivate) {
          continue;
        }
        DartType? fieldType;
        if (member is Field) {
          fieldType = member.getterType;
        } else if (member is Procedure && member.isGetter) {
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
          fieldTypes[member.name.text] = fieldType;
        }
      }
    } else if (type is RecordType) {
      Map<String, DartType> fieldTypes = {};
      for (int index = 0; index < type.positional.length; index++) {
        fieldTypes['\$${index + 1}'] = type.positional[index];
      }
      for (NamedType field in type.named) {
        fieldTypes[field.name] = field.type;
      }
      return fieldTypes;
    }
    return fieldTypes;
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

abstract class SwitchCaseInfo {
  int get fileOffset;

  Space createSpace(CfeExhaustivenessCache cache,
      Map<Node, Constant?> constants, StaticTypeContext context);
}

class ExpressionCaseInfo extends SwitchCaseInfo {
  final Expression expression;

  @override
  final int fileOffset;

  ExpressionCaseInfo(this.expression, {required this.fileOffset});

  @override
  Space createSpace(CfeExhaustivenessCache cache,
      Map<Node, Constant?> constants, StaticTypeContext context) {
    return convertExpressionToSpace(cache, expression, constants, context);
  }
}

class PatternCaseInfo extends SwitchCaseInfo {
  final Pattern pattern;
  @override
  final int fileOffset;

  PatternCaseInfo(this.pattern, {required this.fileOffset});

  @override
  Space createSpace(CfeExhaustivenessCache cache,
      Map<Node, Constant?> constants, StaticTypeContext context) {
    return convertPatternToSpace(cache, pattern, constants, context);
  }
}

class SwitchInfo {
  final TreeNode node;
  final DartType expressionType;
  final List<SwitchCaseInfo> cases;
  final bool mustBeExhaustive;
  final int fileOffset;

  SwitchInfo(this.node, this.expressionType, this.cases,
      {required this.mustBeExhaustive, required this.fileOffset});
}

class ExhaustivenessInfo {
  Map<TreeNode, SwitchInfo> _switchInfo = {};

  void registerSwitchInfo(SwitchInfo info) {
    _switchInfo[info.node] = info;
  }

  SwitchInfo? getSwitchInfo(TreeNode node) => _switchInfo.remove(node);

  bool get isEmpty => _switchInfo.isEmpty;

  Iterable<TreeNode> get nodes => _switchInfo.keys;
}

Space convertExpressionToSpace(
    CfeExhaustivenessCache cache,
    Expression expression,
    Map<Node, Constant?> constants,
    StaticTypeContext context) {
  Constant? constant = constants[expression];
  return convertConstantToSpace(cache, constant, constants, context);
}

Space convertPatternToSpace(CfeExhaustivenessCache cache, Pattern pattern,
    Map<Node, Constant?> constants, StaticTypeContext context) {
  if (pattern is ObjectPattern) {
    DartType type = pattern.objectType;
    Map<String, Space> fields = {};
    for (NamedPattern field in pattern.fields) {
      fields[field.name] =
          convertPatternToSpace(cache, field.pattern, constants, context);
    }
    return new Space(cache.getStaticType(type), fields);
  } else if (pattern is VariablePattern) {
    return new Space(cache.getStaticType(pattern.variable.type));
  } else if (pattern is ConstantPattern) {
    return convertExpressionToSpace(
        cache, pattern.expression, constants, context);
  } else if (pattern is RecordPattern) {
    int index = 1;
    Map<String, Space> fields = {};
    for (Pattern field in pattern.patterns) {
      String name;
      Pattern subpattern;
      if (field is NamedPattern) {
        name = field.name;
        subpattern = field.pattern;
      } else {
        name = '\$${index++}';
        subpattern = field;
      }
      fields[name] =
          convertPatternToSpace(cache, subpattern, constants, context);
    }
    return new Space(cache.getStaticType(pattern.type), fields);
  } else if (pattern is WildcardPattern) {
    final DartType? type = pattern.type;
    if (type == null) {
      return Space.top;
    } else {
      return new Space(cache.getStaticType(type));
    }
  } else if (pattern is OrPattern) {
    return new Space.union([
      convertPatternToSpace(cache, pattern.left, constants, context),
      convertPatternToSpace(cache, pattern.right, constants, context)
    ]);
  }

  // TODO(johnniwinther): Handle remaining constants.
  return new Space(cache.getUnknownStaticType());
}

Space convertConstantToSpace(CfeExhaustivenessCache cache, Constant? constant,
    Map<Node, Constant?> constants, StaticTypeContext context) {
  if (constant != null) {
    if (constant is NullConstant) {
      return Space.nullSpace;
    } else if (constant is BoolConstant) {
      return new Space(cache.getBoolValueStaticType(constant.value));
    } else if (constant is InstanceConstant && constant.classNode.isEnum) {
      return new Space(
          cache.getEnumElementStaticType(constant.classNode, constant));
    } else if (constant is RecordConstant) {
      Map<String, Space> fields = {};
      for (int index = 0; index < constant.positional.length; index++) {
        fields['\$${index + 1}'] = convertConstantToSpace(
            cache, constant.positional[index], constants, context);
      }
      for (MapEntry<String, Constant> entry in constant.named.entries) {
        fields[entry.key] =
            convertConstantToSpace(cache, entry.value, constants, context);
      }
      return new Space(cache.getStaticType(constant.recordType), fields);
    } else {
      return new Space(cache.getUniqueStaticType(
          constant.getType(context), constant, '${constant}'));
    }
  } else {
    // TODO(johnniwinther): Assert that constant value is available when the
    // exhaustiveness checking is complete.
    return new Space(cache.getUnknownStaticType());
  }
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
