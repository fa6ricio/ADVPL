#Include "Totvs.ch"
#Include "FwMvcDef.ch"
#Include "RwMake.ch"
#Include "TopConn.ch"

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MEST003    Autor  Fabricio Antunes      Data   28/10/2021   	  |
|_____________________________________________________________________________|
|Descricao|FUncao para transferencia multipla customziada                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

User Function MEST003()
Private oBrowse 	:= FwMBrowse():New()

oBrowse:SetAlias('SZF')
oBrowse:SetDescripton("Transferencia Multipla Coopervap")
oBrowse:AddLegend( "Alltrim(SZF->ZF_DOC) = ''", "GREEN", "Aberto" )
oBrowse:AddLegend( "Alltrim(SZF->ZF_DOC) <> ''", "RED",   "Gerado" )
oBrowse:SetAmbiente(.F.)
oBrowse:SetWalkThru(.F.)
oBrowse:DisableDetails()
oBrowse:Activate()

Return
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MenuDef    Autor  Fabricio Antunes      Data   28/10/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao padrão MVC para geracao do menu da rotina			          |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MenuDef()

Local aMenu :=	{}

	ADD OPTION aMenu TITLE 'Pesquisar'  ACTION 'PesqBrw'       		OPERATION 1 ACCESS 0
	ADD OPTION aMenu TITLE 'Visualizar' ACTION 'VIEWDEF.MEST003'	OPERATION 2 ACCESS 0
	ADD OPTION aMenu TITLE 'Incluir'    ACTION 'VIEWDEF.MEST003' 	OPERATION 3 ACCESS 0
	ADD OPTION aMenu TITLE 'Alterar'    ACTION 'VIEWDEF.MEST003' 	OPERATION 4 ACCESS 0
	ADD OPTION aMenu TITLE 'Excluir'    ACTION 'VIEWDEF.MEST003' 	OPERATION 5 ACCESS 0
	ADD OPTION aMenu TITLE 'Imprimir'   ACTION 'VIEWDEF.MEST003'	OPERATION 8 ACCESS 0
	//ADD OPTION aMenu TITLE 'Copiar'     ACTION 'VIEWDEF.MEST003'	OPERATION 9 ACCESS 0

