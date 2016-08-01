// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart' show Script;
import 'package:observatory/src/elements/script_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class ScriptRefElementWrapper extends HtmlElement {
  static const binder = const Binder<ScriptRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<ScriptRefElementWrapper>('script-ref');

  Script _script;
  Script get ref => _script;
  set ref(Script script) { _script = script; render(); }

  ScriptRefElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  Future render() async {
    shadowRoot.children = [];
    if (_script == null) return;

    shadowRoot.children = [
      new StyleElement()
        ..text = '@import "packages/observatory/src/elements/css/shared.css";',
      new ScriptRefElement(_script.isolate, _script,
                                 queue: ObservatoryApplication.app.queue)
    ];
  }
}
