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
			];
			luks =
			{
				devices =
				{
					cryptroot =
					{
						device = "/dev/nvme0n1p2";
					};
					cryptshare =
					{
						device = "/dev/sda";
					};
					cryptserver =
					{
						device = "/dev/sdb";
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
								Name = "eno1";
							};
							networkConfig =
							{
								DHCP = "ipv4";
							};
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
			"coretemp"
			"nct6775"
			"kvm_intel"
			"e1000e"
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
		kernel =
		{
			sysctl =
			{
				"net.ipv4.conf.all.forwarding" = true;
			};
		};
	};
	
	age =
	{
		secrets =
		{
			server-gateway-wireguard-private =
			{
				file = ../secrets/server-gateway-wireguard-private.age;
				owner = "root";
				group = "root";
				"mode" = "0600";
			};
		};
	};

	fileSystems =
	{
		"/srv/share" =
		{
			device = "/dev/mapper/cryptshare";
			fsType = "btrfs";
			options =
			[
				"compress=zstd"
				"noatime"
			];
		};
		"/srv/server" =
		{
			device = "/dev/mapper/cryptserver";
			fsType = "btrfs";
			options =
			[
				"compress=zstd"
				"noatime"
			];
		};
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
		hostName = "server-gateway";
		useDHCP = false;
		interfaces =
		{
			eno1 =
			{
				useDHCP = true;
				ipv4 =
				{
					routes =
					[
						{
							address = "74.113.97.95";
							prefixLength = 32;
							via = "192.168.0.1";
						}
					];
				};
			};
			enp1s0 =
			{
				ipv4 =
				{
					addresses =
					[
						{
							address = "10.1.0.1";
							prefixLength = 24;
						}
					];
				};
			};
			wg0 =
			{
				ipv4 =
				{
					addresses =
					[
						{
							address = "172.16.0.2";
							prefixLength = 24;
						}
					];
				};
			};
		};
		wireguard =
		{
			interfaces =
			{
				wg0 =
				{
					privateKeyFile = config.age.secrets.server-gateway-wireguard-private.path;
					peers =
					[
						{
							publicKey = (builtins.readFile ../pubkeys/nixlabs-vps-wireguard-public);
							allowedIPs =
							[
								"0.0.0.0/0"
							];
							endpoint = "74.113.97.95:51820";
							persistentKeepalive = 25;
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
				"eno1" =
				{
					allowedTCPPorts =
					[
						2222
					];
					allowedUDPPorts =
					[
					];
				};
				"enp1s0" =
				{
					allowedTCPPorts =
					[
						2222
					];
					allowedUDPPorts =
					[
					];
				};
				"wg0" =
				{
					allowedTCPPorts =
					[
						22
						2222
						80
						443
						111
						2049
						4000
						4001
						4002
						20048
					];
					allowedUDPPorts =
					[
						111
						2049
						4000
						4001
						4002
						20048
					];
				};
			};
			allowPing = true;
		};
		nat =
		{
			enable = true;
			externalInterface = "eno1";
			internalInterfaces =
			[
				"enp1s0"
			];
		};
	};

	systemd =
	{
		tmpfiles =
		{
			rules =
			[
				"d /srv/share 2770 root root -"
				"d /srv/server 2770 root root -"
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
		nfs =
		{
			server =
			{
				enable = true;
				lockdPort = 4001;
				mountdPort = 4002;
				statdPort = 4000;
				exports =
				''
					/srv 172.16.0.3(rw,fsid=0,no_subtree_check)
					/srv/share 172.16.0.3(rw,nohide,insecure,no_subtree_check)
				'';
			};
		};
		nginx =
		{
			enable = true;
			recommendedProxySettings = true;
			recommendedTlsSettings = true;
			virtualHosts =
			{
				"_default" =
				{
					default = true;
					locations =
					{
						"/" =
						{
							return = "404";
						};
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
			extraPackages = with pkgs;
			[
				intel-media-driver
				libvdpau-va-gl
			];
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

	security =
	{
		acme =
		{
			acceptTerms = true;
			defaults =
			{
				email = "nixwiz@nixwiz.one";
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
		hostPlatform = lib.mkDefault "x86_64-linux";
	};

	system =
	{
		stateVersion = "25.05";
	};
}
