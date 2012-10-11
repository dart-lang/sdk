// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file contains functionality for getting dart version numbers using
 * our standard version construction method. Systems that does not include this
 * file should emulate the structure for revision numbers that we have here.
 *
 * The version number of a dart build is constructed as follows:
 *   1. The major, minor, build and patch numbers are extracted from the VERSION
 *      file in the root directory. We call these MAJOR, MINOR, BUILD and PATCH.
 *   2. The svn revision number for the current checkout is extracted from the
 *      source control system that is used in the current checkout. We call this
 *      REVISION.
 *   3. If this is _not_ a official build, i.e., this is not build by our
 *      buildbot infrastructure, we extract the user-name of the logged in
 *      person from the operating system. We call this USERNAME.
 *   4. The version number is constructed as follows:
 *      MAJOR.MINOR.BUILD.PATCH_rREVISION_USERNAME
 */

library version;
import "dart:io";

/**
 * Generates version information for builds.
 */
class Version {
  String _versionFileName;
  String USERNAME;
  int REVISION;
  int MAJOR;
  int MINOR;
  int BUILD;
  int PATCH;

  Version(String this._versionFileName);

  /**
   * Get the version number for this specific build using the version info
   * from the VERSION file in the root directory and the revision info
   * from the source control system of the current checkout.
   */
  Future<String> getVersion() {
    File f = new File(_versionFileName);
    Completer c = new Completer();
    f.exists().then((existed) {
      if (!existed) {
        c.completeException("No VERSION file");
        return;
      }
      StringInputStream input = new StringInputStream(f.openInputStream());
      input.onLine = () {
        var line = input.readLine();
        if (line == null) {
          c.completeException(
              "VERSION input file seems to be in the wrong format");
          return;
        }
        var values = line.split(" ");
        if (values.length != 2) {
          c.completeException(
              "VERSION input file seems to be in the wrong format");
          return;
        }
        var number = 0;
        try {
          number = int.parse(values[1]);
        } catch (e) {
          c.completeException("Can't parse version numbers, not an int");
          return;
        }
        switch (values[0]) {
          case "MAJOR":
            MAJOR = number;
            break;
          case "MINOR":
            MINOR = number;
            break;
          case "BUILD":
            BUILD = number;
            break;
          case "PATCH":
            PATCH = number;
            break;
          default:
            c.completeException("Wrong format in VERSION file, line does not "
                                "contain one of {MAJOR, MINOR, BUILD, PATCH}");
            return;
        }
      };
      input.onClosed = () {
        // Only complete if we did not already complete with a failure.
        if (!c.future.isComplete) {
          getRevision().then((revision) {
            REVISION = revision;
            USERNAME = getUserName();
            var userNameString = "";
            if (USERNAME != '') userNameString = "_$USERNAME";
            var revisionString = "";
            if (revision != 0) revisionString = "_r$revision";
            c.complete(
                "$MAJOR.$MINOR.$BUILD.$PATCH$revisionString$userNameString");
            return;
          });
        }
      };
    });
    return c.future;
  }

  String getExecutableSuffix() {
    if (Platform.operatingSystem == 'windows') {
      return '.bat';
    }
    return '';
  }

  Future<int> getRevision() {
    if (repositoryType == RepositoryType.UNKNOWN) {
      return new Future.immediate(0);
    }
    var isSvn = repositoryType == RepositoryType.SVN;
    var command = isSvn ? "svn" : "git";
    command = "$command${getExecutableSuffix()}";
    var arguments = isSvn ? ["info"] : ["svn", "info"];
    return Process.run(command, arguments).transform((result) {
      if (result.exitCode != 0) {
        return 0;
      }
      // If anything goes wrong parsing the revision we simply return 0.
      try {
        // Extract the revision. It's located at the 8th line,
        // 18 characters in.
        String revisionString = result.stdout.split("\n")[8].substring(18);
        return int.parse(revisionString);
      } catch (e) {
        return 0;
      }
    });
  }

  String getUserName() {
    // TODO(ricow): Don't add this on the buildbot.
    var key = "USER";
    if (Platform.operatingSystem == 'windows') {
      key = "USERNAME";
    }
    if (!Platform.environment.containsKey(key)) return "";
    return Platform.environment[key];
  }

  RepositoryType get repositoryType {
    if (new Directory(".svn").existsSync()) return RepositoryType.SVN;
    if (new Directory(".git").existsSync()) return RepositoryType.GIT;
    return RepositoryType.UNKNOWN;
  }
}

class RepositoryType {
  static final RepositoryType SVN = const RepositoryType("SVN");
  static final RepositoryType GIT = const RepositoryType("GIT");
  static final RepositoryType UNKNOWN = const RepositoryType("UNKNOWN");

  const RepositoryType(String this.name);

  static RepositoryType guessType() {
    if (new Directory(".svn").existsSync()) return RepositoryType.SVN;
    if (new Directory(".git").existsSync()) return RepositoryType.GIT;
    return RepositoryType.UNKNOWN;
  }

  String toString() => name;

  final String name;
}
