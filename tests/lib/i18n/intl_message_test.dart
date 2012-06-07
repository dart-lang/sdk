// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#library('intl_message_test');

#import('../../../lib/i18n/intl.dart');
#import('../../../lib/i18n/intl_message.dart');
#import('../../../lib/unittest/unittest.dart');

/**
 * Tests the MessageFormat library in dart.
 */

main() {
  test('Trivial Message', () {
    msg_format() => new IntlMessage('Hello, world!',
        desc: 'hello world string');
  });
  //expect(msg_format(), 'Hello, world!');

  test('One num', () {
    msg_format(number) => new IntlMessage('Your lucky number is $number',
        desc: 'number str', examples: {'number': 2});
  });
  //expect(msg_format(3), 'Your lucky number is 3');

  test('Message formatting', () {
    msg_format(number) => new IntlMessage(
        Intl.plural(number,
          {'0': 'There are no emails left.',
           '1': 'There is one email left.',
           'other': 'There are $number emails left.'}),
          desc: 'Message telling user how many emails will be sent.',
          examples: {'number': 32});
  });
  // TODO(efortuna): Uncomment when functioning correctly.
  //expect(msg_format(5), '5 emails will be sent.');
 
  test('Message formatting with dictionary', () {
    msg_format(dict) => new IntlMessage(
        "Hello, my name is ${dict['first']} ${dict['last']}",
          desc: "States a person's name.",
          examples: {'first': 'Ford', 'last': 'Prefect'});
  });
  //expect(msg_format({'first' : 'Ford', 'last' : 'Prefect'),
  //    'Hello, my name is Ford Prefect');
}
