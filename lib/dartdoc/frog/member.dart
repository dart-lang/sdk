// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A formal parameter to a [Method]. */
class Parameter {
  FormalNode definition;
  Member method;

  String name;
  Type type;
  bool isInitializer = false;

  Value value;

  Parameter(this.definition, this.method);

  resolve() {
    name = definition.name.name;
    if (name.startsWith('this.')) {
      name = name.substring(5);
      isInitializer = true;
    }

    type = method.resolveType(definition.type, false, true);

    if (definition.value != null) {
      // To match VM, detect cases where value was not actually specified in
      // code and don't signal errors.
      // TODO(jimhug): Clean up after issue #352 is resolved.
      if (!hasDefaultValue) return;

      if (method.name == ':call') {
        // TODO(jimhug): Need simpler way to detect "true" function types vs.
        //   regular methods being used as function types for closures.
        // TODO(sigmund): Disallow non-null default values for native calls?
        var methodDef = method.definition;
        if (methodDef.body == null && !method.isNative) {
          world.error('default value not allowed on function type',
              definition.span);
        }
      } else if (method.isAbstract) {
        world.error('default value not allowed on abstract methods',
            definition.span);
      }
    } else if (isInitializer && !method.isConstructor) {
      world.error('initializer parameters only allowed on constructors',
          definition.span);
    }
  }

  genValue(MethodMember method, CallingContext context) {
    if (definition.value == null || value != null) return;

    // TODO(jmesserly): what should we do when context is not a MethodGenerator?
    if (context is MethodGenerator) {
      MethodGenerator gen = context;
      value = definition.value.visit(gen);
      if (!value.isConst) {
        world.error('default parameter values must be constant', value.span);
      }
      value = value.convertTo(context, type);
    }
  }

  Parameter copyWithNewType(Member newMethod, Type newType) {
    var ret = new Parameter(definition, newMethod);
    ret.type = newType;
    ret.name = name;
    ret.isInitializer = isInitializer;
    return ret;
  }

  bool get isOptional() => definition != null && definition.value != null;

  /**
   * Gets whether this named parameter has an explicit default value or relies
   * on the implicit `null`.
   */
  bool get hasDefaultValue() =>
    definition.value.span.start != definition.span.start;
}


class Member extends Element {
  final Type declaringType;

  Member genericMember;

  // A root string for getter and setter names.  This is used e.g. to ensure
  // that fields with the same Dart name but different jsnames (due to native
  // name directives) still have a common getter name.  Is null when there is no
  // renaming.
  String _jsnameRoot;

  Member(String name, Type declaringType)
      : this.declaringType = declaringType,
        super(name, declaringType);

  String mangleJsName() {
    var mangled = super.mangleJsName();
    if (declaringType != null && declaringType.isTop) {
      return JsNames.getValid(mangled);
    } else {
      // We don't need to mangle native member names unless
      // they contain illegal characters.
      return (isNative && !name.contains(':')) ? name : mangled;
    }
  }

  abstract bool get isStatic();
  abstract Type get returnType();

  abstract bool get canGet();
  abstract bool get canSet();

  Library get library() => declaringType.library;

  bool get isPrivate() => name !== null && name.startsWith('_');

  bool get isConstructor() => false;
  bool get isField() => false;
  bool get isMethod() => false;
  bool get isProperty() => false;
  bool get isAbstract() => false;

  bool get isFinal() => false;

  // TODO(jmesserly): these only makes sense on methods, but because of
  // ConcreteMember we need to support them on Member.
  bool get isConst() => false;
  bool get isFactory() => false;

  bool get isOperator() => name.startsWith(':');
  bool get isCallMethod() => name == ':call';

  bool get requiresPropertySyntax() => false;
  bool _provideGetter = false;
  bool _provideSetter = false;

  bool get isNative() => false;
  String get constructorName() {
    world.internalError('cannot be a constructor', span);
  }

  void provideGetter() {}
  void provideSetter() {}

  String get jsnameOfGetter() => 'get\$$jsnameRoot';
  String get jsnameOfSetter() => 'set\$$jsnameRoot';
  String get jsnameRoot() => _jsnameRoot != null ? _jsnameRoot : _jsname;

  Member get initDelegate() {
    world.internalError('cannot have initializers', span);
  }
  void set initDelegate(ctor) {
    world.internalError('cannot have initializers', span);
  }

  Value computeValue() {
    world.internalError('cannot have value', span);
  }

  /**
   * The inferred returnType. Right now this is just used to track
   * non-nullable bools.
   */
  Type get inferredResult() {
    var t = returnType;
    if (t.isBool && (library.isCore || library.isCoreImpl)) {
      // We trust our core libraries not to return null from bools.
      // I hope this trust is well placed!
      return world.nonNullBool;
    }
    return t;
  }

  Definition get definition() => null;

  List<Parameter> get parameters() => [];

  MemberSet _preciseMemberSet, _potentialMemberSet;

  MemberSet get preciseMemberSet() {
    if (_preciseMemberSet === null) {
      _preciseMemberSet = new MemberSet(this);
    }
    return _preciseMemberSet;
  }

