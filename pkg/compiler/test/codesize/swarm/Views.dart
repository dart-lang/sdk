// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

// This file contains View framework classes.
// As it grows, it may need to be split into multiple files.

/// A factory that creates a view from a data model. */
abstract class ViewFactory<D> {
  View newView(D item);

  /// The width of the created view or null if the width is not fixed. */
  int? get width;

  /// The height of the created view or null if the height is not fixed. */
  int? get height;
}

abstract class VariableSizeViewFactory<D> {
  View newView(D item);

  /// The width of the created view for a specific data model. */
  int getWidth(D? item);

  /// The height of the created view for a specific data model. */
  int getHeight(D? item);
}

/// A collection of event listeners. */
class EventListeners {
  var listeners;
  EventListeners() {
    listeners = [];
  }

  void addListener(listener) {
    listeners.add(listener);
  }

  void fire(var event) {
    for (final listener in listeners) {
      listener(event);
    }
  }
}

/// Private view class used to store placeholder views for detached ListView
/// elements.
class _PlaceholderView extends View {
  _PlaceholderView();

  @override
  Element render() => Element.tag('div');
}

/// Class providing all metrics required to layout a data driven list view.
abstract class ListViewLayout<D> {
  void onDataChange();

  // TODO(jacobr): placing the newView member function on this class seems like
  // the wrong design.
  View newView(int index);

  /// Get the height of the view. Possibly expensive to compute. */
  int? getHeight(int viewLength);

  /// Get the width of the view. Possibly expensive to compute. */
  int? getWidth(int viewLength);

  /// Get the length of the view. Possible expensive to compute. */
  int getLength(int viewLength);

  /// Estimated height of the view. Guaranteed to be fast to compute. */
  int? getEstimatedHeight(int viewLength);

  /// Estimated with of the view. Guaranteed to be fast to compute. */
  int? getEstimatedWidth(int viewLength);

  /// Returns the offset in px that the ith item in the view should be placed
  /// at.
  int getOffset(int index);

  /// The page the ith item in the view should be placed in.
  int getPage(int index, int viewLength);
  int getPageStartIndex(int index, int viewLength);

  int getEstimatedLength(int viewLength);

  /// Snap a specified index to the nearest visible view given the [viewLength].
  int getSnapIndex(num offset, int viewLength);

  /// Returns an interval specifying what views are currently visible given a
  /// particular [:offset:].
  Interval<int> computeVisibleInterval(
      num offset, num viewLength, num bufferLength);
}

/// Base class used for the simple fixed size item [:ListView:] classes and more
/// complex list view classes such as [:VariableSizeListView:] using a
/// [:ListViewLayout:] class to drive the actual layout.
class GenericListView<D> extends View {
  /// Minimum throw distance in pixels to trigger snapping to the next item. */
  static const SNAP_TO_NEXT_THROW_THRESHOLD = 15;

  static const INDEX_DATA_ATTRIBUTE = 'data-index';

  final bool _scrollable;
  final bool _showScrollbar;
  final bool _snapToItems;
  Scroller? scroller;
  Scrollbar? _scrollbar;
  final List<D> _data;
  final ObservableValue<D?>? _selectedItem;
  final Map<int, View> _itemViews;
  late Element _containerElem;
  final bool _vertical;

  /// Length of the scrollable dimension of the view in px. */
  int _viewLength = 0;
  Interval<int> _activeInterval;
  final bool _paginate;
  final bool _removeClippedViews;
  final ListViewLayout<D> _layout;
  D? _lastSelectedItem;
  final PageState? _pages;

  /// Creates a new GenericListView with the given layout and data. If [:_data:]
  /// is an [:ObservableList<T>:] then it will listen to changes to the list
  /// and update the view appropriately.
  GenericListView(
      this._layout,
      this._data,
      this._scrollable,
      this._vertical,
      this._selectedItem,
      this._snapToItems,
      this._paginate,
      this._removeClippedViews,
      this._showScrollbar,
      this._pages)
      : _activeInterval = Interval(0, 0),
        _itemViews = <int, View>{} {
    // TODO(rnystrom): Move this into enterDocument once we have an exitDocument
    // that we can use to unregister it.
    if (_scrollable) {
      window.onResize.listen((Event event) {
        if (isInDocument) {
          onResize();
        }
      });
    }
  }

