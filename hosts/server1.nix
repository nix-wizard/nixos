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
				"r8169"
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
			};
		};
		kernelModules =
		[
			"kvm_intel"
			"r8169"
		];
		supportedFilesystems =
		[
			"nfs"
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
		"/srv/share" =
		{
			device = "172.16.1.1:/srv/share";
			fsType = "nfs";
		};
		"/srv/server" =
		{
			device = "172.16.1.1:/srv/server";
			fsType = "nfs";
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
				wg1 =
				{
					ips =
					[
						"172.16.1.2/24"
					];
					privateKeyFile = config.age.secrets.server1-wireguard-private.path;
					peers =
					[
						{
							name = "server-gateway";
							publicKey = (builtins.readFile ../pubkeys/server-gateway-wireguard-public);
							allowedIPs =
							[
								"172.16.1.0/24"
							];
							endpoint = "10.1.0.1:51820";
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
				"enp3s0" =
				{
					allowedTCPPorts =
					[
						22
					];
					allowedUDPPorts =
					[
					];
				};
				"wg1" =
				{
					allowedTCPPorts =
					[
						8001
					];
					allowedUDPPorts =
					[
					];
				};
			};
			allowPing = true;
		};
	};

	systemd =
	{
		tmpfiles =
		{
			rules =
			[
				"d /srv/share 0777 root root -"
				"d /srv/server 0777 root root -"
			];
		};
		services =
		{
			snac =
			{
				description = "Start snac2 service";
				wantedBy =
				[
					"multi-user.target"
				];
				after =
				[
					"network.target"
				];
				serviceConfig =
				{
					ExecStart = "${pkgs.snac2}/bin/snac httpd /srv/server/server1/home/snacusr/snac-data";
					User = "snacusr";
					WorkingDirectory = "/srv/server/server1/home/snacusr/snac-data";
					Restart = "always";
					Environment = "DEBUG=1";
					StandardOutput = "journal";
					StandardError = "journal";
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
					port = 22;
				}
			];
		};
	};

	users =
	{
		users =
		{
			root =
			{
				openssh =
				{
					authorizedKeys =
					{
						keyFiles =
						[
							../pubkeys/server-gateway-root-ssh.pub
						];
					};
				};
			};
			snacusr =
			{
				isNormalUser = true;
				home = "/srv/server/server1/home/snacusr";
				description = "snac2 user";
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
			snac2
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
