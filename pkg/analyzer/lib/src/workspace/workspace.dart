// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/workspace/bazel.dart';

/// Abstract superclass of classes that provide information about the workspace
/// in which analysis is being performed.
abstract class Workspace {
  /// Return true iff this [Workspace] is a [BazelWorkspace].
  bool get isBazel => false;

  /// The [UriResolver] that can resolve `package` URIs.
  UriResolver get packageUriResolver;

  /// The absolute workspace root path.
  String get root;

  /// Create the source factory that should be used to resolve Uris to
  /// [Source]s. The [sdk] may be `null`. The [summaryData] can also be `null`.
  SourceFactory createSourceFactory(DartSdk sdk, SummaryDataStore summaryData);

  /// Find the [WorkspacePackage] where the library at [path] is defined.
  ///
  /// Separate from [Packages] or [packageMap], this method is designed to find
  /// the package, by its root, in which a library at an arbitrary path is
  /// defined.
  WorkspacePackage findPackageFor(String path);
}

/// Abstract superclass of classes that provide information about a package
/// defined in a Workspace.
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a Workspace.
abstract class WorkspacePackage {
  String get root;

  Workspace get workspace;

  bool contains(Source source);

  /// Return a file path for the location of [source].
  ///
  /// If [source]'s URI scheme is package, it's fullName might be unusable (for
  /// example, the case of a [InSummarySource]). In this case, use
  /// [workspace]'s package URI resolver to fetch the file path.
  String filePathFromSource(Source source) {
    if (source.uri.scheme == 'package') {
      return workspace.packageUriResolver.resolveAbsolute(source.uri)?.fullName;
    } else {
      return source.fullName;
    }
  }
}

/// An interface for a workspace that contains a default analysis options file.
/// Classes that provide information of such a workspace should implement this
/// interface.
class WorkspaceWithDefaultAnalysisOptions {
  /// The uri for the default analysis options file.
  static const String uri = 'package:dart.analysis_options/default.yaml';

  ///  The uri for third_party analysis options file.
  static const String thirdPartyUri =
      'package:dart.analysis_options/third_party.yaml';
}
