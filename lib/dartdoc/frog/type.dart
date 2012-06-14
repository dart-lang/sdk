// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Type extends Element {
  bool isTested = false;
  bool isChecked = false;
  bool isWritten = false;

  /**
   * For core types (int, String, etc) this is the generated type assertion
   * function (uses JS "typeof"). This field is null for all other types.
   */
  String typeCheckCode;

  Member _typeMember;

  /** Stubs used to call into this method dynamically. */
  Map<String, VarMember> varStubs;

  /** Cache of [Member]s that have been found. */
  Map<String, Member> _foundMembers;

  Type(String name): _foundMembers = {}, varStubs = {}, super(name, null);

  void markUsed() {}
  abstract void genMethod(Member method);

  TypeMember get typeMember() {
    if (_typeMember == null) {
      _typeMember = new TypeMember(this);
    }
    return _typeMember;
  }

  Member getMember(String name) => null;
  abstract MethodMember getConstructor(String name);
  abstract MethodMember getFactory(Type type, String name);
  abstract Type getOrMakeConcreteType(List<Type> typeArgs);
  abstract Map<String, MethodMember> get constructors();
  abstract addDirectSubtype(Type type);
  abstract bool get isClass();
  abstract Library get library();
  Set<Type> get subtypes() => null;

  // TODO(jmesserly): rename to isDynamic?
  bool get isVar() => false;
  bool get isTop() => false;

  bool get isObject() => false;
  bool get isString() => false;
  bool get isBool() => false;
  bool get isFunction() => false;
  bool get isNum() => false;
  bool get isInt() => false;
  bool get isDouble() => false;
  bool get isVoid() => false;

  // True for all types in the Dart type system. We track non-nullabiltity
  // as an optimization for booleans to generate better code in checked mode.
  bool get isNullable() => true;

  // Strangely Dart treats calls on Function much like calls on var.
  bool get isVarOrFunction() => isVar || isFunction;

  bool get isVarOrObject() => isVar || isObject;

  /** Gets the :call method for a function type. */
  MethodMember getCallMethod() => null;

  /** These types may not be implemented or extended by user code. */
  bool get isClosed() => isString || isBool || isNum || isFunction || isVar;

  bool get isUsed() => false;

  bool get isGeneric() => false;

  // Various special bits that we track on native types.
  // Generally controls how prototypes are emitted.
  NativeType get nativeType() => null;
  bool get isHiddenNativeType() =>
      (nativeType != null && nativeType.isConstructorHidden);
  bool get isSingletonNative() =>
      (nativeType != null && nativeType.isSingleton);
  bool get isJsGlobalObject() =>
      (nativeType != null && nativeType.isJsGlobalObject);

  bool get hasTypeParams() => false;

  String get typeofName() => null;

  String get fullname() =>
    library.name !== null ? '${library.name}.$name' : name;

  Map<String, Member> get members() => null;
  Definition get definition() => null;
  FactoryMap get factories() => null;

  List<Type> get typeArgsInOrder() => const [];
  DefinedType get genericType() => this;

  /** Indicates a concrete version of a generic type, such as List<String>. */
  bool get isConcreteGeneric() => genericType != this;

  // TODO(jmesserly): what should these do for ParameterType?
  List<Type> get interfaces() => null;
  Type get parent() => null;

  Map<String, Member> getAllMembers() => {};

  /** The native name of this element if it has one, otherwise the JS name. */
  String get nativeName() => isNative ? definition.nativeType.name : jsname;

  /**
   * Avoid the native name if hidden native. It might exist on some browsers
   * and we want to use it if it does.
   */
  bool get avoidNativeName() => isHiddenNativeType;

  bool _hasNativeSubtypes;
  bool get hasNativeSubtypes() {
    if (_hasNativeSubtypes == null) {
      _hasNativeSubtypes = subtypes.some((t) => t.isNative);
    }
    return _hasNativeSubtypes;
  }

  void _checkExtends() {
    var typeParams = genericType.typeParameters;
    if (typeParams != null) {
      for (int i = 0; i < typeParams.length; i++) {
        if (typeParams[i].extendsType != null) {
          // TODO(jimhug): This dynamic shouldn't be needed...
          typeArgsInOrder[i].dynamic.ensureSubtypeOf(typeParams[i].extendsType,
            typeParams[i].span, false);
        }
      }
    }

    // Parent should be handled by the super constructor call, but we still
    // need to check our interfaces.
    if (interfaces != null) {
      for (var i in interfaces) {
        i._checkExtends();
      }
    }
  }

  void _checkOverride(Member member) {
    // always look in parents to check that any overloads are legal
    var parentMember = _getMemberInParents(member.name);
    if (parentMember != null) {
      // TODO(jimhug): Ensure that this is only done once.
      if (!member.isPrivate || member.library == parentMember.library) {
        member.override(parentMember);
      }
    }
  }

  void _createNotEqualMember() {
    assert(isObject);
    // Add a != method just like the == one.
    MethodMember eq = members[':eq'];
    if (eq == null) {
      // TODO(jmesserly): should this be an error?
      // Frog is being hosted by "utils/css" such that it doesn't have its
      // standard lib initialized properly.
      return;
    }
    final ne = new MethodMember(':ne', this, eq.definition);
    ne.returnType = eq.returnType;
    ne.parameters = eq.parameters;
    ne.isStatic = eq.isStatic;
    ne.isAbstract = eq.isAbstract;
    // TODO - What else to fill in?
    members[':ne'] = ne;
  }

  Member _getMemberInParents(String memberName) {
    // print('getting $memberName in parents of $name, $isClass');
    // Now look in my parents.
    if (isClass) {
      if (parent != null) {
        return parent.getMember(memberName);
      } else {
        return null;
      }
    } else {
      // TODO(jimhug): Will probably check types more than once - errors?
      if (interfaces != null && interfaces.length > 0) {
        for (var i in interfaces) {
          var ret = i.getMember(memberName);
          if (ret != null) {
            return ret;
          }
        }
      }
      return world.objectType.getMember(memberName);
    }
  }

  void ensureSubtypeOf(Type other, SourceSpan span, [bool typeErrors=false]) {
    if (!isSubtypeOf(other)) {
      var msg = 'type $name is not a subtype of ${other.name}';
      if (typeErrors) {
        world.error(msg, span);
      } else {
        world.warning(msg, span);
      }
    }
  }

  /**
   * Returns true if we need to use our .call$N$names calling convention.
   * This is only needed for calls to Functions where we lack enough type info.
   */
  bool needsVarCall(Arguments args) {
    if (isVarOrFunction) {
      return true;
    }

    var call = getCallMethod();
    if (call != null) {
      // If the call doesn't fill in all arguments, or it doesn't use the right
      // named parameter order, we need to go through a "var" call because we
      // don't know what arguments the callee wants to fill in.

      // TODO(jmesserly): we could be smarter if the optional calls look
      // similar enough, which is probably true quite often in practice.
      if (args.length != call.parameters.length || !call.namesInOrder(args)) {
        return true;
      }
    }

    // Use a normal JS call, or not a function type.
    return false;
  }

  static Type union(Type x, Type y) {
    if (x == y) return x;
    if (x.isNum && y.isNum) return world.numType;
    if (x.isString && y.isString) return world.stringType;

    // TODO(jmesserly): make this more precise when we can. Or add UnionValue
    // and have Value do the heavy lifting of tracking sets of types.
    return world.varType;
  }

  // This is from the "Interface Types" section of the language spec:

  /**
   * A type T may be assigned to a type S, written T <=> S, i either T <: S
   * or S <: T.
   */
  bool isAssignable(Type other) {
    return isSubtypeOf(other) || other.isSubtypeOf(this);
  }

  /**
   * An interface I is a direct supertype of an interface J iff:
   * If I is Object, and J has no extends clause
   * if I is listed in the extends clause of J.
   */
  bool _isDirectSupertypeOf(Type other) {
    if (other.isClass) {
      return other.parent == this || isObject && other.parent == null;
    } else {
      if (other.interfaces == null || other.interfaces.isEmpty()) {
        return isObject;
      } else {
        return other.interfaces.some((i) => i == this);
      }
    }
  }

  /**
   * This implements the subtype operator <: defined in "Interface Types"
   * of the language spec. It's implemented in terms of the << "more specific"
   * operator. The spec is below:
   *
   * A type T is more specific than a type S, written T << S, if one of the
   * following conditions is met:
   *   - T is S.
   *   - T is Bottom.
   *   - S is Dynamic.
   *   - S is a direct supertype of T.
   *   - T is a type variable and S is the upper bound of T.
   *   - T is of the form I<T1,...,Tn> and S is of the form I<S1,...,Sn>
   *       and: Ti << Si, 1 <= i <= n
   *   - T << U and U << S.
   *
   * << is a partial order on types. T is a subtype of S, written T <: S, iff
   * [Bottom/Dynamic]T << S.
   */
  // TODO(jmesserly): this function could be expensive. Memoize results?
  // TODO(jmesserly): should merge this with the subtypes/directSubtypes
  // machinery? Possible issues: needing this during resolve(), integrating
  // the more accurate generics/function subtype handling.
  bool isSubtypeOf(Type other) {
    if (this == other) return true;

    // Note: the extra "isVar" check here is the difference between << and <:
    // Since we don't implement the << relation itself, we can just pretend
    // "null" literals are Dynamic and not worry about the Bottom type.
    if (isVar || other.isVar) return true;
    if (other._isDirectSupertypeOf(this)) return true;

    var call = getCallMethod();
    var otherCall = other.getCallMethod();
    if (call != null && otherCall != null) {
      return _isFunctionSubtypeOf(call, otherCall);
    }

    if (genericType === other.genericType) {
      // These must be true for matching generic types.
      assert(typeArgsInOrder.length == other.typeArgsInOrder.length);

      for (int i = 0; i < typeArgsInOrder.length; i++) {
        // Type args don't have subtype relationship
        // TODO(jimhug): This dynamic shouldn't be needed...
        if (!typeArgsInOrder[i].dynamic.isSubtypeOf(other.typeArgsInOrder[i])) {
          return false;
        }
      }
      return true;
    }

    // And now for some fun: T << U and U << S -> T << S
    // To implement this, we need to enumerate a set of types C such that
    // U will be an element of C. We can do this by either enumerating less
    // specific types of T, or more specific types of S.
    if (parent != null && parent.isSubtypeOf(other)) {
      return true;
    }
    if (interfaces != null && interfaces.some((i) => i.isSubtypeOf(other))) {
      return true;
    }

    // Unrelated types
    return false;
  }

  int hashCode() {
    var libraryCode = library == null ? 1 : library.hashCode();
    var nameCode = name == null ? 1 : name.hashCode();
    return (libraryCode << 4) ^ nameCode;
  }

  bool operator ==(other) =>
    other is Type && other.name == name && library == other.library;

  /**
   * A function type (T1,...,Tn, [Tx1 x1,..., Txk xk]) -> T is a subtype of the
   * function type   (S1,...,Sn, [Sy1 y1,..., Sym ym]) -> S, if all of the
   * following conditions are met:
   *   1. Either:
   *      - S is void, Or
   *      - T <=> S.
   *   2. for all i in 1..n, Ti <=> Si
   *   3. k >= m and xi = yi, i is in 1..m. It is necessary, but not sufficient,
   *      that the optional arguments of the subtype be a subset of those of the
   *      supertype. We cannot treat them as just sets, because optional
   *      arguments can be invoked positionally, so the order matters.
   *   4. For all y in {y1,..., ym}Sy <=> Ty
   * We write (T1,..., Tn) => T as a shorthand for the type (T1,...,Tn,[]) => T.
   * All functions implement the interface Function, so all function types are a
   * subtype of Function.
   */
  static bool _isFunctionSubtypeOf(MethodMember t, MethodMember s) {
    if (!s.returnType.isVoid && !s.returnType.isAssignable(t.returnType)) {
      return false; // incompatible return types
    }

    var tp = t.parameters;
    var sp = s.parameters;

    // Function subtype must have >= the total number of arguments
    if (tp.length < sp.length) return false;

    for (int i = 0; i < sp.length; i++) {
      // Mismatched required parameter count
      if (tp[i].isOptional != sp[i].isOptional) return false;

      // Mismatched optional parameter name
      if (tp[i].isOptional && tp[i].name != sp[i].name) return false;

      // Parameter types not assignable
      if (!tp[i].type.isAssignable(sp[i].type)) return false;
    }

    // Mismatched required parameter count
    if (tp.length > sp.length && !tp[sp.length].isOptional) return false;

    return true;
  }
}


