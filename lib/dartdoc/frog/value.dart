// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


interface CallingContext {
  MemberSet findMembers(String name);
  CounterLog get counters();
  Library get library();
  bool get isStatic();
  MethodMember get method();

  bool get needsCode();
  bool get showWarnings();

  // Hopefully remove the 5 members below that are only used for code gen.
  String _makeThisCode();

  Value getTemp(Value value);
  VariableValue forceTemp(Value value);
  Value assignTemp(Value tmp, Value v);
  void freeTemp(VariableValue value);
}

// TODO(jimhug): Value needs better separation into three parts:
//  1. Static analysis
//  2. Type inferred abstract interpretation analysis
//  3. Actual code generation
/**
 * This subtype of value is the one and only version used for static
 * analysis.  It has no code and its type is always the static type.
 */
class PureStaticValue extends Value {
  bool isConst;
  bool isType;

  // TODO(jimhug): Can we remove span?
  PureStaticValue(Type type, SourceSpan span,
    [this.isConst = false, this.isType = false]):
    super(type, null, span);

  Member getMem(CallingContext context, String name, Node node) {
    var member = type.getMember(name);

    if (member == null) {
      world.warning('cannot find "$name" on "${type.name}"', node.span);
      return null;
    }

    if (isType && !member.isStatic) {
      world.error('cannot refer to instance member as static', node.span);
    }

    return member;
  }

  Value get_(CallingContext context, String name, Node node) {
    if (type.isVar) return new PureStaticValue(world.varType, node.span);
    var member = getMem(context, name, node);
    if (member == null) return new PureStaticValue(world.varType, node.span);

    return member._get(context, node, this);
  }

  Value set_(CallingContext context, String name, Node node, Value value,
      [int kind=0, int returnKind=ReturnKind.IGNORE]) {
    if (type.isVar) return new PureStaticValue(world.varType, node.span);

    var member = getMem(context, name, node);
    if (member != null) {
      member._set(context, node, this, value);
    }
    return new PureStaticValue(value.type, node.span);
  }

  Value setIndex(CallingContext context, Value index, Node node, Value value,
      [int kind=0, int returnKind=ReturnKind.IGNORE]) {
    var tmp = invoke(context, ':setindex', node,
      new Arguments(null, [index, value]));
    return new PureStaticValue(value.type, node.span);
  }

  Value unop(int kind, CallingContext context, var node) {
    switch (kind) {
      case TokenKind.NOT:
        // TODO(jimhug): Issue #359 seeks to clarify this behavior.
        // ?var newVal = convertTo(context, world.nonNullBool);
        return new PureStaticValue(world.boolType, node.span);
      case TokenKind.ADD:
        if (!isConst && !type.isNum) {
          world.error('no unary add operator in dart', node.span);
        }
        return new PureStaticValue(world.numType, node.span);
      case TokenKind.SUB:
        return invoke(context, ':negate', node, Arguments.EMPTY);
      case TokenKind.BIT_NOT:
        return invoke(context, ':bit_not', node, Arguments.EMPTY);
    }
    world.internalError('unimplemented: ${node.op}', node.span);
  }

  Value binop(int kind, Value other, CallingContext context, var node) {
    var isConst = isConst && other.isConst;


    switch (kind) {
      case TokenKind.AND:
      case TokenKind.OR:
        return new PureStaticValue(world.boolType, node.span, isConst);
      case TokenKind.EQ_STRICT:
        return new PureStaticValue(world.boolType, node.span, isConst);
      case TokenKind.NE_STRICT:
        return new PureStaticValue(world.boolType, node.span, isConst);
    }

    var name = kind == TokenKind.NE ? ':ne': TokenKind.binaryMethodName(kind);
    var ret = invoke(context, name, node, new Arguments(null, [other]));
    if (isConst) {
      ret = new PureStaticValue(ret.type, node.span, isConst);
    }
    return ret;
  }


  Value invoke(CallingContext context, String name, Node node,
      Arguments args) {
    if (type.isVar) return new PureStaticValue(world.varType, node.span);
    if (type.isFunction && name == ':call') {
      return new PureStaticValue(world.varType, node.span);
    }

    var member = getMem(context, name, node);
    if (member == null) return new PureStaticValue(world.varType, node.span);

    return member.invoke(context, node, this, args);
  }

  Value invokeNoSuchMethod(CallingContext context, String name, Node node,
      [Arguments args]) {
    if (isType) {
      world.error('member lookup failed for "$name"', node.span);
    }

    var member = getMem(context, 'noSuchMethod', node);
    if (member == null) return new PureStaticValue(world.varType, node.span);

    final noSuchArgs = new Arguments(null, [
        new PureStaticValue(world.stringType, node.span),
        new PureStaticValue(world.listType, node.span)]);

    return member.invoke(context, node, this, noSuchArgs);
  }

  // These are implementation details of convertTo. (Eventually we might find it
  // easier to just implement convertTo itself).

  Value _typeAssert(CallingContext context, Type toType) {
    return _changeStaticType(toType);
  }

  Value _changeStaticType(Type toType) {
    if (toType === type) return this;
    return new PureStaticValue(toType, span, isConst, isType);
  }
}


/**
 * Represents a meta-value for code generation.
 */
class Value {
  /** The inferred (i.e. most precise) [Type] of the [Value]. */
  final Type type;

  /** The javascript code to generate this value. */
  final String code;

  /** The source location that created this value for error messages. */
  final SourceSpan span;

  Value(this.type, this.code, this.span) {
    if (type == null) world.internalError('type passed as null', span);
  }


  /** Is this a pretend first-class type? */
  bool get isType() => false;

  /** Is this a reference to super? */
  bool get isSuper() => false;

  /** Is this value a constant expression? */
  bool get isConst() => false;

  /** Is this a final variable? */
  bool get isFinal() => false;

  /** If we reference this value multiple times, do we need a temp? */
  bool get needsTemp() => true;

  /**
   * The statically declared [Type] of the [Value]. This type determines which
   * kind of static type warnings are issued. It's also the type that is used
   * for generating type assertions (i.e. given `Foo x; ...; x = expr;`,
   * expr will be checked against "Foo" regardless of the inferred type of `x`).
   */
  Type get staticType() => type;

  /** If [isConst], the [EvaluatedValue] that defines this value. */
  EvaluatedValue get constValue() => null;

  static Value comma(Value x, Value y) {
    return new Value(y.type, '(${x.code}, ${y.code})', null);
  }

