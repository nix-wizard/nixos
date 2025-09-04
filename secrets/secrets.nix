{
	"copyparty-nixwiz-password.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.nix)
		];
	};
	"server-gateway-wireguard-priv.age" =
	{
		publicKeys =
		[
			(builtins.readFile ../pubkeys/server-gateway.nix)
		];
	};
}