/** A type parameter within the body of the type. */
class ParameterType extends Type {
  TypeParameter typeParameter;
  Type extendsType;

  bool get isClass() => false;
  Library get library() => null; // TODO(jimhug): Make right...
  SourceSpan get span() => typeParameter.span;

  ParameterType(String name, this.typeParameter): super(name);

  Map<String, MethodMember> get constructors() {
    world.internalError('no constructors on type parameters yet');
  }

  MethodMember getCallMethod() => extendsType.getCallMethod();

  void genMethod(Member method) {
    extendsType.genMethod(method);
  }

  // TODO(jmesserly): should be like this:
  //bool isSubtypeOf(Type other) => extendsType.isSubtypeOf(other);
  bool isSubtypeOf(Type other) => true;

  MethodMember getConstructor(String constructorName) {
    world.internalError('no constructors on type parameters yet');
  }

  Type getOrMakeConcreteType(List<Type> typeArgs) {
    world.internalError('no concrete types of type parameters yet', span);
  }

  addDirectSubtype(Type type) {
    world.internalError('no subtypes of type parameters yet', span);
  }

  resolve() {
    if (typeParameter.extendsType != null) {
      extendsType =
        enclosingElement.resolveType(typeParameter.extendsType, true, true);
    } else {
      extendsType = world.objectType;
    }
  }
}

