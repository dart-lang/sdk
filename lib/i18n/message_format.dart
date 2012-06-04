/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * Message/plural format library with locale support.
 *
 * Message format grammar:
 *
 *    messageFormatPattern := string ( "{" messageFormatElement "}" string )*
 *    messageFormatElement := argumentIndex [ "," elementFormat ]
 *    elementFormat := "plural" "," pluralStyle
 *                      | "select" "," selectStyle
 *    pluralStyle :=  pluralFormatPattern
 *    selectStyle :=  selectFormatPattern
 *    pluralFormatPattern := \\[ "offset" ":" offsetIndex ] pluralForms*
 *    selectFormatPattern := pluralForms*
 *    pluralForms := stringKey "{" ( "{" messageFormatElement "}"|string )* "}"
 *
 *
 * Message example:
 *
 * I see {NUM_PEOPLE, plural, offset:1
 *         =0 {no one at all}
 *         =1 {{WHO}}
 *         one {{WHO} and one other person}
 *         other {{WHO} and # other people}}
 * in {PLACE}.
 *
 * Calling format({'NUM_PEOPLE': 2, 'WHO': 'Mark', 'PLACE': 'Athens'}) would
 * produce "I see Mark and one other person in Athens." as output.
 *
 * See tests/message_format_test.dart for more examples.
 */

#library('MessageFormat');

class MessageFormat {

  /**
   * String that is used to determin the particular case and gender needed to be
   * returned. The format of this string follows the same pattern as in Closure,
   * Java, and C++. This pattern is described at the beginning of this class
   * definition. See tests/message_format_test.dart for more examples.
   */
  final String _messageFunction;

  /**
   * String indicating a language code with which the message is to be
   * formatted (such as en-US).
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
  const MessageFormat(this._messageFunction, [this._locale = 'en-US']);

  /**
   * Formats a message. By default, we treat '#' with special meaning
   * representing the number (plural_variable - plural_offset). If [ignorePound]
   * is true, then we do not treat '#' as a special character, and it is just
   * treated literally. [namedParameters] is a map of String keys to String or
   * int values to influence the formatting of the message or data in the
   * message. For example, example, in the call to 
   *     msg_formatter.format({'NUM_PEOPLE': 5, 'NAME': 'Angela'}),
   * object \{'NUM_PEOPLE': 5, 'NAME': 'Angela'\} holds positional parameters.
   * 1st parameter could mean 5 people, which could influence plural format,
   * and 2nd parameter is just relevant data to be printed out in the proper
   * position in the message.
   * Returns the correctly formatted message in the desired language.
   */
  String format(Map<String, dynamic> messageParameters,
                [bool ignorePound=false]) {
    // TODO(efortuna): actually perform the translation here. For now, I'm just
    // returning a description of the message to be returned.
    return _messageDescription;
  }
}
