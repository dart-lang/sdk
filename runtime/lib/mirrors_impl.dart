// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

import "dart:collection" show UnmodifiableListView, UnmodifiableMapView;
import "dart:async" show Future;

var dirty = false;
final emptyList = new UnmodifiableListView([]);
final emptyMap = new UnmodifiableMapView({});

class _InternalMirrorError {
  final String _msg;
  const _InternalMirrorError(String this._msg);
  String toString() => _msg;
}

String _n(Symbol symbol) => internal.Symbol.getName(symbol);

Symbol _s(String name) {
  if (name == null) return null;
  return new internal.Symbol.unvalidated(name);
}

Symbol _computeQualifiedName(DeclarationMirror owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  return _s('${_n(owner.qualifiedName)}.${_n(simpleName)}');
}

String _makeSignatureString(TypeMirror returnType,
                            List<ParameterMirror> parameters) {
  StringBuffer buf = new StringBuffer();
  buf.write('(');
  bool found_optional_positional = false;
  bool found_optional_named = false;

  for (int i = 0; i < parameters.length; i++) {
    var param = parameters[i];
    if (param.isOptional && param.isNamed && !found_optional_named) {
      buf.write('{');
      found_optional_named = true;
    }
    if (param.isOptional && !param.isNamed && !found_optional_positional) {
      buf.write('[');
      found_optional_positional = true;
    }
    if (param.isNamed) {
      buf.write(_n(param.simpleName));
      buf.write(': ');
    }
    buf.write(_n(param.type.qualifiedName));
    if (i < (parameters.length - 1)) {
      buf.write(', ');
    }
  }
  if (found_optional_named) {
    buf.write('}');
  }
  if (found_optional_positional) {
    buf.write(']');
  }
  buf.write(') -> ');
  buf.write(_n(returnType.qualifiedName));
  return buf.toString();
}

SourceLocation _location(reflectee)
    native "DeclarationMirror_location";

List _metadata(reflectee)
    native 'DeclarationMirror_metadata';

bool _subtypeTest(Type a, Type b)
    native 'TypeMirror_subtypeTest';

class _AccessorCacheAssociation {
  String key;
  Function value;
  bool usedSinceGrowth = true;
  _AccessorCacheAssociation(this.key, this.value);
}

/**
 * A map that will grow as associations are added but will prefer to evict
 * associations that have not been used since the last growth when needing to
 * grow again. Implemented as an open addressing hash table.
 */
class _AccessorCache {
  List table;
  int shift;
  int mask;
  int capacity;  // Max number of associations before we start evicting/growing.
  int size = 0;  // Current number of associations.

  /**
   * Create a cache whose capacity is 75% of 2^shift.
   */
  _AccessorCache.withInitialShift(int shift) {
    // The scheme used here for handling collisions relies on there always
    // being at least one empty slot.
    if (shift < 1) throw new Exception("_AccessorCache requires a shift >= 1");
    initWithShift(shift);
  }

  void initWithShift(int shift) {
    this.shift = shift;
    this.mask = (1 << shift) - 1;
    this.capacity = (1 << shift) * 3 ~/ 4;
    this.table = new List(1 << shift);
    assert(table.length > capacity);
  }

  int scanFor(String key) {
    var start = key.hashCode & mask;
    var index = start;
    do {
      var assoc = table[index];
      if (null == assoc || assoc.key == key) {
        return index;
      }
      index = (index + 1) & mask;
    } while (index != start);
    // Should never happen because we start evicting associations before the
    // table is full.
    throw new Exception("Internal error: _AccessorCache table full");
  }

  int scanForEmpty(String key) {
    var start = key.hashCode & mask;
    var index = start;
    do {
      if (null == table[index]) {
        return index;
      }
      index = (index + 1) & mask;
    } while (index != start);
    // Should never happen because we start evicting associations before the
    // table is full.
    throw new Exception("Internal error: _AccessorCache table full");
  }

  void fixCollisionsAfter(int start) {
    var assoc;
    var index = (start + 1) & mask;
    while (null != (assoc = table[index])) {
      var newIndex = scanFor(assoc.key);
      if (newIndex != index) {
        assert(table[newIndex] == null);
        table[newIndex] = assoc;
        table[index] = null;
      }
      index = (index + 1) & mask;
    }
  }

  void grow() {
    var oldTable = table;

    initWithShift(shift + 1);

    for (int oldIndex = 0; oldIndex < oldTable.length; oldIndex++) {
      var assoc = oldTable[oldIndex];
      if (assoc != null) {
        var newIndex = scanForEmpty(assoc.key);
        assoc.usedSinceGrowth = false;
        table[newIndex] = assoc;
      }
    }
  }

  void tryToShrinkOtherwiseGrow() {
    // Remove any associations not accessed since the last growth. If we are
    // unable to free any slots, grow.
    bool needToGrow = true;
    for (int i = 0; i < table.length; i++) {
      var assoc = table[i];
      if (null != assoc && (!assoc.usedSinceGrowth || null == assoc.value)) {
        table[i] = null;
        size--;
        fixCollisionsAfter(i);
        needToGrow = false;
      }
    }
    if (needToGrow) grow();
  }

  operator []=(String key, Function value) {
    int index = scanFor(key);
    var assoc = table[index];
    if (null != assoc) {
      // Existing key, replace value.
      assert(assoc.key == key);
      assoc.value = value;
      assoc.usedSinceGrowth = true;
    } else {
      // New key.
      var newAssoc = new _AccessorCacheAssociation(key, value);
      if (size == capacity) {
        // No free slots.
        tryToShrinkOtherwiseGrow();
        index = scanFor(key);
        assert(table[index] == null);
      }
      table[index] = newAssoc;
      size++;
    }
  }

  Function operator [](String key) {
    var index = scanFor(key);
    var assoc = table[index];
    if (null == assoc) return null;
    assoc.usedSinceGrowth = true;
    return assoc.value;
  }
}

class _LocalMirrorSystem extends MirrorSystem {
  final TypeMirror dynamicType = new _SpecialTypeMirror('dynamic');
  final TypeMirror voidType = new _SpecialTypeMirror('void');

