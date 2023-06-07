// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';

/// An object that represents the location of a package name.
class PubPackageNameProducer extends KeyValueProducer {
  const PubPackageNameProducer();

  @override
  Producer producerForKey(String key) => PubPackageVersionProducer(key);

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    final cachedPackages = request.pubPackageService?.cachedPackages;
    if (cachedPackages != null) {
      var relevance = cachedPackages.length;
      yield* cachedPackages.map((package) =>
          packageName('${package.packageName}: ', relevance: relevance--));
    }
  }
}

/// An object that represents the location of the version number for a pub
/// package.
class PubPackageVersionProducer extends Producer {
  final String package;

  const PubPackageVersionProducer(this.package);

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    final versions = request.pubPackageService
        ?.cachedPubOutdatedVersions(request.filePath, package);
    final resolvable = versions?.resolvableVersion;
    var latest = versions?.latestVersion;

    // If we didn't get a latest version from the "pub outdated" results, we can
    // use the result from the Pub API if we've called it (this will usually
    // only be the case for LSP where a resolve() call was sent).
    //
    // This allows us (in some cases) to still show version numbers even if the
    // package was newly added to pubspec and not saved, so not yet in the
    // "pub outdated" results.
    latest ??= request.pubPackageService?.cachedPubApiLatestVersion(package);

    if (resolvable != null && resolvable != latest) {
      yield identifier('^$resolvable', docComplete: '_latest compatible_');
    }
    if (latest != null) {
      yield identifier('^$latest', docComplete: '_latest_');
    }
  }
}

/// A completion generator that can produce completion suggestions for pubspec
/// files.
class PubspecGenerator extends YamlCompletionGenerator {
  /// The producer representing the known valid structure of a pubspec file.
  static const MapProducer pubspecProducer = MapProducer({
    'name': EmptyProducer(),
    'version': EmptyProducer(),
    'description': EmptyProducer(),
    'homepage': EmptyProducer(),
    'repository': EmptyProducer(),
    'issue_tracker': EmptyProducer(),
    'documentation': EmptyProducer(),
    'executables': EmptyProducer(),
    'publish_to': EmptyProducer(),
    'environment': MapProducer({
      'flutter': EmptyProducer(),
      'sdk': EmptyProducer(),
    }),
    'dependencies': PubPackageNameProducer(),
    'dev_dependencies': PubPackageNameProducer(),
    // TODO(brianwilkerson) Suggest names already listed under 'dependencies'
    //  and 'dev_dependencies'.
    'dependency_overrides': EmptyProducer(),
    'flutter': MapProducer({
      'assets': ListProducer(FilePathProducer()),
      'fonts': ListProducer(MapProducer({
        'family': EmptyProducer(),
        'fonts': ListProducer(MapProducer({
          'asset': EmptyProducer(),
          'style': EnumProducer(['italic', 'normal']),
          'weight': EnumProducer(
              ['100', '200', '300', '400', '500', '600', '700', '800', '900']),
        })),
      })),
      'generate': BooleanProducer(),
      'module': MapProducer({
        'androidX': BooleanProducer(),
        'androidPackage': EmptyProducer(),
        'iosBundleIdentifier': EmptyProducer(),
      }),
      'plugin': MapProducer({
        'platforms': MapProducer({
          'android': MapProducer({
            'package': EmptyProducer(),
            'pluginClass': EmptyProducer(),
          }),
          'ios': MapProducer({
            'pluginClass': EmptyProducer(),
          }),
          'linux': MapProducer({
            'dartPluginClass': EmptyProducer(),
            'pluginClass': EmptyProducer(),
          }),
          'macos': MapProducer({
            'dartPluginClass': EmptyProducer(),
            'pluginClass': EmptyProducer(),
          }),
          'web': MapProducer({
            'fileName': EmptyProducer(),
            'pluginClass': EmptyProducer(),
          }),
          'windows': MapProducer({
            'dartPluginClass': EmptyProducer(),
            'pluginClass': EmptyProducer(),
          }),
        }),
      }),
      'uses-material-design': BooleanProducer(),
    }),
    'screenshots': ListProducer(MapProducer({
      'description': EmptyProducer(),
      'path': FilePathProducer(),
    })),
    'topics': EmptyProducer(),
  });

  /// Initialize a newly created suggestion generator for pubspec files.
  PubspecGenerator(
      super.resourceProvider, PubPackageService super.pubPackageService);

  @override
  Producer get topLevelProducer => pubspecProducer;
}
