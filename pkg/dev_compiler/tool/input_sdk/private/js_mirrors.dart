// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:mirrors';
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' as _internal;

String getName(Symbol symbol) {
  if (symbol is _internal.PrivateSymbol) {
    return _internal.PrivateSymbol.getName(symbol);
  } else {
    return _internal.Symbol.getName(symbol as _internal.Symbol);
  }
}

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
  var property =
      JS('', 'Object.getOwnPropertyDescriptor(#, #)', unwrapped, _typeMirror);
  if (property != null) {
    return JS('', '#.value', property);
  }
  // TODO(vsm): Might not be a class.
  var mirror = new JsClassMirror._(key);
  JS('', '#[#] = #', unwrapped, _typeMirror, mirror);
  return mirror;
}

final dynamic _dart = JS('', 'dart');

dynamic _dload(obj, name) {
  return JS('', '#.dloadMirror(#, #)', _dart, obj, name);
}

void _dput(obj, name, val) {
  JS('', '#.dputMirror(#, #, #)', _dart, obj, name, val);
}

dynamic _dcall(obj, List args) {
  return JS('', '#.dcall(#, ...#)', _dart, obj, args);
}

dynamic _dsend(obj, name, List args) {
  return JS('', '#.dsend(#, #, ...#)', _dart, obj, name, args);
}

dynamic _getGenericClass(obj) {
  return JS('', '#.getGenericClass(#)', _dart, obj);
}

dynamic _getGenericArgs(obj) {
  return JS('', '#.getGenericArgs(#)', _dart, obj);
}

dynamic _defaultConstructorType(type) {
  return JS('', '#.fnType(#, [])', _dart, type);
}

dynamic _getMixins(type) {
  return JS('', '#.getMixins(#, [])', _dart, type);
}

dynamic _getFunctionType(type) {
  return JS('', '#.getFunctionTypeMirror(#)', _dart, type);
}

typedef T _Lazy<T>();

dynamic _getESSymbol(Symbol symbol) =>
    _internal.PrivateSymbol.getNativeSymbol(symbol);

dynamic _getMember(Symbol symbol) {
  var privateSymbol = _getESSymbol(symbol);
  if (privateSymbol != null) {
    return privateSymbol;
  }
  var name = getName(symbol);
  // TODO(jacobr): this code is duplicated in code_generator.dart
  switch (name) {
    case '[]':
      name = '_get';
      break;
    case '[]=':
      name = '_set';
      break;
    case 'unary-':
      name = '_negate';
      break;
    case 'constructor':
    case 'prototype':
      name = '_$name';
      break;
  }
  return name;
}

String _getNameForESSymbol(member) {
  // Convert private JS symbol "Symbol(_foo)" to string "_foo".
  assert(JS('bool', 'typeof # == "symbol"', member));
  var str = member.toString();
  assert(str.startsWith('Symbol(') && str.endsWith(')'));
  return str.substring(7, str.length - 1);
}

Symbol _getSymbolForESSymbol(member) {
  var name = _getNameForESSymbol(member);
  return new _internal.PrivateSymbol(name, member);
}

// The [member] must be either a string (public) or an ES6 symbol (private).
Symbol _getSymbolForMember(member) {
  if (member is String) {
    return new Symbol(member);
  } else {
    var name = _getNameForESSymbol(member);
    return new _internal.PrivateSymbol(name, member);
  }
}

Map<Symbol, dynamic> _toDartMap(data) {
  if (data == null) return {};
  var map = new Map<Symbol, dynamic>();
  // Note: we recorded a map from fields/methods to their type and metadata.
  // The key is a string name for public members but an ES6 symbol for private
  // ones.  That's works nicely for dynamic operations, but dart:mirrors expects
  // Dart symbols, so we convert here.
  var publicMembers = JS('', 'Object.getOwnPropertyNames(#)', data);
  for (var member in publicMembers) {
    var symbol = new Symbol(member);
    map[symbol] = JS('', '#[#]', data, member);
  }

  var privateMembers = JS('', 'Object.getOwnPropertySymbols(#)', data);
  for (var member in privateMembers) {
    var symbol = _getSymbolForESSymbol(member);
    map[symbol] = JS('', '#[#]', data, member);
  }
  return map;
}

