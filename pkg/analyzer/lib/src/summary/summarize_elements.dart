// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.elements;

import 'dart:convert';

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:front_end/src/base/api_signature.dart';

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
  static const int currentMinorVersion = 0;

  final List<String> _linkedLibraryUris = <String>[];
  final List<LinkedLibraryBuilder> _linkedLibraries = <LinkedLibraryBuilder>[];
  final List<String> _unlinkedUnitUris = <String>[];
  final List<UnlinkedUnitBuilder> _unlinkedUnits = <UnlinkedUnitBuilder>[];
  final Map<String, UnlinkedUnitBuilder> _unlinkedUnitMap =
      <String, UnlinkedUnitBuilder>{};
  final List<String> _unlinkedUnitHashes;
  final bool _excludeHashes;

  /**
   * Create a [PackageBundleAssembler].  If [excludeHashes] is `true`, hash
   * computation will be skipped.
   */
  PackageBundleAssembler({bool excludeHashes: false})
      : _excludeHashes = excludeHashes,
        _unlinkedUnitHashes = excludeHashes ? null : <String>[];

  void addLinkedLibrary(String uri, LinkedLibraryBuilder library) {
    _linkedLibraries.add(library);
    _linkedLibraryUris.add(uri);
  }

  void addUnlinkedUnit(Source source, UnlinkedUnitBuilder unit) {
    addUnlinkedUnitWithHash(source.uri.toString(), unit,
        _excludeHashes ? null : _hash(source.contents.data));
  }

  void addUnlinkedUnitWithHash(
      String uri, UnlinkedUnitBuilder unit, String hash) {
    _unlinkedUnitUris.add(uri);
    _unlinkedUnits.add(unit);
    _unlinkedUnitMap[uri] = unit;
    _unlinkedUnitHashes?.add(hash);
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
        unlinkedUnitHashes: _unlinkedUnitHashes,
        majorVersion: currentMajorVersion,
        minorVersion: currentMinorVersion,
        apiSignature: _computeApiSignature());
  }

  /**
   * Compute the API signature for this package bundle.
   */
  String _computeApiSignature() {
    ApiSignature apiSignature = new ApiSignature();
    for (String unitUri in _unlinkedUnitMap.keys.toList()..sort()) {
      apiSignature.addString(unitUri);
      _unlinkedUnitMap[unitUri].collectApiSignature(apiSignature);
    }
    return apiSignature.toHex();
  }

  /**
   * Compute a hash of the given file contents.
   */
  String _hash(String contents) {
    return hex.encode(md5.convert(utf8.encode(contents)).bytes);
  }
}
