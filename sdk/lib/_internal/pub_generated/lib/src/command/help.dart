library pub.command.help;
import 'dart:async';
import '../command.dart';
class HelpCommand extends PubCommand {
  String get description => "Display help information for Pub.";
  String get usage => "pub help [command]";
  bool get takesArguments => true;
  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      PubCommand.printGlobalUsage();
      return null;
    }
    var commands = PubCommand.mainCommands;
    var command = null;
    var commandString = "pub";
    for (var name in commandOptions.rest) {
      if (commands.isEmpty) {
        command.usageError(
            'Command "$commandString" does not expect a subcommand.');
      }
      if (commands[name] == null) {
        if (command == null) {
          PubCommand.usageErrorWithCommands(
              commands,
              'Could not find a command named "$name".');
        }
        command.usageError(
            'Could not find a subcommand named "$name" for "$commandString".');
      }
      command = commands[name];
      commands = command.subcommands;
      commandString += " $name";
    }
    command.printUsage();
    return null;
  }
}