  void onSelectedItemChange() {
    // TODO(rnystrom): use Observable to track the last value of _selectedItem
    // rather than tracking it ourselves.
    _select(findIndex(_lastSelectedItem), false);
    _select(findIndex(_selectedItem!.value), true);
    _lastSelectedItem = _selectedItem.value;
  }

  @override
  Iterable<View> get childViews {
    return _itemViews.values.toList();
  }

  void _onClick(MouseEvent e) {
    int? index = _findAssociatedIndex(e.target as Node?);
    if (index != null) {
      _selectedItem!.value = _data[index];
    }
  }

  int? _findAssociatedIndex(Node? leafNode) {
    Node? node = leafNode;
    while (node != null && node != _containerElem) {
      if (node.parent == _containerElem) {
        return _nodeToIndex(node as Element);
      }
      node = node.parent;
    }
    return null;
  }

  int? _nodeToIndex(Element node) {
    // TODO(jacobr): use data attributes when available.
    String? index = node.attributes[INDEX_DATA_ATTRIBUTE];
    if (index != null && index.isNotEmpty) {
      return int.parse(index);
    }
    return null;
  }

  @override
  Element render() {
    final node = Element.tag('div');
    if (_scrollable) {
      _containerElem = Element.tag('div');
      _containerElem.tabIndex = -1;
      node.nodes.add(_containerElem);
    } else {
      _containerElem = node;
    }

    if (_scrollable) {
      scroller = Scroller(
          _containerElem,
          _vertical /* verticalScrollEnabled */,
          !_vertical /* horizontalScrollEnabled */,
          true /* momentumEnabled */, () {
        num? width = _layout.getWidth(_viewLength);
        num? height = _layout.getHeight(_viewLength);
        width = width ?? 0;
        height = height ?? 0;
        return Size(width, height);
      },
          _paginate && _snapToItems
              ? Scroller.FAST_SNAP_DECELERATION_FACTOR
              : 1);
      scroller!.onContentMoved.listen((e) => renderVisibleItems(false));
      if (_pages != null) {
        watch(_pages.target, (s) => _onPageSelected());
      }

      if (_snapToItems) {
        scroller!.onDecelStart.listen((e) => _decelStart());
        scroller!.onScrollerDragEnd.listen((e) => _decelStart());
      }
      if (_showScrollbar) {
        _scrollbar = Scrollbar(scroller!, true);
      }
    } else {
      _reserveArea();
      renderVisibleItems(true);
    }

    return node;
  }

  @override
  void afterRender(Element node) {
    // If our data source is observable, observe it.
    final data = _data;
    if (data is ObservableList<D>) {
      attachWatch(data, (EventSummary e) {
        if (e.target == data) {
          onDataChange();
        }
      });
    }

    if (_selectedItem != null) {
      addOnClick((Event e) {
        _onClick(e as MouseEvent);
      });
    }

    if (_selectedItem != null) {
      watch(_selectedItem, (EventSummary summary) => onSelectedItemChange());
    }
  }

  void onDataChange() {
    _layout.onDataChange();
    _renderItems();
  }

  void _reserveArea() {
    final style = _containerElem.style;
    int? width = _layout.getWidth(_viewLength);
    int? height = _layout.getHeight(_viewLength);
    if (width != null) {
      style.width = '${width}px';
    }
    if (height != null) {
      style.height = '${height}px';
    }
    // TODO(jacobr): this should be specified by the default CSS for a
    // GenericListView.
    style.overflow = 'hidden';
  }

  void onResize() {
    int lastViewLength = _viewLength;
    scheduleMicrotask(() {
      _viewLength = (_vertical ? node.offset.height : node.offset.width) as int;
      if (_viewLength != lastViewLength) {
        if (_scrollbar != null) {
          _scrollbar!.refresh();
        }
        renderVisibleItems(true);
      }
    });
  }

  @override
  void enterDocument() {
    if (scroller != null) {
      onResize();

      if (_scrollbar != null) {
        _scrollbar!.initialize();
      }
    }
  }

