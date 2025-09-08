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
				"wireguard"
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
				services =
				{
					wireguard-setup =
					{
						wantedBy =
						[
							"initrd.target"
						];
						after =
						[
							"network-online.target"
						];
						wants =
						[
							"network-online.target"
						];
						path = with pkgs;
						[
							wireguard-tools
							iproute2
						];
						serviceConfig =
						{
							Type = "oneshot";
							ExecStart = pkgs.writeShellScript "setup-wireguard"
							''
								set -eux

								echo "[initrd] Waiting for network interface 'eno1' to be ready..."

								while ! ip route | grep -q '^default'; do
									sleep 1
								done

								echo "[initrd] Setting up route to WireGuard endpoint..."

								ip route add 74.113.97.96/32 via 192.168.0.1 dev eno1

								echo "[initrd] Setting up WireGuard interface..."

								ip link add dev wg0 type wireguard
								ip addr add 172.16.0.3/24 dev wg0

								wg set wg0 \
									private-key /etc/wireguard/server-gateway-initrd-wireguard-private \
									peer $(cat /etc/wireguard/nixlabs-vps-wireguard-public) \
									endpoint 74.113.97.95 \
									allowed-ips 0.0.0.0/0 \
									persistent-keepalive 25
								ip link set wg0 up

								echo "[initrd] WireGuard setup complete."
							'';
						};
					};
				};
				packages = with pkgs;
				[
					wireguard-tools
					iproute2
				];
			};
			extraFiles =
			{
				"/etc/wireguard/nixlabs-vps-wireguard-public" =
				{
					source = ../pubkeys/nixlabs-vps-wireguard-public;
				};
			};
			secrets =
			{
				"/etc/wireguard/server-gateway-initrd-wireguard-private" = config.age.secrets.server-gateway-initrd-wireguard-private.path;
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
				mode = "0600";
			};
			server-gateway-initrd-wireguard-private =
			{
				file = ../secrets/server-gateway-initrd-wireguard-private.age;
				owner = "root";
				group = "root";
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
				wg1 =
				{
					ips =
					[
						"172.16.1.1/24"
					];
					listenPort = 51820;
					privateKeyFile = config.age.secrets.server-gateway-wireguard-private.path;
					#peers =
					#[
						#{
							#name = "server1";
							#publicKey = (builtins.readFile ../pubkeys/server1-wireguard-public);
							#allowedIPs =
							#[
							#	"172.16.1.2/32"
							#];
						#}
					#];
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
						22
					];
					allowedUDPPorts =
					[
					];
				};
				"enp1s0" =
				{
					allowedTCPPorts =
					[
					];
					allowedUDPPorts =
					[
						51820
					];
				};
				"wg0" =
				{
					allowedTCPPorts =
					[
						22
						80
						443
						2049
					];
					allowedUDPPorts =
					[
						2049
					];
				};
			};
			allowPing = true;
			#extraCommands =
			#''
			#	iptables -t nat -A POSTROUTING -o wg0 -s 10.1.0.0/24 -j MASQUERADE
			#'';
		};
		nat =
		{
			enable = true;
			externalInterface = "eno1";
			internalInterfaces =
			[
				"wg0"
			];
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
		nfs =
		{
			server =
			{
				enable = true;
				exports =
				''
					/srv/share 172.16.0.4(rw,sync,no_subtree_check,no_root_squash) 172.16.1.2(rw,sync,no_subtree_check,no_root_squash)
					/srv/server 172.16.1.2(rw,sync,no_subtree_check,no_root_squash)
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
