// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:code_assets/code_assets.dart' show OS;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks_runner/hooks_runner.dart' show Target;
import 'package:http/http.dart' as http;

/// S_IXUSR bit from POSIX sys/stat.h.
///
/// When the file is user executable, this bit should be set in its mode.
const sIxusr = 0x40;

/// Represents a folder in Dart archive.
///
/// See https://dart.dev/get-dart/archive.
class ArchiveFolder {
  final String version;
  final String revision;
  final Channel channel;

  Uri fileUri(String path, {required Stage stage}) => SdkCache.archiveUri(
      channel: channel, version: 'hash/$revision', stage: stage, path: path);

  ArchiveFolder(
      {required this.version, required this.revision, required this.channel});
}

/// Cache for retrieving artifacts that are not shipped with the Dart SDK.
///
/// Some binaries required by DartDev are not included with the distributed
/// Dart SDK but can be downloaded from the Dart archive. This class downloads
/// requested artifacts and stores them on disk (usually in ~/.dart).
class SdkCache {
  final FileSystem fs;
  late final Directory directory;
  final bool verbose;
  final http.Client _httpClient;
  final StringSink _stderr;
  final io.ProcessResult Function(String) _setUserExecutable;

  SdkCache(
      {required String directory,
      required this.verbose,
      http.Client Function()? createHttpClient,
      FileSystem? fs,
      StringSink? stderr,
      io.ProcessResult Function(String)? chmod,
      http.Client? httpClient})
      : _setUserExecutable = chmod ?? _defaultSetUserExecutable,
        _httpClient = httpClient ?? http.Client(),
        _stderr = stderr ?? io.stderr,
        fs = fs ?? LocalFileSystem() {
    this.directory = this.fs.directory(directory);
  }

  /// Determines the remote location of artifacts for the current SDK.
  ///
  /// The stage depends on host operating system: macOS requires signed
  /// executables.
  ///
  /// Additionally, for the main channel it validates that the given revision
  /// exists in the remote archive, or falls back to the latest revision if it
  /// does not (this may happen when Dart SDK is built locally from a local
  /// revision, or built with RBE, in which case there's no revision at all).
  Future<ArchiveFolder> resolveVersion(
      {required String version,
      required String revision,
      required String channelName,
      Target? host}) async {
    host ??= Target.current;
    final channel = Channel.fromString(channelName);
    if (channel == null) {
      throw ArgumentError('Unsupported channel: "$channelName".');
    }

    final folderFromArgs =
        ArchiveFolder(version: version, revision: revision, channel: channel);
    if (channel != Channel.main) {
      // Past main channel, we always assume that given version and revision
      // must exist on the server.
      if (revision.isEmpty) {
        throw ArgumentError(
            'Channel "${channel.name}" requires valid revision.');
      }

      return folderFromArgs;
    }

    // Require signed artifacts on macOS past main channel (main channel
    // releases aren't signed).
    final stage = host.os == OS.macOS && channel != Channel.main
        ? Stage.signed
        : Stage.raw;

    // On the main channel, on contrary, we do not trust the revision, because
    // it can be empty (if Dart SDK is built with RBE), or be at the local
    // commit revision, which does not exist on storage.
    if (revision.isNotEmpty) {
      // Check that the given revision exists.
      var exists =
          await _exists(folderFromArgs.fileUri('VERSION', stage: stage));

      if (exists) {
        return ArchiveFolder(
            version: version, revision: revision, channel: channel);
      } else {
        if (verbose) {
          _stderr.writeln('Cannot find revision $revision in an archive.');
        }
      }
    }

    // No revision or invalid revision, checking the latest version.
    _stderr.writeln('Checking the latest available revision...');
    (version, revision) =
        await _getLatestVersion(channel: channel, stage: stage);
    if (verbose) {
      _stderr.writeln('Using revision $revision.');
    }
    return ArchiveFolder(
        version: version, revision: revision, channel: channel);
  }

  void _ensureExecutable(File destinationFile, OS hostOS) {
    if (hostOS == OS.windows) {
      return;
    }

    final isUserExecutable = destinationFile.statSync().mode & sIxusr == sIxusr;
    if (isUserExecutable) {
      return;
    }

    final chmodResult = _setUserExecutable(destinationFile.path);
    if (chmodResult.exitCode != 0) {
      throw SdkCacheException(
          'Cannot make ${destinationFile.path} executable, chmod failed.\n'
          'exitCode: ${chmodResult.exitCode}\n'
          'stderr: ${chmodResult.stderr}');
    }
  }