  int getNextIndex(int index, bool forward) {
    int delta = forward ? 1 : -1;
    if (_paginate) {
      int newPage = Math.max(0, _layout.getPage(index, _viewLength) + delta);
      index = _layout.getPageStartIndex(newPage, _viewLength);
    } else {
      index += delta;
    }
    return GoogleMath.clamp(index, 0, _data.length - 1);
  }

  void _decelStart() {
    final scroll = scroller!;
    num currentTarget = scroll.verticalEnabled
        ? scroll.currentTarget.y
        : scroll.currentTarget.x;
    num current = scroll.verticalEnabled
        ? scroll.contentOffset.y
        : scroll.contentOffset.x;
    int targetIndex = _layout.getSnapIndex(currentTarget, _viewLength);
    if (current != currentTarget) {
      // The user is throwing rather than statically releasing.
      // For this case, we want to move them to the next snap interval
      // as long as they made at least a minimal throw gesture.
      num currentIndex = _layout.getSnapIndex(current, _viewLength);
      if (currentIndex == targetIndex &&
          (currentTarget - current).abs() > SNAP_TO_NEXT_THROW_THRESHOLD &&
          -_layout.getOffset(targetIndex) != currentTarget) {
        num snappedCurrentPosition = -_layout.getOffset(targetIndex);
        targetIndex = getNextIndex(targetIndex, currentTarget < current);
      }
    }
    num targetPosition = -_layout.getOffset(targetIndex);
    if (currentTarget != targetPosition) {
      if (scroll.verticalEnabled) {
        scroll.throwTo(scroll.contentOffset.x, targetPosition);
      } else {
        scroll.throwTo(targetPosition, scroll.contentOffset.y);
      }
    } else {
      // Update the target page only after we are all done animating.
      if (_pages != null) {
        _pages.target.value = _layout.getPage(targetIndex, _viewLength);
      }
    }
  }

  void _renderItems() {
    for (int i = _activeInterval.start; i < _activeInterval.end; i++) {
      _removeView(i);
    }
    _itemViews.clear();
    _activeInterval = Interval(0, 0);
    if (scroller == null) {
      _reserveArea();
    }
    renderVisibleItems(false);
  }

  void _onPageSelected() {
    if (_pages!.target != _layout.getPage(_activeInterval.start, _viewLength)) {
      _throwTo(_layout.getOffset(
          _layout.getPageStartIndex(_pages.target.value, _viewLength)));
    }
  }

  num get _offset {
    return scroller!.verticalEnabled
        ? scroller!.getVerticalOffset()
        : scroller!.getHorizontalOffset();
  }

  /// Calculates visible interval, based on the scroller position.
  Interval<int> getVisibleInterval() {
    return _layout.computeVisibleInterval(_offset, _viewLength, 0);
  }

  void renderVisibleItems(bool lengthChanged) {
    Interval<int> targetInterval;
    if (scroller != null) {
      targetInterval = getVisibleInterval();
    } else {
      // If the view is not scrollable, render all elements.
      targetInterval = Interval(0, _data.length);
    }

    if (_pages != null) {
      _pages.current.value = _layout.getPage(targetInterval.start, _viewLength);
    }
    if (_pages != null) {
      _pages.length.value = _data.isNotEmpty
          ? _layout.getPage(_data.length - 1, _viewLength) + 1
          : 0;
    }

    if (!_removeClippedViews) {
      // Avoid removing clipped views by extending the target interval to
      // include the existing interval of rendered views.
      targetInterval = targetInterval.union(_activeInterval);
    }

    if (lengthChanged == false && targetInterval == _activeInterval) {
      return;
    }

    // TODO(jacobr): add unittests that this code behaves correctly.

    // Remove views that are not needed anymore
    for (int i = _activeInterval.start,
            end = Math.min(targetInterval.start, _activeInterval.end);
        i < end;
        i++) {
      _removeView(i);
    }
    for (int i = Math.max(targetInterval.end, _activeInterval.start);
        i < _activeInterval.end;
        i++) {
      _removeView(i);
    }

    // Add new views
    for (int i = targetInterval.start,
            end = Math.min(_activeInterval.start, targetInterval.end);
        i < end;
        i++) {
      _addView(i);
    }
    for (int i = Math.max(_activeInterval.end, targetInterval.start);
        i < targetInterval.end;
        i++) {
      _addView(i);
    }

    _activeInterval = targetInterval;
  }