/**
 * Non-nullable type. Currently used for bools, so we can generate better
 * asserts in checked mode. Forwards almost all operations to its real type.
 */
// NOTE: there's more work to do before this would work for types other than
// bool.
class NonNullableType extends Type {

  /** The corresponding nullable [Type]. */
  final Type type;

  NonNullableType(Type type): super(type.name), type = type;

  bool get isNullable() => false;

  // TODO(jmesserly): this would need to change if we support other types.
  bool get isBool() => type.isBool;

  // Treat it as unused so it doesn't get JS generated
  bool get isUsed() => false;

  // Augment our subtype rules with: non-nullable types are subtypes of
  // themselves, their corresponding nullable types, or anything that type is a
  // subtype of.
  bool isSubtypeOf(Type other) =>
      this == other || type == other || type.isSubtypeOf(other);

  // Forward everything. This is overkill for now; might be useful later.
  Type resolveType(TypeReference node, bool isRequired, bool allowTypeParams) =>
      type.resolveType(node, isRequired, allowTypeParams);
  void addDirectSubtype(Type subtype) { type.addDirectSubtype(subtype); }
  void markUsed() { type.markUsed(); }
  void genMethod(Member method) { type.genMethod(method); }
  SourceSpan get span() => type.span;
  Member getMember(String name) => type.getMember(name);
  MethodMember getConstructor(String name) => type.getConstructor(name);
  MethodMember getFactory(Type t, String name) => type.getFactory(t, name);
  Type getOrMakeConcreteType(List<Type> typeArgs) =>
      type.getOrMakeConcreteType(typeArgs);
  Map<String, MethodMember> get constructors() => type.constructors;
  bool get isClass() => type.isClass;
  Library get library() => type.library;
  MethodMember getCallMethod() => type.getCallMethod();
  bool get isGeneric() => type.isGeneric;
  bool get hasTypeParams() => type.hasTypeParams;
  String get typeofName() => type.typeofName;
  String get jsname() => type.jsname;
  Map<String, Member> get members() => type.members;
  Definition get definition() => type.definition;
  FactoryMap get factories() => type.factories;
  List<Type> get typeArgsInOrder() => type.typeArgsInOrder;
  DefinedType get genericType() => type.genericType;
  List<Type> get interfaces() => type.interfaces;
  Type get parent() => type.parent;
  Map<String, Member> getAllMembers() => type.getAllMembers();
  bool get isNative() => type.isNative;
}


