// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Generates JS helpers for dart:core. This used to be in a file "core.js".
 * Having them in Dart code means we can easily control which are generated.
 */
// TODO(jmesserly): one idea to make this cleaner: put these as private "native"
// methods somewhere in a library that we import. This would be rather elegant
// because they'd get the right name collision behavior, conversions,
// include-if-used, etc for free. Not sure if it's worth doing that.
class CoreJs {
  // These values track if the helper is actually used. If it is we generate it.
  bool useThrow = false;
  bool useNotNullBool = false;
  bool useIndex = false;
  bool useSetIndex = false;

  bool useWrap0 = false;
  bool useWrap1 = false;
  bool useWrap2 = false;
  bool useIsolates = false;

  // These helpers had to switch to a new pattern, because they can be generated
  // after everything else.
  bool _generatedTypeNameOf = false;
  bool _generatedDynamicProto = false;
  bool _generatedDynamicSetMetadata = false;
  bool _generatedInherits = false;
  bool _generatedDefProp = false;
  bool _generatedBind = false;


  Map<String, String> _usedOperators;

  CodeWriter writer;

  CoreJs(): _usedOperators = {}, writer = new CodeWriter();

  void markCorelibTypeUsed(String typeName) {
    world.gen.markTypeUsed(world.corelib.types[typeName]);
  }

  _emit(String code) => writer.writeln(code);

  /**
   * Generates the special operator method, e.g. $add.
   * We want to do $add(x, y) instead of x.$add(y) so it doesn't box.
   * Same idea for the other methods.
   */
  void useOperator(String name) {
    if (_usedOperators[name] != null) return;

    if (name != ':ne' && name != ':eq') {
      // TODO(jimhug): Only do this once!
      markCorelibTypeUsed('NoSuchMethodException');
    }
    if (name != ':bit_not' && name != ':negate') {
        // TODO(jimhug): Only do this once!
      markCorelibTypeUsed('IllegalArgumentException');
    }

    var code;
    switch (name) {
      case ':ne':
        code = _NE_FUNCTION;
        break;

      case ':eq':
        ensureDefProp();
        code = _EQ_FUNCTION;
        break;

      case ':bit_not':
        code = _BIT_NOT_FUNCTION;
        break;

      case ':negate':
        code = _NEGATE_FUNCTION;
        break;

      case ':add':
        code = _ADD_FUNCTION;
        break;

      case ':truncdiv':
        useThrow = true;
        // TODO(jimhug): Only do this once!
        markCorelibTypeUsed('IntegerDivisionByZeroException');
        code = _TRUNCDIV_FUNCTION;
        break;

      case ':mod':
        code = _MOD_FUNCTION;
        break;

      default:
        // All of the other helpers are generated the same way
        var op = TokenKind.rawOperatorFromMethod(name);
        var jsname = world.toJsIdentifier(name);
        code = _otherOperator(jsname, op);
        break;
    }

    _usedOperators[name] = code;
  }

  // NOTE: some helpers can't be generated when we generate corelib,
  // because we don't discover that we need them until later.
  // Generate on-demand instead
  void ensureDynamicProto() {
    if (_generatedDynamicProto) return;
    _generatedDynamicProto = true;
    ensureTypeNameOf();
    ensureDefProp();
    _emit(_DYNAMIC_FUNCTION);
  }

  void ensureDynamicSetMetadata() {
    if (_generatedDynamicSetMetadata) return;
    _generatedDynamicSetMetadata = true;
    _emit(_DYNAMIC_SET_METADATA_FUNCTION);
  }

  void ensureTypeNameOf() {
    if (_generatedTypeNameOf) return;
    _generatedTypeNameOf = true;
    ensureDefProp();
    _emit(_TYPE_NAME_OF_FUNCTION);
  }

  /** Generates the $inherits function when it's first used. */
  void ensureInheritsHelper() {
    if (_generatedInherits) return;
    _generatedInherits = true;
    _emit(_INHERITS_FUNCTION);
  }

  /** Generates the $defProp function when it's first used. */
  void ensureDefProp() {
    if (_generatedDefProp) return;
    _generatedDefProp = true;
    _emit(_DEF_PROP_FUNCTION);
  }

