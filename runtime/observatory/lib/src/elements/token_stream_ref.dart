// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, TokenStreamRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class TokenStreamRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<TokenStreamRefElement>('token-stream-ref');

  RenderingScheduler<TokenStreamRefElement> _r;

  Stream<RenderedEvent<TokenStreamRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.TokenStreamRef _token;

  M.IsolateRef get isolate => _isolate;
  M.TokenStreamRef get token => _token;

  factory TokenStreamRefElement(M.IsolateRef isolate, M.TokenStreamRef token,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(token != null);
    TokenStreamRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._token = token;
    return e;
  }

  TokenStreamRefElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    final text = (_token.name == null || _token.name == '')
        ? 'TokenStream'
        : _token.name;
    children = [
      new AnchorElement(href: Uris.inspect(_isolate, object: _token))
        ..text = text
    ];
  }
}
