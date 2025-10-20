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
				services =
				{
					wireguard-setup =
					{
						description = "Set up WireGuard interface";
						wantedBy =
						[
							"initrd.target"
						];
						before =
						[
							"cryptsetup.target"
							"systemd-cryptsetup@cryptserver.service"
						];
						after =
						[
							"systemd-networkd.service"
						];
						path = with pkgs;
						[
							wireguard-tools
							iproute2
						];
						unitConfig =
						{
							DefaultDependencies = "no";
						};
						serviceConfig =
						{
							Type = "oneshot";
						};
						script =
						''
							ip link add dev wg1 type wireguard

							wg set wg1 private-key /etc/wireguard/server1-initrd-wireguard-private peer ${builtins.replaceStrings ["\n"] [""] (builtins.readFile ../pubkeys/server-gateway-wireguard-public)} endpoint 10.1.0.1:51820 allowed-ips 172.16.1.0/24 persistent-keepalive 25

							ip addr add 172.16.1.3/24 dev wg1
							ip link set wg1 up
						'';
					};
					wireguard-cleanup =
					{
						description = "Tear down the WireGuard interface post-cryptsetup";
						wantedBy =
						[
							"initrd.target"
						];
						after =
						[
							"cryptsetup.target"
						];
						path = with pkgs;
						[
							iproute2
						];
						script =
						''
							ip link delete wg1
						'';
					};
				};
				initrdBin = with pkgs;
				[
					wireguard-tools
					iproute2
				];
			};
			secrets =
			{
				"/etc/wireguard/server1-initrd-wireguard-private" = config.age.secrets.server1-initrd-wireguard-private.path;
			};
		};
		kernelModules =
		[
			"kvm_intel"
			"r8169"
			"wireguard"
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
		kernel =
		{
			sysctl =
			{
				"net.ipv4.conf.all.forwarding" = true;
			};
		};
	};

	time =
	{
		timeZone = "America/Los_Angeles";
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
			device = "server-gateway.server-gateway:/srv/share";
			fsType = "nfs";
			options =
			[
				"_netdev"
				"x-systemd.requires=wireguard-wg1-peer-server-gateway.service"
			];
		};
		"/srv/server" =
		{
			device = "server-gateway.server-gateway:/srv/server/servers/server1";
			fsType = "nfs";
			options =
			[
				"_netdev"
				"x-systemd.requires=wireguard-wg1-peer-server-gateway.service"
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
			br0 =
			{
				ipv4 =
				{
					addresses =
					[
						{
							address = "10.1.2.1";
							prefixLength = 24;
						}
					];
				};
				useDHCP = false;
			};

		};
		bridges =
		{
			br0 =
			{
				interfaces =
				[
				];
			};
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
								"0.0.0.0/0"
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
					];
					allowedUDPPorts =
					[
					];
				};
				"wg1" =
				{
					allowedTCPPorts =
					[
						22
						8001
					];
					allowedUDPPorts =
					[
					];
				};
				"br0" =
				{
					allowedTCPPorts =
					[
						53
					];
					allowedUDPPorts =
					[
						53
					];
				};
			};
			allowPing = true;
		};
		nat =
		{
			enable = true;
			internalInterfaces =
			[
				"br0"
			];
			externalInterface = "wg1";
			enableIPv6 = false;
			forwardPorts =
			[
				{
					sourcePort = 8002;
					proto = "tcp";
					destination = "10.1.2.2:8080";
				}
				{
					sourcePort = 8003;
					proto = "tcp";
					destination = "10.1.2.3:8080";
				}
				{
					sourcePort = 2222;
					proto = "tcp";
					destination = "10.1.2.4:22";
				}
				{
					sourcePort = 8005;
					proto = "tcp";
					destination = "10.1.2.5:80";
				}
			];
		};
	};

	containers =
	{
		snac =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.2";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/snac/";
					isReadOnly = false;
				};
			};
			config =
			{
				config,
				pkgs,
				lib,
				...
			}:
			{
				networking =
				{
					defaultGateway =
					{
						address = "10.1.2.1";
						interface = "eth0";
					};
					nameservers =
					[
						"10.1.2.1"
					];
					firewall =
					{
						enable = true;
						allowPing = true;
						allowedTCPPorts =
						[
							8080
						];
						allowedUDPPorts =
						[
						];
					};
					useHostResolvConf = lib.mkForce false;
				};

				users =
				{
					users =
					{
						snac =
						{
							description = "snac2 user";
							isNormalUser = true;
							home = "/home/snac";
						};
					};
				};

				systemd =
				{
					services =
					{
						snac =
						{
							description = "snac2 ActivityPub instance";
							wantedBy =
							[
								"multi-user.target"
							];
							after =
							[
								"network-online.target"
							];
							requires =
							[
								"network-online.target"
							];
							serviceConfig =
							{
								ExecStart = "${pkgs.snac2}/bin/snac httpd /home/snac/snacdata";
								User = "snac";
								WorkingDirectory = "/home/snac/snacdata";
								Restart = "always";
								Environment = "DEBUG=1";
								StandardOutput = "journal";
								StandardError = "journal";
							};
						};
					};
				};

				environment =
				{
					systemPackages = with pkgs;
					[
						snac2
					];
				};

				system =
				{
					stateVersion = "25.11";
				};
			};
		};
		vaultwarden =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.3";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/vaultwarden/";
					isReadOnly = false;
				};
			};
			config =
			{
				config,
				pkgs,
				lib,
				...
			}:
			{
				networking =
				{
					defaultGateway =
					{
						address = "10.1.2.1";
						interface = "eth0";
					};
					nameservers =
					[
						"10.1.2.1"
					];
					firewall =
					{
						enable = true;
						allowPing = true;
						allowedTCPPorts =
						[
							8080
						];
						allowedUDPPorts =
						[
						];
					};
					useHostResolvConf = lib.mkForce false;
				};

				services =
				{
					resolved =
					{
						enable = true;
					};
					vaultwarden =
					{
						enable = true;
						config =
						{
							DOMAIN = "https://vault.nixwiz.one";
							SIGNUPS_ALLOWED = false;
							ROCKET_ADDRESS = "0.0.0.0";
							ROCKET_PORT = 8080;
							ROCKET_LOG = "critical";
						};
					};
				};

				system =
				{
					stateVersion = "25.11";
				};
			};
		};
		git =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.4";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/git";
					isReadOnly = false;
				};
			};
			config =
			{
				config,
				pkgs,
				libs,
				...
			}:
			{
				networking =
				{
					defaultGateway =
					{
						address = "10.1.2.1";
						interface = "eth0";
					};
					nameservers =
					[
						"10.1.2.1"
					];
					firewall =
					{
						enable = true;
						allowPing = true;
						allowedTCPPorts =
						[
							22
						];
						allowedUDPPorts =
						[
						];
					};
					useHostResolvConf = lib.mkForce false;
				};

				services =
				{
					resolved =
					{
						enable = true;
					};
					openssh =
					{
						enable = true;
						settings =
						{
							PasswordAuthentication = false;
							KbdInteractiveAuthentication = false;
						};
					};
					gitolite =
					{
						enable = true;
						user = "git";
						adminPubkey = (builtins.readFile ../pubkeys/nixwiz.pub);
					};
				};
				
				system =
				{
					stateVersion = "25.11";
				};
			};
		};
		freepenis =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.5";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/freepenis";
					isReadOnly = false;
				};
			};
			config =
			{
				config,
				pkgs,
				libs,
				...
			}:
			{
				networking =
				{
					defaultGateway =
					{
						address = "10.1.2.1";
						interface = "eth0";
					};
					nameservers =
					[
						"10.1.2.1"
					];
					firewall =
					{
						enable = true;
						allowPing = true;
						allowedTCPPorts =
						[
							80
						];
						allowedUDPPorts =
						[
						];
					};
					useHostResolvConf = lib.mkForce false;
				};

				services =
				{
					resolved =
					{
						enable = true;
					};
					nginx =
					{
						enable = true;
						virtualHosts =
						{
							"freepenis.nixlabs.dev" =
							{
								root = "/var/www/freepenis.nixlabs.dev";
							};
						};
					};
				};

				system =
				{
					stateVersion = "25.11";
				};
			};
		};
	};

	systemd =
	{
		tmpfiles =
		{
			rules =
			[
				"d /srv/share 0755 root root -"
				"d /srv/server 0755 root root -"
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
					addr = "172.16.1.2";
					port = 22;
				}
			];
		};
		dnsmasq =
		{
			enable = true;
			settings =
			{
				server =
				[
					"172.16.1.1"
				];
				address =
				[
					"/server1.server1/10.1.2.1"
					"/snac.server1/10.1.2.2"
					"/vaultwarden.server1/10.1.2.3"
				];
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
		];
	};

	nixpkgs =
	{
		hostPlatform = lib.mkDefault "x86_64-linux";
	};

	system =
	{
		stateVersion = "25.11";
	};
}