/** Represents a Dart type defined as source code. */
class DefinedType extends Type {
  // Not final so that we can fill this in for special types like List or num.
  Definition definition;
  final Library library;
  final bool isClass;

  // TODO(vsm): Restore the field once Issue 280 is fixed.
  // Type parent;
  Type _parent;
  Type get parent() => _parent;
  void set parent(Type p) { _parent = p; }

  List<Type> interfaces;
  DefinedType defaultType;

  Set<Type> directSubtypes;
  Set<Type> _subtypes;

  List<ParameterType> typeParameters;
  List<Type> typeArgsInOrder;

  Map<String, MethodMember> constructors;
  Map<String, Member> members;
  FactoryMap factories;

  Map<String, Type> _concreteTypes;

  /** Methods to be generated once we know for sure that the type is used. */
  Map<String, Member> _lazyGenMethods;

  bool isUsed = false;
  bool isNative = false;

  Type baseGenericType;

  DefinedType get genericType() =>
    baseGenericType === null ? this : baseGenericType;


  DefinedType(String name, this.library, Definition definition, this.isClass)
      : super(name), directSubtypes = new Set<Type>(), constructors = {},
        members = {}, factories = new FactoryMap() {
    setDefinition(definition);
  }

  void setDefinition(Definition def) {
    assert(definition == null);
    definition = def;
    if (definition is TypeDefinition && definition.nativeType != null) {
      isNative = true;
    }
    if (definition != null && definition.typeParameters != null) {
      _concreteTypes = {};
      typeParameters = definition.typeParameters;
      // TODO(jimhug): Should share these very generic lists better.
      typeArgsInOrder = new List(typeParameters.length);
      for (int i=0; i < typeArgsInOrder.length; i++) {
        typeArgsInOrder[i] = world.varType;
      }
    } else {
      typeArgsInOrder = const [];
    }
  }

  NativeType get nativeType() =>
      (definition != null ? definition.nativeType : null);

  bool get isVar() => this == world.varType;
  bool get isVoid() => this == world.voidType;

  /** Is this the type that holds onto top-level code for its library? **/
  bool get isTop() => name == null;

  // TODO(jimhug) -> this == world.objectType, etc.
  bool get isObject() => this == world.objectType;

  // TODO(jimhug): Really hating on the interface + impl pattern by now...
  bool get isString() => this == world.stringType ||
    this == world.stringImplType;

