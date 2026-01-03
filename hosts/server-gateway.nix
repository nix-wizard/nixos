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
					cryptshare =
					{
						device = "/dev/disk/by-uuid/74519cf0-f16d-40be-b2b0-a3b7f0c40e87";
					};
					cryptserver =
					{
						device = "/dev/disk/by-uuid/60ef38f7-23bf-4295-95bb-7d50deb5c737";
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
							ip link add dev wg0 type wireguard

							wg set wg0 private-key /etc/wireguard/server-gateway-initrd-wireguard-private peer ${builtins.replaceStrings ["\n"] [""] (builtins.readFile ../pubkeys/racknerd-vps-wireguard-public)} endpoint 107.174.108.42:51820 allowed-ips 172.16.0.0/24 persistent-keepalive 25

							ip addr add 172.16.0.3/24 dev wg0
							ip link set wg0 up
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
							ip link delete wg0
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
	
	time =
	{
		timeZone = "America/Los_Angeles";
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
		};
		wg-quick =
		{
			interfaces =
			{
				wg0 =
				{
					address =
					[
						"172.16.0.2/24"
					];
					privateKeyFile = config.age.secrets.server-gateway-wireguard-private.path;
					peers =
					[
						{
							publicKey = (builtins.readFile ../pubkeys/racknerd-vps-wireguard-public);
							allowedIPs =
							[
								"0.0.0.0/0"
							];
							endpoint = "107.174.108.42:51820";
							persistentKeepalive = 25;
						}
					];
				};
				wg1 =
				{
					address =
					[
						"172.16.1.1/24"
					];
					listenPort = 51820;
					privateKeyFile = config.age.secrets.server-gateway-wireguard-private.path;
					peers =
					[
						{
							publicKey = (builtins.readFile ../pubkeys/server1-wireguard-public);
							allowedIPs =
							[
								"172.16.1.2/32"
							];
						}
						{
							publicKey = (builtins.readFile ../pubkeys/server1-initrd-wireguard-public);
							allowedIPs =
							[
								"172.16.1.3/32"
							];
						}
						{
							publicKey = (builtins.readFile ../pubkeys/main-desktop-wireguard-public);
							allowedIPs =
							[
								"172.16.1.4/32"
				
							];
						}
						{
							publicKey = (builtins.readFile ../pubkeys/a54-5g-wireguard-public);
							allowedIPs =
							[
								"172.16.1.5/32"
							];
						}
						{
							publicKey = (builtins.readFile ../pubkeys/thinkpad-t530-wireguard-public);
							allowedIPs =
							[
								"172.16.1.6/32"
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
				"eno1" =
				{
					allowedTCPPorts =
					[
					];
					allowedUDPPorts =
					[
						51820
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
						80
						443
						2222
						20000
					];
					allowedUDPPorts =
					[
						20000
						51820
					];
				};
				"wg1" =
				{
					allowedTCPPorts =
					[
						22
						111
						53
						2049
						4000
						4001
						4002
						20048
						7070
					];
					allowedUDPPorts =
					[
						111
						53
						2049
						4000
						4001
						4002
						20048
					];
				};
			};
			allowPing = true;
			checkReversePath = "loose";
		};
		nat =
		{
			enable = true;
			externalInterface = "wg0";
			internalInterfaces =
			[
				"wg1"
			];
			forwardPorts =
			[
			];
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
		services =
		{
			nfs-server =
			{
				requires =
				[
					"dnsmasq.service"
				];
				after =
				[
					"dnsmasq.service"
				];
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
					/srv/share server1.server-gateway(rw,sync,no_subtree_check,no_root_squash)
					/srv/share main-desktop.server-gateway(rw,sync,no_subtree_check,no_root_squash)
					/srv/share thinkpad-t530.server-gateway(rw,sync,no_subtree_check,no_root_squash)
					/srv/server/servers/server1 server1.server-gateway(rw,sync,no_subtree_check,no_root_squash)
				'';
			};
		};
		dnsmasq =
		{
			enable = true;
			settings =
			{
				server =
				[
					"9.9.9.9"
				];
				address =
				[
					"/server-gateway.server-gateway/172.16.1.1"
					"/server1.server-gateway/172.16.1.2"
					"/server1-initrd.server-gateway/172.16.1.3"
					"/main-desktop.server-gateway/172.16.1.4"
					"/a54-5g.server-gateway/172.16.1.5"
					"/thinkpad-t530.server-gateway/172.16.1.6"
				];
			};
		};
		i2pd =
		{
			enable = true;
			ifname = "eno1";
			port = 20000;
			ntcp2 =
			{
				enable = true;
				published = true;
				port = 20000;
			};
			ssu2 =
			{
				enable = true;
				published = true;
				port = 20000;
			};
			proto =
			{
				http =
				{
					enable = true;
					hostname = "server-gateway.server-gateway";
					address = "0.0.0.0";
				};
				socksProxy =
				{
					enable = true;
					address = "0.0.0.0";
				};
			};
		};
		nginx =
		{
			enable = true;
			package = pkgs.nginx.override
			{
				withSlice = true;
			};
			recommendedProxySettings = true;
			recommendedTlsSettings = true;
			recommendedOptimisation = true;
			recommendedGzipSettings = true;
			proxyCachePath =
			{
				"akkoma-media-cache" =
				{
					enable = true;
					levels = "1:2";
					keysZoneName = "akkoma_media_cache";
					keysZoneSize = "10m";
					maxSize = "1g";
					inactive = "720m";
					useTempPath = false;
				};
			};
			virtualHosts =
			{
				"_default" =
				{
					default = true;
					addSSL = true;
					sslCertificate = "/etc/ssl/catchall/catchall.crt";
					sslCertificateKey = "/etc/ssl/catchall/catchall.key";
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
					enableACME = true;
					forceSSL = true;
					locations =
					{
						"/" =
						{
							proxyPass = "http://172.16.1.2:80";
						};
					};
				};
				"nixwiz.one" =
				{
					enableACME = true;
					forceSSL = true;
					locations =
					{
						"/" =
						{
							proxyPass = "http://172.16.1.2:80";
						};
					};
				};
				"vault.nixwiz.one" =
				{
					enableACME = true;
					forceSSL = true;
					http2 = true;
					locations =
					{
						"/" =
						{
							proxyPass = "http://172.16.1.2:80";
							proxyWebsockets = true;
						};
					};
					extraConfig =
					''
						client_max_body_size 525M;
					'';
				};
				"evilfucking.website" =
				{
					enableACME = true;
					forceSSL = true;
					http2 = true;
					locations =
					{
						/*
						"~ ^/(media|proxy)" =
						{
							return = "404";
						};
						"/" =
						{
							proxyPass = "http://172.16.1.2:80";
							proxyWebsockets = true;
						};
						*/
						"/" =
						{
							return ="410";
						};
					};
					extraConfig =
					''
						client_max_body_size 16m;
						ignore_invalid_headers off;
					'';
				};
				"media.evilfucking.website" =
				{
					enableACME = true;
					forceSSL = true;
					http2 = true;
					locations =
					{
						/*
						"~ ^/(media|proxy)" =
						{
							proxyPass = "http://172.16.1.2:80";
							extraConfig =
							''
								slice 1m;
								proxy_cache akkoma_media_cache;
								proxy_cache_key $host$uri$is_args$args$slice_range;
								proxy_set_header Range $slice_range;
								proxy_cache_valid  200 206 301 304 1h;
								proxy_cache_lock on;
								proxy_ignore_client_abort on;
								proxy_buffering on;
								chunked_transfer_encoding on;
							'';
						};
						"/" =
						{
							return = "404";
						};
						*/
						"/" =
						{
							return = "410";
						};
					};
					extraConfig =
					''
						client_max_body_size 16m;
						ignore_invalid_headers off;
					'';
				};
				"fedi.nixwiz.one" =
				{
					enableACME = true;
					forceSSL = true;
					locations =
					{
						"/" =
						{
							return = "410";
						};
					};
				};
				"freepenis.nixlabs.dev" =
				{
					enableACME = true;
					forceSSL = true;
					locations =
					{
						"/" =
						{
							proxyPass = "http://172.16.1.2:80";
						};
					};
				};
				"music.nixwiz.one" =
				{
					enableACME = true;
					forceSSL = true;
					http2 = true;
					locations =
					{
						"/" =
						{
							proxyPass = "http://172.16.1.2:80";
						};
					};
					extraConfig =
					''
						proxy_buffering off;
						proxy_read_timeout 300s;
						proxy_connect_timeout 300s;
					'';
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

	users =
	{
		users =
		{
			#chloe = # i'm not doing this shit again
			#{
			#	isNormalUser = true;
			#	home = "/home/chloe";
			#	description = "DEATH TO AMERICA!";
			#	openssh =
			#	{
			#		authorizedKeys =
			#		{
			#			keyFiles =
			#			[
			#				../pubkeys/chloe.pub
			#			];
			#		};
			#	};
			#};
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