  // TODO(jmesserly): more work is needed to make unifying all kinds of Values
  // work properly.
  static Value union(Value x, Value y) {
    if (y === null || x == y) return x;
    if (x === null) return y;

    var ret = x._tryUnion(y);
    if (ret != null) return ret;

    // TODO(jmesserly): might want to call a _tryUnionReversed here.
    ret = y._tryUnion(x);
    if (ret != null) return ret;

    // TODO(jmesserly): should use something like UnionValue and track the
    // precise set of types. For now we find the Type.union.

    // TODO(jmesserly): What to do about code? Right now, we're intentionally
    // throwing it away because they aren't used in the current flow-insensitive
    // inference.
    return new Value(Type.union(x.type, y.type), null, null);
  }

  Value _tryUnion(Value right) => null;

  // TODO(jimhug): remove once type system works better.
  setField(Member field, Value value, [bool duringInit = false]) { }

  // Nothing to do in general?
  validateInitialized(SourceSpan span) { }

  // TODO(jimhug): Fix these names once get/set are truly pseudo-keywords.
  //   See issue #379.
  Value get_(CallingContext context, String name, Node node) {
    final member = _resolveMember(context, name, node);
    if (member != null) {
      return member._get(context, node, this);
    } else {
      return invokeNoSuchMethod(context, 'get:$name', node);
    }
  }

  Value set_(CallingContext context, String name, Node node, Value value,
      [int kind=0, int returnKind=ReturnKind.IGNORE]) {
    final member = _resolveMember(context, name, node);
    if (member != null) {
      var thisValue = this;
      var thisTmp = null;
      var retTmp = null;
      if (kind != 0) {
        // TODO(jimhug): Very special number optimizations will go here...
        thisTmp = context.getTemp(thisValue);
        thisValue = context.assignTemp(thisTmp, thisValue);
        var lhs = member._get(context, node, thisTmp);
        if (returnKind == ReturnKind.PRE) {
          retTmp = context.forceTemp(lhs);
          lhs = context.assignTemp(retTmp, lhs);
        }
        value = lhs.binop(kind, value, context, node);
      }

      if (returnKind == ReturnKind.POST) {
        // TODO(jimhug): Optimize this away when native JS is detected.
        retTmp = context.forceTemp(value);
        value = context.assignTemp(retTmp, value);
      }

      var ret = member._set(context, node, thisValue, value);
      if (thisTmp != null && thisTmp != this) context.freeTemp(thisTmp);
      if (retTmp != null) {
        context.freeTemp(retTmp);
        return Value.comma(ret, retTmp);
      } else {
        return ret;
      }
    } else {
      // TODO(jimhug): Need to support += and noSuchMethod better.
      return invokeNoSuchMethod(context, 'set:$name', node,
          new Arguments(null, [value]));
    }
  }

  // TODO(jimhug): This method body has too much in common with set_ above.
  Value setIndex(CallingContext context, Value index, Node node, Value value,
      [int kind=0, int returnKind=ReturnKind.IGNORE]) {
    final member = _resolveMember(context, ':setindex', node);
    if (member != null) {
      var thisValue = this;
      var indexValue = index;
      var thisTmp = null;
      var indexTmp = null;
      var retTmp = null;
      if (returnKind == ReturnKind.POST) {
        // TODO(jimhug): Optimize this away when native JS works.
        retTmp = context.forceTemp(value);
      }
      if (kind != 0) {
        // TODO(jimhug): Very special number optimizations will go here...
        thisTmp = context.getTemp(this);
        indexTmp = context.getTemp(index);
        thisValue = context.assignTemp(thisTmp, thisValue);
        indexValue = context.assignTemp(indexTmp, indexValue);

        if (returnKind == ReturnKind.PRE) {
          retTmp = context.forceTemp(value);
        }

        var lhs = thisTmp.invoke(context, ':index', node,
          new Arguments(null, [indexTmp]));
        if (returnKind == ReturnKind.PRE) {
          lhs = context.assignTemp(retTmp, lhs);
        }
        value = lhs.binop(kind, value, context, node);
      }
      if (returnKind == ReturnKind.POST) {
        value = context.assignTemp(retTmp, value);
      }

      var ret = member.invoke(context, node, thisValue,
        new Arguments(null, [indexValue, value]));
      if (thisTmp != null && thisTmp != this) context.freeTemp(thisTmp);
      if (indexTmp != null && indexTmp != index) context.freeTemp(indexTmp);
      if (retTmp != null) {
        context.freeTemp(retTmp);
        return Value.comma(ret, retTmp);
      } else {
        return ret;
      }
    } else {
      // TODO(jimhug): Need to support += and noSuchMethod better.
      return invokeNoSuchMethod(context, ':index', node,
          new Arguments(null, [index, value]));
    }
  }

  //Value getIndex(CallingContext context, Value index, var node) {
  //}

  Value unop(int kind, CallingContext context, var node) {
    switch (kind) {
      case TokenKind.NOT:
        // TODO(jimhug): Issue #359 seeks to clarify this behavior.
        var newVal = convertTo(context, world.nonNullBool);
        return new Value(newVal.type, '!${newVal.code}', node.span);
      case TokenKind.ADD:
        world.error('no unary add operator in dart', node.span);
        break;
      case TokenKind.SUB:
        return invoke(context, ':negate', node, Arguments.EMPTY);
      case TokenKind.BIT_NOT:
        return invoke(context, ':bit_not', node, Arguments.EMPTY);
    }
    world.internalError('unimplemented: ${node.op}', node.span);
  }

  bool _mayOverrideEqual() {
    // TODO(jimhug): Need to check subtypes as well
    return type.isVar || type.isObject ||
      !type.getMember(':eq').declaringType.isObject;
  }

