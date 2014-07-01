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



