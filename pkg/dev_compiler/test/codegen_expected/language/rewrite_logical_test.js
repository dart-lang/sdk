dart_library.library('language/rewrite_logical_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_logical_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_logical_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_logical_test.cneg_and = function(x, y) {
    if (dart.test(x) && dart.test(y) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_and, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_and_not = function(x, y) {
    if (dart.test(x) && (dart.test(y) ? false : true) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_and_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_not_and = function(x, y) {
    if ((dart.test(x) ? false : true) && dart.test(y) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_not_and, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_not_and_not = function(x, y) {
    if ((dart.test(x) ? false : true) && (dart.test(y) ? false : true) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_not_and_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_or = function(x, y) {
    if (dart.test(x) || dart.test(y) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_or, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_or_not = function(x, y) {
    if (dart.test(x) || (dart.test(y) ? false : true) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_or_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_not_or = function(x, y) {
    if ((dart.test(x) ? false : true) || dart.test(y) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_not_or, dynamicAnddynamicTodynamic());
  rewrite_logical_test.cneg_not_or_not = function(x, y) {
    if ((dart.test(x) ? false : true) || (dart.test(y) ? false : true) ? false : true) {
      return 0;
    } else {
      return 1;
    }
  };
  dart.fn(rewrite_logical_test.cneg_not_or_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_tobool = function(x) {
    return dart.test(x) ? true : false;
  };
  dart.fn(rewrite_logical_test.value_tobool, dynamicTodynamic());
  rewrite_logical_test.value_negate = function(x) {
    return dart.test(x) ? false : true;
  };
  dart.fn(rewrite_logical_test.value_negate, dynamicTodynamic());
  rewrite_logical_test.value_and = function(x, y) {
    return dart.test(x) ? dart.test(y) ? true : false : false;
  };
  dart.fn(rewrite_logical_test.value_and, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_or = function(x, y) {
    return dart.test(x) ? true : dart.test(y) ? true : false;
  };
  dart.fn(rewrite_logical_test.value_or, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_and_not = function(x, y) {
    return dart.test(x) ? dart.test(y) ? false : true : false;
  };
  dart.fn(rewrite_logical_test.value_and_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_not_and = function(x, y) {
    return dart.test(x) ? false : dart.test(y) ? true : false;
  };
  dart.fn(rewrite_logical_test.value_not_and, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_not_and_not = function(x, y) {
    return dart.test(x) ? false : dart.test(y) ? false : true;
  };
  dart.fn(rewrite_logical_test.value_not_and_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_or_not = function(x, y) {
    return dart.test(x) ? true : dart.test(y) ? false : true;
  };
  dart.fn(rewrite_logical_test.value_or_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_not_or = function(x, y) {
    return dart.test(x) ? dart.test(y) ? true : false : true;
  };
  dart.fn(rewrite_logical_test.value_not_or, dynamicAnddynamicTodynamic());
  rewrite_logical_test.value_not_or_not = function(x, y) {
    return dart.test(x) ? dart.test(y) ? false : true : true;
  };
  dart.fn(rewrite_logical_test.value_not_or_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_negate = function(x) {
    if (dart.test(x) ? false : true) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_negate, dynamicTodynamic());
  rewrite_logical_test.if_and = function(x, y) {
    if (dart.test(x) ? dart.test(y) ? true : false : false) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_and, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_or = function(x, y) {
    if (dart.test(dart.test(x) ? true : y)) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_or, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_and_not = function(x, y) {
    if (dart.test(x) ? dart.test(y) ? false : true : false) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_and_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_not_and = function(x, y) {
    if (dart.test(dart.test(x) ? false : y)) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_not_and, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_not_and_not = function(x, y) {
    if (dart.test(x) ? false : dart.test(y) ? false : true) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_not_and_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_or_not = function(x, y) {
    if (dart.test(x) ? true : dart.test(y) ? false : true) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_or_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_not_or = function(x, y) {
    if (dart.test(dart.test(x) ? y : true)) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_not_or, dynamicAnddynamicTodynamic());
  rewrite_logical_test.if_not_or_not = function(x, y) {
    if (dart.test(x) ? dart.test(y) ? false : true : true) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(rewrite_logical_test.if_not_or_not, dynamicAnddynamicTodynamic());
  rewrite_logical_test.main = function() {
    expect$.Expect.equals(1, rewrite_logical_test.cneg_and(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_and(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_and(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_and(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_and_not(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_and_not(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_and_not(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_and_not(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_and(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_and(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_and(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_and(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_and_not(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_and_not(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_and_not(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_and_not(false, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_or(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_or(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_or(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_or(false, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_or_not(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_or_not(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_or_not(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_or_not(false, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_or(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_or(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_or(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_or(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.cneg_not_or_not(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_or_not(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_or_not(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.cneg_not_or_not(false, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_tobool(true));
    expect$.Expect.equals(false, rewrite_logical_test.value_tobool(false));
    expect$.Expect.equals(false, rewrite_logical_test.value_negate(true));
    expect$.Expect.equals(true, rewrite_logical_test.value_negate(false));
    expect$.Expect.equals(true, rewrite_logical_test.value_and(true, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_and(true, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_and(false, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_and(false, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_and_not(true, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_and_not(true, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_and_not(false, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_and_not(false, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_and(true, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_and(true, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_and(false, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_and(false, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_and_not(true, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_and_not(true, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_and_not(false, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_and_not(false, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_or(true, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_or(true, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_or(false, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_or(false, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_or_not(true, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_or_not(true, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_or_not(false, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_or_not(false, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_or(true, true));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_or(true, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_or(false, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_or(false, false));
    expect$.Expect.equals(false, rewrite_logical_test.value_not_or_not(true, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_or_not(true, false));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_or_not(false, true));
    expect$.Expect.equals(true, rewrite_logical_test.value_not_or_not(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_negate(true));
    expect$.Expect.equals(1, rewrite_logical_test.if_negate(false));
    expect$.Expect.equals(1, rewrite_logical_test.if_and(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_and(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_and(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_and(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_and_not(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_and_not(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_and_not(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_and_not(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_and(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_and(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_and(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_and(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_and_not(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_and_not(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_and_not(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_and_not(false, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_or(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_or(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_or(false, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_or(false, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_or_not(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_or_not(true, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_or_not(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_or_not(false, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_or(true, true));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_or(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_or(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_or(false, false));
    expect$.Expect.equals(0, rewrite_logical_test.if_not_or_not(true, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_or_not(true, false));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_or_not(false, true));
    expect$.Expect.equals(1, rewrite_logical_test.if_not_or_not(false, false));
  };
  dart.fn(rewrite_logical_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_logical_test = rewrite_logical_test;
});
