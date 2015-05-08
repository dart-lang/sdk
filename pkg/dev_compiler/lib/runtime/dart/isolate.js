var isolate = dart.defineLibrary(isolate, {});
var core = dart.import(core);
var _isolate_helper = dart.lazyImport(_isolate_helper);
var async = dart.import(async);
(function(exports, core, _isolate_helper, async) {
  'use strict';
  class Capability extends core.Object {
    Capability() {
      return new _isolate_helper.CapabilityImpl();
    }
  }
  class IsolateSpawnException extends core.Object {
    IsolateSpawnException(message) {
      this.message = message;
    }
    toString() {
      return `IsolateSpawnException: ${this.message}`;
    }
  }
  IsolateSpawnException[dart.implements] = () => [core.Exception];
  let _pause = Symbol('_pause');
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
        return dart.as(_isolate_helper.IsolateNatives.spawnFunction(entryPoint, message, paused).then(msg => new Isolate(dart.as(dart.dindex(msg, 1), SendPort), {pauseCapability: dart.as(dart.dindex(msg, 2), Capability), terminateCapability: dart.as(dart.dindex(msg, 3), Capability)})), async.Future$(Isolate));
      } catch (e) {
        let st = dart.stackTrace(e);
        return new (async.Future$(Isolate)).error(e, st);
      }

    }
    static spawnUri(uri, args, message, opts) {
      let paused = opts && 'paused' in opts ? opts.paused : false;
      let packageRoot = opts && 'packageRoot' in opts ? opts.packageRoot : null;
      if (packageRoot != null)
        throw new core.UnimplementedError("packageRoot");
      try {
        if (dart.is(args, core.List)) {
          for (let i = 0; dart.notNull(i) < dart.notNull(args[core.$length]); i = dart.notNull(i) + 1) {
            if (!(typeof args[core.$get](i) == 'string')) {
              throw new core.ArgumentError(`Args must be a list of Strings ${args}`);
            }
          }
        } else if (args != null) {
          throw new core.ArgumentError(`Args must be a list of Strings ${args}`);
        }
        return dart.as(_isolate_helper.IsolateNatives.spawnUri(uri, args, message, paused).then(msg => new Isolate(dart.as(dart.dindex(msg, 1), SendPort), {pauseCapability: dart.as(dart.dindex(msg, 2), Capability), terminateCapability: dart.as(dart.dindex(msg, 3), Capability)})), async.Future$(Isolate));
      } catch (e) {
        let st = dart.stackTrace(e);
        return new (async.Future$(Isolate)).error(e, st);
      }

    }
    pause(resumeCapability) {
      if (resumeCapability === void 0)
        resumeCapability = null;
      if (resumeCapability == null)
        resumeCapability = new Capability();
      this[_pause](resumeCapability);
      return resumeCapability;
    }
    [_pause](resumeCapability) {
      let message = new core.List(3);
      message[core.$set](0, "pause");
      message[core.$set](1, this.pauseCapability);
      message[core.$set](2, resumeCapability);
      this.controlPort.send(message);
    }
    resume(resumeCapability) {
      let message = new core.List(2);
      message[core.$set](0, "resume");
      message[core.$set](1, resumeCapability);
      this.controlPort.send(message);
    }
    addOnExitListener(responsePort) {
      let message = new core.List(2);
      message[core.$set](0, "add-ondone");
      message[core.$set](1, responsePort);
      this.controlPort.send(message);
    }
    removeOnExitListener(responsePort) {
      let message = new core.List(2);
      message[core.$set](0, "remove-ondone");
      message[core.$set](1, responsePort);
      this.controlPort.send(message);
    }
    setErrorsFatal(errorsAreFatal) {
      let message = new core.List(3);
      message[core.$set](0, "set-errors-fatal");
      message[core.$set](1, this.terminateCapability);
      message[core.$set](2, errorsAreFatal);
      this.controlPort.send(message);
    }
    kill(priority) {
      if (priority === void 0)
        priority = Isolate.BEFORE_NEXT_EVENT;
      this.controlPort.send(["kill", this.terminateCapability, priority]);
    }
    ping(responsePort, pingType) {
      if (pingType === void 0)
        pingType = Isolate.IMMEDIATE;
      let message = new core.List(3);
      message[core.$set](0, "ping");
      message[core.$set](1, responsePort);
      message[core.$set](2, pingType);
      this.controlPort.send(message);
    }
    addErrorListener(port) {
      let message = new core.List(2);
      message[core.$set](0, "getErrors");
      message[core.$set](1, port);
      this.controlPort.send(message);
    }
    removeErrorListener(port) {
      let message = new core.List(2);
      message[core.$set](0, "stopErrors");
      message[core.$set](1, port);
      this.controlPort.send(message);
    }
    get errors() {
      let controller = null;
      let port = null;
      // Function handleError: (dynamic) → void
      let handleError = message => {
        let errorDescription = dart.as(dart.dindex(message, 0), core.String);
        let stackDescription = dart.as(dart.dindex(message, 1), core.String);
        let error = new RemoteError(errorDescription, stackDescription);
        controller.addError(error, error.stackTrace);
      };
      controller = new async.StreamController.broadcast({
        sync: true,
        onListen: (() => {
          port = new RawReceivePort(handleError);
          this.addErrorListener(port.sendPort);
        }).bind(this),
        onCancel: (() => {
          this.removeErrorListener(port.sendPort);
          port.close();
          port = null;
        }).bind(this)
      });
      return controller.stream;
    }
  }
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
    ReceivePort() {
      return new _isolate_helper.ReceivePortImpl();
    }
    fromRawReceivePort(rawPort) {
      return new _isolate_helper.ReceivePortImpl.fromRawReceivePort(rawPort);
    }
  }
  ReceivePort[dart.implements] = () => [async.Stream];
  dart.defineNamedConstructor(ReceivePort, 'fromRawReceivePort');
  class RawReceivePort extends core.Object {
    RawReceivePort(handler) {
      if (handler === void 0)
        handler = null;
      return new _isolate_helper.RawReceivePortImpl(handler);
    }
  }
  class _IsolateUnhandledException extends core.Object {
    _IsolateUnhandledException(message, source, stackTrace) {
      this.message = message;
      this.source = source;
      this.stackTrace = stackTrace;
    }
    toString() {
      return 'IsolateUnhandledException: exception while handling message: ' + `${this.message} \n  ` + `${dart.toString(this.source).replaceAll("\n", "\n  ")}\n` + 'original stack trace:\n  ' + `${dart.toString(this.stackTrace).replaceAll("\n", "\n  ")}`;
    }
  }
  _IsolateUnhandledException[dart.implements] = () => [core.Exception];
  let _description = Symbol('_description');
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
  let _trace = Symbol('_trace');
  class _RemoteStackTrace extends core.Object {
    _RemoteStackTrace(trace) {
      this[_trace] = trace;
    }
    toString() {
      return this[_trace];
    }
  }
  _RemoteStackTrace[dart.implements] = () => [core.StackTrace];
  // Exports:
  exports.Capability = Capability;
  exports.IsolateSpawnException = IsolateSpawnException;
  exports.Isolate = Isolate;
  exports.SendPort = SendPort;
  exports.ReceivePort = ReceivePort;
  exports.RawReceivePort = RawReceivePort;
  exports.RemoteError = RemoteError;
})(isolate, core, _isolate_helper, async);
