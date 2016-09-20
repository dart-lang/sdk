// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/models.dart' show ConnectionException;

class ExceptionDeleteEvent {
  final Exception exception;
  final StackTrace stacktrace;

  ExceptionDeleteEvent(this.exception, {this.stacktrace});
}

class NavNotifyExceptionElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavNotifyExceptionElement>('nav-exception');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavNotifyExceptionElement>> get onRendered =>
      _r.onRendered;

  final StreamController<ExceptionDeleteEvent> _onDelete =
      new StreamController<ExceptionDeleteEvent>.broadcast();
  Stream<ExceptionDeleteEvent> get onDelete => _onDelete.stream;

  Exception _exception;
  StackTrace _stacktrace;

  Exception get exception => _exception;
  StackTrace get stacktrace => _stacktrace;

  factory NavNotifyExceptionElement(Exception exception,
      {StackTrace stacktrace: null, RenderingQueue queue}) {
    assert(exception != null);
    NavNotifyExceptionElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._exception = exception;
    e._stacktrace = stacktrace;
    return e;
  }

  NavNotifyExceptionElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    if (exception is ConnectionException) {
      renderConnectionException();
    } else {
      renderGenericException();
    }
  }

  void renderConnectionException() {
    children = [
      new DivElement()
        ..children = [
          new SpanElement()
            ..text = 'The request cannot be completed because the '
                'VM is currently disconnected',
          new BRElement(),
          new BRElement(),
          new SpanElement()..text = '[',
          new AnchorElement(href: Uris.vmConnect())
            ..text = 'Connect to a different VM',
          new SpanElement()..text = ']',
          new ButtonElement()
            ..innerHtml = '&times;'
            ..onClick.map(_toEvent).listen(_delete)
        ]
    ];
  }

  void renderGenericException() {
    List<Node> content;
    content = [
      new SpanElement()..text = 'Unexpected exception:',
      new BRElement(),
      new BRElement(),
      new DivElement()..text = exception.toString(),
      new BRElement()
    ];
    if (stacktrace != null) {
      content.addAll([
        new SpanElement()..text = 'Stacktrace:',
        new BRElement(),
        new BRElement(),
        new DivElement()..text = stacktrace.toString(),
        new BRElement()
      ]);
    }
    content.addAll([
      new SpanElement()..text = '[',
      new AnchorElement(href: Uris.vmConnect())
        ..text = 'Connect to a different VM',
      new SpanElement()..text = ']',
      new ButtonElement()
        ..innerHtml = '&times;'
        ..onClick.map(_toEvent).listen(_delete)
    ]);
    children = [new DivElement()..children = content];
  }

  ExceptionDeleteEvent _toEvent(_) {
    return new ExceptionDeleteEvent(exception, stacktrace: stacktrace);
  }

  void _delete(ExceptionDeleteEvent e) {
    _onDelete.add(e);
  }

  void delete() {
    _onDelete.add(new ExceptionDeleteEvent(exception, stacktrace: stacktrace));
  }
}
