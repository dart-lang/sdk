library pub.git;
import 'dart:async';
import 'dart:io';
import 'package:stack_trace/stack_trace.dart';
import 'exceptions.dart';
import 'io.dart';
import 'log.dart' as log;
import 'utils.dart';
class GitException implements ApplicationException {
  final List<String> args;
  final String stderr;
  String get message => 'Git error. Command: git ${args.join(" ")}\n$stderr';
  GitException(Iterable<String> args, this.stderr) : args = args.toList();
  String toString() => message;
}
bool get isInstalled {
  if (_isInstalledCache != null) return _isInstalledCache;
  _isInstalledCache = _gitCommand != null;
  return _isInstalledCache;
}
bool _isInstalledCache;
Future<List<String>> run(List<String> args, {String workingDir, Map<String,
    String> environment}) {
  if (!isInstalled) {
    fail(
        "Cannot find a Git executable.\n" "Please ensure Git is correctly installed.");
  }
  return runProcess(
      _gitCommand,
      args,
      workingDir: workingDir,
      environment: environment).then((result) {
    if (!result.success) throw new GitException(args, result.stderr.join("\n"));
    return result.stdout;
  });
}
List<String> runSync(List<String> args, {String workingDir, Map<String,
    String> environment}) {
  if (!isInstalled) {
    fail(
        "Cannot find a Git executable.\n" "Please ensure Git is correctly installed.");
  }
  var result = runProcessSync(
      _gitCommand,
      args,
      workingDir: workingDir,
      environment: environment);
  if (!result.success) throw new GitException(args, result.stderr.join("\n"));
  return result.stdout;
}
String get _gitCommand {
  if (_commandCache != null) return _commandCache;
  var command;
  if (_tryGitCommand("git")) {
    _commandCache = "git";
  } else if (_tryGitCommand("git.cmd")) {
    _commandCache = "git.cmd";
  } else {
    return null;
  }
  log.fine('Determined git command $command.');
  return _commandCache;
}
String _commandCache;
bool _tryGitCommand(String command) {
  try {
    var result = runProcessSync(command, ["--version"]);
    var regexp = new RegExp("^git version");
    return result.stdout.length == 1 && regexp.hasMatch(result.stdout.single);
  } on ProcessException catch (error, stackTrace) {
    var chain = new Chain.forTrace(stackTrace);
    log.message('Git command is not "$command": $error\n$chain');
    return false;
  }
}