  void ensureBind() {
    if (_generatedBind) return;
    _generatedBind = true;
    _emit(_BIND_CODE);
  }

  void generate(CodeWriter w) {
    // Write any stuff we had queued up, then replace our writer with a
    // subwriter into the one in WorldGenerator so anything we discover that we
    // need later on will be generated on-demand.
    w.write(writer.text);
    writer = w.subWriter();

    if (useNotNullBool) {
      useThrow = true;
      _emit(_NOTNULL_BOOL_FUNCTION);
    }

    if (useThrow) {
      _emit(_THROW_FUNCTION);
    }

    if (useIndex) {
      markCorelibTypeUsed('NoSuchMethodException');
      ensureDefProp();
      _emit(options.disableBoundsChecks ?
        _INDEX_OPERATORS : _CHECKED_INDEX_OPERATORS);
    }

    if (useSetIndex) {
      markCorelibTypeUsed('NoSuchMethodException');
      ensureDefProp();
      _emit(options.disableBoundsChecks ?
        _SETINDEX_OPERATORS : _CHECKED_SETINDEX_OPERATORS);
    }

    if (!useIsolates) {
      if (useWrap0) _emit(_EMPTY_WRAP_CALL0_FUNCTION);
      if (useWrap1) _emit(_EMPTY_WRAP_CALL1_FUNCTION);
      if (useWrap2) _emit(_EMPTY_WRAP_CALL2_FUNCTION);
    }

    // Write operator helpers
    for (var opImpl in orderValuesByKeys(_usedOperators)) {
      _emit(opImpl);
    }

    if (world.dom != null || world.html != null) {
      ensureTypeNameOf();
      ensureDefProp();
      // TODO(jmesserly): we need to find a way to avoid conflicts with other
      // generated "typeName" fields. Ideally we wouldn't be patching 'Object'
      // here.
      _emit('\$defProp(Object.prototype, "get\$typeName", '
            'Object.prototype.\$typeNameOf);');
    }
  }
}


/** Snippet for `$ne`. */
final String _NE_FUNCTION = @"""
function $ne$(x, y) {
  if (x == null) return y != null;
  return (typeof(x) != 'object') ? x !== y : !x.$eq(y);
}
""";

/** Snippet for `$eq`. */
final String _EQ_FUNCTION = @"""
function $eq$(x, y) {
  if (x == null) return y == null;
  return (typeof(x) != 'object') ? x === y : x.$eq(y);
}
// TODO(jimhug): Should this or should it not match equals?
$defProp(Object.prototype, '$eq', function(other) {
  return this === other;
});
""";

/** Snippet for `$bit_not`. */
final String _BIT_NOT_FUNCTION = @"""
function $bit_not$(x) {
  if (typeof(x) == 'number') return ~x;
  if (typeof(x) == 'object') return  x.$bit_not();
  $throw(new NoSuchMethodException(x, "operator ~", []));
}
""";

/** Snippet for `$negate`. */
final String _NEGATE_FUNCTION = @"""
function $negate$(x) {
  if (typeof(x) == 'number') return -x;
  if (typeof(x) == 'object') return x.$negate();
  $throw(new NoSuchMethodException(x, "operator negate", []));
}
""";

/** Snippet for `$add`. This relies on JS's string "+" to match Dart's. */
final String _ADD_FUNCTION = @"""
function $add$complex$(x, y) {
  if (typeof(x) == 'number') {
    $throw(new IllegalArgumentException(y));
  } else if (typeof(x) == 'string') {
    var str = (y == null) ? 'null' : y.toString();
    if (typeof(str) != 'string') {
      throw new Error("calling toString() on right hand operand of operator " +
      "+ did not return a String");
    }
    return x + str;
  } else if (typeof(x) == 'object') {
    return x.$add(y);
  } else {
    $throw(new NoSuchMethodException(x, "operator +", [y]));
  }
}

function $add$(x, y) {
  if (typeof(x) == 'number' && typeof(y) == 'number') return x + y;
  return $add$complex$(x, y);
}
""";

