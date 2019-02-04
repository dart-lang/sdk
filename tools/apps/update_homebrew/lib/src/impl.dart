part of '../update_homebrew.dart';

const _files = {
  'dev': [_x64File, _ia32File],
  'stable': [_x64File, _ia32File]
};

const _urlBase = 'https://storage.googleapis.com/dart-archive/channels';
const _x64File = 'sdk/dartsdk-macos-x64-release.zip';
const _ia32File = 'sdk/dartsdk-macos-ia32-release.zip';

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
    for (var file in _files[channel]) {
      var hash = await _getHash256(channel, revisions[channel], file);
      hashes[channel][file] = hash;
    }
  }
  return hashes;
}

String _createDartFormula(
        Map revisions, Map hashes, String devVersion, String stableVersion) =>
    '''
class Dart < Formula
  desc "The Dart SDK"
  homepage "https://www.dartlang.org/"

  version "$stableVersion"
  if Hardware::CPU.is_64_bit?
    url "$_urlBase/stable/release/${revisions['stable']}/$_x64File"
    sha256 "${hashes['stable'][_x64File]}"
  else
    url "$_urlBase/stable/release/${revisions['stable']}/$_ia32File"
    sha256 "${hashes['stable'][_ia32File]}"
  end

  devel do
    version "$devVersion"
    if Hardware::CPU.is_64_bit?
      url "$_urlBase/dev/release/${revisions['dev']}/$_x64File"
      sha256 "${hashes['dev'][_x64File]}"
    else
      url "$_urlBase/dev/release/${revisions['dev']}/$_ia32File"
      sha256 "${hashes['dev'][_ia32File]}"
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
