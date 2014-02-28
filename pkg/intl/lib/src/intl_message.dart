// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This provides classes to represent the internal structure of the
 * arguments to `Intl.message`. It is used when parsing sources to extract
 * messages or to generate code for message substitution. Normal programs
 * using Intl would not import this library.
 *
 * While it's written
 * in a somewhat abstract way, it has some assumptions about ICU-style
 * message syntax for parameter substitutions, choices, selects, etc.
 *
 * For example, if we have the message
 *      plurals(num) => Intl.message("""${Intl.plural(num,
 *          zero : 'Is zero plural?',
 *          one : 'This is singular.',
 *          other : 'This is plural ($num).')
 *         }""",
 *         name: "plurals", args: [num], desc: "Basic plurals");
 * That is represented as a MainMessage which has only one message component, a
 * Plural, but also has a name, list of arguments, and a description.
 * The Plural has three different clauses. The `zero` clause is
 * a LiteralString containing 'Is zero plural?'. The `other` clause is a
 * CompositeMessage containing three pieces, a LiteralString for
 * 'This is plural (', a VariableSubstitution for `num`. amd a LiteralString
 * for '.)'.
 *
 * This representation isn't used at runtime. Rather, we read some format
 * from a translation file, parse it into these objects, and they are then
 * used to generate the code representation above.
 */
library intl_message;

import 'package:analyzer/analyzer.dart';

/** A default function for the [Message.expanded] method. */
_nullTransform(msg, chunk) => chunk;

/**
 * An abstract superclass for Intl.message/plural/gender calls in the
 * program's source text. We
 * assemble these into objects that can be used to write out some translation
 * format and can also print themselves into code.
 */
abstract class Message {

  /**
   * All [Message]s except a [MainMessage] are contained inside some parent,
   * terminating at an Intl.message call which supplies the arguments we
   * use for variable substitutions.
   */
  Message parent;

  Message(this.parent);

  /**
   * We find the arguments from the top-level [MainMessage] and use those to
   * do variable substitutions. [MainMessage] overrides this to return
   * the actual arguments.
   */
  get arguments => parent == null ? const [] : parent.arguments;

  /**
   * We find the examples from the top-level [MainMessage] and use those
   * when writing out variables. [MainMessage] overrides this to return
   * the actual examples.
   */
  get examples => parent == null ? const [] : parent.examples;

  String checkValidity(MethodInvocation node, List arguments,
                       String outerName, FormalParameterList outerArgs) {
    var hasArgs = arguments.any(
        (each) => each is NamedExpression && each.name.label.name == 'args');
    var hasParameters = !outerArgs.parameters.isEmpty;
    if (!hasArgs && hasParameters) {
      return "The 'args' argument for Intl.message must be specified";
    }

    var messageName = arguments.firstWhere(
        (eachArg) => eachArg is NamedExpression &&
            eachArg.name.label.name == 'name',
        orElse: () => null);
    if (messageName == null) {
      return "The 'name' argument for Intl.message must be specified";
    }
    if (messageName.expression is! SimpleStringLiteral) {
      return "The 'name' argument for Intl.message must be a simple string "
          "literal.";
    }
    if (outerName != null && outerName != messageName.expression.value) {
      return "The 'name' argument for Intl.message must match "
          "the name of the containing function ("
          "'${messageName.expression.value}' vs. '$outerName')";
    }
    var simpleArguments = arguments.where(
        (each) => each is NamedExpression
        && ["desc", "name"].contains(each.name.label.name));
    var values = simpleArguments.map((each) => each.expression).toList();
    for (var arg in values) {
      if (arg is! StringLiteral) {
        return( "Intl.message arguments must be string literals: $arg");
      }
    }
    return null;
  }