  MemberSet get potentialMemberSet() {
    // TODO(jimhug): This needs one more redesign - move to TypeSets...

    if (_potentialMemberSet === null) {
      if (name == ':call') {
        _potentialMemberSet = preciseMemberSet;
        return _potentialMemberSet;
      }

      final mems = new Set<Member>();
      if (declaringType.isClass) mems.add(this);

      for (var subtype in declaringType.genericType.subtypes) {
        if (!subtype.isClass) continue;
        var mem = subtype.members[name];
        if (mem !== null) {
          if (mem.isDefinedOn(declaringType)) {
            mems.add(mem);
          }
        } else if (!declaringType.isClass) {
          // Handles weird interface case.
          mem = subtype.getMember(name);
          if (mem !== null && mem.isDefinedOn(declaringType)) {
            mems.add(mem);
          }
        }
      }

      if (mems.length != 0) {
        // TODO(jimhug): This hack needs to be rationalized.
        for (var mem in mems) {
          if (declaringType.genericType != declaringType &&
              mem.genericMember != null && mems.contains(mem.genericMember)) {
            //world.info('skip ${name} on ${mem.genericMember.declaringType.name}' +
            //  ' because we have on ${mem.declaringType.name} for ${declaringType.name}');
            mems.remove(mem.genericMember);
          }
        }


        for (var mem in mems) {
          if (_potentialMemberSet === null) {
            _potentialMemberSet = new MemberSet(mem);
          } else {
            _potentialMemberSet.add(mem);
          }
        }
      }
    }
    return _potentialMemberSet;
  }

  // If I have an object of [type] could I be invoking this member?
  bool isDefinedOn(Type type) {
    if (type.isClass) {
      if (declaringType.isSubtypeOf(type)) {
        return true;
      } else if (type.isSubtypeOf(declaringType)) {
        // maybe - but not if overridden somewhere
        // TODO(jimhug): This lookup is not great for perf of this method.
        return type.getMember(name) == this;
      } else {
        return false;
      }
    } else {
       if (declaringType.isSubtypeOf(type)) {
         return true;
       } else {
         // If this is an interface, the actual implementation may
         // come from a class that does not implement this interface.
         for (var t in declaringType.subtypes) {
           if (t.isSubtypeOf(type) && t.getMember(name) == this) {
             return true;
           }
         }
         return false;
       }
    }
  }

  abstract Value _get(CallingContext context, Node node, Value target);

  abstract Value _set(CallingContext context, Node node, Value target,
      Value value);


  bool canInvoke(CallingContext context, Arguments args) {
    // Any gettable member whose return type is callable can be "invoked".
    if (canGet && (isField || isProperty)) {
      return this.returnType.isFunction || this.returnType.isVar ||
        this.returnType.getCallMethod() != null;
    }
    return false;
  }

  Value invoke(CallingContext context, Node node, Value target,
    Arguments args) {
    var newTarget = _get(context, node, target);
    return newTarget.invoke(context, ':call', node, args);
  }

  bool override(Member other) {
    if (isStatic) {
      world.error('static members cannot hide parent members',
          span, other.span);
      return false;
    } else if (other.isStatic) {
      world.error('cannot override static member', span, other.span);
      return false;
    }
    return true;
  }

  String get generatedFactoryName() {
    assert(this.isFactory);
    String prefix = '${declaringType.genericType.jsname}.${constructorName}\$';
    if (name == '') {
      return '${prefix}factory';
    } else {
      return '${prefix}$name\$factory';
    }
  }

  int hashCode() {
    final typeCode = declaringType == null ? 1 : declaringType.hashCode();
    final nameCode = isConstructor ? constructorName.hashCode() :
      name.hashCode();
    return (typeCode << 4) ^ nameCode;
  }

  bool operator ==(other) {
    return other is Member && isConstructor == other.isConstructor &&
        declaringType == other.declaringType && (isConstructor ?
            constructorName == other.constructorName : name == other.name);
  }

  /** Overriden to ensure that type arguments aren't used in static mems. */
  Type resolveType(TypeReference node, bool typeErrors, bool allowTypeParams) {
    allowTypeParams = allowTypeParams && !(isStatic && !isFactory);

    return super.resolveType(node, typeErrors, allowTypeParams);
  }

  // TODO(jimhug): Make this abstract.
  Member makeConcrete(Type concreteType) {
    world.internalError('cannot make this concrete', span);
  }
}


/**
 * Types are treated as first class members of their library's top type.
 */
// TODO(jmesserly): perhaps Type should extend Member, but that can get
// complicated.
class TypeMember extends Member {
  final DefinedType type;

  TypeMember(DefinedType type)
      : super(type.name, type.library.topType),
        this.type = type;

  SourceSpan get span() => type.definition === null ? null : type.definition.span;

  bool get isStatic() => true;

  // If this really becomes first class, this should return typeof(Type)
  Type get returnType() => world.varType;

  bool canInvoke(CallingContext context, Arguments args) => false;
  bool get canGet() => true;
  bool get canSet() => false;

  Value _get(CallingContext context, Node node, Value target) {
    return new TypeValue(type, node.span);
  }

  Value _set(CallingContext context, Node node, Value target, Value value) {
    world.error('cannot set type', node.span);
  }

  Value invoke(CallingContext context, Node node, Value target,
      Arguments args) {
    world.error('cannot invoke type', node.span);
  }
}

