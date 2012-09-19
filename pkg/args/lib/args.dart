// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library lets you define parsers for parsing raw command-line arguments
 * into a set of options and values using [GNU][] and [POSIX][] style options.
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
 * ## Usage ##
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
 * [posix]: http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap12.html#tag_12_02
 * [gnu]: http://www.gnu.org/prep/standards/standards.html#Command_002dLine-Interfaces
 */
#library('args');

#import('dart:math');

// TODO(rnystrom): Use "package:" URL here when test.dart can handle pub.
#import('src/utils.dart');

/**
 * A class for taking a list of raw command line arguments and parsing out
 * options and flags from them.
 */
class ArgParser {
  static const _SOLO_OPT = const RegExp(@'^-([a-zA-Z0-9])$');
  static const _ABBR_OPT = const RegExp(@'^-([a-zA-Z0-9]+)(.*)$');
  static const _LONG_OPT = const RegExp(@'^--([a-zA-Z\-_0-9]+)(=(.*))?$');

  final Map<String, _Option> _options;

  /**
   * The names of the options, in the order that they were added. This way we
   * can generate usage information in the same order.
   */
  // TODO(rnystrom): Use an ordered map type, if one appears.
  final List<String> _optionNames;

  /** The current argument list being parsed. Set by [parse()]. */
  List<String> _args;

  /** Index of the current argument being parsed in [_args]. */
  int _current;

  /** Creates a new ArgParser. */
  ArgParser()
    : _options = <String, _Option>{},
      _optionNames = <String>[];

  /**
   * Defines a flag. Throws an [IllegalArgumentException] if:
   *
   * * There is already an option named [name].
   * * There is already an option using abbreviation [abbr].
   */
  void addFlag(String name, [String abbr, String help, bool defaultsTo = false,
      bool negatable = true, void callback(bool value)]) {
    _addOption(name, abbr, help, null, null, defaultsTo, callback,
        isFlag: true, negatable: negatable);
  }

  /**
   * Defines a value-taking option. Throws an [IllegalArgumentException] if:
   *
   * * There is already an option with name [name].
   * * There is already an option using abbreviation [abbr].
   */
  void addOption(String name, [String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, String defaultsTo,
      void callback(value), bool allowMultiple = false]) {
    _addOption(name, abbr, help, allowed, allowedHelp, defaultsTo,
        callback, isFlag: false, allowMultiple: allowMultiple);
  }

  void _addOption(String name, String abbr, String help, List<String> allowed,
      Map<String, String> allowedHelp, defaultsTo,
      void callback(value), [bool isFlag, bool negatable = false,
      bool allowMultiple = false]) {
    // Make sure the name isn't in use.
    if (_options.containsKey(name)) {
      throw new IllegalArgumentException('Duplicate option "$name".');
    }

    // Make sure the abbreviation isn't too long or in use.
    if (abbr != null) {
      if (abbr.length > 1) {
        throw new IllegalArgumentException(
            'Abbreviation "$abbr" is longer than one character.');
      }

      var existing = _findByAbbr(abbr);
      if (existing != null) {
        throw new IllegalArgumentException(
            'Abbreviation "$abbr" is already used by "${existing.name}".');
      }
    }

    _options[name] = new _Option(name, abbr, help, allowed, allowedHelp,
        defaultsTo, callback, isFlag: isFlag, negatable: negatable,
        allowMultiple: allowMultiple);
    _optionNames.add(name);
  }

  /**
   * Parses [args], a list of command-line arguments, matches them against the
   * flags and options defined by this parser, and returns the result.
   */
  ArgResults parse(List<String> args) {
    _args = args;
    _current = 0;
    var results = {};

    // Initialize flags to their defaults.
    _options.forEach((name, option) {
      if (option.allowMultiple) {
        results[name] = [];
      } else {
        results[name] = option.defaultValue;
      }
    });

    // Parse the args.
    for (_current = 0; _current < args.length; _current++) {
      var arg = args[_current];

      if (arg == '--') {
        // Reached the argument terminator, so stop here.
        _current++;
        break;
      }

      // Try to parse the current argument as an option. Note that the order
      // here matters.
      if (_parseSoloOption(results)) continue;
      if (_parseAbbreviation(results)) continue;
      if (_parseLongOption(results)) continue;

      // If we got here, the argument doesn't look like an option, so stop.
      break;
    }

    // Set unspecified multivalued arguments to their default value,
    // if any, and invoke the callbacks.
    for (var name in _optionNames) {
      var option = _options[name];
      if (option.allowMultiple &&
          results[name].length == 0 &&
          option.defaultValue != null) {
        results[name].add(option.defaultValue);
      }
      if (option.callback != null) option.callback(results[name]);
    }

    // Add in the leftover arguments we didn't parse.
    return new ArgResults(results,
        _args.getRange(_current, _args.length - _current));
  }

