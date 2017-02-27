// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder_accessors;

export 'frontend_accessors.dart' show
    wrapInvalid;

import 'frontend_accessors.dart' show
    Accessor;

import 'package:kernel/ast.dart';

import 'package:kernel/core_types.dart' show
    CoreTypes;

import '../errors.dart' show
    internalError,
    printUnexpected;

import 'frontend_accessors.dart' as kernel show
    IndexAccessor,
    NullAwarePropertyAccessor,
    PropertyAccessor,
    StaticAccessor,
    SuperIndexAccessor,
    SuperPropertyAccessor,
    ThisIndexAccessor,
    ThisPropertyAccessor,
    VariableAccessor;

import 'frontend_accessors.dart' show
    buildIsNull,
    makeLet;

import 'kernel_builder.dart' show
    Builder,
    KernelClassBuilder,
    PrefixBuilder,
    TypeDeclarationBuilder;

abstract class BuilderHelper {
  Uri get uri;

  CoreTypes get coreTypes;

  Constructor lookupConstructor(Name name, {bool isSuper});

  Expression toSuperMethodInvocation(MethodInvocation node);

  Expression toValue(node);

  Member lookupSuperMember(Name name, {bool isSetter: false});

  builderToFirstExpression(Builder builder, String name, int charOffset);

  finishSend(Object receiver, Arguments arguments, int charOffset);

  Expression buildCompileTimeError(error, [int charOffset]);

  Initializer buildCompileTimeErrorIntializer(error, [int charOffset]);

  Expression buildStaticInvocation(Procedure target, Arguments arguments);

  Expression buildProblemExpression(Builder builder, String name);
}

abstract class BuilderAccessor implements Accessor {
  BuilderHelper get helper;

  int get charOffset;

  String get plainNameForRead;

  Uri get uri => helper.uri;

  CoreTypes get coreTypes => helper.coreTypes;

  String get plainNameForWrite => plainNameForRead;

  Expression buildForEffect() => buildSimpleRead();

  Initializer buildFieldInitializer(
      Map<String, FieldInitializer> initializers) {
    // TODO(ahe): This error message is really bad.
    return helper.buildCompileTimeErrorIntializer(
        "Can't use $plainNameForRead here.", charOffset);
  }

  Expression makeInvalidRead() {
    return throwNoSuchMethodError(plainNameForRead, new Arguments.empty(), uri,
        charOffset, coreTypes, isGetter: true);
  }

  Expression makeInvalidWrite(Expression value) {
    return throwNoSuchMethodError(plainNameForWrite,
        new Arguments(<Expression>[value]), uri, charOffset, coreTypes,
        isSetter: true);
  }

  TreeNode doInvocation(int charOffset, Arguments arguments);

  buildPropertyAccess(IncompleteSend send, bool isNullAware) {
    if (send is SendAccessor) {
      return buildMethodInvocation(buildSimpleRead(), send.name, send.arguments,
          charOffset, isNullAware: isNullAware);
    } else {
      return PropertyAccessor.make(helper, charOffset, buildSimpleRead(),
          send.name, null, null, isNullAware);
    }
  }

  Expression buildThrowNoSuchMethodError(Arguments arguments) {
    bool isGetter = false;
    if (arguments == null) {
      arguments = new Arguments.empty();
      isGetter = true;
    }
    return throwNoSuchMethodError(plainNameForWrite, arguments, uri, charOffset,
        coreTypes, isGetter: isGetter);
  }

  bool get isThisPropertyAccessor => false;
}

abstract class CompileTimeErrorAccessor implements Accessor {
  Expression buildError();

  Name get name => internalError("Unsupported operation.");

  String get plainNameForRead => name.name;

  withReceiver(Object receiver, {bool isNullAware}) => this;

  Initializer buildFieldInitializer(
      Map<String, FieldInitializer> initializers) {
    return new LocalInitializer(new VariableDeclaration.forValue(buildError()));
  }

