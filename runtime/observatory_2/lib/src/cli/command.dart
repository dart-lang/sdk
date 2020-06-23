// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cli;

// Splits a line into a list of string args.  Each arg retains any
// trailing whitespace so that we can reconstruct the original command
// line from the pieces.
List<String> _splitLine(String line) {
  line = line.trimLeft();
  var args = <String>[];
  int pos = 0;
  while (pos < line.length) {
    int startPos = pos;

    // Advance to end of word.
    for (; pos < line.length && line[pos] != ' '; pos++);

    // Advance to end of spaces.
    for (; pos < line.length && line[pos] == ' '; pos++);

    args.add(line.substring(startPos, pos));
  }
  return args;
}

// Concatenates the first 'count' args.
String _concatArgs(List<String> args, int count) {
  if (count == 0) {
    return '';
  }
  return '${args.sublist(0, count).join('')}';
}

// Shared functionality for RootCommand and Command.
abstract class _CommandBase {
  _CommandBase(List<Command> children) {
    assert(children != null);
    _children.addAll(children);
    for (var child in _children) {
      child._parent = this;
    }
  }

  // A command may optionally have sub-commands.
  List<Command> _children = <Command>[];

  _CommandBase _parent;
  int get _depth => (_parent == null ? 0 : _parent._depth + 1);

  // Override in subclasses to provide command-specific argument completion.
  //
  // Given a list of arguments to this command, provide a list of
  // possible completions for those arguments.
  Future<List<String>> complete(List<String> args) =>
      new Future.value(<String>[]);

  // Override in subclasses to provide command-specific execution.
  Future run(List<String> args);

  // Returns a list of local subcommands which match the args.
  List<Command> _matchLocal(String argWithSpace, bool preferExact) {
    var matches = <Command>[];
    var arg = argWithSpace.trimRight();
    for (var child in _children) {
      if (child.name.startsWith(arg)) {
        if (preferExact && ((child.name == arg) || (child.alias == arg))) {
          return [child];
        }
        matches.add(child);
      }
    }
    return matches;
  }

  // Returns the set of commands could be triggered by a list of
  // arguments.
  List<Command> _match(List<String> args, bool preferExact) {
    if (args.isEmpty) {
      return <Command>[];
    }
    bool lastArg = (args.length == 1);
    var matches = _matchLocal(args[0], !lastArg || preferExact);
    if (matches.isEmpty) {
      return <Command>[];
    } else if (matches.length == 1) {
      var childMatches = matches[0]._match(args.sublist(1), preferExact);
      if (childMatches.isEmpty) {
        return matches;
      } else {
        return childMatches;
      }
    } else {
      return matches;
    }
  }

  // Builds a list of completions for this command.
  Future<List<String>> _buildCompletions(
      List<String> args, bool addEmptyString) {
    return complete(args.sublist(_depth, args.length)).then((completions) {
      if (addEmptyString &&
          completions.isEmpty &&
          args[args.length - 1] == '') {
        // Special case allowance for an empty particle at the end of
        // the command.
        completions = <String>[''];
      }
      var prefix = _concatArgs(args, _depth);
      return completions.map((str) => '${prefix}${str}').toList();
    });
  }
}

// The root of a tree of commands.
class RootCommand extends _CommandBase {
  RootCommand(List<Command> children, [List<String> history])
      : this._(children, history ?? ['']);

  RootCommand._(List<Command> children, List<String> history)
      : history = history,
        historyPos = history.length - 1,
        super(children);

  // Provides a list of possible completions for a line of text.
  Future<List<String>> completeCommand(String line) {
    var args = _splitLine(line);
    bool showAll = line.endsWith(' ') || args.isEmpty;
    if (showAll) {
      // Adding an empty string to the end causes us to match all
      // subcommands of the last command.
      args.add('');
    }
    var commands = _match(args, false);
    if (commands.isEmpty) {
      // No matching commands.
      return new Future.value(<String>[]);
    }
    int matchLen = commands[0]._depth;
    if (matchLen < args.length) {
      // We were able to find a command which matches a prefix of the
      // args, but not the full list.
      if (commands.length == 1) {
        // The matching command is unique.  Attempt to provide local
        // argument completion from the command.
        return commands[0]._buildCompletions(args, true);
      } else {
        // An ambiguous prefix match leaves us nowhere.  The user is
        // typing a bunch of stuff that we don't know how to complete.
        return new Future.value(<String>[]);
      }
    }

    // We have found a set of commands which match all of the args.
    // Return the completion strings.
    var prefix = _concatArgs(args, args.length - 1);
    var completions =
        commands.map((command) => '${prefix}${command.name} ').toList();
    if (matchLen == args.length) {
      // If we are showing all possiblities, also include local
      // completions for the parent command.
      return commands[0]
          ._parent
          ._buildCompletions(args, false)
          .then((localCompletions) {
        completions.addAll(localCompletions);
        return completions;
      });
    }
    return new Future.value(completions);
  }

  // Runs a command.
  Future runCommand(String line) {
    _historyAdvance(line);
    var args = _splitLine(line);
    var commands = _match(args, true);
    if (commands.isEmpty) {
      return new Future.error(new NoSuchCommandException(line));
    } else if (commands.length == 1) {
      return commands[0].run(args.sublist(commands[0]._depth));
    } else {
      return new Future.error(new AmbiguousCommandException(line, commands));
    }
  }

  // Find all matching commands.  Useful for implementing help systems.
  List<Command> matchCommand(List<String> args, bool preferExact) {
    if (args.isEmpty) {
      // Adding an empty string to the end causes us to match all
      // subcommands of the last command.
      args.add('');
    }
    return _match(args, preferExact);
  }

  // Command line history always contains one slot to hold the current
  // line, so we start off with one entry.
  List<String> history;
  int historyPos;

  String historyPrev(String line) {
    if (historyPos == 0) {
      return line;
    }
    history[historyPos] = line;
    historyPos--;
    return history[historyPos];
  }

  String historyNext(String line) {
    if (historyPos == history.length - 1) {
      return line;
    }
    history[historyPos] = line;
    historyPos++;
    return history[historyPos];
  }

  void _historyAdvance(String line) {
    // Replace the last history line.
    historyPos = history.length - 1;
    history[historyPos] = line;

    // Create an empty spot for the next line.
    history.add('');
    historyPos++;
  }

  Future run(List<String> args) {
    throw 'should-not-execute-the-root-command';
  }

  toString() => 'RootCommand';
}

// A node in the command tree.
abstract class Command extends _CommandBase {
  Command(this.name, List<Command> children) : super(children);

  final String name;
  String alias;

  String get fullName {
    if (_parent is RootCommand) {
      return name;
    } else {
      Command parent = _parent;
      return '${parent.fullName} $name';
    }
  }

  toString() => 'Command(${name})';
}

abstract class CommandException implements Exception {}

class AmbiguousCommandException extends CommandException {
  AmbiguousCommandException(this.command, this.matches);

  final String command;
  final List<Command> matches;

  @override
  String toString() {
    List<String> matchNames =
        matches.map((Command command) => '${command.fullName}').toList();
    return "Command '$command' is ambiguous: $matchNames";
  }
}

class NoSuchCommandException extends CommandException {
  NoSuchCommandException(this.command);

  final String command;

  @override
  String toString() => "No such command: '$command'";
}
