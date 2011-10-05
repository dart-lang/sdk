// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <math.h>

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Double_doubleFromInteger, 2) {
  ASSERT(TypeArguments::CheckedHandle(arguments->At(0)).IsNull());
  const Integer& value = Integer::CheckedHandle(arguments->At(1));
  const Double& result = Double::Handle(Double::New(value.AsDoubleValue()));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_add, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  const Double& result = Double::Handle(Double::New(left + right));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_sub, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  const Double& result = Double::Handle(Double::New(left - right));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_mul, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  const Double& result = Double::Handle(Double::New(left * right));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_div, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  const Double& result = Double::Handle(Double::New(left / right));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_trunc_div, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  const Double& result = Double::Handle(Double::New(trunc(left / right)));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_modulo, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  double remainder = fmod(left, right);
  if (remainder == 0.0) {
    // We explicitely switch to the positive 0.0 (just in case it was negative).
    remainder = +0.0;
  } else if (remainder < 0) {
    if (right < 0) {
      remainder -= right;
    } else {
      remainder += right;
    }
  }
  const Double& result = Double::Handle(Double::New(remainder));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_remainder, 2) {
  double left = Double::CheckedHandle(arguments->At(0)).value();
  double right = Double::CheckedHandle(arguments->At(1)).value();
  const Double& result = Double::Handle(Double::New(fmod(left, right)));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_greaterThan, 2) {
  const Double& left = Double::CheckedHandle(arguments->At(0));
  const Double& right = Double::CheckedHandle(arguments->At(1));
  bool result = right.IsNull() ? false : (left.value() > right.value());
  arguments->SetReturn(Bool::Handle(Bool::Get(result)));
}


DEFINE_NATIVE_ENTRY(Double_greaterThanFromInteger, 2) {
  const Double& right = Double::CheckedHandle(arguments->At(0));
  const Integer& left = Integer::CheckedHandle(arguments->At(1));
  const Bool& result = Bool::Handle(Bool::Get(
      left.AsDoubleValue() > right.value()));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_equal, 2) {
  const Double& left = Double::CheckedHandle(arguments->At(0));
  const Double& right = Double::CheckedHandle(arguments->At(1));
  bool result = right.IsNull() ? false : (left.value() == right.value());
  arguments->SetReturn(Bool::Handle(Bool::Get(result)));
}


DEFINE_NATIVE_ENTRY(Double_equalToInteger, 2) {
  const Double& left = Double::CheckedHandle(arguments->At(0));
  const Integer& right = Integer::CheckedHandle(arguments->At(1));
  const Bool& result =
      Bool::Handle(Bool::Get(left.value() == right.AsDoubleValue()));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Double_round, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  arguments->SetReturn(Double::Handle(Double::New(round(arg.value()))));
}

DEFINE_NATIVE_ENTRY(Double_floor, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  arguments->SetReturn(Double::Handle(Double::New(floor(arg.value()))));
}

DEFINE_NATIVE_ENTRY(Double_ceil, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  arguments->SetReturn(Double::Handle(Double::New(ceil(arg.value()))));
}


DEFINE_NATIVE_ENTRY(Double_truncate, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  arguments->SetReturn(Double::Handle(Double::New(trunc(arg.value()))));
}


DEFINE_NATIVE_ENTRY(Double_pow, 2) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  const double exponent = Double::CheckedHandle(arguments->At(1)).value();
  arguments->SetReturn(Double::Handle(Double::New(pow(operand, exponent))));
}


#if defined(TARGET_OS_MACOS)
// MAC OSX math library produces old style cast warning.
#pragma GCC diagnostic ignored "-Wold-style-cast"
#endif

DEFINE_NATIVE_ENTRY(Double_toInt, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  if (isinf(arg.value()) || isnan(arg.value())) {
    GrowableArray<const Object*> args;
    args.Add(&String::ZoneHandle(String::New(
        "Infinity or NaN toInt")));
    Exceptions::ThrowByType(Exceptions::kBadNumberFormat, args);
  }
  double result = trunc(arg.value());
  if ((Smi::kMinValue <= result) && (result <= Smi::kMaxValue)) {
    arguments->SetReturn(Smi::Handle(Smi::New(static_cast<intptr_t>(result))));
  } else if ((Mint::kMinValue <= result) && (result <= Mint::kMaxValue)) {
    arguments->SetReturn(Mint::Handle(Mint::New(static_cast<int64_t>(result))));
  } else {
    arguments->SetReturn(
        Bigint::Handle(BigintOperations::NewFromDouble(result)));
  }
}


DEFINE_NATIVE_ENTRY(Double_isInfinite, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  if (isinf(arg.value())) {
    arguments->SetReturn(Bool::Handle(Bool::True()));
  } else {
    arguments->SetReturn(Bool::Handle(Bool::False()));
  }
}


DEFINE_NATIVE_ENTRY(Double_isNaN, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  if (isnan(arg.value())) {
    arguments->SetReturn(Bool::Handle(Bool::True()));
  } else {
    arguments->SetReturn(Bool::Handle(Bool::False()));
  }
}


DEFINE_NATIVE_ENTRY(Double_isNegative, 1) {
  const Double& arg = Double::CheckedHandle(arguments->At(0));
  // Include negative zero, infinity.
  if (signbit(arg.value()) && !isnan(arg.value())) {
    arguments->SetReturn(Bool::Handle(Bool::True()));
  } else {
    arguments->SetReturn(Bool::Handle(Bool::False()));
  }
}

// Add here only functions using/referring to old-style casts.

}  // namespace dart

