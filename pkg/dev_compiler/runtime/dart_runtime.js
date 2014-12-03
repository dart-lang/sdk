var dart_runtime;
(function (dart_runtime) {
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
      throw new dart.core.NoSuchMethodError(obj, field);
    }
    return obj[field];
  }
  dart_runtime.dload = dload;

  function dinvokef(f, args) {
    var formals = formalParameterList(f);
    // TODO(vsm): Type check args!  We need to encode sufficient type info on f.
    if (formals.length < args.length) {
      throw new dart.core.NoSuchMethodError(f, args);
    } else if (formals.length > args.length) {
      for (var i = args.length; i < formals.length; ++i) {
        if (formals[i].indexOf("opt$") != 0)
          throw new dart.core.NoSuchMethodError(f, args);
      }
    }
    return f.apply(void 0, args);
  }
  dart_runtime.dinvokef = dinvokef;

  function dextend(sub, _super) {
    sub.prototype = Object.create(_super.prototype);
    sub.prototype.constructor = sub;
  }
  dart_runtime.dextend = dextend;

})(dart_runtime || (dart_runtime = {}));
