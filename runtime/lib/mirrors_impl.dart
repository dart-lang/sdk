// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

import "dart:collection" show UnmodifiableListView, UnmodifiableMapView;
import "dart:_internal" show LRUMap;

final emptyList = new UnmodifiableListView([]);
final emptyMap = new UnmodifiableMapView({});

class _InternalMirrorError {
  final String _msg;
  const _InternalMirrorError(String this._msg);
  String toString() => _msg;
}

Map _filterMap(Map<Symbol, dynamic> old_map, bool filter(Symbol key, value)) {
  Map new_map = new Map<Symbol, dynamic>();
  old_map.forEach((key, value) {
    if (filter(key, value)) {
      new_map[key] = value;
    }
  });
  return new UnmodifiableMapView(new_map);
}

Map _makeMemberMap(List mirrors) {
  return new UnmodifiableMapView<Symbol, DeclarationMirror>(
      new Map<Symbol, DeclarationMirror>.fromIterable(
          mirrors, key: (e) => e.simpleName));
}

String _n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

Symbol _s(String name) {
  if (name == null) return null;
  return new _symbol_dev.Symbol.unvalidated(name);
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

List _metadata(reflectee)
    native 'DeclarationMirror_metadata';

bool _subtypeTest(Type a, Type b)
    native 'TypeMirror_subtypeTest';

bool _moreSpecificTest(Type a, Type b)
    native 'TypeMirror_moreSpecificTest';

class _LocalMirrorSystem extends MirrorSystem {
  final Map<Uri, LibraryMirror> libraries;
  final IsolateMirror isolate;

  _LocalMirrorSystem(List<LibraryMirror> libraries, this.isolate)
      : this.libraries = new Map<Uri, LibraryMirror>.fromIterable(
            libraries, key: (e) => e.uri);

  TypeMirror _dynamicType = null;
  TypeMirror get dynamicType {
    if (_dynamicType == null) {
      _dynamicType = new _SpecialTypeMirror('dynamic');
    }
    return _dynamicType;
  }

  TypeMirror _voidType = null;
  TypeMirror get voidType {
    if (_voidType == null) {
      _voidType = new _SpecialTypeMirror('void');
    }
    return _voidType;
  }

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

  List<InstanceMirror> get metadata => emptyList;
  String get source => null;
  SourceLocation get location => null;
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
  List<InstanceMirror> get metadata => emptyList;
  SourceLocation get location => throw new UnimplementedError();
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
  bool hasReflectee = true;

  get reflectee => _reflectee;

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

  static var _getFieldClosures = new LRUMap.withShift(7);
  static var _setFieldClosures = new LRUMap.withShift(7);
  static var _getFieldCallCounts = new LRUMap.withShift(8);
  static var _setFieldCallCounts = new LRUMap.withShift(8);
  static const _closureThreshold = 20;

  _getFieldSlow(unwrapped) {
    // Slow path factored out to give the fast path a better chance at being
    // inlined.
    var callCount = _getFieldCallCounts[unwrapped];
    if (callCount == null) {
      callCount = 0;
    }
    if (callCount == _closureThreshold) {
      // We've seen a successful setter invocation a few times: time to invest
      // in a closure.
      var f;
      var atPosition = unwrapped.indexOf('@');
      if (atPosition == -1) {
        // Public symbol.
        f = _eval('(x) => x.$unwrapped', null);
      } else {
        // Private symbol.
        var withoutKey = unwrapped.substring(0, atPosition);
        var privateKey = unwrapped.substring(atPosition);
        f = _eval('(x) => x.$withoutKey', privateKey);
      }
      _getFieldClosures[unwrapped] = f;
      return reflect(f(_reflectee));
    }
    var result = reflect(_invokeGetter(_reflectee, unwrapped));
    // Only update call count if we don't throw to avoid creating closures for
    // non-existent getters.
    _getFieldCallCounts[unwrapped] = callCount + 1;
    return result;
  }

  InstanceMirror getField(Symbol memberName) {
    var unwrapped = _n(memberName);
    var f = _getFieldClosures[unwrapped];
    return (f == null) ? _getFieldSlow(unwrapped) : reflect(f(_reflectee));
  }

  _setFieldSlow(unwrapped, arg) {
    // Slow path factored out to give the fast path a better chance at being
    // inlined.
    var callCount = _setFieldCallCounts[unwrapped];
    if (callCount == null) {
      callCount = 0;
    }
    if (callCount == _closureThreshold) {
      // We've seen a successful getter invocation a few times: time to invest
      // in a closure.
      var f;
      var atPosition = unwrapped.indexOf('@');
      if (atPosition == -1) {
        // Public symbol.
        f = _eval('(x, v) => x.$unwrapped = v', null);
      } else {
        // Private symbol.
        var withoutKey = unwrapped.substring(0, atPosition);
        var privateKey = unwrapped.substring(atPosition);
        f = _eval('(x, v) => x.$withoutKey = v', privateKey);
      }
      _setFieldClosures[unwrapped] = f;
      return reflect(f(_reflectee, arg));
    }
    _invokeSetter(_reflectee, unwrapped, arg);
    var result = reflect(arg);
    // Only update call count if we don't throw to avoid creating closures for
    // non-existent setters.
    _setFieldCallCounts[unwrapped] = callCount + 1;
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
  Type _instantiator;

  _LocalClassMirror(reflectee,
                    reflectedType,
                    String simpleName,
                    this._owner,
                    this.isAbstract,
                    this._isGeneric,
                    this._isMixinAlias,
                    this._isGenericDeclaration)
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
      _owner = _library(_reflectee);
    }
    return _owner;
  }

  bool get isPrivate => _n(simpleName).startsWith('_');

  final bool isTopLevel = true;

  SourceLocation get location {
    throw new UnimplementedError('ClassMirror.location is not implemented');
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
        Type mixinType = _nativeMixinInstantiated(_trueSuperclass._reflectedType,
                                                  _instantiator);
        _mixin = reflectType(mixinType);
      } else {
        Type mixinType = _nativeMixinInstantiated(_reflectedType, _instantiator);
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
    decls.addAll(_members);
    decls.addAll(_constructors);
    typeVariables.forEach((tv) => decls[tv.simpleName] = tv);
    return _declarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(decls);
  }

  Map<Symbol, Mirror> _cachedMembers;
  Map<Symbol, Mirror> get _members {
    if (_cachedMembers == null) {
      var whoseMembers = _isMixinAlias ? _trueSuperclass : this;
      _cachedMembers = _makeMemberMap(mixin._computeMembers(whoseMembers._reflectee));
    }
    return _cachedMembers;
  }

  Map<Symbol, MethodMirror> _cachedMethods;
  Map<Symbol, MethodMirror> get _methods {
    if (_cachedMethods == null) {
      _cachedMethods = _filterMap(
          _members,
          (key, value) => (value is MethodMirror && value.isRegularMethod));
    }
    return _cachedMethods;
  }

  Map<Symbol, MethodMirror> _cachedConstructors;
  Map<Symbol, MethodMirror> get _constructors {
    if (_cachedConstructors == null) {
      var constructorsList = _computeConstructors(_reflectee);
      var stringName = _n(simpleName);
      constructorsList.forEach((c) => c._patchConstructorName(stringName));
      _cachedConstructors =
          new Map.fromIterable(constructorsList, key: (e) => e.simpleName);
    }
    return _cachedConstructors;
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
    return _moreSpecificTest(_reflectedType, other._reflectedType)
        || _moreSpecificTest(other._reflectedType, _reflectedType);
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

  static _library(reflectee)
      native "ClassMirror_library";

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

  _computeMembers(reflectee)
      native "ClassMirror_members";

  _computeConstructors(reflectee)
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
      : super(reflectee, reflectedType, null, null, false, false, false, false);

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
  Map<Symbol, Mirror> get members => emptyMap;
  Map<Symbol, MethodMirror> get constructors => emptyMap;

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

  SourceLocation get location {
    throw new UnimplementedError(
        'TypeVariableMirror.location is not implemented');
  }

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
    return _moreSpecificTest(_reflectedType, other._reflectedType)
        || _moreSpecificTest(other._reflectedType, _reflectedType);
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
      _owner = _LocalClassMirror._library(_reflectee);
    }
    return _owner;
  }

  SourceLocation get location {
    throw new UnimplementedError('TypedefMirror.location is not implemented');
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
    return _moreSpecificTest(_reflectedType, other._reflectedType)
        || _moreSpecificTest(other._reflectedType, _reflectedType);
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

  SourceLocation get location {
    throw new UnimplementedError('LibraryMirror.location is not implemented');
  }

  Map<Symbol, DeclarationMirror> _declarations;
  Map<Symbol, DeclarationMirror> get declarations {
    if (_declarations != null) return _declarations;
    return _declarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(_members);
  }

  Map<Symbol, Mirror> _cachedMembers;
  Map<Symbol, Mirror> get _members {
    if (_cachedMembers == null) {
      _cachedMembers = _makeMemberMap(_computeMembers(_reflectee));
    }
    return _cachedMembers;
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
  final LibraryMirror targetLibrary;
  final List<CombinatorMirror> combinators;
  final Symbol prefix;
  final bool isImport;
  final List<InstanceMirror> metadata;

  _LocalLibraryDependencyMirror(this.sourceLibrary,
                                this.targetLibrary,
                                this.combinators,
                                prefixString,
                                this.isImport,
                                unwrappedMetadata)
      : prefix = _s(prefixString),
        metadata = new UnmodifiableListView(unwrappedMetadata.map(reflect));

  bool get isExport => !isImport;
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
  final bool isStatic;
  final bool isAbstract;
  final bool isGetter;
  final bool isSetter;
  final bool isConstructor;
  final bool isConstConstructor;
  final bool isGenerativeConstructor;
  final bool isRedirectingConstructor;
  final bool isFactoryConstructor;
  final bool isOperator;

  static const _operators = const ["%", "&", "*", "+", "-", "/", "<", "<<",
      "<=", "==", ">", ">=", ">>", "[]", "[]=", "^", "|", "~", "unary-", "~/"];

  _LocalMethodMirror(reflectee,
                     String simpleName,
                     this._owner,
                     this.isStatic,
                     this.isAbstract,
                     this.isGetter,
                     this.isSetter,
                     this.isConstructor,
                     this.isConstConstructor,
                     this.isGenerativeConstructor,
                     this.isRedirectingConstructor,
                     this.isFactoryConstructor)
      : this.isOperator = _operators.contains(simpleName),
        super(reflectee, _s(simpleName));

  DeclarationMirror _owner;
  DeclarationMirror get owner {
    // For nested closures it is possible, that the mirror for the owner has not
    // been created yet.
    if (_owner == null) {
      _owner = _MethodMirror_owner(_reflectee);
    }
    return _owner;
  }

  bool get isPrivate => _n(simpleName).startsWith('_') ||
                        _n(constructorName).startsWith('_');

  bool get isTopLevel => owner is LibraryMirror;
  bool get isSynthetic => false;

  SourceLocation _location;
  SourceLocation get location {
    if (_location == null) {
      _location = _MethodMirror_location(_reflectee);
    }
    return _location;
  }

  Type get _instantiator {
    var o = owner;
    while (o is MethodMirror) o = o.owner;
    return o._instantiator;
  }

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

  String _source = null;
  String get source {
    if (_source == null) {
      _source = _MethodMirror_source(_reflectee);
    }
    return _source;
  }

  void _patchConstructorName(ownerName) {
    var cn = _n(constructorName);
    if(cn == ''){
      _simpleName = _s(ownerName);
    } else {
      _simpleName = _s(ownerName + "." + cn);
    }
  }

  String toString() => "MethodMirror on '${MirrorSystem.getName(simpleName)}'";

  static dynamic _MethodMirror_owner(reflectee)
      native "MethodMirror_owner";

  static dynamic _MethodMirror_return_type(reflectee, instantiator)
      native "MethodMirror_return_type";

  List<ParameterMirror> _MethodMirror_parameters(reflectee)
      native "MethodMirror_parameters";

  static String _MethodMirror_source(reflectee)
      native "MethodMirror_source";

  static SourceLocation _MethodMirror_location(reflectee)
      native "MethodMirror_location";
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

  SourceLocation get location {
    throw new UnimplementedError('VariableMirror.location is not implemented');
  }

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

  List<InstanceMirror> get metadata {
    if (_unmirroredMetadata == null) return emptyList;
    return new UnmodifiableListView(_unmirroredMetadata.map(reflect));
  }

  Type get _instantiator {
    var o = owner;
    while (o is MethodMirror) o = o.owner;
    return o._instantiator;
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

  SourceLocation get location {
    throw new UnimplementedError('TypeMirror.location is not implemented');
  }

  Symbol get qualifiedName => simpleName;

  // TODO(11955): Remove once dynamicType and voidType are canonical objects in
  // the object store.
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
  static MirrorSystem _currentMirrorSystem = null;

  // Creates a new local MirrorSystem.
  static MirrorSystem makeLocalMirrorSystem()
      native 'Mirrors_makeLocalMirrorSystem';

  // The MirrorSystem for the current isolate.
  static MirrorSystem currentMirrorSystem() {
    if (_currentMirrorSystem == null) {
      _currentMirrorSystem = makeLocalMirrorSystem();
    }
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
