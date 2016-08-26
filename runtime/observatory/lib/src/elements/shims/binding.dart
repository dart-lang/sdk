// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:html';
import 'dart:js';
@MirrorsUsed(metaTargets: const [BindableAnnotation])
import 'dart:mirrors';
import 'package:js/js.dart';
import 'package:js_util/js_util.dart';
import 'package:polymer/polymer.dart';

const BindableAnnotation bindable = const BindableAnnotation();
class BindableAnnotation {
  const BindableAnnotation();
}


///This is a temporary bridge between Polymer Bindings and the wrapper entities.
class Binder<T extends HtmlElement> {
  final Map<String, Symbol> attributes;

  const Binder(Map<String, Symbol> attributes)
      : attributes = attributes;

  registerCallback(T element) {
    assert(element != null);
    setValue(element, 'bind', allowInteropCaptureThis(_callback));
  }

  void _callback(_this, name, value, [other]) {
    final setter = attributes[name];
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
  }
}
