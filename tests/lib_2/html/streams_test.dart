import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

class StreamHelper {
  var _a;
  StreamHelper() {
    _a = new TextInputElement();
    document.body.append(_a);
  }

  Element get element => _a;
  Stream<Event> get stream => _a.onFocus;

  // Causes an event on a to be fired.
  void pulse() {
    var event = new Event('focus');
    _a.dispatchEvent(event);
  }
}

main() {
  test('simple', () {
    var helper = new StreamHelper();

    var callCount = 0;
    helper.stream.listen((Event e) {
      ++callCount;
    });

    helper.pulse();
    expect(callCount, 1);
  });

  test('broadcast', () {
    var stream = new DivElement().onClick;
    expect(stream.asBroadcastStream(), stream);
    expect(stream.isBroadcast, isTrue);
  });

  // Validates that capturing events fire on parent before child.
  test('capture', () {
    var parent = new DivElement();
    document.body.append(parent);

    var helper = new StreamHelper();
    parent.append(helper.element);

    var childCallCount = 0;
    var parentCallCount = 0;
    Element.focusEvent.forTarget(parent, useCapture: true).listen((Event e) {
      ++parentCallCount;
      expect(childCallCount, 0);
    });

    Element.focusEvent
        .forTarget(helper.element, useCapture: true)
        .listen((Event e) {
      ++childCallCount;
      expect(parentCallCount, 1);
    });

    helper.pulse();
    expect(childCallCount, 1);
    expect(parentCallCount, 1);
  });

  test('cancel', () {
    var helper = new StreamHelper();

    var callCount = 0;
    var subscription = helper.stream.listen((_) {
      ++callCount;
    });

    helper.pulse();
    expect(callCount, 1);

    subscription.cancel();
    helper.pulse();
    expect(callCount, 1);

    expect(() {
      subscription.onData((_) {});
    }, throws);

    // Calling these after a cancel does nothing.
    subscription.cancel();
    subscription.pause();
    subscription.resume();
  });

  test('pause/resume', () {
    var helper = new StreamHelper();

    var callCount = 0;
    var subscription = helper.stream.listen((_) {
      ++callCount;
    });

    helper.pulse();
    expect(callCount, 1);

    subscription.pause();
    helper.pulse();
    expect(callCount, 1);

    subscription.resume();
    helper.pulse();
    expect(callCount, 2);

    var completer = new Completer<int>.sync();
    subscription.pause(completer.future);
    helper.pulse();
    expect(callCount, 2);

    // Paused, should have no impact.
    subscription.pause();
    helper.pulse();
    subscription.resume();
    helper.pulse();
    expect(callCount, 2);

    completer.complete(0);
    helper.pulse();
    expect(callCount, 3);

    // Not paused, but resuming once too often is ok.
    subscription.resume();
  });

  test('onData', () {
    var helper = new StreamHelper();

    var callCountOne = 0;
    var subscription = helper.stream.listen((_) {
      ++callCountOne;
    });

    helper.pulse();
    expect(callCountOne, 1);

    var callCountTwo = 0;
    subscription.onData((_) {
      ++callCountTwo;
    });

    helper.pulse();
    expect(callCountOne, 1);
    expect(callCountTwo, 1);
  });

  test('null onData', () {
    var helper = new StreamHelper();

    var subscription = helper.stream.listen(null);
    helper.pulse();

    var callCountOne = 0;
    subscription.onData((_) {
      ++callCountOne;
    });
    helper.pulse();
    expect(callCountOne, 1);

    subscription.onData(null);
    helper.pulse();
    expect(callCountOne, 1);
  });

  var stream = new StreamHelper().stream;
  // Streams have had some type-checking issues, these tests just validate that
  // those are OK.
  test('first', () {
    stream.first.then((_) {});
  });

  test('asBroadcastStream', () {
    stream.asBroadcastStream().listen((_) {});
  });

  test('where', () {
    stream.where((_) => true).listen((_) {});
  });

  test('map', () {
    stream.map((_) => null).listen((_) {});
  });

  test('reduce', () {
    stream.reduce((a, b) => null).then((_) {});
  });

  test('fold', () {
    stream.fold(null, (a, b) => null).then((_) {});
  });

  test('contains', () {
    stream.contains((_) => true).then((_) {});
  });

  test('every', () {
    stream.every((_) => true).then((_) {});
  });

  test('any', () {
    stream.any((_) => true).then((_) {});
  });

  test('length', () {
    stream.length.then((_) {});
  });

  test('isEmpty', () {
    stream.isEmpty.then((_) {});
  });

  test('toList', () {
    stream.toList().then((_) {});
  });

  test('toSet', () {
    stream.toSet().then((_) {});
  });

  test('take', () {
    stream.take(1).listen((_) {});
  });

  test('takeWhile', () {
    stream.takeWhile((_) => false).listen((_) {});
  });

  test('skip', () {
    stream.skip(0).listen((_) {});
  });

  test('skipWhile', () {
    stream.skipWhile((_) => false).listen((_) {});
  });

  test('distinct', () {
    stream.distinct((a, b) => false).listen((_) {});
  });

  test('first', () {
    stream.first.then((_) {});
  });

  test('last', () {
    stream.last.then((_) {});
  });

  test('single', () {
    stream.single.then((_) {});
  });

  test('firstWhere', () {
    stream.firstWhere((_) => true).then((_) {});
  });

  test('lastWhere', () {
    stream.lastWhere((_) => true).then((_) {});
  });

  test('singleWhere', () {
    stream.singleWhere((_) => true).then((_) {});
  });

  test('elementAt', () {
    stream.elementAt(0).then((_) {});
  });
}
