// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:html';
import 'dart:js';
import 'dart:mirrors';
import 'package:js/js.dart';
import 'package:js_util/js_util.dart';
import 'package:polymer/polymer.dart';

class Binding {
  final String attribute;
  final String property;
  const Binding (attribute, [String property])
      : attribute = attribute,
        property = property == null ? attribute : property;
}

///This is a temporary bridge between Polymer Bindings and the wrapper entities.
class Binder<T extends HtmlElement> {
  final List<Binding> attributes;
  final callback;

  Binder(List<Binding> attributes)
      : attributes = attributes,
        callback = _createCallback(T, attributes);

  registerCallback(T element) {
    assert(element != null);
    setValue(element, 'bind', callback);
  }

  static _createCallback(Type T, List<Binding> attributes){
    final target = reflectClass(T);
    final setters = <String, Symbol>{};
    for (Binding binding in attributes){
      var member = target.instanceMembers[new Symbol(binding.property + '=')];
      if (!member.isSetter)
        throw new ArgumentError(
          '${binding.property} is not a Setter for class $T');
      setters[binding.attribute] = new Symbol(binding.property);
    }
    return allowInteropCaptureThis((_this, name, value, [other]) {
      final setter = setters[name];
      if (setter == null) return;
      Bindable bindable;
      if (identical(1, 1.0)) { // dart2js
        bindable = getValue(getValue(value, '__dartBindable'), 'o') as Bindable;
      } else { // vm
        bindable = getValue(value, '__dartBindable');
      }
      var obj = reflect(_this);
      obj.setField(setter, bindable.value);
      bindable.open((value) {
        obj.setField(setter, value);
      });
    });
  }
}
