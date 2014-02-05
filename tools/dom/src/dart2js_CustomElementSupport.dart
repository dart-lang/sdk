// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

_callConstructor(constructor, interceptor) {
  return (receiver) {
    setNativeSubclassDispatchRecord(receiver, interceptor);

    // Mirrors uses the constructor property to cache lookups, so we need it to
    // be set correctly, including on IE where it is not automatically picked
    // up from the __proto__.
    JS('', '#.constructor = #.__proto__.constructor', receiver, receiver);
    return JS('', '#(#)', constructor, receiver);
  };
}

_callEnteredView(receiver) {
  return receiver.enteredView();
}

_callLeftView(receiver) {
  return receiver.leftView();
}
 _callAttributeChanged(receiver, name, oldValue, newValue) {
  return receiver.attributeChanged(name, oldValue, newValue);
}

_makeCallbackMethod(callback) {
  return JS('',
      '''((function(invokeCallback) {
             return function() {
               return invokeCallback(this);
             };
          })(#))''',
      convertDartClosureToJS(callback, 1));
}

_makeCallbackMethod3(callback) {
  return JS('',
      '''((function(invokeCallback) {
             return function(arg1, arg2, arg3) {
               return invokeCallback(this, arg1, arg2, arg3);
             };
          })(#))''',
      convertDartClosureToJS(callback, 4));
}

void _registerCustomElement(context, document, String tag, Type type,
    String extendsTagName) {
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
  //    document.registerElement('x-foo', { prototype: proto });
  //    ...
  //    var e = document.createElement('x-foo');

  var interceptorClass = findInterceptorConstructorForType(type);
  if (interceptorClass == null) {
    throw new ArgumentError(type);
  }

  var interceptor = JS('=Object', '#.prototype', interceptorClass);

  var constructor = findConstructorForNativeSubclassType(type, 'created');
  if (constructor == null) {
    throw new ArgumentError("$type has no constructor called 'created'");
  }

  // Workaround for 13190- use an article element to ensure that HTMLElement's
  // interceptor is resolved correctly.
  getNativeInterceptor(new Element.tag('article'));

  String baseClassName = findDispatchTagForInterceptorClass(interceptorClass);
  if (baseClassName == null) {
    throw new ArgumentError(type);
  }

  if (extendsTagName == null) {
    if (baseClassName != 'HTMLElement') {
      throw new UnsupportedError('Class must provide extendsTag if base '
          'native class is not HTMLElement');
    }
  } else {
    if (!JS('bool', '(#.createElement(#) instanceof window[#])',
        document, extendsTagName, baseClassName)) {
      throw new UnsupportedError('extendsTag does not match base native class');
    }
  }

  var baseConstructor = JS('=Object', '#[#]', context, baseClassName);

  var properties = JS('=Object', '{}');

  JS('void', '#.createdCallback = #', properties,
      JS('=Object', '{value: #}',
          _makeCallbackMethod(_callConstructor(constructor, interceptor))));
  JS('void', '#.attachedCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callEnteredView)));
  JS('void', '#.detachedCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callLeftView)));
  JS('void', '#.attributeChangedCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod3(_callAttributeChanged)));

  var baseProto = JS('=Object', '#.prototype', baseConstructor);
  var proto = JS('=Object', 'Object.create(#, #)', baseProto, properties);

  setNativeSubclassDispatchRecord(proto, interceptor);

  var options = JS('=Object', '{prototype: #}', proto);

  if (extendsTagName != null) {
    JS('=Object', '#.extends = #', options, extendsTagName);
  }

  JS('void', '#.registerElement(#, #)', document, tag, options);
}

//// Called by Element.created to do validation & initialization.
void _initializeCustomElement(Element e) {
  // TODO(blois): Add validation that this is only in response to an upgrade.
}
