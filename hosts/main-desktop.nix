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
			"kvm-amd"
		];
		initrd =
		{
			kernelModules =
			[
				"uas"
				"usbcore"
				"usb_storage"
				"vfat"
				"nls_cp437"
				"nls_iso8859_1"
				"nvidia"
				"dm-snapshot"
			];
			availableKernelModules =
			[
				"nvme"
				"xhci_pci"
				"ahci"
				"usb_storage"
				"usbhid"
				"uas"
				"sd_mod"
				"sr_mod"
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
						device = "/dev/nvme0n1p3";
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
		nvidia =
		{
			modesetting =
			{
				enable = true;
			};
			powerManagement =
			{
				enable = false;
				finegrained = false;
			};
			open = true;
			nvidiaSettings = true;
		};
		cpu =
		{
			amd =
			{
				updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
			};
		};
	};
	
	swapDevices =
	[
		{
			device = "/dev/vol/swap";
		}
	];
	
	networking =
	{
		hostName = "main-desktop";
		enableIPv6 = false;
		useDHCP = false;
		defaultGateway =
		{
			address = "10.0.0.1";
			interface = "enp38s0";
		};
		firewall =
		{
			enable = true;
			interfaces =
			{
				"enp38s0" =
				{
					allowedTCPPorts =
					[
						22
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
			enp38s0 =
			{
				ipv4 =
				{
					addresses =
					[
						{
							address = "10.0.0.2";
							prefixLength = 24;
						}
					];
				};
			};
		};
		nameservers =
		[
			"10.0.0.1"
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
		keyd =
		{
			enable = true;
			keyboards =
			{
				default =
				{
					ids =
					[
						"*"
					];
					settings =
					{
						main =
						{
							rightalt = "layer(meta)";
						};
					};
				};
			};
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
				"nvidia"
			];
			windowManager =
			{
				fvwm3 =
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
	};

	fileSystems =
	{
		"/" =
		{
			device = "/dev/vol/root";
			fsType = "ext4";
		};
		"/boot" =
		{
			device = "/dev/nvme0n1p1";
			fsType = "vfat";
			options =
			[
				"fmask=0077"
				"dmask=0077"
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
					"input"
				];
			};
		};
	};

	environment =
	{
		systemPackages = with pkgs;
		[
			exfatprogs
		];
	};

	time =
	{
		timeZone = "America/Los_Angeles";
	};

	nixpkgs =
	{
		config =
		{
			packageOverrides = pkgs:
			{
				nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/main.tar.gz")
				{
					inherit pkgs;
				};
			};
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

	system =
	{
		stateVersion = "24.11";
	};
}
