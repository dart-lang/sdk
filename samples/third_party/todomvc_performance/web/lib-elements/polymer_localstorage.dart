// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
library todomvc.web.lib_elements.polymer_localstorage;

import 'dart:convert' show JSON;
import 'dart:html';
import 'package:polymer/polymer.dart';

// TODO(jmesserly): replace with interop to <polymer-localstorage>.
@CustomTag('polymer-localstorage')
class PolymerLocalStorage extends PolymerElement {
  @published String name;
  @published var value;
  @published bool useRaw = false;

  factory PolymerLocalStorage() => new Element.tag('polymer-localstorage');
  PolymerLocalStorage.created() : super.created();

  void ready() {
    load();
  }

  void valueChanged() {
    save();
  }

  void load() {
    var s = window.localStorage[name];
    if (s != null && !useRaw) {
      value = JSON.decode(s);
    } else {
      value = s;
    }
  }

  void save() {
    window.localStorage[name] = useRaw ? value : JSON.encode(value);
  }
}
