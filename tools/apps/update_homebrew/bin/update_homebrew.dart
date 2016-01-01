// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library update_homebrew;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/common/common.dart' show DownloadOptions, Media;
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:http/http.dart' as http;
import 'package:stack_trace/stack_trace.dart';

String repository; // The path to the temporary git checkout of dart-homebrew.
Map gitEnvironment; // Pass a wrapper script for SSH to git in the environment.

const GITHUB_REPO = 'dart-lang/homebrew-dart';

const CHANNELS = const ['dev', 'stable'];

const FILES = const [x64File, ia32File, dartiumFile, contentShellFile];

const urlBase = 'https://storage.googleapis.com/dart-archive/channels';
const x64File = 'sdk/dartsdk-macos-x64-release.zip';
const ia32File = 'sdk/dartsdk-macos-ia32-release.zip';
const dartiumFile = 'dartium/dartium-macos-ia32-release.zip';
const contentShellFile = 'dartium/content_shell-macos-ia32-release.zip';

Future<String> getHash256(
    String channel, String revision, String download) async {
  var client = new http.Client();
  try {
    var api = new storage.StorageApi(client);
    var media = await api.objects.get('dart-archive',
        'channels/$channel/release/$revision/$download.sha256sum',
        downloadOptions: DownloadOptions.FullMedia);

    var hashLine = await ASCII.decodeStream(media.stream);
    return new RegExp('[0-9a-fA-F]*').stringMatch(hashLine);
  } finally {
    client.close();
  }
}

Future<String> getVersion(String channel, String revision) async {
  var client = new http.Client();
  try {
    var api = new storage.StorageApi(client);

    var media = await api.objects.get(
        'dart-archive', 'channels/$channel/release/$revision/VERSION',
        downloadOptions: DownloadOptions.FullMedia);

    var versionObject = await JSON.fuse(ASCII).decoder.bind(media.stream).first;
    return versionObject['version'];
  } finally {
    client.close();
  }
}

Future<Map> getCurrentRevisions() async {
  var revisions = <String, String>{};
  var lines = await (new File('$repository/dart.rb')).readAsLines();

  for (var channel in CHANNELS) {
    /// This RegExp between release/ and /sdk matches
    /// * 1 digit followed by
    /// * Any number of letters, numbers, dashes and dots
    /// This covers both numeric- and version-formatted revisions
    ///
    /// Note: all of the regexp escape slashes `\` are double-escaped within the
    /// Dart string
    final regExp =
        new RegExp('channels/$channel/release/(\\d[\\w\\d\\-\\.]*)/sdk');

    revisions[channel] =
        regExp.firstMatch(lines.firstWhere(regExp.hasMatch)).group(1);
  }
  return revisions;
}

Future<Map> getHashes(Map revisions) async {
  var hashes = <String, Map>{};
  for (var channel in CHANNELS) {
    hashes[channel] = {};
    for (var file in FILES) {
      var hash = await getHash256(channel, revisions[channel], file);
      hashes[channel][file] = hash;
    }
  }
  return hashes;
}

Future writeHomebrewInfo(String channel, String revision) async {
  var revisions = await getCurrentRevisions();

  if (revisions[channel] == revision) {
    print("Channel $channel is already at revision $revision in homebrew.");
    exit(0);
  }
  revisions[channel] = revision;
  var hashes = await getHashes(revisions);
  var devVersion = await getVersion('dev', revisions['dev']);

  var stableVersion = await getVersion('stable', revisions['stable']);

  await new File('$repository/dart.rb').writeAsString(
      createDartFormula(revisions, hashes, devVersion, stableVersion),
      flush: true);
}

String createDartFormula(
    Map revisions, Map hashes, String devVersion, String stableVersion) => '''
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

  option 'with-content-shell', 'Download and install content_shell -- headless Dartium for testing'
  option 'with-dartium', 'Download and install Dartium -- Chromium with Dart'

  devel do
    version '$devVersion'
    if MacOS.prefer_64_bit?
      url '$urlBase/dev/release/${revisions['dev']}/$x64File'
      sha256 '${hashes['dev'][x64File]}'
    else
      url '$urlBase/dev/release/${revisions['dev']}/$ia32File'
      sha256 '${hashes['dev'][ia32File]}'
    end

    resource 'content_shell' do
      version '$devVersion'
      url '$urlBase/dev/release/${revisions['dev']}/$contentShellFile'
      sha256 '${hashes['dev'][contentShellFile]}'
    end

    resource 'dartium' do
      version '$devVersion'
      url '$urlBase/dev/release/${revisions['dev']}/$dartiumFile'
      sha256 '${hashes['dev'][dartiumFile]}'
    end
  end

  resource 'content_shell' do
    version '$stableVersion'
    url '$urlBase/stable/release/${revisions['stable']}/$contentShellFile'
    sha256 '${hashes['stable'][contentShellFile]}'
  end

  resource 'dartium' do
    version '$stableVersion'
    url '$urlBase/stable/release/${revisions['stable']}/$dartiumFile'
    sha256 '${hashes['stable'][dartiumFile]}'
  end

  def install
    libexec.install Dir['*']
    bin.install_symlink "#{libexec}/bin/dart"
    bin.write_exec_script Dir["#{libexec}/bin/{pub,dart?*}"]

    if build.with? 'dartium'
      dartium_binary = 'Chromium.app/Contents/MacOS/Chromium'
      prefix.install resource('dartium')
      (bin+"dartium").write shim_script dartium_binary
    end

    if build.with? 'content-shell'
      content_shell_binary = 'Content Shell.app/Contents/MacOS/Content Shell'
      prefix.install resource('content_shell')
      (bin+"content_shell").write shim_script content_shell_binary
    end
  end

  def shim_script target
    <<-EOS.undent
      #!/bin/bash
      exec "#{prefix}/#{target}" "\$@"
    EOS
  end

  def caveats; <<-EOS.undent
    Please note the path to the Dart SDK:
      #{opt_libexec}

    --with-dartium:
      To use with IntelliJ, set the Dartium execute home to:
        #{opt_prefix}/Chromium.app
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

Future runGit(List<String> args) async {
  print("git ${args.join(' ')}");

  var result = await Process.run('git', args,
      workingDirectory: repository, environment: gitEnvironment);

  print(result.stdout);
  print(result.stderr);
}

main(args) async {
  final parser = new ArgParser()
    ..addOption('revision', abbr: 'r')
    ..addOption('channel', abbr: 'c', allowed: ['dev', 'stable'])
    ..addOption('key', abbr: 'k');
  final options = parser.parse(args);
  final revision = options['revision'];
  final channel = options['channel'];
  if ([revision, channel].contains(null)) {
    print("Usage: update_homebrew.dart -r revision -c channel [-k ssh_key]\n"
        "  ssh_key should allow pushes to ${GITHUB_REPO} on github");
    return;
  }

  final key = options['key'];
  if (key != null) {
    final sshWrapper = Platform.script.resolve('ssh_with_key').toFilePath();
    gitEnvironment = {'GIT_SSH': sshWrapper, 'SSH_KEY_PATH': key};
  }

  Chain.capture(() async {
    var tempDir = await Directory.systemTemp.createTemp('update_homebrew');

    try {
      repository = tempDir.path;

      await runGit(['clone', 'git@github.com:${GITHUB_REPO}.git', '.']);
      await writeHomebrewInfo(channel, revision);
      await runGit([
        'commit',
        '-a',
        '-m',
        'Updated $channel branch to revision $revision'
      ]);

      await runGit(['push']);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }, onError: (error, chain) {
    print(error);
    print(chain.terse);
  });
}
