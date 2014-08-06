// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.src.dart_sdk;

import 'dart:convert' as convert;
import 'dart:io' show File, Platform, Process;
import 'package:path/path.dart' as path;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';


/// Attempts to provide the current Dart SDK directory.
///
/// This will return null if the SDK cannot be found
///
/// Note that this may not be correct when executing outside of `pub`.
String get dartSdkDirectory {

  bool isSdkDir(String dirname) =>
      new File(path.join(dirname, 'lib', '_internal', 'libraries.dart'))
        .existsSync();

  if (path.split(Platform.executable).length == 1) {
    // TODO(blois): make this cross-platform.
    // HACK: A single part, hope it's on the path.
    var result = Process.runSync('which', ['dart'],
        stdoutEncoding: convert.UTF8);

    var sdkDir = path.dirname(path.dirname(result.stdout));
    if (isSdkDir(sdkDir)) return sdkDir;
  }
  var dartDir = path.dirname(path.absolute(Platform.executable));
  // If there's a sub-dir named dart-sdk then we're most likely executing from
  // a dart enlistment build directory.
  if (isSdkDir(path.join(dartDir, 'dart-sdk'))) {
    return path.join(dartDir, 'dart-sdk');
  }
  // If we can find libraries.dart then it's the root of the SDK.
  if (isSdkDir(dartDir)) return dartDir;

  var parts = path.split(dartDir);
  // If the dart executable is within the sdk dir then get the root.
  if (parts.contains('dart-sdk')) {
    var dartSdkDir = path.joinAll(parts.take(parts.indexOf('dart-sdk') + 1));
    if (isSdkDir(dartSdkDir)) return dartSdkDir;
  }

  return null;
}

/// Sources that are annotated with a source uri, so it is easy to resolve how
/// to support `Resolver.getImportUri`.
abstract class UriAnnotatedSource extends Source {
  Uri get uri;
}

/// Dart SDK which wraps all Dart sources as [UriAnnotatedSource] to ensure they
/// are tracked with Uris.
class DirectoryBasedDartSdkProxy extends DirectoryBasedDartSdk {
  DirectoryBasedDartSdkProxy(String sdkDirectory)
      : super(new JavaFile(sdkDirectory));

  Source mapDartUri(String dartUri) =>
      DartSourceProxy.wrap(super.mapDartUri(dartUri), Uri.parse(dartUri));
}

/// Dart SDK resolver which wraps all Dart sources to ensure they are tracked
/// with URIs.
class DartUriResolverProxy implements DartUriResolver {
  final DartUriResolver _proxy;
  DartUriResolverProxy(DartSdk sdk) :
      _proxy = new DartUriResolver(sdk);

  Source resolveAbsolute(Uri uri) =>
    DartSourceProxy.wrap(_proxy.resolveAbsolute(uri), uri);

  DartSdk get dartSdk => _proxy.dartSdk;

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw new UnsupportedError('fromEncoding is not supported');

  Uri restoreAbsolute(Source source) =>
      throw new UnsupportedError('restoreAbsolute is not supported');
}

/// Source file for dart: sources which track the sources with dart: URIs.
///
/// This is primarily to support [Resolver.getImportUri] for Dart SDK (dart:)
/// based libraries.
class DartSourceProxy implements UriAnnotatedSource {

  /// Absolute URI which this source can be imported from
  final Uri uri;

  /// Underlying source object.
  final Source _proxy;

  DartSourceProxy(this._proxy, this.uri);

  /// Ensures that [source] is a DartSourceProxy.
  static DartSourceProxy wrap(Source source, Uri uri) {
    if (source == null || source is DartSourceProxy) return source;
    return new DartSourceProxy(source, uri);
  }

  Source resolveRelative(Uri relativeUri) {
    // Assume that the type can be accessed via this URI, since these
    // should only be parts for dart core files.
    return wrap(_proxy.resolveRelative(relativeUri), uri);
  }

  Uri resolveRelativeUri(Uri relativeUri) {
    return _proxy.resolveRelativeUri(relativeUri);
  }

  bool exists() => _proxy.exists();

  bool operator ==(Object other) =>
    (other is DartSourceProxy && _proxy == other._proxy);

  int get hashCode => _proxy.hashCode;

  TimestampedData<String> get contents => _proxy.contents;

  String get encoding => _proxy.encoding;

  String get fullName => _proxy.fullName;

  int get modificationStamp => _proxy.modificationStamp;

  String get shortName => _proxy.shortName;

  UriKind get uriKind => _proxy.uriKind;

  bool get isInSystemLibrary => _proxy.isInSystemLibrary;
}


/// Dart SDK which contains a mock implementation of the SDK libraries. May be
/// used to speed up resultion when most of the core libraries is not needed.
class MockDartSdk implements DartSdk {
  final Map<Uri, _MockSdkSource> _sources = {};
  final bool reportMissing;
  final Map<String, SdkLibrary> _libs = {};
  final String sdkVersion = '0';
  List<String> get uris => _sources.keys.map((uri) => '$uri').toList();
  final AnalysisContext context = new SdkAnalysisContext();
  DartUriResolver _resolver;
  DartUriResolver get resolver => _resolver;

  MockDartSdk(Map<String, String> sources, {this.reportMissing}) {
    sources.forEach((uriString, contents) {
      var uri = Uri.parse(uriString);
      _sources[uri] = new _MockSdkSource(uri, contents);
      _libs[uriString] = new SdkLibraryImpl(uri.path)
        ..setDart2JsLibrary()
        ..setVmLibrary();
    });
    _resolver = new DartUriResolver(this);
    context.sourceFactory = new SourceFactory([_resolver]);
  }

  List<SdkLibrary> get sdkLibraries => _libs.values.toList();
  SdkLibrary getSdkLibrary(String dartUri) => _libs[dartUri];
  Source mapDartUri(String dartUri) => _getSource(Uri.parse(dartUri));

  Source fromEncoding(UriKind kind, Uri uri) {
    if (kind != UriKind.DART_URI) {
      throw new UnsupportedError('expected dart: uri kind, got $kind.');
    }
    return _getSource(uri);
  }

  Source _getSource(Uri uri) {
    var src = _sources[uri];
    if (src == null) {
      if (reportMissing) print('warning: missing mock for $uri.');
      _sources[uri] = src =
          new _MockSdkSource(uri, 'library dart.${uri.path};');
    }
    return src;
  }

  @override
  Source fromFileUri(Uri uri) {
    throw new UnsupportedError('MockDartSdk.fromFileUri');
  }
}

class _MockSdkSource implements UriAnnotatedSource {
  /// Absolute URI which this source can be imported from.
  final Uri uri;
  final String _contents;

  _MockSdkSource(this.uri, this._contents);

  bool exists() => true;

  int get hashCode => uri.hashCode;

  final int modificationStamp = 1;

  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, _contents);

  String get encoding => "${uriKind.encoding}$uri";

  String get fullName => shortName;

  String get shortName => uri.path;

  UriKind get uriKind => UriKind.DART_URI;

  bool get isInSystemLibrary => true;

  Source resolveRelative(Uri relativeUri) =>
      throw new UnsupportedError('not expecting relative urls in dart: mocks');

  Uri resolveRelativeUri(Uri relativeUri) =>
      throw new UnsupportedError('not expecting relative urls in dart: mocks');
}
