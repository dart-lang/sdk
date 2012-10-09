// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library provides internationalization and localization. This includes
 * message formatting and replacement, date and number formatting and parsing,
 * and utilities for working with Bidirectional text.
 *
 * For things that require locale or other data, there are multiple different
 * ways of making that data available, which may require importing different
 * libraries. See the class comments for more details.
 *
 * There is also a simple example application that can be found in the
 * `example/basic` directory.
 */
#library('intl');

#import('src/intl_helpers.dart');
#import('dart:math');
#import('date_symbols.dart');
#import('src/date_format_internal.dart');

#source('date_format.dart');
#source('src/date_format_field.dart');
#source('src/date_format_helpers.dart');
#source('bidi_formatter.dart');
#source('bidi_utils.dart');

/**
 * The Intl class provides a common entry point for internationalization
 * related tasks. An Intl instance can be created for a particular locale
 * and used to create a date format via `anIntl.date()`. Static methods
 * on this class are also used in message formatting.
 *
 * Message example:
 *     '''I see ${Intl.plural(num_people,
 *               {'0': 'no one at all',
 *                '1': 'one other person',
 *                'other': '$num_people other people'})} in $place.''''
 *
 * Usage examples:
 *      today(date) => intl.message(
 *          "Today's date is $date",
 *          desc: 'Indicate the current date',
 *          examples: {'date' : 'June 8, 2012'});
 *      print(today(new Date.now());
 *
 *      msg(num_people, place) => intl.message(
 *           '''I see ${Intl.plural(num_people,
 *             {'0': 'no one at all',
 *              '1': 'one other person',
 *              'other': '$num_people other people'})} in $place.'''',
 *          desc: 'Description of how many people are seen as program start.',
 *          examples: {'num_people': 3, 'place': 'London'});
 *
 * Calling `msg({'num_people': 2, 'place': 'Athens'});` would
 * produce "I see 2 other people in Athens." as output.
 *
 * See `tests/message_format_test.dart` for more examples.
 */
 //TODO(efortuna): documentation example involving the offset parameter?

class Intl {
  /**
   * String indicating the locale code with which the message is to be
   * formatted (such as en-CA).
   */
  String _locale;

  /** The default locale. This defaults to being set from systemLocale, but
   * can also be set explicitly, and will then apply to any new instances where
   * the locale isn't specified.
   */
  static String _defaultLocale;

  /**
   * The system's locale, as obtained from the window.navigator.language
   * or other operating system mechanism. Note that due to system limitations
   * this is not automatically set, and must be set by importing one of
   * intl_browser.dart or intl_standalone.dart and calling findSystemLocale().
   */
  static String systemLocale = 'en_US';

  /**
   * Return a new date format using the specified [pattern].
   * If [desiredLocale] is not specified, then we default to [locale].
   */
  DateFormat date([String pattern, String desiredLocale]) {
    var actualLocale = (desiredLocale == null) ? locale : desiredLocale;
    return new DateFormat(pattern, actualLocale);
  }

  /**
   * Constructor optionally [aLocale] for specifics of the language
   * locale to be used, otherwise, we will attempt to infer it (acceptable if
   * Dart is running on the client, we can infer from the browser/client
   * preferences).
   */
  Intl([String aLocale]) {
    if (aLocale != null) {
      _locale = aLocale;
    } else {
      _locale = getCurrentLocale();
    }
  }

  /**
   * Returns a message that can be internationalized. It takes a
   * [message_str] that will be translated, which may be interpolated
   * based on one or more variables, a [desc] providing a description of usage
   * for the [message_str], and a map of [examples] for each data element to be
   * substituted into the message. For example, if message="Hello, $name", then
   * examples = {'name': 'Sparky'}. If not using the user's default locale, or
   * if the locale is not easily detectable, explicitly pass [locale].
   * The values of [desc] and [examples] are not used at run-time but are only
   * made available to the translators, so they MUST be simple Strings available
   * at compile time: no String interpolation or concatenation.
   * The expected usage of this is inside a function that takes as parameters
   * the variables used in the interpolated string, and additionally also a
   * locale (optional).
   * Ultimately, the information about the enclosing function and its arguments
   * will be extracted automatically but for the time being it must be passed
   * explicitly in the [name] and [args] arguments.
   */
  static String message(String message_str, [final String desc='',
      final Map examples=const {}, String locale, String name,
      List<String> args]) {
    return messageLookup.lookupMessage(
        message_str, desc, examples, locale, name, args);
  }

