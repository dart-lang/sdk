// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Top-level native code needed by the frog compiler

var $globalThis = this;
var $globals = null;
var $globalState = null;
function $initGlobals(context) { context.isolateStatics = {}; }
function $setGlobals(context) { $globals = context.isolateStatics; }

// Wrap a 0-arg dom-callback to bind it with the current isolate:
function $wrap_call$0(fn) { return fn && fn.wrap$call$0(); }

Function.prototype.wrap$call$0 = function() {
  var isolateContext = $globalState.currentContext;
  var self = this;
  this.wrap$0 = function() {
    var res = isolateContext.eval(self);
    $globalState.topEventLoop.run();
    return res;
  };
  this.wrap$call$0 = function() { return this.wrap$0; };
  return this.wrap$0;
};

// Wrap a 1-arg dom-callback to bind it with the current isolate:
function $wrap_call$1(fn) { return fn && fn.wrap$call$1(); }

Function.prototype.wrap$call$1 = function() {
  var isolateContext = $globalState.currentContext;
  var self = this;
  this.wrap$1 = function(arg) {
    var res = isolateContext.eval(function() { return self(arg); });
    $globalState.topEventLoop.run();
    return res;
  };
  this.wrap$call$1 = function() { return this.wrap$1; };
  return this.wrap$1;
};
