// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('intl_test');

#import('../intl.dart');
#import('../../../pkg/unittest/unittest.dart');
#import('../date_symbol_data_local.dart');

main() {
  test('Set locale', (){
    // TODO(alanknight): We need to make the locale verification be on a per
    // usage basis rather than once for the entire Intl object. The set of
    // locales covered for messages may be different from that for date
    // formatting.
    initializeDateFormatting('de_DE', null).then((_) {
      var de = new Intl('de_DE');
      expect(de.locale, equals('de'));});
  });
}
