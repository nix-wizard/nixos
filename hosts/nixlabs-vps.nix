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
				"xhci_pci"
				"ehci_pci"
				"ahci"
				"nvme"
				"usbhid"
				"usb_storage"
				"sd_mod"
				"virtio_pci"
				"virtio_scsi"
				"sr_mod"
				"virtio_blk"
				"virtio_net"
				"virtio_mmio"
				"9p"
				"9pnet_virtio"
			];
			kernelModules =
			[
				"virtio_pci"
				"virtio_net"
				"virtio_balloon"
				"virtio_console"
				"virtio_rng"
				"virtio_gpu"
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
				#ssh =
				#{
				#	enable = true;
				#	hostKeys =
				#	[
				#		"/etc/secrets/initrd/ssh_host_rsa_key"
				#		"/etc/secrets/initrd/ssh_host_ed25519_key"
				#	];
				#};
			};
			systemd =
			{
				enable = true;
				network =
				{
					enable = true;
					networks =
					{
						"50-wan" =
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
								"74.113.94.90/24"
							];
							routes =
							[
								{
									Gateway = "74.113.94.1";
								}
							];
							linkConfig =
							{
								RequiredForOnline = "no";
							};
						};
					};
				};
			};
		};
		kernelModules =
		[
			"kvm_intel"
			"virtio_pci"
			"virtio_net"
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
			p3s0
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
						};
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
		};
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
