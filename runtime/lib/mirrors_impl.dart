// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

import "dart:collection";

// These values are allowed to be passed directly over the wire.
bool _isSimpleValue(var value) {
  return (value == null || value is num || value is String || value is bool);
}

Map _filterMap(Map<Symbol, dynamic> old_map, bool filter(Symbol key, value)) {
  Map new_map = new Map<Symbol, dynamic>();
  old_map.forEach((key, value) {
    if (filter(key, value)) {
      new_map[key] = value;
    }
  });
  return new_map;
}

Map _makeMemberMap(List mirrors) => new Map<Symbol, dynamic>.fromIterable(
    mirrors, key: (e) => e.simpleName);

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

// This will verify the argument types, unwrap them, and ensure we have a fixed
// array.
List _unwrapAsyncPositionals(wrappedArgs) {
  List unwrappedArgs = new List(wrappedArgs.length);
  for(int i = 0; i < wrappedArgs.length; i++){
    var wrappedArg = wrappedArgs[i];
    if(_isSimpleValue(wrappedArg)) {
      unwrappedArgs[i] = wrappedArg;
    } else if(wrappedArg is InstanceMirror) {
      unwrappedArgs[i] = wrappedArg._reflectee;
    } else {
      throw "positional argument $i ($wrappedArg) was "
            "not a simple value or InstanceMirror";
    }
  }
  return unwrappedArgs;
}

Map _unwrapAsyncNamed(wrappedArgs) {
  if (wrappedArgs==null) return null;
  Map unwrappedArgs = new Map();
  wrappedArgs.forEach((name, wrappedArg){
    if(_isSimpleValue(wrappedArg)) {
      unwrappedArgs[name] = wrappedArg;
    } else if(wrappedArg is InstanceMirror) {
      unwrappedArgs[name] = wrappedArg._reflectee;
    } else {
      throw "named argument ${_n(name)} ($wrappedArg) was "
            "not a simple value or InstanceMirror";
    }
  });
  return unwrappedArgs;
}

class _LocalMirrorSystemImpl extends MirrorSystem {
  // Change parameter back to "this.libraries" when native code is changed.
  _LocalMirrorSystemImpl(List<LibraryMirror> libraries, this.isolate)
      : this.libraries = new Map<Uri, LibraryMirror>.fromIterable(
            libraries, key: (e) => e.uri);

  final Map<Uri, LibraryMirror> libraries;
  final IsolateMirror isolate;

  TypeMirror _dynamicType = null;
  TypeMirror get dynamicType {
    if (_dynamicType == null) {
      _dynamicType = new _SpecialTypeMirrorImpl('dynamic');
    }
    return _dynamicType;
  }

  TypeMirror _voidType = null;
  TypeMirror get voidType {
    if (_voidType == null) {
      _voidType = new _SpecialTypeMirrorImpl('void');
    }
    return _voidType;
  }

  String toString() => "MirrorSystem for isolate '${isolate.debugName}'";
}

abstract class _LocalMirrorImpl implements Mirror {
  int get hashCode {
    throw new UnimplementedError('Mirror.hashCode is not implemented');
  }

  // Local mirrors always return the same MirrorSystem.  This field
  // is more interesting once we implement remote mirrors.
  MirrorSystem get mirrors => _Mirrors.currentMirrorSystem();
}

class _LocalIsolateMirrorImpl extends _LocalMirrorImpl
    implements IsolateMirror {
  _LocalIsolateMirrorImpl(this.debugName, this.rootLibrary);

  final String debugName;
  final bool isCurrent = true;
  final LibraryMirror rootLibrary;

  String toString() => "IsolateMirror on '$debugName'";
}

