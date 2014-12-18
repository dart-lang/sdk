// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class ConstantEmitter {
  ConstantReferenceEmitter _referenceEmitter;
  ConstantLiteralEmitter _literalEmitter;

  ConstantEmitter(Compiler compiler,
                  Namer namer,
                  jsAst.Template makeConstantListTemplate) {
    _literalEmitter = new ConstantLiteralEmitter(
        compiler, namer, makeConstantListTemplate, this);
    _referenceEmitter = new ConstantReferenceEmitter(compiler, namer, this);
  }

  /**
   * Constructs an expression that is a reference to the constant.  Uses a
   * canonical name unless the constant can be emitted multiple times (as for
   * numbers and strings).
   */
  jsAst.Expression reference(ConstantValue constant) {
    return _referenceEmitter.generate(constant);
  }

  /**
   * Constructs a literal expression that evaluates to the constant. Uses a
   * canonical name unless the constant can be emitted multiple times (as for
   * numbers and strings).
   */
  jsAst.Expression literal(ConstantValue constant) {
    return _literalEmitter.generate(constant);
  }

  /**
   * Constructs an expression like [reference], but the expression is valid
   * during isolate initialization.
   */
  jsAst.Expression referenceInInitializationContext(ConstantValue constant) {
    return _referenceEmitter.generate(constant);
  }

  /**
   * Constructs an expression used to initialize a canonicalized constant.
   */
  jsAst.Expression initializationExpression(ConstantValue constant) {
    return _literalEmitter.generate(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions to refer to [ConstantValue]s.
 * Do not use directly, use methods from [ConstantEmitter].
 */
class ConstantReferenceEmitter
    implements ConstantValueVisitor<jsAst.Expression, Null> {
  final Compiler compiler;
  final Namer namer;

  final ConstantEmitter constantEmitter;

  ConstantReferenceEmitter(this.compiler, this.namer, this.constantEmitter);

  JavaScriptBackend get backend => compiler.backend;

  jsAst.Expression generate(ConstantValue constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(ConstantValue constant) {
    return constant.accept(this, null);
  }

  jsAst.Expression emitCanonicalVersion(ConstantValue constant) {
    String name = namer.constantName(constant);
    return new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(namer.globalObjectForConstant(constant)), name);
  }

  jsAst.Expression literal(ConstantValue constant) {
      return constantEmitter.literal(constant);
  }

  @override
  jsAst.Expression visitFunction(FunctionConstantValue constant, [_]) {
    return backend.emitter.isolateStaticClosureAccess(constant.element);
  }

  @override
  jsAst.Expression visitNull(NullConstantValue constant, [_]) {
    return literal(constant);
  }

  @override
  jsAst.Expression visitInt(IntConstantValue constant, [_]) {
    return literal(constant);
  }

  @override
  jsAst.Expression visitDouble(DoubleConstantValue constant, [_]) {
    return literal(constant);
  }

  @override
  jsAst.Expression visitBool(BoolConstantValue constant, [_]) {
    return literal(constant);
  }

  /**
   * Write the contents of the quoted string to a [CodeBuffer] in
   * a form that is valid as JavaScript string literal content.
   * The string is assumed quoted by double quote characters.
   */
  @override
  jsAst.Expression visitString(StringConstantValue constant, [_]) {
    // TODO(sra): If the string is long *and repeated* (and not on a hot path)
    // then it should be assigned to a name.  We don't have reference counts (or
    // profile information) here, so this is the wrong place.
    return literal(constant);
  }

  @override
  jsAst.Expression visitList(ListConstantValue constant, [_]) {
    return emitCanonicalVersion(constant);
  }

  @override
  jsAst.Expression visitMap(MapConstantValue constant, [_]) {
    return emitCanonicalVersion(constant);
  }

  @override
  jsAst.Expression visitType(TypeConstantValue constant, [_]) {
    return emitCanonicalVersion(constant);
  }

  @override
  jsAst.Expression visitConstructed(ConstructedConstantValue constant, [_]) {
    return emitCanonicalVersion(constant);
  }

  @override
  jsAst.Expression visitInterceptor(InterceptorConstantValue constant, [_]) {
    return emitCanonicalVersion(constant);
  }

  @override
  jsAst.Expression visitDummy(DummyConstantValue constant, [_]) {
    return literal(constant);
  }

  @override
  jsAst.Expression visitDeferred(DeferredConstantValue constant, [_]) {
    return emitCanonicalVersion(constant);
  }
}

/**
 * Visitor for generating JavaScript expressions that litterally represent
 * [ConstantValue]s. These can be used for inlining constants or in
 * initializers. Do not use directly, use methods from [ConstantEmitter].
 */
class ConstantLiteralEmitter
    implements ConstantValueVisitor<jsAst.Expression, Null> {

  // Matches blank lines, comment lines and trailing comments that can't be part
  // of a string.
  static final RegExp COMMENT_RE =
      new RegExp(r'''^ *(//.*)?\n|  *//[^''"\n]*$''' , multiLine: true);

  final Compiler compiler;
  final Namer namer;
  final jsAst.Template makeConstantListTemplate;
  final ConstantEmitter constantEmitter;

  ConstantLiteralEmitter(this.compiler,
                         this.namer,
                         this.makeConstantListTemplate,
                         this.constantEmitter);

  jsAst.Expression generate(ConstantValue constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(ConstantValue constant) {
    return constant.accept(this, null);
  }

  @override
  jsAst.Expression visitFunction(FunctionConstantValue constant, [_]) {
    compiler.internalError(NO_LOCATION_SPANNABLE,
        "The function constant does not need specific JS code.");
    return null;
  }

  @override
  jsAst.Expression visitNull(NullConstantValue constant, [_]) {
    return new jsAst.LiteralNull();
  }

  @override
  jsAst.Expression visitInt(IntConstantValue constant, [_]) {
    return new jsAst.LiteralNumber('${constant.primitiveValue}');
  }

  @override
  jsAst.Expression visitDouble(DoubleConstantValue constant, [_]) {
    double value = constant.primitiveValue;
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

  @override
  jsAst.Expression visitBool(BoolConstantValue constant, [_]) {
    if (compiler.enableMinification) {
      if (constant.isTrue) {
        // Use !0 for true.
        return js("!0");
      } else {
        // Use !1 for false.
        return js("!1");
      }
    } else {
      return constant.isTrue ? js('true') : js('false');
    }
  }

  /**
   * Write the contents of the quoted string to a [CodeBuffer] in
   * a form that is valid as JavaScript string literal content.
   * The string is assumed quoted by double quote characters.
   */
  @override
  jsAst.Expression visitString(StringConstantValue constant, [_]) {
    StringBuffer sb = new StringBuffer();
    writeJsonEscapedCharsOn(constant.primitiveValue.slowToString(), sb);
    return new jsAst.LiteralString('"$sb"');
  }

  @override
  jsAst.Expression visitList(ListConstantValue constant, [_]) {
    List<jsAst.Expression> elements = _array(constant.entries);
    jsAst.ArrayInitializer array = new jsAst.ArrayInitializer(elements);
    jsAst.Expression value = makeConstantListTemplate.instantiate([array]);
    return maybeAddTypeArguments(constant.type, value);
  }

  jsAst.Expression getJsConstructor(ClassElement element) {
    return backend.emitter.classAccess(element);
  }

  @override
  jsAst.Expression visitMap(JavaScriptMapConstant constant, [_]) {
    jsAst.Expression jsMap() {
      List<jsAst.Property> properties = <jsAst.Property>[];
      for (int i = 0; i < constant.length; i++) {
        StringConstantValue key = constant.keys[i];
        if (key.primitiveValue == JavaScriptMapConstant.PROTO_PROPERTY) {
          continue;
        }

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
      return new jsAst.ArrayInitializer(data);
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
    return backend.emitter.staticFunctionAccess(helper);
  }

  @override
  jsAst.Expression visitType(TypeConstantValue constant, [_]) {
    DartType type = constant.representedType;
    String name = namer.getRuntimeTypeName(type.element);
    jsAst.Expression typeName = new jsAst.LiteralString("'$name'");
    return new jsAst.Call(getHelperProperty(backend.getCreateRuntimeType()),
                          [typeName]);
  }

  @override
  jsAst.Expression visitInterceptor(InterceptorConstantValue constant, [_]) {
    return new jsAst.PropertyAccess.field(
        getJsConstructor(constant.dispatchedType.element),
        'prototype');
  }

  @override
  jsAst.Expression visitDummy(DummyConstantValue constant, [_]) {
    return new jsAst.LiteralNumber('0');
  }

  @override
  jsAst.Expression visitConstructed(ConstructedConstantValue constant, [_]) {
    Element element = constant.type.element;
    if (element.isForeign(backend)
        && element.name == 'JS_CONST') {
      StringConstantValue str = constant.fields[0];
      String value = str.primitiveValue.slowToString();
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

  List<jsAst.Expression> _array(List<ConstantValue> values) {
    return values.map(constantEmitter.reference).toList(growable: false);
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

  @override
  jsAst.Expression visitDeferred(DeferredConstantValue constant, [_]) {
    return constantEmitter.reference(constant.referenced);
  }
}
