// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:mirrors';
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' as _internal;

String getName(Symbol symbol) =>
    _internal.Symbol.getName(symbol as _internal.Symbol);

Symbol getSymbol(name, library) =>
    throw new UnimplementedError("MirrorSystem.getSymbol unimplemented");

final currentJsMirrorSystem = throw new UnimplementedError(
    "MirrorSystem.currentJsMirrorSystem unimplemented");

final _typeMirror = JS('', 'Symbol("_typeMirror")');

InstanceMirror reflect(reflectee) {
  // TODO(vsm): Consider caching the mirror here.  Unlike the type below,
  // reflectee may be a primitive - i.e., we can't just add an expando.
  if (reflectee is Function) {
    return new JsClosureMirror._(reflectee);
  } else {
    return new JsInstanceMirror._(reflectee);
  }
}

TypeMirror reflectType(Type key) {
  var unwrapped = _unwrap(key);
  var property = JS('', 'Object.getOwnPropertyDescriptor(#, #)', unwrapped, _typeMirror);
  if (property != null) {
    return JS('', '#.value', property);
  }
  // TODO(vsm): Might not be a class.
  var mirror = new JsClassMirror._(key);
  JS('', '#[#] = #', unwrapped, _typeMirror, mirror);
  return mirror;
}

final dynamic _dart = JS('', 'dart');

dynamic _dload(obj, String name) {
  return JS('', '#.dload(#, #)', _dart, obj, name);
}

void _dput(obj, String name, val) {
  JS('', '#.dput(#, #, #)', _dart, obj, name, val);
}

dynamic _dcall(obj, List args) {
  return JS('', '#.dcall(#, ...#)', _dart, obj, args);
}

dynamic _dsend(obj, String name, List args) {
  return JS('', '#.dsend(#, #, ...#)', _dart, obj, name, args);
}

dynamic _getGenericClass(obj) {
  return JS('', '#.getGenericClass(#)', _dart, obj);
}

dynamic _getGenericArgs(obj) {
  return JS('', '#.getGenericArgs(#)', _dart, obj);
}

dynamic _defaultConstructorType(type) {
  return JS('', '#.definiteFunctionType(#, [])', _dart, type);
}

typedef T _Lazy<T>();

String _getNameForESSymbol(member) {
  // Convert private JS symbol "Symbol(_foo)" to string "_foo".
  var str = member.toString();
  assert(str.startsWith('Symbol(') && str.endsWith(')'));
  return str.substring(7, str.length - 1);
}

Map _toDartMap(data) {
  if (data == null) return {};
  var map = JS('Map', '#.map(#)', _dart, data);
  // Note: we recorded a map from fields/methods to their type and metadata.
  // The key is a string name for public members but an ES6 symbol for private
  // ones.  That's works nicely for dynamic operations, but dart:mirrors expects
  // strings, so we convert back here.
  var privateMembers = JS('', 'Object.getOwnPropertySymbols(#)', data);
  for (var member in privateMembers) {
    var name = _getNameForESSymbol(member);
    map[name] = JS('', '#[#]', data, member);
  }
  return map;
}

