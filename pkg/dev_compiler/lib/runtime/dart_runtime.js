var dart;
(function (dart) {
  var defineProperty = Object.defineProperty;
  var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  var getOwnPropertyNames = Object.getOwnPropertyNames;

  // Adapted from Angular.js
  var FN_ARGS = /^function\s*[^\(]*\(\s*([^\)]*)\)/m;
  var FN_ARG_SPLIT = /,/;
  var FN_ARG = /^\s*(_?)(\S+?)\1\s*$/;
  var STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg;

  function formalParameterList(fn) {
    var fnText,argDecl;
    var args=[];
    fnText = fn.toString().replace(STRIP_COMMENTS, '');
    argDecl = fnText.match(FN_ARGS);

    var r = argDecl[1].split(FN_ARG_SPLIT);
    for(var a in r){
      var arg = r[a];
      arg.replace(FN_ARG, function(all, underscore, name){
        args.push(name);
      });
    }
    return args;
  }

  function dload(obj, field) {
    if (!(field in obj)) {
      throw new dart_core.NoSuchMethodError(obj, field);
    }
    return obj[field];
  }
  dart.dload = dload;

  function dinvokef(f, args) {
    var formals = formalParameterList(f);
    // TODO(vsm): Type check args!  We need to encode sufficient type info on f.
    if (formals.length < args.length) {
      throw new dart_core.NoSuchMethodError(f, args);
    } else if (formals.length > args.length) {
      for (var i = args.length; i < formals.length; ++i) {
        if (formals[i].indexOf("opt$") != 0)
          throw new dart_core.NoSuchMethodError(f, args);
      }
    }
    return f.apply(void 0, args);
  }
  dart.dinvokef = dinvokef;

  function dextend(sub, _super) {
    sub.prototype = Object.create(_super.prototype);
    sub.prototype.constructor = sub;
  }
  dart.dextend = dextend;

  function cast(obj, type) {
    if (obj == null || instanceOf(obj, type)) return obj;
    throw new dart_core.CastError();
  }
  dart.cast = cast;

  function instanceOf(obj, type) {
    // TODO(vsm): Implement.
    throw new dart_core.UnimplementedError();
  }
  dart.instanceOf = instanceOf;

  function isGroundType(type) {
    // TODO(vsm): Implement.
    throw new dart_core.UnimplementedError();
  }
  dart.isGroundType = isGroundType;

  function arity(f) {
    // TODO(vsm): Implement.
    throw new dart_core.UnimplementedError();
  }
  dart.arity = arity;

  function equals(x, y) {
    if (x === null || y === null) return x === y;
    var eq = x.__equals;
    return eq ? eq.call(x, y) : x === y;
  }
  dart.equals = equals;

  /**
   * Defines a lazy property.
   * After initial get or set, it will replace itself with a value property.
   */
  // TODO(jmesserly): is this the best implementation for JS engines?
  // TODO(jmesserly): reusing descriptor objects has been shown to improve
  // performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
  function defineLazyProperty(to, name, desc) {
    var init = desc.get;
    var writable = !!desc.set;
    function lazySetter(value) {
      defineProperty(to, name, { value: value, writable: writable });
    }
    function lazyGetter() {
      // Clear the init function to detect circular initialization.
      var f = init;
      if (f === null) throw 'circular initialization for field ' + name;
      init = null;

      // Compute and store the value.
      var value = f();
      lazySetter(value);
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (writable) desc.set = lazySetter;
    defineProperty(to, name, desc);
  }

  function defineLazyProperties(to, from) {
    var names = getOwnPropertyNames(from);
    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  dart.defineLazyProperties = defineLazyProperties;

  function mixin(to, from) {
    var names = getOwnPropertyNames(from);
    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
    return to;
  }
  dart.mixin = mixin;

})(dart || (dart = {}));
