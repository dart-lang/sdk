// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_ref_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('script-ref')
class ScriptRefElement extends ServiceRefElement {
  @published int pos = -1;

  String get hoverText {
    if (ref == null) {
      return super.hoverText;
    }
    return ref.vmName;
  }

  void posChanged(oldValue) {
    _updateProperties(null);
  }

  void _updateProperties(_) {
    if (ref != null && ref.loaded) {
      notifyPropertyChange(#name, 0, 1);
      notifyPropertyChange(#url, 0, 1);
    }
  }

  String get name {
    if (ref == null) {
      return super.name;
    }
    if (pos >= 0) {
      if (ref.loaded) {
        // Script is loaded, get the line number.
        Script script = ref;
        return '${super.name}:${script.tokenToLine(pos)}';
      } else {
        ref.load().then(_updateProperties);
      }
    }
    return super.name;
  }

  String get url {
    if (ref == null) {
      return super.url;
    }
    if (pos >= 0) {
      if (ref.loaded) {
        // Script is loaded, get the line number.
        Script script = ref;
        return '${super.url}#pos=${pos}';
      } else {
        ref.load().then(_updateProperties);
      }
    }
    return super.url;
  }

  ScriptRefElement.created() : super.created();
}
