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

InstanceMirror reflect(reflectee) => new JsInstanceMirror._(reflectee);

TypeMirror reflectType(Type key) {
  // TODO(vsm): Might not be a class.
  return new JsClassMirror._(key);
}

final dynamic _dart = JS('', 'dart');

dynamic _dload(obj, String name) {
  return JS('', '#.dload(#, #)', _dart, obj, name);
}

void _dput(obj, String name, val) {
  JS('', '#.dput(#, #, #)', _dart, obj, name, val);
}

dynamic _dsend(obj, String name, List args) {
  return JS('', '#.dsend(#, #, ...#)', _dart, obj, name, args);
}

class JsInstanceMirror implements InstanceMirror {
  final Object reflectee;

  JsInstanceMirror._(this.reflectee);

  ClassMirror get type =>
      throw new UnimplementedError("ClassMirror.type unimplemented");
  bool get hasReflectee =>
      throw new UnimplementedError("ClassMirror.hasReflectee unimplemented");
  delegate(Invocation invocation) =>
      throw new UnimplementedError("ClassMirror.delegate unimplemented");

  InstanceMirror getField(Symbol symbol) {
    var name = getName(symbol);
    var field = _dload(reflectee, name);
    return new JsInstanceMirror._(field);
  }

  InstanceMirror setField(Symbol symbol, Object value) {
    var name = getName(symbol);
    _dput(reflectee, name, value);
    return new JsInstanceMirror._(value);
  }

  InstanceMirror invoke(Symbol symbol, List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    var name = getName(symbol);
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = _dsend(reflectee, name, args);
    return new JsInstanceMirror._(result);
  }

  dynamic _toJsMap(Map<Symbol, dynamic> map) {
    var obj = JS('', '{}');
    map.forEach((Symbol key, value) {
      JS('', '#[#] = #', obj, getName(key), value);
    });
    return obj;
  }
}

class JsClassMirror implements ClassMirror {
  final Type _cls;
  final Symbol simpleName;

  List<InstanceMirror> _metadata;
  Map<Symbol, MethodMirror> _declarations;

  // TODO(vsm):These need to be immutable when escaping from this class.
  List<InstanceMirror> get metadata => _metadata;
  Map<Symbol, MethodMirror> get declarations => _declarations;

  JsClassMirror._(Type cls)
      : _cls = cls,
        simpleName = new Symbol(JS('String', '#.name', cls)) {
    // Load metadata.
    var fn = JS('Function', '#[dart.metadata]', _cls);
    _metadata = (fn == null)
        ? <InstanceMirror>[]
        : new List<InstanceMirror>.from(
            fn().map((i) => new JsInstanceMirror._(i)));

    // Load declarations.
    // TODO(vsm): This is only populating the default constructor right now.
    _declarations = new Map<Symbol, MethodMirror>();
    _declarations[simpleName] = new JsMethodMirror._(this, _cls);
  }

  InstanceMirror newInstance(Symbol constructorName, List args,
      [Map<Symbol, dynamic> namedArgs]) {
    // TODO(vsm): Support named constructors and named arguments.
    assert(getName(constructorName) == "");
    assert(namedArgs == null || namedArgs.isEmpty);
    var instance = JS('', 'new #(...#)', _cls, args);
    return new JsInstanceMirror._(instance);
  }

  List<ClassMirror> get superinterfaces {
    var interfaceThunk = JS('Function', '#[dart.implements]', _cls);
    if (interfaceThunk == null) {
      return [];
    } else {
      List<Type> interfaces = interfaceThunk();
      return interfaces.map((t) => new JsClassMirror._(t)).toList();
    }
  }

