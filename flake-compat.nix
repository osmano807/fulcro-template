let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes.flake-compat.locked) rev narHash;

  flake-compat = builtins.fetchTarball {
    url = lock.nodes.flake-compat.locked.url or "https://github.com/edolstra/flake-compat/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
in
  import flake-compat {src = ./.;}