Return(aMenu)

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ModelDef    Autor  Fabricio Antunes      Data   28/10/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de Modelo de Dados do MVC onde é definido a estrutura de    |
|         |dados e Regras de Negocio                                          |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function ModelDef()
	Local oStruSZF	:=	FWFormStruct(1,'SZF', /*bAvalCampo*/, /*lViewUsado*/ ) 
	Local oStruSZG	:=	FWFormStruct(1,'SZG', /*bAvalCampo*/, /*lViewUsado*/ ) 

	Local oModel

	oModel	:=	MpFormModel():New('MDMEST003',/*Pre-Validacao*/,/*Pos-Validacao*/,/*Commit*/,/*Commit*/,/*Cancel*/)
	oModel:AddFields('ID_M_FLD_SZF', /*cOwner*/, oStruSZF, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	oModel:AddGrid( 'ID_M_GRD_SZG', 'ID_M_FLD_SZF', oStruSZG, /*bLinePre*/, /*{|oModelSZG| ValLinha(oModelSZG)}*/, /*bPreVal*/,/*{|oModel| ValLinha(oModel)}*/, /*BLoad*/ )
	oModel:SetRelation( 'ID_M_GRD_SZG', {{'ZG_FILIAL','xFilial("SZG")'},{'ZG_CONTROL','ZF_CONTROL'}}, SZG->(IndexKey(1)))
	oModel:GetModel( 'ID_M_GRD_SZG' ):SetUniqueLine( { 'ZG_ITEM'} )
	oModel:SetPrimaryKey({ 'ZF_FILIAL', 'ZF_CONTROL' })
	oModel:SetDescription( 'Transferencia Multiplas Coopervap' )
	oModel:GetModel( 'ID_M_FLD_SZF' ):SetDescription( 'Cabeçãlho Transferencia' )
    oModel:GetModel( 'ID_M_GRD_SZG' ):SetDescription( 'Itens Transferencia' )
	
	//Ao ativar o modelo, irá alterar o campo do cabeçalho mandando o conteúdo FAKE pois é necessário alteração no cabeçalho
	oModel:SetActivate({ | oModel | FwFldPut("ZF_XAUT", 'S') })
Return(oModel)


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ViewDef    Autor  Fabricio Antunes      Data   28/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de Visualização de Dados do MVC onde é definido a           |
|         |visualizacao da Regra de Negocio.                                  |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function ViewDef()
	Local oStruSZF	:=	FWFormStruct(2,'SZF') 	
	Local oStruSZG	:=	FWFormStruct(2,'SZG') 
	Local oModel	:=	FwLoadModel('MEST003')	
	Local oView		:=	FwFormView():New() 

 	oView:SetModel(oModel)
	oView:AddField( 'ID_V_FLD_SZF', oStruSZF, 'ID_M_FLD_SZF')
	oView:AddGrid(  'ID_V_GRD_SZG', oStruSZG, 'ID_M_GRD_SZG')
	oView:AddUserButton( 'Gerar Transferencia', 'CLIPS', {|oView| MCOM01A()} )
	oView:CreateHorizontalBox( 'ID_HBOX_30', 25 )
	oView:CreateHorizontalBox( 'ID_HBOX_70', 75 )
	oView:SetOwnerView( 'ID_V_FLD_SZF', 'ID_HBOX_30' )
	oView:SetOwnerView( 'ID_V_GRD_SZG', 'ID_HBOX_70' )
	oView:EnableTitleView('ID_V_FLD_SZF'	,'Transferencia Multipla Coopervap')
	oView:EnableTitleView('ID_V_GRD_SZG'	,'Produtos')
	oView:AddIncrementField( 'ID_V_GRD_SZG', 'ZG_ITEM' )


Return(oView)

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCOM01A    Autor  Fabricio Antunes      Data   04/11/2020   	  |
|_____________________________________________________________________________|
|Descricao|Funcao responsavel por movimentacao multipla atraves de execauto   |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      | Coopervap                                                         | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|

*/
Static Function MCOM01A()

Local oModelbc  := FWModelActive()
//Local oModelbc  := FwLoadModel('MABEST05')
Local nI
Local oModelSZF	:= oModelbc:GetModel('ID_M_FLD_SZF')
Local oModelSZG := oModelbc:GetModel('ID_M_GRD_SZG')
Local oView            := FwViewActive()
Local aLinha := {}
Local cDoc   := ""
Local aAuto := {}
Local aItem := {}
Local nOpcAuto := 3
Private lMsHelpAuto := .T.
PRIVATE lMsErroAuto := .F.


IF Alltrim(oModelSZF:GetValue("ZF_DOC")) = ''
	
    //_____________________________________		
	//| Verifica numero do documento       |		
	//_____________________________________|		
	cDoc := GetSxeNum("SD3","D3_DOC")
	dbSelectArea("SD2")	
	SD3->(dbSetOrder(1))		
	While SD3->(dbSeek(xFilial("SC1")+cDoc))			
		ConfirmSX8()			
		cDoc := GetSXENum("SC1","C1_NUM")		
	EndDo	


    //Cabecalho a Incluir
    aadd(aAuto,{cDoc,oModelSZF:GetValue("ZF_EMISSAO")}) //Cabecalho

    //Itens a Incluir 
    aItem := {}
    
    DbSelectArea("SB1")
    SB1->(dbSetOrder(1))
		
    For nI := 1 To oModelSZG:Length()
        oModelSZG:GoLine(nI)
        If !oModelSZG:IsDeleted() 
            aLinha := {}
           
            IF SB1->(DbSeek(xFilial("SB1")+oModelSZG:GetValue('ZG_PRODUTO')))
              
                //Origem 
                aadd(aLinha,{"D3_COD"           ,Padr(oModelSZG:GetValue('ZG_PRODUTO'),TAMSX3("B1_COD")[1])           ,Nil}) //Cod Produto origem 
                aadd(aLinha,{"D3_DESCRI"        ,oModelSZG:GetValue('ZG_DESC')              ,Nil}) //descr produto origem 
                aadd(aLinha,{"D3_UM"            ,oModelSZG:GetValue('ZG_UM')                ,Nil}) //unidade medida origem 
                aadd(aLinha,{"D3_LOCAL"         ,Padr(oModelSZF:GetValue("ZF_LOCORIG"),TAMSX3("D3_LOCAL")[1])          ,Nil}) //armazem origem 
                aadd(aLinha,{"D3_LOCALIZ"       ,PadR("",tamsx3('D3_LOCALIZ') [1])          ,Nil}) //Informar endereço origem

                //Destino
                aadd(aLinha,{"D3_COD"           ,Padr(oModelSZG:GetValue('ZG_PRODUTO'),TAMSX3("B1_COD")[1])           ,Nil})  //Cod Produto destino 
                aadd(aLinha,{"D3_DESCRI"        ,oModelSZG:GetValue('ZG_DESC')              ,Nil}) //descr produto destino 
                aadd(aLinha,{"D3_UM"            ,oModelSZG:GetValue('ZG_UM')                ,Nil}) //unidade medida destino 
                aadd(aLinha,{"D3_LOCAL"         ,Padr(oModelSZF:GetValue("ZF_LOCALDE"),TAMSX3("D3_LOCAL")[1])           ,Nil}) //armazem destino 
                aadd(aLinha,{"D3_LOCALIZ"       ,PadR("",tamsx3('D3_LOCALIZ') [1])          ,Nil}) //Informar endereço destino

                aadd(aLinha,{"D3_NUMSERI"       , ""                                        ,Nil}) //Numero serie
                aadd(aLinha,{"D3_LOTECTL"       , ""                                        ,Nil}) //Lote Origem
                aadd(aLinha,{"D3_NUMLOTE"       , ""                                        ,Nil}) //sublote origem
                aadd(aLinha,{"D3_DTVALID"       , cTod("  /  /    ")                        ,Nil}) //data validade 
                aadd(aLinha,{"D3_POTENCI"       , Criavar("D3_POTENCI")                     ,Nil}) // Potencia
                aadd(aLinha,{"D3_QUANT"         , oModelSZG:GetValue('ZG_QUANT')            ,Nil}) //Quantidade
                aadd(aLinha,{"D3_QTSEGUM"       , Criavar("D3_QTSEGUM")                     ,Nil}) //Seg unidade medida
                aadd(aLinha,{"D3_ESTORNO"       , Criavar("D3_ESTORNO")                     ,Nil}) //Estorno 
                aadd(aLinha,{"D3_NUMSEQ"        , ""                                        ,Nil}) // Numero sequencia D3_NUMSEQ

                aadd(aLinha,{"D3_LOTECTL"       , Criavar("D3_NUMSEQ")                      ,Nil}) //Lote destino
                aadd(aLinha,{"D3_NUMLOTE"       , CriaVar('D3_NUMLOTE')                     ,Nil}) //sublote destino 
                aadd(aLinha,{"D3_DTVALID"       , cTod("  /  /    ")                        ,Nil}) //validade lote destino
                aadd(aLinha,{"D3_ITEMGRD"       , ""                                        ,Nil}) //Item Grade


            EndIF

            aAdd(aAuto,aLinha)
        EndIF
    Next nX

   

	//_________________________________		
	//| Roda execauto de Inclusao      |		
	//_________________________________|	

	MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)	

	If !lMsErroAuto			
		MsgInfo("Transferencia de numero "+cDoc+" incluida com sucesso.")
		oModelSZF:SetValue("ZF_DOC",cDoc)
	Else			
		MsgAlert("Erro na inclusao da solicitacao.")
		MostraErro()
	EndIf	
Else
	Help( ,, 'Help',,"Tranferencia já gerada, nao sera possivel gerar novamente", 1, 0 )
EndIF

oModelSZG:GoLine(1)
oView:Refresh('ID_V_FLD_SZF')
oView:Refresh('ID_V_GRD_SZG')

Return
