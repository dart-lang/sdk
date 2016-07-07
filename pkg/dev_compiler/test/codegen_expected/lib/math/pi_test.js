dart_library.library('lib/math/pi_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__pi_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const pi_test = Object.create(null);
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [], [dart.dynamic])))();
  pi_test.known_bad_seeds = dart.constList([50051, 55597, 59208], core.int);
  pi_test.main = function(args) {
    if (args === void 0) args = null;
    let seed = -1;
    if (args != null && dart.test(dart.dsend(dart.dload(args, 'length'), '>', 0))) {
      seed = core.int.parse(core.String._check(dart.dindex(args, 0)));
    } else {
      let seed_prng = math.Random.new();
      while (seed == -1) {
        seed = seed_prng.nextInt(1 << 16);
        if (dart.test(pi_test.known_bad_seeds[dartx.contains](seed))) {
          seed = -1;
        }
      }
    }
    core.print(dart.str`pi_test seed: ${seed}`);
    let prng = math.Random.new(seed);
    let outside = 0;
    let inside = 0;
    for (let i = 0; i < 600000; i++) {
      let x = prng.nextDouble();
      let y = prng.nextDouble();
      if (dart.notNull(x) * dart.notNull(x) + dart.notNull(y) * dart.notNull(y) < 1.0) {
        inside++;
      } else {
        outside++;
      }
    }
    let pie = 4.0 * (inside / (inside + outside));
    core.print(dart.str`${pie}`);
    expect$.Expect.isTrue(math.PI - 0.009 < pie && pie < math.PI + 0.009);
  };
  dart.fn(pi_test.main, __Tovoid());
  // Exports:
  exports.pi_test = pi_test;
});
