// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/analysis_target.dart';
import 'package:front_end/src/base/timestamped_data.dart';
import 'package:front_end/src/base/uri_kind.dart';
import 'package:path/path.dart' as pathos;

/// Base class providing implementations for the methods in [Source] that don't
/// require filesystem access.
abstract class BasicSource extends Source {
  final Uri uri;

  BasicSource(this.uri);

  @override
  String get encoding => uri.toString();

  @override
  String get fullName => encoding;

  @override
  int get hashCode => uri.hashCode;

  @override
  bool get isInSystemLibrary => uri.scheme == 'dart';

  @override
  String get shortName => pathos.basename(fullName);

  @override
  bool operator ==(Object object) => object is Source && object.uri == uri;
}

/**
 * The interface `Source` defines the behavior of objects representing source code that can be
 * analyzed by the analysis engine.
 *
 * Implementations of this interface need to be aware of some assumptions made by the analysis
 * engine concerning sources:
 * * Sources are not required to be unique. That is, there can be multiple instances representing
 * the same source.
 * * Sources are long lived. That is, the engine is allowed to hold on to a source for an extended
 * period of time and that source must continue to report accurate and up-to-date information.
 * Because of these assumptions, most implementations will not maintain any state but will delegate
 * to an authoritative system of record in order to implement this API. For example, a source that
 * represents files on disk would typically query the file system to determine the state of the
 * file.
 *
 * If the instances that implement this API are the system of record, then they will typically be
 * unique. In that case, sources that are created that represent non-existent files must also be
 * retained so that if those files are created at a later date the long-lived sources representing
 * those files will know that they now exist.
 */
abstract class Source implements AnalysisTarget {
  /**
   * An empty list of sources.
   */
  static const List<Source> EMPTY_LIST = const <Source>[];

  /**
   * Get the contents and timestamp of this source.
   *
   * Clients should consider using the method [AnalysisContext.getContents]
   * because contexts can have local overrides of the content of a source that the source is not
   * aware of.
   *
   * @return the contents and timestamp of the source
   * @throws Exception if the contents of this source could not be accessed
   */
  TimestampedData<String> get contents;

  /**
   * Return an encoded representation of this source that can be used to create a source that is
   * equal to this source.
   *
   * @return an encoded representation of this source
   * See [SourceFactory.fromEncoding].
   */
  String get encoding;

  /**
   * Return the full (long) version of the name that can be displayed to the user to denote this
   * source. For example, for a source representing a file this would typically be the absolute path
   * of the file.
   *
   * @return a name that can be displayed to the user to denote this source
   */
  String get fullName;

  /**
   * Return a hash code for this source.
   *
   * @return a hash code for this source
   * See [Object.hashCode].
   */
  @override
  int get hashCode;

  /**
   * Return `true` if this source is in one of the system libraries.
   *
   * @return `true` if this is in a system library
   */
  bool get isInSystemLibrary;

  @override
  Source get librarySource => null;

  /**
   * Return the modification stamp for this source, or a negative value if the
   * source does not exist. A modification stamp is a non-negative integer with
   * the property that if the contents of the source have not been modified
   * since the last time the modification stamp was accessed then the same value
   * will be returned, but if the contents of the source have been modified one
   * or more times (even if the net change is zero) the stamps will be different.
   *
   * Clients should consider using the method
   * [AnalysisContext.getModificationStamp] because contexts can have local
   * overrides of the content of a source that the source is not aware of.
   */
  int get modificationStamp;

  /**
   * Return a short version of the name that can be displayed to the user to denote this source. For
   * example, for a source representing a file this would typically be the name of the file.
   *
   * @return a name that can be displayed to the user to denote this source
   */
  String get shortName;

  @override
  Source get source => this;

  /**
   * Return the URI from which this source was originally derived.
   *
   * @return the URI from which this source was originally derived
   */
  Uri get uri;

  /**
   * Return the kind of URI from which this source was originally derived. If this source was
   * created from an absolute URI, then the returned kind will reflect the scheme of the absolute
   * URI. If it was created from a relative URI, then the returned kind will be the same as the kind
   * of the source against which the relative URI was resolved.
   *
   * @return the kind of URI from which this source was originally derived
   */
  UriKind get uriKind;

  /**
   * Return `true` if the given object is a source that represents the same source code as
   * this source.
   *
   * @param object the object to be compared with this object
   * @return `true` if the given object is a source that represents the same source code as
   *         this source
   * See [Object.==].
   */
  @override
  bool operator ==(Object object);

  /**
   * Return `true` if this source exists.
   *
   * Clients should consider using the method [AnalysisContext.exists] because
   * contexts can have local overrides of the content of a source that the source is not aware of
   * and a source with local content is considered to exist even if there is no file on disk.
   *
   * @return `true` if this source exists
   */
  bool exists();
}
