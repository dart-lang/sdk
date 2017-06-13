// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/flat_buffers.dart' as fb;

/// Unlinked information about a `show` or `hide` combinator in an import or
/// export directive.
abstract class UnlinkedCombinator {
  factory UnlinkedCombinator(List<int> bytes) {
    fb.BufferContext rootRef = new fb.BufferContext.fromBytes(bytes);
    return const _UnlinkedCombinatorReader().read(rootRef, 0);
  }

  /// List of names which are hidden.
  /// Empty if this is a `show` combinator.
  List<String> get hides;

  /// List of names which are shown.
  /// Empty if this is a `hide` combinator.
  List<String> get shows;
}

/// Builder of [UnlinkedCombinator]s.
class UnlinkedCombinatorBuilder {
  List<String> _shows;
  List<String> _hides;

  UnlinkedCombinatorBuilder({List<String> shows, List<String> hides})
      : _shows = shows,
        _hides = hides;

  void set hides(List<String> value) {
    this._hides = value;
  }

  void set shows(List<String> value) {
    this._shows = value;
  }

  /// Finish building, and store into the [fbBuilder].
  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_shows;
    fb.Offset offset_hides;
    if (!(_shows == null || _shows.isEmpty)) {
      offset_shows = fbBuilder
          .writeList(_shows.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_hides == null || _hides.isEmpty)) {
      offset_hides = fbBuilder
          .writeList(_hides.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_shows != null) {
      fbBuilder.addOffset(0, offset_shows);
    }
    if (offset_hides != null) {
      fbBuilder.addOffset(1, offset_hides);
    }
    return fbBuilder.endTable();
  }
}

/// Unlinked summary information about an import, export or part directive.
abstract class UnlinkedNamespaceDirective {
  factory UnlinkedNamespaceDirective(List<int> bytes) {
    fb.BufferContext rootRef = new fb.BufferContext.fromBytes(bytes);
    return const _UnlinkedNamespaceDirectiveReader().read(rootRef, 0);
  }

  /// Combinators contained in the directive.
  List<UnlinkedCombinator> get combinators;

  /// URI used in the directive.
  String get uri;
}

/// Builder of [UnlinkedNamespaceDirective]s.
class UnlinkedNamespaceDirectiveBuilder {
  String _uri;
  List<UnlinkedCombinatorBuilder> _combinators;

  UnlinkedNamespaceDirectiveBuilder(
      {String uri, List<UnlinkedCombinatorBuilder> combinators})
      : _uri = uri,
        _combinators = combinators;

  void set combinators(List<UnlinkedCombinatorBuilder> value) {
    this._combinators = value;
  }

  void set uri(String value) {
    this._uri = value;
  }

  /// Finish building, and store into the [fbBuilder].
  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_uri;
    fb.Offset offset_combinators;
    if (!(_uri == null || _uri.isEmpty)) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    if (!(_combinators == null || _combinators.isEmpty)) {
      offset_combinators = fbBuilder
          .writeList(_combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    fbBuilder.addOffset(0, offset_uri);
    fbBuilder.addOffset(1, offset_combinators);
    return fbBuilder.endTable();
  }
}

abstract class UnlinkedUnit {
  factory UnlinkedUnit(List<int> bytes) {
    fb.BufferContext rootRef = new fb.BufferContext.fromBytes(bytes);
    return const _UnlinkedUnitReader().read(rootRef, 0);
  }

  /// API signature of the unit.
  /// It depends on all non-comment tokens outside the block bodies.
  List<int> get apiSignature;

  /// Export directives in the compilation unit.
  List<UnlinkedNamespaceDirective> get exports;

  /// Import directives in the compilation unit.
  List<UnlinkedNamespaceDirective> get imports;

  /// Part directives in the compilation unit.
  List<UnlinkedNamespaceDirective> get parts;
}

/// Builder of [UnlinkedUnit]s.
class UnlinkedUnitBuilder {
  List<int> _apiSignature;
  List<UnlinkedNamespaceDirectiveBuilder> _imports;
  List<UnlinkedNamespaceDirectiveBuilder> _exports;
  List<UnlinkedNamespaceDirectiveBuilder> _parts;

  UnlinkedUnitBuilder(
      {List<int> apiSignature,
      List<UnlinkedNamespaceDirectiveBuilder> imports,
      List<UnlinkedNamespaceDirectiveBuilder> exports,
      List<UnlinkedNamespaceDirectiveBuilder> parts})
      : _apiSignature = apiSignature,
        _imports = imports,
        _exports = exports,
        _parts = parts;

  void set exports(List<UnlinkedNamespaceDirectiveBuilder> value) {
    this._exports = value;
  }

