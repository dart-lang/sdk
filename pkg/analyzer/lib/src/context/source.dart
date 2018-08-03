// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show min;

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' as utils;
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:package_config/packages.dart';

/**
 * Instances of the class `SourceFactory` resolve possibly relative URI's
 * against an existing [Source].
 */
class SourceFactoryImpl implements SourceFactory {
  @override
  AnalysisContext context;

  /**
   * URI processor used to find mappings for `package:` URIs found in a
   * `.packages` config file.
   */
  final Packages _packages;

  /**
   * Resource provider used in working with package maps.
   */
  final ResourceProvider _resourceProvider;

  /**
   * The resolvers used to resolve absolute URI's.
   */
  final List<UriResolver> resolvers;

  /**
   * The predicate to determine is [Source] is local.
   */
  LocalSourcePredicate _localSourcePredicate = LocalSourcePredicate.NOT_SDK;

  /**
   * Cache of mapping of absolute [Uri]s to [Source]s.
   */
  final HashMap<Uri, Source> _absoluteUriToSourceCache =
      new HashMap<Uri, Source>();

  /**
   * Initialize a newly created source factory with the given absolute URI
   * [resolvers] and optional [_packages] resolution helper.
   */
  SourceFactoryImpl(this.resolvers,
      [this._packages, ResourceProvider resourceProvider])
      : _resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  @override
  DartSdk get dartSdk {
    List<UriResolver> resolvers = this.resolvers;
    int length = resolvers.length;
    for (int i = 0; i < length; i++) {
      UriResolver resolver = resolvers[i];
      if (resolver is DartUriResolver) {
        DartUriResolver dartUriResolver = resolver;
        return dartUriResolver.dartSdk;
      }
    }
    return null;
  }

  @override
  void set localSourcePredicate(LocalSourcePredicate localSourcePredicate) {
    this._localSourcePredicate = localSourcePredicate;
  }

  @override
  Map<String, List<Folder>> get packageMap {
    // Start by looking in .packages.
    if (_packages != null) {
      Map<String, List<Folder>> packageMap = <String, List<Folder>>{};
      _packages.asMap().forEach((String name, Uri uri) {
        if (uri.scheme == 'file' || uri.scheme == '' /* unspecified */) {
          packageMap[name] = <Folder>[
            _resourceProvider.getFolder(uri.toFilePath())
          ];
        }
      });
      return packageMap;
    }

    // Default to the PackageMapUriResolver.
    PackageMapUriResolver resolver = resolvers
        .firstWhere((r) => r is PackageMapUriResolver, orElse: () => null);
    return resolver?.packageMap;
  }

  @override
  SourceFactory clone() {
    SourceFactory factory =
        new SourceFactory(resolvers, _packages, _resourceProvider);
    factory.localSourcePredicate = _localSourcePredicate;
    return factory;
  }

  @override
  Source forUri(String absoluteUri) {
    try {
      Uri uri = Uri.parse(absoluteUri);
      if (uri.isAbsolute) {
        return _internalResolveUri(null, uri);
      }
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          "Could not resolve URI: $absoluteUri",
          new CaughtException(exception, stackTrace));
    }
    return null;
  }

  @override
  Source forUri2(Uri absoluteUri) {
    if (absoluteUri.isAbsolute) {
      try {
        return _internalResolveUri(null, absoluteUri);
      } on AnalysisException catch (exception, stackTrace) {
        AnalysisEngine.instance.logger.logError(
            "Could not resolve URI: $absoluteUri",
            new CaughtException(exception, stackTrace));
      }
    }
    return null;
  }

  @override
  Source fromEncoding(String encoding) {
    Source source = forUri(encoding);
    if (source == null) {
      throw new ArgumentError("Invalid source encoding: '$encoding'");
    }
    return source;
  }

  @override
  bool isLocalSource(Source source) => _localSourcePredicate.isLocal(source);

  @override
  Source resolveUri(Source containingSource, String containedUri) {
    if (containedUri == null || containedUri.isEmpty) {
      return null;
    }
    try {
      // Force the creation of an escaped URI to deal with spaces, etc.
      return _internalResolveUri(containingSource, Uri.parse(containedUri));
    } on FormatException {
      return null;
    } catch (exception, stackTrace) {
      String containingFullName =
          containingSource != null ? containingSource.fullName : '<null>';
      AnalysisEngine.instance.logger.logInformation(
          "Could not resolve URI ($containedUri) "
          "relative to source ($containingFullName)",
          new CaughtException(exception, stackTrace));
      return null;
    }
  }

  @override
  Uri restoreUri(Source source) {
    // First see if a resolver can restore the URI.
    for (UriResolver resolver in resolvers) {
      Uri uri = resolver.restoreAbsolute(source);
      if (uri != null) {
        // Now see if there's a package mapping.
        Uri packageMappedUri = _getPackageMapping(uri);
        if (packageMappedUri != null) {
          return packageMappedUri;
        }
        // Fall back to the resolver's computed URI.
        return uri;
      }
    }

    return null;
  }

  Uri _getPackageMapping(Uri sourceUri) {
    if (_packages == null) {
      return null;
    }
    if (sourceUri.scheme != 'file') {
      //TODO(pquitslund): verify this works for non-file URIs.
      return null;
    }

    Uri packageUri;
    _packages.asMap().forEach((String name, Uri uri) {
      if (packageUri == null) {
        if (utils.startsWith(sourceUri, uri)) {
          String relativePath = sourceUri.path
              .substring(min(uri.path.length, sourceUri.path.length));
          packageUri = Uri.parse('package:$name/$relativePath');
        }
      }
    });
    return packageUri;
  }

  /**
   * Return a source object representing the URI that results from resolving
   * the given (possibly relative) contained URI against the URI associated
   * with an existing source object, or `null` if the URI could not be resolved.
   *
   * @param containingSource the source containing the given URI
   * @param containedUri the (possibly relative) URI to be resolved against the
   *        containing source
   * @return the source representing the contained URI
   * @throws AnalysisException if either the contained URI is invalid or if it
   *         cannot be resolved against the source object's URI
   */
  Source _internalResolveUri(Source containingSource, Uri containedUri) {
    if (!containedUri.isAbsolute) {
      if (containingSource == null) {
        throw new AnalysisException(
            "Cannot resolve a relative URI without a containing source: "
            "$containedUri");
      }
      containedUri =
          utils.resolveRelativeUri(containingSource.uri, containedUri);
    }

    Uri actualUri = containedUri;

    // Check .packages and update target and actual URIs as appropriate.
    if (_packages != null && containedUri.scheme == 'package') {
      Uri packageUri = null;
      try {
        packageUri =
            _packages.resolve(containedUri, notFound: (Uri packageUri) => null);
      } on ArgumentError {
        // Fall through to try resolvers.
      }

      if (packageUri != null) {
        // Ensure scheme is set.
        if (packageUri.scheme == '') {
          packageUri = packageUri.replace(scheme: 'file');
        }
        containedUri = packageUri;
      }
    }

    return _absoluteUriToSourceCache.putIfAbsent(actualUri, () {
      for (UriResolver resolver in resolvers) {
        Source result = resolver.resolveAbsolute(containedUri, actualUri);
        if (result != null) {
          return result;
        }
      }
      return null;
    });
  }
}
