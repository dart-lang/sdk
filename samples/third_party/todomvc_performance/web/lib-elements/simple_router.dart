// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
library todomvc.web.lib_elements.simple_router;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';

// A very simple router for TodoMVC. Real app should use package:route, but it
// does not currently support Shadow DOM.
@CustomTag('simple-router')
class SimpleRouter extends PolymerElement {
  @published String route = '';

  StreamSubscription _sub;

  factory SimpleRouter() => new Element.tag('simple-router');
  SimpleRouter.created() : super.created();

  attached() {
    super.attached();
    _sub = windowLocation.changes.listen((_) {
      var hash = window.location.hash;
      if (hash.startsWith('#/')) hash = hash.substring(2);
      // TODO(jmesserly): empty string is not triggering a call to TodoList
      // routeChanged after deployment. Use 'all' as a workaround.
      if (hash == '') hash = 'all';
      route = hash;
    });
  }

  detached() {
    super.detached();
    _sub.cancel();
  }

  routeChanged() {
    fire('route', detail: route);
  }
}