  Value binop(int kind, Value other, CallingContext context, var node) {
    switch (kind) {
      case TokenKind.AND:
      case TokenKind.OR:
        final code = '${code} ${node.op} ${other.code}';
        return new Value(world.nonNullBool, code, node.span);

      case TokenKind.EQ_STRICT:
      case TokenKind.NE_STRICT:
        var op = kind == TokenKind.EQ_STRICT ? '==' : '!=';
        if (code == 'null') {
          return new Value(world.nonNullBool,
            'null ${op} ${other.code}', node.span);
        } else if (other.code == 'null') {
          return new Value(world.nonNullBool,
            'null ${op} ${code}', node.span);
        } else {
          // TODO(jimhug): Add check to see if we can just use op on this type
          // TODO(jimhug): Optimize case of other.needsTemp == false.
          var ret;
          var check;
          if (needsTemp) {
            var tmp = context.forceTemp(this);
            ret = tmp.code;
            check = '(${ret} = ${code}) == null';
          } else {
            ret = code;
            check = 'null == ${code}';
          }
          return new Value(world.nonNullBool,
            '(${check} ? null ${op} (${other.code}) : ${ret} ${op}= ${other.code})',
            node.span);
        }

      case TokenKind.EQ:
        if (other.code == 'null') {
          if (!_mayOverrideEqual()) {
            return new Value(world.nonNullBool, '${code} == ${other.code}',
              node.span);
          }
        } else if (code == 'null') {
          return new Value(world.nonNullBool, '${code} == ${other.code}',
            node.span);
        }
        break;
      case TokenKind.NE:
        if (other.code == 'null') {
          if (!_mayOverrideEqual()) {
            return new Value(world.nonNullBool, '${code} != ${other.code}',
              node.span);
          }
        } else if (code == 'null') {
          return new Value(world.nonNullBool, '${code} != ${other.code}',
            node.span);
        }
        break;

    }

    var name = kind == TokenKind.NE ? ':ne': TokenKind.binaryMethodName(kind);
    return invoke(context, name, node, new Arguments(null, [other]));
  }


  Value invoke(CallingContext context, String name, Node node,
      Arguments args) {
    // TODO(jmesserly): it'd be nice to remove these special cases
    // We could create a :call in world members, and have that handle the
    // canInvoke/Invoke logic.

    // Note: this check is a little different than the one in canInvoke, because
    // sometimes we need to call dynamically even if we found the :call method
    // statically.

    if (name == ':call') {
      if (isType) {
        world.error('must use "new" or "const" to construct a new instance',
            node.span);
      }
      if (type.needsVarCall(args)) {
        return _varCall(context, node, args);
      }
    }

    var member = _resolveMember(context, name, node);
    if (member == null) {
      return invokeNoSuchMethod(context, name, node, args);
    } else {
      return member.invoke(context, node, this, args);
    }
  }

  /**
   * True if this class (or some related class that is not Object) overrides
   * noSuchMethod. If it does we suppress warnings about unknown members.
   */
  // TODO(jmesserly): should we be doing this?
  bool _hasOverriddenNoSuchMethod() {
    var m = type.getMember('noSuchMethod');
    return m != null && !m.declaringType.isObject;
  }

  // TODO(jimhug): Handle more precise types here, i.e. consts or closed...
  bool get isPreciseType() => isSuper || isType;

  void _missingMemberError(CallingContext context, String name, Node node) {
    bool onStaticType = false;
    if (type != staticType) {
      onStaticType = staticType.getMember(name) !== null;
    }

    if (!onStaticType && context.showWarnings &&
      !_isVarOrParameterType(staticType) && !_hasOverriddenNoSuchMethod()) {
      // warn if the member was not found, or error if it is a static lookup.
      var typeName = staticType.name;
      if (typeName == null) typeName = staticType.library.name;
      var message = 'cannot resolve "$name" on "${typeName}"';
      if (isType) {
        world.error(message, node.span);
      } else {
        world.warning(message, node.span);
      }
    }
  }



  MemberSet _tryResolveMember(CallingContext context, String name, Node node) {
    var member = type.getMember(name);
    if (member == null) {
      _missingMemberError(context, name, node);
      return null;
    } else {
      if (isType && !member.isStatic && context.showWarnings) {
        world.error('cannot refer to instance member as static', node.span);
        return null;
      }
    }

    if (isPreciseType || member.isStatic) {
      return member.preciseMemberSet;
    } else {
      return member.potentialMemberSet;
    }
  }

  // TODO(jmesserly): until reified generics are fixed, treat ParameterType as
  // "var".
  bool _isVarOrParameterType(Type t) => t.isVar || t is ParameterType;

  bool _shouldBindDynamically() {
    return _isVarOrParameterType(type) || options.forceDynamic && !isConst;
  }

  // TODO(jimhug): Better type here - currently is union(Member, MemberSet)
  MemberSet _resolveMember(CallingContext context, String name, Node node) {
    var member = null;
    if (!_shouldBindDynamically()) {
      member = _tryResolveMember(context, name, node);
    }

    // Fall back to a dynamic operation for instance members
    if (member == null && !isSuper && !isType) {
      member = context.findMembers(name);
      if (member == null && context.showWarnings) {
        var where = 'the world';
        if (name.startsWith('_')) {
          where = 'library "${context.library.name}"';
        }
        world.warning('$name is not defined anywhere in $where.',
           node.span);
      }
    }

    return member;
  }

  checkFirstClass(SourceSpan span) {
    if (isType) {
      world.error('Types are not first class', span);
    }
  }

  /** Generate a call to an unknown function type. */
  Value _varCall(CallingContext context, Node node, Arguments args) {
    // TODO(jmesserly): calls to unknown functions will bypass type checks,
    // which normally happen on the caller side, or in the generated stub for
    // dynamic method calls. What should we do?
    var stub = world.functionType.getCallStub(args);
    return stub.invoke(context, node, this, args);
  }

  /** True if convertTo would generate a conversion. */
  bool needsConversion(Type toType) {
    var c = convertTo(null, toType);
    return c == null || code != c.code;
  }

  /**
   * Assign or convert this value to another type.
   * This is used for converting between function types, inserting type
   * checks when --enable_type_checks is enabled, and wrapping callback
   * functions passed to the dom so we can restore their isolate context.
   */
  Value convertTo(CallingContext context, Type toType) {

    // Issue type warnings unless we are processing a dynamic operation.
    bool checked = context != null && context.showWarnings;

    var callMethod = toType.getCallMethod();
    if (callMethod != null) {
      if (checked && !toType.isAssignable(type)) {
        convertWarning(toType);
      }

      return _maybeWrapFunction(toType, callMethod);
    }

    // If we're assigning from a var, pretend it's Object for the purpose of
    // runtime checks.

    // TODO(jmesserly): I'm a little bothered by the fact that we can't call
    // isSubtypeOf directly. If we tracked null literals as the bottom type,
    // and then only allowed Dynamic to be bottom for generic type args, I think
    // we'd get the right behavior from isSubtypeOf.
    Type fromType = type;
    if (type.isVar && (code != 'null' || !toType.isNullable)) {
      fromType = world.objectType;
    }

    // TODO(jmesserly): remove the special case for "num" when our num handling
    // is better.
    bool bothNum = type.isNum && toType.isNum;
    if (!fromType.isSubtypeOf(toType) && !bothNum) {
      // If it is a narrowing conversion, we'll need a check in checked mode.

      if (checked && !toType.isSubtypeOf(type)) {
        // According to the static types, this conversion can't work.
        convertWarning(toType);
      }

      if (options.enableTypeChecks) {
        if (context == null) {
          // If we're called from needsConversion, we don't need a context.
          // Just return null so it knows a conversion is required.
          return null;
        }
        return _typeAssert(context, toType);
      }
    }

    return _changeStaticType(toType);
  }