/** Snippet for `$truncdiv`. This uses `$throw`. */
final String _TRUNCDIV_FUNCTION = @"""
function $truncdiv$(x, y) {
  if (typeof(x) == 'number') {
    if (typeof(y) == 'number') {
      if (y == 0) $throw(new IntegerDivisionByZeroException());
      var tmp = x / y;
      return (tmp < 0) ? Math.ceil(tmp) : Math.floor(tmp);
    } else {
      $throw(new IllegalArgumentException(y));
    }
  } else if (typeof(x) == 'object') {
    return x.$truncdiv(y);
  } else {
    $throw(new NoSuchMethodException(x, "operator ~/", [y]));
  }
}
""";

/** Snippet for `$mod`. */
final String _MOD_FUNCTION = @"""
function $mod$(x, y) {
  if (typeof(x) == 'number') {
    if (typeof(y) == 'number') {
      var result = x % y;
      if (result == 0) {
        return 0;  // Make sure we don't return -0.0.
      } else if (result < 0) {
        if (y < 0) {
          return result - y;
        } else {
          return result + y;
        }
      }
      return result;
    } else {
      $throw(new IllegalArgumentException(y));
    }
  } else if (typeof(x) == 'object') {
    return x.$mod(y);
  } else {
    $throw(new NoSuchMethodException(x, "operator %", [y]));
  }
}
""";

/** Code snippet for all other operators. */
String _otherOperator(String jsname, String op) {
  return """
function $jsname\$complex\$(x, y) {
  if (typeof(x) == 'number') {
    \$throw(new IllegalArgumentException(y));
  } else if (typeof(x) == 'object') {
    return x.$jsname(y);
  } else {
    \$throw(new NoSuchMethodException(x, "operator $op", [y]));
  }
}
function $jsname\$(x, y) {
  if (typeof(x) == 'number' && typeof(y) == 'number') return x $op y;
  return $jsname\$complex\$(x, y);
}
""";
}

/**
 * Snippet for `$dynamic`. Usage:
 *    $dynamic(name).SomeTypeName = ... method ...;
 *    $dynamic(name).Object = ... noSuchMethod ...;
 */
final String _DYNAMIC_FUNCTION = @"""
function $dynamic(name) {
  var f = Object.prototype[name];
  if (f && f.methods) return f.methods;

  var methods = {};
  if (f) methods.Object = f;
  function $dynamicBind() {
    // Find the target method
    var obj = this;
    var tag = obj.$typeNameOf();
    var method = methods[tag];
    if (!method) {
      var table = $dynamicMetadata;
      for (var i = 0; i < table.length; i++) {
        var entry = table[i];
        if (entry.map.hasOwnProperty(tag)) {
          method = methods[entry.tag];
          if (method) break;
        }
      }
    }
    method = method || methods.Object;

    var proto = Object.getPrototypeOf(obj);

    if (method == null) {
      // Trampoline to throw NoSuchMethodException (TODO: call noSuchMethod).
      method = function(){
        // Exact type check to prevent this code shadowing the dispatcher from a
        // subclass.
        if (Object.getPrototypeOf(this) === proto) {
          // TODO(sra): 'name' is the jsname, should be the Dart name.
          $throw(new NoSuchMethodException(
              obj, name, Array.prototype.slice.call(arguments)));
        }
        return Object.prototype[name].apply(this, arguments);
      };
    }

    if (!proto.hasOwnProperty(name)) {
      $defProp(proto, name, method);
    }

    return method.apply(this, Array.prototype.slice.call(arguments));
  };
  $dynamicBind.methods = methods;
  $defProp(Object.prototype, name, $dynamicBind);
  return methods;
}
if (typeof $dynamicMetadata == 'undefined') $dynamicMetadata = [];
""";

/**
 * Snippet for `$dynamicSetMetadata`.
 */
final String _DYNAMIC_SET_METADATA_FUNCTION = @"""
function $dynamicSetMetadata(inputTable) {
  // TODO: Deal with light isolates.
  var table = [];
  for (var i = 0; i < inputTable.length; i++) {
    var tag = inputTable[i][0];
    var tags = inputTable[i][1];
    var map = {};
    var tagNames = tags.split('|');
    for (var j = 0; j < tagNames.length; j++) {
      map[tagNames[j]] = true;
    }
    table.push({tag: tag, tags: tags, map: map});
  }
  $dynamicMetadata = table;
}
""";

