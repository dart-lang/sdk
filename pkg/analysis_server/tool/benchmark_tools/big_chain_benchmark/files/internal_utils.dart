import 'characters.dart' show $$, $0, $9, $A, $Z, $_, $a, $z;

@pragma("vm:prefer-inline")
bool isIdentifierChar(int next, bool allowDollar) {
  return ($a <= next && next <= $z) ||
      ($A <= next && next <= $Z) ||
      ($0 <= next && next <= $9) ||
      next == $_ ||
      (next == $$ && allowDollar);
}

/// Checks if the character [next] is an identifier character (allowing the
/// dollar sign) using a table lookup, utilizing the fact that the input is from
/// a Uint8List and therefore between 0 and 255.
/// It is the callers responsibility to ensure that this is the case.
// DartDocTest(() {
//   for (int i = 0; i < 256; i++) {
//     if (isIdentifierCharAllowDollarTableLookup(i) !=
//         isIdentifierChar(i, true)) {
//       return false;
//     }
//   }
//   return true;
// }(), true);
@pragma("vm:prefer-inline")
bool isIdentifierCharAllowDollarTableLookup(int next) {
  const List<bool> table = [
    // format hack.
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, true, false, false, false,
    false, false, false, false, false, false, false, false,
    true, true, true, true, true, true, true, true,
    true, true, false, false, false, false, false, false,
    false, true, true, true, true, true, true, true,
    true, true, true, true, true, true, true, true,
    true, true, true, true, true, true, true, true,
    true, true, true, false, false, false, false, true,
    false, true, true, true, true, true, true, true,
    true, true, true, true, true, true, true, true,
    true, true, true, true, true, true, true, true,
    true, true, true, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    // format hack.
  ];
  return table[next];
}
