// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Message/plural format library with locale support. This can have different
 * implementations based on the mechanism for finding the localized versions
 * of messages. This version expects them to be in a library named e.g.
 * 'messages_en_US'. The prefix is set in the [initializeMessages] call, which
 * must be made for a locale before any lookups can be done.
 *
 *
 * _message example:
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
 * See tests/message_format_test.dart for more examples.
 */
 //TODO(efortuna): documentation example involving the offset parameter?

#library('message_lookup_local');

#import('intl.dart');
#import('dart:mirrors');

/**
 * Initialize the user messages for [localeName]. Note that this is an ASYNC
 * operation. This must be called before attempting to use messages in
 * [localeName].
 */
Future initializeMessages(localeName, [String source = 'messages_']) {
  initializeInternalMessageLookup(
      () => new MessageLookupLocal(localeName, source));
  _initializeMessagesForLocale(localeName);
  return new Future.immediate(null);
}

void _initializeMessagesForLocale(String localeName) {}

class MessageLookupLocal {
  /** Prevent infinite recursion when looking up the message. */
  bool _lookupInProgress = false;

  /** The libraries we can look in for internationalization messages. */
  Map<String, LibraryMirror> _libraries;

  /** The prefix used to find libraries that contain localized messages.
   * So, if this is 'messages_' we would look for messages for the locale
   * 'pt_BR' in a library named 'messages_pt_BR'.
   */
  String _sourcePrefix;

  /**
   * Constructor. The [localeName] is of the form 'en' or 'en_US'.
   *The [source] parameter defines the prefix that is used to find
   * libraries that contain localized messages. So with the default value of
   * 'messages_', we would look for messages for the locale 'pt_BR' in a library
   * named 'messages_pt_BR'.
   */
  MessageLookupLocal(String localeName, this._sourcePrefix) {
    _libraries = currentMirrorSystem().libraries;
  }

  /**
   * Return the localized version of a message. We are passed the original
   * version of the message, which consists of a
   * [message_str] that will be translated, and which may be interpolated
   * based on one or more variables, a [desc] providing a description of usage
   * for the [message_str], and a map of [examples] for each data element to be
   * substituted into the message.
   *
   * For example, if message="Hello, $name", then
   * examples = {'name': 'Sparky'}. If not using the user's default locale, or
   * if the locale is not easily detectable, explicitly pass [locale].
   *
   * The values of [desc] and [examples] are not used at run-time but are only
   * made available to the translators, so they MUST be simple Strings available
   * at compile time: no String interpolation or concatenation.
   * The expected usage of this is inside a function that takes as parameters
   * the variables used in the interpolated string.
   *
   * Ultimately, the information about the enclosing function and its arguments
   * will be extracted automatically but for the time being it must be passed
   * explicitly in the [name] and [args] arguments.
   */
  String lookupMessage(String message_str, [final String desc='',
      final Map examples=const {}, String locale,
      String name, List<String> args]) {
    if (name == null) return message_str;
    // The translations also make use of Intl.message, so we need to not
    // recurse and just stop when we find the first substitution.
    if (_lookupInProgress) return message_str;
    _lookupInProgress = true;
    var result;
    try {
      // TODO(alanknight): Look up alternate forms, e.g. en for en_US
      var actualLocale = (locale == null) ? Intl.getCurrentLocale() : locale;
      LibraryMirror messagesForThisLocale =
          _libraries['$_sourcePrefix$actualLocale'];
      if (messagesForThisLocale == null) return message_str;
      MethodMirror localized = messagesForThisLocale.functions[name];
      if (localized == null) return message_str;
      result = messagesForThisLocale.invoke(localized.simpleName, args);
      }
    finally {
      _lookupInProgress = false;
    }
    return result.value.reflectee;
  }
}