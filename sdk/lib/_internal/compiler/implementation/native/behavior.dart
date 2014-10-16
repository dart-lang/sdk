// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of native;

/// This class is a temporary work-around until we get a more powerful DartType.
class SpecialType {
final String name;
const SpecialType._(this.name);

/// The type Object, but no subtypes:
static const JsObject = const SpecialType._('=Object');

int get hashCode => name.hashCode;
}

/**
 * A summary of the behavior of a native element.
 *
 * Native code can return values of one type and cause native subtypes of
 * another type to be instantiated.  By default, we compute both from the
 * declared type.
 *
 * A field might yield any native type that 'is' the field type.
 *
 * A method might create and return instances of native subclasses of its
 * declared return type, and a callback argument may be called with instances of
 * the callback parameter type (e.g. Event).
 *
 * If there is one or more `@Creates` annotations, the union of the named types
 * replaces the inferred instantiated type, and the return type is ignored for
 * the purpose of inferring instantiated types.
 *
 *     @Creates('IDBCursor')    // Created asynchronously.
 *     @Creates('IDBRequest')   // Created synchronously (for return value).
 *     IDBRequest openCursor();
 *
 * If there is one or more `@Returns` annotations, the union of the named types
 * replaces the declared return type.
 *
 *     @Returns('IDBRequest')
 *     IDBRequest openCursor();
 *
 * Types in annotations are non-nullable, so include `@Returns('Null')` if
 * `null` may be returned.
 */
class NativeBehavior {

  /// [DartType]s or [SpecialType]s returned or yielded by the native element.
  final List typesReturned = [];

  /// [DartType]s or [SpecialType]s instantiated by the native element.
  final List typesInstantiated = [];

  // If this behavior is for a JS expression, [codeTemplate] contains the
  // parsed tree.
  js.Template codeTemplate;

  final SideEffects sideEffects = new SideEffects.empty();

  static NativeBehavior NONE = new NativeBehavior();

  /// Processes the type specification string of a call to JS and stores the
  /// result in the [typesReturned] and [typesInstantiated].
  ///
  /// Two forms of the string is supported:
  /// 1) A single type string of the form 'void', '', 'var' or 'T1|...|Tn'
  ///    which defines the types returned and for the later form also created by
  ///    the call to JS.
  /// 2) A sequence of the form '<tag>:<type-string>;' where <tag> is either
  ///    'returns' or 'creates' and where <type-string> is a type string like in
  ///    1). The type string marked by 'returns' defines the types returned and
  ///    'creates' defines the types created by the call to JS. Each tag kind
  ///    can only occur once in the sequence.
  ///
  /// [specString] is the specification string, [resolveType] resolves named
  /// types into type values, [typesReturned] and [typesInstantiated] collects
  /// the types defined by the specification string, and [objectType] and
  /// [nullType] define the types for `Object` and `Null`, respectively. The
  /// latter is used for the type strings of the form '' and 'var'.
  // TODO(johnniwinther): Use ';' as a separator instead of a terminator.
  static void processSpecString(
      DiagnosticListener listener,
      Spannable spannable,
      String specString,
      {dynamic resolveType(String typeString),
       List typesReturned, List typesInstantiated,
       objectType, nullType}) {

    /// Resolve a type string of one of the three forms:
    /// *  'void' - in which case [onVoid] is called,
    /// *  '' or 'var' - in which case [onVar] is called,
    /// *  'T1|...|Tn' - in which case [onType] is called for each Ti.
    void resolveTypesString(String typesString,
                            {onVoid(), onVar(), onType(type)}) {
      // Various things that are not in fact types.
      if (typesString == 'void') {
        if (onVoid != null) {
          onVoid();
        }
        return;
      }
      if (typesString == '' || typesString == 'var') {
        if (onVar != null) {
          onVar();
        }
        return;
      }
      for (final typeString in typesString.split('|')) {
        onType(resolveType(typeString));
      }
    }

    if (specString.contains(':')) {
      /// Find and remove a substring of the form 'tag:<type-string>;' from
      /// [specString].
      String getTypesString(String tag) {
        String marker = '$tag:';
        int startPos = specString.indexOf(marker);
        if (startPos == -1) return null;
        int endPos = specString.indexOf(';', startPos);
        if (endPos == -1) return null;
        String typeString =
            specString.substring(startPos + marker.length, endPos);
        specString = '${specString.substring(0, startPos)}'
                     '${specString.substring(endPos + 1)}'.trim();
        return typeString;
      }

      String returns = getTypesString('returns');
      if (returns != null) {
        resolveTypesString(returns, onVar: () {
          typesReturned.add(objectType);
          typesReturned.add(nullType);
        }, onType: (type) {
          typesReturned.add(type);
        });
      }

      String creates = getTypesString('creates');
      if (creates != null) {
        resolveTypesString(creates, onVoid: () {
          listener.internalError(spannable,
              "Invalid type string 'creates:$creates'");
        }, onVar: () {
          listener.internalError(spannable,
              "Invalid type string 'creates:$creates'");
        }, onType: (type) {
          typesInstantiated.add(type);
        });
      }

      if (!specString.isEmpty) {
        listener.internalError(spannable, "Invalid JS type string.");
      }
    } else {
      resolveTypesString(specString, onVar: () {
        typesReturned.add(objectType);
        typesReturned.add(nullType);
      }, onType: (type) {
        typesInstantiated.add(type);
        typesReturned.add(type);
      });
    }
  }

