// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AstBinaryFlags {
  static const _hasInitializer = 1 << 0;
  static const _isAbstract = 1 << 1;
  static const _isConst = 1 << 2;
  static const _isCovariant = 1 << 3;
  static const _isDeferred = 1 << 4;
  static const _isExternal = 1 << 5;
  static const _isFactory = 1 << 6;
  static const _isFinal = 1 << 7;
  static const _isGet = 1 << 8;
  static const _isLate = 1 << 9;
  static const _isNew = 1 << 10;
  static const _isSet = 1 << 11;
  static const _isStatic = 1 << 12;
  static const _isVar = 1 << 13;

  static int encode({
    bool hasInitializer: false,
    bool isAbstract: false,
    bool isConst: false,
    bool isCovariant: false,
    bool isDeferred: false,
    bool isExternal: false,
    bool isFactory: false,
    bool isFinal: false,
    bool isGet: false,
    bool isLate: false,
    bool isNew: false,
    bool isSet: false,
    bool isStatic: false,
    bool isVar: false,
  }) {
    var result = 0;
    if (hasInitializer) {
      result |= _hasInitializer;
    }
    if (isAbstract) {
      result |= _isAbstract;
    }
    if (isCovariant) {
      result |= _isCovariant;
    }
    if (isDeferred) {
      result |= _isDeferred;
    }
    if (isConst) {
      result |= _isConst;
    }
    if (isExternal) {
      result |= _isExternal;
    }
    if (isFactory) {
      result |= _isFactory;
    }
    if (isFinal) {
      result |= _isFinal;
    }
    if (isGet) {
      result |= _isGet;
    }
    if (isLate) {
      result |= _isLate;
    }
    if (isNew) {
      result |= _isNew;
    }
    if (isSet) {
      result |= _isSet;
    }
    if (isStatic) {
      result |= _isStatic;
    }
    if (isVar) {
      result |= _isVar;
    }
    return result;
  }

  static bool hasInitializer(int flags) {
    return (flags & _hasInitializer) != 0;
  }

  static bool isAbstract(int flags) {
    return (flags & _isAbstract) != 0;
  }

  static bool isConst(int flags) {
    return (flags & _isConst) != 0;
  }

  static bool isCovariant(int flags) {
    return (flags & _isCovariant) != 0;
  }

  static bool isDeferred(int flags) {
    return (flags & _isDeferred) != 0;
  }

  static bool isExternal(int flags) {
    return (flags & _isExternal) != 0;
  }

  static bool isFactory(int flags) {
    return (flags & _isFactory) != 0;
  }

  static bool isFinal(int flags) {
    return (flags & _isFinal) != 0;
  }

  static bool isGet(int flags) {
    return (flags & _isGet) != 0;
  }

  static bool isLate(int flags) {
    return (flags & _isLate) != 0;
  }

  static bool isNew(int flags) {
    return (flags & _isNew) != 0;
  }

  static bool isSet(int flags) {
    return (flags & _isSet) != 0;
  }

  static bool isStatic(int flags) {
    return (flags & _isStatic) != 0;
  }

  static bool isVar(int flags) {
    return (flags & _isVar) != 0;
  }
}