  var _libraries;
  Map<Uri, LibraryMirror> get libraries {
    if ((_libraries == null) || dirty) {
      _libraries = new Map<Uri, LibraryMirror>.fromIterable(
          _computeLibraries(), key: (e) => e.uri);
    }
    return _libraries;
  }
  static _computeLibraries() native "MirrorSystem_libraries";

  var _isolate;
  IsolateMirror get isolate {
    if (_isolate == null) {
      _isolate = _computeIsolate();
    }
    return _isolate;
  }
  static _computeIsolate() native "MirrorSystem_isolate";

  String toString() => "MirrorSystem for isolate '${isolate.debugName}'";
}

class _SourceLocation implements SourceLocation {
  _SourceLocation(uriString, this.line, this.column)
      : this.sourceUri = Uri.parse(uriString);

  // Line and column positions are 1-origin, or 0 if unknown.
  final int line;
  final int column;

  final Uri sourceUri;

  String toString() {
    return column == 0 ? "$sourceUri:$line" : "$sourceUri:$line:$column";
  }
}

abstract class _LocalMirror implements Mirror {}

class _LocalIsolateMirror extends _LocalMirror implements IsolateMirror {
  final String debugName;
  final LibraryMirror rootLibrary;

  _LocalIsolateMirror(this.debugName, this.rootLibrary);

  bool get isCurrent => true;

  String toString() => "IsolateMirror on '$debugName'";
}

class _SyntheticAccessor implements MethodMirror {
  final DeclarationMirror owner;
  final Symbol simpleName;
  final bool isGetter;
  final bool isStatic;
  final bool isTopLevel;
  final _target;

  _SyntheticAccessor(this.owner,
                     this.simpleName,
                     this.isGetter,
                     this.isStatic,
                     this.isTopLevel,
                     this._target);

  bool get isSynthetic => true;
  bool get isRegularMethod => false;
  bool get isOperator => false;
  bool get isConstructor => false;
  bool get isConstConstructor => false;
  bool get isGenerativeConstructor => false;
  bool get isFactoryConstructor => false;
  bool get isExternal => false;
  bool get isRedirectingConstructor => false;
  bool get isAbstract => false;

  bool get isSetter => !isGetter;
  bool get isPrivate => _n(simpleName).startsWith('_');

  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);
  Symbol get constructorName => const Symbol('');

  TypeMirror get returnType => _target.type;
  List<ParameterMirror> get parameters {
    if (isGetter) return emptyList;
    return new UnmodifiableListView(
        [new _SyntheticSetterParameter(this, this._target)]);
  }

  SourceLocation get location => null;
  List<InstanceMirror> get metadata => emptyList;
  String get source => null;
}

class _SyntheticSetterParameter implements ParameterMirror {
  final DeclarationMirror owner;
  final VariableMirror _target;

  _SyntheticSetterParameter(this.owner, this._target);

  Symbol get simpleName => _target.simpleName;
  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);
  TypeMirror get type => _target.type;

  bool get isOptional => false;
  bool get isNamed => false;
  bool get isStatic => false;
  bool get isTopLevel => false;
  bool get isConst => false;
  bool get isFinal => true;
  bool get isPrivate => false;
  bool get hasDefaultValue => false;
  InstanceMirror get defaultValue => null;
  SourceLocation get location => null;
  List<InstanceMirror> get metadata => emptyList;
}

abstract class _LocalObjectMirror extends _LocalMirror implements ObjectMirror {
  final _reflectee; // May be a MirrorReference or an ordinary object.

  _LocalObjectMirror(this._reflectee);

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol, dynamic> namedArguments]) {
    int numPositionalArguments = positionalArguments.length;
    int numNamedArguments = namedArguments != null ? namedArguments.length : 0;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List(numArguments);
    arguments.setRange(0, numPositionalArguments, positionalArguments);
    List names = new List(numNamedArguments);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _n(name);
      });
    }

    return reflect(this._invoke(_reflectee, _n(memberName), arguments, names));
  }

  InstanceMirror getField(Symbol memberName) {
    return reflect(this._invokeGetter(_reflectee, _n(memberName)));
  }

  InstanceMirror setField(Symbol memberName, Object value) {
    this._invokeSetter(_reflectee, _n(memberName), value);
    return reflect(value);
  }

  delegate(Invocation invocation) {
    if (invocation.isMethod) {
      return this.invoke(invocation.memberName,
                         invocation.positionalArguments,
                         invocation.namedArguments).reflectee;
    }
    if (invocation.isGetter) {
      return this.getField(invocation.memberName).reflectee;
    }
    if (invocation.isSetter) {
      var unwrapped = _n(invocation.memberName);
      var withoutEqual = _s(unwrapped.substring(0, unwrapped.length - 1));
      var arg = invocation.positionalArguments[0];
      this.setField(withoutEqual, arg).reflectee;
      return arg;
    }
    throw "UNREACHABLE";
  }
}

