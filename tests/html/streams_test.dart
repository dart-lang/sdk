library streams_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:async';
import 'dart:html';

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
    _a.$dom_dispatchEvent(event);
  }
}

main() {
  useHtmlConfiguration();

  test('simple', () {
    var helper = new StreamHelper();

    var callCount = 0;
    helper.stream.listen((Event e) {
      ++callCount;
    });

    helper.pulse();
    expect(callCount, 1);
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

    Element.focusEvent.forTarget(helper.element, useCapture: true).listen(
        (Event e) {
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