  /**
   * Generates a string displaying usage information for the defined options.
   * This is basically the help text shown on the command line.
   */
  String getUsage() {
    return new _Usage(this).generate();
  }

  /**
   * Called during parsing to validate the arguments. Throws a
   * [FormatException] if [condition] is `false`.
   */
  _validate(bool condition, String message) {
    if (!condition) throw new FormatException(message);
  }

  /** Validates and stores [value] as the value for [option]. */
  _setOption(Map results, _Option option, value) {
    // See if it's one of the allowed values.
    if (option.allowed != null) {
      _validate(option.allowed.some((allow) => allow == value),
          '"$value" is not an allowed value for option "${option.name}".');
    }

    if (option.allowMultiple) {
      results[option.name].add(value);
    } else {
      results[option.name] = value;
    }
  }

  /**
   * Pulls the value for [option] from the next argument in [_args] (where the
   * current option is at index [_current]. Validates that there is a valid
   * value there.
   */
  void _readNextArgAsValue(Map results, _Option option) {
    _current++;
    // Take the option argument from the next command line arg.
    _validate(_current < _args.length,
        'Missing argument for "${option.name}".');

    // Make sure it isn't an option itself.
    _validate(!_ABBR_OPT.hasMatch(_args[_current]) &&
              !_LONG_OPT.hasMatch(_args[_current]),
        'Missing argument for "${option.name}".');

    _setOption(results, option, _args[_current]);
  }

  /**
   * Tries to parse the current argument as a "solo" option, which is a single
   * hyphen followed by a single letter. We treat this differently than
   * collapsed abbreviations (like "-abc") to handle the possible value that
   * may follow it.
   */
  bool _parseSoloOption(Map results) {
    var soloOpt = _SOLO_OPT.firstMatch(_args[_current]);
    if (soloOpt == null) return false;

    var option = _findByAbbr(soloOpt[1]);
    _validate(option != null,
        'Could not find an option or flag "-${soloOpt[1]}".');

    if (option.isFlag) {
      _setOption(results, option, true);
    } else {
      _readNextArgAsValue(results, option);
    }

    return true;
  }

  /**
   * Tries to parse the current argument as a series of collapsed abbreviations
   * (like "-abc") or a single abbreviation with the value directly attached
   * to it (like "-mrelease").
   */
  bool _parseAbbreviation(Map results) {
    var abbrOpt = _ABBR_OPT.firstMatch(_args[_current]);
    if (abbrOpt == null) return false;

    // If the first character is the abbreviation for a non-flag option, then
    // the rest is the value.
    var c = abbrOpt[1].substring(0, 1);
    var first = _findByAbbr(c);
    if (first == null) {
      _validate(false, 'Could not find an option with short name "-$c".');
    } else if (!first.isFlag) {
      // The first character is a non-flag option, so the rest must be the
      // value.
      var value = '${abbrOpt[1].substring(1)}${abbrOpt[2]}';
      _setOption(results, first, value);
    } else {
      // If we got some non-flag characters, then it must be a value, but
      // if we got here, it's a flag, which is wrong.
      _validate(abbrOpt[2] == '',
        'Option "-$c" is a flag and cannot handle value '
        '"${abbrOpt[1].substring(1)}${abbrOpt[2]}".');

      // Not an option, so all characters should be flags.
      for (var i = 0; i < abbrOpt[1].length; i++) {
        var c = abbrOpt[1].substring(i, i + 1);
        var option = _findByAbbr(c);
        _validate(option != null,
            'Could not find an option with short name "-$c".');

        // In a list of short options, only the first can be a non-flag. If
        // we get here we've checked that already.
        _validate(option.isFlag,
            'Option "-$c" must be a flag to be in a collapsed "-".');

        _setOption(results, option, true);
      }
    }

    return true;
  }

