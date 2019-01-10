import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

part 'src/impl.dart';

const githubRepo = 'dart-lang/homebrew-dart';

const dartRbFileName = 'dart.rb';

Iterable<String> get supportedChannels => _files.keys;

Future<void> writeHomebrewInfo(
    String channel, String revision, String repository) async {
  var revisions = await _getCurrentRevisions(repository);

  if (revisions[channel] == revision) {
    print("Channel $channel is already at revision $revision in homebrew.");
    exit(0);
  }
  revisions[channel] = revision;
  var hashes = await _getHashes(revisions);
  var devVersion = await _getVersion('dev', revisions['dev']);

  var stableVersion = await _getVersion('stable', revisions['stable']);

  await File(p.join(repository, dartRbFileName)).writeAsString(
      _createDartFormula(revisions, hashes, devVersion, stableVersion),
      flush: true);
}

Future<void> runGit(List<String> args, String repository,
    Map<String, String> gitEnvironment) async {
  print("git ${args.join(' ')}");

  var result = await Process.run('git', args,
      workingDirectory: repository, environment: gitEnvironment);

  print(result.stdout);
  print(result.stderr);
}
