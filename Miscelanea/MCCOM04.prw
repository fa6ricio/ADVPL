#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#include 'stdwin.ch'
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "SHELL.CH"
#INCLUDE "FWPrintSetup.ch"
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MCCOM04    Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para liberacao de solicitacao de compras                    |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

User Function MCCOM04()
    Local aCposCab    := {}
    Local aCposGrd1   := {}
	Local aPergs   := {}
    Local aTitulos
    Private cTableCab, cTableGr1
	Private oBrowse := Nil	
    Private aRotina         := Menudef()
    Private aBrows, aGrd1, aGrd2    //Varias com estrutura de colunas para ser utilizado no browser, no fields e nos grids
    Private cAlisCab:=GetNextAlias()
    Private cAlisGr1:=GetNextAlias()
 	Private cfilqry
	Private oGrd1
    Private oCabec

	// Perguntas de parametros para Funcao
	aAdd(aPergs, {1, "Da Solicitacao de", '      ',  "@!", ".T.", "SC1", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Da Solicitacao ate", 'ZZZZZZ',  "@!", ".T.", "SC1", ".T.", 80,  .T.})
	
	If ParamBox(aPergs, "Informe os parâmetros para definicao dos filtros da rotina")
		
		//----------------------------------------------------------
		//Cria tabela para browser que sera usada no filds do MVC
		//----------------------------------------------------------
		aAdd(aCposCab,{"C1_NUM","C",6,00})
		aAdd(aCposCab,{"C1_EMISSAO","C",10,00})
		aAdd(aCposCab,{"C1_SOLICIT","C",25,0})
		aAdd(aCposCab,{"C1_SCORI","C",6,0})
		
		//Array com nome dos campos para Browser
		aTitulos:={'Numero', "Emissao", "Solicitante","Interno"}

		//Funcao para gerar as colunas do Browser
		aBrows:=gerCpBrow(aCposCab,aTitulos)
		If oCabec <> Nil
			oCabec:Delete()
			oCabec := Nil
		Endif
		oCabec:=FWTemporaryTable():New(cAlisCab)
		oCabec:SetFields(aCposCab)
		oCabec:AddIndex("1", {"C1_NUM"})
		oCabec:Create()
		
		//Obtenho o nome "verdadeiro" da tabela no BD (criada como tempor ria)
		cTableCab := oCabec:GetRealName()



		//----------------------------------------------------------
		//Cria tabela grid 1 para ser usado  do MVC
		//----------------------------------------------------------

		If oGrd1 <> Nil
			oGrd1:Delete()
			oGrd1 := Nil
		Endif

		oGrd1 := FWTemporaryTable():New(cAlisGr1)
		aAdd(aCposGrd1,{"C1_NUM"	 ,"C",6,00})
		aAdd(aCposGrd1,{"C1_ITEM" 	 ,"C",04,0})
		aAdd(aCposGrd1,{"C1_PRODUTO" ,"C",14,0})
		aAdd(aCposGrd1,{"C1_DESCRI"  ,"C",60,0})
		aAdd(aCposGrd1,{"C1_UM"      ,"C",2,0})
		aAdd(aCposGrd1,{"C1_QUANT"   ,"N",12,2})
		aAdd(aCposGrd1,{"C1_DATPRF"  ,"C",10,0})


		aTitulos:={'Numero',  "Item","Produto", "Descricao", "Unid Med","Quantidade","Necessidade"}
		aGrd1:=gerCpBrow(aCposGrd1,aTitulos)


		oGrd1:SetFields(aCposGrd1)
		oGrd1:AddIndex("1", {"C1_NUM"})
		oGrd1:AddIndex("2", {"C1_ITEM"})
		oGrd1:AddIndex("3", {"C1_PRODUTO"})
		oGrd1:Create()
		//Obtenho o nome "verdadeiro" da tabela no BD (criada como tempor ria)
		cTableGr1 := oGrd1:GetRealName()


		MsgRun("Carregando solicitacoes de comrpas...",,{||CursorWait(),BuscSolict(MV_PAR01,MV_PAR02),CursorArrow()})
					
		dbSelectArea(cAlisGr1)

		//----------------------------------------------------------
		//Montagem do browser
		//----------------------------------------------------------
		oBrowse:= FwMBrowse():New()
		oBrowse:SetDescription("Liberacao de solicitacao de compras") 
		oBrowse:SetAlias(cAlisCab) 
		oBrowse:SetWalkThru(.F.)
		oBrowse:SetAmbiente(.T.) 
		oBrowse:SetTemporary(.T.)
		oBrowse:SetFields(aBrows)
		oBrowse:Activate()

		//--------------------------------
		//Exclui tabelas temporarias
		//--------------------------------
		If oCabec <> Nil
			oCabec:Delete()
			oCabec := Nil
		Endif

		If oGrd1 <> Nil
			oGrd1:Delete()
			oGrd1 := Nil
		Endif

	EndIF
Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MenuDef    Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Menu da rotina                                                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MenuDef()
    Local aRot := {}
    
    ADD OPTION aRot TITLE 'Aprovar/Reprovar'    ACTION 'VIEWDEF.MCCOM04' 	OPERATION 4 ACCESS 0

Return(Aclone(aRot))

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ModelDef   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Modelo de dados MVC para edicao da tabela temporaria               |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function ModelDef()

	Local oModel := Nil
	Local osCabec := FWFormModelStruct():New()
	Local osGrd1  := FWFormModelStruct():New()
	Local nX
	Local bPre := {|oModel, cAction, cIDField, xValue| validPre(oModel, cAction, cIDField, xValue)}
	Local bPos := {|oModel|fieldValidPos(oModel)}
	Local bLoad := {|oModel, lCopy| loadField(oModel, lCopy)}
	Local bLoaGr1	:={|oModel, lCopy| loadGrd(oModel, lCopy,"GR1")}

	For nX:=1 to Len(aBrows)
		aBrows[nX,6]=.F.
	Next
	osCabec:AddTable(cAlisCab, {"C1_NUM"}, "Libercao solicitacao de compras")

	For nX:=1 to Len(aGrd1)
		aadd(aGrd1[nX],.F.)
	Next

    /*----------------------------------------------------------------------
    Estratuda do array para montagem dos campos usados na funcao MntStrut
        1 - Descricao
        2 - Nome do Campo
        3 - Tipo do campo
        4 - Tamanho do campo
        5 - Decimal
        6 - Se campo e editavel
    ------------------------------------------------------------------------*/

     MntStrut(@osCabec,cAlisCab,aBrows)  
     MntStrut(@osGrd1,cAlisGr1,aGrd1)  


    osCabec:AddTable(cAlisCab,, "Solicitacao de Compras"	,{|| oCabec:GetRealName()})
	osGrd1:AddTable(cAlisGr1,, "Produtos"	,{|| oGrd1:GetRealName()})

    oModel := FWFormModel():New( 'mdMCCOM04',,,{|oModel| commit(oModel)},{|oModel| cancel()})   

	oModel:AddFields( 'ID_M_FLD', , osCabec,bPre,bPos,bLoad)
	oModel:AddGrid( 'ID_M_GRD1', 'ID_M_FLD', osGrd1, /*bLinePre*/, /*{|oModelZA2| ValLinha(oModelZA2)}*/, /*bPreVal*/,/*{|oModel| ValLinha(oModel)}*/, bLoaGr1/*bLoad1*/)

	oModel:SetRelation( 'ID_M_GRD1', {{'C1_NUM','C1_NUM'}}, (cAlisGr1)->(IndexKey(1)))
	oModel:GetModel( 'ID_M_GRD1' ):SetUniqueLine( { 'C1_NUM','C1_ITEM'} )
	oModel:SetPrimaryKey({ 'C1_NUM' })
	oModel:SetDescription( 'Solicitacao de compras' )
	oModel:GetModel( 'ID_M_GRD1' ):SetDescription( 'Produtos' )

	oModel:SetActivate({ | oModel | FwFldPut("C1_SCORI", 'S',NIL,oModel,.F.,.T.) })
	

Return oModel

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ModelDef   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de validacao pos carregamento dos dados                     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function fieldValidPos(oModel)
Local lRet := .T.
   
   	//aAdd(aCposGrd1,{"C1_NUM"        ,"C",06,0})
	//aAdd(aCposGrd1,{"C1_ITEM"       ,"C",04,0})
	
    //oModel:GetModel():SetErrorMessage('mdMCCOM04', "C1_NUM" , 'mdMCCOM04' , 'C1_NUM' , "C1_ITEM")      
   
Return lRet

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - validPre   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de validação dos dados de carregamento                      |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function validPre(oModel, cAction, cIDField, xValue)
Local lRet := .T.

  // oModel:GetModel():SetErrorMessage('mdMCCOM04', "C1_NUM" , 'mdMCCOM04' , 'C1_NUM' , "C1_ITEM")
Return lRet

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - loadField   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao de carregamento dos dados para o Filds                      |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function loadField(oModel, lCopy)
Local aLoad := {}
Local nI as numeric
Local aLine as array
Local xValue as variant

//    aAdd(aLoad, {xFilial("01"), "ID", "ITEM"}) //dados

	aLine := {}
	//DbSelectArea(cAlisCab)

//	While !(cAlisCab)->(EOF())
		For nI := 1 to Len(aBrows)
			If aBrows[nI][3] == "C"
				xValue := (cAlisCab)->&(aBrows[nI,2])
			Elseif aBrows[nI][3] == "D"
				xValue := StoD((cAlisCab)->&(aBrows[nI,2]))
			Elseif aBrows[nI][3] == "N"
				xValue := (cAlisCab)->&(aBrows[nI,2])
			Else
				xValue := .F.
			Endif

			aAdd(aLine, xValue)
		Next
	

	aAdd(aLoad, aLine) //dados
	aAdd(aLoad, 1) //recno
      
Return aLoad


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - loadGrd   Autor  Fabricio Antunes      Data   01/11/2021    	  |
|_____________________________________________________________________________|
|Descricao|Função responsável pela carga dos submodelos do MVC.               | 
|         |@param	oSub, objeto, instância da classe FWFormFieldsModel ou da |
|         |classe FWFormGridModel                                             |
		  |	cIdSub, caractere, id do submodelo que será carregado             |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function loadGrd(oSub,lCopy,cIdSub)

Local cAliasTab	:= ""

Local nI		:= 0
Local nRec		:= 1
Local aFldSub	:= {}
Local aRet 		:= {}
Local aAux		:= {}



aFldSub := oSub:GetStruct():GetFields()
cAliasTab := oGrd1:GetAlias()
(cAliasTab)->(DbGoTop())

(cAliasTab)->(dbSetOrder(1))
(cAliasTab)->(dbGoTop())
IF (cAliasTab)->(dbSeek((cAlisCab)->C1_NUM))
	While !(cAliasTab)->(Eof()) .AND. (cAliasTab)->C1_NUM = (cAlisCab)->C1_NUM
				
		For nI := 1 to Len(aFldSub)

			If ( (cAliasTab)->(FieldPos(aFldSub[nI,3])) > 0 )
				aAdd(aAux,(cAliasTab)->&(aFldSub[nI,3]))
			Else
				aAdd(aAux,GTPCastType(,aFldSub[nI,4]))
			EndIf

		Next nI
		
		aAdd(aRet,{nRec,aClone(aAux)})
		aAux := {}
		nRec++
		
		(cAliasTab)->(DbSkip())
		
	EndDo
EndIF



Return(aRet)


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - Commit   Autor  Fabricio Antunes      Data   01/11/2021     	  |
|_____________________________________________________________________________|
|Descricao|Funcao de valicao do comit da					  tela            |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function Commit(oModel)

Local oModelGRD := oModel:GetModel('ID_M_GRD1')
Local nI
dbSelectArea("SC1")
SC1->(dbSetOrder(1))

 For nI := 1 To oModelGRD:Length()
	oModelGRD:GoLine(nI)
	IF SC1->(dbSeek(xFilial("SC1")+oModelGRD:GetValue("C1_NUM")+oModelGRD:GetValue("C1_ITEM")))
		RecLock("SC1",.F.)
		If !oModelGRD:IsDeleted() 
			SC1->C1_APROV = 'L'
		Else
			SC1->C1_APROV = 'R'	
		EndIF
		msUnLock()
	EndIf
Next nI


MsgInfo("Solicitacao de compras processada com sucesso", "Liberacao")


//Limpa registro processado da tabela temporaria
Reclock((cAlisCab),.F.)
	(cAlisCab)->(dbDelete())
msUnLock()


Return .T.
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - Cancel   Autor  Fabricio Antunes      Data   01/11/2021   	      |
|_____________________________________________________________________________|
|Descricao|Funcao de valicao do cancelamento do tela                          |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function Cancel()
Return .T.
/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - ViewDef   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Visao de dados MVC para montagem da tela da  tabela temporaria     |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static Function ViewDef()
	Local oModel := FWLoadModel("MCCOM04")
	Local osCabec := FWFormViewStruct():New()
	Local osGrd1 := FWFormViewStruct():New()
	Local oView := Nil
	Local nX
	Local aDadCab :={}
	Local aDadGr1 :={}

    /*----------------------------------------------------------------------
    Estratuda do array para montagem dos campos usados na funcao MntView
        1 - Nome do Campo
        2 - Ordem
        3 - Titulo do campo
        4 - Tipo do campo
        5 - Picture
        6 - Se campo e editavel
    ------------------------------------------------------------------------*/
  
	For nX:=1 to Len(aBrows)
		IF aBrows[nX,3] = "C"
            cPict:="@!"
		ElseIF aBrows[nX,3] = "N"
            cPict:="@E 9,999,999.99"
		Else
            cPict:=""
		EnDIF
        aADD(aDadCab,{aBrows[nX,2],StrZero(nX,2),aBrows[nX,1],aBrows[nX,3],cPict,.F.})

	Next

	For nX:=1 to Len(aGrd1)
		IF aGrd1[nX,3] = "C"
            cPict:="@!"
		ElseIF aGrd1[nX,3] = "N"
            cPict:="@E 9,999,999.99"
		Else
            cPict:=""
		EnDIF
        aADD(aDadGr1,{aGrd1[nX,2],StrZero(nX,2),aGrd1[nX,1],aGrd1[nX,3],cPict,.F.})

	Next


    MntView(@osCabec,aDadCab)
    MntView(@osGrd1,aDadGr1)


    oView := FWFormView():New()
    oView:SetModel(oModel)

    oView:AddField("ID_V_FLD", osCabec, "ID_M_FLD")
    oView:AddGrid("ID_V_GRD1", osGrd1, "ID_M_GRD1")


    oView:CreateHorizontalBox("SUPERIOR",30)
    oView:CreateHorizontalBox("INFERIOR",70)

    
    oView:SetOwnerView( 'ID_V_FLD'   , 'SUPERIOR' )
	oView:SetOwnerView( 'ID_V_GRD1'   , 'INFERIOR' )

    oView:EnableTitleView('ID_V_FLD', 'Solicitacao de compras' )  
    oView:EnableTitleView('ID_V_GRD1', 'Produtos' )  
     
    oView:SetCloseOnOk({||.T.})

Return oView



/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - gerCpBrow    Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para montar array com colunas para browser                  |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function gerCpBrow(aCampos,aTitulos)

	Local nX
	Local aBrows:={}

	For nX:=1 to Len(aCampos)
		AAdd(aBrows,{aTitulos[nX], aCampos[nX,1] ,aCampos[nX,2] ,aCampos[nX,3] ,aCampos[nX,4]})
	Next
Return aBrows

/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MntStrut   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao para montar estrutura de dados para MODELDEF                |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MntStrut(oObj,cAlias, aCampos)
	Local nX
	Default aCampos:={}

	For nX:=1 to Len(aCampos)
		oObj:AddField(;
			aCampos[nX,1],;                                                                              // [01]  C   Titulo do campo
		aCampos[nX,1],;                                                                                  // [02]  C   ToolTip do campo
		aCampos[nX,2],;                                                                                  // [03]  C   Id do Field
		aCampos[nX,3],;                                                                                  // [04]  C   Tipo do campo
		aCampos[nX,4],;                                                                                  // [05]  N   Tamanho do campo
		aCampos[nX,5],;                                                                                  // [06]  N   Decimal do campo
		Nil,;                                                                                            // [07]  B   Code-block de validação do campo
		Nil,;                                                                                            // [08]  B   Code-block de validação When do campo
		{},;                                                                                             // [09]  A   Lista de valores permitido do campo
		.F.,;                                                                                            // [10]  L   Indica se o campo tem preenchimento obrigatório
		FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,('"+cAlias+"')->"+aCampos[nX,2]+",'')" ),;   // [11]  B   Code-block de inicializacao do campo
		.T.,;                                                                                            // [12]  L   Indica se trata-se de um campo chave
		aCampos[nX,6],;                                                                                  // [13]  L   Indica se o campo pode receber valor em uma operação de update.
		.F.)                                                                                             // [14]  L   Indica se o campo é virtual


		IF aCampos[nX,6]
			oObj:SetProperty(aCampos[nX,2], MODEL_FIELD_WHEN, { || .T.})
			oObj:SetProperty(aCampos[nX,2], MODEL_FIELD_NOUPD,.F.)
		EndIF
	Next
Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - MntView   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao auxliar para montagem da estrutura dos campos no Viewdef    |
|         |                                                                   |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/
Static Function MntView(oObj,aCampos)
	Local nX


	For nX:=1 to Len(aCampos)
		//Adicionando campos da estrutura
		oObj:AddField(;
			aCampos[nX,1],;                  // [01]  C   Nome do Campo
		aCampos[nX,2],;                  // [02]  C   Ordem
		aCampos[nX,3],;                  // [03]  C   Titulo do campo
		aCampos[nX,3],;                  // [04]  C   Descricao do campo
		Nil,;                            // [05]  A   Array com Help
		aCampos[nX,4],;                  // [06]  C   Tipo do campo
		aCampos[nX,5],;                  // [07]  C   Picture
		Nil,;                            // [08]  B   Bloco de PictTre Var
		Nil,;                            // [09]  C   Consulta F3
		aCampos[nX,6],;                  // [10]  L   Indica se o campo é alteravel
		Nil,;                            // [11]  C   Pasta do campo
		Nil,;                            // [12]  C   Agrupamento do campo
		Nil,;                            // [13]  A   Lista de valores permitido do campo (Combo)
		Nil,;                            // [14]  N   Tamanho maximo da maior opção do combo
		Nil,;                            // [15]  C   Inicializador de Browse
		Nil,;                            // [16]  L   Indica se o campo é virtual
		Nil,;                            // [17]  C   Picture Variavel
		Nil)                             // [18]  L   Indica pulo de linha após o campo
	Next

Return


/*
______________________________________________________________________________
|_____________________________________________________________________________|
|Programa  - BuscSolict   Autor  Fabricio Antunes      Data   01/11/2021   	  |
|_____________________________________________________________________________|
|Descricao|Funcao auxliar para busca dados da solicitacoes e alimentar tabelas|
|         |temporárias                                                        |
|_________|___________________________________________________________________|
|Uso      |                                                                   | 
|_________|___________________________________________________________________|
|_____________________________________________________________________________|
*/

Static function BuscSolict(cSolDe,cSolAte)
Local cQuery:=""
Local lPri:=.T.
Local cNum

cQuery+= " SELECT * FROM "+RetSqlName("SC1")+" WHERE C1_FILIAL = '"+xFilial("SC1")+"' AND C1_NUM >= '"+cSolDe+"' AND C1_NUM <= '"+cSolAte+"' AND D_E_L_E_T_ = '' "
cQuery+= " AND C1_APROV = 'B' ORDER BY C1_NUM, C1_ITEM"
TCQUERY cQuery NEW ALIAS "SC1X"

SC1X->(dbGoTop())
cNum:=SC1X->C1_NUM
While !SC1X->(EOF())
	IF cNum <> SC1X->C1_NUM .OR. lPri
		lPri:=.F.
		Reclock((cAlisCab),.T.)
			(cAlisCab)->C1_NUM			:=SC1X->C1_NUM
			(cAlisCab)->C1_EMISSAO		:=dToc(sTod(SC1X->C1_EMISSAO))
			(cAlisCab)->C1_SOLICIT		:=SC1X->C1_SOLICIT
			(cAlisCab)->C1_SCORI		:=SC1X->C1_SCORI

		msUnLock()
	EndIF

	RecLock(cAlisGr1,.T.)

		(cAlisGr1)->C1_NUM		:=SC1X->C1_NUM
		(cAlisGr1)->C1_ITEM		:=SC1X->C1_ITEM
		(cAlisGr1)->C1_PRODUTO	:=SC1X->C1_PRODUTO
		(cAlisGr1)->C1_DESCRI	:=SC1X->C1_DESCRI
		(cAlisGr1)->C1_UM		:=SC1X->C1_UM
		(cAlisGr1)->C1_QUANT	:=SC1X->C1_QUANT
		(cAlisGr1)->C1_DATPRF	:=dToc(sTod(SC1X->C1_DATPRF))
	msUnLock()
	cNum:=SC1X->C1_NUM
	SC1X->(dbSkip())
	
EndDo

Return

