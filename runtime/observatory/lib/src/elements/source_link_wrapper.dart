// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/repositories.dart' show ScriptRepository;
import 'package:observatory/service_html.dart' show SourceLocation;
import 'package:observatory/src/elements/source_link.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class SourceLinkElementWrapper extends HtmlElement {
  static const binder = const Binder<SourceLinkElementWrapper>(const {
      'location' : #location
    });

  static const tag = const Tag<SourceLinkElementWrapper>('source-link');

  SourceLocation _location;
  SourceLocation get location => location;
  set location(SourceLocation location) { _location = location; render(); }

  SourceLinkElementWrapper.created() : super.created() {
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
    if (_location == null) return;

    ScriptRepository repository = new ScriptRepository(_location.isolate);

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        source-link-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        source-link-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new SourceLinkElement(_location.isolate, _location, repository,
                            queue: ObservatoryApplication.app.queue)
    ];
  }
}