class _LocalInstanceMirror extends _LocalObjectMirror
    implements InstanceMirror {

  _LocalInstanceMirror(reflectee) : super(reflectee);

  ClassMirror _type;
  ClassMirror get type {
    if (_type == null) {
      // Note it not safe to use reflectee.runtimeType because runtimeType may
      // be overridden.
      _type = reflectType(_computeType(reflectee));
    }
    return _type;
  }

  // LocalInstanceMirrors always reflect local instances
  bool get hasReflectee => true;

  get reflectee => _reflectee;

  String toString() => 'InstanceMirror on ${Error.safeToString(_reflectee)}';

  bool operator ==(other) {
    return other is _LocalInstanceMirror &&
           identical(_reflectee, other._reflectee);
  }

  int get hashCode {
    // Avoid hash collisions with the reflectee. This constant is in Smi range
    // and happens to be the inner padding from RFC 2104.
    return identityHashCode(_reflectee) ^ 0x36363636;
  }

  static var _getFieldClosures = new _AccessorCache.withInitialShift(4);
  static var _setFieldClosures = new _AccessorCache.withInitialShift(4);

  _createGetterClosure(unwrapped) {
    var atPosition = unwrapped.indexOf('@');
    if (atPosition == -1) {
      // Public symbol.
      return  _eval('(x) => x.$unwrapped', null);
    } else {
      // Private symbol.
      var withoutKey = unwrapped.substring(0, atPosition);
      var privateKey = unwrapped.substring(atPosition);
      return _eval('(x) => x.$withoutKey', privateKey);
    }
  }

  _getFieldSlow(unwrapped) {
    // Slow path factored out to give the fast path a better chance at being
    // inlined.
    var result = reflect(_invokeGetter(_reflectee, unwrapped));
    // Wait until success to avoid creating closures for non-existent getters,
    // and defer the creation until the next getField invocation.
    // o.<operator> is not valid Dart and will cause a compilation error, so
    // don't attempt to generate such a closure.
    bool isOperator = _LocalMethodMirror._operators.contains(unwrapped);
    if (!isOperator) {
      _getFieldClosures[unwrapped] = (receiver) {
        var getterClosure = _createGetterClosure(unwrapped);
        _getFieldClosures[unwrapped] = getterClosure;
        return getterClosure(receiver);
      };
    }
    return result;
  }

  InstanceMirror getField(Symbol memberName) {
    var unwrapped = _n(memberName);
    var f = _getFieldClosures[unwrapped];
    return (f == null) ? _getFieldSlow(unwrapped) : reflect(f(_reflectee));
  }

  _createSetterClosure(unwrapped) {
    var atPosition = unwrapped.indexOf('@');
    if (atPosition == -1) {
      // Public symbol.
      return _eval('(x, v) => x.$unwrapped = v', null);
    } else {
      // Private symbol.
      var withoutKey = unwrapped.substring(0, atPosition);
      var privateKey = unwrapped.substring(atPosition);
      return _eval('(x, v) => x.$withoutKey = v', privateKey);
    }
  }

  _setFieldSlow(unwrapped, arg) {
    // Slow path factored out to give the fast path a better chance at being
    // inlined.
    _invokeSetter(_reflectee, unwrapped, arg);
    var result = reflect(arg);
    // Wait until success to avoid creating closures for non-existent setters.
    // and defer the creation until the next setField invocation.
    _setFieldClosures[unwrapped] = (receiver, argument) {
      var setterClosure = _createSetterClosure(unwrapped);
      _setFieldClosures[unwrapped] = setterClosure;
      return setterClosure(receiver, argument);
    };
    return result;
  }

  InstanceMirror setField(Symbol memberName, arg) {
    var unwrapped = _n(memberName);
    var f = _setFieldClosures[unwrapped];
    return (f == null)
        ? _setFieldSlow(unwrapped, arg)
        : reflect(f(_reflectee, arg));
  }

  static _eval(expression, privateKey)
      native "Mirrors_evalInLibraryWithPrivateKey";

  // Override to include the receiver in the arguments.
  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol, dynamic> namedArguments]) {
    int numPositionalArguments = positionalArguments.length + 1;  // Receiver.
    int numNamedArguments = namedArguments != null ? namedArguments.length : 0;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List(numArguments);
    arguments[0] = _reflectee;  // Receiver.
    arguments.setRange(1, numPositionalArguments, positionalArguments);
    List names = new List(numNamedArguments);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _n(name);
      });
    }

    return reflect(this._invoke(_reflectee, _n(memberName), arguments, names));
  }

  _invoke(reflectee, functionName, arguments, argumentNames)
      native 'InstanceMirror_invoke';

  _invokeGetter(reflectee, getterName)
      native 'InstanceMirror_invokeGetter';

  _invokeSetter(reflectee, setterName, value)
      native 'InstanceMirror_invokeSetter';

  static _computeType(reflectee)
      native 'InstanceMirror_computeType';
}

