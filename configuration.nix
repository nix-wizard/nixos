{
	config,
	lib,
	pkgs,
	...
}:
{
	imports =
	[
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
			net-tools
			wireguard-tools
			dos2unix
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
				user =
				{
					name = "nixwiz";
					email = "nixwiz@nixwiz.one";
				};
			};
		};
	};

	users =
	{
		users =
		{
			"root" =
			{
				openssh =
				{
					authorizedKeys =
					{
						keyFiles =
						[
							./pubkeys/nixwiz.pub
						];
					};
				};
			};
		};
	};

	networking =
	{
		nameservers =
		[
			"9.9.9.9"
			"1.1.1.1"
		];
	};

	system =
	{
		autoUpgrade =
		{
			enable = true;
			flake = "/etc/nixos";
			flags =
			[
				"-L"
			];
			dates = "02:00";
			randomizedDelaySec = "45min";
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
