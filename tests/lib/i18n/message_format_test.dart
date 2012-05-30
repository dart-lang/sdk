/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#library('message_format_test');

#import('../../../lib/i18n/message_format.dart');
#import('../../../lib/unittest/unittest.dart');

/**
 * Tests the MessageFormat library in dart.
 */

main() {
  test('Message formatting', () {
    var msg_format = new MessageFormat(
      'Message telling user how many emails will be sent.',
      '''{NUM_EMAILS_TO_SEND, plural,
          =0 {unused plural form}
          =1 {One email will be sent.}
          other {# emails will be sent.}}''');
    // TODO(efortuna): Uncomment when functioning correctly.
    //Expect.stringEquals('5 emails will be sent.',
    //                    msg_formatter.format({'NUM_EMAILS_TO_SEND' : 5})); 
  });
}
