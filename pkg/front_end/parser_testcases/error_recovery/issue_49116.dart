Future<bool> returnsFuture() => new Future.value(true);

// Notice the missing async marker.
void foo() {
  await returnsFuture();
  if (await returnsFuture()) {}
  else if (!await returnsFuture()) {}
  print(await returnsFuture());
  xor(await returnsFuture(), await returnsFuture(), await returnsFuture());
  await returnsFuture() ^ await returnsFuture();
  print(await returnsFuture() ^ await returnsFuture());
  await returnsFuture() + await returnsFuture();
  print(await returnsFuture() + await returnsFuture());
  await returnsFuture() - await returnsFuture();
  print(await returnsFuture() - await returnsFuture());
  !await returnsFuture() ^ !await returnsFuture();
  print(!await returnsFuture() ^ !await returnsFuture());

  var f = returnsFuture();
  await f; // valid variable declaration.
  if (await f) {}
  else if (!await f) {}
  print(await f);
  xor(await f, await f, await f);
  await f ^ await f;
  print(await f ^ await f);
  await f + await f;
  print(await f + await f);
  await f - await f;
  print(await f - await f);
  !await f ^ !await f;
  print(!await f ^ !await f);

  // Valid:
  await x; // Valid.
  await y, z; // Valid.
  await x2 = await; // Valid.
  await y2 = await, z2 = await; // Valid.
  await foo(int bar) { // Valid.
    return new await(); // Valid.
  } // Valid.
  await bar(await baz, await baz2, await baz3) { // Valid.
    return baz; // Valid.
  } // Valid.
}

bool xor(bool a, bool b, bool c) {
  return b ^ b ^ c;
}

class await {}
