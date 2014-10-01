// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library update_homebrew;

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:args/args.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis/common/common.dart' show DownloadOptions, Media;

String repository;  // The path to the temporary git checkout of dart-homebrew.
Map gitEnvironment;  // Pass a wrapper script for SSH to git in the environment.

Future<String> getHash256(String channel, int revision, String download) {
  var client = new http.Client();
  var api = new storage.StorageApi(client);
  return
      api.objects.get('dart-archive',
                      'channels/$channel/release/$revision/$download.sha256sum',
                       downloadOptions: DownloadOptions.FullMedia)
      .then((Media media) => ASCII.decodeStream(media.stream))
      .then((hashLine) => new RegExp('[0-9a-fA-F]*').stringMatch(hashLine))
      .whenComplete(client.close);
}

Future<String> getVersion(String channel, int revision) {
  var client = new http.Client();
  var api = new storage.StorageApi(client);
  return api.objects.get('dart-archive',
                         'channels/$channel/release/$revision/VERSION',
                         downloadOptions: DownloadOptions.FullMedia)
      .then((Media media) => JSON.fuse(ASCII).decoder.bind(media.stream).first)
      .then((versionObject) => versionObject['version'])
      .whenComplete(client.close);
}

Future writeHomebrewInfo(String channel, int revision) {
  final buffer = new StringBuffer();
  final moduleName = (channel == 'dev') ? 'DartDev' : 'DartStable';
  buffer.writeln('module $moduleName');
  final files = {'SDK64': 'sdk/dartsdk-macos-x64-release.zip',
                 'SDK32': 'sdk/dartsdk-macos-ia32-release.zip',
                 'DARTIUM': 'dartium/dartium-macos-ia32-release.zip'};
  return Future.forEach(files.keys, (key) {
    return getHash256(channel, revision, files[key]).then((hash) {
      final file = "channels/$channel/release/$revision/${files[key]}";
      buffer.writeln('  ${key}_FILE = "$file"');
      buffer.writeln('  ${key}_HASH = "$hash"');
    });
  })
    .then((_) => getVersion(channel, revision))
    .then((version) {
      buffer.writeln('  VERSION = "$version"');
      buffer.writeln('end');
      return (new File('$repository/data/${channel}_info.rb').openWrite()
        ..write(buffer))
        .close();
    });
}

Future runGit(List<String> args) {
  print("git ${args.join(' ')}");
  return Process.run('git', args, workingDirectory: repository,
                     environment: gitEnvironment)
      .then((result) {
        print(result.stdout);
        print(result.stderr);
      });
}

main(args) {
  final parser = new ArgParser()
      ..addOption('revision', abbr: 'r')
      ..addOption('channel', abbr: 'c', allowed: ['dev', 'stable'])
      ..addOption('key', abbr: 'k');
  final options = parser.parse(args);
  final revision = options['revision'];
  final channel = options['channel'];
  if ([revision, channel, options['key']].contains(null)) {
    print("Usage: update_homebrew.dart -r revision -c channel -k ssh_key\n"
          "  ssh_key should allow pushes to dart-lang/homebrew-dart on github");
    return;
  }
  final sshWrapper = Platform.script.resolve('ssh_with_key').toFilePath();
  gitEnvironment = {'GIT_SSH': sshWrapper,
                    'SSH_KEY_PATH': options['key']};

  Directory.systemTemp.createTemp('update_homebrew')
      .then((tempDir) {
        repository = tempDir.path;
      })
      .then((_) => runGit(
          ['clone', 'git@github.com:dart-lang/homebrew-dart.git', '.']))
      .then((_) => writeHomebrewInfo(channel, revision))
      .then((_) => runGit(['commit', '-a', '-m',
                           'Updated $channel branch to revision $revision']))
      .then((_) => runGit(['push']))
      .whenComplete(() => new Directory(repository).delete(recursive: true));
}