  // Nothing to do in general.
  Value _changeStaticType(Type toType) => this;

  /**
   * Wraps a function with a conversion, so it can be called directly from
   * Dart or JS code with the proper arity. We avoid the wrapping if the target
   * function has the same arity.
   *
   * Also wraps a callback attached to the dom (e.g. event listeners,
   * setTimeout) so we can restore it's isolate context information. This is
   * needed so that callbacks are executed within the context of the isolate
   * that created them in the first place.
   */
  Value _maybeWrapFunction(Type toType, MethodMember callMethod) {
    int arity = callMethod.parameters.length;
    var myCall = type.getCallMethod();

    Value result = this;
    if (myCall == null || myCall.parameters.length != arity) {
      final stub = world.functionType.getCallStub(new Arguments.bare(arity));
      result = new Value(toType, 'to\$${stub.name}($code)', span);
    }

    // TODO(jmesserly): handle when type or toType are type parameters.
    if (toType.library.isDomOrHtml && !type.library.isDomOrHtml) {
      // TODO(jmesserly): either remove this or make it a more first class
      // feature of our native interop. We shouldn't be checking for the DOM
      // library--any host environment (like node.js) might need this feature
      // for isolates too. But we don't want to wrap every function we send to
      // native code--many callbacks like List.filter are perfectly safe.
      if (arity == 0) {
        world.gen.corejs.useWrap0 = true;
      } else if (arity == 1) {
        world.gen.corejs.useWrap1 = true;
      } else if (arity == 2) {
        world.gen.corejs.useWrap2 = true;
      }

      result = new Value(toType, '\$wrap_call\$$arity(${result.code})', span);
    }

    return result._changeStaticType(toType);
  }

  /**
   * Generates a run time type assertion for the given value. This works like
   * [instanceOf], but it allows null since Dart types are nullable.
   * Also it will throw a TypeError if it gets the wrong type.
   */
  Value _typeAssert(CallingContext context, Type toType) {
    if (toType is ParameterType) {
      ParameterType p = toType;
      toType = p.extendsType;
    }

    if (toType.isObject || toType.isVar) {
      world.internalError(
          'We thought ${type.name} is not a subtype of ${toType.name}?');
    }

    // Prevent a stack overflow when forceDynamic and type checks are both
    // enabled. forceDynamic would cause the TypeError constructor to type check
    // its arguments, which in turn invokes the TypeError constructor, ad
    // infinitum.
    String throwTypeError(String paramName) => world.withoutForceDynamic(() {
      final typeErrorCtor = world.typeErrorType.getConstructor('_internal');
      world.gen.corejs.ensureTypeNameOf();
      final result = typeErrorCtor.invoke(context, null,
          new TypeValue(world.typeErrorType, null),
          new Arguments(null, [
            new Value(world.objectType, paramName, null),
            new Value(world.stringType, '"${toType.name}"', null)]));
      world.gen.corejs.useThrow = true;
      return '\$throw(${result.code})';
    });

    // TODO(jmesserly): better assert for integers?
    if (toType.isNum) toType = world.numType;

    // Generate a check like these:
    //   obj && obj.is$TypeName()
    //   $assert_int(obj)
    //
    // We rely on the fact that calling an undefined method produces a JS
    // TypeError. Alternatively we could define fallbacks on Object that throw.
    String check;
    if (toType.isVoid) {
      check = '\$assert_void($code)';
      if (toType.typeCheckCode == null) {
        toType.typeCheckCode = '''
function \$assert_void(x) {
  if (x == null) return null;
  ${throwTypeError("x")}
}''';
      }
    } else if (toType == world.nonNullBool) {
      // This could be made less of a special case
      world.gen.corejs.useNotNullBool = true;
      check = '\$notnull_bool($code)';

    } else if (toType.library.isCore && toType.typeofName != null) {
      check = '\$assert_${toType.name}($code)';

      if (toType.typeCheckCode == null) {
        toType.typeCheckCode = '''
function \$assert_${toType.name}(x) {
  if (x == null || typeof(x) == "${toType.typeofName}") return x;
  ${throwTypeError("x")}
}''';
      }
    } else {
      toType.isChecked = true;

      String checkName = 'assert\$${toType.jsname}';

      // If we track nullability, we could simplify this check.
      var temp = context.getTemp(this);
      check = '(${context.assignTemp(temp, this).code} == null ? null :';
      check += ' ${temp.code}.$checkName())';
      if (this != temp) context.freeTemp(temp);

      // Generate the fallback on Object (that throws a TypeError)
      world.objectType.varStubs.putIfAbsent(checkName,
          () => new VarMethodStub(checkName, null, Arguments.EMPTY,
            throwTypeError('this')));
    }

    context.counters.typeAsserts++;
    return new Value(toType, check, span);
  }

  /**
   * Test to see if value is an instance of this type.
   *
   * - If a primitive type, then uses the JavaScript typeof.
   * - If it's a non-generic class, use instanceof.
   * - Otherwise add a fake member to test for.  This value is generated
   *   as a function so that it can be called for a runtime failure.
   */
  Value instanceOf(CallingContext context, Type toType, SourceSpan span,
      [bool isTrue=true, bool forceCheck=false]) {
    // TODO(jimhug): Optimize away tests that will always pass unless
    //    forceCheck is true.

    if (toType.isVar) {
      world.error('cannot resolve type', span);
    }

    String testCode = null;
    if (toType.isVar || toType.isObject || toType is ParameterType) {
      // Note: everything is an Object, including null.
      if (needsTemp) {
        return new Value(world.nonNullBool, '($code, true)', span);
      } else {
        // TODO(jimhug): Mark non-const?
        return Value.fromBool(true, span);
      }
    }

    if (toType.library.isCore) {
      var typeofName = toType.typeofName;
      if (typeofName != null) {
        testCode = "(typeof($code) ${isTrue ? '==' : '!='} '$typeofName')";
      }
    }

    if (toType.isClass
        && !toType.isHiddenNativeType && !toType.isConcreteGeneric) {
      toType.markUsed();
      testCode = '($code instanceof ${toType.jsname})';
      if (!isTrue) {
        testCode = '!${testCode}';
      }
    }
    if (testCode == null) {
      toType.isTested = true;

      // If we track nullability, we could simplify this check.
      var temp = context.getTemp(this);

      String checkName = 'is\$${toType.jsname}';
      testCode = '(${context.assignTemp(temp, this).code} &&'
          ' ${temp.code}.$checkName())';
      if (isTrue) {
        // Add !! to convert to boolean.
        // TODO(jimhug): only do this if needed
        testCode = '!!${testCode}';
      } else {
        // The single ! here nicely converts undefined to false and function
        // to true.
        testCode = '!${testCode}';
      }
      if (this != temp) context.freeTemp(temp);

      // Generate the fallback on Object (that returns false)
      if (!world.objectType.varStubs.containsKey(checkName)) {
        world.objectType.varStubs[checkName] =
          new VarMethodStub(checkName, null, Arguments.EMPTY, 'return false');
      }
    }
    return new Value(world.nonNullBool, testCode, span);
  }

