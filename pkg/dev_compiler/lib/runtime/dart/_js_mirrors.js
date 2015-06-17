dart_library.library('dart/_js_mirrors', null, /* Imports */[
  "dart_runtime/dart",
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
    return dart.throw_(new core.UnimplementedError("MirrorSystem.getSymbol unimplemented"));
  }
  dart.fn(getSymbol, core.Symbol, [dart.dynamic, dart.dynamic]);
  dart.defineLazyProperties(exports, {
    get currentJsMirrorSystem() {
      return dart.throw_(new core.UnimplementedError("MirrorSystem.currentJsMirrorSystem unimplemented"));
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
  dart.defineLazyProperties(exports, {
    get _dart() {
      return dart;
    },
    get _metadata() {
      return exports._dart.metadata;
    }
  });
  function _dload(obj, name) {
    return exports._dart.dload(obj, name);
  }
  dart.fn(_dload, dart.dynamic, [dart.dynamic, core.String]);
  function _dput(obj, name, val) {
    exports._dart.dput(obj, name, val);
  }
  dart.fn(_dput, dart.void, [dart.dynamic, core.String, dart.dynamic]);
  function _dsend(obj, name, args) {
    return exports._dart.dsend(obj, name, ...args);
  }
  dart.fn(_dsend, dart.dynamic, [dart.dynamic, core.String, core.List]);
  let _toJsMap = Symbol('_toJsMap');
  class JsInstanceMirror extends core.Object {
    _(reflectee) {
      this.reflectee = reflectee;
    }
    getField(symbol) {
      let name = getName(symbol);
      let field = _dload(this.reflectee, name);
      return new JsInstanceMirror._(field);
    }
    setField(symbol, value) {
      let name = getName(symbol);
      let field = _dput(this.reflectee, name, value);
      return new JsInstanceMirror._(field);
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
      getField: [mirrors.InstanceMirror, [core.Symbol]],
      setField: [mirrors.InstanceMirror, [core.Symbol, core.Object]],
      invoke: [mirrors.InstanceMirror, [core.Symbol, core.List], [core.Map$(core.Symbol, dart.dynamic)]],
      [_toJsMap]: [dart.dynamic, [core.Map$(core.Symbol, dart.dynamic)]]
    })
  });
  let _metadata = Symbol('_metadata');
  let _declarations = Symbol('_declarations');
  let _cls = Symbol('_cls');
  class JsClassMirror extends core.Object {
    get metadata() {
      return this[_metadata];
    }
    get declarations() {
      return this[_declarations];
    }
    _(cls) {
      this[_cls] = cls;
      this.simpleName = core.Symbol.new(cls.name);
      this[_metadata] = null;
      this[_declarations] = null;
      let fn = this[_cls][dart.metadata];
      this[_metadata] = fn == null ? dart.list([], mirrors.InstanceMirror) : core.List$(mirrors.InstanceMirror).from(dart.as(dart.dsend(dart.dcall(fn), 'map', dart.fn(i => new JsInstanceMirror._(i), JsInstanceMirror, [dart.dynamic])), core.Iterable));
      this[_declarations] = core.Map$(core.Symbol, mirrors.MethodMirror).new();
      this[_declarations].set(this.simpleName, new JsMethodMirror._(this, this[_cls]));
    }
    newInstance(constructorName, args, namedArgs) {
      if (namedArgs === void 0)
        namedArgs = null;
      dart.assert(getName(constructorName) == "");
      dart.assert(namedArgs == null || dart.notNull(namedArgs.isEmpty));
      let instance = exports._dart.instantiate(this[_cls], args);
      return new JsInstanceMirror._(instance);
    }
  }
  JsClassMirror[dart.implements] = () => [mirrors.ClassMirror];
  dart.defineNamedConstructor(JsClassMirror, '_');
  dart.setSignature(JsClassMirror, {
    constructors: () => ({_: [JsClassMirror, [core.Type]]}),
    methods: () => ({newInstance: [mirrors.InstanceMirror, [core.Symbol, core.List], [core.Map$(core.Symbol, dart.dynamic)]]})
  });
  class JsTypeMirror extends core.Object {
    _(reflectedType) {
      this.reflectedType = reflectedType;
    }
  }
  JsTypeMirror[dart.implements] = () => [mirrors.TypeMirror];
  dart.defineNamedConstructor(JsTypeMirror, '_');
  dart.setSignature(JsTypeMirror, {
    constructors: () => ({_: [JsTypeMirror, [core.Type]]})
  });
  let _name = Symbol('_name');
  class JsParameterMirror extends core.Object {
    _(name, t) {
      this.metadata = dart.list([], mirrors.InstanceMirror);
      this[_name] = name;
      this.type = new JsTypeMirror._(t);
    }
  }
  JsParameterMirror[dart.implements] = () => [mirrors.ParameterMirror];
  dart.defineNamedConstructor(JsParameterMirror, '_');
  dart.setSignature(JsParameterMirror, {
    constructors: () => ({_: [JsParameterMirror, [core.String, core.Type]]})
  });
  let _method = Symbol('_method');
  let _params = Symbol('_params');
  let _createParameterMirrorList = Symbol('_createParameterMirrorList');
  class JsMethodMirror extends core.Object {
    _(cls, method) {
      this[_method] = method;
      this[_name] = getName(cls.simpleName);
      this[_params] = null;
      let ftype = exports._dart.classGetConstructorType(cls[_cls]);
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
        let param = new JsParameterMirror._('', dart.as(type, core.Type));
        params[dartx.set](i, param);
      }
      for (let i = 0; dart.notNull(i) < dart.notNull(opts[dartx.length]); i = dart.notNull(i) + 1) {
        let type = opts[dartx.get](i);
        let param = new JsParameterMirror._('', dart.as(type, core.Type));
        params[dartx.set](dart.notNull(i) + dart.notNull(args[dartx.length]), param);
      }
      return params;
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
