// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

_callCreated(receiver) {
  return receiver.createdCallback();
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

const _typeNameToTag = const {
  'HTMLAnchorElement': 'a',
  'HTMLAudioElement': 'audio',
  'HTMLButtonElement': 'button',
  'HTMLCanvasElement': 'canvas',
  'HTMLDivElement': 'div',
  'HTMLImageElement': 'img',
  'HTMLInputElement': 'input',
  'HTMLLIElement': 'li',
  'HTMLLabelElement': 'label',
  'HTMLMenuElement': 'menu',
  'HTMLMeterElement': 'meter',
  'HTMLOListElement': 'ol',
  'HTMLOptionElement': 'option',
  'HTMLOutputElement': 'output',
  'HTMLParagraphElement': 'p',
  'HTMLPreElement': 'pre',
  'HTMLProgressElement': 'progress',
  'HTMLSelectElement': 'select',
  'HTMLSpanElement': 'span',
  'HTMLUListElement': 'ul',
  'HTMLVideoElement': 'video',
};

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
  //    document.register('x-foo', { prototype: proto });
  //    ...
  //    var e = document.createElement('x-foo');

  var interceptorClass = findInterceptorConstructorForType(type);
  if (interceptorClass == null) {
    throw new ArgumentError(type);
  }

  // Workaround for 13190- use an article element to ensure that HTMLElement's
  // interceptor is resolved correctly.
  getNativeInterceptor(new Element.tag('article'));

  String baseClassName = findDispatchTagForInterceptorClass(interceptorClass);
  if (baseClassName == null) {
    throw new ArgumentError(type);
  }
  if (baseClassName == 'Element') baseClassName = 'HTMLElement';

  var baseConstructor = JS('=Object', '#[#]', context, baseClassName);

  var properties = JS('=Object', '{}');

  JS('void', '#.createdCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callCreated)));
  JS('void', '#.enteredViewCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callEnteredView)));
  JS('void', '#.leftViewCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callLeftView)));
  JS('void', '#.attributeChangedCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod3(_callAttributeChanged)));

  // TODO(blois): Bug 13220- remove once transition is complete
  JS('void', '#.enteredDocumentCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callEnteredView)));
  JS('void', '#.leftDocumentCallback = #', properties,
      JS('=Object', '{value: #}', _makeCallbackMethod(_callLeftView)));

  var baseProto = JS('=Object', '#.prototype', baseConstructor);
  var proto = JS('=Object', 'Object.create(#, #)', baseProto, properties);

  var interceptor = JS('=Object', '#.prototype', interceptorClass);

  setNativeSubclassDispatchRecord(proto, interceptor);

  var options = JS('=Object', '{prototype: #}', proto);

  if (baseClassName != 'HTMLElement') {
    if (extendsTagName != null) {
      JS('=Object', '#.extends = #', options, extendsTagName);
    } else if (_typeNameToTag.containsKey(baseClassName)) {
      JS('=Object', '#.extends = #', options, _typeNameToTag[baseClassName]);
    }
  }

  JS('void', '#.register(#, #)', document, tag, options);
}

//// Called by Element.created to do validation & initialization.
void _initializeCustomElement(Element e) {
  // TODO(blois): Add validation that this is only in response to an upgrade.
}
