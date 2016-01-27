dart_library.library('fieldtest', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class A extends core.Object {
    A() {
      this.x = 42;
    }
  }
  const B$ = dart.generic(function(T) {
    class B extends core.Object {
      B() {
        this.x = null;
        this.y = null;
        this.z = null;
      }
    }
    return B;
  });
  let B = B$();
  function foo(a) {
    core.print(a.x);
    return a.x;
  }
  dart.fn(foo, core.int, [A]);
  function bar(a) {
    core.print(dart.dload(a, 'x'));
    return dart.as(dart.dload(a, 'x'), core.int);
  }
  dart.fn(bar, core.int, [dart.dynamic]);
  function baz(a) {
    return a.x;
  }
  dart.fn(baz, dart.dynamic, [A]);
  function compute() {
    return 123;
  }
  dart.fn(compute, core.int, []);
  dart.defineLazyProperties(exports, {
    get y() {
      return dart.notNull(compute()) + 444;
    },
    set y(_) {}
  });
  dart.copyProperties(exports, {
    get q() {
      return 'life, ' + 'the universe ' + 'and everything';
    },
    get z() {
      return 42;
    },
    set z(value) {
      exports.y = dart.as(value, core.int);
    }
  });
  class BaseWithGetter extends core.Object {
    get foo() {
      return 1;
    }
  }
  class Derived extends BaseWithGetter {
    Derived() {
      this.foo = 2;
      this.bar = 3;
    }
  }
  dart.virtualField(Derived, 'foo');
  const Generic$ = dart.generic(function(T) {
    class Generic extends core.Object {
      foo(t) {
        dart.as(t, T);
        return core.print(dart.notNull(Generic$().bar) + dart.notNull(dart.as(t, core.String)));
      }
    }
    dart.setSignature(Generic, {
      methods: () => ({foo: [dart.dynamic, [T]]})
    });
    Generic.bar = 'hello';
    return Generic;
  });
  let Generic = Generic$();
  class StaticFieldOrder1 extends core.Object {}
  StaticFieldOrder1.d = 4;
  dart.defineLazyProperties(StaticFieldOrder1, {
    get a() {
      return dart.notNull(StaticFieldOrder1.b) + 1;
    },
    get c() {
      return dart.notNull(StaticFieldOrder1.d) + 2;
    },
    get b() {
      return dart.notNull(StaticFieldOrder1.c) + 3;
    }
  });
  class StaticFieldOrder2 extends core.Object {}
  StaticFieldOrder2.d = 4;
  dart.defineLazyProperties(StaticFieldOrder2, {
    get a() {
      return dart.notNull(StaticFieldOrder2.b) + 1;
    },
    get c() {
      return dart.notNull(StaticFieldOrder2.d) + 2;
    },
    get b() {
      return dart.notNull(StaticFieldOrder2.c) + 3;
    }
  });
  class MyEnum extends core.Object {
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
  MyEnum.Val1 = dart.const(new MyEnum(0));
  MyEnum.Val2 = dart.const(new MyEnum(1));
  MyEnum.Val3 = dart.const(new MyEnum(2));
  MyEnum.Val4 = dart.const(new MyEnum(3));
  MyEnum.values = dart.const(dart.list([MyEnum.Val1, MyEnum.Val2, MyEnum.Val3, MyEnum.Val4], MyEnum));
  function main() {
    let a = new A();
    foo(a);
    bar(a);
    core.print(baz(a));
    core.print(new (Generic$(core.String))().foo(' world'));
    core.print(MyEnum.values);
  }
  dart.fn(main, dart.void, []);
  // Exports:
  exports.A = A;
  exports.B$ = B$;
  exports.B = B;
  exports.foo = foo;
  exports.bar = bar;
  exports.baz = baz;
  exports.compute = compute;
  exports.BaseWithGetter = BaseWithGetter;
  exports.Derived = Derived;
  exports.Generic$ = Generic$;
  exports.Generic = Generic;
  exports.StaticFieldOrder1 = StaticFieldOrder1;
  exports.StaticFieldOrder2 = StaticFieldOrder2;
  exports.MyEnum = MyEnum;
  exports.main = main;
});