  // TODO(jimhug): Where is boolImplType?
  bool get isBool() => this == world.boolType;
  bool get isFunction() => this == world.functionType ||
    this == world.functionImplType;

  bool get isGeneric() => typeParameters != null;

  SourceSpan get span()  => definition == null ? null : definition.span;


  String get typeofName() {
    if (!library.isCore) return null;

    if (isBool) return 'boolean';
    else if (isNum) return 'number';
    else if (isString) return 'string';
    else if (isFunction) return 'function';
    else return null;
  }

  // TODO(jimhug): Reconcile different number types on JS.
  bool get isNum() {
    return this == world.numType || this == world.intType ||
      this == world.doubleType || this == world.numImplType;
  }

  bool get isInt() => this == world.intType;
  bool get isDouble() => this == world.doubleType;

  // TODO(jimhug): Understand complicated generics here...
  MethodMember getCallMethod() => genericType.members[':call'];

  Map<String, Member> getAllMembers() => new Map.from(members);

  void markUsed() {
    if (isUsed) return;

    isUsed = true;

    _checkExtends();

    if (_lazyGenMethods != null) {
      for (var method in orderValuesByKeys(_lazyGenMethods)) {
        world.gen.genMethod(method);
      }
      _lazyGenMethods = null;
    }

    if (parent != null) parent.markUsed();
  }

  void genMethod(Member method) {
    // TODO(jimhug): Remove baseGenericType check from here.
    if (isUsed || baseGenericType != null) {
      world.gen.genMethod(method);
    } else if (isClass) {
      if (_lazyGenMethods == null) _lazyGenMethods = {};
      _lazyGenMethods[method.name] = method;
    }
  }

  List<Type> _resolveInterfaces(List<TypeReference> types) {
    if (types == null) return [];
    var interfaces = [];
    for (final type in types) {
      var resolvedInterface = resolveType(type, true, true);
      if (resolvedInterface.isClosed &&
          !(library.isCore || library.isCoreImpl)) {
        world.error(
          'cannot implement "${resolvedInterface.name}": '
          'only native implementation allowed', type.span);
      }
      resolvedInterface.addDirectSubtype(this);
      // TODO(jimhug): if (resolveInterface.isClass) may need special handling.
      interfaces.add(resolvedInterface);
    }
    return interfaces;
  }

  addDirectSubtype(Type type) {
    directSubtypes.add(type);
    // TODO(jimhug): Shouldn't need this in both places.
    if (baseGenericType != null) {
      baseGenericType.addDirectSubtype(type);
    }
  }

  Set<Type> get subtypes() {
    if (_subtypes == null) {
      _subtypes = new Set<Type>();
      for (var st in directSubtypes) {
        _subtypes.add(st);
        _subtypes.addAll(st.subtypes);
      }
    }
    return _subtypes;
  }

  /** Check whether this class has a cycle in its inheritance chain. */
  bool _cycleInClassExtends() {
    final seen = new Set();
    seen.add(this);
    var ancestor = parent;
    while (ancestor != null) {
      if (ancestor === this) {
        return true;
      }
      if (seen.contains(ancestor)) {
        // there is a cycle above, but [this] is not part of it
        return false;
      }
      seen.add(ancestor);
      ancestor = ancestor.parent;
    }
    return false;
  }

  /**
   * Check whether this interface has a cycle in its inheritance chain. If so,
   * returns which of the parent interfaces creates the cycle (for error
   * reporting).
   */
  int _cycleInInterfaceExtends() {
    final seen = new Set();
    seen.add(this);

    bool _helper(var ancestor) {
      if (ancestor == null) return false;
      if (ancestor === this) return true;
      if (seen.contains(ancestor)) {
        // this detects both cycles and DAGs with interfaces not involving
        // [this]. In the case of cycles, we won't report an error here (but
        // where the cycle was first detected), with DAGs we just take advantage
        // that we detected it to avoid traversing twice.
        return false;
      }
      seen.add(ancestor);
      if (ancestor.interfaces != null) {
        for (final parent in ancestor.interfaces) {
          if (_helper(parent)) return true;
        }
      }
      return false;
    }

    for (int i = 0; i < interfaces.length; i++) {
      if (_helper(interfaces[i])) return i;
    }
    return -1;
  }

