// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

typedef HtmlElement VirtualCollectionCreateCallback();
typedef List<HtmlElement> VirtualCollectionHeaderCallback();
typedef void VirtualCollectionUpdateCallback(
    HtmlElement el, dynamic item, int index);

class VirtualCollectionElement extends HtmlElement implements Renderable {
  static const tag = const Tag<VirtualCollectionElement>('virtual-collection');

  RenderingScheduler<VirtualCollectionElement> _r;

  Stream<RenderedEvent<VirtualCollectionElement>> get onRendered =>
      _r.onRendered;

  VirtualCollectionCreateCallback _create;
  VirtualCollectionHeaderCallback _createHeader;
  VirtualCollectionUpdateCallback _update;
  double _itemHeight;
  double _headerHeight = 0.0;
  int _top;
  double _height;
  List _items;
  StreamSubscription _onScrollSubscription;
  StreamSubscription _onResizeSubscription;

  List get items => _items;

  set items(Iterable value) {
    _items = new List.unmodifiable(value);
    _top = null;
    _r.dirty();
  }

  factory VirtualCollectionElement(VirtualCollectionCreateCallback create,
      VirtualCollectionUpdateCallback update,
      {Iterable items: const [],
      VirtualCollectionHeaderCallback createHeader,
      RenderingQueue queue}) {
    assert(create != null);
    assert(update != null);
    assert(items != null);
    VirtualCollectionElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._create = create;
    e._createHeader = createHeader;
    e._update = update;
    e._items = new List.unmodifiable(items);
    return e;
  }

  VirtualCollectionElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _top = null;
    _itemHeight = null;
    _onScrollSubscription = onScroll.listen(_onScroll);
    _onResizeSubscription = window.onResize.listen(_onResize);
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = const [];
    _onScrollSubscription.cancel();
    _onResizeSubscription.cancel();
  }

  final DivElement _header = new DivElement()..classes = ['header'];
  final DivElement _scroller = new DivElement()..classes = ['scroller'];
  final DivElement _shifter = new DivElement()..classes = ['shifter'];
  final DivElement _container = new DivElement()..classes = ['container'];

  dynamic getItemFromElement(HtmlElement element) {
    final el_index = _container.children.indexOf(element);
    if (el_index < 0) {
      return null;
    }
    final item_index = _top +
        el_index -
        (_container.children.length * _inverse_preload).floor();
    if (0 <= item_index && item_index < items.length) {
      return _items[item_index];
    }
    return null;
  }

  /// The preloaded element before and after the visible area are:
  /// 1/preload_size of the number of items in the visble area.
  /// See shared.css for the "top:-25%;".
  static const int _preload = 2;

  /// L = length of all the elements loaded
  /// l = length of the visible area
  ///
  /// L = l + 2 * l / _preload
  /// l = L * _preload / (_preload + 2)
  ///
  /// tail = l / _preload = L * 1 / (_preload + 2) = L * _inverse_preload
  static const double _inverse_preload = 1 / (_preload + 2);

  var _takeIntoView;

  void takeIntoView(item) {
    _takeIntoView = item;
    _r.dirty();
  }

  void render() {
    if (children.isEmpty) {
      children = [
        _scroller
          ..children = [
            _shifter
              ..children = [
                _container..children = [_create()]
              ]
          ],
      ];
      if (_createHeader != null) {
        _header.children = [
          new DivElement()
            ..classes = ['container']
            ..children = _createHeader()
        ];
        _scroller.children.insert(0, _header);
        _headerHeight = _header.children[0].getBoundingClientRect().height;
      }
      _itemHeight = _container.children[0].getBoundingClientRect().height;
      _height = getBoundingClientRect().height;
    }

    if (_takeIntoView != null) {
      final index = items.indexOf(_takeIntoView);
      if (index >= 0) {
        final minScrollTop = _itemHeight * (index + 1) - _height;
        final maxScrollTop = _itemHeight * index;
        scrollTop = ((maxScrollTop - minScrollTop) / 2 + minScrollTop).floor();
      }
      _takeIntoView = null;
    }

    final top = (scrollTop / _itemHeight).floor();

    _updateHeader();
    _scroller.style.height = '${_itemHeight*(_items.length)+_headerHeight}px';
    final tail_length = (_height / _itemHeight / _preload).ceil();
    final length = tail_length * 2 + tail_length * _preload;

    if (_container.children.length < length) {
      while (_container.children.length != length) {
        var e = _create();
        e..style.display = 'hidden';
        _container.children.add(e);
      }
      _top = null; // force update;
    }

    if ((_top == null) || ((top - _top).abs() >= tail_length)) {
      _shifter.style.top = '${_itemHeight*(top-tail_length)}px';
      int i = top - tail_length;
      for (final HtmlElement e in _container.children) {
        if (0 <= i && i < _items.length) {
          e..style.display = null;
          _update(e, _items[i], i);
        } else {
          e.style.display = 'hidden';
        }
        i++;
      }
      _top = top;
    }
  }

  void _updateHeader() {
    _header.style.top = '${scrollTop}px';
  }

  void _onScroll(_) {
    // needed to avoid flickering
    _updateHeader();
    _r.dirty();
  }

  void _onResize(_) {
    final newHeight = getBoundingClientRect().height;
    if (newHeight > _height) {
      _height = newHeight;
      _r.dirty();
    }
  }
}