  doInvocation(int charOffset, Arguments arguments) => this;

  buildPropertyAccess(IncompleteSend send, bool isNullAware) => this;

  buildThrowNoSuchMethodError(Arguments arguments) => this;

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildError();
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return buildError();
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return buildError();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return buildError();
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return buildError();
  }

  Expression buildSimpleRead() => buildError();

  Expression makeInvalidRead() => buildError();

  Expression makeInvalidWrite(Expression value) => buildError();
}

class ThisAccessor extends BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  final bool isInitializer;

  final bool isSuper;

  ThisAccessor(this.helper, this.charOffset, this.isInitializer,
      {this.isSuper: false});

  String get plainNameForRead => internalError(isSuper ? "super" : "this");

  Expression buildSimpleRead() {
    if (!isSuper) {
      return new ThisExpression();
    } else {
      return helper.buildCompileTimeError(
          "Can't use `super` as an expression.", charOffset);
    }
  }

  Initializer buildFieldInitializer(
      Map<String, FieldInitializer> initializers) {
    String keyword = isSuper ? "super" : "this";
    return helper.buildCompileTimeErrorIntializer(
        "Can't use '$keyword' here, did you mean '$keyword()'?", charOffset);
  }

  buildPropertyAccess(IncompleteSend send, bool isNullAware) {
    if (isInitializer && send is SendAccessor) {
      return buildConstructorInitializer(
          send.charOffset, send.name, send.arguments);
    }
    if (send is SendAccessor) {
      // Notice that 'this' or 'super' can't be null. So we can ignore the
      // value of [isNullAware].
      MethodInvocation result = buildMethodInvocation(new ThisExpression(),
          send.name, send.arguments, charOffset);
      return isSuper ? helper.toSuperMethodInvocation(result) : result;
    } else {
      if (isSuper) {
        Member getter = helper.lookupSuperMember(send.name);
        Member setter = helper.lookupSuperMember(send.name, isSetter: true);
        return new SuperPropertyAccessor(helper, charOffset, send.name, getter,
            setter);
      } else {
        return new ThisPropertyAccessor(helper, charOffset, send.name, null,
            null);
      }
    }
  }

  doInvocation(int charOffset, Arguments arguments) {
    if (isInitializer) {
      return buildConstructorInitializer(charOffset, new Name(""), arguments);
    } else {
      return buildMethodInvocation(new ThisExpression(), new Name("call"),
          arguments, charOffset);
    }
  }

  Initializer buildConstructorInitializer(int charOffset, Name name,
      Arguments arguments) {
    Constructor constructor = helper.lookupConstructor(name, isSuper: isSuper);
    Initializer result;
    if (constructor == null) {
      result = new LocalInitializer(
          new VariableDeclaration.forValue(
              throwNoSuchMethodError(
                  name.name, arguments, uri, charOffset, coreTypes,
                  isSuper: isSuper)));
    } else if (isSuper) {
      result = new SuperInitializer(constructor, arguments);
    } else {
      result = new RedirectingInitializer(constructor, arguments);
    }
    return result
        ..fileOffset = charOffset;
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return internalError("");
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return internalError("");
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("");
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("");
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("");
  }

  toString() => "ThisAccessor($charOffset${isSuper ? ', super' : ''})";
}

abstract class IncompleteSend extends BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  final Name name;

  IncompleteSend(this.helper, this.charOffset, this.name);

  withReceiver(Object receiver, {bool isNullAware});
}

class IncompleteError extends IncompleteSend with CompileTimeErrorAccessor {
  final Object error;

  IncompleteError(BuilderHelper helper, int charOffset, this.error)
      : super(helper, charOffset, null);

  Expression buildError() {
    return helper.buildCompileTimeError(error, charOffset);
  }
}

class SendAccessor extends IncompleteSend {
  final Arguments arguments;

  SendAccessor(BuilderHelper helper, int charOffset, Name name, this.arguments)
      : super(helper, charOffset, name) {
    assert(arguments != null);
  }

