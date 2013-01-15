// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.isolate;

class _IsolateEncoder {
  final manglingToken;
  // TODO(floitsch): switch to identity set.
  final Map _encoded = new Map();
  final Map _visiting = new Map();
  final Function _mangle;
  static const int _REFERENCE = 0;
  static const int _DECLARATION = 1;
  static const int _ESCAPED = 2;
  static const int _MANGLED = 3;

  _IsolateEncoder(this.manglingToken, mangle(data))
      : this._mangle = mangle;

  encode(var data) {
    if (data is num || data is String || data is bool || data == null) {
      return data;
    }

    if (_encoded.containsKey(data)) return _encoded[data];
    if (_visiting.containsKey(data)) {
      // Self reference.
      var selfReference = _visiting[data];
      if (selfReference == data) {
        // Nobody used the self-reference yet.
        selfReference = _createReference();
        _visiting[data] = selfReference;
      }
      return selfReference;
    }
    _visiting[data] = data;

    var result;

    if (data is List) {
      bool hasBeenDuplicated = false;
      result = data;
      for (int i = 0; i < data.length; i++) {
        var mangled = encode(data[i]);
        if (mangled != data[i] && !hasBeenDuplicated) {
          result = new List.fixedLength(data.length);
          for (int j = 0; j < i; j++) {
            result[j] = data[j];
          }
          hasBeenDuplicated = true;
        }
        if (hasBeenDuplicated) {
          result[i] = mangled;
        }
      }
      result = _escapeIfNecessary(result);
    } else if (data is Set) {
      // TODO(floitsch): should we accept sets?
      bool needsCopy = false;
      for (var entry in data) {
        var encoded = encode(entry);
        if (encoded != entry) {
          needsCopy = true;
          break;
        }
      }
      result = data;
      if (needsCopy) {
        result = new Set();
        data.forEach((entry) {
          result.add(encode(entry));
        });
      }
    } else if (data is Map) {
      bool needsCopy = false;
      data.forEach((key, value) {
        var encodedKey = encode(key);
        var encodedValue = encode(value);
        if (encodedKey != key) needsCopy = true;
        if (encodedValue != value) needsCopy = true;
      });
      result = data;
      if (needsCopy) {
        result = new Map();
        data.forEach((key, value) {
          result[encode(key)] = encode(value);
        });
      }
    } else {
      // We don't handle self-references for user data.
      // TODO(floitsch): we could keep the reference and throw when we see it
      // again. However now the user has at least the possibility to do
      // cyclic data-structures.
      _visiting.remove(data);
      result = _mangle(data);
      if (result != data) {
        result = _wrapMangled(encode(result));
      }
    }

    var selfReference = _visiting[data];
    if (selfReference != null && selfReference != data) {
      // A self-reference has been used.
      result = _declareReference(selfReference, result);
    }
    _encoded[data] = result;

    _visiting.remove(data);
    return result;
  }

  _createReference() => [manglingToken, _REFERENCE];
  _declareReference(reference, data) {
    return [manglingToken, _DECLARATION, reference, data];
  }

  _wrapMangled(data) => [manglingToken, _MANGLED, data];
  _escapeIfNecessary(List list) {
    if (!list.isEmpty && list[0] == manglingToken) {
      return [manglingToken, _ESCAPED, list];
    } else {
      return list;
    }
  }
}

class _IsolateDecoder {
  final manglingToken;
  final Map _decoded = new Map();
  final Function _unmangle;
  static const int _REFERENCE = _IsolateEncoder._REFERENCE;
  static const int _DECLARATION = _IsolateEncoder._DECLARATION;
  static const int _ESCAPED = _IsolateEncoder._ESCAPED;
  static const int _MANGLED = _IsolateEncoder._MANGLED;

  _IsolateDecoder(this.manglingToken, unmangle(data))
      : this._unmangle = unmangle;

  decode(var data) {
    if (data is num || data is String || data is bool || data == null) {
      return data;
    }

    if (_decoded.containsKey(data)) return _decoded[data];

    if (_isDeclaration(data)) {
      var reference = _extractReference(data);
      var declared = _extractDeclared(data);
      return _decodeObject(declared, reference);
    } else {
      return _decodeObject(data, null);
    }
  }

  _decodeObject(data, reference) {
    if (_decoded.containsKey(data)) {
      assert(reference == null);
      return _decoded[data];
    }

    // If the data was a reference then we would have found it in the _decoded
    // map.
    assert(!_isReference(data));

    var result;
    if (_isMangled(data)) {
      assert(reference == null);
      List mangled = _extractMangled(data);
      var decoded = decode(mangled);
      result = _unmangle(decoded);
    } else if (data is List) {
      if (_isEscaped(data)) data = _extractEscaped(data);
      assert(!_isMarked(data));
      result = data;
      bool hasBeenDuplicated = false;
      List duplicate() {
        assert(!hasBeenDuplicated);
        result = new List();
        result.length = data.length;
        if (reference != null) _decoded[reference] = result;
        hasBeenDuplicated = true;
      }

      if (reference != null) duplicate();
      for (int i = 0; i < data.length; i++) {
        var decoded = decode(data[i]);
        if (decoded != data[i] && !hasBeenDuplicated) {
          duplicate();
          for (int j = 0; j < i; j++) {
            result[j] = data[j];
          }
        }
        if (hasBeenDuplicated) {
          result[i] = decoded;
        }
      }
    } else if (data is Set) {
      bool needsCopy = reference != null;
      if (!needsCopy) {
        for (var entry in data) {
          var decoded = decode(entry);
          if (decoded != entry) {
            needsCopy = true;
            break;
          }
        }
      }
      result = data;
      if (needsCopy) {
        result = new Set();
        if (reference != null) _decoded[reference] = result;
        for (var entry in data) {
          result.add(decode(entry));
        }
      }
    } else if (data is Map) {
      bool needsCopy = reference != null;
      if (!needsCopy) {
        data.forEach((key, value) {
          var decodedKey = decode(key);
          var decodedValue = decode(value);
          if (decodedKey != key) needsCopy = true;
          if (decodedValue != value) needsCopy = true;
        });
      }
      result = data;
      if (needsCopy) {
        result = new Map();
        if (reference != null) _decoded[reference] = result;
        data.forEach((key, value) {
          result[decode(key)] = decode(value);
        });
      }
    } else {
      result = data;
    }
    _decoded[data] = result;
    return result;
  }

  _isMarked(data) {
    if (data is List && !data.isEmpty && data[0] == manglingToken) {
      assert(data.length > 1);
      return true;
    }
    return false;
  }
  _isReference(data) => _isMarked(data) && data[1] == _REFERENCE;
  _isDeclaration(data) => _isMarked(data) && data[1] == _DECLARATION;
  _isMangled(data) => _isMarked(data) && data[1] == _MANGLED;
  _isEscaped(data) => _isMarked(data) && data[1] == _ESCAPED;

  _extractReference(declaration) {
    assert(_isDeclaration(declaration));
    return declaration[2];
  }
  _extractDeclared(declaration) {
    assert(_isDeclaration(declaration));
    return declaration[3];
  }
  _extractMangled(wrappedMangled) {
    assert(_isMangled(wrappedMangled));
    return wrappedMangled[2];
  }
  _extractEscaped(data) {
    assert(_isEscaped(data));
    return data[2];
  }
}
