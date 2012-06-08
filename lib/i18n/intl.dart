/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * Internationalization object providing access to message formatting objects,
 * date formatting, parsing, bidirectional text relative to a specific locale.
 */

#library('Intl');

#import('intl_message.dart');
#import('date_format.dart');

class Intl {

  /**
   * String indicating the locale code with which the message is to be
   * formatted (such as en-CA).
   */
  String _locale;

  IntlMessage intlMsg;

  DateFormat date;

  /**
   * Constructor optionally [_locale] for specifics of the language
   * locale to be used, otherwise, we will attempt to infer it (acceptable if
   * Dart is running on the client, we can infer from the browser/client
   * preferences).
   */
  Intl([this._locale]) {
    intlMsg = new IntlMessage(_locale);
    date = new DateFormat(_locale);
  }

  /**
   * Create a message that can be internationalized. It takes a
   * [message_str] that will be translated, which may be interpolated
   * based on one or more variables, a [desc] providing a description of usage
   * for the [message_str], and a map of [examples] for each data element to be
   * substituted into the message. For example, if message="Hello, $name", then
   * examples = {'name': 'Sparky'}. The values of [desc] and [examples] are
   * not used at run-time but are only made available to the translators, so
   * they MUST be simple Strings available at compile time: no String
   * interpolation or concatenation.
   * The expected usage of this is inside a function that takes as parameters
   * the variables used in the interpolated string.
   */
  String message(String message_str, [final String desc='',
                 final Map examples=const {}]) {
    return message_str;
  }

  /**
   * Support method for message formatting. Select the correct plural form from
   * [cases] given [howMany].
   */
  static String plural(var howMany, Map cases, [num offset=0]) {
    // TODO(efortuna): Deal with "few" and "many" cases, offset, and others!
    // TODO(alanknight): Should we have instance methods instead/as well?
    // Or have the others as statics?
    return select(howMany.toString(), cases);
  }

  /**
   * Support method for message formatting. Select the correct exact (gender,
   * usually) form from [cases] given the user [choice].
   */
  static String select(String choice, Map cases) {
    if (cases.containsKey(choice)) {
      return cases[choice];
    } else if (cases.containsKey('other')){
      return cases['other'];
    } else {
      return '';
    }
  }
}