  void _removeView(int index) {
    // Do not remove placeholder views as they need to stay present in case
    // they scroll out of view and then back into view.
    final nodeView = _itemViews[index]!;
    if (nodeView is! _PlaceholderView) {
      // Remove from the active DOM but don't destroy.
      nodeView.node.remove();
      childViewRemoved(nodeView);
    }
  }

  View _newView(int index) {
    final view = _layout.newView(index);
    view.node.attributes[INDEX_DATA_ATTRIBUTE] = index.toString();
    return view;
  }

  View _addView(int index) {
    if (_itemViews.containsKey(index)) {
      final view = _itemViews[index]!;
      _addViewHelper(view, index);
      childViewAdded(view);
      return view;
    }

    final view = _newView(index);
    _itemViews[index] = view;
    // TODO(jacobr): its ugly to put this here... but its needed
    // as typical even-odd css queries won't work as we only display some
    // children at a time.
    if (index == 0) {
      view.addClass('first-child');
    }
    _selectHelper(view, _data[index] == _lastSelectedItem);
    // The order of the child elements doesn't matter as we use absolute
    // positioning.
    _addViewHelper(view, index);
    childViewAdded(view);
    return view;
  }

  void _addViewHelper(View view, int index) {
    _positionSubview(view.node, index);
    // The view might already be attached.
    if (view.node.parent != _containerElem) {
      _containerElem.nodes.add(view.node);
    }
  }

  /// Detach a subview from the view replacing it with an empty placeholder view.
  /// The detached subview can be safely reparented.
  View detachSubview(D itemData) {
    int index = findIndex(itemData)!;
    View? view = _itemViews[index];
    if (view == null) {
      // Edge case: add the view so we can detach as the view is currently
      // outside but might soon be inside the visible area.
      assert(!_activeInterval.contains(index));
      _addView(index);
      view = _itemViews[index];
    }
    final placeholder = _PlaceholderView();
    view!.node.replaceWith(placeholder.node);
    _itemViews[index] = placeholder;
    return view;
  }

  /// Reattach a subview from the view that was detached from the view
  /// by calling detachSubview. [callback] is called once the subview is
  /// reattached and done animating into position.
  void reattachSubview(D data, View view, bool animate) {
    int index = findIndex(data)!;
    // TODO(jacobr): perform some validation that the view is
    // really detached.
    late Coordinate currentPosition;
    if (animate) {
      currentPosition =
          FxUtil.computeRelativePosition(view.node, _containerElem);
    }
    assert(_itemViews[index] is _PlaceholderView);
    view.enterDocument();
    _itemViews[index]!.node.replaceWith(view.node);
    _itemViews[index] = view;
    if (animate) {
      FxUtil.setTranslate(view.node, currentPosition.x, currentPosition.y, 0);
      // The view's position is unchanged except now re-parented to
      // the list view.
      Timer.run(() {
        _positionSubview(view.node, index);
      });
    } else {
      _positionSubview(view.node, index);
    }
  }

  int? findIndex(D? targetItem) {
    // TODO(jacobr): move this to a util library or modify this class so that
    // the data is an List not a Collection.
    int i = 0;
    for (D item in _data) {
      if (item == targetItem) {
        return i;
      }
      i++;
    }
    return null;
  }

  void _positionSubview(Element node, int index) {
    if (_vertical) {
      FxUtil.setTranslate(node, 0, _layout.getOffset(index), 0);
    } else {
      FxUtil.setTranslate(node, _layout.getOffset(index), 0, 0);
    }
    node.style.zIndex = index.toString();
  }

  void _select(int? index, bool selected) {
    if (index != null) {
      final subview = getSubview(index);
      if (subview != null) {
        _selectHelper(subview, selected);
      }
    }
  }

  void _selectHelper(View view, bool selected) {
    if (selected) {
      view.addClass('sel');
    } else {
      view.removeClass('sel');
    }
  }

