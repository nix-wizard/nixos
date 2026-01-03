{
	description = "nixwiz sysnix";

	inputs =
	{
		nixpkgs =
		{
			url = "github:nixos/nixpkgs?ref=nixos-unstable";
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
					./common.nix
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
					./common.nix
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
			server1 = nixpkgs.lib.nixosSystem
			{
				system = "x86_64-linux";
				modules =
				[
					./common.nix
					./hosts/server1.nix
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
			main-desktop = nixpkgs.lib.nixosSystem
			{
				system = "x86_64-linux";
				modules =
				[
					./common.nix
					./hosts/main-desktop.nix
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
