let
	server-gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3HWy1VmBen1+eG6j6JxBhPS8iwXDr4wQnuuDe42yOv";
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
