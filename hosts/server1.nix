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
				"xhci_pci"
				"ehci_pci"
				"ahci"
				"nvme"
				"usbhid"
				"usb_storage"
				"sd_mod"
			];
			kernelModules =
			[
				"i915"
				"e1000e"
				"wireguard"
			];
			luks =
			{
				devices =
				{
					cryptroot =
					{
						device = "/dev/nvme0n1p2";
					};
				};
			};
			network =
			{
				ssh =
				{
					enable = true;
					port = 2222;
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
								"10.1.0.2/24"
							];
							routes =
							[
								{
									Gateway = "74.113.97.1";
								}
							];
							linkConfig =
							{
								RequiredForOnline = "no";
							};
						};
					};
				};
			#	services =
			#	{
			#		wireguard-setup =
			#		{
			#			description = "Set up WireGuard interface";
			#			wantedBy =
			#			[
			#				"initrd.target"
			#			];
			#			before =
			#			[
			#				"cryptsetup.target"
			#				"systemd-cryptsetup@cryptserver.service"
			#			];
			#			after =
			#			[
			#				"systemd-networkd.service"
			#			];
			#			path = with pkgs;
			#			[
			#				wireguard-tools
			#				iproute2
			#			];
			#			unitConfig =
			#			{
			#				DefaultDependencies = "no";
			#			};
			#			serviceConfig =
			#			{
			#				Type = "oneshot";
			#			};
			#			script =
			#			''
			#				ip link add dev wg0 type wireguard

			#				wg set wg0 private-key /etc/wireguard/server-gateway-initrd-wireguard-private peer ${builtins.replaceStrings ["\n"] [""] (builtins.readFile ../pubkeys/nixlabs-vps-wireguard-public)} endpoint 74.113.97.90:51820 allowed-ips 172.16.0.0/24 persistent-keepalive 25

			#				ip addr add 172.16.0.3/24 dev wg0
			#				ip link set wg0 up
			#			'';
			#		};
			#		wireguard-cleanup =
			#		{
			#			description = "Tear down the WireGuard interface post-cryptsetup";
			#			wantedBy =
			#			[
			#				"initrd.target"
			#			];
			#			after =
			#			[
			#				"cryptsetup.target"
			#			];
			#			path = with pkgs;
			#			[
			#				iproute2
			#			];
			#			script =
			#			''
			#				ip link delete wg0
			#			'';
			#		};
			#	};
				initrdBin = with pkgs;
				[
					wireguard-tools
					iproute2
				];
			};
			secrets =
			{
			#	"/etc/wireguard/server1-initrd-wireguard-private" = config.age.secrets.server1-initrd-wireguard-private.path;
			};
		};
		kernelModules =
		[
			"kvm_intel"
			"e1000e"
			"wireguard"
		];
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
	};

	swapDevices =
	[
		{
			device = "/dev/nvme0n1p3";
		}
	];
	
	age =
	{
		secrets =
		{
			server1-wireguard-private =
			{
				file = ../secrets/server1-wireguard-private.age;
				owner = "root";
				group = "root";
				mode = "0600";
			};
			server1-initrd-wireguard-private =
			{
				file = ../secrets/server1-initrd-wireguard-private.age;
				owner = "root";
				group = "root";
				mode = "0600";
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
	};

	networking =
	{
		hostName = "server1";
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
							address = "10.1.0.2";
							prefixLength = 24;
						}
					];
				};
			};
		};
		defaultGateway =
		{
			address = "10.1.0.1";
			interface = "enp3s0";
		};
		wireguard =
		{
			interfaces =
			{
			#	wg0 =
			#	{
			#		privateKeyFile = config.age.secrets.server1-private.path;
			#		peers =
			#		[
			#			{
			#				name = "nixlabs-vps";
			#				publicKey = (builtins.readFile ../pubkeys/nixlabs-vps-wireguard-public);
			#				allowedIPs =
			#				[
			#					"172.16.0.0/24"
			#				];
			#				endpoint = "74.113.97.90:51820";
			#				persistentKeepalive = 25;
			#			}
			#		];
			#	};
			#	wg1 =
			#	{
			#		ips =
			#		[
			#			"172.16.1.2/24"
			#		];
			#		privateKeyFile = config.age.secrets.server-gateway-wireguard-private.path;
			#		peers =
			#		[
			#			{
			#				name = "server-gateway";
			#				publicKey = (builtins.readFile ../pubkeys/server-gateway-wireguard-public);
			#				allowedIPs =
			#				[
			#					"172.16.1.0/24"
			#				];
			#			}
			#		];
			#	};
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
					];
					allowedUDPPorts =
					[
					];
				};
				"wg0" =
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
	};

	services =
	{
		openssh =
		{
			enable = true;
			settings =
			{
				PermitRootLogin = "yes";
				PasswordAuthentication = true;
				KbdInteractiveAuthentication = false;
			};
			listenAddresses =
			[
				{
					addr = "0.0.0.0";
					port = 22;
				}
			];
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
				enable = true;
				finegrained = true;
			};
			open = false;
		};
		cpu =
		{
			intel =
			{
				updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
			};
		};
		enableRedistributableFirmware = true;
	};

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