class _LocalClosureMirror extends _LocalInstanceMirror
    implements ClosureMirror {
  _LocalClosureMirror(reflectee) : super(reflectee);

  MethodMirror _function;
  MethodMirror get function {
    if (_function == null) {
      _function = _computeFunction(reflectee);
    }
    return _function;
  }

  InstanceMirror apply(List<Object> positionalArguments,
                       [Map<Symbol, Object> namedArguments]) {
    return this.invoke(#call, positionalArguments, namedArguments);
  }

  String toString() => "ClosureMirror on '${Error.safeToString(_reflectee)}'";

  static _computeFunction(reflectee)
      native 'ClosureMirror_function';
}

class _LocalClassMirror extends _LocalObjectMirror
    implements ClassMirror {
  final Type _reflectedType;
  Symbol _simpleName;
  DeclarationMirror _owner;
  final bool isAbstract;
  final bool _isGeneric;
  final bool _isMixinAlias;
  final bool _isGenericDeclaration;
  final bool isEnum;
  Type _instantiator;

  _LocalClassMirror(reflectee,
                    reflectedType,
                    String simpleName,
                    this._owner,
                    this.isAbstract,
                    this._isGeneric,
                    this._isMixinAlias,
                    this._isGenericDeclaration,
                    this.isEnum)
      : this._simpleName = _s(simpleName),
        this._reflectedType = reflectedType,
        this._instantiator = reflectedType,
        super(reflectee);


  bool get hasReflectedType => !_isGenericDeclaration;
  Type get reflectedType {
    if (!hasReflectedType) {
      throw new UnsupportedError(
          "Declarations of generics have no reflected type");
    }
    return _reflectedType;
  }

  Symbol get simpleName {
    // All but anonymous mixin applications have their name set at construction.
    if(_simpleName == null) {
      _simpleName = this._mixinApplicationName;
    }
    return _simpleName;
  }

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
    }
    return _qualifiedName;
  }

  DeclarationMirror get owner {
    if (_owner == null) {
      var uri = _LocalClassMirror._libraryUri(_reflectee);
      _owner = currentMirrorSystem().libraries[Uri.parse(uri)];
    }
    return _owner;
  }

  bool get isPrivate => _n(simpleName).startsWith('_');

  bool get isTopLevel => true;

  SourceLocation get location {
    return _location(_reflectee);
  }

  ClassMirror _trueSuperclassField;
  ClassMirror get _trueSuperclass {
    if (_trueSuperclassField == null) {
      Type supertype = isOriginalDeclaration
          ? _supertype(_reflectedType)
          : _supertypeInstantiated(_reflectedType);
      if (supertype == null) {
        // Object has no superclass.
        return null;
      }
      _trueSuperclassField = reflectType(supertype);
      _trueSuperclassField._instantiator = _instantiator;
    }
    return _trueSuperclassField;
  }
  ClassMirror get superclass {
    return _isMixinAlias ? _trueSuperclass._trueSuperclass : _trueSuperclass;
  }

  var _superinterfaces;
  List<ClassMirror> get superinterfaces {
    if (_superinterfaces == null) {
      _superinterfaces = isOriginalDeclaration
          ? _nativeInterfaces(_reflectedType)
          : _nativeInterfacesInstantiated(_reflectedType);
      _superinterfaces =
          new UnmodifiableListView(_superinterfaces.map(reflectType));
    }
    return _superinterfaces;
  }

  get _mixinApplicationName {
    var mixins = new List<ClassMirror>();
    var klass = this;
    while (_nativeMixin(klass._reflectedType) != null) {
      mixins.add(klass.mixin);
      klass = klass.superclass;
    }
    return _s(
      _n(klass.qualifiedName)
      + ' with '
      + mixins.reversed.map((m)=>_n(m.qualifiedName)).join(', '));
  }

  var _mixin;
  ClassMirror get mixin {
    if (_mixin == null) {
      if (_isMixinAlias) {
        Type mixinType = _nativeMixinInstantiated(
            _trueSuperclass._reflectedType, _instantiator);
        _mixin = reflectType(mixinType);
      } else {
        Type mixinType = _nativeMixinInstantiated(_reflectedType,
                                                  _instantiator);
        if (mixinType == null) {
          // The reflectee is not a mixin application.
          _mixin = this;
        } else {
          _mixin = reflectType(mixinType);
        }
      }
    }
    return _mixin;
  }

  var _cachedStaticMembers;
  Map<Symbol, MethodMirror> get staticMembers {
    if (_cachedStaticMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      declarations.values.forEach((decl) {
        if (decl is MethodMirror && decl.isStatic && !decl.isConstructor) {
          result[decl.simpleName] = decl;
        }
        if (decl is VariableMirror && decl.isStatic) {
          var getterName = decl.simpleName;
          result[getterName] =
              new _SyntheticAccessor(this, getterName, true, true, false, decl);
          if (!decl.isFinal) {
            var setterName = _asSetter(decl.simpleName, this.owner);
            result[setterName] = new _SyntheticAccessor(
                this, setterName, false, true, false, decl);
          }
        }
      });
      _cachedStaticMembers =
          new UnmodifiableMapView<Symbol, MethodMirror>(result);
    }
    return _cachedStaticMembers;
  }

  var _cachedInstanceMembers;
  Map<Symbol, MethodMirror> get instanceMembers {
    if (_cachedInstanceMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      if (superclass != null) {
        result.addAll(superclass.instanceMembers);
      }
      declarations.values.forEach((decl) {
        if (decl is MethodMirror && !decl.isStatic &&
            !decl.isConstructor && !decl.isAbstract) {
          result[decl.simpleName] = decl;
        }
        if (decl is VariableMirror && !decl.isStatic) {
          var getterName = decl.simpleName;
          result[getterName] =
              new _SyntheticAccessor(this, getterName, true, false, false, decl);
          if (!decl.isFinal) {
            var setterName = _asSetter(decl.simpleName, this.owner);
            result[setterName] = new _SyntheticAccessor(
                this, setterName, false, false, false, decl);
          }
        }
      });
      _cachedInstanceMembers =
          new UnmodifiableMapView<Symbol, MethodMirror>(result);
    }
    return _cachedInstanceMembers;
  }

  Map<Symbol, DeclarationMirror> _declarations;
  Map<Symbol, DeclarationMirror> get declarations {
    if (_declarations != null) return _declarations;

    var decls = new Map<Symbol, DeclarationMirror>();

    var whoseMembers = _isMixinAlias ? _trueSuperclass : this;
    var members = mixin._computeMembers(_instantiator,
                                        whoseMembers.mixin._reflectee);
    for (var member in members) {
      decls[member.simpleName] = member;
    }

    var constructors = _computeConstructors(_instantiator, _reflectee);
    var stringName = _n(simpleName);
    for (var constructor in constructors) {
      constructor._patchConstructorName(stringName);
      decls[constructor.simpleName] = constructor;
    }

    for (var typeVariable in typeVariables) {
      decls[typeVariable.simpleName] = typeVariable;
    }

    return _declarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(decls);
  }

  bool get _isAnonymousMixinApplication {
    if (_isMixinAlias) return false;  // Named mixin application.
    if (mixin == this) return false;  // Not a mixin application.
    return true;
  }

  List<TypeVariableMirror> _typeVariables = null;
  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      if (_isAnonymousMixinApplication) return _typeVariables = emptyList;
      _typeVariables = new List<TypeVariableMirror>();

      List params = _ClassMirror_type_variables(_reflectee);
      ClassMirror owner = originalDeclaration;
      var mirror;
      for (var i = 0; i < params.length; i += 2) {
        mirror = new _LocalTypeVariableMirror(
            params[i + 1], params[i], owner);
        _typeVariables.add(mirror);
      }
      _typeVariables = new UnmodifiableListView(_typeVariables);
    }
    return _typeVariables;
  }

  List<TypeMirror> _typeArguments = null;
  List<TypeMirror> get typeArguments {
    if(_typeArguments == null) {
      if(_isGenericDeclaration || _isAnonymousMixinApplication) {
        _typeArguments = emptyList;
      } else {
        _typeArguments =
            new UnmodifiableListView(_computeTypeArguments(_reflectedType));
      }
    }
    return _typeArguments;
  }

  bool get isOriginalDeclaration => !_isGeneric || _isGenericDeclaration;

  ClassMirror get originalDeclaration {
    if (isOriginalDeclaration) {
      return this;
    } else {
      return reflectClass(_reflectedType);
    }
  }

  String toString() => "ClassMirror on '${MirrorSystem.getName(simpleName)}'";

  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol, dynamic> namedArguments]) {
    // Native code will add the 1 or 2 implicit arguments depending on whether
    // we end up invoking a factory or constructor respectively.
    int numPositionalArguments = positionalArguments.length;
    int numNamedArguments = namedArguments != null ? namedArguments.length : 0;
    int numArguments = numPositionalArguments + numNamedArguments;
    List arguments = new List(numArguments);
    arguments.setRange(0, numPositionalArguments, positionalArguments);
    List names = new List(numNamedArguments);
    int argumentIndex = numPositionalArguments;
    int nameIndex = 0;
    if (numNamedArguments > 0) {
      namedArguments.forEach((name, value) {
        arguments[argumentIndex++] = value;
        names[nameIndex++] = _n(name);
      });
    }

    return reflect(_invokeConstructor(_reflectee,
                                      _reflectedType,
                                      _n(constructorName),
                                      arguments,
                                      names));
  }

  List<InstanceMirror> get metadata {
    // Get the metadata objects, convert them into InstanceMirrors using
    // reflect() and then make them into a Dart list.
    return new UnmodifiableListView(_metadata(_reflectee).map(reflect));
  }

  bool operator ==(other) {
    return this.runtimeType == other.runtimeType &&
           this._reflectee == other._reflectee &&
           this._reflectedType == other._reflectedType &&
           this._isGenericDeclaration == other._isGenericDeclaration;
  }

  int get hashCode => simpleName.hashCode;

  bool isSubtypeOf(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return false;
    return _subtypeTest(_reflectedType, other._reflectedType);
  }

  bool isAssignableTo(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return false;
    return _subtypeTest(_reflectedType, other._reflectedType)
        || _subtypeTest(other._reflectedType, _reflectedType);
  }

  bool isSubclassOf(ClassMirror other) {
    if (other is! ClassMirror) throw new ArgumentError(other);
    ClassMirror otherDeclaration = other.originalDeclaration;
    ClassMirror c = this;
    while (c != null) {
      c = c.originalDeclaration;
      if (c == otherDeclaration) return true;
      c = c.superclass;
    }
    return false;
  }

  static _libraryUri(reflectee)
      native "ClassMirror_libraryUri";

  static _supertype(reflectedType)
      native "ClassMirror_supertype";

  static _supertypeInstantiated(reflectedType)
      native "ClassMirror_supertype_instantiated";

  static _nativeInterfaces(reflectedType)
      native "ClassMirror_interfaces";

  static _nativeInterfacesInstantiated(reflectedType)
      native "ClassMirror_interfaces_instantiated";

  static _nativeMixin(reflectedType)
      native "ClassMirror_mixin";

  static _nativeMixinInstantiated(reflectedType, instantiator)
      native "ClassMirror_mixin_instantiated";

  _computeMembers(reflectee, instantiator)
      native "ClassMirror_members";

  _computeConstructors(reflectee, instantiator)
      native "ClassMirror_constructors";

  _invoke(reflectee, memberName, arguments, argumentNames)
      native 'ClassMirror_invoke';

  _invokeGetter(reflectee, getterName)
      native 'ClassMirror_invokeGetter';

  _invokeSetter(reflectee, setterName, value)
      native 'ClassMirror_invokeSetter';

  static _invokeConstructor(reflectee, type, constructorName, arguments, argumentNames)
      native 'ClassMirror_invokeConstructor';

  static _ClassMirror_type_variables(reflectee)
      native "ClassMirror_type_variables";

  static _computeTypeArguments(reflectee)
      native "ClassMirror_type_arguments";
}

