// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.event;

import 'package:source_span/source_span.dart';

import 'style.dart';
import 'yaml_document.dart';

/// An event emitted by a [Parser].
class Event {
  /// The event type.
  final EventType type;

  /// The span associated with the event.
  final FileSpan span;

  Event(this.type, this.span);

  String toString() => type.toString();
}

/// An event indicating the beginning of a YAML document.
class DocumentStartEvent implements Event {
  get type => EventType.DOCUMENT_START;
  final FileSpan span;

  /// The document's `%YAML` directive, or `null` if there was none.
  final VersionDirective versionDirective;

  /// The document's `%TAG` directives, if any.
  final List<TagDirective> tagDirectives;

  /// Whether the document started implicitly (that is, without an explicit
  /// `===` sequence).
  final bool isImplicit;

  DocumentStartEvent(this.span, {this.versionDirective,
          List<TagDirective> tagDirectives, this.isImplicit: true})
      : tagDirectives = tagDirectives == null ? [] : tagDirectives;

  String toString() => "DOCUMENT_START";
}

/// An event indicating the end of a YAML document.
class DocumentEndEvent implements Event {
  get type => EventType.DOCUMENT_END;
  final FileSpan span;

  /// Whether the document ended implicitly (that is, without an explicit
  /// `...` sequence).
  final bool isImplicit;

  DocumentEndEvent(this.span, {this.isImplicit: true});

  String toString() => "DOCUMENT_END";
}

/// An event indicating that an alias was referenced.
class AliasEvent implements Event {
  get type => EventType.ALIAS;
  final FileSpan span;

  /// The name of the anchor.
  final String name;

  AliasEvent(this.span, this.name);

  String toString() => "ALIAS $name";
}

/// A base class for events that can have anchor and tag properties associated
/// with them.
abstract class _ValueEvent implements Event {
  /// The name of the value's anchor, or `null` if it wasn't anchored.
  String get anchor;

  /// The text of the value's tag, or `null` if it wasn't tagged.
  String get tag;

  String toString() {
    var buffer = new StringBuffer('$type');
    if (anchor != null) buffer.write(" &$anchor");
    if (tag != null) buffer.write(" $tag");
    return buffer.toString();
  }
}

/// An event indicating a single scalar value.
class ScalarEvent extends _ValueEvent {
  get type => EventType.SCALAR;
  final FileSpan span;
  final String anchor;
  final String tag;

  /// The contents of the scalar.
  final String value;

  /// The style of the scalar in the original source.
  final ScalarStyle style;

  ScalarEvent(this.span, this.value, this.style, {this.anchor, this.tag});

  String toString() => "${super.toString()} \"$value\"";
}

/// An event indicating the beginning of a sequence.
class SequenceStartEvent extends _ValueEvent {
  get type => EventType.SEQUENCE_START;
  final FileSpan span;
  final String anchor;
  final String tag;

  /// The style of the collection in the original source.
  final CollectionStyle style;

  SequenceStartEvent(this.span, this.style, {this.anchor, this.tag});
}

/// An event indicating the beginning of a mapping.
class MappingStartEvent extends _ValueEvent {
  get type => EventType.MAPPING_START;
  final FileSpan span;
  final String anchor;
  final String tag;

  /// The style of the collection in the original source.
  final CollectionStyle style;

  MappingStartEvent(this.span, this.style, {this.anchor, this.tag});
}

/// An enum of types of [Event] object.
class EventType {
  static const STREAM_START = const EventType._("STREAM_START");
  static const STREAM_END = const EventType._("STREAM_END");

  static const DOCUMENT_START = const EventType._("DOCUMENT_START");
  static const DOCUMENT_END = const EventType._("DOCUMENT_END");

  static const ALIAS = const EventType._("ALIAS");
  static const SCALAR = const EventType._("SCALAR");

  static const SEQUENCE_START = const EventType._("SEQUENCE_START");
  static const SEQUENCE_END = const EventType._("SEQUENCE_END");

  static const MAPPING_START = const EventType._("MAPPING_START");
  static const MAPPING_END = const EventType._("MAPPING_END");

  final String name;

  const EventType._(this.name);

  String toString() => name;
}
