// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library view_footer_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';

class ViewFooterElement extends CustomElement implements Renderable {
  RenderingScheduler<ViewFooterElement> _r;

  Stream<RenderedEvent<ViewFooterElement>> get onRendered => _r.onRendered;

  factory ViewFooterElement({RenderingQueue queue}) {
    ViewFooterElement e = new ViewFooterElement.created();
    e._r = new RenderingScheduler<ViewFooterElement>(e, queue: queue);
    return e;
  }

  ViewFooterElement.created() : super.created('view-footer');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    children = <Element>[
      new AnchorElement()
        ..href = 'https://dart-lang.github.io/observatory/'
        ..text = 'View documentation',
      new AnchorElement()
        ..href =
            'https://github.com/dart-lang/sdk/issues/new?title=Observatory:&amp;body=Observatory%20Feedback'
        ..text = 'File a bug report'
    ];
  }
}
