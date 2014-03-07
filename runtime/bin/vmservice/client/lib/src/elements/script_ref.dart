// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_ref_element;

import 'package:polymer/polymer.dart';
import 'service_ref.dart';

@CustomTag('script-ref')
class ScriptRefElement extends ServiceRefElement {
  @published int line = -1;

  String get objectId {
    if (line < 0) {
      return super.objectId;
    }
    // TODO(johnmccutchan): Add a ?line=XX invalidates the idea that this
    // method returns an objectId.
    return '${super.objectId}?line=$line';
  }

  String get hoverText {
    if (ref == null) {
      return '';
    }
    if (line < 0) {
      return ref['user_name'];
    } else {
      return "${ref['user_name']}:$line";
    }
  }

  String get name {
    if (ref == null) {
      return '';
    }
    var scriptUrl = ref['user_name'];
    var shortScriptUrl = scriptUrl.substring(scriptUrl.lastIndexOf('/') + 1);
    if (line < 0) {
      return shortScriptUrl;
    } else {
      return "$shortScriptUrl:$line";
    }
  }

  ScriptRefElement.created() : super.created();
}
