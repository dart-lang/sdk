import 'dart:js_interop';

@JS()
external JSAny? eval(String script);

@JS()
external JSPromise createPromise();

@JS()
external void rejectPromise();

@JS()
external bool rejectCalled;

void injectJS() {
  eval('''
    self.rejectCalled = false;
    self.rejectFunction = null;
    self.createPromise = function(s) {
        let { promise, resolve, reject } = Promise.withResolvers();
        self.rejectFunction = function() {
            self.rejectCalled = true;
            reject();
        };
        return promise;
    };
    self.rejectPromise = function() {
        self.rejectFunction();
    };
    ''');
}
