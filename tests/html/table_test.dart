// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('TableTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('createTBody', () {
    var table = new TableElement();
    var head = table.createTHead();
    var headerRow =  head.insertRow(-1);
    var headerCell = headerRow.insertCell(-1);
    headerCell.text = 'Header Cell';

    var body = table.createTBody();
    var bodyRow =  body.insertRow(-1);
    var bodyCell = bodyRow.insertCell(-1);
    bodyCell.text = 'Body Cell';

    expect(table.tBodies.length, 1);
    expect(table.tBodies[0], body);

    var foot = table.createTFoot();
    var footerRow =  foot.insertRow(-1);
    var footerCell = footerRow.insertCell(-1);
    footerCell.text = 'Footer Cell';

    var body2 = table.createTBody();
    var bodyRow2 =  body2.insertRow(-1);
    var bodyCell2 = bodyRow2.insertCell(-1);
    bodyCell2.text = 'Body Cell2';

    expect(table.tBodies.length, 2);
    expect(table.tBodies[1], body2);

  });
}

