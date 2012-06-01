/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#library('date_format_test');

#import('../../../lib/i18n/date_format.dart');
#import('../../../lib/unittest/unittest.dart');

/**
 * Tests the DateFormat library in dart.
 */

main() {
  test('Date formatting', () {
    var date_format = new DateFormat.fullDate();
    Date date = new Date.now();
    // TODO(efortuna): Change the expectation once we have a functioning date
    // formatting class.
    Expect.stringEquals(date.toString(), date_format.format(date));
    
    date_format = new DateFormat("hh:mm:ss");
    Expect.stringEquals(date.toString(), date_format.format(date));
  });

  test('Date parsing', () {
    var date_format = new DateFormat.fullDate();
    Date date =  new Date.now();
    // TODO(efortuna): Change the expectation once we have a functioning date
    // formatting class.
    Expect.stringEquals(date_format.parse(date.toString()), date.toString());
  });
}