  /**
   * Turn a value, typically read from a translation file or created out of an
   * AST for a source program, into the appropriate
   * subclass. We expect to get literal Strings, variable substitutions
   * represented by integers, things that are already MessageChunks and
   * lists of the same.
   */
  static Message from(value, Message parent) {
    if (value is String) return new LiteralString(value, parent);
    if (value is int) return new VariableSubstitution(value, parent);
    if (value is Iterable) {
      var result = new CompositeMessage([], parent);
      var items = value.map((x) => from(x, result)).toList();
      result.pieces.addAll(items);
      return result;
    }
    // We assume this is already a Message.
    value.parent = parent;
    return value;
  }

  /**
   * Return a string representation of this message for use in generated Dart
   * code.
   */
  String toCode();

  /**
   * Escape the string for use in generated Dart code and validate that it
   * doesn't  doesn't contain any illegal interpolations. We only allow
   * simple variables ("$foo", but not "${foo}") and Intl.gender/plural
   * calls.
   */
  String escapeAndValidateString(String value) {
    const escapes = const {
      r"\" : r"\\",
      '"' : r'\"',
      "\b" : r"\b",
      "\f" : r"\f",
      "\n" : r"\n",
      "\r" : r"\r",
      "\t" : r"\t",
      "\v" : r"\v",
      "'"  : r"\'",
    };

    _escape(String s) => (escapes[s] == null) ? s : escapes[s];

    var escaped = value.splitMapJoin("", onNonMatch: _escape);

    // We don't allow any ${} expressions, only $variable to avoid malicious
    // code. Disallow any usage of "${". If that makes a false positive
    // on a translation that legitimately contains "\\${" or other variations,
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
   * Expand this string out into a printed form. The function [f] will be
   * applied to any sub-messages, allowing this to be used to generate a form
   * suitable for a wide variety of translation file formats.
   */
  String expanded([Function f]);
}

/**
 * Abstract class for messages with internal structure, representing the
 * main Intl.message call, plurals, and genders.
 */
abstract class ComplexMessage extends Message {

  ComplexMessage(parent) : super(parent);

  /**
   * When we create these from strings or from AST nodes, we want to look up and
   * set their attributes by string names, so we override the indexing operators
   * so that they behave like maps with respect to those attribute names.
   */
  operator [](x);

  /**
   * When we create these from strings or from AST nodes, we want to look up and
   * set their attributes by string names, so we override the indexing operators
   * so that they behave like maps with respect to those attribute names.
   */
  operator []=(x, y);

  List<String> get attributeNames;

  /**
   * Return the name of the message type, as it will be generated into an
   * ICU-type format. e.g. choice, select
   */
  String get icuMessageName;

  /**
   * Return the message name we would use for this when doing Dart code
   * generation, e.g. "Intl.plural".
   */
  String get dartMessageName;
}

/**
 * This represents a message chunk that is a list of multiple sub-pieces,
 * each of which is in turn a [Message].
 */
class CompositeMessage extends Message {
  List<Message> pieces;

  CompositeMessage.withParent(parent) : super(parent);
  CompositeMessage(this.pieces, ComplexMessage parent) : super(parent) {
    pieces.forEach((x) => x.parent = this);
  }
  toCode() => pieces.map((each) => each.toCode()).join('');
  toString() => "CompositeMessage(" + pieces.toString() + ")";
  String expanded([Function f = _nullTransform]) =>
      pieces.map((chunk) => f(this, chunk)).join("");
}

/** Represents a simple constant string with no dynamic elements. */
class LiteralString extends Message {
  String string;
  LiteralString(this.string, Message parent) : super(parent);
  toCode() => escapeAndValidateString(string);
  toString() => "Literal($string)";
  String expanded([Function f = _nullTransform]) => f(this, string);
}

/**
 * Represents an interpolation of a variable value in a message. We expect
 * this to be specified as an [index] into the list of variables, or else
 * as the name of a variable that exists in [arguments] and we will
 * compute the variable name or the index based on the value of the other.
 */
class VariableSubstitution extends Message {
  VariableSubstitution(this._index, Message parent) : super(parent);

