dart_library.library('dart/isolate', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/async'
], /* Lazy imports */[
  'dart/_isolate_helper'
], function(exports, dart, core, async, _isolate_helper) {
  'use strict';
  let dartx = dart.dartx;
  class Capability extends core.Object {
    static new() {
      return new _isolate_helper.CapabilityImpl();
    }
  }
  dart.setSignature(Capability, {
    constructors: () => ({new: [Capability, []]})
  });
  class IsolateSpawnException extends core.Object {
    IsolateSpawnException(message) {
      this.message = message;
    }
    toString() {
      return `IsolateSpawnException: ${this.message}`;
    }
  }
  IsolateSpawnException[dart.implements] = () => [core.Exception];
  dart.setSignature(IsolateSpawnException, {
    constructors: () => ({IsolateSpawnException: [IsolateSpawnException, [core.String]]})
  });
  const _pause = Symbol('_pause');
  class Isolate extends core.Object {
    Isolate(controlPort, opts) {
      let pauseCapability = opts && 'pauseCapability' in opts ? opts.pauseCapability : null;
      let terminateCapability = opts && 'terminateCapability' in opts ? opts.terminateCapability : null;
      this.controlPort = controlPort;
      this.pauseCapability = pauseCapability;
      this.terminateCapability = terminateCapability;
    }
    static get current() {
      return Isolate._currentIsolateCache;
    }
    static spawn(entryPoint, message, opts) {
      let paused = opts && 'paused' in opts ? opts.paused : false;
      try {
        return _isolate_helper.IsolateNatives.spawnFunction(entryPoint, message, paused).then(dart.fn(msg => new Isolate(dart.as(msg[dartx.get](1), SendPort), {pauseCapability: dart.as(msg[dartx.get](2), Capability), terminateCapability: dart.as(msg[dartx.get](3), Capability)}), Isolate, [core.List]));
      } catch (e) {
        let st = dart.stackTrace(e);
        return async.Future$(Isolate).error(e, st);
      }

    }
    static spawnUri(uri, args, message, opts) {
      let paused = opts && 'paused' in opts ? opts.paused : false;
      let packageRoot = opts && 'packageRoot' in opts ? opts.packageRoot : null;
      if (packageRoot != null) dart.throw(new core.UnimplementedError("packageRoot"));
      try {
        if (dart.is(args, core.List)) {
          for (let i = 0; i < dart.notNull(args[dartx.length]); i++) {
            if (!(typeof args[dartx.get](i) == 'string')) {
              dart.throw(new core.ArgumentError(`Args must be a list of Strings ${args}`));
            }
          }
        } else if (args != null) {
          dart.throw(new core.ArgumentError(`Args must be a list of Strings ${args}`));
        }
        return _isolate_helper.IsolateNatives.spawnUri(uri, args, message, paused).then(dart.fn(msg => new Isolate(dart.as(msg[dartx.get](1), SendPort), {pauseCapability: dart.as(msg[dartx.get](2), Capability), terminateCapability: dart.as(msg[dartx.get](3), Capability)}), Isolate, [core.List]));
      } catch (e) {
        let st = dart.stackTrace(e);
        return async.Future$(Isolate).error(e, st);
      }

    }
    pause(resumeCapability) {
      if (resumeCapability === void 0) resumeCapability = null;
      if (resumeCapability == null) resumeCapability = Capability.new();
      this[_pause](resumeCapability);
      return resumeCapability;
    }
    [_pause](resumeCapability) {
      let message = core.List.new(3);
      message[dartx.set](0, "pause");
      message[dartx.set](1, this.pauseCapability);
      message[dartx.set](2, resumeCapability);
      this.controlPort.send(message);
    }
    resume(resumeCapability) {
      let message = core.List.new(2);
      message[dartx.set](0, "resume");
      message[dartx.set](1, resumeCapability);
      this.controlPort.send(message);
    }
    addOnExitListener(responsePort) {
      let message = core.List.new(2);
      message[dartx.set](0, "add-ondone");
      message[dartx.set](1, responsePort);
      this.controlPort.send(message);
    }
    removeOnExitListener(responsePort) {
      let message = core.List.new(2);
      message[dartx.set](0, "remove-ondone");
      message[dartx.set](1, responsePort);
      this.controlPort.send(message);
    }
    setErrorsFatal(errorsAreFatal) {
      let message = core.List.new(3);
      message[dartx.set](0, "set-errors-fatal");
      message[dartx.set](1, this.terminateCapability);
      message[dartx.set](2, errorsAreFatal);
      this.controlPort.send(message);
    }
    kill(priority) {
      if (priority === void 0) priority = Isolate.BEFORE_NEXT_EVENT;
      this.controlPort.send(dart.list(["kill", this.terminateCapability, priority], core.Object));
    }
    ping(responsePort, pingType) {
      if (pingType === void 0) pingType = Isolate.IMMEDIATE;
      let message = core.List.new(3);
      message[dartx.set](0, "ping");
      message[dartx.set](1, responsePort);
      message[dartx.set](2, pingType);
      this.controlPort.send(message);
    }
    addErrorListener(port) {
      let message = core.List.new(2);
      message[dartx.set](0, "getErrors");
      message[dartx.set](1, port);
      this.controlPort.send(message);
    }
    removeErrorListener(port) {
      let message = core.List.new(2);
      message[dartx.set](0, "stopErrors");
      message[dartx.set](1, port);
      this.controlPort.send(message);
    }
    get errors() {
      let controller = null;
      let port = null;
      function handleError(message) {
        let errorDescription = dart.as(dart.dindex(message, 0), core.String);
        let stackDescription = dart.as(dart.dindex(message, 1), core.String);
        let error = new RemoteError(errorDescription, stackDescription);
        controller.addError(error, error.stackTrace);
      }
      dart.fn(handleError, dart.void, [dart.dynamic]);
      controller = async.StreamController.broadcast({sync: true, onListen: dart.fn(() => {
          port = RawReceivePort.new(handleError);
          this.addErrorListener(port.sendPort);
        }, dart.void, []), onCancel: dart.fn(() => {
          this.removeErrorListener(port.sendPort);
          port.close();
          port = null;
        }, dart.void, [])});
      return controller.stream;
    }
  }
  dart.setSignature(Isolate, {
    constructors: () => ({Isolate: [Isolate, [SendPort], {pauseCapability: Capability, terminateCapability: Capability}]}),
    methods: () => ({
      pause: [Capability, [], [Capability]],
      [_pause]: [dart.void, [Capability]],
      resume: [dart.void, [Capability]],
      addOnExitListener: [dart.void, [SendPort]],
      removeOnExitListener: [dart.void, [SendPort]],
      setErrorsFatal: [dart.void, [core.bool]],
      kill: [dart.void, [], [core.int]],
      ping: [dart.void, [SendPort], [core.int]],
      addErrorListener: [dart.void, [SendPort]],
      removeErrorListener: [dart.void, [SendPort]]
    }),
    statics: () => ({
      spawn: [async.Future$(Isolate), [dart.functionType(dart.void, [dart.dynamic]), dart.dynamic], {paused: core.bool}],
      spawnUri: [async.Future$(Isolate), [core.Uri, core.List$(core.String), dart.dynamic], {paused: core.bool, packageRoot: core.Uri}]
    }),
    names: ['spawn', 'spawnUri']
  });
  Isolate.IMMEDIATE = 0;
  Isolate.BEFORE_NEXT_EVENT = 1;
  Isolate.AS_EVENT = 2;
  dart.defineLazyProperties(Isolate, {
    get _currentIsolateCache() {
      return _isolate_helper.IsolateNatives.currentIsolate;
    }
  });
  class SendPort extends core.Object {}
  SendPort[dart.implements] = () => [Capability];
  class ReceivePort extends core.Object {
    static new() {
      return new _isolate_helper.ReceivePortImpl();
    }
    static fromRawReceivePort(rawPort) {
      return new _isolate_helper.ReceivePortImpl.fromRawReceivePort(rawPort);
    }
  }
  ReceivePort[dart.implements] = () => [async.Stream];
  dart.setSignature(ReceivePort, {
    constructors: () => ({
      new: [ReceivePort, []],
      fromRawReceivePort: [ReceivePort, [RawReceivePort]]
    })
  });
  class RawReceivePort extends core.Object {
    static new(handler) {
      if (handler === void 0) handler = null;
      return new _isolate_helper.RawReceivePortImpl(handler);
    }
  }
  dart.setSignature(RawReceivePort, {
    constructors: () => ({new: [RawReceivePort, [], [dart.functionType(dart.void, [dart.dynamic])]]})
  });
  class _IsolateUnhandledException extends core.Object {
    _IsolateUnhandledException(message, source, stackTrace) {
      this.message = message;
      this.source = source;
      this.stackTrace = stackTrace;
    }
    toString() {
      return 'IsolateUnhandledException: exception while handling message: ' + `${this.message} \n  ` + `${dart.toString(this.source)[dartx.replaceAll]("\n", "\n  ")}\n` + 'original stack trace:\n  ' + `${dart.toString(this.stackTrace)[dartx.replaceAll]("\n", "\n  ")}`;
    }
  }
  _IsolateUnhandledException[dart.implements] = () => [core.Exception];
  dart.setSignature(_IsolateUnhandledException, {
    constructors: () => ({_IsolateUnhandledException: [_IsolateUnhandledException, [dart.dynamic, dart.dynamic, core.StackTrace]]})
  });
  const _description = Symbol('_description');
  class RemoteError extends core.Object {
    RemoteError(description, stackDescription) {
      this[_description] = description;
      this.stackTrace = new _RemoteStackTrace(stackDescription);
    }
    toString() {
      return this[_description];
    }
  }
  RemoteError[dart.implements] = () => [core.Error];
  dart.setSignature(RemoteError, {
    constructors: () => ({RemoteError: [RemoteError, [core.String, core.String]]})
  });
  const _trace = Symbol('_trace');
  class _RemoteStackTrace extends core.Object {
    _RemoteStackTrace(trace) {
      this[_trace] = trace;
    }
    toString() {
      return this[_trace];
    }
  }
  _RemoteStackTrace[dart.implements] = () => [core.StackTrace];
  dart.setSignature(_RemoteStackTrace, {
    constructors: () => ({_RemoteStackTrace: [_RemoteStackTrace, [core.String]]})
  });
  // Exports:
  exports.Capability = Capability;
  exports.IsolateSpawnException = IsolateSpawnException;
  exports.Isolate = Isolate;
  exports.SendPort = SendPort;
  exports.ReceivePort = ReceivePort;
  exports.RawReceivePort = RawReceivePort;
  exports.RemoteError = RemoteError;
});