  String get plainNameForRead => name.name;

  Expression buildSimpleRead() {
    return internalError("Unhandled");
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  withReceiver(Object receiver, {bool isNullAware: false}) {
    if (receiver is TypeDeclarationBuilder) {
      /// `SomeType?.toString` is the same as `SomeType.toString`, not
      /// `(SomeType).toString`.
      isNullAware = false;
    }
    if (receiver is BuilderAccessor) {
      return receiver.buildPropertyAccess(this, isNullAware);
    }
    if (receiver is PrefixBuilder) {
      PrefixBuilder prefix = receiver;
      receiver = helper.builderToFirstExpression(
          prefix.exports[name.name], "${prefix.name}.${name.name}", charOffset);
      return helper.finishSend(receiver, arguments, charOffset);
    }
    Expression result;
    if (receiver is KernelClassBuilder) {
      Builder builder = receiver.findStaticBuilder(name.name, charOffset, uri);
      if (builder == null) {
        return buildThrowNoSuchMethodError(arguments);
      }
      if (builder.hasProblem) {
        result = helper.buildProblemExpression(builder, name.name);
      } else {
        Member target = builder.target;
        if (target != null) {
          if (target is Field) {
            result = buildMethodInvocation(new StaticGet(target),
                new Name("call"), arguments, charOffset,
                isNullAware: isNullAware);
          } else {
            result = helper.buildStaticInvocation(target, arguments);
          }
        } else {
          result = buildThrowNoSuchMethodError(arguments);
        }
      }
    } else {
      result = buildMethodInvocation(helper.toValue(receiver), name,
          arguments, charOffset, isNullAware: isNullAware);
    }
    return result..fileOffset = charOffset;
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return internalError("");
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("");
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression doInvocation(int charOffset, Arguments arguments) {
    return internalError("Unhandled");
  }

  toString() => "SendAccessor($charOffset, $name, $arguments)";
}

class IncompletePropertyAccessor extends IncompleteSend {
  IncompletePropertyAccessor(BuilderHelper helper, int charOffset, Name name)
      : super(helper, charOffset, name);

  String get plainNameForRead => name.name;

  Expression buildSimpleRead() => internalError("Unhandled");

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  withReceiver(Object receiver, {bool isNullAware: false}) {
    if (receiver is TypeDeclarationBuilder) {
      /// For reasons beyond comprehension, `SomeType?.toString` is the same as
      /// `SomeType.toString`, not `(SomeType).toString`. WTAF!?!
      //
      isNullAware = false;
    }
    if (receiver is BuilderAccessor) {
      return receiver.buildPropertyAccess(this, isNullAware);
    }
    if (receiver is PrefixBuilder) {
      PrefixBuilder prefix = receiver;
      return helper.builderToFirstExpression(
          prefix.exports[name.name], name.name, charOffset);
    }
    if (receiver is KernelClassBuilder) {
      Builder builder = receiver.findStaticBuilder(name.name, charOffset, uri);
      Member getter = builder?.target;
      Member setter;
      if (builder == null) {
        builder = receiver.findStaticBuilder(
            name.name, charOffset, uri, isSetter: true);
        if (builder == null) {
          return buildThrowNoSuchMethodError(null);
        }
      }
      if (builder.hasProblem) {
        return helper.buildProblemExpression(builder, name.name)
            ..fileOffset = charOffset;
      }
      if (getter is Field) {
        if (!getter.isFinal && !getter.isConst) {
          setter = getter;
        }
      } else if (getter is Procedure) {
        if (getter.isGetter) {
          builder = receiver.findStaticBuilder(
              name.name, charOffset, uri, isSetter: true);
          if (builder != null && !builder.hasProblem) {
            setter = builder.target;
          }
        }
      }
      if (getter == null) {
        return internalError("no getter for $name");
      }
      return new StaticAccessor(helper, charOffset, getter, setter);
    }
    return PropertyAccessor.make(helper, charOffset, helper.toValue(receiver),
        name, null, null, isNullAware);
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return internalError("Unhandled");
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("Unhandled");
  }

  Expression doInvocation(int charOffset, Arguments arguments) {
    return internalError("Unhandled");
  }

  toString() => "IncompletePropertyAccessor($charOffset, $name)";
}

class IndexAccessor extends kernel.IndexAccessor with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  IndexAccessor.internal(this.helper, this.charOffset, Expression receiver,
      Expression index, Procedure getter, Procedure setter)
      : super.internal(receiver, index, getter, setter);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int charOffset, Arguments arguments) {
    return buildMethodInvocation(buildSimpleRead(), new Name("call"), arguments,
        charOffset);
  }

