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
  Intl([this._locale]) : intlMsg = new IntlMessage(_locale),
      date = new DateFormat(_locale);

  /**
   * Create a message that can be internationalized. It contains a [message_str]
   * that will be translated, a [desc] providing a description of the use case
   * for the [message_str], and a map of [examples] for each data element to be
   * substituted into the message. For example, if message="Hello, $name", then
   * examples = {'name': 'Sparky'}. The values of [desc] and [examples] MUST be
   * simple Strings available at compile time: no String interpolation or
   * concatenation.
   */
  String message(String message_str, [final String desc='',
                 final Map examples=const {}]) {
    // TODO(efortuna): implement.
    return message_str; 
  }

  /**
   * Support method for message formatting. Select the correct plural form from
   * [cases] given [howMany].
   */
  static String plural(var howMany, Map cases, [num offset=0]) {
    // TODO(efortuna): Deal with "few" and "many" cases, offset, and others!
    select(howMany.toString(), cases);
  }

  /**
   * Support method for message formatting. Select the correct exact (gender,
   * usually) form from [cases] given the user [choice].
   */
  static String select(String choice, Map cases) {
    if (cases.getKeys().some((elem) => elem == choice)) {
      return cases[choice];
    } else if (cases.containsKey('other')){
      return cases['other'];
    } else {
      return '';
    }
  }
}
