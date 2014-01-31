// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library number_symbols;

/**
 * This holds onto information about how a particular locale formats numbers. It
 * contains strings for things like the decimal separator, digit to use for "0"
 * and infinity. We expect the data for instances to be generated out of ICU
 * or a similar reference source.
 */
class NumberSymbols {
  final String NAME;
  final String DECIMAL_SEP, GROUP_SEP, PERCENT, ZERO_DIGIT, PLUS_SIGN,
      MINUS_SIGN, EXP_SYMBOL, PERMILL, INFINITY, NAN, DECIMAL_PATTERN,
      SCIENTIFIC_PATTERN, PERCENT_PATTERN, CURRENCY_PATTERN, DEF_CURRENCY_CODE;

  const NumberSymbols({this.NAME,
                       this.DECIMAL_SEP,
                       this.GROUP_SEP,
                       this.PERCENT,
                       this.ZERO_DIGIT,
                       this.PLUS_SIGN,
                       this.MINUS_SIGN,
                       this.EXP_SYMBOL,
                       this.PERMILL,
                       this.INFINITY,
                       this.NAN,
                       this.DECIMAL_PATTERN,
                       this.SCIENTIFIC_PATTERN,
                       this.PERCENT_PATTERN,
                       this.CURRENCY_PATTERN,
                       this.DEF_CURRENCY_CODE});

  toString() => NAME;
}
