{
	config,
	lib,
	pkgs,
	modulesPath,
	...
}:
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
		};
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

	age =
	{
		secrets =
		{
			nixlabs-vps-wireguard-private =
			{
				file = ../secrets/nixlabs-vps-wireguard-private.age;
				owner = "root";
				group = "root";
				mode = "0600";
			};
		};
	};

	networking =
	{
		hostName = "nixlabs-vps";
		useDHCP = false;
		interfaces =
		{
			enp3s0 =
			{
				ipv4 =
				{
					addresses =
					[
						{
							address = "74.113.97.90";
							prefixLength = 24;
						}
					];
				};
			};
		};
		defaultGateway =
		{
			address = "74.113.97.1";
			interface = "enp3s0";
		};
		wireguard =
		{
			interfaces =
			{
				wg0 =
				{
					ips =
					[
						"192.168.1.1/24"
					];
					listenPort = 51820;
					postSetup =
					''
						${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o enp3s0 -j MASQUERADE
					'';
					postShutdown =
					''
						${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.1.0/24 -o enp3s0 -j MASQUERADE
					'';

					privateKeyFile = config.age.secrets.nixlabs-vps-wireguard-private.path;
					peers =
					[
						{
							name = "server-gateway";
							publicKey = (builtins.readFile ../pubkeys/server-gateway-wireguard-public);
							allowedIPs =
							[
								"192.168.1.2/32"
							];
						}
					];
				};
			};
		};
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
						51820
					];
				};
			};
		};
		nat =
		{
			enable = true;
			externalInterface = "enp3s0";
			internalInterfaces =
			[
				"wg0"
			];
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
