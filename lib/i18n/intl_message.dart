// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Message/plural format library with locale support.
 *
 *
 * _message example:
 *    '''I see ${Intl.plural(num_people,
 *             {'0': 'no one at all',
 *              '1': 'one other person',
 *              'other': '$num_people other people'})} in $place.''''
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
 * <!-- TODO(efortuna): documentation example involving the offset parameter.
 * -->
 *
 * See tests/message_format_test.dart for more examples.
 */

#library('intl_message');

class IntlMessage {

  /** String describing the use case for this message. */
  String _messageDescription;

  /**
   * String that contains the message to be displayed. It may contain
   * placeholders in the form of string interpolated items (ie 'hello$foo') that
   * will be substituted in to complete the message.
   * See tests/message_format_test.dart for more examples.
   */
  String _message;

  /**
   * String indicating the locale code with which the message is to be
   * formatted (such as en-CA).
   */
  String _languageCode;

  /** Examples of the placeholders used in the message string. */
  Map _messageExamples;

  /**
   * Accepts a String [_message] that contains the message (that
   * will be internationalized). A String [_messageDescription] describes the
   * use case for this string in the program, and [examples] provides a map of
   * examples for the items (if any) to be subsituted into [_message].
   * It also optionally accepts a [_languageCode] to specify the particular
   * language to return content in (necessary if the Dart code is not running in
   * a browser). The values of [desc] and [examples] *must* be
   * simple Strings available at compile time: no String interpolation or
   * concatenation.
   */
  IntlMessage(this._message, [final String desc='', final Map examples=const {},
              final String locale='']) {
    this._messageDescription = desc;
    this._messageExamples = examples;
    this._languageCode = locale;
  }

}