  /**
   * Tries to parse the current argument as a long-form named option, which
   * may include a value like "--mode=release" or "--mode release".
   */
  bool _parseLongOption(Map results) {
    var longOpt = _LONG_OPT.firstMatch(_args[_current]);
    if (longOpt == null) return false;

    var name = longOpt[1];
    var option = _options[name];
    if (option != null) {
      if (option.isFlag) {
        _validate(longOpt[3] == null,
            'Flag option "$name" should not be given a value.');

        _setOption(results, option, true);
      } else if (longOpt[3] != null) {
        // We have a value like --foo=bar.
        _setOption(results, option, longOpt[3]);
      } else {
        // Option like --foo, so look for the value as the next arg.
        _readNextArgAsValue(results, option);
      }
    } else if (name.startsWith('no-')) {
      // See if it's a negated flag.
      name = name.substring('no-'.length);
      option = _options[name];
      _validate(option != null, 'Could not find an option named "$name".');
      _validate(option.isFlag, 'Cannot negate non-flag option "$name".');
      _validate(option.negatable, 'Cannot negate option "$name".');

      _setOption(results, option, false);
    } else {
      _validate(option != null, 'Could not find an option named "$name".');
    }

    return true;
  }

  /**
   * Finds the option whose abbreviation is [abbr], or `null` if no option has
   * that abbreviation.
   */
  _Option _findByAbbr(String abbr) {
    for (var option in _options.getValues()) {
      if (option.abbreviation == abbr) return option;
    }

    return null;
  }

  /**
   * Get the default value for an option. Useful after parsing to test
   * if the user specified something other than the default.
   */
  getDefault(String option) {
    if (!_options.containsKey(option)) {
      throw new IllegalArgumentException('No option named $option');
    }
    return _options[option].defaultValue;
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
   * The remaining command-line arguments that were not parsed as options or
   * flags. If `--` was used to separate the options from the remaining
   * arguments, it will not be included in this list.
   */
  final List<String> rest;

  /** Creates a new [ArgResults]. */
  ArgResults(this._options, this.rest);

  /** Gets the parsed command-line option named [name]. */
  operator [](String name) {
    if (!_options.containsKey(name)) {
      throw new IllegalArgumentException(
          'Could not find an option named "$name".');
    }

    return _options[name];
  }

  /** Get the names of the options as a [Collection]. */
  Collection<String> get options => _options.getKeys();
}

class _Option {
  final String name;
  final String abbreviation;
  final List allowed;
  final defaultValue;
  final Function callback;
  final String help;
  final Map<String, String> allowedHelp;
  final bool isFlag;
  final bool negatable;
  final bool allowMultiple;

  _Option(this.name, this.abbreviation, this.help, this.allowed,
      this.allowedHelp, this.defaultValue, this.callback, [this.isFlag,
      this.negatable, this.allowMultiple = false]);
}

/**
 * Takes an [ArgParser] and generates a string of usage (i.e. help) text for its
 * defined options. Internally, it works like a tabular printer. The output is
 * divided into three horizontal columns, like so:
 *
 *     -h, --help  Prints the usage information
 *     |  |        |                                 |
 *
 * It builds the usage text up one column at a time and handles padding with
 * spaces and wrapping to the next line to keep the cells correctly lined up.
 */
class _Usage {
  static const NUM_COLUMNS = 3; // Abbreviation, long name, help.

  /** The parser this is generating usage for. */
  final ArgParser args;

  /** The working buffer for the generated usage text. */
  StringBuffer buffer;

  /**
   * The column that the "cursor" is currently on. If the next call to
   * [write()] is not for this column, it will correctly handle advancing to
   * the next column (and possibly the next row).
   */
  int currentColumn = 0;

  /** The width in characters of each column. */
  List<int> columnWidths;

  /**
   * The number of sequential lines of text that have been written to the last
   * column (which shows help info). We track this so that help text that spans
   * multiple lines can be padded with a blank line after it for separation.
   * Meanwhile, sequential options with single-line help will be compacted next
   * to each other.
   */
  int numHelpLines = 0;

  /**
   * How many newlines need to be rendered before the next bit of text can be
   * written. We do this lazily so that the last bit of usage doesn't have
   * dangling newlines. We only write newlines right *before* we write some
   * real content.
   */
  int newlinesNeeded = 0;

  _Usage(this.args);

