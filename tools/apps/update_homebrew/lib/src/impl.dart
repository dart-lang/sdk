part of '../update_homebrew.dart';

const _files = {
  'dev': [_x64Files, _ia32Files],
  'stable': [_x64Files, _ia32Files]
};

const _urlBase = 'https://storage.googleapis.com/dart-archive/channels';
const _x64Files = {
  'mac': 'sdk/dartsdk-macos-x64-release.zip',
  'linux': 'sdk/dartsdk-linux-x64-release.zip',
  'linux-arm': 'sdk/dartsdk-linux-arm64-release.zip',
};
const _ia32Files = {
  'linux': 'sdk/dartsdk-linux-ia32-release.zip',
  'linux-arm': 'sdk/dartsdk-linux-arm-release.zip',
};

Future<String> _getHash256(
    String channel, String revision, String download) async {
  var client = http.Client();
  try {
    var api = storage.StorageApi(client);
    var media = await api.objects.get('dart-archive',
        'channels/$channel/release/$revision/$download.sha256sum',
        downloadOptions: DownloadOptions.FullMedia) as Media;

    var hashLine = await ascii.decodeStream(media.stream);
    return RegExp('[0-9a-fA-F]*').stringMatch(hashLine);
  } finally {
    client.close();
  }
}

Future<String> _getVersion(String channel, String revision) async {
  var client = http.Client();
  try {
    var api = storage.StorageApi(client);

    var media = await api.objects.get(
        'dart-archive', 'channels/$channel/release/$revision/VERSION',
        downloadOptions: DownloadOptions.FullMedia) as Media;

    var versionObject =
        await json.fuse(ascii).decoder.bind(media.stream).first as Map;
    return versionObject['version'] as String;
  } finally {
    client.close();
  }
}

Future<Map<String, String>> _getCurrentRevisions(String repository) async {
  var revisions = <String, String>{};
  var lines = await (File(p.join(repository, dartRbFileName))).readAsLines();

  for (var channel in supportedChannels) {
    /// This RegExp between release/ and /sdk matches
    /// * 1 digit followed by
    /// * Any number of letters, numbers, dashes and dots
    /// This covers both numeric- and version-formatted revisions
    ///
    /// Note: all of the regexp escape slashes `\` are double-escaped within the
    /// Dart string
    final regExp = RegExp('channels/$channel/release/(\\d[\\w\\d\\-\\.]*)/sdk');

    revisions[channel] =
        regExp.firstMatch(lines.firstWhere(regExp.hasMatch)).group(1);
  }
  return revisions;
}

Future<Map<String, Map>> _getHashes(Map<String, String> revisions) async {
  var hashes = <String, Map>{};
  for (var channel in supportedChannels) {
    hashes[channel] = {};
    for (var files in _files[channel]) {
      for (var file in files.values) {
        var hash = await _getHash256(channel, revisions[channel], file);
        hashes[channel][file] = hash;
      }
    }
  }
  return hashes;
}

String _createDartFormula(
        Map revisions, Map hashes, String devVersion, String stableVersion) =>
    '''
class Dart < Formula
  desc "The Dart SDK"
  homepage "https://dart.dev"

  version "$stableVersion"
  if OS.mac?
    url "$_urlBase/stable/release/${revisions['stable']}/${_x64Files['mac']}"
    sha256 "${hashes['stable'][_x64Files['mac']]}"
  elsif OS.linux? && Hardware::CPU.intel?
    if Hardware::CPU.is_64_bit?
      url "$_urlBase/stable/release/${revisions['stable']}/${_x64Files['linux']}"
      sha256 "${hashes['stable'][_x64Files['linux']]}"
    else
      url "$_urlBase/stable/release/${revisions['stable']}/${_ia32Files['linux']}"
      sha256 "${hashes['stable'][_ia32Files['linux']]}"
    end
  elsif OS.linux? && Hardware::CPU.arm?
    if Hardware::CPU.is_64_bit?
      url "$_urlBase/stable/release/${revisions['stable']}/${_x64Files['linux-arm']}"
      sha256 "${hashes['stable'][_x64Files['linux-arm']]}"
    else
      url "$_urlBase/stable/release/${revisions['stable']}/${_ia32Files['linux-arm']}"
      sha256 "${hashes['stable'][_ia32Files['linux-arm']]}"
    end
  end

  devel do
    version "$devVersion"
    if OS.mac?
      url "$_urlBase/dev/release/${revisions['dev']}/${_x64Files['mac']}"
      sha256 "${hashes['dev'][_x64Files['mac']]}"
    elsif OS.linux? && Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        url "$_urlBase/dev/release/${revisions['dev']}/${_x64Files['linux']}"
        sha256 "${hashes['dev'][_x64Files['linux']]}"
      else
        url "$_urlBase/dev/release/${revisions['dev']}/${_ia32Files['linux']}"
        sha256 "${hashes['dev'][_ia32Files['linux']]}"
      end
    elsif OS.linux? && Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        url "$_urlBase/dev/release/${revisions['dev']}/${_x64Files['linux-arm']}"
        sha256 "${hashes['dev'][_x64Files['linux-arm']]}"
      else
        url "$_urlBase/dev/release/${revisions['dev']}/${_ia32Files['linux-arm']}"
        sha256 "${hashes['dev'][_ia32Files['linux-arm']]}"
      end
    end
  end

  def install
    libexec.install Dir["*"]
    bin.install_symlink "#{libexec}/bin/dart"
    bin.write_exec_script Dir["#{libexec}/bin/{pub,dart?*}"]
  end

  def shim_script(target)
    <<~EOS
      #!/usr/bin/env bash
      exec "#{prefix}/#{target}" "\$@"
    EOS
  end

  def caveats; <<~EOS
    Please note the path to the Dart SDK:
      #{opt_libexec}
    EOS
  end

  test do
    (testpath/"sample.dart").write <<~EOS
      void main() {
        print(r"test message");
      }
    EOS

    assert_equal "test message\\n", shell_output("#{bin}/dart sample.dart")
  end
end
''';
