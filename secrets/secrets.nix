{
	"nixlabs-vps-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/nixlabs-vps.pub)
		];
	};
	"server-gateway-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.pub)
		];
	};
	"server-gateway-initrd-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.pub)
		];
	};
	"server1-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server1.pub)
		];
	};
	"server1-initrd-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server1.pub)
		];
	};
	"main-desktop-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/main-desktop.pub)
		];
	};
}