  /**
   * Create a substitution based on the name rather than the index. The name
   * may have been used as all upper-case in the translation tool, so we
   * save it separately and look it up case-insensitively once the parent
   * (and its arguments) are definitely available.
   */
  VariableSubstitution.named(String name, Message parent)
      : super(parent) {
    _variableNameUpper = name.toUpperCase();
  }

  /** The index in the list of parameters of the containing function. */
  int _index;
  int get index {
    if (_index != null) return _index;
    if (arguments.isEmpty) return null;
    // We may have been given an all-uppercase version of the name, so compare
    // case-insensitive.
    _index = arguments.map((x) => x.toUpperCase()).toList()
        .indexOf(_variableNameUpper);
    return _index;
  }

  /**
   * The variable name we get from parsing. This may be an all uppercase version
   * of the Dart argument name.
   */
  String _variableNameUpper;

  /**
   * The name of the variable in the parameter list of the containing function.
   * Used when generating code for the interpolation.
   */
  String get variableName =>
      _variableName == null ? _variableName = arguments[index] : _variableName;
  String _variableName;
  // Although we only allow simple variable references, we always enclose them
  // in curly braces so that there's no possibility of ambiguity with
  // surrounding text.
  toCode() => "\${${variableName}}";
  toString() => "VariableSubstitution($index)";
  String expanded([Function f = _nullTransform]) => f(this, index);
}

class MainMessage extends ComplexMessage {

  MainMessage() : super(null);

  /**
   * All the pieces of the message. When we go to print, these will
   * all be expanded appropriately. The exact form depends on what we're
   * printing it for See [expanded], [toCode].
   */
  List<Message> messagePieces = [];

  /** Verify that this looks like a correct Intl.message invocation. */
  String checkValidity(MethodInvocation node, List arguments,
      String outerName, FormalParameterList outerArgs) {
    if (arguments.first is! StringLiteral) {
      return "Intl.message messages must be string literals";
    }

    return super.checkValidity(node, arguments, outerName, outerArgs);
  }

  void addPieces(List<Message> messages) {
    for (var each in messages) {
      messagePieces.add(Message.from(each, this));
    }
  }

  /** The description provided in the Intl.message call. */
  String description;

  /** The examples from the Intl.message call */
  Map<String, dynamic> examples;

  /**
   * A field to disambiguate two messages that might have exactly the
   * same text. The two messages will also need different names, but
   * this can be used by machine translation tools to distinguish them.
   */
  String meaning;

  /**
   * The name, which may come from the function name, from the arguments
   * to Intl.message, or we may just re-use the message.
   */
  String _name;

  /**
   * A placeholder for any other identifier that the translation format
   * may want to use.
   */
  String id;

  /** The arguments list from the Intl.message call. */
  List arguments;

  /**
   * When generating code, we store translations for each locale
   * associated with the original message.
   */
  Map<String, String> translations = new Map();

  /**
   * If the message was not given a name, we use the entire message string as
   * the name.
   */
  String get name => _name == null ? computeName() : _name;
  set name(String newName) { _name = newName; }

  String computeName() => name = expanded((msg, chunk) => "");

  /**
   * Return the full message, with any interpolation expressions transformed
   * by [f] and all the results concatenated. The chunk argument to [f] may be
   * either a String, an int or an object representing a more complex
   * message entity.
   * See [messagePieces].
   */
  String expanded([Function f = _nullTransform]) =>
      messagePieces.map((chunk) => f(this, chunk)).join("");

  /**
   * Record the translation for this message in the given locale, after
   * suitably escaping it.
   */
  void addTranslation(String locale, Message translated) {
      translated.parent = this;
      translations[locale] = translated.toCode();
  }

  toCode() => throw
      new UnsupportedError("MainMessage.toCode requires a locale");

  /**
   * Generate code for this message, expecting it to be part of a map
   * keyed by name with values the function that calls Intl.message.
   */
  String toCodeForLocale(String locale) {
    var out = new StringBuffer()
      ..write('static $name(')
      ..write(arguments.join(", "))
      ..write(') => "')
      ..write(translations[locale])
      ..write('";');
    return out.toString();
  }

