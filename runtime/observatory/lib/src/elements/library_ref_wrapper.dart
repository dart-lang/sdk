// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart' show Library;
import 'package:observatory/src/elements/library_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class LibraryRefElementWrapper extends HtmlElement {

  static const binder = const Binder<LibraryRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<LibraryRefElementWrapper>('library-ref');

  Library _library;
  Library get ref => _library;
  void set ref(Library ref) { _library = ref; render(); }

  LibraryRefElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  void render() {
    shadowRoot.children = [];
    if (ref == null) return;

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        library-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        library-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new LibraryRefElement(_library.isolate, _library,
          queue: ObservatoryApplication.app.queue)
    ];
  }
}
