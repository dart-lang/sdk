dart_library.library('language/named_parameters_with_object_property_names_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_with_object_property_names_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_with_object_property_names_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {constructor: dart.dynamic})))();
  let __Todynamic$ = () => (__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {hasOwnProperty: dart.dynamic})))();
  let __Todynamic$0 = () => (__Todynamic$0 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {isPrototypeOf: dart.dynamic})))();
  let __Todynamic$1 = () => (__Todynamic$1 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {propertyIsEnumerable: dart.dynamic})))();
  let __Todynamic$2 = () => (__Todynamic$2 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {toSource: dart.dynamic})))();
  let __Todynamic$3 = () => (__Todynamic$3 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {toLocaleString: dart.dynamic})))();
  let __Todynamic$4 = () => (__Todynamic$4 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {toString: dart.dynamic})))();
  let __Todynamic$5 = () => (__Todynamic$5 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {unwatch: dart.dynamic})))();
  let __Todynamic$6 = () => (__Todynamic$6 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {valueOf: dart.dynamic})))();
  let __Todynamic$7 = () => (__Todynamic$7 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {watch: dart.dynamic})))();
  named_parameters_with_object_property_names_test.main = function() {
    named_parameters_with_object_property_names_test.test_constructor();
    named_parameters_with_object_property_names_test.test_hasOwnProperty();
    named_parameters_with_object_property_names_test.test_isPrototypeOf();
    named_parameters_with_object_property_names_test.test_propertyIsEnumerable();
    named_parameters_with_object_property_names_test.test_toSource();
    named_parameters_with_object_property_names_test.test_toLocaleString();
    named_parameters_with_object_property_names_test.test_toString();
    named_parameters_with_object_property_names_test.test_unwatch();
    named_parameters_with_object_property_names_test.test_valueOf();
    named_parameters_with_object_property_names_test.test_watch();
  };
  dart.fn(named_parameters_with_object_property_names_test.main, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_constructor = class TestClass_constructor extends core.Object {
    method(opts) {
      let constructor = opts && 'constructor' in opts ? opts.constructor : null;
      return constructor;
    }
    static staticMethod(opts) {
      let constructor = opts && 'constructor' in opts ? opts.constructor : null;
      return constructor;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_constructor, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {constructor: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {constructor: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_constructor = function(opts) {
    let constructor = opts && 'constructor' in opts ? opts.constructor : null;
    return constructor;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_constructor, __Todynamic());
  named_parameters_with_object_property_names_test.test_constructor = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_constructor();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({constructor: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_constructor.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_constructor.staticMethod({constructor: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_constructor());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_constructor({constructor: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_constructor, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_hasOwnProperty = class TestClass_hasOwnProperty extends core.Object {
    method(opts) {
      let hasOwnProperty = opts && 'hasOwnProperty' in opts ? opts.hasOwnProperty : null;
      return hasOwnProperty;
    }
    static staticMethod(opts) {
      let hasOwnProperty = opts && 'hasOwnProperty' in opts ? opts.hasOwnProperty : null;
      return hasOwnProperty;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_hasOwnProperty, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {hasOwnProperty: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {hasOwnProperty: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_hasOwnProperty = function(opts) {
    let hasOwnProperty = opts && 'hasOwnProperty' in opts ? opts.hasOwnProperty : null;
    return hasOwnProperty;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_hasOwnProperty, __Todynamic$());
  named_parameters_with_object_property_names_test.test_hasOwnProperty = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_hasOwnProperty();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({hasOwnProperty: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_hasOwnProperty.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_hasOwnProperty.staticMethod({hasOwnProperty: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_hasOwnProperty());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_hasOwnProperty({hasOwnProperty: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_hasOwnProperty, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_isPrototypeOf = class TestClass_isPrototypeOf extends core.Object {
    method(opts) {
      let isPrototypeOf = opts && 'isPrototypeOf' in opts ? opts.isPrototypeOf : null;
      return isPrototypeOf;
    }
    static staticMethod(opts) {
      let isPrototypeOf = opts && 'isPrototypeOf' in opts ? opts.isPrototypeOf : null;
      return isPrototypeOf;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_isPrototypeOf, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {isPrototypeOf: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {isPrototypeOf: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_isPrototypeOf = function(opts) {
    let isPrototypeOf = opts && 'isPrototypeOf' in opts ? opts.isPrototypeOf : null;
    return isPrototypeOf;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_isPrototypeOf, __Todynamic$0());
  named_parameters_with_object_property_names_test.test_isPrototypeOf = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_isPrototypeOf();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({isPrototypeOf: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_isPrototypeOf.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_isPrototypeOf.staticMethod({isPrototypeOf: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_isPrototypeOf());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_isPrototypeOf({isPrototypeOf: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_isPrototypeOf, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_propertyIsEnumerable = class TestClass_propertyIsEnumerable extends core.Object {
    method(opts) {
      let propertyIsEnumerable = opts && 'propertyIsEnumerable' in opts ? opts.propertyIsEnumerable : null;
      return propertyIsEnumerable;
    }
    static staticMethod(opts) {
      let propertyIsEnumerable = opts && 'propertyIsEnumerable' in opts ? opts.propertyIsEnumerable : null;
      return propertyIsEnumerable;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_propertyIsEnumerable, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {propertyIsEnumerable: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {propertyIsEnumerable: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_propertyIsEnumerable = function(opts) {
    let propertyIsEnumerable = opts && 'propertyIsEnumerable' in opts ? opts.propertyIsEnumerable : null;
    return propertyIsEnumerable;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_propertyIsEnumerable, __Todynamic$1());
  named_parameters_with_object_property_names_test.test_propertyIsEnumerable = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_propertyIsEnumerable();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({propertyIsEnumerable: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_propertyIsEnumerable.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_propertyIsEnumerable.staticMethod({propertyIsEnumerable: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_propertyIsEnumerable());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_propertyIsEnumerable({propertyIsEnumerable: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_propertyIsEnumerable, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_toSource = class TestClass_toSource extends core.Object {
    method(opts) {
      let toSource = opts && 'toSource' in opts ? opts.toSource : null;
      return toSource;
    }
    static staticMethod(opts) {
      let toSource = opts && 'toSource' in opts ? opts.toSource : null;
      return toSource;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_toSource, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {toSource: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {toSource: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_toSource = function(opts) {
    let toSource = opts && 'toSource' in opts ? opts.toSource : null;
    return toSource;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_toSource, __Todynamic$2());
  named_parameters_with_object_property_names_test.test_toSource = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_toSource();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({toSource: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_toSource.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_toSource.staticMethod({toSource: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_toSource());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_toSource({toSource: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_toSource, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_toLocaleString = class TestClass_toLocaleString extends core.Object {
    method(opts) {
      let toLocaleString = opts && 'toLocaleString' in opts ? opts.toLocaleString : null;
      return toLocaleString;
    }
    static staticMethod(opts) {
      let toLocaleString = opts && 'toLocaleString' in opts ? opts.toLocaleString : null;
      return toLocaleString;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_toLocaleString, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {toLocaleString: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {toLocaleString: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_toLocaleString = function(opts) {
    let toLocaleString = opts && 'toLocaleString' in opts ? opts.toLocaleString : null;
    return toLocaleString;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_toLocaleString, __Todynamic$3());
  named_parameters_with_object_property_names_test.test_toLocaleString = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_toLocaleString();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({toLocaleString: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_toLocaleString.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_toLocaleString.staticMethod({toLocaleString: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_toLocaleString());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_toLocaleString({toLocaleString: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_toLocaleString, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_toString = class TestClass_toString extends core.Object {
    method(opts) {
      let toString = opts && 'toString' in opts ? opts.toString : null;
      return toString;
    }
    static staticMethod(opts) {
      let toString = opts && 'toString' in opts ? opts.toString : null;
      return toString;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_toString, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {toString: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {toString: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_toString = function(opts) {
    let toString = opts && 'toString' in opts ? opts.toString : null;
    return toString;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_toString, __Todynamic$4());
  named_parameters_with_object_property_names_test.test_toString = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_toString();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({toString: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_toString.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_toString.staticMethod({toString: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_toString());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_toString({toString: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_toString, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_unwatch = class TestClass_unwatch extends core.Object {
    method(opts) {
      let unwatch = opts && 'unwatch' in opts ? opts.unwatch : null;
      return unwatch;
    }
    static staticMethod(opts) {
      let unwatch = opts && 'unwatch' in opts ? opts.unwatch : null;
      return unwatch;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_unwatch, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {unwatch: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {unwatch: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_unwatch = function(opts) {
    let unwatch = opts && 'unwatch' in opts ? opts.unwatch : null;
    return unwatch;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_unwatch, __Todynamic$5());
  named_parameters_with_object_property_names_test.test_unwatch = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_unwatch();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({unwatch: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_unwatch.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_unwatch.staticMethod({unwatch: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_unwatch());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_unwatch({unwatch: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_unwatch, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_valueOf = class TestClass_valueOf extends core.Object {
    method(opts) {
      let valueOf = opts && 'valueOf' in opts ? opts.valueOf : null;
      return valueOf;
    }
    static staticMethod(opts) {
      let valueOf = opts && 'valueOf' in opts ? opts.valueOf : null;
      return valueOf;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_valueOf, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {valueOf: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {valueOf: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_valueOf = function(opts) {
    let valueOf = opts && 'valueOf' in opts ? opts.valueOf : null;
    return valueOf;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_valueOf, __Todynamic$6());
  named_parameters_with_object_property_names_test.test_valueOf = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_valueOf();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({valueOf: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_valueOf.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_valueOf.staticMethod({valueOf: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_valueOf());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_valueOf({valueOf: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_valueOf, VoidTodynamic());
  named_parameters_with_object_property_names_test.TestClass_watch = class TestClass_watch extends core.Object {
    method(opts) {
      let watch = opts && 'watch' in opts ? opts.watch : null;
      return watch;
    }
    static staticMethod(opts) {
      let watch = opts && 'watch' in opts ? opts.watch : null;
      return watch;
    }
  };
  dart.setSignature(named_parameters_with_object_property_names_test.TestClass_watch, {
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [], {watch: dart.dynamic})}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [], {watch: dart.dynamic})}),
    names: ['staticMethod']
  });
  named_parameters_with_object_property_names_test.globalMethod_watch = function(opts) {
    let watch = opts && 'watch' in opts ? opts.watch : null;
    return watch;
  };
  dart.fn(named_parameters_with_object_property_names_test.globalMethod_watch, __Todynamic$7());
  named_parameters_with_object_property_names_test.test_watch = function() {
    let obj = new named_parameters_with_object_property_names_test.TestClass_watch();
    expect$.Expect.equals(null, obj.method());
    expect$.Expect.equals(0, obj.method({watch: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.TestClass_watch.staticMethod());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.TestClass_watch.staticMethod({watch: 0}));
    expect$.Expect.equals(null, named_parameters_with_object_property_names_test.globalMethod_watch());
    expect$.Expect.equals(0, named_parameters_with_object_property_names_test.globalMethod_watch({watch: 0}));
  };
  dart.fn(named_parameters_with_object_property_names_test.test_watch, VoidTodynamic());
  // Exports:
  exports.named_parameters_with_object_property_names_test = named_parameters_with_object_property_names_test;
});
