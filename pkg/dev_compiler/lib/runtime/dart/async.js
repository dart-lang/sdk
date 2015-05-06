var async = dart.defineLibrary(async, {});
var core = dart.import(core);
var _internal = dart.import(_internal);
var _js_helper = dart.lazyImport(_js_helper);
var _isolate_helper = dart.lazyImport(_isolate_helper);
var collection = dart.import(collection);
(function(exports, core, _internal, _js_helper, _isolate_helper, collection) {
  'use strict';
  // Function _invokeErrorHandler: (Function, Object, StackTrace) → dynamic
  function _invokeErrorHandler(errorHandler, error, stackTrace) {
    if (dart.is(errorHandler, ZoneBinaryCallback)) {
      return dart.dcall(errorHandler, error, stackTrace);
    } else {
      return dart.dcall(errorHandler, error);
    }
  }
  // Function _registerErrorHandler: (Function, Zone) → Function
  function _registerErrorHandler(errorHandler, zone) {
    if (dart.is(errorHandler, ZoneBinaryCallback)) {
      return zone.registerBinaryCallback(errorHandler);
    } else {
      return zone.registerUnaryCallback(dart.as(errorHandler, __CastType0));
    }
  }
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
  class _UncaughtAsyncError extends AsyncError {
    _UncaughtAsyncError(error, stackTrace) {
      super.AsyncError(error, _UncaughtAsyncError._getBestStackTrace(error, stackTrace));
    }
    static _getBestStackTrace(error, stackTrace) {
      if (stackTrace != null)
        return stackTrace;
      if (dart.is(error, core.Error)) {
        return dart.as(dart.dload(error, 'stackTrace'), core.StackTrace);
      }
      return null;
    }
    toString() {
      let result = `Uncaught Error: ${this.error}`;
      if (this.stackTrace != null) {
        result = dart.notNull(result) + `\nStack Trace:\n${this.stackTrace}`;
      }
      return result;
    }
  }
  let __CastType0 = dart.typedef('__CastType0', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  let _controller = Symbol('_controller');
  let _createSubscription = Symbol('_createSubscription');
  let _subscribe = Symbol('_subscribe');
  let _onListen = Symbol('_onListen');
  let _add = Symbol('_add');
  let _closeUnchecked = Symbol('_closeUnchecked');
  let _addError = Symbol('_addError');
  let _completeError = Symbol('_completeError');
  let _complete = Symbol('_complete');
  let _sink = Symbol('_sink');
  let Stream$ = dart.generic(function(T) {
    class Stream extends core.Object {
      Stream() {
      }
      fromFuture(future) {
        let controller = dart.as(new (StreamController$(T))({sync: true}), _StreamController$(T));
        future.then(value => {
          controller[_add](dart.as(value, T));
          controller[_closeUnchecked]();
        }, {
          onError: (error, stackTrace) => {
            controller[_addError](error, dart.as(stackTrace, core.StackTrace));
            controller[_closeUnchecked]();
          }
        });
        return controller.stream;
      }
      fromIterable(data) {
        return new (_GeneratedStreamImpl$(T))(() => new (_IterablePendingEvents$(T))(data));
      }
      periodic(period, computation) {
        if (computation === void 0)
          computation = null;
        if (computation == null)
          computation = i => null;
        let timer = null;
        let computationCount = 0;
        let controller = null;
        let watch = new core.Stopwatch();
        // Function sendEvent: () → void
        function sendEvent() {
          watch.reset();
          let data = computation((() => {
            let x = computationCount;
            computationCount = dart.notNull(x) + 1;
            return x;
          })());
          controller.add(data);
        }
        // Function startPeriodicTimer: () → void
        function startPeriodicTimer() {
          dart.assert(timer == null);
          timer = new Timer.periodic(period, timer => {
            sendEvent();
          });
        }
        controller = new (StreamController$(T))({
          sync: true,
          onListen: () => {
            watch.start();
            startPeriodicTimer();
          },
          onPause: () => {
            timer.cancel();
            timer = null;
            watch.stop();
          },
          onResume: () => {
            dart.assert(timer == null);
            let elapsed = watch.elapsed;
            watch.start();
            timer = new Timer(period['-'](elapsed), () => {
              timer = null;
              startPeriodicTimer();
              sendEvent();
            });
          },
          onCancel: () => {
            if (timer != null)
              timer.cancel();
            timer = null;
          }
        });
        return controller.stream;
      }
      eventTransformed(source, mapSink) {
        return new (_BoundSinkStream$(dart.dynamic, T))(source, dart.as(mapSink, _SinkMapper));
      }
      get isBroadcast() {
        return false;
      }
      asBroadcastStream(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        dart.as(onListen, dart.functionType(dart.void, [StreamSubscription$(T)]));
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        dart.as(onCancel, dart.functionType(dart.void, [StreamSubscription$(T)]));
        return new (_AsBroadcastStream$(T))(this, dart.as(onListen, __CastType12), dart.as(onCancel, dart.functionType(dart.void, [StreamSubscription])));
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
        // Function onListen: () → void
        function onListen() {
          let add = controller.add.bind(controller);
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = controller;
          let addError = eventSink[_addError];
          subscription = this.listen(event => {
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
              dart.dsend(dart.dsend(newValue, 'then', add, {onError: addError}), 'whenComplete', dart.bind(subscription, 'resume'));
            } else {
              controller.add(newValue);
            }
          }, {onError: dart.as(addError, core.Function), onDone: controller.close.bind(controller)});
        }
        if (this.isBroadcast) {
          controller = new StreamController.broadcast({
            onListen: onListen,
            onCancel: () => {
              subscription.cancel();
            },
            sync: true
          });
        } else {
          controller = new StreamController({
            onListen: onListen,
            onPause: () => {
              subscription.pause();
            },
            onResume: () => {
              subscription.resume();
            },
            onCancel: () => {
              subscription.cancel();
            },
            sync: true
          });
        }
        return controller.stream;
      }
      asyncExpand(convert) {
        dart.as(convert, dart.functionType(Stream, [T]));
        let controller = null;
        let subscription = null;
        // Function onListen: () → void
        function onListen() {
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = controller;
          subscription = this.listen(event => {
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
          }, {onError: dart.as(eventSink[_addError], core.Function), onDone: controller.close.bind(controller)});
        }
        if (this.isBroadcast) {
          controller = new StreamController.broadcast({
            onListen: onListen,
            onCancel: () => {
              subscription.cancel();
            },
            sync: true
          });
        } else {
          controller = new StreamController({
            onListen: onListen,
            onPause: () => {
              subscription.pause();
            },
            onResume: () => {
              subscription.resume();
            },
            onCancel: () => {
              subscription.cancel();
            },
            sync: true
          });
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
        return streamConsumer.addStream(this).then(_ => streamConsumer.close());
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
        subscription = this.listen(element => {
          dart.as(element, T);
          if (seenFirst) {
            _runUserCode(() => combine(value, element), newValue => {
              dart.as(newValue, T);
              value = newValue;
            }, dart.as(_cancelAndErrorClosure(subscription, result), __CastType14));
          } else {
            value = element;
            seenFirst = true;
          }
        }, {
          onError: result[_completeError].bind(result),
          onDone: () => {
            if (!dart.notNull(seenFirst)) {
              try {
                throw _internal.IterableElementError.noElement();
              } catch (e) {
                let s = dart.stackTrace(e);
                _completeWithErrorCallback(result, e, s);
              }

            } else {
              result[_complete](value);
            }
          },
          cancelOnError: true
        });
        return result;
      }
      fold(initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, T]));
        let result = new _Future();
        let value = initialValue;
        let subscription = null;
        subscription = this.listen(element => {
          dart.as(element, T);
          _runUserCode(() => dart.dcall(combine, value, element), newValue => {
            value = newValue;
          }, dart.as(_cancelAndErrorClosure(subscription, result), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: (e, st) => {
            result[_completeError](e, dart.as(st, core.StackTrace));
          },
          onDone: () => {
            result[_complete](value);
          },
          cancelOnError: true
        });
        return result;
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let result = new (_Future$(core.String))();
        let buffer = new core.StringBuffer();
        let subscription = null;
        let first = true;
        subscription = this.listen(element => {
          dart.as(element, T);
          if (!dart.notNull(first)) {
            buffer.write(separator);
          }
          first = false;
          try {
            buffer.write(element);
          } catch (e) {
            let s = dart.stackTrace(e);
            _cancelAndErrorWithReplacement(subscription, result, e, s);
          }

        }, {
          onError: e => {
            result[_completeError](e);
          },
          onDone: () => {
            result[_complete](dart.toString(buffer));
          },
          cancelOnError: true
        });
        return result;
      }
      contains(needle) {
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(element => {
          dart.as(element, T);
          _runUserCode(() => dart.equals(element, needle), isMatch => {
            if (isMatch) {
              _cancelAndValue(subscription, future, true);
            }
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](false);
          },
          cancelOnError: true
        });
        return future;
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [T]));
        let future = new _Future();
        let subscription = null;
        subscription = this.listen(element => {
          dart.as(element, T);
          _runUserCode(() => action(element), _ => {
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](null);
          },
          cancelOnError: true
        });
        return future;
      }
      every(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(element => {
          dart.as(element, T);
          _runUserCode(() => test(element), isMatch => {
            if (!dart.notNull(isMatch)) {
              _cancelAndValue(subscription, future, false);
            }
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](true);
          },
          cancelOnError: true
        });
        return future;
      }
      any(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(element => {
          dart.as(element, T);
          _runUserCode(() => test(element), isMatch => {
            if (isMatch) {
              _cancelAndValue(subscription, future, true);
            }
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](false);
          },
          cancelOnError: true
        });
        return future;
      }
      get length() {
        let future = new (_Future$(core.int))();
        let count = 0;
        this.listen(_ => {
          count = dart.notNull(count) + 1;
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](count);
          },
          cancelOnError: true
        });
        return future;
      }
      get isEmpty() {
        let future = new (_Future$(core.bool))();
        let subscription = null;
        subscription = this.listen(_ => {
          _cancelAndValue(subscription, future, false);
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](true);
          },
          cancelOnError: true
        });
        return future;
      }
      toList() {
        let result = dart.setType([], core.List$(T));
        let future = new (_Future$(core.List$(T)))();
        this.listen(data => {
          dart.as(data, T);
          result[core.$add](data);
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](result);
          },
          cancelOnError: true
        });
        return future;
      }
      toSet() {
        let result = new (core.Set$(T))();
        let future = new (_Future$(core.Set$(T)))();
        this.listen(data => {
          dart.as(data, T);
          result.add(data);
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            future[_complete](result);
          },
          cancelOnError: true
        });
        return future;
      }
      drain(futureValue) {
        if (futureValue === void 0)
          futureValue = null;
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
        if (equals === void 0)
          equals = null;
        dart.as(equals, dart.functionType(core.bool, [T, T]));
        return new (_DistinctStream$(T))(this, equals);
      }
      get first() {
        let future = new (_Future$(T))();
        let subscription = null;
        subscription = this.listen(value => {
          dart.as(value, T);
          _cancelAndValue(subscription, future, value);
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            try {
              throw _internal.IterableElementError.noElement();
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          },
          cancelOnError: true
        });
        return future;
      }
      get last() {
        let future = new (_Future$(T))();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(value => {
          dart.as(value, T);
          foundResult = true;
          result = value;
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            try {
              throw _internal.IterableElementError.noElement();
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          },
          cancelOnError: true
        });
        return future;
      }
      get single() {
        let future = new (_Future$(T))();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(value => {
          dart.as(value, T);
          if (foundResult) {
            try {
              throw _internal.IterableElementError.tooMany();
            } catch (e) {
              let s = dart.stackTrace(e);
              _cancelAndErrorWithReplacement(subscription, future, e, s);
            }

            return;
          }
          foundResult = true;
          result = value;
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            try {
              throw _internal.IterableElementError.noElement();
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          },
          cancelOnError: true
        });
        return future;
      }
      firstWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let defaultValue = opts && 'defaultValue' in opts ? opts.defaultValue : null;
        dart.as(defaultValue, dart.functionType(core.Object, []));
        let future = new _Future();
        let subscription = null;
        subscription = this.listen(value => {
          dart.as(value, T);
          _runUserCode(() => test(value), isMatch => {
            if (isMatch) {
              _cancelAndValue(subscription, future, value);
            }
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            if (defaultValue != null) {
              _runUserCode(defaultValue, future[_complete].bind(future), future[_completeError].bind(future));
              return;
            }
            try {
              throw _internal.IterableElementError.noElement();
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          },
          cancelOnError: true
        });
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
        subscription = this.listen(value => {
          dart.as(value, T);
          _runUserCode(() => true == test(value), isMatch => {
            if (isMatch) {
              foundResult = true;
              result = value;
            }
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            if (defaultValue != null) {
              _runUserCode(defaultValue, future[_complete].bind(future), future[_completeError].bind(future));
              return;
            }
            try {
              throw _internal.IterableElementError.noElement();
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          },
          cancelOnError: true
        });
        return future;
      }
      singleWhere(test) {
        dart.as(test, dart.functionType(core.bool, [T]));
        let future = new (_Future$(T))();
        let result = null;
        let foundResult = false;
        let subscription = null;
        subscription = this.listen(value => {
          dart.as(value, T);
          _runUserCode(() => true == test(value), isMatch => {
            if (isMatch) {
              if (foundResult) {
                try {
                  throw _internal.IterableElementError.tooMany();
                } catch (e) {
                  let s = dart.stackTrace(e);
                  _cancelAndErrorWithReplacement(subscription, future, e, s);
                }

                return;
              }
              foundResult = true;
              result = value;
            }
          }, dart.as(_cancelAndErrorClosure(subscription, future), dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace])));
        }, {
          onError: future[_completeError].bind(future),
          onDone: () => {
            if (foundResult) {
              future[_complete](result);
              return;
            }
            try {
              throw _internal.IterableElementError.noElement();
            } catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(future, e, s);
            }

          },
          cancelOnError: true
        });
        return future;
      }
      elementAt(index) {
        if (!(typeof index == 'number') || dart.notNull(index) < 0)
          throw new core.ArgumentError(index);
        let future = new (_Future$(T))();
        let subscription = null;
        let elementIndex = 0;
        subscription = this.listen(value => {
          dart.as(value, T);
          if (index == elementIndex) {
            _cancelAndValue(subscription, future, value);
            return;
          }
          elementIndex = dart.notNull(elementIndex) + 1;
        }, {
          onError: future[_completeError].bind(future),
          onDone: (() => {
            future[_completeError](new core.RangeError.index(index, this, "index", null, elementIndex));
          }).bind(this),
          cancelOnError: true
        });
        return future;
      }
      timeout(timeLimit, opts) {
        let onTimeout = opts && 'onTimeout' in opts ? opts.onTimeout : null;
        dart.as(onTimeout, dart.functionType(dart.void, [EventSink]));
        let controller = null;
        let subscription = null;
        let timer = null;
        let zone = null;
        let timeout = null;
        // Function onData: (T) → void
        function onData(event) {
          dart.as(event, T);
          timer.cancel();
          controller.add(event);
          timer = zone.createTimer(timeLimit, dart.as(timeout, __CastType17));
        }
        // Function onError: (dynamic, StackTrace) → void
        function onError(error, stackTrace) {
          timer.cancel();
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = controller;
          dart.dcall(eventSink[_addError], error, stackTrace);
          timer = zone.createTimer(timeLimit, dart.as(timeout, dart.functionType(dart.void, [])));
        }
        // Function onDone: () → void
        function onDone() {
          timer.cancel();
          controller.close();
        }
        // Function onListen: () → void
        function onListen() {
          zone = Zone.current;
          if (onTimeout == null) {
            timeout = () => {
              controller.addError(new TimeoutException("No stream event", timeLimit), null);
            };
          } else {
            onTimeout = dart.as(zone.registerUnaryCallback(onTimeout), __CastType18);
            let wrapper = new _ControllerEventSinkWrapper(null);
            timeout = () => {
              wrapper[_sink] = controller;
              zone.runUnaryGuarded(onTimeout, wrapper);
              wrapper[_sink] = null;
            };
          }
          subscription = this.listen(onData, {onError: onError, onDone: onDone});
          timer = zone.createTimer(timeLimit, dart.as(timeout, dart.functionType(dart.void, [])));
        }
        // Function onCancel: () → Future<dynamic>
        function onCancel() {
          timer.cancel();
          let result = subscription.cancel();
          subscription = null;
          return result;
        }
        controller = this.isBroadcast ? new _SyncBroadcastStreamController(onListen, onCancel) : new _SyncStreamController(onListen, () => {
          timer.cancel();
          subscription.pause();
        }, () => {
          subscription.resume();
          timer = zone.createTimer(timeLimit, dart.as(timeout, dart.functionType(dart.void, [])));
        }, onCancel);
        return controller.stream;
      }
    }
    dart.defineNamedConstructor(Stream, 'fromFuture');
    dart.defineNamedConstructor(Stream, 'fromIterable');
    dart.defineNamedConstructor(Stream, 'periodic');
    dart.defineNamedConstructor(Stream, 'eventTransformed');
    return Stream;
  });
  let Stream = Stream$();
  let _StreamImpl$ = dart.generic(function(T) {
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
    return _StreamImpl;
  });
  let _StreamImpl = _StreamImpl$();
  let _ControllerStream$ = dart.generic(function(T) {
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
        if (core.identical(this, other))
          return true;
        if (!dart.is(other, _ControllerStream))
          return false;
        let otherStream = dart.as(other, _ControllerStream);
        return core.identical(otherStream[_controller], this[_controller]);
      }
    }
    return _ControllerStream;
  });
  let _ControllerStream = _ControllerStream$();
  let _BroadcastStream$ = dart.generic(function(T) {
    class _BroadcastStream extends _ControllerStream$(T) {
      _BroadcastStream(controller) {
        super._ControllerStream(dart.as(controller, _StreamControllerLifecycle$(T)));
      }
      get isBroadcast() {
        return true;
      }
    }
    return _BroadcastStream;
  });
  let _BroadcastStream = _BroadcastStream$();
  let _next = Symbol('_next');
  let _previous = Symbol('_previous');
  class _BroadcastSubscriptionLink extends core.Object {
    _BroadcastSubscriptionLink() {
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let _eventState = Symbol('_eventState');
  let _expectsEvent = Symbol('_expectsEvent');
  let _toggleEventId = Symbol('_toggleEventId');
  let _isFiring = Symbol('_isFiring');
  let _setRemoveAfterFiring = Symbol('_setRemoveAfterFiring');
  let _removeAfterFiring = Symbol('_removeAfterFiring');
  let _onPause = Symbol('_onPause');
  let _onResume = Symbol('_onResume');
  let _onCancel = Symbol('_onCancel');
  let _recordCancel = Symbol('_recordCancel');
  let _recordPause = Symbol('_recordPause');
  let _recordResume = Symbol('_recordResume');
  let _zone = Symbol('_zone');
  let _state = Symbol('_state');
  let _onData = Symbol('_onData');
  let _onError = Symbol('_onError');
  let _onDone = Symbol('_onDone');
  let _cancelFuture = Symbol('_cancelFuture');
  let _pending = Symbol('_pending');
  let _setPendingEvents = Symbol('_setPendingEvents');
  let _extractPending = Symbol('_extractPending');
  let _isCanceled = Symbol('_isCanceled');
  let _isPaused = Symbol('_isPaused');
  let _isInputPaused = Symbol('_isInputPaused');
  let _inCallback = Symbol('_inCallback');
  let _guardCallback = Symbol('_guardCallback');
  let _decrementPauseCount = Symbol('_decrementPauseCount');
  let _hasPending = Symbol('_hasPending');
  let _mayResumeInput = Symbol('_mayResumeInput');
  let _cancel = Symbol('_cancel');
  let _isClosed = Symbol('_isClosed');
  let _waitsForCancel = Symbol('_waitsForCancel');
  let _canFire = Symbol('_canFire');
  let _cancelOnError = Symbol('_cancelOnError');
  let _incrementPauseCount = Symbol('_incrementPauseCount');
  let _sendData = Symbol('_sendData');
  let _addPending = Symbol('_addPending');
  let _sendError = Symbol('_sendError');
  let _close = Symbol('_close');
  let _sendDone = Symbol('_sendDone');
  let _checkState = Symbol('_checkState');
  let _BufferingStreamSubscription$ = dart.generic(function(T) {
    class _BufferingStreamSubscription extends core.Object {
      _BufferingStreamSubscription(onData, onError, onDone, cancelOnError) {
        this[_zone] = Zone.current;
        this[_state] = cancelOnError ? _BufferingStreamSubscription._STATE_CANCEL_ON_ERROR : 0;
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
        if (pendingEvents == null)
          return;
        this[_pending] = pendingEvents;
        if (!dart.notNull(pendingEvents.isEmpty)) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_HAS_PENDING);
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
        if (handleData == null)
          handleData = dart.as(_nullDataHandler, __CastType20);
        this[_onData] = dart.as(this[_zone].registerUnaryCallback(handleData), _DataHandler$(T));
      }
      onError(handleError) {
        if (handleError == null)
          handleError = _nullErrorHandler;
        this[_onError] = _registerErrorHandler(handleError, this[_zone]);
      }
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
        if (handleDone == null)
          handleDone = _nullDoneHandler;
        this[_onDone] = this[_zone].registerCallback(handleDone);
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0)
          resumeSignal = null;
        if (this[_isCanceled])
          return;
        let wasPaused = this[_isPaused];
        let wasInputPaused = this[_isInputPaused];
        this[_state] = dart.notNull(this[_state]) + dart.notNull(_BufferingStreamSubscription._STATE_PAUSE_COUNT) | dart.notNull(_BufferingStreamSubscription._STATE_INPUT_PAUSED);
        if (resumeSignal != null)
          resumeSignal.whenComplete(this.resume.bind(this));
        if (!dart.notNull(wasPaused) && dart.notNull(this[_pending] != null))
          this[_pending].cancelSchedule();
        if (!dart.notNull(wasInputPaused) && !dart.notNull(this[_inCallback]))
          this[_guardCallback](this[_onPause].bind(this));
      }
      resume() {
        if (this[_isCanceled])
          return;
        if (this[_isPaused]) {
          this[_decrementPauseCount]();
          if (!dart.notNull(this[_isPaused])) {
            if (dart.notNull(this[_hasPending]) && !dart.notNull(this[_pending].isEmpty)) {
              this[_pending].schedule(this);
            } else {
              dart.assert(this[_mayResumeInput]);
              this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_INPUT_PAUSED);
              if (!dart.notNull(this[_inCallback]))
                this[_guardCallback](this[_onResume].bind(this));
            }
          }
        }
      }
      cancel() {
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_WAIT_FOR_CANCEL);
        if (this[_isCanceled])
          return this[_cancelFuture];
        this[_cancel]();
        return this[_cancelFuture];
      }
      asFuture(futureValue) {
        if (futureValue === void 0)
          futureValue = null;
        let result = new (_Future$(T))();
        this[_onDone] = () => {
          result[_complete](futureValue);
        };
        this[_onError] = ((error, stackTrace) => {
          this.cancel();
          result[_completeError](error, dart.as(stackTrace, core.StackTrace));
        }).bind(this);
        return result;
      }
      get [_isInputPaused]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_INPUT_PAUSED)) != 0;
      }
      get [_isClosed]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_CLOSED)) != 0;
      }
      get [_isCanceled]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_CANCELED)) != 0;
      }
      get [_waitsForCancel]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_WAIT_FOR_CANCEL)) != 0;
      }
      get [_inCallback]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK)) != 0;
      }
      get [_hasPending]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_HAS_PENDING)) != 0;
      }
      get [_isPaused]() {
        return dart.notNull(this[_state]) >= dart.notNull(_BufferingStreamSubscription._STATE_PAUSE_COUNT);
      }
      get [_canFire]() {
        return dart.notNull(this[_state]) < dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
      }
      get [_mayResumeInput]() {
        return !dart.notNull(this[_isPaused]) && (dart.notNull(this[_pending] == null) || dart.notNull(this[_pending].isEmpty));
      }
      get [_cancelOnError]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BufferingStreamSubscription._STATE_CANCEL_ON_ERROR)) != 0;
      }
      get isPaused() {
        return this[_isPaused];
      }
      [_cancel]() {
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_CANCELED);
        if (this[_hasPending]) {
          this[_pending].cancelSchedule();
        }
        if (!dart.notNull(this[_inCallback]))
          this[_pending] = null;
        this[_cancelFuture] = this[_onCancel]();
      }
      [_incrementPauseCount]() {
        this[_state] = dart.notNull(this[_state]) + dart.notNull(_BufferingStreamSubscription._STATE_PAUSE_COUNT) | dart.notNull(_BufferingStreamSubscription._STATE_INPUT_PAUSED);
      }
      [_decrementPauseCount]() {
        dart.assert(this[_isPaused]);
        this[_state] = dart.notNull(this[_state]) - dart.notNull(_BufferingStreamSubscription._STATE_PAUSE_COUNT);
      }
      [_add](data) {
        dart.as(data, T);
        dart.assert(!dart.notNull(this[_isClosed]));
        if (this[_isCanceled])
          return;
        if (this[_canFire]) {
          this[_sendData](data);
        } else {
          this[_addPending](new _DelayedData(data));
        }
      }
      [_addError](error, stackTrace) {
        if (this[_isCanceled])
          return;
        if (this[_canFire]) {
          this[_sendError](error, stackTrace);
        } else {
          this[_addPending](new _DelayedError(error, stackTrace));
        }
      }
      [_close]() {
        dart.assert(!dart.notNull(this[_isClosed]));
        if (this[_isCanceled])
          return;
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_CLOSED);
        if (this[_canFire]) {
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
        if (this[_pending] == null)
          pending = this[_pending] = new _StreamImplEvents();
        pending.add(event);
        if (!dart.notNull(this[_hasPending])) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_HAS_PENDING);
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
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
        this[_zone].runUnaryGuarded(this[_onData], data);
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
        this[_checkState](wasInputPaused);
      }
      [_sendError](error, stackTrace) {
        dart.assert(!dart.notNull(this[_isCanceled]));
        dart.assert(!dart.notNull(this[_isPaused]));
        dart.assert(!dart.notNull(this[_inCallback]));
        let wasInputPaused = this[_isInputPaused];
        // Function sendError: () → void
        function sendError() {
          if (dart.notNull(this[_isCanceled]) && !dart.notNull(this[_waitsForCancel]))
            return;
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
          if (dart.is(this[_onError], ZoneBinaryCallback)) {
            this[_zone].runBinaryGuarded(dart.as(this[_onError], __CastType22), error, stackTrace);
          } else {
            this[_zone].runUnaryGuarded(dart.as(this[_onError], __CastType25), error);
          }
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
        }
        if (this[_cancelOnError]) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_WAIT_FOR_CANCEL);
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
        // Function sendDone: () → void
        function sendDone() {
          if (!dart.notNull(this[_waitsForCancel]))
            return;
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_CANCELED) | dart.notNull(_BufferingStreamSubscription._STATE_CLOSED) | dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
          this[_zone].runGuarded(this[_onDone]);
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
        }
        this[_cancel]();
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_WAIT_FOR_CANCEL);
        if (dart.is(this[_cancelFuture], Future)) {
          this[_cancelFuture].whenComplete(sendDone);
        } else {
          sendDone();
        }
      }
      [_guardCallback](callback) {
        dart.assert(!dart.notNull(this[_inCallback]));
        let wasInputPaused = this[_isInputPaused];
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
        dart.dcall(callback);
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
        this[_checkState](wasInputPaused);
      }
      [_checkState](wasInputPaused) {
        dart.assert(!dart.notNull(this[_inCallback]));
        if (dart.notNull(this[_hasPending]) && dart.notNull(this[_pending].isEmpty)) {
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_HAS_PENDING);
          if (dart.notNull(this[_isInputPaused]) && dart.notNull(this[_mayResumeInput])) {
            this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_INPUT_PAUSED);
          }
        }
        while (true) {
          if (this[_isCanceled]) {
            this[_pending] = null;
            return;
          }
          let isInputPaused = this[_isInputPaused];
          if (wasInputPaused == isInputPaused)
            break;
          this[_state] = dart.notNull(this[_state]) ^ dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
          if (isInputPaused) {
            this[_onPause]();
          } else {
            this[_onResume]();
          }
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BufferingStreamSubscription._STATE_IN_CALLBACK);
          wasInputPaused = isInputPaused;
        }
        if (dart.notNull(this[_hasPending]) && !dart.notNull(this[_isPaused])) {
          this[_pending].schedule(this);
        }
      }
    }
    _BufferingStreamSubscription[dart.implements] = () => [StreamSubscription$(T), _EventSink$(T), _EventDispatch$(T)];
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
  let _ControllerSubscription$ = dart.generic(function(T) {
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
    return _ControllerSubscription;
  });
  let _ControllerSubscription = _ControllerSubscription$();
  let _BroadcastSubscription$ = dart.generic(function(T) {
    class _BroadcastSubscription extends _ControllerSubscription$(T) {
      _BroadcastSubscription(controller, onData, onError, onDone, cancelOnError) {
        this[_eventState] = null;
        this[_next] = null;
        this[_previous] = null;
        super._ControllerSubscription(dart.as(controller, _StreamControllerLifecycle$(T)), onData, onError, onDone, cancelOnError);
        this[_next] = this[_previous] = this;
      }
      get [_controller]() {
        return dart.as(super[_controller], _BroadcastStreamController$(T));
      }
      [_expectsEvent](eventId) {
        return (dart.notNull(this[_eventState]) & dart.notNull(_BroadcastSubscription._STATE_EVENT_ID)) == eventId;
      }
      [_toggleEventId]() {
        this[_eventState] = dart.notNull(this[_eventState]) ^ dart.notNull(_BroadcastSubscription._STATE_EVENT_ID);
      }
      get [_isFiring]() {
        return (dart.notNull(this[_eventState]) & dart.notNull(_BroadcastSubscription._STATE_FIRING)) != 0;
      }
      [_setRemoveAfterFiring]() {
        dart.assert(this[_isFiring]);
        this[_eventState] = dart.notNull(this[_eventState]) | dart.notNull(_BroadcastSubscription._STATE_REMOVE_AFTER_FIRING);
      }
      get [_removeAfterFiring]() {
        return (dart.notNull(this[_eventState]) & dart.notNull(_BroadcastSubscription._STATE_REMOVE_AFTER_FIRING)) != 0;
      }
      [_onPause]() {}
      [_onResume]() {}
    }
    _BroadcastSubscription[dart.implements] = () => [_BroadcastSubscriptionLink];
    _BroadcastSubscription._STATE_EVENT_ID = 1;
    _BroadcastSubscription._STATE_FIRING = 2;
    _BroadcastSubscription._STATE_REMOVE_AFTER_FIRING = 4;
    return _BroadcastSubscription;
  });
  let _BroadcastSubscription = _BroadcastSubscription$();
  let _addStreamState = Symbol('_addStreamState');
  let _doneFuture = Symbol('_doneFuture');
  let _isEmpty = Symbol('_isEmpty');
  let _hasOneListener = Symbol('_hasOneListener');
  let _isAddingStream = Symbol('_isAddingStream');
  let _mayAddEvent = Symbol('_mayAddEvent');
  let _ensureDoneFuture = Symbol('_ensureDoneFuture');
  let _addListener = Symbol('_addListener');
  let _removeListener = Symbol('_removeListener');
  let _callOnCancel = Symbol('_callOnCancel');
  let _addEventError = Symbol('_addEventError');
  let _forEachListener = Symbol('_forEachListener');
  let _mayComplete = Symbol('_mayComplete');
  let _asyncComplete = Symbol('_asyncComplete');
  let _BroadcastStreamController$ = dart.generic(function(T) {
    class _BroadcastStreamController extends core.Object {
      _BroadcastStreamController(onListen, onCancel) {
        this[_onListen] = onListen;
        this[_onCancel] = onCancel;
        this[_state] = _BroadcastStreamController._STATE_INITIAL;
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
        return (dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController._STATE_CLOSED)) != 0;
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
        return (dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController._STATE_FIRING)) != 0;
      }
      get [_isAddingStream]() {
        return (dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController._STATE_ADDSTREAM)) != 0;
      }
      get [_mayAddEvent]() {
        return dart.notNull(this[_state]) < dart.notNull(_BroadcastStreamController._STATE_CLOSED);
      }
      [_ensureDoneFuture]() {
        if (this[_doneFuture] != null)
          return this[_doneFuture];
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
        subscription[_eventState] = dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController._STATE_EVENT_ID);
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
        if (this.isClosed) {
          if (onDone == null)
            onDone = _nullDoneHandler;
          return new (_DoneStreamSubscription$(T))(onDone);
        }
        let subscription = new (_BroadcastSubscription$(T))(this, onData, onError, onDone, cancelOnError);
        this[_addListener](dart.as(subscription, _BroadcastSubscription$(T)));
        if (core.identical(this[_next], this[_previous])) {
          _runGuarded(this[_onListen]);
        }
        return dart.as(subscription, StreamSubscription$(T));
      }
      [_recordCancel](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        if (core.identical(subscription[_next], subscription))
          return null;
        dart.assert(!dart.notNull(core.identical(subscription[_next], subscription)));
        if (subscription[_isFiring]) {
          dart.dcall(subscription[_setRemoveAfterFiring]);
        } else {
          dart.assert(!dart.notNull(core.identical(subscription[_next], subscription)));
          this[_removeListener](dart.as(subscription, _BroadcastSubscription$(T)));
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
        if (this.isClosed) {
          return new core.StateError("Cannot add new events after calling close");
        }
        dart.assert(this[_isAddingStream]);
        return new core.StateError("Cannot add new events while doing an addStream");
      }
      add(data) {
        dart.as(data, T);
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_addEventError]();
        this[_sendData](data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_addEventError]();
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement != null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this[_sendError](error, stackTrace);
      }
      close() {
        if (this.isClosed) {
          dart.assert(this[_doneFuture] != null);
          return this[_doneFuture];
        }
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_addEventError]();
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController._STATE_CLOSED);
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
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_addEventError]();
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController._STATE_ADDSTREAM);
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
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BroadcastStreamController._STATE_ADDSTREAM);
        addState.complete();
      }
      [_forEachListener](action) {
        dart.as(action, dart.functionType(dart.void, [_BufferingStreamSubscription$(T)]));
        if (this[_isFiring]) {
          throw new core.StateError("Cannot fire new event. Controller is already firing an event");
        }
        if (this[_isEmpty])
          return;
        let id = dart.notNull(this[_state]) & dart.notNull(_BroadcastStreamController._STATE_EVENT_ID);
        this[_state] = dart.notNull(this[_state]) ^ (dart.notNull(_BroadcastStreamController._STATE_EVENT_ID) | dart.notNull(_BroadcastStreamController._STATE_FIRING));
        let link = this[_next];
        while (!dart.notNull(core.identical(link, this))) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          if (subscription[_expectsEvent](id)) {
            subscription[_eventState] = dart.notNull(subscription[_eventState]) | dart.notNull(_BroadcastSubscription._STATE_FIRING);
            action(subscription);
            subscription[_toggleEventId]();
            link = subscription[_next];
            if (subscription[_removeAfterFiring]) {
              this[_removeListener](subscription);
            }
            subscription[_eventState] = dart.notNull(subscription[_eventState]) & ~dart.notNull(_BroadcastSubscription._STATE_FIRING);
          } else {
            link = subscription[_next];
          }
        }
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BroadcastStreamController._STATE_FIRING);
        if (this[_isEmpty]) {
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
    _BroadcastStreamController._STATE_INITIAL = 0;
    _BroadcastStreamController._STATE_EVENT_ID = 1;
    _BroadcastStreamController._STATE_FIRING = 2;
    _BroadcastStreamController._STATE_CLOSED = 4;
    _BroadcastStreamController._STATE_ADDSTREAM = 8;
    return _BroadcastStreamController;
  });
  let _BroadcastStreamController = _BroadcastStreamController$();
  let _SyncBroadcastStreamController$ = dart.generic(function(T) {
    class _SyncBroadcastStreamController extends _BroadcastStreamController$(T) {
      _SyncBroadcastStreamController(onListen, onCancel) {
        super._BroadcastStreamController(onListen, onCancel);
      }
      [_sendData](data) {
        dart.as(data, T);
        if (this[_isEmpty])
          return;
        if (this[_hasOneListener]) {
          this[_state] = dart.notNull(this[_state]) | dart.notNull(_BroadcastStreamController._STATE_FIRING);
          let subscription = dart.as(this[_next], _BroadcastSubscription);
          subscription[_add](data);
          this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_BroadcastStreamController._STATE_FIRING);
          if (this[_isEmpty]) {
            this[_callOnCancel]();
          }
          return;
        }
        this[_forEachListener](subscription => {
          dart.as(subscription, _BufferingStreamSubscription$(T));
          subscription[_add](data);
        });
      }
      [_sendError](error, stackTrace) {
        if (this[_isEmpty])
          return;
        this[_forEachListener](subscription => {
          dart.as(subscription, _BufferingStreamSubscription$(T));
          subscription[_addError](error, stackTrace);
        });
      }
      [_sendDone]() {
        if (!dart.notNull(this[_isEmpty])) {
          this[_forEachListener](dart.as(subscription => {
            dart.as(subscription, _BroadcastSubscription$(T));
            subscription[_close]();
          }, __CastType2));
        } else {
          dart.assert(this[_doneFuture] != null);
          dart.assert(this[_doneFuture][_mayComplete]);
          this[_doneFuture][_asyncComplete](null);
        }
      }
    }
    return _SyncBroadcastStreamController;
  });
  let _SyncBroadcastStreamController = _SyncBroadcastStreamController$();
  let _AsyncBroadcastStreamController$ = dart.generic(function(T) {
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
    return _AsyncBroadcastStreamController;
  });
  let _AsyncBroadcastStreamController = _AsyncBroadcastStreamController$();
  let _addPendingEvent = Symbol('_addPendingEvent');
  let _AsBroadcastStreamController$ = dart.generic(function(T) {
    class _AsBroadcastStreamController extends _SyncBroadcastStreamController$(T) {
      _AsBroadcastStreamController(onListen, onCancel) {
        this[_pending] = null;
        super._SyncBroadcastStreamController(onListen, onCancel);
      }
      get [_hasPending]() {
        return dart.notNull(this[_pending] != null) && !dart.notNull(this[_pending].isEmpty);
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
        while (this[_hasPending]) {
          this[_pending].handleNext(this);
        }
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        if (!dart.notNull(this.isClosed) && dart.notNull(this[_isFiring])) {
          this[_addPendingEvent](new _DelayedError(error, stackTrace));
          return;
        }
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_addEventError]();
        this[_sendError](error, stackTrace);
        while (this[_hasPending]) {
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
        if (this[_hasPending]) {
          this[_pending].clear();
          this[_pending] = null;
        }
        super[_callOnCancel]();
      }
    }
    _AsBroadcastStreamController[dart.implements] = () => [_EventDispatch$(T)];
    return _AsBroadcastStreamController;
  });
  let _AsBroadcastStreamController = _AsBroadcastStreamController$();
  let _pauseCount = Symbol('_pauseCount');
  let _resume = Symbol('_resume');
  let _DoneSubscription$ = dart.generic(function(T) {
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
        if (resumeSignal === void 0)
          resumeSignal = null;
        if (resumeSignal != null)
          resumeSignal.then(this[_resume].bind(this));
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
        if (value === void 0)
          value = null;
        return new _Future();
      }
    }
    _DoneSubscription[dart.implements] = () => [StreamSubscription$(T)];
    return _DoneSubscription;
  });
  let _DoneSubscription = _DoneSubscription$();
  let __CastType2$ = dart.generic(function(T) {
    let __CastType2 = dart.typedef('__CastType2', () => dart.functionType(dart.void, [_BufferingStreamSubscription$(T)]));
    return __CastType2;
  });
  let __CastType2 = __CastType2$();
  class DeferredLibrary extends core.Object {
    DeferredLibrary(libraryName, opts) {
      let uri = opts && 'uri' in opts ? opts.uri : null;
      this.libraryName = libraryName;
      this.uri = uri;
    }
    load() {
      throw 'DeferredLibrary not supported. ' + 'please use the `import "lib.dart" deferred as lib` syntax.';
    }
  }
  let _s = Symbol('_s');
  class DeferredLoadException extends core.Object {
    DeferredLoadException(s) {
      this[_s] = s;
    }
    toString() {
      return `DeferredLoadException: '${this[_s]}'`;
    }
  }
  DeferredLoadException[dart.implements] = () => [core.Exception];
  let _completeWithValue = Symbol('_completeWithValue');
  let Future$ = dart.generic(function(T) {
    class Future extends core.Object {
      Future(computation) {
        let result = new (_Future$(T))();
        Timer.run(() => {
          try {
            result[_complete](computation());
          } catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }

        });
        return dart.as(result, Future$(T));
      }
      microtask(computation) {
        let result = new (_Future$(T))();
        scheduleMicrotask(() => {
          try {
            result[_complete](computation());
          } catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }

        });
        return dart.as(result, Future$(T));
      }
      sync(computation) {
        try {
          let result = computation();
          return new (Future$(T)).value(result);
        } catch (error) {
          let stackTrace = dart.stackTrace(error);
          return new (Future$(T)).error(error, stackTrace);
        }

      }
      value(value) {
        if (value === void 0)
          value = null;
        return new (_Future$(T)).immediate(value);
      }
      error(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
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
      delayed(duration, computation) {
        if (computation === void 0)
          computation = null;
        let result = new (_Future$(T))();
        new Timer(duration, () => {
          try {
            result[_complete](computation == null ? null : computation());
          } catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }

        });
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
        // Function handleError: (dynamic, dynamic) → void
        function handleError(theError, theStackTrace) {
          remaining = dart.notNull(remaining) - 1;
          if (values != null) {
            if (cleanUp != null) {
              for (let value of values) {
                if (value != null) {
                  new Future.sync(() => {
                    dart.dcall(cleanUp, value);
                  });
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
        for (let future of futures) {
          let pos = remaining;
          remaining = dart.notNull(pos) + 1;
          future.then(value => {
            remaining = dart.notNull(remaining) - 1;
            if (values != null) {
              values[core.$set](pos, value);
              if (remaining == 0) {
                result[_completeWithValue](values);
              }
            } else {
              if (dart.notNull(cleanUp != null) && dart.notNull(value != null)) {
                new Future.sync(() => {
                  dart.dcall(cleanUp, value);
                });
              }
              if (remaining == 0 && !dart.notNull(eagerError)) {
                result[_completeError](error, stackTrace);
              }
            }
          }, {onError: handleError});
        }
        if (remaining == 0) {
          return new (Future$(core.List)).value(dart.const([]));
        }
        values = new core.List(remaining);
        return result;
      }
      static forEach(input, f) {
        dart.as(f, dart.functionType(dart.dynamic, [dart.dynamic]));
        let iterator = input[core.$iterator];
        return Future.doWhile(() => {
          if (!dart.notNull(iterator.moveNext()))
            return false;
          return new Future.sync(() => dart.dcall(f, iterator.current)).then(_ => true);
        });
      }
      static doWhile(f) {
        dart.as(f, dart.functionType(dart.dynamic, []));
        let doneSignal = new _Future();
        let nextIteration = null;
        nextIteration = Zone.current.bindUnaryCallback(keepGoing => {
          if (keepGoing) {
            new Future.sync(f).then(dart.as(nextIteration, __CastType4), {onError: doneSignal[_completeError].bind(doneSignal)});
          } else {
            doneSignal[_complete](null);
          }
        }, {runGuarded: true});
        dart.dcall(nextIteration, true);
        return doneSignal;
      }
    }
    dart.defineNamedConstructor(Future, 'microtask');
    dart.defineNamedConstructor(Future, 'sync');
    dart.defineNamedConstructor(Future, 'value');
    dart.defineNamedConstructor(Future, 'error');
    dart.defineNamedConstructor(Future, 'delayed');
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
      if (duration === void 0)
        duration = null;
      this.message = message;
      this.duration = duration;
    }
    toString() {
      let result = "TimeoutException";
      if (this.duration != null)
        result = `TimeoutException after ${this.duration}`;
      if (this.message != null)
        result = `${result}: ${this.message}`;
      return result;
    }
  }
  TimeoutException[dart.implements] = () => [core.Exception];
  let Completer$ = dart.generic(function(T) {
    class Completer extends core.Object {
      Completer() {
        return new (_AsyncCompleter$(T))();
      }
      sync() {
        return new (_SyncCompleter$(T))();
      }
    }
    dart.defineNamedConstructor(Completer, 'sync');
    return Completer;
  });
  let Completer = Completer$();
  // Function _completeWithErrorCallback: (_Future<dynamic>, dynamic, dynamic) → void
  function _completeWithErrorCallback(result, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, dart.as(stackTrace, core.StackTrace));
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    result[_completeError](error, dart.as(stackTrace, core.StackTrace));
  }
  // Function _nonNullError: (Object) → Object
  function _nonNullError(error) {
    return error != null ? error : new core.NullThrownError();
  }
  let __CastType4 = dart.typedef('__CastType4', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  let _FutureOnValue$ = dart.generic(function(T) {
    let _FutureOnValue = dart.typedef('_FutureOnValue', () => dart.functionType(dart.dynamic, [T]));
    return _FutureOnValue;
  });
  let _FutureOnValue = _FutureOnValue$();
  let _FutureErrorTest = dart.typedef('_FutureErrorTest', () => dart.functionType(core.bool, [dart.dynamic]));
  let _FutureAction = dart.typedef('_FutureAction', () => dart.functionType(dart.dynamic, []));
  let _Completer$ = dart.generic(function(T) {
    class _Completer extends core.Object {
      _Completer() {
        this.future = new (_Future$(T))();
      }
      completeError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(this.future[_mayComplete]))
          throw new core.StateError("Future already completed");
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
    return _Completer;
  });
  let _Completer = _Completer$();
  let _asyncCompleteError = Symbol('_asyncCompleteError');
  let _AsyncCompleter$ = dart.generic(function(T) {
    class _AsyncCompleter extends _Completer$(T) {
      _AsyncCompleter() {
        super._Completer();
      }
      complete(value) {
        if (value === void 0)
          value = null;
        if (!dart.notNull(this.future[_mayComplete]))
          throw new core.StateError("Future already completed");
        this.future[_asyncComplete](value);
      }
      [_completeError](error, stackTrace) {
        this.future[_asyncCompleteError](error, stackTrace);
      }
    }
    return _AsyncCompleter;
  });
  let _AsyncCompleter = _AsyncCompleter$();
  let _SyncCompleter$ = dart.generic(function(T) {
    class _SyncCompleter extends _Completer$(T) {
      _SyncCompleter() {
        super._Completer();
      }
      complete(value) {
        if (value === void 0)
          value = null;
        if (!dart.notNull(this.future[_mayComplete]))
          throw new core.StateError("Future already completed");
        this.future[_complete](value);
      }
      [_completeError](error, stackTrace) {
        this.future[_completeError](error, stackTrace);
      }
    }
    return _SyncCompleter;
  });
  let _SyncCompleter = _SyncCompleter$();
  let _nextListener = Symbol('_nextListener');
  let _onValue = Symbol('_onValue');
  let _errorTest = Symbol('_errorTest');
  let _whenCompleteAction = Symbol('_whenCompleteAction');
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
  _FutureListener.MASK_VALUE = 1;
  _FutureListener.MASK_ERROR = 2;
  _FutureListener.MASK_TEST_ERROR = 4;
  _FutureListener.MASK_WHENCOMPLETE = 8;
  _FutureListener.STATE_CHAIN = 0;
  _FutureListener.STATE_THEN = _FutureListener.MASK_VALUE;
  _FutureListener.STATE_THEN_ONERROR = dart.notNull(_FutureListener.MASK_VALUE) | dart.notNull(_FutureListener.MASK_ERROR);
  _FutureListener.STATE_CATCHERROR = _FutureListener.MASK_ERROR;
  _FutureListener.STATE_CATCHERROR_TEST = dart.notNull(_FutureListener.MASK_ERROR) | dart.notNull(_FutureListener.MASK_TEST_ERROR);
  _FutureListener.STATE_WHENCOMPLETE = _FutureListener.MASK_WHENCOMPLETE;
  let _resultOrListeners = Symbol('_resultOrListeners');
  let _isChained = Symbol('_isChained');
  let _isComplete = Symbol('_isComplete');
  let _hasValue = Symbol('_hasValue');
  let _hasError = Symbol('_hasError');
  let _markPendingCompletion = Symbol('_markPendingCompletion');
  let _value = Symbol('_value');
  let _error = Symbol('_error');
  let _setValue = Symbol('_setValue');
  let _setErrorObject = Symbol('_setErrorObject');
  let _setError = Symbol('_setError');
  let _removeListeners = Symbol('_removeListeners');
  let _Future$ = dart.generic(function(T) {
    class _Future extends core.Object {
      _Future() {
        this[_zone] = Zone.current;
        this[_state] = _Future._INCOMPLETE;
        this[_resultOrListeners] = null;
      }
      immediate(value) {
        this[_zone] = Zone.current;
        this[_state] = _Future._INCOMPLETE;
        this[_resultOrListeners] = null;
        this[_asyncComplete](value);
      }
      immediateError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        this[_zone] = Zone.current;
        this[_state] = _Future._INCOMPLETE;
        this[_resultOrListeners] = null;
        this[_asyncCompleteError](error, stackTrace);
      }
      get [_mayComplete]() {
        return this[_state] == _Future._INCOMPLETE;
      }
      get [_isChained]() {
        return this[_state] == _Future._CHAINED;
      }
      get [_isComplete]() {
        return dart.notNull(this[_state]) >= dart.notNull(_Future._VALUE);
      }
      get [_hasValue]() {
        return this[_state] == _Future._VALUE;
      }
      get [_hasError]() {
        return this[_state] == _Future._ERROR;
      }
      set [_isChained](value) {
        if (value) {
          dart.assert(!dart.notNull(this[_isComplete]));
          this[_state] = _Future._CHAINED;
        } else {
          dart.assert(this[_isChained]);
          this[_state] = _Future._INCOMPLETE;
        }
      }
      then(f, opts) {
        dart.as(f, dart.functionType(dart.dynamic, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let result = new _Future();
        if (!dart.notNull(core.identical(result[_zone], _ROOT_ZONE))) {
          f = dart.as(result[_zone].registerUnaryCallback(f), __CastType6);
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
        let result = new _Future();
        if (!dart.notNull(core.identical(result[_zone], _ROOT_ZONE))) {
          onError = _registerErrorHandler(onError, result[_zone]);
          if (test != null)
            test = dart.as(result[_zone].registerUnaryCallback(test), __CastType8);
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
        return new (Stream$(T)).fromFuture(this);
      }
      [_markPendingCompletion]() {
        if (!dart.notNull(this[_mayComplete]))
          throw new core.StateError("Future already completed");
        this[_state] = _Future._PENDING_COMPLETE;
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
        this[_state] = _Future._VALUE;
        this[_resultOrListeners] = value;
      }
      [_setErrorObject](error) {
        dart.assert(!dart.notNull(this[_isComplete]));
        this[_state] = _Future._ERROR;
        this[_resultOrListeners] = error;
      }
      [_setError](error, stackTrace) {
        this[_setErrorObject](new AsyncError(error, stackTrace));
      }
      [_addListener](listener) {
        dart.assert(listener[_nextListener] == null);
        if (this[_isComplete]) {
          this[_zone].scheduleMicrotask((() => {
            _Future._propagateToListeners(this, listener);
          }).bind(this));
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
        dart.assert(!dart.is(source, _Future));
        target[_isChained] = true;
        source.then(value => {
          dart.assert(target[_isChained]);
          target[_completeWithValue](value);
        }, {
          onError: (error, stackTrace) => {
            if (stackTrace === void 0)
              stackTrace = null;
            dart.assert(target[_isChained]);
            target[_completeError](error, dart.as(stackTrace, core.StackTrace));
          }
        });
      }
      static _chainCoreFuture(source, target) {
        dart.assert(!dart.notNull(target[_isComplete]));
        dart.assert(dart.is(source, _Future));
        target[_isChained] = true;
        let listener = new _FutureListener.chain(target);
        if (source[_isComplete]) {
          _Future._propagateToListeners(source, listener);
        } else {
          source[_addListener](listener);
        }
      }
      [_complete](value) {
        dart.assert(!dart.notNull(this[_isComplete]));
        if (dart.is(value, Future)) {
          if (dart.is(value, _Future)) {
            _Future._chainCoreFuture(dart.as(value, _Future), this);
          } else {
            _Future._chainForeignFuture(dart.as(value, Future), this);
          }
        } else {
          let listeners = this[_removeListeners]();
          this[_setValue](dart.as(value, T));
          _Future._propagateToListeners(this, listeners);
        }
      }
      [_completeWithValue](value) {
        dart.assert(!dart.notNull(this[_isComplete]));
        dart.assert(!dart.is(value, Future));
        let listeners = this[_removeListeners]();
        this[_setValue](dart.as(value, T));
        _Future._propagateToListeners(this, listeners);
      }
      [_completeError](error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        dart.assert(!dart.notNull(this[_isComplete]));
        let listeners = this[_removeListeners]();
        this[_setError](error, stackTrace);
        _Future._propagateToListeners(this, listeners);
      }
      [_asyncComplete](value) {
        dart.assert(!dart.notNull(this[_isComplete]));
        if (value == null) {
        } else if (dart.is(value, Future)) {
          let typedFuture = dart.as(value, Future$(T));
          if (dart.is(typedFuture, _Future)) {
            let coreFuture = dart.as(typedFuture, _Future$(T));
            if (dart.notNull(coreFuture[_isComplete]) && dart.notNull(coreFuture[_hasError])) {
              this[_markPendingCompletion]();
              this[_zone].scheduleMicrotask((() => {
                _Future._chainCoreFuture(coreFuture, this);
              }).bind(this));
            } else {
              _Future._chainCoreFuture(coreFuture, this);
            }
          } else {
            _Future._chainForeignFuture(typedFuture, this);
          }
          return;
        } else {
          let typedValue = dart.as(value, T);
        }
        this[_markPendingCompletion]();
        this[_zone].scheduleMicrotask((() => {
          this[_completeWithValue](value);
        }).bind(this));
      }
      [_asyncCompleteError](error, stackTrace) {
        dart.assert(!dart.notNull(this[_isComplete]));
        this[_markPendingCompletion]();
        this[_zone].scheduleMicrotask((() => {
          this[_completeError](error, stackTrace);
        }).bind(this));
      }
      static _propagateToListeners(source, listeners) {
        while (true) {
          dart.assert(source[_isComplete]);
          let hasError = source[_hasError];
          if (listeners == null) {
            if (hasError) {
              let asyncError = source[_error];
              source[_zone].handleUncaughtError(asyncError.error, asyncError.stackTrace);
            }
            return;
          }
          while (listeners[_nextListener] != null) {
            let listener = listeners;
            listeners = listener[_nextListener];
            listener[_nextListener] = null;
            _Future._propagateToListeners(source, listener);
          }
          let listener = listeners;
          let listenerHasValue = true;
          let sourceValue = hasError ? null : source[_value];
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
            // Function handleValueCallback: () → bool
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
            // Function handleError: () → void
            function handleError() {
              let asyncError = source[_error];
              let matchesTest = true;
              if (listener.hasErrorTest) {
                let test = listener[_errorTest];
                try {
                  matchesTest = dart.as(zone.runUnary(test, asyncError.error), core.bool);
                } catch (e) {
                  let s = dart.stackTrace(e);
                  listenerValueOrError = core.identical(asyncError.error, e) ? asyncError : new AsyncError(e, s);
                  listenerHasValue = false;
                  return;
                }

              }
              let errorCallback = listener[_onError];
              if (dart.notNull(matchesTest) && dart.notNull(errorCallback != null)) {
                try {
                  if (dart.is(errorCallback, ZoneBinaryCallback)) {
                    listenerValueOrError = zone.runBinary(errorCallback, asyncError.error, asyncError.stackTrace);
                  } else {
                    listenerValueOrError = zone.runUnary(dart.as(errorCallback, __CastType10), asyncError.error);
                  }
                } catch (e) {
                  let s = dart.stackTrace(e);
                  listenerValueOrError = core.identical(asyncError.error, e) ? asyncError : new AsyncError(e, s);
                  listenerHasValue = false;
                  return;
                }

                listenerHasValue = true;
              } else {
                listenerValueOrError = asyncError;
                listenerHasValue = false;
              }
            }
            // Function handleWhenCompleteCallback: () → void
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
                dart.dsend(completeResult, 'then', ignored => {
                  _Future._propagateToListeners(source, new _FutureListener.chain(result));
                }, {
                  onError: (error, stackTrace) => {
                    if (stackTrace === void 0)
                      stackTrace = null;
                    if (!dart.is(completeResult, _Future)) {
                      completeResult = new _Future();
                      dart.dsend(completeResult, _setError, error, stackTrace);
                    }
                    _Future._propagateToListeners(dart.as(completeResult, _Future), new _FutureListener.chain(result));
                  }
                });
              }
            }
            if (!dart.notNull(hasError)) {
              if (listener.handlesValue) {
                listenerHasValue = handleValueCallback();
              }
            } else {
              handleError();
            }
            if (listener.handlesComplete) {
              handleWhenCompleteCallback();
            }
            if (oldZone != null)
              Zone._leave(oldZone);
            if (isPropagationAborted)
              return;
            if (dart.notNull(listenerHasValue) && !dart.notNull(core.identical(sourceValue, listenerValueOrError)) && dart.is(listenerValueOrError, Future)) {
              let chainSource = dart.as(listenerValueOrError, Future);
              let result = listener.result;
              if (dart.is(chainSource, _Future)) {
                if (chainSource[_isComplete]) {
                  result[_isChained] = true;
                  source = chainSource;
                  listeners = new _FutureListener.chain(result);
                  continue;
                } else {
                  _Future._chainCoreFuture(chainSource, result);
                }
              } else {
                _Future._chainForeignFuture(chainSource, result);
              }
              return;
            }
          }
          let result = listener.result;
          listeners = result[_removeListeners]();
          if (listenerHasValue) {
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
        if (this[_isComplete])
          return new _Future.immediate(this);
        let result = new _Future();
        let timer = null;
        if (onTimeout == null) {
          timer = new Timer(timeLimit, () => {
            result[_completeError](new TimeoutException("Future not completed", timeLimit));
          });
        } else {
          let zone = Zone.current;
          onTimeout = zone.registerCallback(onTimeout);
          timer = new Timer(timeLimit, () => {
            try {
              result[_complete](zone.run(onTimeout));
            } catch (e) {
              let s = dart.stackTrace(e);
              result[_completeError](e, s);
            }

          });
        }
        this.then(v => {
          dart.as(v, T);
          if (timer.isActive) {
            timer.cancel();
            result[_completeWithValue](v);
          }
        }, {
          onError: (e, s) => {
            if (timer.isActive) {
              timer.cancel();
              result[_completeError](e, dart.as(s, core.StackTrace));
            }
          }
        });
        return result;
      }
    }
    _Future[dart.implements] = () => [Future$(T)];
    dart.defineNamedConstructor(_Future, 'immediate');
    dart.defineNamedConstructor(_Future, 'immediateError');
    _Future._INCOMPLETE = 0;
    _Future._PENDING_COMPLETE = 1;
    _Future._CHAINED = 2;
    _Future._VALUE = 4;
    _Future._ERROR = 8;
    return _Future;
  });
  let _Future = _Future$();
  let __CastType6$ = dart.generic(function(T) {
    let __CastType6 = dart.typedef('__CastType6', () => dart.functionType(dart.dynamic, [T]));
    return __CastType6;
  });
  let __CastType6 = __CastType6$();
  let __CastType8 = dart.typedef('__CastType8', () => dart.functionType(core.bool, [dart.dynamic]));
  let __CastType10 = dart.typedef('__CastType10', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  let _AsyncCallback = dart.typedef('_AsyncCallback', () => dart.functionType(dart.void, []));
  class _AsyncCallbackEntry extends core.Object {
    _AsyncCallbackEntry(callback) {
      this.callback = callback;
      this.next = null;
    }
  }
  exports._nextCallback = null;
  exports._lastCallback = null;
  exports._lastPriorityCallback = null;
  exports._isInCallbackLoop = false;
  // Function _asyncRunCallbackLoop: () → void
  function _asyncRunCallbackLoop() {
    while (exports._nextCallback != null) {
      exports._lastPriorityCallback = null;
      let entry = exports._nextCallback;
      exports._nextCallback = entry.next;
      if (exports._nextCallback == null)
        exports._lastCallback = null;
      entry.callback();
    }
  }
  // Function _asyncRunCallback: () → void
  function _asyncRunCallback() {
    exports._isInCallbackLoop = true;
    try {
      _asyncRunCallbackLoop();
    } finally {
      exports._lastPriorityCallback = null;
      exports._isInCallbackLoop = false;
      if (exports._nextCallback != null)
        _AsyncRun._scheduleImmediate(_asyncRunCallback);
    }
  }
  // Function _scheduleAsyncCallback: (dynamic) → void
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
  // Function _schedulePriorityAsyncCallback: (dynamic) → void
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
  // Function scheduleMicrotask: (() → void) → void
  function scheduleMicrotask(callback) {
    if (core.identical(_ROOT_ZONE, Zone.current)) {
      _rootScheduleMicrotask(null, null, _ROOT_ZONE, callback);
      return;
    }
    Zone.current.scheduleMicrotask(Zone.current.bindCallback(callback, {runGuarded: true}));
  }
  class _AsyncRun extends core.Object {
    static _scheduleImmediate(callback) {
      dart.dcall(_AsyncRun.scheduleImmediateClosure, callback);
    }
    static _initializeScheduleImmediate() {
      _js_helper.requiresPreamble();
      if (self.scheduleImmediate != null) {
        return _AsyncRun._scheduleImmediateJsOverride;
      }
      if (dart.notNull(self.MutationObserver != null) && dart.notNull(self.document != null)) {
        let div = self.document.createElement("div");
        let span = self.document.createElement("span");
        let storedCallback = null;
        // Function internalCallback: (dynamic) → dynamic
        function internalCallback(_) {
          _isolate_helper.leaveJsAsync();
          let f = storedCallback;
          storedCallback = null;
          dart.dcall(f);
        }
        ;
        let observer = new self.MutationObserver(_js_helper.convertDartClosureToJS(internalCallback, 1));
        observer.observe(div, {childList: true});
        return callback => {
          dart.assert(storedCallback == null);
          _isolate_helper.enterJsAsync();
          storedCallback = callback;
          div.firstChild ? div.removeChild(span) : div.appendChild(span);
        };
      } else if (self.setImmediate != null) {
        return _AsyncRun._scheduleImmediateWithSetImmediate;
      }
      return _AsyncRun._scheduleImmediateWithTimer;
    }
    static _scheduleImmediateJsOverride(callback) {
      // Function internalCallback: () → dynamic
      function internalCallback() {
        _isolate_helper.leaveJsAsync();
        callback();
      }
      ;
      _isolate_helper.enterJsAsync();
      self.scheduleImmediate(_js_helper.convertDartClosureToJS(internalCallback, 0));
    }
    static _scheduleImmediateWithSetImmediate(callback) {
      // Function internalCallback: () → dynamic
      function internalCallback() {
        _isolate_helper.leaveJsAsync();
        callback();
      }
      ;
      _isolate_helper.enterJsAsync();
      self.setImmediate(_js_helper.convertDartClosureToJS(internalCallback, 0));
    }
    static _scheduleImmediateWithTimer(callback) {
      Timer._createTimer(core.Duration.ZERO, callback);
    }
  }
  dart.defineLazyProperties(_AsyncRun, {
    get scheduleImmediateClosure() {
      return _AsyncRun._initializeScheduleImmediate();
    }
  });
  let StreamSubscription$ = dart.generic(function(T) {
    class StreamSubscription extends core.Object {}
    return StreamSubscription;
  });
  let StreamSubscription = StreamSubscription$();
  let EventSink$ = dart.generic(function(T) {
    class EventSink extends core.Object {}
    EventSink[dart.implements] = () => [core.Sink$(T)];
    return EventSink;
  });
  let EventSink = EventSink$();
  let _stream = Symbol('_stream');
  let StreamView$ = dart.generic(function(T) {
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
    return StreamView;
  });
  let StreamView = StreamView$();
  let StreamConsumer$ = dart.generic(function(S) {
    class StreamConsumer extends core.Object {}
    return StreamConsumer;
  });
  let StreamConsumer = StreamConsumer$();
  let StreamSink$ = dart.generic(function(S) {
    class StreamSink extends core.Object {}
    StreamSink[dart.implements] = () => [StreamConsumer$(S), EventSink$(S)];
    return StreamSink;
  });
  let StreamSink = StreamSink$();
  let StreamTransformer$ = dart.generic(function(S, T) {
    class StreamTransformer extends core.Object {
      StreamTransformer(transformer) {
        return new _StreamSubscriptionTransformer(transformer);
      }
      fromHandlers(opts) {
        return new _StreamHandlerTransformer(opts);
      }
    }
    dart.defineNamedConstructor(StreamTransformer, 'fromHandlers');
    return StreamTransformer;
  });
  let StreamTransformer = StreamTransformer$();
  let StreamIterator$ = dart.generic(function(T) {
    class StreamIterator extends core.Object {
      StreamIterator(stream) {
        return new (_StreamIteratorImpl$(T))(stream);
      }
    }
    return StreamIterator;
  });
  let StreamIterator = StreamIterator$();
  let _ControllerEventSinkWrapper$ = dart.generic(function(T) {
    class _ControllerEventSinkWrapper extends core.Object {
      _ControllerEventSinkWrapper(sink) {
        this[_sink] = sink;
      }
      add(data) {
        dart.as(data, T);
        this[_sink].add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        this[_sink].addError(error, stackTrace);
      }
      close() {
        this[_sink].close();
      }
    }
    _ControllerEventSinkWrapper[dart.implements] = () => [EventSink$(T)];
    return _ControllerEventSinkWrapper;
  });
  let _ControllerEventSinkWrapper = _ControllerEventSinkWrapper$();
  let __CastType12 = dart.typedef('__CastType12', () => dart.functionType(dart.void, [StreamSubscription]));
  let __CastType14 = dart.typedef('__CastType14', () => dart.functionType(dart.dynamic, [dart.dynamic, core.StackTrace]));
  let __CastType17 = dart.typedef('__CastType17', () => dart.functionType(dart.void, []));
  let __CastType18 = dart.typedef('__CastType18', () => dart.functionType(dart.void, [EventSink]));
  let StreamController$ = dart.generic(function(T) {
    class StreamController extends core.Object {
      StreamController(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        let onPause = opts && 'onPause' in opts ? opts.onPause : null;
        let onResume = opts && 'onResume' in opts ? opts.onResume : null;
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        let sync = opts && 'sync' in opts ? opts.sync : false;
        if (dart.notNull(onListen == null) && dart.notNull(onPause == null) && dart.notNull(onResume == null) && dart.notNull(onCancel == null)) {
          return dart.as(sync ? new _NoCallbackSyncStreamController() : new _NoCallbackAsyncStreamController(), StreamController$(T));
        }
        return sync ? new (_SyncStreamController$(T))(onListen, onPause, onResume, onCancel) : new (_AsyncStreamController$(T))(onListen, onPause, onResume, onCancel);
      }
      broadcast(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        let sync = opts && 'sync' in opts ? opts.sync : false;
        return sync ? new (_SyncBroadcastStreamController$(T))(onListen, onCancel) : new (_AsyncBroadcastStreamController$(T))(onListen, onCancel);
      }
    }
    StreamController[dart.implements] = () => [StreamSink$(T)];
    dart.defineNamedConstructor(StreamController, 'broadcast');
    return StreamController;
  });
  let StreamController = StreamController$();
  let _StreamControllerLifecycle$ = dart.generic(function(T) {
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
    return _StreamControllerLifecycle;
  });
  let _StreamControllerLifecycle = _StreamControllerLifecycle$();
  let _varData = Symbol('_varData');
  let _isInitialState = Symbol('_isInitialState');
  let _subscription = Symbol('_subscription');
  let _pendingEvents = Symbol('_pendingEvents');
  let _ensurePendingEvents = Symbol('_ensurePendingEvents');
  let _badEventState = Symbol('_badEventState');
  let _StreamController$ = dart.generic(function(T) {
    class _StreamController extends core.Object {
      _StreamController() {
        this[_varData] = null;
        this[_state] = _StreamController._STATE_INITIAL;
        this[_doneFuture] = null;
      }
      get stream() {
        return new (_ControllerStream$(T))(this);
      }
      get sink() {
        return new (_StreamSinkWrapper$(T))(this);
      }
      get [_isCanceled]() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController._STATE_CANCELED)) != 0;
      }
      get hasListener() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController._STATE_SUBSCRIBED)) != 0;
      }
      get [_isInitialState]() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController._STATE_SUBSCRIPTION_MASK)) == _StreamController._STATE_INITIAL;
      }
      get isClosed() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController._STATE_CLOSED)) != 0;
      }
      get isPaused() {
        return this.hasListener ? this[_subscription][_isInputPaused] : !dart.notNull(this[_isCanceled]);
      }
      get [_isAddingStream]() {
        return (dart.notNull(this[_state]) & dart.notNull(_StreamController._STATE_ADDSTREAM)) != 0;
      }
      get [_mayAddEvent]() {
        return dart.notNull(this[_state]) < dart.notNull(_StreamController._STATE_CLOSED);
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
          if (this[_varData] == null)
            this[_varData] = new _StreamImplEvents();
          return dart.as(this[_varData], _StreamImplEvents);
        }
        let state = dart.as(this[_varData], _StreamControllerAddStreamState);
        if (state.varData == null)
          state.varData = new _StreamImplEvents();
        return dart.as(state.varData, _StreamImplEvents);
      }
      get [_subscription]() {
        dart.assert(this.hasListener);
        if (this[_isAddingStream]) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          return dart.as(addState.varData, _ControllerSubscription);
        }
        return dart.as(this[_varData], _ControllerSubscription);
      }
      [_badEventState]() {
        if (this.isClosed) {
          return new core.StateError("Cannot add event after closing");
        }
        dart.assert(this[_isAddingStream]);
        return new core.StateError("Cannot add event while adding a stream");
      }
      addStream(source, opts) {
        dart.as(source, Stream$(T));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : true;
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_badEventState]();
        if (this[_isCanceled])
          return new _Future.immediate(null);
        let addState = new _StreamControllerAddStreamState(this, this[_varData], source, cancelOnError);
        this[_varData] = addState;
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_StreamController._STATE_ADDSTREAM);
        return addState.addStreamFuture;
      }
      get done() {
        return this[_ensureDoneFuture]();
      }
      [_ensureDoneFuture]() {
        if (this[_doneFuture] == null) {
          this[_doneFuture] = this[_isCanceled] ? Future._nullFuture : new _Future();
        }
        return this[_doneFuture];
      }
      add(value) {
        dart.as(value, T);
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_badEventState]();
        this[_add](value);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        error = _nonNullError(error);
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_badEventState]();
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement != null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this[_addError](error, stackTrace);
      }
      close() {
        if (this.isClosed) {
          return this[_ensureDoneFuture]();
        }
        if (!dart.notNull(this[_mayAddEvent]))
          throw this[_badEventState]();
        this[_closeUnchecked]();
        return this[_ensureDoneFuture]();
      }
      [_closeUnchecked]() {
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_StreamController._STATE_CLOSED);
        if (this.hasListener) {
          this[_sendDone]();
        } else if (this[_isInitialState]) {
          this[_ensurePendingEvents]().add(dart.const(new _DelayedDone()));
        }
      }
      [_add](value) {
        dart.as(value, T);
        if (this.hasListener) {
          this[_sendData](value);
        } else if (this[_isInitialState]) {
          this[_ensurePendingEvents]().add(new (_DelayedData$(T))(value));
        }
      }
      [_addError](error, stackTrace) {
        if (this.hasListener) {
          this[_sendError](error, stackTrace);
        } else if (this[_isInitialState]) {
          this[_ensurePendingEvents]().add(new _DelayedError(error, stackTrace));
        }
      }
      [_close]() {
        dart.assert(this[_isAddingStream]);
        let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
        this[_varData] = addState.varData;
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_StreamController._STATE_ADDSTREAM);
        addState.complete();
      }
      [_subscribe](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        if (!dart.notNull(this[_isInitialState])) {
          throw new core.StateError("Stream has already been listened to.");
        }
        let subscription = new _ControllerSubscription(this, onData, onError, onDone, cancelOnError);
        let pendingEvents = this[_pendingEvents];
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_StreamController._STATE_SUBSCRIBED);
        if (this[_isAddingStream]) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          addState.varData = subscription;
          addState.resume();
        } else {
          this[_varData] = subscription;
        }
        subscription[_setPendingEvents](pendingEvents);
        subscription[_guardCallback]((() => {
          _runGuarded(this[_onListen]);
        }).bind(this));
        return dart.as(subscription, StreamSubscription$(T));
      }
      [_recordCancel](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        let result = null;
        if (this[_isAddingStream]) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          result = addState.cancel();
        }
        this[_varData] = null;
        this[_state] = dart.notNull(this[_state]) & ~(dart.notNull(_StreamController._STATE_SUBSCRIBED) | dart.notNull(_StreamController._STATE_ADDSTREAM)) | dart.notNull(_StreamController._STATE_CANCELED);
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
        // Function complete: () → void
        function complete() {
          if (dart.notNull(this[_doneFuture] != null) && dart.notNull(this[_doneFuture][_mayComplete])) {
            this[_doneFuture][_asyncComplete](null);
          }
        }
        if (result != null) {
          result = result.whenComplete(complete);
        } else {
          complete();
        }
        return result;
      }
      [_recordPause](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        if (this[_isAddingStream]) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          addState.pause();
        }
        _runGuarded(this[_onPause]);
      }
      [_recordResume](subscription) {
        dart.as(subscription, StreamSubscription$(T));
        if (this[_isAddingStream]) {
          let addState = dart.as(this[_varData], _StreamControllerAddStreamState);
          addState.resume();
        }
        _runGuarded(this[_onResume]);
      }
    }
    _StreamController[dart.implements] = () => [StreamController$(T), _StreamControllerLifecycle$(T), _EventSink$(T), _EventDispatch$(T)];
    _StreamController._STATE_INITIAL = 0;
    _StreamController._STATE_SUBSCRIBED = 1;
    _StreamController._STATE_CANCELED = 2;
    _StreamController._STATE_SUBSCRIPTION_MASK = 3;
    _StreamController._STATE_CLOSED = 4;
    _StreamController._STATE_ADDSTREAM = 8;
    return _StreamController;
  });
  let _StreamController = _StreamController$();
  let _SyncStreamControllerDispatch$ = dart.generic(function(T) {
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
    return _SyncStreamControllerDispatch;
  });
  let _SyncStreamControllerDispatch = _SyncStreamControllerDispatch$();
  let _AsyncStreamControllerDispatch$ = dart.generic(function(T) {
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
    return _AsyncStreamControllerDispatch;
  });
  let _AsyncStreamControllerDispatch = _AsyncStreamControllerDispatch$();
  let _AsyncStreamController$ = dart.generic(function(T) {
    class _AsyncStreamController extends dart.mixin(_StreamController$(T), _AsyncStreamControllerDispatch$(T)) {
      _AsyncStreamController(onListen, onPause, onResume, onCancel) {
        this[_onListen] = onListen;
        this[_onPause] = onPause;
        this[_onResume] = onResume;
        this[_onCancel] = onCancel;
        super._StreamController();
      }
    }
    return _AsyncStreamController;
  });
  let _AsyncStreamController = _AsyncStreamController$();
  let _SyncStreamController$ = dart.generic(function(T) {
    class _SyncStreamController extends dart.mixin(_StreamController$(T), _SyncStreamControllerDispatch$(T)) {
      _SyncStreamController(onListen, onPause, onResume, onCancel) {
        this[_onListen] = onListen;
        this[_onPause] = onPause;
        this[_onResume] = onResume;
        this[_onCancel] = onCancel;
        super._StreamController();
      }
    }
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
  class _NoCallbackAsyncStreamController extends dart.mixin(_StreamController, _AsyncStreamControllerDispatch, _NoCallbacks) {}
  class _NoCallbackSyncStreamController extends dart.mixin(_StreamController, _SyncStreamControllerDispatch, _NoCallbacks) {}
  let _NotificationHandler = dart.typedef('_NotificationHandler', () => dart.functionType(dart.dynamic, []));
  // Function _runGuarded: (() → dynamic) → Future<dynamic>
  function _runGuarded(notificationHandler) {
    if (notificationHandler == null)
      return null;
    try {
      let result = notificationHandler();
      if (dart.is(result, Future))
        return dart.as(result, Future);
      return null;
    } catch (e) {
      let s = dart.stackTrace(e);
      Zone.current.handleUncaughtError(e, s);
    }

  }
  let _target = Symbol('_target');
  let _StreamSinkWrapper$ = dart.generic(function(T) {
    class _StreamSinkWrapper extends core.Object {
      _StreamSinkWrapper(target) {
        this[_target] = target;
      }
      add(data) {
        dart.as(data, T);
        this[_target].add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
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
    return _StreamSinkWrapper;
  });
  let _StreamSinkWrapper = _StreamSinkWrapper$();
  let _AddStreamState$ = dart.generic(function(T) {
    class _AddStreamState extends core.Object {
      _AddStreamState(controller, source, cancelOnError) {
        this.addStreamFuture = new _Future();
        this.addSubscription = source.listen(controller[_add].bind(controller), {onError: cancelOnError ? dart.as(_AddStreamState.makeErrorHandler(controller), core.Function) : controller[_addError].bind(controller), onDone: controller[_close].bind(controller), cancelOnError: cancelOnError});
      }
      static makeErrorHandler(controller) {
        return (e, s) => {
          controller[_addError](e, s);
          controller[_close]();
        };
      }
      pause() {
        this.addSubscription.pause();
      }
      resume() {
        this.addSubscription.resume();
      }
      cancel() {
        let cancel = this.addSubscription.cancel();
        if (cancel == null) {
          this.addStreamFuture[_asyncComplete](null);
          return null;
        }
        return cancel.whenComplete((() => {
          this.addStreamFuture[_asyncComplete](null);
        }).bind(this));
      }
      complete() {
        this.addStreamFuture[_asyncComplete](null);
      }
    }
    return _AddStreamState;
  });
  let _AddStreamState = _AddStreamState$();
  let _StreamControllerAddStreamState$ = dart.generic(function(T) {
    class _StreamControllerAddStreamState extends _AddStreamState$(T) {
      _StreamControllerAddStreamState(controller, varData, source, cancelOnError) {
        this.varData = varData;
        super._AddStreamState(dart.as(controller, _EventSink$(T)), source, cancelOnError);
        if (controller.isPaused) {
          this.addSubscription.pause();
        }
      }
    }
    return _StreamControllerAddStreamState;
  });
  let _StreamControllerAddStreamState = _StreamControllerAddStreamState$();
  let _EventSink$ = dart.generic(function(T) {
    class _EventSink extends core.Object {}
    return _EventSink;
  });
  let _EventSink = _EventSink$();
  let _EventDispatch$ = dart.generic(function(T) {
    class _EventDispatch extends core.Object {}
    return _EventDispatch;
  });
  let _EventDispatch = _EventDispatch$();
  let _EventGenerator = dart.typedef('_EventGenerator', () => dart.functionType(_PendingEvents, []));
  let _isUsed = Symbol('_isUsed');
  let _GeneratedStreamImpl$ = dart.generic(function(T) {
    class _GeneratedStreamImpl extends _StreamImpl$(T) {
      _GeneratedStreamImpl(pending) {
        this[_pending] = pending;
        this[_isUsed] = false;
      }
      [_createSubscription](onData, onError, onDone, cancelOnError) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        dart.as(onDone, dart.functionType(dart.void, []));
        if (this[_isUsed])
          throw new core.StateError("Stream has already been listened to.");
        this[_isUsed] = true;
        return dart.as((() => {
          let _ = new _BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
          _[_setPendingEvents](this[_pending]());
          return _;
        }).bind(this)(), StreamSubscription$(T));
      }
    }
    return _GeneratedStreamImpl;
  });
  let _GeneratedStreamImpl = _GeneratedStreamImpl$();
  let _iterator = Symbol('_iterator');
  let _eventScheduled = Symbol('_eventScheduled');
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
      if (this.isScheduled)
        return;
      dart.assert(!dart.notNull(this.isEmpty));
      if (this[_eventScheduled]) {
        dart.assert(this[_state] == _PendingEvents._STATE_CANCELED);
        this[_state] = _PendingEvents._STATE_SCHEDULED;
        return;
      }
      scheduleMicrotask((() => {
        let oldState = this[_state];
        this[_state] = _PendingEvents._STATE_UNSCHEDULED;
        if (oldState == _PendingEvents._STATE_CANCELED)
          return;
        this.handleNext(dispatch);
      }).bind(this));
      this[_state] = _PendingEvents._STATE_SCHEDULED;
    }
    cancelSchedule() {
      if (this.isScheduled)
        this[_state] = _PendingEvents._STATE_CANCELED;
    }
  }
  _PendingEvents._STATE_UNSCHEDULED = 0;
  _PendingEvents._STATE_SCHEDULED = 1;
  _PendingEvents._STATE_CANCELED = 3;
  let _IterablePendingEvents$ = dart.generic(function(T) {
    class _IterablePendingEvents extends _PendingEvents {
      _IterablePendingEvents(data) {
        this[_iterator] = data[core.$iterator];
        super._PendingEvents();
      }
      get isEmpty() {
        return this[_iterator] == null;
      }
      handleNext(dispatch) {
        if (this[_iterator] == null) {
          throw new core.StateError("No events pending.");
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
        if (this.isScheduled)
          this.cancelSchedule();
        this[_iterator] = null;
      }
    }
    return _IterablePendingEvents;
  });
  let _IterablePendingEvents = _IterablePendingEvents$();
  let _DataHandler$ = dart.generic(function(T) {
    let _DataHandler = dart.typedef('_DataHandler', () => dart.functionType(dart.void, [T]));
    return _DataHandler;
  });
  let _DataHandler = _DataHandler$();
  let _DoneHandler = dart.typedef('_DoneHandler', () => dart.functionType(dart.void, []));
  // Function _nullDataHandler: (dynamic) → void
  function _nullDataHandler(value) {
  }
  // Function _nullErrorHandler: (dynamic, [StackTrace]) → void
  function _nullErrorHandler(error, stackTrace) {
    if (stackTrace === void 0)
      stackTrace = null;
    Zone.current.handleUncaughtError(error, stackTrace);
  }
  // Function _nullDoneHandler: () → void
  function _nullDoneHandler() {
  }
  let _DelayedEvent$ = dart.generic(function(T) {
    class _DelayedEvent extends core.Object {
      _DelayedEvent() {
        this.next = null;
      }
    }
    return _DelayedEvent;
  });
  let _DelayedEvent = _DelayedEvent$();
  let _DelayedData$ = dart.generic(function(T) {
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
      throw new core.StateError("No events after a done.");
    }
  }
  _DelayedDone[dart.implements] = () => [_DelayedEvent];
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
      if (this.isScheduled)
        this.cancelSchedule();
      this.firstPendingEvent = this.lastPendingEvent = null;
    }
  }
  let _unlink = Symbol('_unlink');
  let _insertBefore = Symbol('_insertBefore');
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
  let _broadcastCallback = dart.typedef('_broadcastCallback', () => dart.functionType(dart.void, [StreamSubscription]));
  let _schedule = Symbol('_schedule');
  let _isSent = Symbol('_isSent');
  let _isScheduled = Symbol('_isScheduled');
  let _DoneStreamSubscription$ = dart.generic(function(T) {
    class _DoneStreamSubscription extends core.Object {
      _DoneStreamSubscription(onDone) {
        this[_onDone] = onDone;
        this[_zone] = Zone.current;
        this[_state] = 0;
        this[_schedule]();
      }
      get [_isSent]() {
        return (dart.notNull(this[_state]) & dart.notNull(_DoneStreamSubscription._DONE_SENT)) != 0;
      }
      get [_isScheduled]() {
        return (dart.notNull(this[_state]) & dart.notNull(_DoneStreamSubscription._SCHEDULED)) != 0;
      }
      get isPaused() {
        return dart.notNull(this[_state]) >= dart.notNull(_DoneStreamSubscription._PAUSED);
      }
      [_schedule]() {
        if (this[_isScheduled])
          return;
        this[_zone].scheduleMicrotask(this[_sendDone].bind(this));
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_DoneStreamSubscription._SCHEDULED);
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
        if (resumeSignal === void 0)
          resumeSignal = null;
        this[_state] = dart.notNull(this[_state]) + dart.notNull(_DoneStreamSubscription._PAUSED);
        if (resumeSignal != null)
          resumeSignal.whenComplete(this.resume.bind(this));
      }
      resume() {
        if (this.isPaused) {
          this[_state] = dart.notNull(this[_state]) - dart.notNull(_DoneStreamSubscription._PAUSED);
          if (!dart.notNull(this.isPaused) && !dart.notNull(this[_isSent])) {
            this[_schedule]();
          }
        }
      }
      cancel() {
        return null;
      }
      asFuture(futureValue) {
        if (futureValue === void 0)
          futureValue = null;
        let result = new _Future();
        this[_onDone] = () => {
          result[_completeWithValue](null);
        };
        return result;
      }
      [_sendDone]() {
        this[_state] = dart.notNull(this[_state]) & ~dart.notNull(_DoneStreamSubscription._SCHEDULED);
        if (this.isPaused)
          return;
        this[_state] = dart.notNull(this[_state]) | dart.notNull(_DoneStreamSubscription._DONE_SENT);
        if (this[_onDone] != null)
          this[_zone].runGuarded(this[_onDone]);
      }
    }
    _DoneStreamSubscription[dart.implements] = () => [StreamSubscription$(T)];
    _DoneStreamSubscription._DONE_SENT = 1;
    _DoneStreamSubscription._SCHEDULED = 2;
    _DoneStreamSubscription._PAUSED = 4;
    return _DoneStreamSubscription;
  });
  let _DoneStreamSubscription = _DoneStreamSubscription$();
  let _source = Symbol('_source');
  let _onListenHandler = Symbol('_onListenHandler');
  let _onCancelHandler = Symbol('_onCancelHandler');
  let _cancelSubscription = Symbol('_cancelSubscription');
  let _pauseSubscription = Symbol('_pauseSubscription');
  let _resumeSubscription = Symbol('_resumeSubscription');
  let _isSubscriptionPaused = Symbol('_isSubscriptionPaused');
  let _AsBroadcastStream$ = dart.generic(function(T) {
    class _AsBroadcastStream extends Stream$(T) {
      _AsBroadcastStream(source, onListenHandler, onCancelHandler) {
        this[_source] = source;
        this[_onListenHandler] = dart.as(Zone.current.registerUnaryCallback(onListenHandler), _broadcastCallback);
        this[_onCancelHandler] = dart.as(Zone.current.registerUnaryCallback(onCancelHandler), _broadcastCallback);
        this[_zone] = Zone.current;
        this[_controller] = null;
        this[_subscription] = null;
        super.Stream();
        this[_controller] = new (_AsBroadcastStreamController$(T))(this[_onListen].bind(this), this[_onCancel].bind(this));
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
        if (dart.notNull(this[_controller] == null) || dart.notNull(this[_controller].isClosed)) {
          return new (_DoneStreamSubscription$(T))(onDone);
        }
        if (this[_subscription] == null) {
          this[_subscription] = this[_source].listen(dart.bind(this[_controller], 'add'), {onError: dart.bind(this[_controller], 'addError'), onDone: dart.bind(this[_controller], 'close')});
        }
        cancelOnError = core.identical(true, cancelOnError);
        return this[_controller][_subscribe](onData, onError, onDone, cancelOnError);
      }
      [_onCancel]() {
        let shutdown = dart.notNull(this[_controller] == null) || dart.notNull(this[_controller].isClosed);
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
        if (this[_subscription] == null)
          return;
        let subscription = this[_subscription];
        this[_subscription] = null;
        this[_controller] = null;
        subscription.cancel();
      }
      [_pauseSubscription](resumeSignal) {
        if (this[_subscription] == null)
          return;
        this[_subscription].pause(resumeSignal);
      }
      [_resumeSubscription]() {
        if (this[_subscription] == null)
          return;
        this[_subscription].resume();
      }
      get [_isSubscriptionPaused]() {
        if (this[_subscription] == null)
          return false;
        return this[_subscription].isPaused;
      }
    }
    return _AsBroadcastStream;
  });
  let _AsBroadcastStream = _AsBroadcastStream$();
  let _BroadcastSubscriptionWrapper$ = dart.generic(function(T) {
    class _BroadcastSubscriptionWrapper extends core.Object {
      _BroadcastSubscriptionWrapper(stream) {
        this[_stream] = stream;
      }
      onData(handleData) {
        dart.as(handleData, dart.functionType(dart.void, [T]));
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
      onError(handleError) {
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0)
          resumeSignal = null;
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
        if (futureValue === void 0)
          futureValue = null;
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
    }
    _BroadcastSubscriptionWrapper[dart.implements] = () => [StreamSubscription$(T)];
    return _BroadcastSubscriptionWrapper;
  });
  let _BroadcastSubscriptionWrapper = _BroadcastSubscriptionWrapper$();
  let _current = Symbol('_current');
  let _futureOrPrefetch = Symbol('_futureOrPrefetch');
  let _clear = Symbol('_clear');
  let _StreamIteratorImpl$ = dart.generic(function(T) {
    class _StreamIteratorImpl extends core.Object {
      _StreamIteratorImpl(stream) {
        this[_subscription] = null;
        this[_current] = null;
        this[_futureOrPrefetch] = null;
        this[_state] = _StreamIteratorImpl._STATE_FOUND;
        this[_subscription] = stream.listen(this[_onData].bind(this), {onError: this[_onError].bind(this), onDone: this[_onDone].bind(this), cancelOnError: true});
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (this[_state] == _StreamIteratorImpl._STATE_DONE) {
          return new (_Future$(core.bool)).immediate(false);
        }
        if (this[_state] == _StreamIteratorImpl._STATE_MOVING) {
          throw new core.StateError("Already waiting for next.");
        }
        if (this[_state] == _StreamIteratorImpl._STATE_FOUND) {
          this[_state] = _StreamIteratorImpl._STATE_MOVING;
          this[_current] = null;
          this[_futureOrPrefetch] = new (_Future$(core.bool))();
          return dart.as(this[_futureOrPrefetch], Future$(core.bool));
        } else {
          dart.assert(dart.notNull(this[_state]) >= dart.notNull(_StreamIteratorImpl._STATE_EXTRA_DATA));
          switch (this[_state]) {
            case _StreamIteratorImpl._STATE_EXTRA_DATA:
            {
              this[_state] = _StreamIteratorImpl._STATE_FOUND;
              this[_current] = dart.as(this[_futureOrPrefetch], T);
              this[_futureOrPrefetch] = null;
              this[_subscription].resume();
              return new (_Future$(core.bool)).immediate(true);
            }
            case _StreamIteratorImpl._STATE_EXTRA_ERROR:
            {
              let prefetch = dart.as(this[_futureOrPrefetch], AsyncError);
              this[_clear]();
              return new (_Future$(core.bool)).immediateError(prefetch.error, prefetch.stackTrace);
            }
            case _StreamIteratorImpl._STATE_EXTRA_DONE:
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
        this[_state] = _StreamIteratorImpl._STATE_DONE;
      }
      cancel() {
        let subscription = this[_subscription];
        if (this[_state] == _StreamIteratorImpl._STATE_MOVING) {
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
        if (this[_state] == _StreamIteratorImpl._STATE_MOVING) {
          this[_current] = data;
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_futureOrPrefetch] = null;
          this[_state] = _StreamIteratorImpl._STATE_FOUND;
          hasNext[_complete](true);
          return;
        }
        this[_subscription].pause();
        dart.assert(this[_futureOrPrefetch] == null);
        this[_futureOrPrefetch] = data;
        this[_state] = _StreamIteratorImpl._STATE_EXTRA_DATA;
      }
      [_onError](error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        if (this[_state] == _StreamIteratorImpl._STATE_MOVING) {
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_clear]();
          hasNext[_completeError](error, stackTrace);
          return;
        }
        this[_subscription].pause();
        dart.assert(this[_futureOrPrefetch] == null);
        this[_futureOrPrefetch] = new AsyncError(error, stackTrace);
        this[_state] = _StreamIteratorImpl._STATE_EXTRA_ERROR;
      }
      [_onDone]() {
        if (this[_state] == _StreamIteratorImpl._STATE_MOVING) {
          let hasNext = dart.as(this[_futureOrPrefetch], _Future$(core.bool));
          this[_clear]();
          hasNext[_complete](false);
          return;
        }
        this[_subscription].pause();
        this[_futureOrPrefetch] = null;
        this[_state] = _StreamIteratorImpl._STATE_EXTRA_DONE;
      }
    }
    _StreamIteratorImpl[dart.implements] = () => [StreamIterator$(T)];
    _StreamIteratorImpl._STATE_FOUND = 0;
    _StreamIteratorImpl._STATE_DONE = 1;
    _StreamIteratorImpl._STATE_MOVING = 2;
    _StreamIteratorImpl._STATE_EXTRA_DATA = 3;
    _StreamIteratorImpl._STATE_EXTRA_ERROR = 4;
    _StreamIteratorImpl._STATE_EXTRA_DONE = 5;
    return _StreamIteratorImpl;
  });
  let _StreamIteratorImpl = _StreamIteratorImpl$();
  let __CastType20$ = dart.generic(function(T) {
    let __CastType20 = dart.typedef('__CastType20', () => dart.functionType(dart.void, [T]));
    return __CastType20;
  });
  let __CastType20 = __CastType20$();
  let __CastType22 = dart.typedef('__CastType22', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  let __CastType25 = dart.typedef('__CastType25', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  // Function _runUserCode: (() → dynamic, (dynamic) → dynamic, (dynamic, StackTrace) → dynamic) → dynamic
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
  // Function _cancelAndError: (StreamSubscription<dynamic>, _Future<dynamic>, dynamic, StackTrace) → void
  function _cancelAndError(subscription, future, error, stackTrace) {
    let cancelFuture = subscription.cancel();
    if (dart.is(cancelFuture, Future)) {
      cancelFuture.whenComplete(() => future[_completeError](error, stackTrace));
    } else {
      future[_completeError](error, stackTrace);
    }
  }
  // Function _cancelAndErrorWithReplacement: (StreamSubscription<dynamic>, _Future<dynamic>, dynamic, StackTrace) → void
  function _cancelAndErrorWithReplacement(subscription, future, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _cancelAndError(subscription, future, error, stackTrace);
  }
  // Function _cancelAndErrorClosure: (StreamSubscription<dynamic>, _Future<dynamic>) → dynamic
  function _cancelAndErrorClosure(subscription, future) {
    return (error, stackTrace) => _cancelAndError(subscription, future, error, stackTrace);
  }
  // Function _cancelAndValue: (StreamSubscription<dynamic>, _Future<dynamic>, dynamic) → void
  function _cancelAndValue(subscription, future, value) {
    let cancelFuture = subscription.cancel();
    if (dart.is(cancelFuture, Future)) {
      cancelFuture.whenComplete(() => future[_complete](value));
    } else {
      future[_complete](value);
    }
  }
  let _handleData = Symbol('_handleData');
  let _handleError = Symbol('_handleError');
  let _handleDone = Symbol('_handleDone');
  let _ForwardingStream$ = dart.generic(function(S, T) {
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
    return _ForwardingStream;
  });
  let _ForwardingStream = _ForwardingStream$();
  let _ForwardingStreamSubscription$ = dart.generic(function(S, T) {
    class _ForwardingStreamSubscription extends _BufferingStreamSubscription$(T) {
      _ForwardingStreamSubscription(stream, onData, onError, onDone, cancelOnError) {
        this[_stream] = stream;
        this[_subscription] = null;
        super._BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
        this[_subscription] = this[_stream][_source].listen(this[_handleData].bind(this), {onError: this[_handleError].bind(this), onDone: this[_handleDone].bind(this)});
      }
      [_add](data) {
        dart.as(data, T);
        if (this[_isClosed])
          return;
        super[_add](data);
      }
      [_addError](error, stackTrace) {
        if (this[_isClosed])
          return;
        super[_addError](error, stackTrace);
      }
      [_onPause]() {
        if (this[_subscription] == null)
          return;
        this[_subscription].pause();
      }
      [_onResume]() {
        if (this[_subscription] == null)
          return;
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
    return _ForwardingStreamSubscription;
  });
  let _ForwardingStreamSubscription = _ForwardingStreamSubscription$();
  let _Predicate$ = dart.generic(function(T) {
    let _Predicate = dart.typedef('_Predicate', () => dart.functionType(core.bool, [T]));
    return _Predicate;
  });
  let _Predicate = _Predicate$();
  // Function _addErrorWithReplacement: (_EventSink<dynamic>, dynamic, dynamic) → void
  function _addErrorWithReplacement(sink, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, dart.as(stackTrace, core.StackTrace));
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    sink[_addError](error, dart.as(stackTrace, core.StackTrace));
  }
  let _test = Symbol('_test');
  let _WhereStream$ = dart.generic(function(T) {
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

        if (satisfies) {
          sink[_add](inputEvent);
        }
      }
    }
    return _WhereStream;
  });
  let _WhereStream = _WhereStream$();
  let _Transformation$ = dart.generic(function(S, T) {
    let _Transformation = dart.typedef('_Transformation', () => dart.functionType(T, [S]));
    return _Transformation;
  });
  let _Transformation = _Transformation$();
  let _transform = Symbol('_transform');
  let _MapStream$ = dart.generic(function(S, T) {
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
    return _MapStream;
  });
  let _MapStream = _MapStream$();
  let _expand = Symbol('_expand');
  let _ExpandStream$ = dart.generic(function(S, T) {
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
    return _ExpandStream;
  });
  let _ExpandStream = _ExpandStream$();
  let _ErrorTest = dart.typedef('_ErrorTest', () => dart.functionType(core.bool, [dart.dynamic]));
  let _HandleErrorStream$ = dart.generic(function(T) {
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
        if (matches) {
          try {
            _invokeErrorHandler(this[_transform], error, stackTrace);
          } catch (e) {
            let s = dart.stackTrace(e);
            if (core.identical(e, error)) {
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
    return _HandleErrorStream;
  });
  let _HandleErrorStream = _HandleErrorStream$();
  let _remaining = Symbol('_remaining');
  let _TakeStream$ = dart.generic(function(T) {
    class _TakeStream extends _ForwardingStream$(T, T) {
      _TakeStream(source, count) {
        this[_remaining] = count;
        super._ForwardingStream(source);
        if (!(typeof count == 'number'))
          throw new core.ArgumentError(count);
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
    return _TakeStream;
  });
  let _TakeStream = _TakeStream$();
  let _TakeWhileStream$ = dart.generic(function(T) {
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

        if (satisfies) {
          sink[_add](inputEvent);
        } else {
          sink[_close]();
        }
      }
    }
    return _TakeWhileStream;
  });
  let _TakeWhileStream = _TakeWhileStream$();
  let _SkipStream$ = dart.generic(function(T) {
    class _SkipStream extends _ForwardingStream$(T, T) {
      _SkipStream(source, count) {
        this[_remaining] = count;
        super._ForwardingStream(source);
        if (!(typeof count == 'number') || dart.notNull(count) < 0)
          throw new core.ArgumentError(count);
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
    return _SkipStream;
  });
  let _SkipStream = _SkipStream$();
  let _hasFailed = Symbol('_hasFailed');
  let _SkipWhileStream$ = dart.generic(function(T) {
    class _SkipWhileStream extends _ForwardingStream$(T, T) {
      _SkipWhileStream(source, test) {
        this[_test] = test;
        this[_hasFailed] = false;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        if (this[_hasFailed]) {
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
    return _SkipWhileStream;
  });
  let _SkipWhileStream = _SkipWhileStream$();
  let _Equality$ = dart.generic(function(T) {
    let _Equality = dart.typedef('_Equality', () => dart.functionType(core.bool, [T, T]));
    return _Equality;
  });
  let _Equality = _Equality$();
  let _equals = Symbol('_equals');
  let _DistinctStream$ = dart.generic(function(T) {
    class _DistinctStream extends _ForwardingStream$(T, T) {
      _DistinctStream(source, equals) {
        this[_previous] = _DistinctStream._SENTINEL;
        this[_equals] = equals;
        super._ForwardingStream(source);
      }
      [_handleData](inputEvent, sink) {
        dart.as(inputEvent, T);
        dart.as(sink, _EventSink$(T));
        if (core.identical(this[_previous], _DistinctStream._SENTINEL)) {
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
    dart.defineLazyProperties(_DistinctStream, {
      get _SENTINEL() {
        return new core.Object();
      },
      set _SENTINEL(_) {}
    });
    return _DistinctStream;
  });
  let _DistinctStream = _DistinctStream$();
  let _EventSinkWrapper$ = dart.generic(function(T) {
    class _EventSinkWrapper extends core.Object {
      _EventSinkWrapper(sink) {
        this[_sink] = sink;
      }
      add(data) {
        dart.as(data, T);
        this[_sink][_add](data);
      }
      addError(error, stackTrace) {
        if (stackTrace === void 0)
          stackTrace = null;
        this[_sink][_addError](error, stackTrace);
      }
      close() {
        this[_sink][_close]();
      }
    }
    _EventSinkWrapper[dart.implements] = () => [EventSink$(T)];
    return _EventSinkWrapper;
  });
  let _EventSinkWrapper = _EventSinkWrapper$();
  let _transformerSink = Symbol('_transformerSink');
  let _isSubscribed = Symbol('_isSubscribed');
  let _SinkTransformerStreamSubscription$ = dart.generic(function(S, T) {
    class _SinkTransformerStreamSubscription extends _BufferingStreamSubscription$(T) {
      _SinkTransformerStreamSubscription(source, mapper, onData, onError, onDone, cancelOnError) {
        this[_transformerSink] = null;
        this[_subscription] = null;
        super._BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
        let eventSink = new (_EventSinkWrapper$(T))(this);
        this[_transformerSink] = mapper(eventSink);
        this[_subscription] = source.listen(this[_handleData].bind(this), {onError: this[_handleError].bind(this), onDone: this[_handleDone].bind(this)});
      }
      get [_isSubscribed]() {
        return this[_subscription] != null;
      }
      [_add](data) {
        dart.as(data, T);
        if (this[_isClosed]) {
          throw new core.StateError("Stream is already closed");
        }
        super[_add](data);
      }
      [_addError](error, stackTrace) {
        if (this[_isClosed]) {
          throw new core.StateError("Stream is already closed");
        }
        super[_addError](error, stackTrace);
      }
      [_close]() {
        if (this[_isClosed]) {
          throw new core.StateError("Stream is already closed");
        }
        super[_close]();
      }
      [_onPause]() {
        if (this[_isSubscribed])
          this[_subscription].pause();
      }
      [_onResume]() {
        if (this[_isSubscribed])
          this[_subscription].resume();
      }
      [_onCancel]() {
        if (this[_isSubscribed]) {
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
        if (stackTrace === void 0)
          stackTrace = null;
        try {
          this[_transformerSink].addError(error, dart.as(stackTrace, core.StackTrace));
        } catch (e) {
          let s = dart.stackTrace(e);
          if (core.identical(e, error)) {
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
    return _SinkTransformerStreamSubscription;
  });
  let _SinkTransformerStreamSubscription = _SinkTransformerStreamSubscription$();
  let _SinkMapper$ = dart.generic(function(S, T) {
    let _SinkMapper = dart.typedef('_SinkMapper', () => dart.functionType(EventSink$(S), [EventSink$(T)]));
    return _SinkMapper;
  });
  let _SinkMapper = _SinkMapper$();
  let _sinkMapper = Symbol('_sinkMapper');
  let _StreamSinkTransformer$ = dart.generic(function(S, T) {
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
    return _StreamSinkTransformer;
  });
  let _StreamSinkTransformer = _StreamSinkTransformer$();
  let _BoundSinkStream$ = dart.generic(function(S, T) {
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
        let subscription = new (_SinkTransformerStreamSubscription$(dart.dynamic, T))(this[_stream], dart.as(this[_sinkMapper], _SinkMapper), onData, onError, onDone, cancelOnError);
        return subscription;
      }
    }
    return _BoundSinkStream;
  });
  let _BoundSinkStream = _BoundSinkStream$();
  let _TransformDataHandler$ = dart.generic(function(S, T) {
    let _TransformDataHandler = dart.typedef('_TransformDataHandler', () => dart.functionType(dart.void, [S, EventSink$(T)]));
    return _TransformDataHandler;
  });
  let _TransformDataHandler = _TransformDataHandler$();
  let _TransformErrorHandler$ = dart.generic(function(T) {
    let _TransformErrorHandler = dart.typedef('_TransformErrorHandler', () => dart.functionType(dart.void, [core.Object, core.StackTrace, EventSink$(T)]));
    return _TransformErrorHandler;
  });
  let _TransformErrorHandler = _TransformErrorHandler$();
  let _TransformDoneHandler$ = dart.generic(function(T) {
    let _TransformDoneHandler = dart.typedef('_TransformDoneHandler', () => dart.functionType(dart.void, [EventSink$(T)]));
    return _TransformDoneHandler;
  });
  let _TransformDoneHandler = _TransformDoneHandler$();
  let _HandlerEventSink$ = dart.generic(function(S, T) {
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
        if (stackTrace === void 0)
          stackTrace = null;
        return this[_handleError](error, stackTrace, this[_sink]);
      }
      close() {
        return this[_handleDone](this[_sink]);
      }
    }
    _HandlerEventSink[dart.implements] = () => [EventSink$(S)];
    return _HandlerEventSink;
  });
  let _HandlerEventSink = _HandlerEventSink$();
  let _StreamHandlerTransformer$ = dart.generic(function(S, T) {
    class _StreamHandlerTransformer extends _StreamSinkTransformer$(S, T) {
      _StreamHandlerTransformer(opts) {
        let handleData = opts && 'handleData' in opts ? opts.handleData : null;
        let handleError = opts && 'handleError' in opts ? opts.handleError : null;
        let handleDone = opts && 'handleDone' in opts ? opts.handleDone : null;
        super._StreamSinkTransformer(dart.as(outputSink => {
          dart.as(outputSink, EventSink$(T));
          if (handleData == null)
            handleData = dart.as(_StreamHandlerTransformer._defaultHandleData, __CastType27);
          if (handleError == null)
            handleError = dart.as(_StreamHandlerTransformer._defaultHandleError, __CastType30);
          if (handleDone == null)
            handleDone = _StreamHandlerTransformer._defaultHandleDone;
          return new (_HandlerEventSink$(S, T))(handleData, handleError, handleDone, outputSink);
        }, _SinkMapper$(S, T)));
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
    return _StreamHandlerTransformer;
  });
  let _StreamHandlerTransformer = _StreamHandlerTransformer$();
  let _SubscriptionTransformer$ = dart.generic(function(S, T) {
    let _SubscriptionTransformer = dart.typedef('_SubscriptionTransformer', () => dart.functionType(StreamSubscription$(T), [Stream$(S), core.bool]));
    return _SubscriptionTransformer;
  });
  let _SubscriptionTransformer = _SubscriptionTransformer$();
  let _transformer = Symbol('_transformer');
  let _StreamSubscriptionTransformer$ = dart.generic(function(S, T) {
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
    return _StreamSubscriptionTransformer;
  });
  let _StreamSubscriptionTransformer = _StreamSubscriptionTransformer$();
  let _BoundSubscriptionStream$ = dart.generic(function(S, T) {
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
    return _BoundSubscriptionStream;
  });
  let _BoundSubscriptionStream = _BoundSubscriptionStream$();
  let __CastType27$ = dart.generic(function(S, T) {
    let __CastType27 = dart.typedef('__CastType27', () => dart.functionType(dart.void, [S, EventSink$(T)]));
    return __CastType27;
  });
  let __CastType27 = __CastType27$();
  let __CastType30$ = dart.generic(function(T) {
    let __CastType30 = dart.typedef('__CastType30', () => dart.functionType(dart.void, [core.Object, core.StackTrace, EventSink$(T)]));
    return __CastType30;
  });
  let __CastType30 = __CastType30$();
  class Timer extends core.Object {
    Timer(duration, callback) {
      if (dart.equals(Zone.current, Zone.ROOT)) {
        return Zone.current.createTimer(duration, callback);
      }
      return Zone.current.createTimer(duration, Zone.current.bindCallback(callback, {runGuarded: true}));
    }
    periodic(duration, callback) {
      if (dart.equals(Zone.current, Zone.ROOT)) {
        return Zone.current.createPeriodicTimer(duration, callback);
      }
      return Zone.current.createPeriodicTimer(duration, dart.as(Zone.current.bindUnaryCallback(callback, {runGuarded: true}), __CastType34));
    }
    static run(callback) {
      new Timer(core.Duration.ZERO, callback);
    }
    static _createTimer(duration, callback) {
      let milliseconds = duration.inMilliseconds;
      if (dart.notNull(milliseconds) < 0)
        milliseconds = 0;
      return new _isolate_helper.TimerImpl(milliseconds, callback);
    }
    static _createPeriodicTimer(duration, callback) {
      let milliseconds = duration.inMilliseconds;
      if (dart.notNull(milliseconds) < 0)
        milliseconds = 0;
      return new _isolate_helper.TimerImpl.periodic(milliseconds, callback);
    }
  }
  dart.defineNamedConstructor(Timer, 'periodic');
  let __CastType34 = dart.typedef('__CastType34', () => dart.functionType(dart.void, [Timer]));
  let ZoneCallback = dart.typedef('ZoneCallback', () => dart.functionType(dart.dynamic, []));
  let ZoneUnaryCallback = dart.typedef('ZoneUnaryCallback', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  let ZoneBinaryCallback = dart.typedef('ZoneBinaryCallback', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  let HandleUncaughtErrorHandler = dart.typedef('HandleUncaughtErrorHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.dynamic, core.StackTrace]));
  let RunHandler = dart.typedef('RunHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  let RunUnaryHandler = dart.typedef('RunUnaryHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic]), dart.dynamic]));
  let RunBinaryHandler = dart.typedef('RunBinaryHandler', () => dart.functionType(dart.dynamic, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]), dart.dynamic, dart.dynamic]));
  let RegisterCallbackHandler = dart.typedef('RegisterCallbackHandler', () => dart.functionType(ZoneCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  let RegisterUnaryCallbackHandler = dart.typedef('RegisterUnaryCallbackHandler', () => dart.functionType(ZoneUnaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic])]));
  let RegisterBinaryCallbackHandler = dart.typedef('RegisterBinaryCallbackHandler', () => dart.functionType(ZoneBinaryCallback, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]));
  let ErrorCallbackHandler = dart.typedef('ErrorCallbackHandler', () => dart.functionType(AsyncError, [Zone, ZoneDelegate, Zone, core.Object, core.StackTrace]));
  let ScheduleMicrotaskHandler = dart.typedef('ScheduleMicrotaskHandler', () => dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, dart.functionType(dart.dynamic, [])]));
  let CreateTimerHandler = dart.typedef('CreateTimerHandler', () => dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [])]));
  let CreatePeriodicTimerHandler = dart.typedef('CreatePeriodicTimerHandler', () => dart.functionType(Timer, [Zone, ZoneDelegate, Zone, core.Duration, dart.functionType(dart.void, [Timer])]));
  let PrintHandler = dart.typedef('PrintHandler', () => dart.functionType(dart.void, [Zone, ZoneDelegate, Zone, core.String]));
  let ForkHandler = dart.typedef('ForkHandler', () => dart.functionType(Zone, [Zone, ZoneDelegate, Zone, ZoneSpecification, core.Map]));
  class _ZoneFunction extends core.Object {
    _ZoneFunction(zone, func) {
      this.zone = zone;
      this.function = func;
    }
  }
  class ZoneSpecification extends core.Object {
    ZoneSpecification(opts) {
      return new _ZoneSpecification(opts);
    }
    from(other, opts) {
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
      return new ZoneSpecification({handleUncaughtError: handleUncaughtError != null ? handleUncaughtError : other.handleUncaughtError, run: run != null ? run : other.run, runUnary: runUnary != null ? runUnary : other.runUnary, runBinary: runBinary != null ? runBinary : other.runBinary, registerCallback: registerCallback != null ? registerCallback : other.registerCallback, registerUnaryCallback: registerUnaryCallback != null ? registerUnaryCallback : other.registerUnaryCallback, registerBinaryCallback: registerBinaryCallback != null ? registerBinaryCallback : other.registerBinaryCallback, errorCallback: errorCallback != null ? errorCallback : other.errorCallback, scheduleMicrotask: scheduleMicrotask != null ? scheduleMicrotask : other.scheduleMicrotask, createTimer: createTimer != null ? createTimer : other.createTimer, createPeriodicTimer: createPeriodicTimer != null ? createPeriodicTimer : other.createPeriodicTimer, print: print != null ? print : other.print, fork: fork != null ? fork : other.fork});
    }
  }
  dart.defineNamedConstructor(ZoneSpecification, 'from');
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
  Zone.ROOT = _ROOT_ZONE;
  Zone._current = _ROOT_ZONE;
  let _delegate = Symbol('_delegate');
  // Function _parentDelegate: (_Zone) → ZoneDelegate
  function _parentDelegate(zone) {
    if (zone.parent == null)
      return null;
    return zone.parent[_delegate];
  }
  let _delegationTarget = Symbol('_delegationTarget');
  let _handleUncaughtError = Symbol('_handleUncaughtError');
  let _run = Symbol('_run');
  let _runUnary = Symbol('_runUnary');
  let _runBinary = Symbol('_runBinary');
  let _registerCallback = Symbol('_registerCallback');
  let _registerUnaryCallback = Symbol('_registerUnaryCallback');
  let _registerBinaryCallback = Symbol('_registerBinaryCallback');
  let _errorCallback = Symbol('_errorCallback');
  let _scheduleMicrotask = Symbol('_scheduleMicrotask');
  let _createTimer = Symbol('_createTimer');
  let _createPeriodicTimer = Symbol('_createPeriodicTimer');
  let _print = Symbol('_print');
  let _fork = Symbol('_fork');
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
      if (core.identical(implZone, _ROOT_ZONE))
        return null;
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
  class _Zone extends core.Object {
    _Zone() {
    }
    inSameErrorZone(otherZone) {
      return dart.notNull(core.identical(this, otherZone)) || dart.notNull(core.identical(this.errorZone, otherZone.errorZone));
    }
  }
  _Zone[dart.implements] = () => [Zone];
  let _delegateCache = Symbol('_delegateCache');
  let _map = Symbol('_map');
  class _CustomZone extends _Zone {
    get [_delegate]() {
      if (this[_delegateCache] != null)
        return this[_delegateCache];
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
      if (runGuarded) {
        return (() => this.runGuarded(registered)).bind(this);
      } else {
        return (() => this.run(registered)).bind(this);
      }
    }
    bindUnaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      let registered = this.registerUnaryCallback(f);
      if (runGuarded) {
        return (arg => this.runUnaryGuarded(registered, arg)).bind(this);
      } else {
        return (arg => this.runUnary(registered, arg)).bind(this);
      }
    }
    bindBinaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      let registered = this.registerBinaryCallback(f);
      if (runGuarded) {
        return ((arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2)).bind(this);
      } else {
        return ((arg1, arg2) => this.runBinary(registered, arg1, arg2)).bind(this);
      }
    }
    get(key) {
      let result = this[_map].get(key);
      if (dart.notNull(result != null) || dart.notNull(this[_map].containsKey(key)))
        return result;
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
      if (core.identical(implementationZone, _ROOT_ZONE))
        return null;
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
  // Function _rootHandleUncaughtError: (Zone, ZoneDelegate, Zone, dynamic, StackTrace) → void
  function _rootHandleUncaughtError(self, parent, zone, error, stackTrace) {
    _schedulePriorityAsyncCallback(() => {
      throw new _UncaughtAsyncError(error, stackTrace);
    });
  }
  // Function _rootRun: (Zone, ZoneDelegate, Zone, () → dynamic) → dynamic
  function _rootRun(self, parent, zone, f) {
    if (dart.equals(Zone._current, zone))
      return f();
    let old = Zone._enter(zone);
    try {
      return f();
    } finally {
      Zone._leave(old);
    }
  }
  // Function _rootRunUnary: (Zone, ZoneDelegate, Zone, (dynamic) → dynamic, dynamic) → dynamic
  function _rootRunUnary(self, parent, zone, f, arg) {
    if (dart.equals(Zone._current, zone))
      return dart.dcall(f, arg);
    let old = Zone._enter(zone);
    try {
      return dart.dcall(f, arg);
    } finally {
      Zone._leave(old);
    }
  }
  // Function _rootRunBinary: (Zone, ZoneDelegate, Zone, (dynamic, dynamic) → dynamic, dynamic, dynamic) → dynamic
  function _rootRunBinary(self, parent, zone, f, arg1, arg2) {
    if (dart.equals(Zone._current, zone))
      return dart.dcall(f, arg1, arg2);
    let old = Zone._enter(zone);
    try {
      return dart.dcall(f, arg1, arg2);
    } finally {
      Zone._leave(old);
    }
  }
  // Function _rootRegisterCallback: (Zone, ZoneDelegate, Zone, () → dynamic) → ZoneCallback
  function _rootRegisterCallback(self, parent, zone, f) {
    return f;
  }
  // Function _rootRegisterUnaryCallback: (Zone, ZoneDelegate, Zone, (dynamic) → dynamic) → ZoneUnaryCallback
  function _rootRegisterUnaryCallback(self, parent, zone, f) {
    return f;
  }
  // Function _rootRegisterBinaryCallback: (Zone, ZoneDelegate, Zone, (dynamic, dynamic) → dynamic) → ZoneBinaryCallback
  function _rootRegisterBinaryCallback(self, parent, zone, f) {
    return f;
  }
  // Function _rootErrorCallback: (Zone, ZoneDelegate, Zone, Object, StackTrace) → AsyncError
  function _rootErrorCallback(self, parent, zone, error, stackTrace) {
    return null;
  }
  // Function _rootScheduleMicrotask: (Zone, ZoneDelegate, Zone, () → dynamic) → void
  function _rootScheduleMicrotask(self, parent, zone, f) {
    if (!dart.notNull(core.identical(_ROOT_ZONE, zone))) {
      let hasErrorHandler = !dart.notNull(_ROOT_ZONE.inSameErrorZone(zone));
      f = zone.bindCallback(f, {runGuarded: hasErrorHandler});
    }
    _scheduleAsyncCallback(f);
  }
  // Function _rootCreateTimer: (Zone, ZoneDelegate, Zone, Duration, () → void) → Timer
  function _rootCreateTimer(self, parent, zone, duration, callback) {
    if (!dart.notNull(core.identical(_ROOT_ZONE, zone))) {
      callback = zone.bindCallback(callback);
    }
    return Timer._createTimer(duration, callback);
  }
  // Function _rootCreatePeriodicTimer: (Zone, ZoneDelegate, Zone, Duration, (Timer) → void) → Timer
  function _rootCreatePeriodicTimer(self, parent, zone, duration, callback) {
    if (!dart.notNull(core.identical(_ROOT_ZONE, zone))) {
      callback = dart.as(zone.bindUnaryCallback(callback), __CastType36);
    }
    return Timer._createPeriodicTimer(duration, callback);
  }
  // Function _rootPrint: (Zone, ZoneDelegate, Zone, String) → void
  function _rootPrint(self, parent, zone, line) {
    _internal.printToConsole(line);
  }
  // Function _printToZone: (String) → void
  function _printToZone(line) {
    Zone.current.print(line);
  }
  // Function _rootFork: (Zone, ZoneDelegate, Zone, ZoneSpecification, Map<dynamic, dynamic>) → Zone
  function _rootFork(self, parent, zone, specification, zoneValues) {
    _internal.printToZone = _printToZone;
    if (specification == null) {
      specification = dart.const(new ZoneSpecification());
    } else if (!dart.is(specification, _ZoneSpecification)) {
      throw new core.ArgumentError("ZoneSpecifications must be instantiated" + " with the provided constructor.");
    }
    let valueMap = null;
    if (zoneValues == null) {
      if (dart.is(zone, _Zone)) {
        valueMap = zone[_map];
      } else {
        valueMap = new collection.HashMap();
      }
    } else {
      valueMap = new collection.HashMap.from(zoneValues);
    }
    return new _CustomZone(dart.as(zone, _Zone), specification, valueMap);
  }
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
      if (_RootZone._rootDelegate != null)
        return _RootZone._rootDelegate;
      return _RootZone._rootDelegate = new _ZoneDelegate(this);
    }
    get errorZone() {
      return this;
    }
    runGuarded(f) {
      try {
        if (core.identical(_ROOT_ZONE, Zone._current)) {
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
        if (core.identical(_ROOT_ZONE, Zone._current)) {
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
        if (core.identical(_ROOT_ZONE, Zone._current)) {
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
      if (runGuarded) {
        return (() => this.runGuarded(f)).bind(this);
      } else {
        return (() => this.run(f)).bind(this);
      }
    }
    bindUnaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      if (runGuarded) {
        return (arg => this.runUnaryGuarded(f, arg)).bind(this);
      } else {
        return (arg => this.runUnary(f, arg)).bind(this);
      }
    }
    bindBinaryCallback(f, opts) {
      let runGuarded = opts && 'runGuarded' in opts ? opts.runGuarded : true;
      if (runGuarded) {
        return ((arg1, arg2) => this.runBinaryGuarded(f, arg1, arg2)).bind(this);
      } else {
        return ((arg1, arg2) => this.runBinary(f, arg1, arg2)).bind(this);
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
      if (core.identical(Zone._current, _ROOT_ZONE))
        return f();
      return _rootRun(null, null, this, f);
    }
    runUnary(f, arg) {
      if (core.identical(Zone._current, _ROOT_ZONE))
        return dart.dcall(f, arg);
      return _rootRunUnary(null, null, this, f, arg);
    }
    runBinary(f, arg1, arg2) {
      if (core.identical(Zone._current, _ROOT_ZONE))
        return dart.dcall(f, arg1, arg2);
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
  _RootZone._rootDelegate = null;
  dart.defineLazyProperties(_RootZone, {
    get _rootMap() {
      return new collection.HashMap();
    },
    set _rootMap(_) {}
  });
  let _ROOT_ZONE = dart.const(new _RootZone());
  // Function runZoned: (() → dynamic, {zoneValues: Map<dynamic, dynamic>, zoneSpecification: ZoneSpecification, onError: Function}) → dynamic
  function runZoned(body, opts) {
    let zoneValues = opts && 'zoneValues' in opts ? opts.zoneValues : null;
    let zoneSpecification = opts && 'zoneSpecification' in opts ? opts.zoneSpecification : null;
    let onError = opts && 'onError' in opts ? opts.onError : null;
    let errorHandler = null;
    if (onError != null) {
      errorHandler = (self, parent, zone, error, stackTrace) => {
        try {
          if (dart.is(onError, ZoneBinaryCallback)) {
            return self.parent.runBinary(onError, error, stackTrace);
          }
          return self.parent.runUnary(dart.as(onError, __CastType38), error);
        } catch (e) {
          let s = dart.stackTrace(e);
          if (core.identical(e, error)) {
            return parent.handleUncaughtError(zone, error, stackTrace);
          } else {
            return parent.handleUncaughtError(zone, e, s);
          }
        }

      };
    }
    if (zoneSpecification == null) {
      zoneSpecification = new ZoneSpecification({handleUncaughtError: errorHandler});
    } else if (errorHandler != null) {
      zoneSpecification = new ZoneSpecification.from(zoneSpecification, {handleUncaughtError: errorHandler});
    }
    let zone = Zone.current.fork({specification: zoneSpecification, zoneValues: zoneValues});
    if (onError != null) {
      return zone.runGuarded(body);
    } else {
      return zone.run(body);
    }
  }
  let __CastType36 = dart.typedef('__CastType36', () => dart.functionType(dart.void, [Timer]));
  let __CastType38 = dart.typedef('__CastType38', () => dart.functionType(dart.dynamic, [dart.dynamic]));
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
})(async, core, _internal, _js_helper, _isolate_helper, collection);
