// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_ref_element;

import 'package:polymer/polymer.dart';
import 'service_ref.dart';

@CustomTag('script-ref')
class ScriptRefElement extends ServiceRefElement {
  @published int line = -1;

  String get hoverText {
    if (ref == null) {
      return super.hoverText;
    }
    if (line < 0) {
      return ref.vmName;
    } else {
      return '${ref.vmName}:$line';
    }
  }

  String get name {
    if (ref == null) {
      return super.name;
    }
    if (line < 0) {
      return ref.name;
    } else {
      return '${ref.name}:$line';
    }
  }

  ScriptRefElement.created() : super.created();
}
