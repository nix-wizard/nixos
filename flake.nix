{
	description = "nix flake";

	inputs =
	{
		nixpkgs =
		{
			url = "github:nixos/nixpkgs?ref=nixos-unstable";
		};
		flake-utils =
		{
			url = "github:numtide/flake-utils";
		};
		copyparty =
		{
			url = "github:9001/copyparty";
		};
		agenix =
		{
			url = "github:ryantm/agenix";
		};
	};

	outputs =
	{
		self,
		nixpkgs,
		flake-utils,
		copyparty,
		agenix
	}:
	{
		nixosConfigurations =
		{
			server-gateway = nixpkgs.lib.nixosSystem
			{
				system = "x86_64-linux";
				modules =
				[
					./configuration.nix
					./hosts/server-gateway.nix
					copyparty.nixosModules.default
					agenix.nixosModules.default
					(
						{
							pkgs,
							...
						}:
						{
							nixpkgs =
							{
								overlays =
								[
									copyparty.overlays.default
								];
							};
							environment =
							{
								systemPackages =
								[
									agenix.packages.x86_64-linux.default
								];
							};
						}
					)
				];
			};
		};
	};
}
