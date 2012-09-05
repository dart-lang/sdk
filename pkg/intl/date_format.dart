// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * DateFormat is for formatting and parsing dates in a locale-sensitive
 * manner.
 * It allows the user to choose from a set of standard date time formats as well
 * as specify a customized pattern under certain locales. Date elements that
 * vary across locales include month name, week name, field order, etc.
 * <!-- TODO(efortuna): Customized pattern system -- suggested by i18n needs
 * feedback on appropriateness. -->
 * We also allow the user to use any customized pattern to parse or format
 * date-time strings under certain locales. Date elements that vary across
 * locales include month name, weekname, field, order, etc.
 *
 * This library uses the ICU/JDK date/time pattern specification both for
 * complete format specifications and also the abbreviated "skeleton" form
 * which can also adapt to different locales and is preferred where available.
 *
 * Skeletons: These can be specified either as the ICU constant name or as the
 * skeleton to which it resolves. The supported set of skeletons is as follows
 *   ICU Name                   Skeleton
 *   --------                   --------
 *   DAY                          d
 *   ABBR_WEEKDAY                 E
 *   WEEKDAY                      EEEE
 *   ABBR_STANDALONE_MONTH        LLL
 *   STANDALONE_MONTH             LLLL
 *   NUM_MONTH                    M
 *   NUM_MONTH_DAY                Md
 *   NUM_MONTH_WEEKDAY_DAY        MEd
 *   ABBR_MONTH                   MMM
 *   ABBR_MONTH_DAY               MMMd
 *   ABBR_MONTH_WEEKDAY_DAY       MMMEd
 *   MONTH                        MMMM
 *   MONTH_DAY                    MMMMd
 *   MONTH_WEEKDAY_DAY            MMMMEEEEd
 *   ABBR_QUARTER                 QQQ
 *   QUARTER                      QQQQ
 *   YEAR                         y
 *   YEAR_NUM_MONTH               yM
 *   YEAR_NUM_MONTH_DAY           yMd
 *   YEAR_NUM_MONTH_WEEKDAY_DAY   yMEd
 *   YEAR_ABBR_MONTH              yMMM
 *   YEAR_ABBR_MONTH_DAY          yMMMd
 *   YEAR_ABBR_MONTH_WEEKDAY_DAY  yMMMEd
 *   YEAR_MONTH                   yMMMM
 *   YEAR_MONTH_DAY               yMMMMd
 *   YEAR_MONTH_WEEKDAY_DAY       yMMMMEEEEd
 *   YEAR_ABBR_QUARTER            yQQQ
 *   YEAR_QUARTER                 yQQQQ
 *   HOUR24                       H
 *   HOUR24_MINUTE                Hm
 *   HOUR24_MINUTE_SECOND         Hms
 *   HOUR                         j
 *   HOUR_MINUTE                  jm
 *   HOUR_MINUTE_SECOND           jms
 *   HOUR_MINUTE_GENERIC_TZ       jmv
 *   HOUR_MINUTE_TZ               jmz
 *   HOUR_GENERIC_TZ              jv
 *   HOUR_TZ                      jz
 *   MINUTE                       m
 *   MINUTE_SECOND                ms
 *   SECOND                       s
 *
 * Examples Using the US Locale:
 *
 *      Pattern                           Result
 *      ----------------                  -------
 *      new DateFormat.yMd()             -> 07/10/1996
 *      new DateFormat("yMd")            -> 07/10/1996
 *      new DateFormat.yMMMMd("en_US")   -> July 10, 1996
 *      new DateFormat("Hm", "en_US")    -> 12:08 PM
 *      new DateFormat.yMd().Hm()        -> 07/10/1996 12:08 PM
 *
 * Explicit Pattern Syntax: Formats can also be specified with a pattern string.
 * The skeleton forms will resolve to explicit patterns of this form, but will
 * also adapt to different patterns in different locales.
 * The following characters are reserved:
 *
 *     Symbol   Meaning                Presentation        Example
 *     ------   -------                ------------        -------
 *     G        era designator         (Text)              AD
 *     y        year                   (Number)            1996
 *     M        month in year          (Text & Number)     July & 07
 *     L        standalone month       (Text & Number)     July & 07
 *     d        day in month           (Number)            10
 *     c        standalone day         (Number)            10
 *     h        hour in am/pm (1~12)   (Number)            12
 *     H        hour in day (0~23)     (Number)            0
 *     m        minute in hour         (Number)            30
 *     s        second in minute       (Number)            55
 *     S        fractional second      (Number)            978
 *     E        day of week            (Text)              Tuesday
 *     D        day in year            (Number)            189
 *     a        am/pm marker           (Text)              PM
 *     k        hour in day (1~24)     (Number)            24
 *     K        hour in am/pm (0~11)   (Number)            0
 *     z        time zone              (Text)              Pacific Standard Time
 *     Z        time zone (RFC 822)    (Number)            -0800
 *     v        time zone (generic)    (Text)              Pacific Time
 *     Q        quarter                (Text)              Q3
 *     '        escape for text        (Delimiter)         'Date='
 *     ''       single quote           (Literal)           'o''clock'
 *
 * The count of pattern letters determine the format.
 * **Text**:
 * * 5 pattern letters--use narrow form for standalone. Otherwise does not apply
 * * 4 or more pattern letters--use full form,
 * * 3 pattern letters--use short or abbreviated form if one exists
 * * less than 3--use numeric form if one exists
 *
 * **Number**: the minimum number of digits. Shorter numbers are zero-padded to
 * this amount (e.g. if "m" produces "6", "mm" produces "06"). Year is handled
 * specially; that is, if the count of 'y' is 2, the Year will be truncated to
 * 2 digits. (e.g., if "yyyy" produces "1997", "yy" produces "97".) Unlike other
 * fields, fractional seconds are padded on the right with zero.
 *
 * (Text & Number): 3 or over, use text, otherwise use number.
 *
 * Any characters that not in the pattern will be treated as quoted text. For
 * instance, characters like ':', '.', ' ', '#' and '@' will appear in the
 * resulting time text even they are not embraced within single quotes. In our
 * current pattern usage, we didn't use up all letters. But those unused
 * letters are strongly discouraged to be used as quoted text without quote.
 * That's because we may use other letter for pattern in future.
 *
 * Examples Using the US Locale:
 *
 *     Format Pattern                         Result
 *     --------------                         -------
 *     "yyyy.MM.dd G 'at' HH:mm:ss vvvv"->1996.07.10 AD at 15:08:56 Pacific Time
 *     "EEE, MMM d, ''yy"               ->Wed, July 10, '96
 *     "h:mm a"                         ->12:08 PM
 *     "hh 'o''clock' a, zzzz"          ->12 o'clock PM, Pacific Daylight Time
 *     "K:mm a, vvv"                    ->0:00 PM, PT
 *     "yyyyy.MMMMM.dd GGG hh:mm aaa"   ->01996.July.10 AD 12:08 PM
 *
 * When parsing a date string using the abbreviated year pattern ("yy"),
 * DateFormat must interpret the abbreviated year relative to some
 * century. It does this by adjusting dates to be within 80 years before and 20
 * years after the time the parse function is called. For example, using a
 * pattern of "MM/dd/yy" and a DateTimeParse instance created on Jan 1, 1997,
 * the string "01/11/12" would be interpreted as Jan 11, 2012 while the string
 * "05/04/64" would be interpreted as May 4, 1964. During parsing, only
 * strings consisting of exactly two digits, as defined by {@link
 * java.lang.Character#isDigit(char)}, will be parsed into the default
 * century. Any other numeric string, such as a one digit string, a three or
 * more digit string will be interpreted as its face value.
 *
 * If the year pattern does not have exactly two 'y' characters, the year is
 * interpreted literally, regardless of the number of digits. So using the
 * pattern "MM/dd/yyyy", "01/11/12" parses to Jan 11, 12 A.D.
 */

#library('date_format');

#import('dart:math');
#import('intl.dart');
#import('date_symbols.dart');
#import('lib/intl_helpers.dart');
#import('lib/date_format_internal.dart');

#source('lib/date_format_field.dart');
#source('lib/date_format_helpers.dart');

class DateFormat {

  /**
   * If [newPattern] matches one of the skeleton forms, it is looked up
   * in [locale] or in the default if none is specified, and the corresponding
   * full format string is used. If [newPattern] does not match one
   * of the supported skeleton forms then it is used as a format directly.
   *
   * For example, in an en_US locale, specifying the skeleton
   *     `new DateFormat('yMEd');`
   * or the explicit
   *     `new DateFormat('EEE, M/d/y');`
   * would produce the same result, a date of the form
   *     `Wed, 6/27/2012`
   * However, the skeleton version would also adapt to other locales.
   *
   * If [locale] does not exist in our set of supported locales then an
   * [IllegalArgumentException] is thrown.
   */
  DateFormat([String newPattern, String locale]) {
    // TODO(alanknight): It should be possible to specify multiple skeletons eg
    // date, time, timezone all separately. Adding many or named parameters to
    // the constructor seems awkward, especially with the possibility of
    // confusion with the locale. A "fluent" interface with cascading on an
    // instance might work better? A list of patterns is also possible.
    // TODO(alanknight): There will need to be at least setup type async
    // operations to avoid the need to bring along every locale in every program
    _locale = Intl.verifiedLocale(locale);
    addPattern(newPattern);
  }

  /**
   * Return a string representing [date] formatted according to our locale
   * and internal format.
   */
  String format(Date date) {
    // TODO(efortuna): read optional TimeZone argument (or similar)?
    var result = new StringBuffer();
    _formatFields.forEach((field) => result.add(field.format(date)));
    return result.toString();
  }

  /**
   * Returns a date string indicating how long ago (3 hours, 2 minutes)
   * something has happened or how long in the future something will happen
   * given a [reference] Date relative to the current time.
   */
  String formatDuration(Date reference) {
    return '';
  }

  /**
   * Formats a string indicating how long ago (negative [duration]) or how far
   * in the future (positive [duration]) some time is with respect to a
   * reference [date].
   */
  String formatDurationFrom(Duration duration, Date date) {
    return '';
  }

  /**
   * Given user input, attempt to parse the [inputString] into the anticipated
   * format, treating it as being in the local timezone.
   */
  Date parse(String inputString, [utc = false]) {
    // TODO(alanknight): The Closure code refers to special parsing of numeric
    // values with no delimiters, which we currently don't do. Should we?
    var dateFields = new _DateBuilder();
    if (utc) dateFields.utc=true;
    var stream = new _Stream(inputString);
    _formatFields.forEach(
        (each) => each.parse(stream, dateFields));
    return dateFields.asDate();
  }

  /**
   * Given user input, attempt to parse the [inputString] into the anticipated
   * format, treating it as being in UTC.
   */
  Date parseUTC(String inputString) {
    return parse(inputString, true);
  }

  /**
   * Return the locale code in which we operate, e.g. 'en_US' or 'pt'.
   */
  String get locale() => _locale;

  /**
   * Returns a list of all locales for which we have date formatting
   * information.
   */
  static List<String> allLocalesWithSymbols() => dateTimeSymbols.getKeys();

  /**
   * Constructors for a set of predefined formats for which
   * internationalized forms are known. These can be specified
   * either as ICU constants, or as skeletons.
   */
  DateFormat.DAY([locale]) : this(DAY, locale);
  DateFormat.ABBR_WEEKDAY([locale]) : this(ABBR_WEEKDAY, locale);
  DateFormat.WEEKDAY([locale]) : this(WEEKDAY, locale);
  DateFormat.ABBR_STANDALONE_MONTH([locale]) :
      this(ABBR_STANDALONE_MONTH, locale);
  DateFormat.STANDALONE_MONTH([locale]) : this(STANDALONE_MONTH, locale);
  DateFormat.NUM_MONTH([locale]) : this(NUM_MONTH, locale);
  DateFormat.NUM_MONTH_DAY([locale]) : this(NUM_MONTH_DAY, locale);
  DateFormat.NUM_MONTH_WEEKDAY_DAY([locale]) :
      this(NUM_MONTH_WEEKDAY_DAY, locale);
  DateFormat.ABBR_MONTH([locale]) : this(ABBR_MONTH, locale);
  DateFormat.ABBR_MONTH_DAY([locale]) : this(ABBR_MONTH_DAY, locale);
  DateFormat.ABBR_MONTH_WEEKDAY_DAY([locale]) :
      this(ABBR_MONTH_WEEKDAY_DAY, locale);
  DateFormat.MONTH([locale]) : this(MONTH, locale);
  DateFormat.MONTH_DAY([locale]) : this(MONTH_DAY, locale);
  DateFormat.MONTH_WEEKDAY_DAY([locale]) : this(MONTH_WEEKDAY_DAY, locale);
  DateFormat.ABBR_QUARTER([locale]) : this(ABBR_QUARTER, locale);
  DateFormat.QUARTER([locale]) : this(QUARTER, locale);
  DateFormat.YEAR([locale]) : this(YEAR, locale);
  DateFormat.YEAR_NUM_MONTH([locale]) : this(YEAR_NUM_MONTH, locale);
  DateFormat.YEAR_NUM_MONTH_DAY([locale]) : this(YEAR_NUM_MONTH_DAY, locale);
  DateFormat.YEAR_NUM_MONTH_WEEKDAY_DAY([locale]) :
      this(YEAR_NUM_MONTH_WEEKDAY_DAY, locale);
  DateFormat.YEAR_ABBR_MONTH([locale]) : this(YEAR_ABBR_MONTH, locale);
  DateFormat.YEAR_ABBR_MONTH_DAY([locale]) : this(YEAR_ABBR_MONTH_DAY, locale);
  DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY([locale]) :
      this(YEAR_ABBR_MONTH_WEEKDAY_DAY, locale);
  DateFormat.YEAR_MONTH([locale]) : this(YEAR_MONTH, locale);
  DateFormat.YEAR_MONTH_DAY([locale]) : this(YEAR_MONTH_DAY, locale);
  DateFormat.YEAR_MONTH_WEEKDAY_DAY([locale]) :
      this(YEAR_MONTH_WEEKDAY_DAY, locale);
  DateFormat.YEAR_ABBR_QUARTER([locale]) : this(YEAR_ABBR_QUARTER, locale);
  DateFormat.YEAR_QUARTER([locale]) : this(YEAR_QUARTER, locale);
  DateFormat.HOUR24([locale]) : this(HOUR24, locale);
  DateFormat.HOUR24_MINUTE([locale]) : this(HOUR24_MINUTE, locale);
  DateFormat.HOUR24_MINUTE_SECOND([locale]) :
      this(HOUR24_MINUTE_SECOND, locale);
  DateFormat.HOUR([locale]) : this(HOUR, locale);
  DateFormat.HOUR_MINUTE([locale]) : this(HOUR_MINUTE, locale);
  DateFormat.HOUR_MINUTE_SECOND([locale]) : this(HOUR_MINUTE_SECOND, locale);
  DateFormat.HOUR_MINUTE_GENERIC_TZ([locale]) :
      this(HOUR_MINUTE_GENERIC_TZ, locale);
  DateFormat.HOUR_MINUTE_TZ([locale]) : this(HOUR_MINUTE_TZ, locale);
  DateFormat.HOUR_GENERIC_TZ([locale]) : this(HOUR_GENERIC_TZ, locale);
  DateFormat.HOUR_TZ([locale]) : this(HOUR_TZ, locale);
  DateFormat.MINUTE([locale]) : this(MINUTE, locale);
  DateFormat.MINUTE_SECOND([locale]) : this(MINUTE_SECOND, locale);
  DateFormat.SECOND([locale]) : this(SECOND, locale);

  DateFormat.d([locale]) : this("d", locale);
  DateFormat.E([locale]) : this("E", locale);
  DateFormat.EEEE([locale]) : this("EEEE", locale);
  DateFormat.LLL([locale]) : this("LLL", locale);
  DateFormat.LLLL([locale]) : this("LLLL", locale);
  DateFormat.M([locale]) : this("M", locale);
  DateFormat.Md([locale]) : this("Md", locale);
  DateFormat.MEd([locale]) : this("MEd", locale);
  DateFormat.MMM([locale]) : this("MMM", locale);
  DateFormat.MMMd([locale]) : this("MMMd", locale);
  DateFormat.MMMEd([locale]) : this("MMMEd", locale);
  DateFormat.MMMM([locale]) : this("MMMM", locale);
  DateFormat.MMMMd([locale]) : this("MMMMd", locale);
  DateFormat.MMMMEEEEd([locale]) : this("MMMMEEEEd", locale);
  DateFormat.QQQ([locale]) : this("QQQ", locale);
  DateFormat.QQQQ([locale]) : this("QQQQ", locale);
  DateFormat.y([locale]) : this("y", locale);
  DateFormat.yM([locale]) : this("yM", locale);
  DateFormat.yMd([locale]) : this("yMd", locale);
  DateFormat.yMEd([locale]) : this("yMEd", locale);
  DateFormat.yMMM([locale]) : this("yMMM", locale);
  DateFormat.yMMMd([locale]) : this("yMMMd", locale);
  DateFormat.yMMMEd([locale]) : this("yMMMEd", locale);
  DateFormat.yMMMM([locale]) : this("yMMMM", locale);
  DateFormat.yMMMMd([locale]) : this("yMMMMd", locale);
  DateFormat.yMMMMEEEEd([locale]) : this("yMMMMEEEEd", locale);
  DateFormat.yQQQ([locale]) : this("yQQQ", locale);
  DateFormat.yQQQQ([locale]) : this("yQQQQ", locale);
  DateFormat.H([locale]) : this("H", locale);
  DateFormat.Hm([locale]) : this("Hm", locale);
  DateFormat.Hms([locale]) : this("Hms", locale);
  DateFormat.j([locale]) : this("j", locale);
  DateFormat.jm([locale]) : this("jm", locale);
  DateFormat.jms([locale]) : this("jms", locale);
  DateFormat.jmv([locale]) : this("jmv", locale);
  DateFormat.jmz([locale]) : this("jmz", locale);
  DateFormat.jv([locale]) : this("jv", locale);
  DateFormat.jz([locale]) : this("jz", locale);
  DateFormat.m([locale]) : this("m", locale);
  DateFormat.ms([locale]) : this("ms", locale);
  DateFormat.s([locale]) : this("s", locale);

  /**
   * Methods for appending a particular skeleton to the format, or setting
   * it as the only format if none was previously set. These are primarily
   * useful for creating compound formats. For example
   *       new DateFormat.yMd().hms();
   * would create a date format that prints both the date and the time.
   */
  DateFormat d() => addPattern("d");
  DateFormat E() => addPattern("E");
  DateFormat EEEE() => addPattern("EEEE");
  DateFormat LLL() => addPattern("LLL");
  DateFormat LLLL() => addPattern("LLLL");
  DateFormat M() => addPattern("M");
  DateFormat Md() => addPattern("Md");
  DateFormat MEd() => addPattern("MEd");
  DateFormat MMM() => addPattern("MMM");
  DateFormat MMMd() => addPattern("MMMd");
  DateFormat MMMEd() => addPattern("MMMEd");
  DateFormat MMMM() => addPattern("MMMM");
  DateFormat MMMMd() => addPattern("MMMMd");
  DateFormat MMMMEEEEd() => addPattern("MMMMEEEEd");
  DateFormat QQQ() => addPattern("QQQ");
  DateFormat QQQQ() => addPattern("QQQQ");
  DateFormat y() => addPattern("y");
  DateFormat yM() => addPattern("yM");
  DateFormat yMd() => addPattern("yMd");
  DateFormat yMEd() => addPattern("yMEd");
  DateFormat yMMM() => addPattern("yMMM");
  DateFormat yMMMd() => addPattern("yMMMd");
  DateFormat yMMMEd() => addPattern("yMMMEd");
  DateFormat yMMMM() => addPattern("yMMMM");
  DateFormat yMMMMd() => addPattern("yMMMMd");
  DateFormat yMMMMEEEEd() => addPattern("yMMMMEEEEd");
  DateFormat yQQQ() => addPattern("yQQQ");
  DateFormat yQQQQ() => addPattern("yQQQQ");
  DateFormat H() => addPattern("H");
  DateFormat Hm() => addPattern("Hm");
  DateFormat Hms() => addPattern("Hms");
  DateFormat j() => addPattern("j");
  DateFormat jm() => addPattern("jm");
  DateFormat jms() => addPattern("jms");
  DateFormat jmv() => addPattern("jmv");
  DateFormat jmz() => addPattern("jmz");
  DateFormat jv() => addPattern("jv");
  DateFormat jz() => addPattern("jz");
  DateFormat m() => addPattern("m");
  DateFormat ms() => addPattern("ms");
  DateFormat s() => addPattern("s");

  /**
   * ICU constants for format names, resolving to the corresponding skeletons.
   */
  static const String DAY = 'd';
  static const String ABBR_WEEKDAY = 'E';
  static const String WEEKDAY = 'EEEE';
  static const String ABBR_STANDALONE_MONTH = 'LLL';
  static const String STANDALONE_MONTH = 'LLLL';
  static const String NUM_MONTH = 'M';
  static const String NUM_MONTH_DAY = 'Md';
  static const String NUM_MONTH_WEEKDAY_DAY = 'MEd';
  static const String ABBR_MONTH = 'MMM';
  static const String ABBR_MONTH_DAY = 'MMMd';
  static const String ABBR_MONTH_WEEKDAY_DAY = 'MMMEd';
  static const String MONTH = 'MMMM';
  static const String MONTH_DAY = 'MMMMd';
  static const String MONTH_WEEKDAY_DAY = 'MMMMEEEEd';
  static const String ABBR_QUARTER = 'QQQ';
  static const String QUARTER = 'QQQQ';
  static const String YEAR = 'y';
  static const String YEAR_NUM_MONTH = 'yM';
  static const String YEAR_NUM_MONTH_DAY = 'yMd';
  static const String YEAR_NUM_MONTH_WEEKDAY_DAY = 'yMEd';
  static const String YEAR_ABBR_MONTH = 'yMMM';
  static const String YEAR_ABBR_MONTH_DAY = 'yMMMd';
  static const String YEAR_ABBR_MONTH_WEEKDAY_DAY = 'yMMMEd';
  static const String YEAR_MONTH = 'yMMMM';
  static const String YEAR_MONTH_DAY = 'yMMMMd';
  static const String YEAR_MONTH_WEEKDAY_DAY = 'yMMMMEEEEd';
  static const String YEAR_ABBR_QUARTER = 'yQQQ';
  static const String YEAR_QUARTER = 'yQQQQ';
  static const String HOUR24 = 'H';
  static const String HOUR24_MINUTE = 'Hm';
  static const String HOUR24_MINUTE_SECOND = 'Hms';
  static const String HOUR = 'j';
  static const String HOUR_MINUTE = 'jm';
  static const String HOUR_MINUTE_SECOND = 'jms';
  static const String HOUR_MINUTE_GENERIC_TZ = 'jmv';
  static const String HOUR_MINUTE_TZ = 'jmz';
  static const String HOUR_GENERIC_TZ = 'jv';
  static const String HOUR_TZ = 'jz';
  static const String MINUTE = 'm';
  static const String MINUTE_SECOND = 'ms';
  static const String SECOND = 's';

  /** The locale in which we operate, e.g. 'en_US', or 'pt'. */
  String _locale;

  /**
   * The full template string. This may have been specified directly, or
   * it may have been derived from a skeleton and the locale information
   * on how to interpret that skeleton.
   */
  String _pattern;

  /**
   * We parse the format string into individual [_DateFormatField] objects
   * that are used to do the actual formatting and parsing. Do not use
   * this variable directly, use the getter [_formatFields].
   */
  List<_DateFormatField> _formatFieldsPrivate;

  /**
   * Getter for [_formatFieldsPrivate] that lazily initializes it.
   */
  get _formatFields() {
    if (_formatFieldsPrivate == null) {
      _formatFieldsPrivate = parsePattern(_pattern);
    }
    return _formatFieldsPrivate;
  }

  /**
   * A series of regular expressions used to parse a format string into its
   * component fields.
   */
  static var _matchers = const [
      // Quoted String - anything between single quotes, with escaping
      //   of single quotes by doubling them.
      // e.g. in the pattern "hh 'o''clock'" will match 'o''clock'
      const RegExp("^\'(?:[^\']|\'\')*\'"),
      // Fields - any sequence of 1 or more of the same field characters.
      // e.g. in "hh:mm:ss" will match hh, mm, and ss. But in "hms" would
      // match each letter individually.
      const RegExp(
        "^(?:G+|y+|M+|k+|S+|E+|a+|h+|K+|H+|c+|L+|Q+|d+|m+|s+|v+|z+|Z+)"),
      // Everything else - A sequence that is not quotes or field characters.
      // e.g. in "hh:mm:ss" will match the colons.
      const RegExp("^[^\'GyMkSEahKHcLQdmsvzZ]+")
  ];

  /**
   * Set our pattern, appending it to any existing patterns. Also adds a single
   * space to separate the two.
   */
  _setPattern(String inputPattern, [String separator = ' ']) {
    if (_pattern == null) {
      _pattern = inputPattern;
    } else {
      _pattern = "$_pattern$separator$inputPattern";
    }
  }

  /**
   * Add [inputPattern] to this instance as a pattern. If there was a previous
   * pattern, then this appends to it, separating the two by [separator].
   * [inputPattern] is first looked up in our list of known skeletons.
   * If it's found there, then use the corresponding pattern for this locale.
   * If it's not, then treat [inputPattern] as an explicit pattern.
   */
  DateFormat addPattern(String inputPattern, [String separator = ' ']) {
    // TODO(alanknight): This is an expensive operation. Caching recently used
    // formats, or possibly introducing an entire "locale" object that would
    // cache patterns for that locale could be a good optimization.
    if (!_availableSkeletons.containsKey(inputPattern)) {
      _setPattern(inputPattern, separator);
    } else {
      _setPattern(_availableSkeletons[inputPattern], separator);
    }
    // If we have already parsed the format fields, reset them.
    _formatFieldsPrivate = null;
    return this;
  }

  /** Return the pattern that we use to format dates.*/
  get pattern() => _pattern;

  /** Return the skeletons for our current locale. */
  Map get _availableSkeletons() {
    return dateTimePatterns[locale];
  }

  /**
   * Set the locale. If the locale can't be found, we also look up
   * based on alternative versions, e.g. if we have no 'en_CA' we will
   * look for 'en' as a fallback. It will also translate en-ca into en_CA.
   * Null is also considered a valid value for [newLocale], indicating
   * to use the default.
   */
  _setLocale(String newLocale) {
    _locale = Intl.verifiedLocale(newLocale);
  }

  /**
   * Return true if the locale exists, or if it is null. The null case
   * is interpreted to mean that we use the default locale.
   */
  static bool localeExists(localeName) {
    if (localeName == null) return false;
    return dateTimeSymbols.containsKey(localeName);
  }

  // TODO(alanknight): This can be a variable once that's permitted.
  static List get _fieldConstructors() => [
      (pattern, parent) => new _DateFormatQuotedField(pattern, parent),
      (pattern, parent) => new _DateFormatPatternField(pattern, parent),
      (pattern, parent) => new _DateFormatLiteralField(pattern, parent)];

  /** Parse the template pattern and return a list of field objects.*/
  List parsePattern(String pattern) {
    if (pattern == null) return null;
    return _reverse(_parsePatternHelper(pattern));
  }

  /** Recursive helper for parsing the template pattern. */
  List _parsePatternHelper(String pattern) {
    if (pattern.isEmpty()) return [];

    var matched = _match(pattern);
    if (matched == null) return [];

    var parsed = _parsePatternHelper(
                      pattern.substring(matched.fullPattern().length));
    parsed.add(matched);
    return parsed;
  }

  /** Find elements in a string that are patterns for specific fields.*/
  _DateFormatField _match(String pattern) {
    for (var i = 0; i < _matchers.length; i++) {
      var regex = _matchers[i];
      var match = regex.firstMatch(pattern);
      if (match != null) {
        return _fieldConstructors[i](match.group(0), this);
      }
    }
  }

  /** Polyfill for missing library function. */
  List _reverse(List list) {
    // TODO(alanknight): Use standardized list reverse when implemented.
    // See Issue 2804.
    var result = new List();
    for (var i = list.length-1; i >= 0; i--) {
      result.addLast(list[i]);
    }
    return result;
  }
}
