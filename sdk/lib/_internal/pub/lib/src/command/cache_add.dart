// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.cache_add;

import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../log.dart' as log;
import '../package.dart';
import '../utils.dart';

/// Handles the `cache add` pub command.
class CacheAddCommand extends PubCommand {
  String get name => "add";
  String get description => "Install a package.";
  String get invocation =>
      "pub cache add <package> [--version <constraint>] [--all]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-cache.html";

  CacheAddCommand() {
    argParser.addFlag("all",
        help: "Install all matching versions.",
        negatable: false);

    argParser.addOption("version", abbr: "v",
        help: "Version constraint.");
  }

  Future run() {
    // Make sure there is a package.
    if (argResults.rest.isEmpty) {
      usageException("No package to add given.");
    }

    // Don't allow extra arguments.
    if (argResults.rest.length > 1) {
      var unexpected = argResults.rest.skip(1).map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageException("Unexpected $arguments ${toSentence(unexpected)}.");
    }

    var package = argResults.rest.single;

    // Parse the version constraint, if there is one.
    var constraint = VersionConstraint.any;
    if (argResults["version"] != null) {
      try {
        constraint = new VersionConstraint.parse(argResults["version"]);
      } on FormatException catch (error) {
        usageException(error.message);
      }
    }

    // TODO(rnystrom): Support installing from git too.
    var source = cache.sources["hosted"];

    // TODO(rnystrom): Allow specifying the server.
    return source.getVersions(package, package).then((versions) {
      versions = versions.where(constraint.allows).toList();

      if (versions.isEmpty) {
        // TODO(rnystrom): Show most recent unmatching version?
        fail("Package $package has no versions that match $constraint.");
      }

      downloadVersion(Version version) {
        var id = new PackageId(package, source.name, version, package);
        return cache.contains(id).then((contained) {
          if (contained) {
            // TODO(rnystrom): Include source and description if not hosted.
            // See solve_report.dart for code to harvest.
            log.message("Already cached ${id.name} ${id.version}.");
            return null;
          }

          // Download it.
          return source.downloadToSystemCache(id);
        });
      }

      if (argResults["all"]) {
        // Install them in ascending order.
        versions.sort();
        return Future.forEach(versions, downloadVersion);
      } else {
        // Pick the best matching version.
        versions.sort(Version.prioritize);
        return downloadVersion(versions.last);
      }
    });
  }
}
