// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of view;

typedef void SelectHandler(String menuText);

/**
 * This implements a horizontal menu bar with a sliding triangle arrow
 * that points at the currently selected item.
 */
class SliderMenu extends View {
  static const int TRIANGLE_WIDTH = 24;

  // currently selected menu item
  Element selectedItem;

  // This holds the element where a touchstart occured.  (This is set
  // in touchstart, and cleared in touchend.)  If this is null, then a
  // touch operation is not in progress.
  // TODO(mattsh) - move this to a touch mixin
  Element touchItem;

  /**
   * Callback function that we call when the user chooses something from
   * the menu.  This is passed the menu item text.
   */
  SelectHandler onSelect;

  List<String> _menuItems;

  SliderMenu(this._menuItems, this.onSelect) : super() {}

  Element render() {
    // Create a div for each menu item.
    final items = new StringBuffer();
    for (final item in _menuItems) {
      items.write('<div class="sm-item">$item</div>');
    }

    // Create a root node to hold this view.
    return new Element.html('''
        <div class="sm-root">
          <div class="sm-item-box">
            <div class="sm-item-filler"></div>
            $items
            <div class="sm-item-filler"></div>
          </div>
          <div class="sm-slider-box">
            <div class="sm-triangle"></div>
          </div>
        </div>
        ''');
  }

  void enterDocument() {
    // select the first item
    // todo(jacobr): too much actual work is performed in enterDocument.
    // Ideally, enterDocument should do nothing more than redecorate a view
    // and perhaps calculating the correct child sizes for edge cases that
    // cannot be handled by the browser layout engine.
    selectItem(node.querySelector('.sm-item'), false);

    // TODO(mattsh), abstract this somehow into a touch click mixin
    if (Device.supportsTouch) {
      node.onTouchStart.listen((event) {
        touchItem = itemOfTouchEvent(event);
        if (touchItem != null) {
          selectItemText(touchItem);
        }
        event.preventDefault();
      });
      node.onTouchEnd.listen((event) {
        if (touchItem != null) {
          if (itemOfTouchEvent(event) == touchItem) {
            selectItem(touchItem, true);
          } else {
            // the Touch target is somewhere other where than the touchstart
            // occured, so revert the selected menu text back to where it was
            // before the touchstart,
            selectItemText(selectedItem);
          }
          // touch operation has ended
          touchItem = null;
        }
        event.preventDefault();
      });
    } else {
      node.onClick.listen((event) => selectItem(event.target, true));
    }

    window.onResize.listen((Event event) => updateIndicator(false));
  }

  /**
   * Walks the parent chain of the first Touch target to find the first ancestor
   * that has sm-item class.
   */
  Element itemOfTouchEvent(event) {
    Node node = event.changedTouches[0].target;
    return itemOfNode(node);
  }

  Element itemOfNode(Node node) {
    // TODO(jmesserly): workaround for bug 5399957, document.parent == document
    while (node != null && node != document) {
      if (node is Element) {
        Element element = node;
        if (element.classes.contains('sm-item')) {
          return element;
        }
      }
      node = node.parent;
    }
    return null;
  }

  void selectItemText(Element item) {
    // unselect all menu items
    for (final sliderItem in node.querySelectorAll('.sm-item')) {
      sliderItem.classes.remove('sel');
    }

    // select the item the user clicked on
    item.classes.add('sel');
  }

  void selectItem(Element item, bool animate) {
    if (!item.classes.contains('sm-item')) {
      return;
    }

    selectedItem = item;
    selectItemText(item);
    updateIndicator(animate);
    onSelect(item.text);
  }

  void selectNext(bool animate) {
    final result = node.querySelector('.sm-item.sel').nextElementSibling;
    if (result != null) {
      selectItem(result, animate);
    }
  }

  void selectPrevious(bool animate) {
    final result = node.querySelector('.sm-item.sel').previousElementSibling;
    if (result != null) {
      selectItem(result, animate);
    }
  }

  /**
   * animate - if true, then animate the movement of the triangle slider
   */
  void updateIndicator(bool animate) {
    if (selectedItem != null) {
      // calculate where we want to put the triangle
      scheduleMicrotask(() {
        num x = selectedItem.offset.left +
            selectedItem.offset.width / 2 -
            TRIANGLE_WIDTH / 2;
        _moveIndicator(x, animate);
      });
    } else {
      _moveIndicator(0, animate);
    }
  }

  void _moveIndicator(num x, bool animate) {
    // find the slider filler (the div element to the left of the
    // triangle) set its width the push the triangle to where we want it.
    String duration = animate ? '.3s' : '0s';
    final triangle = node.querySelector('.sm-triangle');
    triangle.style.transitionDuration = duration;
    FxUtil.setWebkitTransform(triangle, x, 0);
  }
}