  // TODO(vsm): Implement
  InstanceMirror getField(Symbol fieldName) =>
      throw new UnimplementedError("ClassMirror.getField unimplemented");
  InstanceMirror invoke(Symbol memberName, List positionalArguments,
          [Map<Symbol, dynamic> namedArguments]) =>
      throw new UnimplementedError("ClassMirror.invoke unimplemented");
  bool isAssignableTo(TypeMirror other) =>
      throw new UnimplementedError("ClassMirror.isAssignable unimplemented");
  bool isSubclassOf(ClassMirror other) =>
      throw new UnimplementedError("ClassMirror.isSubclassOf unimplemented");
  bool isSubtypeOf(TypeMirror other) =>
      throw new UnimplementedError("ClassMirror.isSubtypeOf unimplemented");
  InstanceMirror setField(Symbol fieldName, Object value) =>
      throw new UnimplementedError("ClassMirror.setField unimplemented");
  bool get hasReflectedType => throw new UnimplementedError(
      "ClassMirror.hasReflectedType unimplemented");
  Map<Symbol, MethodMirror> get instanceMembers =>
      throw new UnimplementedError("ClassMirror.instanceMembers unimplemented");
  bool get isAbstract =>
      throw new UnimplementedError("ClassMirror.isAbstract unimplemented");
  bool get isEnum =>
      throw new UnimplementedError("ClassMirror.isEnum unimplemented");
  bool get isOriginalDeclaration => throw new UnimplementedError(
      "ClassMirror.isOriginalDeclaration unimplemented");
  bool get isPrivate =>
      throw new UnimplementedError("ClassMirror.isPrivate unimplemented");
  bool get isTopLevel =>
      throw new UnimplementedError("ClassMirror.isTopLevel unimplemented");
  SourceLocation get location =>
      throw new UnimplementedError("ClassMirror.location unimplemented");
  ClassMirror get mixin =>
      throw new UnimplementedError("ClassMirror.mixin unimplemented");
  TypeMirror get originalDeclaration {
    // TODO(vsm): Handle generic case.  How should we represent an original
    // declaration for a generic class?
    return this;
  }
  DeclarationMirror get owner =>
      throw new UnimplementedError("ClassMirror.owner unimplemented");
  Symbol get qualifiedName =>
      throw new UnimplementedError("ClassMirror.qualifiedName unimplemented");
  Type get reflectedType { return _cls; }
  Map<Symbol, MethodMirror> get staticMembers =>
      throw new UnimplementedError("ClassMirror.staticMembers unimplemented");
  ClassMirror get superclass {
    if (_cls == Object) {
      return null;
    } else {
      return new JsClassMirror._(JS('Type', '#.__proto__', _cls));
    }
  }
  List<TypeMirror> get typeArguments =>
      throw new UnimplementedError("ClassMirror.typeArguments unimplemented");
  List<TypeVariableMirror> get typeVariables =>
      throw new UnimplementedError("ClassMirror.typeVariables unimplemented");
}

class JsTypeMirror implements TypeMirror {
  // TODO(vsm): Support original declarations, etc., where there is no actual
  // reflected type.
  final Type reflectedType;
  final bool hasReflectedType = true;

  JsTypeMirror._(this.reflectedType);

  // TODO(vsm): Implement
  bool isAssignableTo(TypeMirror other) =>
      throw new UnimplementedError("TypeMirror.isAssignable unimplemented");
  bool isSubtypeOf(TypeMirror other) =>
      throw new UnimplementedError("TypeMirror.isSubtypeOf unimplemented");
  bool get isOriginalDeclaration => throw new UnimplementedError(
      "TypeMirror.isOriginalDeclaration unimplemented");
  bool get isPrivate =>
      throw new UnimplementedError("TypeMirror.isPrivate unimplemented");
  bool get isTopLevel =>
      throw new UnimplementedError("TypeMirror.isTopLevel unimplemented");
  SourceLocation get location =>
      throw new UnimplementedError("TypeMirror.location unimplemented");
  List<InstanceMirror> get metadata =>
      throw new UnimplementedError("TypeMirror.metadata unimplemented");
  TypeMirror get originalDeclaration => throw new UnimplementedError(
      "TypeMirror.originalDeclaration unimplemented");
  DeclarationMirror get owner =>
      throw new UnimplementedError("TypeMirror.owner unimplemented");
  Symbol get qualifiedName =>
      throw new UnimplementedError("TypeMirror.qualifiedName unimplemented");
  Symbol get simpleName =>
      throw new UnimplementedError("TypeMirror.simpleName unimplemented");
  List<TypeMirror> get typeArguments =>
      throw new UnimplementedError("TypeMirror.typeArguments unimplemented");
  List<TypeVariableMirror> get typeVariables =>
      throw new UnimplementedError("TypeMirror.typeVariables unimplemented");
}

class JsParameterMirror implements ParameterMirror {
  final String _name;
  final TypeMirror type;
  final List<InstanceMirror> metadata;

  JsParameterMirror._(this._name, Type t, List annotations)
      : type = new JsTypeMirror._(t),
        metadata = new List<InstanceMirror>.from(
            annotations.map((a) => new JsInstanceMirror._(a)));

