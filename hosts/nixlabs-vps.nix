{
	config,
	lib,
	pkgs,
	modulesPath,
	...
}:
let
	main-desktop_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHm3/himFHzpu+B5N9uB7QEafkYrUmXfPatEQgKcSWJ2 main-desktop";
in
{
	boot =
	{
		initrd =
		{
			availableKernelModules =
			[
				"virtio_pci"
				"virtio_blk"
				"virtio_scsi"
				"nvme"
				"sd_mod"
				"sr_mod"
				"ahci"
				"xhci_pci"
				"ehci_pci"
				"usbhid"
				"usb_storage"
				"9p"
				"9pnet_virtio"
			];
			kernelModules =
			[
				"virtio_net"
			];
			luks =
			{
				devices =
				{
					cryptroot =
					{
						device = "/dev/vda2";
					};
				};
			};
			network =
			{
				ssh =
				{
					enable = true;
					hostKeys =
					[
						"/etc/secrets/initrd/ssh_host_rsa_key"
						"/etc/secrets/initrd/ssh_host_ed25519_key"
					];
				};
			};
			systemd =
			{
				enable = true;
				network =
				{
					enable = true;
					networks =
					{
						"50-wan" = config.systemd.network.networks."50-wan";
					};
				};
			};
		};
		kernelModules =
		[
			"kvm_intel"
			"virtio_balloon"
			"virtio_console"
			"virtio_rng"
			"virtio_gpu"
		];
		kernel =
		{
			sysctl =
			{
				"net.ipv4.conf.all.forwarding" = true;
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
			device = "/dev/vda1";
			fsType = "vfat";
			options =
			[
				"fmask=0077"
				"dmask=0077"
			];
		};
	};

	networking =
	{
		hostName = "nixlabs-vps";
		useDHCP = false;
		firewall =
		{
			enable = true;
			interfaces =
			{
				"enp3s0" =
				{
					allowedTCPPorts =
					[
						22
						2222
					];
					allowedUDPPorts =
					[
					];
				};
			};
		};
	};

	systemd =
	{
		network =
		{
			enable = true;
			networks =
			{
				"50-wan"=
				{
					matchConfig =
					{
						Name = "enp3s0";
					};
					networkConfig =
					{
						DHCP = "no";
					};
					address =
					[
						"74.113.97.90/24"
					];
					routes =
					[
						{
							Gateway = "74.113.97.1";
						}
					];
					linkConfig =
					{
						RequiredForOnline = "yes";
					};
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
						keys =
						[
							main-desktop_pubkey
						];
					};
				};
			};
		};
	};

	services =
	{
		openssh =
		{
			enable = true;
			settings =
			{
				PermitRootLogin = "yes";
				PasswordAuthentication = false;
				KbdInteractiveAuthentication = false;
			};
			listenAddresses =
			[
				{
					addr = "0.0.0.0";
					port = 2222;
				}
			];
		};
		endlessh =
		{
			enable = true;
			port = 22;
		};
	};

	swapDevices =
	[
		{
			device = "/dev/vda3";
		}
	];
	
	environment =
	{
		systemPackages = with pkgs;
		[
		];
	};

	nixpkgs =
	{
		hostPlatform = lib.mkDefault "x86_64-linux";
	};

	system =
	{
		stateVersion = "25.05";
	};
}
