// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class TypeArgumentsRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<TypeArgumentsRefElement> _r;

  Stream<RenderedEvent<TypeArgumentsRefElement>> get onRendered =>
      _r.onRendered;

  late M.IsolateRef _isolate;
  late M.TypeArgumentsRef _arguments;

  M.IsolateRef get isolate => _isolate;
  M.TypeArgumentsRef get arguments => _arguments;

  factory TypeArgumentsRefElement(
    M.IsolateRef isolate,
    M.TypeArgumentsRef args, {
    RenderingQueue? queue,
  }) {
    TypeArgumentsRefElement e = new TypeArgumentsRefElement.created();
    e._r = new RenderingScheduler<TypeArgumentsRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._arguments = args;
    return e;
  }

  TypeArgumentsRefElement.created() : super.created('type-arguments-ref');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    final text = (_arguments.name == null || _arguments.name == '')
        ? 'TypeArguments'
        : _arguments.name;
    children = <HTMLElement>[
      new HTMLAnchorElement()
        ..href = Uris.inspect(_isolate, object: _arguments)
        ..text = text ?? '',
    ];
  }
}