  View? getSubview(int index) {
    return _itemViews[index];
  }

  void showView(D targetItem) {
    int? index = findIndex(targetItem);
    if (index != null) {
      if (_layout.getOffset(index) < -_offset) {
        _throwTo(_layout.getOffset(index));
      } else if (_layout.getOffset(index + 1) > (-_offset + _viewLength)) {
        // TODO(jacobr): for completeness we should check whether
        // the current view is longer than _viewLength in which case
        // there are some nasty edge cases.
        _throwTo(_layout.getOffset(index + 1) - _viewLength);
      }
    }
  }

  void _throwTo(num offset) {
    if (_vertical) {
      scroller!.throwTo(0, -offset);
    } else {
      scroller!.throwTo(-offset, 0);
    }
  }
}

class FixedSizeListViewLayout<D> implements ListViewLayout<D> {
  final ViewFactory<D> itemViewFactory;
  final bool _vertical;
  final List<D> _data;
  final bool _paginate;

  FixedSizeListViewLayout(
      this.itemViewFactory, this._data, this._vertical, this._paginate);

  @override
  void onDataChange() {}

  @override
  View newView(int index) {
    return itemViewFactory.newView(_data[index]);
  }

  int get _itemLength {
    return (_vertical ? itemViewFactory.height : itemViewFactory.width)!;
  }

  @override
  int? getWidth(int viewLength) {
    return _vertical ? itemViewFactory.width : getLength(viewLength);
  }

  @override
  int? getHeight(int viewLength) {
    return _vertical ? getLength(viewLength) : itemViewFactory.height;
  }

  @override
  int? getEstimatedHeight(int viewLength) {
    // Returns the exact height as it is trivial to compute for this layout.
    return getHeight(viewLength);
  }

  @override
  int? getEstimatedWidth(int viewLength) {
    // Returns the exact height as it is trivial to compute for this layout.
    return getWidth(viewLength);
  }

  @override
  int getEstimatedLength(int viewLength) {
    // Returns the exact length as it is trivial to compute for this layout.
    return getLength(viewLength);
  }

  @override
  int getLength(int viewLength) {
    int itemLength =
        (_vertical ? itemViewFactory.height : itemViewFactory.width)!;
    if (viewLength == null || viewLength == 0) {
      return itemLength * _data.length;
    } else if (_paginate) {
      if (_data.isNotEmpty) {
        final pageLength = getPageLength(viewLength);
        return getPage(_data.length - 1, viewLength) * pageLength +
            Math.max(viewLength, pageLength);
      } else {
        return 0;
      }
    } else {
      return itemLength * (_data.length - 1) + Math.max(viewLength, itemLength);
    }
  }

  @override
  int getOffset(int index) {
    return index * _itemLength;
  }

  int getPageLength(int viewLength) {
    final itemsPerPage = viewLength ~/ _itemLength;
    return Math.max(1, itemsPerPage) * _itemLength;
  }

  @override
  int getPage(int index, int viewLength) {
    return getOffset(index) ~/ getPageLength(viewLength);
  }

  @override
  int getPageStartIndex(int page, int viewLength) {
    return getPageLength(viewLength) ~/ _itemLength * page;
  }

  @override
  int getSnapIndex(num offset, int viewLength) {
    int index = (-offset / _itemLength).round();
    if (_paginate) {
      index = getPageStartIndex(getPage(index, viewLength), viewLength);
    }
    return GoogleMath.clamp(index, 0, _data.length - 1);
  }

  @override
  Interval<int> computeVisibleInterval(
      num offset, num viewLength, num bufferLength) {
    int targetIntervalStart =
        Math.max(0, (-offset - bufferLength) ~/ _itemLength);
    num targetIntervalEnd = GoogleMath.clamp(
        ((-offset + viewLength + bufferLength) / _itemLength).ceil(),
        targetIntervalStart,
        _data.length);
    return Interval(targetIntervalStart, targetIntervalEnd.toInt());
  }
}

