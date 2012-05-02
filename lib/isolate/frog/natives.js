// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Top-level native code needed by the frog compiler

var $globalThis = this;
var $globals = null;
var $globalState = null;
var $thisScriptUrl = null;
var $isWorker = typeof ($globalThis['importScripts']) != 'undefined';
var $supportsWorkers =
    $isWorker || ((typeof $globalThis['Worker']) != 'undefined');
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

// Wrap a 2-arg dom-callback to bind it with the current isolate:
function $wrap_call$2(fn) { return fn && fn.wrap$call$2(); }

Function.prototype.wrap$call$2 = function() {
  var isolateContext = $globalState.currentContext;
  var self = this;
  this.wrap$2 = function(arg1, arg2) {
    var res = isolateContext.eval(function() { return self(arg1, arg2); });
    $globalState.topEventLoop.run();
    return res;
  };
  this.wrap$call$2 = function() { return this.wrap$2; };
  return this.wrap$2;
};

$thisScriptUrl = (function () {
  if (!$supportsWorkers || $isWorker) return (void 0);

  // TODO(5334778): Find a cross-platform non-brittle way of getting the
  // currently running script.
  var scripts = document.getElementsByTagName('script');
  // The scripts variable only contains the scripts that have already been
  // executed. The last one is the currently running script.
  var script = scripts[scripts.length - 1];
  var src = script && script.src;
  if (!src) {
    // TODO()
    src = "FIXME:5407062" + "_" + Math.random().toString();
    if (script) script.src = src;
  }
  return src;
})();
