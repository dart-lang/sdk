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

class Person {
  String firstName, lastName;
  Person(this.firstName, this.lastName);
}

main() {
  Intl intl = new Intl();

  test('Trivial Message', () {
    hello() => intl.message('Hello, world!',
        desc: 'hello world string');
    expect(hello(), equals('Hello, world!'));
  });

  test('Message with one parameter', () {
    lucky(number) => intl.message('Your lucky number is $number',
        desc: 'number str', examples: {'number': 2});
    expect(lucky(3), equals('Your lucky number is 3'));
  });

  test('Message with multiple plural cases (whole message)', () {
    emails(number) => intl.message(
        Intl.plural(number,
          {'0': 'There are no emails left.',
           '1': 'There is one email left.',
           'other': 'There are $number emails left.'}),
          desc: 'Message telling user how many emails will be sent.',
          examples: {'number': 32});
    expect(emails(5), equals('There are 5 emails left.'));
    expect(emails(0), equals('There are no emails left.'));
    expect(emails(1), equals('There is one email left.'));
  });

  test('Message with multiple plural cases (partial message)', () {
    emails(number) => intl.message(
      "There ${Intl.plural(number,
        {'0': 'are',
         '1': 'is',
         'other': 'are'})} $number messages left.",
          desc: 'Message telling user how many emails will be sent.',
          examples: {'number': 32});
    expect(emails(5), equals('There are 5 messages left.'));
    expect(emails(0), equals('There are 0 messages left.'));
    expect(emails(1), equals('There is 1 messages left.'));
  });

  test('Message with dictionary parameter', () {
    hello(dict) => intl.message(
        "Hello, my name is ${dict['first']} ${dict['last']}",
        desc: "States a person's name.",
        examples: {'first': 'Ford', 'last': 'Prefect'});
    expect(hello({'first' : 'Ford', 'last' : 'Prefect'}),
      equals('Hello, my name is Ford Prefect'));
  });

  test('Message with object parameter', () {
    hello(person) => intl.message(
        "Hello, my name is ${person.firstName} ${person.lastName}.",
        desc: "States a person's name.",
        examples: {'first': 'Ford', 'last' : 'Prefect'});
    var ford = new Person('Ford', 'Prefect');
    expect(hello(ford), equals('Hello, my name is Ford Prefect.'));
  });
}
