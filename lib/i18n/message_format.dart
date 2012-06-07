/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * Library for internationalizing and localizing user messages, including
 * support for customizing them based on plurals and genders.
 *
 * Messages are written as functions with either one parameter (which can be
 * omitted). The function name serves as an identifier for the message, and is
 * customarily given a unique prefix such as intl_ to distinguish it from
 * application functions.
 * The function is expected to return a single interpolated string, based
 * on the parameter (which can be a Map or a complex object).
 *
 * For example
 *   intl_helloWorld () => "Hello world";
 *   intl_oneValue (waiting) => "There are $waiting jobs waiting";
 *   intl_dict (dict) =>
 *  "Hello ${dict['name']}, your waiting time is ${dict['minutes']} minutes";
 *
 * More complex formatting can make use of the Intl object and associated
 * message format.
 * Here is a more complete example of usage with complex formatting
 *  var intl = new Intl();
 *  intl_howManyPeopleAreHere (NUM)
 *    //@desc Lists how many people are here
 *    => "There ${intl.plural(NUM,{'0': 'are', '1': 'is', 'other': 'are'})} "
 *    "$NUM other ${intl.plural(NUM, {'1':'person', 'other': 'people'})} here.";
 *  var msg_format = new MessageFormat(intl_howManyPeopleAreHere);
 *  msg_format.format(2);
 *
 * See tests/message_format_test.dart for more comprehensive examples.
 */

#library('MessageFormat');
#import('intl.dart');

class MessageFormat {

  /**
   * The definition of this message. This should be a function which returns
   * a string. The string may use Dart's string interpolation feature to
   * substitute values based on the function's parameter.
   * See tests/message_format_test.dart for more examples.
   */
  final Function _messageFunction;

  /**
   * String indicating a locale code with which the message is to be
   * formatted (such as en-CA).
   */
  final String _locale;

  /**
   * Constructor. The constructor expects you do provide annotations in comments
   * above your declaration of this constructor with an @desc describing the
   * context for the useage of the function. You may also specify @ex to specify
   * examples of inputs for each particular argument that the [_messageFunction]
   * accepts. The String [_messageFunction] is used to determine the particular
   * case and gender for the given instance. An optional [_locale] can be
   * provided for specifics of the language locale to be used, otherwise, we
   * will attempt to infer it (acceptable if Dart is running on the client, we
   * can infer from the browser).
   */
  //TODO(efortuna): _locale is not currently inferred.
  const MessageFormat([this._messageFunction, this._locale = 'en-US']);

  /**
   * Formats the _messageFunction message and returns the correctly
   * formatted message in the language of the current locale.
   *
   * The variable [messageParameters] can be null, in which case the message
   * function is called with no arguments. Otherwise, it is called with
   * [messageParameters] as the single argument. If the message function
   * requires more than one variable, then messageParameters can be a
   * map with the values in it.
   */
  String format(var messageParameters) {
    return _messageFunction(messageParameters);
  }

  /**
   * Formats the [messageFunction] argument and returns the correctly
   * formatted message in the language of the current locale.
   *
   * The variable [messageParameters] can be null, in which case the message
   * function is called with no arguments. Otherwise, it is called with
   * messageParameters as the single argument. If the message function
   * requires more than one variable, then messageParameters can be a
   * map with the values in it.
   *
   * This differs from format only in that the message is passed as an argument
   */
  String formatMessage(Function messageFunction,var messageParameters) {
    if (messageParameters == null) {
      return messageFunction();
    } else {
      return messageFunction(messageParameters);
    }
  }
}
