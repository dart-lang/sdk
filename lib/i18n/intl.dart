/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 */

#library('Intl');
#import('date_format.dart');
#import('message_format.dart');

class Intl {

  /**
   * As yet not clearly defined variable for holding onto our current locale,
   * which may actually be a list of locales, or have different information
   * for different aspects of internationalization (e.g. German locale but with
   * Canadian date format)
   */
  // TODO (alanknight): Actually make this class do something with locales,
  // just a skeleton right now.
  var _locale;

  /**
   * Constructor
   */
  Intl([this._locale]);

  /**
   * Methods to return appropriate format objects.
   */
  DateFormat date() => new DateFormat.fullDate();
  DateFormat time() => new DateFormat.fullTime();
  DateFormat dateTime() => new DateFormat.fullDateTime();
  MessageFormat message() => new MessageFormat();

  /**
   * Support methods for message formatting.
   */
  String plural(num howMany, Map actions) {
    var desiredKey = howMany.toString();
    for (var key in actions.getKeys()) {
        if(desiredKey == key) return actions[key];
    }
    if (actions.containsKey('other')) {
      return actions['other'];
    } else {
      return '';
    }
  }

  String select(String choice, Map actions) {
    for (var key in actions.getKeys()) {
      if (choice == key) return actions[key];
    }
    return '';
  }
}
