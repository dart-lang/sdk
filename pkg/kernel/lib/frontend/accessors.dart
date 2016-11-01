// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help transform compounds and null-aware accessors into
/// let expressions.
library kernel.frontend.accessors;

import '../ast.dart';

abstract class Accessor {
  Expression buildSimpleRead() {
    return _finish(_makeSimpleRead());
  }

  /// Returns an assignment to the accessor.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _finish(_makeSimpleWrite(value, voidContext));
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    if (voidContext) {
      return _finish(new ConditionalExpression(buildIsNull(_makeRead()),
          _makeWrite(value, voidContext), new NullLiteral(), type));
    }
    var tmp = new VariableDeclaration.forValue(_makeRead());
    return _finish(makeLet(
        tmp,
        new ConditionalExpression(buildIsNull(new VariableGet(tmp)),
            _makeWrite(value, voidContext), new VariableGet(tmp), type)));
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return _finish(_makeWrite(
        makeBinary(_makeRead(), binaryOperator, interfaceTarget, value),
        voidContext));
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return buildCompoundAssignment(binaryOperator, new IntLiteral(1),
        voidContext: voidContext, interfaceTarget: interfaceTarget);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    if (voidContext) {
      return buildPrefixIncrement(binaryOperator,
          voidContext: true, interfaceTarget: interfaceTarget);
    }
    var value = new VariableDeclaration.forValue(_makeRead());
    valueAccess() => new VariableGet(value);
    var dummy = new VariableDeclaration.forValue(_makeWrite(
        makeBinary(
            valueAccess(), binaryOperator, interfaceTarget, new IntLiteral(1)),
        true));
    return _finish(makeLet(value, makeLet(dummy, valueAccess())));
  }

  Expression _makeSimpleRead() => _makeRead();

  Expression _makeSimpleWrite(Expression value, bool voidContext) {
    return _makeWrite(value, voidContext);
  }

  Expression _makeRead();

  Expression _makeWrite(Expression value, bool voidContext);

  Expression _finish(Expression body) => body;

  makeInvalidRead() => new InvalidExpression();

  makeInvalidWrite(Expression value) => wrapInvalid(value);
}

class VariableAccessor extends Accessor {
  VariableDeclaration variable;
  DartType promotedType;

  VariableAccessor(this.variable, [this.promotedType]);

  _makeRead() => new VariableGet(variable, promotedType);

  _makeWrite(Expression value, bool voidContext) {
    return variable.isFinal || variable.isConst
        ? makeInvalidWrite(value)
        : new VariableSet(variable, value);
  }
}

class PropertyAccessor extends Accessor {
  VariableDeclaration _receiverVariable;
  Expression receiver;
  Name name;
  Member getter, setter;

  static Accessor make(
      Expression receiver, Name name, Member getter, Member setter) {
    if (receiver is ThisExpression) {
      return new ThisPropertyAccessor(name, getter, setter);
    } else {
      return new PropertyAccessor._internal(receiver, name, getter, setter);
    }
  }

  PropertyAccessor._internal(
      this.receiver, this.name, this.getter, this.setter);

  _makeSimpleRead() => new PropertyGet(receiver, name, getter);
  _makeSimpleWrite(Expression value, bool voidContext) {
    return new PropertySet(receiver, name, value, setter);
  }

  receiverAccess() {
    _receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(_receiverVariable);
  }

  _makeRead() => new PropertyGet(receiverAccess(), name, getter);

  _makeWrite(Expression value, bool voidContext) {
    return new PropertySet(receiverAccess(), name, value, setter);
  }

  _finish(Expression body) => makeLet(_receiverVariable, body);
}

/// Special case of [PropertyAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisPropertyAccessor extends Accessor {
  Name name;
  Member getter, setter;

  ThisPropertyAccessor(this.name, this.getter, this.setter);

  _makeRead() => new PropertyGet(new ThisExpression(), name, getter);

  _makeWrite(Expression value, bool voidContext) {
    return new PropertySet(new ThisExpression(), name, value, setter);
  }
}

class NullAwarePropertyAccessor extends Accessor {
  VariableDeclaration receiver;
  Name name;
  Member getter, setter;
  DartType type;

  NullAwarePropertyAccessor(
      Expression receiver, this.name, this.getter, this.setter, this.type)
      : this.receiver = makeOrReuseVariable(receiver);

  receiverAccess() => new VariableGet(receiver);

  _makeRead() => new PropertyGet(receiverAccess(), name, getter);

  _makeWrite(Expression value, bool voidContext) {
    return new PropertySet(receiverAccess(), name, value, setter);
  }

  _finish(Expression body) => makeLet(
      receiver,
      new ConditionalExpression(
          buildIsNull(receiverAccess()), new NullLiteral(), body, type));
}

class SuperPropertyAccessor extends Accessor {
  Name name;
  Member getter, setter;

  SuperPropertyAccessor(this.name, this.getter, this.setter);

  _makeRead() => new SuperPropertyGet(name, getter);

  _makeWrite(Expression value, bool voidContext) {
    return new SuperPropertySet(name, value, setter);
  }
}

final Name _indexGet = new Name('[]');
final Name _indexSet = new Name('[]=');

