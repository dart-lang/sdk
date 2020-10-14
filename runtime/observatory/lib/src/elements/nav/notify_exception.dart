// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/models.dart' show ConnectionException;

class ExceptionDeleteEvent {
  final dynamic exception;
  final StackTrace? stacktrace;

  ExceptionDeleteEvent(this.exception, {this.stacktrace});
}

class NavNotifyExceptionElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavNotifyExceptionElement> _r;

  Stream<RenderedEvent<NavNotifyExceptionElement>> get onRendered =>
      _r.onRendered;

  final StreamController<ExceptionDeleteEvent> _onDelete =
      new StreamController<ExceptionDeleteEvent>.broadcast();
  Stream<ExceptionDeleteEvent> get onDelete => _onDelete.stream;

  late dynamic _exception;
  StackTrace? _stacktrace;

  dynamic get exception => _exception;
  StackTrace? get stacktrace => _stacktrace;

  factory NavNotifyExceptionElement(dynamic exception,
      {StackTrace? stacktrace: null, RenderingQueue? queue}) {
    assert(exception != null);
    NavNotifyExceptionElement e = new NavNotifyExceptionElement.created();
    e._r = new RenderingScheduler<NavNotifyExceptionElement>(e, queue: queue);
    e._exception = exception;
    e._stacktrace = stacktrace;
    return e;
  }

  NavNotifyExceptionElement.created() : super.created('nav-exception');

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
    if (exception is ConnectionException) {
      renderConnectionException();
    } else {
      renderGenericException();
    }
  }

  void renderConnectionException() {
    children = <Element>[
      new DivElement()
        ..children = <Element>[
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
    List<Element> content;
    content = <Element>[
      new SpanElement()..text = 'Unexpected exception:',
      new BRElement(),
      new BRElement(),
      new DivElement()..text = exception.toString(),
      new BRElement()
    ];
    if (stacktrace != null) {
      content.addAll(<Element>[
        new SpanElement()..text = 'StackTrace:',
        new BRElement(),
        new BRElement(),
        new DivElement()..text = stacktrace.toString(),
        new BRElement()
      ]);
    }
    content.addAll(<Element>[
      new SpanElement()..text = '[',
      new AnchorElement(href: Uris.vmConnect())
        ..text = 'Connect to a different VM',
      new SpanElement()..text = ']',
      new ButtonElement()
        ..innerHtml = '&times;'
        ..onClick.map(_toEvent).listen(_delete)
    ]);
    children = <Element>[new DivElement()..children = content];
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
