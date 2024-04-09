@JS()
library promise_reject_null_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' show promiseToFuture, NullRejectionException;

import 'package:async_helper/async_helper.dart';
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

@JS()
external void eval(String s);

@JS('Promise.reject')
external dynamic getRejectedPromise(v);

@JS()
external void reject(v);

@JS()
external dynamic getNewPromise();

void main() {
  asyncTest(() async {
    eval('''
      self.getNewPromise = function () {
        return new Promise(function (_, reject) {
          self.reject = reject;
        });
      };
    ''');

    // Rejected promise with a `null` value should trigger a
    // `NullRejectionException`.
    await promiseToFuture(getRejectedPromise(null)).then((_) {
      fail("Expected promise to reject and not fulfill.");
    }).catchError((e) {
      expect(e is NullRejectionException, true);
      expect(e.isUndefined, false);
    });

    // Similar to the above, except we reject using JS interop.
    var future = promiseToFuture(getNewPromise()).then((_) {
      fail("Expected promise to reject and not fulfill.");
    }).catchError((e) {
      expect(e is NullRejectionException, true);
      expect(e.isUndefined, false);
    });

    reject(null);

    await future;

    // It's also possible to reject with `undefined`. Make sure that the
    // exception correctly flags that case.
    future = promiseToFuture(getNewPromise()).then((_) {
      fail("Expected promise to reject and not fulfill.");
    }).catchError((e) {
      expect(e is NullRejectionException, true);
      expect(e.isUndefined, true);
    });

    eval('''
      self.reject(undefined);
    ''');

    await future;
  });
}
