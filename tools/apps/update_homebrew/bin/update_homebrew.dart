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

final CHANNELS = ['dev', 'stable'];

final SDK_FILES = ['sdk/dartsdk-macos-x64-release.zip',
                   'sdk/dartsdk-macos-ia32-release.zip' ];
final DARTIUM_FILES = ['dartium/dartium-macos-ia32-release.zip' ];
final FILES = []..addAll(SDK_FILES)..addAll(DARTIUM_FILES);


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

Future<Map> setCurrentRevisions(Map revisions) {
  return new File('$repository/dart.rb')
    .readAsLines()
    .then((lines) {
      for (var channel in CHANNELS) {
        final regExp = new RegExp('channels/$channel/release/(\\d*)/sdk');
        revisions[channel] =
	    regExp.firstMatch(lines.firstWhere(regExp.hasMatch)).group(1);
      }
    });
}

Future<Map> setHashes(Map revisions, Map hashes) {
  List waitOn = [];
  for (var channel in CHANNELS) {
    hashes[channel] = {};
    for (var file in FILES) {
      waitOn.add(getHash256(channel, revisions[channel], file).then((hash) {
        hashes[channel][file] = hash;
      }));
    }
  }
  return Future.wait(waitOn);
}

Future writeHomebrewInfo(String channel, int revision) {
  var revisions = {};
  var hashes = {};
  var devVersion;
  var stableVersion;
  return setCurrentRevisions(revisions).then((_) {
    if (revisions[channel] == revision) {
      print("Channel $channel is already at revision $revision in homebrew.");
      exit(0);
    }
    revisions[channel] = revision;
    return setHashes(revisions, hashes);
  }).then((_) {
    return getVersion('dev', revisions['dev']);
  }).then((version) {
    devVersion = version;
    return getVersion('stable', revisions['stable']);
  }).then((version) {
    stableVersion = version;
    return (new File('$repository/dartium.rb').openWrite()
      ..write(DartiumFile(revisions, hashes, devVersion, stableVersion)))
      .close();
  }).then((_) {
    return (new File('$repository/dart.rb').openWrite()
      ..write(DartFile(revisions, hashes, devVersion, stableVersion)))
      .close();
  });
}

String DartiumFile(Map revisions,
                   Map hashes,
                   String devVersion,
                   String stableVersion) {
  final urlBase = 'https://storage.googleapis.com/dart-archive/channels';
  final dartiumFile = 'dartium/dartium-macos-ia32-release.zip';

  return '''
require 'formula'

class Dartium < Formula
  homepage "https://www.dartlang.org"

  version '$stableVersion'
  url '$urlBase/stable/release/${revisions['stable']}/$dartiumFile'
  sha256 '${hashes['stable'][dartiumFile]}'

  devel do
    version '$devVersion'
    url '$urlBase/dev/release/${revisions['dev']}/$dartiumFile'
    sha256 '${hashes['dev'][dartiumFile]}'
  end

  def shim_script target
    <<-EOS.undent
      #!/bin/bash
      open "#{prefix}/#{target}" "\$@"
    EOS
  end

  def install
    prefix.install Dir['*']
    (bin+"dartium").write shim_script "Chromium.app"
  end

  def caveats; <<-EOS.undent
     To use with IntelliJ, set the Dartium execute home to:
        #{prefix}/Chromium.app
    EOS
  end

  test do
    system "#{bin}/dartium"
  end
end
''';
}

String DartFile(Map revisions,
                Map hashes,
                String devVersion,
                String stableVersion) {
  final urlBase = 'https://storage.googleapis.com/dart-archive/channels';
  final x64File = 'sdk/dartsdk-macos-x64-release.zip';
  final ia32File = 'sdk/dartsdk-macos-ia32-release.zip';

  return '''
require 'formula'

class Dart < Formula
  homepage 'https://www.dartlang.org/'

  version '$stableVersion'
  if MacOS.prefer_64_bit?
    url '$urlBase/stable/release/${revisions['stable']}/$x64File'
    sha256 '${hashes['stable'][x64File]}'
  else
    url '$urlBase/stable/release/${revisions['stable']}/$ia32File'
    sha256 '${hashes['stable'][ia32File]}'
  end

  devel do
    version '$devVersion'
    if MacOS.prefer_64_bit?
      url '$urlBase/dev/release/${revisions['dev']}/$x64File'
      sha256 '${hashes['dev'][x64File]}'
    else
      url '$urlBase/dev/release/${revisions['dev']}/$ia32File'
      sha256 '${hashes['dev'][ia32File]}'
    end
  end

  def install
    libexec.install Dir['*']
    bin.install_symlink "#{libexec}/bin/dart"
    bin.write_exec_script Dir["#{libexec}/bin/{pub,docgen,dart?*}"]
  end

  def caveats; <<-EOS.undent
    Please note the path to the Dart SDK:
      #{opt_libexec}
    EOS
  end

  test do
    (testpath/'sample.dart').write <<-EOS.undent
      void main() {
        print(r"test message");
      }
    EOS

    assert_equal "test message\\n", shell_output("#{bin}/dart sample.dart")
  end
end
''';
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
