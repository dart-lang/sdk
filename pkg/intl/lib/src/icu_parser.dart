// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Contains a parser for ICU format plural/gender/select format for localized
 * messages. See extract_to_arb.dart and make_hardcoded_translation.dart.
 */
library icu_parser;

import 'package:intl/src/intl_message.dart';
import 'package:petitparser/petitparser.dart';

/**
 * This defines a grammar for ICU MessageFormat syntax. Usage is
 *       new IcuParser.message.parse(<string>).value;
 * The "parse" method will return a Success or Failure object which responds
 * to "value".
 */
class IcuParser {
  get openCurly => char("{");

  get closeCurly => char("}");
  get quotedCurly => (string("'{'") | string("'}'")).map((x) => x[1]);

  get icuEscapedText => quotedCurly | twoSingleQuotes;
  get curly => (openCurly | closeCurly);
  get notAllowedInIcuText => curly | char("<");
  get icuText => notAllowedInIcuText.neg();
  get notAllowedInNormalText => char("{");
  get normalText => notAllowedInNormalText.neg();
  get messageText => (icuEscapedText | icuText)
      .plus().map((x) => x.join());
  get nonIcuMessageText => normalText.plus().map((x) => x.join());
  get twoSingleQuotes => string("''").map((x) => "'");
  get number => digit().plus().flatten().trim().map(int.parse);
  get id => (letter() & (word() | char("_")).star()).flatten();
  get comma => char(",").trim();

  /**
   * Given a list of possible keywords, return a rule that accepts any of them.
   * e.g., given ["male", "female", "other"], accept any of them.
   */
  asKeywords(list) => list.map(string).reduce((a, b) => a | b).flatten().trim();

  get pluralKeyword => asKeywords(
      ["=0", "=1", "=2", "zero", "one", "two", "few", "many", "other"]);
  get genderKeyword => asKeywords(
      ["female", "male", "other"]);

  var interiorText = undefined();

  get preface => (openCurly & id & comma).map((values) => values[1]);

  get pluralLiteral => string("plural");
  get pluralClause => (pluralKeyword & openCurly & interiorText & closeCurly)
      .trim().map((result) => [result[0], result[2]]);
  get plural =>
      preface & pluralLiteral & comma & pluralClause.plus() & closeCurly;
  get intlPlural =>
      plural.map((values) => new Plural.from(values.first, values[3], null));

  get selectLiteral => string("select");
  get genderClause => (genderKeyword & openCurly & interiorText & closeCurly)
      .trim().map((result) => [result[0], result[2]]);
  get gender =>
      preface & selectLiteral & comma & genderClause.plus() & closeCurly;
  get intlGender =>
      gender.map((values) => new Gender.from(values.first, values[3], null));
  get selectClause => (id & openCurly & interiorText & closeCurly).map(
      (x) => [x.first, x[2]]);
  get generalSelect => preface & selectLiteral & comma &
      selectClause.plus() & closeCurly;
  get intlSelect => generalSelect.map(
      (values) => new Select.from(values.first, values[3], null));

  get pluralOrGenderOrSelect => intlPlural | intlGender | intlSelect;

  get contents => pluralOrGenderOrSelect | parameter | messageText;
  get simpleText => (nonIcuMessageText | parameter | openCurly).plus();
  get empty => epsilon().map((_) => '');

  get parameter => (openCurly & id & closeCurly).map(
      (param) => new VariableSubstitution.named(param[1], null));

  /**
   * The primary entry point for parsing. Accepts a string and produces
   * a parsed representation of it as a Message.
   */
  get message => (pluralOrGenderOrSelect | empty).map((chunk) =>
      Message.from(chunk, null));

  /**
   * Represents an ordinary message, i.e. not a plural/gender/select, although
   * it may have parameters.
   */
  get nonIcuMessage => (simpleText | empty).map((chunk) =>
      Message.from(chunk, null));

  get stuff => (pluralOrGenderOrSelect | empty).map(
      (chunk) => Message.from(chunk, null));

  IcuParser() {
    // There is a cycle here, so we need the explicit set to avoid
    // infinite recursion.
    interiorText.set(contents.plus() | empty);
  }
}