/** Represents a Dart field from source code. */
class FieldMember extends Member {
  final VariableDefinition definition;
  final Expression value;

  Type type;
  Value _computedValue;

  bool isStatic;
  bool isFinal;
  final bool isNative;

  // TODO(jimhug): Better notion of fields that need special handling...
  bool get overridesProperty() {
    if (isStatic) return false;

    if (declaringType.parent != null) {
      var p = declaringType.parent.getProperty(name);
      if (p != null && p.isProperty) return true;
      if (p is FieldMember && p != this) return p.overridesProperty;
    }
    return false;
  }

  bool override(Member other) {
    if (!super.override(other)) return false;

    // According to the specification, fields can override properties
    // and other fields.
    if (other.isProperty || other.isField) {
      // TODO(jimhug):
      // other.returnType.ensureAssignableFrom(returnType, null, true);
      return true;
      // TODO(jimhug): Merge in overridesProperty logic here.
    } else {
      world.error('field can only override field or property',
          span, other.span);
      return false;
    }
  }

  void provideGetter() {
    _provideGetter = true;
    if (genericMember !== null) {
      genericMember.provideGetter();
    }
  }

  void provideSetter() {
    _provideSetter = true;
    if (genericMember !== null) {
      genericMember.provideSetter();
    }
  }

  FieldMember(String name, Type declaringType, this.definition, this.value,
              [bool this.isNative = false])
      : super(name, declaringType);

  Member makeConcrete(Type concreteType) {
    var ret = new FieldMember(name, concreteType, definition, value);
    ret.genericMember = this;
    ret._jsname = _jsname;
    return ret;
  }

  SourceSpan get span() => definition == null ? null : definition.span;

  Type get returnType() => type;

  bool get canGet() => true;
  bool get canSet() => !isFinal;

  bool get isField() => true;

  resolve() {
    isStatic = declaringType.isTop;
    isFinal = false;
    if (definition.modifiers != null) {
      for (var mod in definition.modifiers) {
        if (mod.kind == TokenKind.STATIC) {
          if (isStatic) {
            world.error('duplicate static modifier', mod.span);
          }
          isStatic = true;
        } else if (mod.kind == TokenKind.FINAL) {
          if (isFinal) {
            world.error('duplicate final modifier', mod.span);
          }
          isFinal = true;
        } else {
          world.error('${mod} modifier not allowed on field', mod.span);
        }
      }
    }
    type = resolveType(definition.type, false, true);

    if (isStatic && isFinal && value == null) {
      world.error('static final field is missing initializer', span);
    }

    if (declaringType.isClass) library._addMember(this);
  }


  bool _computing = false;
  /** Generates the initial value for this field, if any. Marks it as used. */
  Value computeValue() {
    if (value == null) return null;

    if (_computedValue == null) {
      if (_computing) {
        world.error('circular reference', value.span);
        return null;
      }
      _computing = true;
      var finalMethod = new MethodMember('final_context', declaringType, null);
      finalMethod.isStatic = true;
      var finalGen = new MethodGenerator(finalMethod, null);
      _computedValue = value.visit(finalGen);
      if (!_computedValue.isConst) {
        if (isStatic) {
          world.error(
            'non constant static field must be initialized in functions',
            value.span);
        } else {
          world.error(
              'non constant field must be initialized in constructor',
              value.span);
        }
      }


      if (isStatic) {
        if (isFinal && _computedValue.isConst) {
          ; // keep const as is here
        } else {
          _computedValue = world.gen.globalForStaticField(
              this, _computedValue, [_computedValue]);
        }
      }
      _computing = false;
    }
    return _computedValue;
  }

  Value _get(CallingContext context, Node node, Value target) {
    if (!context.needsCode) {
      return new PureStaticValue(type, node.span, isStatic && isFinal);
    }

    if (isNative && returnType != null) {
      returnType.markUsed();
      if (returnType is DefinedType) {
        // TODO(jmesserly): this handles native fields that return types like
        // "List". Is there a better solution for fields? Unlike methods we have
        // no good way to annotate them.
        var defaultType = returnType.genericType.defaultType;
        if (defaultType != null && defaultType.isNative) {
          defaultType.markUsed();
        }
      }
    }

    if (isStatic) {
      // TODO(jmesserly): can we avoid generating the whole type?
      declaringType.markUsed();

      // Make sure to compute the value of all static fields, even if we don't
      // use this value immediately.
      var cv = computeValue();
      if (isFinal) {
        return cv;
      }
      world.gen.hasStatics = true;
      if (declaringType.isTop) {
        return new Value(type, '\$globals.$jsname', node.span);
      } else if (declaringType.isNative) {
        if (declaringType.isHiddenNativeType) {
          // TODO: Could warn at parse time.
          world.error('static field of hidden native type is inaccessible',
              node.span);
        }
        return new Value(type, '${declaringType.jsname}.$jsname', node.span);
      } else {
        return new Value(type,
            '\$globals.${declaringType.jsname}_$jsname', node.span);
      }
    }
    return new Value(type, '${target.code}.$jsname', node.span);
  }

  Value _set(CallingContext context, Node node, Value target, Value value) {
    if (!context.needsCode) {
      // TODO(jimhug): Add type checks here.
      return new PureStaticValue(type, node.span);
    }

    var lhs = _get(context, node, target);
    value = value.convertTo(context, type);
    return new Value(type, '${lhs.code} = ${value.code}', node.span);
  }
}

