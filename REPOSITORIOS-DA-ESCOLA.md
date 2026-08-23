# Os repositórios da Escola conversam entre si

> **Para o agente ou a pessoa que está começando agora:** você provavelmente
> abriu **um** repositório. Ele não vive sozinho. A Escola de Pacientes DF tem
> seis no GitHub (`github.com/escola-de-pacientes`), e pelo menos três se
> referenciam — endereço, acervo, promessa de tela.
>
> **Este arquivo é transversal, e é para estar em TODOS eles.** Se você o achou
> num repositório e ele descreve outros, não é engano. A cópia dos três é igual
> byte a byte; só o caminho muda, e o porquê está no fim.
>
> **Você não precisa mexer em todos a cada tarefa.** Precisa saber que existem,
> para não fazer no seu uma mudança que quebra a promessa do outro.

Última conferência do mapa: **23/08/2026**.

---

## O mapa

| Repositório | O que é | Onde vive | Estado |
|---|---|---|---|
| **`HUB-de-LLMs`** | O SimulaPacientes: o hub de pacientes digitais. Next.js, é onde mora a rubrica e a avaliação. **Privado.** | `hub-de-ll-ms.vercel.app` (domínio decidido e ainda não apontado: `simula.escoladepacientes.com`) | ativo |
| **`escola-de-pacientes-df`** | O site institucional. Conteúdo estático gerado de `build/` para `docs/`. **Público.** | `escoladepacientes.com` | ativo |
| **`adm-epdf`** | Núcleo EP — o sistema interno de gestão do grupo. **Privado.** | `adm-epdf.vercel.app` | ativo |
| **`Radar-de-congressos-FAPDF-`** | Radar de congressos. Público. | — | periférico |
| **`estudos`** | Material de estudo. Público. | — | periférico |
| **`temporario`** | Rascunho. Público. | — | periférico |

Os três primeiros são os que se conversam. Os outros três não têm acoplamento
conhecido — se você descobrir um, acrescente aqui.

---

## Onde eles se tocam, e o que quebra

### O site manda gente para o Hub

Páginas de tema do site (`build/content/*.md` — hipertensão, dengue, diabetes,
pré-natal, DCNT, entre outras) descrevem as simulações e mandam o leitor para o
SimulaPacientes. Algumas ainda apontam para os **Custom GPTs antigos** no
`chatgpt.com`, que são o caminho anterior ao Hub.

**O que quebra:** mudar o endereço do Hub, ou renomear/remover um caso, deixa o
site prometendo uma simulação que não existe mais. O site é público e indexado;
o Hub é privado. Quem chega pelo site é o estudante.

> Se você **apontar `simula.escoladepacientes.com`** para o Hub, as páginas do
> site que citam o endereço antigo precisam ser revistas na mesma leva.

### O acervo do site NÃO é o acervo do Hub

Está escrito em `contextoPACIENTES.md` §6.1, e é a confusão mais fácil de
cometer: o site lista os pacientes digitais publicados historicamente; o Hub tem
o seu próprio acervo, com rubrica ponderada. **Os dois divergem de propósito**,
mas a divergência tem de ser deliberada, não acidental.

**O que quebra:** acrescentar caso no Hub e supor que o site já fala dele — ou o
contrário, tirar do site algo que o Hub ainda oferece.

### O Núcleo EP é citado, não integrado

`adm-epdf` aparece no glossário do `contextoPACIENTES.md` e no `README` como o
sistema de gestão do grupo. Não há integração técnica hoje: nenhum dado
atravessa. É link e contexto.

---

## Confira em que branch você está

**Resolvido em 22/08/2026** (PR #31): a documentação e o `src/lib/fontes.ts` do
Hub estão na `main`. Antes disso viviam só numa branch de trabalho, e um agente
que clonasse e ficasse na `main` lia metade dos documentos e concluía que o resto
não existia — aconteceu de verdade, e custou tempo.

A lição sobrevive à correção: **antes de concluir que um documento não existe,
confira em que branch você está.**

```bash
cd ~/HUB-de-LLMs
git fetch --all
git branch -a
git log --oneline origin/main -1
```

Para saber se um arquivo existe numa branch sem trocar de branch:

```bash
git cat-file -e origin/main:docs/VIGENCIA.md 2>/dev/null && echo existe || echo "não existe nesta branch"
```

> **Trabalho novo vai para branch, e volta por PR.** A `main` do Hub é a branch
> de produção: todo push publica sozinho. Mas não deixe documentação parada numa
> branch — foi assim que a armadilha nasceu.

## O que conferir quando você mexe em quê

| Se você mudar… | Confira também |
|---|---|
| endereço, domínio ou rota pública do Hub | páginas de tema do site que mandam para lá; `docs/ACESSOS.md` no Hub |
| o acervo de casos do Hub (entrou, saiu, mudou de nome) | o que o site promete em `build/content/`; `contextoPACIENTES.md` §6.1 |
| conteúdo de tema no site | se o Hub tem caso correspondente, e se a promessa bate |
| qualquer coisa relevante em qualquer repo | `README.md`, `contexto.md` e `contextoPACIENTES.md` do repo mexido |

---

## Como manter este arquivo

- **Ele é para viver em todos os repositórios ativos**, com o mesmo conteúdo.
  Mudou aqui, copie para os outros — hoje isso é feito à mão, e é aceitável
  porque muda pouco.
- **A origem é o `HUB-de-LLMs`.** Quem muda, muda lá; as outras duas cópias
  saem de lá, no mesmo trabalho — não "depois". Conferir é `sha256sum` nos três.
- **O caminho não é o mesmo nos três, e isso é deliberado:**

  | Repositório | Onde este arquivo mora | Por quê |
  |---|---|---|
  | `HUB-de-LLMs` | `docs/REPOSITORIOS-DA-ESCOLA.md` | é a pasta de documentação |
  | `adm-epdf` | `docs/REPOSITORIOS-DA-ESCOLA.md` | idem |
  | `escola-de-pacientes-df` | **`REPOSITORIOS-DA-ESCOLA.md`, na raiz** | lá `docs/` é o SITE GERADO: o que se escreve nela some no próximo build |

  O conteúdo é o mesmo nos três. Só o lugar muda.
- **Acoplamento novo entra na tabela "Onde eles se tocam"**, com o que quebra
  junto. Acoplamento que ninguém escreveu é acoplamento que alguém vai quebrar.
- **Aviso que deixou de valer sai daqui.** A seção da armadilha da branch já
  encolheu quando o PR #31 integrou tudo à `main`: virou a lição, sem o alarme.
  Documento que avisa de problema resolvido treina o leitor a ignorá-lo.
