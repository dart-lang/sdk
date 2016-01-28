dart_library.library('dart/async', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/_internal',
  'dart/collection'
], /* Lazy imports */[
  'dart/_isolate_helper'
], function(exports, dart, core, _internal, collection, _isolate_helper) {
  'use strict';
  let dartx = dart.dartx;
  function _invokeErrorHandler(errorHandler, error, stackTrace) {
    if (dart.is(errorHandler, ZoneBinaryCallback)) {
      return dart.dcall(errorHandler, error, stackTrace);
    } else {
      return dart.dcall(errorHandler, error);
    }
  }
  dart.fn(_invokeErrorHandler, dart.dynamic, [core.Function, core.Object, core.StackTrace]);
  function _registerErrorHandler(errorHandler, zone) {
    if (dart.is(errorHandler, ZoneBinaryCallback)) {
      return zone.registerBinaryCallback(errorHandler);
    } else {
      return zone.registerUnaryCallback(dart.as(errorHandler, __CastType0));
    }
  }
  dart.fn(_registerErrorHandler, () => dart.definiteFunctionType(core.Function, [core.Function, Zone]));
  class AsyncError extends core.Object {
    AsyncError(error, stackTrace) {
      this.error = error;
      this.stackTrace = stackTrace;
    }
    toString() {
      return dart.toString(this.error);
    }
  }
  AsyncError[dart.implements] = () => [core.Error];
  dart.setSignature(AsyncError, {
    constructors: () => ({AsyncError: [AsyncError, [dart.dynamic, core.StackTrace]]})
  });
  class _UncaughtAsyncError extends AsyncError {
    _UncaughtAsyncError(error, stackTrace) {
      super.AsyncError(error, _UncaughtAsyncError._getBestStackTrace(error, stackTrace));
    }
    static _getBestStackTrace(error, stackTrace) {
      if (stackTrace != null) return stackTrace;
      if (dart.is(error, core.Error)) {
        return error.stackTrace;
      }
      return null;
    }
    toString() {
      let result = `Uncaught Error: ${this.error}`;
      if (this.stackTrace != null) {
        result = result + `\nStack Trace:\n${this.stackTrace}`;
      }
      return result;
    }
  }
  dart.setSignature(_UncaughtAsyncError, {
    constructors: () => ({_UncaughtAsyncError: [_UncaughtAsyncError, [dart.dynamic, core.StackTrace]]}),
    statics: () => ({_getBestStackTrace: [core.StackTrace, [dart.dynamic, core.StackTrace]]}),
    names: ['_getBestStackTrace']
  });
  const __CastType0 = dart.typedef('__CastType0', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  const _add = Symbol('_add');
  const _closeUnchecked = Symbol('_closeUnchecked');
  const _addError = Symbol('_addError');
  const _completeError = Symbol('_completeError');
  const _complete = Symbol('_complete');
  const _sink = Symbol('_sink');
  const Stream$ = dart.generic(function(T) {
    class Stream extends core.Object {
      Stream() {
      }
      static fromFuture(future) {
        let controller = dart.as(StreamController$(T).new({sync: true}), _StreamController$(T));
        future.then(dart.fn(value => {
          dart.as(value, T);
          controller[_add](value);
          controller[_closeUnchecked]();
        }, dart.dynamic, [T]), {onError: dart.fn((error, stackTrace) => {
            controller[_addError](error, dart.as(stackTrace, core.StackTrace));
            controller[_closeUnchecked]();
          })});
        return controller.stream;
      }
      static fromIterable(data) {
        return new (_GeneratedStreamImpl$(T))(dart.fn(() => new (_IterablePendingEvents$(T))(data), _IterablePendingEvents$(T), []));
      }
      static periodic(period, computation) {
        if (computation === void 0) computation = null;
        if (computation == null) computation = dart.fn(i => null, T, [core.int]);
        let timer = null;
        let computationCount = 0;
        let controller = null;
        let watch = new core.Stopwatch();
        function sendEvent() {
          watch.reset();
          let data = computation(computationCount++);
          controller.add(data);
        }
        dart.fn(sendEvent, dart.void, []);
        function startPeriodicTimer() {
          dart.assert(timer == null);
          timer = Timer.periodic(period, dart.fn(timer => {
            sendEvent();
          }, dart.void, [Timer]));
        }
        dart.fn(startPeriodicTimer, dart.void, []);
        controller = StreamController$(T).new({sync: true, onListen: dart.fn(() => {
            watch.start();
            startPeriodicTimer();
          }, dart.void, []), onPause: dart.fn(() => {
            timer.cancel();
            timer = null;
            watch.stop();
          }, dart.void, []), onResume: dart.fn(() => {
            dart.assert(timer == null);
            let elapsed = watch.elapsed;
            watch.start();
            timer = Timer.new(period['-'](elapsed), dart.fn(() => {
              timer = null;
              startPeriodicTimer();
              sendEvent();
            }, dart.void, []));
          }, dart.void, []), onCancel: dart.fn(() => {
            if (timer != null) timer.cancel();
            timer = null;
          })});
        return controller.stream;
      }
      static eventTransformed(source, mapSink) {
        return new (_BoundSinkStream$(dart.dynamic, T))(source, mapSink);
      }
      get isBroadcast() {
        return false;
      }
      asBroadcastStream(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        dart.as(onListen, dart.functionType(dart.void, [StreamSubscription$(T)]));
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        dart.as(onCancel, dart.functionType(dart.void, [StreamSubscription$(T)]));
        return new (_AsBroadcastStream$(T))(this, dart.as(onListen, __CastType10), dart.as(onCancel, dart.functionType(dart.void, [StreamSubscription])));
      }
      where(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        return new (_WhereStream$(T))(this, test);
      }
      map(convert) {
        dart.as(convert, dart.functionType(dart.dynamic, [T]));
        return new (_MapStream$(T, dart.dynamic))(this, convert);
      }
      asyncMap(convert) {
        dart.as(convert, dart.functionType(dart.dynamic, [T]));
        let controller = null;
        let subscription = null;
        const onListen = (function() {
          let add = dart.bind(controller, 'add');
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = dart.as(controller, _EventSink$(T));
          let addError = dart.bind(eventSink, _addError);
          subscription = this.listen(dart.fn(event => {
            dart.as(event, T);
            let newValue = null;
            try {
              newValue = convert(event);
            } catch (e) {
              let s = dart.stackTrace(e);
              controller.addError(e, s);
              return;
            }

            if (dart.is(newValue, Future)) {
              subscription.pause();
              newValue.then(add, {onError: addError}).whenComplete(dart.bind(subscription, 'resume'));
            } else {
              controller.add(newValue);
            }
          }, dart.void, [T]), {onError: addError, onDone: dart.bind(controller, 'close')});
        }).bind(this);
        dart.fn(onListen, dart.void, []);
        if (dart.notNull(this.isBroadcast)) {
          controller = StreamController.broadcast({onListen: onListen, onCancel: dart.fn(() => {
              subscription.cancel();
            }, dart.void, []), sync: true});
        } else {
          controller = StreamController.new({onListen: onListen, onPause: dart.fn(() => {
              subscription.pause();
            }, dart.void, []), onResume: dart.fn(() => {
              subscription.resume();
            }, dart.void, []), onCancel: dart.fn(() => {
              subscription.cancel();
            }), sync: true});
        }
        return controller.stream;
      }
      asyncExpand(convert) {
        dart.as(convert, dart.functionType(Stream$(), [T]));
        let controller = null;
        let subscription = null;
        const onListen = (function() {
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = dart.as(controller, _EventSink$(T));
          subscription = this.listen(dart.fn(event => {
            dart.as(event, T);
            let newStream = null;
            try {
              newStream = convert(event);
            } catch (e) {
              let s = dart.stackTrace(e);
              controller.addError(e, s);
              return;
            }

            if (newStream != null) {
              subscription.pause();
              controller.addStream(newStream).whenComplete(dart.bind(subscription, 'resume'));
            }
          }, dart.void, [T]), {onError: dart.bind(eventSink, _addError), onDone: dart.bind(controller, 'close')});
        }).bind(this);
        dart.fn(onListen, dart.void, []);
        if (dart.notNull(this.isBroadcast)) {
          controller = StreamController.broadcast({onListen: onListen, onCancel: dart.fn(() => {
              subscription.cancel();
            }, dart.void, []), sync: true});
        } else {
          controller = StreamController.new({onListen: onListen, onPause: dart.fn(() => {
              subscription.pause();
            }, dart.void, []), onResume: dart.fn(() => {
              subscription.resume();
            }, dart.void, []), onCancel: dart.fn(() => {
              subscription.cancel();
            }), sync: true});
        }
        return controller.stream;
      }
      handleError(onError, opts) {
        let test = opts && 'test' in opts ? opts.test : null;
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        return new (_HandleErrorStream$(T))(this, onError, test);
      }
      expand(convert) {
        dart.as(convert, dart.functionType(core.Iterable, [T]));
        return new (_ExpandStream$(T, dart.dynamic))(this, convert);
      }
      pipe(streamConsumer) {
        dart.as(streamConsumer, StreamConsumer$(T));
        return streamConsumer.addStream(this).then(dart.fn(_ => streamConsumer.close(), Future, [dart.dynamic]));
      }
      transform(streamTransformer) {
        dart.as(streamTransformer, StreamTransformer$(T, dart.dynamic));
        return streamTransformer.bind(this);
      }
      reduce(combine) {
        dart.as(combine, dart.functionType(T, [T, T]));
        let result = new (_Future$(T))();
        let seenFirst = false;
        let value = null;
        let subscription = null;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          if (seenFirst) {
            _runUserCode(dart.fn(() => combine(value, element), T, []), dart.fn(newValue => {
              dart.as(newValue, T);
              value = newValue;
            }, dart.dynamic, [T]), dart.as(_cancelAndErrorClosure(subscription, result), __CastType12));
          } else {
            value = element;
            seenFirst = true;
          }
        }, dart.void, [T]), {onError: dart.bind(result, _completeError), onDone: dart.fn(() => {
            if (!seenFirst) {
              try {
                dart.throw(_internal.IterableElementError.noElement());
              } catch (e) {
                let s = dart.stackTrace(e);
                _completeWithErrorCallback(result, e, s);
              }

            } else {
              result[_complete](value);
            }
          }, dart.void, []), cancelOnError: true});
        return result;
      }
      fold(initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, T]));
        let result = new _Future();
        let value = initialValue;
        let subscription = null;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          _runUserCode(dart.fn(() => combine(value, element), dart.dynamic, []), dart.fn(newValue => {
            value = dart.as(newValue, dart.dynamic);
          }), dart.as(_cancelAndErrorClosure(subscription, result), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.fn((e, st) => {
            result[_completeError](e, dart.as(st, core.StackTrace));
          }), onDone: dart.fn(() => {
            result[_complete](value);
          }, dart.void, []), cancelOnError: true});
        return result;
      }
      join(separator) {
        if (separator === void 0) separator = "";
        let result = new (_Future$(core.String))();
        let buffer = new core.StringBuffer();
        let subscription = null;
        let first = true;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          if (!first) {
            buffer.write(separator);
          }
          first = false;
          try {
            buffer.write(element);
          } catch (e) {
            let s = dart.stackTrace(e);
            _cancelAndErrorWithReplacement(subscription, result, e, s);
          }

        }, dart.void, [T]), {onError: dart.fn(e => {
            result[_completeError](e);
          }), onDone: dart.fn(() => {
            result[_complete](dart.toString(buffer));
          }, dart.void, []), cancelOnError: true});
        return result;
      }
      contains(needle) {
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          _runUserCode(dart.fn(() => dart.equals(element, needle), core.bool, []), dart.fn(isMatch => {
            if (dart.notNull(isMatch)) {
              _cancelAndValue(subscription, future, true);
            }
          }, dart.dynamic, [core.bool]), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](false);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [T]));
        let future = new _Future();
        let subscription = null;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          _runUserCode(dart.fn(() => action(element), dart.void, []), dart.fn(_ => {
          }), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](null);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      every(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          _runUserCode(dart.fn(() => test(element), core.bool, []), dart.fn(isMatch => {
            if (!dart.notNull(isMatch)) {
              _cancelAndValue(subscription, future, false);
            }
          }, dart.dynamic, [core.bool]), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](true);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      any(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(dart.fn(element => {
          dart.as(element, T);
          _runUserCode(dart.fn(() => test(element), core.bool, []), dart.fn(isMatch => {
            if (dart.notNull(isMatch)) {
              _cancelAndValue(subscription, future, true);
            }
          }, dart.dynamic, [core.bool]), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](false);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      get length() {
        let future = new (_Future$(core.int))();
        let count = 0;
        this.listen(dart.fn(_ => {
          dart.as(_, T);
          count++;
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](count);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      get isEmpty() {
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(dart.fn(_ => {
          dart.as(_, T);
          _cancelAndValue(subscription, future, false);
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](true);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      toList() {
        let result = dart.list([], T);
        let future = new (_Future$(core.List$(T)))();
        this.listen(dart.fn(data => {
          dart.as(data, T);
          result[dartx.add](data);
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](result);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      toSet() {
        let result = core.Set$(T).new();
        let future = new (_Future$(core.Set$(T)))();
        this.listen(dart.fn(data => {
          dart.as(data, T);
          result.add(data);
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            future[_complete](result);
          }, dart.void, []), cancelOnError: true});
        return future;
      }
      drain(futureValue) {
        if (futureValue === void 0) futureValue = null;
        return this.listen(null, {cancelOnError: true}).asFuture(futureValue);
      }
      take(count) {
        return new (_TakeStream$(T))(this, count);
      }
      takeWhile(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        return new (_TakeWhileStream$(T))(this, test);
      }
      skip(count) {
        return new (_SkipStream$(T))(this, count);
      }
      skipWhile(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        return new (_SkipWhileStream$(T))(this, test);
      }
      distinct(equals) {
        if (equals === void 0) equals = null;
        dart.as(equals, dart.functionType(core.bool, [T, T]));
        return new (_DistinctStream$(T))(this, equals);
      }
      get first() {
        let future = new (_Future$(T))();
        let subscription = null;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          _cancelAndValue(subscription, future, value);
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            try {
              dart.throw(_internal.IterableElementError.noElement());
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          }, dart.void, []), cancelOnError: true});
        return future;
      }
      get last() {
        let future = new (_Future$(T))();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          foundResult = true;
          result = value;
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            try {
              dart.throw(_internal.IterableElementError.noElement());
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          }, dart.void, []), cancelOnError: true});
        return future;
      }
      get single() {
        let future = new (_Future$(T))();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          if (foundResult) {
            try {
              dart.throw(_internal.IterableElementError.tooMany());
            } catch (e) {
              let s = dart.stackTrace(e);
              _cancelAndErrorWithReplacement(subscription, future, e, s);
            }

            return;
          }
          foundResult = true;
          result = value;
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            try {
              dart.throw(_internal.IterableElementError.noElement());
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          }, dart.void, []), cancelOnError: true});
        return future;
      }
      firstWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let defaultValue = opts && 'defaultValue' in opts ? opts.defaultValue : null;
        dart.as(defaultValue, dart.functionType(core.Object, []));
        let future = new _Future();
        let subscription = null;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          _runUserCode(dart.fn(() => test(value), core.bool, []), dart.fn(isMatch => {
            if (dart.notNull(isMatch)) {
              _cancelAndValue(subscription, future, value);
            }
          }, dart.dynamic, [core.bool]), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            if (defaultValue != null) {
              _runUserCode(defaultValue, dart.bind(future, _complete), dart.bind(future, _completeError));
              return;
            }
            try {
              dart.throw(_internal.IterableElementError.noElement());
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          }, dart.void, []), cancelOnError: true});
        return future;
      }
      lastWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let defaultValue = opts && 'defaultValue' in opts ? opts.defaultValue : null;
        dart.as(defaultValue, dart.functionType(core.Object, []));
        let future = new _Future();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          _runUserCode(dart.fn(() => true == test(value), core.bool, []), dart.fn(isMatch => {
            if (dart.notNull(isMatch)) {
              foundResult = true;
              result = value;
            }
          }, dart.dynamic, [core.bool]), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            if (defaultValue != null) {
              _runUserCode(defaultValue, dart.bind(future, _complete), dart.bind(future, _completeError));
              return;
            }
            try {
              dart.throw(_internal.IterableElementError.noElement());
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          }, dart.void, []), cancelOnError: true});
        return future;
      }
      singleWhere(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let future = new (_Future$(T))();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          _runUserCode(dart.fn(() => true == test(value), core.bool, []), dart.fn(isMatch => {
            if (dart.notNull(isMatch)) {
              if (foundResult) {
                try {
                  dart.throw(_internal.IterableElementError.tooMany());
                } catch (e) {
                  let s = dart.stackTrace(e);
                  _cancelAndErrorWithReplacement(subscription, future, e, s);
                }

                return;
              }
              foundResult = true;
              result = value;
            }
          }, dart.dynamic, [core.bool]), dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn(() => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            try {
              dart.throw(_internal.IterableElementError.noElement());
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          }, dart.void, []), cancelOnError: true});
        return future;
      }
      elementAt(index) {
        if (!(typeof index == 'number') || dart.notNull(index) < 0) dart.throw(new core.ArgumentError(index));
        let future = new (_Future$(T))();
        let subscription = null;
        let elementIndex = 0;
        subscription = this.listen(dart.fn(value => {
          dart.as(value, T);
          if (index == elementIndex) {
            _cancelAndValue(subscription, future, value);
            return;
          }
          elementIndex = elementIndex + 1;
        }, dart.void, [T]), {onError: dart.bind(future, _completeError), onDone: dart.fn((() => {
            future[_completeError](core.RangeError.index(index, this, "index", null, elementIndex));
          }).bind(this), dart.void, []), cancelOnError: true});
        return future;
      }
      timeout(timeLimit, opts) {
        let onTimeout = opts && 'onTimeout' in opts ? opts.onTimeout : null;
        dart.as(onTimeout, dart.functionType(dart.void, [EventSink]));
        let controller = null;
        let subscription = null;
        let timer = null;
        let zone = null;
        let timeout2 = null;
        function onData(event) {
          dart.as(event, T);
          timer.cancel();
          controller.add(event);
          timer = zone.createTimer(timeLimit, dart.as(timeout2, __CastType15));
        }
        dart.fn(onData, dart.void, [T]);
        function onError(error, stackTrace) {
          timer.cancel();
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = dart.as(controller, _EventSink$(T));
          eventSink[_addError](error, stackTrace);
          timer = zone.createTimer(timeLimit, dart.as(timeout2, dart.functionType(dart.void, [])));
        }
        dart.fn(onError, dart.void, [dart.dynamic, core.StackTrace]);
        function onDone() {
          timer.cancel();
          controller.close();
        }
        dart.fn(onDone, dart.void, []);
        const onListen = (function() {
          zone = Zone.current;
          if (onTimeout == null) {
            timeout2 = dart.fn(() => {
              controller.addError(new TimeoutException("No stream event", timeLimit), null);
            });
          } else {
            onTimeout = dart.as(zone.registerUnaryCallback(onTimeout), __CastType16);
            let wrapper = new _ControllerEventSinkWrapper(null);
            timeout2 = dart.fn(() => {
              wrapper[_sink] = controller;
              zone.runUnaryGuarded(onTimeout, wrapper);
              wrapper[_sink] = null;
            });
          }
          subscription = this.listen(onData, {onError: onError, onDone: onDone});
          timer = zone.createTimer(timeLimit, dart.as(timeout2, dart.functionType(dart.void, [])));
        }).bind(this);
        dart.fn(onListen, dart.void, []);
        function onCancel() {
          timer.cancel();
          let result = subscription.cancel();
          subscription = null;
          return result;
        }
        dart.fn(onCancel, Future, []);
        controller = dart.notNull(this.isBroadcast) ? new _SyncBroadcastStreamController(onListen, onCancel) : new _SyncStreamController(onListen, dart.fn(() => {
          timer.cancel();
          subscription.pause();
        }, dart.void, []), dart.fn(() => {
          subscription.resume();
          timer = zone.createTimer(timeLimit, dart.as(timeout2, dart.functionType(dart.void, [])));
        }, dart.void, []), onCancel);
        return controller.stream;
      }
    }
    dart.setSignature(Stream, {
      constructors: () => ({
        Stream: [Stream$(T), []],
        fromFuture: [Stream$(T), [Future$(T)]],
        fromIterable: [Stream$(T), [core.Iterable$(T)]],
        periodic: [Stream$(T), [core.Duration], [dart.functionType(T, [core.int])]],
        eventTransformed: [Stream$(T), [Stream$(), dart.functionType(EventSink, [EventSink$(T)])]]
      }),
      methods: () => ({
        asBroadcastStream: [Stream$(T), [], {onListen: dart.functionType(dart.void, [StreamSubscription$(T)]), onCancel: dart.functionType(dart.void, [StreamSubscription$(T)])}],
        where: [Stream$(T), [dart.functionType(core.bool, [T])]],
        map: [Stream$(), [dart.functionType(dart.dynamic, [T])]],
        asyncMap: [Stream$(), [dart.functionType(dart.dynamic, [T])]],
        asyncExpand: [Stream$(), [dart.functionType(Stream$(), [T])]],
        handleError: [Stream$(T), [core.Function], {test: dart.functionType(core.bool, [dart.dynamic])}],
        expand: [Stream$(), [dart.functionType(core.Iterable, [T])]],
        pipe: [Future, [StreamConsumer$(T)]],
        transform: [Stream$(), [StreamTransformer$(T, dart.dynamic)]],
        reduce: [Future$(T), [dart.functionType(T, [T, T])]],
        fold: [Future, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, T])]],
        join: [Future$(core.String), [], [core.String]],
        contains: [Future$(core.bool), [core.Object]],
        forEach: [Future, [dart.functionType(dart.void, [T])]],
        every: [Future$(core.bool), [dart.functionType(core.bool, [T])]],
        any: [Future$(core.bool), [dart.functionType(core.bool, [T])]],
        toList: [Future$(core.List$(T)), []],
        toSet: [Future$(core.Set$(T)), []],
        drain: [Future, [], [dart.dynamic]],
        take: [Stream$(T), [core.int]],
        takeWhile: [Stream$(T), [dart.functionType(core.bool, [T])]],
        skip: [Stream$(T), [core.int]],
        skipWhile: [Stream$(T), [dart.functionType(core.bool, [T])]],
        distinct: [Stream$(T), [], [dart.functionType(core.bool, [T, T])]],
        firstWhere: [Future, [dart.functionType(core.bool, [T])], {defaultValue: dart.functionType(core.Object, [])}],
        lastWhere: [Future, [dart.functionType(core.bool, [T])], {defaultValue: dart.functionType(core.Object, [])}],
        singleWhere: [Future$(T), [dart.functionType(core.bool, [T])]],
        elementAt: [Future$(T), [core.int]],
        timeout: [Stream$(), [core.Duration], {onTimeout: dart.functionType(dart.void, [EventSink])}]
      })
    });
    return Stream;
  });
  let Stream = Stream$();
  const _createSubscription = Symbol('_createSubscription');
  const _onListen = Symbol('_onListen');
  const _StreamImpl$ = dart.generic(function(T) {
    class _StreamImpl extends Stream$(T) {
      _StreamImpl() {
        super.Stream();
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        cancelOnError = core.identical(true, cancelOnError);
        let subscription = this[_createSubscription](onData, onError, onDone, cancelOnError);
        this[_onListen](subscription);
        return dart.as(subscription, StreamSubscription$(T));
      }
      [_createSubscription](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        return new (_BufferingStreamSubscription$(T))(onData, onError, onDone, cancelOnError);
      }
      [_onListen](subscription) {}
    }
    dart.setSignature(_StreamImpl, {
      methods: () => ({
        listen: [StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}],
        [_createSubscription]: [StreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]],
        [_onListen]: [dart.void, [StreamSubscription]]
      })
    });
    return _StreamImpl;
  });
  let _StreamImpl = _StreamImpl$();
  const _controller = Symbol('_controller');
  const _subscribe = Symbol('_subscribe');
  const _ControllerStream$ = dart.generic(function(T) {
    class _ControllerStream extends _StreamImpl$(T) {
      _ControllerStream(controller) {
        this[_controller] = controller;
      }
      [_createSubscription](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        return this[_controller][_subscribe](onData, onError, onDone, cancelOnError);
      }
      get hashCode() {
        return dart.notNull(dart.hashCode(this[_controller])) ^ 892482866;
      }
      ['=='](other) {
        if (dart.notNull(core.identical(this, other))) return true;
        if (!dart.is(other, _ControllerStream$())) return false;
        let otherStream = dart.as(other, _ControllerStream$());
        return core.identical(otherStream[_controller], this[_controller]);
      }
    }
    dart.setSignature(_ControllerStream, {
      constructors: () => ({_ControllerStream: [_ControllerStream$(T), [_StreamControllerLifecycle$(T)]]}),
      methods: () => ({
        [_createSubscription]: [StreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]],
        '==': [core.bool, [core.Object]]
      })
    });
    return _ControllerStream;
  });
  let _ControllerStream = _ControllerStream$();
  const _BroadcastStream$ = dart.generic(function(T) {
    class _BroadcastStream extends _ControllerStream$(T) {
      _BroadcastStream(controller) {
        super._ControllerStream(dart.as(controller, _StreamControllerLifecycle$(T)));
      }
      get isBroadcast() {
        return true;
      }
    }
    dart.setSignature(_BroadcastStream, {
      constructors: () => ({_BroadcastStream: [_BroadcastStream$(T), [_StreamControllerLifecycle]]})
    });
    return _BroadcastStream;
  });
  let _BroadcastStream = _BroadcastStream$();
  const _next = Symbol('_next');
  const _previous = Symbol('_previous');
  class _BroadcastSubscriptionLink extends core.Object {
    _BroadcastSubscriptionLink() {
      this[_next] = null;
      this[_previous] = null;
    }
  }
  const _zone = Symbol('_zone');
  const _state = Symbol('_state');
  const _onData = Symbol('_onData');
  const _onError = Symbol('_onError');
  const _onDone = Symbol('_onDone');
  const _cancelFuture = Symbol('_cancelFuture');
  const _pending = Symbol('_pending');
  const _setPendingEvents = Symbol('_setPendingEvents');
  const _isCanceled = Symbol('_isCanceled');
  const _extractPending = Symbol('_extractPending');
  const _isPaused = Symbol('_isPaused');
  const _isInputPaused = Symbol('_isInputPaused');
  const _inCallback = Symbol('_inCallback');
  const _guardCallback = Symbol('_guardCallback');
  const _onPause = Symbol('_onPause');
  const _decrementPauseCount = Symbol('_decrementPauseCount');
  const _hasPending = Symbol('_hasPending');
  const _mayResumeInput = Symbol('_mayResumeInput');
  const _onResume = Symbol('_onResume');
  const _cancel = Symbol('_cancel');
  const _isClosed = Symbol('_isClosed');
  const _waitsForCancel = Symbol('_waitsForCancel');
  const _canFire = Symbol('_canFire');
  const _cancelOnError = Symbol('_cancelOnError');
  const _onCancel = Symbol('_onCancel');
  const _incrementPauseCount = Symbol('_incrementPauseCount');
  const _sendData = Symbol('_sendData');
  const _addPending = Symbol('_addPending');
  const _sendError = Symbol('_sendError');
  const _sendDone = Symbol('_sendDone');
  const _close = Symbol('_close');
  const _checkState = Symbol('_checkState');
  const _BufferingStreamSubscription$ = dart.generic(function(T) {
    class _BufferingStreamSubscription extends core.Object {
      _BufferingStreamSubscription(onData, onError, onDone, cancelOnError) {
        this[_zone] = Zone.current;
        this[_state] = dart.notNull(cancelOnError) ? _BufferingStreamSubscription$()._STATE_CANCEL_ON_ERROR : 0;
        this[_onData] = null;
        this[_onError] = null;
        this[_onDone] = null;
        this[_cancelFuture] = null;
        this[_pending] = null;
        this.onData(onData);
        this.onError(onError);
        this.onDone(onDone);
      }
      [_setPendingEvents](pendingEvents) {
        dart.assert(this[_pending] == null);
        if (pendingEvents == null) return;
        this[_pending] = pendingEvents;
        if (!dart.notNull(pendingEvents.isEmpty)) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_HAS_PENDING);
          this[_pending].schedule(this);
        }
      }
      [_extractPending]() {
        dart.assert(this[_isCanceled]);
        let events = this[_pending];
        this[_pending] = null;
        return events;
      }
      onData(handleData) {
        dart.as(handleData, dart.functionType(dart.void, [T]));
        if (handleData == null) handleData = dart.as(_nullDataHandler, __CastType18);
        this[_onData] = dart.as(this[_zone].registerUnaryCallback(handleData), _DataHandler$(T));
      }
      onError(handleError) {
        if (handleError == null) handleError = _nullErrorHandler;
        this[_onError] = _registerErrorHandler(handleError, this[_zone]);
      }
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
        if (handleDone == null) handleDone = _nullDoneHandler;
        this[_onDone] = this[_zone].registerCallback(handleDone);
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0) resumeSignal = null;
        if (dart.notNull(this[_isCanceled])) return;
        let wasPaused = this[_isPaused];
        let wasInputPaused = this[_isInputPaused];
        this[_state] = dart.notNull(this[_state]) + dart.notNull(_BufferingStreamSubscription$()._STATE_PAUSE_COUNT) | dart.notNull(_BufferingStreamSubscription$()._STATE_INPUT_PAUSED);
        if (resumeSignal != null) resumeSignal.whenComplete(dart.bind(this, 'resume'));
        if (!dart.notNull(wasPaused) && this[_pending] != null) this[_pending].cancelSchedule();
        if (!dart.notNull(wasInputPaused) && !dart.notNull(this[_inCallback])) this[_guardCallback](dart.bind(this, _onPause));
      }
      resume() {
        if (dart.notNull(this[_isCanceled])) return;
        if (dart.notNull(this[_isPaused])) {
          this[_decrementPauseCount]();
          if (!dart.notNull(this[_isPaused])) {
            if (dart.notNull(this[_hasPending]) && !dart.notNull(this[_pending].isEmpty)) {
              this[_pending].schedule(this);
            } else {
              dart.assert(this[_mayResumeInput]);
              this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_INPUT_PAUSED);
              if (!dart.notNull(this[_inCallback])) this[_guardCallback](dart.bind(this, _onResume));
            }
          }
        }
      }
      cancel() {
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_WAIT_FOR_CANCEL);
        if (dart.notNull(this[_isCanceled])) return this[_cancelFuture];
        this[_cancel]();
        return this[_cancelFuture];
      }
      asFuture(futureValue) {
        if (futureValue === void 0) futureValue = null;
        let result = new (_Future$(T))();
        this[_onDone] = dart.fn(() => {
          result[_complete](futureValue);
        }, dart.void, []);
        this[_onError] = dart.fn(((error, stackTrace) => {
          this.cancel();
          result[_completeError](error, dart.as(stackTrace, core.StackTrace));
        }).bind(this));
        return result;
      }
      get [_isInputPaused]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_INPUT_PAUSED)) != 0;
      }
      get [_isClosed]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_CLOSED)) != 0;
      }
      get [_isCanceled]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_CANCELED)) != 0;
      }
      get [_waitsForCancel]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_WAIT_FOR_CANCEL)) != 0;
      }
      get [_inCallback]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK)) != 0;
      }
      get [_hasPending]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_HAS_PENDING)) != 0;
      }
      get [_isPaused]() {
        return dart.notNull(this[_state]) >= dart.notNull(_BufferingStreamSubscription$()._STATE_PAUSE_COUNT);
      }
      get [_canFire]() {
        return dart.notNull(this[_state]) < dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
      }
      get [_mayResumeInput]() {
        return !dart.notNull(this[_isPaused]) && (this[_pending] == null || dart.notNull(this[_pending].isEmpty));
      }
      get [_cancelOnError]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription$()._STATE_CANCEL_ON_ERROR)) != 0;
      }
      get isPaused() {
        return this[_isPaused];
      }
      [_cancel]() {
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_CANCELED);
        if (dart.notNull(this[_hasPending])) {
          this[_pending].cancelSchedule();
        }
        if (!dart.notNull(this[_inCallback])) this[_pending] = null;
        this[_cancelFuture] = this[_onCancel]();
      }
      [_incrementPauseCount]() {
        this[_state] = dart.notNull(this[_state]) + dart.notNull(_BufferingStreamSubscription$()._STATE_PAUSE_COUNT) | dart.notNull(_BufferingStreamSubscription$()._STATE_INPUT_PAUSED);
      }
      [_decrementPauseCount]() {
        dart.assert(this[_isPaused]);
        this[_state] = dart.notNull(this[_state]) - dart.notNull(_BufferingStreamSubscription$()._STATE_PAUSE_COUNT);
      }
      [_add](data) {
        dart.as(data, T);
        dart.assert(!dart.notNull(this[_isClosed]));
        if (dart.notNull(this[_isCanceled])) return;
        if (dart.notNull(this[_canFire])) {
          this[_sendData](data);
        } else {
          this[_addPending](new _DelayedData(data));
        }
      }
      [_addError](error, stackTrace) {
        if (dart.notNull(this[_isCanceled])) return;
        if (dart.notNull(this[_canFire])) {
          this[_sendError](error, stackTrace);
        } else {
          this[_addPending](new _DelayedError(error, stackTrace));
        }
      }
      [_close]() {
        dart.assert(!dart.notNull(this[_isClosed]));
        if (dart.notNull(this[_isCanceled])) return;
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_CLOSED);
        if (dart.notNull(this[_canFire])) {
          this[_sendDone]();
        } else {
          this[_addPending](dart.const(new _DelayedDone()));
        }
      }
      [_onPause]() {
        dart.assert(this[_isInputPaused]);
      }
      [_onResume]() {
        dart.assert(!dart.notNull(this[_isInputPaused]));
      }
      [_onCancel]() {
        dart.assert(this[_isCanceled]);
        return null;
      }
      [_addPending](event) {
        let pending = dart.as(this[_pending], _StreamImplEvents);
        if (this[_pending] == null) pending = this[_pending] = new _StreamImplEvents();
        pending.add(event);
        if (!dart.notNull(this[_hasPending])) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_HAS_PENDING);
          if (!dart.notNull(this[_isPaused])) {
            this[_pending].schedule(this);
          }
        }
      }
      [_sendData](data) {
        dart.as(data, T);
        dart.assert(!dart.notNull(this[_isCanceled]));
        dart.assert(!dart.notNull(this[_isPaused]));
        dart.assert(!dart.notNull(this[_inCallback]));
        let wasInputPaused = this[_isInputPaused];
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
        this[_zone].runUnaryGuarded(this[_onData], data);
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
        this[_checkState](wasInputPaused);
      }
      [_sendError](error, stackTrace) {
        dart.assert(!dart.notNull(this[_isCanceled]));
        dart.assert(!dart.notNull(this[_isPaused]));
        dart.assert(!dart.notNull(this[_inCallback]));
        let wasInputPaused = this[_isInputPaused];
        const sendError = (function() {
          if (dart.notNull(this[_isCanceled]) && !dart.notNull(this[_waitsForCancel])) return;
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
          if (dart.is(this[_onError], ZoneBinaryCallback)) {
            this[_zone].runBinaryGuarded(dart.as(this[_onError], __CastType20), error, stackTrace);
          } else {
            this[_zone].runUnaryGuarded(dart.as(this[_onError], __CastType23), error);
          }
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
        }).bind(this);
        dart.fn(sendError, dart.void, []);
        if (dart.notNull(this[_cancelOnError])) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_WAIT_FOR_CANCEL);
          this[_cancel]();
          if (dart.is(this[_cancelFuture], Future)) {
            this[_cancelFuture].whenComplete(sendError);
          } else {
            sendError();
          }
        } else {
          sendError();
          this[_checkState](wasInputPaused);
        }
      }
      [_sendDone]() {
        dart.assert(!dart.notNull(this[_isCanceled]));
        dart.assert(!dart.notNull(this[_isPaused]));
        dart.assert(!dart.notNull(this[_inCallback]));
        const sendDone = (function() {
          if (!dart.notNull(this[_waitsForCancel])) return;
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_CANCELED) | dart.notNull(_BufferingStreamSubscription$()._STATE_CLOSED) | dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
          this[_zone].runGuarded(this[_onDone]);
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
        }).bind(this);
        dart.fn(sendDone, dart.void, []);
        this[_cancel]();
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_WAIT_FOR_CANCEL);
        if (dart.is(this[_cancelFuture], Future)) {
          this[_cancelFuture].whenComplete(sendDone);
        } else {
          sendDone();
        }
      }
      [_guardCallback](callback) {
        dart.assert(!dart.notNull(this[_inCallback]));
        let wasInputPaused = this[_isInputPaused];
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
        dart.dcall(callback);
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
        this[_checkState](wasInputPaused);
      }
      [_checkState](wasInputPaused) {
        dart.assert(!dart.notNull(this[_inCallback]));
        if (dart.notNull(this[_hasPending]) && dart.notNull(this[_pending].isEmpty)) {
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_HAS_PENDING);
          if (dart.notNull(this[_isInputPaused]) && dart.notNull(this[_mayResumeInput])) {
            this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_INPUT_PAUSED);
          }
        }
        while (true) {
          if (dart.notNull(this[_isCanceled])) {
            this[_pending] = null;
            return;
          }
          let isInputPaused = this[_isInputPaused];
          if (wasInputPaused == isInputPaused) break;
          this[_state] = dart.notNull(this[_state]) ^ dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
          if (dart.notNull(isInputPaused)) {
            this[_onPause]();
          } else {
            this[_onResume]();
          }
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription$()._STATE_IN_CALLBACK);
          wasInputPaused = isInputPaused;
        }
        if (dart.notNull(this[_hasPending]) && !dart.notNull(this[_isPaused])) {
          this[_pending].schedule(this);
        }
      }
    }
    _BufferingStreamSubscription[dart.implements] = () => [StreamSubscription$(T), _EventSink$(T), _EventDispatch$(T)];
    dart.setSignature(_BufferingStreamSubscription, {
      constructors: () => ({_BufferingStreamSubscription: [_BufferingStreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]]}),
      methods: () => ({
        [_setPendingEvents]: [dart.void, [_PendingEvents]],
        [_extractPending]: [_PendingEvents, []],
        onData: [dart.void, [dart.functionType(dart.void, [T])]],
        onError: [dart.void, [core.Function]],
        onDone: [dart.void, [dart.functionType(dart.void, [])]],
        pause: [dart.void, [], [Future]],
        resume: [dart.void, []],
        cancel: [Future, []],
        asFuture: [Future, [], [dart.dynamic]],
        [_cancel]: [dart.void, []],
        [_incrementPauseCount]: [dart.void, []],
        [_decrementPauseCount]: [dart.void, []],
        [_add]: [dart.void, [T]],
        [_addError]: [dart.void, [core.Object, core.StackTrace]],
        [_close]: [dart.void, []],
        [_onPause]: [dart.void, []],
        [_onResume]: [dart.void, []],
        [_onCancel]: [Future, []],
        [_addPending]: [dart.void, [_DelayedEvent]],
        [_sendData]: [dart.void, [T]],
        [_sendError]: [dart.void, [core.Object, core.StackTrace]],
        [_sendDone]: [dart.void, []],
        [_guardCallback]: [dart.void, [dart.dynamic]],
        [_checkState]: [dart.void, [core.bool]]
      })
    });
    _BufferingStreamSubscription._STATE_CANCEL_ON_ERROR = 1;
    _BufferingStreamSubscription._STATE_CLOSED = 2;
    _BufferingStreamSubscription._STATE_INPUT_PAUSED = 4;
    _BufferingStreamSubscription._STATE_CANCELED = 8;
    _BufferingStreamSubscription._STATE_WAIT_FOR_CANCEL = 16;
    _BufferingStreamSubscription._STATE_IN_CALLBACK = 32;
    _BufferingStreamSubscription._STATE_HAS_PENDING = 64;
    _BufferingStreamSubscription._STATE_PAUSE_COUNT = 128;
    _BufferingStreamSubscription._STATE_PAUSE_COUNT_SHIFT = 7;
    return _BufferingStreamSubscription;
  });
  let _BufferingStreamSubscription = _BufferingStreamSubscription$();
  const _recordCancel = Symbol('_recordCancel');
  const _recordPause = Symbol('_recordPause');
  const _recordResume = Symbol('_recordResume');
  const _ControllerSubscription$ = dart.generic(function(T) {
    class _ControllerSubscription extends _BufferingStreamSubscription$(T) {
      _ControllerSubscription(controller, onData, onError, onDone, cancelOnError) {
        this[_controller] = controller;
        super._BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
      }
      [_onCancel]() {
        return this[_controller][_recordCancel](this);
      }
      [_onPause]() {
        this[_controller][_recordPause](this);
      }
      [_onResume]() {
        this[_controller][_recordResume](this);
      }
    }
    dart.setSignature(_ControllerSubscription, {
      constructors: () => ({_ControllerSubscription: [_ControllerSubscription$(T), [_StreamControllerLifecycle$(T), dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]]})
    });
    return _ControllerSubscription;
  });
  let _ControllerSubscription = _ControllerSubscription$();
  const _eventState = Symbol('_eventState');
  const _expectsEvent = Symbol('_expectsEvent');
  const _toggleEventId = Symbol('_toggleEventId');
  const _isFiring = Symbol('_isFiring');
  const _setRemoveAfterFiring = Symbol('_setRemoveAfterFiring');
  const _removeAfterFiring = Symbol('_removeAfterFiring');
  const _BroadcastSubscription$ = dart.generic(function(T) {
    class _BroadcastSubscription extends _ControllerSubscription$(T) {
      _BroadcastSubscription(controller, onData, onError, onDone, cancelOnError) {
        this[_eventState] = null;
        this[_next] = null;
        this[_previous] = null;
        super._ControllerSubscription(dart.as(controller, _StreamControllerLifecycle$(T)), onData, onError, onDone, cancelOnError);
        this[_next] = this[_previous] = this;
      }
      [_expectsEvent](eventId) {
        return (dart.notNull(this[_eventState]) & dart.notNull(_BroadcastSubscription$()._STATE_EVENT_ID)) == eventId;
      }
      [_toggleEventId]() {
        this[_eventState] = dart.notNull(this[_eventState]) ^ dart.notNull(_BroadcastSubscription$()._STATE_EVENT_ID);
      }
      get [_isFiring]() {
        return (dart.notNull(this[_eventState]) & dart.notNull(_BroadcastSubscription$()._STATE_FIRING)) != 0;
      }
      [_setRemoveAfterFiring]() {
        dart.assert(this[_isFiring]);
        this[_eventState] = dart.notNull(this[_eventState]) | dart.notNull(_BroadcastSubscription$()._STATE_REMOVE_AFTER_FIRING);
      }
      get [_removeAfterFiring]() {
        return (dart.notNull(this[_eventState]) & dart.notNull(_BroadcastSubscription$()._STATE_REMOVE_AFTER_FIRING)) != 0;
      }
      [_onPause]() {}
      [_onResume]() {}
    }
    _BroadcastSubscription[dart.implements] = () => [_BroadcastSubscriptionLink];
    dart.setSignature(_BroadcastSubscription, {
      constructors: () => ({_BroadcastSubscription: [_BroadcastSubscription$(T), [_StreamControllerLifecycle, dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]]}),
      methods: () => ({
        [_expectsEvent]: [core.bool, [core.int]],
        [_toggleEventId]: [dart.void, []],
        [_setRemoveAfterFiring]: [dart.void, []]
      })
    });
    _BroadcastSubscription._STATE_EVENT_ID = 1;
    _BroadcastSubscription._STATE_FIRING = 2;
    _BroadcastSubscription._STATE_REMOVE_AFTER_FIRING = 4;
    return _BroadcastSubscription;
  });
  let _BroadcastSubscription = _BroadcastSubscription$();
  const _addStreamState = Symbol('_addStreamState');
  const _doneFuture = Symbol('_doneFuture');
  const _isEmpty = Symbol('_isEmpty');
  const _hasOneListener = Symbol('_hasOneListener');
  const _isAddingStream = Symbol('_isAddingStream');
  const _mayAddEvent = Symbol('_mayAddEvent');
  const _ensureDoneFuture = Symbol('_ensureDoneFuture');
  const _addListener = Symbol('_addListener');
  const _removeListener = Symbol('_removeListener');
  const _callOnCancel = Symbol('_callOnCancel');
  const _addEventError = Symbol('_addEventError');
  const _forEachListener = Symbol('_forEachListener');
  const _mayComplete = Symbol('_mayComplete');
  const _asyncComplete = Symbol('_asyncComplete');
  const _BroadcastStreamController$ = dart.generic(function(T) {
    class _BroadcastStreamController extends core.Object {
      _BroadcastStreamController(onListen, onCancel) {
        this[_onListen] = onListen;
        this[_onCancel] = onCancel;
        this[_state] = _BroadcastStreamController$()._STATE_INITIAL;
        this[_next] = null;
        this[_previous] = null;
        this[_addStreamState] = null;
        this[_doneFuture] = null;
        this[_next] = this[_previous] = this;
      }
      get stream() {
        return new (_BroadcastStream$(T))(this);
      }
      get sink() {
        return new (_StreamSinkWrapper$(T))(this);
      }
      get isClosed() {
        return (dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController$()._STATE_CLOSED)) != 0;
      }
      get isPaused() {
        return false;
      }
      get hasListener() {
        return !dart.notNull(this[_isEmpty]);
      }
      get [_hasOneListener]() {
        dart.assert(!dart.notNull(this[_isEmpty]));
        return core.identical(this[_next][_next], this);
      }
      get [_isFiring]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController$()._STATE_FIRING)) != 0;
      }
      get [_isAddingStream]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController$()._STATE_ADDSTREAM)) != 0;
      }
      get [_mayAddEvent]() {
        return dart.notNull(this[_state]) < dart.notNull(_BroadcastStreamController$()._STATE_CLOSED);
      }
      [_ensureDoneFuture]() {
        if (this[_doneFuture] != null) return this[_doneFuture];
        return this[_doneFuture] = new _Future();
      }
      get [_isEmpty]() {
        return core.identical(this[_next], this);
      }
      [_addListener](subscription) {
        dart.as(subscription, _BroadcastSubscription$(T));
        dart.assert(core.identical(subscription[_next], subscription));
        subscription[_previous] = this[_previous];
        subscription[_next] = this;
        this[_previous][_next] = subscription;
        this[_previous] = subscription;
        subscription[_eventState] = dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController$()._STATE_EVENT_ID);
      }
      [_removeListener](subscription) {
        dart.as(subscription, _BroadcastSubscription$(T));
        dart.assert(core.identical(subscription[_controller], this));
        dart.assert(!dart.notNull(core.identical(subscription[_next], subscription)));
        let previous = subscription[_previous];
        let next = subscription[_next];
        previous[_next] = next;
        next[_previous] = previous;
        subscription[_next] = subscription[_previous] = subscription;
      }
      [_subscribe](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        if (dart.notNull(this.isClosed)) {
          if (onDone == null) onDone = _nullDoneHandler;
          return new (_DoneStreamSubscription$(T))(onDone);
        }
        let subscription = new (_BroadcastSubscription$(T))(this, onData, onError, onDone, cancelOnError);
        this[_addListener](dart.as(subscription, _BroadcastSubscription$(T)));
        if (dart.notNull(core.identical(this[_next], this[_previous]))) {
          _runGuarded(this[_onListen]);
        }
        return dart.as(subscription, StreamSubscription$(T));
      }
      [_recordCancel](sub) {
        dart.as(sub, StreamSubscription$(T));
        let subscription = dart.as(sub, _BroadcastSubscription$(T));
        if (dart.notNull(core.identical(subscription[_next], subscription))) return null;
        dart.assert(!dart.notNull(core.identical(subscription[_next], subscription)));
        if (dart.notNull(subscription[_isFiring])) {
          subscription[_setRemoveAfterFiring]();
        } else {
          dart.assert(!dart.notNull(core.identical(subscription[_next], subscription)));
          this[_removeListener](subscription);
          if (!dart.notNull(this[_isFiring]) && dart.notNull(this[_isEmpty])) {
            this[_callOnCancel]();
          }
        }
        return null;
      }
      [_recordPause](subscription) {
        dart.as(subscription, StreamSubscription$(T));
      }
      [_recordResume](subscription) {
        dart.as(subscription, StreamSubscription$(T));
      }
      [_addEventError]() {
        if (dart.notNull(this.isClosed)) {
          return new core.StateError("Cannot add new events after calling close");
        }
        dart.assert(this[_isAddingStream]);
        return new core.StateError("Cannot add new events while doing an addStream");
      }
      add(data) {
        dart.as(data, T);
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_addEventError]());
        this[_sendData](data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_addEventError]());
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement != null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this[_sendError](error, stackTrace);
      }
      close() {
        if (dart.notNull(this.isClosed)) {
          dart.assert(this[_doneFuture] != null);
          return this[_doneFuture];
        }
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_addEventError]());
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController$()._STATE_CLOSED);
        let doneFuture = this[_ensureDoneFuture]();
        this[_sendDone]();
        return doneFuture;
      }
      get done() {
        return this[_ensureDoneFuture]();
      }
      addStream(stream, opts) {
        dart.as(stream, Stream$(T));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : true;
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_addEventError]());
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController$()._STATE_ADDSTREAM);
        this[_addStreamState] = new (_AddStreamState$(T))(this, stream, cancelOnError);
        return this[_addStreamState].addStreamFuture;
      }
      [_add](data) {
        dart.as(data, T);
        this[_sendData](data);
      }
      [_addError](error, stackTrace) {
        this[_sendError](error, stackTrace);
      }
      [_close]() {
        dart.assert(this[_isAddingStream]);
        let addState = this[_addStreamState];
        this[_addStreamState] = null;
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BroadcastStreamController$()._STATE_ADDSTREAM);
        addState.complete();
      }
      [_forEachListener](action) {
        dart.as(action, dart.functionType(dart.void, [_BufferingStreamSubscription$(T)]));
        if (dart.notNull(this[_isFiring])) {
          dart.throw(new core.StateError("Cannot fire new event. Controller is already firing an event"));
        }
        if (dart.notNull(this[_isEmpty])) return;
        let id = dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController$()._STATE_EVENT_ID);
        this[_state] = dart.notNull(this[_state]) ^ (dart.notNull(_BroadcastStreamController$()._STATE_EVENT_ID) | dart.notNull(_BroadcastStreamController$()._STATE_FIRING));
        let link = this[_next];
        while (!dart.notNull(core.identical(link, this))) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          if (dart.notNull(subscription[_expectsEvent](id))) {
            subscription[_eventState] = dart.notNull(subscription[_eventState]) | dart.notNull(_BroadcastSubscription._STATE_FIRING);
            action(subscription);
            subscription[_toggleEventId]();
            link = subscription[_next];
            if (dart.notNull(subscription[_removeAfterFiring])) {
              this[_removeListener](subscription);
            }
            subscription[_eventState] = dart.notNull(subscription[_eventState]) & ~dart.notNull(_BroadcastSubscription._STATE_FIRING);
          } else {
            link = subscription[_next];
          }
        }
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BroadcastStreamController$()._STATE_FIRING);
        if (dart.notNull(this[_isEmpty])) {
          this[_callOnCancel]();
        }
      }
      [_callOnCancel]() {
        dart.assert(this[_isEmpty]);
        if (dart.notNull(this.isClosed) && dart.notNull(this[_doneFuture][_mayComplete])) {
          this[_doneFuture][_asyncComplete](null);
        }
        _runGuarded(this[_onCancel]);
      }
    }
    _BroadcastStreamController[dart.implements] = () => [StreamController$(T), _StreamControllerLifecycle$(T), _BroadcastSubscriptionLink, _EventSink$(T), _EventDispatch$(T)];
    dart.setSignature(_BroadcastStreamController, {
      constructors: () => ({_BroadcastStreamController: [_BroadcastStreamController$(T), [_NotificationHandler, _NotificationHandler]]}),
      methods: () => ({
        [_ensureDoneFuture]: [_Future, []],
        [_addListener]: [dart.void, [_BroadcastSubscription$(T)]],
        [_removeListener]: [dart.void, [_BroadcastSubscription$(T)]],
        [_subscribe]: [StreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]],
        [_recordCancel]: [Future, [StreamSubscription$(T)]],
        [_recordPause]: [dart.void, [StreamSubscription$(T)]],
        [_recordResume]: [dart.void, [StreamSubscription$(T)]],
        [_addEventError]: [core.Error, []],
        add: [dart.void, [T]],
        addError: [dart.void, [core.Object], [core.StackTrace]],
        close: [Future, []],
        addStream: [Future, [Stream$(T)], {cancelOnError: core.bool}],
        [_add]: [dart.void, [T]],
        [_addError]: [dart.void, [core.Object, core.StackTrace]],
        [_close]: [dart.void, []],
        [_forEachListener]: [dart.void, [dart.functionType(dart.void, [_BufferingStreamSubscription$(T)])]],
        [_callOnCancel]: [dart.void, []]
      })
    });
    _BroadcastStreamController._STATE_INITIAL = 0;
    _BroadcastStreamController._STATE_EVENT_ID = 1;
    _BroadcastStreamController._STATE_FIRING = 2;
    _BroadcastStreamController._STATE_CLOSED = 4;
    _BroadcastStreamController._STATE_ADDSTREAM = 8;
    return _BroadcastStreamController;
  });
  let _BroadcastStreamController = _BroadcastStreamController$();
  const _SyncBroadcastStreamController$ = dart.generic(function(T) {
    class _SyncBroadcastStreamController extends _BroadcastStreamController$(T) {
      _SyncBroadcastStreamController(onListen, onCancel) {
        super._BroadcastStreamController(onListen, onCancel);
      }
      [_sendData](data) {
        dart.as(data, T);
        if (dart.notNull(this[_isEmpty])) return;
        if (dart.notNull(this[_hasOneListener])) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController._STATE_FIRING);
          let subscription = dart.as(this[_next], _BroadcastSubscription);
          subscription[_add](data);
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BroadcastStreamController._STATE_FIRING);
          if (dart.notNull(this[_isEmpty])) {
            this[_callOnCancel]();
          }
          return;
        }
        this[_forEachListener](dart.fn(subscription => {
          dart.as(subscription, _BufferingStreamSubscription$(T));
          subscription[_add](data);
        }, dart.void, [_BufferingStreamSubscription$(T)]));
      }
      [_sendError](error, stackTrace) {
        if (dart.notNull(this[_isEmpty])) return;
        this[_forEachListener](dart.fn(subscription => {
          dart.as(subscription, _BufferingStreamSubscription$(T));
          subscription[_addError](error, stackTrace);
        }, dart.void, [_BufferingStreamSubscription$(T)]));
      }
      [_sendDone]() {
        if (!dart.notNull(this[_isEmpty])) {
          this[_forEachListener](dart.fn(subscription => {
            dart.as(subscription, _BroadcastSubscription$(T));
            subscription[_close]();
          }, dart.void, [_BroadcastSubscription$(T)]));
        } else {
          dart.assert(this[_doneFuture] != null);
          dart.assert(this[_doneFuture][_mayComplete]);
          this[_doneFuture][_asyncComplete](null);
        }
      }
    }
    dart.setSignature(_SyncBroadcastStreamController, {
      constructors: () => ({_SyncBroadcastStreamController: [_SyncBroadcastStreamController$(T), [dart.functionType(dart.void, []), dart.functionType(dart.void, [])]]}),
      methods: () => ({
        [_sendData]: [dart.void, [T]],
        [_sendError]: [dart.void, [core.Object, core.StackTrace]],
        [_sendDone]: [dart.void, []]
      })
    });
    return _SyncBroadcastStreamController;
  });
  let _SyncBroadcastStreamController = _SyncBroadcastStreamController$();
  const _AsyncBroadcastStreamController$ = dart.generic(function(T) {
    class _AsyncBroadcastStreamController extends _BroadcastStreamController$(T) {
      _AsyncBroadcastStreamController(onListen, onCancel) {
        super._BroadcastStreamController(onListen, onCancel);
      }
      [_sendData](data) {
        dart.as(data, T);
        for (let link = this[_next]; !dart.notNull(core.identical(link, this)); link = link[_next]) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          subscription[_addPending](new _DelayedData(data));
        }
      }
      [_sendError](error, stackTrace) {
        for (let link = this[_next]; !dart.notNull(core.identical(link, this)); link = link[_next]) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          subscription[_addPending](new _DelayedError(error, stackTrace));
        }
      }
      [_sendDone]() {
        if (!dart.notNull(this[_isEmpty])) {
          for (let link = this[_next]; !dart.notNull(core.identical(link, this)); link = link[_next]) {
            let subscription = dart.as(link, _BroadcastSubscription$(T));
            subscription[_addPending](dart.const(new _DelayedDone()));
          }
        } else {
          dart.assert(this[_doneFuture] != null);
          dart.assert(this[_doneFuture][_mayComplete]);
          this[_doneFuture][_asyncComplete](null);
        }
      }
    }
    dart.setSignature(_AsyncBroadcastStreamController, {
      constructors: () => ({_AsyncBroadcastStreamController: [_AsyncBroadcastStreamController$(T), [dart.functionType(dart.void, []), dart.functionType(dart.void, [])]]}),
      methods: () => ({
        [_sendData]: [dart.void, [T]],
        [_sendError]: [dart.void, [core.Object, core.StackTrace]],
        [_sendDone]: [dart.void, []]
      })
    });
    return _AsyncBroadcastStreamController;
  });
  let _AsyncBroadcastStreamController = _AsyncBroadcastStreamController$();
  const _addPendingEvent = Symbol('_addPendingEvent');
  const _AsBroadcastStreamController$ = dart.generic(function(T) {
    class _AsBroadcastStreamController extends _SyncBroadcastStreamController$(T) {
      _AsBroadcastStreamController(onListen, onCancel) {
        this[_pending] = null;
        super._SyncBroadcastStreamController(onListen, onCancel);
      }
      get [_hasPending]() {
        return this[_pending] != null && !dart.notNull(this[_pending].isEmpty);
      }
      [_addPendingEvent](event) {
        if (this[_pending] == null) {
          this[_pending] = new _StreamImplEvents();
        }
        this[_pending].add(event);
      }
      add(data) {
        dart.as(data, T);
        if (!dart.notNull(this.isClosed) && dart.notNull(this[_isFiring])) {
          this[_addPendingEvent](new (_DelayedData$(T))(data));
          return;
        }
        super.add(data);
        while (dart.notNull(this[_hasPending])) {
          this[_pending].handleNext(this);
        }
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        if (!dart.notNull(this.isClosed) && dart.notNull(this[_isFiring])) {
          this[_addPendingEvent](new _DelayedError(error, stackTrace));
          return;
        }
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_addEventError]());
        this[_sendError](error, stackTrace);
        while (dart.notNull(this[_hasPending])) {
          this[_pending].handleNext(this);
        }
      }
      close() {
        if (!dart.notNull(this.isClosed) && dart.notNull(this[_isFiring])) {
          this[_addPendingEvent](dart.const(new _DelayedDone()));
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController._STATE_CLOSED);
          return super.done;
        }
        let result = super.close();
        dart.assert(!dart.notNull(this[_hasPending]));
        return result;
      }
      [_callOnCancel]() {
        if (dart.notNull(this[_hasPending])) {
          this[_pending].clear();
          this[_pending] = null;
        }
        super[_callOnCancel]();
      }
    }
    _AsBroadcastStreamController[dart.implements] = () => [_EventDispatch$(T)];
    dart.setSignature(_AsBroadcastStreamController, {
      constructors: () => ({_AsBroadcastStreamController: [_AsBroadcastStreamController$(T), [dart.functionType(dart.void, []), dart.functionType(dart.void, [])]]}),
      methods: () => ({
        [_addPendingEvent]: [dart.void, [_DelayedEvent]],
        add: [dart.void, [T]]
      })
    });
    return _AsBroadcastStreamController;
  });
  let _AsBroadcastStreamController = _AsBroadcastStreamController$();
  const _pauseCount = Symbol('_pauseCount');
  const _resume = Symbol('_resume');
  const _DoneSubscription$ = dart.generic(function(T) {
    class _DoneSubscription extends core.Object {
      _DoneSubscription() {
        this[_pauseCount] = 0;
      }
      onData(handleData) {
        dart.as(handleData, dart.functionType(dart.void, [T]));
      }
      onError(handleError) {}
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0) resumeSignal = null;
        if (resumeSignal != null) resumeSignal.then(dart.bind(this, _resume));
        this[_pauseCount] = dart.notNull(this[_pauseCount]) + 1;
      }
      resume() {
        this[_resume](null);
      }
      [_resume](_) {
        if (dart.notNull(this[_pauseCount]) > 0) {
          this[_pauseCount] = dart.notNull(this[_pauseCount]) - 1;
        }
      }
      cancel() {
        return new _Future.immediate(null);
      }
      get isPaused() {
        return dart.notNull(this[_pauseCount]) > 0;
      }
      asFuture(value) {
        if (value === void 0) value = null;
        return new _Future();
      }
    }
    _DoneSubscription[dart.implements] = () => [StreamSubscription$(T)];
    dart.setSignature(_DoneSubscription, {
      methods: () => ({
        onData: [dart.void, [dart.functionType(dart.void, [T])]],
        onError: [dart.void, [core.Function]],
        onDone: [dart.void, [dart.functionType(dart.void, [])]],
        pause: [dart.void, [], [Future]],
        resume: [dart.void, []],
        [_resume]: [dart.void, [dart.dynamic]],
        cancel: [Future, []],
        asFuture: [Future, [], [core.Object]]
      })
    });
    return _DoneSubscription;
  });
  let _DoneSubscription = _DoneSubscription$();
  class DeferredLibrary extends core.Object {
    DeferredLibrary(libraryName, opts) {
      let uri = opts && 'uri' in opts ? opts.uri : null;
      this.libraryName = libraryName;
      this.uri = uri;
    }
    load() {
      dart.throw('DeferredLibrary not supported. ' + 'please use the `import "lib.dart" deferred as lib` syntax.');
    }
  }
  dart.setSignature(DeferredLibrary, {
    constructors: () => ({DeferredLibrary: [DeferredLibrary, [core.String], {uri: core.String}]}),
    methods: () => ({load: [Future$(core.Null), []]})
  });
  DeferredLibrary[dart.metadata] = () => [dart.const(new core.Deprecated("Dart sdk v. 1.8"))];
  const _s = Symbol('_s');
  class DeferredLoadException extends core.Object {
    DeferredLoadException(s) {
      this[_s] = s;
    }
    toString() {
      return `DeferredLoadException: '${this[_s]}'`;
    }
  }
  DeferredLoadException[dart.implements] = () => [core.Exception];
  dart.setSignature(DeferredLoadException, {
    constructors: () => ({DeferredLoadException: [DeferredLoadException, [core.String]]})
  });
  const _completeWithValue = Symbol('_completeWithValue');
  const Future$ = dart.generic(function(T) {
    class Future extends core.Object {
      static new(computation) {
        let result = new (_Future$(T))();
        Timer.run(dart.fn(() => {
          try {
            result[_complete](computation());
          } catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }

        }, dart.void, []));
        return dart.as(result, Future$(T));
      }
      static microtask(computation) {
        let result = new (_Future$(T))();
        scheduleMicrotask(dart.fn(() => {
          try {
            result[_complete](computation());
          } catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }

        }, dart.void, []));
        return dart.as(result, Future$(T));
      }
      static sync(computation) {
        try {
          let result = computation();
          return Future$(T).value(result);
        } catch (error) {
          let stackTrace = dart.stackTrace(error);
          return Future$(T).error(error, stackTrace);
        }

      }
      static value(value) {
        if (value === void 0) value = null;
        return new (_Future$(T)).immediate(value);
      }
      static error(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(core.identical(Zone.current, _ROOT_ZONE))) {
          let replacement = Zone.current.errorCallback(error, stackTrace);
          if (replacement != null) {
            error = _nonNullError(replacement.error);
            stackTrace = replacement.stackTrace;
          }
        }
        return new (_Future$(T)).immediateError(error, stackTrace);
      }
      static delayed(duration, computation) {
        if (computation === void 0) computation = null;
        let result = new (_Future$(T))();
        Timer.new(duration, dart.fn(() => {
          try {
            result[_complete](computation == null ? null : computation());
          } catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }

        }, dart.void, []));
        return dart.as(result, Future$(T));
      }
      static wait(futures, opts) {
        let eagerError = opts && 'eagerError' in opts ? opts.eagerError : false;
        let cleanUp = opts && 'cleanUp' in opts ? opts.cleanUp : null;
        dart.as(cleanUp, dart.functionType(dart.void, [dart.dynamic]));
        let result = new (_Future$(core.List))();
        let values = null;
        let remaining = 0;
        let error = null;
        let stackTrace = null;
        function handleError(theError, theStackTrace) {
          remaining--;
          if (values != null) {
            if (cleanUp != null) {
              for (let value2 of values) {
                if (value2 != null) {
                  Future$().sync(dart.fn(() => {
                    cleanUp(value2);
                  }));
                }
              }
            }
            values = null;
            if (remaining == 0 || dart.notNull(eagerError)) {
              result[_completeError](theError, dart.as(theStackTrace, core.StackTrace));
            } else {
              error = theError;
              stackTrace = dart.as(theStackTrace, core.StackTrace);
            }
          } else if (remaining == 0 && !dart.notNull(eagerError)) {
            result[_completeError](error, stackTrace);
          }
        }
        dart.fn(handleError, dart.void, [dart.dynamic, dart.dynamic]);
        for (let future of futures) {
          let pos = remaining++;
          future.then(dart.fn(value => {
            remaining--;
            if (values != null) {
              values[dartx.set](pos, dart.as(value, dart.dynamic));
              if (remaining == 0) {
                result[_completeWithValue](values);
              }
            } else {
              if (cleanUp != null && value != null) {
                Future$().sync(dart.fn(() => {
                  cleanUp(dart.as(value, dart.dynamic));
                }));
              }
              if (remaining == 0 && !dart.notNull(eagerError)) {
                result[_completeError](error, stackTrace);
              }
            }
          }, dart.dynamic, [core.Object]), {onError: handleError});
        }
        if (remaining == 0) {
          return Future$(core.List).value(dart.const([]));
        }
        values = core.List.new(remaining);
        return result;
      }
      static forEach(input, f) {
        dart.as(f, dart.functionType(dart.dynamic, [dart.dynamic]));
        let iterator = input[dartx.iterator];
        return Future$().doWhile(dart.fn(() => {
          if (!dart.notNull(iterator.moveNext())) return false;
          return Future$().sync(dart.fn(() => dart.dcall(f, iterator.current))).then(dart.fn(_ => true, core.bool, [dart.dynamic]));
        }));
      }
      static doWhile(f) {
        dart.as(f, dart.functionType(dart.dynamic, []));
        let doneSignal = new _Future();
        let nextIteration = null;
        nextIteration = Zone.current.bindUnaryCallback(dart.fn(keepGoing => {
          if (dart.notNull(keepGoing)) {
            Future$().sync(f).then(dart.as(nextIteration, __CastType2), {onError: dart.bind(doneSignal, _completeError)});
          } else {
            doneSignal[_complete](null);
          }
        }, dart.dynamic, [core.bool]), {runGuarded: true});
        dart.dcall(nextIteration, true);
        return doneSignal;
      }
    }
    dart.setSignature(Future, {
      constructors: () => ({
        new: [Future$(T), [dart.functionType(dart.dynamic, [])]],
        microtask: [Future$(T), [dart.functionType(dart.dynamic, [])]],
        sync: [Future$(T), [dart.functionType(dart.dynamic, [])]],
        value: [Future$(T), [], [dart.dynamic]],
        error: [Future$(T), [core.Object], [core.StackTrace]],
        delayed: [Future$(T), [core.Duration], [dart.functionType(T, [])]]
      }),
      statics: () => ({
        wait: [Future$(core.List), [core.Iterable$(Future$())], {eagerError: core.bool, cleanUp: dart.functionType(dart.void, [dart.dynamic])}],
        forEach: [Future$(), [core.Iterable, dart.functionType(dart.dynamic, [dart.dynamic])]],
        doWhile: [Future$(), [dart.functionType(dart.dynamic, [])]]
      }),
      names: ['wait', 'forEach', 'doWhile']
    });
    dart.defineLazyProperties(Future, {
      get _nullFuture() {
        return new _Future.immediate(null);
      }
    });
    return Future;
  });
  let Future = Future$();
  class TimeoutException extends core.Object {
    TimeoutException(message, duration) {
      if (duration === void 0) duration = null;
      this.message = message;
      this.duration = duration;
    }
    toString() {
      let result = "TimeoutException";
      if (this.duration != null) result = `TimeoutException after ${this.duration}`;
      if (this.message != null) result = `${result}: ${this.message}`;
      return result;
    }
  }
  TimeoutException[dart.implements] = () => [core.Exception];
  dart.setSignature(TimeoutException, {
    constructors: () => ({TimeoutException: [TimeoutException, [core.String], [core.Duration]]})
  });
  const Completer$ = dart.generic(function(T) {
    class Completer extends core.Object {
      static new() {
        return new (_AsyncCompleter$(T))();
      }
      static sync() {
        return new (_SyncCompleter$(T))();
      }
    }
    dart.setSignature(Completer, {
      constructors: () => ({
        new: [Completer$(T), []],
        sync: [Completer$(T), []]
      })
    });
    return Completer;
  });
  let Completer = Completer$();
  function _completeWithErrorCallback(result, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, dart.as(stackTrace, core.StackTrace));
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    result[_completeError](error, dart.as(stackTrace, core.StackTrace));
  }
  dart.fn(_completeWithErrorCallback, () => dart.definiteFunctionType(dart.void, [_Future, dart.dynamic, dart.dynamic]));
  function _nonNullError(error) {
    return error != null ? error : new core.NullThrownError();
  }
  dart.fn(_nonNullError, core.Object, [core.Object]);
  const __CastType2 = dart.typedef('__CastType2', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  const _FutureOnValue$ = dart.generic(function(T) {
    const _FutureOnValue = dart.typedef('_FutureOnValue', () => dart.functionType(dart.dynamic, [T]));
    return _FutureOnValue;
  });
  let _FutureOnValue = _FutureOnValue$();
  const _FutureErrorTest = dart.typedef('_FutureErrorTest', () => dart.functionType(core.bool, [dart.dynamic]));
  const _FutureAction = dart.typedef('_FutureAction', () => dart.functionType(dart.dynamic, []));
  const _Completer$ = dart.generic(function(T) {
    class _Completer extends core.Object {
      _Completer() {
        this.future = new (_Future$(T))();
      }
      completeError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(this.future[_mayComplete])) dart.throw(new core.StateError("Future already completed"));
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement != null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this[_completeError](error, stackTrace);
      }
      get isCompleted() {
        return !dart.notNull(this.future[_mayComplete]);
      }
    }
    _Completer[dart.implements] = () => [Completer$(T)];
    dart.setSignature(_Completer, {
      methods: () => ({completeError: [dart.void, [core.Object], [core.StackTrace]]})
    });
    return _Completer;
  });
  let _Completer = _Completer$();
  const _asyncCompleteError = Symbol('_asyncCompleteError');
  const _AsyncCompleter$ = dart.generic(function(T) {
    class _AsyncCompleter extends _Completer$(T) {
      _AsyncCompleter() {
        super._Completer();
      }
      complete(value) {
        if (value === void 0) value = null;
        if (!dart.notNull(this.future[_mayComplete])) dart.throw(new core.StateError("Future already completed"));
        this.future[_asyncComplete](value);
      }
      [_completeError](error, stackTrace) {
        this.future[_asyncCompleteError](error, stackTrace);
      }
    }
    dart.setSignature(_AsyncCompleter, {
      methods: () => ({
        complete: [dart.void, [], [dart.dynamic]],
        [_completeError]: [dart.void, [core.Object, core.StackTrace]]
      })
    });
    return _AsyncCompleter;
  });
  let _AsyncCompleter = _AsyncCompleter$();
  const _SyncCompleter$ = dart.generic(function(T) {
    class _SyncCompleter extends _Completer$(T) {
      _SyncCompleter() {
        super._Completer();
      }
      complete(value) {
        if (value === void 0) value = null;
        if (!dart.notNull(this.future[_mayComplete])) dart.throw(new core.StateError("Future already completed"));
        this.future[_complete](value);
      }
      [_completeError](error, stackTrace) {
        this.future[_completeError](error, stackTrace);
      }
    }
    dart.setSignature(_SyncCompleter, {
      methods: () => ({
        complete: [dart.void, [], [dart.dynamic]],
        [_completeError]: [dart.void, [core.Object, core.StackTrace]]
      })
    });
    return _SyncCompleter;
  });
  let _SyncCompleter = _SyncCompleter$();
  const _nextListener = Symbol('_nextListener');
  const _onValue = Symbol('_onValue');
  const _errorTest = Symbol('_errorTest');
  const _whenCompleteAction = Symbol('_whenCompleteAction');
  class _FutureListener extends core.Object {
    then(result, onValue, errorCallback) {
      this.result = result;
      this.callback = onValue;
      this.errorCallback = errorCallback;
      this.state = errorCallback == null ? _FutureListener.STATE_THEN : _FutureListener.STATE_THEN_ONERROR;
      this[_nextListener] = null;
    }
    catchError(result, errorCallback, test) {
      this.result = result;
      this.errorCallback = errorCallback;
      this.callback = test;
      this.state = test == null ? _FutureListener.STATE_CATCHERROR : _FutureListener.STATE_CATCHERROR_TEST;
      this[_nextListener] = null;
    }
    whenComplete(result, onComplete) {
      this.result = result;
      this.callback = onComplete;
      this.errorCallback = null;
      this.state = _FutureListener.STATE_WHENCOMPLETE;
      this[_nextListener] = null;
    }
    chain(result) {
      this.result = result;
      this.callback = null;
      this.errorCallback = null;
      this.state = _FutureListener.STATE_CHAIN;
      this[_nextListener] = null;
    }
    get [_zone]() {
      return this.result[_zone];
    }
    get handlesValue() {
      return (dart.notNull(this.state) & dart.notNull(_FutureListener.MASK_VALUE)) != 0;
    }
    get handlesError() {
      return (dart.notNull(this.state) & dart.notNull(_FutureListener.MASK_ERROR)) != 0;
    }
    get hasErrorTest() {
      return this.state == _FutureListener.STATE_CATCHERROR_TEST;
    }
    get handlesComplete() {
      return this.state == _FutureListener.STATE_WHENCOMPLETE;
    }
    get [_onValue]() {
      dart.assert(this.handlesValue);
      return dart.as(this.callback, _FutureOnValue);
    }
    get [_onError]() {
      return this.errorCallback;
    }
    get [_errorTest]() {
      dart.assert(this.hasErrorTest);
      return dart.as(this.callback, _FutureErrorTest);
    }
    get [_whenCompleteAction]() {
      dart.assert(this.handlesComplete);
      return dart.as(this.callback, _FutureAction);
    }
  }
  dart.defineNamedConstructor(_FutureListener, 'then');
  dart.defineNamedConstructor(_FutureListener, 'catchError');
  dart.defineNamedConstructor(_FutureListener, 'whenComplete');
  dart.defineNamedConstructor(_FutureListener, 'chain');
  dart.setSignature(_FutureListener, {
    constructors: () => ({
      then: [_FutureListener, [_Future, _FutureOnValue, core.Function]],
      catchError: [_FutureListener, [_Future, core.Function, _FutureErrorTest]],
      whenComplete: [_FutureListener, [_Future, _FutureAction]],
      chain: [_FutureListener, [_Future]]
    })
  });
  _FutureListener.MASK_VALUE = 1;
  _FutureListener.MASK_ERROR = 2;
  _FutureListener.MASK_TEST_ERROR = 4;
  _FutureListener.MASK_WHENCOMPLETE = 8;
  _FutureListener.STATE_CHAIN = 0;
  dart.defineLazyProperties(_FutureListener, {
    get STATE_THEN() {
      return _FutureListener.MASK_VALUE;
    },
    get STATE_THEN_ONERROR() {
      return dart.notNull(_FutureListener.MASK_VALUE) | dart.notNull(_FutureListener.MASK_ERROR);
    },
    get STATE_CATCHERROR() {
      return _FutureListener.MASK_ERROR;
    },
    get STATE_CATCHERROR_TEST() {
      return dart.notNull(_FutureListener.MASK_ERROR) | dart.notNull(_FutureListener.MASK_TEST_ERROR);
    },
    get STATE_WHENCOMPLETE() {
      return _FutureListener.MASK_WHENCOMPLETE;
    }
  });
  const _resultOrListeners = Symbol('_resultOrListeners');
  const _isChained = Symbol('_isChained');
  const _isComplete = Symbol('_isComplete');
  const _hasValue = Symbol('_hasValue');
  const _hasError = Symbol('_hasError');
  const _markPendingCompletion = Symbol('_markPendingCompletion');
  const _value = Symbol('_value');
  const _error = Symbol('_error');
  const _setValue = Symbol('_setValue');
  const _setErrorObject = Symbol('_setErrorObject');
  const _setError = Symbol('_setError');
  const _removeListeners = Symbol('_removeListeners');
  const _Future$ = dart.generic(function(T) {
    class _Future extends core.Object {
      _Future() {
        this[_zone] = Zone.current;
        this[_state] = _Future$()._INCOMPLETE;
        this[_resultOrListeners] = null;
      }
      immediate(value) {
        this[_zone] = Zone.current;
        this[_state] = _Future$()._INCOMPLETE;
        this[_resultOrListeners] = null;
        this[_asyncComplete](value);
      }
      immediateError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        this[_zone] = Zone.current;
        this[_state] = _Future$()._INCOMPLETE;
        this[_resultOrListeners] = null;
        this[_asyncCompleteError](error, stackTrace);
      }
      get [_mayComplete]() {
        return this[_state] == _Future$()._INCOMPLETE;
      }
      get [_isChained]() {
        return this[_state] == _Future$()._CHAINED;
      }
      get [_isComplete]() {
        return dart.notNull(this[_state]) >= dart.notNull(_Future$()._VALUE);
      }
      get [_hasValue]() {
        return this[_state] == _Future$()._VALUE;
      }
      get [_hasError]() {
        return this[_state] == _Future$()._ERROR;
      }
      set [_isChained](value) {
        if (dart.notNull(value)) {
          dart.assert(!dart.notNull(this[_isComplete]));
          this[_state] = _Future$()._CHAINED;
        } else {
          dart.assert(this[_isChained]);
          this[_state] = _Future$()._INCOMPLETE;
        }
      }
      then(f, opts) {
        dart.as(f, dart.functionType(dart.dynamic, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let result = new (_Future$())();
        if (!dart.notNull(core.identical(result[_zone], _ROOT_ZONE))) {
          f = dart.as(result[_zone].registerUnaryCallback(f), __CastType4);
          if (onError != null) {
            onError = _registerErrorHandler(onError, result[_zone]);
          }
        }
        this[_addListener](new _FutureListener.then(result, f, onError));
        return result;
      }
      catchError(onError, opts) {
        let test = opts && 'test' in opts ? opts.test : null;
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        let result = new (_Future$())();
        if (!dart.notNull(core.identical(result[_zone], _ROOT_ZONE))) {
          onError = _registerErrorHandler(onError, result[_zone]);
          if (test != null) test = dart.as(result[_zone].registerUnaryCallback(test), __CastType6);
        }
        this[_addListener](new _FutureListener.catchError(result, onError, test));
        return result;
      }
      whenComplete(action) {
        dart.as(action, dart.functionType(dart.dynamic, []));
        let result = new (_Future$(T))();
        if (!dart.notNull(core.identical(result[_zone], _ROOT_ZONE))) {
          action = result[_zone].registerCallback(action);
        }
        this[_addListener](new _FutureListener.whenComplete(result, action));
        return dart.as(result, Future$(T));
      }
      asStream() {
        return Stream$(T).fromFuture(this);
      }
      [_markPendingCompletion]() {
        if (!dart.notNull(this[_mayComplete])) dart.throw(new core.StateError("Future already completed"));
        this[_state] = _Future$()._PENDING_COMPLETE;
      }
      get [_value]() {
        dart.assert(dart.notNull(this[_isComplete]) && dart.notNull(this[_hasValue]));
        return dart.as(this[_resultOrListeners], T);
      }
      get [_error]() {
        dart.assert(dart.notNull(this[_isComplete]) && dart.notNull(this[_hasError]));
        return dart.as(this[_resultOrListeners], AsyncError);
      }
      [_setValue](value) {
        dart.as(value, T);
        dart.assert(!dart.notNull(this[_isComplete]));
        this[_state] = _Future$()._VALUE;
        this[_resultOrListeners] = value;
      }
      [_setErrorObject](error) {
        dart.assert(!dart.notNull(this[_isComplete]));
        this[_state] = _Future$()._ERROR;
        this[_resultOrListeners] = error;
      }
      [_setError](error, stackTrace) {
        this[_setErrorObject](new AsyncError(error, stackTrace));
      }
      [_addListener](listener) {
        dart.assert(listener[_nextListener] == null);
        if (dart.notNull(this[_isComplete])) {
          this[_zone].scheduleMicrotask(dart.fn((() => {
            _Future$()._propagateToListeners(this, listener);
          }).bind(this), dart.void, []));
        } else {
          listener[_nextListener] = dart.as(this[_resultOrListeners], _FutureListener);
          this[_resultOrListeners] = listener;
        }
      }
      [_removeListeners]() {
        dart.assert(!dart.notNull(this[_isComplete]));
        let current = dart.as(this[_resultOrListeners], _FutureListener);
        this[_resultOrListeners] = null;
        let prev = null;
        while (current != null) {
          let next = current[_nextListener];
          current[_nextListener] = prev;
          prev = current;
          current = next;
        }
        return prev;
      }
      static _chainForeignFuture(source, target) {
        dart.assert(!dart.notNull(target[_isComplete]));
        dart.assert(!dart.is(source, _Future$()));
        target[_isChained] = true;
        source.then(dart.fn(value => {
          dart.assert(target[_isChained]);
          target[_completeWithValue](value);
        }), {onError: dart.fn((error, stackTrace) => {
            if (stackTrace === void 0) stackTrace = null;
            dart.assert(target[_isChained]);
            target[_completeError](error, dart.as(stackTrace, core.StackTrace));
          }, dart.dynamic, [dart.dynamic], [dart.dynamic])});
      }
      static _chainCoreFuture(source, target) {
        dart.assert(!dart.notNull(target[_isComplete]));
        dart.assert(dart.is(source, _Future$()));
        target[_isChained] = true;
        let listener = new _FutureListener.chain(target);
        if (dart.notNull(source[_isComplete])) {
          _Future$()._propagateToListeners(source, listener);
        } else {
          source[_addListener](listener);
        }
      }
      [_complete](value) {
        dart.assert(!dart.notNull(this[_isComplete]));
        if (dart.is(value, Future)) {
          if (dart.is(value, _Future$())) {
            _Future$()._chainCoreFuture(value, this);
          } else {
            _Future$()._chainForeignFuture(value, this);
          }
        } else {
          let listeners = this[_removeListeners]();
          this[_setValue](dart.as(value, T));
          _Future$()._propagateToListeners(this, listeners);
        }
      }
      [_completeWithValue](value) {
        dart.assert(!dart.notNull(this[_isComplete]));
        dart.assert(!dart.is(value, Future));
        let listeners = this[_removeListeners]();
        this[_setValue](dart.as(value, T));
        _Future$()._propagateToListeners(this, listeners);
      }
      [_completeError](error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        dart.assert(!dart.notNull(this[_isComplete]));
        let listeners = this[_removeListeners]();
        this[_setError](error, stackTrace);
        _Future$()._propagateToListeners(this, listeners);
      }
      [_asyncComplete](value) {
        dart.assert(!dart.notNull(this[_isComplete]));
        if (value == null) {
        } else if (dart.is(value, Future)) {
          let typedFuture = dart.as(value, Future$(T));
          if (dart.is(typedFuture, _Future$())) {
            let coreFuture = dart.as(typedFuture, _Future$(T));
            if (dart.notNull(coreFuture[_isComplete]) && dart.notNull(coreFuture[_hasError])) {
              this[_markPendingCompletion]();
              this[_zone].scheduleMicrotask(dart.fn((() => {
                _Future$()._chainCoreFuture(coreFuture, this);
              }).bind(this), dart.void, []));
            } else {
              _Future$()._chainCoreFuture(coreFuture, this);
            }
          } else {
            _Future$()._chainForeignFuture(typedFuture, this);
          }
          return;
        } else {
          let typedValue = dart.as(value, T);
        }
        this[_markPendingCompletion]();
        this[_zone].scheduleMicrotask(dart.fn((() => {
          this[_completeWithValue](value);
        }).bind(this), dart.void, []));
      }
      [_asyncCompleteError](error, stackTrace) {
        dart.assert(!dart.notNull(this[_isComplete]));
        this[_markPendingCompletion]();
        this[_zone].scheduleMicrotask(dart.fn((() => {
          this[_completeError](error, stackTrace);
        }).bind(this), dart.void, []));
      }
      static _propagateToListeners(source, listeners) {
        while (true) {
          dart.assert(source[_isComplete]);
          let hasError = source[_hasError];
          if (listeners == null) {
            if (dart.notNull(hasError)) {
              let asyncError = source[_error];
              source[_zone].handleUncaughtError(asyncError.error, asyncError.stackTrace);
            }
            return;
          }
          while (listeners[_nextListener] != null) {
            let listener = listeners;
            listeners = listener[_nextListener];
            listener[_nextListener] = null;
            _Future$()._propagateToListeners(source, listener);
          }
          let listener = listeners;
          let listenerHasValue = true;
          let sourceValue = dart.notNull(hasError) ? null : source[_value];
          let listenerValueOrError = sourceValue;
          let isPropagationAborted = false;
          if (dart.notNull(hasError) || dart.notNull(listener.handlesValue) || dart.notNull(listener.handlesComplete)) {
            let zone = listener[_zone];
            if (dart.notNull(hasError) && !dart.notNull(source[_zone].inSameErrorZone(zone))) {
              let asyncError = source[_error];
              source[_zone].handleUncaughtError(asyncError.error, asyncError.stackTrace);
              return;
            }
            let oldZone = null;
            if (!dart.notNull(core.identical(Zone.current, zone))) {
              oldZone = Zone._enter(zone);
            }
            function handleValueCallback() {
              try {
                listenerValueOrError = zone.runUnary(listener[_onValue], sourceValue);
                return true;
              } catch (e) {
                let s = dart.stackTrace(e);
                listenerValueOrError = new AsyncError(e, s);
                return false;
              }

            }
            dart.fn(handleValueCallback, core.bool, []);
            function handleError() {
              let asyncError = source[_error];
              let matchesTest = true;
              if (dart.notNull(listener.hasErrorTest)) {
                let test = listener[_errorTest];
                try {
                  matchesTest = dart.as(zone.runUnary(test, asyncError.error), core.bool);
                } catch (e) {
                  let s = dart.stackTrace(e);
                  listenerValueOrError = dart.notNull(core.identical(asyncError.error, e)) ? asyncError : new AsyncError(e, s);
                  listenerHasValue = false;
                  return;
                }

              }
              let errorCallback = listener[_onError];
              if (dart.notNull(matchesTest) && errorCallback != null) {
                try {
                  if (dart.is(errorCallback, ZoneBinaryCallback)) {
                    listenerValueOrError = zone.runBinary(errorCallback, asyncError.error, asyncError.stackTrace);
                  } else {
                    listenerValueOrError = zone.runUnary(dart.as(errorCallback, __CastType8), asyncError.error);
                  }
                } catch (e) {
                  let s = dart.stackTrace(e);
                  listenerValueOrError = dart.notNull(core.identical(asyncError.error, e)) ? asyncError : new AsyncError(e, s);
                  listenerHasValue = false;
                  return;
                }

                listenerHasValue = true;
              } else {
                listenerValueOrError = asyncError;
                listenerHasValue = false;
              }
            }
            dart.fn(handleError, dart.void, []);
            function handleWhenCompleteCallback() {
              let completeResult = null;
              try {
                completeResult = zone.run(listener[_whenCompleteAction]);
              } catch (e) {
                let s = dart.stackTrace(e);
                if (dart.notNull(hasError) && dart.notNull(core.identical(source[_error].error, e))) {
                  listenerValueOrError = source[_error];
                } else {
                  listenerValueOrError = new AsyncError(e, s);
                }
                listenerHasValue = false;
                return;
              }

              if (dart.is(completeResult, Future)) {
                let result = listener.result;
                result[_isChained] = true;
                isPropagationAborted = true;
                dart.dsend(completeResult, 'then', dart.fn(ignored => {
                  _Future$()._propagateToListeners(source, new _FutureListener.chain(result));
                }), {onError: dart.fn((error, stackTrace) => {
                    if (stackTrace === void 0) stackTrace = null;
                    if (!dart.is(completeResult, _Future$())) {
                      completeResult = new (_Future$())();
                      dart.dsend(completeResult, _setError, error, stackTrace);
                    }
                    _Future$()._propagateToListeners(dart.as(completeResult, _Future$()), new _FutureListener.chain(result));
                  }, dart.dynamic, [dart.dynamic], [dart.dynamic])});
              }
            }
            dart.fn(handleWhenCompleteCallback, dart.void, []);
            if (!dart.notNull(hasError)) {
              if (dart.notNull(listener.handlesValue)) {
                listenerHasValue = handleValueCallback();
              }
            } else {
              handleError();
            }
            if (dart.notNull(listener.handlesComplete)) {
              handleWhenCompleteCallback();
            }
            if (oldZone != null) Zone._leave(oldZone);
            if (isPropagationAborted) return;
            if (dart.notNull(listenerHasValue) && !dart.notNull(core.identical(sourceValue, listenerValueOrError)) && dart.is(listenerValueOrError, Future)) {
              let chainSource = dart.as(listenerValueOrError, Future);
              let result = listener.result;
              if (dart.is(chainSource, _Future$())) {
                if (dart.notNull(chainSource[_isComplete])) {
                  result[_isChained] = true;
                  source = chainSource;
                  listeners = new _FutureListener.chain(result);
                  continue;
                } else {
                  _Future$()._chainCoreFuture(chainSource, result);
                }
              } else {
                _Future$()._chainForeignFuture(chainSource, result);
              }
              return;
            }
          }
          let result = listener.result;
          listeners = result[_removeListeners]();
          if (dart.notNull(listenerHasValue)) {
            result[_setValue](listenerValueOrError);
          } else {
            let asyncError = dart.as(listenerValueOrError, AsyncError);
            result[_setErrorObject](asyncError);
          }
          source = result;
        }
      }
      timeout(timeLimit, opts) {
        let onTimeout = opts && 'onTimeout' in opts ? opts.onTimeout : null;
        dart.as(onTimeout, dart.functionType(dart.dynamic, []));
        if (dart.notNull(this[_isComplete])) return new (_Future$()).immediate(this);
        let result = new (_Future$())();
        let timer = null;
        if (onTimeout == null) {
          timer = Timer.new(timeLimit, dart.fn(() => {
            result[_completeError](new TimeoutException("Future not completed", timeLimit));
          }, dart.void, []));
        } else {
          let zone = Zone.current;
          onTimeout = zone.registerCallback(onTimeout);
          timer = Timer.new(timeLimit, dart.fn(() => {
            try {
              result[_complete](zone.run(onTimeout));
            } catch (e) {
              let s = dart.stackTrace(e);
              result[_completeError](e, s);
            }

          }, dart.void, []));
        }
        this.then(dart.fn(v => {
          dart.as(v, T);
          if (dart.notNull(timer.isActive)) {
            timer.cancel();
            result[_completeWithValue](v);
          }
        }, dart.dynamic, [T]), {onError: dart.fn((e, s) => {
            if (dart.notNull(timer.isActive)) {
              timer.cancel();
              result[_completeError](e, dart.as(s, core.StackTrace));
            }
          })});
        return result;
      }
    }
    _Future[dart.implements] = () => [Future$(T)];
    dart.defineNamedConstructor(_Future, 'immediate');
    dart.defineNamedConstructor(_Future, 'immediateError');
    dart.setSignature(_Future, {
      constructors: () => ({
        _Future: [_Future$(T), []],
        immediate: [_Future$(T), [dart.dynamic]],
        immediateError: [_Future$(T), [dart.dynamic], [core.StackTrace]]
      }),
      methods: () => ({
        then: [Future, [dart.functionType(dart.dynamic, [T])], {onError: core.Function}],
        catchError: [Future, [core.Function], {test: dart.functionType(core.bool, [dart.dynamic])}],
        whenComplete: [Future$(T), [dart.functionType(dart.dynamic, [])]],
        asStream: [Stream$(T), []],
        [_markPendingCompletion]: [dart.void, []],
        [_setValue]: [dart.void, [T]],
        [_setErrorObject]: [dart.void, [AsyncError]],
        [_setError]: [dart.void, [core.Object, core.StackTrace]],
        [_addListener]: [dart.void, [_FutureListener]],
        [_removeListeners]: [_FutureListener, []],
        [_complete]: [dart.void, [dart.dynamic]],
        [_completeWithValue]: [dart.void, [dart.dynamic]],
        [_completeError]: [dart.void, [dart.dynamic], [core.StackTrace]],
        [_asyncComplete]: [dart.void, [dart.dynamic]],
        [_asyncCompleteError]: [dart.void, [dart.dynamic, core.StackTrace]],
        timeout: [Future, [core.Duration], {onTimeout: dart.functionType(dart.dynamic, [])}]
      }),
      statics: () => ({
        _chainForeignFuture: [dart.void, [Future, _Future$()]],
        _chainCoreFuture: [dart.void, [_Future$(), _Future$()]],
        _propagateToListeners: [dart.void, [_Future$(), _FutureListener]]
      }),
      names: ['_chainForeignFuture', '_chainCoreFuture', '_propagateToListeners']
    });
    _Future._INCOMPLETE = 0;
    _Future._PENDING_COMPLETE = 1;
    _Future._CHAINED = 2;
    _Future._VALUE = 4;
    _Future._ERROR = 8;
    return _Future;
  });
  let _Future = _Future$();
  const __CastType4$ = dart.generic(function(T, S) {
    const __CastType4 = dart.typedef('__CastType4', () => dart.functionType(S, [T]));
    return __CastType4;
  });
  let __CastType4 = __CastType4$();
  const __CastType6 = dart.typedef('__CastType6', () => dart.functionType(core.bool, [dart.dynamic]));
  const __CastType8 = dart.typedef('__CastType8', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  const _AsyncCallback = dart.typedef('_AsyncCallback', () => dart.functionType(dart.void, []));
  class _AsyncCallbackEntry extends core.Object {
    _AsyncCallbackEntry(callback) {
      this.callback = callback;
      this.next = null;
    }
  }
  dart.setSignature(_AsyncCallbackEntry, {
    constructors: () => ({_AsyncCallbackEntry: [_AsyncCallbackEntry, [_AsyncCallback]]})
  });
  exports._nextCallback = null;
  exports._lastCallback = null;
  exports._lastPriorityCallback = null;
  exports._isInCallbackLoop = false;
  function _asyncRunCallbackLoop() {
    while (exports._nextCallback != null) {
      exports._lastPriorityCallback = null;
      let entry = exports._nextCallback;
      exports._nextCallback = entry.next;
      if (exports._nextCallback == null) exports._lastCallback = null;
      entry.callback();
    }
  }
  dart.fn(_asyncRunCallbackLoop, dart.void, []);
  function _asyncRunCallback() {
    exports._isInCallbackLoop = true;
    try {
      _asyncRunCallbackLoop();
    } finally {
      exports._lastPriorityCallback = null;
      exports._isInCallbackLoop = false;
      if (exports._nextCallback != null) _AsyncRun._scheduleImmediate(_asyncRunCallback);
    }
  }
  dart.fn(_asyncRunCallback, dart.void, []);
  function _scheduleAsyncCallback(callback) {
    if (exports._nextCallback == null) {
      exports._nextCallback = exports._lastCallback = new _AsyncCallbackEntry(dart.as(callback, _AsyncCallback));
      if (!dart.notNull(exports._isInCallbackLoop)) {
        _AsyncRun._scheduleImmediate(_asyncRunCallback);
      }
    } else {
      let newEntry = new _AsyncCallbackEntry(dart.as(callback, _AsyncCallback));
      exports._lastCallback.next = newEntry;
      exports._lastCallback = newEntry;
    }
  }
  dart.fn(_scheduleAsyncCallback, dart.void, [dart.dynamic]);
  function _schedulePriorityAsyncCallback(callback) {
    let entry = new _AsyncCallbackEntry(dart.as(callback, _AsyncCallback));
    if (exports._nextCallback == null) {
      _scheduleAsyncCallback(callback);
      exports._lastPriorityCallback = exports._lastCallback;
    } else if (exports._lastPriorityCallback == null) {
      entry.next = exports._nextCallback;
      exports._nextCallback = exports._lastPriorityCallback = entry;
    } else {
      entry.next = exports._lastPriorityCallback.next;
      exports._lastPriorityCallback.next = entry;
      exports._lastPriorityCallback = entry;
      if (entry.next == null) {
        exports._lastCallback = entry;
      }
    }
  }
  dart.fn(_schedulePriorityAsyncCallback, dart.void, [dart.dynamic]);
  function scheduleMicrotask(callback) {
    if (dart.notNull(core.identical(_ROOT_ZONE, Zone.current))) {
      _rootScheduleMicrotask(null, null, _ROOT_ZONE, callback);
      return;
    }
    Zone.current.scheduleMicrotask(Zone.current.bindCallback(callback, {runGuarded: true}));
  }
  dart.fn(scheduleMicrotask, dart.void, [dart.functionType(dart.void, [])]);
  class _AsyncRun extends core.Object {
    static _scheduleImmediate(callback) {
      dart.dcall(_AsyncRun.scheduleImmediateClosure, callback);
    }
    static _initializeScheduleImmediate() {
      if (self.scheduleImmediate != null) {
        return _AsyncRun._scheduleImmediateJsOverride;
      }
      if (self.MutationObserver != null && self.document != null) {
        let div = self.document.createElement("div");
        let span = self.document.createElement("span");
        let storedCallback = null;
        function internalCallback(_) {
          _isolate_helper.leaveJsAsync();
          let f = storedCallback;
          storedCallback = null;
          dart.dcall(f);
        }
        dart.fn(internalCallback);
        ;
        let observer = new self.MutationObserver(internalCallback);
        observer.observe(div, {childList: true});
        return dart.fn(callback => {
          dart.assert(storedCallback == null);
          _isolate_helper.enterJsAsync();
          storedCallback = callback;
          div.firstChild ? div.removeChild(span) : div.appendChild(span);
        }, dart.dynamic, [dart.functionType(dart.void, [])]);
      } else if (self.setImmediate != null) {
        return _AsyncRun._scheduleImmediateWithSetImmediate;
      }
      return _AsyncRun._scheduleImmediateWithTimer;
    }
    static _scheduleImmediateJsOverride(callback) {
      function internalCallback() {
        _isolate_helper.leaveJsAsync();
        callback();
      }
      dart.fn(internalCallback);
      ;
      _isolate_helper.enterJsAsync();
      self.scheduleImmediate(internalCallback);
    }
    static _scheduleImmediateWithSetImmediate(callback) {
      function internalCallback() {
        _isolate_helper.leaveJsAsync();
        callback();
      }
      dart.fn(internalCallback);
      ;
      _isolate_helper.enterJsAsync();
      self.setImmediate(internalCallback);
    }
    static _scheduleImmediateWithTimer(callback) {
      Timer._createTimer(core.Duration.ZERO, callback);
    }
  }
  dart.setSignature(_AsyncRun, {
    statics: () => ({
      _scheduleImmediate: [dart.void, [dart.functionType(dart.void, [])]],
      _initializeScheduleImmediate: [core.Function, []],
      _scheduleImmediateJsOverride: [dart.void, [dart.functionType(dart.void, [])]],
      _scheduleImmediateWithSetImmediate: [dart.void, [dart.functionType(dart.void, [])]],
      _scheduleImmediateWithTimer: [dart.void, [dart.functionType(dart.void, [])]]
    }),
    names: ['_scheduleImmediate', '_initializeScheduleImmediate', '_scheduleImmediateJsOverride', '_scheduleImmediateWithSetImmediate', '_scheduleImmediateWithTimer']
  });
  dart.defineLazyProperties(_AsyncRun, {
    get scheduleImmediateClosure() {
      return _AsyncRun._initializeScheduleImmediate();
    }
  });
  const StreamSubscription$ = dart.generic(function(T) {
    class StreamSubscription extends core.Object {}
    return StreamSubscription;
  });
  let StreamSubscription = StreamSubscription$();
  const EventSink$ = dart.generic(function(T) {
    class EventSink extends core.Object {}
    EventSink[dart.implements] = () => [core.Sink$(T)];
    return EventSink;
  });
  let EventSink = EventSink$();
  const _stream = Symbol('_stream');
  const StreamView$ = dart.generic(function(T) {
    class StreamView extends Stream$(T) {
      StreamView(stream) {
        this[_stream] = stream;
        super.Stream();
      }
      get isBroadcast() {
        return this[_stream].isBroadcast;
      }
      asBroadcastStream(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        dart.as(onListen, dart.functionType(dart.void, [StreamSubscription$(T)]));
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        dart.as(onCancel, dart.functionType(dart.void, [StreamSubscription$(T)]));
        return this[_stream].asBroadcastStream({onListen: onListen, onCancel: onCancel});
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        return this[_stream].listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
      }
    }
    dart.setSignature(StreamView, {
      constructors: () => ({StreamView: [StreamView$(T), [Stream$(T)]]}),
      methods: () => ({
        asBroadcastStream: [Stream$(T), [], {onListen: dart.functionType(dart.void, [StreamSubscription$(T)]), onCancel: dart.functionType(dart.void, [StreamSubscription$(T)])}],
        listen: [StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}]
      })
    });
    return StreamView;
  });
  let StreamView = StreamView$();
  const StreamConsumer$ = dart.generic(function(S) {
    class StreamConsumer extends core.Object {}
    return StreamConsumer;
  });
  let StreamConsumer = StreamConsumer$();
  const StreamSink$ = dart.generic(function(S) {
    class StreamSink extends core.Object {}
    StreamSink[dart.implements] = () => [StreamConsumer$(S), EventSink$(S)];
    return StreamSink;
  });
  let StreamSink = StreamSink$();
  const StreamTransformer$ = dart.generic(function(S, T) {
    class StreamTransformer extends core.Object {
      static new(transformer) {
        return new (_StreamSubscriptionTransformer$(S, T))(transformer);
      }
      static fromHandlers(opts) {
        return new (_StreamHandlerTransformer$(S, T))(opts);
      }
    }
    dart.setSignature(StreamTransformer, {
      constructors: () => ({
        new: [StreamTransformer$(S, T), [dart.functionType(StreamSubscription$(T), [Stream$(S), core.bool])]],
        fromHandlers: [StreamTransformer$(S, T), [], {handleData: dart.functionType(dart.void, [S, EventSink$(T)]), handleError: dart.functionType(dart.void, [core.Object, core.StackTrace, EventSink$(T)]), handleDone: dart.functionType(dart.void, [EventSink$(T)])}]
      })
    });
    return StreamTransformer;
  });
  let StreamTransformer = StreamTransformer$();
  const StreamIterator$ = dart.generic(function(T) {
    class StreamIterator extends core.Object {
      static new(stream) {
        return new (_StreamIteratorImpl$(T))(stream);
      }
    }
    dart.setSignature(StreamIterator, {
      constructors: () => ({new: [StreamIterator$(T), [Stream$(T)]]})
    });
    return StreamIterator;
  });
  let StreamIterator = StreamIterator$();
  const _ControllerEventSinkWrapper$ = dart.generic(function(T) {
    class _ControllerEventSinkWrapper extends core.Object {
      _ControllerEventSinkWrapper(sink) {
        this[_sink] = sink;
      }
      add(data) {
        dart.as(data, T);
        this[_sink].add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        this[_sink].addError(error, stackTrace);
      }
      close() {
        this[_sink].close();
      }
    }
    _ControllerEventSinkWrapper[dart.implements] = () => [EventSink$(T)];
    dart.setSignature(_ControllerEventSinkWrapper, {
      constructors: () => ({_ControllerEventSinkWrapper: [_ControllerEventSinkWrapper$(T), [EventSink]]}),
      methods: () => ({
        add: [dart.void, [T]],
        addError: [dart.void, [dart.dynamic], [core.StackTrace]],
        close: [dart.void, []]
      })
    });
    return _ControllerEventSinkWrapper;
  });
  let _ControllerEventSinkWrapper = _ControllerEventSinkWrapper$();
  const __CastType10 = dart.typedef('__CastType10', () => dart.functionType(dart.void, [StreamSubscription]));
  const __CastType12 = dart.typedef('__CastType12', () => dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace]));
  const __CastType15 = dart.typedef('__CastType15', () => dart.functionType(dart.void, []));
  const __CastType16 = dart.typedef('__CastType16', () => dart.functionType(dart.void, [EventSink]));
  const StreamController$ = dart.generic(function(T) {
    class StreamController extends core.Object {
      static new(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        let onPause = opts && 'onPause' in opts ? opts.onPause : null;
        let onResume = opts && 'onResume' in opts ? opts.onResume : null;
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        let sync = opts && 'sync' in opts ? opts.sync : false;
        if (onListen == null && onPause == null && onResume == null && onCancel == null) {
          return dart.notNull(sync) ? new (_NoCallbackSyncStreamController$(T))() : new (_NoCallbackAsyncStreamController$(T))();
        }
        return dart.notNull(sync) ? new (_SyncStreamController$(T))(onListen, onPause, onResume, onCancel) : new (_AsyncStreamController$(T))(onListen, onPause, onResume, onCancel);
      }
      static broadcast(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        let sync = opts && 'sync' in opts ? opts.sync : false;
        return dart.notNull(sync) ? new (_SyncBroadcastStreamController$(T))(onListen, onCancel) : new (_AsyncBroadcastStreamController$(T))(onListen, onCancel);
      }
    }
    StreamController[dart.implements] = () => [StreamSink$(T)];
    dart.setSignature(StreamController, {
      constructors: () => ({
        new: [StreamController$(T), [], {onListen: dart.functionType(dart.void, []), onPause: dart.functionType(dart.void, []), onResume: dart.functionType(dart.void, []), onCancel: dart.functionType(dart.dynamic, []), sync: core.bool}],
        broadcast: [StreamController$(T), [], {onListen: dart.functionType(dart.void, []), onCancel: dart.functionType(dart.void, []), sync: core.bool}]
      })
    });
    return StreamController;
  });
  let StreamController = StreamController$();
  const _StreamControllerLifecycle$ = dart.generic(function(T) {
    class _StreamControllerLifecycle extends core.Object {
      [_recordPause](subscription) {
        dart.as(subscription, StreamSubscription$(T));
      }
      [_recordResume](subscription) {
        dart.as(subscription, StreamSubscription$(T));
      }
      [_recordCancel](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        return null;
      }
    }
    dart.setSignature(_StreamControllerLifecycle, {
      methods: () => ({
        [_recordPause]: [dart.void, [StreamSubscription$(T)]],
        [_recordResume]: [dart.void, [StreamSubscription$(T)]],
        [_recordCancel]: [Future, [StreamSubscription$(T)]]
      })
    });
    return _StreamControllerLifecycle;
  });
  let _StreamControllerLifecycle = _StreamControllerLifecycle$();
  const _varData = Symbol('_varData');
  const _isInitialState = Symbol('_isInitialState');
  const _subscription = Symbol('_subscription');
  const _pendingEvents = Symbol('_pendingEvents');
  const _ensurePendingEvents = Symbol('_ensurePendingEvents');
  const _badEventState = Symbol('_badEventState');
  const _StreamController$ = dart.generic(function(T) {
    class _StreamController extends core.Object {
      _StreamController() {
        this[_varData] = null;
        this[_state] = _StreamController$()._STATE_INITIAL;
        this[_doneFuture] = null;
      }
      get stream() {
        return new (_ControllerStream$(T))(this);
      }
      get sink() {
        return new (_StreamSinkWrapper$(T))(this);
      }
      get [_isCanceled]() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController$()._STATE_CANCELED)) != 0;
      }
      get hasListener() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController$()._STATE_SUBSCRIBED)) != 0;
      }
      get [_isInitialState]() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController$()._STATE_SUBSCRIPTION_MASK)) == _StreamController$()._STATE_INITIAL;
      }
      get isClosed() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController$()._STATE_CLOSED)) != 0;
      }
      get isPaused() {
        return dart.notNull(this.hasListener) ? this[_subscription][_isInputPaused] : !dart.notNull(this[_isCanceled]);
      }
      get [_isAddingStream]() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController$()._STATE_ADDSTREAM)) != 0;
      }
      get [_mayAddEvent]() {
        return dart.notNull(this[_state]) < dart.notNull(_StreamController$()._STATE_CLOSED);
      }
      get [_pendingEvents]() {
        dart.assert(this[_isInitialState]);
        if (!dart.notNull(this[_isAddingStream])) {
          return dart.as(this[_varData], _PendingEvents);
        }
        let state = dart.as(this[_varData], _StreamControllerAddStreamState);
        return dart.as(state.varData, _PendingEvents);
      }
      [_ensurePendingEvents]() {
        dart.assert(this[_isInitialState]);
        if (!dart.notNull(this[_isAddingStream])) {
          if (this[_varData] == null) this[_varData] = new _StreamImplEvents();
          return dart.as(this[_varData], _StreamImplEvents);
        }
        let state = dart.as(this[_varData], _StreamControllerAddStreamState);
        if (state.varData == null) state.varData = new _StreamImplEvents();
        return dart.as(state.varData, _StreamImplEvents);
      }
      get [_subscription]() {
        dart.assert(this.hasListener);
        if (dart.notNull(this[_isAddingStream])) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          return dart.as(addState.varData, _ControllerSubscription);
        }
        return dart.as(this[_varData], _ControllerSubscription);
      }
      [_badEventState]() {
        if (dart.notNull(this.isClosed)) {
          return new core.StateError("Cannot add event after closing");
        }
        dart.assert(this[_isAddingStream]);
        return new core.StateError("Cannot add event while adding a stream");
      }
      addStream(source, opts) {
        dart.as(source, Stream$(T));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : true;
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_badEventState]());
        if (dart.notNull(this[_isCanceled])) return new _Future.immediate(null);
        let addState = new _StreamControllerAddStreamState(this, this[_varData], source, cancelOnError);
        this[_varData] = addState;
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_StreamController$()._STATE_ADDSTREAM);
        return addState.addStreamFuture;
      }
      get done() {
        return this[_ensureDoneFuture]();
      }
      [_ensureDoneFuture]() {
        if (this[_doneFuture] == null) {
          this[_doneFuture] = dart.notNull(this[_isCanceled]) ? Future._nullFuture : new _Future();
        }
        return this[_doneFuture];
      }
      add(value) {
        dart.as(value, T);
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_badEventState]());
        this[_add](value);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_badEventState]());
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement != null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this[_addError](error, stackTrace);
      }
      close() {
        if (dart.notNull(this.isClosed)) {
          return this[_ensureDoneFuture]();
        }
        if (!dart.notNull(this[_mayAddEvent])) dart.throw(this[_badEventState]());
        this[_closeUnchecked]();
        return this[_ensureDoneFuture]();
      }
      [_closeUnchecked]() {
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_StreamController$()._STATE_CLOSED);
        if (dart.notNull(this.hasListener)) {
          this[_sendDone]();
        } else if (dart.notNull(this[_isInitialState])) {
          this[_ensurePendingEvents]().add(dart.const(new _DelayedDone()));
        }
      }
      [_add](value) {
        dart.as(value, T);
        if (dart.notNull(this.hasListener)) {
          this[_sendData](value);
        } else if (dart.notNull(this[_isInitialState])) {
          this[_ensurePendingEvents]().add(new (_DelayedData$(T))(value));
        }
      }
      [_addError](error, stackTrace) {
        if (dart.notNull(this.hasListener)) {
          this[_sendError](error, stackTrace);
        } else if (dart.notNull(this[_isInitialState])) {
          this[_ensurePendingEvents]().add(new _DelayedError(error, stackTrace));
        }
      }
      [_close]() {
        dart.assert(this[_isAddingStream]);
        let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
        this[_varData] = addState.varData;
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_StreamController$()._STATE_ADDSTREAM);
        addState.complete();
      }
      [_subscribe](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        if (!dart.notNull(this[_isInitialState])) {
          dart.throw(new core.StateError("Stream has already been listened to."));
        }
        let subscription = new _ControllerSubscription(this, onData, onError, onDone, cancelOnError);
        let pendingEvents = this[_pendingEvents];
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_StreamController$()._STATE_SUBSCRIBED);
        if (dart.notNull(this[_isAddingStream])) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          addState.varData = subscription;
          addState.resume();
        } else {
          this[_varData] = subscription;
        }
        subscription[_setPendingEvents](pendingEvents);
        subscription[_guardCallback](dart.fn((() => {
          _runGuarded(this[_onListen]);
        }).bind(this)));
        return dart.as(subscription, StreamSubscription$(T));
      }
      [_recordCancel](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        let result = null;
        if (dart.notNull(this[_isAddingStream])) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          result = addState.cancel();
        }
        this[_varData] = null;
        this[_state] = dart.notNull(this[_state]) & ~(dart.notNull(_StreamController$()._STATE_SUBSCRIBED) | dart.notNull(_StreamController$()._STATE_ADDSTREAM)) | dart.notNull(_StreamController$()._STATE_CANCELED);
        if (this[_onCancel] != null) {
          if (result == null) {
            try {
              result = dart.as(this[_onCancel](), Future);
            } catch (e) {
              let s = dart.stackTrace(e);
              result = new _Future();
              result[_asyncCompleteError](e, s);
            }

          } else {
            result = result.whenComplete(this[_onCancel]);
          }
        }
        const complete = (function() {
          if (this[_doneFuture] != null && dart.notNull(this[_doneFuture][_mayComplete])) {
            this[_doneFuture][_asyncComplete](null);
          }
        }).bind(this);
        dart.fn(complete, dart.void, []);
        if (result != null) {
          result = result.whenComplete(complete);
        } else {
          complete();
        }
        return result;
      }
      [_recordPause](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        if (dart.notNull(this[_isAddingStream])) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          addState.pause();
        }
        _runGuarded(this[_onPause]);
      }
      [_recordResume](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        if (dart.notNull(this[_isAddingStream])) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          addState.resume();
        }
        _runGuarded(this[_onResume]);
      }
    }
    _StreamController[dart.implements] = () => [StreamController$(T), _StreamControllerLifecycle$(T), _EventSink$(T), _EventDispatch$(T)];
    dart.setSignature(_StreamController, {
      constructors: () => ({_StreamController: [_StreamController$(T), []]}),
      methods: () => ({
        [_ensurePendingEvents]: [_StreamImplEvents, []],
        [_badEventState]: [core.Error, []],
        addStream: [Future, [Stream$(T)], {cancelOnError: core.bool}],
        [_ensureDoneFuture]: [Future, []],
        add: [dart.void, [T]],
        addError: [dart.void, [core.Object], [core.StackTrace]],
        close: [Future, []],
        [_closeUnchecked]: [dart.void, []],
        [_add]: [dart.void, [T]],
        [_addError]: [dart.void, [core.Object, core.StackTrace]],
        [_close]: [dart.void, []],
        [_subscribe]: [StreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]],
        [_recordCancel]: [Future, [StreamSubscription$(T)]],
        [_recordPause]: [dart.void, [StreamSubscription$(T)]],
        [_recordResume]: [dart.void, [StreamSubscription$(T)]]
      })
    });
    _StreamController._STATE_INITIAL = 0;
    _StreamController._STATE_SUBSCRIBED = 1;
    _StreamController._STATE_CANCELED = 2;
    _StreamController._STATE_SUBSCRIPTION_MASK = 3;
    _StreamController._STATE_CLOSED = 4;
    _StreamController._STATE_ADDSTREAM = 8;
    return _StreamController;
  });
  let _StreamController = _StreamController$();
  const _SyncStreamControllerDispatch$ = dart.generic(function(T) {
    class _SyncStreamControllerDispatch extends core.Object {
      [_sendData](data) {
        dart.as(data, T);
        this[_subscription][_add](data);
      }
      [_sendError](error, stackTrace) {
        this[_subscription][_addError](error, stackTrace);
      }
      [_sendDone]() {
        this[_subscription][_close]();
      }
    }
    _SyncStreamControllerDispatch[dart.implements] = () => [_StreamController$(T)];
    dart.setSignature(_SyncStreamControllerDispatch, {
      methods: () => ({
        [_sendData]: [dart.void, [T]],
        [_sendError]: [dart.void, [core.Object, core.StackTrace]],
        [_sendDone]: [dart.void, []]
      })
    });
    return _SyncStreamControllerDispatch;
  });
  let _SyncStreamControllerDispatch = _SyncStreamControllerDispatch$();
  const _AsyncStreamControllerDispatch$ = dart.generic(function(T) {
    class _AsyncStreamControllerDispatch extends core.Object {
      [_sendData](data) {
        dart.as(data, T);
        this[_subscription][_addPending](new _DelayedData(data));
      }
      [_sendError](error, stackTrace) {
        this[_subscription][_addPending](new _DelayedError(error, stackTrace));
      }
      [_sendDone]() {
        this[_subscription][_addPending](dart.const(new _DelayedDone()));
      }
    }
    _AsyncStreamControllerDispatch[dart.implements] = () => [_StreamController$(T)];
    dart.setSignature(_AsyncStreamControllerDispatch, {
      methods: () => ({
        [_sendData]: [dart.void, [T]],
        [_sendError]: [dart.void, [core.Object, core.StackTrace]],
        [_sendDone]: [dart.void, []]
      })
    });
    return _AsyncStreamControllerDispatch;
  });
  let _AsyncStreamControllerDispatch = _AsyncStreamControllerDispatch$();
  const _AsyncStreamController$ = dart.generic(function(T) {
    class _AsyncStreamController extends dart.mixin(_StreamController$(T), _AsyncStreamControllerDispatch$(T)) {
      _AsyncStreamController(onListen, onPause, onResume, onCancel) {
        this[_onListen] = onListen;
        this[_onPause] = onPause;
        this[_onResume] = onResume;
        this[_onCancel] = onCancel;
        super._StreamController();
      }
    }
    dart.setSignature(_AsyncStreamController, {
      constructors: () => ({_AsyncStreamController: [_AsyncStreamController$(T), [dart.functionType(dart.void, []), dart.functionType(dart.void, []), dart.functionType(dart.void, []), dart.functionType(dart.dynamic, [])]]})
    });
    return _AsyncStreamController;
  });
  let _AsyncStreamController = _AsyncStreamController$();
  const _SyncStreamController$ = dart.generic(function(T) {
    class _SyncStreamController extends dart.mixin(_StreamController$(T), _SyncStreamControllerDispatch$(T)) {
      _SyncStreamController(onListen, onPause, onResume, onCancel) {
        this[_onListen] = onListen;
        this[_onPause] = onPause;
        this[_onResume] = onResume;
        this[_onCancel] = onCancel;
        super._StreamController();
      }
    }
    dart.setSignature(_SyncStreamController, {
      constructors: () => ({_SyncStreamController: [_SyncStreamController$(T), [dart.functionType(dart.void, []), dart.functionType(dart.void, []), dart.functionType(dart.void, []), dart.functionType(dart.dynamic, [])]]})
    });
    return _SyncStreamController;
  });
  let _SyncStreamController = _SyncStreamController$();
  class _NoCallbacks extends core.Object {
    get [_onListen]() {
      return null;
    }
    get [_onPause]() {
      return null;
    }
    get [_onResume]() {
      return null;
    }
    get [_onCancel]() {
      return null;
    }
  }
  const _NoCallbackAsyncStreamController$ = dart.generic(function(T) {
    class _NoCallbackAsyncStreamController extends dart.mixin(_StreamController$(T), _AsyncStreamControllerDispatch$(T), _NoCallbacks) {
      _NoCallbackAsyncStreamController() {
        super._StreamController(...arguments);
      }
    }
    return _NoCallbackAsyncStreamController;
  });
  let _NoCallbackAsyncStreamController = _NoCallbackAsyncStreamController$();
  const _NoCallbackSyncStreamController$ = dart.generic(function(T) {
    class _NoCallbackSyncStreamController extends dart.mixin(_StreamController$(T), _SyncStreamControllerDispatch$(T), _NoCallbacks) {
      _NoCallbackSyncStreamController() {
        super._StreamController(...arguments);
      }
    }
    return _NoCallbackSyncStreamController;
  });
  let _NoCallbackSyncStreamController = _NoCallbackSyncStreamController$();
  const _NotificationHandler = dart.typedef('_NotificationHandler', () => dart.functionType(dart.dynamic, []));
  function _runGuarded(notificationHandler) {
    if (notificationHandler == null) return null;
    try {
      let result = notificationHandler();
      if (dart.is(result, Future)) return result;
      return null;
    } catch (e) {
      let s = dart.stackTrace(e);
      Zone.current.handleUncaughtError(e, s);
    }

  }
  dart.fn(_runGuarded, Future, [_NotificationHandler]);
  const _target = Symbol('_target');
  const _StreamSinkWrapper$ = dart.generic(function(T) {
    class _StreamSinkWrapper extends core.Object {
      _StreamSinkWrapper(target) {
        this[_target] = target;
      }
      add(data) {
        dart.as(data, T);
        this[_target].add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        this[_target].addError(error, stackTrace);
      }
      close() {
        return this[_target].close();
      }
      addStream(source, opts) {
        dart.as(source, Stream$(T));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : true;
        return this[_target].addStream(source, {cancelOnError: cancelOnError});
      }
      get done() {
        return this[_target].done;
      }
    }
    _StreamSinkWrapper[dart.implements] = () => [StreamSink$(T)];
    dart.setSignature(_StreamSinkWrapper, {
      constructors: () => ({_StreamSinkWrapper: [_StreamSinkWrapper$(T), [StreamController]]}),
      methods: () => ({
        add: [dart.void, [T]],
        addError: [dart.void, [core.Object], [core.StackTrace]],
        close: [Future, []],
        addStream: [Future, [Stream$(T)], {cancelOnError: core.bool}]
      })
    });
    return _StreamSinkWrapper;
  });
  let _StreamSinkWrapper = _StreamSinkWrapper$();
  const _AddStreamState$ = dart.generic(function(T) {
    class _AddStreamState extends core.Object {
      _AddStreamState(controller, source, cancelOnError) {
        this.addStreamFuture = new _Future();
        this.addSubscription = source.listen(dart.bind(controller, _add), {onError: dart.as(dart.notNull(cancelOnError) ? _AddStreamState$().makeErrorHandler(controller) : dart.bind(controller, _addError), core.Function), onDone: dart.bind(controller, _close), cancelOnError: cancelOnError});
      }
      static makeErrorHandler(controller) {
        return dart.fn((e, s) => {
          controller[_addError](e, s);
          controller[_close]();
        }, dart.dynamic, [dart.dynamic, core.StackTrace]);
      }
      pause() {
        this.addSubscription.pause();
      }
      resume() {
        this.addSubscription.resume();
      }
      cancel() {
        let cancel2 = this.addSubscription.cancel();
        if (cancel2 == null) {
          this.addStreamFuture[_asyncComplete](null);
          return null;
        }
        return cancel2.whenComplete(dart.fn((() => {
          this.addStreamFuture[_asyncComplete](null);
        }).bind(this)));
      }
      complete() {
        this.addStreamFuture[_asyncComplete](null);
      }
    }
    dart.setSignature(_AddStreamState, {
      constructors: () => ({_AddStreamState: [_AddStreamState$(T), [_EventSink$(T), Stream, core.bool]]}),
      methods: () => ({
        pause: [dart.void, []],
        resume: [dart.void, []],
        cancel: [Future, []],
        complete: [dart.void, []]
      }),
      statics: () => ({makeErrorHandler: [dart.dynamic, [_EventSink]]}),
      names: ['makeErrorHandler']
    });
    return _AddStreamState;
  });
  let _AddStreamState = _AddStreamState$();
  const _StreamControllerAddStreamState$ = dart.generic(function(T) {
    class _StreamControllerAddStreamState extends _AddStreamState$(T) {
      _StreamControllerAddStreamState(controller, varData, source, cancelOnError) {
        this.varData = varData;
        super._AddStreamState(dart.as(controller, _EventSink$(T)), source, cancelOnError);
        if (dart.notNull(controller.isPaused)) {
          this.addSubscription.pause();
        }
      }
    }
    dart.setSignature(_StreamControllerAddStreamState, {
      constructors: () => ({_StreamControllerAddStreamState: [_StreamControllerAddStreamState$(T), [_StreamController, dart.dynamic, Stream, core.bool]]})
    });
    return _StreamControllerAddStreamState;
  });
  let _StreamControllerAddStreamState = _StreamControllerAddStreamState$();
  const _EventSink$ = dart.generic(function(T) {
    class _EventSink extends core.Object {}
    return _EventSink;
  });
  let _EventSink = _EventSink$();
  const _EventDispatch$ = dart.generic(function(T) {
    class _EventDispatch extends core.Object {}
    return _EventDispatch;
  });
  let _EventDispatch = _EventDispatch$();
  const _EventGenerator = dart.typedef('_EventGenerator', () => dart.functionType(_PendingEvents, []));
  const _isUsed = Symbol('_isUsed');
  const _GeneratedStreamImpl$ = dart.generic(function(T) {
    class _GeneratedStreamImpl extends _StreamImpl$(T) {
      _GeneratedStreamImpl(pending) {
        this[_pending] = pending;
        this[_isUsed] = false;
      }
      [_createSubscription](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        if (dart.notNull(this[_isUsed])) dart.throw(new core.StateError("Stream has already been listened to."));
        this[_isUsed] = true;
        let _ = new (_BufferingStreamSubscription$(T))(onData, onError, onDone, cancelOnError);
        _[_setPendingEvents](this[_pending]());
        return _;
      }
    }
    dart.setSignature(_GeneratedStreamImpl, {
      constructors: () => ({_GeneratedStreamImpl: [_GeneratedStreamImpl$(T), [_EventGenerator]]}),
      methods: () => ({[_createSubscription]: [StreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]]})
    });
    return _GeneratedStreamImpl;
  });
  let _GeneratedStreamImpl = _GeneratedStreamImpl$();
  const _eventScheduled = Symbol('_eventScheduled');
  class _PendingEvents extends core.Object {
    _PendingEvents() {
      this[_state] = _PendingEvents._STATE_UNSCHEDULED;
    }
    get isScheduled() {
      return this[_state] == _PendingEvents._STATE_SCHEDULED;
    }
    get [_eventScheduled]() {
      return dart.notNull(this[_state]) >= dart.notNull(_PendingEvents._STATE_SCHEDULED);
    }
    schedule(dispatch) {
      if (dart.notNull(this.isScheduled)) return;
      dart.assert(!dart.notNull(this.isEmpty));
      if (dart.notNull(this[_eventScheduled])) {
        dart.assert(this[_state] == _PendingEvents._STATE_CANCELED);
        this[_state] = _PendingEvents._STATE_SCHEDULED;
        return;
      }
      scheduleMicrotask(dart.fn((() => {
        let oldState = this[_state];
        this[_state] = _PendingEvents._STATE_UNSCHEDULED;
        if (oldState == _PendingEvents._STATE_CANCELED) return;
        this.handleNext(dispatch);
      }).bind(this), dart.void, []));
      this[_state] = _PendingEvents._STATE_SCHEDULED;
    }
    cancelSchedule() {
      if (dart.notNull(this.isScheduled)) this[_state] = _PendingEvents._STATE_CANCELED;
    }
  }
  dart.setSignature(_PendingEvents, {
    methods: () => ({
      schedule: [dart.void, [_EventDispatch]],
      cancelSchedule: [dart.void, []]
    })
  });
  _PendingEvents._STATE_UNSCHEDULED = 0;
  _PendingEvents._STATE_SCHEDULED = 1;
  _PendingEvents._STATE_CANCELED = 3;
  const _iterator = Symbol('_iterator');
  const _IterablePendingEvents$ = dart.generic(function(T) {
    class _IterablePendingEvents extends _PendingEvents {
      _IterablePendingEvents(data) {
        this[_iterator] = data[dartx.iterator];
        super._PendingEvents();
      }
      get isEmpty() {
        return this[_iterator] == null;
      }
      handleNext(dispatch) {
        if (this[_iterator] == null) {
          dart.throw(new core.StateError("No events pending."));
        }
        let isDone = null;
        try {
          isDone = !dart.notNull(this[_iterator].moveNext());
        } catch (e) {
          let s = dart.stackTrace(e);
          this[_iterator] = null;
          dispatch[_sendError](e, s);
          return;
        }

        if (!dart.notNull(isDone)) {
          dispatch[_sendData](this[_iterator].current);
        } else {
          this[_iterator] = null;
          dispatch[_sendDone]();
        }
      }
      clear() {
        if (dart.notNull(this.isScheduled)) this.cancelSchedule();
        this[_iterator] = null;
      }
    }
    dart.setSignature(_IterablePendingEvents, {
      constructors: () => ({_IterablePendingEvents: [_IterablePendingEvents$(T), [core.Iterable$(T)]]}),
      methods: () => ({
        handleNext: [dart.void, [_EventDispatch]],
        clear: [dart.void, []]
      })
    });
    return _IterablePendingEvents;
  });
  let _IterablePendingEvents = _IterablePendingEvents$();
  const _DataHandler$ = dart.generic(function(T) {
    const _DataHandler = dart.typedef('_DataHandler', () => dart.functionType(dart.void, [T]));
    return _DataHandler;
  });
  let _DataHandler = _DataHandler$();
  const _DoneHandler = dart.typedef('_DoneHandler', () => dart.functionType(dart.void, []));
  function _nullDataHandler(value) {
  }
  dart.fn(_nullDataHandler, dart.void, [dart.dynamic]);
  function _nullErrorHandler(error, stackTrace) {
    if (stackTrace === void 0) stackTrace = null;
    Zone.current.handleUncaughtError(error, stackTrace);
  }
  dart.fn(_nullErrorHandler, dart.void, [dart.dynamic], [core.StackTrace]);
  function _nullDoneHandler() {
  }
  dart.fn(_nullDoneHandler, dart.void, []);
  const _DelayedEvent$ = dart.generic(function(T) {
    class _DelayedEvent extends core.Object {
      _DelayedEvent() {
        this.next = null;
      }
    }
    return _DelayedEvent;
  });
  let _DelayedEvent = _DelayedEvent$();
  const _DelayedData$ = dart.generic(function(T) {
    class _DelayedData extends _DelayedEvent$(T) {
      _DelayedData(value) {
        this.value = value;
        super._DelayedEvent();
      }
      perform(dispatch) {
        dart.as(dispatch, _EventDispatch$(T));
        dispatch[_sendData](this.value);
      }
    }
    dart.setSignature(_DelayedData, {
      constructors: () => ({_DelayedData: [_DelayedData$(T), [T]]}),
      methods: () => ({perform: [dart.void, [_EventDispatch$(T)]]})
    });
    return _DelayedData;
  });
  let _DelayedData = _DelayedData$();
  class _DelayedError extends _DelayedEvent {
    _DelayedError(error, stackTrace) {
      this.error = error;
      this.stackTrace = stackTrace;
      super._DelayedEvent();
    }
    perform(dispatch) {
      dispatch[_sendError](this.error, this.stackTrace);
    }
  }
  dart.setSignature(_DelayedError, {
    constructors: () => ({_DelayedError: [_DelayedError, [dart.dynamic, core.StackTrace]]}),
    methods: () => ({perform: [dart.void, [_EventDispatch]]})
  });
  class _DelayedDone extends core.Object {
    _DelayedDone() {
    }
    perform(dispatch) {
      dispatch[_sendDone]();
    }
    get next() {
      return null;
    }
    set next(_) {
      dart.throw(new core.StateError("No events after a done."));
    }
  }
  _DelayedDone[dart.implements] = () => [_DelayedEvent];
  dart.setSignature(_DelayedDone, {
    constructors: () => ({_DelayedDone: [_DelayedDone, []]}),
    methods: () => ({perform: [dart.void, [_EventDispatch]]})
  });
  class _StreamImplEvents extends _PendingEvents {
    _StreamImplEvents() {
      this.firstPendingEvent = null;
      this.lastPendingEvent = null;
      super._PendingEvents();
    }
    get isEmpty() {
      return this.lastPendingEvent == null;
    }
    add(event) {
      if (this.lastPendingEvent == null) {
        this.firstPendingEvent = this.lastPendingEvent = event;
      } else {
        this.lastPendingEvent = this.lastPendingEvent.next = event;
      }
    }
    handleNext(dispatch) {
      dart.assert(!dart.notNull(this.isScheduled));
      let event = this.firstPendingEvent;
      this.firstPendingEvent = event.next;
      if (this.firstPendingEvent == null) {
        this.lastPendingEvent = null;
      }
      event.perform(dispatch);
    }
    clear() {
      if (dart.notNull(this.isScheduled)) this.cancelSchedule();
      this.firstPendingEvent = this.lastPendingEvent = null;
    }
  }
  dart.setSignature(_StreamImplEvents, {
    methods: () => ({
      add: [dart.void, [_DelayedEvent]],
      handleNext: [dart.void, [_EventDispatch]],
      clear: [dart.void, []]
    })
  });
  const _unlink = Symbol('_unlink');
  const _insertBefore = Symbol('_insertBefore');
  class _BroadcastLinkedList extends core.Object {
    _BroadcastLinkedList() {
      this[_next] = null;
      this[_previous] = null;
    }
    [_unlink]() {
      this[_previous][_next] = this[_next];
      this[_next][_previous] = this[_previous];
      this[_next] = this[_previous] = this;
    }
    [_insertBefore](newNext) {
      let newPrevious = newNext[_previous];
      newPrevious[_next] = this;
      newNext[_previous] = this[_previous];
      this[_previous][_next] = newNext;
      this[_previous] = newPrevious;
    }
  }
  dart.setSignature(_BroadcastLinkedList, {
    methods: () => ({
      [_unlink]: [dart.void, []],
      [_insertBefore]: [dart.void, [_BroadcastLinkedList]]
    })
  });
  const _broadcastCallback = dart.typedef('_broadcastCallback', () => dart.functionType(dart.void, [StreamSubscription]));
  const _schedule = Symbol('_schedule');
  const _isSent = Symbol('_isSent');
  const _isScheduled = Symbol('_isScheduled');
  const _DoneStreamSubscription$ = dart.generic(function(T) {
    class _DoneStreamSubscription extends core.Object {
      _DoneStreamSubscription(onDone) {
        this[_onDone] = onDone;
        this[_zone] = Zone.current;
        this[_state] = 0;
        this[_schedule]();
      }
      get [_isSent]() {
        return (dart.notNull(this[_state]) & dart.notNull(_DoneStreamSubscription$()._DONE_SENT)) != 0;
      }
      get [_isScheduled]() {
        return (dart.notNull(this[_state]) & dart.notNull(_DoneStreamSubscription$()._SCHEDULED)) != 0;
      }
      get isPaused() {
        return dart.notNull(this[_state]) >= dart.notNull(_DoneStreamSubscription$()._PAUSED);
      }
      [_schedule]() {
        if (dart.notNull(this[_isScheduled])) return;
        this[_zone].scheduleMicrotask(dart.bind(this, _sendDone));
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_DoneStreamSubscription$()._SCHEDULED);
      }
      onData(handleData) {
        dart.as(handleData, dart.functionType(dart.void, [T]));
      }
      onError(handleError) {}
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
        this[_onDone] = handleDone;
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0) resumeSignal = null;
        this[_state] = dart.notNull(this[_state]) + dart.notNull(_DoneStreamSubscription$()._PAUSED);
        if (resumeSignal != null) resumeSignal.whenComplete(dart.bind(this, 'resume'));
      }
      resume() {
        if (dart.notNull(this.isPaused)) {
          this[_state] = dart.notNull(this[_state]) - dart.notNull(_DoneStreamSubscription$()._PAUSED);
          if (!dart.notNull(this.isPaused) && !dart.notNull(this[_isSent])) {
            this[_schedule]();
          }
        }
      }
      cancel() {
        return null;
      }
      asFuture(futureValue) {
        if (futureValue === void 0) futureValue = null;
        let result = new _Future();
        this[_onDone] = dart.fn(() => {
          result[_completeWithValue](null);
        }, dart.void, []);
        return result;
      }
      [_sendDone]() {
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_DoneStreamSubscription$()._SCHEDULED);
        if (dart.notNull(this.isPaused)) return;
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_DoneStreamSubscription$()._DONE_SENT);
        if (this[_onDone] != null) this[_zone].runGuarded(this[_onDone]);
      }
    }
    _DoneStreamSubscription[dart.implements] = () => [StreamSubscription$(T)];
    dart.setSignature(_DoneStreamSubscription, {
      constructors: () => ({_DoneStreamSubscription: [_DoneStreamSubscription$(T), [_DoneHandler]]}),
      methods: () => ({
        [_schedule]: [dart.void, []],
        onData: [dart.void, [dart.functionType(dart.void, [T])]],
        onError: [dart.void, [core.Function]],
        onDone: [dart.void, [dart.functionType(dart.void, [])]],
        pause: [dart.void, [], [Future]],
        resume: [dart.void, []],
        cancel: [Future, []],
        asFuture: [Future, [], [dart.dynamic]],
        [_sendDone]: [dart.void, []]
      })
    });
    _DoneStreamSubscription._DONE_SENT = 1;
    _DoneStreamSubscription._SCHEDULED = 2;
    _DoneStreamSubscription._PAUSED = 4;
    return _DoneStreamSubscription;
  });
  let _DoneStreamSubscription = _DoneStreamSubscription$();
  const _source = Symbol('_source');
  const _onListenHandler = Symbol('_onListenHandler');
  const _onCancelHandler = Symbol('_onCancelHandler');
  const _cancelSubscription = Symbol('_cancelSubscription');
  const _pauseSubscription = Symbol('_pauseSubscription');
  const _resumeSubscription = Symbol('_resumeSubscription');
  const _isSubscriptionPaused = Symbol('_isSubscriptionPaused');
  const _AsBroadcastStream$ = dart.generic(function(T) {
    class _AsBroadcastStream extends Stream$(T) {
      _AsBroadcastStream(source, onListenHandler, onCancelHandler) {
        this[_source] = source;
        this[_onListenHandler] = dart.as(Zone.current.registerUnaryCallback(onListenHandler), _broadcastCallback);
        this[_onCancelHandler] = dart.as(Zone.current.registerUnaryCallback(onCancelHandler), _broadcastCallback);
        this[_zone] = Zone.current;
        this[_controller] = null;
        this[_subscription] = null;
        super.Stream();
        this[_controller] = new (_AsBroadcastStreamController$(T))(dart.bind(this, _onListen), dart.bind(this, _onCancel));
      }
      get isBroadcast() {
        return true;
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        if (this[_controller] == null || dart.notNull(this[_controller].isClosed)) {
          return new (_DoneStreamSubscription$(T))(onDone);
        }
        if (this[_subscription] == null) {
          this[_subscription] = this[_source].listen(dart.bind(this[_controller], 'add'), {onError: dart.bind(this[_controller], 'addError'), onDone: dart.bind(this[_controller], 'close')});
        }
        cancelOnError = core.identical(true, cancelOnError);
        return this[_controller][_subscribe](onData, onError, onDone, cancelOnError);
      }
      [_onCancel]() {
        let shutdown = this[_controller] == null || dart.notNull(this[_controller].isClosed);
        if (this[_onCancelHandler] != null) {
          this[_zone].runUnary(this[_onCancelHandler], new _BroadcastSubscriptionWrapper(this));
        }
        if (shutdown) {
          if (this[_subscription] != null) {
            this[_subscription].cancel();
            this[_subscription] = null;
          }
        }
      }
      [_onListen]() {
        if (this[_onListenHandler] != null) {
          this[_zone].runUnary(this[_onListenHandler], new _BroadcastSubscriptionWrapper(this));
        }
      }
      [_cancelSubscription]() {
        if (this[_subscription] == null) return;
        let subscription = this[_subscription];
        this[_subscription] = null;
        this[_controller] = null;
        subscription.cancel();
      }
      [_pauseSubscription](resumeSignal) {
        if (this[_subscription] == null) return;
        this[_subscription].pause(resumeSignal);
      }
      [_resumeSubscription]() {
        if (this[_subscription] == null) return;
        this[_subscription].resume();
      }
      get [_isSubscriptionPaused]() {
        if (this[_subscription] == null) return false;
        return this[_subscription].isPaused;
      }
    }
    dart.setSignature(_AsBroadcastStream, {
      constructors: () => ({_AsBroadcastStream: [_AsBroadcastStream$(T), [Stream$(T), dart.functionType(dart.void, [StreamSubscription]), dart.functionType(dart.void, [StreamSubscription])]]}),
      methods: () => ({
        listen: [StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}],
        [_onCancel]: [dart.void, []],
        [_onListen]: [dart.void, []],
        [_cancelSubscription]: [dart.void, []],
        [_pauseSubscription]: [dart.void, [Future]],
        [_resumeSubscription]: [dart.void, []]
      })
    });
    return _AsBroadcastStream;
  });
  let _AsBroadcastStream = _AsBroadcastStream$();
  const _BroadcastSubscriptionWrapper$ = dart.generic(function(T) {
    class _BroadcastSubscriptionWrapper extends core.Object {
      _BroadcastSubscriptionWrapper(stream) {
        this[_stream] = stream;
      }
      onData(handleData) {
        dart.as(handleData, dart.functionType(dart.void, [T]));
        dart.throw(new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription."));
      }
      onError(handleError) {
        dart.throw(new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription."));
      }
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
        dart.throw(new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription."));
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0) resumeSignal = null;
        this[_stream][_pauseSubscription](resumeSignal);
      }
      resume() {
        this[_stream][_resumeSubscription]();
      }
      cancel() {
        this[_stream][_cancelSubscription]();
        return null;
      }
      get isPaused() {
        return this[_stream][_isSubscriptionPaused];
      }
      asFuture(futureValue) {
        if (futureValue === void 0) futureValue = null;
        dart.throw(new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription."));
      }
    }
    _BroadcastSubscriptionWrapper[dart.implements] = () => [StreamSubscription$(T)];
    dart.setSignature(_BroadcastSubscriptionWrapper, {
      constructors: () => ({_BroadcastSubscriptionWrapper: [_BroadcastSubscriptionWrapper$(T), [_AsBroadcastStream]]}),
      methods: () => ({
        onData: [dart.void, [dart.functionType(dart.void, [T])]],
        onError: [dart.void, [core.Function]],
        onDone: [dart.void, [dart.functionType(dart.void, [])]],
        pause: [dart.void, [], [Future]],
        resume: [dart.void, []],
        cancel: [Future, []],
        asFuture: [Future, [], [dart.dynamic]]
      })
    });
    return _BroadcastSubscriptionWrapper;
  });
  let _BroadcastSubscriptionWrapper = _BroadcastSubscriptionWrapper$();
  const _current = Symbol('_current');
  const _futureOrPrefetch = Symbol('_futureOrPrefetch');
  const _clear = Symbol('_clear');
  const _StreamIteratorImpl$ = dart.generic(function(T) {
    class _StreamIteratorImpl extends core.Object {
      _StreamIteratorImpl(stream) {
        this[_subscription] = null;
        this[_current] = null;
        this[_futureOrPrefetch] = null;
        this[_state] = _StreamIteratorImpl$()._STATE_FOUND;
        this[_subscription] = stream.listen(dart.bind(this, _onData), {onError: dart.bind(this, _onError), onDone: dart.bind(this, _onDone), cancelOnError: true});
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (this[_state] == _StreamIteratorImpl$()._STATE_DONE) {
          return new (_Future$(core.bool)).immediate(false);
        }
        if (this[_state] == _StreamIteratorImpl$()._STATE_MOVING) {
          dart.throw(new core.StateError("Already waiting for next."));
        }
        if (this[_state] == _StreamIteratorImpl$()._STATE_FOUND) {
          this[_state] = _StreamIteratorImpl$()._STATE_MOVING;
          this[_current] = null;
          this[_futureOrPrefetch] = new (_Future$(core.bool))();
          return dart.as(this[_futureOrPrefetch], Future$(core.bool));
        } else {
          dart.assert(dart.notNull(this[_state]) >= dart.notNull(_StreamIteratorImpl$()._STATE_EXTRA_DATA));
          switch (this[_state]) {
            case _StreamIteratorImpl$()._STATE_EXTRA_DATA:
            {
              this[_state] = _StreamIteratorImpl$()._STATE_FOUND;
              this[_current] = dart.as(this[_futureOrPrefetch], T);
              this[_futureOrPrefetch] = null;
              this[_subscription].resume();
              return new (_Future$(core.bool)).immediate(true);
            }
            case _StreamIteratorImpl$()._STATE_EXTRA_ERROR:
            {
              let prefetch = dart.as(this[_futureOrPrefetch], AsyncError);
              this[_clear]();
              return new (_Future$(core.bool)).immediateError(prefetch.error, prefetch.stackTrace);
            }
            case _StreamIteratorImpl$()._STATE_EXTRA_DONE:
            {
              this[_clear]();
              return new (_Future$(core.bool)).immediate(false);
            }
          }
        }
      }
      [_clear]() {
        this[_subscription] = null;
        this[_futureOrPrefetch] = null;
        this[_current] = null;
        this[_state] = _StreamIteratorImpl$()._STATE_DONE;
      }
      cancel() {
        let subscription = this[_subscription];
        if (subscription == null) return null;
        if (this[_state] == _StreamIteratorImpl$()._STATE_MOVING) {
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_clear]();
          hasNext[_complete](false);
        } else {
          this[_clear]();
        }
        return subscription.cancel();
      }
      [_onData](data) {
        dart.as(data, T);
        if (this[_state] == _StreamIteratorImpl$()._STATE_MOVING) {
          this[_current] = data;
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_futureOrPrefetch] = null;
          this[_state] = _StreamIteratorImpl$()._STATE_FOUND;
          hasNext[_complete](true);
          return;
        }
        this[_subscription].pause();
        dart.assert(this[_futureOrPrefetch] == null);
        this[_futureOrPrefetch] = data;
        this[_state] = _StreamIteratorImpl$()._STATE_EXTRA_DATA;
      }
      [_onError](error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        if (this[_state] == _StreamIteratorImpl$()._STATE_MOVING) {
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_clear]();
          hasNext[_completeError](error, stackTrace);
          return;
        }
        this[_subscription].pause();
        dart.assert(this[_futureOrPrefetch] == null);
        this[_futureOrPrefetch] = new AsyncError(error, stackTrace);
        this[_state] = _StreamIteratorImpl$()._STATE_EXTRA_ERROR;
      }
      [_onDone]() {
        if (this[_state] == _StreamIteratorImpl$()._STATE_MOVING) {
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_clear]();
          hasNext[_complete](false);
          return;
        }
        this[_subscription].pause();
        this[_futureOrPrefetch] = null;
        this[_state] = _StreamIteratorImpl$()._STATE_EXTRA_DONE;
      }
    }
    _StreamIteratorImpl[dart.implements] = () => [StreamIterator$(T)];
    dart.setSignature(_StreamIteratorImpl, {
      constructors: () => ({_StreamIteratorImpl: [_StreamIteratorImpl$(T), [Stream$(T)]]}),
      methods: () => ({
        moveNext: [Future$(core.bool), []],
        [_clear]: [dart.void, []],
        cancel: [Future, []],
        [_onData]: [dart.void, [T]],
        [_onError]: [dart.void, [core.Object], [core.StackTrace]],
        [_onDone]: [dart.void, []]
      })
    });
    _StreamIteratorImpl._STATE_FOUND = 0;
    _StreamIteratorImpl._STATE_DONE = 1;
    _StreamIteratorImpl._STATE_MOVING = 2;
    _StreamIteratorImpl._STATE_EXTRA_DATA = 3;
    _StreamIteratorImpl._STATE_EXTRA_ERROR = 4;
    _StreamIteratorImpl._STATE_EXTRA_DONE = 5;
    return _StreamIteratorImpl;
  });
  let _StreamIteratorImpl = _StreamIteratorImpl$();
  const __CastType18$ = dart.generic(function(T) {
    const __CastType18 = dart.typedef('__CastType18', () => dart.functionType(dart.void, [T]));
    return __CastType18;
  });
  let __CastType18 = __CastType18$();
  const __CastType20 = dart.typedef('__CastType20', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  const __CastType23 = dart.typedef('__CastType23', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  function _runUserCode(userCode, onSuccess, onError) {
    try {
      dart.dcall(onSuccess, userCode());
    } catch (e) {
      let s = dart.stackTrace(e);
      let replacement = Zone.current.errorCallback(e, s);
      if (replacement == null) {
        dart.dcall(onError, e, s);
      } else {
        let error = _nonNullError(replacement.error);
        let stackTrace = replacement.stackTrace;
        dart.dcall(onError, error, stackTrace);
      }
    }

  }
  dart.fn(_runUserCode, dart.dynamic, [dart.functionType(dart.dynamic, []), dart.functionType(dart.dynamic, [dart.dynamic]), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])]);
  function _cancelAndError(subscription, future, error, stackTrace) {
    let cancelFuture = subscription.cancel();
    if (dart.is(cancelFuture, Future)) {
      cancelFuture.whenComplete(dart.fn(() => future[_completeError](error, stackTrace), dart.void, []));
    } else {
      future[_completeError](error, stackTrace);
    }
  }
  dart.fn(_cancelAndError, dart.void, [StreamSubscription, _Future, dart.dynamic, core.StackTrace]);
  function _cancelAndErrorWithReplacement(subscription, future, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _cancelAndError(subscription, future, error, stackTrace);
  }
  dart.fn(_cancelAndErrorWithReplacement, dart.void, [StreamSubscription, _Future, dart.dynamic, core.StackTrace]);
  function _cancelAndErrorClosure(subscription, future) {
    return dart.fn((error, stackTrace) => _cancelAndError(subscription, future, error, stackTrace), dart.void, [dart.dynamic, core.StackTrace]);
  }
  dart.fn(_cancelAndErrorClosure, dart.dynamic, [StreamSubscription, _Future]);
  function _cancelAndValue(subscription, future, value) {
    let cancelFuture = subscription.cancel();
    if (dart.is(cancelFuture, Future)) {
      cancelFuture.whenComplete(dart.fn(() => future[_complete](value), dart.void, []));
    } else {
      future[_complete](value);
    }
  }
  dart.fn(_cancelAndValue, dart.void, [StreamSubscription, _Future, dart.dynamic]);
  const _handleData = Symbol('_handleData');
  const _handleError = Symbol('_handleError');
  const _handleDone = Symbol('_handleDone');
  const _ForwardingStream$ = dart.generic(function(S, T) {
    class _ForwardingStream extends Stream$(T) {
      _ForwardingStream(source) {
        this[_source] = source;
        super.Stream();
      }
      get isBroadcast() {
        return this[_source].isBroadcast;
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        cancelOnError = core.identical(true, cancelOnError);
        return this[_createSubscription](onData, onError, onDone, cancelOnError);
      }
      [_createSubscription](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        return new (_ForwardingStreamSubscription$(S, T))(this, onData, onError, onDone, cancelOnError);
      }
      [_handleData](data, sink) {
        dart.as(data, S);
        dart.as(sink, _EventSink$(T));
        let outputData = data;
        sink[_add](dart.as(outputData, T));
      }
      [_handleError](error, stackTrace, sink) {
        dart.as(sink, _EventSink$(T));
        sink[_addError](error, stackTrace);
      }
      [_handleDone](sink) {
        dart.as(sink, _EventSink$(T));
        sink[_close]();
      }
    }
    dart.setSignature(_ForwardingStream, {
      constructors: () => ({_ForwardingStream: [_ForwardingStream$(S, T), [Stream$(S)]]}),
      methods: () => ({
        listen: [StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}],
        [_createSubscription]: [StreamSubscription$(T), [dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]],
        [_handleData]: [dart.void, [S, _EventSink$(T)]],
        [_handleError]: [dart.void, [dart.dynamic, core.StackTrace, _EventSink$(T)]],
        [_handleDone]: [dart.void, [_EventSink$(T)]]
      })
    });
    return _ForwardingStream;
  });
  let _ForwardingStream = _ForwardingStream$();
  const _ForwardingStreamSubscription$ = dart.generic(function(S, T) {
    class _ForwardingStreamSubscription extends _BufferingStreamSubscription$(T) {
      _ForwardingStreamSubscription(stream, onData, onError, onDone, cancelOnError) {
        this[_stream] = stream;
        this[_subscription] = null;
        super._BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
        this[_subscription] = this[_stream][_source].listen(dart.bind(this, _handleData), {onError: dart.bind(this, _handleError), onDone: dart.bind(this, _handleDone)});
      }
      [_add](data) {
        dart.as(data, T);
        if (dart.notNull(this[_isClosed])) return;
        super[_add](data);
      }
      [_addError](error, stackTrace) {
        if (dart.notNull(this[_isClosed])) return;
        super[_addError](error, stackTrace);
      }
      [_onPause]() {
        if (this[_subscription] == null) return;
        this[_subscription].pause();
      }
      [_onResume]() {
        if (this[_subscription] == null) return;
        this[_subscription].resume();
      }
      [_onCancel]() {
        if (this[_subscription] != null) {
          let subscription = this[_subscription];
          this[_subscription] = null;
          subscription.cancel();
        }
        return null;
      }
      [_handleData](data) {
        dart.as(data, S);
        this[_stream][_handleData](data, this);
      }
      [_handleError](error, stackTrace) {
        this[_stream][_handleError](error, stackTrace, this);
      }
      [_handleDone]() {
        this[_stream][_handleDone](this);
      }
    }
    dart.setSignature(_ForwardingStreamSubscription, {
      constructors: () => ({_ForwardingStreamSubscription: [_ForwardingStreamSubscription$(S, T), [_ForwardingStream$(S, T), dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]]}),
      methods: () => ({
        [_add]: [dart.void, [T]],
        [_handleData]: [dart.void, [S]],
        [_handleError]: [dart.void, [dart.dynamic, core.StackTrace]],
        [_handleDone]: [dart.void, []]
      })
    });
    return _ForwardingStreamSubscription;
  });
  let _ForwardingStreamSubscription = _ForwardingStreamSubscription$();
  const _Predicate$ = dart.generic(function(T) {
    const _Predicate = dart.typedef('_Predicate', () => dart.functionType(core.bool, [T]));
    return _Predicate;
  });
  let _Predicate = _Predicate$();
  function _addErrorWithReplacement(sink, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, dart.as(stackTrace, core.StackTrace));
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    sink[_addError](error, dart.as(stackTrace, core.StackTrace));
  }
  dart.fn(_addErrorWithReplacement, dart.void, [_EventSink, dart.dynamic, dart.dynamic]);
  const _test = Symbol('_test');
  const _WhereStream$ = dart.generic(function(T) {
    class _WhereStream extends _ForwardingStream$(T, T) {
      _WhereStream(source, test) {
        this[_test] = test;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        let satisfies = null;
        try {
          satisfies = this[_test](inputEvent);
        } catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          return;
        }

        if (dart.notNull(satisfies)) {
          sink[_add](inputEvent);
        }
      }
    }
    dart.setSignature(_WhereStream, {
      constructors: () => ({_WhereStream: [_WhereStream$(T), [Stream$(T), dart.functionType(core.bool, [T])]]}),
      methods: () => ({[_handleData]: [dart.void, [T, _EventSink$(T)]]})
    });
    return _WhereStream;
  });
  let _WhereStream = _WhereStream$();
  const _Transformation$ = dart.generic(function(S, T) {
    const _Transformation = dart.typedef('_Transformation', () => dart.functionType(T, [S]));
    return _Transformation;
  });
  let _Transformation = _Transformation$();
  const _transform = Symbol('_transform');
  const _MapStream$ = dart.generic(function(S, T) {
    class _MapStream extends _ForwardingStream$(S, T) {
      _MapStream(source, transform) {
        this[_transform] = transform;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, S);
        dart.as(sink, _EventSink$(T));
        let outputEvent = null;
        try {
          outputEvent = dart.as(dart.dcall(this[_transform], inputEvent), T);
        } catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          return;
        }

        sink[_add](outputEvent);
      }
    }
    dart.setSignature(_MapStream, {
      constructors: () => ({_MapStream: [_MapStream$(S, T), [Stream$(S), dart.functionType(T, [S])]]}),
      methods: () => ({[_handleData]: [dart.void, [S, _EventSink$(T)]]})
    });
    return _MapStream;
  });
  let _MapStream = _MapStream$();
  const _expand = Symbol('_expand');
  const _ExpandStream$ = dart.generic(function(S, T) {
    class _ExpandStream extends _ForwardingStream$(S, T) {
      _ExpandStream(source, expand) {
        this[_expand] = expand;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, S);
        dart.as(sink, _EventSink$(T));
        try {
          for (let value of this[_expand](inputEvent)) {
            sink[_add](value);
          }
        } catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
        }

      }
    }
    dart.setSignature(_ExpandStream, {
      constructors: () => ({_ExpandStream: [_ExpandStream$(S, T), [Stream$(S), dart.functionType(core.Iterable$(T), [S])]]}),
      methods: () => ({[_handleData]: [dart.void, [S, _EventSink$(T)]]})
    });
    return _ExpandStream;
  });
  let _ExpandStream = _ExpandStream$();
  const _ErrorTest = dart.typedef('_ErrorTest', () => dart.functionType(core.bool, [dart.dynamic]));
  const _HandleErrorStream$ = dart.generic(function(T) {
    class _HandleErrorStream extends _ForwardingStream$(T, T) {
      _HandleErrorStream(source, onError, test) {
        this[_transform] = onError;
        this[_test] = test;
        super._ForwardingStream(source);
      }
      [_handleError](error, stackTrace, sink) {
        dart.as(sink, _EventSink$(T));
        let matches = true;
        if (this[_test] != null) {
          try {
            matches = dart.dcall(this[_test], error);
          } catch (e) {
            let s = dart.stackTrace(e);
            _addErrorWithReplacement(sink, e, s);
            return;
          }

        }
        if (dart.notNull(matches)) {
          try {
            _invokeErrorHandler(this[_transform], error, stackTrace);
          } catch (e) {
            let s = dart.stackTrace(e);
            if (dart.notNull(core.identical(e, error))) {
              sink[_addError](error, stackTrace);
            } else {
              _addErrorWithReplacement(sink, e, s);
            }
            return;
          }

        } else {
          sink[_addError](error, stackTrace);
        }
      }
    }
    dart.setSignature(_HandleErrorStream, {
      constructors: () => ({_HandleErrorStream: [_HandleErrorStream$(T), [Stream$(T), core.Function, dart.functionType(core.bool, [dart.dynamic])]]}),
      methods: () => ({[_handleError]: [dart.void, [core.Object, core.StackTrace, _EventSink$(T)]]})
    });
    return _HandleErrorStream;
  });
  let _HandleErrorStream = _HandleErrorStream$();
  const _remaining = Symbol('_remaining');
  const _TakeStream$ = dart.generic(function(T) {
    class _TakeStream extends _ForwardingStream$(T, T) {
      _TakeStream(source, count) {
        this[_remaining] = count;
        super._ForwardingStream(source);
        if (!(typeof count == 'number')) dart.throw(new core.ArgumentError(count));
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        if (dart.notNull(this[_remaining]) > 0) {
          sink[_add](inputEvent);
          this[_remaining] = dart.notNull(this[_remaining]) - 1;
          if (this[_remaining] == 0) {
            sink[_close]();
          }
        }
      }
    }
    dart.setSignature(_TakeStream, {
      constructors: () => ({_TakeStream: [_TakeStream$(T), [Stream$(T), core.int]]}),
      methods: () => ({[_handleData]: [dart.void, [T, _EventSink$(T)]]})
    });
    return _TakeStream;
  });
  let _TakeStream = _TakeStream$();
  const _TakeWhileStream$ = dart.generic(function(T) {
    class _TakeWhileStream extends _ForwardingStream$(T, T) {
      _TakeWhileStream(source, test) {
        this[_test] = test;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        let satisfies = null;
        try {
          satisfies = this[_test](inputEvent);
        } catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          sink[_close]();
          return;
        }

        if (dart.notNull(satisfies)) {
          sink[_add](inputEvent);
        } else {
          sink[_close]();
        }
      }
    }
    dart.setSignature(_TakeWhileStream, {
      constructors: () => ({_TakeWhileStream: [_TakeWhileStream$(T), [Stream$(T), dart.functionType(core.bool, [T])]]}),
      methods: () => ({[_handleData]: [dart.void, [T, _EventSink$(T)]]})
    });
    return _TakeWhileStream;
  });
  let _TakeWhileStream = _TakeWhileStream$();
  const _SkipStream$ = dart.generic(function(T) {
    class _SkipStream extends _ForwardingStream$(T, T) {
      _SkipStream(source, count) {
        this[_remaining] = count;
        super._ForwardingStream(source);
        if (!(typeof count == 'number') || dart.notNull(count) < 0) dart.throw(new core.ArgumentError(count));
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        if (dart.notNull(this[_remaining]) > 0) {
          this[_remaining] = dart.notNull(this[_remaining]) - 1;
          return;
        }
        sink[_add](inputEvent);
      }
    }
    dart.setSignature(_SkipStream, {
      constructors: () => ({_SkipStream: [_SkipStream$(T), [Stream$(T), core.int]]}),
      methods: () => ({[_handleData]: [dart.void, [T, _EventSink$(T)]]})
    });
    return _SkipStream;
  });
  let _SkipStream = _SkipStream$();
  const _hasFailed = Symbol('_hasFailed');
  const _SkipWhileStream$ = dart.generic(function(T) {
    class _SkipWhileStream extends _ForwardingStream$(T, T) {
      _SkipWhileStream(source, test) {
        this[_test] = test;
        this[_hasFailed] = false;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        if (dart.notNull(this[_hasFailed])) {
          sink[_add](inputEvent);
          return;
        }
        let satisfies = null;
        try {
          satisfies = this[_test](inputEvent);
        } catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          this[_hasFailed] = true;
          return;
        }

        if (!dart.notNull(satisfies)) {
          this[_hasFailed] = true;
          sink[_add](inputEvent);
        }
      }
    }
    dart.setSignature(_SkipWhileStream, {
      constructors: () => ({_SkipWhileStream: [_SkipWhileStream$(T), [Stream$(T), dart.functionType(core.bool, [T])]]}),
      methods: () => ({[_handleData]: [dart.void, [T, _EventSink$(T)]]})
    });
    return _SkipWhileStream;
  });
  let _SkipWhileStream = _SkipWhileStream$();
  const _Equality$ = dart.generic(function(T) {
    const _Equality = dart.typedef('_Equality', () => dart.functionType(core.bool, [T, T]));
    return _Equality;
  });
  let _Equality = _Equality$();
  const _equals = Symbol('_equals');
  const _DistinctStream$ = dart.generic(function(T) {
    class _DistinctStream extends _ForwardingStream$(T, T) {
      _DistinctStream(source, equals) {
        this[_previous] = _DistinctStream$()._SENTINEL;
        this[_equals] = equals;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        if (dart.notNull(core.identical(this[_previous], _DistinctStream$()._SENTINEL))) {
          this[_previous] = inputEvent;
          return sink[_add](inputEvent);
        } else {
          let isEqual = null;
          try {
            if (this[_equals] == null) {
              isEqual = dart.equals(this[_previous], inputEvent);
            } else {
              isEqual = this[_equals](dart.as(this[_previous], T), inputEvent);
            }
          } catch (e) {
            let s = dart.stackTrace(e);
            _addErrorWithReplacement(sink, e, s);
            return null;
          }

          if (!dart.notNull(isEqual)) {
            sink[_add](inputEvent);
            this[_previous] = inputEvent;
          }
        }
      }
    }
    dart.setSignature(_DistinctStream, {
      constructors: () => ({_DistinctStream: [_DistinctStream$(T), [Stream$(T), dart.functionType(core.bool, [T, T])]]}),
      methods: () => ({[_handleData]: [dart.void, [T, _EventSink$(T)]]})
    });
    dart.defineLazyProperties(_DistinctStream, {
      get _SENTINEL() {
        return new core.Object();
      },
      set _SENTINEL(_) {}
    });
    return _DistinctStream;
  });
  let _DistinctStream = _DistinctStream$();
  const _EventSinkWrapper$ = dart.generic(function(T) {
    class _EventSinkWrapper extends core.Object {
      _EventSinkWrapper(sink) {
        this[_sink] = sink;
      }
      add(data) {
        dart.as(data, T);
        this[_sink][_add](data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        this[_sink][_addError](error, stackTrace);
      }
      close() {
        this[_sink][_close]();
      }
    }
    _EventSinkWrapper[dart.implements] = () => [EventSink$(T)];
    dart.setSignature(_EventSinkWrapper, {
      constructors: () => ({_EventSinkWrapper: [_EventSinkWrapper$(T), [_EventSink]]}),
      methods: () => ({
        add: [dart.void, [T]],
        addError: [dart.void, [dart.dynamic], [core.StackTrace]],
        close: [dart.void, []]
      })
    });
    return _EventSinkWrapper;
  });
  let _EventSinkWrapper = _EventSinkWrapper$();
  const _transformerSink = Symbol('_transformerSink');
  const _isSubscribed = Symbol('_isSubscribed');
  const _SinkTransformerStreamSubscription$ = dart.generic(function(S, T) {
    class _SinkTransformerStreamSubscription extends _BufferingStreamSubscription$(T) {
      _SinkTransformerStreamSubscription(source, mapper, onData, onError, onDone, cancelOnError) {
        this[_transformerSink] = null;
        this[_subscription] = null;
        super._BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
        let eventSink = new (_EventSinkWrapper$(T))(this);
        this[_transformerSink] = mapper(eventSink);
        this[_subscription] = source.listen(dart.bind(this, _handleData), {onError: dart.bind(this, _handleError), onDone: dart.bind(this, _handleDone)});
      }
      get [_isSubscribed]() {
        return this[_subscription] != null;
      }
      [_add](data) {
        dart.as(data, T);
        if (dart.notNull(this[_isClosed])) {
          dart.throw(new core.StateError("Stream is already closed"));
        }
        super[_add](data);
      }
      [_addError](error, stackTrace) {
        if (dart.notNull(this[_isClosed])) {
          dart.throw(new core.StateError("Stream is already closed"));
        }
        super[_addError](error, stackTrace);
      }
      [_close]() {
        if (dart.notNull(this[_isClosed])) {
          dart.throw(new core.StateError("Stream is already closed"));
        }
        super[_close]();
      }
      [_onPause]() {
        if (dart.notNull(this[_isSubscribed])) this[_subscription].pause();
      }
      [_onResume]() {
        if (dart.notNull(this[_isSubscribed])) this[_subscription].resume();
      }
      [_onCancel]() {
        if (dart.notNull(this[_isSubscribed])) {
          let subscription = this[_subscription];
          this[_subscription] = null;
          subscription.cancel();
        }
        return null;
      }
      [_handleData](data) {
        dart.as(data, S);
        try {
          this[_transformerSink].add(data);
        } catch (e) {
          let s = dart.stackTrace(e);
          this[_addError](e, s);
        }

      }
      [_handleError](error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        try {
          this[_transformerSink].addError(error, dart.as(stackTrace, core.StackTrace));
        } catch (e) {
          let s = dart.stackTrace(e);
          if (dart.notNull(core.identical(e, error))) {
            this[_addError](error, dart.as(stackTrace, core.StackTrace));
          } else {
            this[_addError](e, s);
          }
        }

      }
      [_handleDone]() {
        try {
          this[_subscription] = null;
          this[_transformerSink].close();
        } catch (e) {
          let s = dart.stackTrace(e);
          this[_addError](e, s);
        }

      }
    }
    dart.setSignature(_SinkTransformerStreamSubscription, {
      constructors: () => ({_SinkTransformerStreamSubscription: [_SinkTransformerStreamSubscription$(S, T), [Stream$(S), _SinkMapper$(S, T), dart.functionType(dart.void, [T]), core.Function, dart.functionType(dart.void, []), core.bool]]}),
      methods: () => ({
        [_add]: [dart.void, [T]],
        [_handleData]: [dart.void, [S]],
        [_handleError]: [dart.void, [dart.dynamic], [dart.dynamic]],
        [_handleDone]: [dart.void, []]
      })
    });
    return _SinkTransformerStreamSubscription;
  });
  let _SinkTransformerStreamSubscription = _SinkTransformerStreamSubscription$();
  const _SinkMapper$ = dart.generic(function(S, T) {
    const _SinkMapper = dart.typedef('_SinkMapper', () => dart.functionType(EventSink$(S), [EventSink$(T)]));
    return _SinkMapper;
  });
  let _SinkMapper = _SinkMapper$();
  const _sinkMapper = Symbol('_sinkMapper');
  const _StreamSinkTransformer$ = dart.generic(function(S, T) {
    class _StreamSinkTransformer extends core.Object {
      _StreamSinkTransformer(sinkMapper) {
        this[_sinkMapper] = sinkMapper;
      }
      bind(stream) {
        dart.as(stream, Stream$(S));
        return new (_BoundSinkStream$(S, T))(stream, this[_sinkMapper]);
      }
    }
    _StreamSinkTransformer[dart.implements] = () => [StreamTransformer$(S, T)];
    dart.setSignature(_StreamSinkTransformer, {
      constructors: () => ({_StreamSinkTransformer: [_StreamSinkTransformer$(S, T), [_SinkMapper$(S, T)]]}),
      methods: () => ({bind: [Stream$(T), [Stream$(S)]]})
    });
    return _StreamSinkTransformer;
  });
  let _StreamSinkTransformer = _StreamSinkTransformer$();
  const _BoundSinkStream$ = dart.generic(function(S, T) {
    class _BoundSinkStream extends Stream$(T) {
      get isBroadcast() {
        return this[_stream].isBroadcast;
      }
      _BoundSinkStream(stream, sinkMapper) {
        this[_stream] = stream;
        this[_sinkMapper] = sinkMapper;
        super.Stream();
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        cancelOnError = core.identical(true, cancelOnError);
        let subscription = new (_SinkTransformerStreamSubscription$(dart.dynamic, T))(this[_stream], this[_sinkMapper], onData, onError, onDone, cancelOnError);
        return subscription;
      }
    }
    dart.setSignature(_BoundSinkStream, {
      constructors: () => ({_BoundSinkStream: [_BoundSinkStream$(S, T), [Stream$(S), _SinkMapper$(S, T)]]}),
      methods: () => ({listen: [StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}]})
    });
    return _BoundSinkStream;
  });
  let _BoundSinkStream = _BoundSinkStream$();
  const _TransformDataHandler$ = dart.generic(function(S, T) {
    const _TransformDataHandler = dart.typedef('_TransformDataHandler', () => dart.functionType(dart.void, [S, EventSink$(T)]));
    return _TransformDataHandler;
  });
  let _TransformDataHandler = _TransformDataHandler$();
  const _TransformErrorHandler$ = dart.generic(function(T) {
    const _TransformErrorHandler = dart.typedef('_TransformErrorHandler', () => dart.functionType(dart.void, [core.Object, core.StackTrace, EventSink$(T)]));
    return _TransformErrorHandler;
  });
  let _TransformErrorHandler = _TransformErrorHandler$();
  const _TransformDoneHandler$ = dart.generic(function(T) {
    const _TransformDoneHandler = dart.typedef('_TransformDoneHandler', () => dart.functionType(dart.void, [EventSink$(T)]));
    return _TransformDoneHandler;
  });
  let _TransformDoneHandler = _TransformDoneHandler$();
  const _HandlerEventSink$ = dart.generic(function(S, T) {
    class _HandlerEventSink extends core.Object {
      _HandlerEventSink(handleData, handleError, handleDone, sink) {
        this[_handleData] = handleData;
        this[_handleError] = handleError;
        this[_handleDone] = handleDone;
        this[_sink] = sink;
      }
      add(data) {
        dart.as(data, S);
        return this[_handleData](data, this[_sink]);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0) stackTrace = null;
        return this[_handleError](error, stackTrace, this[_sink]);
      }
      close() {
        return this[_handleDone](this[_sink]);
      }
    }
    _HandlerEventSink[dart.implements] = () => [EventSink$(S)];
    dart.setSignature(_HandlerEventSink, {
      constructors: () => ({_HandlerEventSink: [_HandlerEventSink$(S, T), [_TransformDataHandler$(S, T), _TransformErrorHandler$(T), _TransformDoneHandler$(T), EventSink$(T)]]}),
      methods: () => ({
        add: [dart.void, [S]],
        addError: [dart.void, [core.Object], [core.StackTrace]],
        close: [dart.void, []]
      })
    });
    return _HandlerEventSink;
  });
  let _HandlerEventSink = _HandlerEventSink$();
  const _StreamHandlerTransformer$ = dart.generic(function(S, T) {
    class _StreamHandlerTransformer extends _StreamSinkTransformer$(S, T) {
      _StreamHandlerTransformer(opts) {
        let handleData = opts && 'handleData' in opts ? opts.handleData : null;
        let handleError = opts && 'handleError' in opts ? opts.handleError : null;
        let handleDone = opts && 'handleDone' in opts ? opts.handleDone : null;
        super._StreamSinkTransformer(dart.fn(outputSink => {
          dart.as(outputSink, EventSink$(T));
          if (handleData == null) handleData = dart.as(_StreamHandlerTransformer$()._defaultHandleData, __CastType25);
          if (handleError == null) handleError = dart.as(_StreamHandlerTransformer$()._defaultHandleError, __CastType28);
          if (handleDone == null) handleDone = _StreamHandlerTransformer$()._defaultHandleDone;
          return new (_HandlerEventSink$(S, T))(handleData, handleError, handleDone, outputSink);
        }, EventSink$(S), [EventSink$(T)]));
      }
      bind(stream) {
        dart.as(stream, Stream$(S));
        return super.bind(stream);
      }
      static _defaultHandleData(data, sink) {
        sink.add(data);
      }
      static _defaultHandleError(error, stackTrace, sink) {
        sink.addError(error);
      }
      static _defaultHandleDone(sink) {
        sink.close();
      }
    }
    dart.setSignature(_StreamHandlerTransformer, {
      constructors: () => ({_StreamHandlerTransformer: [_StreamHandlerTransformer$(S, T), [], {handleData: dart.functionType(dart.void, [S, EventSink$(T)]), handleError: dart.functionType(dart.void, [core.Object, core.StackTrace, EventSink$(T)]), handleDone: dart.functionType(dart.void, [EventSink$(T)])}]}),
      methods: () => ({bind: [Stream$(T), [Stream$(S)]]}),
      statics: () => ({
        _defaultHandleData: [dart.void, [dart.dynamic, EventSink]],
        _defaultHandleError: [dart.void, [dart.dynamic, core.StackTrace, EventSink]],
        _defaultHandleDone: [dart.void, [EventSink]]
      }),
      names: ['_defaultHandleData', '_defaultHandleError', '_defaultHandleDone']
    });
    return _StreamHandlerTransformer;
  });
  let _StreamHandlerTransformer = _StreamHandlerTransformer$();
  const _SubscriptionTransformer$ = dart.generic(function(S, T) {
    const _SubscriptionTransformer = dart.typedef('_SubscriptionTransformer', () => dart.functionType(StreamSubscription$(T), [Stream$(S), core.bool]));
    return _SubscriptionTransformer;
  });
  let _SubscriptionTransformer = _SubscriptionTransformer$();
  const _transformer = Symbol('_transformer');
  const _StreamSubscriptionTransformer$ = dart.generic(function(S, T) {
    class _StreamSubscriptionTransformer extends core.Object {
      _StreamSubscriptionTransformer(transformer) {
        this[_transformer] = transformer;
      }
      bind(stream) {
        dart.as(stream, Stream$(S));
        return new (_BoundSubscriptionStream$(S, T))(stream, this[_transformer]);
      }
    }
    _StreamSubscriptionTransformer[dart.implements] = () => [StreamTransformer$(S, T)];
    dart.setSignature(_StreamSubscriptionTransformer, {
      constructors: () => ({_StreamSubscriptionTransformer: [_StreamSubscriptionTransformer$(S, T), [_SubscriptionTransformer$(S, T)]]}),
      methods: () => ({bind: [Stream$(T), [Stream$(S)]]})
    });
    return _StreamSubscriptionTransformer;
  });
  let _StreamSubscriptionTransformer = _StreamSubscriptionTransformer$();
  const _BoundSubscriptionStream$ = dart.generic(function(S, T) {
    class _BoundSubscriptionStream extends Stream$(T) {
      _BoundSubscriptionStream(stream, transformer) {
        this[_stream] = stream;
        this[_transformer] = transformer;
        super.Stream();
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        cancelOnError = core.identical(true, cancelOnError);
        let result = this[_transformer](this[_stream], cancelOnError);
        result.onData(onData);
        result.onError(onError);
        result.onDone(onDone);
        return result;
      }
    }
    dart.setSignature(_BoundSubscriptionStream, {
      constructors: () => ({_BoundSubscriptionStream: [_BoundSubscriptionStream$(S, T), [Stream$(S), _SubscriptionTransformer$(S, T)]]}),
      methods: () => ({listen: [StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}]})
    });
    return _BoundSubscriptionStream;
  });
  let _BoundSubscriptionStream = _BoundSubscriptionStream$();
  const __CastType25$ = dart.generic(function(S, T) {
    const __CastType25 = dart.typedef('__CastType25', () => dart.functionType(dart.void, [S, EventSink$(T)]));
    return __CastType25;
  });
  let __CastType25 = __CastType25$();
  const __CastType28$ = dart.generic(function(T) {
    const __CastType28 = dart.typedef('__CastType28', () => dart.functionType(dart.void, [core.Object, core.StackTrace, EventSink$(T)]));
    return __CastType28;
  });
  let __CastType28 = __CastType28$();
  class Timer extends core.Object {
    static new(duration, callback) {
      if (dart.equals(Zone.current, Zone.ROOT)) {
        return Zone.current.createTimer(duration, callback);
      }
      return Zone.current.createTimer(duration, Zone.current.bindCallback(callback, {runGuarded: true}));
    }
    static periodic(duration, callback) {
      if (dart.equals(Zone.current, Zone.ROOT)) {
        return Zone.current.createPeriodicTimer(duration, callback);
      }
      return Zone.current.createPeriodicTimer(duration, dart.as(Zone.current.bindUnaryCallback(callback, {runGuarded: true}), __CastType32));
    }
    static run(callback) {
      Timer.new(core.Duration.ZERO, callback);
    }
    static _createTimer(duration, callback) {
      let milliseconds = duration.inMilliseconds;
      if (dart.notNull(milliseconds) < 0) milliseconds = 0;
      return new _isolate_helper.TimerImpl(milliseconds, callback);
    }
    static _createPeriodicTimer(duration, callback) {
      let milliseconds = duration.inMilliseconds;
      if (dart.notNull(milliseconds) < 0) milliseconds = 0;
      return new _isolate_helper.TimerImpl.periodic(milliseconds, callback);
    }
  }
  dart.setSignature(Timer, {
    constructors: () => ({
      new: [Timer, [core.Duration, dart.functionType(dart.void, [])]],
      periodic: [Timer, [core.Duration, dart.functionType(dart.void, [Timer])]]
    }),
    statics: () => ({
      run: [dart.void, [dart.functionType(dart.void, [])]],
      _createTimer: [Timer, [core.Duration, dart.functionType(dart.void, [])]],
      _createPeriodicTimer: [Timer, [core.Duration, dart.functionType(dart.void, [Timer])]]
    }),
    names: ['run', '_createTimer', '_createPeriodicTimer']
  });
  const __CastType32 = dart.typedef('__CastType32', () => dart.functionType(dart.void, [Timer]));
  const ZoneCallback = dart.typedef('ZoneCallback', () => dart.functionType(dart.dynamic, []));
  const ZoneUnaryCallback = dart.typedef('ZoneUnaryCallback', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  const ZoneBinaryCallback = dart.typedef('ZoneBinaryCallback', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  const HandleUncaughtErrorHandler = dart.typedef('HandleUncaughtErrorHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]));
  const RunHandler = dart.typedef('RunHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  const RunUnaryHandler = dart.typedef('RunUnaryHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]));
  const RunBinaryHandler = dart.typedef('RunBinaryHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]));
  const RegisterCallbackHandler = dart.typedef('RegisterCallbackHandler', () => dart.functionType(ZoneCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  const RegisterUnaryCallbackHandler = dart.typedef('RegisterUnaryCallbackHandler', () => dart.functionType(ZoneUnaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic])]));
  const RegisterBinaryCallbackHandler = dart.typedef('RegisterBinaryCallbackHandler', () => dart.functionType(ZoneBinaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]));
  const ErrorCallbackHandler = dart.typedef('ErrorCallbackHandler', () => dart.functionType(AsyncError, [Zone, ZoneDelegate, Zone, core.Object, core.StackTrace]));
  const ScheduleMicrotaskHandler = dart.typedef('ScheduleMicrotaskHandler', () => dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  const CreateTimerHandler = dart.typedef('CreateTimerHandler', () => dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [])]));
  const CreatePeriodicTimerHandler = dart.typedef('CreatePeriodicTimerHandler', () => dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [Timer])]));
  const PrintHandler = dart.typedef('PrintHandler', () => dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, core.String]));
  const ForkHandler = dart.typedef('ForkHandler', () => dart.functionType(Zone, [Zone, ZoneDelegate, Zone, ZoneSpecification, core.Map]));
  class _ZoneFunction extends core.Object {
    _ZoneFunction(zone, func) {
      this.zone = zone;
      this.function = func;
    }
  }
  dart.setSignature(_ZoneFunction, {
    constructors: () => ({_ZoneFunction: [_ZoneFunction, [_Zone, core.Function]]})
  });
  class ZoneSpecification extends core.Object {
    static new(opts) {
      return new _ZoneSpecification(opts);
    }
    static from(other, opts) {
      let handleUncaughtError = opts && 'handleUncaughtError' in opts ? opts.handleUncaughtError : null;
      let run = opts && 'run' in opts ? opts.run : null;
      let runUnary = opts && 'runUnary' in opts ? opts.runUnary : null;
      let runBinary = opts && 'runBinary' in opts ? opts.runBinary : null;
      let registerCallback = opts && 'registerCallback' in opts ? opts.registerCallback : null;
      let registerUnaryCallback = opts && 'registerUnaryCallback' in opts ? opts.registerUnaryCallback : null;
      let registerBinaryCallback = opts && 'registerBinaryCallback' in opts ? opts.registerBinaryCallback : null;
      let errorCallback = opts && 'errorCallback' in opts ? opts.errorCallback : null;
      let scheduleMicrotask = opts && 'scheduleMicrotask' in opts ? opts.scheduleMicrotask : null;
      let createTimer = opts && 'createTimer' in opts ? opts.createTimer : null;
      let createPeriodicTimer = opts && 'createPeriodicTimer' in opts ? opts.createPeriodicTimer : null;
      let print = opts && 'print' in opts ? opts.print : null;
      let fork = opts && 'fork' in opts ? opts.fork : null;
      return ZoneSpecification.new({handleUncaughtError: dart.as(handleUncaughtError != null ? handleUncaughtError : other.handleUncaughtError, __CastType34), run: dart.as(run != null ? run : other.run, __CastType40), runUnary: dart.as(runUnary != null ? runUnary : other.runUnary, __CastType45), runBinary: dart.as(runBinary != null ? runBinary : other.runBinary, __CastType52), registerCallback: dart.as(registerCallback != null ? registerCallback : other.registerCallback, __CastType61), registerUnaryCallback: dart.as(registerUnaryCallback != null ? registerUnaryCallback : other.registerUnaryCallback, __CastType66), registerBinaryCallback: dart.as(registerBinaryCallback != null ? registerBinaryCallback : other.registerBinaryCallback, __CastType72), errorCallback: dart.as(errorCallback != null ? errorCallback : other.errorCallback, __CastType79), scheduleMicrotask: dart.as(scheduleMicrotask != null ? scheduleMicrotask : other.scheduleMicrotask, __CastType85), createTimer: dart.as(createTimer != null ? createTimer : other.createTimer, __CastType90), createPeriodicTimer: dart.as(createPeriodicTimer != null ? createPeriodicTimer : other.createPeriodicTimer, __CastType96), print: dart.as(print != null ? print : other.print, __CastType103), fork: dart.as(fork != null ? fork : other.fork, __CastType108)});
    }
  }
  dart.setSignature(ZoneSpecification, {
    constructors: () => ({
      new: [ZoneSpecification, [], {handleUncaughtError: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]), run: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]), runUnary: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]), runBinary: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]), registerCallback: dart.functionType(ZoneCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]), registerUnaryCallback: dart.functionType(ZoneUnaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic])]), registerBinaryCallback: dart.functionType(ZoneBinaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]), errorCallback: dart.functionType(AsyncError, [Zone, ZoneDelegate, Zone, core.Object, core.StackTrace]), scheduleMicrotask: dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]), createTimer: dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [])]), createPeriodicTimer: dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [Timer])]), print: dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, core.String]), fork: dart.functionType(Zone, [Zone, ZoneDelegate, Zone, ZoneSpecification, core.Map])}],
      from: [ZoneSpecification, [ZoneSpecification], {handleUncaughtError: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]), run: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]), runUnary: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]), runBinary: dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]), registerCallback: dart.functionType(ZoneCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]), registerUnaryCallback: dart.functionType(ZoneUnaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic])]), registerBinaryCallback: dart.functionType(ZoneBinaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]), errorCallback: dart.functionType(AsyncError, [Zone, ZoneDelegate, Zone, core.Object, core.StackTrace]), scheduleMicrotask: dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]), createTimer: dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [])]), createPeriodicTimer: dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [Timer])]), print: dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, core.String]), fork: dart.functionType(Zone, [Zone, ZoneDelegate, Zone, ZoneSpecification, core.Map])}]
    })
  });
  class _ZoneSpecification extends core.Object {
    _ZoneSpecification(opts) {
      let handleUncaughtError = opts && 'handleUncaughtError' in opts ? opts.handleUncaughtError : null;
      let run = opts && 'run' in opts ? opts.run : null;
      let runUnary = opts && 'runUnary' in opts ? opts.runUnary : null;
      let runBinary = opts && 'runBinary' in opts ? opts.runBinary : null;
      let registerCallback = opts && 'registerCallback' in opts ? opts.registerCallback : null;
      let registerUnaryCallback = opts && 'registerUnaryCallback' in opts ? opts.registerUnaryCallback : null;
      let registerBinaryCallback = opts && 'registerBinaryCallback' in opts ? opts.registerBinaryCallback : null;
      let errorCallback = opts && 'errorCallback' in opts ? opts.errorCallback : null;
      let scheduleMicrotask = opts && 'scheduleMicrotask' in opts ? opts.scheduleMicrotask : null;
      let createTimer = opts && 'createTimer' in opts ? opts.createTimer : null;
      let createPeriodicTimer = opts && 'createPeriodicTimer' in opts ? opts.createPeriodicTimer : null;
      let print = opts && 'print' in opts ? opts.print : null;
      let fork = opts && 'fork' in opts ? opts.fork : null;
      this.handleUncaughtError = handleUncaughtError;
      this.run = run;
      this.runUnary = runUnary;
      this.runBinary = runBinary;
      this.registerCallback = registerCallback;
      this.registerUnaryCallback = registerUnaryCallback;
      this.registerBinaryCallback = registerBinaryCallback;
      this.errorCallback = errorCallback;
      this.scheduleMicrotask = scheduleMicrotask;
      this.createTimer = createTimer;
      this.createPeriodicTimer = createPeriodicTimer;
      this.print = print;
      this.fork = fork;
    }
  }
  _ZoneSpecification[dart.implements] = () => [ZoneSpecification];
  dart.setSignature(_ZoneSpecification, {
    constructors: () => ({_ZoneSpecification: [_ZoneSpecification, [], {handleUncaughtError: HandleUncaughtErrorHandler, run: RunHandler, runUnary: RunUnaryHandler, runBinary: RunBinaryHandler, registerCallback: RegisterCallbackHandler, registerUnaryCallback: RegisterUnaryCallbackHandler, registerBinaryCallback: RegisterBinaryCallbackHandler, errorCallback: ErrorCallbackHandler, scheduleMicrotask: ScheduleMicrotaskHandler, createTimer: CreateTimerHandler, createPeriodicTimer: CreatePeriodicTimerHandler, print: PrintHandler, fork: ForkHandler}]})
  });
  class ZoneDelegate extends core.Object {}
  class Zone extends core.Object {
    _() {
    }
    static get current() {
      return Zone._current;
    }
    static _enter(zone) {
      dart.assert(zone != null);
      dart.assert(!dart.notNull(core.identical(zone, Zone._current)));
      let previous = Zone._current;
      Zone._current = zone;
      return previous;
    }
    static _leave(previous) {
      dart.assert(previous != null);
      Zone._current = previous;
    }
  }
  dart.defineNamedConstructor(Zone, '_');
  dart.setSignature(Zone, {
    constructors: () => ({_: [Zone, []]}),
    statics: () => ({
      _enter: [Zone, [Zone]],
      _leave: [dart.void, [Zone]]
    }),
    names: ['_enter', '_leave']
  });
  dart.defineLazyProperties(Zone, {
    get ROOT() {
      return _ROOT_ZONE;
    },
    get _current() {
      return _ROOT_ZONE;
    },
    set _current(_) {}
  });
  const _delegate = Symbol('_delegate');
  function _parentDelegate(zone) {
    if (zone.parent == null) return null;
    return zone.parent[_delegate];
  }
  dart.fn(_parentDelegate, () => dart.definiteFunctionType(ZoneDelegate, [_Zone]));
  const _delegationTarget = Symbol('_delegationTarget');
  const _handleUncaughtError = Symbol('_handleUncaughtError');
  const _run = Symbol('_run');
  const _runUnary = Symbol('_runUnary');
  const _runBinary = Symbol('_runBinary');
  const _registerCallback = Symbol('_registerCallback');
  const _registerUnaryCallback = Symbol('_registerUnaryCallback');
  const _registerBinaryCallback = Symbol('_registerBinaryCallback');
  const _errorCallback = Symbol('_errorCallback');
  const _scheduleMicrotask = Symbol('_scheduleMicrotask');
  const _createTimer = Symbol('_createTimer');
  const _createPeriodicTimer = Symbol('_createPeriodicTimer');
  const _print = Symbol('_print');
  const _fork = Symbol('_fork');
  class _ZoneDelegate extends core.Object {
    _ZoneDelegate(delegationTarget) {
      this[_delegationTarget] = delegationTarget;
    }
    handleUncaughtError(zone, error, stackTrace) {
      let implementation = this[_delegationTarget][_handleUncaughtError];
      let implZone = implementation.zone;
      return dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, error, stackTrace);
    }
    run(zone, f) {
      let implementation = this[_delegationTarget][_run];
      let implZone = implementation.zone;
      return dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f);
    }
    runUnary(zone, f, arg) {
      let implementation = this[_delegationTarget][_runUnary];
      let implZone = implementation.zone;
      return dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f, arg);
    }
    runBinary(zone, f, arg1, arg2) {
      let implementation = this[_delegationTarget][_runBinary];
      let implZone = implementation.zone;
      return dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f, arg1, arg2);
    }
    registerCallback(zone, f) {
      let implementation = this[_delegationTarget][_registerCallback];
      let implZone = implementation.zone;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f), ZoneCallback);
    }
    registerUnaryCallback(zone, f) {
      let implementation = this[_delegationTarget][_registerUnaryCallback];
      let implZone = implementation.zone;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f), ZoneUnaryCallback);
    }
    registerBinaryCallback(zone, f) {
      let implementation = this[_delegationTarget][_registerBinaryCallback];
      let implZone = implementation.zone;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f), ZoneBinaryCallback);
    }
    errorCallback(zone, error, stackTrace) {
      let implementation = this[_delegationTarget][_errorCallback];
      let implZone = implementation.zone;
      if (dart.notNull(core.identical(implZone, _ROOT_ZONE))) return null;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, error, stackTrace), AsyncError);
    }
    scheduleMicrotask(zone, f) {
      let implementation = this[_delegationTarget][_scheduleMicrotask];
      let implZone = implementation.zone;
      dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, f);
    }
    createTimer(zone, duration, f) {
      let implementation = this[_delegationTarget][_createTimer];
      let implZone = implementation.zone;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, duration, f), Timer);
    }
    createPeriodicTimer(zone, period, f) {
      let implementation = this[_delegationTarget][_createPeriodicTimer];
      let implZone = implementation.zone;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, period, f), Timer);
    }
    print(zone, line) {
      let implementation = this[_delegationTarget][_print];
      let implZone = implementation.zone;
      dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, line);
    }
    fork(zone, specification, zoneValues) {
      let implementation = this[_delegationTarget][_fork];
      let implZone = implementation.zone;
      return dart.as(dart.dcall(implementation.function, implZone, _parentDelegate(implZone), zone, specification, zoneValues), Zone);
    }
  }
  _ZoneDelegate[dart.implements] = () => [ZoneDelegate];
  dart.setSignature(_ZoneDelegate, {
    constructors: () => ({_ZoneDelegate: [_ZoneDelegate, [_Zone]]}),
    methods: () => ({
      handleUncaughtError: [dart.dynamic, [Zone, dart.dynamic, core.StackTrace]],
      run: [dart.dynamic, [Zone, dart.functionType(dart.dynamic, [])]],
      runUnary: [dart.dynamic, [Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]],
      runBinary: [dart.dynamic, [Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]],
      registerCallback: [ZoneCallback, [Zone, dart.functionType(dart.dynamic, [])]],
      registerUnaryCallback: [ZoneUnaryCallback, [Zone, dart.functionType(dart.dynamic, [dart.dynamic])]],
      registerBinaryCallback: [ZoneBinaryCallback, [Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]],
      errorCallback: [AsyncError, [Zone, core.Object, core.StackTrace]],
      scheduleMicrotask: [dart.void, [Zone, dart.functionType(dart.dynamic, [])]],
      createTimer: [Timer, [Zone, core.Duration, dart.functionType(dart.void, [])]],
      createPeriodicTimer: [Timer, [Zone, core.Duration, dart.functionType(dart.void, [Timer])]],
      print: [dart.void, [Zone, core.String]],
      fork: [Zone, [Zone, ZoneSpecification, core.Map]]
    })
  });
  class _Zone extends core.Object {
    _Zone() {
    }
    inSameErrorZone(otherZone) {
      return dart.notNull(core.identical(this, otherZone)) || dart.notNull(core.identical(this.errorZone, otherZone.errorZone));
    }
  }
  _Zone[dart.implements] = () => [Zone];
  dart.setSignature(_Zone, {
    constructors: () => ({_Zone: [_Zone, []]}),
    methods: () => ({inSameErrorZone: [core.bool, [Zone]]})
  });
  const _delegateCache = Symbol('_delegateCache');
  const _map = Symbol('_map');
  class _CustomZone extends _Zone {
    get [_delegate]() {
      if (this[_delegateCache] != null) return this[_delegateCache];
      this[_delegateCache] = new _ZoneDelegate(this);
      return this[_delegateCache];
    }
    _CustomZone(parent, specification, map) {
      this.parent = parent;
      this[_map] = map;
      this[_runUnary] = null;
      this[_run] = null;
      this[_runBinary] = null;
      this[_registerCallback] = null;
      this[_registerUnaryCallback] = null;
      this[_registerBinaryCallback] = null;
      this[_errorCallback] = null;
      this[_scheduleMicrotask] = null;
      this[_createTimer] = null;
      this[_createPeriodicTimer] = null;
      this[_print] = null;
      this[_fork] = null;
      this[_handleUncaughtError] = null;
      this[_delegateCache] = null;
      super._Zone();
      this[_run] = specification.run != null ? new _ZoneFunction(this, specification.run) : this.parent[_run];
      this[_runUnary] = specification.runUnary != null ? new _ZoneFunction(this, specification.runUnary) : this.parent[_runUnary];
      this[_runBinary] = specification.runBinary != null ? new _ZoneFunction(this, specification.runBinary) : this.parent[_runBinary];
      this[_registerCallback] = specification.registerCallback != null ? new _ZoneFunction(this, specification.registerCallback) : this.parent[_registerCallback];
      this[_registerUnaryCallback] = specification.registerUnaryCallback != null ? new _ZoneFunction(this, specification.registerUnaryCallback) : this.parent[_registerUnaryCallback];
      this[_registerBinaryCallback] = specification.registerBinaryCallback != null ? new _ZoneFunction(this, specification.registerBinaryCallback) : this.parent[_registerBinaryCallback];
      this[_errorCallback] = specification.errorCallback != null ? new _ZoneFunction(this, specification.errorCallback) : this.parent[_errorCallback];
      this[_scheduleMicrotask] = specification.scheduleMicrotask != null ? new _ZoneFunction(this, specification.scheduleMicrotask) : this.parent[_scheduleMicrotask];
      this[_createTimer] = specification.createTimer != null ? new _ZoneFunction(this, specification.createTimer) : this.parent[_createTimer];
      this[_createPeriodicTimer] = specification.createPeriodicTimer != null ? new _ZoneFunction(this, specification.createPeriodicTimer) : this.parent[_createPeriodicTimer];
      this[_print] = specification.print != null ? new _ZoneFunction(this, specification.print) : this.parent[_print];
      this[_fork] = specification.fork != null ? new _ZoneFunction(this, specification.fork) : this.parent[_fork];
      this[_handleUncaughtError] = specification.handleUncaughtError != null ? new _ZoneFunction(this, specification.handleUncaughtError) : this.parent[_handleUncaughtError];
    }
    get errorZone() {
      return this[_handleUncaughtError].zone;
    }
    runGuarded(f) {
      try {
        return this.run(f);
      } catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }

    }
    runUnaryGuarded(f, arg) {
      try {
        return this.runUnary(f, arg);
      } catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }

    }
    runBinaryGuarded(f, arg1, arg2) {
      try {
        return this.runBinary(f, arg1, arg2);
      } catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }

    }
    bindCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      let registered = this.registerCallback(f);
      if (dart.notNull(runGuarded)) {
        return dart.fn((() => this.runGuarded(registered)).bind(this));
      } else {
        return dart.fn((() => this.run(registered)).bind(this));
      }
    }
    bindUnaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      let registered = this.registerUnaryCallback(f);
      if (dart.notNull(runGuarded)) {
        return dart.fn((arg => this.runUnaryGuarded(registered, arg)).bind(this));
      } else {
        return dart.fn((arg => this.runUnary(registered, arg)).bind(this));
      }
    }
    bindBinaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      let registered = this.registerBinaryCallback(f);
      if (dart.notNull(runGuarded)) {
        return dart.fn(((arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2)).bind(this));
      } else {
        return dart.fn(((arg1, arg2) => this.runBinary(registered, arg1, arg2)).bind(this));
      }
    }
    get(key) {
      let result = this[_map].get(key);
      if (result != null || dart.notNull(this[_map].containsKey(key))) return result;
      if (this.parent != null) {
        let value = this.parent.get(key);
        if (value != null) {
          this[_map].set(key, value);
        }
        return value;
      }
      dart.assert(dart.equals(this, _ROOT_ZONE));
      return null;
    }
    handleUncaughtError(error, stackTrace) {
      let implementation = this[_handleUncaughtError];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dcall(implementation.function, implementation.zone, parentDelegate, this, error, stackTrace);
    }
    fork(opts) {
      let specification = opts && 'specification' in opts ? opts.specification : null;
      let zoneValues = opts && 'zoneValues' in opts ? opts.zoneValues : null;
      let implementation = this[_fork];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dcall(implementation.function, implementation.zone, parentDelegate, this, specification, zoneValues), Zone);
    }
    run(f) {
      let implementation = this[_run];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f);
    }
    runUnary(f, arg) {
      let implementation = this[_runUnary];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f, arg);
    }
    runBinary(f, arg1, arg2) {
      let implementation = this[_runBinary];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f, arg1, arg2);
    }
    registerCallback(f) {
      let implementation = this[_registerCallback];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f), ZoneCallback);
    }
    registerUnaryCallback(f) {
      let implementation = this[_registerUnaryCallback];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f), ZoneUnaryCallback);
    }
    registerBinaryCallback(f) {
      let implementation = this[_registerBinaryCallback];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f), ZoneBinaryCallback);
    }
    errorCallback(error, stackTrace) {
      let implementation = this[_errorCallback];
      dart.assert(implementation != null);
      let implementationZone = implementation.zone;
      if (dart.notNull(core.identical(implementationZone, _ROOT_ZONE))) return null;
      let parentDelegate = _parentDelegate(dart.as(implementationZone, _Zone));
      return dart.as(dart.dcall(implementation.function, implementationZone, parentDelegate, this, error, stackTrace), AsyncError);
    }
    scheduleMicrotask(f) {
      let implementation = this[_scheduleMicrotask];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dcall(implementation.function, implementation.zone, parentDelegate, this, f);
    }
    createTimer(duration, f) {
      let implementation = this[_createTimer];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dcall(implementation.function, implementation.zone, parentDelegate, this, duration, f), Timer);
    }
    createPeriodicTimer(duration, f) {
      let implementation = this[_createPeriodicTimer];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dcall(implementation.function, implementation.zone, parentDelegate, this, duration, f), Timer);
    }
    print(line) {
      let implementation = this[_print];
      dart.assert(implementation != null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dcall(implementation.function, implementation.zone, parentDelegate, this, line);
    }
  }
  dart.setSignature(_CustomZone, {
    constructors: () => ({_CustomZone: [_CustomZone, [_Zone, ZoneSpecification, core.Map]]}),
    methods: () => ({
      runGuarded: [dart.dynamic, [dart.functionType(dart.dynamic, [])]],
      runUnaryGuarded: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]],
      runBinaryGuarded: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]],
      bindCallback: [ZoneCallback, [dart.functionType(dart.dynamic, [])], {runGuarded: core.bool}],
      bindUnaryCallback: [ZoneUnaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic])], {runGuarded: core.bool}],
      bindBinaryCallback: [ZoneBinaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])], {runGuarded: core.bool}],
      get: [dart.dynamic, [core.Object]],
      handleUncaughtError: [dart.dynamic, [dart.dynamic, core.StackTrace]],
      fork: [Zone, [], {specification: ZoneSpecification, zoneValues: core.Map}],
      run: [dart.dynamic, [dart.functionType(dart.dynamic, [])]],
      runUnary: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]],
      runBinary: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]],
      registerCallback: [ZoneCallback, [dart.functionType(dart.dynamic, [])]],
      registerUnaryCallback: [ZoneUnaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic])]],
      registerBinaryCallback: [ZoneBinaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]],
      errorCallback: [AsyncError, [core.Object, core.StackTrace]],
      scheduleMicrotask: [dart.void, [dart.functionType(dart.void, [])]],
      createTimer: [Timer, [core.Duration, dart.functionType(dart.void, [])]],
      createPeriodicTimer: [Timer, [core.Duration, dart.functionType(dart.void, [Timer])]],
      print: [dart.void, [core.String]]
    })
  });
  function _rootHandleUncaughtError(self, parent, zone, error, stackTrace) {
    _schedulePriorityAsyncCallback(dart.fn(() => {
      dart.throw(new _UncaughtAsyncError(error, stackTrace));
    }));
  }
  dart.fn(_rootHandleUncaughtError, dart.void, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]);
  function _rootRun(self, parent, zone, f) {
    if (dart.equals(Zone._current, zone)) return f();
    let old = Zone._enter(zone);
    try {
      return f();
    } finally {
      Zone._leave(old);
    }
  }
  dart.fn(_rootRun, dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]);
  function _rootRunUnary(self, parent, zone, f, arg) {
    if (dart.equals(Zone._current, zone)) return dart.dcall(f, arg);
    let old = Zone._enter(zone);
    try {
      return dart.dcall(f, arg);
    } finally {
      Zone._leave(old);
    }
  }
  dart.fn(_rootRunUnary, dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]);
  function _rootRunBinary(self, parent, zone, f, arg1, arg2) {
    if (dart.equals(Zone._current, zone)) return dart.dcall(f, arg1, arg2);
    let old = Zone._enter(zone);
    try {
      return dart.dcall(f, arg1, arg2);
    } finally {
      Zone._leave(old);
    }
  }
  dart.fn(_rootRunBinary, dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]);
  function _rootRegisterCallback(self, parent, zone, f) {
    return f;
  }
  dart.fn(_rootRegisterCallback, ZoneCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]);
  function _rootRegisterUnaryCallback(self, parent, zone, f) {
    return f;
  }
  dart.fn(_rootRegisterUnaryCallback, ZoneUnaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic])]);
  function _rootRegisterBinaryCallback(self, parent, zone, f) {
    return f;
  }
  dart.fn(_rootRegisterBinaryCallback, ZoneBinaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]);
  function _rootErrorCallback(self, parent, zone, error, stackTrace) {
    return null;
  }
  dart.fn(_rootErrorCallback, AsyncError, [Zone, ZoneDelegate, Zone, core.Object, core.StackTrace]);
  function _rootScheduleMicrotask(self, parent, zone, f) {
    if (!dart.notNull(core.identical(_ROOT_ZONE, zone))) {
      let hasErrorHandler = !dart.notNull(_ROOT_ZONE.inSameErrorZone(zone));
      f = zone.bindCallback(f, {runGuarded: hasErrorHandler});
    }
    _scheduleAsyncCallback(f);
  }
  dart.fn(_rootScheduleMicrotask, dart.void, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]);
  function _rootCreateTimer(self, parent, zone, duration, callback) {
    if (!dart.notNull(core.identical(_ROOT_ZONE, zone))) {
      callback = zone.bindCallback(callback);
    }
    return Timer._createTimer(duration, callback);
  }
  dart.fn(_rootCreateTimer, Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [])]);
  function _rootCreatePeriodicTimer(self, parent, zone, duration, callback) {
    if (!dart.notNull(core.identical(_ROOT_ZONE, zone))) {
      callback = dart.as(zone.bindUnaryCallback(callback), __CastType114);
    }
    return Timer._createPeriodicTimer(duration, callback);
  }
  dart.fn(_rootCreatePeriodicTimer, Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [Timer])]);
  function _rootPrint(self, parent, zone, line) {
    _internal.printToConsole(line);
  }
  dart.fn(_rootPrint, dart.void, [Zone, ZoneDelegate, Zone, core.String]);
  function _printToZone(line) {
    Zone.current.print(line);
  }
  dart.fn(_printToZone, dart.void, [core.String]);
  function _rootFork(self, parent, zone, specification, zoneValues) {
    _internal.printToZone = _printToZone;
    if (specification == null) {
      specification = dart.const(ZoneSpecification.new());
    } else if (!dart.is(specification, _ZoneSpecification)) {
      dart.throw(new core.ArgumentError("ZoneSpecifications must be instantiated" + " with the provided constructor."));
    }
    let valueMap = null;
    if (zoneValues == null) {
      if (dart.is(zone, _Zone)) {
        valueMap = zone[_map];
      } else {
        valueMap = collection.HashMap.new();
      }
    } else {
      valueMap = collection.HashMap.from(zoneValues);
    }
    return new _CustomZone(dart.as(zone, _Zone), specification, valueMap);
  }
  dart.fn(_rootFork, Zone, [Zone, ZoneDelegate, Zone, ZoneSpecification, core.Map]);
  class _RootZoneSpecification extends core.Object {
    get handleUncaughtError() {
      return _rootHandleUncaughtError;
    }
    get run() {
      return _rootRun;
    }
    get runUnary() {
      return _rootRunUnary;
    }
    get runBinary() {
      return _rootRunBinary;
    }
    get registerCallback() {
      return _rootRegisterCallback;
    }
    get registerUnaryCallback() {
      return _rootRegisterUnaryCallback;
    }
    get registerBinaryCallback() {
      return _rootRegisterBinaryCallback;
    }
    get errorCallback() {
      return _rootErrorCallback;
    }
    get scheduleMicrotask() {
      return _rootScheduleMicrotask;
    }
    get createTimer() {
      return _rootCreateTimer;
    }
    get createPeriodicTimer() {
      return _rootCreatePeriodicTimer;
    }
    get print() {
      return _rootPrint;
    }
    get fork() {
      return _rootFork;
    }
  }
  _RootZoneSpecification[dart.implements] = () => [ZoneSpecification];
  class _RootZone extends _Zone {
    _RootZone() {
      super._Zone();
    }
    get [_run]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootRun));
    }
    get [_runUnary]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootRunUnary));
    }
    get [_runBinary]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootRunBinary));
    }
    get [_registerCallback]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootRegisterCallback));
    }
    get [_registerUnaryCallback]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootRegisterUnaryCallback));
    }
    get [_registerBinaryCallback]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootRegisterBinaryCallback));
    }
    get [_errorCallback]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootErrorCallback));
    }
    get [_scheduleMicrotask]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootScheduleMicrotask));
    }
    get [_createTimer]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootCreateTimer));
    }
    get [_createPeriodicTimer]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootCreatePeriodicTimer));
    }
    get [_print]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootPrint));
    }
    get [_fork]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootFork));
    }
    get [_handleUncaughtError]() {
      return dart.const(new _ZoneFunction(_ROOT_ZONE, _rootHandleUncaughtError));
    }
    get parent() {
      return null;
    }
    get [_map]() {
      return _RootZone._rootMap;
    }
    get [_delegate]() {
      if (_RootZone._rootDelegate != null) return _RootZone._rootDelegate;
      return _RootZone._rootDelegate = new _ZoneDelegate(this);
    }
    get errorZone() {
      return this;
    }
    runGuarded(f) {
      try {
        if (dart.notNull(core.identical(_ROOT_ZONE, Zone._current))) {
          return f();
        }
        return _rootRun(null, null, this, f);
      } catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }

    }
    runUnaryGuarded(f, arg) {
      try {
        if (dart.notNull(core.identical(_ROOT_ZONE, Zone._current))) {
          return dart.dcall(f, arg);
        }
        return _rootRunUnary(null, null, this, f, arg);
      } catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }

    }
    runBinaryGuarded(f, arg1, arg2) {
      try {
        if (dart.notNull(core.identical(_ROOT_ZONE, Zone._current))) {
          return dart.dcall(f, arg1, arg2);
        }
        return _rootRunBinary(null, null, this, f, arg1, arg2);
      } catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }

    }
    bindCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      if (dart.notNull(runGuarded)) {
        return dart.fn((() => this.runGuarded(f)).bind(this));
      } else {
        return dart.fn((() => this.run(f)).bind(this));
      }
    }
    bindUnaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      if (dart.notNull(runGuarded)) {
        return dart.fn((arg => this.runUnaryGuarded(f, arg)).bind(this));
      } else {
        return dart.fn((arg => this.runUnary(f, arg)).bind(this));
      }
    }
    bindBinaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      if (dart.notNull(runGuarded)) {
        return dart.fn(((arg1, arg2) => this.runBinaryGuarded(f, arg1, arg2)).bind(this));
      } else {
        return dart.fn(((arg1, arg2) => this.runBinary(f, arg1, arg2)).bind(this));
      }
    }
    get(key) {
      return null;
    }
    handleUncaughtError(error, stackTrace) {
      return _rootHandleUncaughtError(null, null, this, error, stackTrace);
    }
    fork(opts) {
      let specification = opts && 'specification' in opts ? opts.specification : null;
      let zoneValues = opts && 'zoneValues' in opts ? opts.zoneValues : null;
      return _rootFork(null, null, this, specification, zoneValues);
    }
    run(f) {
      if (dart.notNull(core.identical(Zone._current, _ROOT_ZONE))) return f();
      return _rootRun(null, null, this, f);
    }
    runUnary(f, arg) {
      if (dart.notNull(core.identical(Zone._current, _ROOT_ZONE))) return dart.dcall(f, arg);
      return _rootRunUnary(null, null, this, f, arg);
    }
    runBinary(f, arg1, arg2) {
      if (dart.notNull(core.identical(Zone._current, _ROOT_ZONE))) return dart.dcall(f, arg1, arg2);
      return _rootRunBinary(null, null, this, f, arg1, arg2);
    }
    registerCallback(f) {
      return f;
    }
    registerUnaryCallback(f) {
      return f;
    }
    registerBinaryCallback(f) {
      return f;
    }
    errorCallback(error, stackTrace) {
      return null;
    }
    scheduleMicrotask(f) {
      _rootScheduleMicrotask(null, null, this, f);
    }
    createTimer(duration, f) {
      return Timer._createTimer(duration, f);
    }
    createPeriodicTimer(duration, f) {
      return Timer._createPeriodicTimer(duration, f);
    }
    print(line) {
      _internal.printToConsole(line);
    }
  }
  dart.setSignature(_RootZone, {
    constructors: () => ({_RootZone: [_RootZone, []]}),
    methods: () => ({
      runGuarded: [dart.dynamic, [dart.functionType(dart.dynamic, [])]],
      runUnaryGuarded: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]],
      runBinaryGuarded: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]],
      bindCallback: [ZoneCallback, [dart.functionType(dart.dynamic, [])], {runGuarded: core.bool}],
      bindUnaryCallback: [ZoneUnaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic])], {runGuarded: core.bool}],
      bindBinaryCallback: [ZoneBinaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])], {runGuarded: core.bool}],
      get: [dart.dynamic, [core.Object]],
      handleUncaughtError: [dart.dynamic, [dart.dynamic, core.StackTrace]],
      fork: [Zone, [], {specification: ZoneSpecification, zoneValues: core.Map}],
      run: [dart.dynamic, [dart.functionType(dart.dynamic, [])]],
      runUnary: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]],
      runBinary: [dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]],
      registerCallback: [ZoneCallback, [dart.functionType(dart.dynamic, [])]],
      registerUnaryCallback: [ZoneUnaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic])]],
      registerBinaryCallback: [ZoneBinaryCallback, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]],
      errorCallback: [AsyncError, [core.Object, core.StackTrace]],
      scheduleMicrotask: [dart.void, [dart.functionType(dart.void, [])]],
      createTimer: [Timer, [core.Duration, dart.functionType(dart.void, [])]],
      createPeriodicTimer: [Timer, [core.Duration, dart.functionType(dart.void, [Timer])]],
      print: [dart.void, [core.String]]
    })
  });
  _RootZone._rootDelegate = null;
  dart.defineLazyProperties(_RootZone, {
    get _rootMap() {
      return collection.HashMap.new();
    },
    set _rootMap(_) {}
  });
  const _ROOT_ZONE = dart.const(new _RootZone());
  function runZoned(body, opts) {
    let zoneValues = opts && 'zoneValues' in opts ? opts.zoneValues : null;
    let zoneSpecification = opts && 'zoneSpecification' in opts ? opts.zoneSpecification : null;
    let onError = opts && 'onError' in opts ? opts.onError : null;
    let errorHandler = null;
    if (onError != null) {
      errorHandler = dart.fn((self, parent, zone, error, stackTrace) => {
        try {
          if (dart.is(onError, ZoneBinaryCallback)) {
            return self.parent.runBinary(onError, error, stackTrace);
          }
          return self.parent.runUnary(dart.as(onError, __CastType116), error);
        } catch (e) {
          let s = dart.stackTrace(e);
          if (dart.notNull(core.identical(e, error))) {
            return parent.handleUncaughtError(zone, error, stackTrace);
          } else {
            return parent.handleUncaughtError(zone, e, s);
          }
        }

      }, dart.dynamic, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]);
    }
    if (zoneSpecification == null) {
      zoneSpecification = ZoneSpecification.new({handleUncaughtError: errorHandler});
    } else if (errorHandler != null) {
      zoneSpecification = ZoneSpecification.from(zoneSpecification, {handleUncaughtError: errorHandler});
    }
    let zone = Zone.current.fork({specification: zoneSpecification, zoneValues: zoneValues});
    if (onError != null) {
      return zone.runGuarded(body);
    } else {
      return zone.run(body);
    }
  }
  dart.fn(runZoned, dart.dynamic, [dart.functionType(dart.dynamic, [])], {zoneValues: core.Map, zoneSpecification: ZoneSpecification, onError: core.Function});
  const __CastType34 = dart.typedef('__CastType34', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]));
  const __CastType40 = dart.typedef('__CastType40', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  const __CastType45 = dart.typedef('__CastType45', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]));
  const __CastType52 = dart.typedef('__CastType52', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]));
  const __CastType61 = dart.typedef('__CastType61', () => dart.functionType(ZoneCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  const __CastType66 = dart.typedef('__CastType66', () => dart.functionType(ZoneUnaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic])]));
  const __CastType72 = dart.typedef('__CastType72', () => dart.functionType(ZoneBinaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]));
  const __CastType79 = dart.typedef('__CastType79', () => dart.functionType(AsyncError, [Zone, ZoneDelegate, Zone, core.Object, core.StackTrace]));
  const __CastType85 = dart.typedef('__CastType85', () => dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  const __CastType90 = dart.typedef('__CastType90', () => dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [])]));
  const __CastType96 = dart.typedef('__CastType96', () => dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [Timer])]));
  const __CastType103 = dart.typedef('__CastType103', () => dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, core.String]));
  const __CastType108 = dart.typedef('__CastType108', () => dart.functionType(Zone, [Zone, ZoneDelegate, Zone, ZoneSpecification, core.Map]));
  const __CastType114 = dart.typedef('__CastType114', () => dart.functionType(dart.void, [Timer]));
  const __CastType116 = dart.typedef('__CastType116', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  dart.copyProperties(exports, {
    get _hasDocument() {
      return typeof document == 'object';
    }
  });
  // Exports:
  exports.AsyncError = AsyncError;
  exports.Stream$ = Stream$;
  exports.Stream = Stream;
  exports.DeferredLibrary = DeferredLibrary;
  exports.DeferredLoadException = DeferredLoadException;
  exports.Future$ = Future$;
  exports.Future = Future;
  exports.TimeoutException = TimeoutException;
  exports.Completer$ = Completer$;
  exports.Completer = Completer;
  exports.scheduleMicrotask = scheduleMicrotask;
  exports.StreamSubscription$ = StreamSubscription$;
  exports.StreamSubscription = StreamSubscription;
  exports.EventSink$ = EventSink$;
  exports.EventSink = EventSink;
  exports.StreamView$ = StreamView$;
  exports.StreamView = StreamView;
  exports.StreamConsumer$ = StreamConsumer$;
  exports.StreamConsumer = StreamConsumer;
  exports.StreamSink$ = StreamSink$;
  exports.StreamSink = StreamSink;
  exports.StreamTransformer$ = StreamTransformer$;
  exports.StreamTransformer = StreamTransformer;
  exports.StreamIterator$ = StreamIterator$;
  exports.StreamIterator = StreamIterator;
  exports.StreamController$ = StreamController$;
  exports.StreamController = StreamController;
  exports.Timer = Timer;
  exports.ZoneCallback = ZoneCallback;
  exports.ZoneUnaryCallback = ZoneUnaryCallback;
  exports.ZoneBinaryCallback = ZoneBinaryCallback;
  exports.HandleUncaughtErrorHandler = HandleUncaughtErrorHandler;
  exports.RunHandler = RunHandler;
  exports.RunUnaryHandler = RunUnaryHandler;
  exports.RunBinaryHandler = RunBinaryHandler;
  exports.RegisterCallbackHandler = RegisterCallbackHandler;
  exports.RegisterUnaryCallbackHandler = RegisterUnaryCallbackHandler;
  exports.RegisterBinaryCallbackHandler = RegisterBinaryCallbackHandler;
  exports.ErrorCallbackHandler = ErrorCallbackHandler;
  exports.ScheduleMicrotaskHandler = ScheduleMicrotaskHandler;
  exports.CreateTimerHandler = CreateTimerHandler;
  exports.CreatePeriodicTimerHandler = CreatePeriodicTimerHandler;
  exports.PrintHandler = PrintHandler;
  exports.ForkHandler = ForkHandler;
  exports.ZoneSpecification = ZoneSpecification;
  exports.ZoneDelegate = ZoneDelegate;
  exports.Zone = Zone;
  exports.runZoned = runZoned;
});
