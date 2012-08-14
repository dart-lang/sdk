// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('intl_test');

#import('../../../pkg/i18n/intl.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
  test('Set locale', (){
    var de = new Intl('de_DE');
    expect(de.locale, equals('de'));
  });
}
