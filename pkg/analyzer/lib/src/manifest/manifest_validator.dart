// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import 'charcodes.dart';
import 'manifest_values.dart';
import 'manifest_warning_code.dart';

/// A rudimentary parser for Android Manifest files.
///
/// Android Manifest files are written in XML. In order to validate an Android
/// Manifest file, however, we do not need to parse or retain each element. This
/// parser understands which elements are relevant to manifest validation.
/// This parser does not validate the XML, and if it encounters an error while
/// parsing, no exception is thrown. Instead, a parse result with
/// [ParseResult.error] is returned.
///
/// This parser does not understand
///
/// * CDATA sections (https://www.w3.org/TR/xml/#sec-cdata-sect),
/// * element type declarations (https://www.w3.org/TR/xml/#elemdecls),
/// * attribute list declarations (https://www.w3.org/TR/xml/#attdecls),
/// * conditional sections (https://www.w3.org/TR/xml/#sec-condition-sect),
/// * entity declarations (https://www.w3.org/TR/xml/#sec-entity-decl),
/// * notation declarations (https://www.w3.org/TR/xml/#Notations).
///
/// This parser does not replace character or entity references
/// (https://www.w3.org/TR/xml/#sec-references).
class ManifestParser {
  /// Elements which are relevant to manifest validation.
  static const List<String> _relevantElements = [
    ACTIVITY_TAG,
    APPLICATION_TAG,
    MANIFEST_TAG,
    USES_FEATURE_TAG,
    USES_PERMISSION_TAG
  ];

  /// The text of the Android Manifest file.
  final String content;

  /// The source file representing the Android Manifest file, for source span
  /// purposes.
  final SourceFile sourceFile;

  /// The current offset in the source file.
  int _pos;

  ManifestParser(this.content, Uri uri)
      : sourceFile = SourceFile.fromString(content, url: uri),
        _pos = 0;

  /// Whether the current character is a tag-closing character (">").
  bool get _isClosing =>
      _pos < content.length && content.codeUnitAt(_pos) == $gt;

  /// Whether the current character and the following two characters make a
  /// comment closing ("-->").
  bool get _isCommentClosing =>
      _pos + 2 < content.length &&
      content.codeUnitAt(_pos) == $dash &&
      content.codeUnitAt(_pos + 1) == $dash &&
      content.codeUnitAt(_pos + 2) == $gt;

  /// Whether the following three characters make a comment opening ("<!--").
  bool get _isCommentOpening =>
      _pos + 3 < content.length &&
      content.codeUnitAt(_pos + 1) == $exclamation &&
      content.codeUnitAt(_pos + 2) == $dash &&
      content.codeUnitAt(_pos + 3) == $dash;

  /// Whether the following character makes a comment opening ("<!").
  bool get _isDeclarationOpening =>
      _pos + 1 < content.length && content.codeUnitAt(_pos + 1) == $exclamation;

  /// Whether the current character and the following character make a
  /// two-character closing.
  ///
  /// The "/>" and "?>" closings each represent an empty element.
  bool get _isTwoCharClosing =>
      _pos + 1 < content.length &&
      (content.codeUnitAt(_pos) == $question ||
          content.codeUnitAt(_pos) == $slash) &&
      content.codeUnitAt(_pos + 1) == $gt;

  bool get _isWhitespace {
    var char = content.codeUnitAt(_pos);
    return char == $space || char == $tab || char == $lf || char == $cr;
  }

  /// Parses an XML tag into a [ParseTagResult].
  ParseTagResult parseXmlTag() {
    // Walk until we find a tag.
    while (_pos < content.length && content.codeUnitAt(_pos) != $lt) {
      _pos++;
    }
    if (_pos >= content.length) {
      return ParseTagResult.eof;
    }
    if (_isCommentOpening) {
      return _parseComment();
    }
    if (_isDeclarationOpening) {
      return _parseDeclaration();
    }

    return _parseNormalTag();
  }

  /// Returns whether [name] represents an element that is relevant to manifest
  /// validation.
  bool _isRelevantElement(String name) => _relevantElements.contains(name);