  /**
   * The AST node will have the attribute names as strings, so we translate
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
      case "meaning" : meaning = value; return;
      default: return;
    }
  }

  /**
   * The AST node will have the attribute names as strings, so we translate
   * between those and the fields of the class.
   */
  operator [](attributeName) {
    switch (attributeName) {
      case "desc" : return description;
      case "examples" : return examples;
      case "name" : return name;
      // We use the actual args from the parser rather than what's given in the
      // arguments to Intl.message.
      case "args" : return [];
      case "meaning" : return meaning;
      default: return null;
    }
  }

  // This is the top-level construct, so there's no meaningful ICU name.
  get icuMessageName => '';

  get dartMessageName => "message";

  /** The parameters that the Intl.message call may provide. */
  get attributeNames => const ["name", "desc", "examples", "args", "meaning"];

  String toString() =>
      "Intl.message(${expanded()}, $name, $description, $examples, $arguments)";
}

/**
 * An abstract class to represent sub-sections of a message, primarily
 * plurals and genders.
 */
abstract class SubMessage extends ComplexMessage {

  SubMessage() : super(null);

  /**
   * Creates the sub-message, given a list of [clauses] in the sort of form
   * that we're likely to get them from parsing a translation file format,
   * as a list of [key, value] where value may in turn be a list.
   */
  SubMessage.from(this.mainArgument, List clauses, parent) : super(parent) {
    for (var clause in clauses) {
      this[clause.first] = (clause.last is List) ? clause.last : [clause.last];
    }
  }

  toString() => expanded();

  /**
   * The name of the main argument, which is expected to have the value
   * which is one of [attributeNames] and is used to decide which clause to use.
   */
  String mainArgument;

  /**
   * Return the arguments that affect this SubMessage as a map of
   * argument names and values.
   */
  Map argumentsOfInterestFor(MethodInvocation node) {
    var basicArguments = node.argumentList.arguments;
    var others = basicArguments.where((each) => each is NamedExpression);
    return new Map.fromIterable(others,
        key: (node) => node.name.label.token.value(),
        value: (node) => node.expression);
  }

  /**
   * Return the list of attribute names to use when generating code. This
   *  may be different from [attributeNames] if there are multiple aliases
   *  that map to the same clause.
   */
  List<String> get codeAttributeNames;

  String expanded([Function transform = _nullTransform]) {
    fullMessageForClause(key) => key + '{' +
        transform(parent, this[key]).toString() + '}';
    var clauses = attributeNames
        .where((key) => this[key] != null)
        .map(fullMessageForClause).toList();
    return "{$mainArgument,$icuMessageName, ${clauses.join("")}}";
  }

  String toCode() {
    var out = new StringBuffer();
    out.write('\${');
    out.write(dartMessageName);
    out.write('(');
    out.write(mainArgument);
    var args = codeAttributeNames.where(
        (attribute) => this[attribute] != null);
    args.fold(out, (buffer, arg) => buffer..write(
        ", $arg: '${this[arg].toCode()}'"));
    out.write(")}");
    return out.toString();
  }
}

/**
 * Represents a message send of [Intl.gender] inside a message that is to
 * be internationalized. This corresponds to an ICU message syntax "select"
 * with "male", "female", and "other" as the possible options.
 */
class Gender extends SubMessage {

  Gender();
  /**
   * Create a new Gender providing [mainArgument] and the list of possible
   * clauses. Each clause is expected to be a list whose first element is a
   * variable name and whose second element is either a [String] or
   * a list of strings and [Message] or [VariableSubstitution].
   */
  Gender.from(String mainArgument, List clauses, Message parent) :
      super.from(mainArgument, clauses, parent);

  Message female;
  Message male;
  Message other;

  String get icuMessageName => "select";
  String get dartMessageName => 'Intl.gender';

  get attributeNames => ["female", "male", "other"];
  get codeAttributeNames => attributeNames;

