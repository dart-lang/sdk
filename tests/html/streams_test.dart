library streams_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:async';
import 'dart:html';

class StreamHelper {
  var _a;
  var _b;
  StreamHelper() {
    _a = new TextInputElement();
    document.body.append(_a);
    _b = new TextInputElement();
    document.body.append(_b);
  }

  Stream<Event> get stream => _a.onFocus;

  // Causes an event on a to be fired.
  void pulse() {
    _b.focus();
    _a.focus();
  }
}

main() {
  useHtmlConfiguration();

  test('simple', () {
    var a = new TextInputElement();
    document.body.append(a);

    var callCount = 0;
    a.onFocus.listen((Event e) {
      ++callCount;
    });

    a.focus();
    expect(callCount, 1);
  });

  // Validates that capturing events fire on parent before child.
  test('capture', () {
    var parent = new DivElement();
    document.body.append(parent);

    var child = new TextInputElement();
    parent.append(child);

    var childCallCount = 0;
    var parentCallCount = 0;
    Element.focusEvent.forTarget(parent, useCapture: true).listen((Event e) {
      ++parentCallCount;
      expect(childCallCount, 0);
    });

    Element.focusEvent.forTarget(child, useCapture: true).listen((Event e) {
      ++childCallCount;
      expect(parentCallCount, 1);
    });

    child.focus();
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

    expect(() {
      subscription.pause();
    }, throws);

    expect(() {
      subscription.resume();
    }, throws);
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

    var completer = new Completer<int>();
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

    // Not paused.
    expect(() {
      subscription.resume();
    }, throws);
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
}
