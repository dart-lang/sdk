// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This provides the class IntlMessage to represent an occurence of
 * [Intl.message] in a program. It is used when parsing sources to extract
 * messages or to generate code for message substitution.
 */
library intl_message;

/**
 * Represents an occurence of Intl.message in the program's source text. We
 * assemble it into an object that can be used to write out some translation
 * format and can also print itself into code.
 */
class IntlMessage {

  /**
   * This holds either Strings or ints representing the message. Literal
   * parts of the message are stored as strings. Interpolations are represented
   * by the index of the function parameter that they represent. When writing
   * out to a translation file format the interpolations must be turned
   * into the appropriate syntax, and the non-interpolated sections
   * may be modified. See [fullMessage].
   */
  // TODO(alanknight): This will need to be changed for plural support.
  List messagePieces;

  String description;

  /** The examples from the Intl.message call */
  String examples;

  /**
   * The name, which may come from the function name, from the arguments
   * to Intl.message, or we may just re-use the message.
   */
  String _name;

  /** The arguments parameter from the Intl.message call. */
  List<String> arguments;

  /**
   * A placeholder for any other identifier that the translation format
   * may want to use.
   */
  String id;

  /**
   * When generating code, we store translations for each locale
   * associated with the original message.
   */
  Map<String, String> translations = new Map();

  IntlMessage();

  /**
   * If the message was not given a name, we use the entire message string as
   * the name.
   */
  String get name => _name == null ? computeName() : _name;
  void set name(x) {_name = x;}
  String computeName() => name = fullMessage((msg, chunk) => "");

  /**
   * Return the full message, with any interpolation expressions transformed
   * by [f] and all the results concatenated. The argument to [f] may be
   * either a String or an int representing the index of a function parameter
   * that's being interpolated. See [messagePieces].
   */
  String fullMessage([Function f]) {
    var transform = f == null ? (msg, chunk) => chunk : f;
    var out = new StringBuffer();
    messagePieces.map((chunk) => transform(this, chunk)).forEach(out.write);
    return out.toString();
  }

  /**
   * The node will have the attribute names as strings, so we translate
   * between those and the fields of the class.
   */
  void operator []=(attributeName, value) {
    switch (attributeName) {
      case "desc" : description = value; return;
      case "examples" : examples = value; return;
      case "name" : name = value; return;
      // We use the actual args from the parser rather than what's given in the
      // arguments to Intl.message.
      case "args" : return;
      default: return;
    }
  }

  /**
   * Record the translation for this message in the given locale, after
   * suitably escaping it.
   */
  String addTranslation(locale, value) =>
      translations[locale] = escapeAndValidate(locale, value);

  /**
   * Escape the string and validate that it doesn't contain any interpolations
   * more complex than including a simple variable value.
   */
  String escapeAndValidate(String locale, String s) {
    const escapes = const {
      r"\" : r"\\",
      '"' : r'\"',
      "\b" : r"\b",
      "\f" : r"\f",
      "\n" : r"\n",
      "\r" : r"\r",
      "\t" : r"\t",
      "\v" : r"\v"
    };

    _escape(String s) => (escapes[s] == null) ? s : escapes[s];

    // We know that we'll be enclosing the string in double-quotes, so we need
    // to escape those, but not single-quotes. In addition we must escape
    // backslashes, newlines, and other formatting characters.
    var escaped = s.splitMapJoin("", onNonMatch: _escape);

    // We don't allow any ${} expressions, only $variable to avoid malicious
    // code. Disallow any usage of "${". If that makes a false positive
    // on a translation that legitimate contains "\\${" or other variations,
    // we'll live with that rather than risk a false negative.
    var validInterpolations = new RegExp(r"(\$\w+)|(\${\w+})");
    var validMatches = validInterpolations.allMatches(escaped);
    escapeInvalidMatches(Match m) {
      var valid = validMatches.any((x) => x.start == m.start);
      if (valid) {
        return m.group(0);
      } else {
        return "\\${m.group(0)}";
      }
    }
    return escaped.replaceAllMapped("\$", escapeInvalidMatches);
  }

  /**
   * Generate code for this message, expecting it to be part of a map
   * keyed by name with values the function that calls Intl.message.
   */
  String toCode(String locale) {
    var out = new StringBuffer();
    // These are statics because we want to closurize them into a map and
    // that doesn't work for instance methods.
    out.write('static $name(');
    out.write(arguments.join(", "));
    out.write(') => Intl.message("${translations[locale]}");');
    return out.toString();
  }

  /**
   * Escape the string to be used in the name, as a map key. So no double quotes
   * and no interpolation. Assumes that the string has no existing escaping.
   */
  String escapeForName(String s) {
    var escaped1 = s.replaceAll('"', r'\"');
    var escaped2 = escaped1.replaceAll('\$', r'\$');
    return escaped2;
  }

  String toString() =>
      "Intl.message(${fullMessage()}, $name, $description, $examples, "
          "$arguments)";
}