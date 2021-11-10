# ADVPL #PROTHEUS #TL++ #WebServiced #JSon #RestFull
Fontes de Exemplo de ADVPL

Fabrício Antunes Fonseca
Analista protheus com mais de 14 anos de experiência em desenolvimento, implantação e suporte Protheus, ADVPL

-------------------------------------
-----Miscelanea (Fontes Gerais)------
-------------------------------------

MCCOM004
Formulario MVC feito com tabelas temporarias no banco para aprovação em conjunto de solicitações de compras Protheus


MCON00X
Rotina MVC com um filds e dois grids toda baseada em tabela temporária no banco de dados

MFAT001
Markbrowser MVC de tabela temporária com filtros e ordenações e opção de alterar o conteúdo dos campos. usado para preficação na tabela de preços e impressão de etiquetas zebra

MLOJA006
Função para ser chamada em consulta padrão para montagem de tela customizada para localização de produto, com opção de digitação de qualquer parte da descrição do produto, fazendo filtros


--------------------
-----ExecAutos------
--------------------
MFIN001
Execauto básico de importação de contas a receber

MEST003
Execauto de movimentação multiplas de estoque (mata261) desenvolvido em MVC com tabelas customizadas para pode ser usar leitores de código de barras para localizar os produtos


--------------------
--------Fluig-------
--------------------
MT120FIM
Ponto de entrada MT120FIM com consumo de webservice wsdl do Fluig para ingração de processo de liberação de pedido de compras via FLuig. Rotina feita usando método TWsdlManager


----------------------
--------WS Wsdl-------
----------------------
WSFLGSRV
WebService WSDL para aprovação de solicitacao de compras com tratativas por nível de aprovação e integração com fluig usando classe TWsdlManager

FATWS001
WebService WSDL para inclusao de pedido de vendas, com funcao recursiva para montagem do XML recebido,