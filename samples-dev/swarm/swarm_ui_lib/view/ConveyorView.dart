// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of view;

/**
 * Holds a number of child views.  As you switch between views, the old
 * view is pushed off to the side and the new view slides in from the other
 * side.
 */
class ConveyorView extends CompositeView {
  // TODO(jmesserly): some places use this property to know when the slide
  // transition is finished. It would be better to have an event that fires
  // when we're done sliding
  static const ANIMATE_SECONDS = 0.25;

  View targetView;
  // TODO(rnystrom): Should not be settable.
  View selectedView;
  // TODO(rnystrom): Hackish. Should use a real multicast event-like class.
  // Or just have it depend on an Observable to select a view and indicate
  // which view is selected? (e.g. the MVVM pattern)
  Function viewSelected;

  Timer animationTimer;

  ConveyorView()
      : super('conveyor-view', true),
        animationTimer = null {}

  Element render() {
    final result = super.render();
    // TODO(rnystrom): Have to do this in render() because container doesn't
    // exist before then. Hack. Should find a cleaner solution. One of:
    // - Add a ctor param to CompositeView for container class name.
    // - Make ConveyorView contain a CompositeView instead of subclass.
    // - Add method to CompositeView to set class name.
    container.attributes['class'] = 'conveyor-view-container';
    return result;
  }

  void selectView(View targetView_, [bool animate = true]) {
    selectedView = targetView_;

    // Only animate if we're actually in the document now.
    if (isRendered) {
      adjustOffset(animate);
    }
  }

  void adjustOffset(bool animate) {
    int index = getIndexOfSelectedView();
    final durationSeconds = animate ? ANIMATE_SECONDS : 0.0;

    final style = container.style;
    // TODO(jacobr): modify setTransitionDuration so the input is always
    // specified in miliseconds rather than accepting a string.
    style.transitionDuration = '${durationSeconds}s';
    final xTranslationPercent = -index * 100;
    style.transform = 'translate3d(${xTranslationPercent}%, 0px, 0px)';

    if (animate) {
      animationTimer = new Timer(
          new Duration(milliseconds: ((durationSeconds * 1000).toInt())), () {
        _onAnimationEnd();
      });
    }
    // TODO(mattsh), we should set the visibility to hide everything but the
    // selected view.
  }

  int getIndexOfSelectedView() {
    for (int i = 0; i < childViews.length; i++) {
      if (childViews[i] == selectedView) {
        return i;
      }
    }
    throw "view not found";
  }

  /**
   * Adds a child view to the ConveyorView.  The views are stacked horizontally
   * in the order they are added.
   */
  View addChild(View view) {
    view.addClass('conveyor-item');
    view.transform = 'translate3d(${(childViews.length * 100)}%, 0, 0)';
    return super.addChild(view);
  }

  void _onAnimationEnd() {
    if (viewSelected != null) {
      viewSelected(selectedView);
    }
  }
}
