// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Object that gathers information uses it to assemble a new
 * [PackageBundleBuilder].
 */
class PackageBundleAssembler {
  /**
   * Value that will be stored in [PackageBundle.majorVersion] for any summaries
   * created by this code.  When making a breaking change to the summary format,
   * this value should be incremented by 1 and [currentMinorVersion] should be
   * reset to zero.
   */
  static const int currentMajorVersion = 1;

  /**
   * Value that will be stored in [PackageBundle.minorVersion] for any summaries
   * created by this code.  When making a non-breaking change to the summary
   * format that clients might need to be aware of (such as adding a kind of
   * data that was previously not summarized), this value should be incremented
   * by 1.
   */
  static const int currentMinorVersion = 1;

  final List<String> _linkedLibraryUris = <String>[];
  final List<LinkedLibraryBuilder> _linkedLibraries = <LinkedLibraryBuilder>[];
  final List<String> _unlinkedUnitUris = <String>[];
  final List<UnlinkedUnitBuilder> _unlinkedUnits = <UnlinkedUnitBuilder>[];
  final Map<String, UnlinkedUnitBuilder> _unlinkedUnitMap =
      <String, UnlinkedUnitBuilder>{};

  void addLinkedLibrary(String uri, LinkedLibraryBuilder library) {
    _linkedLibraries.add(library);
    _linkedLibraryUris.add(uri);
  }

  void addUnlinkedUnit(Source source, UnlinkedUnitBuilder unit) {
    addUnlinkedUnitViaUri(source.uri.toString(), unit);
  }

  void addUnlinkedUnitViaUri(String uri, UnlinkedUnitBuilder unit) {
    _unlinkedUnitUris.add(uri);
    _unlinkedUnits.add(unit);
    _unlinkedUnitMap[uri] = unit;
  }

  /**
   * Assemble a new [PackageBundleBuilder] using the gathered information.
   */
  PackageBundleBuilder assemble() {
    return new PackageBundleBuilder(
        linkedLibraryUris: _linkedLibraryUris,
        linkedLibraries: _linkedLibraries,
        unlinkedUnitUris: _unlinkedUnitUris,
        unlinkedUnits: _unlinkedUnits,
        majorVersion: currentMajorVersion,
        minorVersion: currentMinorVersion);
  }
}
