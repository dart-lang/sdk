// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.command_line;

import 'errors.dart' show inputError, internalError;

argumentError(String usage, String message) {
  if (usage != null) print(usage);
  inputError(null, null, message);
}

class ParsedArguments {
  final Map<String, dynamic> options = <String, dynamic>{};
  final List<String> arguments = <String>[];

  toString() => "ParsedArguments($options, $arguments)";
}

class CommandLine {
  final Map<String, dynamic> options;

  final List<String> arguments;

  final String usage;

  CommandLine.parsed(ParsedArguments p, this.usage)
      : this.options = p.options,
        this.arguments = p.arguments {
    validate();
    if (verbose) {
      print(p);
    }
  }

  CommandLine(List<String> arguments,
      {Map<String, dynamic> specification, String usage})
      : this.parsed(parse(arguments, specification, usage), usage);

  bool get verbose {
    return options.containsKey("-v") || options.containsKey("--verbose");
  }

  /// Override to validate arguments and options.
  void validate() {}

  /// Parses a list of command-line [arguments] into options and arguments.
  ///
  /// An /option/ is something that, normally, starts with `-` or `--` (one or
  /// two dashes). However, as a special case `/?` and `/h` are also recognized
  /// as options for increased compatibility with Windows. An option can have a
  /// value.
  ///
  /// An /argument/ is something that isn't an option, for example, a file name.
  ///
  /// The specification is a map of options to one of the type literals `Uri`,
  /// `int`, `bool`, or `String`, or a comma (`","`) that represents option
  /// values of type [Uri], [int], [bool], [String], or a comma-separated list
  /// of [String], respectively.
  ///
  /// If [arguments] contains `"--"`, anything before is parsed as options, and
  /// arguments; anything following is treated as arguments (even if starting
  /// with, for example, a `-`).
  ///
  /// Anything that looks like an option is assumed to be a `bool` option set
  /// to true, unless it's mentioned in [specification] in which case the
  /// option requires a value, either on the form `--option value` or
  /// `--option=value`.
  ///
  /// This method performs only a limited amount of validation, but if an error
  /// occurs, it will print [usage] along with a specific error message.
  static ParsedArguments parse(List<String> arguments,
      Map<String, dynamic> specification, String usage) {
    specification ??= const <String, dynamic>{};
    ParsedArguments result = new ParsedArguments();
    int index = arguments.indexOf("--");
    Iterable<String> nonOptions = const <String>[];
    Iterator<String> iterator = arguments.iterator;
    if (index != -1) {
      nonOptions = arguments.skip(index + 1);
      iterator = arguments.take(index).iterator;
    }
    while (iterator.moveNext()) {
      String argument = iterator.current;
      if (argument.startsWith("-")) {
        var valueSpecification = specification[argument];
        String value;
        if (valueSpecification != null) {
          if (!iterator.moveNext()) {
            return argumentError(usage, "Expected value after '$argument'.");
          }
          value = iterator.current;
        } else {
          index = argument.indexOf("=");
          if (index != -1) {
            value = argument.substring(index + 1);
            argument = argument.substring(0, index);
            valueSpecification = specification[argument];
          }
        }
        if (valueSpecification == null) {
          if (value != null) {
            return argumentError(
                usage, "Argument '$argument' doesn't take a value: '$value'.");
          }
          result.options[argument] = true;
        } else {
          if (valueSpecification is! String && valueSpecification is! Type) {
            return argumentError(
                usage,
                "Unrecognized type of value "
                "specification: ${valueSpecification.runtimeType}.");
          }
          switch ("$valueSpecification") {
            case ",":
              result.options
                  .putIfAbsent(argument, () => <String>[])
                  .addAll(value.split(","));
              break;

            case "int":
            case "bool":
            case "String":
            case "Uri":
              if (result.options.containsKey(argument)) {
                return argumentError(
                    usage,
                    "Multiple values for '$argument': "
                    "'${result.options[argument]}' and '$value'.");
              }
              var parsedValue;
              if (valueSpecification == int) {
                parsedValue = int.parse(value, onError: (_) {
                  return argumentError(
                      usage, "Value for '$argument', '$value', isn't an int.");
                });
              } else if (valueSpecification == bool) {
                if (value == "true" || value == "yes") {
                  parsedValue = true;
                } else if (value == "false" || value == "no") {
                  parsedValue = false;
                } else {
                  return argumentError(
                      usage,
                      "Value for '$argument' is '$value', "
                      "but expected one of: 'true', 'false', 'yes', or 'no'.");
                }
              } else if (valueSpecification == Uri) {
                parsedValue = Uri.base.resolve(value);
              } else if (valueSpecification == String) {
                parsedValue = value;
              } else if (valueSpecification is String) {
                return argumentError(
                    usage,
                    "Unrecognized value specification: "
                    "'$valueSpecification', try using a type literal instead.");
              } else {
                // All possible cases should have been handled above.
                return internalError("assertion failure");
              }
              result.options[argument] = parsedValue;
              break;

            default:
              return argumentError(usage,
                  "Unrecognized value specification: '$valueSpecification'.");
          }
        }
      } else if (argument == "/?" || argument == "/h") {
        result.options[argument] = true;
      } else {
        result.arguments.add(argument);
      }
    }
    result.arguments.addAll(nonOptions);
    return result;
  }
}