class _LocalFunctionTypeMirror extends _LocalClassMirror
    implements FunctionTypeMirror {
  _LocalFunctionTypeMirror(reflectee, reflectedType)
      : super(reflectee, reflectedType, null, null, false, false, false, false, false);

  bool get _isAnonymousMixinApplication => false;

  // FunctionTypeMirrors have a simpleName generated from their signature.
  Symbol _simpleName = null;
  Symbol get simpleName {
    if (_simpleName == null) {
      _simpleName = _s(_makeSignatureString(returnType, parameters));
    }
    return _simpleName;
  }

  MethodMirror _callMethod;
  MethodMirror get callMethod {
    if (_callMethod == null) {
      _callMethod = this._FunctionTypeMirror_call_method(_reflectee);
    }
    return _callMethod;
  }

  TypeMirror _returnType = null;
  TypeMirror get returnType {
    if (_returnType == null) {
      _returnType = reflectType(
          _FunctionTypeMirror_return_type(_reflectee, _instantiator));
    }
    return _returnType;
  }

  List<ParameterMirror> _parameters = null;
  List<ParameterMirror> get parameters {
    if (_parameters == null) {
      _parameters = _FunctionTypeMirror_parameters(_reflectee);
      _parameters = new UnmodifiableListView(_parameters);
    }
    return _parameters;
  }

  bool get isOriginalDeclaration => true;
  get originalDeclaration => this;
  get typeVariables => emptyList;
  get typeArguments => emptyList;
  get metadata => emptyList;

  String toString() => "FunctionTypeMirror on '${_n(simpleName)}'";

  MethodMirror _FunctionTypeMirror_call_method(reflectee)
      native "FunctionTypeMirror_call_method";

  static Type _FunctionTypeMirror_return_type(reflectee, instantiator)
      native "FunctionTypeMirror_return_type";

  List<ParameterMirror> _FunctionTypeMirror_parameters(reflectee)
      native "FunctionTypeMirror_parameters";
}

abstract class _LocalDeclarationMirror extends _LocalMirror
    implements DeclarationMirror {
  final _reflectee;
  Symbol _simpleName;

  _LocalDeclarationMirror(this._reflectee, this._simpleName);

  Symbol get simpleName => _simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
    }
    return _qualifiedName;
  }

  bool get isPrivate => _n(simpleName).startsWith('_');

  SourceLocation get location {
    return _location(_reflectee);
  }

  List<InstanceMirror> get metadata {
    // Get the metadata objects, convert them into InstanceMirrors using
    // reflect() and then make them into a Dart list.
    return new UnmodifiableListView(_metadata(_reflectee).map(reflect));
  }

  bool operator ==(other) {
    return this.runtimeType == other.runtimeType &&
           this._reflectee == other._reflectee;
  }

  int get hashCode => simpleName.hashCode;
}