abstract class _LocalObjectMirrorImpl extends _LocalMirrorImpl
    implements ObjectMirror {
  _LocalObjectMirrorImpl(this._reflectee);

  final _reflectee; // May be a MirrorReference or an ordinary object.

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

    return reflect(this._invoke(_reflectee,
                                _n(memberName),
                                arguments,
                                names));
  }

  InstanceMirror getField(Symbol memberName) {
    return reflect(this._invokeGetter(_reflectee,
                                      _n(memberName)));
  }

  InstanceMirror setField(Symbol memberName, Object value) {
    this._invokeSetter(_reflectee,
                       _n(memberName),
                       value);
    return reflect(value);
  }

  Future<InstanceMirror> invokeAsync(Symbol memberName,
                                     List positionalArguments,
                                     [Map<Symbol, dynamic> namedArguments]) {
    return new Future(() {
      return this.invoke(memberName,
                         _unwrapAsyncPositionals(positionalArguments),
                         _unwrapAsyncNamed(namedArguments));
    });
  }

  Future<InstanceMirror> getFieldAsync(Symbol memberName) {
   try {
      var result = this._invokeGetter(_reflectee,
                                      _n(memberName));
      return new Future.value(reflect(result));
    } catch(e) {
      return new Future.error(e);
    }
  }

  Future<InstanceMirror> setFieldAsync(Symbol memberName, Object value) {
    try {
      var unwrappedValue;
      if(_isSimpleValue(value)) {
        unwrappedValue = value;
      } else if(value is InstanceMirror) {
        unwrappedValue = value._reflectee;
      } else {
        throw "setter argument ($value) must be"
              "a simple value or InstanceMirror";
      }

      this._invokeSetter(_reflectee,
                         _n(memberName),
                         unwrappedValue);
      return new Future.value(reflect(unwrappedValue));
    } catch(e) {
      return new Future.error(e);
    }
  }

  static _validateArgument(int i, Object arg)
  {
    if (arg is Mirror) {
        if (arg is! InstanceMirror) {
          throw new MirrorException(
              'positional argument $i ($arg) was not an InstanceMirror');
        }
      } else if (!_isSimpleValue(arg)) {
        throw new MirrorException(
            'positional argument $i ($arg) was not a simple value');
      }
  }
}

class _LocalInstanceMirrorImpl extends _LocalObjectMirrorImpl
    implements InstanceMirror {
  // TODO(ahe): This is a hack, see delegate below.
  static Function _invokeOnClosure;

  _LocalInstanceMirrorImpl(reflectee) : super(reflectee);

  ClassMirror _type;
  ClassMirror get type {
    if (_type == null) {
      // Note it not safe to use reflectee.runtimeType because runtimeType may
      // be overridden.
      _type = _Mirrors._reflectType(_computeType(reflectee));
    }
    return _type;
  }

  // LocalInstanceMirrors always reflect local instances
  bool hasReflectee = true;

  get reflectee => _reflectee;

  delegate(Invocation invocation) {
    if (_invokeOnClosure == null) {
      // TODO(ahe): This is a total hack.  We're using the mirror
      // system to access a private field in a different library.  For
      // some reason, that works.  On the other hand, calling a
      // private method does not work.

      _LocalInstanceMirrorImpl mirror =
          reflect(invocation);
      _invokeOnClosure = reflectClass(invocation.runtimeType)
          .getField(const Symbol('_invokeOnClosure')).reflectee;
    }
    return _invokeOnClosure(reflectee, invocation);
  }

  String toString() => 'InstanceMirror on ${Error.safeToString(_reflectee)}';

  bool operator ==(other) {
    return other is _LocalInstanceMirrorImpl &&
           identical(_reflectee, other._reflectee);
  }

  int get hashCode {
    // If the reflectee is a double or bignum, use the base hashCode to preserve
    // the illusion that boxed numbers with the same value are identical. If the
    // reflectee is a Smi, use the base hashCode because Object.hashCode does
    // not work for non-heap objects. Otherwise, use Object.hashCode to maintain
    // correctness even if a user-defined hashCode returns different values for
    // successive invocations.
    var h = _reflectee is num ? _reflectee.hashCode : _identityHash(_reflectee);
    // Avoid hash collisions with the reflectee. This constant is in Smi range
    // and happens to be the inner padding from RFC 2104.
    return h ^ 0x36363636;
  }

  static _identityHash(reflectee)
      native "InstanceMirror_identityHash";

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

    return reflect(this._invoke(_reflectee,
                                _n(memberName),
                                arguments,
                                names));
  }

  _invoke(reflectee, functionName, arguments, argumentNames)
      native 'InstanceMirror_invoke';

  _invokeGetter(reflectee, getterName)
      native 'InstanceMirror_invokeGetter';

  _invokeSetter(reflectee, setterName, value)
      native 'InstanceMirror_invokeSetter';

  static _computeType(reflectee)
      native 'Object_runtimeType';
}