class PropertyMember extends Member {
  MethodMember getter;
  MethodMember setter;

  Member _overriddenField;

  // TODO(jimhug): What is the right span for this beast?
  SourceSpan get span() => getter != null ? getter.span : null;

  bool get canGet() => getter != null;
  bool get canSet() => setter != null;

  // If the property is just a declaration in an interface, continue to allow
  // field syntax in the generated code.
  bool get requiresPropertySyntax() => declaringType.isClass;

  // When overriding native fields, we still provide a field syntax to ensure
  // that native functions will find the appropriate property implementation.
  // TODO(sigmund): should check for this transitively...
  bool get needsFieldSyntax() =>
      _overriddenField != null &&
      _overriddenField.isNative &&
      // Can't put property on hidden native class...
      !_overriddenField.declaringType.isHiddenNativeType
      ;

  // TODO(jimhug): Union of getter and setters sucks!
  bool get isStatic() => getter == null ? setter.isStatic : getter.isStatic;

  bool get isProperty() => true;

  Type get returnType() {
    return getter == null ? setter.returnType : getter.returnType;
  }

  PropertyMember(String name, Type declaringType): super(name, declaringType);

  Member makeConcrete(Type concreteType) {
    var ret = new PropertyMember(name, concreteType);
    if (getter !== null) ret.getter = getter.makeConcrete(concreteType);
    if (setter !== null) ret.setter = setter.makeConcrete(concreteType);
    ret._jsname = _jsname;
    return ret;
  }

  bool override(Member other) {
    if (!super.override(other)) return false;

    // properties can override other properties and fields
    if (other.isProperty || other.isField) {
      // TODO(jimhug):
      // other.returnType.ensureAssignableFrom(returnType, null, true);
      if (other.isProperty) addFromParent(other);
      else _overriddenField = other;
      return true;
    } else {
      world.error('property can only override field or property',
          span, other.span);
      return false;
    }
  }

  Value _get(CallingContext context, Node node, Value target) {
    if (getter == null) {
      if (_overriddenField != null) {
        return _overriddenField._get(context, node, target);
      }
      return target.invokeNoSuchMethod(context, 'get:$name', node);
    }
    return getter.invoke(context, node, target, Arguments.EMPTY);
  }

  Value _set(CallingContext context, Node node, Value target, Value value) {
    if (setter == null) {
      if (_overriddenField != null) {
        return _overriddenField._set(context, node, target, value);
      }
      return target.invokeNoSuchMethod(context, 'set:$name', node,
        new Arguments(null, [value]));
    }
    return setter.invoke(context, node, target, new Arguments(null, [value]));
  }

  addFromParent(Member parentMember) {
    final parent = parentMember;

    if (getter == null) getter = parent.getter;
    if (setter == null) setter = parent.setter;
  }

  resolve() {
    if (getter != null) {
      getter.resolve();
      if (getter.parameters.length != 0) {
        world.error('getter methods should take no arguments',
            getter.definition.span);
      }
      if (getter.returnType.isVoid) {
        world.warning('getter methods should not be void',
            getter.definition.returnType.span);
      }
    }
    if (setter != null) {
      setter.resolve();
      if (setter.parameters.length != 1) {
        world.error('setter methods should take a single argument',
            setter.definition.span);
      }
      // Not issue warning if setter is implicitly dynamic (returnType == null),
      // but do if it is explicit (returnType.isVar)
      if (!setter.returnType.isVoid && setter.definition.returnType != null) {
        world.warning('setter methods should be void',
            setter.definition.returnType.span);
      }
    }

    if (declaringType.isClass) library._addMember(this);
  }
}


/** Represents a Dart method or top-level function. */
class MethodMember extends Member {
  FunctionDefinition definition;
  Type returnType;
  List<Parameter> parameters;

  MethodData _methodData;

  Type _functionType;
  bool isStatic = false;
  bool isAbstract = false;

  // Note: these two modifiers are only legal on constructors
  bool isConst = false;
  bool isFactory = false;

  /** True if this is a function defined inside another method. */
  final bool isLambda;

  /**
   * True if we should provide info on optional parameters for use by runtime
   * dispatch.
   */
  bool _provideOptionalParamInfo = false;

  /*
   * When this is a constructor, contains any other constructor called during
   * initialization (if any).
   */
  Member initDelegate;

  bool _hasNativeBody = false;

  static final kIdentifierRegExp = const RegExp(@'^[a-zA-Z][a-zA-Z_$0-9]*$');

  MethodMember(String name, Type declaringType, this.definition)
      : isLambda = false, super(name, declaringType) {
    if (isNative) {
      // Parse the native string.  The the native string can be a native name
      // (identifier) or a chunk of JavaScript code.
      //
      //  foo() native 'bar';      // The native method is called 'bar'.
      //  foo() native 'return 1'; // Defines method with native implementation.
      //
      if (kIdentifierRegExp.hasMatch(definition.nativeBody)) {
        _jsname = definition.nativeBody;
        // Prevent the compiler from using the name for a regular Dart member.
        world._addHazardousMemberName(_jsname);
      }
      _hasNativeBody = definition.nativeBody != '' &&
                       definition.nativeBody != _jsname;
    }
  }