/// Simple list view class where each item has fixed width and height.
class ListView<D> extends GenericListView<D> {
  /// Creates a new ListView for the given data. If [:_data:] is an
  /// [:ObservableList<T>:] then it will listen to changes to the list and
  /// update the view appropriately.
  ListView(List<D> data, ViewFactory<D> itemViewFactory, bool scrollable,
      bool vertical, ObservableValue<D>? selectedItem,
      [bool snapToItems = false,
      bool paginate = false,
      bool removeClippedViews = false,
      bool showScrollbar = false,
      PageState? pages])
      : super(
            FixedSizeListViewLayout<D>(
                itemViewFactory, data, vertical, paginate),
            data,
            scrollable,
            vertical,
            selectedItem,
            snapToItems,
            paginate,
            removeClippedViews,
            showScrollbar,
            pages);
}

/// Layout where each item may have variable size along the axis the list view
/// extends.
class VariableSizeListViewLayout<D> implements ListViewLayout<D> {
  final List<D> _data;
  List<int> _itemOffsets;
  List<int> _lengths;
  int _lastOffset = 0;
  final bool _vertical;
  final bool _paginate;
  VariableSizeViewFactory<D> itemViewFactory;
  Interval<int> _lastVisibleInterval;

  VariableSizeListViewLayout(
      this.itemViewFactory, data, this._vertical, this._paginate)
      : _data = data,
        _lastVisibleInterval = Interval(0, 0),
        _itemOffsets = <int>[0],
        _lengths = <int>[];

  @override
  void onDataChange() {
    _itemOffsets.clear();
    _itemOffsets.add(0);
    _lengths.clear();
  }

  @override
  View newView(int index) => itemViewFactory.newView(_data[index]);

  @override
  int getWidth(int viewLength) {
    if (_vertical) {
      return itemViewFactory.getWidth(null);
    } else {
      return getLength(viewLength);
    }
  }

  @override
  int getHeight(int viewLength) {
    if (_vertical) {
      return getLength(viewLength);
    } else {
      return itemViewFactory.getHeight(null);
    }
  }

  @override
  int getEstimatedHeight(int viewLength) {
    if (_vertical) {
      return getEstimatedLength(viewLength);
    } else {
      return itemViewFactory.getHeight(null);
    }
  }

  @override
  int getEstimatedWidth(int viewLength) {
    if (_vertical) {
      return itemViewFactory.getWidth(null);
    } else {
      return getEstimatedLength(viewLength);
    }
  }

  // TODO(jacobr): this logic is overly complicated. Replace with something
  // simpler.
  @override
  int getEstimatedLength(int viewLength) {
    if (_lengths.length == _data.length) {
      // No need to estimate... we have all the data already.
      return getLength(viewLength);
    }
    if (_itemOffsets.length > 1 && _lengths.isNotEmpty) {
      // Estimate length by taking the average of the lengths
      // of the known views.
      num lengthFromAllButLastElement = 0;
      if (_itemOffsets.length > 2) {
        lengthFromAllButLastElement =
            (getOffset(_itemOffsets.length - 2) - getOffset(0)) *
                (_data.length / (_itemOffsets.length - 2));
      }
      return (lengthFromAllButLastElement +
              Math.max(viewLength, _lengths[_lengths.length - 1]))
          .toInt();
    } else {
      if (_lengths.length == 1) {
        return Math.max(viewLength, _lengths[0]);
      } else {
        return viewLength;
      }
    }
  }

  @override
  int getLength(int viewLength) {
    if (_data.isEmpty) {
      return viewLength;
    } else {
      // Hack so that _lengths[length - 1] is available.
      getOffset(_data.length);
      return (getOffset(_data.length - 1) - getOffset(0)) +
          Math.max(_lengths[_lengths.length - 1], viewLength);
    }
  }

  @override
  int getOffset(int index) {
    if (index >= _itemOffsets.length) {
      int offset = _itemOffsets[_itemOffsets.length - 1];
      for (int i = _itemOffsets.length; i <= index; i++) {
        int length = _vertical
            ? itemViewFactory.getHeight(_data[i - 1])
            : itemViewFactory.getWidth(_data[i - 1]);
        offset += length;
        _itemOffsets.add(offset);
        _lengths.add(length);
      }
    }
    return _itemOffsets[index];
  }

