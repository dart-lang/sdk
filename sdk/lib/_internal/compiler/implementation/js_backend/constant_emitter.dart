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
  js.Expression reference(Constant constant) {
    return _referenceEmitter.generate(constant);
  }

  /**
   * Constructs an expression like [reference], but the expression is valid
   * during isolate initialization.
   */
  js.Expression referenceInInitializationContext(Constant constant) {
    return _referenceEmitter.generateInInitializationContext(constant);
  }

  /**
   * Constructs an expression used to initialize a canonicalized constant.
   */
  js.Expression initializationExpression(Constant constant) {
    return _initializerEmitter.generate(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions to refer to [Constant]s.
 * Do not use directly, use methods from [ConstantEmitter].
 */
class ConstantReferenceEmitter implements ConstantVisitor<js.Expression> {
  final Compiler compiler;
  final Namer namer;
  bool inIsolateInitializationContext = false;

  ConstantReferenceEmitter(this.compiler, this.namer);

  js.Expression generate(Constant constant) {
    inIsolateInitializationContext = false;
    return _visit(constant);
  }

  js.Expression generateInInitializationContext(Constant constant) {
    inIsolateInitializationContext = true;
    return _visit(constant);
  }

  js.Expression _visit(Constant constant) {
    return constant.accept(this);
  }

  js.Expression visitSentinel(SentinelConstant constant) {
    return new js.VariableUse(namer.CURRENT_ISOLATE);
  }

  js.Expression visitFunction(FunctionConstant constant) {
    return inIsolateInitializationContext
        ? new js.VariableUse(namer.isolatePropertiesAccess(constant.element))
        : new js.VariableUse(namer.isolateAccess(constant.element));
  }

  js.Expression visitNull(NullConstant constant) {
    return new js.LiteralNull();
  }

  js.Expression visitInt(IntConstant constant) {
    return new js.LiteralNumber('${constant.value}');
  }

  js.Expression visitDouble(DoubleConstant constant) {
    double value = constant.value;
    if (value.isNaN) {
      return new js.LiteralNumber("(0/0)");
    } else if (value == double.INFINITY) {
      return new js.LiteralNumber("(1/0)");
    } else if (value == -double.INFINITY) {
      return new js.LiteralNumber("(-1/0)");
    } else {
      return new js.LiteralNumber("$value");
    }
  }

  js.Expression visitTrue(TrueConstant constant) {
    if (compiler.enableMinification) {
      // Use !0 for true.
      return new js.Prefix("!", new js.LiteralNumber("0"));
    } else {
      return new js.LiteralBool(true);
    }

  }

  js.Expression visitFalse(FalseConstant constant) {
    if (compiler.enableMinification) {
      // Use !1 for false.
      return new js.Prefix("!", new js.LiteralNumber("1"));
    } else {
      return new js.LiteralBool(false);
    }
  }

  /**
   * Write the contents of the quoted string to a [CodeBuffer] in
   * a form that is valid as JavaScript string literal content.
   * The string is assumed quoted by double quote characters.
   */
  js.Expression visitString(StringConstant constant) {
    // TODO(sra): If the string is long *and repeated* (and not on a hot path)
    // then it should be assigned to a name.  We don't have reference counts (or
    // profile information) here, so this is the wrong place.
    StringBuffer sb = new StringBuffer();
    writeJsonEscapedCharsOn(constant.value.slowToString(), sb);
    return new js.LiteralString('"$sb"');
  }

  js.Expression emitCanonicalVersion(Constant constant) {
    String name = namer.constantName(constant);
    if (inIsolateInitializationContext) {
      //  $ISOLATE.$ISOLATE_PROPERTIES.$name
      return new js.PropertyAccess.field(
          new js.PropertyAccess.field(
              new js.VariableUse(namer.ISOLATE),
              namer.ISOLATE_PROPERTIES),
          name);
    } else {
      return new js.PropertyAccess.field(
          new js.VariableUse(namer.CURRENT_ISOLATE),
          name);
    }
  }

  js.Expression visitList(ListConstant constant) {
    return emitCanonicalVersion(constant);
  }

  js.Expression visitMap(MapConstant constant) {
    return emitCanonicalVersion(constant);
  }

  js.Expression visitType(TypeConstant constant) {
    return emitCanonicalVersion(constant);
  }

  js.Expression visitConstructed(ConstructedConstant constant) {
    return emitCanonicalVersion(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions to initialize [Constant]s.
 * Do not use directly; use methods from [ConstantEmitter].
 */
class ConstantInitializerEmitter implements ConstantVisitor<js.Expression> {
  final Compiler compiler;
  final Namer namer;
  final ConstantReferenceEmitter referenceEmitter;

  ConstantInitializerEmitter(this.compiler, this.namer, this.referenceEmitter);

  js.Expression generate(Constant constant) {
    return _visit(constant);
  }

  js.Expression _visit(Constant constant) {
    return constant.accept(this);
  }

  js.Expression _reference(Constant constant) {
    return referenceEmitter.generateInInitializationContext(constant);
  }

  js.Expression visitSentinel(SentinelConstant constant) {
    compiler.internalError(
        "The parameter sentinel constant does not need specific JS code");
  }

  js.Expression visitFunction(FunctionConstant constant) {
    compiler.internalError(
        "The function constant does not need specific JS code");
  }

  js.Expression visitNull(NullConstant constant) {
    return _reference(constant);
  }

  js.Expression visitInt(IntConstant constant) {
    return _reference(constant);
  }

  js.Expression visitDouble(DoubleConstant constant) {
    return _reference(constant);
  }

  js.Expression visitTrue(TrueConstant constant) {
    return _reference(constant);
  }

  js.Expression visitFalse(FalseConstant constant) {
    return _reference(constant);
  }

  js.Expression visitString(StringConstant constant) {
    // TODO(sra): Some larger strings are worth sharing.
    return _reference(constant);
  }

  js.Expression visitList(ListConstant constant) {
    return new js.Call(
        new js.PropertyAccess.field(
            new js.VariableUse(namer.ISOLATE),
            'makeConstantList'),
        [new js.ArrayInitializer.from(_array(constant.entries))]);
  }

  String getJsConstructor(ClassElement element) {
    return namer.isolatePropertiesAccess(element);
  }

  js.Expression visitMap(MapConstant constant) {
    js.Expression jsMap() {
      List<js.Property> properties = <js.Property>[];
      int valueIndex = 0;
      for (int i = 0; i < constant.keys.entries.length; i++) {
        StringConstant key = constant.keys.entries[i];
        if (key.value == MapConstant.PROTO_PROPERTY) continue;

        // Keys in literal maps must be emitted in place.
        js.Literal keyExpression = _visit(key);
        js.Expression valueExpression =
            _reference(constant.values[valueIndex++]);
        properties.add(new js.Property(keyExpression, valueExpression));
      }
      if (valueIndex != constant.values.length) {
        compiler.internalError("Bad value count.");
      }
      return new js.ObjectInitializer(properties);
    }

    void badFieldCountError() {
      compiler.internalError(
          "Compiler and ConstantMap disagree on number of fields.");
    }

    ClassElement classElement = constant.type.element;

    List<js.Expression> arguments = <js.Expression>[];

    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    classElement.implementation.forEachInstanceField(
        (ClassElement enclosing, Element field) {
          if (field.name == MapConstant.LENGTH_NAME) {
            arguments.add(
                new js.LiteralNumber('${constant.keys.entries.length}'));
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

    return new js.New(
        new js.VariableUse(getJsConstructor(classElement)),
        arguments);
  }

  js.Expression visitType(TypeConstant constant) {
    SourceString helperSourceName = const SourceString('createRuntimeType');
    Element helper = compiler.findHelper(helperSourceName);
    JavaScriptBackend backend = compiler.backend;
    String helperName = backend.namer.getName(helper);
    DartType type = constant.representedType;
    Element element = type.element;
    String typeName;
    if (type.kind == TypeKind.INTERFACE) {
      typeName =
          backend.rti.getStringRepresentation(type, expandRawType: true);
    } else {
      assert(type.kind == TypeKind.TYPEDEF);
      typeName = element.name.slowToString();
    }
    return new js.Call(
        new js.PropertyAccess.field(
            new js.VariableUse(namer.CURRENT_ISOLATE),
            helperName),
        [new js.LiteralString("'$typeName'")]);
  }

  js.Expression visitConstructed(ConstructedConstant constant) {
    return new js.New(
        new js.VariableUse(getJsConstructor(constant.type.element)),
        _array(constant.fields));
  }

  List<js.Expression> _array(List<Constant> values) {
    List<js.Expression> valueList = <js.Expression>[];
    for (int i = 0; i < values.length; i++) {
      valueList.add(_reference(values[i]));
    }
    return valueList;
  }
}
