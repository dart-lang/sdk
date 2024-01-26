// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';

/// Helper class for continuously loading kernel dill files that consists of
/// sub components as when serialized via the incremental serializer.
///
/// For instance the frontend-server serializes with the incremental serializer
/// which works by outputting previously serialized component bytes, i.e. a
/// single dill actually contains several components, and many of these
/// components will byte-for-byte be the same between compiles.
///
/// This helper class will do checksums of the bytes of each sub component (and
/// byte-for-byte check on match), to avoid loading previously loaded data.
///
/// In some cases we might even have access to identical data between loads
/// which allows us to skip creating a checksum and comparing bytes, but instead
/// rely on the identity of the list.
class MultiBinaryLoader {
  /// Map from the adler32 checksum to the (possibly multiple) previously loaded
  /// data.
  final Map<int, List<_LoadedData>> _adlerToData = {};

  /// Identity-map from the original list to the loaded equivalent.
  final Map<Uint8List, _LoadedData> _identityHashToData = new Map.identity();

  /// The canonical name root *everything* is loaded in to.
  final CanonicalName _canonicalNameRoot = new CanonicalName.root();

  /// Check if the bytes match, i.e. if the bytes in [data] from [from] to [to]
  /// matches the bytes in the [candidate].
  bool _checkCandidate(
      Uint8List data, int from, int to, _LoadedData candidate) {
    int length = to - from;
    if (length != candidate.data.length) return false;
    for (int i = 0, j = from; i < length; i++, j++) {
      if (data[j] != candidate.data[i]) {
        return false;
      }
    }
    return true;
  }

  /// Load the data provided in [allData] into a component.
  ///
  /// [allData] is a list to allow loading several chunks, e.g. loading the
  /// platform together with a serialized component without the platform.
  /// [alternativeData] can optionally give an alternative version of some data
  /// range. This would possibly allow for skipping the creation of a checksum.
  Component load(List<Uint8List> allData,
      Uint8List? Function(Uint8List data, int from, int to)? alternativeData) {
    List<_LoadedData> subComponents = [];

    for (Uint8List orgData in allData) {
      for (SubComponentView subView in BinaryBuilder.index(orgData)) {
        int from = subView.componentStartOffset;
        int to = subView.componentStartOffset + subView.componentFileSize;
        if (from == 0 && to == orgData.length) {
          _LoadedData? found = _identityHashToData[orgData];
          if (found != null) {
            subComponents.add(found);
            continue;
          }
        }
        Uint8List data = orgData;
        if (alternativeData != null) {
          Uint8List? alternative = alternativeData(data, from, to);
          if (alternative != null) {
            data = alternative;
            from = 0;
            to = alternative.length;
            _LoadedData? found = _identityHashToData[alternative];
            if (found != null) {
              subComponents.add(found);
              continue;
            }
          }
        }

        _LoadedData? found;
        final int checksum = _adler32(data, from, to);
        final List<_LoadedData> lookup = _adlerToData[checksum] ??= [];
        for (_LoadedData candidate in lookup) {
          // Checksum matches --- check the actual bytes.
          if (_checkCandidate(data, from, to, candidate)) {
            found = candidate;
            break;
          }
        }

        if (found == null) {
          // Load and add.
          // The subData is a view, so if we save that we'll make the while file
          // live in memory. We don't want that so we make a "physical" copy.
          Uint8List subData = new Uint8List(to - from);
          subData.setRange(0, subData.length, data, from);
          BinaryBuilder bb = new BinaryBuilder(subData,
              disableLazyReading: true,
              useGrowableLists: false,
              alwaysCreateNewNamedNodes: true);
          Component component = new Component(nameRoot: _canonicalNameRoot);
          bb.readComponent(component);

          List<CanonicalName> linkTable = bb.linkTable;
          found = new _LoadedData(subData, component, linkTable);
          lookup.add(found);
        }

        if (from == 0 && to == data.length) {
          _identityHashToData[data] = found;
        }

        // Add data to combined output.
        subComponents.add(found);
      }
    }

    // Create the combined component and link it up.
    Component result = new Component(nameRoot: _canonicalNameRoot);
    for (_LoadedData subComponent in subComponents) {
      // At first none of the canonical names (or, references really) in the
      // requested data should point to anything.
      for (CanonicalName canonicalName in subComponent.linkTable) {
        canonicalName.referenceOrNull?.node = null;
      }

      result.libraries.addAll(subComponent.component.libraries);
      // TODO: Set main method, combine sources etc.
    }

    // Then we relink everything, effectively making canonical names
    // (references) point to the right things iff it's in the data we was asked
    // to load.
    for (Library library in result.libraries) {
      library.parent = result;
      library.relink();
    }

    // We could check all the used canonical names if they're set.
    // TODO: Should this be optional?
    for (_LoadedData subComponent in subComponents) {
      for (CanonicalName canonicalName in subComponent.linkTable) {
        canonicalName.checkThisCanonicalName();
      }
    }

    return result;
  }
}

class _LoadedData {
  final Uint8List data;
  final Component component;
  final List<CanonicalName> linkTable;

  _LoadedData(this.data, this.component, this.linkTable);
}

/// Calculate the "Adler-32" checksum.
///
/// See https://en.wikipedia.org/wiki/Adler-32 for details.
int _adler32(Uint8List data, int from, int to) {
  int a = 1;
  int b = 0;
  for (int i = from; i < to; i++) {
    a += data[i];
    b += a;

    if (i & 255 == 255) {
      a %= 65521;
      b %= 65521;
    }
  }
  a %= 65521;
  b %= 65521;
  return (b << 16) | a;
}
