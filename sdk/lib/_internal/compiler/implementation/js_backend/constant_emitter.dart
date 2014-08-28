// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class ConstantEmitter {
  ConstantReferenceEmitter _referenceEmitter;
  ConstantLiteralEmitter _literalEmitter;

  ConstantEmitter(Compiler compiler, Namer namer) {
    _literalEmitter = new ConstantLiteralEmitter(compiler, namer, this);
    _referenceEmitter = new ConstantReferenceEmitter(compiler, namer, this);
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
   * Constructs a literal expression that evaluates to the constant. Uses a
   * canonical name unless the constant can be emitted multiple times (as for
   * numbers and strings).
   */
  jsAst.Expression literal(Constant constant) {
    return _literalEmitter.generate(constant);
  }

  /**
   * Constructs an expression like [reference], but the expression is valid
   * during isolate initialization.
   */
  jsAst.Expression referenceInInitializationContext(Constant constant) {
    return _referenceEmitter.generate(constant);
  }

  /**
   * Constructs an expression used to initialize a canonicalized constant.
   */
  jsAst.Expression initializationExpression(Constant constant) {
    return _literalEmitter.generate(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions to refer to [Constant]s.
 * Do not use directly, use methods from [ConstantEmitter].
 */
class ConstantReferenceEmitter implements ConstantVisitor<jsAst.Expression> {
  final Compiler compiler;
  final Namer namer;

  final ConstantEmitter constantEmitter;

  ConstantReferenceEmitter(this.compiler, this.namer, this.constantEmitter);

  jsAst.Expression generate(Constant constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(Constant constant) {
    return constant.accept(this);
  }

  jsAst.Expression emitCanonicalVersion(Constant constant) {
    String name = namer.constantName(constant);
    return new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(namer.globalObjectForConstant(constant)), name);
  }

  jsAst.Expression literal(Constant constant) {
      return constantEmitter.literal(constant);
  }

  jsAst.Expression visitFunction(FunctionConstant constant) {
    return namer.isolateStaticClosureAccess(constant.element);
  }

  jsAst.Expression visitNull(NullConstant constant) {
    return literal(constant);
  }

  jsAst.Expression visitInt(IntConstant constant) {
    return literal(constant);
  }

  jsAst.Expression visitDouble(DoubleConstant constant) {
    return literal(constant);
  }

  jsAst.Expression visitTrue(TrueConstant constant) {
    return literal(constant);
  }

  jsAst.Expression visitFalse(FalseConstant constant) {
    return literal(constant);
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
    return literal(constant);
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

  jsAst.Expression visitDummy(DummyConstant constant) {
    return literal(constant);
  }

  jsAst.Expression visitDeferred(DeferredConstant constant) {
    return emitCanonicalVersion(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions that litterally represent
 * [Constant]s. These can be used for inlining constants or in initializers.
 * Do not use directly, use methods from [ConstantEmitter].
 */
class ConstantLiteralEmitter implements ConstantVisitor<jsAst.Expression> {

  // Matches blank lines, comment lines and trailing comments that can't be part
  // of a string.
  static final RegExp COMMENT_RE =
      new RegExp(r'''^ *(//.*)?\n|  *//[^''"\n]*$''' , multiLine: true);

  final Compiler compiler;
  final Namer namer;
  final ConstantEmitter constantEmitter;

  ConstantLiteralEmitter(this.compiler, this.namer, this.constantEmitter);

  jsAst.Expression generate(Constant constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(Constant constant) {
    return constant.accept(this);
  }

  jsAst.Expression visitFunction(FunctionConstant constant) {
    compiler.internalError(NO_LOCATION_SPANNABLE,
        "The function constant does not need specific JS code.");
    return null;
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
    StringBuffer sb = new StringBuffer();
    writeJsonEscapedCharsOn(constant.value.slowToString(), sb);
    return new jsAst.LiteralString('"$sb"');
  }

  jsAst.Expression visitList(ListConstant constant) {
    jsAst.Expression value = new jsAst.Call(
        new jsAst.PropertyAccess.field(
            new jsAst.VariableUse(namer.isolateName),
            namer.getMappedInstanceName('makeConstantList')),
        [new jsAst.ArrayInitializer.from(_array(constant.entries))]);
    return maybeAddTypeArguments(constant.type, value);
  }

  jsAst.Expression getJsConstructor(ClassElement element) {
    return namer.elementAccess(element);
  }

  jsAst.Expression visitMap(JavaScriptMapConstant constant) {
    jsAst.Expression jsMap() {
      List<jsAst.Property> properties = <jsAst.Property>[];
      for (int i = 0; i < constant.length; i++) {
        StringConstant key = constant.keys[i];
        if (key.value == JavaScriptMapConstant.PROTO_PROPERTY) continue;

        // Keys in literal maps must be emitted in place.
        jsAst.Literal keyExpression = _visit(key);
        jsAst.Expression valueExpression =
            constantEmitter.reference(constant.values[i]);
        properties.add(new jsAst.Property(keyExpression, valueExpression));
      }
      return new jsAst.ObjectInitializer(properties);
    }

    jsAst.Expression jsGeneralMap() {
      List<jsAst.Expression> data = <jsAst.Expression>[];
      for (int i = 0; i < constant.keys.length; i++) {
        jsAst.Expression keyExpression =
            constantEmitter.reference(constant.keys[i]);
        jsAst.Expression valueExpression =
            constantEmitter.reference(constant.values[i]);
        data.add(keyExpression);
        data.add(valueExpression);
      }
      return new jsAst.ArrayInitializer.from(data);
    }

    ClassElement classElement = constant.type.element;
    String className = classElement.name;

    List<jsAst.Expression> arguments = <jsAst.Expression>[];

    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    classElement.implementation.forEachInstanceField(
        (ClassElement enclosing, Element field) {
          if (field.name == JavaScriptMapConstant.LENGTH_NAME) {
            arguments.add(
                new jsAst.LiteralNumber('${constant.keyList.entries.length}'));
          } else if (field.name == JavaScriptMapConstant.JS_OBJECT_NAME) {
            arguments.add(jsMap());
          } else if (field.name == JavaScriptMapConstant.KEYS_NAME) {
            arguments.add(constantEmitter.reference(constant.keyList));
          } else if (field.name == JavaScriptMapConstant.PROTO_VALUE) {
            assert(constant.protoValue != null);
            arguments.add(constantEmitter.reference(constant.protoValue));
          } else if (field.name == JavaScriptMapConstant.JS_DATA_NAME) {
            arguments.add(jsGeneralMap());
          } else {
            compiler.internalError(field,
                "Compiler has unexpected field ${field.name} for "
                "${className}.");
          }
          emittedArgumentCount++;
        },
        includeSuperAndInjectedMembers: true);
    if ((className == JavaScriptMapConstant.DART_STRING_CLASS &&
         emittedArgumentCount != 3) ||
        (className == JavaScriptMapConstant.DART_PROTO_CLASS &&
         emittedArgumentCount != 4) ||
        (className == JavaScriptMapConstant.DART_GENERAL_CLASS &&
         emittedArgumentCount != 1)) {
      compiler.internalError(classElement,
          "Compiler and ${className} disagree on number of fields.");
    }

    jsAst.Expression value =
        new jsAst.New(getJsConstructor(classElement), arguments);
    return maybeAddTypeArguments(constant.type, value);
  }

  JavaScriptBackend get backend => compiler.backend;

  jsAst.PropertyAccess getHelperProperty(Element helper) {
    return backend.namer.elementAccess(helper);
  }

  jsAst.Expression visitType(TypeConstant constant) {
    DartType type = constant.representedType;
    String name = namer.getRuntimeTypeName(type.element);
    jsAst.Expression typeName = new jsAst.LiteralString("'$name'");
    return new jsAst.Call(getHelperProperty(backend.getCreateRuntimeType()),
                          [typeName]);
  }

  jsAst.Expression visitInterceptor(InterceptorConstant constant) {
    return new jsAst.PropertyAccess.field(
        getJsConstructor(constant.dispatchedType.element),
        'prototype');
  }

  jsAst.Expression visitDummy(DummyConstant constant) {
    return new jsAst.LiteralNumber('0');
  }

  jsAst.Expression visitConstructed(ConstructedConstant constant) {
    Element element = constant.type.element;
    if (element.isForeign(backend)
        && element.name == 'JS_CONST') {
      StringConstant str = constant.fields[0];
      String value = str.value.slowToString();
      return new jsAst.LiteralExpression(stripComments(value));
    }
    jsAst.New instantiation = new jsAst.New(
        getJsConstructor(constant.type.element),
        _array(constant.fields));
    return maybeAddTypeArguments(constant.type, instantiation);
  }

  String stripComments(String rawJavaScript) {
    return rawJavaScript.replaceAll(COMMENT_RE, '');
  }

  List<jsAst.Expression> _array(List<Constant> values) {
    List<jsAst.Expression> valueList = <jsAst.Expression>[];
    for (int i = 0; i < values.length; i++) {
      valueList.add(constantEmitter.reference(values[i]));
    }
    return valueList;
  }

  jsAst.Expression maybeAddTypeArguments(InterfaceType type,
                                         jsAst.Expression value) {
    if (type is InterfaceType &&
        !type.treatAsRaw &&
        backend.classNeedsRti(type.element)) {
      InterfaceType interface = type;
      RuntimeTypes rti = backend.rti;
      Iterable<String> arguments = interface.typeArguments
          .map((DartType type) =>
              rti.getTypeRepresentationWithHashes(type, (_){}));
      jsAst.Expression argumentList =
          new jsAst.LiteralString('[${arguments.join(', ')}]');
      return new jsAst.Call(getHelperProperty(backend.getSetRuntimeTypeInfo()),
                            [value, argumentList]);
    }
    return value;
  }

  jsAst.Expression visitDeferred(DeferredConstant constant) {
    return constantEmitter.reference(constant.referenced);
  }
}
