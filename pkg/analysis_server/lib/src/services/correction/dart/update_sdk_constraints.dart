// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class UpdateSdkConstraints extends CorrectionProducer {
  /// The minimum version to which the SDK constraints should be updated.
  final String _minimumVersion;

  /// Initialize a newly created instance that will update the SDK constraints
  /// to the [minimumVersion].
  UpdateSdkConstraints(this._minimumVersion);

  @override
  FixKind get fixKind => DartFixKind.UPDATE_SDK_CONSTRAINTS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var context = resourceProvider.pathContext;
    File pubspecFile;
    var folder = resourceProvider.getFolder(context.dirname(file));
    while (folder != null) {
      pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
      if (pubspecFile.exists) {
        break;
      }
      pubspecFile = null;
      folder = folder.parent;
    }
    if (pubspecFile == null) {
      return;
    }
    var extractor = SdkConstraintExtractor(pubspecFile);
    var text = extractor.constraintText();
    var offset = extractor.constraintOffset();
    if (text == null || offset < 0) {
      return;
    }
    var length = text.length;
    String newText;
    var spaceOffset = text.indexOf(' ');
    if (spaceOffset >= 0) {
      length = spaceOffset;
    }
    if (text == 'any') {
      newText = '^$_minimumVersion';
    } else if (text.startsWith('^')) {
      newText = '^$_minimumVersion';
    } else if (text.startsWith('>=')) {
      newText = '>=$_minimumVersion';
    } else if (text.startsWith('>')) {
      newText = '>=$_minimumVersion';
    }
    if (newText == null) {
      return;
    }
    await builder.addGenericFileEdit(pubspecFile.path, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newText);
    });
  }

  /// Return an instance of this class that will update the SDK constraints to
  /// '2.1.0'. Used as a tear-off in `FixProcessor`.
  static UpdateSdkConstraints version_2_1_0() => UpdateSdkConstraints('2.1.0');

  /// Return an instance of this class that will update the SDK constraints to
  /// '2.2.0'. Used as a tear-off in `FixProcessor`.
  static UpdateSdkConstraints version_2_2_0() => UpdateSdkConstraints('2.2.0');

  /// Return an instance of this class that will update the SDK constraints to
  /// '2.2.0'. Used as a tear-off in `FixProcessor`.
  static UpdateSdkConstraints version_2_2_2() => UpdateSdkConstraints('2.2.2');

  /// Return an instance of this class that will update the SDK constraints to
  /// '2.2.0'. Used as a tear-off in `FixProcessor`.
  static UpdateSdkConstraints version_2_6_0() => UpdateSdkConstraints('2.6.0');
}
