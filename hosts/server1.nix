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
					mtu = 1280;
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
						80
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
		};
	};

	containers =
	{
		fedi =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.2";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/fedi/";
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
					akkoma =
					{
						enable = true;
						config =
						{
							":pleroma" =
							{
								":instance" =
								{
									name = "evil fucking website";
									description = "terrible personal fedi server";
									email = "nixwiz@nixwiz.one";
									registrations_open = true;
									account_approval_required = true;
									federating = true;
									allow_relay = true;
								};
								"Pleroma.Web.Endpoint" =
								{
									http =
									{
										ip = "0.0.0.0";
										port = 8080;
									};
									url =
									{
										host = "evilfucking.website";
									};
								};
								"Pleroma.Upload" =
								{
									base_url = "https://media.evilfucking.website/media";
								};
							};
						};
						extraStatic =
						{
							"emoji/neocat" = pkgs.fetchzip
							{
								url = "https://strapi.volpeon.ink/uploads/neocat_5359f48261.zip";
								hash = "sha256-+oGg5H1o7MOLrZv0efpiW65OKH9veHM7EHsTmtPMrNQ=";
								stripRoot = false;
							};
							"emoji/neofox" = pkgs.fetchzip
							{
								url = "https://strapi.volpeon.ink/uploads/neofox_e17e757433.zip";
								hash = "sha256-OS8pT/YGKhfNGaIngU+EwnbVZCkZbnRWaTTYI+q0gpg=";
								stripRoot = false;
							};
							"static/logo.png" = pkgs.copyPathToStore ../files/akkoma/logo.png;
							"favicon.png" = pkgs.copyPathToStore ../files/akkoma/logo.png;
							"emoji/other/viska.png" = pkgs.fetchurl
							{
								url = "https://static.wikia.nocookie.net/mspaintadventures/images/8/81/Vriska_Serket.png";
								hash = "sha256-33Y1yCbGijvH/mW8tTcvlRlfPEPSehgtyYIue2d60SM=";
							};
							"emoji/other/tezi.png" = pkgs.fetchurl
							{
								url = "https://static.wikia.nocookie.net/mspaintadventures/images/9/96/Terezi_Pyrope.png";
								hash = "sha256-SYj8uHnAxTl3ESgr/jGgCtTob4yXmcH1nyQQHs5H6mk=";
							};
						};
					};
					postgresql =
					{
						enable = true;
					};
				};

				system =
				{
					stateVersion = "25.05";
				};
			};
		};
		passwordmanager =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.3";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/passwordmanager/";
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
					postgresql =
					{
						enable = true;
						ensureDatabases =
						[
							"vaultwarden"
						];
						ensureUsers =
						[
							{
								name = "vaultwarden";
								ensureDBOwnership = true;
								ensureClauses =
								{
									login = true;
								};
							}
						];
						authentication =
						''
							local vaultwarden vaultwarden trust
							host all all 127.0.0.1/32 trust
						'';
					};
					vaultwarden =
					{
						enable = true;
						dbBackend = "postgresql";
						config =
						{
							DOMAIN = "https://vault.nixwiz.one";
							SIGNUPS_ALLOWED = true;
							ROCKET_ADDRESS = "0.0.0.0";
							ROCKET_PORT = 8080;
							ROCKET_LOG = "critical";
							DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
						};
					};
				};
				
				systemd =
				{
					services =
					{
						vaultwarden =
						{
							after =
							[
								"postgresql.service"
							];
							requires =
							[
								"postgresql.service"
							];
						};
					};
				};

				system =
				{
					stateVersion = "25.05";
				};
			};
		};
		static =
		{
			autoStart = true;
			privateNetwork = true;
			hostBridge = "br0";
			localAddress = "10.1.2.4";
			bindMounts =
			{
				"/" =
				{
					hostPath = "/srv/server/containers/static";
					isReadOnly = false;
				};
				"/srv/www" =
				{
					hostPath = "/srv/server/www";
					isReadOnly = true;
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
					merecat =
					{
						enable = true;
						settings =
						{
							directory = "/srv/www";
							virtual-host = true;
						};
					};
				};
				
				system =
				{
					stateVersion = "25.05";
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
					"/fedi.server1/10.1.2.2"
					"/passwordmanager.server1/10.1.2.3"
					"/static.server1/10.1.2.4"
				];
			};
		};
		gitolite =
		{
			enable = true;
			user = "git";
			adminPubkey = (builtins.readFile ../pubkeys/nixwiz.pub);
			dataDir = "/srv/server/git";
		};
		nginx =
		{
			enable = true;
			recommendedProxySettings = true;
			recommendedOptimisation = true;
			clientMaxBodySize = "2g";
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
				"nixwiz.network" =
				{
					locations =
					{
						"/" =
						{
							proxyPass = "http://10.1.2.4:80/public/";
						};
						"/share" =
						{
							proxyPass = "http://10.1.2.4:80/public/share";
							extraConfig =
							''
								add_header Access-Control-Allow-Origin * always;
							'';
						};
					};
				};
				"nixwiz.one" =
				{
					locations =
					{
						"/" =
						{
							proxyPass = "http://10.1.2.4:80";
						};
					};
				};
				"vault.nixwiz.one" =
				{
					http2 = true;
					locations =
					{
						"/" =
						{
							proxyPass = "http://10.1.2.3:8080";
							proxyWebsockets = true;
						};
					};
				};
				"evilfucking.website" =
				{
					locations =
					{
						"~ ^/(media|proxy)" =
						{
							return = "404";
						};
						"/" =
						{
							proxyPass = "http://10.1.2.2:8080";
							proxyWebsockets = true;
						};
					};
					extraConfig =
					''
						ignore_invalid_headers off;
					'';
				};
				"media.evilfucking.website" =
				{
					http2 = true;
					locations =
					{
						"~ ^/(media|proxy)" =
						{
							proxyPass = "http://10.1.2.2:8080";
						};
						"/" =
						{
							return = "404";
						};
					};
					extraConfig =
					''
						ignore_invalid_headers off;
					'';
				};
				"freepenis.nixlabs.dev" =
				{
					locations =
					{
						"/" =
						{
							proxyPass = "http://10.1.2.4:80/public/";
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

	users =
	{
		groups =
		{
			www =
			{
				members =
				[
					"git"
				];
			};
		};
	};

	environment =
	{
		systemPackages = with pkgs;
		[
			stagit
			md4c
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
