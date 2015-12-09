dart_library.library('dart/_js_mirrors', null, /* Imports */[
  "dart/_runtime",
  'dart/_internal',
  'dart/core',
  'dart/mirrors'
], /* Lazy imports */[
], function(exports, dart, _internal, core, mirrors) {
  'use strict';
  let dartx = dart.dartx;
  function getName(symbol) {
    return _internal.Symbol.getName(dart.as(symbol, _internal.Symbol));
  }
  dart.fn(getName, core.String, [core.Symbol]);
  function getSymbol(name, library) {
    return dart.throw(new core.UnimplementedError("MirrorSystem.getSymbol unimplemented"));
  }
  dart.fn(getSymbol, core.Symbol, [dart.dynamic, dart.dynamic]);
  dart.defineLazyProperties(exports, {
    get currentJsMirrorSystem() {
      return dart.throw(new core.UnimplementedError("MirrorSystem.currentJsMirrorSystem unimplemented"));
    }
  });
  function reflect(reflectee) {
    return new JsInstanceMirror._(reflectee);
  }
  dart.fn(reflect, mirrors.InstanceMirror, [dart.dynamic]);
  function reflectType(key) {
    return new JsClassMirror._(key);
  }
  dart.fn(reflectType, mirrors.TypeMirror, [core.Type]);
  const _dart = dart;
  const _metadata = _dart.metadata;
  function _dload(obj, name) {
    return _dart.dload(obj, name);
  }
  dart.fn(_dload, dart.dynamic, [dart.dynamic, core.String]);
  function _dput(obj, name, val) {
    _dart.dput(obj, name, val);
  }
  dart.fn(_dput, dart.void, [dart.dynamic, core.String, dart.dynamic]);
  function _dsend(obj, name, args) {
    return _dart.dsend(obj, name, ...args);
  }
  dart.fn(_dsend, dart.dynamic, [dart.dynamic, core.String, core.List]);
  const _toJsMap = Symbol('_toJsMap');
  class JsInstanceMirror extends core.Object {
    _(reflectee) {
      this.reflectee = reflectee;
    }
    get type() {
      return dart.throw(new core.UnimplementedError("ClassMirror.type unimplemented"));
    }
    get hasReflectee() {
      return dart.throw(new core.UnimplementedError("ClassMirror.hasReflectee unimplemented"));
    }
    delegate(invocation) {
      return dart.throw(new core.UnimplementedError("ClassMirror.delegate unimplemented"));
    }
    getField(symbol) {
      let name = getName(symbol);
      let field = _dload(this.reflectee, name);
      return new JsInstanceMirror._(field);
    }
    setField(symbol, value) {
      let name = getName(symbol);
      _dput(this.reflectee, name, value);
      return new JsInstanceMirror._(value);
    }
    invoke(symbol, args, namedArgs) {
      if (namedArgs === void 0)
        namedArgs = null;
      let name = getName(symbol);
      if (namedArgs != null) {
        args = core.List.from(args);
        args[dartx.add](this[_toJsMap](namedArgs));
      }
      let result = _dsend(this.reflectee, name, args);
      return new JsInstanceMirror._(result);
    }
    [_toJsMap](map) {
      let obj = {};
      map.forEach(dart.fn((key, value) => {
        obj[getName(key)] = value;
      }, dart.dynamic, [core.Symbol, dart.dynamic]));
      return obj;
    }
  }
  JsInstanceMirror[dart.implements] = () => [mirrors.InstanceMirror];
  dart.defineNamedConstructor(JsInstanceMirror, '_');
  dart.setSignature(JsInstanceMirror, {
    constructors: () => ({_: [JsInstanceMirror, [core.Object]]}),
    methods: () => ({
      delegate: [dart.dynamic, [core.Invocation]],
      getField: [mirrors.InstanceMirror, [core.Symbol]],
      setField: [mirrors.InstanceMirror, [core.Symbol, core.Object]],
      invoke: [mirrors.InstanceMirror, [core.Symbol, core.List], [core.Map$(core.Symbol, dart.dynamic)]],
      [_toJsMap]: [dart.dynamic, [core.Map$(core.Symbol, dart.dynamic)]]
    })
  });
  const _metadata$ = Symbol('_metadata');
  const _declarations = Symbol('_declarations');
  const _cls = Symbol('_cls');
  class JsClassMirror extends core.Object {
    get metadata() {
      return this[_metadata$];
    }
    get declarations() {
      return this[_declarations];
    }
    _(cls) {
      this[_cls] = cls;
      this.simpleName = core.Symbol.new(cls.name);
      this[_metadata$] = null;
      this[_declarations] = null;
      let fn = this[_cls][dart.metadata];
      this[_metadata$] = fn == null ? dart.list([], mirrors.InstanceMirror) : core.List$(mirrors.InstanceMirror).from(dart.as(dart.dsend(dart.dcall(fn), 'map', dart.fn(i => new JsInstanceMirror._(i), JsInstanceMirror, [dart.dynamic])), core.Iterable));
      this[_declarations] = core.Map$(core.Symbol, mirrors.MethodMirror).new();
      this[_declarations].set(this.simpleName, new JsMethodMirror._(this, this[_cls]));
    }
    newInstance(constructorName, args, namedArgs) {
      if (namedArgs === void 0)
        namedArgs = null;
      dart.assert(getName(constructorName) == "");
      dart.assert(namedArgs == null || dart.notNull(namedArgs.isEmpty));
      let instance = new this[_cls](...args);
      return new JsInstanceMirror._(instance);
    }
    get superinterfaces() {
      let interfaceThunk = this[_cls][dart.implements];
      if (interfaceThunk == null) {
        return dart.list([], mirrors.ClassMirror);
      } else {
        let interfaces = dart.as(dart.dcall(interfaceThunk), core.List$(core.Type));
        return interfaces[dartx.map](dart.fn(t => new JsClassMirror._(dart.as(t, core.Type)), JsClassMirror, [dart.dynamic]))[dartx.toList]();
      }
    }
    getField(fieldName) {
      return dart.throw(new core.UnimplementedError("ClassMirror.getField unimplemented"));
    }
    invoke(memberName, positionalArguments, namedArguments) {
      if (namedArguments === void 0)
        namedArguments = null;
      return dart.throw(new core.UnimplementedError("ClassMirror.invoke unimplemented"));
    }
    isAssignableTo(other) {
      return dart.throw(new core.UnimplementedError("ClassMirror.isAssignable unimplemented"));
    }
    isSubclassOf(other) {
      return dart.throw(new core.UnimplementedError("ClassMirror.isSubclassOf unimplemented"));
    }
    isSubtypeOf(other) {
      return dart.throw(new core.UnimplementedError("ClassMirror.isSubtypeOf unimplemented"));
    }
    setField(fieldName, value) {
      return dart.throw(new core.UnimplementedError("ClassMirror.setField unimplemented"));
    }
    get hasReflectedType() {
      return dart.throw(new core.UnimplementedError("ClassMirror.hasReflectedType unimplemented"));
    }
    get instanceMembers() {
      return dart.throw(new core.UnimplementedError("ClassMirror.instanceMembers unimplemented"));
    }
    get isAbstract() {
      return dart.throw(new core.UnimplementedError("ClassMirror.isAbstract unimplemented"));
    }
    get isEnum() {
      return dart.throw(new core.UnimplementedError("ClassMirror.isEnum unimplemented"));
    }
    get isOriginalDeclaration() {
      return dart.throw(new core.UnimplementedError("ClassMirror.isOriginalDeclaration unimplemented"));
    }
    get isPrivate() {
      return dart.throw(new core.UnimplementedError("ClassMirror.isPrivate unimplemented"));
    }
    get isTopLevel() {
      return dart.throw(new core.UnimplementedError("ClassMirror.isTopLevel unimplemented"));
    }
    get location() {
      return dart.throw(new core.UnimplementedError("ClassMirror.location unimplemented"));
    }
    get mixin() {
      return dart.throw(new core.UnimplementedError("ClassMirror.mixin unimplemented"));
    }
    get originalDeclaration() {
      return this;
    }
    get owner() {
      return dart.throw(new core.UnimplementedError("ClassMirror.owner unimplemented"));
    }
    get qualifiedName() {
      return dart.throw(new core.UnimplementedError("ClassMirror.qualifiedName unimplemented"));
    }
    get reflectedType() {
      return this[_cls];
    }
    get staticMembers() {
      return dart.throw(new core.UnimplementedError("ClassMirror.staticMembers unimplemented"));
    }
    get superclass() {
      if (dart.equals(this[_cls], core.Object)) {
        return null;
      } else {
        return new JsClassMirror._(this[_cls].__proto__);
      }
    }
    get typeArguments() {
      return dart.throw(new core.UnimplementedError("ClassMirror.typeArguments unimplemented"));
    }
    get typeVariables() {
      return dart.throw(new core.UnimplementedError("ClassMirror.typeVariables unimplemented"));
    }
  }
  JsClassMirror[dart.implements] = () => [mirrors.ClassMirror];
  dart.defineNamedConstructor(JsClassMirror, '_');
  dart.setSignature(JsClassMirror, {
    constructors: () => ({_: [JsClassMirror, [core.Type]]}),
    methods: () => ({
      newInstance: [mirrors.InstanceMirror, [core.Symbol, core.List], [core.Map$(core.Symbol, dart.dynamic)]],
      getField: [mirrors.InstanceMirror, [core.Symbol]],
      invoke: [mirrors.InstanceMirror, [core.Symbol, core.List], [core.Map$(core.Symbol, dart.dynamic)]],
      isAssignableTo: [core.bool, [mirrors.TypeMirror]],
      isSubclassOf: [core.bool, [mirrors.ClassMirror]],
      isSubtypeOf: [core.bool, [mirrors.TypeMirror]],
      setField: [mirrors.InstanceMirror, [core.Symbol, core.Object]]
    })
  });
  class JsTypeMirror extends core.Object {
    _(reflectedType) {
      this.reflectedType = reflectedType;
      this.hasReflectedType = true;
    }
    isAssignableTo(other) {
      return dart.throw(new core.UnimplementedError("TypeMirror.isAssignable unimplemented"));
    }
    isSubtypeOf(other) {
      return dart.throw(new core.UnimplementedError("TypeMirror.isSubtypeOf unimplemented"));
    }
    get isOriginalDeclaration() {
      return dart.throw(new core.UnimplementedError("TypeMirror.isOriginalDeclaration unimplemented"));
    }
    get isPrivate() {
      return dart.throw(new core.UnimplementedError("TypeMirror.isPrivate unimplemented"));
    }
    get isTopLevel() {
      return dart.throw(new core.UnimplementedError("TypeMirror.isTopLevel unimplemented"));
    }
    get location() {
      return dart.throw(new core.UnimplementedError("TypeMirror.location unimplemented"));
    }
    get metadata() {
      return dart.throw(new core.UnimplementedError("TypeMirror.metadata unimplemented"));
    }
    get originalDeclaration() {
      return dart.throw(new core.UnimplementedError("TypeMirror.originalDeclaration unimplemented"));
    }
    get owner() {
      return dart.throw(new core.UnimplementedError("TypeMirror.owner unimplemented"));
    }
    get qualifiedName() {
      return dart.throw(new core.UnimplementedError("TypeMirror.qualifiedName unimplemented"));
    }
    get simpleName() {
      return dart.throw(new core.UnimplementedError("TypeMirror.simpleName unimplemented"));
    }
    get typeArguments() {
      return dart.throw(new core.UnimplementedError("TypeMirror.typeArguments unimplemented"));
    }
    get typeVariables() {
      return dart.throw(new core.UnimplementedError("TypeMirror.typeVariables unimplemented"));
    }
  }
  JsTypeMirror[dart.implements] = () => [mirrors.TypeMirror];
  dart.defineNamedConstructor(JsTypeMirror, '_');
  dart.setSignature(JsTypeMirror, {
    constructors: () => ({_: [JsTypeMirror, [core.Type]]}),
    methods: () => ({
      isAssignableTo: [core.bool, [mirrors.TypeMirror]],
      isSubtypeOf: [core.bool, [mirrors.TypeMirror]]
    })
  });
  const _name = Symbol('_name');
  class JsParameterMirror extends core.Object {
    _(name, t, annotations) {
      this[_name] = name;
      this.type = new JsTypeMirror._(t);
      this.metadata = core.List$(mirrors.InstanceMirror).from(annotations[dartx.map](dart.fn(a => new JsInstanceMirror._(a), JsInstanceMirror, [dart.dynamic])));
    }
    get defaultValue() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.defaultValues unimplemented"));
    }
    get hasDefaultValue() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.hasDefaultValue unimplemented"));
    }
    get isConst() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isConst unimplemented"));
    }
    get isFinal() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isFinal unimplemented"));
    }
    get isNamed() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isNamed unimplemented"));
    }
    get isOptional() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isOptional unimplemented"));
    }
    get isPrivate() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isPrivate unimplemented"));
    }
    get isStatic() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isStatic unimplemented"));
    }
    get isTopLevel() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.isTopLevel unimplemented"));
    }
    get location() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.location unimplemented"));
    }
    get owner() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.owner unimplemented"));
    }
    get qualifiedName() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.qualifiedName unimplemented"));
    }
    get simpleName() {
      return dart.throw(new core.UnimplementedError("ParameterMirror.simpleName unimplemented"));
    }
  }
  JsParameterMirror[dart.implements] = () => [mirrors.ParameterMirror];
  dart.defineNamedConstructor(JsParameterMirror, '_');
  dart.setSignature(JsParameterMirror, {
    constructors: () => ({_: [JsParameterMirror, [core.String, core.Type, core.List]]})
  });
  const _method = Symbol('_method');
  const _params = Symbol('_params');
  const _createParameterMirrorList = Symbol('_createParameterMirrorList');
  class JsMethodMirror extends core.Object {
    _(cls, method) {
      this[_method] = method;
      this[_name] = getName(cls.simpleName);
      this[_params] = null;
      let ftype = _dart.classGetConstructorType(cls[_cls]);
      this[_params] = this[_createParameterMirrorList](ftype);
    }
    get constructorName() {
      return core.Symbol.new('');
    }
    get parameters() {
      return this[_params];
    }
    [_createParameterMirrorList](ftype) {
      if (ftype == null) {
        return dart.list([], mirrors.ParameterMirror);
      }
      let args = dart.as(dart.dload(ftype, 'args'), core.List);
      let opts = dart.as(dart.dload(ftype, 'optionals'), core.List);
      let params = core.List$(mirrors.ParameterMirror).new(dart.notNull(args[dartx.length]) + dart.notNull(opts[dartx.length]));
      for (let i = 0; dart.notNull(i) < dart.notNull(args[dartx.length]); i = dart.notNull(i) + 1) {
        let type = args[dartx.get](i);
        let metadata = dart.dindex(dart.dload(ftype, 'metadata'), i);
        let param = new JsParameterMirror._('', dart.as(type, core.Type), dart.as(metadata, core.List));
        params[dartx.set](i, param);
      }
      for (let i = 0; dart.notNull(i) < dart.notNull(opts[dartx.length]); i = dart.notNull(i) + 1) {
        let type = opts[dartx.get](i);
        let metadata = dart.dindex(dart.dload(ftype, 'metadata'), dart.notNull(args[dartx.length]) + dart.notNull(i));
        let param = new JsParameterMirror._('', dart.as(type, core.Type), dart.as(metadata, core.List));
        params[dartx.set](dart.notNull(i) + dart.notNull(args[dartx.length]), param);
      }
      return params;
    }
    get isAbstract() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isAbstract unimplemented"));
    }
    get isConstConstructor() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isConstConstructor unimplemented"));
    }
    get isConstructor() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isConstructor unimplemented"));
    }
    get isFactoryConstructor() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isFactoryConstructor unimplemented"));
    }
    get isGenerativeConstructor() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isGenerativeConstructor unimplemented"));
    }
    get isGetter() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isGetter unimplemented"));
    }
    get isOperator() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isOperator unimplemented"));
    }
    get isPrivate() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isPrivate unimplemented"));
    }
    get isRedirectingConstructor() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isRedirectingConstructor unimplemented"));
    }
    get isRegularMethod() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isRegularMethod unimplemented"));
    }
    get isSetter() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isSetter unimplemented"));
    }
    get isStatic() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isStatic unimplemented"));
    }
    get isSynthetic() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isSynthetic unimplemented"));
    }
    get isTopLevel() {
      return dart.throw(new core.UnimplementedError("MethodMirror.isTopLevel unimplemented"));
    }
    get location() {
      return dart.throw(new core.UnimplementedError("MethodMirror.location unimplemented"));
    }
    get metadata() {
      return dart.list([], mirrors.InstanceMirror);
    }
    get owner() {
      return dart.throw(new core.UnimplementedError("MethodMirror.owner unimplemented"));
    }
    get qualifiedName() {
      return dart.throw(new core.UnimplementedError("MethodMirror.qualifiedName unimplemented"));
    }
    get returnType() {
      return dart.throw(new core.UnimplementedError("MethodMirror.returnType unimplemented"));
    }
    get simpleName() {
      return dart.throw(new core.UnimplementedError("MethodMirror.simpleName unimplemented"));
    }
    get source() {
      return dart.throw(new core.UnimplementedError("MethodMirror.source unimplemented"));
    }
  }
  JsMethodMirror[dart.implements] = () => [mirrors.MethodMirror];
  dart.defineNamedConstructor(JsMethodMirror, '_');
  dart.setSignature(JsMethodMirror, {
    constructors: () => ({_: [JsMethodMirror, [JsClassMirror, dart.dynamic]]}),
    methods: () => ({[_createParameterMirrorList]: [core.List$(mirrors.ParameterMirror), [dart.dynamic]]})
  });
  // Exports:
  exports.getName = getName;
  exports.getSymbol = getSymbol;
  exports.reflect = reflect;
  exports.reflectType = reflectType;
  exports.JsInstanceMirror = JsInstanceMirror;
  exports.JsClassMirror = JsClassMirror;
  exports.JsTypeMirror = JsTypeMirror;
  exports.JsParameterMirror = JsParameterMirror;
  exports.JsMethodMirror = JsMethodMirror;
});
