/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#library('message_format_test');

#import('../../../lib/i18n/message_format.dart');
#import('../../../lib/i18n/intl.dart');
#import('../../../lib/unittest/unittest.dart');


/**
 * Tests the MessageFormat library in dart.
 */

main() {

  test('Trivial message', () {
    intl_helloWorld()
        //@desc Hello world, doesn't get much simpler than this.
        => "Hello World";
    var msg_format = new MessageFormat();
    var result = msg_format.formatMessage(intl_helloWorld,null);
    Expect.stringEquals(result,"Hello World");
  });

   test('Message with one numeric', () {
      intl_oneNumeric(num)
        //@desc Tell the user about their lucky number.
        => "Your lucky number is $num";
     var msg_format = new MessageFormat();
     var result = msg_format.formatMessage(intl_oneNumeric,42);
     Expect.stringEquals(result,"Your lucky number is 42");
  });

  /**
   * Test for the simple error of evaluating the message function before
   * passing it in.
   */

  test('Evaluate the function by mistake', () {
        intl_oopsie()
         //@desc Doesn't matter
         => "You want to pass the formatter the function, not the string";
        var msg_format = new MessageFormat();
        expectThrow(()=>msg_format.formatMessage(intl_oopsie(),null));
  });

  test('Complex message with plural', () {
       var intl = new Intl();
       var df = intl.date;
       intl_howManyPeopleAreHere (NUM) =>
         //@desc Lists how many people are here
         "There ${intl.plural(NUM,{'0': 'are', '1': 'is', 'other': 'are'})} "
      "$NUM other ${intl.plural(NUM, {'1':'person', 'other': 'people'})} here.";
       var msg_format = new MessageFormat();
       Expect.stringEquals(
           msg_format.formatMessage(intl_howManyPeopleAreHere,0),
           "There are 0 other people here.");
       Expect.stringEquals(
          msg_format.formatMessage(intl_howManyPeopleAreHere,1),
          "There is 1 other person here.");
       Expect.stringEquals(
          msg_format.formatMessage(intl_howManyPeopleAreHere,2),
          "There are 2 other people here.");
  });

  test('MessageFormat with message', () {
          intl_mapArgument (dict)
          // @desc Lists person's name
          => "Hello, my name is ${dict['firstName']} ${dict['lastName']}";
      var msg_format = new MessageFormat(intl_mapArgument);
      var person = {'firstName' : 'Ford', 'lastName': 'Prefect'};
      Expect.stringEquals(
         msg_format.format(person),
         "Hello, my name is Ford Prefect");
  });

}
