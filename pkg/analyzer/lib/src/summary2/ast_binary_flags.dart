// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

class AstBinaryFlags {
  static final Map<Type, int> _typeBits = {};

  static final _hasAwait = _checkBit(0, ForElement, ForStatement);

  static final _hasInitializer = _checkBit(2, FormalParameter);

  static final _hasName = _checkBit(5, FormalParameter);

  static final _hasNot = _checkBit(0, IsExpression);

  static final _hasQuestion = _checkBit(
    2,
    GenericFunctionType,
    NamedType,
    ReceiverIndexAssignmentTarget,
    ReceiverIndexExpression,
  );

  static final _hasThis = _checkBit(
    0,
    ConstructorFieldInitializer,
    RedirectingConstructorInvocation,
  );

  static final _hasTypeArguments = _checkBit(0, NamedType, TypedLiteral);

  static final _isConst = _checkBit(
    3,
    DeclaredIdentifier,
    ConstructorInvocation,
    TypedLiteral,
  );

  static final _isFinal = _checkBit(4, DeclaredIdentifier);

  static final _isNamed = _checkBit(0, DelimitedFormalParameters);

  static final _isNew = _checkBit(0, ConstructorInvocation);

  static final _isPositional = _checkBit(1, FormalParameter);

  static final _isRequired = _checkBit(0, FormalParameter);

  static final _isStringInterpolationIdentifier = _checkBit(
    0,
    InterpolationExpression,
  );

  static final _isVar = _checkBit(1, DeclaredIdentifier);

  static const _formalParameterKeywordFinal = 1 << 3;
  static const _formalParameterKeywordConst = 1 << 4;
  static const _formalParameterKeywordMask =
      _formalParameterKeywordFinal | _formalParameterKeywordConst;
  static const _formalParameterHasQuestion = 1 << 6;
  static const _formalParameterIsCovariant = 1 << 7;

  static int encode({
    bool hasAwait = false,
    bool hasInitializer = false,
    bool hasName = false,
    bool hasNot = false,
    bool hasQuestion = false,
    bool hasThis = false,
    bool hasTypeArguments = false,
    bool isConst = false,
    bool isFinal = false,
    bool isNamed = false,
    bool isNew = false,
    bool isPositional = false,
    bool isRequired = false,
    bool isStringInterpolationIdentifier = false,
    bool isVar = false,
  }) {
    var result = 0;
    if (hasAwait) {
      result |= _hasAwait;
    }
    if (hasInitializer) {
      result |= _hasInitializer;
    }
    if (hasName) {
      result |= _hasName;
    }
    if (hasNot) {
      result |= _hasNot;
    }
    if (hasQuestion) {
      result |= _hasQuestion;
    }
    if (hasThis) {
      result |= _hasThis;
    }
    if (hasTypeArguments) {
      result |= _hasTypeArguments;
    }
    if (isConst) {
      result |= _isConst;
    }
    if (isFinal) {
      result |= _isFinal;
    }
    if (isNamed) {
      result |= _isNamed;
    }
    if (isNew) {
      result |= _isNew;
    }
    if (isPositional) {
      result |= _isPositional;
    }
    if (isRequired) {
      result |= _isRequired;
    }
    if (isStringInterpolationIdentifier) {
      result |= _isStringInterpolationIdentifier;
    }
    if (isVar) {
      result |= _isVar;
    }
    return result;
  }

  static int encodeFormalParameter({
    required bool hasInitializer,
    required bool hasName,
    required bool hasQuestion,
    required bool isConst,
    required bool isCovariant,
    required bool isFinal,
    required bool isPositional,
    required bool isRequired,
    required bool isVar,
  }) {
    var result = encode(
      hasInitializer: hasInitializer,
      hasName: hasName,
      isPositional: isPositional,
      isRequired: isRequired,
    );
    if (isFinal) {
      result |= _formalParameterKeywordFinal;
    }
    if (isConst) {
      result |= _formalParameterKeywordConst;
    }
    if (isVar) {
      result |= _formalParameterKeywordMask;
    }
    if (hasQuestion) {
      result |= _formalParameterHasQuestion;
    }
    if (isCovariant) {
      result |= _formalParameterIsCovariant;
    }
    return result;
  }

  static bool formalParameterHasInitializer(int flags) {
    return hasInitializer(flags);
  }

  static bool formalParameterHasName(int flags) {
    return hasName(flags);
  }

  static bool formalParameterHasQuestion(int flags) {
    return (flags & _formalParameterHasQuestion) != 0;
  }

  static bool formalParameterIsConst(int flags) {
    return (flags & _formalParameterKeywordMask) ==
        _formalParameterKeywordConst;
  }

  static bool formalParameterIsCovariant(int flags) {
    return (flags & _formalParameterIsCovariant) != 0;
  }

  static bool formalParameterIsFinal(int flags) {
    return (flags & _formalParameterKeywordMask) ==
        _formalParameterKeywordFinal;
  }

  static bool formalParameterIsPositional(int flags) {
    return isPositional(flags);
  }

  static bool formalParameterIsRequired(int flags) {
    return isRequired(flags);
  }

  static bool formalParameterIsVar(int flags) {
    return (flags & _formalParameterKeywordMask) == _formalParameterKeywordMask;
  }

  static bool hasAwait(int flags) {
    return (flags & _hasAwait) != 0;
  }

  static bool hasInitializer(int flags) {
    return (flags & _hasInitializer) != 0;
  }

  static bool hasName(int flags) {
    return (flags & _hasName) != 0;
  }

  static bool hasNot(int flags) {
    return (flags & _hasNot) != 0;
  }

  static bool hasQuestion(int flags) {
    return (flags & _hasQuestion) != 0;
  }

  static bool hasThis(int flags) {
    return (flags & _hasThis) != 0;
  }

  static bool hasTypeArguments(int flags) {
    return (flags & _hasTypeArguments) != 0;
  }

  static bool isConst(int flags) {
    return (flags & _isConst) != 0;
  }

  static bool isFinal(int flags) {
    return (flags & _isFinal) != 0;
  }

  static bool isNamed(int flags) {
    return (flags & _isNamed) != 0;
  }

  static bool isNew(int flags) {
    return (flags & _isNew) != 0;
  }

  static bool isPositional(int flags) {
    return (flags & _isPositional) != 0;
  }

  static bool isRequired(int flags) {
    return (flags & _isRequired) != 0;
  }

  static bool isStringInterpolationIdentifier(int flags) {
    return (flags & _isStringInterpolationIdentifier) != 0;
  }

  static bool isVar(int flags) {
    return (flags & _isVar) != 0;
  }

  /// Check the bit for its uniqueness for the given types.
  static int _checkBit(
    int shift,
    Type type1, [
    Type? type2,
    Type? type3,
    Type? type4,
    Type? type5,
    Type? type6,
  ]) {
    _checkBit0(shift, type1);
    _checkBit0(shift, type2);
    _checkBit0(shift, type3);
    _checkBit0(shift, type4);
    _checkBit0(shift, type5);
    _checkBit0(shift, type6);
    return 1 << shift;
  }

  /// Check the bit for its uniqueness for the [type].
  static void _checkBit0(int shift, Type? type) {
    if (type != null) {
      var currentBits = _typeBits[type] ?? 0;
      var bit = 1 << shift;
      if ((currentBits & bit) != 0) {
        throw StateError('1 << $shift is already used for $type');
      }
      _typeBits[type] = currentBits | bit;
    }
  }
}
