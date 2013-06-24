// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library lets you define parsers for parsing raw command-line arguments
 * into a set of options and values using [GNU][] and [POSIX][] style options.
 *
 * ## Installing ##
 *
 * Use [pub][] to install this package. Add the following to your `pubspec.yaml`
 * file.
 *
 *     dependencies:
 *       args: any
 *
 * Then run `pub install`.
 *
 * For more information, see the
 * [args package on pub.dartlang.org](http://pub.dartlang.org/packages/args).
 *
 * ## Defining options ##
 *
 * To use this library, you create an [ArgParser] object which will contain
 * the set of options you support:
 *
 *     var parser = new ArgParser();
 *
 * Then you define a set of options on that parser using [addOption()] and
 * [addFlag()]. The minimal way to create an option is:
 *
 *     parser.addOption('name');
 *
 * This creates an option named "name". Options must be given a value on the
 * command line. If you have a simple on/off flag, you can instead use:
 *
 *     parser.addFlag('name');
 *
 * Flag options will, by default, accept a 'no-' prefix to negate the option.
 * This can be disabled like so:
 *
 *     parser.addFlag('name', negatable: false);
 *
 * (From here on out "option" will refer to both "regular" options and flags.
 * In cases where the distinction matters, we'll use "non-flag option".)
 *
 * Options may have an optional single-character abbreviation:
 *
 *     parser.addOption('mode', abbr: 'm');
 *     parser.addFlag('verbose', abbr: 'v');
 *
 * They may also specify a default value. The default value will be used if the
 * option isn't provided:
 *
 *     parser.addOption('mode', defaultsTo: 'debug');
 *     parser.addFlag('verbose', defaultsTo: false);
 *
 * The default value for non-flag options can be any [String]. For flags, it
 * must be a [bool].
 *
 * To validate non-flag options, you may provide an allowed set of values. When
 * you do, it will throw a [FormatException] when you parse the arguments if
 * the value for an option is not in the allowed set:
 *
 *     parser.addOption('mode', allowed: ['debug', 'release']);
 *
 * You can provide a callback when you define an option. When you later parse
 * a set of arguments, the callback for that option will be invoked with the
 * value provided for it:
 *
 *     parser.addOption('mode', callback: (mode) => print('Got mode $mode));
 *     parser.addFlag('verbose', callback: (verbose) {
 *       if (verbose) print('Verbose');
 *     });
 *
 * The callback for each option will *always* be called when you parse a set of
 * arguments. If the option isn't provided in the args, the callback will be
 * passed the default value, or `null` if there is none set.
 *
 * ## Parsing arguments ##
 *
 * Once you have an [ArgParser] set up with some options and flags, you use it
 * by calling [ArgParser.parse()] with a set of arguments:
 *
 *     var results = parser.parse(['some', 'command', 'line', 'args']);
 *
 * These will usually come from `new Options().arguments`, but you can pass in
 * any list of strings. It returns an instance of [ArgResults]. This is a
 * map-like object that will return the value of any parsed option.
 *
 *     var parser = new ArgParser();
 *     parser.addOption('mode');
 *     parser.addFlag('verbose', defaultsTo: true);
 *     var results = parser.parse('['--mode', 'debug', 'something', 'else']);
 *
 *     print(results['mode']); // debug
 *     print(results['verbose']); // true
 *
 * The [parse()] method will stop as soon as it reaches `--` or anything that
 * it doesn't recognize as an option, flag, or option value. If there are still
 * arguments left, they will be provided to you in
 * [ArgResults.rest].
 *
 *     print(results.rest); // ['something', 'else']
 *
 * ## Specifying options ##
 *
 * To actually pass in options and flags on the command line, use GNU or POSIX
 * style. If you define an option like:
 *
 *     parser.addOption('name', abbr: 'n');
 *
 * Then a value for it can be specified on the command line using any of:
 *
 *     --name=somevalue
 *     --name somevalue
 *     -nsomevalue
 *     -n somevalue
 *
 * Given this flag:
 *
 *     parser.addFlag('name', abbr: 'n');
 *
 * You can set it on using one of:
 *
 *     --name
 *     -n
 *
 * Or set it off using:
 *
 *     --no-name
 *
 * Multiple flag abbreviation can also be collapsed into a single argument. If
 * you define:
 *
 *     parser.addFlag('verbose', abbr: 'v');
 *     parser.addFlag('french', abbr: 'f');
 *     parser.addFlag('iambic-pentameter', abbr: 'i');
 *
 * Then all three flags could be set using:
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
 * If you need multiple values, set the [allowMultiple] flag. In that
 * case the option can occur multiple times and when parsing arguments a
 * List of values will be returned:
 *
 *     var parser = new ArgParser();
 *     parser.addOption('mode', allowMultiple: true);
 *     var results = parser.parse(['--mode', 'on', '--mode', 'off']);
 *     print(results['mode']); // prints '[on, off]'
 *
 * ## Defining commands ##
 *
 * In addition to *options*, you can also define *commands*. A command is a
 * named argument that has its own set of options. For example, when you run:
 *
 *     $ git commit -a
 *
 * The executable is `git`, the command is `commit`, and the `-a` option is an
 * option passed to the command. You can add a command like so:
 *
 *     var parser = new ArgParser();
 *     var command = parser.addCommand('commit');
 *
 * It returns another [ArgParser] which you can then use to define options
 * specific to that command. If you already have an [ArgParser] for the
 * command's options, you can pass it to [addCommand]:
 *
 *     var parser = new ArgParser();
 *     var command = new ArgParser();
 *     parser.addCommand('commit', command);
 *
 * The [ArgParser] for a command can then define whatever options or flags:
 *
 *     command.addFlag('all', abbr: 'a');
 *
 * You can add multiple commands to the same parser so that a user can select
 * one from a range of possible commands. When an argument list is parsed,
 * you can then determine which command was entered and what options were
 * provided for it.
 *
 *     var results = parser.parse(['commit', '-a']);
 *     print(results.command.name); // "commit"
 *     print(results.command['a']); // true
 *
 * Options for a command must appear after the command in the argument list.
 * For example, given the above parser, "git -a commit" is *not* valid. The
 * parser will try to find the right-most command that accepts an option. For
 * example:
 *
 *     var parser = new ArgParser();
 *     parser.addFlag('all', abbr: 'a');
 *     var command = new ArgParser().addCommand('commit');
 *     parser.addFlag('all', abbr: 'a');
 *     var results = parser.parse(['commit', '-a']);
 *     print(results.command['a']); // true
 *
 * Here, both the top-level parser and the "commit" command can accept a "-a"
 * (which is probably a bad command line interface, admittedly). In that case,
 * when "-a" appears after "commit", it will be applied to that command. If it
 * appears to the left of "commit", it will be given to the top-level parser.
 *
 * ## Displaying usage ##
 *
 * This library can also be used to automatically generate nice usage help
 * text like you get when you run a program with `--help`. To use this, you
 * will also want to provide some help text when you create your options. To
 * define help text for the entire option, do:
 *
 *     parser.addOption('mode', help: 'The compiler configuration',
 *         allowed: ['debug', 'release']);
 *     parser.addFlag('verbose', help: 'Show additional diagnostic info');
 *
 * For non-flag options, you can also provide detailed help for each expected
 * value using a map:
 *
 *     parser.addOption('arch', help: 'The architecture to compile for',
 *         allowedHelp: {
 *           'ia32': 'Intel x86',
 *           'arm': 'ARM Holding 32-bit chip'
 *         });
 *
 * If you define a set of options like the above, then calling this:
 *
 *     print(parser.getUsage());
 *
 * Will display something like:
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
 * To assist the formatting of the usage help, single line help text will
 * be followed by a single new line. Options with multi-line help text
 * will be followed by two new lines. This provides spatial diversity between
 * options.
 *
 * [posix]: http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap12.html#tag_12_02
 * [gnu]: http://www.gnu.org/prep/standards/standards.html#Command_002dLine-Interfaces
 * [pub]: http://pub.dartlang.org
 */
library args;

import 'src/parser.dart';
import 'src/usage.dart';
import 'src/options.dart';
export 'src/options.dart';

/**
 * A class for taking a list of raw command line arguments and parsing out
 * options and flags from them.
 */
class ArgParser {
  /**
   * The options that have been defined for this parser.
   */
  final Map<String, Option> options = <String, Option>{};

  /**
   * The commands that have been defined for this parser.
   */
  final Map<String, ArgParser> commands = <String, ArgParser>{};

  /** Creates a new ArgParser. */
  ArgParser();

  /**
   * Defines a command.
   *
   * A command is a named argument which may in turn define its own options and
   * subcommands using the given parser. If [parser] is omitted, implicitly
   * creates a new one. Returns the parser for the command.
   */
  ArgParser addCommand(String name, [ArgParser parser]) {
    // Make sure the name isn't in use.
    if (commands.containsKey(name)) {
      throw new ArgumentError('Duplicate command "$name".');
    }

    if (parser == null) parser = new ArgParser();
    commands[name] = parser;
    return parser;
  }

  /**
   * Defines a flag. Throws an [ArgumentError] if:
   *
   * * There is already an option named [name].
   * * There is already an option using abbreviation [abbr].
   */
  void addFlag(String name, {String abbr, String help, bool defaultsTo: false,
      bool negatable: true, void callback(bool value)}) {
    _addOption(name, abbr, help, null, null, defaultsTo, callback,
        isFlag: true, negatable: negatable);
  }

  /**
   * Defines a value-taking option. Throws an [ArgumentError] if:
   *
   * * There is already an option with name [name].
   * * There is already an option using abbreviation [abbr].
   */
  void addOption(String name, {String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, String defaultsTo,
      void callback(value), bool allowMultiple: false}) {
    _addOption(name, abbr, help, allowed, allowedHelp, defaultsTo,
        callback, isFlag: false, allowMultiple: allowMultiple);
  }

  void _addOption(String name, String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, defaultsTo,
      void callback(value), {bool isFlag, bool negatable: false,
      bool allowMultiple: false}) {
    // Make sure the name isn't in use.
    if (options.containsKey(name)) {
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

    options[name] = new Option(name, abbr, help, allowed, allowedHelp,
        defaultsTo, callback, isFlag: isFlag, negatable: negatable,
        allowMultiple: allowMultiple);
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
  final Map _options;

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
  ArgResults(this._options, this.name, this.command, this.rest);

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

