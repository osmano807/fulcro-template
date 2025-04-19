{
  inputs,
  cell,
}:
let
  inherit (inputs) nixpkgs std;
  l = nixpkgs.lib // builtins;
in
# Here we map an attribute set to the `std.std.lib.mkShell` function.
# This is a small wrapper around the numtide/devshell `mkShell` function and
# provides integration with `nixago`. The
# result of this map is a attribute set where the value is a proper
# development shell derivation.
l.mapAttrs (_: std.lib.dev.mkShell) {
  # This is our only development shell, so we name it "default". The
  # numtide/devshell `mkShell` function uses modules, so the `{ ... }` here is
  # simply boilerplate.
  default =
    { ... }:
    {
      # The structure of this attribute set is defined here:
      # https://github.com/numtide/devshell/tree/master/modules
      #

      name = "fulcro-devshell";

      devshell.meta.description = "Development shell for Fulcro application";

      # Since we're using modules here, we can import other modules into our
      # final configuration. In this case, we import the `std` default development
      # shell profile which will, among other things, automatically include the
      # `std` TUI in our environment.
      imports = [ std.std.devshellProfiles.default ];

      packages = [
        nixpkgs.yq-go
        nixpkgs.clojure
        nixpkgs.jdk
        nixpkgs.nodejs
        nixpkgs.clojure-lsp
        nixpkgs.clj-kondo
        nixpkgs.chromium
        nixpkgs.karma
      ];

      commands = [
        # Setup and Dependencies
        {
          name = "setup";
          command = ''
            echo "Installing JavaScript dependencies..."
            npm install
            echo "Installing Clojure dependencies..."
            clj -P
            echo "Setup clj-kondo lints"
            mkdir -p .clj-kondo
            clj-kondo --lint "$(npx shadow-cljs classpath)" --dependencies --parallel --copy-configs
          '';
          help = "Install all project dependencies (npm packages and Clojure libraries)";
          category = "Setup";
        }

        # Development Servers
        {
          name = "dev-frontend";
          command = "npx shadow-cljs server";
          help = "Start the shadow-cljs development server for frontend compilation";
          category = "Development";
        }
        {
          name = "dev-backend";
          command = ''
            JAVA_OPTS="-Dtrace -Dguardrails.enabled=true" clj -M:dev -e "(require 'development) (in-ns 'development) (start)"
          '';
          help = "Start the Clojure backend development server with tracing enabled";
          category = "Development";
        }

        # Testing
        {
          name = "test-all";
          command = ''
            npx shadow-cljs compile ci-tests
            npx karma start --single-run
            clj -M:dev:clj-tests
          '';
          help = "Run all tests (ClojureScript and Clojure)";
          category = "Testing";
        }
        {
          name = "test-cljs";
          command = ''
            npx shadow-cljs compile ci-tests
            npx karma start --single-run
          '';
          help = "Run only the ClojureScript tests";
          category = "Testing";
        }
        {
          name = "test-clj";
          command = "clj -M:dev:clj-tests";
          help = "Run only the Clojure tests";
          category = "Testing";
        }

        # Build and Release
        {
          name = "build";
          command = ''
              npx shadow-cljs release main
              clj -T:build uber
          '';
          help = "Build the production uberjar";
          category = "Build";
        }
        {
          name = "clean";
          command = ''
              rm -rf "$PRJ_ROOT/resources/public/js/main"
              clj -T:build clean
          '';
          help = "Clean build artifacts and temporary files";
          category = "Build";
        }
      ];
    };
}