class _LocalTypeVariableMirror extends _LocalDeclarationMirror
    implements TypeVariableMirror {
  _LocalTypeVariableMirror(reflectee,
                           String simpleName,
                           this._owner)
      : super(reflectee, _s(simpleName));

  DeclarationMirror _owner;
  DeclarationMirror get owner {
    if (_owner == null) {
      _owner = _TypeVariableMirror_owner(_reflectee).originalDeclaration;
    }
    return _owner;
  }

  bool get isStatic => false;
  bool get isTopLevel => false;

  TypeMirror _upperBound = null;
  TypeMirror get upperBound {
    if (_upperBound == null) {
      _upperBound = reflectType(_TypeVariableMirror_upper_bound(_reflectee));
    }
    return _upperBound;
  }

  bool get hasReflectedType => false;
  Type get reflectedType {
    throw new UnsupportedError('Type variables have no reflected type');
  }
  Type get _reflectedType => _reflectee;

  List<TypeVariableMirror> get typeVariables => emptyList;
  List<TypeMirror> get typeArguments => emptyList;

  bool get isOriginalDeclaration => true;
  TypeMirror get originalDeclaration => this;

  String toString() => "TypeVariableMirror on '${_n(simpleName)}'";

  operator ==(other) {
    return other is TypeVariableMirror
        && simpleName == other.simpleName
        && owner == other.owner;
  }
  int get hashCode => simpleName.hashCode;

  bool isSubtypeOf(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return false;
    return _subtypeTest(_reflectedType, other._reflectedType);
  }

  bool isAssignableTo(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return false;
    return _subtypeTest(_reflectedType, other._reflectedType)
        || _subtypeTest(other._reflectedType, _reflectedType);
  }

  static DeclarationMirror _TypeVariableMirror_owner(reflectee)
      native "TypeVariableMirror_owner";

  static Type _TypeVariableMirror_upper_bound(reflectee)
      native "TypeVariableMirror_upper_bound";
}


class _LocalTypedefMirror extends _LocalDeclarationMirror
    implements TypedefMirror {
  final Type _reflectedType;
  final bool _isGeneric;
  final bool _isGenericDeclaration;

  _LocalTypedefMirror(reflectee,
                      this._reflectedType,
                      String simpleName,
                      this._isGeneric,
                      this._isGenericDeclaration,
                      this._owner)
      : super(reflectee, _s(simpleName));

  bool get isTopLevel => true;

  DeclarationMirror _owner;
  DeclarationMirror get owner {
    if (_owner == null) {
      var uri = _LocalClassMirror._libraryUri(_reflectee);
      _owner = currentMirrorSystem().libraries[Uri.parse(uri)];
    }
    return _owner;
  }

  TypeMirror _referent = null;
  TypeMirror get referent {
    if (_referent == null) {
      _referent = _nativeReferent(_reflectedType);
      _referent._instantiator = _reflectedType;
    }
    return _referent;
  }

  bool get hasReflectedType => !_isGenericDeclaration;
  Type get reflectedType {
    if (!hasReflectedType) {
      throw new UnsupportedError(
          "Declarations of generics have no reflected type");
    }
    return _reflectedType;
  }

  bool get isOriginalDeclaration => !_isGeneric || _isGenericDeclaration;

  TypedefMirror get originalDeclaration {
    if (isOriginalDeclaration) {
      return this;
    } else {
      return _nativeDeclaration(_reflectedType);
    }
  }

  List<TypeVariableMirror> _typeVariables = null;
  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      _typeVariables = new List<TypeVariableMirror>();
      List params = _LocalClassMirror._ClassMirror_type_variables(_reflectee);
      TypedefMirror owner = originalDeclaration;
      var mirror;
      for (var i = 0; i < params.length; i += 2) {
        mirror = new _LocalTypeVariableMirror(
            params[i + 1], params[i], owner);
        _typeVariables.add(mirror);
      }
    }
    return _typeVariables;
  }

  List<TypeMirror> _typeArguments = null;
  List<TypeMirror> get typeArguments {
    if(_typeArguments == null) {
      if(_isGenericDeclaration) {
        _typeArguments = emptyList;
      } else {
        _typeArguments = new UnmodifiableListView(
            _LocalClassMirror._computeTypeArguments(_reflectedType));
      }
    }
    return _typeArguments;
  }

  String toString() => "TypedefMirror on '${_n(simpleName)}'";

  bool isSubtypeOf(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return false;
    return _subtypeTest(_reflectedType, other._reflectedType);
  }

  bool isAssignableTo(TypeMirror other) {
    if (other == currentMirrorSystem().dynamicType) return true;
    if (other == currentMirrorSystem().voidType) return false;
    return _subtypeTest(_reflectedType, other._reflectedType)
        || _subtypeTest(other._reflectedType, _reflectedType);
  }

  static _nativeReferent(reflectedType)
      native "TypedefMirror_referent";

  static _nativeDeclaration(reflectedType)
      native "TypedefMirror_declaration";
}

Symbol _asSetter(Symbol getter, LibraryMirror library) {
  var unwrapped = MirrorSystem.getName(getter);
  return MirrorSystem.getSymbol('${unwrapped}=', library);
}

class _LocalLibraryMirror extends _LocalObjectMirror implements LibraryMirror {
  final Symbol simpleName;
  final Uri uri;

  _LocalLibraryMirror(reflectee,
                      String simpleName,
                      String url)
      : this.simpleName = _s(simpleName),
        this.uri = Uri.parse(url),
        super(reflectee);

  // The simple name and the qualified name are the same for a library.
  Symbol get qualifiedName => simpleName;

  DeclarationMirror get owner => null;

  bool get isPrivate => false;
  bool get isTopLevel => false;

  Type get _instantiator => null;

  Map<Symbol, DeclarationMirror> _declarations;
  Map<Symbol, DeclarationMirror> get declarations {
    if (_declarations != null) return _declarations;

    var decls = new Map<Symbol, DeclarationMirror>();
    var members = _computeMembers(_reflectee);
    for (var member in members) {
      decls[member.simpleName] = member;
    }

    return _declarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(decls);
  }

  SourceLocation get location {
    return _location(_reflectee);
  }

  List<InstanceMirror> get metadata {
    // Get the metadata objects, convert them into InstanceMirrors using
    // reflect() and then make them into a Dart list.
    return new UnmodifiableListView(_metadata(_reflectee).map(reflect));
  }

  bool operator ==(other) {
    return this.runtimeType == other.runtimeType &&
           this._reflectee == other._reflectee;
  }

  int get hashCode => simpleName.hashCode;

  String toString() => "LibraryMirror on '${_n(simpleName)}'";

  var _cachedLibraryDependencies;
  get libraryDependencies {
    if (_cachedLibraryDependencies == null) {
      _cachedLibraryDependencies = _libraryDependencies(_reflectee);
    }
    return _cachedLibraryDependencies;
  }

