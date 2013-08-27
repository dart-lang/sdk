// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

_callCreated(receiver) {
  return receiver.created();
}

_makeCreatedCallbackMethod() {
  return JS('',
      '''((function(invokeCallback) {
             return function() {
               return invokeCallback(this);
             };
          })(#))''',
      convertDartClosureToJS(_callCreated, 1));
}

void _registerCustomElement(context, document, String tag, Type type) {
  // Function follows the same pattern as the following JavaScript code for
  // registering a custom element.
  //
  //    var proto = Object.create(HTMLElement.prototype, {
  //        createdCallback: {
  //          value: function() {
  //            window.console.log('here');
  //          }
  //        }
  //    });
  //    document.register('x-foo', { prototype: proto });
  //    ...
  //    var e = document.createElement('x-foo');

  var interceptorClass = findInterceptorConstructorForType(type);
  if (interceptorClass == null) {
    throw new ArgumentError(type);
  }

  String baseClassName = findDispatchTagForInterceptorClass(interceptorClass);
  if (baseClassName == null) {
    throw new ArgumentError(type);
  }
  if (baseClassName == 'Element') baseClassName = 'HTMLElement';

  var baseConstructor = JS('=Object', '#[#]', context, baseClassName);

  var properties = JS('=Object', '{}');

  var jsCreatedCallback = _makeCreatedCallbackMethod();

  JS('void', '#.createdCallback = #', properties,
      JS('=Object', '{value: #}', jsCreatedCallback));

  var baseProto = JS('=Object', '#.prototype', baseConstructor);
  var proto = JS('=Object', 'Object.create(#, #)', baseProto, properties);

  var interceptor = JS('=Object', '#.prototype', interceptorClass);

  setNativeSubclassDispatchRecord(proto, interceptor);

  JS('void', '#.register(#, #)',
      document, tag, JS('', '{prototype: #}', proto));
}
