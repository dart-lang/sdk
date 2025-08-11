// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_ref_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M show IsolateRef, ScriptRef;
import 'helpers/custom_element.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class ScriptRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<ScriptRefElement> _r;

  Stream<RenderedEvent<ScriptRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ScriptRef _script;

  M.IsolateRef get isolate => _isolate;
  M.ScriptRef get script => _script;

  factory ScriptRefElement(
    M.IsolateRef isolate,
    M.ScriptRef script, {
    RenderingQueue? queue,
  }) {
    ScriptRefElement e = new ScriptRefElement.created();
    e._r = new RenderingScheduler<ScriptRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._script = script;
    return e;
  }

  ScriptRefElement.created() : super.created('script-ref');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    var displayUri = script.uri!.split('/').last;
    if (displayUri.isEmpty) {
      displayUri = 'N/A';
    }

    children = <HTMLElement>[
      new HTMLAnchorElement()
        ..href = Uris.inspect(isolate, object: script)
        ..title = script.uri!
        ..text = displayUri,
    ];
  }
}