class _LocalClosureMirrorImpl extends _LocalInstanceMirrorImpl
    implements ClosureMirror {
  _LocalClosureMirrorImpl(reflectee) : super(reflectee);

  MethodMirror _function;
  MethodMirror get function {
    if (_function == null) {
      _function = _computeFunction(reflectee);
    }
    return _function;
  }

  InstanceMirror apply(List<Object> positionalArguments,
                       [Map<Symbol, Object> namedArguments]) {
    // TODO(iposva): When closures get an ordinary call method, this can be
    // replaced with
    //   return this.invoke(#call, positionalArguments, namedArguments);
    // and the native ClosureMirror_apply can be removed.

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

    // It is tempting to implement this in terms of Function.apply, but then
    // lazy compilation errors would be fatal.
    return reflect(_apply(_reflectee, arguments, names));
  }

  Future<InstanceMirror> applyAsync(List positionalArguments,
                                    [Map<Symbol, dynamic> namedArguments]) {
    return new Future(() {
      return this.apply(_unwrapAsyncPositionals(positionalArguments),
                        _unwrapAsyncNamed(namedArguments));
    });
  }

  Future<InstanceMirror> findInContext(Symbol name) {
    throw new UnimplementedError(
        'ClosureMirror.findInContext() is not implemented');
  }

  String toString() => "ClosureMirror on '${Error.safeToString(_reflectee)}'";

  static _apply(reflectee, arguments, argumentNames)
      native 'ClosureMirror_apply';

  static _computeFunction(reflectee)
      native 'ClosureMirror_function';
}

