// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:source_span/source_span.dart';

import 'manifest_values.dart';
import 'manifest_warning_code.dart';

class ManifestValidator {
  /**
   * The source representing the file being validated.
   */
  final Source source;

  /**
   * Initialize a newly create validator to validate the content of the given
   * [source].
   */
  ManifestValidator(this.source);

  /*
   * Validate the [contents] of the Android Manifest file.
   */
  List<AnalysisError> validate(String contents, bool checkManifest) {
    RecordingErrorListener recorder = new RecordingErrorListener();
    ErrorReporter reporter = new ErrorReporter(recorder, source);

    if (checkManifest) {
      var document =
          parseFragment(contents, container: MANIFEST_TAG, generateSpans: true);
      var manifest = document.children.firstWhere(
          (element) => element.localName == MANIFEST_TAG,
          orElse: () => null);
      var features = manifest?.getElementsByTagName(USES_FEATURE_TAG) ?? [];
      var permissions =
          manifest?.getElementsByTagName(USES_PERMISSION_TAG) ?? [];
      var activities = _findActivityElements(manifest);

      _validateTouchScreenFeature(features, manifest, reporter);
      _validateFeatures(features, reporter);
      _validatePermissions(permissions, features, reporter);
      _validateActivities(activities, reporter);
    }
    return recorder.errors;
  }

  /*
   * Validate the presence/absence of the touchscreen feature tag.
   */
  _validateTouchScreenFeature(
      List<Element> features, Element manifest, ErrorReporter reporter) {
    var feature = features.firstWhere(
        (element) =>
            element.attributes[ANDROID_NAME] == HARDWARE_FEATURE_TOUCHSCREEN,
        orElse: () => null);
    if (feature != null) {
      if (!feature.attributes.containsKey(ANDROID_REQUIRED)) {
        _reportErrorForNode(reporter, feature, ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE);
      } else if (feature.attributes[ANDROID_REQUIRED] == 'true') {
        _reportErrorForNode(reporter, feature, ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_FEATURE);
      }
    } else {
      _reportErrorForNode(
          reporter, manifest, null, ManifestWarningCode.NO_TOUCHSCREEN_FEATURE);
    }
  }

  /*
   * Validate the `uses-feature` tags.
   */
  _validateFeatures(List<Element> features, ErrorReporter reporter) {
    var unsupported = features
        .where((element) => UNSUPPORTED_HARDWARE_FEATURES
            .contains(element.attributes[ANDROID_NAME]))
        .toList();
    unsupported.forEach((element) {
      if (!element.attributes.containsKey(ANDROID_REQUIRED)) {
        _reportErrorForNode(reporter, element, ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE);
      } else if (element.attributes[ANDROID_REQUIRED] == 'true') {
        _reportErrorForNode(reporter, element, ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_FEATURE);
      }
    });
  }

  /*
   * Validate the `uses-permission` tags.
   */
  _validatePermissions(List<Element> permissions, List<Element> features,
      ErrorReporter reporter) {
    permissions.forEach((permission) {
      if (permission.attributes[ANDROID_NAME] == ANDROID_PERMISSION_CAMERA) {
        if (!_hasFeatureCamera(features) ||
            !_hasFeatureCameraAutoFocus(features)) {
          _reportErrorForNode(reporter, permission, ANDROID_NAME,
              ManifestWarningCode.CAMERA_PERMISSIONS_INCOMPATIBLE);
        }
      } else {
        var featureName =
            getImpliedUnsupportedHardware(permission.attributes[ANDROID_NAME]);
        if (featureName != null) {
          _reportErrorForNode(
              reporter,
              permission,
              ANDROID_NAME,
              ManifestWarningCode.PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE,
              [featureName]);
        }
      }
    });
  }

  /*
   * Validate the 'activity' tags.
   */
  _validateActivities(List<Element> activites, ErrorReporter reporter) {
    activites.forEach((activity) {
      var attributes = activity.attributes;
      if (attributes.containsKey(ATTRIBUTE_SCREEN_ORIENTATION)) {
        if (UNSUPPORTED_ORIENTATIONS
            .contains(attributes[ATTRIBUTE_SCREEN_ORIENTATION])) {
          _reportErrorForNode(reporter, activity, ATTRIBUTE_SCREEN_ORIENTATION,
              ManifestWarningCode.SETTING_ORIENTATION_ON_ACTIVITY);
        }
      }
      if (attributes.containsKey(ATTRIBUTE_RESIZEABLE_ACTIVITY)) {
        if (attributes[ATTRIBUTE_RESIZEABLE_ACTIVITY] == 'false') {
          _reportErrorForNode(reporter, activity, ATTRIBUTE_RESIZEABLE_ACTIVITY,
              ManifestWarningCode.NON_RESIZABLE_ACTIVITY);
        }
      }
    });
  }

  List<Element> _findActivityElements(Element manifest) {
    var applications = manifest?.getElementsByTagName(APPLICATION_TAG);
    var applicationElement = (applications != null && applications.isNotEmpty)
        ? applications.first
        : null;
    var activities =
        applicationElement?.getElementsByTagName(ACTIVITY_TAG) ?? [];
    return activities;
  }

  bool _hasFeatureCamera(List<Element> features) =>
      features.any((f) => f.localName == HARDWARE_FEATURE_CAMERA);

  bool _hasFeatureCameraAutoFocus(List<Element> features) =>
      features.any((f) => f.localName == HARDWARE_FEATURE_CAMERA_AUTOFOCUS);

  /**
   * Report an error for the given node.
   */
  void _reportErrorForNode(
      ErrorReporter reporter, Node node, dynamic key, ErrorCode errorCode,
      [List<Object> arguments]) {
    FileSpan span =
        key == null ? node.sourceSpan : node.attributeValueSpans[key];
    reporter.reportErrorForOffset(
        errorCode, span.start.offset, span.length, arguments);
  }
}
