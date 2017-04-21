// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TableTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('createTBody', () {
    var table = new TableElement();
    var head = table.createTHead();
    expect(table.tHead, head);

    var headerRow = head.addRow();
    var headerCell = headerRow.addCell();
    headerCell.text = 'Header Cell';

    var caption = table.createCaption();
    expect(table.caption, caption);

    var body = table.createTBody();
    expect(table.tBodies.length, 1);
    expect(table.tBodies[0], body);

    var bodyRow = body.addRow();
    expect(body.rows.length, 1);
    expect(body.rows[0], bodyRow);

    var bodyCell = bodyRow.addCell();
    bodyCell.text = 'Body Cell';
    expect(bodyRow.cells.length, 1);
    expect(bodyRow.cells[0], bodyCell);

    var foot = table.createTFoot();
    expect(table.tFoot, foot);

    var footerRow = foot.addRow();
    expect(foot.rows.length, 1);
    expect(foot.rows[0], footerRow);

    var footerCell = footerRow.addCell();
    footerCell.text = 'Footer Cell';
    expect(footerRow.cells.length, 1);
    expect(footerRow.cells[0], footerCell);

    var body2 = table.createTBody();
    var bodyRow2 = body2.addRow();
    var bodyCell2 = bodyRow2.addCell();
    bodyCell2.text = 'Body Cell2';

    expect(body2.rows.length, 1);

    expect(table.tBodies.length, 2);
    expect(table.tBodies[1], body2);
  });
}