Map<Symbol, dynamic> _getConstructors(obj) {
  List sig = JS('', '#.getConstructorSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getFields(obj) {
  List sig = JS('', '#.getFieldSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getMethods(obj) {
  List sig = JS('', '#.getMethodSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getGetters(obj) {
  List sig = JS('', '#.getGetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getSetters(obj) {
  List sig = JS('', '#.getSetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getStaticFields(obj) {
  List sig = JS('', '#.getStaticFieldSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getStatics(obj) {
  List sig = JS('', '#.getStaticSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getStaticGetters(obj) {
  List sig = JS('', '#.getStaticGetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

Map<Symbol, dynamic> _getStaticSetters(obj) {
  List sig = JS('', '#.getStaticSetterSig(#)', _dart, obj);
  return _toDartMap(sig);
}

// TODO(vsm): These methods need to validate whether we really have a
// WrappedType or a raw type that should be wrapped (as opposed to a
// function).
dynamic _unwrap(obj) => JS('', '#.unwrapType(#)', _dart, obj);

dynamic _wrap(obj) => JS('', '#.wrapType(#)', _dart, obj);

dynamic _runtimeType(obj) => _wrap(JS('', '#.getReifiedType(#)', _dart, obj));

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

class JsCombinatorMirror extends JsMirror implements CombinatorMirror {}

class JsDeclarationMirror extends JsMirror implements DeclarationMirror {}

class JsIsolateMirror extends JsMirror implements IsolateMirror {}

class JsLibraryDependencyMirror extends JsMirror
    implements LibraryDependencyMirror {}

class JsObjectMirror extends JsMirror implements ObjectMirror {}

class JsInstanceMirror extends JsObjectMirror implements InstanceMirror {
  // Reflected object
  final reflectee;
  bool get hasReflectee => true;

  ClassMirror get type {
    // The spec guarantees that `null` is the singleton instance of the `Null`
    // class.
    if (reflectee == null) return reflectClass(Null);
    return reflectType(_runtimeType(reflectee));
  }

  JsInstanceMirror._(this.reflectee);

  bool operator ==(Object other) {
    return (other is JsInstanceMirror) && identical(reflectee, other.reflectee);
  }

  int get hashCode {
    // Avoid hash collisions with the reflectee. This constant is in Smi range
    // and happens to be the inner padding from RFC 2104.
    return identityHashCode(reflectee) ^ 0x36363636;
  }

  // Returns a String for public members or an ES6 symbol for private members.
  _getAccessor(dynamic reflectee, Symbol symbol,
      [List<dynamic> args, Map<Symbol, dynamic> namedArgs]) {
    return _getMember(symbol);
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

  InstanceMirror apply(List<dynamic> args, [Map<Symbol, dynamic> namedArgs]) {
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = _dcall(reflectee, args);
    return reflect(result);
  }
}

// For generic classes, mirrors uses the same representation, [ClassMirror],
// for the instantiated and uninstantiated type.  Somewhat awkwardly, most APIs
// (e.g., [newInstance]) treat the uninstantiated type as if instantiated
// with all dynamic.  The representation below is correspondingly a bit wonky.
// For an uninstantiated generic class, [_cls] is the instantiated type (with
// dynamic) and [_raw] is null.  For an instantiated generic class, [_cls] is
// the instantiated type (with the corresponding type parameters), and [_raw]
// is the generic factory.
class JsClassMirror extends JsMirror implements ClassMirror {
  final Type _cls;
  final Symbol simpleName;
  // Generic class factory for instantiated types.
  final dynamic _raw;

  ClassMirror _originalDeclaration;

  // TODO(vsm): Do this properly
  ClassMirror _mixin = null;
  List<TypeMirror> _typeArguments;

  List<InstanceMirror> _metadata;
  Map<Symbol, DeclarationMirror> _declarations;

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      // Load metadata.
      var unwrapped = _unwrap(_cls);
      // Only get metadata directly embedded on this class, not its
      // superclasses.
      var fn = JS(
          'Function',
          'Object.hasOwnProperty.call(#, dart.metadata) ? #[dart.metadata] : null',
          unwrapped,
          unwrapped);
      _metadata = (fn == null)
          ? const <InstanceMirror>[]
          : new List<InstanceMirror>.unmodifiable(fn().map((i) => reflect(i)));
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
      constructors.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._constructor(this, symbol, ft);
      });
      if (constructors.isEmpty) {
        // Add a default
        var name = 'new';
        var ft = _defaultConstructorType(_unwrap(_cls));
        var symbol = new Symbol(name);
        _declarations[symbol] =
            new JsMethodMirror._constructor(this, symbol, ft);
      }
      var fields = _getFields(unwrapped);
      fields.forEach((symbol, t) {
        _declarations[symbol] = new JsVariableMirror._fromField(symbol, t);
      });
      var methods = _getMethods(unwrapped);
      methods.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._instanceMethod(this, symbol, ft);
      });
      var getters = _getGetters(unwrapped);
      getters.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._instanceMethod(this, symbol, ft);
      });
      var setters = _getSetters(unwrapped);
      setters.forEach((symbol, ft) {
        var name = getName(symbol) + '=';
        // Create a separate symbol for the setter.
        symbol = new _internal.PrivateSymbol(name, _getESSymbol(symbol));
        _declarations[symbol] =
            new JsMethodMirror._instanceMethod(this, symbol, ft);
      });
      var staticFields = _getStaticFields(unwrapped);
      staticFields.forEach((symbol, t) {
        _declarations[symbol] = new JsVariableMirror._fromField(symbol, t);
      });
      var statics = _getStatics(unwrapped);
      statics.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._staticMethod(this, symbol, ft);
      });
      var staticGetters = _getStaticGetters(unwrapped);
      staticGetters.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._staticMethod(this, symbol, ft);
      });
      var staticSetters = _getStaticSetters(unwrapped);
      staticSetters.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._staticMethod(this, symbol, ft);
      });
      _declarations =
          new Map<Symbol, DeclarationMirror>.unmodifiable(_declarations);
    }
    return _declarations;
  }

  JsClassMirror._(Type cls, {bool instantiated: true})
      : _cls = cls,
        _raw = instantiated ? _getGenericClass(_unwrap(cls)) : null,
        simpleName = new Symbol(JS('String', '#.name', _unwrap(cls))) {
    var typeArgs = _getGenericArgs(_unwrap(_cls));
    if (typeArgs == null) {
      _typeArguments = const [];
    } else {
      _typeArguments =
          new List.unmodifiable(typeArgs.map((t) => reflectType(_wrap(t))));
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
    _Lazy<List<Type>> interfaceThunk =
        JS('', '#[dart.implements]', _unwrap(_cls));
    if (interfaceThunk == null) {
      return [];
    } else {
      List<Type> interfaces = interfaceThunk();
      return interfaces.map((t) => reflectType(t)).toList();
    }
  }

  bool get hasReflectedType => true;
  Type get reflectedType {
    return _cls;
  }

  bool get isOriginalDeclaration => _raw == null;

  List<TypeMirror> get typeArguments => _typeArguments;

  TypeMirror get originalDeclaration {
    if (_raw == null) {
      return this;
    }
    if (_originalDeclaration != null) {
      return _originalDeclaration;
    }
    _originalDeclaration =
        new JsClassMirror._(_wrap(JS('', '#()', _raw)), instantiated: false);
    return _originalDeclaration;
  }

  ClassMirror get superclass {
    if (_cls == Object) {
      return null;
    } else {
      return reflectType(_wrap(JS('Type', '#.__proto__', _unwrap(_cls))));
    }
  }

  ClassMirror get mixin {
    if (_mixin != null) {
      return _mixin;
    }
    var mixins = _getMixins(_unwrap(_cls));
    if (mixins == null || mixins.isEmpty) {
      // If there is no mixin, return this mirror per API.
      _mixin = this;
      return _mixin;
    }
    if (mixins.length > 1) {
      throw new UnsupportedError("ClassMirror.mixin not yet supported for "
          "classes ($_cls) with multiple mixins");
    }
    _mixin = reflectType(_wrap(mixins[0]));
    return _mixin;
  }

  String toString() => "ClassMirror on '$_cls'";
}