  MethodMember.lambda(String name, Type declaringType, this.definition)
      : isLambda = true, super(name, declaringType);

  Member makeConcrete(Type concreteType) {
    var _name = isConstructor ? concreteType.name : name;
    var ret = new MethodMember(_name, concreteType, definition);
    ret.genericMember = this;
    ret._jsname = _jsname;
    return ret;
  }

  MethodData get methodData() {
    if (genericMember !== null) return genericMember.dynamic.methodData;

    if (_methodData === null) {
      _methodData = new MethodData(this);
    }
    return _methodData;
  }

  bool get isConstructor() => name == declaringType.name;
  bool get isMethod() => !isConstructor;

  bool get isNative() {
    if (definition == null) return false;
    return definition.nativeBody != null;
  }

  bool get hasNativeBody() => _hasNativeBody;

  bool get canGet() => true;
  bool get canSet() => false;

  bool get requiresPropertySyntax() => true;

  SourceSpan get span() => definition == null ? null : definition.span;

  String get constructorName() {
    var returnType = definition.returnType;
    if (returnType == null) return '';
    if (returnType is GenericTypeReference) {
      return '';
    }

    // TODO(jmesserly): make this easier?
    if (returnType.names != null) {
      return returnType.names[0].name;
    } else if (returnType.name != null) {
      return returnType.name.name;
    }
    world.internalError('no valid constructor name', definition.span);
  }

  Type get functionType() {
    if (_functionType == null) {
      _functionType = library.getOrAddFunctionType(declaringType, name,
          definition, methodData);
      // TODO(jimhug): Better resolution checks.
      if (parameters == null) {
        resolve();
      }
    }
    return _functionType;
  }

  bool override(Member other) {
    if (!super.override(other)) return false;

    // methods can only override other methods
    if (other.isMethod) {
      // TODO(jimhug):
      // other.returnType.ensureAssignableFrom(returnType, null, true);
      // TODO(jimhug): Check for further parameter compatibility.
      return true;
    } else {
      world.error('method can only override methods', span, other.span);
      return false;
    }
  }

  bool canInvoke(CallingContext context, Arguments args) {
    int bareCount = args.bareCount;

    if (bareCount > parameters.length) return false;

    if (bareCount == parameters.length) {
      if (bareCount != args.length) return false;
    } else {
      if (!parameters[bareCount].isOptional) return false;

      for (int i = bareCount; i < args.length; i++) {
        if (indexOfParameter(args.getName(i)) < 0) {
          return false;
        }
      }
    }

    return true;
  }

  // TODO(jmesserly): might need to make this faster
  /** Gets the index of an optional parameter. */
  int indexOfParameter(String name) {
    for (int i = 0; i < parameters.length; i++) {
      final p = parameters[i];
      if (p.isOptional && p.name == name) {
        return i;
      }
    }
    return -1;
  }

  void provideGetter() { _provideGetter = true; }
  void provideSetter() { _provideSetter = true; }

  Value _set(CallingContext context, Node node, Value target, Value value) {
    world.error('cannot set method', node.span);
  }

  Value _get(CallingContext context, Node node, Value target) {
    if (!context.needsCode) {
      return new PureStaticValue(functionType, node.span);
    }

    // TODO(jimhug): Would prefer to invoke!
    declaringType.genMethod(this);
    _provideOptionalParamInfo = true;
    if (isStatic) {
      // ensure the type is generated.
      // TODO(sigmund): can we avoid generating the entire type, but only what
      // we need?
      declaringType.markUsed();
      var type = declaringType.isTop ? '' : '${declaringType.jsname}.';
      return new Value(functionType, '$type$jsname', node.span);
    }
    _provideGetter = true;
    return new Value(functionType, '${target.code}.$jsnameOfGetter()', node.span);
  }

  /**
   * Checks if the named arguments are in their natural or 'home' positions,
   * i.e. they may be passed directly without inserting, deleting or moving the
   * arguments to correspond with the parameters.
   */
  bool namesInHomePositions(Arguments args) {
    if (!args.hasNames) return true;

    for (int i = args.bareCount; i < args.values.length; i++) {
      if (i >= parameters.length) {
        return false;
      }
      if (args.getName(i) != parameters[i].name) {
        return false;
      }
    }
    return true;
  }

  bool namesInOrder(Arguments args) {
    if (!args.hasNames) return true;

    int lastParameter = null;
    for (int i = args.bareCount; i < parameters.length; i++) {
      var p = args.getIndexOfName(parameters[i].name);
      // Only worry about parameters that needTemps. Otherwise it's fine to
      // reorder.
      if (p >= 0 && args.values[p].needsTemp) {
        if (lastParameter != null && lastParameter > p) {
          return false;
        }
        lastParameter = p;
      }
    }
    return true;
  }

  /** Returns true if any of the arguments will need conversion. */
  // TODO(jmesserly): I don't like how this is coupled to invoke
  bool needsArgumentConversion(Arguments args) {
    int bareCount = args.bareCount;
    for (int i = 0; i < bareCount; i++) {
      var arg = args.values[i];
      if (arg.needsConversion(parameters[i].type)) {
        return true;
      }
    }

    if (bareCount < parameters.length) {
      for (int i = bareCount; i < parameters.length; i++) {
        var arg = args.getValue(parameters[i].name);
        if (arg != null && arg.needsConversion(parameters[i].type)) {
          return true;
        }
      }
    }

    return false;
  }