  Future<String> ensureGenSnapshot(
      {required ArchiveFolder archiveFolder,
      required Target target,
      Target? host}) {
    host ??= Target.current;
    // Determine a file base name.
    var basename = 'gen_snapshot_${host}_$target';
    if (host.os == OS.windows) {
      basename = '$basename.exe';
    }
    return ensureArtifact(
        archiveFolder: archiveFolder,
        host: host,
        target: target,
        basename: basename,
        isExecutable: true);
  }

  Future<String> ensureDartAotRuntime({
    required ArchiveFolder archiveFolder,
    required Target target,
    Target? host,
  }) {
    host ??= Target.current;
    return ensureArtifact(
        archiveFolder: archiveFolder,
        basename: 'dartaotruntime_$target',
        target: target,
        host: host,
        isExecutable: false);
  }

  Future<String> ensureArtifact({
    required ArchiveFolder archiveFolder,
    required String basename,
    required Target target,
    required Target host,
    required bool isExecutable,
  }) async {
    // Calculate the local path.
    var localFile =
        directory.childDirectory(archiveFolder.version).childFile(basename);
    if (localFile.existsSync()) {
      if (isExecutable) {
        _ensureExecutable(localFile, host.os);
      }
      return localFile.path;
    }

    localFile.parent.createSync(recursive: true);
    final uri = archiveFolder.fileUri('sdk/$basename',
        stage: resolveStage(
            channel: archiveFolder.channel,
            isExecutable: isExecutable,
            hostOS: host.os));

    try {
      localFile.writeAsBytesSync(await _download(uri));
    } catch (_) {
      _stderr.writeln('Failed to download $uri to ${localFile.path}.');
      _stderr.writeln('If the problem persists, try downloading it manually.');
      rethrow;
    }

    if (isExecutable) {
      _ensureExecutable(localFile, host.os);
    }
    return localFile.path;
  }

  /// For a given channel, find the latest available revision.
  Future<(String, String)> _getLatestVersion(
      {required Channel channel, required Stage stage}) async {
    final json = jsonDecode(utf8.decode(await _download(archiveUri(
        channel: channel, stage: stage, version: 'latest', path: 'VERSION'))));
    return (json['version'] as String, json['revision'] as String);
  }

  Future<bool> _exists(Uri uri) async {
    if (verbose) {
      _stderr.writeln('Checking $uri...');
    }
    final response = await _httpClient.head(uri);
    if (response.statusCode == io.HttpStatus.ok) {
      return true;
    } else if (response.statusCode == io.HttpStatus.notFound) {
      return false;
    } else {
      throw SdkCacheException('HEAD $uri failed: ${response.statusCode}');
    }
  }

  Future<Uint8List> _download(Uri uri) async {
    if (verbose) {
      _stderr.writeln('Downloading $uri...');
    }
    final response = await _httpClient.get(uri);
    if (response.statusCode != io.HttpStatus.ok) {
      throw SdkCacheException('GET $uri failed: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  static Stage resolveStage(
      {required Channel channel,
      required bool isExecutable,
      required OS hostOS}) {
    if (channel == Channel.main || !isExecutable) {
      return Stage.raw;
    }

    return hostOS == OS.macOS ? Stage.signed : Stage.raw;
  }

  static Uri archiveUri(
          {required Channel channel,
          required Stage stage,
          required String version,
          required String path}) =>
      Uri.https('storage.googleapis.com',
          'dart-archive/channels/${channel.name}/${stage.name}/$version/$path');

  /// Default implementation fdor making a [path] executable.
  ///
  /// For testability, the actual implementation can be overridden in [SdkCache]
  /// constructor.
  static io.ProcessResult _defaultSetUserExecutable(String path) =>
      io.Process.runSync('chmod', ['u+x', path]);
}

/// Release stage.
///
/// The stage is related to an internal release process, and not all artifacts
/// are available at all stages.
///
/// E.g. signed stage contains only signed SDK and executables for macOS.
enum Stage {
  raw('raw'),
  signed('signed');

  final String name;

  const Stage(this.name);
}

/// Release channel (e.g. beta, stable).
///
/// It corresponds to release channels at https://dart.dev/get-dart/archive and
/// does not necessarily maps to Git branches.
enum Channel {
  main('main'),
  dev('dev'),
  beta('beta'),
  stable('stable');

  final String name;

  const Channel(this.name);

  static Channel? fromString(String name) {
    for (final value in Channel.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}

class SdkCacheException implements Exception {
  final String message;

  SdkCacheException(this.message);

  @override
  String toString() => 'SdkCacheException: $message';
}
