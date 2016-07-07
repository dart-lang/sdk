dart_library.library('language/switch_label_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__switch_label_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const switch_label_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  switch_label_test.Switcher = class Switcher extends core.Object {
    new() {
    }
    say1(sound) {
      let x = 0;
      switch (sound) {
        case "moo":
        {
          // Unimplemented case labels: [MOO:]
          x = 100;
          break;
        }
        case "woof":
        {
          x = 200;
          continue MOO;
        }
        default:
        {
          x = 300;
          break;
        }
      }
      return x;
    }
    say2(sound) {
      let x = 0;
      switch (sound) {
        case "woof":
        {
          // Unimplemented case labels: [WOOF:]
          x = 200;
          break;
        }
        case "moo":
        {
          x = 100;
          continue WOOF;
        }
        default:
        {
          x = 300;
          break;
        }
      }
      return x;
    }
    say3(animal, sound) {
      let x = 0;
      switch (animal) {
        case "cow":
        {
          switch (sound) {
            case "moo":
            {
              x = 100;
              break;
            }
            case "muh":
            {
              x = 200;
              break;
            }
            default:
            {
              continue NIX_UNDERSTAND;
            }
          }
          break;
        }
        case "dog":
        {
          if (dart.equals(sound, "woof")) {
            x = 300;
          } else {
            continue NIX_UNDERSTAND;
          }
          break;
        }
        case "unicorn":
        {
          // Unimplemented case labels: [NIX_UNDERSTAND:]
          x = 400;
          break;
        }
        default:
        {
          x = 500;
          break;
        }
      }
      return x;
    }
  };
  dart.setSignature(switch_label_test.Switcher, {
    constructors: () => ({new: dart.definiteFunctionType(switch_label_test.Switcher, [])}),
    methods: () => ({
      say1: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      say2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      say3: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])
    })
  });
  switch_label_test.SwitchLabelTest = class SwitchLabelTest extends core.Object {
    static testMain() {
      let s = new switch_label_test.Switcher();
      expect$.Expect.equals(100, s.say1("moo"));
      expect$.Expect.equals(100, s.say1("woof"));
      expect$.Expect.equals(300, s.say1("cockadoodledoo"));
      expect$.Expect.equals(200, s.say2("moo"));
      expect$.Expect.equals(200, s.say2("woof"));
      expect$.Expect.equals(300, s.say2(""));
      expect$.Expect.equals(100, s.say3("cow", "moo"));
      expect$.Expect.equals(200, s.say3("cow", "muh"));
      expect$.Expect.equals(400, s.say3("cow", "boeh"));
      expect$.Expect.equals(300, s.say3("dog", "woof"));
      expect$.Expect.equals(400, s.say3("dog", "boj"));
      expect$.Expect.equals(400, s.say3("unicorn", ""));
      expect$.Expect.equals(500, s.say3("angry bird", "whoooo"));
    }
  };
  dart.setSignature(switch_label_test.SwitchLabelTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  switch_label_test.main = function() {
    switch_label_test.SwitchLabelTest.testMain();
  };
  dart.fn(switch_label_test.main, VoidTodynamic());
  // Exports:
  exports.switch_label_test = switch_label_test;
});