  void convertWarning(Type toType) {
    // TODO(jmesserly): better error messages for type conversion failures
    world.warning(
        'type "${type.fullname}" is not assignable to "${toType.fullname}"',
        span);
  }

  Value invokeNoSuchMethod(CallingContext context, String name, Node node,
      [Arguments args]) {
    if (isType) {
      world.error('member lookup failed for "$name"', node.span);
    }

    var pos = '';
    if (args != null) {
      var argsCode = [];
      for (int i = 0; i < args.length; i++) {
        argsCode.add(args.values[i].code);
      }
      pos = Strings.join(argsCode, ", "); // don't remove trailing nulls
    }
    final noSuchArgs = [
        new Value(world.stringType, '"$name"', node.span),
        new Value(world.listType, '[$pos]', node.span)];

    // TODO(jmesserly): should be passing names but that breaks tests. Oh well.
    /*if (args != null && args.hasNames) {
      var names = [];
      for (int i = args.bareCount; i < args.length; i++) {
        names.add('"${args.getName(i)}", ${args.values[i].code}');
      }
      noSuchArgs.add(new Value(world.gen.useMapFactory(),
          '\$map(${Strings.join(names, ", ")})'));
    }*/

    // Finally, invoke noSuchMethod
    return _resolveMember(context, 'noSuchMethod', node).invoke(
        context, node, this, new Arguments(null, noSuchArgs));
  }


  static Value fromBool(bool value, SourceSpan span) {
    return new BoolValue(value, true, span);
  }

  static Value fromInt(int value, SourceSpan span) {
    return new IntValue(value, true, span);
  }

  static Value fromDouble(double value, SourceSpan span) {
    return new DoubleValue(value, true, span);
  }

  static Value fromString(String value, SourceSpan span) {
    return new StringValue(value, true, span);
  }

  static Value fromNull(SourceSpan span) {
    return new NullValue(true, span);
  }
}


// TODO(jimhug): rename to PrimitiveValue and refactor further
class EvaluatedValue extends Value implements Hashable {
  /** Is this value treated as const by dart language? */
  final bool isConst;

  EvaluatedValue(this.isConst, Type type, SourceSpan span):
    super(type, '@@@', span);

  String get code() {
    world.internalError('Should not be getting code from raw EvaluatedValue',
      span);
  }

  get actualValue() {
    world.internalError('Should not be getting actual value '
                        'from raw EvaluatedValue', span);
  }

  bool get needsTemp() => false;

  EvaluatedValue get constValue() => this;

  // TODO(jimhug): Using computed code here without caching is major fear.
  int hashCode() => code.hashCode();

  bool operator ==(var other) {
    return other is EvaluatedValue && other.type == this.type &&
      other.code == this.code;
  }
}


class NullValue extends EvaluatedValue {
  NullValue(bool isConst, SourceSpan span):
    super(isConst, world.varType, span);

  get actualValue() => null;

  String get code() => 'null';

  Value binop(int kind, var other, CallingContext context, var node) {
    if (other is! NullValue) return super.binop(kind, other, context, node);

    final c = isConst && other.isConst;
    final s = node.span;
    switch (kind) {
      case TokenKind.EQ_STRICT:
      case TokenKind.EQ:
        return new BoolValue(true, c, s);
      case TokenKind.NE_STRICT:
      case TokenKind.NE:
        return new BoolValue(false, c, s);
    }

    return super.binop(kind, other, context, node);
  }
}

class BoolValue extends EvaluatedValue {
  final bool actualValue;

  BoolValue(this.actualValue, bool isConst, SourceSpan span):
    super(isConst, world.nonNullBool, span);

  String get code() => actualValue ? 'true' : 'false';

  Value unop(int kind, CallingContext context, var node) {
    switch (kind) {
      case TokenKind.NOT:
        return new BoolValue(!actualValue, isConst, node.span);
    }
    return super.unop(kind, context, node);
  }

  Value binop(int kind, var other, CallingContext context, var node) {
    if (other is! BoolValue) return super.binop(kind, other, context, node);

    final c = isConst && other.isConst;
    final s = node.span;
    bool x = actualValue, y = other.actualValue;
    switch (kind) {
      case TokenKind.EQ_STRICT:
      case TokenKind.EQ:
        return new BoolValue(x == y, c, s);
      case TokenKind.NE_STRICT:
      case TokenKind.NE:
        return new BoolValue(x != y, c, s);
      case TokenKind.AND:
        return new BoolValue(x && y, c, s);
      case TokenKind.OR:
        return new BoolValue(x || y, c, s);
    }

    return super.binop(kind, other, context, node);
  }
}

class IntValue extends EvaluatedValue {
  final int actualValue;

  IntValue(this.actualValue, bool isConst, SourceSpan span):
    super(isConst, world.intType, span);

  // TODO(jimhug): Only add parens when needed.
  String get code() => '(${actualValue})';

  Value unop(int kind, CallingContext context, var node) {
    switch (kind) {
      case TokenKind.ADD:
        // This is allowed on numeric constants only
        return new IntValue(actualValue, isConst, span);
      case TokenKind.SUB:
        return new IntValue(-actualValue, isConst, span);
      case TokenKind.BIT_NOT:
        return new IntValue(~actualValue, isConst, span);
    }
    return super.unop(kind, context, node);
  }


