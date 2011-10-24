// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The examples from the spec: [http://dev.w3.org/csswg/css3-grid-align/]
 */
// I've omitted examples that are subsumed by other examples, or examples
// that illustrate features (such as grid-flow) that are currently
// unsupported.
class GridExamples {
  // Note: controls is positioned in row 3 in the example. Might be a bug in
  // the example, or they're using flow.
  // TODO(jmesserly): also needed to set "display: inline-block" to get
  // horizontal content sizing to work.
  static final styles = const {
    '1 Adaptive Layouts': AdaptiveLayout.selectors,
    '2a Source Independence: Portrait': SourceIndependencePortrait.selectors,
    '2b Source Independence: Landscape': SourceIndependenceLandscape.selectors,
    '3 Grid Layering of Elements': GridLayering.selectors,
    '5 Grid Lines': GridLines_5.selectors,
    '6 Grid Lines': GridLines_6.selectors,
    '7 Grid Cells': GridCells.selectors,
    '11a Starting and Ending Grid Lines': StartEndingGridlines11a.selectors,
    '11b Starting and Ending Grid Lines': StartEndingGridlines11b.selectors,
    '12 Repeating Columns and Rows': RepeatingColumnsRows.selectors,
    '17 Anonymous Grid Cells': AnonymousGridCells.selectors,
    '20 Implicit Columns and Rows': ImplicitColumnsRows.selectors,
    '22 Grid Item Alignment': AlignGridItems.selectors,
    '23 Drawing Order of Grid Items': DrawOrderGridItems.selectors
  };
}
