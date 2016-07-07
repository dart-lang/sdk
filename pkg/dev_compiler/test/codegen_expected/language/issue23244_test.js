dart_library.library('language/issue23244_test', null, /* Imports */[
  'dart_sdk'
], function load__issue23244_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const isolate = dart_sdk.isolate;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue23244_test = Object.create(null);
  let JSArrayOfFisk = () => (JSArrayOfFisk = dart.constFn(_interceptors.JSArray$(issue23244_test.Fisk)))();
  let MapOfint$Fisk = () => (MapOfint$Fisk = dart.constFn(core.Map$(core.int, issue23244_test.Fisk)))();
  let SendPortTodynamic = () => (SendPortTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [isolate.SendPort])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let FiskTodynamic = () => (FiskTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [issue23244_test.Fisk])))();
  issue23244_test.Fisk = class Fisk extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Fisk.torsk"
      }[this.index];
    }
  };
  issue23244_test.Fisk.torsk = dart.const(new issue23244_test.Fisk(0));
  issue23244_test.Fisk.values = dart.constList([issue23244_test.Fisk.torsk], issue23244_test.Fisk);
  issue23244_test.isolate1 = function(port) {
    port.send(issue23244_test.Fisk.torsk);
  };
  dart.fn(issue23244_test.isolate1, SendPortTodynamic());
  issue23244_test.isolate2 = function(port) {
    port.send(JSArrayOfFisk().of([issue23244_test.Fisk.torsk]));
  };
  dart.fn(issue23244_test.isolate2, SendPortTodynamic());
  issue23244_test.isolate3 = function(port) {
    let x = MapOfint$Fisk().new();
    x[dartx.set](0, issue23244_test.Fisk.torsk);
    x[dartx.set](1, issue23244_test.Fisk.torsk);
    port.send(x);
  };
  dart.fn(issue23244_test.isolate3, SendPortTodynamic());
  issue23244_test.main = function() {
    return dart.async(function*() {
      let port = isolate.ReceivePort.new();
      yield isolate.Isolate.spawn(issue23244_test.isolate1, port.sendPort);
      let completer1 = async.Completer.new();
      port.listen(dart.fn(message => {
        core.print(dart.str`Received ${message}`);
        port.close();
        issue23244_test.expectTorsk(issue23244_test.Fisk._check(message));
        completer1.complete();
      }, dynamicTovoid()));
      yield completer1.future;
      let completer2 = async.Completer.new();
      port = isolate.ReceivePort.new();
      yield isolate.Isolate.spawn(issue23244_test.isolate2, port.sendPort);
      port.listen(dart.fn(message => {
        core.print(dart.str`Received ${message}`);
        port.close();
        issue23244_test.expectTorsk(issue23244_test.Fisk._check(dart.dindex(message, 0)));
        completer2.complete();
      }, dynamicTovoid()));
      yield completer2.future;
      port = isolate.ReceivePort.new();
      yield isolate.Isolate.spawn(issue23244_test.isolate3, port.sendPort);
      port.listen(dart.fn(message => {
        core.print(dart.str`Received ${message}`);
        port.close();
        issue23244_test.expectTorsk(issue23244_test.Fisk._check(dart.dindex(message, 0)));
        issue23244_test.expectTorsk(issue23244_test.Fisk._check(dart.dindex(message, 1)));
      }, dynamicTovoid()));
    }, dart.dynamic);
  };
  dart.fn(issue23244_test.main, VoidTodynamic());
  issue23244_test.expectTorsk = function(fisk) {
    if (!dart.equals(fisk, issue23244_test.Fisk.torsk)) {
      dart.throw(dart.str`${fisk} isn't a ${issue23244_test.Fisk.torsk}`);
    }
  };
  dart.fn(issue23244_test.expectTorsk, FiskTodynamic());
  // Exports:
  exports.issue23244_test = issue23244_test;
});
