{
	"copyparty-nixwiz-password.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.pub)
		];
	};
	"nixlabs-vps-wireguard-private.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/nixlabs-vps.pub)
		];
	};
}