/** Snippet for `$typeNameOf`. */
final String _TYPE_NAME_OF_FUNCTION = @"""
$defProp(Object.prototype, '$typeNameOf', (function() {
  function constructorNameWithFallback(obj) {
    var constructor = obj.constructor;
    if (typeof(constructor) == 'function') {
      // The constructor isn't null or undefined at this point. Try
      // to grab hold of its name.
      var name = constructor.name;
      // If the name is a non-empty string, we use that as the type
      // name of this object. On Firefox, we often get 'Object' as
      // the constructor name even for more specialized objects so
      // we have to fall through to the toString() based implementation
      // below in that case.
      if (typeof(name) == 'string' && name && name != 'Object') return name;
    }
    var string = Object.prototype.toString.call(obj);
    return string.substring(8, string.length - 1);
  }

  function chrome$typeNameOf() {
    var name = this.constructor.name;
    if (name == 'Window') return 'DOMWindow';
    if (name == 'CanvasPixelArray') return 'Uint8ClampedArray';
    return name;
  }

  function firefox$typeNameOf() {
    var name = constructorNameWithFallback(this);
    if (name == 'Window') return 'DOMWindow';
    if (name == 'Document') return 'HTMLDocument';
    if (name == 'XMLDocument') return 'Document';
    if (name == 'WorkerMessageEvent') return 'MessageEvent';
    return name;
  }

  function ie$typeNameOf() {
    var name = constructorNameWithFallback(this);
    if (name == 'Window') return 'DOMWindow';
    // IE calls both HTML and XML documents 'Document', so we check for the
    // xmlVersion property, which is the empty string on HTML documents.
    if (name == 'Document' && this.xmlVersion) return 'Document';
    if (name == 'Document') return 'HTMLDocument';
    if (name == 'HTMLTableDataCellElement') return 'HTMLTableCellElement';
    if (name == 'HTMLTableHeaderCellElement') return 'HTMLTableCellElement';
    if (name == 'MSStyleCSSProperties') return 'CSSStyleDeclaration';
    if (name == 'CanvasPixelArray') return 'Uint8ClampedArray';
    if (name == 'HTMLPhraseElement') return 'HTMLElement';
    if (name == 'MouseWheelEvent') return 'WheelEvent';
    return name;
  }

  // If we're not in the browser, we're almost certainly running on v8.
  if (typeof(navigator) != 'object') return chrome$typeNameOf;

  var userAgent = navigator.userAgent;
  if (/Chrome|DumpRenderTree/.test(userAgent)) return chrome$typeNameOf;
  if (/Firefox/.test(userAgent)) return firefox$typeNameOf;
  if (/MSIE/.test(userAgent)) return ie$typeNameOf;
  return function() { return constructorNameWithFallback(this); };
})());
""";

/** Snippet for `$inherits`. */
final String _INHERITS_FUNCTION = @"""
/** Implements extends for Dart classes on JavaScript prototypes. */
function $inherits(child, parent) {
  if (child.prototype.__proto__) {
    child.prototype.__proto__ = parent.prototype;
  } else {
    function tmp() {};
    tmp.prototype = parent.prototype;
    child.prototype = new tmp();
    child.prototype.constructor = child;
  }
}
""";

/** Snippet for `$defProp`. */
final String _DEF_PROP_FUNCTION = @"""
function $defProp(obj, prop, value) {
  Object.defineProperty(obj, prop,
      {value: value, enumerable: false, writable: true, configurable: true});
}
""";

/** Snippet for `$stackTraceOf`. */
final String _STACKTRACEOF_FUNCTION = @"""
function $stackTraceOf(e) {
  // TODO(jmesserly): we shouldn't be relying on the e.stack property.
  // Need to mangle it.
  return  (e && e.stack) ? e.stack : null;
}
""";

/**
 * Snippet for `$notnull_bool`. This pattern chosen because IE9 does really
 * badly with typeof, and it's still decent on other browsers.
 */
final String _NOTNULL_BOOL_FUNCTION = @"""
function $notnull_bool(test) {
  if (test === true || test === false) return test;
  $throw(new TypeError(test, 'bool'));
}
""";

