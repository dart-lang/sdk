// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:mirrors';
import 'dart:_runtime' as dart;
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' as _internal show Symbol;
import 'dart:_js_helper' show PrivateSymbol;

String getName(Symbol symbol) {
  if (symbol is PrivateSymbol) {
    return PrivateSymbol.getName(symbol);
  } else {
    return _internal.Symbol.getName(symbol as _internal.Symbol);
  }
}

Symbol getSymbol(name, library) =>
    throw new UnimplementedError("MirrorSystem.getSymbol unimplemented");

final currentJsMirrorSystem = new JsMirrorSystem();

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
  var unwrapped = dart.unwrapType(key);
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

typedef T _Lazy<T>();

dynamic _getESSymbol(Symbol symbol) => PrivateSymbol.getNativeSymbol(symbol);

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
  return new PrivateSymbol(name, member);
}

// The [member] must be either a string (public) or an ES6 symbol (private).
Symbol _getSymbolForMember(member) {
  if (member is String) {
    return new Symbol(member);
  } else {
    var name = _getNameForESSymbol(member);
    return new PrivateSymbol(name, member);
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

dynamic _runtimeType(obj) => dart.wrapType(dart.getReifiedType(obj));

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

class JsMirrorSystem implements MirrorSystem {
  get libraries => const {};

  noSuchMethod(Invocation i) {
    _unimplemented(this.runtimeType, i);
  }
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

  InstanceMirror getField(Symbol symbol) {
    var name = _getMember(symbol);
    var field = dart.dloadMirror(reflectee, name);
    return reflect(field);
  }

  InstanceMirror setField(Symbol symbol, Object value) {
    var name = _getMember(symbol);
    dart.dputMirror(reflectee, name, value);
    return reflect(value);
  }

  InstanceMirror invoke(Symbol symbol, List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    var name = _getMember(symbol);
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = dart.callMethod(reflectee, name, null, args, name);
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
    var result = dart.dcall(reflectee, args);
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
      var unwrapped = dart.unwrapType(_cls);
      // Only get metadata directly embedded on this class, not its
      // superclasses.
      var fn = JS(
          'Function|Null',
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
      var unwrapped = dart.unwrapType(_cls);
      var constructors = _toDartMap(dart.getConstructors(unwrapped));
      constructors.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._constructor(this, symbol, ft);
      });
      if (constructors.isEmpty) {
        // Add a default
        var name = 'new';
        var ft = dart.fnType(dart.unwrapType(_cls), []);
        var symbol = new Symbol(name);
        _declarations[symbol] =
            new JsMethodMirror._constructor(this, symbol, ft);
      }
      var fields = _toDartMap(dart.getFields(unwrapped));
      fields.forEach((symbol, t) {
        _declarations[symbol] = new JsVariableMirror._fromField(symbol, t);
      });
      var methods = _toDartMap(dart.getMethods(unwrapped));
      methods.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._instanceMethod(this, symbol, ft);
      });
      var getters = _toDartMap(dart.getGetters(unwrapped));
      getters.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._instanceMethod(this, symbol, ft);
      });
      var setters = _toDartMap(dart.getSetters(unwrapped));
      setters.forEach((symbol, ft) {
        var name = getName(symbol) + '=';
        // Create a separate symbol for the setter.
        symbol = new PrivateSymbol(name, _getESSymbol(symbol));
        _declarations[symbol] =
            new JsMethodMirror._instanceMethod(this, symbol, ft);
      });
      var staticFields = _toDartMap(dart.getStaticFields(unwrapped));
      staticFields.forEach((symbol, t) {
        _declarations[symbol] = new JsVariableMirror._fromField(symbol, t);
      });
      var statics = _toDartMap(dart.getStaticMethods(unwrapped));
      statics.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._staticMethod(this, symbol, ft);
      });
      var staticGetters = _toDartMap(dart.getStaticGetters(unwrapped));
      staticGetters.forEach((symbol, ft) {
        var name = getName(symbol);
        _declarations[symbol] =
            new JsMethodMirror._staticMethod(this, symbol, ft);
      });
      var staticSetters = _toDartMap(dart.getStaticSetters(unwrapped));
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
        _raw = instantiated ? dart.getGenericClass(dart.unwrapType(cls)) : null,
        simpleName = new Symbol(JS('String', '#.name', dart.unwrapType(cls))) {
    var typeArgs = dart.getGenericArgs(dart.unwrapType(_cls));
    if (typeArgs == null) {
      _typeArguments = const [];
    } else {
      _typeArguments = new List.unmodifiable(
          typeArgs.map((t) => reflectType(dart.wrapType(t))));
    }
  }

  InstanceMirror newInstance(Symbol constructorName, List args,
      [Map<Symbol, dynamic> namedArgs]) {
    // TODO(vsm): Support named arguments.
    var name = getName(constructorName);
    assert(namedArgs == null || namedArgs.isEmpty);
    // Default constructors are mapped to new.
    if (name == '') name = 'new';
    var cls = dart.unwrapType(_cls);
    var ctr = JS('', '#.#', cls, name);
    // Only generative Dart constructors are wired up as real JS constructors.
    var instance = JS('bool', '#.prototype == #.prototype', cls, ctr)
        // Generative
        ? JS('', 'new #(...#)', ctr, args)
        // Factory
        : JS('', '#(...#)', ctr, args);
    return reflect(instance);
  }

  // TODO(vsm): Need to check for NSM, types on accessors below.  Unlike the
  // InstanceMirror case, there is no dynamic helper to delegate to - we never
  // need a dload, etc. on a static.

  InstanceMirror getField(Symbol symbol) {
    var name = getName(symbol);
    return reflect(JS('', '#[#]', dart.unwrapType(_cls), name));
  }

  InstanceMirror setField(Symbol symbol, Object value) {
    var name = getName(symbol);
    JS('', '#[#] = #', dart.unwrapType(_cls), name, value);
    return reflect(value);
  }

  InstanceMirror invoke(Symbol symbol, List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    var name = getName(symbol);
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = JS('', '#.#(...#)', dart.unwrapType(_cls), name, args);
    return reflect(result);
  }

  List<ClassMirror> get superinterfaces {
    _Lazy<List<Type>> interfaceThunk =
        JS('', '#[dart.implements]', dart.unwrapType(_cls));
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
    _originalDeclaration = new JsClassMirror._(
        dart.wrapType(JS('', '#()', _raw)),
        instantiated: false);
    return _originalDeclaration;
  }

  ClassMirror get superclass {
    if (_cls == Object) {
      return null;
    } else {
      return reflectType(
          dart.wrapType(JS('Type', '#.__proto__', dart.unwrapType(_cls))));
    }
  }

  ClassMirror get mixin {
    if (_mixin != null) {
      return _mixin;
    }
    var mixin = dart.getMixin(dart.unwrapType(_cls));
    if (mixin == null) {
      // If there is no mixin, return this mirror per API.
      _mixin = this;
      return _mixin;
    }
    _mixin = reflectType(dart.wrapType(mixin));
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
      : this._(symbol, dart.wrapType(JS('', '#.type', fieldInfo)),
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
    ftype = dart.getFunctionTypeMirror(ftype);

    // TODO(vsm): Add named args.
    List args = ftype.args;
    List opts = ftype.optionals;
    var params = new List<ParameterMirror>(args.length + opts.length);

    for (var i = 0; i < args.length; ++i) {
      var type = args[i];
      var metadata = ftype.metadata[i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._(
          new Symbol(''), dart.wrapType(type), metadata);
      params[i] = param;
    }

    for (var i = 0; i < opts.length; ++i) {
      var type = opts[i];
      var metadata = ftype.metadata[args.length + i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._(
          new Symbol(''), dart.wrapType(type), metadata);
      params[i + args.length] = param;
    }

    _params = new List.unmodifiable(params);
  }

  String toString() => "MethodMirror on '$_name'";
}
