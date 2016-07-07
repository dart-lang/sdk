dart_library.library('language/issue10581_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10581_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10581_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue10581_test.AxesObject = class AxesObject extends core.Object {};
  issue10581_test.result = '';
  issue10581_test.Point2DObject = class Point2DObject extends issue10581_test.AxesObject {
    Update() {
      issue10581_test.result = dart.notNull(issue10581_test.result) + 'P';
    }
  };
  dart.setSignature(issue10581_test.Point2DObject, {
    methods: () => ({Update: dart.definiteFunctionType(dart.dynamic, [])})
  });
  issue10581_test.BestFitObject = class BestFitObject extends issue10581_test.AxesObject {
    Update() {
      issue10581_test.result = dart.notNull(issue10581_test.result) + 'B';
    }
  };
  dart.setSignature(issue10581_test.BestFitObject, {
    methods: () => ({Update: dart.definiteFunctionType(dart.dynamic, [])})
  });
  issue10581_test.Foo = class Foo extends core.Object {
    AddAxesObject(type) {
      let a = null;
      switch (type) {
        case 100:
        {
          a = new issue10581_test.Point2DObject();
          break;
        }
        case 200:
        {
          a = new issue10581_test.BestFitObject();
          break;
        }
      }
      if (a != null) {
        a.Update();
      }
    }
    AddAxesObject2(type) {
      let a = null;
      if (dart.equals(type, 100)) {
        a = new issue10581_test.Point2DObject();
      } else if (dart.equals(type, 200)) {
        a = new issue10581_test.BestFitObject();
      }
      if (a != null) {
        a.Update();
      }
    }
  };
  dart.setSignature(issue10581_test.Foo, {
    methods: () => ({
      AddAxesObject: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      AddAxesObject2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  issue10581_test.main = function() {
    let f = new issue10581_test.Foo();
    f.AddAxesObject(100);
    f.AddAxesObject(200);
    f.AddAxesObject2(100);
    f.AddAxesObject2(200);
    expect$.Expect.equals('PBPB', issue10581_test.result);
  };
  dart.fn(issue10581_test.main, VoidTodynamic());
  // Exports:
  exports.issue10581_test = issue10581_test;
});
