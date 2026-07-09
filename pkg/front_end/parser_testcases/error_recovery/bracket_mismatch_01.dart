class C {
  C({c});
  C m() {
    return C(
      c: [
        C(c: [
          C(),
          C(),
          C(),
        ]),
        C(),
        C(),
      ],
    );
  }
}

class D {
  D({d});
  D m() {
    return D(
      d: [
        D(d:
          D(),
          D(),
          D(),
        ]),
        D(),
        D(),
      ],
    );
  }
}