  _libraryDependencies(reflectee)
      native 'LibraryMirror_libraryDependencies';

  _invoke(reflectee, memberName, arguments, argumentNames)
      native 'LibraryMirror_invoke';

  _invokeGetter(reflectee, getterName)
      native 'LibraryMirror_invokeGetter';

  _invokeSetter(reflectee, setterName, value)
      native 'LibraryMirror_invokeSetter';

  _computeMembers(reflectee)
      native "LibraryMirror_members";
}

class _LocalLibraryDependencyMirror
    extends _LocalMirror implements LibraryDependencyMirror {
  final LibraryMirror sourceLibrary;
  var _targetMirrorOrPrefix;
  final List<CombinatorMirror> combinators;
  final Symbol prefix;
  final bool isImport;
  final bool isDeferred;
  final List<InstanceMirror> metadata;

  _LocalLibraryDependencyMirror(this.sourceLibrary,
                                this._targetMirrorOrPrefix,
                                this.combinators,
                                prefixString,
                                this.isImport,
                                this.isDeferred,
                                unwrappedMetadata)
      : prefix = _s(prefixString),
        metadata = new UnmodifiableListView(unwrappedMetadata.map(reflect));

  bool get isExport => !isImport;

  LibraryMirror get targetLibrary {
    if (_targetMirrorOrPrefix is _LocalLibraryMirror) {
      return _targetMirrorOrPrefix;
    }
    var mirrorOrNull = _tryUpgradePrefix(_targetMirrorOrPrefix);
    if (mirrorOrNull != null) {
      _targetMirrorOrPrefix = mirrorOrNull;
    }
    return mirrorOrNull;
  }

  Future<LibraryMirror> loadLibrary() {
    if (_targetMirrorOrPrefix is _LocalLibraryMirror) {
      return new Future.value(_targetMirrorOrPrefix);
    }
    var savedPrefix = _targetMirrorOrPrefix;
    return savedPrefix.loadLibrary().then((_) {
      return _tryUpgradePrefix(savedPrefix);
    });
  }

  static _tryUpgradePrefix(libraryPrefix) native "LibraryMirror_fromPrefix";
}

class _LocalCombinatorMirror extends _LocalMirror implements CombinatorMirror {
  final List<Symbol> identifiers;
  final bool isShow;

  _LocalCombinatorMirror(identifierString, this.isShow)
      : this.identifiers = [_s(identifierString)];

  bool get isHide => !isShow;
}

class _LocalMethodMirror extends _LocalDeclarationMirror
    implements MethodMirror {
  final Type _instantiator;
  final bool isStatic;
  final int _kindFlags;

  _LocalMethodMirror(reflectee,
                     String simpleName,
                     this._owner,
                     this._instantiator,
                     this.isStatic,
                     this._kindFlags)
      : super(reflectee, _s(simpleName));

  static const kAbstract = 0;
  static const kGetter = 1;
  static const kSetter = 2;
  static const kConstructor = 3;
  static const kConstCtor = 4;
  static const kGenerativeCtor = 5;
  static const kRedirectingCtor = 6;
  static const kFactoryCtor = 7;
  static const kExternal = 8;

  // These offsets much be kept in sync with those in mirrors.h.
  bool get isAbstract =>               0 != (_kindFlags & (1 << kAbstract));
  bool get isGetter =>                 0 != (_kindFlags & (1 << kGetter));
  bool get isSetter =>                 0 != (_kindFlags & (1 << kSetter));
  bool get isConstructor =>            0 != (_kindFlags & (1 << kConstructor));
  bool get isConstConstructor =>       0 != (_kindFlags & (1 << kConstCtor));
  bool get isGenerativeConstructor =>  0 != (_kindFlags & (1 << kGenerativeCtor));
  bool get isRedirectingConstructor => 0 != (_kindFlags & (1 << kRedirectingCtor));
  bool get isFactoryConstructor =>     0 != (_kindFlags & (1 << kFactoryCtor));
  bool get isExternal =>               0 != (_kindFlags & (1 << kExternal));

  static const _operators = const ["%", "&", "*", "+", "-", "/", "<", "<<",
      "<=", "==", ">", ">=", ">>", "[]", "[]=", "^", "|", "~", "unary-", "~/"];
  bool get isOperator => _operators.contains(_n(simpleName));

  DeclarationMirror _owner;
  DeclarationMirror get owner {
    // For nested closures it is possible, that the mirror for the owner has not
    // been created yet.
    if (_owner == null) {
      _owner = _MethodMirror_owner(_reflectee, _instantiator);
    }
    return _owner;
  }

  bool get isPrivate => _n(simpleName).startsWith('_') ||
                        _n(constructorName).startsWith('_');

  bool get isTopLevel => owner is LibraryMirror;
  bool get isSynthetic => false;

  TypeMirror _returnType = null;
  TypeMirror get returnType {
    if (_returnType == null) {
      if (isConstructor) {
        _returnType = owner;
      } else {
        _returnType = reflectType(
            _MethodMirror_return_type(_reflectee, _instantiator));
      }
    }
    return _returnType;
  }

  List<ParameterMirror> _parameters = null;
  List<ParameterMirror> get parameters {
    if (_parameters == null) {
      _parameters = _MethodMirror_parameters(_reflectee);
      _parameters = new UnmodifiableListView(_parameters);
    }
    return _parameters;
  }

  bool get isRegularMethod => !isGetter && !isSetter && !isConstructor;

  Symbol _constructorName = null;
  Symbol get constructorName {
    if (_constructorName == null) {
      if (!isConstructor) {
        _constructorName = _s('');
      } else {
        var parts = MirrorSystem.getName(simpleName).split('.');
        if (parts.length > 2) {
          throw new _InternalMirrorError(
              'Internal error in MethodMirror.constructorName: '
              'malformed name <$simpleName>');
        } else if (parts.length == 2) {
          LibraryMirror definingLibrary = owner.owner;
          _constructorName = MirrorSystem.getSymbol(parts[1], definingLibrary);
        } else {
          _constructorName = _s('');
        }
      }
    }
    return _constructorName;
  }

  String get source => _MethodMirror_source(_reflectee);

  void _patchConstructorName(ownerName) {
    var cn = _n(constructorName);
    if (cn == '') {
      _simpleName = _s(ownerName);
    } else {
      _simpleName = _s(ownerName + "." + cn);
    }
  }

  String toString() => "MethodMirror on '${MirrorSystem.getName(simpleName)}'";

  static dynamic _MethodMirror_owner(reflectee, instantiator)
      native "MethodMirror_owner";

  static dynamic _MethodMirror_return_type(reflectee, instantiator)
      native "MethodMirror_return_type";

  List<ParameterMirror> _MethodMirror_parameters(reflectee)
      native "MethodMirror_parameters";

  static String _MethodMirror_source(reflectee)
      native "MethodMirror_source";
}

