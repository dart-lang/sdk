timing_test(function() {
  at(0, function() {
    assert_styles(".anim", [
      {'boxShadow':'rgb(0, 0, 255) -20px -20px 0px 0px'},
      {'boxShadow':'rgb(0, 0, 255) -20px -20px 8px 0px inset'},
      {'boxShadow':'rgb(0, 0, 255) 20px 20px 8px 0px inset'},
      {'boxShadow':'none'},
    ]);
  });
  at(1, function() {
    assert_styles(".anim", [
      {'boxShadow':'rgb(0, 32, 191) -10px -10px 3px 2px'},
      {'boxShadow':'rgb(0, 32, 191) -10px -10px 9px 2px inset'},
      {'boxShadow':'rgb(0, 0, 255) 20px 20px 8px 0px inset'},
      {'boxShadow':'none'},
    ]);
  });
  at(2, function() {
    assert_styles(".anim", [
      {'boxShadow':'rgb(0, 64, 128) 0px 0px 6px 4px'},
      {'boxShadow':'rgb(0, 64, 128) 0px 0px 10px 4px inset'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
    ]);
  });
  at(3, function() {
    assert_styles(".anim", [
      {'boxShadow':'rgb(0, 96, 64) 10px 10px 9px 6px'},
      {'boxShadow':'rgb(0, 96, 64) 10px 10px 11px 6px inset'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
    ]);
  });
  at(4, function() {
    assert_styles(".anim", [
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px inset'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
      {'boxShadow':'rgb(0, 128, 0) 20px 20px 12px 8px'},
    ]);
  });
}, "Auto generated tests");