  /// Parses any whitespace, returning `null` when non-whitespace is parsed.
  ParseResult _parseAnyWhitespace() {
    if (_pos >= content.length) {
      return ParseResult.error;
    }

    while (_isWhitespace) {
      _pos++;
      if (_pos >= content.length) {
        return ParseResult.error;
      }
    }
    return null;
  }

  /// Parses an attribute.
  ParseAttributeResult _parseAttribute(bool isRelevant) {
    var attributes = <String, _XmlAttribute>{};
    /*late*/ bool isEmptyElement;

    while (true) {
      if (_pos >= content.length) {
        return ParseAttributeResult.error;
      }
      var char = content.codeUnitAt(_pos);

      // In each loop, [_pos] must either be whitespace, ">", "/>", or "?>" to
      // be valid.
      if (_isClosing) {
        isEmptyElement = false;
        break;
      } else if (_isTwoCharClosing) {
        isEmptyElement = true;
        _pos++;
        break;
      } else if (!_isWhitespace) {
        return ParseAttributeResult.error;
      }

      var parsedWhitespaceResult = _parseAnyWhitespace();
      if (parsedWhitespaceResult == ParseResult.error) {
        return ParseAttributeResult.error;
      }

      if (_isClosing) {
        isEmptyElement = false;
        break;
      } else if (_isTwoCharClosing) {
        isEmptyElement = true;
        _pos++;
        break;
      }

      // Parse attribute name.
      var attributeNamePos = _pos;
      String attributeName;
      _pos++;
      if (_pos >= content.length) {
        return ParseAttributeResult.error;
      }

      while ((char = content.codeUnitAt(_pos)) != $equal) {
        if (_isWhitespace || _isClosing || _isTwoCharClosing) {
          // An attribute without a value, while allowed in HTML, is not allowed
          // in XML.
          return ParseAttributeResult.error;
        }
        _pos++;
        if (_pos >= content.length) {
          return ParseAttributeResult.error;
        }
      }

      if (isRelevant) {
        attributeName = content.substring(attributeNamePos, _pos).toLowerCase();
      }
      _pos++; // Walk past "=".
      if (_pos >= content.length) {
        return ParseAttributeResult.error;
      }

      // Parse attribute value.
      int quote;
      char = content.codeUnitAt(_pos);
      if (char == $apostrophe || char == $quote) {
        quote = char;
        _pos++;
      } else {
        // An attribute name, followed by "=", followed by ">" is an error.
        return ParseAttributeResult.error;
      }
      int attributeValuePos = _pos;

      while ((char = content.codeUnitAt(_pos)) != quote) {
        _pos++;
        if (_pos >= content.length) {
          return ParseAttributeResult.error;
        }
      }

      if (isRelevant) {
        var attributeValue = content.substring(attributeValuePos, _pos);
        var sourceSpan = sourceFile.span(attributeNamePos, _pos);
        attributes[attributeName] =
            _XmlAttribute(attributeName, attributeValue, sourceSpan);
      }
      _pos++;
    }

    var parseResult = isEmptyElement
        ? ParseResult.attributesWithEmptyElementClose
        : ParseResult.attributesWithTagClose;

    return ParseAttributeResult(parseResult, attributes);
  }

  /// Parses a comment tag, as per https://www.w3.org/TR/xml/#sec-comments.
  ParseTagResult _parseComment() {
    // Walk past "<!--"
    _pos += 4;
    if (_pos >= content.length) {
      return ParseTagResult.error;
    }
    while (!_isCommentClosing) {
      _pos++;
      if (_pos >= content.length) {
        return ParseTagResult.error;
      }
    }
    _pos += 2;

    return ParseTagResult(ParseResult.element, null);
  }

  /// Parses a general declaration.
  ///
  /// Declarations are not processed or stored. The parser just intends to read
  /// the tag and return.
  ParseTagResult _parseDeclaration() {
    // Walk past "<!"
    _pos += 2;
    if (_pos >= content.length) {
      return ParseTagResult.error;
    }
    while (!_isClosing) {
      _pos++;
      if (_pos >= content.length) {
        return ParseTagResult.error;
      }
    }

    return ParseTagResult(ParseResult.element, null);
  }