  resolve() {
    if (definition is TypeDefinition) {
      TypeDefinition typeDef = definition;
      if (isClass) {
        if (typeDef.extendsTypes != null && typeDef.extendsTypes.length > 0) {
          if (typeDef.extendsTypes.length > 1) {
            world.error('more than one base class',
              typeDef.extendsTypes[1].span);
          }
          var extendsTypeRef = typeDef.extendsTypes[0];
          if (extendsTypeRef is GenericTypeReference) {
            // TODO(jimhug): Understand and verify comment below.
            // If we are extending a generic type first resolve against the
            // base type, then the full generic type. This makes circular
            // "extends" checks on generic type args work correctly.
            GenericTypeReference g = extendsTypeRef;
            parent = resolveType(g.baseType, true, true);
          }
          parent = resolveType(extendsTypeRef, true, true);
          if (!parent.isClass) {
            world.error('class may not extend an interface - use implements',
              typeDef.extendsTypes[0].span);
          }
          parent.addDirectSubtype(this);
          if (_cycleInClassExtends()) {
            world.error('class "$name" has a cycle in its inheritance chain',
                extendsTypeRef.span);
          }
        } else {
          if (!isObject) {
            // Object is the default parent for everthing except Object.
            parent = world.objectType;
            parent.addDirectSubtype(this);
          }
        }
        this.interfaces = _resolveInterfaces(typeDef.implementsTypes);
        if (typeDef.defaultType != null) {
          world.error('default not allowed on classes',
            typeDef.defaultType.span);
        }
      } else {
        if (typeDef.implementsTypes != null &&
              typeDef.implementsTypes.length > 0) {
          world.error('implements not allowed on interfaces (use extends)',
            typeDef.implementsTypes[0].span);
        }
        this.interfaces = _resolveInterfaces(typeDef.extendsTypes);
        final res = _cycleInInterfaceExtends();
        if (res >= 0) {
          world.error('interface "$name" has a cycle in its inheritance chain',
              typeDef.extendsTypes[res].span);
        }

        if (typeDef.defaultType != null) {
          defaultType = resolveType(typeDef.defaultType.baseType, true, true);
          if (defaultType == null) {
            // TODO(jimhug): Appropriate warning levels;
            world.warning('unresolved default class', typeDef.defaultType.span);
          } else {
            if (baseGenericType != null) {
              if (!defaultType.isGeneric) {
                world.error('default type of generic interface must be generic',
                  typeDef.defaultType.span);
              }
              defaultType = defaultType.getOrMakeConcreteType(typeArgsInOrder);
            }
          }
        }
      }
    } else if (definition is FunctionTypeDefinition) {
      // Function types implement the Function interface.
      this.interfaces = [world.functionType];
    }

    _resolveTypeParams(typeParameters);

    if (isObject) _createNotEqualMember();

    // Concrete specializations of ListFactory === Array are never actually
    // created as the performance suffers too badly in most JS engines.
    if (baseGenericType != world.listFactoryType) world._addType(this);

    for (var c in constructors.getValues()) c.resolve();
    for (var m in members.getValues()) m.resolve();
    factories.forEach((f) => f.resolve());

    // All names from the JS global object need to be treated as top-level
    // native names, so we don't clobber them with other Dart top-level names.
    if (isJsGlobalObject) {
      for (var m in members.getValues()) {
        if (!m.isStatic) world._addTopName(new ExistingJsGlobal(m.name, m));
      }
    }
  }

  _resolveTypeParams(List<ParameterType> params) {
    if (params == null) return;
    for (var tp in params) {
      tp.enclosingElement = this;
      tp.resolve();
    }
  }

  addMethod(String methodName, FunctionDefinition definition) {
    if (methodName == null) methodName = definition.name.name;

    var method = new MethodMember(methodName, this, definition);

    if (method.isConstructor) {
      if (constructors.containsKey(method.constructorName)) {
        world.error('duplicate constructor definition of ${method.name}',
          definition.span);
        return;
      }
      constructors[method.constructorName] = method;
      return;
    }

    if (definition.modifiers != null
        && definition.modifiers.length == 1
        && definition.modifiers[0].kind == TokenKind.FACTORY) {
      // constructorName for a factory is the type.
      if (factories.getFactory(method.constructorName, method.name) != null) {
        world.error('duplicate factory definition of "${method.name}"',
          definition.span);
        return;
      }
      factories.addFactory(method.constructorName, method.name, method);
      return;
    }

    if (methodName.startsWith('get:') || methodName.startsWith('set:')) {
      var propName = methodName.substring(4);
      var prop = members[propName];
      if (prop == null) {
        prop = new PropertyMember(propName, this);
        members[propName] = prop;
      }
      if (prop is! PropertyMember) {
        world.error('property conflicts with field "$propName"',
          definition.span);
        return;
      }
      if (methodName[0] == 'g') {
        if (prop.getter != null) {
          world.error('duplicate getter definition for "$propName"',
            definition.span);
        }
        // TODO(jimhug): Validate zero parameters
        prop.getter = method;
      } else {
        if (prop.setter != null) {
          world.error('duplicate setter definition for "$propName"',
            definition.span);
        }
        // TODO(jimhug): Validate one parameters - match with getter?
        prop.setter = method;
      }
      return;
    }

    if (members.containsKey(methodName)) {
      world.error('duplicate method definition of "${method.name}"',
        definition.span);
      return;
    }
    members[methodName] = method;
  }