class _LocalVariableMirror extends _LocalDeclarationMirror
    implements VariableMirror {
  final DeclarationMirror owner;
  final bool isStatic;
  final bool isFinal;
  final bool isConst;

  _LocalVariableMirror(reflectee,
                       String simpleName,
                       this.owner,
                       this._type,
                       this.isStatic,
                       this.isFinal,
                       this.isConst)
      : super(reflectee, _s(simpleName));

  bool get isTopLevel => owner is LibraryMirror;

  Type get _instantiator {
    return owner._instantiator;
  }

  TypeMirror _type;
  TypeMirror get type {
    if (_type == null) {
       _type = reflectType(_VariableMirror_type(_reflectee, _instantiator));
    }
    return _type;
  }

  String toString() => "VariableMirror on '${MirrorSystem.getName(simpleName)}'";

  static _VariableMirror_type(reflectee, instantiator)
      native "VariableMirror_type";
}

class _LocalParameterMirror extends _LocalVariableMirror
    implements ParameterMirror {
  final int _position;
  final bool isOptional;
  final bool isNamed;
  final List _unmirroredMetadata;

  _LocalParameterMirror(reflectee,
                        String simpleName,
                        DeclarationMirror owner,
                        this._position,
                        this.isOptional,
                        this.isNamed,
                        bool isFinal,
                        this._defaultValueReflectee,
                        this._unmirroredMetadata)
      : super(reflectee,
              simpleName,
              owner,
              null,  // We override the type.
              false, // isStatic does not apply.
              isFinal,
              false  // Not const.
              );

  Object _defaultValueReflectee;
  InstanceMirror _defaultValue;
  InstanceMirror get defaultValue {
    if (!isOptional) {
      return null;
    }
    if (_defaultValue == null) {
      _defaultValue = reflect(_defaultValueReflectee);
    }
    return _defaultValue;
  }

  bool get hasDefaultValue => _defaultValueReflectee != null;

  SourceLocation get location {
    throw new UnsupportedError("ParameterMirror.location unimplemented");
  }

  List<InstanceMirror> get metadata {
    if (_unmirroredMetadata == null) return emptyList;
    return new UnmodifiableListView(_unmirroredMetadata.map(reflect));
  }

  Type get _instantiator {
    return owner._instantiator;
  }

  TypeMirror _type = null;
  TypeMirror get type {
    if (_type == null) {
      _type = reflectType(
          _ParameterMirror_type(_reflectee, _position, _instantiator));
    }
    return _type;
  }

  String toString() => "ParameterMirror on '${_n(simpleName)}'";

  static Type _ParameterMirror_type(_reflectee, _position, instantiator)
      native "ParameterMirror_type";
}

class _SpecialTypeMirror extends _LocalMirror
    implements TypeMirror, DeclarationMirror {
  final Symbol simpleName;

  _SpecialTypeMirror(String name) : simpleName = _s(name);

  bool get isPrivate => false;
  bool get isTopLevel => true;

  DeclarationMirror get owner => null;

  SourceLocation get location => null;
  List<InstanceMirror> get metadata => emptyList;

  bool get hasReflectedType => simpleName == #dynamic;
  Type get reflectedType {
    if (simpleName == #dynamic) return dynamic;
    throw new UnsupportedError("void has no reflected type");
  }

  List<TypeVariableMirror> get typeVariables => emptyList;
  List<TypeMirror> get typeArguments => emptyList;

  bool get isOriginalDeclaration => true;
  TypeMirror get originalDeclaration => this;

  Symbol get qualifiedName => simpleName;

  bool operator ==(other) {
    if (other is! _SpecialTypeMirror) {
      return false;
    }
    return this.simpleName == other.simpleName;
  }

  int get hashCode => simpleName.hashCode;

  String toString() => "TypeMirror on '${_n(simpleName)}'";

  bool isSubtypeOf(TypeMirror other) {
    return simpleName == #dynamic || other is _SpecialTypeMirror;
  }

  bool isAssignableTo(TypeMirror other) {
    return simpleName == #dynamic || other is _SpecialTypeMirror;
  }
}

class _Mirrors {
  static MirrorSystem _currentMirrorSystem = new _LocalMirrorSystem();
  static MirrorSystem currentMirrorSystem() {
    return _currentMirrorSystem;
  }

  // Creates a new local mirror for some Object.
  static InstanceMirror reflect(Object reflectee) {
    return reflectee is Function
        ? new _LocalClosureMirror(reflectee)
        : new _LocalInstanceMirror(reflectee);
  }

  static ClassMirror makeLocalClassMirror(Type key)
      native "Mirrors_makeLocalClassMirror";
  static TypeMirror makeLocalTypeMirror(Type key)
      native "Mirrors_makeLocalTypeMirror";

  static Expando<ClassMirror> _declarationCache = new Expando("ClassMirror");
  static Expando<TypeMirror> _instanitationCache = new Expando("TypeMirror");

  static ClassMirror reflectClass(Type key) {
    var classMirror = _declarationCache[key];
    if (classMirror == null) {
      classMirror = makeLocalClassMirror(key);
      _declarationCache[key] = classMirror;
      if (!classMirror._isGeneric) {
        _instanitationCache[key] = classMirror;
      }
    }
    return classMirror;
  }

  static TypeMirror reflectType(Type key) {
    var typeMirror = _instanitationCache[key];
    if (typeMirror == null) {
      typeMirror = makeLocalTypeMirror(key);
      _instanitationCache[key] = typeMirror;
      if (typeMirror is ClassMirror && !typeMirror._isGeneric) {
        _declarationCache[key] = typeMirror;
      }
    }
    return typeMirror;
  }
}