  toString() => "IndexAccessor()";

  static BuilderAccessor make(BuilderHelper helper, int charOffset,
      Expression receiver, Expression index, Procedure getter,
      Procedure setter) {
    if (receiver is ThisExpression) {
      return new ThisIndexAccessor(helper, charOffset, index, getter, setter);
    } else {
      return new IndexAccessor.internal(helper, charOffset, receiver, index,
          getter, setter);
    }
  }
}

class PropertyAccessor extends kernel.PropertyAccessor with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  PropertyAccessor.internal(this.helper, this.charOffset, Expression receiver,
      Name name, Member getter, Member setter)
      : super.internal(receiver, name, getter, setter);

  String get plainNameForRead => name.name;

  bool get isThisPropertyAccessor => receiver is ThisExpression;

  Expression doInvocation(int charOffset, Arguments arguments) {
    return buildMethodInvocation(receiver, name, arguments, charOffset);
  }

  toString() => "PropertyAccessor()";

  static BuilderAccessor make(BuilderHelper helper, int charOffset,
      Expression receiver, Name name, Member getter, Member setter,
      bool isNullAware) {
    if (receiver is ThisExpression) {
      return new ThisPropertyAccessor(helper, charOffset, name, getter, setter);
    } else {
      return isNullAware
          ? new NullAwarePropertyAccessor(helper, charOffset, receiver, name,
              getter, setter, null)
          : new PropertyAccessor.internal(helper, charOffset, receiver, name,
              getter, setter);
    }
  }
}

class StaticAccessor extends kernel.StaticAccessor with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  StaticAccessor(this.helper, this.charOffset, Member readTarget,
      Member writeTarget)
      : super(readTarget, writeTarget) {
    assert(readTarget != null || writeTarget != null);
  }

  String get plainNameForRead => (readTarget ?? writeTarget).name.name;

  Expression doInvocation(int charOffset, Arguments arguments) {
    if (readTarget == null || isFieldOrGetter(readTarget)) {
      return buildMethodInvocation(buildSimpleRead(), new Name("call"),
          arguments, charOffset);
    } else {
      return helper.buildStaticInvocation(readTarget, arguments)
          ..fileOffset = charOffset;
    }
  }

  toString() => "StaticAccessor()";
}

class SuperPropertyAccessor extends kernel.SuperPropertyAccessor
    with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  SuperPropertyAccessor(this.helper, this.charOffset, Name name, Member getter,
      Member setter)
      : super(name, getter, setter);

  String get plainNameForRead => name.name;

  Expression doInvocation(int charOffset, Arguments arguments) {
    if (getter == null || isFieldOrGetter(getter)) {
      return buildMethodInvocation(buildSimpleRead(), new Name("call"),
          arguments, charOffset);
    } else {
      return new DirectMethodInvocation(new ThisExpression(), getter, arguments)
          ..fileOffset = charOffset;
    }
  }

  toString() => "SuperPropertyAccessor()";
}

