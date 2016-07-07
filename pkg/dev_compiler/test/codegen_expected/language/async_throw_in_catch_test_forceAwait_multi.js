dart_library.library('language/async_throw_in_catch_test_forceAwait_multi', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_throw_in_catch_test_forceAwait_multi(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_throw_in_catch_test_forceAwait_multi = Object.create(null);
  let TracerTodynamic = () => (TracerTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [async_throw_in_catch_test_forceAwait_multi.Tracer])))();
  let dynamicAnddynamic__Todynamic = () => (dynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  async_throw_in_catch_test_forceAwait_multi.Tracer = class Tracer extends core.Object {
    new(expected, name) {
      if (name === void 0) name = null;
      this.expected = expected;
      this.name = name;
      this.counter = 0;
    }
    trace(msg) {
      if (this.name != null) {
      }
      expect$.Expect.equals(this.expected[dartx.get](this.counter), msg);
      this.counter = dart.notNull(this.counter) + 1;
    }
    done() {
      expect$.Expect.equals(this.expected[dartx.length], this.counter, "Received too few traces");
    }
  };
  dart.setSignature(async_throw_in_catch_test_forceAwait_multi.Tracer, {
    constructors: () => ({new: dart.definiteFunctionType(async_throw_in_catch_test_forceAwait_multi.Tracer, [core.String], [core.String])}),
    methods: () => ({
      trace: dart.definiteFunctionType(dart.void, [dart.dynamic]),
      done: dart.definiteFunctionType(dart.void, [])
    })
  });
  async_throw_in_catch_test_forceAwait_multi.foo1 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        tracer.trace("a");
        yield async.Future.value(3);
        tracer.trace("b");
        dart.throw("Error");
      } catch (error) {
        tracer.trace("c");
        expect$.Expect.equals("Error", error);
        dart.throw("Error2");
        tracer.trace("d");
      }
 finally {
        tracer.trace("e");
      }
      tracer.trace("f");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo1, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo2 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        tracer.trace("a");
        yield async.Future.value(3);
        tracer.trace("b");
        dart.throw("Error");
        tracer.trace("c");
      } catch (error) {
        tracer.trace("d");
        expect$.Expect.equals("Error", error);
        yield async.Future.error("Error2");
      }
 finally {
        tracer.trace("e");
      }
      tracer.trace("f");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo2, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo3 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        tracer.trace("a");
        yield async.Future.value(3);
        tracer.trace("b");
        dart.throw("Error");
        tracer.trace("c");
      } catch (error) {
        expect$.Expect.equals("Error", error);
        tracer.trace("d");
        return;
      }
 finally {
        tracer.trace("e");
      }
      tracer.trace("f");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo3, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo4 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          yield async.Future.value(3);
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          tracer.trace("b");
          expect$.Expect.equals("Error", error);
          dart.throw("Error2");
        }

      } catch (error) {
        expect$.Expect.equals("Error2", error);
        tracer.trace("c");
      }

      tracer.trace("d");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo4, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo5 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        tracer.trace("a");
        try {
          yield async.Future.value(3);
          tracer.trace("b");
          dart.throw("Error");
        } catch (error) {
          tracer.trace("c");
          expect$.Expect.equals("Error", error);
          dart.throw("Error2");
        }

      } finally {
        tracer.trace("d");
      }
      tracer.trace("e");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo5, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo6 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          yield async.Future.value(3);
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          tracer.trace("b");
          expect$.Expect.equals("Error", error);
          dart.throw("Error2");
        }
 finally {
          tracer.trace("c");
          dart.throw("Error3");
        }
      } catch (error) {
        tracer.trace("d");
        expect$.Expect.equals("Error3", error);
      }

      tracer.trace("e");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo6, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo7 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          yield async.Future.value(3);
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          expect$.Expect.equals("Error", error);
          tracer.trace("b");
          dart.throw("Error2");
        }
 finally {
          tracer.trace("c");
          dart.throw("Error3");
        }
      } finally {
        tracer.trace("d");
      }
      tracer.trace("e");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo7, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo8 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          yield async.Future.value(3);
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          expect$.Expect.equals("Error", error);
          tracer.trace("b");
          return;
        }
 finally {
          tracer.trace("c");
          dart.throw("Error3");
        }
      } finally {
        tracer.trace("d");
      }
      tracer.trace("e");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo8, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo9 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        while (true) {
          try {
            yield async.Future.value(3);
            tracer.trace("a");
            dart.throw("Error");
          } catch (error) {
            expect$.Expect.equals("Error", error);
            tracer.trace("b");
            return;
          }
 finally {
            tracer.trace("c");
            break;
          }
          tracer.trace("d");
        }
      } finally {
        tracer.trace("e");
      }
      tracer.trace("f");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo9, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo10 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        let i = 0;
        while (true) {
          try {
            try {
              tracer.trace("a");
              dart.throw("Error");
            } catch (error) {
              tracer.trace("b");
              try {
                yield async.Future.value(3);
                dart.throw("Error2");
              } catch (error) {
                tracer.trace("c");
              }
 finally {
                tracer.trace("d");
              }
              tracer.trace("e");
              dart.throw("Error3");
            }
 finally {
              tracer.trace("f");
              if (i == 0) continue;
              if (i == 1) break;
            }
          } finally {
            tracer.trace("g");
            i++;
          }
        }
      } finally {
        tracer.trace("h");
      }
      tracer.trace("i");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo10, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo11 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        let firstTime = true;
        while (true) {
          tracer.trace("a");
          if (firstTime) {
            try {
              yield async.Future.value(3);
              tracer.trace("b");
              dart.throw("Error");
            } catch (error) {
              expect$.Expect.equals("Error", error);
              tracer.trace("c");
              firstTime = false;
              continue;
            }
 finally {
              tracer.trace("d");
            }
          } else {
            tracer.trace("e");
            return;
          }
        }
      } finally {
        tracer.trace("f");
      }
      tracer.trace("g");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo11, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo12 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        let firstTime = true;
        while (true) {
          tracer.trace("a");
          if (firstTime) {
            try {
              yield async.Future.value(3);
              tracer.trace("b");
              dart.throw("Error");
            } catch (error) {
              expect$.Expect.equals("Error", error);
              tracer.trace("c");
              firstTime = false;
              continue;
            }
 finally {
              tracer.trace("d");
              break;
            }
          } else {
            tracer.trace("e");
            return;
          }
        }
      } finally {
        tracer.trace("f");
      }
      tracer.trace("g");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo12, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo13 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          tracer.trace("a");
          return;
        } catch (error) {
          tracer.trace("b");
        }
 finally {
          tracer.trace("c");
          try {
            try {
              yield async.Future.value(3);
              tracer.trace("d");
              dart.throw("Error");
            } finally {
              tracer.trace("e");
            }
          } finally {
            tracer.trace("f");
          }
        }
      } finally {
        tracer.trace("g");
      }
      tracer.trace("h");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo13, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo14 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          tracer.trace("b");
          try {
            yield async.Future.value(3);
            dart.throw("Error2");
          } catch (error) {
            tracer.trace("c");
          }
 finally {
            tracer.trace("d");
          }
          tracer.trace("e");
          dart.throw("Error3");
        }
 finally {
          tracer.trace("f");
        }
      } finally {
        tracer.trace("g");
      }
      tracer.trace("h");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo14, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo15 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          tracer.trace("b");
          try {
            yield async.Future.value(3);
            dart.throw("Error2");
          } catch (error) {
            tracer.trace("c");
          }
 finally {
            tracer.trace("d");
          }
          tracer.trace("e");
          dart.throw("Error3");
        }
 finally {
          tracer.trace("f");
          return;
        }
      } finally {
        tracer.trace("g");
      }
      tracer.trace("h");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo15, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo16 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        try {
          tracer.trace("a");
          dart.throw("Error");
        } catch (error) {
          tracer.trace("b");
          try {
            yield async.Future.value(3);
            dart.throw("Error2");
          } catch (error) {
            tracer.trace("c");
          }
 finally {
            tracer.trace("d");
            return;
          }
          tracer.trace("e");
          dart.throw("Error3");
        }
 finally {
          tracer.trace("f");
        }
      } finally {
        tracer.trace("g");
      }
      tracer.trace("h");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo16, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo17 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        tracer.trace("a");
      } finally {
        try {
          tracer.trace("b");
          dart.throw("Error");
        } catch (error) {
          yield async.Future.value(3);
          expect$.Expect.equals("Error", error);
          tracer.trace("c");
        }
 finally {
          tracer.trace("d");
        }
        tracer.trace("e");
      }
      tracer.trace("f");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo17, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.foo18 = function(tracer) {
    return dart.async(function*(tracer) {
      try {
        tracer.trace("a");
      } finally {
        try {
          tracer.trace("b");
        } finally {
          yield async.Future.value(3);
          tracer.trace("c");
        }
        tracer.trace("d");
      }
      tracer.trace("e");
    }, dart.dynamic, tracer);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.foo18, TracerTodynamic());
  async_throw_in_catch_test_forceAwait_multi.runTest = function(expectedTrace, fun, expectedError) {
    return dart.async(function*(expectedTrace, fun, expectedError) {
      if (expectedError === void 0) expectedError = null;
      let tracer = new async_throw_in_catch_test_forceAwait_multi.Tracer(core.String._check(expectedTrace), core.String._check(expectedTrace));
      try {
        yield dart.dcall(fun, tracer);
      } catch (error) {
        expect$.Expect.equals(expectedError, error);
        tracer.trace("X");
      }

      tracer.done();
    }, dart.dynamic, expectedTrace, fun, expectedError);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.runTest, dynamicAnddynamic__Todynamic());
  async_throw_in_catch_test_forceAwait_multi.test = function() {
    return dart.async(function*() {
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abceX", async_throw_in_catch_test_forceAwait_multi.foo1, "Error2");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abdeX", async_throw_in_catch_test_forceAwait_multi.foo2, "Error2");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abde", async_throw_in_catch_test_forceAwait_multi.foo3);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcd", async_throw_in_catch_test_forceAwait_multi.foo4);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdX", async_throw_in_catch_test_forceAwait_multi.foo5, "Error2");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcde", async_throw_in_catch_test_forceAwait_multi.foo6);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdX", async_throw_in_catch_test_forceAwait_multi.foo7, "Error3");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdX", async_throw_in_catch_test_forceAwait_multi.foo8, "Error3");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcef", async_throw_in_catch_test_forceAwait_multi.foo9);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdefgabcdefghi", async_throw_in_catch_test_forceAwait_multi.foo10);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdaef", async_throw_in_catch_test_forceAwait_multi.foo11);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdfg", async_throw_in_catch_test_forceAwait_multi.foo12);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("acdefgX", async_throw_in_catch_test_forceAwait_multi.foo13, "Error");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdefgX", async_throw_in_catch_test_forceAwait_multi.foo14, "Error3");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdefgX", async_throw_in_catch_test_forceAwait_multi.foo14, "Error3");
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdefg", async_throw_in_catch_test_forceAwait_multi.foo15);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdfg", async_throw_in_catch_test_forceAwait_multi.foo16);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcdef", async_throw_in_catch_test_forceAwait_multi.foo17);
      yield async_throw_in_catch_test_forceAwait_multi.runTest("abcde", async_throw_in_catch_test_forceAwait_multi.foo18);
    }, dart.dynamic);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.test, VoidTodynamic());
  async_throw_in_catch_test_forceAwait_multi.main = function() {
    async_helper$.asyncTest(async_throw_in_catch_test_forceAwait_multi.test);
  };
  dart.fn(async_throw_in_catch_test_forceAwait_multi.main, VoidTovoid());
  // Exports:
  exports.async_throw_in_catch_test_forceAwait_multi = async_throw_in_catch_test_forceAwait_multi;
});
