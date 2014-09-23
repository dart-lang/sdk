library pub.command.barback;
import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import '../command.dart';
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
final _arrow = getSpecial('\u2192', '=>');
final _allSourceDirectories =
    new Set<String>.from(["benchmark", "bin", "example", "test", "web"]);
abstract class BarbackCommand extends PubCommand {
  final takesArguments = true;
  BarbackMode get mode => new BarbackMode(commandOptions["mode"]);
  final sourceDirectories = new Set<String>();
  BarbackMode get defaultMode => BarbackMode.RELEASE;
  List<String> get defaultSourceDirectories;
  BarbackCommand() {
    commandParser.addOption(
        "mode",
        defaultsTo: defaultMode.toString(),
        help: "Mode to run transformers in.");
    commandParser.addFlag(
        "all",
        help: "Use all default source directories.",
        defaultsTo: false,
        negatable: false);
  }
  Future onRun() {
    log.json.enabled = commandOptions.options.contains("format") &&
        commandOptions["format"] == "json";
    _parseSourceDirectories();
    return onRunTransformerCommand();
  }
  Future onRunTransformerCommand();
  void _parseSourceDirectories() {
    if (commandOptions["all"]) {
      _addAllDefaultSources();
      return;
    }
    if (commandOptions.rest.isEmpty) {
      _addDefaultSources();
      return;
    }
    sourceDirectories.addAll(commandOptions.rest);
    var disallowed = sourceDirectories.where((dir) {
      var parts = path.split(path.normalize(dir));
      return parts.isNotEmpty && parts.first == "lib";
    });
    if (disallowed.isNotEmpty) {
      usageError(_directorySentence(disallowed, "is", "are", "not allowed"));
    }
    var invalid = sourceDirectories.where((dir) => !path.isWithin('.', dir));
    if (invalid.isNotEmpty) {
      usageError(
          _directorySentence(invalid, "isn't", "aren't", "in this package"));
    }
    var missing =
        sourceDirectories.where((dir) => !dirExists(entrypoint.root.path(dir)));
    if (missing.isNotEmpty) {
      dataError(_directorySentence(missing, "does", "do", "not exist"));
    }
    var sources = sourceDirectories.toList();
    var overlapping = new Set();
    for (var i = 0; i < sources.length; i++) {
      for (var j = i + 1; j < sources.length; j++) {
        if (path.isWithin(sources[i], sources[j]) ||
            path.isWithin(sources[j], sources[i])) {
          overlapping.add(sources[i]);
          overlapping.add(sources[j]);
        }
      }
    }
    if (overlapping.isNotEmpty) {
      usageError(
          _directorySentence(overlapping, "cannot", "cannot", "overlap"));
    }
  }
  void _addAllDefaultSources() {
    if (commandOptions.rest.isNotEmpty) {
      usageError('Directory names are not allowed if "--all" is passed.');
    }
    var dirs =
        _allSourceDirectories.where((dir) => dirExists(entrypoint.root.path(dir)));
    if (dirs.isEmpty) {
      var defaultDirs =
          toSentence(_allSourceDirectories.map((name) => '"$name"'));
      dataError(
          'There are no source directories present.\n'
              'The default directories are $defaultDirs.');
    }
    sourceDirectories.addAll(dirs);
  }
  void _addDefaultSources() {
    sourceDirectories.addAll(
        defaultSourceDirectories.where((dir) => dirExists(entrypoint.root.path(dir))));
    if (sourceDirectories.isEmpty) {
      var defaults;
      if (defaultSourceDirectories.length == 1) {
        defaults = 'a "${defaultSourceDirectories.first}" directory';
      } else {
        defaults =
            '"${defaultSourceDirectories[0]}" and/or '
                '"${defaultSourceDirectories[1]}" directories';
      }
      dataError(
          "Your package must have $defaults,\n"
              "or you must specify the source directories.");
    }
  }
  String _directorySentence(Iterable<String> directoryNames,
      String singularVerb, String pluralVerb, String suffix) {
    var directories =
        pluralize('Directory', directoryNames.length, plural: 'Directories');
    var names = toSentence(directoryNames.map((dir) => '"$dir"'));
    var verb =
        pluralize(singularVerb, directoryNames.length, plural: pluralVerb);
    var result = "$directories $names $verb";
    if (suffix != null) result += " $suffix";
    result += ".";
    return result;
  }
}
