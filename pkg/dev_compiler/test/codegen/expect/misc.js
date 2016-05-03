dart_library.library('misc', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const misc = Object.create(null);
  misc._Uninitialized = class _Uninitialized extends core.Object {
    _Uninitialized() {
    }
  };
  dart.setSignature(misc._Uninitialized, {
    constructors: () => ({_Uninitialized: [misc._Uninitialized, []]})
  });
  misc.UNINITIALIZED = dart.const(new misc._Uninitialized());
  misc.Generic$ = dart.generic(T => {
    class Generic extends core.Object {
      get type() {
        return dart.wrapType(misc.Generic);
      }
      m() {
        return core.print(dart.wrapType(T));
      }
    }
    dart.setSignature(Generic, {
      methods: () => ({m: [dart.dynamic, []]})
    });
    return Generic;
  });
  misc.Generic = misc.Generic$();
  misc.Base = class Base extends core.Object {
    Base() {
      this.x = 1;
      this.y = 2;
    }
    ['=='](obj) {
      return dart.is(obj, misc.Base) && obj.x == this.x && obj.y == this.y;
    }
  };
  misc.Derived = class Derived extends core.Object {
    Derived() {
      this.z = 3;
    }
    ['=='](obj) {
      return dart.is(obj, misc.Derived) && obj.z == this.z && super['=='](obj);
    }
  };
  misc._isWhitespace = function(ch) {
    return ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
  };
  dart.fn(misc._isWhitespace, core.bool, [core.String]);
  misc.expr = 'foo';
  misc._escapeMap = dart.const(dart.map({'\n': '\\n', '\r': '\\r', '\f': '\\f', '\b': '\\b', '\t': '\\t', '\v': '\\v', '': '\\x7F', [`\${${misc.expr}}`]: ''}));
  misc.main = function() {
    core.print(dart.toString(1));
    core.print(dart.toString(1.0));
    core.print(dart.toString(1.1));
    let x = 42;
    core.print(dart.equals(x, dart.wrapType(dart.dynamic)));
    core.print(dart.equals(x, dart.wrapType(misc.Generic)));
    core.print(new (misc.Generic$(core.int))().type);
    core.print(dart.equals(new misc.Derived(), new misc.Derived()));
    new (misc.Generic$(core.int))().m();
  };
  dart.fn(misc.main);
  // Exports:
  exports.misc = misc;
});
