{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);      
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = import inputs.nixpkgs {
              config.allowUnfree = true;
              config.cudaSupport = true;
              inherit system;
            };
            # pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  # https://devenv.sh/reference/options/
                  packages = [ 
                    pkgs.cudatoolkit
                    pkgs.portaudio
                    pkgs.uv
                    (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
                      # select Python packages here
                      (accelerate.override { 
                        config.doCheck = false; 
                        config.cudaSupport = true;
                      })
                      diffusers
                      jupyter-all
                      jupyter-server
                      jupyter-server-mathjax
                      ipykernel
                      ipywidgets
                      pandas
                      pip
                      pyaudio
                      requests
                      torch
                      torchaudio
                      torchvision
                      transformers
                      virtualenv
                    ]))
                  ];

                  enterShell = ''
                    python -c 'import torch; print(f"Cuda Enabled: {torch.cuda.is_available()}")'
                  '';
                }
              ];
            };
          });
    };
}