  /**
   * The node will have the attribute names as strings, so we translate
   * between those and the fields of the class.
   */
  void operator []=(attributeName, rawValue) {
    var value = Message.from(rawValue, this);
    switch (attributeName) {
      case "female" : female = value; return;
      case "male" : male = value; return;
      case "other" : other = value; return;
      default: return;
    }
  }
  Message operator [](String attributeName) {
    switch (attributeName) {
      case "female" : return female;
      case "male" : return male;
      case "other" : return other;
      default: return other;
    }
  }
}

class Plural extends SubMessage {

   Plural();
   Plural.from(String mainArgument, List clauses, Message parent) :
     super.from(mainArgument, clauses, parent);

   Message zero;
   Message one;
   Message two;
   Message few;
   Message many;
   Message other;

   String get icuMessageName => "plural";
   String get dartMessageName => "Intl.plural";

   get attributeNames => ["=0", "=1", "=2", "few", "many", "other"];
   get codeAttributeNames => ["zero", "one", "two", "few", "many", "other"];

   /**
    * The node will have the attribute names as strings, so we translate
    * between those and the fields of the class.
    */
   void operator []=(String attributeName, rawValue) {
     var value = Message.from(rawValue, this);
     switch (attributeName) {
       case "zero" : zero = value; return;
       case "=0" : zero = value; return;
       case "one" : one = value; return;
       case "=1" : one = value; return;
       case "two" : two = value; return;
       case "=2" : two = value; return;
       case "few" : few = value; return;
       case "many" : many = value; return;
       case "other" : other = value; return;
       default: return;
     }
   }

   Message operator [](String attributeName) {
     switch (attributeName) {
       case "zero" : return zero;
       case "=0" : return zero;
       case "one" : return one;
       case "=1" : return one;
       case "two" : return two;
       case "=2" : return two;
       case "few" : return few;
       case "many" : return many;
       case "other" : return other;
       default: return other;
     }
   }
}

/**
 * Represents a message send of [Intl.select] inside a message that is to
 * be internationalized. This corresponds to an ICU message syntax "select"
 * with arbitrary options.
 */
class Select extends SubMessage {

  Select();
  /**
   * Create a new [Select] providing [mainArgument] and the list of possible
   * clauses. Each clause is expected to be a list whose first element is a
   * variable name and whose second element is either a String or
   * a list of strings and [Message]s or [VariableSubstitution]s.
   */
  Select.from(String mainArgument, List clauses, Message parent) :
      super.from(mainArgument, clauses, parent);

  Map<String, Message> cases = new Map<String, Message>();

  String get icuMessageName => "select";
  String get dartMessageName => 'Intl.select';

  get attributeNames => cases.keys;
  get codeAttributeNames => attributeNames;

  void operator []=(attributeName, rawValue) {
    var value = Message.from(rawValue, this);
    cases[attributeName] = value;
  }

  Message operator [](String attributeName) {
    var exact = cases[attributeName];
    return exact == null ? cases["other"] : exact;
  }

  /**
   * Return the arguments that we care about for the select. In this
   * case they will all be passed in as a Map rather than as the named
   * arguments used in Plural/Gender.
   */
  Map argumentsOfInterestFor(MethodInvocation node) {
    var casesArgument = node.argumentList.arguments[1];
    return new Map.fromIterable(casesArgument.entries,
      key: (node) => node.key.value,
      value: (node) => node.value);
  }

  /**
   * Write out the generated representation of this message. This differs
   * from Plural/Gender in that it prints a literal map rather than
   * named arguments.
   */
  String toCode() {
    var out = new StringBuffer();
    out.write('\${');
    out.write(dartMessageName);
    out.write('(');
    out.write(mainArgument);
    var args = codeAttributeNames;
    out.write(", {");
    args.fold(out, (buffer, arg) => buffer..write(
        "'$arg': '${this[arg].toCode()}', "));
    out.write("})}");
    return out.toString();
  }
}
