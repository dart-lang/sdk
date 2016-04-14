dart_library.library('try_catch', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const try_catch = Object.create(null);
  try_catch.foo = function() {
    try {
      dart.throw("hi there");
    } catch (e$) {
      if (dart.is(e$, core.String)) {
        let e = e$;
        let t = dart.stackTrace(e);
      } else {
        let e = e$;
        let t = dart.stackTrace(e);
        throw e;
      }
    }

  };
  dart.fn(try_catch.foo);
  try_catch.bar = function() {
    try {
      dart.throw("hi there");
    } catch (e$) {
      let e = e$;
      let t = dart.stackTrace(e);
    }

  };
  dart.fn(try_catch.bar);
  try_catch.baz = function() {
    try {
      dart.throw("finally only");
    } finally {
      return true;
    }
  };
  dart.fn(try_catch.baz);
  try_catch.qux = function() {
    try {
      dart.throw("on only");
    } catch (e) {
      if (dart.is(e, core.String)) {
        let t = dart.stackTrace(e);
        throw e;
      } else
        throw e;
    }

  };
  dart.fn(try_catch.qux);
  try_catch.wub = function() {
    try {
      dart.throw("on without exception parameter");
    } catch (e) {
      if (dart.is(e, core.String)) {
      } else
        throw e;
    }

  };
  dart.fn(try_catch.wub);
  try_catch.main = function() {
    try_catch.foo();
    try_catch.bar();
    try_catch.baz();
    try_catch.qux();
    try_catch.wub();
  };
  dart.fn(try_catch.main);
  // Exports:
  exports.try_catch = try_catch;
});
