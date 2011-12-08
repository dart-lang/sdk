// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DocumentEvents extends ElementEvents {
  EventListenerList get readyStateChange();
  EventListenerList get selectionChange();
  EventListenerList get contentLoaded();
}

// TODO(jacobr): add DocumentFragment ctor
// add something smarted for document.domain
interface Document extends Element /*, common.NodeSelector */ {

  // TODO(jacobr): remove.
  Event createEvent(String eventType);

  Element get activeElement();

  // TODO(jacobr): add
  // Map<String, Class> tags;

  Element get body();

  void set body(Element value);

  String get charset();

  void set charset(String value);

  // FIXME(slightlyoff): FIX COOKIES, MMM...COOKIES. ME WANT COOKIES!!
  //                     Map<String, CookieList> cookies
  //                     Map<String, Cookie> CookieList
  String get cookie();

  void set cookie(String value);

  Window get window();

  String get domain();

  HeadElement get head();

  String get lastModified();

  // TODO(jacobr): remove once on.contentLoaded is changed to return a Future.
  String get readyState();

  String get referrer();

  StyleSheetList get styleSheets();

  // TODO(jacobr): should this be removed? Users could write document.query("title").text instead.
  String get title();

  void set title(String value);

  bool get webkitHidden();

  String get webkitVisibilityState();

  Future<Range> caretRangeFromPoint([int x, int y]);

  Future<Element> elementFromPoint([int x, int y]);

  bool execCommand([String command, bool userInterface, String value]);

  // TODO(jacobr): remove once a new API is specified
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name,
                                             int width, int height);

  bool queryCommandEnabled([String command]);

  bool queryCommandIndeterm([String command]);

  bool queryCommandState([String command]);

  bool queryCommandSupported([String command]);

  String queryCommandValue([String command]);

  String get manifest();

  void set manifest(String value);

  DocumentEvents get on();

  Future<ElementRect> get rect();
}
