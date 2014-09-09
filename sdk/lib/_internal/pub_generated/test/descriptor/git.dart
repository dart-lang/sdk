library descriptor.git;
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/descriptor.dart';
import '../../lib/src/git.dart' as git;
class GitRepoDescriptor extends DirectoryDescriptor {
  GitRepoDescriptor(String name, List<Descriptor> contents)
      : super(name, contents);
  Future create([String parent]) => schedule(() {
    return super.create(parent).then((_) {
      return _runGitCommands(
          parent,
          [['init'], ['add', '.'], ['commit', '-m', 'initial commit']]);
    });
  }, 'creating Git repo:\n${describe()}');
  Future commit([String parent]) => schedule(() {
    return super.create(parent).then((_) {
      return _runGitCommands(
          parent,
          [['add', '.'], ['commit', '-m', 'update']]);
    });
  }, 'committing Git repo:\n${describe()}');
  Future<String> revParse(String ref, [String parent]) => schedule(() {
    return _runGit(['rev-parse', ref], parent).then((output) => output[0]);
  }, 'parsing revision $ref for Git repo:\n${describe()}');
  Future runGit(List<String> args, [String parent]) => schedule(() {
    return _runGit(args, parent);
  }, "running 'git ${args.join(' ')}' in Git repo:\n${describe()}");
  Future _runGitCommands(String parent, List<List<String>> commands) =>
      Future.forEach(commands, (command) => _runGit(command, parent));
  Future<List<String>> _runGit(List<String> args, String parent) {
    var environment = {
      'GIT_AUTHOR_NAME': 'Pub Test',
      'GIT_AUTHOR_EMAIL': 'pub@dartlang.org',
      'GIT_COMMITTER_NAME': 'Pub Test',
      'GIT_COMMITTER_EMAIL': 'pub@dartlang.org'
    };
    if (parent == null) parent = defaultRoot;
    return git.run(
        args,
        workingDir: path.join(parent, name),
        environment: environment);
  }
}
