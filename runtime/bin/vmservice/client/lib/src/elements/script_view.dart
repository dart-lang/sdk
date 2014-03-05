// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_view_element;

import 'dart:html';
import 'isolate_element.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

/// Displays an Error response.
@CustomTag('script-view')
class ScriptViewElement extends IsolateElement {
  @published Script script;

  ScriptViewElement.created() : super.created();

  String hitsStyle(ScriptLine line) {
    if (line.hits == -1) {
      return 'min-width:32px;';
    } else if (line.hits == 0) {
      return 'min-width:32px;background-color:red';
    }
    return 'min-width:32px;background-color:green';
  }

  void refreshCoverage(Event e, var detail, Node target) {
    isolate.getMap('coverage').then((Map coverage) {
      assert(coverage['type'] == 'CodeCoverage');
      isolate.updateCoverage(coverage['coverage']);
      notifyPropertyChange(#hitsStyle, "", hitsStyle);
    }).catchError((e, st) {
      print('refreshCoverage $e $st');
    });
  }


}