  // TODO(vsm): Implement
  InstanceMirror get defaultValue => throw new UnimplementedError(
      "ParameterMirror.defaultValues unimplemented");
  bool get hasDefaultValue => throw new UnimplementedError(
      "ParameterMirror.hasDefaultValue unimplemented");
  bool get isConst =>
      throw new UnimplementedError("ParameterMirror.isConst unimplemented");
  bool get isFinal =>
      throw new UnimplementedError("ParameterMirror.isFinal unimplemented");
  bool get isNamed =>
      throw new UnimplementedError("ParameterMirror.isNamed unimplemented");
  bool get isOptional =>
      throw new UnimplementedError("ParameterMirror.isOptional unimplemented");
  bool get isPrivate =>
      throw new UnimplementedError("ParameterMirror.isPrivate unimplemented");
  bool get isStatic =>
      throw new UnimplementedError("ParameterMirror.isStatic unimplemented");
  bool get isTopLevel =>
      throw new UnimplementedError("ParameterMirror.isTopLevel unimplemented");
  SourceLocation get location =>
      throw new UnimplementedError("ParameterMirror.location unimplemented");
  DeclarationMirror get owner =>
      throw new UnimplementedError("ParameterMirror.owner unimplemented");
  Symbol get qualifiedName => throw new UnimplementedError(
      "ParameterMirror.qualifiedName unimplemented");
  Symbol get simpleName =>
      throw new UnimplementedError("ParameterMirror.simpleName unimplemented");
}

class JsMethodMirror implements MethodMirror {
  final String _name;
  final dynamic _method;
  List<ParameterMirror> _params;

  JsMethodMirror._(JsClassMirror cls, this._method)
      : _name = getName(cls.simpleName) {
    var ftype = JS('', '#.classGetConstructorType(#)', _dart, cls._cls);
    _params = _createParameterMirrorList(ftype);
  }

  // TODO(vsm): Support named constructors.
  Symbol get constructorName => new Symbol('');
  List<ParameterMirror> get parameters => _params;

  List<ParameterMirror> _createParameterMirrorList(ftype) {
    if (ftype == null) {
      // TODO(vsm): No explicit constructor.  Verify this.
      return [];
    }

    // TODO(vsm): Add named args.
    List args = ftype.args;
    List opts = ftype.optionals;
    var params = new List<ParameterMirror>(args.length + opts.length);

    for (var i = 0; i < args.length; ++i) {
      var type = args[i];
      var metadata = ftype.metadata[i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._('', type, metadata);
      params[i] = param;
    }

    for (var i = 0; i < opts.length; ++i) {
      var type = opts[i];
      var metadata = ftype.metadata[args.length + i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._('', type, metadata);
      params[i + args.length] = param;
    }

    return params;
  }

  // TODO(vsm): Implement
  bool get isAbstract =>
      throw new UnimplementedError("MethodMirror.isAbstract unimplemented");
  bool get isConstConstructor => throw new UnimplementedError(
      "MethodMirror.isConstConstructor unimplemented");
  bool get isConstructor =>
      throw new UnimplementedError("MethodMirror.isConstructor unimplemented");
  bool get isFactoryConstructor => throw new UnimplementedError(
      "MethodMirror.isFactoryConstructor unimplemented");
  bool get isGenerativeConstructor => throw new UnimplementedError(
      "MethodMirror.isGenerativeConstructor unimplemented");
  bool get isGetter =>
      throw new UnimplementedError("MethodMirror.isGetter unimplemented");
  bool get isOperator =>
      throw new UnimplementedError("MethodMirror.isOperator unimplemented");
  bool get isPrivate =>
      throw new UnimplementedError("MethodMirror.isPrivate unimplemented");
  bool get isRedirectingConstructor => throw new UnimplementedError(
      "MethodMirror.isRedirectingConstructor unimplemented");
  bool get isRegularMethod => throw new UnimplementedError(
      "MethodMirror.isRegularMethod unimplemented");
  bool get isSetter =>
      throw new UnimplementedError("MethodMirror.isSetter unimplemented");
  bool get isStatic =>
      throw new UnimplementedError("MethodMirror.isStatic unimplemented");
  bool get isSynthetic =>
      throw new UnimplementedError("MethodMirror.isSynthetic unimplemented");
  bool get isTopLevel =>
      throw new UnimplementedError("MethodMirror.isTopLevel unimplemented");
  SourceLocation get location =>
      throw new UnimplementedError("MethodMirror.location unimplemented");
  List<InstanceMirror> get metadata {
    // TODO(vsm): Parse and store method metadata
    return <InstanceMirror>[];
  }
  DeclarationMirror get owner =>
      throw new UnimplementedError("MethodMirror.owner unimplemented");
  Symbol get qualifiedName =>
      throw new UnimplementedError("MethodMirror.qualifiedName unimplemented");
  TypeMirror get returnType =>
      throw new UnimplementedError("MethodMirror.returnType unimplemented");
  Symbol get simpleName =>
      throw new UnimplementedError("MethodMirror.simpleName unimplemented");
  String get source =>
      throw new UnimplementedError("MethodMirror.source unimplemented");
}
