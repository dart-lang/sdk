part of '../update_homebrew.dart';

const _files = [
  'dartsdk-macos-x64-release.zip',
  'dartsdk-linux-x64-release.zip',
  'dartsdk-linux-arm64-release.zip',
  'dartsdk-linux-ia32-release.zip',
  'dartsdk-linux-arm-release.zip',
];

const _host = 'https://storage.googleapis.com/dart-archive/channels';

Future<String> _getHash256(
    String channel, String version, String download) async {
  var client = http.Client();
  try {
    var api = storage.StorageApi(client);
    var url = 'channels/$channel/release/$version/sdk/$download.sha256sum';
    var media = await api.objects.get('dart-archive', url,
        downloadOptions: DownloadOptions.FullMedia) as Media;
    var hashLine = await ascii.decodeStream(media.stream);
    return RegExp('[0-9a-fA-F]*').stringMatch(hashLine);
  } finally {
    client.close();
  }
}

Future<void> _updateFormula(String channel, File file, String version,
    Map<String, String> hashes) async {
  var contents = await file.readAsString();

  // Replace the version identifier. Formulas with stable and pre-release
  // versions have multiple identifiers and only the right one should be
  // updated.
  var versionId = channel == 'stable'
      ? RegExp(r'version \"\d+\.\d+.\d+\"')
      : RegExp(r'version \"\d+\.\d+.\d+\-.+\"');
  contents = contents.replaceAll(versionId, 'version "$version"');

  // Extract files and hashes that are stored in the formula in this format:
  //  url "<url base>/<channel>/release/<version>/sdk/<artifact>.zip"
  //  sha256 "<hash>"
  var filesAndHashes = RegExp(
      'channels/$channel/release'
      r'/(\d[\w\d\-\.]*)/sdk/([\w\d\-\.]+)\"\n(\s+)sha256 \"[\da-f]+\"',
      multiLine: true);
  contents = contents.replaceAllMapped(filesAndHashes, (m) {
    var currentVersion = m.group(1);
    if (currentVersion == version) {
      throw new ArgumentError(
          'Channel $channel is already at version $version in homebrew.');
    }
    var artifact = m.group(2);
    var indent = m.group(3);
    return 'channels/$channel/release/$version/sdk/$artifact"\n'
        '${indent}sha256 "${hashes[artifact]}"';
  });
  await file.writeAsString(contents, flush: true);
}

Future<Map<String, String>> _getHashes(String channel, String version) async {
  return <String, String>{
    for (var file in _files) file: await _getHash256(channel, version, file)
  };
}
