// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;
import 'package:observatory/src/elements/containers/search_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

typedef HtmlElement VirtualCollectionCreateCallback();
typedef List<HtmlElement> VirtualCollectionHeaderCallback();
typedef void VirtualCollectionUpdateCallback(
    HtmlElement el, dynamic item, int index);
typedef bool VirtualCollectionSearchCallback(Pattern pattern, dynamic item);

class VirtualCollectionElement extends HtmlElement implements Renderable {
  static const tag = const Tag<VirtualCollectionElement>('virtual-collection',
      dependencies: const [SearchBarElement.tag]);

  RenderingScheduler<VirtualCollectionElement> _r;

  Stream<RenderedEvent<VirtualCollectionElement>> get onRendered =>
      _r.onRendered;

  VirtualCollectionCreateCallback _create;
  VirtualCollectionHeaderCallback _createHeader;
  VirtualCollectionUpdateCallback _update;
  VirtualCollectionSearchCallback _search;
  double _itemHeight;
  int _top;
  double _height;
  List _items;
  StreamSubscription _onScrollSubscription;
  StreamSubscription _onResizeSubscription;

  List get items => _items;

  set items(Iterable value) {
    _items = new List.unmodifiable(value);
    _top = null;
    _searcher?.update();
    _r.dirty();
  }

  factory VirtualCollectionElement(VirtualCollectionCreateCallback create,
      VirtualCollectionUpdateCallback update,
      {Iterable items: const [],
      VirtualCollectionHeaderCallback createHeader,
      VirtualCollectionSearchCallback search,
      RenderingQueue queue}) {
    assert(create != null);
    assert(update != null);
    assert(items != null);
    VirtualCollectionElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._create = create;
    e._createHeader = createHeader;
    e._update = update;
    e._search = search;
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
    _onScrollSubscription = _viewport.onScroll.listen(_onScroll);
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

  DivElement _header;
  SearchBarElement _searcher;
  final DivElement _viewport = new DivElement()
    ..classes = ['viewport', 'container'];
  final DivElement _spacer = new DivElement()..classes = ['spacer'];
  final DivElement _buffer = new DivElement()..classes = ['buffer'];

  dynamic getItemFromElement(HtmlElement element) {
    final el_index = _buffer.children.indexOf(element);
    if (el_index < 0) {
      return null;
    }
    final item_index =
        _top + el_index - (_buffer.children.length * _inverse_preload).floor();
    if (0 <= item_index && item_index < items.length) {
      return _items[item_index];
    }
    return null;
  }

  /// The preloaded element before and after the visible area are:
  /// 1/preload_size of the number of items in the visble area.
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
        _viewport
          ..children = [
            _spacer
              ..children = [
                _buffer..children = [_create()]
              ],
          ]
      ];
      if (_search != null) {
        _searcher =
            _searcher ?? new SearchBarElement(_doSearch, queue: _r.queue)
              ..onSearchResultSelected.listen((e) {
                takeIntoView(e.item);
              });
        children.insert(0, _searcher);
      }
      if (_createHeader != null) {
        _header = new DivElement()
          ..classes = ['header', 'container']
          ..children = _createHeader();
        children.insert(0, _header);
        final rect = _header.getBoundingClientRect();
        _header.classes.add('attached');
        _viewport.style.top = '${rect.height}px';
        final width = _header.children.fold(0, _foldWidth);
        _buffer.style.minWidth = '${width}px';
      }
      _itemHeight = _buffer.children[0].getBoundingClientRect().height;
      _height = getBoundingClientRect().height;
    }

    if (_takeIntoView != null) {
      final index = items.indexOf(_takeIntoView);
      if (index >= 0) {
        final minScrollTop = _itemHeight * (index + 1) - _height;
        final maxScrollTop = _itemHeight * index;
        _viewport.scrollTop =
            ((maxScrollTop - minScrollTop) / 2 + minScrollTop).floor();
      }
      _takeIntoView = null;
    }

    final top = (_viewport.scrollTop / _itemHeight).floor();

    _spacer.style.height = '${_itemHeight*(_items.length)}px';
    final tail_length = (_height / _itemHeight / _preload).ceil();
    final length = tail_length * 2 + tail_length * _preload;

    if (_buffer.children.length < length) {
      while (_buffer.children.length != length) {
        var e = _create();
        e..style.display = 'hidden';
        _buffer.children.add(e);
      }
      _top = null; // force update;
    }

    if ((_top == null) || ((top - _top).abs() >= tail_length)) {
      _buffer.style.top = '${_itemHeight*(top-tail_length)}px';
      int i = top - tail_length;
      for (final HtmlElement e in _buffer.children) {
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

    if (_searcher != null) {
      final current = _searcher.current;
      int i = _top - tail_length;
      for (final HtmlElement e in _buffer.children) {
        if (0 <= i && i < _items.length) {
          if (_items[i] == current) {
            e.classes.add('marked');
          } else {
            e.classes.remove('marked');
          }
        }
        i++;
      }
    }
    _updateHeader();
  }

  double _foldWidth(double value, HtmlElement child) {
    return math.max(value, child.getBoundingClientRect().width);
  }

  void _updateHeader() {
    if (_header != null) {
      _header.style.left = '${-_viewport.scrollLeft}px';
      final width = _buffer.getBoundingClientRect().width;
      _header.children.last.style.width = '${width}px';
    }
  }

  void _onScroll(_) {
    _r.dirty();
    // We anticipate the header in advance to avoid flickering
    _updateHeader();
  }

  void _onResize(_) {
    final newHeight = getBoundingClientRect().height;
    if (newHeight > _height) {
      _height = newHeight;
      _r.dirty();
    } else {
      // Even if we are not updating the structure the computed size is going to
      // change
      _updateHeader();
    }
  }

  Iterable<dynamic> _doSearch(String search) {
    return _items.where((item) => _search(search, item));
  }
}
