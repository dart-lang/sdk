# RegExp

Dart RegExp is defined to have the same behavior as JS RegExp so that the JS implementations of Dart can directly use the host JS RegExp engine. The Dart VM's implementation is taken from V8, which is called [Irregexp](https://blog.chromium.org/2009/02/irregexp-google-chromes-new-regexp.html).

The following are disabled

 - the atom matching optimization
 - the [experimental](https://v8.dev/blog/non-backtracking-regexp) implementation
 - the bytecode peephole optimization
 - the machine code implementations
 - tiering up and statistics counters
 - caching of matches
 - caching of regexp (though we do this in the VM at an earlier place)

To update
  - copy the files from v8/src/{regexp,base,zone,strings}/* to runtime/vm/regexp
    - most of these will become unused
  - update the includes to account for the new location
  - add includes of vm/regexp/base.h to get shims mapping many V8-isms to Dart-isms
  - remove or comment-out anything listed as disabled above
    - hopefully these will mostly be obvious from the diff from the previous port
  - map any remaining compile time errors from V8 things to Dart things
    - Handle<String> -> String&
    - Handle<JSRegExp or RegExpData> -> RegExp&
    - Handle<ByteArray> -> TypedData&

Note that all Dart strings are what V8 calls "flat". We have no special String representations that delay concatenation or taking substrings. All Dart RegExp are also "unmodified": users can't add/remove slots or replace methods.

The most recent update used v8 commit 254cc758346f10be2a7e22e55d90d4defe9cad74, which might be helpful for looking at a diff on the V8 side.
