dart_library.library('language/fannkuch_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fannkuch_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fannkuch_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  fannkuch_test.FannkuchTest = class FannkuchTest extends core.Object {
    static fannkuch(n) {
      let p = core.List.new(core.int._check(n)), q = core.List.new(core.int._check(n)), s = core.List.new(core.int._check(n));
      let sign = 1, maxflips = 0, sum = 0, m = dart.dsend(n, '-', 1);
      for (let i = 0; i < dart.notNull(core.num._check(n)); i++) {
        p[dartx.set](i, i);
        q[dartx.set](i, i);
        s[dartx.set](i, i);
      }
      do {
        let q0 = p[dartx.get](0);
        if (!dart.equals(q0, 0)) {
          for (let i = 1; i < dart.notNull(core.num._check(n)); i++)
            q[dartx.set](i, p[dartx.get](i));
          let flips = 1;
          do {
            let qq = q[dartx.get](core.int._check(q0));
            if (dart.equals(qq, 0)) {
              sum = sum + sign * flips;
              if (flips > maxflips) maxflips = flips;
              break;
            }
            q[dartx.set](core.int._check(q0), q0);
            if (dart.test(dart.dsend(q0, '>=', 3))) {
              let i = 1, j = dart.dsend(q0, '-', 1), t = null;
              do {
                t = q[dartx.get](i);
                q[dartx.set](i, q[dartx.get](core.int._check(j)));
                q[dartx.set](core.int._check(j), t);
                i++;
                j = dart.dsend(j, '-', 1);
              } while (i < dart.notNull(core.num._check(j)));
            }
            q0 = qq;
            flips++;
          } while (true);
        }
        if (sign == 1) {
          let t = p[dartx.get](1);
          p[dartx.set](1, p[dartx.get](0));
          p[dartx.set](0, t);
          sign = -1;
        } else {
          let t = p[dartx.get](1);
          p[dartx.set](1, p[dartx.get](2));
          p[dartx.set](2, t);
          sign = 1;
          for (let i = 2; i < dart.notNull(core.num._check(n)); i++) {
            let sx = s[dartx.get](i);
            if (!dart.equals(sx, 0)) {
              s[dartx.set](i, dart.dsend(sx, '-', 1));
              break;
            }
            if (dart.equals(i, m)) {
              return JSArrayOfint().of([sum, maxflips]);
            }
            s[dartx.set](i, i);
            t = p[dartx.get](0);
            for (let j = 0; j <= i; j++) {
              p[dartx.set](j, p[dartx.get](j + 1));
            }
            p[dartx.set](i + 1, t);
          }
        }
      } while (true);
    }
    static testMain() {
      let n = 6;
      let pf = fannkuch_test.FannkuchTest.fannkuch(n);
      expect$.Expect.equals(49, dart.dindex(pf, 0));
      expect$.Expect.equals(10, dart.dindex(pf, 1));
      core.print(dart.str`${dart.dindex(pf, 0)}\nPfannkuchen(${n}) = ${dart.dindex(pf, 1)}`);
    }
  };
  dart.setSignature(fannkuch_test.FannkuchTest, {
    statics: () => ({
      fannkuch: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['fannkuch', 'testMain']
  });
  fannkuch_test.main = function() {
    fannkuch_test.FannkuchTest.testMain();
  };
  dart.fn(fannkuch_test.main, VoidTodynamic());
  // Exports:
  exports.fannkuch_test = fannkuch_test;
});
