// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

/// Wrapper class for some static utilities.
class GenUtil {
  // Picks a top directory (command line, environment, or current).
  static String getTop(String? top) {
    if (top == null || top == '') {
      top = Platform.environment['DART_TOP'];
    }
    if (top == null || top == '') {
      top = Directory.current.path;
    }
    return top;
  }

  // Create an analyzer session.
  static AnalysisSession createAnalysisSession([String? dart_top]) {
    // Set paths. Note that for this particular use case, packageRoot can be
    // any directory. Here, we set it to the top of the SDK development, and
    // derive the required sdkPath from there.
    final packageRoot = getTop(dart_top);
    final sdkPath = '$packageRoot/sdk';

    // This does most of the hard work of getting the analyzer configured
    // correctly. Typically the included paths are the files and directories
    // that need to be analyzed, but the SDK is always available, so it isn't
    // really important for this particular use case. We use the implementation
    // class in order to pass in the sdkPath directly.
    final provider = PhysicalResourceProvider.INSTANCE;
    final collection = AnalysisContextCollectionImpl(
        includedPaths: <String>[packageRoot],
        excludedPaths: <String>[packageRoot + '/pkg/front_end/test'],
        resourceProvider: provider,
        sdkPath: sdkPath);
    return collection.contexts[0].currentSession;
  }
}

extension DartTypeExtension on DartType {
  /// Returns an approximation of the [DartType] code, suitable for this tool.
  String get asCode {
    final type = this;
    if (type is DynamicType) {
      return 'dynamic';
    } else if (type is FunctionType) {
      final parameters = type.parameters.map((e) => e.type.asCode);
      return type.returnType.asCode + ' Function($parameters)';
    } else if (type is InterfaceType) {
      final typeArguments = type.typeArguments;
      if (typeArguments.isEmpty ||
          typeArguments.every((t) => t is DynamicType)) {
        return type.element.name;
      } else {
        final typeArgumentsStr = typeArguments.map((t) => t.asCode).join(', ');
        return '${type.element.name}<$typeArgumentsStr>';
      }
    } else if (type is NeverType) {
      return 'Never';
    } else if (type is TypeParameterType) {
      return type.element.name;
    } else if (type is VoidType) {
      return 'void';
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }
}
