// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

/// Checks whether the given [element] correctly extends from the native class
/// with the given [baseClassName]. This method will throw if the base class
/// doesn't match, except when the element extends from `template` and it's base
/// class is `HTMLUnknownElement`. This exclusion is needed to support extension
/// of template elements (used heavily in Polymer 1.0) on IE11 when using the
/// webcomponents-lite.js polyfill.
void _checkExtendsNativeClassOrTemplate(
    Element element, String extendsTag, String baseClassName) {
  if (!JS('bool', '(# instanceof window[#])', element, baseClassName) &&
      !((extendsTag == 'template' &&
          JS('bool', '(# instanceof window["HTMLUnknownElement"])',
              element)))) {
    throw new UnsupportedError('extendsTag does not match base native class');
  }
}

/// Dart2JS implementation of ElementUpgrader
class _JSElementUpgrader implements ElementUpgrader {
  var _interceptor;
  var _constructor;
  var _nativeType;

  _JSElementUpgrader(Document document, Type type, String? extendsTag) {
    var interceptorClass = findInterceptorConstructorForType(type);
    if (interceptorClass == null) {
      throw new ArgumentError(type);
    }

    _constructor = findConstructorForNativeSubclassType(type, 'created');
    if (_constructor == null) {
      throw new ArgumentError("$type has no constructor called 'created'");
    }

    // Workaround for 13190- use an article element to ensure that HTMLElement's
    // interceptor is resolved correctly.
    getNativeInterceptor(new Element.tag('article'));

    var baseClassName = findDispatchTagForInterceptorClass(interceptorClass);
    if (baseClassName == null) {
      throw new ArgumentError(type);
    }

    if (extendsTag == null) {
      if (baseClassName != 'HTMLElement') {
        throw new UnsupportedError('Class must provide extendsTag if base '
            'native class is not HtmlElement');
      }
      _nativeType = HtmlElement;
    } else {
      var element = document.createElement(extendsTag);
      _checkExtendsNativeClassOrTemplate(element, extendsTag, baseClassName);
      _nativeType = element.runtimeType;
    }

    _interceptor = JS('=Object', '#.prototype', interceptorClass);
  }

  Element upgrade(Element element) {
    // Only exact type matches are supported- cannot be a subclass.
    if (element.runtimeType != _nativeType) {
      // Some browsers may represent non-upgraded elements <x-foo> as
      // UnknownElement and not a plain HtmlElement.
      if (_nativeType != HtmlElement || element.runtimeType != UnknownElement) {
        throw new ArgumentError('element is not subclass of $_nativeType');
      }
    }

    setNativeSubclassDispatchRecord(element, _interceptor);
    JS('', '#(#)', _constructor, element);
    return element;
  }
}
