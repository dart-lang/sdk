# Changelog

## 0.3.3

- No externally visible changes.

## 0.3.2

- The `find` command can now look up addresses given as offsets from static
  symbols, not just hexadecimal virtual or absolute addresses.
- Integer inputs (addresses or offsets) without an '0x' prefix or hexadecimal
  digits will now be parsed as decimal unless the `-x`/`--force_hexadecimal`
  flag is used.

## 0.3.1

- Uses dynamic symbol information embedded in stack frame lines when available.

## 0.3.0

- Adds handling of virtual addresses within stub code payloads.

## 0.2.2

- Finds instruction sections by the dynamic symbols the Dart VM creates instead
  of assuming there are two text sections.

## 0.2.1

- Added static method `Dwarf.fromBuffer`.

## 0.2.0

- API and documentation cleanups

## 0.1.0

- Initial release