  /// Parses a normal tag starting with an '<' character at the current
  /// position.
  ParseTagResult _parseNormalTag() {
    var startPos = _pos;
    _pos++;

    if (_pos >= content.length) {
      return ParseTagResult.error;
    }

    if (_isWhitespace) {
      // A tag cannot begin with whitespace.
      return ParseTagResult.error;
    }

    var isEndTag = content.codeUnitAt(_pos) == $slash;
    if (isEndTag) _pos++;
    var tagClosingState = _TagClosingState.notClosed;

    // Parse name.
    var namePos = _pos;
    String name;

    while (!_isClosing && !_isTwoCharClosing && !_isWhitespace) {
      _pos++;
      if (_pos >= content.length) {
        return ParseTagResult.error;
      }
    }

    if (_isClosing) {
      // End of tag name, and tag.
      name = content.substring(namePos, _pos).toLowerCase();
      tagClosingState = _TagClosingState.closed;
    } else if (_isTwoCharClosing) {
      // End of tag name, tag, and element.
      name = content.substring(namePos, _pos).toLowerCase();
      tagClosingState = _TagClosingState.closedEmptyElement;
      _pos++;
    } else if (_isWhitespace) {
      // End of tag name.
      name = content.substring(namePos, _pos).toLowerCase();
    }

    if (isEndTag) {
      var parsedWhitespaceResult = _parseAnyWhitespace();
      if (parsedWhitespaceResult == ParseResult.error) {
        return ParseTagResult.error;
      }
      if (_isClosing) {
        // End tags cannot have attributes.
        return ParseTagResult(
            ParseResult.endTag, _XmlElement(name, {}, [], null));
      } else {
        return ParseTagResult.error;
      }
    }

    var isRelevant = _isRelevantElement(name);

    Map<String, _XmlAttribute> attributes;
    bool isEmptyElement;
    if (tagClosingState == _TagClosingState.notClosed) {
      // Have not parsed the tag close yet; parse attributes.
      var attributeResult = _parseAttribute(isRelevant);
      var parseResult = attributeResult.parseResult;
      if (parseResult == ParseResult.error) {
        return ParseTagResult.error;
      }
      attributes = attributeResult.attributes;
      isEmptyElement =
          parseResult == ParseResult.attributesWithEmptyElementClose;
    } else {
      attributes = {};
      isEmptyElement = tagClosingState == _TagClosingState.closedEmptyElement;
    }
    if (name.startsWith('!')) {
      // Declarations (generally beginning with '!', do not require end tags.
      isEmptyElement = true;
    }

    var children = <_XmlElement>[];
    if (!isEmptyElement) {
      ParseTagResult child;
      _pos++;
      // Parse any children, and end tag.
      while ((child = parseXmlTag()).parseResult != ParseResult.endTag) {
        if (child == ParseTagResult.eof || child == ParseTagResult.error) {
          return child;
        }
        if (child.element == null) {
          // Don't store an irrelevant element.
          continue;
        }
        children.add(child.element);
        _pos++;
      }
    }

    // Finished parsing start tag.
    if (isRelevant) {
      var sourceSpan = sourceFile.span(startPos, _pos);
      return ParseTagResult(ParseResult.relevantElement,
          _XmlElement(name, attributes, children, sourceSpan));
    } else {
      // Discard all parsed children. This requires the notion that all relevant
      // tags are direct children of other relevant tags.
      return ParseTagResult(ParseResult.element, null);
    }
  }
}

class ManifestValidator {
  /// The source representing the file being validated.
  final Source source;

  /// Initialize a newly create validator to validate the content of the given
  /// [source].
  ManifestValidator(this.source);

  /// Validate the [contents] of the Android Manifest file.
  List<AnalysisError> validate(String content, bool checkManifest) {
    // TODO(srawlins): Simplify [checkManifest] notion. Why call the method if
    //  the caller always knows whether it should just return empty?
    if (!checkManifest) return [];

    RecordingErrorListener recorder = RecordingErrorListener();
    ErrorReporter reporter = ErrorReporter(
      recorder,
      source,
      isNonNullableByDefault: false,
    );

    var xmlParser = ManifestParser(content, source.uri);

    _checkManifestTag(xmlParser, reporter);
    return recorder.errors;
  }

