// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library provides internationalization and localization. This includes
 * message formatting and replacement, date and number formatting and parsing,
 * and utilities for working with Bidirectional text.
 *
 * This is part of the [intl package]
 * (https://pub.dartlang.org/packages/intl).
 *
 * For things that require locale or other data, there are multiple different
 * ways of making that data available, which may require importing different
 * libraries. See the class comments for more details.
 *
 * There is also a simple example application that can be found in the
 * [example/basic]
 * (https://code.google.com/p/dart/source/browse/#svn%2Fbranches%2Fbleeding_edge%2Fdart%2Fpkg%2Fintl%2Fexample%2Fbasic)
 *  directory.
 */
library intl;

import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'date_symbols.dart';
import 'number_symbols.dart';
import 'number_symbols_data.dart';
import 'src/date_format_internal.dart';
import 'src/intl_helpers.dart';

part 'src/intl/bidi_formatter.dart';
part 'src/intl/bidi_utils.dart';
part 'src/intl/date_format.dart';
part 'src/intl/date_format_field.dart';
part 'src/intl/date_format_helpers.dart';
part 'src/intl/number_format.dart';

/**
 * The Intl class provides a common entry point for internationalization
 * related tasks. An Intl instance can be created for a particular locale
 * and used to create a date format via `anIntl.date()`. Static methods
 * on this class are also used in message formatting.
 *
 * Examples:
 *      today(date) => Intl.message(
 *          "Today's date is $date",
 *          name: 'today',
 *          args: [date],
 *          desc: 'Indicate the current date',
 *          examples: {'date' : 'June 8, 2012'});
 *      print(today(new DateTime.now().toString());
 *
 *      howManyPeople(numberOfPeople, place) => Intl.plural(
 *            zero: 'I see no one at all',
 *            one: 'I see one other person',
 *            other: 'I see $numberOfPeople other people')} in $place.''',
 *          name: 'msg',
 *          args: [numberOfPeople, place],
 *          desc: 'Description of how many people are seen in a place.',
 *          examples: {'numberOfPeople': 3, 'place': 'London'});
 *
 * Calling `howManyPeople(2, 'Athens');` would
 * produce "I see 2 other people in Athens." as output in the default locale.
 * If run in a different locale it would produce appropriately translated
 * output.
 *
 * For more detailed information on messages and localizing them see
 * the main [package documentation](https://pub.dartlang.org/packages/intl)
 *
 * You can set the default locale.
 *       Intl.defaultLocale = "pt_BR";
 *
 * To temporarily use a locale other than the default, use the `withLocale`
 * function.
 *       var todayString = new DateFormat("pt_BR").format(new DateTime.now());
 *       print(withLocale("pt_BR", () => today(todayString));
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
  static String defaultLocale;

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
    _locale = aLocale != null ? aLocale : getCurrentLocale();
  }

  /**
   * Use this for a message that will be translated for different locales. The
   * expected usage is that this is inside an enclosing function that only
   * returns the value of this call and provides a scope for the variables that
   * will be substituted in the message.
   *
   * The parameters are a
   * [message_str] to be translated, which may be interpolated
   * based on one or more variables, the [name] of the message, which should
   * match the enclosing function name, the [args] of the enclosing
   * function, a [desc] providing a description of usage
   * and a map of [examples] for each interpolated variable. For example
   *       hello(yourName) => Intl.message(
   *         "Hello, $yourName",
   *         name: "hello",
   *         args: [name],
   *         desc: "Say hello",
   *         examples = {"yourName": "Sparky"}.
   * The source code will be processed via the analyzer to extract out the
   * message data, so only a subset of valid Dart code is accepted. In
   * particular, everything must be literal and cannot refer to variables
   * outside the scope of the enclosing function. The [examples] map must
   * be a valid const literal map. Similarly, the [desc] argument must
   * be a single, simple string. These two arguments will not be used at runtime
   * but will be extracted from
   * the source code and used as additional data for translators. For more
   * information see the "Messages" section of the main [package documentation]
   * (https://pub.dartlang.org/packages/intl).
   *
   * The [name] and [args] arguments are required, and are used at runtime
   * to look up the localized version and pass the appropriate arguments to it.
   * We may in the future modify the code during compilation to make manually
   * passing those arguments unnecessary.
   */
  static String message(String message_str, {String desc: '',
      Map<String, String> examples: const {}, String locale, String name,
      List<String> args, String meaning}) {
    return messageLookup.lookupMessage(
        message_str, desc, examples, locale, name, args, meaning);
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
  static bool _localeExists(localeName) => DateFormat.localeExists(localeName);

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
  static String verifiedLocale(String newLocale, Function localeExists,
                               {Function onFailure: _throwLocaleError}) {
    // TODO(alanknight): Previously we kept a single verified locale on the Intl
    // object, but with different verification for different uses, that's more
    // difficult. As a result, we call this more often. Consider keeping
    // verified locales for each purpose if it turns out to be a performance
    // issue.
    if (newLocale == null) {
      return verifiedLocale(getCurrentLocale(), localeExists,
          onFailure: onFailure);
    }
    if (localeExists(newLocale)) {
      return newLocale;
    }
    for (var each in
        [canonicalizedLocale(newLocale), shortLocale(newLocale)]) {
      if (localeExists(each)) {
        return each;
      }
    }
    return onFailure(newLocale);
  }

  /**
   * The default action if a locale isn't found in verifiedLocale. Throw
   * an exception indicating the locale isn't correct.
   */
  static String _throwLocaleError(String localeName) {
    throw new ArgumentError("Invalid locale '$localeName'");
  }

  /** Return the short version of a locale name, e.g. 'en_US' => 'en' */
  static String shortLocale(String aLocale) {
    if (aLocale.length < 2) return aLocale;
    return aLocale.substring(0, 2).toLowerCase();
  }

  /**
   * Return the name [aLocale] turned into xx_YY where it might possibly be
   * in the wrong case or with a hyphen instead of an underscore. If
   * [aLocale] is null, for example, if you tried to get it from IE,
   * return the current system locale.
   */
  static String canonicalizedLocale(String aLocale) {
    // Locales of length < 5 are presumably two-letter forms, or else malformed.
    // We return them unmodified and if correct they will be found.
    // Locales longer than 6 might be malformed, but also do occur. Do as
    // little as possible to them, but make the '-' be an '_' if it's there.
    // We treat C as a special case, and assume it wants en_ISO for formatting.
    // TODO(alanknight): en_ISO is probably not quite right for the C/Posix
    // locale for formatting. Consider adding C to the formats database.
    if (aLocale == null) return getCurrentLocale();
    if (aLocale == "C") return "en_ISO";
    if (aLocale.length < 5) return aLocale;
    if (aLocale[2] != '-' && (aLocale[2] != '_')) return aLocale;
    var region = aLocale.substring(3);
    // If it's longer than three it's something odd, so don't touch it.
    if (region.length <= 3) region = region.toUpperCase();
    return
        '${aLocale[0]}${aLocale[1]}_$region';
  }

  /**
   * Format a message differently depending on [howMany]. Normally used
   * as part of an `Intl.message` text that is to be translated.
   * Selects the correct plural form from
   * the provided alternatives. The [other] named argument is mandatory.
   */
  static String plural(int howMany, {zero, one, two, few, many, other,
      String desc, Map<String, String> examples, String locale, String name,
      List<String> args, String meaning}) {
    // If we are passed a name and arguments, then we are operating as a
    // top-level message, so look up our translation by calling Intl.message
    // with ourselves as an argument.
    if (name != null) {
      return message(
        plural(howMany,
            zero: zero, one: one, two: two, few: few, many: many, other: other),
        name: name,
        args: args,
        locale: locale,
        meaning: meaning);
    }
    if (other == null) {
      throw new ArgumentError("The 'other' named argument must be provided");
    }
    // TODO(alanknight): This algorithm needs to be locale-dependent.
    switch (howMany) {
      case 0 : return (zero == null) ? other : zero;
      case 1 : return (one == null) ? other : one;
      case 2: return (two == null) ? ((few == null) ? other : few) : two;
      default:
        if ((howMany == 3 || howMany == 4) && few != null) return few;
        if (howMany > 10 && howMany < 100 && many != null) return many;
        return other;
    }
    throw new ArgumentError("Invalid plural usage for $howMany");
  }

  /**
   * Format a message differently depending on [targetGender]. Normally used as
   * part of an Intl.message message that is to be translated.
   */
  static String gender(String targetGender,
      {String male, String female, String other,
       String desc, Map<String, String> examples, String locale, String name,
       List<String>args, String meaning}) {
    // If we are passed a name and arguments, then we are operating as a
    // top-level message, so look up our translation by calling Intl.message
    // with ourselves as an argument.
    if (name != null) {
      return message(
        gender(targetGender, male: male, female: female, other: other),
        name: name,
        args: args,
        locale: locale,
        meaning: meaning);
    }

    if (other == null) {
      throw new ArgumentError("The 'other' named argument must be specified");
    }
    switch(targetGender) {
      case "female" : return female == null ? other : female;
      case "male" : return male == null ? other : male;
      default: return other;
    }
  }

  /**
   * Format a message differently depending on [choice]. We look up the value
   * of [choice] in [cases] and return the result, or an empty string if
   * it is not found. Normally used as part
   * of an Intl.message message that is to be translated.
   */
  static String select(String choice, Map<String, String> cases,
       {String desc, Map<String, String> examples, String locale, String name,
       List<String>args, String meaning}) {
    // If we are passed a name and arguments, then we are operating as a
    // top-level message, so look up our translation by calling Intl.message
    // with ourselves as an argument.
    if (name != null) {
      return message(
          select(choice, cases),
          name: name,
          args: args,
          locale: locale);
    }
    var exact = cases[choice];
    if (exact != null) return exact;
    var other = cases["other"];
    if (other == null)
      throw new ArgumentError("The 'other' case must be specified");
    return other;
  }

  /**
   * Format the given function with a specific [locale], given a
   * [message_function] that takes no parameters. The [message_function] can be
   * a simple message function that just returns the result of `Intl.message()`
   * it can be a wrapper around a message function that takes arguments, or it
   * can be something more complex that manipulates multiple message
   * functions.
   *
   * In either case, the purpose of this is to delay calling [message_function]
   * until the proper locale has been set. This returns the result of calling
   * [message_function], which could be of an arbitrary type.
   */
  static withLocale(String locale, Function message_function) {
    // We have to do this silliness because Locale is not known at compile time,
    // but must be a static variable in order to be visible to the Intl.message
    // invocation.
    var oldLocale = getCurrentLocale();
    defaultLocale = Intl.canonicalizedLocale(locale);
    var result = message_function();
    defaultLocale = oldLocale;
    return result;
  }

  /**
   * Accessor for the current locale. This should always == the default locale,
   * unless for some reason this gets called inside a message that resets the
   * locale.
   */
  static String getCurrentLocale() {
    if (defaultLocale == null) defaultLocale = systemLocale;
    return defaultLocale;
  }

  toString() => "Intl($locale)";
}
