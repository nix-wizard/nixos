let
	server-gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMjOWJKvKIHuMQSQZKjblyg/pk/BhccPoqImWzGfH2U";
in
{
	"copyparty-nixwiz-password.age" =
	{
		publicKeys =
		[
			server-gateway
		];
	};
}