  /** Returns true if any of the parameters are optional. */
  bool hasOptionalParameters() {
    return parameters.some((Parameter p) => p.isOptional);
  }

  String _tooManyArgumentsMsg(int actual, int expected) {
    return hasOptionalParameters()
        ? 'too many arguments, expected at most $expected but found $actual'
        : _wrongArgumentCountMsg(actual, expected);
  }

  String _tooFewArgumentsMsg(int actual, int expected) {
    return hasOptionalParameters()
        ? 'too few arguments, expected at least $expected but found $actual'
        : _wrongArgumentCountMsg(actual, expected);
  }

  String _wrongArgumentCountMsg(int actual, int expected) {
    return 'wrong number of arguments, expected $expected but found $actual';
  }

  Value _argError(CallingContext context, Node node, Value target,
      Arguments args, String msg, int argIndex) {
    if (context.showWarnings) {
      SourceSpan span;
      if ((args.nodes == null) || (argIndex >= args.nodes.length)) {
        span = node.span;
      } else {
        span = args.nodes[argIndex].span;
      }
      if (isStatic || isConstructor) {
        world.error(msg, span);
      } else {
        world.warning(msg, span);
      }
    }
    return target.invokeNoSuchMethod(context, name, node, args);
  }

  genParameterValues(CallingContext context) {
    // TODO(jimhug): Is this the right context?
    if (context.needsCode) {
      for (var p in parameters) p.genValue(this, context);
    }
  }

  /**
   * Invokes this method on the given [target] with the given [args].
   * [node] provides a [SourceSpan] for any error messages.
   */
  Value invoke(CallingContext context, Node node, Value target,
      Arguments args) {

    var argValues = <Value>[];
    int bareCount = args.bareCount;
    for (int i = 0; i < bareCount; i++) {
      var arg = args.values[i];
      if (i >= parameters.length) {
        var msg = _tooManyArgumentsMsg(args.length, parameters.length);
        return _argError(context, node, target, args, msg, i);
      }
      argValues.add(arg.convertTo(context, parameters[i].type));
    }

    int namedArgsUsed = 0;
    if (bareCount < parameters.length) {
      genParameterValues(context);

      for (int i = bareCount; i < parameters.length; i++) {
        var param = parameters[i];
        var arg = args.getValue(param.name);
        if (arg == null) {
          arg = param.value;
          if (arg == null) {
            // TODO(jmesserly): should we be use the actual constant value here?
            arg = new PureStaticValue(param.type, param.definition.span, true);
          }
        } else {
          arg = arg.convertTo(context, parameters[i].type);
          namedArgsUsed++;
        }

        if (arg == null || !parameters[i].isOptional) {
          var msg = _tooFewArgumentsMsg(Math.min(i, args.length), i + 1);
          return _argError(context, node, target, args, msg, i);
        } else {
          argValues.add(arg);
        }
      }
    }

    if (namedArgsUsed < args.nameCount) {
      // Find the unused argument name
      var seen = new Set<String>();
      for (int i = bareCount; i < args.length; i++) {
        var name = args.getName(i);
        if (seen.contains(name)) {
          return _argError(context, node, target, args,
              'duplicate argument "$name"', i);
        }
        seen.add(name);
        int p = indexOfParameter(name);
        if (p < 0) {
          return _argError(context, node, target, args,
              'method does not have optional parameter "$name"', i);
        } else if (p < bareCount) {
          return _argError(context, node, target, args,
              'argument "$name" passed as positional and named',
              // Given that the named was mentioned explicitly, highlight the
              // positional location instead:
              p);
        }
      }
      world.internalError('wrong named arguments calling $name', node.span);
    }

    if (!context.needsCode) {
      return new PureStaticValue(returnType, node.span);
    }

    declaringType.genMethod(this);

    if (isStatic || isFactory) {
      // TODO(sigmund): can we avoid generating the entire type, but only what
      // we need?
      declaringType.markUsed();
    }

    // TODO(jmesserly): get rid of this in favor of using the native method
    // "bodies" to tell the compiler about valid return types.
    if (isNative && returnType != null) returnType.markUsed();

    if (!namesInOrder(args)) {
      // Names aren't in order. For now, use a var call because it's an
      // easy way to get the right eval order for out of order arguments.
      // TODO(jmesserly): temps would be better.
      return context.findMembers(name).invokeOnVar(context, node, target, args);
    }

    var argsCode = argValues.map((v) => v.code);
    if (!target.isType && (isConstructor || target.isSuper)) {
      argsCode.insertRange(0, 1, 'this');
    }
    if (bareCount < parameters.length) {
      Arguments.removeTrailingNulls(argsCode);
    }
    var argsString = Strings.join(argsCode, ', ');

    if (isConstructor) {
      return _invokeConstructor(context, node, target, args, argsString);
    }

    if (target.isSuper) {
      return new Value(inferredResult,
          '${declaringType.jsname}.prototype.$jsname.call($argsString)',
          node.span);
    }

    if (isOperator) {
      return _invokeBuiltin(context, node, target, args, argsCode);
    }

    if (isFactory) {
      assert(target.isType);
      return new Value(target.type, '$generatedFactoryName($argsString)',
          node !== null ? node.span : null);
    }

    if (isStatic) {
      if (declaringType.isTop) {
        return new Value(inferredResult,
            '$jsname($argsString)', node !== null ? node.span : null);
      }
      return new Value(inferredResult,
          '${declaringType.jsname}.$jsname($argsString)', node.span);
    }

    // TODO(jmesserly): factor this better
    if (name == 'get:typeName' && declaringType.library.isDomOrHtml) {
      world.gen.corejs.ensureTypeNameOf();
    }

    var code = '${target.code}.$jsname($argsString)';
    return new Value(inferredResult, code, node.span);
  }