class JsVariableMirror extends JsMirror implements VariableMirror {
  final Symbol _symbol;
  final String _name;
  final TypeMirror type;
  final List<InstanceMirror> metadata;
  final bool isFinal;

  // TODO(vsm): Refactor this out.
  Symbol get simpleName => _symbol;

  // TODO(vsm): Fix this
  final bool isStatic = false;

  JsVariableMirror._(Symbol symbol, Type t, List annotations,
      {this.isFinal: false})
      : _symbol = symbol,
        _name = getName(symbol),
        type = reflectType(t),
        metadata = new List<InstanceMirror>.unmodifiable(
            annotations?.map(reflect) ?? []);

  JsVariableMirror._fromField(Symbol symbol, fieldInfo)
      : this._(symbol, _wrap(JS('', '#.type', fieldInfo)),
            JS('', '#.metadata', fieldInfo),
            isFinal: JS('bool', '#.isFinal', fieldInfo));

  String toString() => "VariableMirror on '$_name'";
}

class JsParameterMirror extends JsVariableMirror implements ParameterMirror {
  JsParameterMirror._(Symbol member, Type t, List annotations)
      : super._(member, t, annotations);

  String toString() => "ParameterMirror on '$_name'";
}

class JsMethodMirror extends JsMirror implements MethodMirror {
  final Symbol _symbol;
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
  Symbol get simpleName => _symbol;

