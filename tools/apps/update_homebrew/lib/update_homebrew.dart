import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

part 'src/impl.dart';

const githubRepo = 'dart-lang/homebrew-dart';

const formulaByChannel = {
  'beta': 'dart-beta.rb',
  'dev': 'dart.rb',
  'stable': 'dart.rb'
};

Iterable<String> get supportedChannels => formulaByChannel.keys;

Future<void> writeHomebrewInfo(
    String channel, String version, String repository) async {
  var formula = File(p.join(repository, formulaByChannel[channel]));
  var hashes = await _getHashes(channel, version);
  await _updateFormula(channel, formula, version, hashes);
}

Future<void> runGit(List<String> args, String repository,
    Map<String, String> gitEnvironment) async {
  print("git ${args.join(' ')}");

  var result = await Process.run('git', args,
      workingDirectory: repository, environment: gitEnvironment);

  print(result.stdout);
  print(result.stderr);
}
