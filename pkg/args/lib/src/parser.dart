// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library args.src.parser;

import 'arg_parser.dart';
import 'arg_results.dart';
import 'option.dart';

final _SOLO_OPT = new RegExp(r'^-([a-zA-Z0-9])$');
final _ABBR_OPT = new RegExp(r'^-([a-zA-Z0-9]+)(.*)$');
final _LONG_OPT = new RegExp(r'^--([a-zA-Z\-_0-9]+)(=(.*))?$');

/// The actual argument parsing class.
///
/// Unlike [ArgParser] which is really more an "arg grammar", this is the class
/// that does the parsing and holds the mutable state required during a parse.
class Parser {
  /// If parser is parsing a command's options, this will be the name of the
  /// command. For top-level results, this returns `null`.
  final String commandName;

  /// The parser for the supercommand of this command parser, or `null` if this
  /// is the top-level parser.
  final Parser parent;

  /// The grammar being parsed.
  final ArgParser grammar;

  /// The arguments being parsed.
  final List<String> args;

  /// The remaining non-option, non-command arguments.
  final rest = <String>[];

  /// The accumulated parsed options.
  final Map<String, dynamic> results = <String, dynamic>{};

  Parser(this.commandName, this.grammar, this.args, this.parent, rest) {
    if (rest != null) this.rest.addAll(rest);
  }

  /// The current argument being parsed.
  String get current => args[0];

  /// Parses the arguments. This can only be called once.
  ArgResults parse() {
    var arguments = args.toList();
    var commandResults = null;

    // Parse the args.
    while (args.length > 0) {
      if (current == '--') {
        // Reached the argument terminator, so stop here.
        args.removeAt(0);
        break;
      }

      // Try to parse the current argument as a command. This happens before
      // options so that commands can have option-like names.
      var command = grammar.commands[current];
      if (command != null) {
        validate(rest.isEmpty, 'Cannot specify arguments before a command.');
        var commandName = args.removeAt(0);
        var commandParser = new Parser(commandName, command, args, this, rest);
        commandResults = commandParser.parse();

        // All remaining arguments were passed to command so clear them here.
        rest.clear();
        break;
      }

      // Try to parse the current argument as an option. Note that the order
      // here matters.
      if (parseSoloOption()) continue;
      if (parseAbbreviation(this)) continue;
      if (parseLongOption()) continue;

      // This argument is neither option nor command, so stop parsing unless
      // the [allowTrailingOptions] option is set.
      if (!grammar.allowTrailingOptions) break;
      rest.add(args.removeAt(0));
    }

    // Invoke the callbacks.
    grammar.options.forEach((name, option) {
      if (option.callback == null) return;
      option.callback(option.getOrDefault(results[name]));
    });

    // Add in the leftover arguments we didn't parse to the innermost command.
    rest.addAll(args);
    args.clear();
    return newArgResults(grammar, results, commandName, commandResults, rest,
        arguments);
  }

  /// Pulls the value for [option] from the second argument in [args].
  ///
  /// Validates that there is a valid value there.
  void readNextArgAsValue(Option option) {
    // Take the option argument from the next command line arg.
    validate(args.length > 0,
        'Missing argument for "${option.name}".');

    // Make sure it isn't an option itself.
    validate(!_ABBR_OPT.hasMatch(current) && !_LONG_OPT.hasMatch(current),
        'Missing argument for "${option.name}".');

    setOption(results, option, current);
    args.removeAt(0);
  }

  /// Tries to parse the current argument as a "solo" option, which is a single
  /// hyphen followed by a single letter.
  ///
  /// We treat this differently than collapsed abbreviations (like "-abc") to
  /// handle the possible value that may follow it.
  bool parseSoloOption() {
    var soloOpt = _SOLO_OPT.firstMatch(current);
    if (soloOpt == null) return false;

    var option = grammar.findByAbbreviation(soloOpt[1]);
    if (option == null) {
      // Walk up to the parent command if possible.
      validate(parent != null,
          'Could not find an option or flag "-${soloOpt[1]}".');
      return parent.parseSoloOption();
    }

    args.removeAt(0);

    if (option.isFlag) {
      setOption(results, option, true);
    } else {
      readNextArgAsValue(option);
    }

    return true;
  }

