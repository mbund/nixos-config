let
  postBuild = "echo HELLO";

  lib = {
    inherit postBuild;
  };
in
lib