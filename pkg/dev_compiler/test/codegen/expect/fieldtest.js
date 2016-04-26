dart_library.library('fieldtest', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const fieldtest = Object.create(null);
  fieldtest.A = class A extends core.Object {
    A() {
      this.x = 42;
    }
  };
  fieldtest.B$ = dart.generic(T => {
    class B extends core.Object {
      B() {
        this.x = null;
        this.y = null;
        this.z = null;
      }
    }
    return B;
  });
  fieldtest.B = fieldtest.B$();
  fieldtest.foo = function(a) {
    core.print(a.x);
    return a.x;
  };
  dart.fn(fieldtest.foo, core.int, [fieldtest.A]);
  fieldtest.bar = function(a) {
    core.print(dart.dload(a, 'x'));
    return dart.as(dart.dload(a, 'x'), core.int);
  };
  dart.fn(fieldtest.bar, core.int, [dart.dynamic]);
  fieldtest.baz = function(a) {
    return a.x;
  };
  dart.fn(fieldtest.baz, dart.dynamic, [fieldtest.A]);
  fieldtest.compute = function() {
    return 123;
  };
  dart.fn(fieldtest.compute, core.int, []);
  dart.defineLazy(fieldtest, {
    get y() {
      return dart.notNull(fieldtest.compute()) + 444;
    },
    set y(_) {}
  });
  dart.copyProperties(fieldtest, {
    get q() {
      return 'life, ' + 'the universe ' + 'and everything';
    }
  });
  dart.copyProperties(fieldtest, {
    get z() {
      return 42;
    },
    set z(value) {
      fieldtest.y = dart.as(value, core.int);
    }
  });
  fieldtest.BaseWithGetter = class BaseWithGetter extends core.Object {
    get foo() {
      return 1;
    }
  };
  fieldtest.Derived = class Derived extends fieldtest.BaseWithGetter {
    Derived() {
      this[foo] = 2;
      this.bar = 3;
    }
    get foo() {
      return this[foo];
    }
    set foo(value) {
      this[foo] = value;
    }
  };
  const foo = Symbol(fieldtest.Derived.name + "." + 'foo'.toString());
  fieldtest.Generic$ = dart.generic(T => {
    class Generic extends core.Object {
      foo(t) {
        dart.as(t, T);
        return core.print(dart.notNull(fieldtest.Generic.bar) + dart.notNull(dart.as(t, core.String)));
      }
    }
    dart.setSignature(Generic, {
      methods: () => ({foo: [dart.dynamic, [T]]})
    });
    return Generic;
  });
  fieldtest.Generic = fieldtest.Generic$();
  fieldtest.Generic.bar = 'hello';
  fieldtest.StaticFieldOrder1 = class StaticFieldOrder1 extends core.Object {};
  fieldtest.StaticFieldOrder1.d = 4;
  dart.defineLazy(fieldtest.StaticFieldOrder1, {
    get a() {
      return dart.notNull(fieldtest.StaticFieldOrder1.b) + 1;
    },
    get c() {
      return dart.notNull(fieldtest.StaticFieldOrder1.d) + 2;
    },
    get b() {
      return dart.notNull(fieldtest.StaticFieldOrder1.c) + 3;
    }
  });
  fieldtest.StaticFieldOrder2 = class StaticFieldOrder2 extends core.Object {};
  fieldtest.StaticFieldOrder2.d = 4;
  dart.defineLazy(fieldtest.StaticFieldOrder2, {
    get a() {
      return dart.notNull(fieldtest.StaticFieldOrder2.b) + 1;
    },
    get c() {
      return dart.notNull(fieldtest.StaticFieldOrder2.d) + 2;
    },
    get b() {
      return dart.notNull(fieldtest.StaticFieldOrder2.c) + 3;
    }
  });
  fieldtest.MyEnum = class MyEnum extends core.Object {
    MyEnum(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "MyEnum.Val1",
        1: "MyEnum.Val2",
        2: "MyEnum.Val3",
        3: "MyEnum.Val4"
      }[this.index];
    }
  };
  fieldtest.MyEnum.Val1 = dart.const(new fieldtest.MyEnum(0));
  fieldtest.MyEnum.Val2 = dart.const(new fieldtest.MyEnum(1));
  fieldtest.MyEnum.Val3 = dart.const(new fieldtest.MyEnum(2));
  fieldtest.MyEnum.Val4 = dart.const(new fieldtest.MyEnum(3));
  fieldtest.MyEnum.values = dart.const(dart.list([fieldtest.MyEnum.Val1, fieldtest.MyEnum.Val2, fieldtest.MyEnum.Val3, fieldtest.MyEnum.Val4], fieldtest.MyEnum));
  fieldtest.main = function() {
    let a = new fieldtest.A();
    fieldtest.foo(a);
    fieldtest.bar(a);
    core.print(fieldtest.baz(a));
    core.print(new (fieldtest.Generic$(core.String))().foo(' world'));
    core.print(fieldtest.MyEnum.values);
  };
  dart.fn(fieldtest.main, dart.void, []);
  // Exports:
  exports.fieldtest = fieldtest;
});
