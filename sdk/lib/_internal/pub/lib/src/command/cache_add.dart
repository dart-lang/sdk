// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.cache_add;

import 'dart:async';

import '../command.dart';
import '../log.dart' as log;
import '../package.dart';
import '../utils.dart';
import '../version.dart';

/// Handles the `cache add` pub command.
class CacheAddCommand extends PubCommand {
  String get description => "Install a package.";
  String get usage =>
      "pub cache add <package> [--version <constraint>] [--all]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-cache.html";
  bool get requiresEntrypoint => false;
  bool get takesArguments => true;

  CacheAddCommand() {
    commandParser.addFlag("all",
        help: "Install all matching versions.",
        negatable: false);

    commandParser.addOption("version", abbr: "v",
        help: "Version constraint.");
  }

  Future onRun() {
    // Make sure there is a package.
    if (commandOptions.rest.isEmpty) {
      usageError("No package to add given.");
    }

    // Don't allow extra arguments.
    if (commandOptions.rest.length > 1) {
      var unexpected = commandOptions.rest.skip(1).map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageError("Unexpected $arguments ${toSentence(unexpected)}.");
    }

    var package = commandOptions.rest.single;

    // Parse the version constraint, if there is one.
    var constraint = VersionConstraint.any;
    if (commandOptions["version"] != null) {
      try {
        constraint = new VersionConstraint.parse(commandOptions["version"]);
      } on FormatException catch (error) {
        usageError(error.message);
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

      if (commandOptions["all"]) {
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