  void set imports(List<UnlinkedNamespaceDirectiveBuilder> value) {
    this._imports = value;
  }

  void set parts(List<UnlinkedNamespaceDirectiveBuilder> value) {
    this._parts = value;
  }

  /// Finish building, and store into the [fbBuilder].
  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_apiSignature;
    fb.Offset offset_imports;
    fb.Offset offset_exports;
    fb.Offset offset_parts;
    if (!(_apiSignature == null || _apiSignature.isEmpty)) {
      offset_apiSignature = fbBuilder.writeListUint8(_apiSignature);
    }
    if (!(_imports == null || _imports.isEmpty)) {
      offset_imports = fbBuilder
          .writeList(_imports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts =
          fbBuilder.writeList(_parts.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_apiSignature != null) {
      fbBuilder.addOffset(0, offset_apiSignature);
    }
    if (offset_imports != null) {
      fbBuilder.addOffset(1, offset_imports);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(2, offset_exports);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(3, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

class _UnlinkedCombinatorImpl implements UnlinkedCombinator {
  final fb.BufferContext _bc;
  final int _bcOffset;

  List<String> _shows;
  List<String> _hides;

  _UnlinkedCombinatorImpl(this._bc, this._bcOffset);

  @override
  List<String> get hides {
    _hides ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _hides;
  }

  @override
  List<String> get shows {
    _shows ??= const fb.ListReader<String>(const fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
    return _shows;
  }
}

class _UnlinkedCombinatorReader
    extends fb.TableReader<_UnlinkedCombinatorImpl> {
  const _UnlinkedCombinatorReader();

  @override
  _UnlinkedCombinatorImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedCombinatorImpl(bc, offset);
}

class _UnlinkedNamespaceDirectiveImpl implements UnlinkedNamespaceDirective {
  final fb.BufferContext _bc;
  final int _bcOffset;

  String _uri;
  List<UnlinkedCombinator> _combinators;

  _UnlinkedNamespaceDirectiveImpl(this._bc, this._bcOffset);

  @override
  List<UnlinkedCombinator> get combinators {
    _combinators ??= const fb.ListReader<UnlinkedCombinator>(
            const _UnlinkedCombinatorReader())
        .vTableGet(_bc, _bcOffset, 1, const <UnlinkedCombinator>[]);
    return _combinators;
  }

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _uri;
  }
}

class _UnlinkedNamespaceDirectiveReader
    extends fb.TableReader<_UnlinkedNamespaceDirectiveImpl> {
  const _UnlinkedNamespaceDirectiveReader();

  @override
  _UnlinkedNamespaceDirectiveImpl createObject(
          fb.BufferContext bc, int offset) =>
      new _UnlinkedNamespaceDirectiveImpl(bc, offset);
}

class _UnlinkedUnitImpl implements UnlinkedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  List<int> _apiSignature;
  List<UnlinkedNamespaceDirective> _imports;
  List<UnlinkedNamespaceDirective> _exports;
  List<UnlinkedNamespaceDirective> _parts;

  _UnlinkedUnitImpl(this._bc, this._bcOffset);

  @override
  List<int> get apiSignature {
    _apiSignature ??=
        const fb.Uint8ListReader().vTableGet(_bc, _bcOffset, 0, const <int>[]);
    return _apiSignature;
  }

  @override
  List<UnlinkedNamespaceDirective> get exports {
    _exports ??= const fb.ListReader<UnlinkedNamespaceDirective>(
            const _UnlinkedNamespaceDirectiveReader())
        .vTableGet(_bc, _bcOffset, 2, const <UnlinkedNamespaceDirective>[]);
    return _exports;
  }

  @override
  List<UnlinkedNamespaceDirective> get imports {
    _imports ??= const fb.ListReader<UnlinkedNamespaceDirective>(
            const _UnlinkedNamespaceDirectiveReader())
        .vTableGet(_bc, _bcOffset, 1, const <UnlinkedNamespaceDirective>[]);
    return _imports;
  }

  @override
  List<UnlinkedNamespaceDirective> get parts {
    _parts ??= const fb.ListReader<UnlinkedNamespaceDirective>(
            const _UnlinkedNamespaceDirectiveReader())
        .vTableGet(_bc, _bcOffset, 3, const <UnlinkedNamespaceDirective>[]);
    return _parts;
  }
}

class _UnlinkedUnitReader extends fb.TableReader<UnlinkedUnit> {
  const _UnlinkedUnitReader();

  @override
  _UnlinkedUnitImpl createObject(fb.BufferContext bc, int offset) =>
      new _UnlinkedUnitImpl(bc, offset);
}
