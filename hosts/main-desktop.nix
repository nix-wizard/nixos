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
			"unput"
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

	age =
	{
		secrets =
		{
			main-desktop-wireguard-private =
			{
				file = ../secrets/main-desktop-wireguard-private.age;
				owner = "root";
				group = "root";
				mode = "0600";
			};
		};
	};
	
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
		wg-quick =
		{
			interfaces =
			{
				wg0 =
				{
					privateKeyFile = config.age.secrets.main-desktop-wireguard-private.path;
					address =
					[
						"172.16.0.4/24"
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
					privateKeyFile = config.age.secrets.main-desktop-wireguard-private.path;
					address =
					[
						"172.16.1.4/24"
					];
					peers =
					[
						{
							publicKey = (builtins.readFile ../pubkeys/server-gateway-wireguard-public);
							allowedIPs =
							[
								"172.16.1.0/24"
							];
							endpoint = "192.168.0.152:51820"; # it took a lot of restraint to route here through my lan rather than across the width of the united states and back. the latter might be slightly more acceptable now because wg0's endpoint is somewhat geographically close to me now rather than in fucking tennessee
							# who am i writing these comments for nobody looks at this. this is going on a private repo soon anyways
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
			device = "/dev/nvme0n1p1";
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
					"input"
				];
			};
		};
		groups =
		{
			ssd =
			{
				members =
				[
					"nixwiz"
				];
			};
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
