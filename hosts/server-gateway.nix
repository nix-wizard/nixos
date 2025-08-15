{
	config,
	lib,
	pkgs,
	...
}:
let
	main-desktop_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHm3/himFHzpu+B5N9uB7QEafkYrUmXfPatEQgKcSWJ2 main-desktop";
in
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
			};
		};
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
								Name = "enp5s0";
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
			"r8169"
		];
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
			copyparty-nixwiz-password =
			{
				file = ../secrets/copyparty-nixwiz-password.age;
				owner = "copyparty";
				group = "copyparty";
				mode = "0600";
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
	};

	networking =
	{
		hostName = "server-gateway";
		useDHCP = false;
		firewall =
		{
			enable = true;
			interfaces =
			{
				"enp5s0" =
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
				"enp2s0" =
				{
					allowedTCPPorts =
					[
						2222
					];
					allowedUDPPorts =
					[
					];
				};
			};
		};
		nat =
		{
			enable = true;
			externalInterface = "enp5s0";
			internalInterfaces =
			[
				"enp2s0"
			];
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
						Name = "enp5s0";
					};
					networkConfig =
					{
						DHCP = "ipv4";
					};
					linkConfig =
					{
						RequiredForOnline = "yes";
					};
				};
				"50-lan" =
				{
					matchConfig =
					{
						Name = "enp2s0";
					};
					networkConfig =
					{
						DHCP = "no";
					};
					linkConfig =
					{
						RequiredForOnline = "no";
					};
					address =
					[
						"10.1.0.1"
					];
				};
			};
		};
		tmpfiles =
		{
			rules =
			[
				"d /srv/share 0755 root root -"
				"d /srv/server 0755 root root -"
			];
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
		copyparty =
		{
			enable = true;
			settings =
			{
				i = "0.0.0.0";
			};
			accounts =
			{
				nixwiz =
				{
					passwordFile = config.age.secrets.copyparty-nixwiz-password.path;
				};
			};
			volumes =
			{
				"/" =
				{
					path = "/srv/share";
					access =
					{
						rw =
						[
							"nixwiz"
						];
					};
				};
			};
		};
		nfs =
		{
			server =
			{
				enable = true;
				exports =
				''
					/srv/server 127.0.0.1(rw,sync,no_root_squash,no_subtree_check)
				'';
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
		enableRedistributableFirmware = true;
	};

	environment =
	{
		systemPackages = with pkgs;
		[
			copyparty
		];
	};

	system =
	{
		stateVersion = "25.05";
	};
}