  void _checkManifestTag(ManifestParser parser, ErrorReporter reporter) {
    ParseTagResult parseTagResult;
    while (
        (parseTagResult = parser.parseXmlTag()).element?.name != MANIFEST_TAG) {
      if (parseTagResult == ParseTagResult.eof ||
          parseTagResult == ParseTagResult.error) {
        return;
      }
    }

    var manifestElement = parseTagResult.element;
    var features =
        manifestElement.children.where((e) => e.name == USES_FEATURE_TAG);
    var permissions =
        manifestElement.children.where((e) => e.name == USES_PERMISSION_TAG);
    _validateTouchScreenFeature(features, manifestElement, reporter);
    _validateFeatures(features, reporter);
    _validatePermissions(permissions, features, reporter);

    var application = manifestElement.children
        .firstWhere((e) => e.name == APPLICATION_TAG, orElse: () => null);
    if (application != null) {
      for (var activity
          in application.children.where((e) => e.name == ACTIVITY_TAG)) {
        _validateActivity(activity, reporter);
      }
    }
  }

  bool _hasFeatureCamera(Iterable<_XmlElement> features) => features
      .any((f) => f.attributes[ANDROID_NAME]?.value == HARDWARE_FEATURE_CAMERA);

  bool _hasFeatureCameraAutoFocus(Iterable<_XmlElement> features) =>
      features.any((f) =>
          f.attributes[ANDROID_NAME]?.value ==
          HARDWARE_FEATURE_CAMERA_AUTOFOCUS);

  /// Report an error for the given node.
  void _reportErrorForNode(
      ErrorReporter reporter, _XmlElement node, String key, ErrorCode errorCode,
      [List<Object> arguments]) {
    FileSpan span =
        key == null ? node.sourceSpan : node.attributes[key].sourceSpan;
    reporter.reportErrorForOffset(
        errorCode, span.start.offset, span.length, arguments);
  }

  /// Validate the 'activity' tags.
  void _validateActivity(_XmlElement activity, ErrorReporter reporter) {
    var attributes = activity.attributes;
    if (attributes.containsKey(ATTRIBUTE_SCREEN_ORIENTATION)) {
      if (UNSUPPORTED_ORIENTATIONS
          .contains(attributes[ATTRIBUTE_SCREEN_ORIENTATION]?.value)) {
        _reportErrorForNode(reporter, activity, ATTRIBUTE_SCREEN_ORIENTATION,
            ManifestWarningCode.SETTING_ORIENTATION_ON_ACTIVITY);
      }
    }
    if (attributes.containsKey(ATTRIBUTE_RESIZEABLE_ACTIVITY)) {
      if (attributes[ATTRIBUTE_RESIZEABLE_ACTIVITY]?.value == 'false') {
        _reportErrorForNode(reporter, activity, ATTRIBUTE_RESIZEABLE_ACTIVITY,
            ManifestWarningCode.NON_RESIZABLE_ACTIVITY);
      }
    }
  }

  /// Validate the `uses-feature` tags.
  void _validateFeatures(
      Iterable<_XmlElement> features, ErrorReporter reporter) {
    var unsupported = features.where((element) => UNSUPPORTED_HARDWARE_FEATURES
        .contains(element.attributes[ANDROID_NAME]?.value));
    for (var element in unsupported) {
      if (!element.attributes.containsKey(ANDROID_REQUIRED)) {
        _reportErrorForNode(
            reporter,
            element,
            ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE,
            [element.attributes[ANDROID_NAME]?.value]);
      } else if (element.attributes[ANDROID_REQUIRED]?.value == 'true') {
        _reportErrorForNode(
            reporter,
            element,
            ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_FEATURE,
            [element.attributes[ANDROID_NAME]?.value]);
      }
    }
  }