class ThisIndexAccessor extends kernel.ThisIndexAccessor with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  ThisIndexAccessor(this.helper, this.charOffset, Expression index,
      Procedure getter, Procedure setter)
      : super(index, getter, setter);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int charOffset, Arguments arguments) {
    return buildMethodInvocation(buildSimpleRead(), new Name("call"), arguments,
        charOffset);
  }

  toString() => "ThisIndexAccessor()";
}

class SuperIndexAccessor
    extends kernel.SuperIndexAccessor with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  SuperIndexAccessor(this.helper, this.charOffset, Expression index,
      Member getter, Member setter)
      : super(index, getter, setter);

  String get plainNameForRead => "[]";

  String get plainNameForWrite => "[]=";

  Expression doInvocation(int charOffset, Arguments arguments) {
    return buildMethodInvocation(buildSimpleRead(), new Name("call"), arguments,
        charOffset);
  }

  toString() => "SuperIndexAccessor()";
}

class ThisPropertyAccessor extends kernel.ThisPropertyAccessor
    with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  ThisPropertyAccessor(this.helper, this.charOffset, Name name, Member getter,
      Member setter)
      : super(name, getter, setter);

  String get plainNameForRead => name.name;

  bool get isThisPropertyAccessor => true;

  Expression doInvocation(int charOffset, Arguments arguments) {
    Member interfaceTarget = getter;
    if (interfaceTarget is Field) {
      // TODO(ahe): In strong mode we should probably rewrite this to
      // `this.name.call(arguments)`.
      interfaceTarget = null;
    }
    return buildMethodInvocation(new ThisExpression(), name, arguments,
        charOffset);
  }

  toString() => "ThisPropertyAccessor()";
}

class NullAwarePropertyAccessor extends kernel.NullAwarePropertyAccessor
    with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  NullAwarePropertyAccessor(this.helper, this.charOffset, Expression receiver,
      Name name, Member getter, Member setter, DartType type)
      : super(receiver, name, getter, setter, type);

  String get plainNameForRead => name.name;

  Expression doInvocation(int charOffset, Arguments arguments) {
    return internalError("Not implemented yet.");
  }

  toString() => "NullAwarePropertyAccessor()";
}


class VariableAccessor extends kernel.VariableAccessor
    with BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  VariableAccessor(this.helper, this.charOffset, VariableDeclaration variable,
      [DartType promotedType])
      : super.internal(variable, promotedType);

  String get plainNameForRead => variable.name;

  Expression doInvocation(int charOffset, Arguments arguments) {
    return buildMethodInvocation(buildSimpleRead(), new Name("call"), arguments,
        charOffset);
  }

  toString() => "VariableAccessor()";
}

Expression throwNoSuchMethodError(String name, Arguments arguments, Uri uri,
    int charOffset, CoreTypes coreTypes,
    {bool isSuper: false, isGetter: false, isSetter: false}) {
  printUnexpected(uri, charOffset, "Method not found: '$name'.");
  Constructor constructor = coreTypes.getClass(
      "dart:core", "NoSuchMethodError").constructors.first;
  return new Throw(new ConstructorInvocation(
      constructor,
      new Arguments(<Expression>[
          new NullLiteral(),
          new SymbolLiteral(name),
          new ListLiteral(arguments.positional),
          new MapLiteral(arguments.named.map((arg) {
              return new MapEntry(new SymbolLiteral(arg.name), arg.value);
          }).toList()),
          new NullLiteral()])));
}

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}

Expression buildMethodInvocation(Expression receiver, Name name,
    Arguments arguments, int charOffset, {bool isNullAware: false}) {
  if (isNullAware) {
    VariableDeclaration variable = new VariableDeclaration.forValue(receiver);
    return makeLet(
        variable,
        new ConditionalExpression(
            buildIsNull(new VariableGet(variable)),
            new NullLiteral(),
            new MethodInvocation(new VariableGet(variable), name, arguments)
                ..fileOffset = charOffset,
            const DynamicType()));
  } else {
    return new MethodInvocation(receiver, name, arguments)
        ..fileOffset = charOffset;
  }
}
