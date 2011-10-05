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
  static final STYLES = const {
    '1 Adaptive Layouts': '''
      #grid {
          display: -dart-grid;
          grid-columns: auto minmax(min-content, 1fr);
          grid-rows: auto minmax(min-content, 1fr) auto
      }
      #title    { grid-column: 1; grid-row: 1 }
      #score    { grid-column: 1; grid-row: 3 }
      #stats    { grid-column: 1; grid-row: 2; grid-row-align: start }
      #board    { grid-column: 2; grid-row: 1; grid-row-span: 2 }
      #controls { grid-column: 2; grid-row: 3; grid-column-align: center }''',

    '2a Source Independence: Portrait': '''
      #grid {
          display: -dart-grid;
          grid-template: "ta"
                         "sa"
                         "bb"
                         "cc";
          grid-columns: auto minmax(min-content, 1fr);
          grid-rows: auto auto minmax(min-content, 1fr) auto
      }
      #title    { grid-cell: "t" }
      #score    { grid-cell: "s" }
      #stats    { grid-cell: "a" }
      #board    { grid-cell: "b" }
      #controls { grid-cell: "c" }''',

    '2b Source Independence: Landscape': '''
      #grid {
          display: -dart-grid;
          grid-template: "tb"
                         "ab"
                         "sc";

          grid-columns: auto minmax(min-content, 1fr);
          grid-rows: auto minmax(min-content, 1fr) auto
      }
      #title    { grid-cell: "t" }
      #score    { grid-cell: "s" }
      #stats    { grid-cell: "a" }
      #board    { grid-cell: "b" }
      #controls { grid-cell: "c" }''',

    '3 Grid Layering of Elements': '''
      #grid {
          display: -dart-grid;
          grid-columns:
              "start"        auto
              "track-start"  0.5fr
              "thumb-start"  auto
              "fill-split"   auto
              "thumb-end"    0.5fr
              "track-end"    auto
              "end";
      }
      #lower-label { grid-column: "start" }
      #track       { grid-column: "track-start" "track-end";
                     grid-row-align: center }
      #upper-label { grid-column: "track-end"; }
      #lower-fill  { grid-column: "track-start" "fill-split";
                     grid-row-align: center; grid-layer: 5 }
      #upper-fill  { grid-column: "fill-split" "track-end";
                     grid-row-align: center; grid-layer: 5 }
      #thumb       { grid-column: "thumb-start" "thumb-end"; grid-layer: 10 }
      ''',

    '5 Grid Lines': '''
      #grid {
          display: -dart-grid;
          grid-columns: 150px 1fr;
          grid-rows: 50px 1fr 50px
      }
      #item1 { grid-column: 2; grid-row: 1 4 }''',

    '6 Grid Lines': '''
      #grid {
          display: -dart-grid;
          grid-columns: 150px "item1-start" 1fr "item1-end";
          grid-rows: "item1-start" 50px 1fr 50px "item1-end"
      }

      #item1 {
          grid-column: "item1-start" "item1-end";
          grid-row: "item1-start" "item1-end"
      }''',

    '7 Grid Cells': '''
      #grid  {
          display: -dart-grid;
          grid-template: "ad"
                         "bd"
                         "cd";
          grid-columns: 150px 1fr;
          grid-rows: 50px 1fr 50px
      }
      #item2 { grid-cell: "b"; grid-row-align: start  }
      #item3 { grid-cell: "b"; grid-column-align: end; grid-row-align: end }
      ''',

    '11a Starting and Ending Grid Lines': '''
      #grid {
          display: -dart-grid;
          grid-columns: 50px 1fr;
          grid-rows: "first" 250px 1fr 250px "last";
      }
      #item {
          grid-column:1 3;
          grid-row: "first" "last";
      }''',

    '11b Starting and Ending Grid Lines': '''
      #grid {
          display: -dart-grid;
          grid-columns: 50px 1fr;
          grid-rows: "first" 250px 1fr 250px "last";
      }
      #item {
          grid-column: start end;
          grid-row: start end;
      }''',

    '12 Repeating Columns and Rows': '''
      #grid {
          display: -dart-grid;
          grid-columns: 10px ("content" 1fr 10px)[4];
          grid-rows: 1fr;
      }
      #col2 { grid-column: 2 }
      #col4 { grid-column: 4 }
      #col6 { grid-column: 6 }
      #col8 { grid-column: 8 }
      ''',

    '17 Anonymous Grid Cells': '''
      #grid {
          display: -dart-grid;
          grid-rows: "header" auto "main" 1fr "footer" auto;
          grid-columns: 1fr;
      }
      #header { grid-row: "header"; grid-column: start }
      #main   { grid-row: "main"; grid-column: start }
      #footer { grid-row: "footer"; grid-column: start }''',

    '20 Implicit Columns and Rows': '''
      #grid { display: -dart-grid; grid-columns: 20px; grid-rows: 20px }
      #A { grid-column: 1; grid-row: 1; grid-column-align: start;
           grid-row-align: start }
      #B { grid-column: 5; grid-row: 1; grid-row-span: 2; }
      #C { grid-column: 1; grid-row: 2; grid-column-span: 2; }''',

    '22 Grid Item Alignment': '''
      #grid { display: -dart-grid; grid-columns: 1fr 1fr; grid-rows: 1fr 1fr }
      #A { grid-column: 1; grid-row: 1; grid-column-align: start;
           grid-row-align: start }
      #B { grid-column: 2; grid-row: 2; grid-column-align: end;
           grid-row-align: end }''',

    '23 Drawing Order of Grid Items': '''
      #grid { display: -dart-grid; grid-columns: 1fr 1fr; grid-rows: 1fr 1fr }
      #A { grid-column: 1; grid-row: 2; grid-column-span: 2;
           grid-row-align: end }
      #B { grid-column: 1; grid-row: 1; grid-layer: 10 }
      #C { grid-column: 2; grid-row: 1; grid-row-align: start;
           margin-left: -20px }
      #D { grid-column: 2; grid-row: 2; grid-column-align: end;
           grid-row-align: start }
      #E { grid-column: 1; grid-row: 1;
           grid-column-span: 2; grid-row-span: 2; grid-layer: 5;
           grid-column-align: center; grid-row-align: center }'''
  };
}