  /// Validate the `uses-permission` tags.
  void _validatePermissions(Iterable<_XmlElement> permissions,
      Iterable<_XmlElement> features, ErrorReporter reporter) {
    for (var permission in permissions) {
      if (permission.attributes[ANDROID_NAME]?.value ==
          ANDROID_PERMISSION_CAMERA) {
        if (!_hasFeatureCamera(features) ||
            !_hasFeatureCameraAutoFocus(features)) {
          _reportErrorForNode(reporter, permission, ANDROID_NAME,
              ManifestWarningCode.CAMERA_PERMISSIONS_INCOMPATIBLE);
        }
      } else {
        var featureName = getImpliedUnsupportedHardware(
            permission.attributes[ANDROID_NAME]?.value);
        if (featureName != null) {
          _reportErrorForNode(
              reporter,
              permission,
              ANDROID_NAME,
              ManifestWarningCode.PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE,
              [featureName]);
        }
      }
    }
  }

  /// Validate the presence/absence of the touchscreen feature tag.
  void _validateTouchScreenFeature(Iterable<_XmlElement> features,
      _XmlElement manifest, ErrorReporter reporter) {
    var feature = features.firstWhere(
        (element) =>
            element.attributes[ANDROID_NAME]?.value ==
            HARDWARE_FEATURE_TOUCHSCREEN,
        orElse: () => null);
    if (feature != null) {
      if (!feature.attributes.containsKey(ANDROID_REQUIRED)) {
        _reportErrorForNode(
            reporter,
            feature,
            ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE,
            [HARDWARE_FEATURE_TOUCHSCREEN]);
      } else if (feature.attributes[ANDROID_REQUIRED]?.value == 'true') {
        _reportErrorForNode(
            reporter,
            feature,
            ANDROID_NAME,
            ManifestWarningCode.UNSUPPORTED_CHROME_OS_FEATURE,
            [HARDWARE_FEATURE_TOUCHSCREEN]);
      }
    } else {
      _reportErrorForNode(
          reporter, manifest, null, ManifestWarningCode.NO_TOUCHSCREEN_FEATURE);
    }
  }
}

@visibleForTesting
class ParseAttributeResult {
  static ParseAttributeResult error =
      ParseAttributeResult(ParseResult.error, null);

  final ParseResult parseResult;

  final Map<String, _XmlAttribute> attributes;

  ParseAttributeResult(this.parseResult, this.attributes);
}

enum ParseResult {
  // Attributes were parsed, followed by a tag close like "/>", signifying an
  // empty element, as per https://www.w3.org/TR/xml/#sec-starttags.
  attributesWithEmptyElementClose,
  // Attributes were parsed, followed by a tag close, ">".
  attributesWithTagClose,
  // A start tag for an irrelevant element was parsed, as per
  // https://www.w3.org/TR/xml/#sec-starttags.
  element,
  // An end tag for an element was parsed, as per
  // https://www.w3.org/TR/xml/#sec-starttags.
  endTag,
  // The content's EOF was parsed.
  eof,
  // An error was encountered.
  error,
  // A relevant element was parsed.
  relevantElement,
}

@visibleForTesting
class ParseTagResult {
  static ParseTagResult eof = ParseTagResult(ParseResult.eof, null);
  static ParseTagResult error = ParseTagResult(ParseResult.error, null);

  final ParseResult parseResult;

  final _XmlElement element;

  ParseTagResult(this.parseResult, this.element);
}

enum _TagClosingState {
  // Represents that the tag's close has not been parsed.
  notClosed,
  // Represents that the tag's close has been parsed as ">".
  closed,
  // Represents that the tag's close has been parsed as "/>", "?>", indicating
  // an empty element, as per https://www.w3.org/TR/xml/#sec-starttags.
  closedEmptyElement,
}

class _XmlAttribute {
  final String name;
  final String value;
  final SourceSpan sourceSpan;

  _XmlAttribute(this.name, this.value, this.sourceSpan);
}

class _XmlElement {
  final String name;
  final Map<String, _XmlAttribute> attributes;
  final List<_XmlElement> children;
  final SourceSpan sourceSpan;

  _XmlElement(this.name, this.attributes, this.children, this.sourceSpan);
}
