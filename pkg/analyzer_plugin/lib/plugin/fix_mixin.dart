// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// A mixin that can be used when creating a subclass of [ServerPlugin] and
/// mixing in [FixesMixin]. This implements the creation of the fixes request
/// based on the assumption that the driver being created is an [AnalysisDriver].
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin] that also uses [FixesMixin] as a
/// mix-in.
mixin DartFixesMixin implements FixesMixin {
  @override
  Future<FixesRequest> getFixesRequest(EditGetFixesParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var offset = parameters.offset;
    var result = await getResolvedUnitResult(path);
    return DartFixesRequestImpl(
        resourceProvider, offset, _getErrors(offset, result), result);
  }

  List<AnalysisError> _getErrors(int offset, ResolvedUnitResult result) {
    var lineInfo = result.lineInfo;
    var offsetLine = lineInfo.getLocation(offset).lineNumber;
    return result.errors.where((AnalysisError error) {
      var errorLine = lineInfo.getLocation(error.offset).lineNumber;
      return errorLine == offsetLine;
    }).toList();
  }
}

/// A mixin that can be used when creating a subclass of [ServerPlugin] to
/// provide most of the implementation for handling fix requests.
///
/// Clients may not implement this mixin, but are allowed to use it as a mix-in
/// when creating a subclass of [ServerPlugin].
mixin FixesMixin implements ServerPlugin {
  /// Return a list containing the fix contributors that should be used to create
  /// fixes for the file with the given [path].
  List<FixContributor> getFixContributors(String path);

  /// Return the fixes request that should be passes to the contributors
  /// returned from [getFixContributors].
  ///
  /// Throw a [RequestFailure] if the request could not be created.
  Future<FixesRequest> getFixesRequest(EditGetFixesParams parameters);

  @override
  Future<EditGetFixesResult> handleEditGetFixes(
      EditGetFixesParams parameters) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var path = parameters.file;
    var request = await getFixesRequest(parameters);
    var generator = FixGenerator(getFixContributors(path));
    var result = generator.generateFixesResponse(request);
    result.sendNotifications(channel);
    return result.result;
  }
}