  static NativeBehavior ofJsCall(Send jsCall, Compiler compiler, resolver) {
    // The first argument of a JS-call is a string encoding various attributes
    // of the code.
    //
    //  'Type1|Type2'.  A union type.
    //  '=Object'.      A JavaScript Object, no subtype.

    var argNodes = jsCall.arguments;
    if (argNodes.isEmpty) {
      compiler.internalError(jsCall, "JS expression has no type.");
    }

    var code = argNodes.tail.head;
    if (code is !StringNode || code.isInterpolation) {
      compiler.internalError(code, 'JS code must be a string literal.');
    }

    LiteralString specLiteral = argNodes.head.asLiteralString();
    if (specLiteral == null) {
      // TODO(sra): We could accept a type identifier? e.g. JS(bool, '1<2').  It
      // is not very satisfactory because it does not work for void, dynamic.
      compiler.internalError(argNodes.head, "Unexpected JS first argument.");
    }

    NativeBehavior behavior = new NativeBehavior();
    behavior.codeTemplate =
        js.js.parseForeignJS(code.dartString.slowToString());
    new SideEffectsVisitor(behavior.sideEffects)
        .visit(behavior.codeTemplate.ast);

    String specString = specLiteral.dartString.slowToString();

    resolveType(String typeString) {
      return _parseType(
          typeString,
          compiler,
          (name) => resolver.resolveTypeFromString(specLiteral, name),
          jsCall);
    }

    processSpecString(compiler, jsCall,
                      specString,
                      resolveType: resolveType,
                      typesReturned: behavior.typesReturned,
                      typesInstantiated: behavior.typesInstantiated,
                      objectType: compiler.objectClass.computeType(compiler),
                      nullType: compiler.nullClass.computeType(compiler));

    return behavior;
  }

  static NativeBehavior ofJsEmbeddedGlobalCall(Send jsGlobalCall,
                                               Compiler compiler,
                                               resolver) {
    // The first argument of a JS-embedded global call is a string encoding
    // the type of the code.
    //
    //  'Type1|Type2'.  A union type.
    //  '=Object'.      A JavaScript Object, no subtype.

    Link<Node> argNodes = jsGlobalCall.arguments;
    if (argNodes.isEmpty) {
      compiler.internalError(jsGlobalCall,
          "JS embedded global expression has no type.");
    }

    // We don't check the given name. That needs to be done at a later point.
    // This is, because we want to allow non-literals as names.
    if (argNodes.tail.isEmpty) {
      compiler.internalError(jsGlobalCall, 'Embedded Global is missing name');
    }

    if (!argNodes.tail.tail.isEmpty) {
      compiler.internalError(argNodes.tail.tail.head,
          'Embedded Global has more than 2 arguments');
    }

    LiteralString specLiteral = argNodes.head.asLiteralString();
    if (specLiteral == null) {
      // TODO(sra): We could accept a type identifier? e.g. JS(bool, '1<2').  It
      // is not very satisfactory because it does not work for void, dynamic.
      compiler.internalError(argNodes.head, "Unexpected first argument.");
    }

    NativeBehavior behavior = new NativeBehavior();

    String specString = specLiteral.dartString.slowToString();

    resolveType(String typeString) {
      return _parseType(
          typeString,
          compiler,
          (name) => resolver.resolveTypeFromString(specLiteral, name),
          jsGlobalCall);
    }

    processSpecString(compiler, jsGlobalCall,
                      specString,
                      resolveType: resolveType,
                      typesReturned: behavior.typesReturned,
                      typesInstantiated: behavior.typesInstantiated,
                      objectType: compiler.objectClass.computeType(compiler),
                      nullType: compiler.nullClass.computeType(compiler));

    return behavior;
  }

  static NativeBehavior ofMethod(FunctionElement method, Compiler compiler) {
    FunctionType type = method.computeType(compiler);
    var behavior = new NativeBehavior();
    behavior.typesReturned.add(type.returnType);
    if (!type.returnType.isVoid) {
      // Declared types are nullable.
      behavior.typesReturned.add(compiler.nullClass.computeType(compiler));
    }
    behavior._capture(type, compiler);

    // TODO(sra): Optional arguments are currently missing from the
    // DartType. This should be fixed so the following work-around can be
    // removed.
    method.functionSignature.forEachOptionalParameter(
        (ParameterElement parameter) {
          behavior._escape(parameter.type, compiler);
        });

    behavior._overrideWithAnnotations(method, compiler);
    return behavior;
  }

