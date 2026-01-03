{
	config,
	lib,
	pkgs,
	...
}:
{
	boot =
	{
		loader =
		{
			efi =
			{
				canTouchEfiVariables = true;
			};
			grub =
			{
				enable = true;
				device = "nodev";
				efiSupport = true;
				gfxmodeEfi = "1920x1080";
			};
		};
		kernelModules =
		[
			"unput"
			"iwlwifi-7260-17"
		];
		initrd =
		{
			kernelModules =
			[
				"uas"
				"usbcore"
				"usb_storage"
				"vfat"
				"dm-snapshot"
			];
			availableKernelModules =
			[
				"xhci_pci"
				"ehci_pci"
				"ahci"
				"firewire_ohci"
				"usb_storage"
				"usbhid"
				"uas"
				"sd_mod"
				"sr_mod"
				"sdhci_pci"
			];
			systemd =
			{
				enable = true;
			};
			luks =
			{
				devices =
				{
					cryptroot =
					{
						device = "/dev/sda2";
					};
				};
			};
		};
	};

	hardware =
	{
		graphics =
		{
			enable = true;
		};
		opentabletdriver =
		{
			enable = true;
			daemon =
			{
				enable = true;
			};
		};
		uinput =
		{
			enable = true;
		};
		cpu =
		{
			intel =
			{
				updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
			};
		};
	};

	age =
	{
		secrets =
		{
			thinkpad-t530-wireguard-private =
			{
				file = ../secrets/thinkpad-t530-wireguard-private.age;
				owner = "root";
				group = "root";
				mode = "0600";
			};
		};
	};
	
	networking =
	{
		hostName = "thinkpad-t530";
		enableIPv6 = false;
		useDHCP = false;
		firewall =
		{
			enable = true;
			interfaces =
			{
				"enp0s25" =
				{
					allowedTCPPorts =
					[
					];
					allowedUDPPorts =
					[
					];
				};
				"wlp3s0" =
				{
					allowedTCPPorts =
					[
					];
					allowedUDPPorts =
					[
					];
				};
			};
			allowPing = true;
		};
		interfaces =
		{
			enp0s25 =
			{
				useDHCP = true;
			};
		};
		wg-quick =
		{
			interfaces =
			{
				wg0 =
				{
					privateKeyFile = config.age.secrets.thinkpad-t530-wireguard-private.path;
					address =
					[
						"172.16.0.6/24"
					];
					peers =
					[
						{
							publicKey = (builtins.readFile ../pubkeys/racknerd-vps-wireguard-public);
							allowedIPs =
							[
								"172.16.0.0/24"
							];
							endpoint = "107.174.108.42:51820";
							persistentKeepalive = 25;
						}
					];
				};
				wg1 =
				{
					privateKeyFile = config.age.secrets.thinkpad-t530-wireguard-private.path;
					address =
					[
						"172.16.1.6/24"
					];
					peers =
					[
						{
							publicKey = (builtins.readFile ../pubkeys/server-gateway-wireguard-public);
							allowedIPs =
							[
								"172.16.1.0/24"
							];
							endpoint = "172.16.0.2:51820";
							persistentKeepalive = 25;
						}
					];
				};
			};
		};
		nameservers =
		[
			"172.16.1.1"
		];
	};
  	
	services =
	{
		dbus =
		{
			enable = true;
		};
		libinput =
		{
			enable = true;
		};
		openssh =
		{
			enable = true;
		};
		udisks2 =
		{
			enable = true;
		};
		pipewire =
		{
			enable = true;
			pulse =
			{
				enable = true;
			};
		};
		xserver =
		{
			enable = true;
			videoDrivers =
			[
				"intel"
			];
			windowManager =
			{
				dwm =
				{
					enable = true;
				};
			};
			displayManager =
			{
				startx =
				{
					enable = true;
				};
			};
		};
		automatic-timezoned =
		{
			enable = true;
		};
	};

	fileSystems =
	{
		"/" =
		{
			device = "/dev/mapper/cryptroot";
			fsType = "ext4";
		};
		"/boot" =
		{
			device = "/dev/sda1";
			fsType = "vfat";
			options =
			[
				"fmask=0077"
				"dmask=0077"
			];
		};
		"/srv/share" =
		{
			device = "server-gateway.server-gateway:/srv/share";
			fsType = "nfs";
			options =
			[
				"_netdev"
				"x-systemd.requires=wg-quick-wg0.service"
				"x-systemd.requires=wg-quick-wg1.service"
			];
		};
	};

	i18n =
	{
		defaultLocale = "en_US.UTF-8";
	};

	users =
	{
		users =
		{
			nixwiz =
			{
				isNormalUser = true;
				extraGroups =
				[
					"wheel"
					"tty"
					"video"
					"share"
					"input"
					"networkmanager"
				];
			};
		};
		groups =
		{
			share =
			{
				members =
				[
					"nixwiz"
				];
			};
		};
	};

	environment =
	{
		systemPackages = with pkgs;
		[
		];
	};

	nixpkgs =
	{
		config =
		{
			allowUnfree = true;
		};
		hostPlatform = lib.mkDefault "x86_64-linux";
	};

	programs =
	{
		mtr =
		{
			enable = true;
		};
		dconf =
		{
			enable = true;
		};
		gnupg =
		{
			agent =
			{
				enable = true;
				enableSSHSupport = true;
			};
		};
	};

	systemd =
	{
		tmpfiles =
		{
			rules =
			[
				"d /srv/share 0775 root share - -"
			];
		};
	};

	system =
	{
		stateVersion = "25.11";
	};
}