  /**
   * Return the locale for this instance. If none was set, the locale will
   * be the default.
   */
  String get locale => _locale;

  /**
   * Return true if the locale exists, or if it is null. The null case
   * is interpreted to mean that we use the default locale.
   */
  static bool _localeExists(localeName) {
    return DateFormat.localeExists(localeName);
  }

  /**
   * Given [newLocale] return a locale that we have data for that is similar
   * to it, if possible.
   * If [newLocale] is found directly, return it. If it can't be found, look up
   * based on just the language (e.g. 'en_CA' -> 'en'). Also accepts '-'
   * as a separator and changes it into '_' for lookup, and changes the
   * country to uppercase.
   * Note that null is interpreted as meaning the default locale, so if
   * [newLocale] is null it will be returned.
   */
  static String verifiedLocale(String newLocale) {
    // TODO(alanknight): This is specific to DateFormat, and only used there
    // now. This should be moved, renamed, or generalized.
    if (newLocale == null) return systemLocale;
    if (_localeExists(newLocale)) {
      return newLocale;
    }
    for (var each in [canonicalizedLocale(newLocale), _shortLocale(newLocale)]) {
      if (_localeExists(each)) {
        return each;
      }
    }
    throw new ArgumentError("Invalid locale '$newLocale'");
  }

  /** Return the short version of a locale name, e.g. 'en_US' => 'en' */
  static String _shortLocale(String aLocale) {
    if (aLocale.length < 2) return aLocale;
    return aLocale.substring(0, 2).toLowerCase();
  }

  /**
   * Return a locale name turned into xx_YY where it might possibly be
   * in the wrong case or with a hyphen instead of an underscore.
   */
  static String canonicalizedLocale(String aLocale) {
    // Locales of length < 5 are presumably two-letter forms, or else malformed.
    // Locales of length > 6 are likely to be malformed. In either case we
    // return them unmodified and if correct they will be found.
    // We treat C as a special case, and assume it wants en_ISO for formatting.
    // TODO(alanknight): en_ISO is probably not quite right for the C/Posix
    // locale for formatting. Consider adding C to the formats database.
    if (aLocale == "C") return "en_ISO";
    if ((aLocale.length < 5) || (aLocale.length > 6)) return aLocale;
    if (aLocale[2] != '-' && (aLocale[2] != '_')) return aLocale;
    var lastRegionLetter = aLocale.length == 5 ? "" : aLocale[5].toUpperCase();
    return '${aLocale[0]}${aLocale[1]}_${aLocale[3].toUpperCase()}'
           '${aLocale[4].toUpperCase()}$lastRegionLetter';
  }

  /**
   * Support method for message formatting. Select the correct plural form from
   * [cases] given [howMany].
   */
  static String plural(var howMany, Map cases, [num offset=0]) {
    // TODO(efortuna): Deal with "few" and "many" cases, offset, and others!
    return select(howMany.toString(), cases);
  }

  /**
   * Format the given function with a specific [locale], given a
   * [msg_function] that takes no parameters and returns a String. We
   * basically delay calling the message function proper until after the proper
   * locale has been set.
   */
  static String withLocale(String locale, Function msg_function) {
    // We have to do this silliness because Locale is not known at compile time,
    // but must be a static variable.
    if (_defaultLocale == null) _defaultLocale = systemLocale;
    var oldLocale = _defaultLocale;
    _defaultLocale = locale;
    var result = msg_function();
    _defaultLocale = oldLocale;
    return result;
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

  /**
   * Accessor for the current locale. This should always == the default locale,
   * unless for some reason this gets called inside a message that resets the
   * locale.
   */
  static String getCurrentLocale() {
    if (_defaultLocale == null) _defaultLocale = systemLocale;
    return _defaultLocale;
  }
}