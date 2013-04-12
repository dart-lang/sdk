// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class ConstantEmitter  {
  ConstantReferenceEmitter _referenceEmitter;
  ConstantInitializerEmitter _initializerEmitter;

  ConstantEmitter(Compiler compiler, Namer namer) {
    _referenceEmitter = new ConstantReferenceEmitter(compiler, namer);
    _initializerEmitter = new ConstantInitializerEmitter(
        compiler, namer, _referenceEmitter);
  }

  /**
   * Constructs an expression that is a reference to the constant.  Uses a
   * canonical name unless the constant can be emitted multiple times (as for
   * numbers and strings).
   */
  jsAst.Expression reference(Constant constant) {
    return _referenceEmitter.generate(constant);
  }

  /**
   * Constructs an expression like [reference], but the expression is valid
   * during isolate initialization.
   */
  jsAst.Expression referenceInInitializationContext(Constant constant) {
    return _referenceEmitter.generateInInitializationContext(constant);
  }

  /**
   * Constructs an expression used to initialize a canonicalized constant.
   */
  jsAst.Expression initializationExpression(Constant constant) {
    return _initializerEmitter.generate(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions to refer to [Constant]s.
 * Do not use directly, use methods from [ConstantEmitter].
 */
class ConstantReferenceEmitter implements ConstantVisitor<jsAst.Expression> {
  final Compiler compiler;
  final Namer namer;

  ConstantReferenceEmitter(this.compiler, this.namer);

  jsAst.Expression generate(Constant constant) {
    return _visit(constant);
  }

  jsAst.Expression generateInInitializationContext(Constant constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(Constant constant) {
    return constant.accept(this);
  }

  jsAst.Expression visitSentinel(SentinelConstant constant) {
    return new jsAst.VariableUse(namer.CURRENT_ISOLATE);
  }

  jsAst.Expression visitFunction(FunctionConstant constant) {
    return new jsAst.VariableUse(namer.isolateAccess(constant.element));
  }

  jsAst.Expression visitNull(NullConstant constant) {
    return new jsAst.LiteralNull();
  }

  jsAst.Expression visitInt(IntConstant constant) {
    return new jsAst.LiteralNumber('${constant.value}');
  }

  jsAst.Expression visitDouble(DoubleConstant constant) {
    double value = constant.value;
    if (value.isNaN) {
      return js("0/0");
    } else if (value == double.INFINITY) {
      return js("1/0");
    } else if (value == -double.INFINITY) {
      return js("-1/0");
    } else {
      return new jsAst.LiteralNumber("$value");
    }
  }

  jsAst.Expression visitTrue(TrueConstant constant) {
    if (compiler.enableMinification) {
      // Use !0 for true.
      return js("!0");
    } else {
      return js('true');
    }
  }

  jsAst.Expression visitFalse(FalseConstant constant) {
    if (compiler.enableMinification) {
      // Use !1 for false.
      return js("!1");
    } else {
      return js('false');
    }
  }

  /**
   * Write the contents of the quoted string to a [CodeBuffer] in
   * a form that is valid as JavaScript string literal content.
   * The string is assumed quoted by double quote characters.
   */
  jsAst.Expression visitString(StringConstant constant) {
    // TODO(sra): If the string is long *and repeated* (and not on a hot path)
    // then it should be assigned to a name.  We don't have reference counts (or
    // profile information) here, so this is the wrong place.
    StringBuffer sb = new StringBuffer();
    writeJsonEscapedCharsOn(constant.value.slowToString(), sb);
    return new jsAst.LiteralString('"$sb"');
  }

  jsAst.Expression emitCanonicalVersion(Constant constant) {
    String name = namer.constantName(constant);
    return new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(namer.CURRENT_ISOLATE), name);
  }

  jsAst.Expression visitList(ListConstant constant) {
    return emitCanonicalVersion(constant);
  }

  jsAst.Expression visitMap(MapConstant constant) {
    return emitCanonicalVersion(constant);
  }

  jsAst.Expression visitType(TypeConstant constant) {
    return emitCanonicalVersion(constant);
  }

  jsAst.Expression visitConstructed(ConstructedConstant constant) {
    return emitCanonicalVersion(constant);
  }

  jsAst.Expression visitInterceptor(InterceptorConstant constant) {
    return emitCanonicalVersion(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions to initialize [Constant]s.
 * Do not use directly; use methods from [ConstantEmitter].
 */
class ConstantInitializerEmitter implements ConstantVisitor<jsAst.Expression> {
  final Compiler compiler;
  final Namer namer;
  final ConstantReferenceEmitter referenceEmitter;

  ConstantInitializerEmitter(this.compiler, this.namer, this.referenceEmitter);

  jsAst.Expression generate(Constant constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(Constant constant) {
    return constant.accept(this);
  }

  jsAst.Expression _reference(Constant constant) {
    return referenceEmitter.generateInInitializationContext(constant);
  }

  jsAst.Expression visitSentinel(SentinelConstant constant) {
    compiler.internalError(
        "The parameter sentinel constant does not need specific JS code");
  }

  jsAst.Expression visitFunction(FunctionConstant constant) {
    compiler.internalError(
        "The function constant does not need specific JS code");
  }

  jsAst.Expression visitNull(NullConstant constant) {
    return _reference(constant);
  }

  jsAst.Expression visitInt(IntConstant constant) {
    return _reference(constant);
  }

  jsAst.Expression visitDouble(DoubleConstant constant) {
    return _reference(constant);
  }

  jsAst.Expression visitTrue(TrueConstant constant) {
    return _reference(constant);
  }

  jsAst.Expression visitFalse(FalseConstant constant) {
    return _reference(constant);
  }

  jsAst.Expression visitString(StringConstant constant) {
    // TODO(sra): Some larger strings are worth sharing.
    return _reference(constant);
  }

  jsAst.Expression visitList(ListConstant constant) {
    return new jsAst.Call(
        new jsAst.PropertyAccess.field(
            new jsAst.VariableUse(namer.isolateName),
            'makeConstantList'),
        [new jsAst.ArrayInitializer.from(_array(constant.entries))]);
  }

  String getJsConstructor(ClassElement element) {
    return namer.isolateAccess(element);
  }

  jsAst.Expression visitMap(MapConstant constant) {
    jsAst.Expression jsMap() {
      List<jsAst.Property> properties = <jsAst.Property>[];
      int valueIndex = 0;
      for (int i = 0; i < constant.keys.entries.length; i++) {
        StringConstant key = constant.keys.entries[i];
        if (key.value == MapConstant.PROTO_PROPERTY) continue;

        // Keys in literal maps must be emitted in place.
        jsAst.Literal keyExpression = _visit(key);
        jsAst.Expression valueExpression =
            _reference(constant.values[valueIndex++]);
        properties.add(new jsAst.Property(keyExpression, valueExpression));
      }
      if (valueIndex != constant.values.length) {
        compiler.internalError("Bad value count.");
      }
      return new jsAst.ObjectInitializer(properties);
    }

    void badFieldCountError() {
      compiler.internalError(
          "Compiler and ConstantMap disagree on number of fields.");
    }

    ClassElement classElement = constant.type.element;

    List<jsAst.Expression> arguments = <jsAst.Expression>[];

    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    classElement.implementation.forEachInstanceField(
        (ClassElement enclosing, Element field) {
          if (field.name == MapConstant.LENGTH_NAME) {
            arguments.add(
                new jsAst.LiteralNumber('${constant.keys.entries.length}'));
          } else if (field.name == MapConstant.JS_OBJECT_NAME) {
            arguments.add(jsMap());
          } else if (field.name == MapConstant.KEYS_NAME) {
            arguments.add(_reference(constant.keys));
          } else if (field.name == MapConstant.PROTO_VALUE) {
            assert(constant.protoValue != null);
            arguments.add(_reference(constant.protoValue));
          } else {
            badFieldCountError();
          }
          emittedArgumentCount++;
        },
        includeBackendMembers: true,
        includeSuperMembers: true);

    if ((constant.protoValue == null && emittedArgumentCount != 3) ||
        (constant.protoValue != null && emittedArgumentCount != 4)) {
      badFieldCountError();
    }

    return new jsAst.New(
        new jsAst.VariableUse(getJsConstructor(classElement)),
        arguments);
  }

  jsAst.Expression visitType(TypeConstant constant) {
    JavaScriptBackend backend = compiler.backend;
    Element helper = backend.getCreateRuntimeType();
    String helperName = backend.namer.getName(helper);
    DartType type = constant.representedType;
    String name = namer.getRuntimeTypeName(type.element);
    jsAst.Expression typeName = new jsAst.LiteralString("'$name'");
    return new jsAst.Call(
        new jsAst.PropertyAccess.field(
            new jsAst.VariableUse(namer.CURRENT_ISOLATE),
            helperName),
        [typeName]);
  }

  jsAst.Expression visitInterceptor(InterceptorConstant constant) {
    return new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(
            getJsConstructor(constant.dispatchedType.element)),
        'prototype');
  }

  jsAst.Expression visitConstructed(ConstructedConstant constant) {
    return new jsAst.New(
        new jsAst.VariableUse(getJsConstructor(constant.type.element)),
        _array(constant.fields));
  }

  List<jsAst.Expression> _array(List<Constant> values) {
    List<jsAst.Expression> valueList = <jsAst.Expression>[];
    for (int i = 0; i < values.length; i++) {
      valueList.add(_reference(values[i]));
    }
    return valueList;
  }
}
