class C<@a<int>> {}

List<@a<int>> x;

(@a<int>> x, int y) z;

class C2<@a<List<int>>> {}

List<@a<List<int>>> x2;

(@a<List<int>>> x, int y) z2;

Map<@a<int>, @b<int>> x3;

@a<@b<int>>
class C3 {}

void f(x) {
  if (x case <@a<int>>[]) {}
}

class C4 = Object with List<@a<int>>