class IndexAccessor extends Accessor {
  Expression receiver;
  Expression index;
  VariableDeclaration receiverVariable;
  VariableDeclaration indexVariable;
  Procedure getter, setter;

  static Accessor make(Expression receiver, Expression index, Procedure getter,
      Procedure setter) {
    if (receiver is ThisExpression) {
      return new ThisIndexAccessor(index, getter, setter);
    } else {
      return new IndexAccessor._internal(receiver, index, getter, setter);
    }
  }

  IndexAccessor._internal(this.receiver, this.index, this.getter, this.setter);

  _makeSimpleRead() => new MethodInvocation(
      receiver, _indexGet, new Arguments(<Expression>[index]), getter);

  _makeSimpleWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new MethodInvocation(
        receiver, _indexSet, new Arguments(<Expression>[index, value]), setter);
  }

  receiverAccess() {
    // We cannot reuse the receiver if it is a variable since it might be
    // reassigned in the index expression.
    receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(receiverVariable);
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  _makeRead() {
    return new MethodInvocation(receiverAccess(), _indexGet,
        new Arguments(<Expression>[indexAccess()]), getter);
  }

  _makeWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new MethodInvocation(receiverAccess(), _indexSet,
        new Arguments(<Expression>[indexAccess(), value]), setter);
  }

  _makeWriteAndReturn(Expression value) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(new MethodInvocation(
        receiverAccess(),
        _indexSet,
        new Arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(Expression body) {
    return makeLet(receiverVariable, makeLet(indexVariable, body));
  }
}

/// Special case of [IndexAccessor] to avoid creating an indirect access to
/// 'this'.
class ThisIndexAccessor extends Accessor {
  Expression index;
  VariableDeclaration indexVariable;
  Procedure getter, setter;

  ThisIndexAccessor(this.index, this.getter, this.setter);

  _makeSimpleRead() {
    return new MethodInvocation(new ThisExpression(), _indexGet,
        new Arguments(<Expression>[index]), getter);
  }

  _makeSimpleWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new MethodInvocation(new ThisExpression(), _indexSet,
        new Arguments(<Expression>[index, value]), setter);
  }

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  _makeRead() => new MethodInvocation(new ThisExpression(), _indexGet,
      new Arguments(<Expression>[indexAccess()]), getter);

  _makeWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new MethodInvocation(new ThisExpression(), _indexSet,
        new Arguments(<Expression>[indexAccess(), value]), setter);
  }

  _makeWriteAndReturn(Expression value) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(new MethodInvocation(
        new ThisExpression(),
        _indexSet,
        new Arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(Expression body) => makeLet(indexVariable, body);
}

class SuperIndexAccessor extends Accessor {
  Expression index;
  VariableDeclaration indexVariable;
  Member getter, setter;

  SuperIndexAccessor(this.index, this.getter, this.setter);

  indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  _makeSimpleRead() => new SuperMethodInvocation(
      _indexGet, new Arguments(<Expression>[index]), getter);

  _makeSimpleWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new SuperMethodInvocation(
        _indexSet, new Arguments(<Expression>[index, value]), setter);
  }

  _makeRead() {
    return new SuperMethodInvocation(
        _indexGet, new Arguments(<Expression>[indexAccess()]), getter);
  }

  _makeWrite(Expression value, bool voidContext) {
    if (!voidContext) return _makeWriteAndReturn(value);
    return new SuperMethodInvocation(
        _indexSet, new Arguments(<Expression>[indexAccess(), value]), setter);
  }

  _makeWriteAndReturn(Expression value) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var dummy = new VariableDeclaration.forValue(new SuperMethodInvocation(
        _indexSet,
        new Arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)]),
        setter));
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  Expression _finish(Expression body) {
    return makeLet(indexVariable, body);
  }
}

class StaticAccessor extends Accessor {
  Member readTarget;
  Member writeTarget;

  StaticAccessor(this.readTarget, this.writeTarget);

  _makeRead() =>
      readTarget == null ? makeInvalidRead() : new StaticGet(readTarget);

  _makeWrite(Expression value, bool voidContext) {
    return writeTarget == null
        ? makeInvalidWrite(value)
        : new StaticSet(writeTarget, value);
  }
}

class ReadOnlyAccessor extends Accessor {
  Expression expression;
  VariableDeclaration value;

  ReadOnlyAccessor(this.expression);

  _makeSimpleRead() => expression;

  _makeRead() {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  _makeWrite(Expression value, bool voidContext) => makeInvalidWrite(value);

  Expression _finish(Expression body) => makeLet(value, body);
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary(Expression left, Name operator, Procedure interfaceTarget,
    Expression right) {
  return new MethodInvocation(
      left, operator, new Arguments(<Expression>[right]), interfaceTarget);
}

final Name _equalOperator = new Name('==');

Expression buildIsNull(Expression value) {
  return makeBinary(value, _equalOperator, null, new NullLiteral());
}

VariableDeclaration makeOrReuseVariable(Expression value) {
  // TODO: Devise a way to remember if a variable declaration was reused
  // or is fresh (hence needs a let binding).
  return new VariableDeclaration.forValue(value);
}

Expression wrapInvalid(Expression e) {
  return new Let(new VariableDeclaration.forValue(e), new InvalidExpression());
}
