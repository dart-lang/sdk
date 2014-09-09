library pub.command;
import 'dart:async';
import 'dart:math' as math;
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'command/build.dart';
import 'command/cache.dart';
import 'command/deps.dart';
import 'command/downgrade.dart';
import 'command/get.dart';
import 'command/global.dart';
import 'command/help.dart';
import 'command/lish.dart';
import 'command/list_package_dirs.dart';
import 'command/run.dart';
import 'command/serve.dart';
import 'command/upgrade.dart';
import 'command/uploader.dart';
import 'command/version.dart';
import 'entrypoint.dart';
import 'exceptions.dart';
import 'log.dart' as log;
import 'global_packages.dart';
import 'system_cache.dart';
import 'utils.dart';
abstract class PubCommand {
  static final Map<String, PubCommand> mainCommands = _initCommands();
  static final pubArgParser = _initArgParser();
  static void printGlobalUsage() {
    var buffer = new StringBuffer();
    buffer.writeln('Pub is a package manager for Dart.');
    buffer.writeln();
    buffer.writeln('Usage: pub <command> [arguments]');
    buffer.writeln();
    buffer.writeln('Global options:');
    buffer.writeln(pubArgParser.getUsage());
    buffer.writeln();
    buffer.write(_listCommands(mainCommands));
    buffer.writeln();
    buffer.writeln(
        'Run "pub help [command]" for more information about a command.');
    buffer.writeln(
        'See http://dartlang.org/tools/pub for detailed documentation.');
    log.message(buffer);
  }
  static void usageErrorWithCommands(Map<String, PubCommand> commands,
      String message) {
    throw new UsageException(message, _listCommands(commands));
  }
  static String _listCommands(Map<String, PubCommand> commands) {
    if (commands.isEmpty) return "";
    var names =
        commands.keys.where((name) => !commands[name].aliases.contains(name));
    var visible = names.where((name) => !commands[name].hidden);
    if (visible.isNotEmpty) names = visible;
    names = ordered(names);
    var length = names.map((name) => name.length).reduce(math.max);
    var isSubcommand = commands != mainCommands;
    var buffer = new StringBuffer();
    buffer.writeln('Available ${isSubcommand ? "sub" : ""}commands:');
    for (var name in names) {
      buffer.writeln(
          '  ${padRight(name, length)}   '
              '${commands[name].description.split("\n").first}');
    }
    return buffer.toString();
  }
  SystemCache get cache => _cache;
  SystemCache _cache;
  GlobalPackages get globals => _globals;
  GlobalPackages _globals;
  ArgResults get globalOptions => _globalOptions;
  ArgResults _globalOptions;
  ArgResults get commandOptions => _commandOptions;
  ArgResults _commandOptions;
  Entrypoint get entrypoint {
    if (_entrypoint == null) {
      _entrypoint = new Entrypoint(
          path.current,
          _cache,
          packageSymlinks: globalOptions['package-symlinks']);
    }
    return _entrypoint;
  }
  Entrypoint _entrypoint;
  String get description;
  bool get hidden {
    if (subcommands.isEmpty) return false;
    return subcommands.values.every((subcommand) => subcommand.hidden);
  }
  String get usage;
  String get docUrl => null;
  bool get takesArguments => false;
  bool get allowTrailingOptions => true;
  final aliases = const <String>[];
  ArgParser get commandParser => _commandParser;
  ArgParser _commandParser;
  final subcommands = <String, PubCommand>{};
  bool get isOffline => false;
  PubCommand() {
    _commandParser = new ArgParser(allowTrailingOptions: allowTrailingOptions);
    commandParser.addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print usage information for this command.');
  }
  Future run(String cacheDir, ArgResults globalOptions, ArgResults options) {
    _globalOptions = globalOptions;
    _commandOptions = options;
    _cache = new SystemCache.withSources(cacheDir, isOffline: isOffline);
    _globals = new GlobalPackages(_cache);
    return syncFuture(onRun);
  }
  Future onRun() {
    assert(false);
    return null;
  }
  void printUsage([String description]) {
    if (description == null) description = this.description;
    log.message('$description\n\n${_getUsage()}');
  }
  void usageError(String message) {
    throw new UsageException(message, _getUsage());
  }
  int parseInt(String intString, String name) {
    try {
      return int.parse(intString);
    } on FormatException catch (_) {
      usageError('Could not parse $name "$intString".');
    }
  }
  String _getUsage() {
    var buffer = new StringBuffer();
    buffer.write('Usage: $usage');
    var commandUsage = commandParser.getUsage();
    if (!commandUsage.isEmpty) {
      buffer.writeln();
      buffer.writeln(commandUsage);
    }
    if (subcommands.isNotEmpty) {
      buffer.writeln();
      buffer.write(_listCommands(subcommands));
    }
    buffer.writeln();
    buffer.writeln('Run "pub help" to see global options.');
    if (docUrl != null) {
      buffer.writeln("See $docUrl for detailed documentation.");
    }
    return buffer.toString();
  }
}
_initCommands() {
  var commands = {
    'build': new BuildCommand(),
    'cache': new CacheCommand(),
    'deps': new DepsCommand(),
    'downgrade': new DowngradeCommand(),
    'global': new GlobalCommand(),
    'get': new GetCommand(),
    'help': new HelpCommand(),
    'list-package-dirs': new ListPackageDirsCommand(),
    'publish': new LishCommand(),
    'run': new RunCommand(),
    'serve': new ServeCommand(),
    'upgrade': new UpgradeCommand(),
    'uploader': new UploaderCommand(),
    'version': new VersionCommand()
  };
  for (var command in commands.values.toList()) {
    for (var alias in command.aliases) {
      commands[alias] = command;
    }
  }
  return commands;
}
ArgParser _initArgParser() {
  var argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.');
  argParser.addFlag('version', negatable: false, help: 'Print pub version.');
  argParser.addFlag(
      'trace',
      help: 'Print debugging information when an error occurs.');
  argParser.addOption(
      'verbosity',
      help: 'Control output verbosity.',
      allowed: ['normal', 'io', 'solver', 'all'],
      allowedHelp: {
    'normal': 'Show errors, warnings, and user messages.',
    'io': 'Also show IO operations.',
    'solver': 'Show steps during version resolution.',
    'all': 'Show all output including internal tracing messages.'
  });
  argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Shortcut for "--verbosity=all".');
  argParser.addFlag(
      'with-prejudice',
      hide: !isAprilFools,
      negatable: false,
      help: 'Execute commands with prejudice.');
  argParser.addFlag(
      'package-symlinks',
      hide: true,
      negatable: true,
      defaultsTo: true);
  PubCommand.mainCommands.forEach((name, command) {
    _registerCommand(name, command, argParser);
  });
  return argParser;
}
void _registerCommand(String name, PubCommand command, ArgParser parser) {
  parser.addCommand(name, command.commandParser);
  command.subcommands.forEach((name, subcommand) {
    _registerCommand(name, subcommand, command.commandParser);
  });
}
