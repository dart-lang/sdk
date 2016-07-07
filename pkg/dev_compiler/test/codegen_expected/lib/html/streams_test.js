dart_library.library('lib/html/streams_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__streams_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const streams_test = Object.create(null);
  let StreamOfEvent = () => (StreamOfEvent = dart.constFn(async.Stream$(html.Event)))();
  let CompleterOfint = () => (CompleterOfint = dart.constFn(async.Completer$(core.int)))();
  let ListOfEvent = () => (ListOfEvent = dart.constFn(core.List$(html.Event)))();
  let SetOfEvent = () => (SetOfEvent = dart.constFn(core.Set$(html.Event)))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let EventTodynamic = () => (EventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.Event])))();
  let EventTobool = () => (EventTobool = dart.constFn(dart.definiteFunctionType(core.bool, [html.Event])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let EventAndEventToEvent = () => (EventAndEventToEvent = dart.constFn(dart.definiteFunctionType(html.Event, [html.Event, html.Event])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAndEventTodynamic = () => (dynamicAndEventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, html.Event])))();
  let boolTodynamic = () => (boolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.bool])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let ListOfEventTodynamic = () => (ListOfEventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfEvent()])))();
  let SetOfEventTodynamic = () => (SetOfEventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [SetOfEvent()])))();
  let EventAndEventTobool = () => (EventAndEventTobool = dart.constFn(dart.definiteFunctionType(core.bool, [html.Event, html.Event])))();
  const _a = Symbol('_a');
  streams_test.StreamHelper = class StreamHelper extends core.Object {
    new() {
      this[_a] = null;
      this[_a] = html.TextInputElement.new();
      html.document[dartx.body][dartx.append](html.Node._check(this[_a]));
    }
    get element() {
      return html.Element._check(this[_a]);
    }
    get stream() {
      return StreamOfEvent()._check(dart.dload(this[_a], 'onFocus'));
    }
    pulse() {
      let event = html.Event.new('focus');
      dart.dsend(this[_a], 'dispatchEvent', event);
    }
  };
  dart.setSignature(streams_test.StreamHelper, {
    constructors: () => ({new: dart.definiteFunctionType(streams_test.StreamHelper, [])}),
    methods: () => ({pulse: dart.definiteFunctionType(dart.void, [])})
  });
  streams_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('simple', dart.fn(() => {
      let helper = new streams_test.StreamHelper();
      let callCount = 0;
      helper.stream.listen(dart.fn(e => {
        ++callCount;
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(callCount, 1);
    }, VoidTodynamic()));
    unittest$.test('broadcast', dart.fn(() => {
      let stream = html.DivElement.new()[dartx.onClick];
      src__matcher__expect.expect(stream.asBroadcastStream(), stream);
      src__matcher__expect.expect(stream.isBroadcast, src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
    unittest$.test('capture', dart.fn(() => {
      let parent = html.DivElement.new();
      html.document[dartx.body][dartx.append](parent);
      let helper = new streams_test.StreamHelper();
      parent[dartx.append](helper.element);
      let childCallCount = 0;
      let parentCallCount = 0;
      html.Element.focusEvent.forTarget(parent, {useCapture: true}).listen(dart.fn(e => {
        ++parentCallCount;
        src__matcher__expect.expect(childCallCount, 0);
      }, EventTovoid()));
      html.Element.focusEvent.forTarget(helper.element, {useCapture: true}).listen(dart.fn(e => {
        ++childCallCount;
        src__matcher__expect.expect(parentCallCount, 1);
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(childCallCount, 1);
      src__matcher__expect.expect(parentCallCount, 1);
    }, VoidTodynamic()));
    unittest$.test('cancel', dart.fn(() => {
      let helper = new streams_test.StreamHelper();
      let callCount = 0;
      let subscription = helper.stream.listen(dart.fn(_ => {
        ++callCount;
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(callCount, 1);
      subscription.cancel();
      helper.pulse();
      src__matcher__expect.expect(callCount, 1);
      src__matcher__expect.expect(dart.fn(() => {
        subscription.onData(dart.fn(_ => {
        }, EventTovoid()));
      }, VoidTodynamic()), src__matcher__throws_matcher.throws);
      subscription.cancel();
      subscription.pause();
      subscription.resume();
    }, VoidTodynamic()));
    unittest$.test('pause/resume', dart.fn(() => {
      let helper = new streams_test.StreamHelper();
      let callCount = 0;
      let subscription = helper.stream.listen(dart.fn(_ => {
        ++callCount;
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(callCount, 1);
      subscription.pause();
      helper.pulse();
      src__matcher__expect.expect(callCount, 1);
      subscription.resume();
      helper.pulse();
      src__matcher__expect.expect(callCount, 2);
      let completer = CompleterOfint().sync();
      subscription.pause(completer.future);
      helper.pulse();
      src__matcher__expect.expect(callCount, 2);
      subscription.pause();
      helper.pulse();
      subscription.resume();
      helper.pulse();
      src__matcher__expect.expect(callCount, 2);
      completer.complete(0);
      helper.pulse();
      src__matcher__expect.expect(callCount, 3);
      subscription.resume();
    }, VoidTodynamic()));
    unittest$.test('onData', dart.fn(() => {
      let helper = new streams_test.StreamHelper();
      let callCountOne = 0;
      let subscription = helper.stream.listen(dart.fn(_ => {
        ++callCountOne;
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(callCountOne, 1);
      let callCountTwo = 0;
      subscription.onData(dart.fn(_ => {
        ++callCountTwo;
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(callCountOne, 1);
      src__matcher__expect.expect(callCountTwo, 1);
    }, VoidTodynamic()));
    unittest$.test('null onData', dart.fn(() => {
      let helper = new streams_test.StreamHelper();
      let subscription = helper.stream.listen(null);
      helper.pulse();
      let callCountOne = 0;
      subscription.onData(dart.fn(_ => {
        ++callCountOne;
      }, EventTovoid()));
      helper.pulse();
      src__matcher__expect.expect(callCountOne, 1);
      subscription.onData(null);
      helper.pulse();
      src__matcher__expect.expect(callCountOne, 1);
    }, VoidTodynamic()));
    let stream = new streams_test.StreamHelper().stream;
    unittest$.test('first', dart.fn(() => {
      stream.first.then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('asBroadcastStream', dart.fn(() => {
      stream.asBroadcastStream().listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('where', dart.fn(() => {
      stream.where(dart.fn(_ => true, EventTobool())).listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('map', dart.fn(() => {
      stream.map(dart.dynamic)(dart.fn(_ => null, EventTodynamic())).listen(dart.fn(_ => {
      }, dynamicTovoid()));
    }, VoidTodynamic()));
    unittest$.test('reduce', dart.fn(() => {
      stream.reduce(dart.fn((a, b) => null, EventAndEventToEvent())).then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('fold', dart.fn(() => {
      stream.fold(dart.dynamic)(null, dart.fn((a, b) => null, dynamicAndEventTodynamic())).then(dart.dynamic)(dart.fn(_ => {
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('contains', dart.fn(() => {
      stream.contains(dart.fn(_ => true, dynamicTobool())).then(dart.dynamic)(dart.fn(_ => {
      }, boolTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('every', dart.fn(() => {
      stream.every(dart.fn(_ => true, EventTobool())).then(dart.dynamic)(dart.fn(_ => {
      }, boolTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('any', dart.fn(() => {
      stream.any(dart.fn(_ => true, EventTobool())).then(dart.dynamic)(dart.fn(_ => {
      }, boolTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('length', dart.fn(() => {
      stream.length.then(dart.dynamic)(dart.fn(_ => {
      }, intTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('isEmpty', dart.fn(() => {
      stream.isEmpty.then(dart.dynamic)(dart.fn(_ => {
      }, boolTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('toList', dart.fn(() => {
      stream.toList().then(dart.dynamic)(dart.fn(_ => {
      }, ListOfEventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('toSet', dart.fn(() => {
      stream.toSet().then(dart.dynamic)(dart.fn(_ => {
      }, SetOfEventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('take', dart.fn(() => {
      stream.take(1).listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('takeWhile', dart.fn(() => {
      stream.takeWhile(dart.fn(_ => false, EventTobool())).listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('skip', dart.fn(() => {
      stream.skip(0).listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('skipWhile', dart.fn(() => {
      stream.skipWhile(dart.fn(_ => false, EventTobool())).listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('distinct', dart.fn(() => {
      stream.distinct(dart.fn((a, b) => false, EventAndEventTobool())).listen(dart.fn(_ => {
      }, EventTovoid()));
    }, VoidTodynamic()));
    unittest$.test('first', dart.fn(() => {
      stream.first.then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('last', dart.fn(() => {
      stream.last.then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('single', dart.fn(() => {
      stream.single.then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('firstWhere', dart.fn(() => {
      stream.firstWhere(dart.fn(_ => true, EventTobool())).then(dart.dynamic)(dart.fn(_ => {
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('lastWhere', dart.fn(() => {
      stream.lastWhere(dart.fn(_ => true, EventTobool())).then(dart.dynamic)(dart.fn(_ => {
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('singleWhere', dart.fn(() => {
      stream.singleWhere(dart.fn(_ => true, EventTobool())).then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('elementAt', dart.fn(() => {
      stream.elementAt(0).then(dart.dynamic)(dart.fn(_ => {
      }, EventTodynamic()));
    }, VoidTodynamic()));
  };
  dart.fn(streams_test.main, VoidTodynamic());
  // Exports:
  exports.streams_test = streams_test;
});
