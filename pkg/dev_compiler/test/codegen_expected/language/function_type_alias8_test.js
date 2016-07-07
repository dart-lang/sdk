dart_library.library('language/function_type_alias8_test', null, /* Imports */[
  'dart_sdk'
], function load__function_type_alias8_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const function_type_alias8_test = Object.create(null);
  let GetFromThing = () => (GetFromThing = dart.constFn(function_type_alias8_test.GetFromThing$()))();
  let DefGetFromThing = () => (DefGetFromThing = dart.constFn(function_type_alias8_test.DefGetFromThing$()))();
  let GetFromThingOfThing = () => (GetFromThingOfThing = dart.constFn(function_type_alias8_test.GetFromThing$(function_type_alias8_test.Thing)))();
  let dynamicToGetFromThingOfThing = () => (dynamicToGetFromThingOfThing = dart.constFn(dart.definiteFunctionType(GetFromThingOfThing(), [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias8_test.GetFromThing$ = dart.generic(T => {
    const GetFromThing = dart.typedef('GetFromThing', () => dart.functionType(dart.dynamic, [T]));
    return GetFromThing;
  });
  function_type_alias8_test.GetFromThing = GetFromThing();
  function_type_alias8_test.DefGetFromThing$ = dart.generic(T => {
    const DefGetFromThing = dart.typedef('DefGetFromThing', () => dart.functionType(function_type_alias8_test.GetFromThing$(T), [dart.dynamic]));
    return DefGetFromThing;
  });
  function_type_alias8_test.DefGetFromThing = DefGetFromThing();
  function_type_alias8_test.Thing = class Thing extends core.Object {};
  function_type_alias8_test.Test = class Test extends core.Object {};
  dart.defineLazy(function_type_alias8_test.Test, {
    get fromThing() {
      return dart.fn(def => {
      }, dynamicToGetFromThingOfThing());
    }
  });
  function_type_alias8_test.main = function() {
    dart.dsend(function_type_alias8_test.Test, 'fromThing', 10);
  };
  dart.fn(function_type_alias8_test.main, VoidTodynamic());
  // Exports:
  exports.function_type_alias8_test = function_type_alias8_test;
});
