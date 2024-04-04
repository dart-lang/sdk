// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Service name for the DTD-hosted file system service.
const String kFileSystemServiceName = 'FileSystem';

/// The default value for the `depth` parameter in the
/// `DartToolingDaemon.getProjectRoots` API.
///
/// This represents the maximum depth of the directory tree that will be
/// searched for project roots. This is a performance optimization in case
/// the workspace roots being searched are large directories; for example, if
/// a user opened their home directory in their IDE.
const int defaultGetProjectRootsDepth = 4;

/// Service name for the DTD-hosted unified analytics service.
const String kUnifiedAnalyticsServiceName = 'UnifiedAnalytics';