  static NativeBehavior ofFieldLoad(Element field, Compiler compiler) {
    DartType type = field.computeType(compiler);
    var behavior = new NativeBehavior();
    behavior.typesReturned.add(type);
    // Declared types are nullable.
    behavior.typesReturned.add(compiler.nullClass.computeType(compiler));
    behavior._capture(type, compiler);
    behavior._overrideWithAnnotations(field, compiler);
    return behavior;
  }

  static NativeBehavior ofFieldStore(Element field, Compiler compiler) {
    DartType type = field.computeType(compiler);
    var behavior = new NativeBehavior();
    behavior._escape(type, compiler);
    // We don't override the default behaviour - the annotations apply to
    // loading the field.
    return behavior;
  }

  void _overrideWithAnnotations(Element element, Compiler compiler) {
    if (element.metadata.isEmpty) return;

    DartType lookup(String name) {
      Element e = element.buildScope().lookup(name);
      if (e == null) return null;
      if (e is! ClassElement) return null;
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      return cls.thisType;
    }

    NativeEnqueuer enqueuer = compiler.enqueuer.resolution.nativeEnqueuer;
    var creates = _collect(element, compiler, enqueuer.annotationCreatesClass,
                           lookup);
    var returns = _collect(element, compiler, enqueuer.annotationReturnsClass,
                           lookup);

    if (creates != null) {
      typesInstantiated..clear()..addAll(creates);
    }
    if (returns != null) {
      typesReturned..clear()..addAll(returns);
    }
  }

  /**
   * Returns a list of type constraints from the annotations of
   * [annotationClass].
   * Returns `null` if no constraints.
   */
  static _collect(Element element, Compiler compiler, Element annotationClass,
                  lookup(str)) {
    var types = null;
    for (Link<MetadataAnnotation> link = element.metadata;
         !link.isEmpty;
         link = link.tail) {
      MetadataAnnotation annotation = link.head.ensureResolved(compiler);
      ConstantValue value = annotation.constant.value;
      if (!value.isConstructedObject) continue;
      ConstructedConstantValue constructedObject = value;
      if (constructedObject.type.element != annotationClass) continue;

      List<ConstantValue> fields = constructedObject.fields;
      // TODO(sra): Better validation of the constant.
      if (fields.length != 1 || !fields[0].isString) {
        PartialMetadataAnnotation partial = annotation;
        compiler.internalError(annotation,
            'Annotations needs one string: ${partial.parseNode(compiler)}');
      }
      StringConstantValue specStringConstant = fields[0];
      String specString = specStringConstant.toDartString().slowToString();
      for (final typeString in specString.split('|')) {
        var type = _parseType(typeString, compiler, lookup, annotation);
        if (types == null) types = [];
        types.add(type);
      }
    }
    return types;
  }

  /// Models the behavior of having intances of [type] escape from Dart code
  /// into native code.
  void _escape(DartType type, Compiler compiler) {
    type = type.unalias(compiler);
    if (type is FunctionType) {
      FunctionType functionType = type;
      // A function might be called from native code, passing us novel
      // parameters.
      _escape(functionType.returnType, compiler);
      for (DartType parameter in functionType.parameterTypes) {
        _capture(parameter, compiler);
      }
    }
  }

  /// Models the behavior of Dart code receiving instances and methods of [type]
  /// from native code.  We usually start the analysis by capturing a native
  /// method that has been used.
  void _capture(DartType type, Compiler compiler) {
    type = type.unalias(compiler);
    if (type is FunctionType) {
      FunctionType functionType = type;
      _capture(functionType.returnType, compiler);
      for (DartType parameter in functionType.parameterTypes) {
        _escape(parameter, compiler);
      }
    } else {
      typesInstantiated.add(type);
    }
  }

  static _parseType(String typeString, Compiler compiler,
      lookup(name), locationNodeOrElement) {
    if (typeString == '=Object') return SpecialType.JsObject;
    if (typeString == 'dynamic') {
      return const DynamicType();
    }
    DartType type = lookup(typeString);
    if (type != null) return type;

    int index = typeString.indexOf('<');
    if (index < 1) {
      compiler.internalError(
          _errorNode(locationNodeOrElement, compiler),
          "Type '$typeString' not found.");
    }
    type = lookup(typeString.substring(0, index));
    if (type != null)  {
      // TODO(sra): Parse type parameters.
      return type;
    }
    compiler.internalError(
        _errorNode(locationNodeOrElement, compiler),
        "Type '$typeString' not found.");
  }

  static _errorNode(locationNodeOrElement, compiler) {
    if (locationNodeOrElement is Node) return locationNodeOrElement;
    return locationNodeOrElement.parseNode(compiler);
  }
}