  Value binop(int kind, var other, CallingContext context, var node) {
    final c = isConst && other.isConst;
    final s = node.span;
    if (other is IntValue) {
      int x = actualValue;
      int y = other.actualValue;
      switch (kind) {
        case TokenKind.EQ_STRICT:
        case TokenKind.EQ:
          return new BoolValue(x == y, c, s);
        case TokenKind.NE_STRICT:
        case TokenKind.NE:
          return new BoolValue(x != y, c, s);

        case TokenKind.BIT_OR:
          return new IntValue(x | y, c, s);
        case TokenKind.BIT_XOR:
          return new IntValue(x ^ y, c, s);
        case TokenKind.BIT_AND:
          return new IntValue(x & y, c, s);
        case TokenKind.SHL:
          return new IntValue(x << y, c, s);
        case TokenKind.SAR:
          return new IntValue(x >> y, c, s);
        case TokenKind.ADD:
          return new IntValue(x + y, c, s);
        case TokenKind.SUB:
          return new IntValue(x - y, c, s);
        case TokenKind.MUL:
          return new IntValue(x * y, c, s);
        case TokenKind.DIV:
          return new DoubleValue(x / y, c, s);
        case TokenKind.TRUNCDIV:
          return new IntValue(x ~/ y, c, s);
        case TokenKind.MOD:
          return new IntValue(x % y, c, s);
        case TokenKind.LT:
          return new BoolValue(x < y, c, s);
        case TokenKind.GT:
          return new BoolValue(x > y, c, s);
        case TokenKind.LTE:
          return new BoolValue(x <= y, c, s);
        case TokenKind.GTE:
          return new BoolValue(x >= y, c, s);
      }
    } else if (other is DoubleValue) {
      int x = actualValue;
      double y = other.actualValue;
      switch (kind) {
        case TokenKind.EQ_STRICT:
        case TokenKind.EQ:
          return new BoolValue(x == y, c, s);
        case TokenKind.NE_STRICT:
        case TokenKind.NE:
          return new BoolValue(x != y, c, s);

        case TokenKind.ADD:
          return new DoubleValue(x + y, c, s);
        case TokenKind.SUB:
          return new DoubleValue(x - y, c, s);
        case TokenKind.MUL:
          return new DoubleValue(x * y, c, s);
        case TokenKind.DIV:
          return new DoubleValue(x / y, c, s);
        case TokenKind.TRUNCDIV:
          // TODO(jimhug): I expected int, but corelib says double here...
          return new DoubleValue(x ~/ y, c, s);
        case TokenKind.MOD:
          return new DoubleValue(x % y, c, s);
        case TokenKind.LT:
          return new BoolValue(x < y, c, s);
        case TokenKind.GT:
          return new BoolValue(x > y, c, s);
        case TokenKind.LTE:
          return new BoolValue(x <= y, c, s);
        case TokenKind.GTE:
          return new BoolValue(x >= y, c, s);
      }
    }

    return super.binop(kind, other, context, node);
  }
}

class DoubleValue extends EvaluatedValue {
  final double actualValue;

  DoubleValue(this.actualValue, bool isConst, SourceSpan span):
    super(isConst, world.doubleType, span);

  String get code() => '(${actualValue})';

  Value unop(int kind, CallingContext context, var node) {
    switch (kind) {
      case TokenKind.ADD:
        // This is allowed on numeric constants only
        return new DoubleValue(actualValue, isConst, span);
      case TokenKind.SUB:
        return new DoubleValue(-actualValue, isConst, span);
    }
    return super.unop(kind, context, node);
  }

  Value binop(int kind, var other, CallingContext context, var node) {
    final c = isConst && other.isConst;
    final s = node.span;
    if (other is DoubleValue) {
      double x = actualValue;
      double y = other.actualValue;
      switch (kind) {
        case TokenKind.EQ_STRICT:
        case TokenKind.EQ:
          return new BoolValue(x == y, c, s);
        case TokenKind.NE_STRICT:
        case TokenKind.NE:
          return new BoolValue(x != y, c, s);

        case TokenKind.ADD:
          return new DoubleValue(x + y, c, s);
        case TokenKind.SUB:
          return new DoubleValue(x - y, c, s);
        case TokenKind.MUL:
          return new DoubleValue(x * y, c, s);
        case TokenKind.DIV:
          return new DoubleValue(x / y, c, s);
        case TokenKind.TRUNCDIV:
          // TODO(jimhug): I expected int, but corelib says double here...
          return new DoubleValue(x ~/ y, c, s);
        case TokenKind.MOD:
          return new DoubleValue(x % y, c, s);
        case TokenKind.LT:
          return new BoolValue(x < y, c, s);
        case TokenKind.GT:
          return new BoolValue(x > y, c, s);
        case TokenKind.LTE:
          return new BoolValue(x <= y, c, s);
        case TokenKind.GTE:
          return new BoolValue(x >= y, c, s);
      }
    } else if (other is IntValue) {
      double x = actualValue;
      int y = other.actualValue;
      switch (kind) {
        case TokenKind.EQ_STRICT:
        case TokenKind.EQ:
          return new BoolValue(x == y, c, s);
        case TokenKind.NE_STRICT:
        case TokenKind.NE:
          return new BoolValue(x != y, c, s);

        case TokenKind.ADD:
          return new DoubleValue(x + y, c, s);
        case TokenKind.SUB:
          return new DoubleValue(x - y, c, s);
        case TokenKind.MUL:
          return new DoubleValue(x * y, c, s);
        case TokenKind.DIV:
          return new DoubleValue(x / y, c, s);
        case TokenKind.TRUNCDIV:
          // TODO(jimhug): I expected int, but corelib says double here...
          return new DoubleValue(x ~/ y, c, s);
        case TokenKind.MOD:
          return new DoubleValue(x % y, c, s);
        case TokenKind.LT:
          return new BoolValue(x < y, c, s);
        case TokenKind.GT:
          return new BoolValue(x > y, c, s);
        case TokenKind.LTE:
          return new BoolValue(x <= y, c, s);
        case TokenKind.GTE:
          return new BoolValue(x >= y, c, s);
      }
    }

    return super.binop(kind, other, context, node);
  }
}

class StringValue extends EvaluatedValue {
  final String actualValue;

  StringValue(this.actualValue, bool isConst, SourceSpan span):
    super(isConst, world.stringType, span);

  Value binop(int kind, var other, CallingContext context, var node) {
    if (other is! StringValue) return super.binop(kind, other, context, node);

    final c = isConst && other.isConst;
    final s = node.span;
    String x = actualValue, y = other.actualValue;
    switch (kind) {
      case TokenKind.EQ_STRICT:
      case TokenKind.EQ:
        return new BoolValue(x == y, c, s);
      case TokenKind.NE_STRICT:
      case TokenKind.NE:
        return new BoolValue(x != y, c, s);
      case TokenKind.ADD:
        return new StringValue(x + y, c, s);
    }

    return super.binop(kind, other, context, node);
  }


