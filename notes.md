# Nix notes

## flakes

### templates

```
nix flake show templates
```

```
nix flake init -t templates#simpleContainer
```

## nix-store commands

`nix-store -r /nix/store/43lknaybnnkmvpz21jnqb9sh8xmclaha-mssql-bcp.drv` to find associated package in store
`nix-store -q --references /nix/store/vb9g56ibb9hs3cky5xqv2ilwis81pkxw-mssql-bcp` to see dependencies