  /// Tries to parse the current argument as a series of collapsed abbreviations
  /// (like "-abc") or a single abbreviation with the value directly attached
  /// to it (like "-mrelease").
  bool parseAbbreviation(Parser innermostCommand) {
    var abbrOpt = _ABBR_OPT.firstMatch(current);
    if (abbrOpt == null) return false;

    // If the first character is the abbreviation for a non-flag option, then
    // the rest is the value.
    var c = abbrOpt[1].substring(0, 1);
    var first = grammar.findByAbbreviation(c);
    if (first == null) {
      // Walk up to the parent command if possible.
      validate(parent != null,
          'Could not find an option with short name "-$c".');
      return parent.parseAbbreviation(innermostCommand);
    } else if (!first.isFlag) {
      // The first character is a non-flag option, so the rest must be the
      // value.
      var value = '${abbrOpt[1].substring(1)}${abbrOpt[2]}';
      setOption(results, first, value);
    } else {
      // If we got some non-flag characters, then it must be a value, but
      // if we got here, it's a flag, which is wrong.
      validate(abbrOpt[2] == '',
        'Option "-$c" is a flag and cannot handle value '
        '"${abbrOpt[1].substring(1)}${abbrOpt[2]}".');

      // Not an option, so all characters should be flags.
      // We use "innermostCommand" here so that if a parent command parses the
      // *first* letter, subcommands can still be found to parse the other
      // letters.
      for (var i = 0; i < abbrOpt[1].length; i++) {
        var c = abbrOpt[1].substring(i, i + 1);
        innermostCommand.parseShortFlag(c);
      }
    }

    args.removeAt(0);
    return true;
  }

  void parseShortFlag(String c) {
    var option = grammar.findByAbbreviation(c);
    if (option == null) {
      // Walk up to the parent command if possible.
      validate(parent != null,
          'Could not find an option with short name "-$c".');
      parent.parseShortFlag(c);
      return;
    }

    // In a list of short options, only the first can be a non-flag. If
    // we get here we've checked that already.
    validate(option.isFlag,
        'Option "-$c" must be a flag to be in a collapsed "-".');

    setOption(results, option, true);
  }

  /// Tries to parse the current argument as a long-form named option, which
  /// may include a value like "--mode=release" or "--mode release".
  bool parseLongOption() {
    var longOpt = _LONG_OPT.firstMatch(current);
    if (longOpt == null) return false;

    var name = longOpt[1];
    var option = grammar.options[name];
    if (option != null) {
      args.removeAt(0);
      if (option.isFlag) {
        validate(longOpt[3] == null,
            'Flag option "$name" should not be given a value.');

        setOption(results, option, true);
      } else if (longOpt[3] != null) {
        // We have a value like --foo=bar.
        setOption(results, option, longOpt[3]);
      } else {
        // Option like --foo, so look for the value as the next arg.
        readNextArgAsValue(option);
      }
    } else if (name.startsWith('no-')) {
      // See if it's a negated flag.
      name = name.substring('no-'.length);
      option = grammar.options[name];
      if (option == null) {
        // Walk up to the parent command if possible.
        validate(parent != null, 'Could not find an option named "$name".');
        return parent.parseLongOption();
      }

      args.removeAt(0);
      validate(option.isFlag, 'Cannot negate non-flag option "$name".');
      validate(option.negatable, 'Cannot negate option "$name".');

      setOption(results, option, false);
    } else {
      // Walk up to the parent command if possible.
      validate(parent != null, 'Could not find an option named "$name".');
      return parent.parseLongOption();
    }

    return true;
  }

  /// Called during parsing to validate the arguments.
  ///
  /// Throws a [FormatException] if [condition] is `false`.
  void validate(bool condition, String message) {
    if (!condition) throw new FormatException(message);
  }

  /// Validates and stores [value] as the value for [option].
  void setOption(Map results, Option option, value) {
    // See if it's one of the allowed values.
    if (option.allowed != null) {
      validate(option.allowed.any((allow) => allow == value),
          '"$value" is not an allowed value for option "${option.name}".');
    }

    if (option.isMultiple) {
      var list = results.putIfAbsent(option.name, () => []);
      list.add(value);
    } else {
      results[option.name] = value;
    }
  }
}