  addField(VariableDefinition definition) {
    for (int i=0; i < definition.names.length; i++) {
      var name = definition.names[i].name;
      if (members.containsKey(name)) {
        world.error('duplicate field definition of "$name"',
          definition.span);
        return;
      }
      var value = null;
      if (definition.values != null) {
        value = definition.values[i];
      }
      var field =
          new FieldMember(name, this, definition, value, isNative: isNative);
      members[name] = field;
    }
  }

  getFactory(Type type, String constructorName) {
    if (baseGenericType != null) {
      var rr = baseGenericType.factories.getFactory(type.genericType.name,
        constructorName);
      if (rr != null) {
        // TODO(jimhug): Understand and fix this case.
        world.info(
          'need to remap factory on ${name} from ${rr.declaringType.name}');
        return rr;
      } else {
        var ret = getConstructor(constructorName);
        return ret;
      }
    }

    // Try to find factory method with the given type.
    // TODO(jimhug): Use jsname as key here or something better?
    var ret = factories.getFactory(type.genericType.name, constructorName);
    if (ret != null) return ret;

    // TODO(ngeoffray): Here we should actually check if the current
    // type implements the given type.
    // Try to find a factory method of this type.
    ret = factories.getFactory(name, constructorName);
    if (ret != null) return ret;

    // Try to find a generative constructor of this type.
    ret = constructors[constructorName];
    if (ret != null) return ret;

    return _tryCreateDefaultConstructor(constructorName);
  }


  getConstructor(String constructorName) {
    // cheat and reuse constructors here to be any resolved cons...
    if (baseGenericType != null) {
      var rr = constructors[constructorName];
      if (rr != null) return rr;

      rr = baseGenericType.constructors[constructorName];
      if (rr != null) {
        if (defaultType != null) {
          var ret = defaultType.getFactory(this, constructorName);
          return ret;
        }
      } else {
        rr = baseGenericType.factories.getFactory(baseGenericType.name,
          constructorName);
      }
      if (rr == null) {
        rr = baseGenericType.dynamic._tryCreateDefaultConstructor(
          constructorName);
      }
      if (rr == null) return null;

      // re-resolve rr in this
      var rr1 = rr.makeConcrete(this);
      rr1.resolve();

      constructors[constructorName] = rr1;
      return rr1;
    }


    var ret = constructors[constructorName];
    if (ret != null) {
      if (defaultType != null) {
        return defaultType.getFactory(this, constructorName);
      }
      return ret;
    }
    ret = factories.getFactory(name, constructorName);
    if (ret != null) return ret;

    return _tryCreateDefaultConstructor(constructorName);
  }

  // TODO(jimhug): Can we remove this with version in resolve + new spec?
  /**
   * Checks that default type parameters match between all 3 locations:
   *   1. the interface (this)
   *   2. the "default" type parameters
   *   3. the class's type parameters
   *
   * The only deviation is that 2 and 3 can have a tighter "extends" bound.
   */
  _checkDefaultTypeParams() {
    // Convert null to empty list so it doesn't complicate the logic
    List<ParameterType> toList(list) => (list != null ? list : const []);

    TypeDefinition typeDef = definition;
    if (typeDef.defaultType.oldFactory) {
      // TODO(jmesserly): for now skip checking of old factories
      return;
    }

    var interfaceParams = toList(typeParameters);
    var defaultParams = toList(typeDef.defaultType.typeParameters);
    var classParams = toList(defaultType.typeParameters);

    if (interfaceParams.length != defaultParams.length
        || defaultParams.length != classParams.length) {
      world.error('"default" must have the same number of type parameters as '
          + 'the class and interface do', span, typeDef.defaultType.span,
          defaultType.span);
      return;
    }

    for (int i = 0; i < interfaceParams.length; i++) {
      var ip = interfaceParams[i];
      var dp = defaultParams[i];
      var cp = classParams[i];
      dp.resolve();
      if (ip.name != dp.name || dp.name != cp.name) {
        world.error('default class must have the same type parameter names as '
            + 'the class and interface', ip.span, dp.span, cp.span);
      } else if (dp.extendsType != cp.extendsType) {
        world.error('default class type parameters must have the same extends '
            + 'as the class does', dp.span, cp.span);
      } else if (!dp.extendsType.isSubtypeOf(ip.extendsType)) {
        // TODO(jmesserly): left this as a warning; it seems harmless to me
        world.warning('"default" can only have tighter type parameter "extends"'
            + ' than the interface', dp.span, ip.span);
      }
    }
  }