/** Snippet for `$throw`. */
final String _THROW_FUNCTION = @"""
function $throw(e) {
  // If e is not a value, we can use V8's captureStackTrace utility method.
  // TODO(jmesserly): capture the stack trace on other JS engines.
  if (e && (typeof e == 'object') && Error.captureStackTrace) {
    // TODO(jmesserly): this will clobber the e.stack property
    Error.captureStackTrace(e, $throw);
  }
  throw e;
}
""";

/**
 * Snippet for `$index` in Object, Array, and String.  If not overridden,
 * `$index` and `$setindex` fall back to JS [] and []= accessors.
 */
// TODO(jimhug): This fallback could be very confusing in a few cases -
// because of the bizare default [] rules in JS.  We need to revisit this
// to get the right errors - at least in checked mode (once we have that).
// TODO(jmesserly): do perf analysis, figure out if this is worth it and
// what the cost of $index $setindex is on all browsers

// Performance of Object.prototype methods can go down because there are
// so many of them. Instead, first time we hit it, put it on the derived
// prototype. TODO(jmesserly): make this go away by handling index more
// like a normal method.
final String _INDEX_OPERATORS = @"""
$defProp(Object.prototype, '$index', function(i) {
  $throw(new NoSuchMethodException(this, "operator []", [i]));
});
$defProp(Array.prototype, '$index', function(i) {
  return this[i];
});
$defProp(String.prototype, '$index', function(i) {
  return this[i];
});
""";

final String _CHECKED_INDEX_OPERATORS = @"""
$defProp(Object.prototype, '$index', function(i) {
  $throw(new NoSuchMethodException(this, "operator []", [i]));
});
$defProp(Array.prototype, '$index', function(index) {
  var i = index | 0;
  if (i !== index) {
    throw new IllegalArgumentException('index is not int');
  } else if (i < 0 || i >= this.length) {
    throw new IndexOutOfRangeException(index);
  }
  return this[i];
});
$defProp(String.prototype, '$index', function(i) {
  return this[i];
});
""";



/** Snippet for `$setindex` in Object, Array, and String. */
final String _SETINDEX_OPERATORS = @"""
$defProp(Object.prototype, '$setindex', function(i, value) {
  $throw(new NoSuchMethodException(this, "operator []=", [i, value]));
});
$defProp(Array.prototype, '$setindex',
    function(i, value) { return this[i] = value; });""";

final String _CHECKED_SETINDEX_OPERATORS = @"""
$defProp(Object.prototype, '$setindex', function(i, value) {
  $throw(new NoSuchMethodException(this, "operator []=", [i, value]));
});
$defProp(Array.prototype, '$setindex', function(index, value) {
  var i = index | 0;
  if (i !== index) {
    throw new IllegalArgumentException('index is not int');
  } else if (i < 0 || i >= this.length) {
    throw new IndexOutOfRangeException(index);
  }
  return this[i] = value;
});
""";

/** Snippet for `$wrap_call$0`, in case it was not necessary. */
final String _EMPTY_WRAP_CALL0_FUNCTION = @"""
function $wrap_call$0(fn) { return fn; }
""";

/** Snippet for `$wrap_call$1`, in case it was not necessary. */
final String _EMPTY_WRAP_CALL1_FUNCTION = @"""
function $wrap_call$1(fn) { return fn; };
""";

/** Snippet for `$wrap_call$2`, in case it was not necessary. */
final String _EMPTY_WRAP_CALL2_FUNCTION = @"""
function $wrap_call$2(fn) { return fn; };
""";

/** Snippet that initializes Function.prototype.bind. */
final String _BIND_CODE = @"""
Function.prototype.bind = Function.prototype.bind ||
  function(thisObj) {
    var func = this;
    var funcLength = func.$length || func.length;
    var argsLength = arguments.length;
    if (argsLength > 1) {
      var boundArgs = Array.prototype.slice.call(arguments, 1);
      var bound = function() {
        // Prepend the bound arguments to the current arguments.
        var newArgs = Array.prototype.slice.call(arguments);
        Array.prototype.unshift.apply(newArgs, boundArgs);
        return func.apply(thisObj, newArgs);
      };
      bound.$length = Math.max(0, funcLength - (argsLength - 1));
      return bound;
    } else {
      var bound = function() {
        return func.apply(thisObj, arguments);
      };
      bound.$length = funcLength;
      return bound;
    }
  };
""";
