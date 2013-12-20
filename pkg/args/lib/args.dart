// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Parser support for transforming raw command-line arguments into a set
 * of options and values.
 *
 * This library supports [GNU][] and [POSIX][] style options, and it works
 * in both server-side and client-side apps.
 *
 * For information on installing this library, see the
 * [args package on pub.dartlang.org](http://pub.dartlang.org/packages/args).
 * Here's an example of importing this library:
 *
 *     import 'package:args/args.dart';
 *
 * ## Defining options
 *
 * To use this library, first create an [ArgParser]:
 *
 *     var parser = new ArgParser();
 *
 * Then define a set of options on that parser using [addOption()] and
 * [addFlag()]. Here's the minimal way to create an option named "name":
 *
 *     parser.addOption('name');
 *
 * When an option can only be set or unset (as opposed to taking a string
 * value), use a flag:
 *
 *     parser.addFlag('name');
 *
 * Flag options, by default, accept a 'no-' prefix to negate the option.
 * You can disable the 'no-' prefix using the `negatable` parameter:
 *
 *     parser.addFlag('name', negatable: false);
 *
 * **Terminology note:**
 * From here on out, the term _option_ refers to both regular options and
 * flags. In cases where the distinction matters, this documentation uses
 * the term _non-flag option._
 *
 * Options can have an optional single-character abbreviation, specified
 * with the `abbr` parameter:
 *
 *     parser.addOption('mode', abbr: 'm');
 *     parser.addFlag('verbose', abbr: 'v');
 *
 * Options can also have a default value, specified with the `defaultsTo`
 * parameter. The default value is used when arguments don't specify the
 * option.
 *
 *     parser.addOption('mode', defaultsTo: 'debug');
 *     parser.addFlag('verbose', defaultsTo: false);
 *
 * The default value for non-flag options can be any [String]. For flags,
 * it must be a [bool].
 *
 * To validate a non-flag option, you can use the `allowed` parameter to
 * provide an allowed set of values. When you do, the parser throws a
 * [FormatException] if the value for an option is not in the allowed set.
 * Here's an example of specifying allowed values:
 *
 *     parser.addOption('mode', allowed: ['debug', 'release']);
 *
 * You can use the `callback` parameter to associate a function with an
 * option. Later, when parsing occurs, the callback function is invoked
 * with the value of the option:
 *
 *     parser.addOption('mode', callback: (mode) => print('Got mode $mode));
 *     parser.addFlag('verbose', callback: (verbose) {
 *       if (verbose) print('Verbose');
 *     });
 *
 * The callbacks for all options are called whenever a set of arguments
 * is parsed. If an option isn't provided in the args, its callback is
 * passed the default value, or `null` if no default value is set.
 *
 * ## Parsing arguments
 *
 * Once you have an [ArgParser] set up with some options and flags, you
 * use it by calling [ArgParser.parse()] with a set of arguments:
 *
 *     var results = parser.parse(['some', 'command', 'line', 'args']);
 *
 * These arguments usually come from the arguments to main
 * (`main(List<String> arguments`), but you can pass in any list of strings.
 * The parse() method returns an instance of [ArgResults], a map-like
 * object that contains the values of the parsed options.
 *
 *     var parser = new ArgParser();
 *     parser.addOption('mode');
 *     parser.addFlag('verbose', defaultsTo: true);
 *     var results = parser.parse(['--mode', 'debug', 'something', 'else']);
 *
 *     print(results['mode']); // debug
 *     print(results['verbose']); // true
 *
 * By default, the parse() method stops as soon as it reaches `--` by itself
 * or anything that the parser doesn't recognize as an option, flag, or
 * option value. If arguments still remain, they go into [ArgResults.rest].
 *
 *     print(results.rest); // ['something', 'else']
 *
 * To continue to parse options found after non-option arguments, call
 * parse() with `allowTrailingOptions: true`.
 *
 * ## Specifying options
 *
 * To actually pass in options and flags on the command line, use GNU or
 * POSIX style. Consider this option:
 *
 *     parser.addOption('name', abbr: 'n');
 *
 * You can specify its value on the command line using any of the following:
 *
 *     --name=somevalue
 *     --name somevalue
 *     -nsomevalue
 *     -n somevalue
 *
 * Consider this flag:
 *
 *     parser.addFlag('name', abbr: 'n');
 *
 * You can set it to true using one of the following:
 *
 *     --name
 *     -n
 *
 * You can set it to false using the following:
 *
 *     --no-name
 *
 * Multiple flag abbreviations can be collapsed into a single argument. Say
 * you define these flags:
 *
 *     parser.addFlag('verbose', abbr: 'v');
 *     parser.addFlag('french', abbr: 'f');
 *     parser.addFlag('iambic-pentameter', abbr: 'i');
 *
 * You can set all three flags at once:
 *
 *     -vfi
 *
 * By default, an option has only a single value, with later option values
 * overriding earlier ones; for example:
 *
 *     var parser = new ArgParser();
 *     parser.addOption('mode');
 *     var results = parser.parse(['--mode', 'on', '--mode', 'off']);
 *     print(results['mode']); // prints 'off'
 *
 * If you need multiple values, set the `allowMultiple` parameter. In that
 * case the option can occur multiple times, and the parse() method returns
 * a list of values:
 *
 *     var parser = new ArgParser();
 *     parser.addOption('mode', allowMultiple: true);
 *     var results = parser.parse(['--mode', 'on', '--mode', 'off']);
 *     print(results['mode']); // prints '[on, off]'
 *
 * ## Defining commands ##
 *
 * In addition to *options*, you can also define *commands*. A command is
 * a named argument that has its own set of options. For example, consider
 * this shell command:
 *
 *     $ git commit -a
 *
 * The executable is `git`, the command is `commit`, and the `-a` option is
 * an option passed to the command. You can add a command using the
 * [addCommand] method:
 *
 *     var parser = new ArgParser();
 *     var command = parser.addCommand('commit');
 *
 * The addCommand() method returns another [ArgParser], which you can then
 * use to define options specific to that command. If you already have an
 * [ArgParser] for the command's options, you can pass it to addCommand:
 *
 *     var parser = new ArgParser();
 *     var command = new ArgParser();
 *     parser.addCommand('commit', command);
 *
 * The [ArgParser] for a command can then define options or flags:
 *
 *     command.addFlag('all', abbr: 'a');
 *
 * You can add multiple commands to the same parser so that a user can select
 * one from a range of possible commands. When parsing an argument list,
 * you can then determine which command was entered and what options were
 * provided for it.
 *
 *     var results = parser.parse(['commit', '-a']);
 *     print(results.command.name);   // "commit"
 *     print(results.command['all']); // true
 *
 * Options for a command must appear after the command in the argument list.
 * For example, given the above parser, "git -a commit" is *not* valid. The
 * parser tries to find the right-most command that accepts an option. For
 * example:
 *
 *     var parser = new ArgParser();
 *     parser.addFlag('all', abbr: 'a');
 *     var command = parser.addCommand('commit');
 *     command.addFlag('all', abbr: 'a');
 *
 *     var results = parser.parse(['commit', '-a']);
 *     print(results.command['all']); // true
 *
 * Here, both the top-level parser and the "commit" command can accept a
 * "-a" (which is probably a bad command line interface, admittedly). In
 * that case, when "-a" appears after "commit", it is applied to that
 * command. If it appears to the left of "commit", it is given to the
 * top-level parser.
 *
 * ## Displaying usage
 *
 * You can automatically generate nice help text, suitable for use as the
 * output of `--help`. To display good usage information, you should
 * provide some help text when you create your options.
 *
 * To define help text for an entire option, use the `help` parameter:
 *
 *     parser.addOption('mode', help: 'The compiler configuration',
 *         allowed: ['debug', 'release']);
 *     parser.addFlag('verbose', help: 'Show additional diagnostic info');
 *
 * For non-flag options, you can also provide detailed help for each expected
 * value by using the `allowedHelp` parameter:
 *
 *     parser.addOption('arch', help: 'The architecture to compile for',
 *         allowedHelp: {
 *           'ia32': 'Intel x86',
 *           'arm': 'ARM Holding 32-bit chip'
 *         });
 *
 * To display the help, use the ArgParser getUsage() method:
 *
 *     print(parser.getUsage());
 *
 * The resulting string looks something like this:
 *
 *     --mode            The compiler configuration
 *                       [debug, release]
 *
 *     --[no-]verbose    Show additional diagnostic info
 *     --arch            The architecture to compile for
 *
 *           [arm]       ARM Holding 32-bit chip
 *           [ia32]      Intel x86
 *
 * To assist the formatting of the usage help, single-line help text is
 * followed by a single new line. Options with multi-line help text are
 * followed by two new lines. This provides spatial diversity between options.
 *
 * [posix]: http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap12.html#tag_12_02
 * [gnu]: http://www.gnu.org/prep/standards/standards.html#Command_002dLine-Interfaces
 */
library args;

import 'package:collection/wrappers.dart';

import 'src/parser.dart';
import 'src/usage.dart';
import 'src/options.dart';
export 'src/options.dart';

/**
 * A class for taking a list of raw command line arguments and parsing out
 * options and flags from them.
 */
class ArgParser {
  final Map<String, Option> _options;
  final Map<String, ArgParser> _commands;

  /**
   * The options that have been defined for this parser.
   */
  final Map<String, Option> options;

  /**
   * The commands that have been defined for this parser.
   */
  final Map<String, ArgParser> commands;

  /** Creates a new ArgParser. */
  factory ArgParser() =>
      new ArgParser._(<String, Option>{}, <String, ArgParser>{});

  ArgParser._(Map<String, Option> options, Map<String, ArgParser> commands) :
    this._options = options,
    this.options = new UnmodifiableMapView(options),
    this._commands = commands,
    this.commands = new UnmodifiableMapView(commands);

  /**
   * Defines a command.
   *
   * A command is a named argument which may in turn define its own options and
   * subcommands using the given parser. If [parser] is omitted, implicitly
   * creates a new one. Returns the parser for the command.
   */
  ArgParser addCommand(String name, [ArgParser parser]) {
    // Make sure the name isn't in use.
    if (_commands.containsKey(name)) {
      throw new ArgumentError('Duplicate command "$name".');
    }

    if (parser == null) parser = new ArgParser();
    _commands[name] = parser;
    return parser;
  }

  /**
   * Defines a flag. Throws an [ArgumentError] if:
   *
   * * There is already an option named [name].
   * * There is already an option using abbreviation [abbr].
   */
  void addFlag(String name, {String abbr, String help, bool defaultsTo: false,
      bool negatable: true, void callback(bool value), bool hide: false}) {
    _addOption(name, abbr, help, null, null, defaultsTo, callback,
        isFlag: true, negatable: negatable, hide: hide);
  }

  /**
   * Defines a value-taking option. Throws an [ArgumentError] if:
   *
   * * There is already an option with name [name].
   * * There is already an option using abbreviation [abbr].
   */
  void addOption(String name, {String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, String defaultsTo,
      void callback(value), bool allowMultiple: false, bool hide: false}) {
    _addOption(name, abbr, help, allowed, allowedHelp, defaultsTo,
        callback, isFlag: false, allowMultiple: allowMultiple,
        hide: hide);
  }

  void _addOption(String name, String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, defaultsTo,
      void callback(value), {bool isFlag, bool negatable: false,
      bool allowMultiple: false, bool hide: false}) {
    // Make sure the name isn't in use.
    if (_options.containsKey(name)) {
      throw new ArgumentError('Duplicate option "$name".');
    }

    // Make sure the abbreviation isn't too long or in use.
    if (abbr != null) {
      var existing = findByAbbreviation(abbr);
      if (existing != null) {
        throw new ArgumentError(
            'Abbreviation "$abbr" is already used by "${existing.name}".');
      }
    }

    _options[name] = new Option(name, abbr, help, allowed, allowedHelp,
        defaultsTo, callback, isFlag: isFlag, negatable: negatable,
        allowMultiple: allowMultiple, hide: hide);
  }

  /**
   * Parses [args], a list of command-line arguments, matches them against the
   * flags and options defined by this parser, and returns the result.
   *
   * If [allowTrailingOptions] is set, the parser will continue parsing even
   * after it finds an argument that is neither an option nor a command.
   * This allows options to be specified after regular arguments.
   *
   * [allowTrailingOptions] is false by default, so when a non-option,
   * non-command argument is encountered, it and all remaining arguments,
   * even those that look like options are passed to the innermost command.
   */
  ArgResults parse(List<String> args, {bool allowTrailingOptions}) {
    if (allowTrailingOptions == null) allowTrailingOptions = false;
    return new Parser(null, this, args.toList(), null, null,
        allowTrailingOptions: allowTrailingOptions).parse();
  }

  /**
   * Generates a string displaying usage information for the defined options.
   * This is basically the help text shown on the command line.
   */
  String getUsage() => new Usage(this).generate();

  /**
   * Get the default value for an option. Useful after parsing to test
   * if the user specified something other than the default.
   */
  getDefault(String option) {
    if (!options.containsKey(option)) {
      throw new ArgumentError('No option named $option');
    }
    return options[option].defaultValue;
  }

  /**
   * Finds the option whose abbreviation is [abbr], or `null` if no option has
   * that abbreviation.
   */
  Option findByAbbreviation(String abbr) {
    return options.values.firstWhere((option) => option.abbreviation == abbr,
        orElse: () => null);
  }
}

/**
 * The results of parsing a series of command line arguments using
 * [ArgParser.parse()]. Includes the parsed options and any remaining unparsed
 * command line arguments.
 */
class ArgResults {
  final Map<String, dynamic> _options;

  /**
   * If these are the results for parsing a command's options, this will be
   * the name of the command. For top-level results, this returns `null`.
   */
  final String name;

  /**
   * The command that was selected, or `null` if none was. This will contain
   * the options that were selected for that command.
   */
  final ArgResults command;

  /**
   * The remaining command-line arguments that were not parsed as options or
   * flags. If `--` was used to separate the options from the remaining
   * arguments, it will not be included in this list.
   */
  final List<String> rest;

  /** Creates a new [ArgResults]. */
  ArgResults(this._options, this.name, this.command, List<String> rest)
    : this.rest = new UnmodifiableListView(rest);

  /** Gets the parsed command-line option named [name]. */
  operator [](String name) {
    if (!_options.containsKey(name)) {
      throw new ArgumentError(
          'Could not find an option named "$name".');
    }

    return _options[name];
  }

  /** Get the names of the options as an [Iterable]. */
  Iterable<String> get options => _options.keys;
}

