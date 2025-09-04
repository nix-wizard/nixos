{
	"copyparty-nixwiz-password.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.pub)
		];
	};
	"server-gateway-wireguard-priv.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.pub)
		];
	};
}
