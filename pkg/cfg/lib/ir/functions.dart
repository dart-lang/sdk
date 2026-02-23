// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/source_position.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;

/// Base class representing a function (getter, setter, regular method,
/// constructor, field initializer etc) in CFG IR.
///
/// A function can be called via one of the call instructions.
/// A non-abstract function can have CFG IR implementing this function.
sealed class CFunction {
  /// Corresponding or enclosing AST member.
  ///
  /// Multiple distinct functions could have the same [member],
  /// e.g. both [GetterFunction] and [SetterFunction] can have
  /// the same [ast.Field] member.
  final ast.Member member;

  CFunction._(this.member);

  /// Whether this function has a receiver parameter.
  bool get hasReceiverParameter =>
      member.isInstanceMember || member is ast.Constructor;

  /// Whether this function has a closure parameter.
  bool get hasClosureParameter => false;

  /// Whether this function has class type parameters in scope.
  bool get hasClassTypeParameters =>
      (member.isInstanceMember || member is ast.Constructor) &&
      member.enclosingClass!.typeParameters.isNotEmpty;

  /// Whether this function has function type parameters.
  bool get hasFunctionTypeParameters =>
      member is ast.Procedure && member.function!.typeParameters.isNotEmpty;

  /// Total number of parameters including receiver, closure and optional parameters.
  int get numberOfParameters;

  /// Return type of this function.
  CType get returnType;

  /// Source position of the beginning of this function.
  SourcePosition get sourcePosition => SourcePosition(member.fileOffset);
}

/// Function representing a getter.
final class GetterFunction extends CFunction {
  GetterFunction._(super.member) : assert(member.hasGetter), super._();

  @override
  int get numberOfParameters => member.isInstanceMember ? 1 /* receiver */ : 0;

  @override
  late final CType returnType = CType.fromStaticType(member.getterType);

  @override
  String toString() => 'getter $member';
}

/// Function representing an implicit getter of a field.
final class ImplicitFieldGetter extends GetterFunction {
  ImplicitFieldGetter._(ast.Field super.member) : super._();
}

/// Function representing a setter.
final class SetterFunction extends CFunction {
  SetterFunction._(super.member) : assert(member.hasSetter), super._();

  @override
  int get numberOfParameters =>
      member.isInstanceMember ? 2 /* receiver, value */ : 1 /* only value */;

  @override
  CType get returnType => const TopType(const ast.VoidType());

  /// Type of the value parameter.
  late final CType valueType = CType.fromStaticType(member.setterType);

  @override
  String toString() => 'setter $member';
}

/// Function representing an implicit setter of a field.
final class ImplicitFieldSetter extends SetterFunction {
  ImplicitFieldSetter._(ast.Field super.member) : super._();
}

/// Function representing a field initializer.
final class FieldInitializerFunction extends CFunction {
  FieldInitializerFunction._(super.member)
    : assert(member is ast.Field && member.initializer != null),
      super._();

  @override
  int get numberOfParameters => member.isInstanceMember ? 1 /* receiver */ : 0;

  @override
  CType get returnType => CType.fromStaticType(member.getterType);

  @override
  String toString() => 'field-init $member';
}

/// Regular instance or static method, or a top-level function.
/// Also used for factory constructors.
final class RegularFunction extends CFunction {
  RegularFunction._(ast.Procedure super.member)
    : assert(!member.isGetter && !member.isSetter),
      super._();

  @override
  int get numberOfParameters =>
      (hasReceiverParameter ? 1 : 0) +
      member.function!.positionalParameters.length +
      member.function!.namedParameters.length;

  @override
  late final CType returnType = CType.fromStaticType(
    member.function!.returnType,
  );

  @override
  String toString() => member.toString();
}

/// Generative constructor.
final class GenerativeConstructor extends CFunction {
  GenerativeConstructor._(ast.Constructor super.member) : super._();

  @override
  int get numberOfParameters =>
      1 /* receiver */ +
      member.function!.positionalParameters.length +
      member.function!.namedParameters.length;

  @override
  CType get returnType => const TopType(const ast.VoidType());

  @override
  String toString() => member.toString();
}

/// Closure function.
sealed class ClosureFunction extends CFunction {
  ClosureFunction._(super.member) : super._();

  @override
  bool get hasReceiverParameter => false;

  @override
  bool get hasClosureParameter => true;
}

/// Anonymous closure or a local function.
final class LocalFunction extends ClosureFunction {
  final ast.LocalFunction localFunction;
  LocalFunction._(super.member, this.localFunction) : super._();

  @override
  String toString() => 'closure $localFunction at $member';

