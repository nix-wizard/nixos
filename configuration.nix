{
	config,
	lib,
	pkgs,
	...
}:
{
	imports =
	[
		./hardware-configuration.nix
	];

	i18n =
	{
		defaultLocale = "en_US.UTF-8";
	};

	console =
	{
		earlySetup = true;
		packages = with pkgs;
		[
			terminus_font
		];
		font = "${pkgs.terminus_font}/share/consolefonts/ter-u12n.psf.gz";
		useXkbConfig = true;
	};

	time =
	{
		timeZone = "America/Los_Angeles";
	};

	environment =
	{
		systemPackages = with pkgs;
		[
			cryptsetup
			btrfs-progs
			pciutils
		];
		variables =
		{
			EDITOR = "nvim";
		};
	};

	programs =
	{
		neovim =
		{
			enable = true;
			defaultEditor = true;
		};
		git =
		{
			enable = true;
			config =
			{
				init =
				{
					defaultBranch = "main";
				};
			};
		};
	};

	networking =
	{
		hosts =
		{
			"127.0.1.1" =
			[
				"${config.networking.hostName}.lan"
			];
			"10.1.0.1" =
			[
				"server-gateway.lan"
			];
			"10.1.0.2" =
			[
				"server1.lan"
			];
		};
	};

	nix =
	{
		settings =
		{
			experimental-features =
			[
				"nix-command"
				"flakes"
			];
		};
	};
}