  _tryCreateDefaultConstructor(String name) {
    // Check if we can create a default constructor.
    if (name == '' && definition != null && isClass &&
        constructors.length == 0) {
      var span = definition.span;

      var inits = null, native = null, body = null;
      if (isNative) {
        native = '';
        inits = null;
      } else {
        body = null;
        inits = [new CallExpression(new SuperExpression(span), [], span)];
      }

      TypeDefinition typeDef = definition;
      var c = new FunctionDefinition(null, null, typeDef.name, [],
        inits, native, body, span);
      addMethod(null, c);
      constructors[''].resolve();
      return constructors[''];
    }
    return null;
  }

  Member getMember(String memberName) {
    Member member = _foundMembers[memberName];
    if (member != null) return member;

    if (baseGenericType != null) {
      member = baseGenericType.getMember(memberName);
      // TODO(jimhug): Need much more elaborate lookup duplication here <frown>

      if (member == null) return null;

      // TODO(jimhug): There will be a few of these we need to specialize for
      // type params, skipping anything not on my direct super is not accurate
      if (member.isStatic || member.declaringType != baseGenericType) {
        _foundMembers[memberName] = member;
        return member;
      }


      var rr = member.makeConcrete(this);
      if (member.definition !== null || member is PropertyMember) {
        rr.resolve();
      } else {
        world.info('no definition for ${member.name} on ${name}');
      }
      // TODO(jimhug): Why do I need to put this in both maps?
      members[memberName] = rr;
      _foundMembers[memberName] = rr;
      return rr;
    }

    member = members[memberName];
    if (member != null) {
      _checkOverride(member);
      _foundMembers[memberName] = member;
      return member;
    }

    if (isTop) {
      // Let's pretend classes are members of the top-level library type
      // TODO(jmesserly): using "this." to workaround a VM bug with abstract
      // getters.
      var libType = this.library.findTypeByName(memberName);
      if (libType != null) {
        member = libType.typeMember;
        _foundMembers[memberName] = member;
        return member;
      }
    }

    member = _getMemberInParents(memberName);
    _foundMembers[memberName] = member;
    return member;
  }

  Type getOrMakeConcreteType(List<Type> typeArgs) {
    assert(isGeneric);
    var jsnames = [];
    var names = [];
    var typeMap = {};
    bool allVar = true;
    for (int i=0; i < typeArgs.length; i++) {
      var typeArg = typeArgs[i];
      if (typeArg is ParameterType) {
        typeArg = world.varType;
        typeArgs[i] = typeArg;
      }
      if (!typeArg.isVar) allVar = false;

      var paramName = typeParameters[i].name;
      typeMap[paramName] = typeArg;
      names.add(typeArg.fullname);
      jsnames.add(typeArg.jsname);
    }

    // If all type args are var or effectively var, just return this
    if (allVar) return this;

    var jsname = '${jsname}_${Strings.join(jsnames, '\$')}';
    var simpleName = '${name}<${Strings.join(names, ', ')}>';

    var ret = _concreteTypes[simpleName];
    if (ret == null) {
      ret = new DefinedType(simpleName, library, definition, isClass);
      ret.baseGenericType = this;
      ret.typeArgsInOrder = typeArgs;
      ret._jsname = jsname;
      _concreteTypes[simpleName] = ret;
      ret.resolve();
    }
    return ret;
  }

  VarFunctionStub getCallStub(Arguments args) {
    assert(isFunction);

    var name = _getCallStubName('call', args);
    var stub = varStubs[name];
    if (stub == null) {
      stub = new VarFunctionStub(name, args);
      varStubs[name] = stub;
    }
    return stub;
  }
}

/**
 * Information about a native type from the native string.
 *
 *  "Foo"  - constructor function is called 'Foo'.
 *  "=Foo" - a singleton instance that should be patched directly. For example,
 *           "=window.console"
 *  "*Foo" - name is 'Foo', constructor function and prototype are not available
 *      in global scope during initialization.  This is characteristic of many
 *      DOM types like CanvasPixelArray. However, the *type name* is presumed to
 *      be available at runtime from the prototype.
 *  "@Foo" - the type of the global object. Members will be treated as names
 *      that can't be shadowed in generated JS.
 */
// TODO(jmesserly): we really need a richer annotation system than just encoding
// this data in strings with magic characters.
class NativeType {
  String name;
  bool isConstructorHidden = false;
  bool isJsGlobalObject = false;
  bool isSingleton = false;

  NativeType(this.name) {
    while (true) {
      if (name.startsWith('@')) {
        name = name.substring(1);
        isJsGlobalObject = true;
      } else if (name.startsWith('*')) {
        name = name.substring(1);
        isConstructorHidden = true;
      } else {
        break;
      }
    }
    if (name.startsWith('=')) {
      name = name.substring(1);
      isSingleton = true;
    }
  }
}
