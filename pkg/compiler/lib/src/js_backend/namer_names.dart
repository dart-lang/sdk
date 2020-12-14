// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend.namer;

abstract class _NamerName extends jsAst.Name {
  int get _kind;
  _NamerName get _target => this;

  @override
  String toString() {
    if (DEBUG_MODE) {
      return 'Name($key)';
    }
    throw new UnsupportedError("Cannot convert a name to a string");
  }
}

enum _NamerNameKinds { StringBacked, Getter, Setter, Async, Compound, Token }

class StringBackedName extends _NamerName {
  @override
  final String name;
  @override
  int get _kind => _NamerNameKinds.StringBacked.index;

  StringBackedName(this.name);

  @override
  String get key => name;

  @override
  operator ==(other) {
    if (other is _NameReference) other = other._target;
    if (identical(this, other)) return true;
    return (other is StringBackedName) && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  int compareTo(jsAst.Name other) {
    _NamerName otherNamerName;
    if (other is ModularName) {
      otherNamerName = other.value;
    } else {
      otherNamerName = other;
    }
    otherNamerName = otherNamerName._target;
    if (otherNamerName._kind != _kind) return otherNamerName._kind - _kind;
    return name.compareTo(otherNamerName.name);
  }
}

abstract class _PrefixedName extends _NamerName implements jsAst.AstContainer {
  final jsAst.Name prefix;
  final jsAst.Name base;
  @override
  int get _kind;

  @override
  Iterable<jsAst.Node> get containedNodes => [prefix, base];

  _PrefixedName(this.prefix, this.base);

  @override
  String get name => prefix.name + base.name;

  @override
  String get key => prefix.key + base.key;

  @override
  bool operator ==(other) {
    if (other is _NameReference) other = other._target;
    if (identical(this, other)) return true;
    if (other is! _PrefixedName) return false;
    return other.base == base && other.prefix == prefix;
  }

  @override
  int get hashCode => base.hashCode * 13 + prefix.hashCode;

  @override
  bool get isFinalized => prefix.isFinalized && base.isFinalized;

  @override
  int compareTo(jsAst.Name other) {
    _NamerName otherNamerName;
    if (other is ModularName) {
      otherNamerName = other.value;
    } else {
      otherNamerName = other;
    }
    otherNamerName = otherNamerName._target;
    if (otherNamerName._kind != _kind) return otherNamerName._kind - _kind;
    _PrefixedName otherSameKind = otherNamerName;
    int result = prefix.compareTo(otherSameKind.prefix);
    if (result == 0) {
      result = prefix.compareTo(otherSameKind.prefix);
      if (result == 0) {
        result = base.compareTo(otherSameKind.base);
      }
    }
    return result;
  }
}

class GetterName extends _PrefixedName {
  @override
  int get _kind => _NamerNameKinds.Getter.index;

  GetterName(jsAst.Name prefix, jsAst.Name base) : super(prefix, base);
}

class SetterName extends _PrefixedName {
  @override
  int get _kind => _NamerNameKinds.Setter.index;

  SetterName(jsAst.Name prefix, jsAst.Name base) : super(prefix, base);
}

class AsyncName extends _PrefixedName {
  @override
  int get _kind => _NamerNameKinds.Async.index;

  AsyncName(jsAst.Name prefix, jsAst.Name base) : super(prefix, base);

  @override
  bool get allowRename => true;
}

class CompoundName extends _NamerName implements jsAst.AstContainer {
  final List<_NamerName> _parts;
  @override
  int get _kind => _NamerNameKinds.Compound.index;
  String _cachedName;
  int _cachedHashCode = -1;

  @override
  Iterable<jsAst.Node> get containedNodes => _parts;

  CompoundName(this._parts);

  CompoundName.from(List<jsAst.Name> parts) : this(<_NamerName>[...parts]);

  @override
  String get name {
    if (_cachedName == null) {
      _cachedName = _parts.map((jsAst.Name name) => name.name).join();
    }
    return _cachedName;
  }

  @override
  String get key => _parts.map((_NamerName name) => name.key).join();

  @override
  bool operator ==(other) {
    if (other is _NameReference) other = other._target;
    if (identical(this, other)) return true;
    if (other is! CompoundName) return false;
    if (other._parts.length != _parts.length) return false;
    for (int i = 0; i < _parts.length; ++i) {
      if (other._parts[i] != _parts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    if (_cachedHashCode < 0) {
      _cachedHashCode = 0;
      for (jsAst.Name name in _parts) {
        _cachedHashCode = (_cachedHashCode * 17 + name.hashCode) & 0x7fffffff;
      }
    }
    return _cachedHashCode;
  }

  @override
  int compareTo(jsAst.Name other) {
    _NamerName otherNamerName;
    if (other is ModularName) {
      otherNamerName = other.value;
    } else {
      otherNamerName = other;
    }
    otherNamerName = otherNamerName._target;
    if (otherNamerName._kind != _kind) return otherNamerName._kind - _kind;
    CompoundName otherSameKind = otherNamerName;
    if (otherSameKind._parts.length != _parts.length) {
      return otherSameKind._parts.length - _parts.length;
    }
    int result = 0;
    for (int pos = 0; result == 0 && pos < _parts.length; pos++) {
      result = _parts[pos].compareTo(otherSameKind._parts[pos]);
    }
    return result;
  }
}

class TokenName extends _NamerName implements jsAst.ReferenceCountedAstNode {
  @override
  int get _kind => _NamerNameKinds.Token.index;
  String _name;
  @override
  final String key;
  final TokenScope _scope;
  int _rc = 0;

  TokenName(this._scope, this.key);

  @override
  bool get isFinalized => _name != null;

  @override
  String get name {
    assert(isFinalized, "TokenName($key) has not been finalized.");
    return _name;
  }

  @override
  int compareTo(covariant _NamerName other) {
    other = other._target;
    if (other._kind != _kind) return other._kind - _kind;
    TokenName otherToken = other;
    return key.compareTo(otherToken.key);
  }

  @override
  void markSeen(jsAst.TokenCounter counter) => _rc++;

  @override
  bool operator ==(other) {
    if (other is _NameReference) other = other._target;
    if (identical(this, other)) return true;
    return false;
  }

  @override
  int get hashCode => super.hashCode;

  void finalize() {
    assert(
        !isFinalized,
        failedAt(NO_LOCATION_SPANNABLE,
            "TokenName($key)=$_name has already been finalized."));
    _name = _scope.getNextName();
  }
}

class _NameReference extends _NamerName implements jsAst.AstContainer {
  @override
  _NamerName _target;

  @override
  int get _kind => _target._kind;
  @override
  String get key => _target.key;

  @override
  Iterable<jsAst.Node> get containedNodes => [_target];

  _NameReference(this._target);

  @override
  String get name => _target.name;

  @override
  int compareTo(jsAst.Name other) {
    _NamerName otherNamerName;
    if (other is ModularName) {
      otherNamerName = other.value;
    } else {
      otherNamerName = other;
    }
    return _target.compareTo(otherNamerName);
  }

  @override
  bool get isFinalized => _target.isFinalized;

  @override
  bool operator ==(other) => _target == other;

  @override
  int get hashCode => _target.hashCode;
}