Map _getConstructors(obj) {
  List sig = JS('', '#.getConstructorSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getFields(obj) {
  List sig = JS('', '#.getFieldSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getMethods(obj) {
  List sig = JS('', '#.getMethodSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getGetters(obj) {
  List sig = JS('', '#.getGetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getSetters(obj) {
  List sig = JS('', '#.getSetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getStaticFields(obj) {
  List sig = JS('', '#.getStaticFieldSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getStatics(obj) {
  List sig = JS('', '#.getStaticSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getStaticGetters(obj) {
  List sig = JS('', '#.getStaticGetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map _getStaticSetters(obj) {
  List sig = JS('', '#.getStaticSetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

// TODO(vsm): These methods need to validate whether we really have a
// WrappedType or a raw type that should be wrapped (as opposed to a
// function).
dynamic _unwrap(obj) => JS('', '#.unwrapType(#)', _dart, obj);

dynamic _wrap(obj) => JS('', '#.wrapType(#)', _dart, obj);

_unimplemented(Type t, Invocation i) {
  throw new UnimplementedError('$t.${getName(i.memberName)} unimplemented');
}

dynamic _toJsMap(Map<Symbol, dynamic> map) {
  var obj = JS('', '{}');
  map.forEach((Symbol key, value) {
    JS('', '#[#] = #', obj, getName(key), value);
  });
  return obj;
}

class JsMirror implements Mirror {
  noSuchMethod(Invocation i) {
    _unimplemented(this.runtimeType, i);
  }
}

class JsCombinatorMirror extends JsMirror implements CombinatorMirror {
}

class JsDeclarationMirror extends JsMirror implements DeclarationMirror {
}

class JsIsolateMirror extends JsMirror implements IsolateMirror {
}

class JsLibraryDependencyMirror extends JsMirror implements LibraryDependencyMirror {
}

class JsObjectMirror extends JsMirror implements ObjectMirror {
}

class JsInstanceMirror extends JsObjectMirror implements InstanceMirror {

  // Reflected object
  final reflectee;
  bool get hasReflectee => true;

  ClassMirror get type {
    // The spec guarantees that `null` is the singleton instance of the `Null`
    // class.
    if (reflectee == null) return reflectClass(Null);
    return reflectType(reflectee.runtimeType);
  }

  JsInstanceMirror._(this.reflectee);

  bool operator==(Object other) {
    return (other is JsInstanceMirror) && identical(reflectee, other.reflectee);
  }

  int get hashCode {
    // Avoid hash collisions with the reflectee. This constant is in Smi range
    // and happens to be the inner padding from RFC 2104.
    return identityHashCode(reflectee) ^ 0x36363636;
  }

  // Returns a String for public members or an ES6 symbol for private members.
  _getAccessor(dynamic reflectee, Symbol symbol, [List<dynamic> args,
      Map<Symbol, dynamic> namedArgs]) {
    var name = getName(symbol);
    if (!name.startsWith('_')) return name;

    // TODO(vsm): Ideally, we'd record ES6 symbols properly during codegen if
    // mirrors is enabled.  Here, we're trying to recover it from the receiver
    // instead.
    //
    // Get private fields and members.  Members are on proto.
    var privateMembers = JS('', 'Object.getOwnPropertySymbols(#)', reflectee)
      ..addAll(JS('', 'Object.getOwnPropertySymbols(#.__proto__)', reflectee));
    for (var member in privateMembers) {
      var privateName = _getNameForESSymbol(member);
      if (name == privateName) return member;
    }
    return new NoSuchMethodError(reflectee, symbol, args, namedArgs);
  }

  InstanceMirror getField(Symbol symbol) {
    var name = _getAccessor(reflectee, symbol);
    var field = _dload(reflectee, name);
    return reflect(field);
  }

  InstanceMirror setField(Symbol symbol, Object value) {
    var name = _getAccessor(reflectee, symbol);
    _dput(reflectee, name, value);
    return reflect(value);
  }

  InstanceMirror invoke(Symbol symbol, List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    var name = _getAccessor(reflectee, symbol, args, namedArgs);
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = _dsend(reflectee, name, args);
    return reflect(result);
  }

  String toString() => "InstanceMirror on '$reflectee'";
}

class JsClosureMirror extends JsInstanceMirror implements ClosureMirror {
  JsClosureMirror._(reflectee) : super._(reflectee);

  InstanceMirror apply(List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = _dcall(reflectee, args);
    return reflect(result);
  }
}

class JsClassMirror extends JsMirror implements ClassMirror {
  final Type _cls;
  final Symbol simpleName;
  // Generic class factory
  final dynamic _raw;

  // TODO(vsm): Do this properly
  final ClassMirror mixin = null;
  List<TypeMirror> _typeArguments;

  List<InstanceMirror> _metadata;
  Map<Symbol, DeclarationMirror> _declarations;

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      // Load metadata.
      var unwrapped = _unwrap(_cls);
      // Only get metadata directly embedded on this class, not its
      // superclasses.
      var fn = JS('Function',
        'Object.hasOwnProperty.call(#, dart.metadata) ? #[dart.metadata] : null',
        unwrapped, unwrapped);
      _metadata = (fn == null)
          ? const <InstanceMirror>[]
          : new List<InstanceMirror>.unmodifiable(
              fn().map((i) => reflect(i)));
    }
    return _metadata;
  }

  Map<Symbol, DeclarationMirror> get declarations {
    if (_declarations == null) {
      // Load declarations.
      // TODO(vsm): This is only populating the default constructor right now.
      _declarations = new Map<Symbol, DeclarationMirror>();
      var unwrapped = _unwrap(_cls);
      var constructors = _getConstructors(unwrapped);
      constructors.forEach((String name, ft) {
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._constructor(this, name, ft);
      });
      if (constructors.isEmpty) {
        // Add a default
        var name = 'new';
        var ft = _defaultConstructorType(_unwrap(_cls));
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._constructor(this, name, ft);
      }
      var fields = _getFields(unwrapped);
      fields.forEach((String name, t) {
        var symbol = new Symbol(name);
        var metadata = [];
        if (t is List) {
          metadata = t.skip(1).toList();
          t = t[0];
        }
        _declarations[symbol] = new JsVariableMirror._(name, _wrap(t), metadata);
      });
      var methods = _getMethods(unwrapped);
      methods.forEach((String name, ft) {
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._instanceMethod(this, name, ft);
      });
      var getters = _getGetters(unwrapped);
      getters.forEach((String name, ft) {
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._instanceMethod(this, name, ft);
      });
      var setters = _getSetters(unwrapped);
      setters.forEach((String name, ft) {
        name += '=';
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._instanceMethod(this, name, ft);
      });
      var staticFields = _getStaticFields(unwrapped);
      staticFields.forEach((String name, t) {
        var symbol = new Symbol(name);
        var metadata = [];
        if (t is List) {
          metadata = t.skip(1).toList();
          t = t[0];
        }
        _declarations[symbol] = new JsVariableMirror._(name, _wrap(t), metadata);
      });
      var statics = _getStatics(unwrapped);
      statics.forEach((String name, ft) {
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._staticMethod(this, name, ft);
      });
      var staticGetters = _getStaticGetters(unwrapped);
      staticGetters.forEach((String name, ft) {
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._staticMethod(this, name, ft);
      });
      var staticSetters = _getStaticSetters(unwrapped);
      staticSetters.forEach((String name, ft) {
        var symbol = new Symbol(name);
        _declarations[symbol] = new JsMethodMirror._staticMethod(this, name, ft);
      });
      _declarations = new Map<Symbol, DeclarationMirror>.unmodifiable(_declarations);
    }
    return _declarations;
  }

  JsClassMirror._(Type cls)
      : _cls = cls,
        _raw = _getGenericClass(_unwrap(cls)),
        simpleName = new Symbol(JS('String', '#.name', _unwrap(cls))) {
    var typeArgs = _getGenericArgs(_unwrap(cls));
    if (typeArgs == null) {
      _typeArguments = const[];
    } else {
      _typeArguments = new List.unmodifiable(typeArgs.map((t) => reflectType(_wrap(t))));
    }
  }

  InstanceMirror newInstance(Symbol constructorName, List args,
      [Map<Symbol, dynamic> namedArgs]) {
    // TODO(vsm): Support factory constructors and named arguments.
    var name = getName(constructorName);
    assert(namedArgs == null || namedArgs.isEmpty);
    var instance = (name == 'new' || name == '')
      ? JS('', 'new #(...#)', _unwrap(_cls), args)
      : JS('', 'new (#.#)(...#)', _unwrap(_cls), name, args);
    return reflect(instance);
  }

  // TODO(vsm): Need to check for NSM, types on accessors below.  Unlike the
  // InstanceMirror case, there is no dynamic helper to delegate to - we never
  // need a dload, etc. on a static.

  InstanceMirror getField(Symbol symbol) {
    var name = getName(symbol);
    return reflect(JS('', '#[#]', _unwrap(_cls), name));
  }

  InstanceMirror setField(Symbol symbol, Object value) {
    var name = getName(symbol);
    JS('', '#[#] = #', _unwrap(_cls), name, value);
    return reflect(value);
  }

  InstanceMirror invoke(Symbol symbol, List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    var name = getName(symbol);
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = JS('', '#.#(...#)', _unwrap(_cls), name, args);
    return reflect(result);
  }

  List<ClassMirror> get superinterfaces {
    _Lazy<List<Type>> interfaceThunk = JS('', '#[dart.implements]', _unwrap(_cls));
    if (interfaceThunk == null) {
      return [];
    } else {
      List<Type> interfaces = interfaceThunk();
      return interfaces.map((t) => reflectType(t)).toList();
    }
  }

  bool get hasReflectedType => true;
  Type get reflectedType { return _cls; }

  bool get isOriginalDeclaration => _raw == null;

  List<TypeMirror> get typeArguments => _typeArguments;

  TypeMirror get originalDeclaration {
    // TODO(vsm): Handle generic case.  How should we represent an original
    // declaration for a generic class?
    if (_raw == null) {
      return this;
    }
    throw new UnimplementedError("ClassMirror.originalDeclaration unimplemented");
  }

  ClassMirror get superclass {
    if (_cls == Object) {
      return null;
    } else {
      return reflectType(_wrap(JS('Type', '#.__proto__', _unwrap(_cls))));
    }
  }

  String toString() => "ClassMirror on '$_cls'";
}

class JsVariableMirror extends JsMirror implements VariableMirror {
  final String _name;
  final TypeMirror type;
  final List<InstanceMirror> metadata;

  // TODO(vsm): Refactor this out.
  Symbol get simpleName => new Symbol(_name);

  // TODO(vsm): Fix this
  final bool isStatic = false;
  final bool isFinal = false;

  JsVariableMirror._(this._name, Type t, List annotations)
      : type = reflectType(t),
        metadata = new List<InstanceMirror>.unmodifiable(
            annotations.map((a) => reflect(a)));

  String toString() => "VariableMirror on '$_name'";
}

class JsParameterMirror extends JsVariableMirror implements ParameterMirror {
  JsParameterMirror._(String name, Type t, List annotations)
      : super._(name, t, annotations);

  String toString() => "ParameterMirror on '$_name'";
}

class JsMethodMirror extends JsMirror implements MethodMirror {
  // TODO(vsm): This could be a JS symbol for private methods
  final String _name;
  List<ParameterMirror> _params;
  List<InstanceMirror> _metadata;
  final bool isConstructor;
  final bool isStatic;

  // TODO(vsm): Fix this
  final bool isFinal = false;
  bool get isSetter => _name.endsWith('=');
  bool get isPrivate => _name.startsWith('_');

  // TODO(vsm): Refactor this out.
  Symbol get simpleName => new Symbol(_name);

  JsMethodMirror._constructor(JsClassMirror cls, String name, ftype)
    : _name = name, isConstructor = true, isStatic = false {
      _createParameterMirrorList(ftype);
  }

  JsMethodMirror._instanceMethod(JsClassMirror cls, String name, ftype)
    : _name = name, isConstructor = false, isStatic = false {
      _createParameterMirrorList(ftype);
  }

  JsMethodMirror._staticMethod(JsClassMirror cls, String name, ftype)
    : _name = name, isConstructor = false, isStatic = true {
      _createParameterMirrorList(ftype);
  }

  // TODO(vsm): Support named constructors.
  Symbol get constructorName => isConstructor ? new Symbol(_name) : null;
  List<ParameterMirror> get parameters => _params;
  List<InstanceMirror> get metadata => _metadata;

  void _createParameterMirrorList(ftype) {
    if (ftype == null) {
      // TODO(vsm): No explicit constructor.  Verify this.
      _params = const [];
      _metadata = const [];
      return;
    }

    // TODO(vsm): Why does generic function type trigger true for List?
    if (ftype is! Function && ftype is List) {
      // Record metadata
      _metadata = new List<InstanceMirror>.unmodifiable(
          ftype.skip(1).map((a) => reflect(a)));
      ftype = ftype[0];
    } else {
      _metadata = const [];
    }

    // TODO(vsm): Handle generic function types properly.  Or deprecate mirrors
    // before we need to!
    if (JS('bool', 'typeof(#) == "function"', ftype)) {
      // Instantiate the generic version.
      // TODO(vsm): Can't use arguments.length on arrow function.
      ftype = JS('', '#.apply(null, #)', ftype, [dynamic, dynamic, dynamic]);
    }

    // TODO(vsm): Add named args.
    List args = ftype.args;
    List opts = ftype.optionals;
    var params = new List<ParameterMirror>(args.length + opts.length);

    for (var i = 0; i < args.length; ++i) {
      var type = args[i];
      var metadata = ftype.metadata[i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._('', _wrap(type), metadata);
      params[i] = param;
    }

    for (var i = 0; i < opts.length; ++i) {
      var type = opts[i];
      var metadata = ftype.metadata[args.length + i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._('', _wrap(type), metadata);
      params[i + args.length] = param;
    }

    _params = new List.unmodifiable(params);
  }

  String toString() => "MethodMirror on '$_name'";
}