  JsMethodMirror._constructor(JsClassMirror cls, Symbol symbol, ftype)
      : _symbol = symbol,
        _name = getName(symbol),
        isConstructor = true,
        isStatic = false {
    _createParameterMirrorList(ftype);
  }

  JsMethodMirror._instanceMethod(JsClassMirror cls, Symbol symbol, ftype)
      : _symbol = symbol,
        _name = getName(symbol),
        isConstructor = false,
        isStatic = false {
    _createParameterMirrorList(ftype);
  }

  JsMethodMirror._staticMethod(JsClassMirror cls, Symbol symbol, ftype)
      : _symbol = symbol,
        _name = getName(symbol),
        isConstructor = false,
        isStatic = true {
    _createParameterMirrorList(ftype);
  }

  // TODO(vsm): Support named constructors.
  Symbol get constructorName => isConstructor ? _symbol : null;
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
    ftype = _getFunctionType(ftype);

    // TODO(vsm): Add named args.
    List args = ftype.args;
    List opts = ftype.optionals;
    var params = new List<ParameterMirror>(args.length + opts.length);

    for (var i = 0; i < args.length; ++i) {
      var type = args[i];
      var metadata = ftype.metadata[i];
      // TODO(vsm): Recover the param name.
      var param =
          new JsParameterMirror._(new Symbol(''), _wrap(type), metadata);
      params[i] = param;
    }

    for (var i = 0; i < opts.length; ++i) {
      var type = opts[i];
      var metadata = ftype.metadata[args.length + i];
      // TODO(vsm): Recover the param name.
      var param =
          new JsParameterMirror._(new Symbol(''), _wrap(type), metadata);
      params[i + args.length] = param;
    }

    _params = new List.unmodifiable(params);
  }

  String toString() => "MethodMirror on '$_name'";
}
