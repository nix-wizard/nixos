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
			openssl
			gnupg
			busybox
		];
		variables =
		{
			EDITOR = "nvim";
		};
	};

	services =
	{
		openssh =
		{
			openFirewall = false;
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

	systemd =
	{
		services =
		{
			"vconsole-fix" =
			{
				wantedBy =
				[
					"multi-user.target"
				];
				after =
				[
					"systemd-modules-load.service"
				];
				before =
				[
					"getty@tty1.service"
				];
				script =
				''
					/run/current-system/sw/bin/systemctl restart systemd-vconsole-setup.service
				'';
				serviceConfig =
				{
					Type = "oneshot";
				};
			};
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