  Value _invokeConstructor(CallingContext context, Node node,
      Value target, Arguments args, argsString) {
    declaringType.markUsed();

    String ctor = constructorName;
    if (ctor != '') ctor = '.${ctor}\$ctor';

    final span = node != null ? node.span : target.span;
    if (!target.isType) {
      // initializer call to another constructor
      var code = '${declaringType.nativeName}${ctor}.call($argsString)';
      return new Value(target.type, code, span);
    } else {
      // Start of abstract interpretation to replace const hacks goes here
      // TODO(jmesserly): using the "node" here feels really hacky
      if (isConst && node is NewExpression && node.dynamic.isConst) {
        // TODO(jimhug): Embedding JSSyntaxRegExp works around an annoying
        //   issue with tracking native constructors for const objects.
        if (isNative || declaringType.name == 'JSSyntaxRegExp') {
          // check that all args are const?
          var code = 'new ${declaringType.nativeName}${ctor}($argsString)';
          return world.gen.globalForConst(new Value(target.type, code, span),
            [args.values]);
        }
        var newType = declaringType;
        var newObject = new ObjectValue(true, newType, span);
        newObject.initFields();
        _evalConstConstructor(newObject, args);
        return world.gen.globalForConst(newObject, [args.values]);
      } else {
        var code = 'new ${declaringType.nativeName}${ctor}($argsString)';
        return new Value(target.type, code, span);
      }
    }
  }

  _evalConstConstructor(Value newObject, Arguments args) {
    declaringType.markUsed();
    methodData.eval(this, newObject, args);
  }

  Value _invokeBuiltin(CallingContext context, Node node, Value target,
      Arguments args, argsCode) {
    // Handle some fast paths for Number, String, List and DOM.
    if (target.type.isNum) {
      // TODO(jimhug): This fails in bad ways when argsCode[1] is not num.
      // TODO(jimhug): What about null?
      var code = null;
      if (args.length == 0) {
        if (name == ':negate') {
          code = '-${target.code}';
        } else if (name == ':bit_not') {
          code = '~${target.code}';
        }
      } else if (args.length == 1 && args.values[0].type.isNum) {
        if (name == ':truncdiv' || name == ':mod') {
          world.gen.corejs.useOperator(name);
          code = '$jsname\$(${target.code}, ${argsCode[0]})';
        } else {
          var op = TokenKind.rawOperatorFromMethod(name);
          code = '${target.code} $op ${argsCode[0]}';
        }
      }
      if (code !== null) {
        return new Value(inferredResult, code, node.span);
      }
    } else if (target.type.isString) {
      if (name == ':index' && args.values[0].type.isNum) {
        return new Value(declaringType, '${target.code}[${argsCode[0]}]',
          node.span);
      } else if (name == ':add' && args.values[0].type.isNum) {
        return new Value(declaringType, '${target.code} + ${argsCode[0]}',
          node.span);
      }
    } else if (declaringType.isNative && options.disableBoundsChecks) {
      if (args.length > 0 && args.values[0].type.isNum) {
        if (name == ':index') {
          return new Value(returnType,
            '${target.code}[${argsCode[0]}]', node.span);
        } else if (name == ':setindex') {
          return new Value(returnType,
              '${target.code}[${argsCode[0]}] = ${argsCode[1]}', node.span);
        }
      }
    }

    // TODO(jimhug): Optimize null on lhs as well.
    if (name == ':eq' || name == ':ne') {
      final op = name == ':eq' ? '==' : '!=';

      if (name == ':ne') {
        // Ensure == is generated.
        target.invoke(context, ':eq', node, args);
      }

      // Optimize test when null is on the rhs.
      if (argsCode[0] == 'null') {
        return new Value(inferredResult, '${target.code} $op null', node.span);
      } else if (target.type.isNum || target.type.isString) {
        // TODO(jimhug): Maybe check rhs.
        return new Value(inferredResult, '${target.code} $op ${argsCode[0]}',
            node.span);
      }
      world.gen.corejs.useOperator(name);
      // TODO(jimhug): Should be able to use faster path sometimes here!
      return new Value(inferredResult,
          '$jsname\$(${target.code}, ${argsCode[0]})', node.span);
    }

    if (isCallMethod) {
      declaringType.markUsed();
      return new Value(inferredResult,
          '${target.code}(${Strings.join(argsCode, ", ")})', node.span);
    }

    // TODO(jimhug): Reconcile with MethodSet version - ideally just eliminate
    if (name == ':index') {
      world.gen.corejs.useIndex = true;
    } else if (name == ':setindex') {
      world.gen.corejs.useSetIndex = true;
    } else {
      world.gen.corejs.useOperator(name);
      var argsString = argsCode.length == 0 ? '' : ', ${argsCode[0]}';
      return new Value(returnType, '$jsname\$(${target.code}${argsString})',
        node.span);
    }

    // Fall back to normal method invocation.
    var argsString = Strings.join(argsCode, ', ');
    return new Value(inferredResult, '${target.code}.$jsname($argsString)',
        node.span);
  }