  @override
  int getPage(int index, int viewLength) {
    // TODO(jacobr): implement.
    throw 'Not implemented';
  }

  @override
  int getPageStartIndex(int page, int viewLength) {
    // TODO(jacobr): implement.
    throw 'Not implemented';
  }

  @override
  int getSnapIndex(num offset, num viewLength) {
    for (int i = 1; i < _data.length; i++) {
      if (getOffset(i) + getOffset(i - 1) > -offset * 2) {
        return i - 1;
      }
    }
    return _data.length - 1;
  }

  @override
  Interval<int> computeVisibleInterval(
      num offset, num viewLength, num bufferLength) {
    final offsetInt = offset.toInt();
    int start = _findFirstItemBefore(-offsetInt - bufferLength,
        _lastVisibleInterval != null ? _lastVisibleInterval.start : 0);
    int end = _findFirstItemAfter(-offsetInt + viewLength + bufferLength,
        _lastVisibleInterval != null ? _lastVisibleInterval.end : 0);
    _lastVisibleInterval = Interval(start, Math.max(start, end));
    _lastOffset = offsetInt;
    return _lastVisibleInterval;
  }

  int _findFirstItemAfter(num target, int hint) {
    for (int i = 0; i < _data.length; i++) {
      if (getOffset(i) > target) {
        return i;
      }
    }
    return _data.length;
  }

  // TODO(jacobr): use hint.
  int _findFirstItemBefore(num target, int hint) {
    // We go search this direction delaying computing the actual view size
    // as long as possible.
    for (int i = 1; i < _data.length; i++) {
      if (getOffset(i) >= target) {
        return i - 1;
      }
    }
    return Math.max(_data.length - 1, 0);
  }
}

class VariableSizeListView<D> extends GenericListView<D> {
  VariableSizeListView(List<D> data, VariableSizeViewFactory<D> itemViewFactory,
      bool scrollable, bool vertical, ObservableValue<D?> selectedItem,
      [bool snapToItems = false,
      bool paginate = false,
      bool removeClippedViews = false,
      bool showScrollbar = false,
      PageState? pages])
      : super(
            VariableSizeListViewLayout(
                itemViewFactory, data, vertical, paginate),
            data,
            scrollable,
            vertical,
            selectedItem,
            snapToItems,
            paginate,
            removeClippedViews,
            showScrollbar,
            pages);
}

/// A back button that is equivalent to clicking "back" in the browser. */
class BackButton extends View {
  BackButton();

  @override
  Element render() => Element.html('<div class="back-arrow button"></div>');

  @override
  void afterRender(Element node) {
    addOnClick((e) => window.history.back());
  }
}

// TODO(terry): Maybe should be part of ButtonView class in appstack/view?
/// OS button. */
class PushButtonView extends View {
  final String _text;
  final String _cssClass;
  final _clickHandler;

  PushButtonView(this._text, this._cssClass, this._clickHandler);

  @override
  Element render() {
    return Element.html('<button class="$_cssClass">$_text</button>');
  }

  @override
  void afterRender(Element node) {
    addOnClick(_clickHandler);
  }
}

// TODO(terry): Add a drop shadow around edge and corners need to be rounded.
//              Need to support conveyor for contents of dialog so it's not
//              larger than the parent window.
/// A generic dialog view supports title, done button and dialog content. */
class DialogView extends View {
  final String _title;
  final String _cssName;
  final View _content;
  late Element container;
  late PushButtonView _done;

  DialogView(this._title, this._cssName, this._content);

  @override
  Element render() {
    final node = Element.html('''
      <div class="dialog-modal">
        <div class="dialog $_cssName">
          <div class="dialog-title-area">
            <span class="dialog-title">$_title</span>
          </div>
          <div class="dialog-body"></div>
        </div>
      </div>''');

    _done =
        PushButtonView('Done', 'done-button', EventBatch.wrap((e) => onDone()));
    final titleArea = node.querySelector('.dialog-title-area')!;
    titleArea.nodes.add(_done.node);

    container = node.querySelector('.dialog-body')!;
    container.nodes.add(_content.node);

    return node;
  }

  /// Override to handle dialog done. */
  void onDone() {}
}
