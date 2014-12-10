## 0.11.11
  * Add a -no-embedded-plurals flag to reject plurals and genders that
    have either leading or trailing text around them. This follows the
    ICU recommendation that a plural or gender should contain the
    entire phrase/sentence, not just part of it.

## 0.11.10
  * Fix some style glitches with naming. The only publicly visible one
    is DateFormat.parseUtc, but the parseUTC variant is still retained
    for backward-compatibility.

  * Provide a better error message when generating translated versions
    and the name of a variable substitution in the message doesn't
    match the name in the translation.

## 0.11.9
  * Fix bug with per-mille parsing (only divided by 100, not 1000)
  
  * Support percent and per-mille formats with both positive and negative
    variations. Previously would throw an exception for too many modifiers.

## 0.11.8

  * Support NumberFormats with two different grouping sizes, e.g.
    1,23,45,67,890

## 0.11.7
  * Moved petitparser into a regular dependency so pub run works.

  * Improved code layout of the package.

  * Added a DateFormat.parseStrict method that rejects DateTimes with invalid
    values and requires it to be the whole string.

## 0.11.6

  * Catch analyzer errors and do not generate messages for that file. Previously
    this would stop the message extraction on syntax errors and not give error
    messages as good as the compiler would produce. Just let the compiler do it.

## 0.11.5

 * Change to work with both petitparser 1.1.x and 1.2.x versions.

## 0.11.4

 * Broaden the pubspec constraints to allow current analyzer versions.

## 0.11.3

 * Add a --[no]-use-deferred-loading flag to generate_from_arb.dart and
   generally make the deferred loading of message libraries optional.

## 0.11.2

 * Missed canonicalization of locales in one place in message library generation.

 * Added a simple debug script for message_extraction_test.

## 0.11.1

 * Negative numbers were being parsed as positive.

## 0.11.0

 * Switch the message format from a custom JSON format to
   the ARB format ( https://code.google.com/p/arb/ )

## 0.10.0

 * Make message catalogs use deferred loading.

 * Update CLDR Data to version 25 for dates and numbers.

 * Update analyzer dependency to allow later versions.

 * Adds workaround for flakiness in DateTime creation, removes debugging code
   associated with that.

## 0.9.9

* Add NumberFormat.parse()

* Allow NumberFormat constructor to take an optional currency name/symbol, so
  you can format for a particular locale without it dictating the currency, and
  also supply the currency symbols which we don't have yet.

* Canonicalize locales more consistently, avoiding a number of problems if you
  use a non-canonical form.

* For locales whose length is longer than 6 change "-" to "_" in position 3 when
  canonicalizing. Previously anything of length > 6 was left completely alone.

## 0.9.8

* Add a "meaning" optional parameter for Intl.message to distinguish between
  two messages with identical text.

* Handle two different messages with the same text.

* Allow complex string literals in arguments (e.g. multi-line)