  resolve() {
    // TODO(jimhug): work through side-by-side with spec
    isStatic = declaringType.isTop;
    isConst = false;
    isFactory = false;
    isAbstract = !declaringType.isClass;
    if (definition.modifiers != null) {
      for (var mod in definition.modifiers) {
        if (mod.kind == TokenKind.STATIC) {
          if (isStatic) {
            world.error('duplicate static modifier', mod.span);
          }
          isStatic = true;
        } else if (isConstructor && mod.kind == TokenKind.CONST) {
          if (isConst) {
            world.error('duplicate const modifier', mod.span);
          }
          if (isFactory) {
            world.error('const factory not allowed', mod.span);
          }
          isConst = true;
        } else if (mod.kind == TokenKind.FACTORY) {
          if (isFactory) {
            world.error('duplicate factory modifier', mod.span);
          }
          if (isConst) {
            world.error('const factory not allowed', mod.span);
          }
          if (isStatic) {
            world.error('static factory not allowed', mod.span);
          }
          isFactory = true;
        } else if (mod.kind == TokenKind.ABSTRACT) {
          if (isAbstract) {
            if (declaringType.isClass) {
              world.error('duplicate abstract modifier', mod.span);
            } else if (!isCallMethod) {
              world.error('abstract modifier not allowed on interface members',
                mod.span);
            }
          }
          isAbstract = true;
        } else {
          world.error('${mod} modifier not allowed on method', mod.span);
        }
      }
    }

    if (isFactory) {
      isStatic = true;
    }

    // TODO(jimhug): need a better annotation for being an operator method
    if (isOperator && isStatic && !isCallMethod) {
      world.error('operator method may not be static "${name}"', span);
    }

    if (isAbstract) {
      if (definition.body != null &&
          declaringType.definition is! FunctionTypeDefinition) {
        // TODO(jimhug): Creating function types for concrete methods is
        //   steadily feeling uglier...
        world.error('abstract method cannot have a body', span);
      }
      if (isStatic &&
          declaringType.definition is! FunctionTypeDefinition) {
        world.error('static method cannot be abstract', span);
      }
    } else {
      if (definition.body == null && !isConstructor && !isNative) {
        world.error('method needs a body', span);
      }
    }

    if (isConstructor && !isFactory) {
      returnType = declaringType;
    } else {
      // This is the one and only place we allow void.
      if (definition.returnType is SimpleTypeReference &&
          definition.returnType.dynamic.type == world.voidType) {
        returnType = world.voidType;
      } else {
        returnType = resolveType(definition.returnType, false, !isStatic);
      }
    }
    parameters = [];
    for (var formal in definition.formals) {
      // TODO(jimhug): Clean up construction of Parameters.
      var param = new Parameter(formal, this);
      param.resolve();
      parameters.add(param);
    }

    if (!isLambda && declaringType.isClass) {
      library._addMember(this);
    }
  }
}


/**
 * A [FactoryMap] maps type names to a list of factory constructors.
 * The constructors list is actually a map that maps factory names to
 * [MethodMember]. The reason why we need both indirections are:
 * 1) A class can define factory methods for multiple interfaces.
 * 2) A factory constructor can have a name.
 *
 * For example:
 *
 * [:
 * interface I factory A {
 *   I();
 *   I.foo();
 * }
 *
 * interface I2 factory A {
 *   I2();
 * }
 *
 * class A {
 *   factory I() { ... }     // Member1
 *   factory I.foo() { ... } // Member2
 *   factory I2() { ... }    // Member3
 *   factory A() { ... }     // Member4
 * }
 * :]
 *
 * The [:factories:] field of A will be a [FactoryMap] that looks
 * like:
 * { "I"  : { "": Member1, "foo": Member2 },
 *   "I2" : { "": Member3 },
 *   "A"  : { "", Member4 }
 * }
 */
class FactoryMap {
  Map<String, Map<String, Member>> factories;

  FactoryMap() : factories = {};

  // Returns the factories defined for [type].
  Map<String, Member> getFactoriesFor(String typeName) {
    var ret = factories[typeName];
    if (ret == null) {
      ret = {};
      factories[typeName] = ret;
    }
    return ret;
  }

  void addFactory(String typeName, String name, Member member) {
    getFactoriesFor(typeName)[name] = member;
  }

  Member getFactory(String typeName, String name) {
    return getFactoriesFor(typeName)[name];
  }

  void forEach(void f(Member member)) {
    factories.forEach((_, Map constructors) {
      constructors.forEach((_, Member member) {
        f(member);
      });
    });
  }

  bool isEmpty() {
    return factories.getValues()
        .every((Map constructors) => constructors.isEmpty());
  }
}