class _LocalClassMirrorImpl extends _LocalObjectMirrorImpl
    implements ClassMirror {
  _LocalClassMirrorImpl(reflectee,
                        this._reflectedType,
                        String simpleName,
                        this._isGeneric,
                        this._isMixinTypedef,
                        this._isGenericDeclaration)
      : this._simpleName = _s(simpleName),
        super(reflectee);

  final Type _reflectedType;
  final bool _isGeneric;
  final bool _isMixinTypedef;
  final bool _isGenericDeclaration;

  bool get hasReflectedType => !_isGenericDeclaration;
  Type get reflectedType {
    if (!hasReflectedType) {
      throw new UnsupportedError(
          "Declarations of generics have no reflected type");
    }
    return _reflectedType;
  }

  Symbol _simpleName;
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

  var _owner;
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

  // TODO(rmacnak): Remove these left-overs from the days of separate interfaces
  // once we send out a breaking change.
  bool get isClass => true;
  ClassMirror get defaultFactory => null;

  ClassMirror _trueSuperclassField;
  ClassMirror get _trueSuperclass {
    if (_trueSuperclassField == null) {
      Type supertype = _supertype(_reflectee);
      if (supertype == null) {
        // Object has no superclass.
        return null;
      }
      _trueSuperclassField = _Mirrors._reflectType(supertype);
    }
    return _trueSuperclassField;
  }
  ClassMirror get superclass {
    return _isMixinTypedef ? _trueSuperclass._trueSuperclass : _trueSuperclass;
  }

  var _superinterfaces;
  List<ClassMirror> get superinterfaces {
    if (_superinterfaces == null) {
      _superinterfaces = _interfaces(_reflectee)
          .map((i) => _Mirrors._reflectType(i)).toList(growable:false);
    }
    return _superinterfaces;
  }

  get _mixinApplicationName {
    var mixins = new List<ClassMirror>();
    var klass = this;
    while (_computeMixin(klass._reflectee) != null) {
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
      if (_isMixinTypedef) {
        _mixin = _trueSuperclass.mixin;
      } else {
        var mixinType = _computeMixin(_reflectee);
        if (mixinType == null) {
          // The reflectee is not a mixin application.
          _mixin = this;
        } else {
          _mixin = _Mirrors._reflectType(mixinType);
        }
      }
    }
    return _mixin;
  }

  Map<Symbol, Mirror> _members;
  Map<Symbol, Mirror> get members {
    if (_members == null) {
      var whoseMembers = _isMixinTypedef ? _trueSuperclass : this;
      _members = _makeMemberMap(mixin._computeMembers(whoseMembers._reflectee));
    }
    return _members;
  }

  Map<Symbol, MethodMirror> _methods;
  Map<Symbol, MethodMirror> get methods {
    if (_methods == null) {
      _methods = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isRegularMethod));
    }
    return _methods;
  }

  Map<Symbol, MethodMirror> _getters;
  Map<Symbol, MethodMirror> get getters {
    if (_getters == null) {
      _getters = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isGetter));
    }
    return _getters;
  }

  Map<Symbol, MethodMirror> _setters;
  Map<Symbol, MethodMirror> get setters {
    if (_setters == null) {
      _setters = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isSetter));
    }
    return _setters;
  }

  Map<Symbol, VariableMirror> _variables;
  Map<Symbol, VariableMirror> get variables {
    if (_variables == null) {
      _variables = _filterMap(
          members,
          (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  Map<Symbol, MethodMirror> _constructors;
  Map<Symbol, MethodMirror> get constructors {
    if (_constructors == null) {
      var constructorsList = _computeConstructors(_reflectee);
      var stringName = _n(simpleName);
      constructorsList.forEach((c) => c._patchConstructorName(stringName));
      _constructors = _makeMemberMap(constructorsList);
    }
    return _constructors;
  }

  List<TypeVariableMirror> _typeVariables = null;
  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      List params = _ClassMirror_type_variables(_reflectee);
      _typeVariables = new List<TypeVariableMirror>();
      var mirror;
      for (var i = 0; i < params.length; i += 2) {
        mirror = new _LocalTypeVariableMirrorImpl(
            params[i + 1], params[i], this);
        _typeVariables.add(mirror);
      }
    }
    return _typeVariables;
  }

  List<TypeMirror> _typeArguments = null;
  List<TypeMirror> get typeArguments {
    if(_typeArguments == null) {
      if(_isGenericDeclaration) {
        _typeArguments = new List<TypeMirror>();
      } else {
        _typeArguments =
            new List<TypeMirror>.from(_computeTypeArguments(_reflectedType));
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

  String toString() => "ClassMirror on '${_n(simpleName)}'";

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

  Future<InstanceMirror> newInstanceAsync(Symbol constructorName,
                                          List positionalArguments,
                                          [Map<Symbol, dynamic> namedArguments]) {
    return new Future(() {
      return this.newInstance(constructorName,
                              _unwrapAsyncPositionals(positionalArguments),
                              _unwrapAsyncNamed(namedArguments));
    });
  }

  List<InstanceMirror> get metadata {
    // Get the metadata objects, convert them into InstanceMirrors using
    // reflect() and then make them into a Dart list.
    return _metadata(_reflectee).map(reflect).toList(growable:false);
  }

  bool operator ==(other) {
    return this.runtimeType == other.runtimeType &&
           this._reflectee == other._reflectee &&
           this._reflectedType == other._reflectedType &&
           this._isGenericDeclaration == other._isGenericDeclaration;
  }

  int get hashCode => simpleName.hashCode;

  static _library(reflectee)
      native "ClassMirror_library";

  static _supertype(reflectee)
      native "ClassMirror_supertype";

  static _interfaces(reflectee)
      native "ClassMirror_interfaces";

  static _computeMixin(reflectee)
      native "ClassMirror_mixin";

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

class _LocalFunctionTypeMirrorImpl extends _LocalClassMirrorImpl
    implements FunctionTypeMirror {
  _LocalFunctionTypeMirrorImpl(reflectee, reflectedType)
      : super(reflectee, reflectedType, null, false, false, false);

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
      _returnType =
          _Mirrors._reflectType(_FunctionTypeMirror_return_type(_reflectee));
    }
    return _returnType;
  }

  List<ParameterMirror> _parameters = null;
  List<ParameterMirror> get parameters {
    if (_parameters == null) {
      _parameters = _FunctionTypeMirror_parameters(_reflectee);
    }
    return _parameters;
  }

  Map<Symbol, Mirror> get members => new Map<Symbol,Mirror>();
  Map<Symbol, MethodMirror> get constructors => new Map<Symbol,MethodMirror>();

  String toString() => "FunctionTypeMirror on '${_n(simpleName)}'";

  MethodMirror _FunctionTypeMirror_call_method(reflectee)
      native "FunctionTypeMirror_call_method";

  static Type _FunctionTypeMirror_return_type(reflectee)
      native "FunctionTypeMirror_return_type";

  List<ParameterMirror> _FunctionTypeMirror_parameters(reflectee)
      native "FunctionTypeMirror_parameters";
}

abstract class _LocalDeclarationMirrorImpl extends _LocalMirrorImpl
    implements DeclarationMirror {
  _LocalDeclarationMirrorImpl(this._reflectee, this._simpleName);

  final _reflectee;

  Symbol _simpleName;
  Symbol get simpleName => _simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
    }
    return _qualifiedName;
  }

  List<InstanceMirror> get metadata {
    // Get the metadata objects, convert them into InstanceMirrors using
    // reflect() and then make them into a Dart list.
    return _metadata(_reflectee).map(reflect).toList(growable:false);
  }

  bool operator ==(other) {
    return this.runtimeType == other.runtimeType &&
           this._reflectee == other._reflectee;
  }

  int get hashCode => simpleName.hashCode;
}

class _LocalTypeVariableMirrorImpl extends _LocalDeclarationMirrorImpl
    implements TypeVariableMirror {
  _LocalTypeVariableMirrorImpl(reflectee,
                               String simpleName,
                               this._owner)
      : super(reflectee, _s(simpleName));

  DeclarationMirror _owner;
  DeclarationMirror get owner {
    if (_owner == null) {
      _owner = _TypeVariableMirror_owner(_reflectee);
    }
    return _owner;
  }

  bool get isPrivate => false;

  final bool isTopLevel = false;

  SourceLocation get location {
    throw new UnimplementedError(
        'TypeVariableMirror.location is not implemented');
  }

  TypeMirror _upperBound = null;
  TypeMirror get upperBound {
    if (_upperBound == null) {
      _upperBound =
          _Mirrors._reflectType(_TypeVariableMirror_upper_bound(_reflectee));
    }
    return _upperBound;
  }

  bool get isOriginalDeclaration => true;
  ClassMirror get originalDeclaration => this;

  String toString() => "TypeVariableMirror on '${_n(simpleName)}'";

  static DeclarationMirror _TypeVariableMirror_owner(reflectee)
      native "TypeVariableMirror_owner";

  static Type _TypeVariableMirror_upper_bound(reflectee)
      native "TypeVariableMirror_upper_bound";
}


class _LocalTypedefMirrorImpl extends _LocalDeclarationMirrorImpl
    implements TypedefMirror {
  _LocalTypedefMirrorImpl(reflectee,
                          String simpleName,
                          this._owner)
      : super(reflectee, _s(simpleName));

  final bool isTopLevel = true;

  // TODO(12282): Deal with generic typedefs.
  bool get _isGeneric => false;

  bool get isPrivate => false;

  DeclarationMirror _owner;
  DeclarationMirror get owner {
    if (_owner == null) {
      _owner = _LocalClassMirrorImpl._library(_reflectee);
    }
    return _owner;
  }

  SourceLocation get location {
    throw new UnimplementedError('TypedefMirror.location is not implemented');
  }

  TypeMirror _referent = null;
  TypeMirror get referent {
    if (_referent == null) {
      // TODO(12282): Deal with generic typedef.
      return new _LocalFunctionTypeMirrorImpl(
          _TypedefMirror_referent(_reflectee), null);
    }
    return _referent;
  }

  String toString() => "TypedefMirror on '${_n(simpleName)}'";

  static _TypedefMirror_referent(_reflectee)
      native "TypedefMirror_referent";
}

class _LocalLibraryMirrorImpl extends _LocalObjectMirrorImpl
    implements LibraryMirror {
  _LocalLibraryMirrorImpl(reflectee,
                          String simpleName,
                          String url)
      : this.simpleName = _s(simpleName),
        this.uri = Uri.parse(url),
        super(reflectee);

  final Symbol simpleName;

  // The simple name and the qualified name are the same for a library.
  Symbol get qualifiedName => simpleName;

  // Always null for libraries.
  final DeclarationMirror owner = null;

  // Always false for libraries.
  final bool isPrivate = false;

  // Always false for libraries.
  final bool isTopLevel = false;

  SourceLocation get location {
    throw new UnimplementedError('LibraryMirror.location is not implemented');
  }

  final Uri uri;

  Map<Symbol, Mirror> _members;
  Map<Symbol, Mirror> get members {
    if (_members == null) {
      _members = _makeMemberMap(_computeMembers(_reflectee));
    }
    return _members;
  }

  Map<Symbol, ClassMirror> _classes;
  Map<Symbol, ClassMirror> get classes {
    if (_classes == null) {
      _classes = _filterMap(members,
                            (key, value) => (value is ClassMirror));
    }
    return _classes;
  }

  Map<Symbol, MethodMirror> _functions;
  Map<Symbol, MethodMirror> get functions {
    if (_functions == null) {
      _functions = _filterMap(members, (key, value) => (value is MethodMirror));
    }
    return _functions;
  }

  Map<Symbol, MethodMirror> _getters;
  Map<Symbol, MethodMirror> get getters {
    if (_getters == null) {
      _getters = _filterMap(functions, (key, value) => (value.isGetter));
    }
    return _getters;
  }

  Map<Symbol, MethodMirror> _setters;
  Map<Symbol, MethodMirror> get setters {
    if (_setters == null) {
      _setters = _filterMap(functions, (key, value) => (value.isSetter));
    }
    return _setters;
  }

  Map<Symbol, VariableMirror> _variables;
  Map<Symbol, VariableMirror> get variables {
    if (_variables == null) {
      _variables = _filterMap(members,
                              (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  List<InstanceMirror> get metadata {
    // Get the metadata objects, convert them into InstanceMirrors using
    // reflect() and then make them into a Dart list.
    return _metadata(_reflectee).map(reflect).toList(growable:false);
  }

  bool operator ==(other) {
    return this.runtimeType == other.runtimeType &&
           this._reflectee == other._reflectee;
  }

  int get hashCode => simpleName.hashCode;

  String toString() => "LibraryMirror on '${_n(simpleName)}'";

  _invoke(reflectee, memberName, arguments, argumentNames)
      native 'LibraryMirror_invoke';

  _invokeGetter(reflectee, getterName)
      native 'LibraryMirror_invokeGetter';

  _invokeSetter(reflectee, setterName, value)
      native 'LibraryMirror_invokeSetter';

  _computeMembers(reflectee)
      native "LibraryMirror_members";
}

class _LocalMethodMirrorImpl extends _LocalDeclarationMirrorImpl
    implements MethodMirror {
  _LocalMethodMirrorImpl(reflectee,
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

  static const _operators = const ["%", "&", "*", "+", "-", "/", "<", "<<",
      "<=", "==", ">", ">=", ">>", "[]", "[]=", "^", "|", "~", "unary-", "~/"];

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

  bool get isTopLevel =>  owner is LibraryMirror;

  SourceLocation get location {
    throw new UnimplementedError('MethodMirror.location is not implemented');
  }

  TypeMirror _returnType = null;
  TypeMirror get returnType {
    if (_returnType == null) {
      if (isConstructor) {
        _returnType = owner;
      } else {
        _returnType =
            _Mirrors._reflectType(_MethodMirror_return_type(_reflectee));
      }
    }
    return _returnType;
  }

  List<ParameterMirror> _parameters = null;
  List<ParameterMirror> get parameters {
    if (_parameters == null) {
      _parameters = _MethodMirror_parameters(_reflectee);
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
        var parts = _n(simpleName).split('.');
        if (parts.length > 2) {
          throw new MirrorException(
              'Internal error in MethodMirror.constructorName: '
              'malformed name <$simpleName>');
        } else if (parts.length == 2) {
          _constructorName = _s(parts[1]);
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
      assert(_source != null);
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

  String toString() => "MethodMirror on '${_n(simpleName)}'";

  static dynamic _MethodMirror_owner(reflectee)
      native "MethodMirror_owner";

  static dynamic _MethodMirror_return_type(reflectee)
      native "MethodMirror_return_type";

  List<ParameterMirror> _MethodMirror_parameters(reflectee)
      native "MethodMirror_parameters";

  static String _MethodMirror_source(reflectee)
      native "MethodMirror_source";
}

class _LocalVariableMirrorImpl extends _LocalDeclarationMirrorImpl
    implements VariableMirror {
  _LocalVariableMirrorImpl(reflectee,
                           String simpleName,
                           this.owner,
                           this._type,
                           this.isStatic,
                           this.isFinal)
      : super(reflectee, _s(simpleName));

  final DeclarationMirror owner;
  final bool isStatic;
  final bool isFinal;

  bool get isPrivate => _n(simpleName).startsWith('_');

  bool get isTopLevel => owner is LibraryMirror;

  SourceLocation get location {
    throw new UnimplementedError('VariableMirror.location is not implemented');
  }

  TypeMirror _type;
  TypeMirror get type {
    if (_type == null) {
       _type = _Mirrors._reflectType(_VariableMirror_type(_reflectee));
    }
    return _type;
  }

  String toString() => "VariableMirror on '${_n(simpleName)}'";

  static _VariableMirror_type(reflectee)
      native "VariableMirror_type";
}

class _LocalParameterMirrorImpl extends _LocalVariableMirrorImpl
    implements ParameterMirror {
  _LocalParameterMirrorImpl(reflectee,
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
              isFinal);

  final int _position;
  final bool isOptional;
  final bool isNamed;
  final List _unmirroredMetadata;

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
    if ( _unmirroredMetadata == null) return const [];
    return _unmirroredMetadata.map(reflect).toList(growable:false);
  }

  TypeMirror _type = null;
  TypeMirror get type {
    if (_type == null) {
      _type =
          _Mirrors._reflectType(_ParameterMirror_type(_reflectee, _position));
    }
    return _type;
  }

  String toString() => "ParameterMirror on '${_n(simpleName)}'";

  static Type _ParameterMirror_type(_reflectee, _position)
      native "ParameterMirror_type";
}

class _SpecialTypeMirrorImpl extends _LocalMirrorImpl
    implements TypeMirror, DeclarationMirror {
  _SpecialTypeMirrorImpl(String name) : simpleName = _s(name);

  final bool isPrivate = false;
  final DeclarationMirror owner = null;
  final Symbol simpleName;
  final bool isTopLevel = true;
  // Fixed length 0, therefore immutable.
  final List<InstanceMirror> metadata = new List(0);

  SourceLocation get location {
    throw new UnimplementedError('TypeMirror.location is not implemented');
  }

  Symbol get qualifiedName => simpleName;

  // TODO(11955): Remove once dynamicType and voidType are canonical objects in
  // the object store.
  bool operator ==(other) {
    if (other is! _SpecialTypeMirrorImpl) {
      return false;
    }
    return this.simpleName == other.simpleName;
  }

  int get hashCode => simpleName.hashCode;

  String toString() => "TypeMirror on '${_n(simpleName)}'";
}

class _Mirrors {
  // Does a port refer to our local isolate?
  static bool isLocalPort(SendPort port) native 'Mirrors_isLocalPort';

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

  static Future<MirrorSystem> mirrorSystemOf(SendPort port) {
    if (isLocalPort(port)) {
      // Make a local mirror system.
      try {
        return new Future<MirrorSystem>.value(currentMirrorSystem());
      } catch (exception) {
        return new Future<MirrorSystem>.error(exception);
      }
    } else {
      // Make a remote mirror system
      throw new UnimplementedError(
          'Remote mirror support is not implemented');
    }
  }

  // Creates a new local mirror for some Object.
  static InstanceMirror reflect(Object reflectee) {
    return reflectee is Function
        ? new _LocalClosureMirrorImpl(reflectee)
        : new _LocalInstanceMirrorImpl(reflectee);
  }

  static ClassMirror makeLocalClassMirror(Type key)
      native "Mirrors_makeLocalClassMirror";
  static TypeMirror makeLocalTypeMirror(Type key)
      native "Mirrors_makeLocalTypeMirror";

  static Expando<ClassMirror> _declarationCache = new Expando("ClassMirror");
  static Expando<ClassMirror> _instanitationCache = new Expando("TypeMirror");

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

  static TypeMirror _reflectType(Type key) {
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
