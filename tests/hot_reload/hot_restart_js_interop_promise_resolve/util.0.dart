import 'dart:js_interop';

@JS()
external JSAny? eval(String script);

@JS()
external JSPromise createPromise();

@JS()
external void resolvePromise();

@JS()
external bool resolveCalled;

void injectJS() {
  eval('''
    self.resolveCalled = false;
    self.resolveFunction = null;
    self.createPromise = function(s) {
        let { promise, resolve, reject } = Promise.withResolvers();
        self.resolveFunction = function() {
            self.resolveCalled = true;
            resolve();
        };
        return promise;
    };
    self.resolvePromise = function() {
        self.resolveFunction();
    };
    ''');
}