  // This is expensive and we may want to cache its value if called often
  String get code() {
    // TODO(jimhug): This could be much more efficient
    StringBuffer buf = new StringBuffer();
    buf.add('"');
    for (int i=0; i < actualValue.length; i++) {
      var ch = actualValue.charCodeAt(i);
      switch (ch) {
        case 9/*'\t'*/: buf.add(@'\t'); break;
        case 10/*'\n'*/: buf.add(@'\n'); break;
        case 13/*'\r'*/: buf.add(@'\r'); break;
        case 34/*"*/: buf.add(@'\"'); break;
        case 92/*\*/: buf.add(@'\\'); break;
        default:
          if (ch >= 32 && ch <= 126) {
            buf.add(actualValue[i]);
          } else {
            final hex = ch.toRadixString(16);
            switch (hex.length) {
              case 1: buf.add(@'\x0'); buf.add(hex); break;
              case 2: buf.add(@'\x'); buf.add(hex); break;
              case 3: buf.add(@'\u0'); buf.add(hex); break;
              case 4: buf.add(@'\u'); buf.add(hex); break;
              default:
                world.internalError(
                  'unicode values greater than 2 bytes not implemented');
                break;
            }
          }
          break;
      }
    }
    buf.add('"');
    return buf.toString();
  }
}

class ListValue extends EvaluatedValue {
  final List<Value> values;

  ListValue(this.values, bool isConst, Type type, SourceSpan span):
    super(isConst, type, span);

  String get code() {
    final buf = new StringBuffer();
    buf.add('[');
    for (var i = 0; i < values.length; i++) {
      if (i > 0) buf.add(', ');
      buf.add(values[i].code);
    }
    buf.add(']');
    var listCode = buf.toString();

    if (!isConst) return listCode;

    var v = new Value(world.listType, listCode, span);
    final immutableListCtor = world.immutableListType.getConstructor('from');
    final result = immutableListCtor.invoke(world.gen.mainContext, null,
        new TypeValue(v.type, span), new Arguments(null, [v]));
    return result.code;
  }

  Value binop(int kind, var other, CallingContext context, var node) {
    // TODO(jimhug): Support int/double better
    if (other is! ListValue) return super.binop(kind, other, context, node);

    switch (kind) {
      case TokenKind.EQ_STRICT:
        return new BoolValue(type == other.type && code == other.code,
          isConst && other.isConst, node.span);
      case TokenKind.NE_STRICT:
        return new BoolValue(type != other.type || code != other.code,
          isConst && other.isConst, node.span);
    }

    return super.binop(kind, other, context, node);
  }

  GlobalValue getGlobalValue() {
    assert(isConst);

    return world.gen.globalForConst(this, values);
  }
}


class MapValue extends EvaluatedValue {
  final List<Value> values;

  MapValue(this.values, bool isConst, Type type, SourceSpan span):
    super(isConst, type, span);

  String get code() {
    // Cache?
    var items = new ListValue(values, false, world.listType, span);
    var tp = world.coreimpl.topType;
    Member f = isConst ? tp.getMember('_constMap') : tp.getMember('_map');
    // TODO(jimhug): Clean up invoke signature
    var value = f.invoke(world.gen.mainContext, null, new TypeValue(tp, null),
      new Arguments(null, [items]));
    return value.code;
  }

  GlobalValue getGlobalValue() {
    assert(isConst);

    return world.gen.globalForConst(this, values);
  }

  Value binop(int kind, var other, CallingContext context, var node) {
    if (other is! MapValue) return super.binop(kind, other, context, node);

    switch (kind) {
      case TokenKind.EQ_STRICT:
        return new BoolValue(type == other.type && code == other.code,
          isConst && other.isConst, node.span);
      case TokenKind.NE_STRICT:
        return new BoolValue(type != other.type || code != other.code,
          isConst && other.isConst, node.span);
    }

    return super.binop(kind, other, context, node);
  }
}


class ObjectValue extends EvaluatedValue {
  final Map<FieldMember, Value> fields;
  final List<FieldMember> fieldsInInitOrder;
  bool seenNativeInitializer = false;

  String _code;

  ObjectValue(bool isConst, Type type, SourceSpan span)
      : fields = new Map<FieldMember, Value>(),
        fieldsInInitOrder = <FieldMember>[],
        super(isConst, type, span);

  String get code() {
    if (_code === null) validateInitialized(null);
    return _code;
  }

  initFields() {
    var allMembers = world.gen._orderValues(type.genericType.getAllMembers());
    for (var f in allMembers) {
      if (f.isField && !f.isStatic && f.declaringType.isClass) {
        _replaceField(f, f.computeValue(), true);
      }
    }
  }

  setField(Member field, Value value, [bool duringInit = false]) {
    // Unpack constant values
    if (value.isConst && value is VariableValue) {
      value = value.dynamic.value;
    }
    var currentValue = fields[field];
    if (isConst && !value.isConst) {
      world.error('used of non-const value in const intializer', value.span);
    }

    if (currentValue === null) {
      _replaceField(field, value, duringInit);
      if (field.isFinal && !duringInit) {
        world.error('cannot initialize final fields outside of initializer',
          value.span);
      }
    } else {
      // TODO(jimhug): Clarify spec on reinitializing fields with defaults.
      if (field.isFinal && field.computeValue() === null) {
        world.error('reassignment of field not allowed', value.span,
          field.span);
      } else {
        _replaceField(field, value, duringInit);
      }
    }
  }

  _replaceField(Member field, Value value, bool duringInit) {
    if (duringInit) {
      for (int i = 0; i < fieldsInInitOrder.length; i++) {
        if (fieldsInInitOrder[i] == field) {
          fieldsInInitOrder[i] = null;
          break;
        }
      }
      // TODO(sra): What if the overridden value contains an effect?
      fieldsInInitOrder.add(field);
    }
    fields[field] = value; //currentValue.union(value);
  }

  validateInitialized(SourceSpan span) {
    var buf = new StringBuffer();
    buf.add('Object.create(');
    buf.add('${type.jsname}.prototype, ');

    buf.add('{');
    bool addComma = false;
    for (var field in fields.getKeys()) {
      if (addComma) buf.add(', ');
      buf.add(field.jsname);
      buf.add(': ');
      buf.add('{"value": ');
      if (fields[field] === null) {
        world.error("Required field '${field.name}' was not initialized",
          span, field.span);
        buf.add('null');
      } else {
        buf.add(fields[field].code);
      }
      buf.add(', writeable: false}');
      addComma = true;
    }
    buf.add('})');
    _code = buf.toString();
  }

