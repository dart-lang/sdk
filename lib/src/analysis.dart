// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis;

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' show Folder;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:linter/src/io.dart';

AnalysisOptions _buildAnalyzerOptions(DriverOptions options) {
  AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
  analysisOptions.cacheSize = options.cacheSize;
  analysisOptions.hint = false;
  analysisOptions.lint = options.enableLints;
  analysisOptions.generateSdkErrors = options.showSdkWarnings;
  return analysisOptions;
}

class AnalysisDriver {
  final DriverOptions options;
  AnalysisDriver(this.options);

  List<UriResolver> get resolvers {
    DartSdk sdk = new DirectoryBasedDartSdk(new JavaFile(sdkDir));
    List<UriResolver> resolvers = [
      new DartUriResolver(sdk),
      new FileUriResolver()
    ];
    if (options.packageRootPath != null) {
      JavaFile packageDirectory = new JavaFile(options.packageRootPath);
      resolvers.add(new PackageUriResolver([packageDirectory]));
    } else {
      PubPackageMapProvider pubPackageMapProvider =
          new PubPackageMapProvider(PhysicalResourceProvider.INSTANCE, sdk);
      PackageMapInfo packageMapInfo = pubPackageMapProvider.computePackageMap(
          PhysicalResourceProvider.INSTANCE.getResource('.'));
      Map<String, List<Folder>> packageMap = packageMapInfo.packageMap;
      if (packageMap != null) {
        resolvers.add(new PackageMapUriResolver(
            PhysicalResourceProvider.INSTANCE, packageMap));
      }
    }
    return resolvers;
  }

  String get sdkDir {
    if (options.dartSdkPath != null) {
      return options.dartSdkPath;
    }
    // In case no SDK has been specified, fall back to inferring it
    // TODO: pass args to cli_util
    return cli_util.getSdkDir().path;
  }

  List<AnalysisErrorInfo> analyze(Iterable<File> files) {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions = _buildAnalyzerOptions(options);
    context.sourceFactory = new SourceFactory(resolvers);
    AnalysisEngine.instance.logger = new _Logger();

    List<Source> sources = [];
    ChangeSet changeSet = new ChangeSet();
    for (File file in files) {
      JavaFile sourceFile = new JavaFile(file.path);
      Source source = new FileBasedSource.con2(sourceFile.toURI(), sourceFile);
      sources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);

    List<AnalysisErrorInfo> errors = [];

    for (Source source in sources) {
      context.computeErrors(source);
      errors.add(context.getErrors(source));
    }

    return errors;
  }
}

class DriverOptions {

  /// The maximum number of sources for which AST structures should be kept
  /// in the cache.  The default is 512.
  int cacheSize = 512;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// Whether to show lint warnings.
  bool enableLints = true;

  /// The path to the package root.
  String packageRootPath;

  /// Whether to show SDK warnings.
  bool showSdkWarnings = false;
}

class _Logger extends Logger {
  void logError(String message, [exception]) => std_err.writeln(message);
  void logError2(String message, dynamic exception) => std_err.writeln(message);
  void logInformation(String message, [exception]) {}
  void logInformation2(String message, dynamic exception) {}
}
