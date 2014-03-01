timing_test(function() {
  at(0, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(255, 0, 0)'},
      {'background-color':'rgb(176, 196, 222)'},
      {'background-color':'rgb(0, 128, 0)'},
      {'background-color':'rgba(0, 0, 0, 0)'},
      {'background-color':'rgba(255, 0, 255, 0)'},
      {'background-color':'rgb(0, 0, 0)'},
      {'background-color':'rgb(0, 0, 0)'},
    ]);
  });
  at(0.25, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(223, 16, 0)'},
      {'background-color':'rgb(154, 188, 194)'},
      {'background-color':'rgb(128, 128, 0)'},
      {'background-color':'rgba(255, 255, 255, 0.2471)'},
      {'background-color':'rgba(255, 255, 255, 0.2471)'},
      {'background-color':'rgb(32, 32, 32)'},
      {'background-color':'rgb(32, 32, 32)'},
    ]);
  });
  at(0.5, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(191, 32, 0)'},
      {'background-color':'rgb(132, 179, 167)'},
      {'background-color':'rgb(255, 128, 0)'},
      {'background-color':'rgba(255, 255, 255, 0.498)'},
      {'background-color':'rgba(255, 255, 255, 0.498)'},
      {'background-color':'rgb(64, 64, 64)'},
      {'background-color':'rgb(64, 64, 64)'},
    ]);
  });
  at(0.75, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(159, 48, 0)'},
      {'background-color':'rgb(110, 171, 139)'},
      {'background-color':'rgb(191, 128, 64)'},
      {'background-color':'rgba(255, 255, 255, 0.749)'},
      {'background-color':'rgba(255, 255, 255, 0.749)'},
      {'background-color':'rgb(96, 96, 96)'},
      {'background-color':'rgb(96, 96, 96)'},
    ]);
  });
  at(1, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(128, 64, 0)'},
      {'background-color':'rgb(88, 162, 111)'},
      {'background-color':'rgb(128, 128, 128)'},
      {'background-color':'rgb(255, 255, 255)'},
      {'background-color':'rgb(255, 255, 255)'},
      {'background-color':'rgb(128, 128, 128)'},
      {'background-color':'rgb(128, 128, 128)'},
    ]);
  });
  at(1.25, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(96, 80, 0)'},
      {'background-color':'rgb(66, 154, 83)'},
      {'background-color':'rgb(64, 128, 191)'},
      {'background-color':'rgba(255, 255, 255, 0.749)'},
      {'background-color':'rgba(255, 255, 255, 0.749)'},
      {'background-color':'rgb(159, 159, 159)'},
      {'background-color':'rgb(159, 159, 159)'},
    ]);
  });
  at(1.5, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(64, 96, 0)'},
      {'background-color':'rgb(44, 145, 56)'},
      {'background-color':'rgb(0, 128, 255)'},
      {'background-color':'rgba(255, 255, 255, 0.498)'},
      {'background-color':'rgba(255, 255, 255, 0.498)'},
      {'background-color':'rgb(191, 191, 191)'},
      {'background-color':'rgb(191, 191, 191)'},
    ]);
  });
  at(1.75, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(32, 112, 0)'},
      {'background-color':'rgb(22, 137, 28)'},
      {'background-color':'rgb(0, 128, 128)'},
      {'background-color':'rgba(255, 255, 255, 0.2471)'},
      {'background-color':'rgba(255, 255, 255, 0.2471)'},
      {'background-color':'rgb(223, 223, 223)'},
      {'background-color':'rgb(223, 223, 223)'},
    ]);
  });
  at(2, function() {
    assert_styles(".anim", [
      {'background-color':'rgb(0, 128, 0)'},
      {'background-color':'rgb(0, 128, 0)'},
      {'background-color':'rgb(0, 128, 0)'},
      {'background-color':'rgba(0, 0, 0, 0)'},
      {'background-color':'rgba(255, 0, 255, 0)'},
      {'background-color':'rgb(255, 255, 255)'},
      {'background-color':'rgb(255, 255, 255)'},
    ]);
  });
}, "Auto generated tests");