  Value binop(int kind, var other, CallingContext context, var node) {
    if (other is! ObjectValue) return super.binop(kind, other, context, node);

    switch (kind) {
      case TokenKind.EQ_STRICT:
      case TokenKind.EQ:
        return new BoolValue(type == other.type && code == other.code,
          isConst && other.isConst, node.span);
      case TokenKind.NE_STRICT:
      case TokenKind.NE:
        return new BoolValue(type != other.type || code != other.code,
          isConst && other.isConst, node.span);
    }

    return super.binop(kind, other, context, node);
  }

}


/**
 * A global value in the generated code, which corresponds to either a static
 * field or a memoized const expressions.
 */
class GlobalValue extends Value implements Comparable {
  /** Static field definition (null for constant exp). */
  final FieldMember field;

  /**
   * When [this] represents a constant expression, the global variable name
   * generated for it.
   */
  final String name;

  /** The value of the field or constant expression to declare. */
  final Value exp;

  /** True for either cont expressions or a final static field. */
  final bool isConst;

  /** The actual constant value, when [isConst] is true. */
  get actualValue() => exp.dynamic.actualValue;

  /** If [isConst], the [EvaluatedValue] that defines this value. */
  EvaluatedValue get constValue() => isConst ? exp.constValue : null;

  /** Other globals that should be defined before this global. */
  final List<GlobalValue> dependencies;

  GlobalValue(Type type, String code, bool isConst,
      this.field, this.name, this.exp,
      SourceSpan span, List<Value> deps):
    isConst = isConst,
    dependencies = <GlobalValue>[],
    super(type, code, span) {

    // store transitive-dependencies so sorting algorithm works correctly.
    for (var dep in deps) {
      if (dep is GlobalValue) {
        dependencies.add(dep);
        dependencies.addAll(dep.dependencies);
      }
    }
  }

  bool get needsTemp() => !isConst;

  int compareTo(GlobalValue other) {
    // order by dependencies, o.w. by name
    if (other == this) {
      return 0;
    } else if (dependencies.indexOf(other) >= 0) {
      return 1;
    } else if (other.dependencies.indexOf(this) >= 0) {
      return -1;
    } else if (dependencies.length > other.dependencies.length) {
      return 1;
    } else if (dependencies.length < other.dependencies.length) {
      return -1;
    } else if (name == null && other.name != null) {
      return 1;
    } else if (name != null && other.name == null) {
      return -1;
    } else if (name != null) {
      return name.compareTo(other.name);
    } else {
      return field.name.compareTo(other.field.name);
    }
  }
}

/**
 * Represents the hidden or implicit value in a bare reference like 'a'.
 * This could be this, the current type, or the current library for purposes
 * of resolving members.
 */
class BareValue extends Value {
  final bool isType;
  final CallingContext home;

  String _code;

  BareValue(this.home, CallingContext outermost, SourceSpan span):
    isType = outermost.isStatic,
    super(outermost.method.declaringType, null, span);

  bool get needsTemp() => false;
  bool _shouldBindDynamically() => false;

  String get code() => _code;

  // TODO(jimhug): Lazy initialization here is weird!
  void _ensureCode() {
    if (_code === null) _code = isType ? type.jsname : home._makeThisCode();
  }

  MemberSet _tryResolveMember(CallingContext context, String name, Node node) {
    assert(context == home);

    // TODO(jimhug): Confirm this matches final resolution of issue 641.
    var member = type.getMember(name);
    if (member == null || member.declaringType != type) {
      var libMember = home.library.lookup(name, span);
      if (libMember !== null) {
        return libMember.preciseMemberSet;
      }
    }

    _ensureCode();
    return super._tryResolveMember(context, name, node);
  }
}

/** A reference to 'super'. */
// TODO(jmesserly): override resolveMember to clean up the one on Value
class SuperValue extends Value {
  SuperValue(Type parentType, SourceSpan span):
    super(parentType, 'this', span);

  bool get needsTemp() => false;
  bool get isSuper() => true;
  bool _shouldBindDynamically() => false;

  Value _tryUnion(Value right) => right is SuperValue ? this : null;
}

/** A reference to 'this'. */
class ThisValue extends Value {
  ThisValue(Type type, String code, SourceSpan span):
    super(type, code, span);

  bool get needsTemp() => false;
  bool _shouldBindDynamically() => false;

  Value _tryUnion(Value right) => right is ThisValue ? this : null;
}

/** A pretend first-class type. */
class TypeValue extends Value {
  TypeValue(Type type, SourceSpan span):
    super(type, null, span);

  bool get needsTemp() => false;
  bool get isType() => true;
  bool _shouldBindDynamically() => false;

  Value _tryUnion(Value right) => right is TypeValue ? this : null;
}


/**
 * A value that represents a variable or parameter. The [assigned] value can be
 * mutated when the variable is assigned to a new Value.
 */
class VariableValue extends Value {
  final bool isFinal;
  final Value value;

  VariableValue(Type staticType, String code, SourceSpan span,
      [this.isFinal=false, Value value]):
    value = _unwrap(value),
    super(staticType, code, span) {

    // these are not really first class
    assert(value === null || !value.isType && !value.isSuper);

    // TODO(jmesserly): should we do convertTo here, so the check doesn't get
    // missed? There are some cases where this assert doesn't hold.
    // assert(value === null || value.staticType == staticType);
  }

  static Value _unwrap(Value v) {
    if (v === null) return null;
    if (v is VariableValue) {
      v = v.dynamic.value;
    }
    return v;
  }

  Value _tryUnion(Value right) => Value.union(value, right);

  bool get needsTemp() => false;
  Type get type() => value !== null ? value.type : staticType;
  Type get staticType() => super.type;
  bool get isConst() => value !== null ? value.isConst : false;

  // TODO(jmesserly): we could use this for checking uninitialized values
  bool get isInitialized() => value != null;

  VariableValue replaceValue(Value v) =>
      new VariableValue(staticType, code, span, isFinal, v);

  // TODO(jmesserly): anything else to override?
  Value unop(int kind, CallingContext context, var node) {
    if (value != null) {
      return replaceValue(value.unop(kind, context, node));
    }
    return super.unop(kind, context, node);
  }
  Value binop(int kind, var other, CallingContext context, var node) {
    if (value != null) {
      return replaceValue(value.binop(kind, _unwrap(other), context, node));
    }
    return super.binop(kind, other, context, node);
  }
}
