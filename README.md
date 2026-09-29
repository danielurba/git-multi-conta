# git-multi-conta

Templates para usar duas contas GitHub (pessoal e empresa) na mesma máquina Windows, sem trocar de conta. Cada repo usa a chave SSH e a identidade (nome/email) certas conforme o host do remote.

## Como funciona

1. `~/.ssh/config` define dois aliases para `github.com`: `github-pessoal` e `github-empresa`, cada um com sua chave (`IdentitiesOnly yes`).
2. O remote do repo usa o alias: `git@github-pessoal:USUARIO/REPO.git`.
3. `~/.gitconfig` usa `includeIf "hasconfig:remote.*.url:..."` (git >= 2.36) para carregar `~/.gitconfig-pessoal` ou `~/.gitconfig-empresa`.

O `.gitconfig` global mantém a identidade da empresa como fallback.

## Uso

```powershell
.\scripts\install.ps1 -NomePessoal "Fulano" -EmailPessoal "fulano@pessoal.com" `
                      -NomeEmpresa "Fulano - Empresa" -EmailEmpresa "fulano@empresa.com"
```

O script não sobrescreve arquivos existentes e gera chaves ED25519 só se não existirem (defina uma passphrase). Depois:

1. Cadastre cada `.pub` na conta certa: GitHub > Settings > SSH and GPG keys.
2. Carregue as chaves no agent: `ssh-add ~/.ssh/github_pessoal` e `ssh-add ~/.ssh/github_empresa`.
3. Teste: `ssh -T git@github-pessoal` e `ssh -T git@github-empresa`.

## Em cada repo

```
git remote add origin git@github-pessoal:USUARIO/REPO.git
git config user.email   # confirma a identidade antes do 1º commit
```

## Cuidados

- A identidade só é resolvida depois que o remote existe. Adicione o remote antes do primeiro commit.
- Use sempre o alias no remote. `git@github.com:` ou HTTPS ignoram o `includeIf` e a chave dedicada.
- Não defina `user.email` local nos repos: sobrescreve o `includeIf`.
- Este repo versiona só `*.example`. Chaves privadas e `known_hosts` estão no `.gitignore`. Revise `git status` antes de cada commit.
