# Curadoria de Versos e Conselhos

A página é estática. Não usa Supabase, API, login, comentários ou banco de dados. O Google Forms é apenas um link externo para receber mensagens: nenhuma resposta chega automaticamente ao site.

## Retirar um registro

1. Nesta pasta, abra o arquivo do registro. O identificador aparece no fim do link público: `#hist-001` corresponde a `hist-001.json`.
2. Exclua o arquivo pelo GitHub e salve a alteração em `main`.
3. Aguarde “Publicar o site” e a publicação do GitHub Pages. A página inteira é reconstruída com os arquivos restantes; não há páginas individuais antigas para apagar.

A exclusão retira o texto da versão corrente do site. Como o repositório é público, o histórico do Git e cópias externas podem continuar contendo versões anteriores. Evite incluir informações privadas mesmo temporariamente.

## Acrescentar ou corrigir

Edite o JSON correspondente ou crie um arquivo com identificador novo e estável. Nunca reutilize o ID de outra pessoa. Exemplo de estrutura, sem depoimento fictício a publicar:

```json
{
  "id": "novo-identificador",
  "titulo": "Título editorial do conselho",
  "autor": "Assinatura escolhida ou Colaborador anônimo",
  "turma": "MED... ou Não informada",
  "data": "2026-08",
  "etapas": ["primeiros-passos"],
  "conselho": ["Texto autorizado pelo autor; um parágrafo por item."],
  "pos_escritos": [],
  "indicacoes": [],
  "origem": "Contribuição enviada à Escola de Pacientes"
}
```

O nome do arquivo deve ser igual ao ID, com `.json`. A data pode conter somente o ano, quando o mês não for conhecido. Etapas disponíveis: `primeiros-passos`, `primeiros-pacientes`, `ciclo-clinico`, `internato`, `reta-final`. Pode escolher várias. A lista aparece do registro mais recente ao mais antigo. Não altere datas antigas para destacar um registro.

Pós-escritos: `{"data":"2026-08","paragrafos":["Texto posterior do mesmo autor."]}`. Indicações: títulos e autores de obras, sem reproduzir letras/poemas completos. `fonte`, quando presente, deve ser um link HTTPS público para a fonte original. Todo texto é escapado: HTML nos campos aparece como texto, não executa.

Antes de incluir uma nova mensagem: confira a autorização para publicar e a assinatura; não copie dados de pacientes, e-mails ou pedidos privados de correção para estes arquivos. Não invente autoria, datas ou depoimentos. As respostas e autorizações permanecem no Forms/Drive, fora deste repositório público.

## Formulário

O endereço público está em `build/versos-e-conselhos-config.json`. É um formulário no Drive da coordenação. Para corrigir ou desativar o convite, altere `formulario_url`; string vazia esconde o botão. Não coloque tokens ou endereço de edição no arquivo.

## Fonte histórica e escolhas editoriais

18 registros com conselhos ou pós-escritos, de 2016 a 2019, extraídos da Calçada já disponível na página anterior. A edição consultada é a de 21/05/2022, vinculada nos próprios registros. O registro histórico `hist-006` contém apenas uma citação de terceiro e não foi incluído. Por isso há uma lacuna intencional nos identificadores.

Mantidos os textos dos conselhos e pós-escritos, as assinaturas e os anonimatos. Títulos de cartões e filtros por etapa são editoriais; não mudam o contexto original do internato. Não foram importados os blocos autônomos de músicas, poemas e citações. Há pequenas citações dentro da própria prosa de alguns conselhos, preservadas junto ao comentário do estudante.

O endereço anterior `/calcada-de-versos-e-conselhos/` continua funcionando e aponta para a coleção nova. A nova página aparece em Estudantes, na busca e no índice A–Z.

## Verificação

Rode `perl build/build.pl` para validar JSON e reconstruir o site localmente. Não envie `docs/` manualmente: o workflow existente gera essa pasta no GitHub. Edite e envie somente as fontes em `build/`.
