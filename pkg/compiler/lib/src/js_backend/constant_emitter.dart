// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

typedef jsAst.Expression _ConstantReferenceGenerator(ConstantValue constant);

typedef jsAst.Expression _ConstantListGenerator(jsAst.Expression array);

/**
 * Generates the JavaScript expressions for constants.
 *
 * It uses a given [constantReferenceGenerator] to reference nested constants
 * (if there are some). It is hence up to that function to decide which
 * constants should be inlined or not.
 */
class ConstantEmitter
    implements ConstantValueVisitor<jsAst.Expression, Null> {

  // Matches blank lines, comment lines and trailing comments that can't be part
  // of a string.
  static final RegExp COMMENT_RE =
      new RegExp(r'''^ *(//.*)?\n|  *//[^''"\n]*$''' , multiLine: true);

  final Compiler compiler;
  final Namer namer;
  final _ConstantReferenceGenerator constantReferenceGenerator;
  final _ConstantListGenerator makeConstantList;

  /**
   * The given [constantReferenceGenerator] function must, when invoked with a
   * constant, either return a reference or return its literal expression if it
   * can be inlined.
   */
  ConstantEmitter(
      this.compiler,
      this.namer,
      jsAst.Expression this.constantReferenceGenerator(ConstantValue constant),
      this.makeConstantList);

  DiagnosticReporter get reporter => compiler.reporter;

  /**
   * Constructs a literal expression that evaluates to the constant. Uses a
   * canonical name unless the constant can be emitted multiple times (as for
   * numbers and strings).
   */
  jsAst.Expression generate(ConstantValue constant) {
    return _visit(constant);
  }

  jsAst.Expression _visit(ConstantValue constant) {
    return constant.accept(this, null);
  }

  @override
  jsAst.Expression visitFunction(FunctionConstantValue constant, [_]) {
    reporter.internalError(NO_LOCATION_SPANNABLE,
        "The function constant does not need specific JS code.");
    return null;
  }

  @override
  jsAst.Expression visitNull(NullConstantValue constant, [_]) {
    return new jsAst.LiteralNull();
  }

  static final _exponentialRE = new RegExp(
      '^'
      '\([-+]?\)'         // 1: sign
      '\([0-9]+\)'        // 2: leading digit(s)
      '\(\.\([0-9]*\)\)?' // 4: fraction digits
      'e\([-+]?[0-9]+\)'  // 5: exponent with sign
      r'$');

  /// Reduces the size of exponential representations when minification is
  /// enabled.
  ///
  /// Removes the "+" after the exponential sign, and removes the "." before the
  /// "e". For example `1.23e+5` is changed to `123e3`.
  String _shortenExponentialRepresentation(String numberString) {
    Match match = _exponentialRE.firstMatch(numberString);
    if (match == null) return numberString;
    String sign = match[1];
    String leadingDigits = match[2];
    String fractionDigits = match[4];
    int exponent = int.parse(match[5]);
    if (fractionDigits == null) fractionDigits = '';
    exponent -= fractionDigits.length;
    String result = '${sign}${leadingDigits}${fractionDigits}e${exponent}';
    assert(double.parse(result) == double.parse(numberString));
    return result;
  }

  @override
  jsAst.Expression visitInt(IntConstantValue constant, [_]) {
    int primitiveValue = constant.primitiveValue;
    // Since we are in JavaScript we can shorten long integers to their shorter
    // exponential representation, for example: "1e4" is shorter than "10000".
    //
    // Note that this shortening apparently loses precision for big numbers
    // (like 1234567890123456789012345 which becomes 12345678901234568e8).
    // However, since JavaScript engines represent all numbers as doubles, these
    // digits are lost anyway.
    String representation = primitiveValue.toString();
    String alternative = null;
    int cutoff = compiler.enableMinification ? 10000 : 1e10.toInt();
    if (primitiveValue.abs() >= cutoff) {
      alternative = _shortenExponentialRepresentation(
          primitiveValue.toStringAsExponential());
    }
    if (alternative != null && alternative.length < representation.length) {
      representation = alternative;
    }
    return new jsAst.LiteralNumber(representation);
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
      String shortened = _shortenExponentialRepresentation("$value");
      return new jsAst.LiteralNumber(shortened);
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
    List<jsAst.Expression> elements = constant.entries
        .map(constantReferenceGenerator)
        .toList(growable: false);
    jsAst.ArrayInitializer array = new jsAst.ArrayInitializer(elements);
    jsAst.Expression value = makeConstantList(array);
    return maybeAddTypeArguments(constant.type, value);
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
            constantReferenceGenerator(constant.values[i]);
        properties.add(new jsAst.Property(keyExpression, valueExpression));
      }
      return new jsAst.ObjectInitializer(properties);
    }

    jsAst.Expression jsGeneralMap() {
      List<jsAst.Expression> data = <jsAst.Expression>[];
      for (int i = 0; i < constant.keys.length; i++) {
        jsAst.Expression keyExpression = constantReferenceGenerator(constant.keys[i]);
        jsAst.Expression valueExpression =
            constantReferenceGenerator(constant.values[i]);
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
            arguments.add(constantReferenceGenerator(constant.keyList));
          } else if (field.name == JavaScriptMapConstant.PROTO_VALUE) {
            assert(constant.protoValue != null);
            arguments.add(constantReferenceGenerator(constant.protoValue));
          } else if (field.name == JavaScriptMapConstant.JS_DATA_NAME) {
            arguments.add(jsGeneralMap());
          } else {
            reporter.internalError(field,
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
      reporter.internalError(classElement,
          "Compiler and ${className} disagree on number of fields.");
    }

    jsAst.Expression constructor =
        backend.emitter.constructorAccess(classElement);
    jsAst.Expression value = new jsAst.New(constructor, arguments);
    return maybeAddTypeArguments(constant.type, value);
  }

  JavaScriptBackend get backend => compiler.backend;

  jsAst.PropertyAccess getHelperProperty(Element helper) {
    return backend.emitter.staticFunctionAccess(helper);
  }

  @override
  jsAst.Expression visitType(TypeConstantValue constant, [_]) {
    DartType type = constant.representedType;
    jsAst.Name typeName = namer.runtimeTypeName(type.element);
    return new jsAst.Call(getHelperProperty(backend.getCreateRuntimeType()),
                          [js.quoteName(typeName)]);
  }

  @override
  jsAst.Expression visitInterceptor(InterceptorConstantValue constant, [_]) {
    ClassElement interceptorClass = constant.dispatchedType.element;
    return backend.emitter.interceptorPrototypeAccess(interceptorClass);
  }

  @override
  jsAst.Expression visitSynthetic(SyntheticConstantValue constant, [_]) {
    switch (constant.kind) {
      case SyntheticConstantKind.DUMMY_INTERCEPTOR:
      case SyntheticConstantKind.EMPTY_VALUE:
        return new jsAst.LiteralNumber('0');
      case SyntheticConstantKind.TYPEVARIABLE_REFERENCE:
      case SyntheticConstantKind.NAME:
        return constant.payload;
      default:
        reporter.internalError(NO_LOCATION_SPANNABLE,
                               "Unexpected DummyConstantKind ${constant.kind}");
        return null;
    }
  }

  @override
  jsAst.Expression visitConstructed(ConstructedConstantValue constant, [_]) {
    Element element = constant.type.element;
    if (backend.isForeign(element)
        && element.name == 'JS_CONST') {
      StringConstantValue str = constant.fields.values.single;
      String value = str.primitiveValue.slowToString();
      return new jsAst.LiteralExpression(stripComments(value));
    }
    jsAst.Expression constructor =
        backend.emitter.constructorAccess(constant.type.element);
    List<jsAst.Expression> fields =
        constant.fields.values.map(constantReferenceGenerator)
        .toList(growable: false);
    jsAst.New instantiation = new jsAst.New(constructor, fields);
    return maybeAddTypeArguments(constant.type, instantiation);
  }

  String stripComments(String rawJavaScript) {
    return rawJavaScript.replaceAll(COMMENT_RE, '');
  }

  jsAst.Expression maybeAddTypeArguments(InterfaceType type,
                                         jsAst.Expression value) {
    if (type is InterfaceType &&
        !type.treatAsRaw &&
        backend.classNeedsRti(type.element)) {
      InterfaceType interface = type;
      RuntimeTypes rti = backend.rti;
      Iterable<jsAst.Expression> arguments = interface.typeArguments
          .map((DartType type) =>
              rti.getTypeRepresentationWithPlaceholders(type, (_){}));
      jsAst.Expression argumentList =
          new jsAst.ArrayInitializer(arguments.toList());
      return new jsAst.Call(getHelperProperty(backend.getSetRuntimeTypeInfo()),
                            [value, argumentList]);
    }
    return value;
  }

  @override
  jsAst.Expression visitDeferred(DeferredConstantValue constant, [_]) {
    return constantReferenceGenerator(constant.referenced);
  }
}