  @override
  bool get hasFunctionTypeParameters =>
      localFunction.function.typeParameters.isNotEmpty;

  @override
  int get numberOfParameters =>
      1 /* closure */ +
      localFunction.function.positionalParameters.length +
      localFunction.function.namedParameters.length;

  @override
  late final CType returnType = CType.fromStaticType(
    localFunction.function.returnType,
  );

  @override
  SourcePosition get sourcePosition => SourcePosition(localFunction.fileOffset);
}

/// Tear-off (result of function closurization).
final class TearOffFunction extends ClosureFunction {
  TearOffFunction._(super.member) : super._();

  @override
  String toString() => 'tear-off $member';

  @override
  bool get hasClassTypeParameters => false;

  @override
  bool get hasFunctionTypeParameters => member is ast.Constructor
      ? member.enclosingClass!.typeParameters.isNotEmpty
      : member.function!.typeParameters.isNotEmpty;

  @override
  int get numberOfParameters =>
      1 /* closure */ +
      member.function!.positionalParameters.length +
      member.function!.namedParameters.length;

  @override
  late final CType returnType = CType.fromStaticType(
    member is ast.Constructor
        ? ast.InterfaceType(
            member.enclosingClass!,
            ast.Nullability.nonNullable,
            member.enclosingClass!.typeParameters
                .map((tp) => tp.defaultType)
                .toList(),
          )
        : member.function!.returnType,
  );
}

class ArgumentsShape {
  final int types;
  final int positional;
  final List<String> named;

  const ArgumentsShape(this.types, this.positional, this.named);

  @override
  String toString() =>
      'Args[$positional${types > 0 ? ', types: $types' : ''}${named.isNotEmpty ? ', named: $named' : ''}]';

  @override
  bool operator ==(Object other) =>
      other is ArgumentsShape &&
      this.types == other.types &&
      this.positional == other.positional &&
      listEquals(this.named, other.named);

  @override
  int get hashCode => finalizeHash(
    combineHash(
      combineHash(types.hashCode, positional.hashCode),
      listHashCode(named),
    ),
  );
}

/// Mapping between AST nodes and functions.
///
/// Ensures that unique [CFunction] is used to represent
/// each function in the program.
class FunctionRegistry {
  final Map<ast.Member, CFunction> _getters = {};
  final Map<ast.Member, CFunction> _setters = {};
  final Map<ast.LocalFunction, CFunction> _closures = {};
  final Map<ast.Member, CFunction> _tearOffs = {};
  final Map<ast.Member, CFunction> _fieldInitializers = {};
  final Map<ast.Member, CFunction> _other = {};
  final List<ArgumentsShape> _positionalArgShapes = [];

  /// Returns [CFunction] corresponding to [member] with
  /// given properties.
  CFunction getFunction(
    ast.Member member, {
    bool isGetter = false,
    bool isSetter = false,
    bool isInitializer = false,
    bool isTearOff = false,
    ast.LocalFunction? localFunction,
  }) {
    if (localFunction != null) {
      assert(!isGetter && !isSetter && !isInitializer && !isTearOff);
      return _closures[localFunction] ??= LocalFunction._(
        member,
        localFunction,
      );
    }
    if (isTearOff) {
      assert(!isGetter && !isSetter && !isInitializer);
      assert(member is ast.Procedure || member is ast.Constructor);
      return _tearOffs[member] ??= TearOffFunction._(member);
    }
    if (isInitializer) {
      assert(!isGetter && !isSetter);
      return _fieldInitializers[member] ??= FieldInitializerFunction._(member);
    }
    if (isGetter) {
      assert(!isSetter);
      return _getters[member] ??= (member is ast.Field)
          ? ImplicitFieldGetter._(member)
          : GetterFunction._(member);
    }
    if (isSetter) {
      return _setters[member] ??= (member is ast.Field)
          ? ImplicitFieldSetter._(member)
          : SetterFunction._(member);
    }
    return _other[member] ??= switch (member) {
      ast.Constructor() => GenerativeConstructor._(member),
      ast.Procedure() => RegularFunction._(member),
      _ => throw 'Unexpected member ${member.runtimeType} $member',
    };
  }

  ArgumentsShape getArgumentsShape(
    int positional, {
    int types = 0,
    List<String> named = const [],
  }) {
    if (types == 0 && named.isEmpty) {
      for (int i = _positionalArgShapes.length, n = positional; i <= n; ++i) {
        _positionalArgShapes.add(ArgumentsShape(0, i, const <String>[]));
      }
      return _positionalArgShapes[positional];
    }
    return ArgumentsShape(types, positional, named);
  }
}
