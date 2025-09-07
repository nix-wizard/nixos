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
					agenix.nixosModules.default
					(
						{
							pkgs,
							...
						}:
						{
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
			nixlabs-vps = nixpkgs.lib.nixosSystem
			{
				system = "x86_64-linux";
				modules =
				[
					./configuration.nix
					./hosts/nixlabs-vps.nix
					agenix.nixosModules.default
					(
						{
							pkgs,
							...
						}:
						{
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
