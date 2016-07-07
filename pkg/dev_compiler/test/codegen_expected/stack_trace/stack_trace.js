dart_library.library('stack_trace', null, /* Imports */[
  'dart_sdk',
  'path'
], function load__stack_trace(exports, dart_sdk, path) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const path$ = path.path;
  const src__chain = Object.create(null);
  const src__frame = Object.create(null);
  const src__lazy_trace = Object.create(null);
  const src__stack_zone_specification = Object.create(null);
  const src__trace = Object.create(null);
  const src__unparsed_frame = Object.create(null);
  const src__utils = Object.create(null);
  const src__vm_trace = Object.create(null);
  const stack_trace = Object.create(null);
  let JSArrayOfTrace = () => (JSArrayOfTrace = dart.constFn(_interceptors.JSArray$(src__trace.Trace)))();
  let UnmodifiableListViewOfTrace = () => (UnmodifiableListViewOfTrace = dart.constFn(collection.UnmodifiableListView$(src__trace.Trace)))();
  let ListOfFrame = () => (ListOfFrame = dart.constFn(core.List$(src__frame.Frame)))();
  let dynamicAndChainTovoid = () => (dynamicAndChainTovoid = dart.constFn(dart.functionType(dart.void, [dart.dynamic, src__chain.Chain])))();
  let ExpandoOf_Node = () => (ExpandoOf_Node = dart.constFn(core.Expando$(src__stack_zone_specification._Node)))();
  let JSArrayOfFrame = () => (JSArrayOfFrame = dart.constFn(_interceptors.JSArray$(src__frame.Frame)))();
  let UnmodifiableListViewOfFrame = () => (UnmodifiableListViewOfFrame = dart.constFn(collection.UnmodifiableListView$(src__frame.Frame)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let StringToTrace = () => (StringToTrace = dart.constFn(dart.definiteFunctionType(src__trace.Trace, [core.String])))();
  let FrameTobool = () => (FrameTobool = dart.constFn(dart.definiteFunctionType(core.bool, [src__frame.Frame])))();
  let TraceToTrace = () => (TraceToTrace = dart.constFn(dart.definiteFunctionType(src__trace.Trace, [src__trace.Trace])))();
  let TraceTobool = () => (TraceTobool = dart.constFn(dart.definiteFunctionType(core.bool, [src__trace.Trace])))();
  let TraceToListOfFrame = () => (TraceToListOfFrame = dart.constFn(dart.definiteFunctionType(ListOfFrame(), [src__trace.Trace])))();
  let FrameToint = () => (FrameToint = dart.constFn(dart.definiteFunctionType(core.int, [src__frame.Frame])))();
  let TraceToint = () => (TraceToint = dart.constFn(dart.definiteFunctionType(core.int, [src__trace.Trace])))();
  let FrameToString = () => (FrameToString = dart.constFn(dart.definiteFunctionType(core.String, [src__frame.Frame])))();
  let TraceToString = () => (TraceToString = dart.constFn(dart.definiteFunctionType(core.String, [src__trace.Trace])))();
  let VoidToFrame = () => (VoidToFrame = dart.constFn(dart.definiteFunctionType(src__frame.Frame, [])))();
  let VoidToTrace = () => (VoidToTrace = dart.constFn(dart.definiteFunctionType(src__trace.Trace, [])))();
  let ObjectAndStackTraceAndEventSinkTovoid = () => (ObjectAndStackTraceAndEventSinkTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Object, core.StackTrace, async.EventSink])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let StringToFrame = () => (StringToFrame = dart.constFn(dart.definiteFunctionType(src__frame.Frame, [core.String])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let FrameToFrame = () => (FrameToFrame = dart.constFn(dart.definiteFunctionType(src__frame.Frame, [src__frame.Frame])))();
  let StringAndintToString = () => (StringAndintToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String, core.int])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  src__chain.ChainHandler = dart.typedef('ChainHandler', () => dart.functionType(dart.void, [dart.dynamic, src__chain.Chain]));
  let const$;
  let const$0;
  src__chain.Chain = class Chain extends core.Object {
    static get _currentSpec() {
      return src__stack_zone_specification.StackZoneSpecification._check(async.Zone.current.get(const$ || (const$ = dart.const(core.Symbol.new('stack_trace.stack_zone.spec')))));
    }
    static capture(T) {
      return (callback, opts) => {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let when = opts && 'when' in opts ? opts.when : true;
        if (!dart.test(when)) {
          let newOnError = null;
          if (onError != null) {
            newOnError = dart.fn((error, stackTrace) => {
              dart.dcall(onError, error, src__chain.Chain.forTrace(core.StackTrace._check(stackTrace)));
            }, dynamicAnddynamicTodynamic());
          }
          return async.runZoned(T)(callback, {onError: core.Function._check(newOnError)});
        }
        let spec = new src__stack_zone_specification.StackZoneSpecification(onError);
        return async.runZoned(T)(dart.fn(() => {
          try {
            return callback();
          } catch (error) {
            let stackTrace = dart.stackTrace(error);
            return async.Zone.current.handleUncaughtError(T)(error, stackTrace);
          }

        }, dart.definiteFunctionType(T, [])), {zoneSpecification: spec.toSpec(), zoneValues: dart.map([const$0 || (const$0 = dart.const(core.Symbol.new('stack_trace.stack_zone.spec'))), spec])});
      };
    }
    static track(futureOrStream) {
      return futureOrStream;
    }
    static current(level) {
      if (level === void 0) level = 0;
      if (src__chain.Chain._currentSpec != null) return src__chain.Chain._currentSpec.currentChain(dart.notNull(level) + 1);
      return new src__chain.Chain(JSArrayOfTrace().of([src__trace.Trace.current(dart.notNull(level) + 1)]));
    }
    static forTrace(trace) {
      if (src__chain.Chain.is(trace)) return trace;
      if (src__chain.Chain._currentSpec == null) return new src__chain.Chain(JSArrayOfTrace().of([src__trace.Trace.from(trace)]));
      return src__chain.Chain._currentSpec.chainFor(trace);
    }
    static parse(chain) {
      if (dart.test(chain[dartx.isEmpty])) return new src__chain.Chain(JSArrayOfTrace().of([]));
      if (!dart.test(chain[dartx.contains](src__utils.chainGap))) return new src__chain.Chain(JSArrayOfTrace().of([src__trace.Trace.parse(chain)]));
      return new src__chain.Chain(chain[dartx.split](src__utils.chainGap)[dartx.map](src__trace.Trace)(dart.fn(trace => new src__trace.Trace.parseFriendly(trace), StringToTrace())));
    }
    new(traces) {
      this.traces = new (UnmodifiableListViewOfTrace())(traces[dartx.toList]());
    }
    get terse() {
      return this.foldFrames(dart.fn(_ => false, FrameTobool()), {terse: true});
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      let foldedTraces = this.traces[dartx.map](src__trace.Trace)(dart.fn(trace => trace.foldFrames(predicate, {terse: terse}), TraceToTrace()));
      let nonEmptyTraces = foldedTraces[dartx.where](dart.fn(trace => {
        if (dart.notNull(trace.frames[dartx.length]) > 1) return true;
        if (dart.test(trace.frames[dartx.isEmpty])) return false;
        if (!dart.test(terse)) return false;
        return trace.frames[dartx.single].line != null;
      }, TraceTobool()));
      if (dart.test(nonEmptyTraces[dartx.isEmpty]) && dart.test(foldedTraces[dartx.isNotEmpty])) {
        return new src__chain.Chain(JSArrayOfTrace().of([foldedTraces[dartx.last]]));
      }
      return new src__chain.Chain(nonEmptyTraces);
    }
    toTrace() {
      return new src__trace.Trace(this.traces[dartx.expand](src__frame.Frame)(dart.fn(trace => trace.frames, TraceToListOfFrame())));
    }
    toString() {
      let longest = this.traces[dartx.map](core.int)(dart.fn(trace => trace.frames[dartx.map](core.int)(dart.fn(frame => frame.location[dartx.length], FrameToint()))[dartx.fold](core.int)(0, dart.gbind(math.max, core.int)), TraceToint()))[dartx.fold](core.int)(0, dart.gbind(math.max, core.int));
      return this.traces[dartx.map](core.String)(dart.fn(trace => trace.frames[dartx.map](core.String)(dart.fn(frame => dart.str`${src__utils.padRight(frame.location, longest)}  ${frame.member}\n`, FrameToString()))[dartx.join](), TraceToString()))[dartx.join](src__utils.chainGap);
    }
  };
  src__chain.Chain[dart.implements] = () => [core.StackTrace];
  dart.setSignature(src__chain.Chain, {
    constructors: () => ({
      current: dart.definiteFunctionType(src__chain.Chain, [], [core.int]),
      forTrace: dart.definiteFunctionType(src__chain.Chain, [core.StackTrace]),
      parse: dart.definiteFunctionType(src__chain.Chain, [core.String]),
      new: dart.definiteFunctionType(src__chain.Chain, [core.Iterable$(src__trace.Trace)])
    }),
    methods: () => ({
      foldFrames: dart.definiteFunctionType(src__chain.Chain, [dart.functionType(core.bool, [src__frame.Frame])], {terse: core.bool}),
      toTrace: dart.definiteFunctionType(src__trace.Trace, [])
    }),
    statics: () => ({
      capture: dart.definiteFunctionType(T => [T, [dart.functionType(T, [])], {onError: dynamicAndChainTovoid(), when: core.bool}]),
      track: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    }),
    names: ['capture', 'track']
  });
  dart.defineLazy(src__frame, {
    get _vmFrame() {
      return core.RegExp.new('^#\\d+\\s+(\\S.*) \\((.+?)((?::\\d+){0,2})\\)$');
    }
  });
  dart.defineLazy(src__frame, {
    get _v8Frame() {
      return core.RegExp.new('^\\s*at (?:(\\S.*?)(?: \\[as [^\\]]+\\])? \\((.*)\\)|(.*))$');
    }
  });
  dart.defineLazy(src__frame, {
    get _v8UrlLocation() {
      return core.RegExp.new('^(.*):(\\d+):(\\d+)|native$');
    }
  });
  dart.defineLazy(src__frame, {
    get _v8EvalLocation() {
      return core.RegExp.new('^eval at (?:\\S.*?) \\((.*)\\)(?:, .*?:\\d+:\\d+)?$');
    }
  });
  dart.defineLazy(src__frame, {
    get _firefoxSafariFrame() {
      return core.RegExp.new('^' + '(?:' + '([^@(/]*)' + '(?:\\(.*\\))?' + '((?:/[^/]*)*)' + '(?:\\(.*\\))?' + '@' + ')?' + '(.*?)' + ':' + '(\\d*)' + '(?::(\\d*))?' + '$');
    }
  });
  dart.defineLazy(src__frame, {
    get _friendlyFrame() {
      return core.RegExp.new('^(\\S+)(?: (\\d+)(?::(\\d+))?)?\\s+([^\\d]\\S*)$');
    }
  });
  dart.defineLazy(src__frame, {
    get _asyncBody() {
      return core.RegExp.new('<(<anonymous closure>|[^>]+)_async_body>');
    }
  });
  dart.defineLazy(src__frame, {
    get _initialDot() {
      return core.RegExp.new("^\\.");
    }
  });
  src__frame.Frame = class Frame extends core.Object {
    get isCore() {
      return this.uri.scheme == 'dart';
    }
    get library() {
      if (this.uri.scheme == 'data') return "data:...";
      return path$.prettyUri(this.uri);
    }
    get package() {
      if (this.uri.scheme != 'package') return null;
      return this.uri.path[dartx.split]('/')[dartx.first];
    }
    get location() {
      if (this.line == null) return this.library;
      if (this.column == null) return dart.str`${this.library} ${this.line}`;
      return dart.str`${this.library} ${this.line}:${this.column}`;
    }
    static caller(level) {
      if (level === void 0) level = 1;
      if (dart.notNull(level) < 0) {
        dart.throw(new core.ArgumentError("Argument [level] must be greater than or equal " + "to 0."));
      }
      return src__trace.Trace.current(dart.notNull(level) + 1).frames[dartx.first];
    }
    static parseVM(frame) {
      return src__frame.Frame._catchFormatException(frame, dart.fn(() => {
        if (frame == '...') {
          return new src__frame.Frame(core.Uri.new(), null, null, '...');
        }
        let match = src__frame._vmFrame.firstMatch(frame);
        if (match == null) return new src__unparsed_frame.UnparsedFrame(frame);
        let member = match.get(1)[dartx.replaceAll](src__frame._asyncBody, "<async>")[dartx.replaceAll]("<anonymous closure>", "<fn>");
        let uri = core.Uri.parse(match.get(2));
        let lineAndColumn = match.get(3)[dartx.split](':');
        let line = dart.notNull(lineAndColumn[dartx.length]) > 1 ? core.int.parse(lineAndColumn[dartx.get](1)) : null;
        let column = dart.notNull(lineAndColumn[dartx.length]) > 2 ? core.int.parse(lineAndColumn[dartx.get](2)) : null;
        return new src__frame.Frame(uri, line, column, member);
      }, VoidToFrame()));
    }
    static parseV8(frame) {
      return src__frame.Frame._catchFormatException(frame, dart.fn(() => {
        let match = src__frame._v8Frame.firstMatch(frame);
        if (match == null) return new src__unparsed_frame.UnparsedFrame(frame);
        function parseLocation(location, member) {
          let evalMatch = src__frame._v8EvalLocation.firstMatch(core.String._check(location));
          while (evalMatch != null) {
            location = evalMatch.get(1);
            evalMatch = src__frame._v8EvalLocation.firstMatch(core.String._check(location));
          }
          if (dart.equals(location, 'native')) {
            return new src__frame.Frame(core.Uri.parse('native'), null, null, core.String._check(member));
          }
          let urlMatch = src__frame._v8UrlLocation.firstMatch(core.String._check(location));
          if (urlMatch == null) return new src__unparsed_frame.UnparsedFrame(frame);
          return new src__frame.Frame(src__frame.Frame._uriOrPathToUri(urlMatch.get(1)), core.int.parse(urlMatch.get(2)), core.int.parse(urlMatch.get(3)), core.String._check(member));
        }
        dart.fn(parseLocation, dynamicAnddynamicTodynamic());
        if (match.get(2) != null) {
          return src__frame.Frame._check(parseLocation(match.get(2), match.get(1)[dartx.replaceAll]("<anonymous>", "<fn>")[dartx.replaceAll]("Anonymous function", "<fn>")));
        } else {
          return src__frame.Frame._check(parseLocation(match.get(3), "<fn>"));
        }
      }, VoidToFrame()));
    }
    static parseJSCore(frame) {
      return src__frame.Frame.parseV8(frame);
    }
    static parseIE(frame) {
      return src__frame.Frame.parseV8(frame);
    }
    static parseFirefox(frame) {
      return src__frame.Frame._catchFormatException(frame, dart.fn(() => {
        let match = src__frame._firefoxSafariFrame.firstMatch(frame);
        if (match == null) return new src__unparsed_frame.UnparsedFrame(frame);
        let uri = src__frame.Frame._uriOrPathToUri(match.get(3));
        let member = null;
        if (match.get(1) != null) {
          member = match.get(1);
          member = dart.dsend(member, '+', core.List.filled('/'[dartx.allMatches](match.get(2))[dartx.length], ".<fn>")[dartx.join]());
          if (dart.equals(member, '')) member = '<fn>';
          member = dart.dsend(member, 'replaceFirst', src__frame._initialDot, '');
        } else {
          member = '<fn>';
        }
        let line = match.get(4) == '' ? null : core.int.parse(match.get(4));
        let column = match.get(5) == null || match.get(5) == '' ? null : core.int.parse(match.get(5));
        return new src__frame.Frame(uri, line, column, core.String._check(member));
      }, VoidToFrame()));
    }
    static parseSafari6_0(frame) {
      return src__frame.Frame.parseFirefox(frame);
    }
    static parseSafari6_1(frame) {
      return src__frame.Frame.parseFirefox(frame);
    }
    static parseSafari(frame) {
      return src__frame.Frame.parseFirefox(frame);
    }
    static parseFriendly(frame) {
      return src__frame.Frame._catchFormatException(frame, dart.fn(() => {
        let match = src__frame._friendlyFrame.firstMatch(frame);
        if (match == null) {
          dart.throw(new core.FormatException(dart.str`Couldn't parse package:stack_trace stack trace line '${frame}'.`));
        }
        let uri = core.Uri.parse(match.get(1));
        if (uri.scheme == '') {
          uri = path$.toUri(path$.absolute(path$.fromUri(uri)));
        }
        let line = match.get(2) == null ? null : core.int.parse(match.get(2));
        let column = match.get(3) == null ? null : core.int.parse(match.get(3));
        return new src__frame.Frame(uri, line, column, match.get(4));
      }, VoidToFrame()));
    }
    static _uriOrPathToUri(uriOrPath) {
      if (dart.test(uriOrPath[dartx.contains](src__frame.Frame._uriRegExp))) {
        return core.Uri.parse(uriOrPath);
      } else if (dart.test(uriOrPath[dartx.contains](src__frame.Frame._windowsRegExp))) {
        return core.Uri.file(uriOrPath, {windows: true});
      } else if (dart.test(uriOrPath[dartx.startsWith]('/'))) {
        return core.Uri.file(uriOrPath, {windows: false});
      }
      if (dart.test(uriOrPath[dartx.contains]('\\'))) return path$.windows.toUri(uriOrPath);
      return core.Uri.parse(uriOrPath);
    }
    static _catchFormatException(text, body) {
      try {
        return body();
      } catch (_) {
        if (core.FormatException.is(_)) {
          return new src__unparsed_frame.UnparsedFrame(text);
        } else
          throw _;
      }

    }
    new(uri, line, column, member) {
      this.uri = uri;
      this.line = line;
      this.column = column;
      this.member = member;
    }
    toString() {
      return dart.str`${this.location} in ${this.member}`;
    }
  };
  dart.setSignature(src__frame.Frame, {
    constructors: () => ({
      caller: dart.definiteFunctionType(src__frame.Frame, [], [core.int]),
      parseVM: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseV8: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseJSCore: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseIE: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseFirefox: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseSafari6_0: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseSafari6_1: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseSafari: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      parseFriendly: dart.definiteFunctionType(src__frame.Frame, [core.String]),
      new: dart.definiteFunctionType(src__frame.Frame, [core.Uri, core.int, core.int, core.String])
    }),
    statics: () => ({
      _uriOrPathToUri: dart.definiteFunctionType(core.Uri, [core.String]),
      _catchFormatException: dart.definiteFunctionType(src__frame.Frame, [core.String, dart.functionType(src__frame.Frame, [])])
    }),
    names: ['_uriOrPathToUri', '_catchFormatException']
  });
  dart.defineLazy(src__frame.Frame, {
    get _uriRegExp() {
      return core.RegExp.new('^[a-zA-Z][-+.a-zA-Z\\d]*://');
    },
    get _windowsRegExp() {
      return core.RegExp.new('^([a-zA-Z]:[\\\\/]|\\\\\\\\)');
    }
  });
  src__lazy_trace.TraceThunk = dart.typedef('TraceThunk', () => dart.functionType(src__trace.Trace, []));
  const _thunk = Symbol('_thunk');
  const _inner = Symbol('_inner');
  const _trace = Symbol('_trace');
  src__lazy_trace.LazyTrace = class LazyTrace extends core.Object {
    new(thunk) {
      this[_thunk] = thunk;
      this[_inner] = null;
    }
    get [_trace]() {
      if (this[_inner] == null) this[_inner] = this[_thunk]();
      return this[_inner];
    }
    get frames() {
      return this[_trace].frames;
    }
    get vmTrace() {
      return this[_trace].vmTrace;
    }
    get terse() {
      return new src__lazy_trace.LazyTrace(dart.fn(() => this[_trace].terse, VoidToTrace()));
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      return new src__lazy_trace.LazyTrace(dart.fn(() => this[_trace].foldFrames(predicate, {terse: terse}), VoidToTrace()));
    }
    toString() {
      return dart.toString(this[_trace]);
    }
    set frames(_) {
      return dart.throw(new core.UnimplementedError());
    }
  };
  src__lazy_trace.LazyTrace[dart.implements] = () => [src__trace.Trace];
  dart.setSignature(src__lazy_trace.LazyTrace, {
    constructors: () => ({new: dart.definiteFunctionType(src__lazy_trace.LazyTrace, [src__lazy_trace.TraceThunk])}),
    methods: () => ({foldFrames: dart.definiteFunctionType(src__trace.Trace, [dart.functionType(core.bool, [src__frame.Frame])], {terse: core.bool})})
  });
  src__stack_zone_specification._ChainHandler = dart.typedef('_ChainHandler', () => dart.functionType(dart.void, [dart.dynamic, src__chain.Chain]));
  const _chains = Symbol('_chains');
  const _onError = Symbol('_onError');
  const _currentNode = Symbol('_currentNode');
  const _createNode = Symbol('_createNode');
  const _run = Symbol('_run');
  src__stack_zone_specification.StackZoneSpecification = class StackZoneSpecification extends core.Object {
    new(onError) {
      if (onError === void 0) onError = null;
      this[_chains] = new (ExpandoOf_Node())("stack chains");
      this[_onError] = onError;
      this[_currentNode] = null;
    }
    toSpec() {
      return async.ZoneSpecification.new({handleUncaughtError: dart.bind(this, 'handleUncaughtError'), registerCallback: dart.bind(this, 'registerCallback'), registerUnaryCallback: dart.bind(this, 'registerUnaryCallback'), registerBinaryCallback: dart.bind(this, 'registerBinaryCallback'), errorCallback: dart.bind(this, 'errorCallback')});
    }
    currentChain(level) {
      if (level === void 0) level = 0;
      return this[_createNode](dart.notNull(level) + 1).toChain();
    }
    chainFor(trace) {
      if (src__chain.Chain.is(trace)) return trace;
      let previous = trace == null ? null : this[_chains].get(trace);
      return new src__stack_zone_specification._Node(trace, previous).toChain();
    }
    trackFuture(future, level) {
      if (level === void 0) level = 0;
      let completer = async.Completer.sync();
      let node = this[_createNode](dart.notNull(level) + 1);
      future.then(dart.dynamic)(dart.bind(completer, 'complete')).catchError(dart.fn((e, stackTrace) => {
        if (stackTrace == null) stackTrace = src__trace.Trace.current();
        if (!src__chain.Chain.is(stackTrace) && this[_chains].get(stackTrace) == null) {
          this[_chains].set(stackTrace, node);
        }
        completer.completeError(e, core.StackTrace._check(stackTrace));
      }, dynamicAnddynamicTodynamic()));
      return completer.future;
    }
    trackStream(stream, level) {
      if (level === void 0) level = 0;
      let node = this[_createNode](dart.notNull(level) + 1);
      return stream.transform(dart.dynamic)(async.StreamTransformer.fromHandlers({handleError: dart.fn((error, stackTrace, sink) => {
          if (stackTrace == null) stackTrace = src__trace.Trace.current();
          if (!src__chain.Chain.is(stackTrace) && this[_chains].get(stackTrace) == null) {
            this[_chains].set(stackTrace, node);
          }
          sink.addError(error, stackTrace);
        }, ObjectAndStackTraceAndEventSinkTovoid())}));
    }
    registerCallback(self, parent, zone, f) {
      if (f == null) return parent.registerCallback(dart.dynamic)(zone, null);
      let node = this[_createNode](1);
      return parent.registerCallback(dart.dynamic)(zone, dart.fn(() => this[_run](f, node), VoidTodynamic()));
    }
    registerUnaryCallback(self, parent, zone, f) {
      if (f == null) return parent.registerUnaryCallback(dart.dynamic, dart.dynamic)(zone, null);
      let node = this[_createNode](1);
      return parent.registerUnaryCallback(dart.dynamic, dart.dynamic)(zone, dart.fn(arg => this[_run](dart.fn(() => dart.dcall(f, arg), VoidTodynamic()), node), dynamicTodynamic()));
    }
    registerBinaryCallback(self, parent, zone, f) {
      if (f == null) return parent.registerBinaryCallback(dart.dynamic, dart.dynamic, dart.dynamic)(zone, null);
      let node = this[_createNode](1);
      return parent.registerBinaryCallback(dart.dynamic, dart.dynamic, dart.dynamic)(zone, dart.fn((arg1, arg2) => this[_run](dart.fn(() => dart.dcall(f, arg1, arg2), VoidTodynamic()), node), dynamicAnddynamicTodynamic()));
    }
    handleUncaughtError(self, parent, zone, error, stackTrace) {
      let stackChain = this.chainFor(stackTrace);
      if (this[_onError] == null) {
        return parent.handleUncaughtError(dart.dynamic)(zone, error, stackChain);
      }
      try {
        return parent.runBinary(dart.dynamic, dart.dynamic, src__chain.Chain)(zone, this[_onError], error, stackChain);
      } catch (newError) {
        let newStackTrace = dart.stackTrace(newError);
        if (core.identical(newError, error)) {
          return parent.handleUncaughtError(dart.dynamic)(zone, error, stackChain);
        } else {
          return parent.handleUncaughtError(dart.dynamic)(zone, newError, newStackTrace);
        }
      }

    }
    errorCallback(self, parent, zone, error, stackTrace) {
      if (stackTrace == null) {
        stackTrace = this[_createNode](2).toChain();
      } else {
        if (this[_chains].get(stackTrace) == null) this[_chains].set(stackTrace, this[_createNode](2));
      }
      let asyncError = parent.errorCallback(zone, error, stackTrace);
      return asyncError == null ? new async.AsyncError(error, stackTrace) : asyncError;
    }
    [_createNode](level) {
      if (level === void 0) level = 0;
      return new src__stack_zone_specification._Node(src__trace.Trace.current(dart.notNull(level) + 1), this[_currentNode]);
    }
    [_run](f, node) {
      let previousNode = this[_currentNode];
      this[_currentNode] = node;
      try {
        return dart.dcall(f);
      } catch (e) {
        let stackTrace = dart.stackTrace(e);
        this[_chains].set(stackTrace, node);
        throw e;
      }
 finally {
        this[_currentNode] = previousNode;
      }
    }
  };
  dart.setSignature(src__stack_zone_specification.StackZoneSpecification, {
    constructors: () => ({new: dart.definiteFunctionType(src__stack_zone_specification.StackZoneSpecification, [], [src__stack_zone_specification._ChainHandler])}),
    methods: () => ({
      toSpec: dart.definiteFunctionType(async.ZoneSpecification, []),
      currentChain: dart.definiteFunctionType(src__chain.Chain, [], [core.int]),
      chainFor: dart.definiteFunctionType(src__chain.Chain, [core.StackTrace]),
      trackFuture: dart.definiteFunctionType(async.Future, [async.Future], [core.int]),
      trackStream: dart.definiteFunctionType(async.Stream, [async.Stream], [core.int]),
      registerCallback: dart.definiteFunctionType(async.ZoneCallback, [async.Zone, async.ZoneDelegate, async.Zone, core.Function]),
      registerUnaryCallback: dart.definiteFunctionType(async.ZoneUnaryCallback, [async.Zone, async.ZoneDelegate, async.Zone, core.Function]),
      registerBinaryCallback: dart.definiteFunctionType(async.ZoneBinaryCallback, [async.Zone, async.ZoneDelegate, async.Zone, core.Function]),
      handleUncaughtError: dart.definiteFunctionType(dart.dynamic, [async.Zone, async.ZoneDelegate, async.Zone, dart.dynamic, core.StackTrace]),
      errorCallback: dart.definiteFunctionType(async.AsyncError, [async.Zone, async.ZoneDelegate, async.Zone, core.Object, core.StackTrace]),
      [_createNode]: dart.definiteFunctionType(src__stack_zone_specification._Node, [], [core.int]),
      [_run]: dart.definiteFunctionType(dart.dynamic, [core.Function, src__stack_zone_specification._Node])
    })
  });
  src__stack_zone_specification._Node = class _Node extends core.Object {
    new(trace, previous) {
      if (previous === void 0) previous = null;
      this.previous = previous;
      this.trace = trace == null ? src__trace.Trace.current() : src__trace.Trace.from(trace);
    }
    toChain() {
      let nodes = JSArrayOfTrace().of([]);
      let node = this;
      while (node != null) {
        nodes[dartx.add](node.trace);
        node = node.previous;
      }
      return new src__chain.Chain(nodes);
    }
  };
  dart.setSignature(src__stack_zone_specification._Node, {
    constructors: () => ({new: dart.definiteFunctionType(src__stack_zone_specification._Node, [core.StackTrace], [src__stack_zone_specification._Node])}),
    methods: () => ({toChain: dart.definiteFunctionType(src__chain.Chain, [])})
  });
  dart.defineLazy(src__trace, {
    get _terseRegExp() {
      return core.RegExp.new("(-patch)?([/\\\\].*)?$");
    }
  });
  dart.defineLazy(src__trace, {
    get _v8Trace() {
      return core.RegExp.new("\\n    ?at ");
    }
  });
  dart.defineLazy(src__trace, {
    get _v8TraceLine() {
      return core.RegExp.new("    ?at ");
    }
  });
  dart.defineLazy(src__trace, {
    get _firefoxSafariTrace() {
      return core.RegExp.new("^" + "(" + "([.0-9A-Za-z_$/<]|\\(.*\\))*" + "@" + ")?" + "[^\\s]*" + ":\\d*" + "$", {multiLine: true});
    }
  });
  dart.defineLazy(src__trace, {
    get _friendlyTrace() {
      return core.RegExp.new("^[^\\s]+( \\d+(:\\d+)?)?[ \\t]+[^\\s]+$", {multiLine: true});
    }
  });
  src__trace.Trace = class Trace extends core.Object {
    static format(stackTrace, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : true;
      let trace = src__trace.Trace.from(stackTrace);
      if (dart.test(terse)) trace = trace.terse;
      return dart.toString(trace);
    }
    static current(level) {
      if (level === void 0) level = 0;
      if (dart.notNull(level) < 0) {
        dart.throw(new core.ArgumentError("Argument [level] must be greater than or equal " + "to 0."));
      }
      let trace = src__trace.Trace.from(core.StackTrace.current);
      return new src__lazy_trace.LazyTrace(dart.fn(() => new src__trace.Trace(trace.frames[dartx.skip](dart.notNull(level) + 1)), VoidToTrace()));
    }
    static from(trace) {
      if (trace == null) {
        dart.throw(new core.ArgumentError("Cannot create a Trace from null."));
      }
      if (src__trace.Trace.is(trace)) return trace;
      if (src__chain.Chain.is(trace)) return trace.toTrace();
      return new src__lazy_trace.LazyTrace(dart.fn(() => src__trace.Trace.parse(dart.toString(trace)), VoidToTrace()));
    }
    static parse(trace) {
      try {
        if (dart.test(trace[dartx.isEmpty])) return new src__trace.Trace(JSArrayOfFrame().of([]));
        if (dart.test(trace[dartx.contains](src__trace._v8Trace))) return new src__trace.Trace.parseV8(trace);
        if (dart.test(trace[dartx.contains]("\tat "))) return new src__trace.Trace.parseJSCore(trace);
        if (dart.test(trace[dartx.contains](src__trace._firefoxSafariTrace))) {
          return new src__trace.Trace.parseFirefox(trace);
        }
        if (dart.test(trace[dartx.contains](src__utils.chainGap))) return src__chain.Chain.parse(trace).toTrace();
        if (dart.test(trace[dartx.contains](src__trace._friendlyTrace))) {
          return new src__trace.Trace.parseFriendly(trace);
        }
        return new src__trace.Trace.parseVM(trace);
      } catch (error) {
        if (core.FormatException.is(error)) {
          dart.throw(new core.FormatException(dart.str`${error.message}\nStack trace:\n${trace}`));
        } else
          throw error;
      }

    }
    parseVM(trace) {
      Trace.prototype.new.call(this, src__trace.Trace._parseVM(trace));
    }
    static _parseVM(trace) {
      let lines = trace[dartx.trim]()[dartx.split]("\n");
      let frames = lines[dartx.take](dart.notNull(lines[dartx.length]) - 1)[dartx.map](src__frame.Frame)(dart.fn(line => src__frame.Frame.parseVM(line), StringToFrame()))[dartx.toList]();
      if (!dart.test(lines[dartx.last][dartx.endsWith](".da"))) {
        frames[dartx.add](src__frame.Frame.parseVM(lines[dartx.last]));
      }
      return frames;
    }
    parseV8(trace) {
      Trace.prototype.new.call(this, trace[dartx.split]("\n")[dartx.skip](1)[dartx.skipWhile](dart.fn(line => !dart.test(line[dartx.startsWith](src__trace._v8TraceLine)), StringTobool()))[dartx.map](src__frame.Frame)(dart.fn(line => src__frame.Frame.parseV8(line), StringToFrame())));
    }
    parseJSCore(trace) {
      Trace.prototype.new.call(this, trace[dartx.split]("\n")[dartx.where](dart.fn(line => line != "\tat ", StringTobool()))[dartx.map](src__frame.Frame)(dart.fn(line => src__frame.Frame.parseV8(line), StringToFrame())));
    }
    parseIE(trace) {
      Trace.prototype.parseV8.call(this, trace);
    }
    parseFirefox(trace) {
      Trace.prototype.new.call(this, trace[dartx.trim]()[dartx.split]("\n")[dartx.where](dart.fn(line => dart.test(line[dartx.isNotEmpty]) && line != '[native code]', StringTobool()))[dartx.map](src__frame.Frame)(dart.fn(line => src__frame.Frame.parseFirefox(line), StringToFrame())));
    }
    parseSafari(trace) {
      Trace.prototype.parseFirefox.call(this, trace);
    }
    parseSafari6_1(trace) {
      Trace.prototype.parseSafari.call(this, trace);
    }
    parseSafari6_0(trace) {
      Trace.prototype.new.call(this, trace[dartx.trim]()[dartx.split]("\n")[dartx.where](dart.fn(line => line != '[native code]', StringTobool()))[dartx.map](src__frame.Frame)(dart.fn(line => src__frame.Frame.parseFirefox(line), StringToFrame())));
    }
    parseFriendly(trace) {
      Trace.prototype.new.call(this, dart.test(trace[dartx.isEmpty]) ? JSArrayOfFrame().of([]) : trace[dartx.trim]()[dartx.split]("\n")[dartx.where](dart.fn(line => !dart.test(line[dartx.startsWith]('=====')), StringTobool()))[dartx.map](src__frame.Frame)(dart.fn(line => src__frame.Frame.parseFriendly(line), StringToFrame())));
    }
    new(frames) {
      this.frames = new (UnmodifiableListViewOfFrame())(frames[dartx.toList]());
    }
    get vmTrace() {
      return new src__vm_trace.VMTrace(this.frames);
    }
    get terse() {
      return this.foldFrames(dart.fn(_ => false, FrameTobool()), {terse: true});
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      if (dart.test(terse)) {
        let oldPredicate = predicate;
        predicate = dart.fn(frame => {
          if (dart.test(oldPredicate(frame))) return true;
          if (dart.test(frame.isCore)) return true;
          if (frame.package == 'stack_trace') return true;
          if (!dart.test(frame.member[dartx.contains]('<async>'))) return false;
          return frame.line == null;
        }, FrameTobool());
      }
      let newFrames = JSArrayOfFrame().of([]);
      for (let frame of this.frames[dartx.reversed]) {
        if (src__unparsed_frame.UnparsedFrame.is(frame) || !dart.test(predicate(frame))) {
          newFrames[dartx.add](frame);
        } else if (dart.test(newFrames[dartx.isEmpty]) || !dart.test(predicate(newFrames[dartx.last]))) {
          newFrames[dartx.add](new src__frame.Frame(frame.uri, frame.line, frame.column, frame.member));
        }
      }
      if (dart.test(terse)) {
        newFrames = newFrames[dartx.map](src__frame.Frame)(dart.fn(frame => {
          if (src__unparsed_frame.UnparsedFrame.is(frame) || !dart.test(predicate(frame))) return frame;
          let library = frame.library[dartx.replaceAll](src__trace._terseRegExp, '');
          return new src__frame.Frame(core.Uri.parse(library), null, null, frame.member);
        }, FrameToFrame()))[dartx.toList]();
        if (dart.notNull(newFrames[dartx.length]) > 1 && dart.test(newFrames[dartx.first].isCore)) newFrames[dartx.removeAt](0);
      }
      return new src__trace.Trace(newFrames[dartx.reversed]);
    }
    toString() {
      let longest = this.frames[dartx.map](core.int)(dart.fn(frame => frame.location[dartx.length], FrameToint()))[dartx.fold](core.int)(0, dart.gbind(math.max, core.int));
      return this.frames[dartx.map](core.String)(dart.fn(frame => {
        if (src__unparsed_frame.UnparsedFrame.is(frame)) return dart.str`${frame}\n`;
        return dart.str`${src__utils.padRight(frame.location, longest)}  ${frame.member}\n`;
      }, FrameToString()))[dartx.join]();
    }
  };
  dart.defineNamedConstructor(src__trace.Trace, 'parseVM');
  dart.defineNamedConstructor(src__trace.Trace, 'parseV8');
  dart.defineNamedConstructor(src__trace.Trace, 'parseJSCore');
  dart.defineNamedConstructor(src__trace.Trace, 'parseIE');
  dart.defineNamedConstructor(src__trace.Trace, 'parseFirefox');
  dart.defineNamedConstructor(src__trace.Trace, 'parseSafari');
  dart.defineNamedConstructor(src__trace.Trace, 'parseSafari6_1');
  dart.defineNamedConstructor(src__trace.Trace, 'parseSafari6_0');
  dart.defineNamedConstructor(src__trace.Trace, 'parseFriendly');
  src__trace.Trace[dart.implements] = () => [core.StackTrace];
  dart.setSignature(src__trace.Trace, {
    constructors: () => ({
      current: dart.definiteFunctionType(src__trace.Trace, [], [core.int]),
      from: dart.definiteFunctionType(src__trace.Trace, [core.StackTrace]),
      parse: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseVM: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseV8: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseJSCore: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseIE: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseFirefox: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseSafari: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseSafari6_1: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseSafari6_0: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      parseFriendly: dart.definiteFunctionType(src__trace.Trace, [core.String]),
      new: dart.definiteFunctionType(src__trace.Trace, [core.Iterable$(src__frame.Frame)])
    }),
    methods: () => ({foldFrames: dart.definiteFunctionType(src__trace.Trace, [dart.functionType(core.bool, [src__frame.Frame])], {terse: core.bool})}),
    statics: () => ({
      format: dart.definiteFunctionType(core.String, [core.StackTrace], {terse: core.bool}),
      _parseVM: dart.definiteFunctionType(core.List$(src__frame.Frame), [core.String])
    }),
    names: ['format', '_parseVM']
  });
  src__unparsed_frame.UnparsedFrame = class UnparsedFrame extends core.Object {
    new(member) {
      this.uri = core.Uri.new({path: "unparsed"});
      this.member = member;
      this.line = null;
      this.column = null;
      this.isCore = false;
      this.library = "unparsed";
      this.package = null;
      this.location = "unparsed";
    }
    toString() {
      return this.member;
    }
  };
  src__unparsed_frame.UnparsedFrame[dart.implements] = () => [src__frame.Frame];
  dart.setSignature(src__unparsed_frame.UnparsedFrame, {
    constructors: () => ({new: dart.definiteFunctionType(src__unparsed_frame.UnparsedFrame, [core.String])})
  });
  src__utils.chainGap = '===== asynchronous gap ===========================\n';
  src__utils.padRight = function(string, length) {
    if (dart.notNull(string[dartx.length]) >= dart.notNull(length)) return string;
    let result = new core.StringBuffer();
    result.write(string);
    for (let i = 0; i < dart.notNull(length) - dart.notNull(string[dartx.length]); i++) {
      result.write(' ');
    }
    return result.toString();
  };
  dart.fn(src__utils.padRight, StringAndintToString());
  src__vm_trace.VMTrace = class VMTrace extends core.Object {
    new(frames) {
      this.frames = frames;
    }
    toString() {
      let i = 1;
      return this.frames[dartx.map](core.String)(dart.fn(frame => {
        let number = src__utils.padRight(dart.str`#${i++}`, 8);
        let member = frame.member[dartx.replaceAllMapped](core.RegExp.new("[^.]+\\.<async>"), dart.fn(match => dart.str`${match.get(1)}.<${match.get(1)}_async_body>`, MatchToString()))[dartx.replaceAll]("<fn>", "<anonymous closure>");
        let line = frame.line == null ? 0 : frame.line;
        let column = frame.column == null ? 0 : frame.column;
        return dart.str`${number}${member} (${frame.uri}:${line}:${column})\n`;
      }, FrameToString()))[dartx.join]();
    }
  };
  src__vm_trace.VMTrace[dart.implements] = () => [core.StackTrace];
  dart.setSignature(src__vm_trace.VMTrace, {
    constructors: () => ({new: dart.definiteFunctionType(src__vm_trace.VMTrace, [core.List$(src__frame.Frame)])})
  });
  stack_trace.ChainHandler = src__chain.ChainHandler;
  stack_trace.Chain = src__chain.Chain;
  stack_trace.Frame = src__frame.Frame;
  stack_trace.Trace = src__trace.Trace;
  stack_trace.UnparsedFrame = src__unparsed_frame.UnparsedFrame;
  // Exports:
  exports.src__chain = src__chain;
  exports.src__frame = src__frame;
  exports.src__lazy_trace = src__lazy_trace;
  exports.src__stack_zone_specification = src__stack_zone_specification;
  exports.src__trace = src__trace;
  exports.src__unparsed_frame = src__unparsed_frame;
  exports.src__utils = src__utils;
  exports.src__vm_trace = src__vm_trace;
  exports.stack_trace = stack_trace;
});