  /**
   * Generates a string displaying usage information for the defined options.
   * This is basically the help text shown on the command line.
   */
  String generate() {
    buffer = new StringBuffer();

    calculateColumnWidths();

    for (var name in args._optionNames) {
      var option = args._options[name];
      write(0, getAbbreviation(option));
      write(1, getLongOption(option));

      if (option.help != null) write(2, option.help);

      if (option.allowedHelp != null) {
        var allowedNames = option.allowedHelp.getKeys();
        allowedNames.sort((a, b) => a.compareTo(b));
        newline();
        for (var name in allowedNames) {
          write(1, getAllowedTitle(name));
          write(2, option.allowedHelp[name]);
        }
        newline();
      } else if (option.allowed != null) {
        write(2, buildAllowedList(option));
      } else if (option.defaultValue != null) {
        if (option.isFlag && option.defaultValue == true) {
          write(2, '(defaults to on)');
        } else if (!option.isFlag) {
          write(2, '(defaults to "${option.defaultValue}")');
        }
      }

      // If any given option displays more than one line of text on the right
      // column (i.e. help, default value, allowed options, etc.) then put a
      // blank line after it. This gives space where it's useful while still
      // keeping simple one-line options clumped together.
      if (numHelpLines > 1) newline();
    }

    return buffer.toString();
  }

  String getAbbreviation(_Option option) {
    if (option.abbreviation != null) {
      return '-${option.abbreviation}, ';
    } else {
      return '';
    }
  }

  String getLongOption(_Option option) {
    if (option.negatable) {
      return '--[no-]${option.name}';
    } else {
      return '--${option.name}';
    }
  }

  String getAllowedTitle(String allowed) {
    return '      [$allowed]';
  }

  void calculateColumnWidths() {
    int abbr = 0;
    int title = 0;
    for (var name in args._optionNames) {
      var option = args._options[name];

      // Make room in the first column if there are abbreviations.
      abbr = max(abbr, getAbbreviation(option).length);

      // Make room for the option.
      title = max(title, getLongOption(option).length);

      // Make room for the allowed help.
      if (option.allowedHelp != null) {
        for (var allowed in option.allowedHelp.getKeys()) {
          title = max(title, getAllowedTitle(allowed).length);
        }
      }
    }

    // Leave a gutter between the columns.
    title += 4;
    columnWidths = [abbr, title];
  }

  newline() {
    newlinesNeeded++;
    currentColumn = 0;
    numHelpLines = 0;
  }

  write(int column, String text) {
    var lines = text.split('\n');

    // Strip leading and trailing empty lines.
    while (lines.length > 0 && lines[0].trim() == '') {
      lines.removeRange(0, 1);
    }

    while (lines.length > 0 && lines[lines.length - 1].trim() == '') {
      lines.removeLast();
    }

    for (var line in lines) {
      writeLine(column, line);
    }
  }

  writeLine(int column, String text) {
    // Write any pending newlines.
    while (newlinesNeeded > 0) {
      buffer.add('\n');
      newlinesNeeded--;
    }

    // Advance until we are at the right column (which may mean wrapping around
    // to the next line.
    while (currentColumn != column) {
      if (currentColumn < NUM_COLUMNS - 1) {
        buffer.add(padRight('', columnWidths[currentColumn]));
      } else {
        buffer.add('\n');
      }
      currentColumn = (currentColumn + 1) % NUM_COLUMNS;
    }

    if (column < columnWidths.length) {
      // Fixed-size column, so pad it.
      buffer.add(padRight(text, columnWidths[column]));
    } else {
      // The last column, so just write it.
      buffer.add(text);
    }

    // Advance to the next column.
    currentColumn = (currentColumn + 1) % NUM_COLUMNS;

    // If we reached the last column, we need to wrap to the next line.
    if (column == NUM_COLUMNS - 1) newlinesNeeded++;

    // Keep track of how many consecutive lines we've written in the last
    // column.
    if (column == NUM_COLUMNS - 1) {
      numHelpLines++;
    } else {
      numHelpLines = 0;
    }
  }

  buildAllowedList(_Option option) {
    var allowedBuffer = new StringBuffer();
    allowedBuffer.add('[');
    bool first = true;
    for (var allowed in option.allowed) {
      if (!first) allowedBuffer.add(', ');
      allowedBuffer.add(allowed);
      if (allowed == option.defaultValue) {
        allowedBuffer.add(' (default)');
      }
      first = false;
    }
    allowedBuffer.add(']');
    return allowedBuffer.toString();
  }
}
